import 'package:flutter/material.dart';

class SelectButtonsFormField extends FormField<String> {
  SelectButtonsFormField({ var options, String? label,
    FormFieldSetter<String>? onSaved, FormFieldValidator<String>? validator,
    String initialValue = '', ValueChanged<String?>? onChanged, Color colorSelected = Colors.blue,
    Color color = Colors.white, Color colorText = Colors.white, bool allowEmpty = true, }) : super(
      onSaved: onSaved,
      validator: validator,
      initialValue: initialValue,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (FormFieldState<String> state) {
        List<Widget> colsLabel = [];
        if (label != null && label.length > 0) {
          colsLabel += [
            Text(label!),
            SizedBox(height: 10),
          ];
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...colsLabel,
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options.map<Widget>((opt) {
                return FilledButton(
                  child: Text(opt['label']),
                  onPressed: () {
                    var newVal = opt['value'].toString();
                    if (state.value.toString() == newVal) {
                      newVal = '';
                    }
                    if (allowEmpty || newVal.length > 0) {
                      state.didChange(newVal);
                      if (onChanged != null) {
                        onChanged!(newVal);
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: state.value.toString() == opt['value'].toString() ? colorSelected : color,
                    foregroundColor: colorText,
                  ),
                );
              }).toList(),
            ),
          ]
        );
      }
    );
}
