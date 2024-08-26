import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import './modules/home.dart';
import './modules/route_not_found.dart';
import './modules/user_auth/user_email_verify.dart';
import './modules/user_auth/user_login.dart';
import './modules/user_auth/user_logout.dart';
import './modules/user_auth/user_password_reset.dart';
import './modules/user_auth/user_signup.dart';
import './modules/user_auth/user.dart';

import './modules/user_auth/users_save.dart';

import './modules/design_library/design_library.dart';

import './modules/about/about.dart';
import './modules/about/team.dart';
import './modules/about/privacy_terms.dart';
import './modules/about/ai_urban_planner_about.dart';

import './modules/ambassador/ambassador_start.dart';
import './modules/ambassador/ambassador_network.dart';
import './modules/ambassador/ambassador_network_view.dart';

import './modules/blog/blog_list.dart';
import './modules/blog/blog_save.dart';
import './modules/blog/blog_view.dart';

import './modules/event/weekly_events.dart';
import './modules/event/weekly_event_save.dart';
import './modules/event/weekly_event_view.dart';
import './modules/event/weekly_event_print.dart';
import './modules/event/weekly_events_search.dart';
import './modules/event/event_feedback_save_page.dart';
import './modules/event/event_feedback_page.dart';

import './modules/icebreaker/icebreakers.dart';
import './modules/icebreaker/icebreaker_save.dart';

import './modules/insight/app_insights.dart';
import './modules/insight/ambassador_insights.dart';

import './modules/land/land_page.dart';

import './modules/neighborhood/belonging_survey.dart';
import './modules/neighborhood/neighborhood.dart';
import './modules/neighborhood/neighborhood_events.dart';
import './modules/neighborhood/neighborhoods_page.dart';
import './modules/neighborhood/neighborhood_save.dart';
import './modules/neighborhood/neighborhood_group.dart';
import './modules/neighborhood/neighborhood_group_save.dart';
import './modules/neighborhood/neighborhood_insights.dart';
import './modules/neighborhood/neighborhood_journey_page.dart';
import './modules/neighborhood/neighborhood_stats.dart';
import './modules/neighborhood/user_neighborhood_save.dart';
import './modules/neighborhood/user_neighborhood_weekly_update_save.dart';
import './modules/neighborhood/user_neighborhood_weekly_updates.dart';

import './modules/shared_item/shared_item.dart';
import './modules/shared_item/shared_items.dart';
import './modules/shared_item/shared_item_save.dart';
import './modules/shared_item/shared_item_owner_save.dart';

import './modules/user_payment/user_money.dart';
import './modules/user_payment/mercury_pay_outs.dart';
import './modules/user_auth/user_availability_save.dart';
import './modules/user_auth/user_interest_save.dart';

import './modules/user_auth/current_user_state.dart';

import './modules/shared_item/amazon_affiliate.dart';

class Routes {
  static const home = '/home';
  static const notFound = '/route-not-found';
  static const emailVerify = '/email-verify';
  static const login = '/login';
  static const logout = '/logout';
  static const passwordReset = '/password-reset';
  static const signup = '/signup';

  static const ambassadorStart = '/ambassador';
  static const ambassadorNetwork = '/ambassador-network';
  static const ambassadorNetworkView = '/ambassador-network-view';

  static const usersSave = '/users-save';

  static const designLibrary = '/design-library';

  static const user = '/user';
  static const userUsername = '/u/:username';

  static const about = '/about';
  static const team = '/team'; 
  static const privacyPolicy = '/privacy-policy';
  static const termsOfService = '/terms-of-service';
  static const aiUrbanPlannerAbout = '/ai-urban-planner';

  static const blogList = '/blog';
  static const blogSave = '/blog-save';
  static const blogView = '/b/:slug';

  static const weeklyEvents = '/weekly-events';
  static const weeklyEventSave = '/weekly-event-save';
  static const weeklyEventView = '/we/:uName';
  static const weeklyEventPrint = '/wep/:uName';
  static const weeklyEventsSearch = '/weekly-events-search';
  static const eat = '/eat';
  static const eventFeedbackSave = '/event-feedback-save';
  static const eventFeedback = '/event-feedback';

  static const icebreakers = '/icebreakers';
  static const icebreakerSave = '/icebreaker-save';

  static const appInsights = '/app-insights';
  static const ambassadorInsights = '/ambassador-insights';

  static const land = '/land';

  static const belongingSurvey = '/belonging-survey';
  static const neighborhoodSave = '/neighborhood-save';
  static const neighborhoodView = '/n/:uName';
  static const neighborhoodEvents = '/ne/:uName';
  static const neighborhoods = '/neighborhoods';
  static const neighborhoodInsights = '/neighborhood-insights';
  static const neighborhoodGroupSave = '/neighborhood-group-save';
  static const neighborhoodGroup = '/neighborhood-group/:uName';
  static const neighborhoodJourney = '/neighborhood-journey';
  static const neighborhoodStats = '/neighborhood-stats/:uName';
  static const userNeighborhoodSave = '/user-neighborhood-save';
  static const ambassadorUpdatesSingle = '/au/:neighborhoodUName';
  static const userNeighborhoodWeeklyUpdates = '/user-neighborhood-weekly-updates';
  static const userNeighborhoodWeeklyUpdateSave = '/user-neighborhood-weekly-update-save';
  static const ambassadorsUpdates = '/ambassadors-updates';

  static const sharedItem = '/si/:uName';
  static const sharedItems = '/own';
  static const sharedItemSave = '/shared-item-save';
  static const sharedItemOwnerSave = '/shared-item-owner-save';

  static const userMoney = '/user-money';
  static const mercuryPayOuts = '/mercury-pay-outs';

  static const userInterestSave = '/interests';
  static const userAvailabilitySave = '/user-availability-save';

  static const amazonAffiliate = '/amazon-affiliate';
}

class AppGoRouter {
  GoRouter router = GoRouter(
    observers: [ SentryNavigatorObserver() ],
    initialLocation: Routes.home,
    errorBuilder: (BuildContext context, GoRouterState state) {
      String route = state.uri.toString();
      return RouteNotFoundPage(attemptedRoute: route);
    },
    routes: [
      GoRoute(
        path: Routes.home, name: 'home',
        builder: (BuildContext context, GoRouterState state) => HomeComponent(),
      ),
      GoRoute(
        path: Routes.login, name: 'login',
        builder: (context, state) => UserLoginComponent(),
      ),
      GoRoute(
        path: Routes.logout, name: 'logout',
        builder: (context, state) => UserLogoutComponent(),
      ),
      GoRoute(
        path: Routes.signup, name: 'signup',
        builder: (context, state) => UserSignup(),
      ),
      GoRoute(
        path: Routes.emailVerify, name: 'emailVerify',
        builder: (context, state) => UserEmailVerifyComponent(
          verifyKey: state.uri.queryParameters['key'] ?? '',
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: Routes.passwordReset, name: 'passwordReset',
        builder: (BuildContext context, GoRouterState state) => UserPasswordResetComponent(
          resetKey: state.uri.queryParameters['key'] ?? '',
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),

      GoRoute(
        path: Routes.designLibrary, name: 'designLibrary',
        builder: (context, state) => DesignLibrary(),
      ),

      GoRoute(
        path: Routes.ambassadorStart, name: 'ambassadorStart',
        builder: (context, state) => AmbassadorStart(),
      ),
      GoRoute(
        path: Routes.ambassadorNetwork, name: 'ambassadorNetwork',
        builder: (context, state) => AmbassadorNetwork(),
      ),
      GoRoute(
        path: Routes.ambassadorNetworkView, name: 'ambassadorNetworkView',
        builder: (BuildContext context, GoRouterState state) => AmbassadorNetworkView(
          lat: double.parse(state.uri.queryParameters['lat'] ?? '0.0'),
          lng: double.parse(state.uri.queryParameters['lng'] ?? '0.0'),
          maxMeters: int.parse(state.uri.queryParameters['maxMeters'] ?? '8000'),
        ),
      ),

      GoRoute(
        path: Routes.user, name: 'user',
        builder: (BuildContext context, GoRouterState state) {
          String mode = '';
          String? ambassadorUpdates = state.uri.queryParameters['au'] ?? '';
          if (ambassadorUpdates != null && ambassadorUpdates.length > 0) {
            mode = 'ambassadorUpdates';
          }
          return User(mode: mode);
        },
      ),
      GoRoute(
        path: Routes.userUsername, name: 'userUsername',
        builder: (BuildContext context, GoRouterState state) {
          String? username = state.pathParameters["username"];
          if (username != null) {
            return User(username: username);
          }
          return User();
        },
      ),

      GoRoute(
        path: Routes.usersSave, name: 'usersSave',
        builder: (context, state) => UsersSave(),
      ),

      GoRoute(
        path: Routes.about, name: 'about',
        builder: (BuildContext context, GoRouterState state) => About(),
      ),

      GoRoute(
        path: Routes.team, name: 'team',
        builder: (BuildContext context, GoRouterState state) => Team(),
      ),

      GoRoute(
        path: Routes.privacyPolicy, name: 'privacyPolicy',
        builder: (BuildContext context, GoRouterState state) => PrivacyTerms(
          type: 'privacy',
        ),
      ),
      GoRoute(
        path: Routes.termsOfService, name: 'termsOfService',
        builder: (BuildContext context, GoRouterState state) => PrivacyTerms(
          type: 'terms',
        ),
      ),

      GoRoute(
        path: Routes.aiUrbanPlannerAbout, name: 'aiUrbanPlannerAbout',
        builder: (BuildContext context, GoRouterState state) => AIUrbanPlannerAbout(),
      ),

      GoRoute(
        path: Routes.blogList, name: 'blogList',
        builder: (context, state) => BlogList(),
      ),
      GoRoute(
        path: Routes.blogSave, name: 'blogSave',
        builder: (context, state) => BlogSave(),
      ),
      GoRoute(
        path: Routes.blogView, name: 'blogView',
        builder: (BuildContext context, GoRouterState state) {
          String? slug = state.pathParameters["slug"];
          if (slug != null) {
            return BlogView(slug: slug);
          }
          return BlogList();
        },
      ),

      GoRoute(
        path: Routes.appInsights, name: 'appInsights',
        builder: (context, state) => AppInsights(),
      ),
      GoRoute(
        path: Routes.ambassadorInsights, name: 'ambassadorInsights',
        builder: (context, state) => AmbassadorInsights(),
      ),

      GoRoute(
        path: Routes.icebreakers, name: 'icebreakers',
        builder: (context, state) => Icebreakers(),
      ),
      GoRoute(
        path: Routes.icebreakerSave, name: 'icebreakerSave',
        builder: (BuildContext context, GoRouterState state) => IcebreakerSave(
          id: state.uri.queryParameters['id'] ?? '',
        ),
      ),

      GoRoute(
        path: Routes.land, name: 'land',
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
        path: Routes.neighborhoods, name: 'neighborhoods',
        builder: (context, state) => NeighborhoodsPage(),
      ),
      GoRoute(
        path: Routes.neighborhoodSave, name: 'neighborhoodSave',
        builder: (BuildContext context, GoRouterState state) => NeighborhoodSave(
          uName: state.uri.queryParameters['uName'] ?? '',
          lat: double.parse(state.uri.queryParameters['lat'] ?? '0'),
          lng: double.parse(state.uri.queryParameters['lng'] ?? '0'),
        )
      ),
      GoRoute(
        path: Routes.neighborhoodView, name: 'neighborhoodView',
        builder: (BuildContext context, GoRouterState state) {
          String? uName = state.pathParameters["uName"];
          if (uName != null) {
            return Neighborhood(uName: uName);
          }
          return NeighborhoodSave();
        },
      ),
      GoRoute(
        path: Routes.neighborhoodEvents, name: 'neighborhoodEvents',
        builder: (BuildContext context, GoRouterState state) {
          String? uName = state.pathParameters["uName"];
          if (uName != null) {
            return NeighborhoodEvents(uName: uName);
          }
          return NeighborhoodsPage();
        },
      ),
      GoRoute(
        path: Routes.neighborhoodGroup, name: 'neighborhoodGroup',
        builder: (BuildContext context, GoRouterState state) {
          String? uName = state.pathParameters["uName"];
          if (uName != null) {
            return NeighborhoodGroup(uName: uName);
          }
          return HomeComponent();
        },
      ),
      GoRoute(
        path: Routes.neighborhoodGroupSave, name: 'neighborhoodGroupSave',
        builder: (BuildContext context, GoRouterState state) => NeighborhoodGroupSave(
          uName: state.uri.queryParameters['uName'] ?? '',
        )
      ),
      GoRoute(
        path: Routes.neighborhoodInsights, name: 'neighborhoodInsights',
        builder: (context, state) => NeighborhoodInsights(),
      ),
      GoRoute(
        path: Routes.neighborhoodStats, name: 'neighborhoodStats',
        builder: (BuildContext context, GoRouterState state) {
          String? uName = state.pathParameters["uName"];
          if (uName != null) {
            return NeighborhoodStats(uName: uName,
              showFreePaid: state.uri.queryParameters['showFreePaid'] != null ? true : false,);
          }
          return NeighborhoodsPage();
        },
      ),
      GoRoute(
        path: Routes.userNeighborhoodSave, name: 'userNeighborhoodSave',
        builder: (BuildContext context, GoRouterState state) => UserNeighborhoodSave(
          id: state.uri.queryParameters['id'] ?? '',
          neighborhoodUName: state.uri.queryParameters['neighborhoodUName'] ?? '',
        )
      ),
      GoRoute(
        path: Routes.userNeighborhoodWeeklyUpdateSave, name: 'userNeighborhoodWeeklyUpdateSave',
        builder: (BuildContext context, GoRouterState state) => UserNeighborhoodWeeklyUpdateSave(
          id: state.uri.queryParameters['id'] ?? '',
          neighborhoodUName: state.uri.queryParameters['neighborhoodUName'] ?? '',
        )
      ),
      GoRoute(
        path: Routes.userNeighborhoodWeeklyUpdates, name: 'userNeighborhoodWeeklyUpdates',
        builder: (BuildContext context, GoRouterState state) => UserNeighborhoodWeeklyUpdates(
          neighborhoodUName: state.uri.queryParameters['neighborhoodUName'] ?? '',
        )
      ),
      GoRoute(
        path: Routes.ambassadorUpdatesSingle, name: 'ambassadorUpdatesSingle',
        builder: (BuildContext context, GoRouterState state) {
          String? neighborhoodUName = state.pathParameters["neighborhoodUName"];
          if (neighborhoodUName != null) {
            return UserNeighborhoodWeeklyUpdates(neighborhoodUName: neighborhoodUName);
          }
          return UserNeighborhoodWeeklyUpdates();
        },
      ),
      GoRoute(
        path: Routes.ambassadorsUpdates, name: 'ambassadorsUpdates',
        builder: (BuildContext context, GoRouterState state) => UserNeighborhoodWeeklyUpdates(
          mode: 'allAmbassadors',
        )
      ),

      GoRoute(
        path: Routes.neighborhoodJourney, name: 'neighborhoodJourney',
        builder: (context, state) => NeighborhoodJourneyPage(),
      ),
      GoRoute(
        path: Routes.belongingSurvey, name: 'belongingSurvey',
        builder: (context, state) => BelongingSurvey(),
      ),

      GoRoute(
        path: Routes.sharedItem, name: 'sharedItem',
        builder: (BuildContext context, GoRouterState state) {
          String? uName = state.pathParameters["uName"];
          if (uName != null) {
            return SharedItem(uName: uName);
          }
          return SharedItems();
        },
      ),
      GoRoute(
        path: Routes.sharedItems, name: 'sharedItems',
        builder: (BuildContext context, GoRouterState state) => SharedItems(
          lat: double.parse(state.uri.queryParameters['lat'] ?? '0'),
          lng: double.parse(state.uri.queryParameters['lng'] ?? '0'),
          maxMeters: double.parse(state.uri.queryParameters['range'] ?? '1500'),
          myType: state.uri.queryParameters['myType'] ?? '',
        ),
      ),
      GoRoute(
        path: Routes.sharedItemSave, name: 'sharedItemSave',
        builder: (BuildContext context, GoRouterState state) => SharedItemSave(
          id: state.uri.queryParameters['id'] ?? '',
        ),
      ),

      GoRoute(
        path: Routes.sharedItemOwnerSave, name: 'sharedItemOwnerSave',
        builder: (BuildContext context, GoRouterState state) => SharedItemOwnerSave(
          sharedItemOwnerId: state.uri.queryParameters['id'] ?? '',
          sharedItemId: state.uri.queryParameters['sharedItemId'] ?? '',
          userId: state.uri.queryParameters['userId'] ?? '',
          generation: state.uri.queryParameters['generation'] != null ?
            int.parse(state.uri.queryParameters['generation']!) : 0,
        ),
      ),

      GoRoute(
        path: Routes.userMoney, name: 'userMoney',
        builder: (BuildContext context, GoRouterState state) => UserMoney(),
      ),
      GoRoute(
        path: Routes.mercuryPayOuts, name: 'mercuryPayOuts',
        builder: (BuildContext context, GoRouterState state) => MercuryPayOuts(),
      ),

      GoRoute(
        path: Routes.weeklyEvents, name: 'weeklyEvents',
        builder: (BuildContext context, GoRouterState state) => WeeklyEvents(
          lat: double.parse(state.uri.queryParameters['lat'] ?? '0'),
          lng: double.parse(state.uri.queryParameters['lng'] ?? '0'),
          maxMeters: double.parse(state.uri.queryParameters['range'] ?? '1500'),
        ),
      ),
      GoRoute(
        path: Routes.weeklyEventSave, name: 'weeklyEventSave',
        builder: (BuildContext context, GoRouterState state) => WeeklyEventSave(
          id: state.uri.queryParameters['id'] ?? '',
          type: state.uri.queryParameters['type'] ?? '',
        ),
      ),
      GoRoute(
        path: Routes.weeklyEventView, name: 'weeklyEventView',
        builder: (BuildContext context, GoRouterState state) {
          String? uName = state.pathParameters["uName"];
          if (uName != null) {
            return WeeklyEventView(uName: uName);
          }
          return WeeklyEvents();
        },
      ),
      GoRoute(
        path: Routes.weeklyEventPrint, name: 'weeklyEventPrint',
        builder: (BuildContext context, GoRouterState state) {
          String? uName = state.pathParameters["uName"];
          if (uName != null) {
            return WeeklyEventPrint(
              uName: uName,
              rows: int.parse(state.uri.queryParameters['rows'] ?? '1'),
              columns: int.parse(state.uri.queryParameters['columns'] ?? '1'),
              showImage: int.parse(state.uri.queryParameters['showImage'] ?? '1'),
              withTearOffs: int.parse(state.uri.queryParameters['withTearOffs'] ?? '1'),
            );
          }
          return WeeklyEvents();
        },
      ),
      GoRoute(
        path: Routes.weeklyEventsSearch, name: 'weeklyEventsSearch',
        builder: (BuildContext context, GoRouterState state) => WeeklyEventsSearch(),
      ),
      GoRoute(
        path: Routes.eat, name: 'eat',
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
        path: Routes.eventFeedbackSave, name: 'eventFeedbackSave',
        builder: (BuildContext context, GoRouterState state) => EventFeedbackSavePage(
          eventId: state.uri.queryParameters['eventId'] ?? '',
        )
      ),
      GoRoute(
        path: Routes.eventFeedback, name: 'eventFeedback',
        builder: (BuildContext context, GoRouterState state) => EventFeedbackPage(
          eventId: state.uri.queryParameters['eventId'] ?? '',
          weeklyEventId: state.uri.queryParameters['weeklyEventId'] ?? '',
        )
      ),

      GoRoute(
        path: Routes.userAvailabilitySave, name: 'userAvailabilitySave',
        builder: (BuildContext context, GoRouterState state) => UserAvailabilitySave(),
      ),
      GoRoute(
        path: Routes.userInterestSave, name: 'userInterestSave',
        builder: (BuildContext context, GoRouterState state) => UserInterestSave(),
      ),

      GoRoute(
        path: Routes.amazonAffiliate, name: 'amazonAffiliate',
        builder: (BuildContext context, GoRouterState state) => AmazonAffiliate(),
      ),

      GoRoute(
        path: Routes.notFound, name: 'notFound',
        builder: (context, state) => RouteNotFoundPage(),
      ),
    ],
  );
}
