import 'package:flutter/material.dart';

import './blog_class.dart';

class BlogState extends ChangeNotifier {
  var _blog = null;

  get blog => _blog;

  void setBlog(BlogClass blog) {
    _blog = blog;
    notifyListeners();
  }

  void clearBlog() {
    _blog = null;
    notifyListeners();
  }
}
