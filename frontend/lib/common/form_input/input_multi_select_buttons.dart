import 'package:flutter/material.dart';

class MultiSelectButtonsFormField extends FormField<List<String>> {
  MultiSelectButtonsFormField({ var options, String? label,
    FormFieldSetter<List<String>>? onSaved, FormFieldValidator<List<String>>? validator,
    List<String> initialValue = const [], ValueChanged<List<String?>>? onChanged, Color colorSelected = Colors.blue,
    Color color = Colors.grey, Color colorText = Colors.white, }) : super(
      onSaved: onSaved,
      validator: validator,
      initialValue: initialValue,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (FormFieldState<List<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label!),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options.map<Widget>((opt) {
                if (state.value != initialValue) {
                  state.didChange(initialValue);
                }
                bool filled = false;
                if (state.value!.contains(opt['value'].toString())) {
                  filled = true;
                }
                return FilledButton(
                  child: Text(opt['label']),
                  onPressed: () {
                    var val = opt['value'].toString();
                    var newVal = state.value!;
                    if (!state.value!.contains(val)) {
                      newVal.add(val);
                    } else {
                      newVal.remove(val);
                    }
                    state.didChange(newVal);
                    if (onChanged != null) {
                      onChanged!(newVal);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: filled ? colorSelected : color,
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
