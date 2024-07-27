import 'dart:async';
//import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:flutter_multiselect/flutter_multiselect.dart';
import 'package:intl/intl.dart';
//import 'package:multi_select_flutter/multi_select_flutter.dart';

import './input_checkbox.dart';
import './input_select_buttons.dart';
import './input_multi_select_buttons.dart';
import '../colors_service.dart';
import '../parse_service.dart';

class InputFields {
  InputFields._privateConstructor();
  static final InputFields _instance = InputFields._privateConstructor();
  factory InputFields() {
    return _instance;
  }

  ColorsService _colors = ColorsService();
  ParseService _parseService = ParseService();

  Widget inputEmail(var formVals, String? formValsKey, { String label = 'Email',
    String hint = 'your@email.com', var fieldKey = null, bool required = false,
    String helpText = '', }) {
    String initialVal = '';
    if (formValsKey == null) {
      initialVal = formVals;
    } else {
      initialVal = (formVals.containsKey(formValsKey)) ? formVals[formValsKey] : '';
    }
    TextEditingController controller = new TextEditingController(text: initialVal);
    return InputWrapper(TextFormField(
      key: fieldKey,
      //initialValue: initialVal,
      controller: controller,
      onSaved: (value) {
        if (formValsKey == null) {
          formVals = value;
        } else {
          formVals[formValsKey] = value;
        }
      },
      onChanged: (value) {
        if (formValsKey == null) {
          formVals = value;
        } else {
          formVals[formValsKey] = value;
        }
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (required && value?.isEmpty == true) {
          return 'Required';
        } else {
          return validateEmail(value);
        }
      }
    ), helpText: helpText);
  }

  Widget inputPassword(var formVals, String? formValsKey, { String label = 'Password',
    int minLen = -1, int maxLen = -1, var fieldKey = null, bool required = false,
    String helpText = '', }) {
    String initialVal = '';
    if (formValsKey == null) {
      initialVal = formVals;
    } else {
      initialVal = (formVals.containsKey(formValsKey)) ? formVals[formValsKey] : '';
    }
    TextEditingController controller = new TextEditingController(text: initialVal);
    return InputWrapper(TextFormField(
      key: fieldKey,
      //initialValue: initialVal,
      controller: controller,
      onSaved: (value) {
        if (formValsKey == null) {
          formVals = value;
        } else {
          formVals[formValsKey] = value;
        }
      },
      onChanged: (value) {
        if (formValsKey == null) {
          formVals = value;
        } else {
          formVals[formValsKey] = value;
        }
      },
      decoration: InputDecoration(
        labelText: label,
        //hintText: '',
      ),
      obscureText: true,
      validator: (value) {
        if (required && value?.isEmpty == true) {
          return 'Required';
        } else {
          return validateMinMaxLen(value, minLen, maxLen);
        }
      },
    ), helpText: helpText);
  }

  Widget inputText(var formVals, String? formValsKey, { String label = '', String hint = '',
    int minLen = -1, int maxLen = -1, var fieldKey = null, int maxLines = 1, int minLines = 1,
    int debounceChange = 1000, Function(String)? onChanged = null, bool required = false,
    Function()? onTap = null, RegExp? pattern = null, String helpText = '', }) {
    Timer? debounce = null;
    String initialVal = '';
    if (maxLines < minLines) {
      maxLines = minLines;
    }
    if (formValsKey == null) {
      initialVal = formVals;
    } else {
      initialVal = (formVals.containsKey(formValsKey)) ? formVals[formValsKey] : '';
    }
    TextEditingController controller = new TextEditingController(text: initialVal);
    return InputWrapper(TextFormField(
      key: fieldKey,
      // initialValue sometimes does not work.. so need to use controller instead..
      //initialValue: initialVal,
      controller: controller,
      onSaved: (value) {
        if (formValsKey == null) {
          formVals = value;
        } else {
          formVals[formValsKey] = value;
        }
      },
      //onEditingComplete: () { print ('onEditingComplete ${controller.text}'); },
      onChanged: (value) {
        if (formValsKey == null) {
          formVals = value;
        } else {
          formVals[formValsKey] = value;
        }
        if (onChanged != null) {
          if (debounceChange > 0) {
            if (debounce?.isActive ?? false) debounce?.cancel();
            debounce = Timer(Duration(milliseconds: debounceChange), () {
              if (formValsKey == null) {
                formVals = value;
              } else {
                formVals[formValsKey] = value;
              }
              onChanged(value);
            });
          } else {
            onChanged(value);
          }
        }
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        focusColor: _colors.colors['primary'],
        hoverColor: _colors.colors['primary'],
      ),
      validator: (value) {
        if (required && value?.isEmpty == true) {
          return 'Required';
        } else {
          if (pattern != null && !validatePattern(value, pattern!)) {
            return 'Invalid pattern';
          }
          return validateMinMaxLen(value, minLen, maxLen);
        }
      },
      maxLines: maxLines,
      minLines: minLines,
      onTap: onTap,
    ), helpText: helpText);
  }

  Widget inputNumber(var formVals, String? formValsKey, { String label = '', String hint = '',
    double? min = null, double? max = null, var fieldKey = null,
    int debounceChange = 1000, Function(double?)? onChanged = null, bool required = false,
    String helpText = '', }) {
    Timer? debounce = null;
    String initialVal = '';
    if (formValsKey == null) {
      initialVal = formVals == null ? '' : formVals.toString();
    } else {
      initialVal = (formVals.containsKey(formValsKey)) ? formVals[formValsKey].toString() : '';
    }
    if (initialVal == 'null') {
      initialVal = '';
    }
    TextEditingController controller = new TextEditingController(text: initialVal);
    return InputWrapper(TextFormField(
      keyboardType: TextInputType.number,
      key: fieldKey,
      // initialValue sometimes does not work.. so need to use controller instead..
      //initialValue: initialVal,
      controller: controller,
      onSaved: (value) {
        double? val = ForceMinMax(_parseService.toDouble(value, allowNull: true), min, max);
        if (formValsKey == null) {
          formVals = val;
        } else {
          formVals[formValsKey] = val;
        }
      },
      onChanged: (value) {
        double? val = ForceMinMax(_parseService.toDouble(value, allowNull: true), min, max);
        if (formValsKey == null) {
          formVals = val;
        } else {
          formVals[formValsKey] = val;
        }
        if (onChanged != null) {
          if (debounceChange > 0) {
            if (debounce?.isActive ?? false) debounce?.cancel();
            debounce = Timer(Duration(milliseconds: debounceChange), () {
              if (formValsKey == null) {
                formVals = val;
              } else {
                formVals[formValsKey] = val;
              }
              onChanged(val);
            });
          } else {
            onChanged(val);
          }
        }
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: (value) {
        if (required && value?.isEmpty == true) {
          return 'Required';
        } else if (value?.isEmpty == false) {
          return validateMinMax(_parseService.toDoubleNoNull(value), min, max);
        } else {
          return null;
        }
      },
    ), helpText: helpText);
  }

  Widget inputTime(var formVals, String? formValsKey, { String label = '', String hint = '',
    var fieldKey = null, int debounceChange = 1000, Function(String)? onChanged = null, bool required = false,
    Function()? onTap = null, String helpText = '',}) {
    RegExp pattern = new RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return inputText(formVals, formValsKey, label: label, hint: hint, fieldKey: fieldKey,
      debounceChange: debounceChange, required: required, onTap: onTap, helpText: helpText,
      pattern: pattern, onChanged: (value) {
        // Ensure leading zero for hour for sorting.
        int posColon = value.indexOf(':');
        if (posColon == 1) {
          value = "0" + value;
        }
        if (formValsKey == null) {
          formVals = value;
        } else {
          formVals[formValsKey] = value;
        }
        if (onChanged != null) {
          onChanged(value);
        }
      });
  }

  Widget inputDateTime(var formVals, String? formValsKey, { String label = '', String hint = '',
    String dateTimeMin = '', String dateTimeMax = '', String datetimeFormat = 'yyyy-MM-ddTHH:mm:ss',
    var fieldKey = null, int debounceChange = 1000, Function(String)? onChanged = null,
    bool required = false, String helpText = '', }) {

    DateTime now = new DateTime.now();
    DateTime firstDate = now.subtract(new Duration(days: 365 * 5));
    DateTime lastDate = now.add(new Duration(days: 365 * 5));
    if (dateTimeMin != '') {
      firstDate = DateTime.parse(dateTimeMin);
    }
    if (dateTimeMax != '') {
      lastDate = DateTime.parse(dateTimeMax);
    }

    Timer? debounce = null;

    String initialVal = '';
    if (formValsKey == null) {
      initialVal = formVals;
    } else {
      initialVal = (formVals.containsKey(formValsKey)) ? formVals[formValsKey] : DateFormat(datetimeFormat).format(now);
    }
    TextEditingController controller = new TextEditingController(text: initialVal);

    return InputWrapper(TextFormField(
      key: fieldKey,
      //initialValue: initialVal,
      controller: controller,
      onSaved: (value) {
        if (formValsKey == null) {
          formVals = value;
        } else {
          formVals[formValsKey] = value;
        }
      },
      //onEditingComplete: () { print ('onEditingComplete ${controller.text}'); },
      onChanged: (value) {
        if (formValsKey == null) {
          formVals = value;
        } else {
          formVals[formValsKey] = value;
        }
        if (onChanged != null) {
          if (debounceChange > 0) {
            if (debounce?.isActive ?? false) debounce?.cancel();
            debounce = Timer(Duration(milliseconds: debounceChange), () {
              if (formValsKey == null) {
                formVals = value;
              } else {
                formVals[formValsKey] = value;
              }
              onChanged(value);
            });
          } else {
            onChanged(value);
          }
        }
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: (value) {
        if (required && value?.isEmpty == true) {
          return 'Required';
        }
        return null;
      },
    ), helpText: helpText);
  }

  // TODO: fix: currently the outer component must use onChanged to set state, otherwise the checkbox will not toggle..
  Widget inputCheckbox(var formVals, String formValsKey, { String label = '',
    var fieldKey = null, String helpText = '', Function(bool)? onChanged = null}) {
    bool initialVal = false;
    if (formValsKey == null) {
      initialVal = formVals;
    } else {
      initialVal = (formVals.containsKey(formValsKey)) ? formVals[formValsKey] : false;
    }
    return InputWrapper(CheckboxFormField(
      title: Text(label),
      initialValue: initialVal,
      //key: fieldKey,
      onSaved: (value) {
        if (formValsKey == null) {
          formVals = value;
        } else {
          formVals[formValsKey] = value;
        }
      },
      onChanged: (value) {
        if (formValsKey == null) {
          formVals = value;
        } else {
          formVals[formValsKey] = value;
        }
        if (onChanged != null) {
          onChanged(value!);
        }
      },
      validator: (value) {
        return null;
      },
    ), helpText: helpText);
  }

  Widget inputSelect(var options, var formVals, String? formValsKey, { String label = '',
    String hint = '', var fieldKey = null, bool required = false, onChanged = null, String helpText = '', }) {
    String? value = null;
    if (formValsKey == null) {
      value = formVals;
    } else {
      value = (formVals.containsKey(formValsKey)) ? formVals[formValsKey].toString() : null;
    }
    if (options.length < 1) {
      // print ('No options for inputSelect ${formValsKey} ${value}');
      return SizedBox.shrink();
    } else {
      bool found = false;
      for (int i = 0; i < options.length; i++) {
        if (options[i]['value'].toString() == value) {
          found = true;
          break;
        }
      }
      if (!found) {
        value = null;
      }
    }
    return InputWrapper(Container(
      child: DropdownButtonFormField(
        isExpanded: true,
        key: fieldKey,
        value: value,
        dropdownColor: Colors.white,
        onSaved: (value) {
          if (formValsKey == null) {
            formVals = value;
          } else {
            formVals[formValsKey] = value;
          }
        },
        //hint: Text(hint),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
        validator: (String? value) {
          if (required && value?.isEmpty == true) {
            return 'Please select one';
          }
          return null;
        },
        onChanged: (newVal) {
          if (formValsKey == null) {
            formVals = newVal;
          } else {
            formVals[formValsKey] = newVal;
          }
          if (onChanged != null) {
            onChanged(newVal);
          }
        },
        items: options.map<DropdownMenuItem<String>>((opt) {
          return DropdownMenuItem<String>(
            value: opt['value'].toString(),
            child: Text(opt['label']),
          );
        }).toList(),
      )
    ), helpText: helpText);
  }

  Widget inputSelectButtons(var options, var formVals, String? formValsKey, { String label = '',
    String hint = '', var fieldKey = null, bool required = false, onChanged = null, String helpText = '',}) {
    String value = '';
    if (formValsKey == null) {
      value = formVals;
    } else {
      value = (formVals.containsKey(formValsKey)) ? formVals[formValsKey].toString() : '';
    }
    if (options.length < 1) {
      return SizedBox.shrink();
    }
    return InputWrapper(SelectButtonsFormField(
      options: options,
      colorSelected: _colors.colors['secondary'],
      color: _colors.colors['greyLight'],
      colorText: _colors.colors['brown'],
      label: label,
      initialValue: value,
      onSaved: (value) {
        if (formValsKey == null) {
          formVals = value;
        } else {
          formVals[formValsKey] = value;
        }
      },
      onChanged: (value) {
        if (formValsKey == null) {
          formVals = value;
        } else {
          formVals[formValsKey] = value;
        }
        if (onChanged != null) {
          onChanged(value!);
        }
      },
      validator: (value) {
        if (required && value?.isEmpty == true) {
          return 'Please select one';
        }
        return null;
      },
    ), helpText: helpText);
  }

  Widget inputMultiSelectButtons(var options, var formVals, String? formValsKey, { String label = '',
    String hint = '', var fieldKey = null, bool required = false, onChanged = null, String helpText = '',}) {
    List<String> values = [];
    if (formValsKey == null) {
      values = formVals;
    } else {
      values = (formVals.containsKey(formValsKey)) ? formVals[formValsKey] : [];
    }
    if (options.length < 1) {
      return SizedBox.shrink();
    }
    return InputWrapper(MultiSelectButtonsFormField(
      options: options,
      colorSelected: _colors.colors['secondary'],
      color: _colors.colors['greyLight'],
      colorText: _colors.colors['brown'],
      label: label,
      initialValue: values,
      onSaved: (values) {
        if (formValsKey == null) {
          formVals = values;
        } else {
          formVals[formValsKey] = values;
        }
      },
      onChanged: (values) {
        if (formValsKey == null) {
          formVals = values;
        } else {
          formVals[formValsKey] = values;
        }
        if (onChanged != null) {
          onChanged(values!);
        }
      },
      validator: (values) {
        if (required && values!.length < 1) {
          return 'Please select at least one';
        }
        return null;
      },
    ), helpText: helpText);
  }

  Widget inputSelectSearch(var options, var context, var formVals, String? formValsKey, { String label = '',
    String hint = '', var fieldKey = null, bool required = false, onChanged = null, onKeyUp = null,
    int debounceChange = 1000, String helpText = '', }) {
    Timer? debounce = null;
    String initialVal = '';
    if (formValsKey == null) {
      initialVal = formVals;
    } else {
      initialVal = (formVals.containsKey(formValsKey)) ? formVals[formValsKey] : '';
    }
    TextEditingController controller = new TextEditingController(text: initialVal);
    //String? value = null;
    //if (formValsKey == null) {
    //  value = formVals;
    //} else {
    //  value = (formVals.containsKey(formValsKey)) ? formVals[formValsKey] : null;
    //}
    List<PopupMenuEntry<dynamic>> items = [];
    for (int ii = 0; ii < options.length; ii++) {
      items.add(PopupMenuItem( value: options[ii]['value'], child: Text(options[ii]['label']) ) );
    }
    return InputWrapper(Row(
      children: [
        //DropdownButtonFormField(
        //  key: fieldKey,
        //  value: value,
        //  onSaved: (value) {
        //    if (formValsKey == null) {
        //      formVals = value;
        //    } else {
        //      formVals[formValsKey] = value;
        //    }
        //  },
        //  //hint: Text(hint),
        //  decoration: InputDecoration(
        //    labelText: label,
        //    hintText: hint,
        //  ),
        //  validator: (String? value) {
        //    if (required && value?.isEmpty == true) {
        //      return 'Please select one';
        //    }
        //    return null;
        //  },
        //  onChanged: (newVal) {
        //    if (formValsKey == null) {
        //      formVals = newVal;
        //    } else {
        //      formVals[formValsKey] = newVal;
        //    }
        //    if (onChanged != null) {
        //      onChanged(newVal);
        //    }
        //  },
        //  items: options.map<DropdownMenuItem<String>>((opt) {
        //    return DropdownMenuItem<String>(
        //      value: opt['value'],
        //      child: Text(opt['label']),
        //    );
        //  }).toList(),
        //),
        Expanded(
          flex: 1,
          //padding: EdgeInsets.only(right: 45),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              //labelText: label,
              hintText: hint,
            ),
            onChanged: (value) {
              if (formValsKey == null) {
                formVals = value;
              } else {
                formVals[formValsKey] = value;
              }
              if (onKeyUp != null) {
                if (debounceChange > 0) {
                  if (debounce?.isActive ?? false) debounce?.cancel();
                  debounce = Timer(Duration(milliseconds: debounceChange), () {
                    if (formValsKey == null) {
                      formVals = value;
                    } else {
                      formVals[formValsKey] = value;
                    }
                    onKeyUp(value);
                  });
                } else {
                  onKeyUp(value);
                }
              }
            },
          ),
        ),
        Container(
          width: 45,
          child: PopupMenuButton(
            //initialValue: selectedMenu,
            onSelected: (var value) {
              if (formValsKey == null) {
                formVals = value;
              } else {
                formVals[formValsKey] = value;
              }
              if (onChanged != null) {
                onChanged(value);
              }
            },
            itemBuilder: (BuildContext context) => items,
            icon: Icon(Icons.expand_more),
          ),
        ),
      ]
    ), helpText: helpText);
  }

  // TODO - fix lint errors
  //Widget inputMultiSelect(var options, BuildContext context, var formVals, String formValsKey, { String label = '',
  //  String hint = '', var fieldKey = null, bool required = false, bool scroll = false }) {
  //  List<MultiSelectItem<dynamic>> items = options.map<MultiSelectItem<dynamic>>((opt) => MultiSelectItem(opt, opt['label'])).toList();
  //  var values = [];
  //  if (formVals.containsKey(formValsKey)) {
  //    for (var opt in options) {
  //      if (formValsKey == null) {
  //        if (formVals.contains(opt['value'])) {
  //          values.add(opt);
  //        }
  //      } else {
  //        if (formVals[formValsKey].contains(opt['value'])) {
  //          values.add(opt);
  //        }
  //      }
  //    }
  //  }
  //  return Column(
  //    crossAxisAlignment: CrossAxisAlignment.start,
  //    children: <Widget>[
  //      SizedBox(height: 5),
  //      Text(label, style: Theme.of(context).textTheme.subtitle1),
  //      MultiSelectChipField(
  //        key: fieldKey,
  //        initialValue: values,
  //        onSaved: (items) {
  //          if (items != null) {
  //            if (formValsKey == null) {
  //              formVals = items.map((item) => item['value'] ).toList();
  //            } else {
  //              formVals[formValsKey] = items.map((item) => item['value'] ).toList();
  //            }
  //          } else {
  //            if (formValsKey == null) {
  //              formVals = [];
  //            } else {
  //              formVals[formValsKey] = [];
  //            }
  //          }
  //        },
  //        validator: (values) {
  //          if (required && (values == null || values?.isEmpty == true)) {
  //            return 'Select at least one';
  //          }
  //          return null;
  //        },
  //        items: items,
  //        //title: Text(label),
  //        //headerColor: Colors.transparent,
  //        showHeader: false,
  //        decoration: BoxDecoration(
  //          border: Border.all(width: 0),
  //        ),
  //        //icon: Icon(Icons.check),
  //        //height: 40,
  //        scroll: scroll,
  //      ),
  //      SizedBox(height: 5),
  //    ]
  //  );
  //}

}

Widget InputWrapper(Widget child, { String helpText = '', }) {
  if (helpText != '') {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(helpText),
        SizedBox(height: 5),
        child,
      ]
    );
  }
  // return child;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      child,
    ]
  );
}

String? validateEmail(String? value) {
  RegExp pattern = new RegExp(r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
  if (!validatePattern(value, pattern)) {
    return 'Invalid email';
  }
  return null;
}


bool validatePattern(String? value, RegExp regex) {
  if (value == null) {
    value = '';
  }
  // pattern = r'${pattern}';
  // RegExp regex = new RegExp(pattern);
  if (!regex.hasMatch(value)) {
    return false;
  }
  return true;
}

String? validateMinMaxLen(String? value, int? minLen, int? maxLen) {
  if (value == null) {
    value = '';
  }
  if (minLen == null) {
    minLen = -1;
  }
  if (maxLen == null) {
    maxLen = -1;
  }
  if (minLen > -1 && value.length < minLen) {
    return 'Min ${minLen} characters';
  } else if (maxLen > -1 && value.length > maxLen) {
    return 'Max ${maxLen} characters';
  }
  return null;
}

String? validateMinMax(double value, double? min, double? max) {
  if (min != null && value < min) {
    return 'Must be at least ${min}';
  } else if (max != null && value > max) {
    return 'Must be less than ${max}';
  }
  return null;
}

double? ForceMinMax(double? value, double? min, double? max) {
  if (value == null) {
    return value;
  }
  if (min != null && value < min) {
    return min;
  } else if (max != null && value > max) {
    return max;
  }
  return value;
}
