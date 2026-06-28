import 'package:intl/intl.dart';

class DateHelpers {
  static final _timeFormat = DateFormat('h:mm a');
  static final _dateFormat = DateFormat('MMM d, yyyy');
  static final _dayFormat = DateFormat('EEEE');
  static final _shortDayFormat = DateFormat('EEE');

  static String formatTime(DateTime dt) => _timeFormat.format(dt);
  static String formatDate(DateTime dt) => _dateFormat.format(dt);
  static String formatDay(DateTime dt) => _dayFormat.format(dt);
  static String formatShortDay(DateTime dt) => _shortDayFormat.format(dt);

  static bool isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
