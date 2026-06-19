part of 'explore_remote_datasource.dart';

// Generates a human-readable relative time label from a DateTime object.
String _dateLabel(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  // Return "Just now" for updates within the last minute.
  if (difference.inMinutes < 1) return 'Just now';
  // Show minutes for updates less than an hour old.
  if (difference.inHours < 1) return '${difference.inMinutes} min ago';
  // Show hours for updates less than a day old.
  if (difference.inDays < 1) return '${difference.inHours} hrs ago';
  // Special case for exactly one day ago.
  if (difference.inDays == 1) return 'Yesterday';
  // Fallback to a simple day/month/year format for older dates.
  return '${date.day}/${date.month}/${date.year}';
}

// Converts a Firestore Timestamp, DateTime, or null value into a DateTime object.
DateTime _dateTime(Object? value) {
  // Handle Firestore Timestamp objects.
  if (value is Timestamp) return value.toDate();
  // Pass through existing DateTime objects.
  if (value is DateTime) return value;
  // Return epoch for null or unsupported types.
  return DateTime.fromMillisecondsSinceEpoch(0);
}

// Maps numeric difficulty levels (1-5) to descriptive labels.
String _difficultyLabel(Object? value) {
  final level = _intValue(value);
  switch (level) {
    case 1:
      return 'Novice';
    case 2:
      return 'Beginner';
    case 3:
      return 'Intermediate';
    case 4:
      return 'Advanced';
    case 5:
      return 'Master';
    default:
      return 'Not set';
  }
}

// Safely extracts a trimmed string from an object, with an optional fallback.
String _stringValue(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

// Converts an iterable into a list of non-empty trimmed strings.
List<String> _stringList(Object? value) {
  // Handle both List and other Iterable types.
  if (value is Iterable) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}

// Extracts an integer from various numeric types or string representations.
int _intValue(Object? value, {int fallback = 0}) {
  // Direct integer assignment.
  if (value is int) return value;
  // Handle num types (double, int) safely.
  if (value is num) return value.toInt();
  // Attempt string parsing as a last resort.
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

// Extracts a double from various numeric types or string representations.
double _doubleValue(Object? value) {
  // Direct double assignment.
  if (value is double) return value;
  // Handle num types (double, int) safely.
  if (value is num) return value.toDouble();
  // Attempt string parsing as a last resort.
  return double.tryParse(value?.toString() ?? '') ?? 0;
}