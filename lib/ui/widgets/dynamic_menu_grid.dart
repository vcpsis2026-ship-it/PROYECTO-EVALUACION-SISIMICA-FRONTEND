import 'package:flutter/material.dart';
import '../../data/models/permiso_model.dart';
import '../../core/theme/app_colors.dart';

/// Mapea el string de icono almacenado en la BD → Material IconData
IconData iconFromString(String? name) {
  switch (name?.toLowerCase()) {
    case 'home':              return Icons.home;
    case 'apartment':         return Icons.apartment;
    case 'assignment':        return Icons.assignment;
    case 'people':            return Icons.people;
    case 'category':          return Icons.category;
    case 'manage_search':     return Icons.manage_search;
    case 'history':           return Icons.history;
    case 'dashboard':         return Icons.dashboard;
    case 'settings':          return Icons.settings;
    case 'bar_chart':         return Icons.bar_chart;
    case 'map':               return Icons.map;
    case 'notifications':     return Icons.notifications;
    case 'add_business':      return Icons.add_business;
    case 'engineering':       return Icons.engineering;
    default:                  return Icons.grid_view;
  }
}

/// Color de acento por módulo
Color accentForOpcion(String codigo) {
  switch (codigo) {
    case 'edificios':    return Colors.blue;
    case 'inspecciones': return Colors.orange;
    case 'usuarios':     return Colors.purple;
    case 'catalogos':    return Colors.teal;
    case 'auditoria':    return Colors.indigo;
    default:             return AppColors.primary;
  }
}

/// Grid de opciones de menú construido desde permisos del backend
class DynamicMenuGrid extends StatelessWidget {
  final List<MenuItemPermiso> items;
  final void Function(MenuItemPermiso) onTap;
  final Color accentColor;

  const DynamicMenuGrid({
    super.key,
    required this.items,
    required this.onTap,
    this.accentColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text(
            'Sin módulos disponibles',
            style: TextStyle(color: AppColors.gray500),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) => _MenuCard(
        item:        item,
        onTap:       () => onTap(item),
        accentColor: accentForOpcion(item.codigo),
      )).toList(),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuItemPermiso item;
  final VoidCallback onTap;
  final Color accentColor;

  const _MenuCard({
    required this.item,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    // ~2 columnas en móvil, ~3 en tablet/web
    final cardW   = (screenW - 48) / (screenW > 600 ? 3 : 2);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:   cardW,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color:       Colors.grey.withOpacity(0.08),
              blurRadius:  6,
              offset:      const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                iconFromString(item.icono),
                size:  28,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.nombre,
              textAlign: TextAlign.center,
              maxLines:  2,
              overflow:  TextOverflow.ellipsis,
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color:      AppColors.text,
              ),
            ),
            // Badge de acciones si tiene más que solo 'acceso'
            if (item.acciones.length > 1) ...[
              const SizedBox(height: 6),
              _ActionsBadge(acciones: item.acciones, color: accentColor),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionsBadge extends StatelessWidget {
  final List<String> acciones;
  final Color color;

  const _ActionsBadge({required this.acciones, required this.color});

  @override
  Widget build(BuildContext context) {
    // Mostrar íconos de las acciones disponibles (excepto 'acceso')
    final map = {
      'ver':            Icons.visibility_outlined,
      'crear':          Icons.add_circle_outline,
      'editar':         Icons.edit_outlined,
      'eliminar':       Icons.delete_outline,
      'cambiar_estado': Icons.swap_horiz,
    };

    final actIcons = map.entries
        .where((e) => acciones.contains(e.key))
        .map((e) => e.value)
        .toList();

    if (actIcons.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: actIcons
          .map((ic) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(ic, size: 12, color: color.withOpacity(0.6)),
              ))
          .toList(),
    );
  }
}
