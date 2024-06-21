import 'package:get_ip_address/get_ip_address.dart';

class IPService {
  IPService._privateConstructor();
  static final IPService _instance = IPService._privateConstructor();
  factory IPService() {
    return _instance;
  }

  String _ipAddress = '0-0-0-0';
  bool _ipLoaded = false;

  String IP({prefix = 'ip_'}) {
    return prefix + _ipAddress.replaceAll('.', '-');
  }

  bool IsLoaded() {
    return _ipLoaded;
  }

  Future<String> GetIPAddress() async {
    if (_ipLoaded) {
      return IP();
    }
    try {
      var ipAddress = IpAddress(type: RequestType.json);
      dynamic data = await ipAddress.getIpAddress();
      print(data.toString());
      _ipAddress = data['ip'].toString().replaceAll('.', '-');
      _ipLoaded = true;
      return IP();
    } on IpAddressException catch (exception) {
      print(exception.message);
    }
    _ipLoaded = true;
    return IP();
  }

}
