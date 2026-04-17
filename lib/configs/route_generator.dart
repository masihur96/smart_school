import 'package:flutter/material.dart';
import 'package:smart_school/features/auth/presntation/views/login_screen.dart';
import 'package:smart_school/features/auth/presntation/views/change_password_screen.dart';
import 'package:smart_school/features/splash_screen.dart';

import 'package:smart_school/features/notifications/screens/notification_screen.dart';

class RouteGenerator {
  static const String splashRoute = '/'; // ✅ Add this
  static const String login = '/login';
  static const String dashboard = '/dashboard';

  static const String loginRoute = '/login';
  static const String logoutRoute = '/logout';
  static const String forceReset = '/force-reset';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home'; // ✅ Add this
  static const String notificationRoute = '/notification';
  static const String changePasswordRoute = '/change-password';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => SplashScreen(
            //shouldSkipUpdate: true,
          ),
        );
      case loginRoute:
        return MaterialPageRoute(builder: (_) => LoginScreen());

      case changePasswordRoute:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());

      case notificationRoute:
        return MaterialPageRoute(builder: (_) => const NotificationScreen());

      default:
        return MaterialPageRoute(builder: (_) => LoginScreen());

      // case homeRoute: // ✅ Add this case
      //   return MaterialPageRoute(
      //       builder: (_) =>  DashboardScreen(
      //             user: ,
      //           ));
      //
      // default:
      //   return MaterialPageRoute(builder: (_) => const DashboardScreen(user: user));
    }
  }
}
