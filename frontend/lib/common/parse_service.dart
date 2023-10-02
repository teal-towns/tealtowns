
class ParseService {
  ParseService._privateConstructor();
  static final ParseService _instance = ParseService._privateConstructor();
  factory ParseService() {
    return _instance;
  }

  double? toDouble(var val, { bool allowNull = false }) {
    if (val.runtimeType == String) {
      if (val.isEmpty || val == '') {
        if (allowNull) {
          return null;
        }
        return 0;
      }
      double? newVal = double.tryParse(val);
      if (newVal == null) {
        return allowNull ? newVal : 0;
      }
      return newVal;
    }
    if (val == null) {
      return allowNull ? val : 0;
    }
    return val;
  }

  double toDoubleNoNull(var val) {
    if (val.runtimeType == String) {
      if (val.isEmpty || val == '') {
        return 0;
      }
      double? newVal = double.tryParse(val);
      if (newVal == null) {
        return 0;
      }
      return newVal;
    }
    if (val == null) {
      return 0;
    }
    return val;
  }

  Map<String, double> parseMapStringDouble(Map<String, dynamic> jsonData) {
    Map<String, double> data = {};
    jsonData.forEach((key, val) {
      data[key] = val;
    });
    return data;
  }

  List<Map<String, dynamic>> parseListMapStringDynamic(List<dynamic> jsonData) {
    List<Map<String, dynamic>> data = [];
    for (int ii = 0; ii < jsonData.length; ii++) {
      data.add({});
      jsonData[ii].forEach((key, val) {
        data[ii][key] = val;
      });
    }
    return data;
  }

  //dynamic toDoubleEmpty(var val) {
  //  if (val.runtimeType == String) {
  //    if (val.isEmpty || val == '') {
  //      return '';
  //    }
  //    return double.parse(val);
  //  }
  //  return val;
  //}
}