import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DateFormatter {
  static String formatDate(dynamic timestamp, {String format = 'MMM dd, yyyy'}) {
    if (timestamp == null) return 'N/A';
    try {
      if (timestamp is String) {
        final ms = int.tryParse(timestamp);
        if (ms != null) {
          final date = DateTime.fromMillisecondsSinceEpoch(ms);
          return DateFormat(format).format(date);
        }
        return timestamp;
      } else if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return DateFormat(format).format(date);
      } else if (timestamp is DateTime) {
        return DateFormat(format).format(timestamp);
      } else if (timestamp is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return DateFormat(format).format(date);
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }
}