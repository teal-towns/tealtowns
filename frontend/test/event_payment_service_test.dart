import 'package:test/test.dart';

import '../lib/modules/event/event_payment_service.dart';

void main() {
  test('EventPaymentService.GetSubscriptionDiscounts', () {
    final service = EventPaymentService();

    Map<String, double> ret = { 'yearlyPrice': 390.0, 'monthlyPrice': 39.0,
        'yearlySavingsPerYear': 130.0, 'monthlySavingsPerYear': 52.0, 'eventFunds': 5.0 };
    expect(service.GetSubscriptionDiscounts(10, 10), ret);

    ret = { 'yearlyPrice': 663.0, 'monthlyPrice': 67.0,
        'yearlySavingsPerYear': 221.0, 'monthlySavingsPerYear': 80.0, 'eventFunds': 10.0 };
    expect(service.GetSubscriptionDiscounts(17, 10), ret);

    // If no hosts, more money per event (but same prices).
    ret = { 'yearlyPrice': 390.0, 'monthlyPrice': 39.0,
        'yearlySavingsPerYear': 130.0, 'monthlySavingsPerYear': 52.0, 'eventFunds': 6.0 };
    expect(service.GetSubscriptionDiscounts(10, 0), ret);

    // If no hosts, can charge less to get same event funds.
    ret = { 'yearlyPrice': 351.0, 'monthlyPrice': 36.0,
        'yearlySavingsPerYear': 117.0, 'monthlySavingsPerYear': 36.0, 'eventFunds': 5.0 };
    expect(service.GetSubscriptionDiscounts(9, 0), ret);
  });
}
