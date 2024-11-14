// ignore_for_file: deprecated_member_use

import 'package:celebrease_manager/Auth/authgate.dart';
import 'package:celebrease_manager/States/changemanger.dart';
import 'package:celebrease_manager/States/theme.dart';
import 'package:celebrease_manager/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

// Color constants remain the same for light mode
const textColor = Color(0xFF0d0506);
const backgroundColor = Color.fromARGB(255, 242, 255, 231);
const primaryColor = Color(0xFFbb5355);
const primaryFgColor = Color(0xFFfdf9f9);
const secondaryColor = Color(0xFFcbd594);
const secondaryFgColor = Color(0xFF0d0506);
const accentColor = Color(0xFF95c771);
const accentFgColor = Color(0xFF0d0506);
const stickerColor = Color(0xFFF3F1E4);
const profileCardColor = Color(0xFFEFD7D7);
const stickerColorDark = Color(0xFF4A4743);
const profileCardColorDark = Color(0xFF5D4B4B);

// Enhanced light mode ColorScheme
// Enhanced light mode ColorScheme
ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: backgroundColor,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    background: backgroundColor,
    onBackground: textColor,
    primary: primaryColor,
    onPrimary: primaryFgColor,
    secondary: secondaryColor,
    onSecondary: secondaryFgColor,
    tertiary: accentColor,
    onTertiary: accentFgColor,
    surface: backgroundColor,
    onSurface: textColor,
    error: Color(0xffB3261E),
    onError: Color(0xffFFFFFF),
    surfaceVariant: Color(0xFFE7F0D8),
    onSurfaceVariant: Color(0xFF121212),
    outline: Color(0xFF85876F),
  ),
  // Enhanced card theme for light mode
  cardTheme: CardTheme(
    elevation: 4,
    shadowColor: const Color(0xFF85876F).withOpacity(0.2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAliasWithSaveLayer,
  ),
  // Enhanced button theme for light mode
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 2,
      shadowColor: primaryColor.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  // Enhanced input decoration theme for light mode
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: backgroundColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF85876F)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF85876F)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
  ),
  // Enhanced text theme
  textTheme: GoogleFonts.lateefTextTheme(ThemeData.light().textTheme).copyWith(
    displayLarge: const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      color: textColor,
    ),
    displayMedium: const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      color: textColor,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      letterSpacing: 0.15,
      color: textColor,
    ),
  ),
  // Enhanced dialog theme for light mode
  dialogTheme: DialogTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 8,
    backgroundColor: backgroundColor,
  ),
  // Enhanced bottom sheet theme for light mode
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: backgroundColor,
    modalBackgroundColor: backgroundColor,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),
);


// Enhanced dark theme
ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    background: Color(0xFF1A1518), // Slightly warmer dark background
    onBackground: Color(0xFFF9F0F1),
    primary: Color(0xFFFF6B6D), // Brighter primary for dark mode
    onPrimary: Color(0xFF1A1518),
    secondary: Color(0xFFD4E5A5), // Lighter secondary for better contrast
    onSecondary: Color(0xFF1A1518),
    tertiary: Color(0xFFA8D67E), // Brighter accent
    onTertiary: Color(0xFF1A1518),
    surface: Color(0xFF231D20), // Slightly lighter than background
    onSurface: Color(0xFFF9F0F1),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    // Adding surface variations for depth
    surfaceVariant: Color(0xFF2D2426),
    onSurfaceVariant: Color(0xFFE6E1E5),
    outline: Color(0xFF958F94),
  ),
  // Enhanced card theme
  cardTheme: CardTheme(
    elevation: 8,
    shadowColor: const Color(0xFF958F94).withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAliasWithSaveLayer,
  ),
  // Enhanced button theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 4,
      shadowColor: const Color(0xFFFF6B6D).withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  // Enhanced input decoration theme
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF231D20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF958F94)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF958F94)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFFF6B6D), width: 2),
    ),
  ),
  // Enhanced text theme
  textTheme: GoogleFonts.lateefTextTheme(ThemeData.dark().textTheme).copyWith(
    displayLarge: const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    displayMedium: const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      letterSpacing: 0.15,
    ),
  ),
  // Enhanced dialog theme
  dialogTheme: DialogTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 16,
  ),
  // Enhanced bottom sheet theme
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF231D20),
    modalBackgroundColor: Color(0xFF231D20),
    elevation: 16,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final themeNotifier = ThemeNotifier();
  await themeNotifier.initialize();

  // Preload the Lateef font
  await GoogleFonts.pendingFonts([
    GoogleFonts.lateef(),
  ]);

  runApp(
    MultiProvider(
      providers: [
         ChangeNotifierProvider(create: (context) => ChangeManager()),
        ChangeNotifierProvider.value(
            value: themeNotifier), // Use value provider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize notifications after building context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //LocalNotificationService.initialize(context);
      //LocalNotificationService.requestPermissions();
    });
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );

    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeNotifier.themeMode,
            builder: EasyLoading.init(),
            home: AuthGate());
      },
    );
  }
}
