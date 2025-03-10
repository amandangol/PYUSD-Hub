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
        throw const FormatException('Invalid date format');
      }

      final DateFormat formatter = DateFormat('MMM dd, yyyy • HH:mm:ss');
      return formatter.format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
