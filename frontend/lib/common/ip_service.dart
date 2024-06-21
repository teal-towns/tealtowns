import 'package:get_ip_address/get_ip_address.dart';

class IPService {
  IPService._privateConstructor();
  static final IPService _instance = IPService._privateConstructor();
  factory IPService() {
    return _instance;
  }

  String _ipAddress = '0-0-0-0';

  String IP({prefix = 'ip_'}) {
    return prefix + _ipAddress.replaceAll('.', '-');
  }

  Future<String> GetIPAddress() async {
    try {
      var ipAddress = IpAddress(type: RequestType.json);
      dynamic data = await ipAddress.getIpAddress();
      print(data.toString());
      _ipAddress = data['ip'].toString().replaceAll('.', '-');
      return _ipAddress;
    } on IpAddressException catch (exception) {
      print(exception.message);
    }
    return _ipAddress;
  }

}
