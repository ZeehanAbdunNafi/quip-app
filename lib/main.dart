import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/group_provider.dart';
import 'providers/payment_provider.dart';
import 'screens/splash_screen.dart';
import 'widgets/logo_test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize providers
  final authProvider = AuthProvider();
  final groupProvider = GroupProvider();
  final paymentProvider = PaymentProvider();
  
  // Initialize providers
  await authProvider.initialize();
  await groupProvider.initialize();
  await paymentProvider.initialize();
  
  // Don't create demo data on startup - only when user signs in
  
  runApp(QuipApp(
    authProvider: authProvider,
    groupProvider: groupProvider,
    paymentProvider: paymentProvider,
  ));
}

class QuipApp extends StatelessWidget {
  final AuthProvider authProvider;
  final GroupProvider groupProvider;
  final PaymentProvider paymentProvider;

  const QuipApp({
    super.key,
    required this.authProvider,
    required this.groupProvider,
    required this.paymentProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: groupProvider),
        ChangeNotifierProvider.value(value: paymentProvider),
      ],
      child: MaterialApp(
        title: 'Quip - Money Transfer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
} 