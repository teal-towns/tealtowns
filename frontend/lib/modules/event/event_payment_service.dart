import 'dart:math';

class EventPaymentService {
  EventPaymentService._privateConstructor();
  static final EventPaymentService _instance = EventPaymentService._privateConstructor();
  factory EventPaymentService() {
    return _instance;
  }

  double _monthlyDiscount = 0.1;
  double _yearlyDiscount = 0.25;
  double _payFeeFactor = 0.029 + 0.008;
  double _payFeeFixed = 0.3;
  double _cutFactor = 0.01;

  Map<String, double> GetSubscriptionDiscounts(double weeklyPrice, double hostGroupSize) {
    double yearlyFullPrice = weeklyPrice * 52;
    double monthlyFullPrice = yearlyFullPrice / 12;
    double yearlyPrice = (yearlyFullPrice * (1 - _yearlyDiscount)).ceil().toDouble();
    double monthlyPrice = (monthlyFullPrice * (1 - _monthlyDiscount)).ceil().toDouble();
    double yearlySavingsPerYear = yearlyFullPrice - yearlyPrice;
    double monthlySavingsPerYear = ((monthlyFullPrice - monthlyPrice) * 12).floor().toDouble();

    double yearlyFunds = yearlyPrice;
    if (hostGroupSize > 0) {
        yearlyFunds = yearlyPrice * (hostGroupSize - 1) / hostGroupSize;
    }
    double eventsPerYear = 52;
    Map<String, double> payInfo = GetPayInfo(yearlyFunds, eventsPerYear);

    return { 'yearlyPrice': yearlyPrice, 'monthlyPrice': monthlyPrice,
        'yearlySavingsPerYear': yearlySavingsPerYear, 'monthlySavingsPerYear': monthlySavingsPerYear,
        'eventFunds': payInfo['eventFunds']! };
  }

  Map<String, double> GetPayInfo(double funds, double eventsPerPayPeriod) {
    double fundsPerEvent = funds / eventsPerPayPeriod;
    double payFee = fundsPerEvent * _payFeeFactor + _payFeeFixed;
    double payFeePerEvent = payFee / eventsPerPayPeriod;
    double cutPerEvent = (fundsPerEvent * _cutFactor).ceil().toDouble();
    double eventFunds = (fundsPerEvent - payFeePerEvent - cutPerEvent).floor().toDouble();
    return { 'eventFunds': eventFunds };
  }
}