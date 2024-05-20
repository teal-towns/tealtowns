import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import './modules/home.dart';
import './modules/route_not_found.dart';
import './modules/user_auth/user_email_verify.dart';
import './modules/user_auth/user_login.dart';
import './modules/user_auth/user_logout.dart';
import './modules/user_auth/user_password_reset.dart';
import './modules/user_auth/user_signup.dart';
import './modules/user_auth/user.dart';

import './modules/design_library/design_library.dart';

import './modules/about/about.dart';
import './modules/about/team.dart';
import './modules/about/privacy_terms.dart';

import './modules/blog/blog_list.dart';
import './modules/blog/blog_save.dart';
import './modules/blog/blog_view.dart';

import './modules/event/weekly_events.dart';
import './modules/event/weekly_event_save.dart';
import './modules/event/weekly_event_view.dart';
import './modules/event/event_feedback_save_page.dart';

import './modules/land/land_page.dart';

import './modules/neighborhood/neighborhood.dart';
import './modules/neighborhood/neighborhoods_page.dart';
import './modules/neighborhood/neighborhood_save.dart';
import './modules/neighborhood/belonging_survey.dart';
import './modules/neighborhood/neighborhood_journey_page.dart';

import './modules/shared_item/shared_items.dart';
import './modules/shared_item/shared_item_save.dart';
import './modules/shared_item/shared_item_owner_save.dart';

import './modules/user_payment/user_money.dart';

import './modules/user_auth/current_user_state.dart';

class Routes {
  static const home = '/home';
  static const notFound = '/route-not-found';
  static const emailVerify = '/email-verify';
  static const login = '/login';
  static const logout = '/logout';
  static const passwordReset = '/password-reset';
  static const signup = '/signup';

  static const designLibrary = '/design-library';

  static const user = '/user';
  static const userUsername = '/u/:username';

  static const about = '/about';
  static const team = '/team'; 
  static const privacyPolicy = '/privacy-policy';
  static const termsOfService = '/terms-of-service';

  static const blogList = '/blog';
  static const blogSave = '/blog-save';
  static const blogView = '/b/:slug';

  static const weeklyEvents = '/weekly-events';
  static const weeklyEventSave = '/weekly-event-save';
  static const weeklyEventView = '/we/:uName';
  static const eat = '/eat';
  static const eventFeedbackSave = '/event-feedback';

  static const land = '/land';

  static const neighborhoodSave = '/neighborhood-save';
  static const neighborhoodView = '/n/:uName';
  static const neighborhoods = '/neighborhoods';
  static const neighborhoodJourney = '/neighborhood-journey';
  static const belongingSurvey = '/belonging-survey';

  static const sharedItems = '/own';
  static const sharedItemSave = '/shared-item-save';
  static const sharedItemOwnerSave = '/shared-item-owner-save';

  static const userMoney = '/user-money';
}

class AppGoRouter {
  GoRouter router = GoRouter(
    initialLocation: Routes.home,
    errorBuilder: (BuildContext context, GoRouterState state) {
      String route = state.uri.toString();
      return RouteNotFoundPage(attemptedRoute: route);
    },
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (BuildContext context, GoRouterState state) => HomeComponent(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => UserLoginComponent(),
      ),
      GoRoute(
        path: Routes.logout,
        builder: (context, state) => UserLogoutComponent(),
      ),
      GoRoute(
        path: Routes.signup,
        builder: (context, state) => UserSignupComponent(),
      ),
      GoRoute(
        path: Routes.emailVerify,
        builder: (context, state) => UserEmailVerifyComponent(),
      ),
      GoRoute(
        path: Routes.passwordReset,
        builder: (context, state) => UserPasswordResetComponent(),
      ),

      GoRoute(
        path: Routes.designLibrary,
        builder: (context, state) => DesignLibrary(),
      ),

      GoRoute(
        path: Routes.user,
        builder: (context, state) => User(),
      ),
      GoRoute(
        path: Routes.userUsername,
        builder: (BuildContext context, GoRouterState state) {
          String? username = state.pathParameters["username"];
          if (username != null) {
            return User(username: username);
          }
          return User();
        },
      ),

      GoRoute(
        path: Routes.about,
        builder: (BuildContext context, GoRouterState state) => About(),
      ),

      GoRoute(
        path: Routes.team,
        builder: (BuildContext context, GoRouterState state) => Team(),
      ),

      GoRoute(
        path: Routes.privacyPolicy,
        builder: (BuildContext context, GoRouterState state) => PrivacyTerms(
          type: 'privacy',
        ),
      ),
      GoRoute(
        path: Routes.termsOfService,
        builder: (BuildContext context, GoRouterState state) => PrivacyTerms(
          type: 'terms',
        ),
      ),

      GoRoute(
        path: Routes.blogList,
        builder: (context, state) => BlogList(),
      ),
      GoRoute(
        path: Routes.blogSave,
        builder: (context, state) => BlogSave(),
      ),
      GoRoute(
        path: Routes.blogView,
        builder: (BuildContext context, GoRouterState state) {
          String? slug = state.pathParameters["slug"];
          if (slug != null) {
            return BlogView(slug: slug);
          }
          return BlogList();
        },
      ),

      GoRoute(
        path: Routes.land,
        builder: (BuildContext context, GoRouterState state) => LandPage(
            goRouterState: state,
            lat: double.parse(state.uri.queryParameters['lat'] ?? '-999'),
            lng: double.parse(state.uri.queryParameters['lng'] ?? '-999'),
            // timeframe: state.uri.queryParameters['tf'] ?? '',
            // year: int.parse(state.uri.queryParameters['year'] ?? '-999'),
            underlay: state.uri.queryParameters['u'] ?? '',
            tileSize: state.uri.queryParameters['size'] ?? '',
            dataType: state.uri.queryParameters['dt'] ?? '',
            polygonUName: state.uri.queryParameters['pg'] ?? '',
          )
      ),

      GoRoute(
        path: Routes.neighborhoods,
        builder: (context, state) => NeighborhoodsPage(),
      ),
      GoRoute(
        path: Routes.neighborhoodSave,
        builder: (BuildContext context, GoRouterState state) => NeighborhoodSave(
          uName: state.uri.queryParameters['uName'] ?? '',
          lat: double.parse(state.uri.queryParameters['lat'] ?? '0'),
          lng: double.parse(state.uri.queryParameters['lng'] ?? '0'),
        )
      ),
      GoRoute(
        path: Routes.neighborhoodView,
        builder: (BuildContext context, GoRouterState state) {
          String? uName = state.pathParameters["uName"];
          if (uName != null) {
            return Neighborhood(uName: uName);
          }
          return NeighborhoodSave();
        },
      ),
      GoRoute(
        path: Routes.neighborhoodJourney,
        builder: (context, state) => NeighborhoodJourneyPage(),
      ),
      GoRoute(
        path: Routes.belongingSurvey,
        builder: (context, state) => BelongingSurvey(),
      ),

      GoRoute(
        path: Routes.sharedItems,
        builder: (BuildContext context, GoRouterState state) => SharedItems(
          lat: double.parse(state.uri.queryParameters['lat'] ?? '0'),
          lng: double.parse(state.uri.queryParameters['lng'] ?? '0'),
          maxMeters: double.parse(state.uri.queryParameters['range'] ?? '1500'),
        ),
      ),
      GoRoute(
        path: Routes.sharedItemSave,
        builder: (BuildContext context, GoRouterState state) => SharedItemSave(
          id: state.uri.queryParameters['id'] ?? '',
        ),
      ),

      GoRoute(
        path: Routes.sharedItemOwnerSave,
        builder: (BuildContext context, GoRouterState state) => SharedItemOwnerSave(
          sharedItemOwnerId: state.uri.queryParameters['id'] ?? '',
          sharedItemId: state.uri.queryParameters['sharedItemId'] ?? '',
          userId: state.uri.queryParameters['userId'] ?? '',
          generation: state.uri.queryParameters['generation'] != null ?
            int.parse(state.uri.queryParameters['generation']!) : 0,
        ),
      ),

      GoRoute(
        path: Routes.userMoney,
        builder: (BuildContext context, GoRouterState state) => UserMoney(),
      ),

      GoRoute(
        path: Routes.weeklyEvents,
        builder: (BuildContext context, GoRouterState state) => WeeklyEvents(
          lat: double.parse(state.uri.queryParameters['lat'] ?? '0'),
          lng: double.parse(state.uri.queryParameters['lng'] ?? '0'),
          maxMeters: double.parse(state.uri.queryParameters['range'] ?? '1500'),
        ),
      ),
      GoRoute(
        path: Routes.weeklyEventSave,
        builder: (BuildContext context, GoRouterState state) => WeeklyEventSave(
          id: state.uri.queryParameters['id'] ?? '',
          type: state.uri.queryParameters['type'] ?? '',
        ),
      ),
      GoRoute(
        path: Routes.weeklyEventView,
        builder: (BuildContext context, GoRouterState state) {
          String? uName = state.pathParameters["uName"];
          if (uName != null) {
            return WeeklyEventView(uName: uName);
          }
          return WeeklyEvents();
        },
      ),
      GoRoute(
        path: Routes.eat,
        builder: (BuildContext context, GoRouterState state) => WeeklyEvents(
          lat: double.parse(state.uri.queryParameters['lat'] ?? '0'),
          lng: double.parse(state.uri.queryParameters['lng'] ?? '0'),
          maxMeters: double.parse(state.uri.queryParameters['range'] ?? '500'),
          type: 'sharedMeal',
          routePath: 'eat',
          showFilters: 0,
        ),
      ),
      GoRoute(
        path: Routes.eventFeedbackSave,
        builder: (BuildContext context, GoRouterState state) => EventFeedbackSavePage(
          eventId: state.uri.queryParameters['eventId'] ?? '',
        )
      ),

      GoRoute(
        path: Routes.notFound,
        builder: (context, state) => RouteNotFoundPage(),
      ),
    ],
    // Not working well.. Just did in AppScaffoldComponent instead.
    // redirect: (BuildContext context, GoRouterState state) {
    //   // var currentUserState = context.watch<CurrentUserState>();
    //   var currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    //   String url = currentUserState.routerRedirectUrl;
    //   print ('url ${url}');
    //   if (url != '') {
    //     return url;
    //   }
    //   return null;
    // }
  );
}
