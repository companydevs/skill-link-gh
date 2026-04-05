/// Trotro-based transport fare estimation for Ghana.
/// Fares are round-trip (artisan travels to client and back).
class TransportFareService {
  TransportFareService._();

  /// Distance bands → one-way trotro fare in GHS.
  static const List<_FareBand> _bands = [
    _FareBand(maxKm: 3, oneWay: 2.0),
    _FareBand(maxKm: 7, oneWay: 4.0),
    _FareBand(maxKm: 12, oneWay: 6.0),
    _FareBand(maxKm: 20, oneWay: 9.0),
    _FareBand(maxKm: 35, oneWay: 13.0),
    _FareBand(maxKm: double.infinity, oneWay: 18.0),
  ];

  /// Returns the round-trip trotro fare for a given distance in km.
  static double roundTripFare(double distanceKm) {
    for (final band in _bands) {
      if (distanceKm <= band.maxKm) return band.oneWay * 2;
    }
    return _bands.last.oneWay * 2;
  }

  /// Formatted string e.g. "GH₵ 12.00 transport"
  static String fareLabel(double distanceKm) {
    final fare = roundTripFare(distanceKm);
    return 'GH₵ ${fare.toStringAsFixed(2)} transport';
  }
}

class _FareBand {
  final double maxKm;
  final double oneWay;
  const _FareBand({required this.maxKm, required this.oneWay});
}
