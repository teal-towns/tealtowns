import 'package:test/test.dart';

import '../lib/modules/shared_item/shared_item_service.dart';

void main() {
  test('SharedItemService.MaxCurrentPrice', () {
    final sharedItem = SharedItemService();
    expect(sharedItem.MaxCurrentPrice(1000, 0), 1000);
    expect(sharedItem.MaxCurrentPrice(1000, 1), 1000);
    expect(sharedItem.MaxCurrentPrice(1000, 2), 500);
    expect(sharedItem.MaxCurrentPrice(1000, 3), 250);
    expect(sharedItem.MaxCurrentPrice(1000, 4), 125);
    expect(sharedItem.MaxCurrentPrice(1000, 5), 100);
    expect(sharedItem.MaxCurrentPrice(1000, 6), 100);
    expect(sharedItem.MaxCurrentPrice(300000, 6), 10000);
  });

  test('SharedItemService.GetMaintenancePerYear', () {
    final sharedItem = SharedItemService();
    expect(sharedItem.GetMaintenancePerYear(1000, 10), 50);
    expect(sharedItem.GetMaintenancePerYear(5000, 20), 100);
    expect(sharedItem.GetMaintenancePerYear(25000, 5), 500);
    expect(sharedItem.GetMaintenancePerYear(50000, 10), 1000);
    expect(sharedItem.GetMaintenancePerYear(6250, 10), 125);
  });

  test('SharedItemService.GetPayments', () {
    final sharedItem = SharedItemService();
    Map<String, dynamic> payments;
    payments = sharedItem.GetPayments(1000, 1*12, 10, 50);
    expect(payments['downPerPerson'], 100);
    expect(payments['downPerPersonWithFee'], 105);
    expect(payments['monthlyPayment'], 10);
    expect(payments['monthlyPaymentWithFee'], 13);
    expect(payments['monthsToPayBack'], 1);
    payments = sharedItem.GetPayments(5000, 1*12, 20, 100);
    expect(payments['downPerPerson'], 100);
    expect(payments['downPerPersonWithFee'], 105);
    expect(payments['monthlyPayment'], 15);
    expect(payments['monthlyPaymentWithFee'], 18);
    expect(payments['monthsToPayBack'], 1*12);
    payments = sharedItem.GetPayments(10000, 1*12, 100, 500);
    expect(payments['downPerPerson'], 100);
    expect(payments['downPerPersonWithFee'], 105);
    expect(payments['monthlyPayment'], 10);
    expect(payments['monthlyPaymentWithFee'], 13);
    expect(payments['monthsToPayBack'], 1);
    payments = sharedItem.GetPayments(25000, 2*12, 5, 500);
    expect(payments['downPerPerson'], 1500);
    expect(payments['downPerPersonWithFee'], 1560);
    expect(payments['monthlyPayment'], 196);
    expect(payments['monthlyPaymentWithFee'], 205);
    expect(payments['monthsToPayBack'], 2*12);
    payments = sharedItem.GetPayments(50000, 3*12, 10, 1000);
    expect(payments['downPerPerson'], 2145);
    expect(payments['downPerPersonWithFee'], 2232);
    expect(payments['monthlyPayment'], 130);
    expect(payments['monthlyPaymentWithFee'], 137);
    expect(payments['monthsToPayBack'], 3*12);
    payments = sharedItem.GetPayments(50000, 5*12, 1, 1000);
    expect(payments['downPerPerson'], 3750);
    expect(payments['downPerPersonWithFee'], 3901);
    expect(payments['monthlyPayment'], 1271);
    expect(payments['monthlyPaymentWithFee'], 1323);
    expect(payments['monthsToPayBack'], 5*12);
    payments = sharedItem.GetPayments(100000, 5*12, 1, 2000);
    expect(payments['downPerPerson'], 7500);
    expect(payments['downPerPersonWithFee'], 7800);
    expect(payments['monthlyPayment'], 2542);
    expect(payments['monthlyPaymentWithFee'], 2645);
    expect(payments['monthsToPayBack'], 5*12);
    payments = sharedItem.GetPayments(300000, 5*12, 2, 6000);
    expect(payments['downPerPerson'], 10000);
    expect(payments['downPerPersonWithFee'], 10400);
    expect(payments['monthlyPayment'], 3834);
    expect(payments['monthlyPaymentWithFee'], 3988);
    expect(payments['monthsToPayBack'], 5*12);
    payments = sharedItem.GetPayments(700000, 12*12, 1, 14000);
    expect(payments['downPerPerson'], 11862);
    expect(payments['downPerPersonWithFee'], 12337);
    expect(payments['monthlyPayment'], 11779);
    expect(payments['monthlyPaymentWithFee'], 12251);
    expect(payments['monthsToPayBack'], 12*12);

    payments = sharedItem.GetPayments(500, 1*12, 10, 50);
    expect(payments['downPerPerson'], 55);
    expect(payments['downPerPersonWithFee'], 59);
    expect(payments['monthlyPayment'], 0);
    expect(payments['monthlyPaymentWithFee'], 0);
    expect(payments['monthsToPayBack'], 0);
  });
}