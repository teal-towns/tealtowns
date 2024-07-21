import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
//if (kIsWeb) {
//import 'dart:html' if (dart.library.html);
//}
import 'package:universal_html/html.dart';
import 'package:url_strategy/url_strategy.dart';

import './common/config_service.dart';
import './common/localstorage_service.dart';
import './common/socket_service.dart';
import './modules/user_auth/current_user_state.dart';
import './routes.dart';
import './styles/custom_theme.dart';

import './modules/blog/blog_state.dart';
import './modules/neighborhood/neighborhood_state.dart';
import './modules/shared_item/shared_item_state.dart';

main() async {
  await dotenv.load(fileName: '.env');
  ConfigService _configService = ConfigService();
  _configService.SetConfig(dotenv.env);

  if (kIsWeb) {
    // Check for redirect.
    bool redirectIt = false;
    String url = Uri.base.toString();
    // dot env is not loading properly if on www? So just assume if null to redirect.
    // Check www first so can also redirect http to https after if necessary.
    if ((dotenv.env['REDIRECT_DOMAINS'] != null && dotenv.env['DOMAIN'] != null &&
      dotenv.env['REDIRECT_DOMAINS']!.length > 0 && dotenv.env['DOMAIN']!.length > 0)) {
      List<String> domains = dotenv.env['REDIRECT_DOMAINS']!.split(',');
      for (String domain in domains) {
        if (url.contains(domain)) {
          url = url.replaceAll(domain, dotenv.env['DOMAIN']!);
          redirectIt = true;
          break;
        }
      }
    }
    if ((dotenv.env['REDIRECT_WWW'] == '1' ||
      dotenv.env['REDIRECT_WWW'] == null) &&
        url.contains('www.')) {
      if (url.contains('https://') || url.contains('http://')) {
        url = url.replaceAll('www.', '');
      } else {
        url = url.replaceAll('www.', 'https://');
      }
      redirectIt = true;
    }
    if (dotenv.env['REDIRECT_HTTP'] == '1' && url.contains('http://')) {
      url = url.replaceAll('http://', 'https://');
      redirectIt = true;
    }
    if (redirectIt) {
      window.location.href = url;
    }
  }

  LocalstorageService _localstorageService = LocalstorageService();
  _localstorageService.init(dotenv.env['APP_NAME']);

  SocketService _socketService = SocketService();
  _socketService.connect({ 'default': dotenv.env['SOCKET_URL_PUBLIC'] });

  setPathUrlStrategy();

  // WidgetsFlutterBinding.ensureInitialized();
  if (dotenv.env['SENTRY_DSN'] != null && dotenv.env['SENTRY_DSN']!.length > 0) {
    print ('init');
    await SentryFlutter.init(
      (options) {
        options.dsn = dotenv.env['SENTRY_DSN'];
        // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
        // We recommend adjusting this value in production.
        options.tracesSampleRate = 1.0;
        // The sampling rate for profiling is relative to tracesSampleRate
        // Setting to 1.0 will profile 100% of sampled transactions:
        options.profilesSampleRate = 1.0;
      },
    );
  }
  runApp(MultiProvider(
    providers: [
      //ChangeNotifierProvider(create: (context) => AppState()),
      ChangeNotifierProvider(create: (context) => CurrentUserState()),
      ChangeNotifierProvider(create: (context) => BlogState()),
      ChangeNotifierProvider(create: (context) => NeighborhoodState()),
      ChangeNotifierProvider(create: (context) => SharedItemState()),
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyApp createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  GoRouter _appRouter = AppGoRouter().router;

  @override
  Widget build(BuildContext context) {
    var currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    currentUserState.checkAndLogin();
    var neighborhoodState = Provider.of<NeighborhoodState>(context, listen: false);
    if(currentUserState.isLoggedIn) {
      String userId = currentUserState.currentUser.id;
      neighborhoodState.CheckAndGet(userId, notify: false);
    } else {
      neighborhoodState.ClearUserNeighborhoods(notify: false);
    }

    return MaterialApp.router(
      theme: CustomTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      title: 'tealtowns',
      routerConfig: _appRouter,
    );
    ;
  }
}
