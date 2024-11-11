import 'package:celebrease_manager/States/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    String userId = auth.currentUser!.uid;
    ThemeMode currentThemeMode = themeNotifier.themeMode;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20),
      children: [
        Text(
          'Settings',
          textScaler: TextScaler.linear(2.7),
          style: GoogleFonts.lateef(fontWeight: FontWeight.bold),
        ),
        const Divider(thickness: 0.1),
        const SizedBox(height: 20),
        Text(
          'Preferences',
          textScaler: const TextScaler.linear(2),
          style: GoogleFonts.lateef(),
        ),
        Column(
          children: [
            RadioListTile<ThemeMode>(
              title: Text('System Theme',
                  textScaler: const TextScaler.linear(1.5),
                  style: GoogleFonts.lateef()),
              value: ThemeMode.system,
              groupValue: currentThemeMode,
              onChanged: (ThemeMode? mode) async {
                if (mode != null) {
                  await themeNotifier.setThemeMode(mode);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text('Light Mode',
                  textScaler: const TextScaler.linear(1.5),
                  style: GoogleFonts.lateef()),
              value: ThemeMode.light,
              groupValue: currentThemeMode,
              onChanged: (ThemeMode? mode) async {
                if (mode != null) {
                  await themeNotifier.setThemeMode(mode);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text('Dark Mode',
                  textScaler: const TextScaler.linear(1.5),
                  style: GoogleFonts.lateef()),
              value: ThemeMode.dark,
              groupValue: currentThemeMode,
              onChanged: (ThemeMode? mode) async {
                if (mode != null) {
                  await themeNotifier.setThemeMode(mode);
                }
              },
            ),
          ],
        ),
        SizedBox(height: 20),
        Text(
          'Account Settings',
          textScaler: const TextScaler.linear(2),
          style: GoogleFonts.lateef(),
        ),
        
        SizedBox(height: 10),
        Text(
          'Change Password',
          textScaler: const TextScaler.linear(1.5),
          style: GoogleFonts.lateef(),
        ),
        SizedBox(height: 20),
        Text(
          'Privacy & Security',
          textScaler: const TextScaler.linear(2),
          style: GoogleFonts.lateef(),
        ),
        // Add bottom padding to account for the navigation bar
        SizedBox(height: 80),
      ],
    );
  }
}