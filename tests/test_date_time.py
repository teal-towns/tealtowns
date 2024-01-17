import date_time

def test_nextMonth():
    datetime1 = date_time.from_string('2024-01-10 08:34:00')

    next = date_time.nextMonth(datetime1, months = 1)
    assert date_time.string(next) == '2024-02-10T00:00:00+00:00'

    next = date_time.nextMonth(datetime1, months = 2)
    assert date_time.string(next) == '2024-03-10T00:00:00+00:00'

    next = date_time.nextMonth(datetime1, months = 6)
    assert date_time.string(next) == '2024-07-10T00:00:00+00:00'

    next = date_time.nextMonth(datetime1, months = 12)
    assert date_time.string(next) == '2025-01-10T00:00:00+00:00'

    next = date_time.nextMonth(datetime1, months = 25)
    assert date_time.string(next) == '2026-02-10T00:00:00+00:00'
