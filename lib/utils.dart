
class DMS {
  final int degrees;
  final int minutes;
  final double seconds;
  final String direction;

  DMS({required this.degrees, required this.minutes, required this.seconds, required this.direction});
}

DMS decimalToDMS(double decimal, bool isLatitude) {
  String direction;
  if (isLatitude) {
    direction = decimal >= 0 ? 'N' : 'S';
  } else {
    direction = decimal >= 0 ? 'E' : 'W';
  }

  double absDecimal = decimal.abs();
  int degrees = absDecimal.truncate();
  double minutesNotTruncated = (absDecimal - degrees) * 60;
  int minutes = minutesNotTruncated.truncate();
  double seconds = (minutesNotTruncated - minutes) * 60;

  return DMS(
    degrees: degrees,
    minutes: minutes,
    seconds: seconds,
    direction: direction,
  );
}

double dmsToDecimal({
  required int degrees,
  required int minutes,
  required double seconds,
  required String direction,
}) {
  double decimal = degrees + (minutes / 60) + (seconds / 3600);
  if (direction == 'S' || direction == 'W') {
    decimal = -decimal;
  }
  return decimal;
}

double? dmsStringToDecimal(String dms) {
  final RegExp regex = RegExp(r'''(\d+)\s*[°º]\s*(\d+)\s*['’]\s*(\d+(?:\.\d+)?)\s*["”]\s*([NSEW])''', caseSensitive: false);
  final match = regex.firstMatch(dms);

  if (match != null) {
    double degrees = double.parse(match.group(1)!);
    double minutes = double.parse(match.group(2)!);
    double seconds = double.parse(match.group(3)!);
    String direction = match.group(4)!.toUpperCase();

    return dmsToDecimal(
      degrees: degrees.toInt(),
      minutes: minutes.toInt(),
      seconds: seconds,
      direction: direction,
    );
  }
  return null;
}
