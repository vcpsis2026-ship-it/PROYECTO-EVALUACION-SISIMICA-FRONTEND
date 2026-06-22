import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationHelper {
  /// Navega al home correcto dependiendo del rol del usuario
  static Future<void> navigateToHome(BuildContext context, {bool isReplacement = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? userRole = prefs.getString('userRole');

    final bool isAdmin = userRole != null && 
        (userRole.toLowerCase() == 'administrador' || 
         userRole.toLowerCase() == 'admin' || 
         userRole == '1');

    final String targetRoute = isAdmin ? '/home_admin' : '/home';

    if (context.mounted) {
      if (isReplacement) {
        Navigator.pushReplacementNamed(context, targetRoute);
      } else {
        Navigator.pushNamed(context, targetRoute);
      }
    }
  }

  /// Navega al perfil correcto dependiendo del rol del usuario
  static Future<void> navigateToProfile(BuildContext context, {bool isReplacement = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? userRole = prefs.getString('userRole');

    final bool isAdmin = userRole != null && 
        (userRole.toLowerCase() == 'administrador' || 
         userRole.toLowerCase() == 'admin' || 
         userRole == '1');

    final String targetRoute = isAdmin ? '/profileAdmin' : '/profile';

    if (context.mounted) {
      if (isReplacement) {
        Navigator.pushReplacementNamed(context, targetRoute);
      } else {
        Navigator.pushNamed(context, targetRoute);
      }
    }
  }
}
