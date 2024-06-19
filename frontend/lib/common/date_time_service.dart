import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class DateTimeService {
  DateTimeService._privateConstructor();
  static final DateTimeService _instance = DateTimeService._privateConstructor();
  factory DateTimeService() {
    return _instance;
  }

  bool _tzInited = false;

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

  void InitTZ() {
    if (!_tzInited) {
      tz.initializeTimeZones();
      _tzInited = true;
    }
  }

  Map<String, dynamic> WeekdayTimezone(int dayOfWeek, String startTime, String timezoneFrom, String timezoneTo) {
    InitTZ();
    Map<String, dynamic> ret = {
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
    };
    var zoneFrom;
    try {
      zoneFrom = tz.getLocation(timezoneFrom);
    }  catch (e) {
      return ret;
    }
    int offsetFromMinutes = (zoneFrom.currentTimeZone.offset / 1000 / 60).round();
    int offsetFromHours = (offsetFromMinutes / 60).round();
    offsetFromMinutes = offsetFromMinutes % 60;

    var zoneTo;
    try {
      zoneTo = tz.getLocation(timezoneTo);
    }  catch (e) {
      return ret;
    }
    int offsetToMinutes = (zoneTo.currentTimeZone.offset / 1000 / 60).round();
    int offsetToHours = (offsetToMinutes / 60).round();
    offsetToMinutes = offsetToMinutes % 60;

    int offsetHours = offsetToHours - offsetFromHours;
    int offsetMinutes = offsetToMinutes - offsetFromMinutes;

    int hour = int.parse(startTime.substring(0, 2));
    int minute = int.parse(startTime.substring(3, 5));
    int newHour = hour + offsetHours;
    int newMinute = minute + offsetMinutes;
    if (newMinute >= 60) {
      newHour += 1;
      newMinute -= 60;
    }
    if (newMinute < 0) {
      newHour -= 1;
      newMinute += 60;
    }
    if (newHour >= 24) {
      newHour -= 24;
      dayOfWeek += 1;
      if (dayOfWeek > 6) {
        dayOfWeek = 0;
      }
    }
    else if (newHour < 0) {
      newHour += 24;
      dayOfWeek -= 1;
      if (dayOfWeek < 0) {
        dayOfWeek = 6;
      }
    }
    return {
      'dayOfWeek': dayOfWeek,
      'startTime': '${newHour.toString().padLeft(2, "0")}:${newMinute.toString().padLeft(2, "0")}',
    };
  }
}
