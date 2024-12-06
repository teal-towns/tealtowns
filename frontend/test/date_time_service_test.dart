import 'package:test/test.dart';

import '../lib/common/date_time_service.dart';

void main() {
  test('DateTimeService.WeekdayTimezone', () {
    final service = DateTimeService();

    Map<String, dynamic> ret;

    ret = { 'dayOfWeek': 0, 'startTime': '21:30' };
    expect(service.WeekdayTimezone(0, '23:30', 'America/Chicago', 'America/Los_Angeles'), ret);

    ret = { 'dayOfWeek': 1, 'startTime': '01:30' };
    expect(service.WeekdayTimezone(0, '23:30', 'America/Los_Angeles', 'America/Chicago'), ret);

    ret = { 'dayOfWeek': 0, 'startTime': '17:00' };
    expect(service.WeekdayTimezone(0, '17:00', 'America/Los_Angeles', 'BAD'), ret);

    ret = { 'dayOfWeek': 0, 'startTime': '17:00' };
    expect(service.WeekdayTimezone(0, '17:00', 'BAD', 'America/Los_Angeles'), ret);


    // TODO - pass in date and use that to get correct zone (with daylight savings).
    // March to November
    // ret = { 'dayOfWeek': 1, 'startTime': '00:00' };
    // expect(service.WeekdayTimezone(0, '17:00', 'America/Los_Angeles', 'UTC'), ret);

    // ret = { 'dayOfWeek': 0, 'startTime': '23:30' };
    // expect(service.WeekdayTimezone(0, '16:30', 'America/Los_Angeles', 'UTC'), ret);

    // ret = { 'dayOfWeek': 6, 'startTime': '17:00' };
    // expect(service.WeekdayTimezone(0, '00:00', 'UTC', 'America/Los_Angeles'), ret);

    // ret = { 'dayOfWeek': 0, 'startTime': '16:30' };
    // expect(service.WeekdayTimezone(0, '23:30', 'UTC', 'America/Los_Angeles'), ret);

    // ret = { 'dayOfWeek': 6, 'startTime': '17:00' };
    // expect(service.WeekdayTimezone(0, '00:00', 'Etc/GMT', 'America/Los_Angeles'), ret);

    // ret = { 'dayOfWeek': 1, 'startTime': '00:00' };
    // expect(service.WeekdayTimezone(0, '17:00', 'America/Los_Angeles', 'Etc/GMT'), ret);

    ret = { 'dayOfWeek': 1, 'startTime': '01:00' };
    expect(service.WeekdayTimezone(0, '17:00', 'America/Los_Angeles', 'UTC'), ret);

    ret = { 'dayOfWeek': 1, 'startTime': '00:30' };
    expect(service.WeekdayTimezone(0, '16:30', 'America/Los_Angeles', 'UTC'), ret);

    ret = { 'dayOfWeek': 6, 'startTime': '16:00' };
    expect(service.WeekdayTimezone(0, '00:00', 'UTC', 'America/Los_Angeles'), ret);

    ret = { 'dayOfWeek': 0, 'startTime': '15:30' };
    expect(service.WeekdayTimezone(0, '23:30', 'UTC', 'America/Los_Angeles'), ret);

    ret = { 'dayOfWeek': 6, 'startTime': '16:00' };
    expect(service.WeekdayTimezone(0, '00:00', 'Etc/GMT', 'America/Los_Angeles'), ret);

    ret = { 'dayOfWeek': 1, 'startTime': '01:00' };
    expect(service.WeekdayTimezone(0, '17:00', 'America/Los_Angeles', 'Etc/GMT'), ret);
  });

  test('DateTimeService.ToAmPm', () {
    final service = DateTimeService();
    expect(service.ToAmPm('00:00'), '12:00am');
    expect(service.ToAmPm('00:30'), '12:30am');
    expect(service.ToAmPm('12:30'), '12:30pm');
    expect(service.ToAmPm('11:59'), '11:59am');
    expect(service.ToAmPm('12:00'), '12:00pm');
    expect(service.ToAmPm('23:59'), '11:59pm');
  });
}
