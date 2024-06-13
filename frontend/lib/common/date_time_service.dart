import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class DateTimeService {
  DateTimeService._privateConstructor();
  static final DateTimeService _instance = DateTimeService._privateConstructor();
  factory DateTimeService() {
    return _instance;
  }

  String Format(var dateTime, String format, {bool local = true}) {
    var dateValue = DateTime.parse(dateTime);
    if (local) {
      dateValue = dateValue.toUtc().toLocal();
    }
    return DateFormat(format).format(dateValue);
  }

  String TZ(var dateTime, { bool local = true }) {
    var dateValue = DateTime.parse(dateTime);
    if (local) {
      dateValue = dateValue.toUtc().toLocal();
    }
    return dateValue.timeZoneName;
  }
}
