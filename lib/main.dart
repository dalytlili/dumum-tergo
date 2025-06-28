import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dumum_tergo/viewmodels/seller/SideMenuViewModelseller.dart';
import 'package:dumum_tergo/views/pas_iternet.dart';
import 'package:dumum_tergo/views/user/experiences/FavoriteExperiencesScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

// Constants
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/constants/theme_config.dart';

// Services
import 'package:dumum_tergo/services/api_service.dart';
import 'package:dumum_tergo/services/logout_service.dart';
import 'package:dumum_tergo/services/websocket_serviceNotif.dart';
import 'package:dumum_tergo/services/login_service.dart';
import 'package:dumum_tergo/services/route_service.dart';
import 'package:dumum_tergo/services/notification_service.dart';
import 'package:dumum_tergo/services/notification_service_user.dart';

// ViewModels
import 'package:dumum_tergo/viewmodels/seller/CampingItemSEllerViewModel.dart';
import 'package:dumum_tergo/viewmodels/user/ChangePasswordViewModel.dart';
import 'package:dumum_tergo/viewmodels/user/EditProfileViewModel.dart';
import 'package:dumum_tergo/viewmodels/user/HomeViewModel.dart';
import 'package:dumum_tergo/viewmodels/user/SettingsViewModel.dart';
import 'package:dumum_tergo/viewmodels/user/SideMenuViewModel.dart';
import 'package:dumum_tergo/viewmodels/user/SignInViewModel.dart';
import 'package:dumum_tergo/viewmodels/user/camping_items_viewmodel.dart';
import 'package:dumum_tergo/viewmodels/user/forgot_password_viewmodel.dart';
import 'package:dumum_tergo/viewmodels/seller/AccueilViewModel.dart';
import 'package:dumum_tergo/viewmodels/seller/CompleteProfileSellerViewModel.dart';
import 'package:dumum_tergo/viewmodels/seller/EditProfileSellerViewModel.dart';
import 'package:dumum_tergo/viewmodels/seller/PaymentViewModelV.dart';
import 'package:dumum_tergo/viewmodels/seller/SellerLoginViewModel.dart';
import 'package:dumum_tergo/viewmodels/seller/otp_verification_viewmodel.dart';
import 'package:dumum_tergo/viewmodels/theme_viewmodel.dart';
import 'package:dumum_tergo/viewmodels/user/rental_search_viewmodel.dart';
import 'package:dumum_tergo/viewmodels/seller/liste_car_viewmodel.dart';

// Views
import 'package:dumum_tergo/views/user/item/vendor_shop_screen.dart';
import 'package:dumum_tergo/views/user/car/reservation_page.dart';
import 'package:dumum_tergo/views/user/auth/ChangePasswordScreen.dart';
import 'package:dumum_tergo/views/user/SettingsView.dart';
import 'package:dumum_tergo/views/user/auth/forgot_password_view.dart';
import 'package:dumum_tergo/views/user/home_view.dart';
import 'package:dumum_tergo/views/onboarding_screens.dart';
import 'package:dumum_tergo/views/user/auth/otp_verification_screen.dart';
import 'package:dumum_tergo/views/privacy_policy_screen.dart';
import 'package:dumum_tergo/views/user/experiences/profile_view.dart';
import 'package:dumum_tergo/views/seller/auth/CompleteProfileSellerView.dart';
import 'package:dumum_tergo/views/seller/AccuilSellerScreen.dart';
import 'package:dumum_tergo/views/seller/auth/PaymentView.dart';
import 'package:dumum_tergo/views/seller/auth/Seller_Login.dart';
import 'package:dumum_tergo/views/seller/auth/VerificationOtpChangeMobile.dart';
import 'package:dumum_tergo/views/seller/auth/otp_verification_screen.dart';
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart';
import 'package:dumum_tergo/views/splash_screen.dart';
import 'package:dumum_tergo/views/welcome_screen.dart';
import 'package:dumum_tergo/views/user/auth/sign_up_screen.dart';

class NoConnectionScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const NoConnectionScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
         children: [
  const Spacer(flex: 2),
  SizedBox(
    width: MediaQuery.of(context).size.width * 0.8,
    child: AspectRatio(
      aspectRatio: 1,
      child: SvgPicture.string(
        noInternetIllustration,
        fit: BoxFit.scaleDown,
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white.withOpacity(0.8) 
            : Colors.black.withOpacity(0.6),
      ), // ← cette parenthèse était mal placée
    ),
  ),
  const Spacer(flex: 2),
  ErrorInfo(
    title: "Pas de connexion Internet",
    description: "Veuillez vérifier votre connexion réseau et réessayer.",
    btnText: "Réessayer",
    press: onRetry,
  ),
],

          ),
        ),
      ),
    );
  }
}

class ErrorInfo extends StatelessWidget {
  const ErrorInfo({
    super.key,
    required this.title,
    required this.description,
    this.button,
    this.btnText,
    required this.press,
  });

  final String title;
  final String description;
  final Widget? button;
  final String? btnText;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16 * 2.5),
            button ??
                ElevatedButton(
                  onPressed: press,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)))),
                  child: Text(btnText ?? "Retry".toUpperCase()),
                ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Vérification de la connexion internet
  final connectivity = Connectivity();
  final connectivityResult = await connectivity.checkConnectivity();
  final isConnected = connectivityResult != ConnectivityResult.none;

  final storage = FlutterSecureStorage();
  final authToken = await storage.read(key: 'authToken');
  final userId = await storage.read(key: 'userId');
  
  // Initialisation des services de notification
  final notificationService = NotificationService();
  await notificationService.initialize();

  final notificationServiceUser = NotificationServiceuser();
  await notificationServiceUser.initialize();

  // Configuration initiale de la status bar
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Icônes noires par défaut
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordViewModel()),
        ChangeNotifierProvider(create: (_) => EditProfileViewModel()),
        ChangeNotifierProvider(create: (_) => ChangePasswordViewModel()),
        ChangeNotifierProvider(create: (_) => SellerLoginViewModel()),
        ChangeNotifierProvider(create: (_) => CompleteProfileSellerViewModel()),
        ChangeNotifierProvider(create: (_) => PaymentViewModel()),
        ChangeNotifierProvider(create: (_) => AccueilViewModel()),
        ChangeNotifierProvider(create: (_) => OtpSellerViewModel(fullPhoneNumber: '')),
        ChangeNotifierProvider(create: (_) => EditProfileSellerViewModel()),
        ChangeNotifierProvider(create: (_) => RentalSearchViewModel()),
        ChangeNotifierProvider(create: (_) => ListeCarViewModel()),
        Provider<NotificationService>.value(value: notificationService),
        Provider<Connectivity>.value(value: connectivity),
        ChangeNotifierProvider(create: (_) => SideMenuViewModelSeller()),
        ChangeNotifierProvider(
          create: (context) => CampingItemsViewModel(
            apiService: ApiService(
              baseUrl: 'https://dumum-tergo-backend.onrender.com/api',
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CampingItemsSellerViewModel(
            apiService: ApiService(
              baseUrl: 'https://dumum-tergo-backend.onrender.com/api',
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SignInViewModel(
            loginService: LoginService(client: http.Client()),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(logoutService: LogoutService()),
        ),
        ChangeNotifierProvider(
          create: (_) => SideMenuViewModel(logoutService: LogoutService()),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(),
        ),
      ],
      child: MyApp(
        initialAuthToken: authToken,
        initialUserId: userId,
        isConnected: isConnected,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final String? initialAuthToken;
  final String? initialUserId;
  final bool isConnected;

  const MyApp({
    super.key,
    this.initialAuthToken,
    this.initialUserId,
    required this.isConnected,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isConnected;
  late Connectivity _connectivity;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _isConnected = widget.isConnected;
    _connectivity = Connectivity();
    _setupConnectivityListener();
  }

  Future<bool> hasInternetConnection() async {
    try {
      final result = await http.get(Uri.parse('https://www.google.com')).timeout(Duration(seconds: 5));
      return result.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _setupConnectivityListener() async {
    _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
    
    final initialResult = await _connectivity.checkConnectivity();
    _updateConnectionStatus(initialResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) async {
    final actualInternet = await hasInternetConnection();
    if (!mounted) return;

    if (actualInternet != _isConnected) {
      setState(() {
        _isConnected = actualInternet;
      });
    }
  }

  Future<void> _retryConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      debugPrint('Resultat /..........r: $result');

      if (!mounted) return;

      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(result != ConnectivityResult.none
              ? 'Connexion rétablie !' 
              : 'Pas de connexion Internet détectée'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeViewModel>(
      builder: (context, themeViewModel, child) {
        // Mise à jour du style de la status bar quand le thème change
        final systemOverlayStyle = themeViewModel.isDarkMode
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                systemNavigationBarColor: Colors.black,
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarColor: Colors.white,
                systemNavigationBarIconBrightness: Brightness.dark,
              );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          SystemChrome.setSystemUIOverlayStyle(systemOverlayStyle);
        });

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemOverlayStyle,
          child: Builder(
            builder: (context) {
              if (!_isConnected) {
                return MaterialApp(
                  scaffoldMessengerKey: _scaffoldMessengerKey,
                  debugShowCheckedModeBanner: false,
                  themeMode: themeViewModel.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  home: NoConnectionScreen(
                    onRetry: _retryConnection,
                  ),
                );
              }

              return FutureBuilder<String?>(
                future: getInitialRoute(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return MaterialApp(
                      scaffoldMessengerKey: _scaffoldMessengerKey,
                      home: Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  } else {
                    return MaterialApp(
                      scaffoldMessengerKey: _scaffoldMessengerKey,
                      title: 'Dumum Tergo',
                      debugShowCheckedModeBanner: false,
                      themeMode: themeViewModel.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                      theme: AppTheme.lightTheme,
                      darkTheme: AppTheme.darkTheme,
                      home: const SplashScreen(),
                      initialRoute: '/splash',
                      routes: {
                        '/vendorShop': (context) {
                          final args = ModalRoute.of(context)!.settings.arguments as String;
                          return VendorShopScreen(vendorId: args);
                        },
                        '/splash': (context) => const SplashScreen(),
                        '/onboarding': (context) => const OnboardingScreens(),
                        '/welcome': (context) => const WelcomeScreen(),
                        '/signin': (context) => SignInScreen(),
                        '/signup': (context) => SignUpScreen(),
                        '/home': (context) => const HomeView(),
                        '/privacy-policy': (context) => const PrivacyPolicyScreen(),
                        '/forgot-password': (context) => const ForgotPasswordView(),
                        '/profile': (context) => ProfileView(),
                        '/SettingsView': (context) => SettingsView(),
                        '/changePassword': (context) => ChangePasswordScreen(),
                        '/signin_seller': (context) => SellerLoginView(),
                        '/profile_seller': (context) => CompleteProfileSellerView(),
                        '/PaymentView': (context) => PaymentView(),
                        '/payment-success': (context) => AccuilSellerScreen(),
                        '/complete_profile': (context) => CompleteProfileSellerView(),
                        '/Reservation-Page': (context) => ReservationPage(),
                        '/Favorite-Page': (context) => FavoriteExperiencesScreen(),
                      },
                      onGenerateRoute: (settings) {
                        switch (settings.name) {
                          case '/otp-verification':
                            final String phoneNumber = settings.arguments as String;
                            return MaterialPageRoute(
                              builder: (context) => OtpVerificationScreen(
                                phoneNumber: phoneNumber,
                              ),
                            );
                          case '/otp-verification-change-mobile':
                            final String phoneNumber = settings.arguments as String;
                            return MaterialPageRoute(
                              builder: (context) => VerificationOtpChangeMobile(
                                fullPhoneNumber: phoneNumber,
                              ),
                            );
                          case '/otp-verification':
                            final String phoneNumber = settings.arguments as String;
                            return MaterialPageRoute(
                              builder: (context) => OtpVerificationSellerScreen(
                                phoneNumber: phoneNumber,
                              ),
                            );
                          default:
                            return null;
                        }
                      },
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}