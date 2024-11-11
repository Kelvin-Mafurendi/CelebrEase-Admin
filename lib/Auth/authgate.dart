import 'package:celebrease_manager/Pages/home.dart';
import 'package:celebrease_manager/Pages/landing.dart';
import 'package:celebrease_manager/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
  });

  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _showSplash = true;

  void _onAnimationComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasData) {
          if (_showSplash) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome to',
                  style: GoogleFonts.merienda(
                      fontSize: 40, fontWeight: FontWeight.w300),
                ),
                AnimatedSplashText(onAnimationComplete: _onAnimationComplete),
              ],
            );
          }

          return Home();
        } else {
          return const Landing();
        }
      },
    );
  }
}

class AnimatedSplashText extends StatefulWidget {
  final VoidCallback onAnimationComplete;
  const AnimatedSplashText({super.key, required this.onAnimationComplete});

  @override
  _AnimatedSplashTextState createState() => _AnimatedSplashTextState();
}

class _AnimatedSplashTextState extends State<AnimatedSplashText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller, curve: Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 0.95).animate(
      CurvedAnimation(
          parent: _controller,
          curve: Interval(0.3, 0.95, curve: Curves.easeOutBack)),
    );

    _controller.forward().then((_) {
      widget.onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Theme.of(context).primaryColorDark.withOpacity(0.8),
                accentColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            );
          },
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Text(
                'CelebrEase',
                textScaler: TextScaler.linear(4),
                style: GoogleFonts.merienda(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
