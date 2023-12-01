import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/common/form_input/input_fields.dart';

void main() {
  testWidgets('inputText widget', (WidgetTester tester) async {
    InputFields _inputFields = InputFields();
    var formVals = {};

    // TextField needs some Material parents to work; MaterialApp and Card suffice.
    await tester.pumpWidget(MaterialApp(home: Card(child: _inputFields.inputText(formVals, 'name', label: 'Name'))));

    expect(find.text('Name'), findsOneWidget);
  });
}