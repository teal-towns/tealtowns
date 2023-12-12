import 'dart:math';

import '../../common/currency_service.dart';

class SharedItemService {
  SharedItemService._privateConstructor();
  static final SharedItemService _instance = SharedItemService._privateConstructor();
  factory SharedItemService() {
    return _instance;
  }

  CurrencyService _currency = CurrencyService();

  double _resaleDiscount = 0.5;
  double _maintenancePerYearFactor = 0.02;
  double _maintenancePerPersonPerYearMin = 5;
  double _investmentReturnPerYearFactor = 0.1;
  double _feeFactor = 0.04;
  double _downPerPersonMinFactor = 0.05;
  double _downTotalFactor = 0.33;
  double _downPerPersonMax = 10000;
  double _downPerPersonMin = 100;
  double _minDiscountFactor = 0.1;
  double _minDiscountPrice = 10000;
  double _minMonthlyPayment = 10;

  double MaxCurrentPrice(double originalPrice, int generation) {
    if (generation <= 1) {
      return originalPrice;
    }
    double min1 = min(_minDiscountPrice, originalPrice * _minDiscountFactor);
    return max(min1, originalPrice * pow(_resaleDiscount, (generation - 1)));
  }

  double GetMaintenancePerYear(double currentPrice, int numOwners) {
    return max(currentPrice * _maintenancePerYearFactor, _maintenancePerPersonPerYearMin * numOwners);
  }

  Map<String, dynamic> GetPayments(double currentPrice, int monthsToPayBack, int numOwners,
    double maintenancePerYear, {String currency = 'USD'}) {
    double returnPerMonthFactor = _investmentReturnPerYearFactor / 12;
    double investorProfit = currentPrice * returnPerMonthFactor * monthsToPayBack;
    double totalToPayBack = currentPrice + investorProfit;
    double maintenancePerPersonMonthly = maintenancePerYear / 12 / numOwners;
    double monthlyPaymentMin = ((totalToPayBack / numOwners / monthsToPayBack) + maintenancePerPersonMonthly);

    double min1 = min(totalToPayBack / numOwners, _downPerPersonMin);
    double min2 = min(totalToPayBack * _downPerPersonMinFactor, totalToPayBack * _downTotalFactor / numOwners);
    min2 = min(min2, _downPerPersonMax);
    double downPerPerson = max(monthlyPaymentMin, min1);
    downPerPerson = max(downPerPerson, min2);

    double basePerPerson = totalToPayBack / numOwners - downPerPerson;
    double monthlyPayment = ((basePerPerson / monthsToPayBack) + maintenancePerPersonMonthly);
    if (monthlyPayment < _minMonthlyPayment) {
      if (basePerPerson <= 0) {
        monthlyPayment = 0;
        monthsToPayBack = 0;
      } else if (basePerPerson < _minMonthlyPayment * 1.5) {
        monthlyPayment = basePerPerson;
        monthsToPayBack = 1;
      } else {
        monthlyPayment = _minMonthlyPayment;
        monthsToPayBack = (basePerPerson / monthlyPayment - maintenancePerPersonMonthly).ceil();
      }
    }

    return {
      'monthlyPayment': monthlyPayment.ceil().toDouble(),
      'monthlyPaymentWithFee': (monthlyPayment * (1 + _feeFactor)).ceil().toDouble(),
      'downPerPerson': downPerPerson.ceil().toDouble(),
      'downPerPersonWithFee': (downPerPerson * (1 + _feeFactor)).ceil().toDouble(),
      'investorProfit': investorProfit.floor().toDouble(),
      'monthsToPayBack': monthsToPayBack.toDouble(),
    };
  }

  Map<String, String> GetTexts(double downPerPerson, double monthlyPayment, int monthsToPayBack,
    String currency) {
    String down = _currency.Format(downPerPerson.ceil().toDouble(), currency);
    String monthly = _currency.Format(monthlyPayment.ceil().toDouble(), currency);
    String months = monthsToPayBack == 1 ? 'month' : 'months';
    String perPersonText = "${down} down, ${monthly} / month for ${monthsToPayBack.toString()} ${months}";
    String perPersonTextDownLast = "${monthly} / month for ${monthsToPayBack.toString()} ${months}, ${down} down";
    return {
      'perPerson': perPersonText,
      'perPersonDownLast': perPersonTextDownLast,
    };
  }
}