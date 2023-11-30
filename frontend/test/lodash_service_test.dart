import 'package:test/test.dart';

import '../lib/common/lodash_service.dart';

void main() {
  test('Lodash.randomString should be proper length', () {
    final lodash = LodashService();

    String randomString = lodash.randomString(length: 10);
    expect(randomString.length, 10);
  });
}