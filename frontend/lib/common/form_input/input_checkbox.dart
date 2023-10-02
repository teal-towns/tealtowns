import 'package:flutter/material.dart';

class CheckboxFormField extends FormField<bool> {
  CheckboxFormField({ Widget? title, FormFieldSetter<bool>? onSaved, FormFieldValidator<bool>? validator,
    bool initialValue = false }) : super(
      onSaved: onSaved,
      validator: validator,
      initialValue: initialValue,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (FormFieldState<bool> state) {
        return CheckboxListTile(
          dense: state.hasError,
          title: title,
          value: state.value,
          onChanged: state.didChange,
          subtitle: state.hasError ? Builder(
              builder: (BuildContext context) =>  Text(
                state.errorText ?? '',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ) : null,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.all(0),
          //activeColor: Theme.of(context).primaryColor,
        );
      }
    );
}
