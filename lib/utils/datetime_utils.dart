import 'package:intl/intl.dart';

class DateTimeUtils {
  static String formatDateTime(dynamic input) {
    try {
      DateTime dateTime;

      if (input is String) {
        dateTime = DateTime.parse(input);
      } else if (input is DateTime) {
        dateTime = input;
      } else {
        throw FormatException('Invalid date format');
      }

      final DateFormat formatter = DateFormat('MMM dd, yyyy • HH:mm:ss');
      return formatter.format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }
}

void main() {
  // Testing with DateTime object
  print(DateTimeUtils.formatDateTime(DateTime.now()));

  // Testing with String timestamp
  print(DateTimeUtils.formatDateTime("2024-03-07T14:30:00Z"));

  // Testing with an invalid input
  print(DateTimeUtils.formatDateTime("invalid-date"));
}
