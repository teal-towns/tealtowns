import 'dart:math';

class MathService {
  MathService._privateConstructor();
  static final MathService _instance = MathService._privateConstructor();
  factory MathService() {
    return _instance;
  }

  double rangeValue(double value, double valueMin, double valueMax, double signalStart, double signalEnd) {
    if (value <= valueMin) {
      return signalStart;
    } else if (value >= valueMax) {
      return signalEnd;
    }
    double changeRatio = ((value - valueMin) / (valueMax - valueMin)).abs();
    return signalStart + (signalEnd - signalStart) * changeRatio;
  }
}