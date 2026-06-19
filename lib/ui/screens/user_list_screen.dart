import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/user_service.dart';
import '../../data/models/user_response.dart';
import 'assign_role_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<UserData> _users = [];
  List<UserData> _filteredUsers = [];
  bool _loading = true;
  String _searchQuery = '';
  String? _errorMessage;
  String _selectedFilter = 'todos'; // todos, sin_rol, inspector, ayudante

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      if (token.isEmpty) {
        setState(() {
          _loading = false;
          _errorMessage = 'Token de autenticación no encontrado';
        });
        return;
      }

      debugPrint('Cargando usuarios con token: ${token.substring(0, 20)}...');

      // Usar el método para obtener TODOS los usuarios (excepto admins)
      final response = await UserService.getAllUsers(
        token: token,
        maxRetries: 2,
      );

      if (response.success && response.data != null) {
        debugPrint('Usuarios cargados exitosamente: ${response.data!.length}');
        setState(() {
          _users = response.data!;
          _applyFilters(); // Aplicar filtros después de cargar datos
          _loading = false;
          _errorMessage = null;
        });
      } else {
        debugPrint('Error cargando usuarios: ${response.error}');
        setState(() {
          _loading = false;
          _errorMessage = response.error ?? 'Error al cargar usuarios';
        });
      }
    } catch (e) {
      debugPrint('Excepción en _fetchUsers: $e');
      setState(() {
        _loading = false;
        _errorMessage = 'Error de conexión: $e';
      });
    }
  }

  void _applyFilters() {
    List<UserData> filteredByRole = _users;

    // Filtrar por rol seleccionado
    switch (_selectedFilter) {
      case 'sin_rol':
        filteredByRole = _users.where((user) {
          final rol = user.rol.trim().toLowerCase();
          return rol.isEmpty || rol == 'null' || rol == 'sin asignar' || rol == 'undefined';
        }).toList();
        break;
      case 'inspector':
        filteredByRole = _users.where((user) => user.rol.toLowerCase() == 'inspector').toList();
        break;
      case 'ayudante':
        filteredByRole = _users.where((user) => user.rol.toLowerCase() == 'ayudante').toList();
        break;
      case 'activos':
        filteredByRole = _users.where((user) => user.activo).toList();
        break;
      case 'inactivos':
        filteredByRole = _users.where((user) => !user.activo).toList();
        break;
      case 'todos':
      default:
        filteredByRole = _users;
        break;
    }

    // Aplicar filtro de búsqueda
    if (_searchQuery.isNotEmpty) {
      filteredByRole = filteredByRole.where((user) {
        final nombre = user.nombre.toLowerCase();
        final cedula = user.cedula?.toLowerCase() ?? '';
        final email = user.email.toLowerCase();
        final queryLower = _searchQuery.toLowerCase();

        return nombre.contains(queryLower) ||
            cedula.contains(queryLower) ||
            email.contains(queryLower);
      }).toList();
    }

    setState(() {
      _filteredUsers = filteredByRole;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _changeRoleFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilters();
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _searchQuery = '';
    });
    await _fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _refreshUsers,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Campo de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Buscar por nombre, cédula o email",
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _filterUsers,
              controller: TextEditingController(text: _searchQuery),
            ),
          ),

          // Filtros por rol
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('todos', 'Todos', _getTotalCount()),
                  const SizedBox(width: 8),
                  _buildFilterChip('activos', 'Activos', _getCountByRole('activos')),
                  const SizedBox(width: 8),
                  _buildFilterChip('inactivos', 'Inactivos', _getCountByRole('inactivos')),
                  const SizedBox(width: 8),
                  _buildFilterChip('inspector', 'Inspectores', _getCountByRole('inspector')),
                  const SizedBox(width: 8),
                  _buildFilterChip('ayudante', 'Ayudantes', _getCountByRole('ayudante')),
                  const SizedBox(width: 8),
                  _buildFilterChip('sin_rol', 'Sin Rol', _getCountByRole('sin_rol')),
                ],
              ),
            ),
          ),

          // Contenido principal
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _selectedFilter == value;
    final color = _getFilterColor(value);

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) => _changeRoleFilter(value),
      label: Text(
        '$label ($count)',
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selectedColor: color,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.white,
      side: BorderSide(color: color),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'activos':
        return Colors.teal;
      case 'inactivos':
        return Colors.red;
      case 'sin_rol':
        return Colors.orange;
      case 'inspector':
        return Colors.blue;
      case 'ayudante':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  int _getTotalCount() {
    return _users.length;
  }

  int _getCountByRole(String role) {
    switch (role) {
      case 'activos':
        return _users.where((user) => user.activo).length;
      case 'inactivos':
        return _users.where((user) => !user.activo).length;
      case 'sin_rol':
        return _users.where((user) {
          final rol = user.rol.trim().toLowerCase();
          return rol.isEmpty || rol == 'null' || rol == 'sin asignar' || rol == 'undefined';
        }).length;
      case 'inspector':
        return _users.where((user) => user.rol.toLowerCase() == 'inspector').length;
      case 'ayudante':
        return _users.where((user) => user.rol.toLowerCase() == 'ayudante').length;
      default:
        return 0;
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Cargando usuarios...',
              style: TextStyle(color: AppColors.text),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _refreshUsers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - 250,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al cargar usuarios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _refreshUsers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshUsers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - 250,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
                    size: 64,
                    color: AppColors.gray500,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No se encontraron usuarios'
                        : _getEmptyMessage(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Intenta con otros términos de búsqueda'
                        : _getEmptySubMessage(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshUsers,
      child: ListView.builder(
        itemCount: _filteredUsers.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case 'activos':
        return 'No hay usuarios activos';
      case 'inactivos':
        return 'No hay usuarios inactivos';
      case 'sin_rol':
        return 'No hay usuarios sin rol';
      case 'inspector':
        return 'No hay inspectores';
      case 'ayudante':
        return 'No hay ayudantes';
      default:
        return 'No hay usuarios';
    }
  }

  String _getEmptySubMessage() {
    switch (_selectedFilter) {
      case 'activos':
        return 'Todos los usuarios están inactivos';
      case 'inactivos':
        return 'Todos los usuarios están activos';
      case 'sin_rol':
        return 'Todos los usuarios ya tienen un rol asignado';
      case 'inspector':
        return 'No hay usuarios con rol de inspector';
      case 'ayudante':
        return 'No hay usuarios con rol de ayudante';
      default:
        return 'No se encontraron usuarios en el sistema';
    }
  }

  Widget _buildUserCard(UserData user) {
    // Determinar color y estado del rol
    Color roleColor;
    String roleText;
    bool hasRole = user.hasRole;

    if (!hasRole) {
      roleColor = Colors.orange;
      roleText = "Sin rol asignado";
    } else {
      switch (user.rol.toLowerCase()) {
        case 'inspector':
          roleColor = Colors.blue;
          roleText = "Inspector";
          break;
        case 'ayudante':
          roleColor = Colors.green;
          roleText = "Ayudante";
          break;
        default:
          roleColor = Colors.grey;
          roleText = user.rol.toUpperCase();
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: _getProfileImage(user),
        ),
        title: Text(
          user.nombre.isNotEmpty ? user.nombre : 'Sin nombre',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.text,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (user.email.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.email, size: 14, color: AppColors.gray500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      user.email,
                      style: const TextStyle(color: AppColors.gray500, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
            ],
            if (user.cedula != null && user.cedula!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.badge, size: 14, color: AppColors.gray500),
                  const SizedBox(width: 4),
                  Text(
                    "CI: ${user.cedula}",
                    style: const TextStyle(color: AppColors.gray500, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: roleColor.withOpacity(0.3)),
              ),
              child: Text(
                roleText,
                style: TextStyle(
                  color: roleColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: user.activo ? Colors.teal.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: user.activo ? Colors.teal.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                user.activo ? "Activo" : "Inactivo",
                style: TextStyle(
                  color: user.activo ? Colors.teal : Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasRole)
              Icon(Icons.verified, size: 18, color: roleColor),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
          ],
        ),
        onTap: () async {
          // Convertir UserData a Map para compatibilidad con AssignRoleScreen
          final userMap = {
            'id': user.idUsuario,
            'nombre': user.nombre,
            'email': user.email,
            'cedula': user.cedula,
            'telefono': user.telefono,
            'rol': user.rol,
            'foto_perfil_url': user.fotoPerfilUrl,
            'activo': user.activo,
            'direccion': user.direccion,
          };

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssignRoleScreen(user: userMap),
            ),
          );

          // Recargar lista si se modificó un rol
          if (result == true) {
            _refreshUsers();
          }
        },
      ),
    );
  }

  // Helper method para manejo seguro de imágenes de perfil
  ImageProvider _getProfileImage(UserData user) {
    try {
      if (user.fotoPerfilUrl != null && user.fotoPerfilUrl!.isNotEmpty) {
        final uri = Uri.tryParse(user.fotoPerfilUrl!);
        if (uri != null && uri.isAbsolute) {
          return NetworkImage(user.fotoPerfilUrl!);
        }
      }
    } catch (e) {
      debugPrint('Error cargando imagen de perfil para ${user.nombre}: $e');
    }
    return const AssetImage("assets/images/avatar_placeholder.png") as ImageProvider;
  }
}
