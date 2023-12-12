import 'package:flutter/material.dart';

import './shared_item_class.dart';

class SharedItemState extends ChangeNotifier {
  var _sharedItem = null;

  get sharedItem => _sharedItem;

  void setSharedItem(SharedItemClass sharedItem) {
    _sharedItem = sharedItem;
    notifyListeners();
  }

  void clearSharedItem() {
    _sharedItem = null;
    notifyListeners();
  }
}
