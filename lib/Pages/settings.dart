import 'package:celebrease_manager/Python/api_service.dart';
import 'package:celebrease_manager/States/changemanger.dart';
import 'package:celebrease_manager/States/theme.dart';
import 'package:celebrease_manager/modules/dynamic_migration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  Map<String, dynamic>? _helloMessage;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHelloMessage();
  }

  Future<void> _fetchHelloMessage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final message = await APIService().fetchHelloMessage;
      setState(() {
        _helloMessage = message;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to fetch message: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    String userId = auth.currentUser!.uid;
    ThemeMode currentThemeMode = themeNotifier.themeMode;

    return RefreshIndicator(
      onRefresh: _fetchHelloMessage,
      child: ListView(
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
          SizedBox(height: 10),
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : _errorMessage != null
                  ? Center(
                      child: Text(_errorMessage!),
                    )
                  : _helloMessage != null
                      ? Center(
                          child: Text(
                            ' ${_helloMessage!['message']}',
                          ),
                        )
                      : Center(
                          child: Text(
                            'No message found',
                          ),
                        ),
          // Add bottom padding to account for the navigation bar
          SizedBox(height: 80),
          // In your settings or admin screen
          Text(
            'Firebase Database Management',
            textScaler: const TextScaler.linear(2),
            style: GoogleFonts.lateef(color: Colors.red),
          ),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const DynamicMigrationDialog(),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storage),
                SizedBox(width: 8),
                Text('Migrate Collection'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<ChangeManager>(context, listen: false)
                  .recoverServices();
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storage),
                SizedBox(width: 8),
                Text('Recovery service'),
              ],
            ),
          ),SizedBox(height: 50,)
        ],
      ),
    );
  }
}
