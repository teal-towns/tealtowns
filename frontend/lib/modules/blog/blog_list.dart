import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/date_time_service.dart';
import '../../common/image_service.dart';
import '../../common/layout_service.dart';
import '../../common/link_service.dart';
import '../../common/paging.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import './blog_class.dart';
import './blog_state.dart';
import '../user_auth/current_user_state.dart';

class BlogList extends StatefulWidget {
  @override
  _BlogListState createState() => _BlogListState();
}

class _BlogListState extends State<BlogList> {
  Buttons _buttons = Buttons();
  DateTimeService _dateTime = DateTimeService();
  ImageService _imageService = ImageService();
  LayoutService _layoutService = LayoutService();
  LinkService _linkService = LinkService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  List<BlogClass> _blogs = [];
  Map<String, dynamic> _dataDefault = {};
  Map<String, Map<String, dynamic>> _filterFields = {
    'title': {},
  };

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('removeBlog', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        setState(() { _loading = false; });
      }
    }));
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column(children: [ LinearProgressIndicator() ]);
    }

    var currentUserState = context.watch<CurrentUserState>();

    List<Widget> columnsCreate = [];
    if (currentUserState.hasRole('admin') || currentUserState.hasRole('tealtownsTeam')) {
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
      listWrapper: true,
      body: Column(
        children: [
          // _style.Text1('Blog', size: 'large'),
          // SizedBox(height: 10,),
          ...columnsCreate,
          Paging(dataName: 'blogs', routeGet: 'getBlogs',
            dataDefault: _dataDefault, filterFields: _filterFields,
            onGet: (dynamic blogs) {
              _blogs = [];
              for (var item in blogs) {
                _blogs.add(BlogClass.fromJson(item));
              }
              setState(() { _blogs = _blogs; });
            },
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _layoutService.WrapWidth(_blogs.map((item) => OneBlog(item, context, currentUserState)).toList(), width: 300),
              ]
            ),
          )
        ]
      ) 
    );
  }

  Widget OneBlog(BlogClass blog, BuildContext context, var currentUserState) {
    var buttons = [];
    if (currentUserState.hasRole('admin')) {
      buttons = [
        TextButton(
          onPressed: () {
            Provider.of<BlogState>(context, listen: false).setBlog(blog);
            context.go('/blog-save');
          },
          child: Text('Edit'),
        ),
        SizedBox(width: 10),
        TextButton(
          onPressed: () {
            _socketService.emit('removeBlog', { 'id': blog.id });
            setState(() { _loading = true; });
          },
          child: Text('Delete'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
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
            style: Theme.of(context).textTheme.displayMedium,
          ),
          SizedBox(height: 5),
          //Text('Tags: ${blog.tags.join(', ')}'),
          //SizedBox(height: 5),
          Text(_dateTime.Format(blog.createdAt!, 'yyyy-MM-dd')),
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
                      h1: Theme.of(context).textTheme.displayLarge,
                      h2: Theme.of(context).textTheme.displayMedium,
                      h3: Theme.of(context).textTheme.displaySmall,
                      h4: Theme.of(context).textTheme.headlineMedium,
                      h5: Theme.of(context).textTheme.headlineSmall,
                      h6: Theme.of(context).textTheme.titleLarge,
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
              _buttons.LinkElevated(context, 'View', '/b/${blog.slug}', launchUrl: true),
              SizedBox(width: 10),
              ...buttons,
            ]
          ),
          SizedBox(height: 20),
        ]
      )
    );
  }
}