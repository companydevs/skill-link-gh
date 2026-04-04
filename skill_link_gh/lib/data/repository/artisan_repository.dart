import 'dart:developer';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class ArtisanRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetch all artisans from Firestore, optionally filtered by category.
  /// Distance is computed client-side from [userLat]/[userLng].
  Future<List<Map<String, dynamic>>> fetchArtisans({
    double? userLat,
    double? userLng,
  }) async {
    try {
      final currentUid = _auth.currentUser?.uid;

      // Run two queries to catch docs saved with either field name
      final results = await Future.wait([
        _firestore
            .collection('users')
            .where('role', isEqualTo: 'artisan')
            .limit(50)
            .get(),
        _firestore
            .collection('users')
            .where('isArtisan', isEqualTo: true)
            .limit(50)
            .get(),
      ]);

      // Merge and deduplicate by doc ID, exclude self and email-keyed docs
      final seen = <String>{};
      final docs = <QueryDocumentSnapshot>[];
      for (final snapshot in results) {
        for (final doc in snapshot.docs) {
          // Skip email-keyed docs (doc ID contains '@') and self
          if (doc.id == currentUid || doc.id.contains('@')) continue;
          if (seen.add(doc.id)) docs.add(doc);
        }
      }

      final artisans = docs.map((doc) {
        final data = Map<String, dynamic>.from(
          doc.data() as Map<String, dynamic>,
        );
        data['id'] = doc.id;

        // Normalise fields to match what the UI expects
        data['name'] = data['fullName'] ?? data['name'] ?? 'Unknown';
        data['profileImage'] = data['profileImage'] ?? data['photoUrl'] ?? '';
        data['semanticLabel'] = 'Profile photo of ${data['name']}';

        // Services: prefer 'skills' list, fall back to 'serviceCategories'
        final skills = data['skills'];
        final categories = data['serviceCategories'];
        if (skills is List && skills.isNotEmpty) {
          data['services'] = List<String>.from(skills);
        } else if (categories is List && categories.isNotEmpty) {
          data['services'] = List<String>.from(categories);
        } else {
          data['services'] = <String>[];
        }

        // Rating
        data['rating'] = (data['rating'] as num?)?.toDouble() ?? 0.0;

        // Availability — default true if not set
        data['isAvailable'] = data['isAvailable'] ?? true;

        // Verified
        data['isVerified'] = data['identityVerified'] ?? false;

        // Price range from dailyRate (falls back to hourlyRate for existing data)
        final rate = data['dailyRate'] ?? data['hourlyRate'];
        if (rate != null) {
          data['dailyRate'] = rate;
          data['priceRange'] = 'GHS $rate/day';
        } else {
          data['priceRange'] = 'Contact for price';
        }

        // Distance + assign stable lat/lng for artisans without stored coords
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          data['_lat'] = lat;
          data['_lng'] = lng;
          if (userLat != null && userLng != null) {
            final meters = Geolocator.distanceBetween(
              userLat,
              userLng,
              lat,
              lng,
            );
            data['distance'] = double.parse((meters / 1000).toStringAsFixed(1));
          } else {
            data['distance'] = 0.0;
          }
        } else if (userLat != null && userLng != null) {
          // Assign a stable random offset so the marker doesn't jump on rebuild
          final rng = math.Random(data['id'].hashCode);
          final offsetLat = (rng.nextDouble() - 0.5) * 0.04;
          final offsetLng = (rng.nextDouble() - 0.5) * 0.04;
          data['_lat'] = userLat + offsetLat;
          data['_lng'] = userLng + offsetLng;
          final meters = Geolocator.distanceBetween(
            userLat,
            userLng,
            data['_lat'] as double,
            data['_lng'] as double,
          );
          data['distance'] = double.parse((meters / 1000).toStringAsFixed(1));
        } else {
          data['distance'] = 0.0;
        }

        return data;
      }).toList();

      // Sort by distance if we have user location
      if (userLat != null && userLng != null) {
        artisans.sort(
          (a, b) =>
              (a['distance'] as double).compareTo(b['distance'] as double),
        );

        // Enrich with real road distances from Google Distance Matrix API
        // Only for artisans that have stored coordinates
        await _enrichWithRoadDistances(artisans, userLat, userLng);
      }

      return artisans;
    } catch (e) {
      log('Error fetching artisans: $e');
      return [];
    }
  }

  /// Calls the getDistanceMatrix Cloud Function to get real road distances
  /// and travel times. Falls back to straight-line if the call fails.
  Future<void> _enrichWithRoadDistances(
    List<Map<String, dynamic>> artisans,
    double userLat,
    double userLng,
  ) async {
    // Use _lat/_lng which are set for ALL artisans (real coords or assigned offsets)
    final withCoords = artisans.where((a) {
      return a['_lat'] != null && a['_lng'] != null;
    }).toList();

    if (withCoords.isEmpty) return;

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getDistanceMatrix')
          .call({
            'originLat': userLat,
            'originLng': userLng,
            'destinations': withCoords
                .map(
                  (a) => {
                    'id': a['id'] as String,
                    'lat': a['_lat'] as double,
                    'lng': a['_lng'] as double,
                  },
                )
                .toList(),
          });

      final results = (result.data['results'] as List).cast<Map>();
      for (final r in results) {
        final id = r['artisanId'] as String;
        final idx = artisans.indexWhere((a) => a['id'] == id);
        if (idx != -1) {
          artisans[idx]['distance'] = (r['distanceKm'] as num).toDouble();
          artisans[idx]['durationMinutes'] = (r['durationMinutes'] as num)
              .toInt();
        }
      }

      artisans.sort(
        (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
      );
    } catch (e) {
      log('Distance Matrix enrichment failed (using straight-line): $e');
    }
  }
}
