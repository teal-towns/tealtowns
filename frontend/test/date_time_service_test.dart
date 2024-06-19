import 'package:test/test.dart';

import '../lib/common/date_time_service.dart';

void main() {
  test('DateTimeService.WeekdayTimezone', () {
    final service = DateTimeService();

    Map<String, dynamic> ret;
    ret = { 'dayOfWeek': 1, 'startTime': '00:00' };
    expect(service.WeekdayTimezone(0, '17:00', 'America/Los_Angeles', 'UTC'), ret);

    ret = { 'dayOfWeek': 0, 'startTime': '23:30' };
    expect(service.WeekdayTimezone(0, '16:30', 'America/Los_Angeles', 'UTC'), ret);

    ret = { 'dayOfWeek': 6, 'startTime': '17:00' };
    expect(service.WeekdayTimezone(0, '00:00', 'UTC', 'America/Los_Angeles'), ret);

    ret = { 'dayOfWeek': 0, 'startTime': '16:30' };
    expect(service.WeekdayTimezone(0, '23:30', 'UTC', 'America/Los_Angeles'), ret);

    ret = { 'dayOfWeek': 0, 'startTime': '21:30' };
    expect(service.WeekdayTimezone(0, '23:30', 'America/Chicago', 'America/Los_Angeles'), ret);

    ret = { 'dayOfWeek': 1, 'startTime': '01:30' };
    expect(service.WeekdayTimezone(0, '23:30', 'America/Los_Angeles', 'America/Chicago'), ret);

    ret = { 'dayOfWeek': 1, 'startTime': '00:00' };
    expect(service.WeekdayTimezone(0, '17:00', 'America/Los_Angeles', 'Etc/GMT'), ret);

    ret = { 'dayOfWeek': 6, 'startTime': '17:00' };
    expect(service.WeekdayTimezone(0, '00:00', 'Etc/GMT', 'America/Los_Angeles'), ret);

    ret = { 'dayOfWeek': 0, 'startTime': '17:00' };
    expect(service.WeekdayTimezone(0, '17:00', 'America/Los_Angeles', 'BAD'), ret);

    ret = { 'dayOfWeek': 0, 'startTime': '17:00' };
    expect(service.WeekdayTimezone(0, '17:00', 'BAD', 'America/Los_Angeles'), ret);
  });
}
