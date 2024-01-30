import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_scaffold.dart';
import '../../common/image_service.dart';
import '../../common/socket_service.dart';
import '../../common/form_input/input_fields.dart';
import './blog_class.dart';
import './blog_state.dart';
import '../user_auth/current_user_state.dart';

class BlogList extends StatefulWidget {
  @override
  _BlogListState createState() => _BlogListState();
}

class _BlogListState extends State<BlogList> {
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  ImageService _imageService = ImageService();
  InputFields _inputFields = InputFields();

  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;
  var filters = {
    'title': '',
    'tags': '',
  };
  bool _loading = false;
  String _message = '';
  bool _canLoadMore = false;
  int _lastPageNumber = 1;
  int _itemsPerPage = 25;

  List<BlogClass> _blogs = [];
  bool _firstLoadDone = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('getBlogs', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data.containsKey('blogs')) {
          _blogs = [];
          for (var blog in data['blogs']) {
            _blogs.add(BlogClass.fromJson(blog));
          }
          if (_blogs.length == 0) {
            _message = 'No results found.';
          }
        } else {
          _message = 'Error.';
        }
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
      }
      setState(() {
        _loading = false;
        _message = _message;
        _blogs = _blogs;
      });
    }));

    _routeIds.add(_socketService.onRoute('removeBlog', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _getBlogs();
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
      }
      setState(() {
        _loading = false;
        _message = _message;
      });
    }));
  }

  Widget _buildMessage(BuildContext context) {
    if (_message.length > 0) {
      return Container(
        padding: EdgeInsets.only(top: 20, bottom: 20, left: 10, right: 10),
        child: Text(_message),
      );
    }
    return SizedBox.shrink();
  }

  _buildBlog(BlogClass blog, BuildContext context, var currentUserState) {
    var buttons = [];
    if (currentUserState.hasRole('admin')) {
      buttons = [
        ElevatedButton(
          onPressed: () {
            Provider.of<BlogState>(context, listen: false).setBlog(blog);
            context.go('/blog-save');
          },
          child: Text('Edit'),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            _socketService.emit('removeBlog', { 'id': blog.id });
          },
          child: Text('Delete'),
          style: ElevatedButton.styleFrom(
            primary: Theme.of(context).errorColor,
          ),
        ),
      ];
    }
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Image.network(_imageService.GetUrl(blog.imageUrl!), height: 300, width: double.infinity, fit: BoxFit.cover),
          SizedBox(height: 5),
          Text(blog.title!,
            style: Theme.of(context).textTheme.headline2,
          ),
          SizedBox(height: 5),
          //Text('Tags: ${blog.tags.join(', ')}'),
          //SizedBox(height: 5),
          Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(blog.createdAt!))),
          SizedBox(height: 10),
          ClipRect(
            child: Container(
              height: 160,
              child: Wrap(
                children: [
                  MarkdownBody(
                    selectable: true,
                    data: blog.text!,
                    onTapLink: (text, href, title) {
                      launch(href!);
                    },
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      h1: Theme.of(context).textTheme.headline1,
                      h2: Theme.of(context).textTheme.headline2,
                      h3: Theme.of(context).textTheme.headline3,
                      h4: Theme.of(context).textTheme.headline4,
                      h5: Theme.of(context).textTheme.headline5,
                      h6: Theme.of(context).textTheme.headline6,
                    ),
                  )
                ]
              )
            )
          ),
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  context.go('/b/${blog.slug}');
                },
                child: Text('View'),
              ),
              SizedBox(width: 10),
              ...buttons,
            ]
          ),
          SizedBox(height: 20),
        ]
      )
    );
  }

  _buildBlogResults(BuildContext context, var currentUserState) {
    if (_blogs.length > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: <Widget> [
              ..._blogs.map((blog) => _buildBlog(blog, context, currentUserState) ).toList(),
            ]
          ),
        ]
      );
    }
    return _buildMessage(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!_firstLoadDone) {
      _firstLoadDone = true;
      _getBlogs();
    }

    var currentUserState = context.watch<CurrentUserState>();

    var columnsCreate = [];
    if (currentUserState.hasRole('admin')) {
      columnsCreate = [
        Align(
          alignment: Alignment.topRight,
          child: ElevatedButton(
            onPressed: () {
              Provider.of<BlogState>(context, listen: false).clearBlog();
              context.go('/blog-save');
            },
            child: Text('Create New Blog'),
          ),
        ),
        SizedBox(height: 10),
      ];
    }

    return AppScaffoldComponent(
      body: ListView(
        children: <Widget> [
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.only(top: 20, bottom: 30, left: 10, right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ...columnsCreate,
                  Align(
                    alignment: Alignment.center,
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: 200,
                            child: _inputFields.inputText(filters, 'title', hint: 'title',
                              label: 'Filter by Title', debounceChange: 1000, onChange: (String val) {
                              _getBlogs();
                            }),
                          ),
                          //SizedBox(width: 10),
                          //SizedBox(width: 200,
                          //  child: _inputFields.inputText(filters, 'tags', hint: 'tag',
                          //    label: 'Filter by Tag', debounceChange: 1000, onChange: (String val) {
                          //    _getBlogs();
                          //  }),
                          //),
                          //_buildSubmit(context),
                        ]
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: _buildBlogResults(context, currentUserState),
                  ),
                ]
              )
            ),
          )
        ]
      )
    );
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  void _getBlogs({int lastPageNumber = 0}) {
    setState(() {
      _loading = true;
      _message = '';
      _canLoadMore = false;
    });
    if (lastPageNumber != 0) {
      _lastPageNumber = lastPageNumber;
    } else {
      _lastPageNumber = 1;
    }
    var data = {
      //'page': _lastPageNumber,
      'skip': (_lastPageNumber - 1) * _itemsPerPage,
      'limit': _itemsPerPage,
      'sortKey': '-createdAt',
      'tags': [],
    };
    if (filters['title'] != '') {
      data['title'] = filters['title']!;
    }
    if (filters['tags'] != '') {
      data['tags'] = [ filters['tags'] ];
    }
    _socketService.emit('getBlogs', data);
  }
}