import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

import './modules/user_auth/current_user_state.dart';
import './routes.dart';

_launchURL(url) async {
  //const url = 'https://flutter.dev';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class AppScaffoldComponent extends StatefulWidget {
  Widget? body;
  double width;
  bool listWrapper;
  double innerWidth;
  bool selectableText;

  AppScaffoldComponent({this.body, this.width = 1200, this.listWrapper = false, this.innerWidth = double.infinity,
    this.selectableText = true,});

  @override
  _AppScaffoldState createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffoldComponent> {
  Widget _buildLinkButton(BuildContext context, String routePath, String label) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 1, color: Theme.of(context).primaryColor)),
      ),
      child: ListTile(
        //onPressed: () {
        onTap: () {
          //if (Scaffold.of(context).isEndDrawerOpen) {
          Navigator.of(context).pop();
          //}
          context.go(routePath);
        },
        //child: Text(label),
        title: Text(label, style: TextStyle( color: Theme.of(context).primaryColor )),
      ),
    );
  }

  Widget _buildUserButton(BuildContext context, currentUserState, { double width = 100, double fontSize = 13 }) {
    if (currentUserState.isLoggedIn) {
      return SizedBox.shrink();
    }
    return TextButton(
      onPressed: () {
        context.go(Routes.login);
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        minimumSize: Size.fromWidth(width),
        padding: EdgeInsets.all(0),
      ),
      child: Container(
        padding: EdgeInsets.only(top: 10),
        child: Column(
          children: <Widget>[
            Icon(Icons.person, color: Theme.of(context).primaryColor),
            Text(
              'Log In',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(context, currentUserState) {
    if (currentUserState.isLoggedIn) {
      return _buildLinkButton(context, '/logout', 'Logout (${currentUserState.currentUser.firstName} ${currentUserState.currentUser.lastName})');
    }
    return SizedBox.shrink();
  }

  Widget _buildNavButton(String route, String text, IconData icon, BuildContext context, { double width = 100, double fontSize = 13 }) {
    return TextButton(
      onPressed: () {
        context.go(route);
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        minimumSize: Size.fromWidth(width),
        padding: EdgeInsets.all(0),
      ),
      child: Container(
        padding: EdgeInsets.only(top: 10),
        child: Column(
          children: <Widget>[
            Icon(icon, color: Theme.of(context).primaryColor),
            Text(
              text,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerButton(BuildContext context, { double width = 100, double fontSize = 13 }) {
    return Builder(
      builder: (BuildContext context) {
        return TextButton(
          onPressed: () {
            Scaffold.of(context).openEndDrawer();
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: Size.fromWidth(width),
            padding: EdgeInsets.all(0),
          ),
          child: Container(
            padding: EdgeInsets.only(top: 10),
            child: Column(
              children: <Widget>[
                Icon(Icons.menu, color: Theme.of(context).primaryColor),
                Text(
                  'More',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: fontSize,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildDrawer(BuildContext context, var currentUserState) {
    List<Widget> columns = [
      _buildLinkButton(context, '/weekly-events', 'Events'),
      _buildLinkButton(context, '/neighborhoods', 'Neighborhoods'),
      _buildLinkButton(context, '/own', 'Shared Items'),
    ];
    if (currentUserState.isLoggedIn) {
      columns += [
        _buildLinkButton(context, '/user-money', 'Funds and Payments'),
        _buildLinkButton(context, '/user', 'User Profile'),
      ];
    }
    if (currentUserState.hasRole('admin')) {
    }
    // columns += [
    //   _buildLinkButton(context, '/about', 'About'),
    // ];
    Color footerColor = Colors.white;

    return Drawer(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Text(''),
              ),
              IconButton(
                icon: Icon(Icons.close),
                color: Theme.of(context).primaryColor,
                onPressed: () {
                  Navigator.of(context).pop();
                }
              ),
            ],
          ),
          ...columns,
          _buildLogoutButton(context, currentUserState),
          SizedBox(height: 30),
          // Text('Powered by Collobartive.Earth', style: TextStyle(color: Colors.white)),
          RichText( text: TextSpan(
            children: [
              TextSpan(
                text: 'About',
                style: TextStyle(color: footerColor),
                recognizer: TapGestureRecognizer()..onTap = () {
                  context.go('/about');
                },
              ),
              TextSpan(
                text: ' | ',
                style: TextStyle(color: footerColor),
              ),
              TextSpan(
                text: 'Blog',
                style: TextStyle(color: footerColor),
                recognizer: TapGestureRecognizer()..onTap = () {
                  context.go('/blog');
                },
              ),
              TextSpan(
                text: ' | ',
                style: TextStyle(color: footerColor),
              ),
              TextSpan(
                text: 'Team',
                style: TextStyle(color: footerColor),
                recognizer: TapGestureRecognizer()..onTap = () {
                  context.go('/team');
                },
              ),
            ]
          )),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, var currentUserState) {
    List<Widget> rows = [
      // Expanded(
      //   flex: 1,
      //   child: _buildNavButton('/home', 'Home', Icons.home, context, width: double.infinity, fontSize: 10),
      // ),
      // Expanded(
      //   flex: 1,
      //   child: _buildNavButton('/own', 'Own', Icons.build, context, width: double.infinity, fontSize: 10),
      // ),
      Expanded(
        flex: 1,
        child: _buildNavButton('/eat', 'Shared Meals', Icons.event, context, width: double.infinity, fontSize: 10),
      ),
    ];
    if (!currentUserState.isLoggedIn) {
      rows.add(Expanded(
        flex: 1,
        child: _buildUserButton(context, currentUserState, width: double.infinity, fontSize: 10),
      ));
    }
    rows.add(
      Expanded(
        flex: 1,
        child: _buildDrawerButton(context, width: double.infinity, fontSize: 10),
      ),
    );

    return SafeArea(
      child: Container(
        height: 55,
        child: Row(
          children: <Widget>[
            ...rows,
          ]
        ),
        color: Colors.white,
        // decoration: BoxDecoration(
        //   boxShadow: [
        //     BoxShadow(
        //       color: Colors.grey.shade300,
        //       spreadRadius: 2,
        //       blurRadius: 4,
        //       offset: Offset(0, 0),
        //     )
        //   ]
        // ),
      )
    );
  }

  Widget _buildBody(BuildContext context, var currentUserState, { bool header = false }) {
    Widget bodyContent = widget.body!;
    if (widget.listWrapper) {
      bodyContent = ListView(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: widget.innerWidth,
              padding: EdgeInsets.only(top: 20, left: 10, right: 10, bottom: 20),
              child: widget.body!,
            )
          )
        ]
      );
    }

    if (header) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeader(context, currentUserState),
          // For drop shadow, otherwise it is cut off.
          // SizedBox(height: 5),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: widget.width,
                  child: bodyContent,
                  color: Colors.white,
                )
              )
            )
          ),
        ]
      );
    }
    return Container(
      color: Colors.white,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: widget.width,
          child: bodyContent,
          color: Colors.white,
        )
      )
    );
  }

  Widget _buildSmall(BuildContext context, var currentUserState) {
    Widget content = Scaffold(
      endDrawer: _buildDrawer(context, currentUserState),
      body: _buildBody(context, currentUserState, header: true),
    );
    if (widget.selectableText) {
      return SelectionArea(
        child: content
      );
    }
    return content;
  }

  Widget _buildMedium(BuildContext context, var currentUserState) {
    Widget content = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Image.asset('assets/images/logo.png', width: 100, height: 50),
        actions: <Widget>[
          // _buildNavButton('/home', 'Home', Icons.home, context),
          // _buildNavButton('/own', 'Own', Icons.build, context),
          _buildNavButton('/eat', 'Shared Meals', Icons.event, context),
          _buildUserButton(context, currentUserState),
          _buildDrawerButton(context),
        ],
      ),
      endDrawer: _buildDrawer(context, currentUserState),
      body: _buildBody(context, currentUserState),
    );
    if (widget.selectableText) {
      return SelectionArea(
        child: content,
      );
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    var currentUserState = context.watch<CurrentUserState?>();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return _buildMedium(context, currentUserState);
        } else {
          return _buildSmall(context, currentUserState);
        }
      }
    );
  }
}
