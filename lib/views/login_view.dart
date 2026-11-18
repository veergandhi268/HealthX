import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/healthx_logo.dart';
import '../services/firestore_service.dart';
import '../main.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final provider = GoogleAuthProvider();
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
      
      if (userCredential.user != null) {
        // Initialize fresh state for new user (free plan, 0 logs)
        await FirestoreService().onUserSignedIn();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainShell()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign in: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Background Elements
            Positioned(
              top: -100, right: -50,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppTheme.luxeGold.withOpacity(0.15), Colors.transparent]),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const HealthXLogo(size: 64, fontSize: 36),
                  const SizedBox(height: 24),
                  const Text('PREMIUM FITNESS TRACKER', style: TextStyle(
                    color: AppTheme.luxeGold, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2.0,
                  )),
                  const SizedBox(height: 12),
                  const Text('Log your nutrition, master your workouts, and unlock your elite potential.', 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 14, height: 1.5)
                  ),
                  const Spacer(),
                  
                  if (_isLoading)
                    const CircularProgressIndicator(color: AppTheme.luxeGold)
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.luxeGold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 10,
                          shadowColor: AppTheme.luxeGold.withOpacity(0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Text('G', style: TextStyle(
                                color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900,
                              )),
                            ),
                            const SizedBox(width: 14),
                            const Text('CONTINUE WITH GOOGLE', style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0,
                            )),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text('By continuing, you agree to our Terms of Service & Privacy Policy', 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textDarkMuted, fontSize: 10)
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
