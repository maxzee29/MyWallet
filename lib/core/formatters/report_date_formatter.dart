import 'package:intl/intl.dart';

class ReportDateFormatter {
  ReportDateFormatter._();

  static final DateFormat _fullDay = DateFormat('EEE, d MMM yyyy', 'id_ID');
  static final DateFormat _fullDayLong = DateFormat(
    'EEEE, d MMMM yyyy',
    'id_ID',
  );
  static final DateFormat _dayMonthLong = DateFormat('EEEE, d MMMM', 'id_ID');
  static final DateFormat _dayMonth = DateFormat('d MMM', 'id_ID');
  static final DateFormat _time = DateFormat('HH.mm', 'id_ID');

  static String fullDay(DateTime date) {
    return _fullDay.format(date);
  }

  static String fullDayLong(DateTime date) {
    return _fullDayLong.format(date);
  }

  static String dayMonthLong(DateTime date) {
    return _dayMonthLong.format(date);
  }

  static String dayMonth(DateTime date) {
    return _dayMonth.format(date);
  }

  static String time(DateTime date) {
    return _time.format(date);
  }
}
