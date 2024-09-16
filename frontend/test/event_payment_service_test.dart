import 'package:test/test.dart';

import '../lib/modules/event/event_payment_service.dart';

void main() {
  test('EventPaymentService.GetSubscriptionDiscounts', () {
    final service = EventPaymentService();

    Map<String, double> ret = { 'monthlyPrice': 39.0, 'monthlySavingsPerYear': 52.0,
      'monthly3Price': 104.0, 'monthly3SavingsPerYear': 104.0,
      'eventFunds': 5.0 };
    expect(service.GetSubscriptionDiscounts(10, 10), ret);

    ret = { 'monthlyPrice': 67.0, 'monthlySavingsPerYear': 80.0,
      'monthly3Price': 177.0, 'monthly3SavingsPerYear': 176.0,
      'eventFunds': 10.0 };
    expect(service.GetSubscriptionDiscounts(17, 10), ret);

    // If no hosts, more money per event (but same prices).
    ret = { 'monthlyPrice': 39.0, 'monthlySavingsPerYear': 52.0,
      'monthly3Price': 104.0, 'monthly3SavingsPerYear': 104.0,
      'eventFunds': 6.0 };
    expect(service.GetSubscriptionDiscounts(10, 0), ret);

    // If no hosts, can charge less to get same event funds.
    ret = { 'monthlyPrice': 36.0, 'monthlySavingsPerYear': 36.0,
      'monthly3Price': 94.0, 'monthly3SavingsPerYear': 92.0,
      'eventFunds': 5.0 };
    expect(service.GetSubscriptionDiscounts(9, 0), ret);
  });
}
