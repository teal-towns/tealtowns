import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './modules/home.dart';
import './modules/route_not_found.dart';
import './modules/user_auth/user_email_verify.dart';
import './modules/user_auth/user_login.dart';
import './modules/user_auth/user_logout.dart';
import './modules/user_auth/user_password_reset.dart';
import './modules/user_auth/user_signup.dart';

import './modules/blog/blog_list.dart';
import './modules/blog/blog_save.dart';
import './modules/blog/blog_view.dart';

import './modules/land/land_page.dart';

import './modules/shared_item/shared_item.dart';
import './modules/shared_item/shared_item_save.dart';
import './modules/shared_item/shared_item_owner_save.dart';

class Routes {
  static const home = '/home';
  static const notFound = '/route-not-found';
  static const emailVerify = '/email-verify';
  static const login = '/login';
  static const logout = '/logout';
  static const passwordReset = '/password-reset';
  static const signup = '/signup';

  static const blogList = '/blog';
  static const blogSave = '/blog-save';
  static const blogView = '/b/:slug';

  static const land = '/land';

  static const sharedItem = '/own';
  static const sharedItemSave = '/shared-item-save';
  static const sharedItemOwnerSave = '/shared-item-owner-save';
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
            lat: double.parse(state.uri.queryParameters['lat']?? '-999'),
            lng: double.parse(state.uri.queryParameters['lng']?? '-999'),
            timeframe: state.uri.queryParameters['tf']?? '',
            year: int.parse(state.uri.queryParameters['year']?? '-999'),
            underlay: state.uri.queryParameters['u']?? '',
            tileSize: state.uri.queryParameters['size']?? '',
            dataType: state.uri.queryParameters['dt']?? '',
            polygonUName: state.uri.queryParameters['pg'] ?? '',
          )
      ),

      GoRoute(
        path: Routes.sharedItem,
        builder: (BuildContext context, GoRouterState state) => SharedItem(),
      ),
      GoRoute(
        path: Routes.sharedItemSave,
        builder: (BuildContext context, GoRouterState state) => SharedItemSave(),
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
        path: Routes.notFound,
        builder: (context, state) => RouteNotFoundPage(),
      ),
    ],
  );
}
