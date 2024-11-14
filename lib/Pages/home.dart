import 'package:celebrease_manager/Pages/main_screen.dart';
import 'package:celebrease_manager/Pages/settings.dart';
import 'package:celebrease_manager/modules/sample.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;
  Widget page = MainScreen();
  Widget titleIcon = Icon(
    FluentSystemIcons.ic_fluent_home_regular,
    size: 50,
    color:Colors.grey.withOpacity(0.9),
  );
  final double expandedHeight = 200.0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _navigate(int index) {
    setState(() {
      selectedIndex = index;
      switch (index) {
        case 0:
          page = MainScreen();
          titleIcon = Icon(
            FluentSystemIcons.ic_fluent_home_regular,
            size: 50,
            color: Colors.grey.withOpacity(0.9),
          );
          break;
          case 1:{
            page = CommunicationCenter();
          titleIcon = Icon(
            FluentSystemIcons.ic_fluent_chat_regular,
            size: 50,
            color: Colors.grey.withOpacity(0.9),
          );
          }
          break;
        case 2:
          page = Settings();
          titleIcon = Icon(
            FluentSystemIcons.ic_fluent_settings_dev_regular,
            size: 50,
            color: Colors.grey.withOpacity(0.9),
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  actions:[IconButton.outlined(onPressed: ()=>_auth.signOut(), icon: Icon(Icons.logout_outlined))],
                  expandedHeight: expandedHeight,
                  floating: false,
                  pinned: true,
                  stretch: true,
                  //backgroundColor: Theme.of(context).primaryColorDark,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    collapseMode: CollapseMode.parallax,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).primaryColorDark,
                            Theme.of(context).primaryColorDark.withOpacity(0.4),
                            Theme.of(context).primaryColorDark.withOpacity(0.01),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: titleIcon,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'CelebrEase',
                              style: GoogleFonts.merienda(
                                color: Colors.grey.withOpacity(0.9),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'Management Dashboard',
                              style: TextStyle(
                                color: Colors.grey.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(child: page),
                  SizedBox(
                    height: 20,
                  )
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: BottomNavigationBar(
                  currentIndex: selectedIndex,
                  onTap: _navigate,
                  selectedItemColor: Theme.of(context).primaryColor,
                  unselectedItemColor: Colors.grey,
                  selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
                  elevation: 0,
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(FluentSystemIcons.ic_fluent_home_regular),
                      activeIcon: Icon(FluentSystemIcons.ic_fluent_home_filled),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(FluentSystemIcons.ic_fluent_chat_regular),
                      activeIcon: Icon(FluentSystemIcons.ic_fluent_chat_filled),
                      label: 'Comms',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                          FluentSystemIcons.ic_fluent_settings_dev_regular),
                      activeIcon:
                          Icon(FluentSystemIcons.ic_fluent_settings_dev_filled),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
