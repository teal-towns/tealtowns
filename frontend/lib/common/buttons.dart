import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './colors_service.dart';
import './link_service.dart';
import './track_insight_service.dart';

class Buttons {
  Buttons._privateConstructor();
  static final Buttons _instance = Buttons._privateConstructor();
  factory Buttons() {
    return _instance;
  }

  ColorsService _colors = ColorsService();
  LinkService _linkService = LinkService();
  TrackInsightService _trackInsightService = TrackInsightService();

  Widget Link(BuildContext context, String text, String url, {bool checkLoggedIn = false, bool launchUrl = false,
    String colorBackground = 'transparent', String colorText = 'primary', bool track = false}) {
    return TextButton(
      onPressed: () {
        OnPress(context, url, checkLoggedIn: checkLoggedIn, launchUrl: launchUrl, track: track, trackEvent: text);
      },
      style: TextButton.styleFrom(
        backgroundColor: _colors.colors[colorBackground],
        foregroundColor: _colors.colors[colorText],
      ),
      child: Text(text),
    );
  }

  Widget LinkElevated(BuildContext context, String text, String url, {bool checkLoggedIn = false, bool launchUrl = false,
    bool track = false}) {
    return ElevatedButton(
      onPressed: () {
        OnPress(context, url, checkLoggedIn: checkLoggedIn, launchUrl: launchUrl, track: track, trackEvent: text);
      },
      child: Text(text),
    );
  }

  Widget LinkInline(BuildContext context, String text, String url, {bool checkLoggedIn = false, bool launchUrl = false,
    String colorText = 'primary', bool track = false}) {
    return InkWell(
      onTap: () {
        OnPress(context, url, checkLoggedIn: checkLoggedIn, launchUrl: launchUrl, track: track, trackEvent: text);
      },
      child: Text(text, style: TextStyle( color: _colors.colors[colorText] )),
    );
  }

  Widget LinkIcon(BuildContext context, IconData icon, String url, {bool checkLoggedIn = false, bool launchUrl = false,
    String color = 'primary', bool track = false, String trackEvent = ''}) {
    return IconButton(
      icon: Icon(icon, color: _colors.colors[color]),
      onPressed: () {
        OnPress(context, url, checkLoggedIn: checkLoggedIn, launchUrl: launchUrl, track: track, trackEvent: trackEvent);
      },
    );
  }

  void OnPress(BuildContext context, String url, {bool checkLoggedIn = false, bool launchUrl = false,
    bool track = false, String trackEvent = ''}) {
    if (launchUrl) {
      _linkService.LaunchURL(url);
    } else {
      if (checkLoggedIn) {
        _linkService.Go(url, context);
      } else {
        context.go(url);
      }
    }
    if (track) {
      _trackInsightService.TrackEvent(trackEvent);
    }
  }
}
