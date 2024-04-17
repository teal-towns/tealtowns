import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class DateTimeService {
  DateTimeService._privateConstructor();
  static final DateTimeService _instance = DateTimeService._privateConstructor();
  factory DateTimeService() {
    return _instance;
  }

  String Format(var dateTime, String format) {
    var dateValue = DateTime.parse(dateTime).toUtc().toLocal();
    return DateFormat(format).format(dateValue);
  }
}
