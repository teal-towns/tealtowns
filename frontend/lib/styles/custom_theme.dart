import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTheme {
  static ThemeData get lightTheme {
    Color primary = Color.fromRGBO(0, 181, 181, 1);
    Color primaryDark = Color.fromRGBO(0, 93, 93, 1);
    Color secondary = Color.fromRGBO(143, 229, 142, 1);
    Color accent = Color.fromRGBO(0, 164, 203, 1);
    Color accentDark = Color.fromRGBO(0, 100, 120, 1);
    Color text = Color.fromRGBO(90, 90, 90, 1);
    Color grey = Colors.grey;
    Color white = Colors.white;
    Color error = Color.fromRGBO(169, 46, 97, 1);
    return ThemeData(
      // https://paletton.com/#uid=53i0u0kDJDJiVIJpYEuFjqdJVjp
      primaryColor: primary,
      textTheme: GoogleFonts.ptSansTextTheme().copyWith(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w300),
        displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w300),
        displaySmall: TextStyle(fontSize: 21, fontWeight: FontWeight.w300),
        headlineMedium:
            TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
        headlineSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w300),
        titleLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w300),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w300),
      ).apply(
        bodyColor: text,
        displayColor: text,
      ),
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        background: accent,
        surface: accentDark,
        error: error,
      ).copyWith(secondary: secondary).copyWith(background: grey),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // textStyle: TextStyle(
          //   letterSpacing: 1.05,
          // ),
          foregroundColor: white,
          backgroundColor: primary,
        )
      ),
      pageTransitionsTheme: PageTransitionsTheme(builders: {
        TargetPlatform.iOS: FadeTransitionBuilder(),
        TargetPlatform.android: FadeTransitionBuilder(),
        TargetPlatform.fuchsia: FadeTransitionBuilder(),
        TargetPlatform.macOS: FadeTransitionBuilder(),
        TargetPlatform.windows: FadeTransitionBuilder(),
      }),
    );
  }
}

class FadeTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(_, __, animation, ___, child) => FadeTransition(opacity: animation, child: child);
}
