import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_scaffold.dart';
import '../../common/socket_service.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/form_input/image_save.dart';
import './blog_class.dart';
import './blog_state.dart';
import '../user_auth/current_user_state.dart';

class BlogSave extends StatefulWidget {
  @override
  _BlogSaveState createState() => _BlogSaveState();
}

class _BlogSaveState extends State<BlogSave> {
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  InputFields _inputFields = InputFields();

  final _formKey = GlobalKey<FormState>();
  var formVals = {};
  bool _loading = false;
  String _message = '';

  bool _loadedBlog = false;

  String _textPreview = '';

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('saveBlog', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        context.go('/blog');
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; });
      }
      setState(() { _loading = false; });
    }));

    if (!Provider.of<CurrentUserState>(context, listen: false).isLoggedIn) {
      Timer(Duration(milliseconds: 200), () {
        context.go('/blog');
      });
    }
  }

  Widget _buildSubmit(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: LinearProgressIndicator(
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: 15, bottom: 5),
      child: ElevatedButton(
        onPressed: () {
          _message = '';
          _loading = false;
          if (formValid()) {
            _loading = true;
            _formKey.currentState?.save();
            save();
          } else {
            _message = 'Please fill out all fields and try again.';
            //_autoValidate = true;
          }
          setState(() {
            _message = _message;
            _loading = _loading;
            //_autoValidate = _autoValidate;
          });
        },
        child: Text('Save Blog'),
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    if (_message.length > 0) {
      return Text(_message);
    }
    return SizedBox.shrink();
  }

  //static Future<List<TaggableOpt>> getTags(String value) async {
  //  await Future.delayed(Duration(milliseconds: 100), null);
  //  return [];
  //}

  @override
  Widget build(BuildContext context) {
    var blogState = context.watch<BlogState>();
    if (blogState.blog != null && !_loadedBlog) {
      _loadedBlog = true;
      setFormVals(blogState.blog);
    }

    //var selectOptsTag = [];

    return AppScaffoldComponent(
      listWrapper: true,
      width: 900,
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ImageSaveComponent(formVals: formVals, formValsKey: 'imageUrl', multiple: false,
              label: 'Image', imageUploadSimple: true, maxImageSize: 1200),
            SizedBox(height: 10),
            _inputFields.inputText(formVals, 'imageCredit', label: 'Image Credit', required: false),
            SizedBox(height: 20),
            _inputFields.inputText(formVals, 'title', label: 'Title', required: true),
            SizedBox(height: 10),
            //_inputFields.inputMultiSelectCreate(selectOptsTag, getTags, formVals, 'tags', label: 'Tags' ),
            //SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: _inputFields.inputText(formVals, 'text', label: 'Text (use Markdown for formatting)',
                    required: true, minLines: 50, maxLines: 50, debounceChange: 1000, onChange: (String text) {
                    setState(() {
                      _textPreview = formVals['text'];
                    });
                  }),
                ),
                SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: MarkdownBody(
                    data: _textPreview,
                    selectable: true,
                    onTapLink: (text, href, title) {
                      launch(href!);
                    },
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      h1: Theme.of(context).textTheme.displayLarge,
                      h2: Theme.of(context).textTheme.displayMedium,
                      h3: Theme.of(context).textTheme.displaySmall,
                      h4: Theme.of(context).textTheme.headlineMedium,
                      h5: Theme.of(context).textTheme.headlineSmall,
                      h6: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                )
              ]
            ),
            SizedBox(height: 10),
            _buildSubmit(context),
            _buildMessage(context),
            SizedBox(height: 50),
          ]
        ),
      ),
    );
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  void setFormVals(BlogClass blog) {
    formVals['_id'] = blog.id;
    formVals['title'] = blog.title;
    formVals['text'] = blog.text;
    formVals['imageUrl'] = blog.imageUrl;
    formVals['imageCredit'] = blog.imageCredit;
    //formVals['tags'] = blog.tags;
    formVals['tags'] = [];

    _textPreview = formVals['text'];
  }

  bool formValid() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    if (!formVals.containsKey('imageUrl') || formVals['imageUrl'].length < 1) {
      return false;
    }
    return true;
  }

  void save() {
    var data = {
      'blog': formVals,
    };
    _socketService.emit('saveBlog', data);
  }
}