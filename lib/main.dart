import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

// Import screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/item_details_screen.dart';

// Import providers
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/user_provider.dart';
import 'utils/food_data_seeder.dart';
// Import services
import 'services/firebase_service.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyC7tGmk5omgEoiRYRgu5MuUjfY_rR6D_04",
          authDomain: "foodordering-app-ef349.firebaseapp.com",
          projectId: "foodordering-app-ef349",
          storageBucket: "foodordering-app-ef349.firebasestorage.app",
          messagingSenderId: "428401096180",
          appId: "1:428401096180:web:b40659ad51e7e4190a75a1",
          measurementId: "G-CXFLXGGZC0",
        ),
      );

      await fb_auth.FirebaseAuth.instance.setPersistence(fb_auth.Persistence.LOCAL);
    } else {
      await Firebase.initializeApp();
    }
    await FirebaseService.instance.initialize();
    
    // 🔥 SEED DATA - Run ONCE, then comment out
    // await FoodDataSeeder().seedFoodItems();
    
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  runApp(const BitesBuzzApp());
}

/// Main application widget for BitesBuzz
/// This is the entry point of the app and sets up theming and routing
class BitesBuzzApp extends StatelessWidget {
  const BitesBuzzApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, authProvider, cartProvider) {
            cartProvider ??= CartProvider();
            cartProvider.setUserId(authProvider.userId);
            return cartProvider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(),
          update: (_, authProvider, orderProvider) {
            orderProvider ??= OrderProvider();
            orderProvider.setUserId(authProvider.userId);
            return orderProvider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(),
          update: (_, authProvider, userProvider) {
            userProvider ??= UserProvider();
            final uid = authProvider.userId;
            if (uid != null) {
              userProvider.loadUserProfile(uid);
            } else {
              userProvider.clearUserData();
            }
            return userProvider;
          },
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'BitesBuzz',
            debugShowCheckedModeBanner: false,
            
            // Custom theme that matches Figma design
            theme: ThemeData(
              // Primary color - vibrant orange for cafeteria vibes
              primaryColor: const Color(0xFFFF6B35),
              
              // Accent color - complementary teal
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFF6B35),
                brightness: Brightness.light,
              ),
              
              // Text theme with clean, readable fonts
              textTheme: const TextTheme(
                // Headings
                headlineLarge: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                headlineMedium: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                headlineSmall: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                
                // Body text
                bodyLarge: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF1A1A1A),
                ),
                bodyMedium: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF666666),
                ),
                bodySmall: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF999999),
                ),
              ),
              
              // Button styling
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              
              // Input field styling
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF6B35),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding: const EdgeInsets.all(16),
                hintStyle: const TextStyle(color: Color(0xFF999999)),
              ),
            ),
            
            // Named routes configuration
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/home': (context) {
                // Extract userName from navigation arguments
                final args = ModalRoute.of(context)?.settings.arguments as String?;
                return HomeScreen(userName: args);
              },
              '/search': (context) => const SearchScreen(),
              '/cart': (context) => const CartScreen(),
              '/menu': (context) => const MenuScreen(),
              '/checkout': (context) => const CheckoutScreen(),
              '/order-history': (context) => const OrderHistoryScreen(),
              '/profile': (context) => const ProfileScreen(),
              // TODO: Add routes as screens are implemented
              // '/item-details': (context) => const ItemDetailsScreen(),
              // '/order-tracking': (context) => const OrderTrackingScreen(),
              // '/profile': (context) => const ProfileScreen(),
            },
          );
        },
      ),
    );
  }
}
