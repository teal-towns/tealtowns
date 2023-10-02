import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // https://paletton.com/#uid=53i0u0kDJDJiVIJpYEuFjqdJVjp
      primaryColor: Color.fromRGBO(0, 167, 0, 1),
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
        bodyColor: Color.fromRGBO(90, 90, 90, 1),
        displayColor: Color.fromRGBO(90, 90, 90, 1),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color.fromRGBO(0, 167, 0, 1),
        secondary: Color.fromRGBO(15, 69, 194, 1),
        background: Color.fromRGBO(0, 181, 181, 1),
        surface: Color.fromRGBO(0, 93, 93, 1),
      ).copyWith(secondary: Color.fromRGBO(15, 69, 194, 1)).copyWith(background: Colors.grey),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // textStyle: TextStyle(
          //   letterSpacing: 1.05,
          // ),
          foregroundColor: Colors.white,
          backgroundColor: Color.fromRGBO(0, 167, 0, 1),
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
