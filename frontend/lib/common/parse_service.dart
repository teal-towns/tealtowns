
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

  int toIntNoNull(dynamic val) {
    if (val.runtimeType == String) {
      if (val.isEmpty || val == '') {
        return 0;
      }
      int? newVal = int.tryParse(val);
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

  Map<String, dynamic> parseMapStringDynamic(Map<String, dynamic> jsonData) {
    Map<String, dynamic> data = {};
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

  List<String> parseListString(List<dynamic> itemsRaw) {
    List<String> items = [];
    if (itemsRaw != null) {
      for (var item in itemsRaw) {
        items.add(item);
      }
    }
    return items;
  }

  List<double> doubleList(List<dynamic> itemsRaw) {
    List<double> items = [];
    if (itemsRaw != null) {
      for (var item in itemsRaw) {
        items.add(toDoubleNoNull(item));
      }
    }
    return items;
  }

  // double StringToDouble(String val) {
  //   if (val[0] == '-') {
  //     return -1 * val.substring(1, val.length).toDouble();
  //   }
  //   return val.toDouble();
  // }

  double Precision(double val, int precision) {
    return  toDoubleNoNull(val.toStringAsFixed(precision));
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