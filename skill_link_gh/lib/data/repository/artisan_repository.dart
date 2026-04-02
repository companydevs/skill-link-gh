import 'package:cloud_firestore/cloud_firestore.dart';
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

      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'artisan')
          .limit(50)
          .get();

      final artisans = snapshot.docs
          .where((doc) => doc.id != currentUid) // exclude self
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;

            // Normalise fields to match what the UI expects
            data['name'] = data['fullName'] ?? data['name'] ?? 'Unknown';
            data['profileImage'] =
                data['profileImage'] ?? data['photoUrl'] ?? '';
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

            // Distance
            final lat = (data['latitude'] as num?)?.toDouble();
            final lng = (data['longitude'] as num?)?.toDouble();
            if (lat != null &&
                lng != null &&
                userLat != null &&
                userLng != null) {
              final meters = Geolocator.distanceBetween(
                userLat,
                userLng,
                lat,
                lng,
              );
              data['distance'] = double.parse(
                (meters / 1000).toStringAsFixed(1),
              );
            } else {
              data['distance'] = 0.0;
            }

            return data;
          })
          .toList();

      // Sort by distance if we have user location
      if (userLat != null && userLng != null) {
        artisans.sort(
          (a, b) =>
              (a['distance'] as double).compareTo(b['distance'] as double),
        );
      }

      return artisans;
    } catch (e) {
      print('Error fetching artisans: $e');
      return [];
    }
  }
}
