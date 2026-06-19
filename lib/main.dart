import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/screens/building_registry_1_screen.dart';
import 'package:flutter_application_1/ui/screens/home_admin_screen.dart';
import 'package:flutter_application_1/core/services/database_service.dart';
import '../../ui/screens/assessed_buildings_screen.dart';
import '../../ui/screens/assign_role_screen.dart';
import '../../ui/screens/building_registry_2_screen.dart';
import '../../ui/screens/building_registry_3_screen.dart';
import '../../ui/screens/building_registry_4_screen.dart';
import '../../ui/screens/buildings_screen.dart';
import '../../ui/screens/exten_revis.dart';
import '../../ui/screens/forgot_password_screen.dart';
import '../../ui/screens/home_page.dart';
import '../../ui/screens/login_screen.dart';
import '../../ui/screens/profile_admin_screen.dart';
import '../../ui/screens/profile_page.dart';
import '../../ui/screens/recovery_password.dart';
import '../../ui/screens/register_screen.dart';
import '../../ui/screens/user_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase para el generador de PDF
  await Supabase.initialize(
    url: 'https://pbjbzlopivfbkqcstcus.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBiamJ6bG9waXZmYmtxY3N0Y3VzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0NDQyNjMsImV4cCI6MjA5NjAyMDI2M30.s_L32ht3D6BZDpw04P17b5N4I0g06cjeObS2UqNXUnE',
  );

  // Restaurar token de sesión guardado en SharedPreferences
  await DatabaseService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SismosApp',
      debugShowCheckedModeBanner: false,
      //theme: AppTheme.light(),
      initialRoute: '/', // 👈 Pantalla inicial
      routes: {
        '/': (_) => const LoginScreen(),
        '/assessed': (_) => const AssessedBuildingsPage(),
        //'/roles/assign': (_) => const AssignRoleScreen(),
        '/buildingRegistry1': (_) => const BuildingRegistry1Screen(),
        '/buildingRegistry2': (_) => const BuildingRegistry2Screen(),
        '/buildingRegistry3': (_) => const BuildingRegistry3Screen(),
        '/buildingRegistry4': (_) => const BuildingRegistry4Screen(),
        '/building': (_) => const BuildingsScreen(),
    '/exten': (_) => const ExtensionRevisionPage(
          idEdificio: 0,
          nombreEdificio: '',
          direccion: '',
          anioConstruccion: '',
          tipoSuelo: 'D',
          numeroPisos: 0,
          ciudad: '', // 👈 Agregado
          ),
        '/forgot': (_) => const ForgotPasswordScreen(),
        '/home_admin': (context) => const HomeAdminScreen(),
        '/homeAdmin': (context) => const HomeAdminScreen(),
        '/home': (context) => const HomePage(),
        '/profileAdmin': (_) => const ProfileAdminScreen(),
        '/profile': (_) => const ProfilePage(),
        '/register': (context) => const RegisterScreen(),
        '/recovery': (context) => const RecoveryPasswordScreen(),
        '/userList': (context) => const UserListScreen(),
      },
    );
  }
}
