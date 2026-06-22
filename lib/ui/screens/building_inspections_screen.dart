import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/inspection_detail_service.dart';
import '../../data/models/building_list_response.dart';

class BuildingInspectionsScreen extends StatefulWidget {
  final BuildingData edificio;

  const BuildingInspectionsScreen({super.key, required this.edificio});

  @override
  State<BuildingInspectionsScreen> createState() =>
      _BuildingInspectionsScreenState();
}

class _BuildingInspectionsScreenState extends State<BuildingInspectionsScreen> {
  List<Map<String, dynamic>> _inspecciones = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    _loadInspecciones();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInspecciones() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data =
          await InspectionDetailService.getByBuilding(widget.edificio.idEdificio);
      setState(() {
        _inspecciones = data;
        _filtered = List.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando inspecciones: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_inspecciones)
          : _inspecciones.where((ins) {
              final codigo =
                  (ins['id_inspeccion'] ?? '').toString().toLowerCase();
              final inspector =
                  (ins['nombre_inspector'] ?? '').toString().toLowerCase();
              return codigo.contains(q) || inspector.contains(q);
            }).toList();
    });
  }

  // ── Formateo de fecha ────────────────────────────────────────
  String _formatDate(dynamic raw) {
    if (raw == null) return 'Sin fecha';
    try {
      final dt = DateTime.parse(raw.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  // ── MODAL: Detalles del informe ──────────────────────────────
  Future<void> _showDetailsModal(Map<String, dynamic> inspeccion) async {
    final idIns = int.tryParse(inspeccion['id_inspeccion'].toString()) ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final detail = await InspectionDetailService.getDetail(idIns);
    final files = await InspectionDetailService.getFiles(idIns);
    final comments = await InspectionDetailService.getComments(idIns);

    if (!mounted) return;
    Navigator.pop(context); // cierra el loading

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
            maxWidth: 500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Informe #$idIns',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (detail != null) ...[
                        _detailRow('Estado',
                            detail['nombre_estado'] ?? detail['estado'] ?? '—'),
                        _detailRow('Inspector',
                            detail['nombre_inspector'] ?? '—'),
                        _detailRow('Fecha inspección',
                            _formatDate(detail['fecha_inspeccion'] ?? detail['created_at'])),
                        _detailRow('Alcance exterior',
                            detail['alcance_exterior'] ?? '—'),
                        _detailRow('Alcance interior',
                            detail['alcance_interior'] ?? '—'),
                        _detailRow('Revisión planos',
                            detail['revision_planos'] == true ? 'Sí' : 'No'),
                        _detailRow('Fuente suelo',
                            detail['fuente_suelo'] ?? '—'),
                        _detailRow('Fuente peligros',
                            detail['fuente_peligros'] ?? '—'),
                        _detailRow(
                            'Contacto', detail['contacto_persona'] ?? '—'),
                        _detailRow('Requiere Nivel 2',
                            detail['requiere_nivel2'] == true ? 'Sí' : 'No'),
                        if (detail['observaciones_generales'] != null &&
                            detail['observaciones_generales']
                                .toString()
                                .isNotEmpty)
                          _detailRow('Observaciones',
                              detail['observaciones_generales']),
                      ],

                      // Archivos / fotos
                      if (files.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const Text('Archivos adjuntos',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: files.map((f) {
                            final url =
                                f['url_archivo']?.toString() ?? '';
                            final isImage = (f['tipo_archivo'] ?? '')
                                .toString()
                                .startsWith('image/');
                            if (isImage && url.isNotEmpty) {
                              return GestureDetector(
                                onTap: () => _showImageFullscreen(url),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(url,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _filePlaceholder()),
                                ),
                              );
                            }
                            return _filePlaceholder();
                          }).toList(),
                        ),
                      ],

                      // Comentarios
                      if (comments.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const Text('Comentarios',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        ...comments.map((c) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['nombre_usuario'] ?? 'Usuario',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(c['comentario'] ?? '',
                                      style: const TextStyle(fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(c['created_at']),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── MODAL: Resultados ────────────────────────────────────────
  Future<void> _showResultsModal(Map<String, dynamic> inspeccion) async {
    final idIns = int.tryParse(inspeccion['id_inspeccion'].toString()) ?? 0;
    final puntuacionFinal = inspeccion['puntuacion_final'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final results = await InspectionDetailService.getResults(idIns);

    if (!mounted) return;
    Navigator.pop(context); // cierra el loading

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            maxWidth: 450,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _scoreColor(puntuacionFinal),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    const Text('Resultado de Inspección',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        puntuacionFinal != null
                            ? double.tryParse(puntuacionFinal.toString())
                                    ?.toStringAsFixed(1) ??
                                '—'
                            : 'Sin puntuación',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _scoreLabel(puntuacionFinal),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Desglose de criterios
              if (results.isNotEmpty)
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    shrinkWrap: true,
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = results[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          r['descripcion_criterio'] ?? 'Criterio ${r['id_criterio']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          r['categoria'] ?? '',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                        trailing: Text(
                          '${r['valor_obtenido'] ?? 0} / ${r['peso_maximo'] ?? 0}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      );
                    },
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No hay criterios evaluados',
                      style: TextStyle(color: Colors.grey)),
                ),

              // Botón cerrar
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cerrar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers visuales ─────────────────────────────────────────
  Color _scoreColor(dynamic score) {
    if (score == null) return Colors.grey;
    final s = double.tryParse(score.toString()) ?? 0;
    if (s >= 7) return Colors.green.shade700;
    if (s >= 4) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  String _scoreLabel(dynamic score) {
    if (score == null) return '';
    final s = double.tryParse(score.toString()) ?? 0;
    if (s >= 7) return 'Estado favorable';
    if (s >= 4) return 'Requiere atención';
    return 'Estado crítico';
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.gray500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _filePlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.insert_drive_file, color: Colors.grey, size: 32),
    );
  }

  void _showImageFullscreen(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image,
                            color: Colors.white, size: 64)),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon:
                    const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final ed = widget.edificio;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inspecciones del Edificio'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.gray500)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _loadInspecciones,
                          child: const Text('Reintentar')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInspecciones,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Foto del edificio ────────────────────
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ed.fotoUrl != null && ed.fotoUrl!.isNotEmpty
                              ? Image.network(
                                  ed.fotoUrl!,
                                  height: 160,
                                  width: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildingPlaceholder(),
                                )
                              : _buildingPlaceholder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Nombre y dirección ───────────────────
                      Center(
                        child: Text(
                          ed.nombreEdificio,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (ed.direccion != null) ...[
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            ed.direccion!,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.gray500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── Buscador ─────────────────────────────
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por código o inspector...',
                          prefixIcon:
                              const Icon(Icons.search, color: AppColors.primary),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.gray300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.gray300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Contador ─────────────────────────────
                      Text(
                        '${_filtered.length} inspección(es)',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.gray500),
                      ),
                      const SizedBox(height: 8),

                      // ── Lista tipo acordeón ──────────────────
                      if (_filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.assignment_outlined,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('No se encontraron inspecciones',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._filtered.asMap().entries.map((entry) {
                          final i = entry.key;
                          final ins = entry.value;
                          final isExpanded = _expandedIndex == i;
                          return _buildAccordionCard(ins, i, isExpanded);
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAccordionCard(
      Map<String, dynamic> ins, int index, bool isExpanded) {
    final codigoInforme = 'INS-${ins['id_inspeccion']}';
    final fecha = _formatDate(ins['fecha_inspeccion'] ?? ins['created_at']);
    final inspector = ins['nombre_inspector']?.toString() ?? 'Sin asignar';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Column(
        children: [
          // Header clicable
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          codigoInforme,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.text),
                        ),
                        const SizedBox(height: 4),
                        Text(fecha,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.gray500)),
                        Text(inspector,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.gray500)),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // Contenido expandido
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  // Botón Ver detalles del informe
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showDetailsModal(ins),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('Ver detalles del informe'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Botón Ver resultados
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showResultsModal(ins),
                      icon: const Icon(Icons.bar_chart_outlined, size: 18),
                      label: const Text('Ver resultado'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: const BorderSide(color: Colors.teal),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildingPlaceholder() {
    return Container(
      height: 160,
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.apartment, size: 64, color: Colors.grey),
    );
  }
}
