import 'dart:async';
//import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:flutter_multiselect/flutter_multiselect.dart';
import 'package:intl/intl.dart';
//import 'package:multi_select_flutter/multi_select_flutter.dart';

import './input_checkbox.dart';
import '../parse_service.dart';

class InputFields {
  InputFields._privateConstructor();
  static final InputFields _instance = InputFields._privateConstructor();
  factory InputFields() {
    return _instance;
  }

  ParseService _parseService = ParseService();

  Widget inputEmail(var formVals, String? formValsKey, { String label = 'Email',
    String hint = 'your@email.com', var fieldKey = null, bool required = false }) {
    String initialVal = '';
    if (formValsKey == null) {
      initialVal = formVals;
    } else {
      initialVal = (formVals.containsKey(formValsKey)) ? formVals[formValsKey] : '';
    }
    TextEditingController controller = new TextEditingController(text: initialVal);
    return TextFormField(
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
    );
  }

  Widget inputPassword(var formVals, String? formValsKey, { String label = 'Password',
    int minLen = -1, int maxLen = -1, var fieldKey = null, bool required = false }) {
    String initialVal = '';
    if (formValsKey == null) {
      initialVal = formVals;
    } else {
      initialVal = (formVals.containsKey(formValsKey)) ? formVals[formValsKey] : '';
    }
    TextEditingController controller = new TextEditingController(text: initialVal);
    return TextFormField(
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
    );
  }

  Widget inputText(var formVals, String? formValsKey, { String label = '', String hint = '',
    int minLen = -1, int maxLen = -1, var fieldKey = null, int maxLines = 1, int minLines = 1,
    int debounceChange = 1000, Function(String)? onChange = null, bool required = false}) {
    Timer? debounce = null;
    String initialVal = '';
    if (formValsKey == null) {
      initialVal = formVals;
    } else {
      initialVal = (formVals.containsKey(formValsKey)) ? formVals[formValsKey] : '';
    }
    TextEditingController controller = new TextEditingController(text: initialVal);
    return TextFormField(
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
        if (onChange != null) {
          if (debounceChange > 0) {
            if (debounce?.isActive ?? false) debounce?.cancel();
            debounce = Timer(Duration(milliseconds: debounceChange), () {
              if (formValsKey == null) {
                formVals = value;
              } else {
                formVals[formValsKey] = value;
              }
              onChange(value);
            });
          } else {
            if (formValsKey == null) {
              formVals = value;
            } else {
              formVals[formValsKey] = value;
            }
            onChange(value);
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
        } else {
          return validateMinMaxLen(value, minLen, maxLen);
        }
      },
      maxLines: maxLines,
      minLines: minLines,
    );
  }

  Widget inputNumber(var formVals, String? formValsKey, { String label = '', String hint = '',
    double? min = null, double? max = null, var fieldKey = null,
    int debounceChange = 1000, Function(double?)? onChange = null, bool required = false }) {
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
    return TextFormField(
      keyboardType: TextInputType.number,
      key: fieldKey,
      // initialValue sometimes does not work.. so need to use controller instead..
      //initialValue: initialVal,
      controller: controller,
      onSaved: (value) {
        if (formValsKey == null) {
          formVals = _parseService.toDouble(value, allowNull: true);
        } else {
          formVals[formValsKey] = _parseService.toDouble(value, allowNull: true);
        }
      },
      onChanged: (value) {
        if (onChange != null) {
          if (debounceChange > 0) {
            if (debounce?.isActive ?? false) debounce?.cancel();
            debounce = Timer(Duration(milliseconds: debounceChange), () {
              if (formValsKey == null) {
                formVals = _parseService.toDouble(value, allowNull: true);
              } else {
                formVals[formValsKey] = _parseService.toDouble(value, allowNull: true);
              }
              onChange(_parseService.toDouble(value, allowNull: true));
            });
          } else {
            if (formValsKey == null) {
              formVals = _parseService.toDouble(value, allowNull: true);
            } else {
              formVals[formValsKey] = _parseService.toDouble(value, allowNull: true);
            }
            onChange(_parseService.toDouble(value, allowNull: true));
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
    );
  }

  Widget inputDateTime(var formVals, String? formValsKey, { String label = '', String hint = '',
    String dateTimeMin = '', String dateTimeMax = '', String datetimeFormat = 'yyyy-MM-ddTHH:mm:ss',
    var fieldKey = null, int debounceChange = 1000, Function(String)? onChange = null, bool required = false }) {

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

    return TextFormField(
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
        if (onChange != null) {
          if (debounceChange > 0) {
            if (debounce?.isActive ?? false) debounce?.cancel();
            debounce = Timer(Duration(milliseconds: debounceChange), () {
              if (formValsKey == null) {
                formVals = value;
              } else {
                formVals[formValsKey] = value;
              }
              onChange(value);
            });
          } else {
            if (formValsKey == null) {
              formVals = value;
            } else {
              formVals[formValsKey] = value;
            }
            onChange(value);
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
    );
  }

  Widget inputCheckbox(var formVals, String formValsKey, { String label = '',
    var fieldKey = null }) {
    bool initialVal = false;
    if (formValsKey == null) {
      initialVal = formVals;
    } else {
      initialVal = (formVals.containsKey(formValsKey)) ? formVals[formValsKey] : false;
    }
    return CheckboxFormField(
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
      validator: (value) {
        return null;
      },
    );
  }

  Widget inputSelect(var options, var formVals, String? formValsKey, { String label = '',
    String hint = '', var fieldKey = null, bool required = false, onChanged = null }) {
    String? value = null;
    if (formValsKey == null) {
      value = formVals;
    } else {
      value = (formVals.containsKey(formValsKey)) ? formVals[formValsKey] : null;
    }
    return Container(
      child: DropdownButtonFormField(
        isExpanded: true,
        key: fieldKey,
        value: value,
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
            value: opt['value'],
            child: Text(opt['label']),
          );
        }).toList(),
      )
    );
  }

  Widget inputSelectSearch(var options, var context, var formVals, String? formValsKey, { String label = '',
    String hint = '', var fieldKey = null, bool required = false, onChanged = null, onKeyUp = null,
    int debounceChange = 1000 }) {
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
    return Row(
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
                  if (formValsKey == null) {
                    formVals = value;
                  } else {
                    formVals[formValsKey] = value;
                  }
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
    );
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

String? validateEmail(String? value) {
  if (value == null) {
    value = '';
  }
  String pattern =
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  RegExp regex = new RegExp(pattern);
  if (!regex.hasMatch(value))
    return 'Invalid email';
  else
    return null;
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
