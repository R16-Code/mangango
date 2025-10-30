import 'dart:math';

double haversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0088; // mean Earth radius (km)
  final phi1 = _deg2rad(lat1);
  final phi2 = _deg2rad(lat2);
  final dPhi = _deg2rad(lat2 - lat1);
  final dLambda = _deg2rad(lon2 - lon1);

  final sinDphi2 = sin(dPhi / 2);
  final sinDlam2 = sin(dLambda / 2);

  var a = sinDphi2 * sinDphi2 +
          cos(phi1) * cos(phi2) * sinDlam2 * sinDlam2;

  // Clamp untuk menghindari a>1 karena floating point (kasus antipodal)
  a = a.clamp(0.0, 1.0);

  final c = 2 * asin(sqrt(a));
  return R * c;
}

double _deg2rad(double deg) => deg * (pi / 180.0);