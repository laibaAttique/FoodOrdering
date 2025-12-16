import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Splash Screen
/// This is the first screen users see when opening the app
/// It displays the app name "BitesBuzz" with a nice animation
/// Users click "Get Started" button to proceed to Login screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// State class for SplashScreen - handles animation and user interaction
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller to manage the fade-in effect
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();

    // Create animation controller with 2-second duration
    _animationController = AnimationController(
      // Reduced duration for faster startup feel while keeping animation
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Create fade animation from 0 (invisible) to 1 (visible)
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Start the animation
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectIfLoggedIn();
    });
  }

  void _redirectIfLoggedIn() {
    if (!mounted || _didNavigate) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      _didNavigate = true;
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: authProvider.userProfile?.name ?? authProvider.user?.email,
      );
    }
  }

  @override
  void dispose() {
    // Always dispose animation controller to free up resources
    _animationController.dispose();
    super.dispose();
  }

  /// Handle "Get Started" button press
  /// Checks if user is already logged in for persistent session
  void _handleGetStarted() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isLoggedIn) {
      // User is already logged in - go straight to Home
      _didNavigate = true;
      Navigator.pushReplacementNamed(
        context, 
        '/home', 
        arguments: authProvider.userProfile?.name ?? authProvider.user?.email
      );
    } else {
      // Not logged in - go to Login
      _didNavigate = true;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Orange background matching the app theme
      backgroundColor: const Color(0xFFFF6B35),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo/icon container
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // App icon/logo - using emoji for simplicity
                  // In a real app, you'd use a custom image asset
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '🍕',
                        style: TextStyle(fontSize: 60),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // App name with custom styling
                  const Text(
                    'BitesBuzz',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2, // Space between letters
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tagline
                  const Text(
                    'University Cafeteria',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70, // Semi-transparent white
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Text(
                    'Food Ordering App',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),

            // "Get Started" button at the bottom
            FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox(
                width: 200,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF6B35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
