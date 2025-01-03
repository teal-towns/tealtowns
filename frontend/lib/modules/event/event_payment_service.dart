import 'dart:math';

class EventPaymentService {
  EventPaymentService._privateConstructor();
  static final EventPaymentService _instance = EventPaymentService._privateConstructor();
  factory EventPaymentService() {
    return _instance;
  }

  double _monthlyDiscount = 0.1;
  double _monthly3Discount = 0.2;
  double _yearlyDiscount = 0.2;
  double _maxDiscount = 0.2;
  double _payFeeFactor = 0.029 + 0.008;
  double _payFeeFixed = 0.3;
  double _cutFactor = 0.01;

  Map<String, double> GetSubscriptionDiscounts(double weeklyPrice, double hostGroupSize) {
    double yearlyFullPrice = weeklyPrice * 52;
    double monthlyFullPrice = yearlyFullPrice / 12;
    double monthly3FullPrice = yearlyFullPrice / 12 * 3;
    double yearlyPrice = (yearlyFullPrice * (1 - _yearlyDiscount)).ceil().toDouble();
    double monthlyPrice = (monthlyFullPrice * (1 - _monthlyDiscount)).ceil().toDouble();
    double monthly3Price = (monthly3FullPrice * (1 - _monthly3Discount)).ceil().toDouble();
    double yearlySavingsPerYear = yearlyFullPrice - yearlyPrice;
    double monthlySavingsPerYear = ((monthlyFullPrice - monthlyPrice) * 12).floor().toDouble();
    double monthly3SavingsPerYear = ((monthly3FullPrice - monthly3Price) * 12 / 3).floor().toDouble();
    double montlyPricePerEvent = double.parse((weeklyPrice * (1 - _monthlyDiscount)).toDouble().toStringAsFixed(2));
    double montly3PricePerEvent = double.parse((weeklyPrice * (1 - _monthly3Discount)).toDouble().toStringAsFixed(2));

    // double minFunds = yearlyPrice;
    // double eventsPerPeriod = 52;
    double minFunds = monthly3Price;
    double eventsPerPeriod = 52 / 12 * 3;
    if (hostGroupSize > 0) {
        minFunds = minFunds * (hostGroupSize - 1) / hostGroupSize;
    }
    double eventFunds = GetSingleEventFunds(weeklyPrice, hostGroupSize);
    // Map<String, double> payInfo = GetPayInfo(minFunds, eventsPerPeriod);

    return {
      // 'yearlyPrice': yearlyPrice, 'yearlySavingsPerYear': yearlySavingsPerYear,
      'monthlyPrice': monthlyPrice, 'monthlySavingsPerYear': monthlySavingsPerYear,
      'monthlyPricePerEvent': montlyPricePerEvent, 'monthlyDiscount': _monthlyDiscount,
      'monthly3Price': monthly3Price, 'monthly3SavingsPerYear': monthly3SavingsPerYear,
      'monthly3PricePerEvent': montly3PricePerEvent, 'monthly3Discount': _monthly3Discount,
      'eventFunds': eventFunds,
    };
  }

  // Map<String, double> GetPayInfo(double funds, double eventsPerPayPeriod) {
  //   double fundsPerEvent = funds / eventsPerPayPeriod;
  //   double payFee = funds * _payFeeFactor + _payFeeFixed;
  //   double payFeePerEvent = payFee / eventsPerPayPeriod;
  //   double cutPerEvent = (fundsPerEvent * _cutFactor).ceil().toDouble();
  //   double eventFunds = (fundsPerEvent - payFeePerEvent - cutPerEvent).floor().toDouble();
  //   return { 'eventFunds': eventFunds };
  // }
  double GetSingleEventFunds(double price, double hostGroupSize) {
    double payFee = price * _payFeeFactor + _payFeeFixed;
    double minPrice = price * (1 - _maxDiscount);
    double minProfit = price * _cutFactor;
    double profitHostBuffer = minProfit;
    if (hostGroupSize > 0) {
        profitHostBuffer += (minPrice - payFee - minProfit) / (hostGroupSize - 1);
    }
    double eventFunds = (minPrice - payFee - profitHostBuffer).floor().toDouble();
    return eventFunds;
  }
}