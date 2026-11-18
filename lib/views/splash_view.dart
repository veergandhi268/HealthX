import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/healthx_logo.dart';
import '../main.dart'; // To access MainShell
import 'package:firebase_auth/firebase_auth.dart';
import 'login_view.dart';
import '../services/firestore_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  double _overlayOpacity = 1.0;
  bool _showOverlay = true;
  late final Widget _underlayPage;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    _underlayPage = user != null ? const MainShell() : const LoginView();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Precache heavy images during splash so they're ready instantly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        precacheImage(const AssetImage('assets/trainer_pro.jpg'), context);
        precacheImage(const AssetImage('assets/trainer_elite.jpg'), context);
        precacheImage(const AssetImage('assets/trainer_vip.jpg'), context);
        precacheImage(const AssetImage('assets/banner_trainer.jpg'), context);
        precacheImage(const AssetImage('assets/banner_elite.jpg'), context);
        precacheImage(const AssetImage('assets/banner_vip.jpg'), context);
      }
    });

    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _overlayOpacity = 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // App is already mounted & fully warmed up in the background
        _underlayPage,

        // Smooth fade-out splash overlay
        if (_showOverlay)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _overlayOpacity == 0.0,
              child: AnimatedOpacity(
                opacity: _overlayOpacity,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                onEnd: () {
                  if (_overlayOpacity == 0.0 && mounted) {
                    setState(() {
                      _showOverlay = false;
                    });
                  }
                },
                child: Scaffold(
                  backgroundColor: AppTheme.bgDark,
                  body: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: const HealthXLogo(size: 80, fontSize: 44),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
