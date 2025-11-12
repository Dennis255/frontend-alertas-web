import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/reporte_service.dart';
import '../services/alert_notifier_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ResumenAlertasGraficas extends StatefulWidget {
  const ResumenAlertasGraficas({super.key});

  @override
  State<ResumenAlertasGraficas> createState() => _ResumenAlertasGraficasState();
}

class _ResumenAlertasGraficasState extends State<ResumenAlertasGraficas> {
  final ReporteService _reporteService = ReporteService();
  List<Map<String, dynamic>> _datos = [];
  Set<String> _categoriasSeleccionadas = {'Helada', 'Sequía', 'Lluvia'};
  bool _isLoading = true;
  String _tipoSeleccionado = ''; // Para gráfica individual

  final Map<String, Color> _colorPorTipo = {
    'Lluvia': Colors.blue.shade700,
    'Helada': Colors.cyan.shade600,
    'Sequía': Colors.orange.shade600,
    'Viento': Colors.purple.shade600,
    'Inundación': Colors.indigo.shade600,
    'Manual': Colors.grey.shade600,
    'Alto': Colors.red.shade600,
    'Moderado': Colors.orange.shade400,
    'Bajo': Colors.green.shade600,
  };

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AlertNotifierService().iniciarVerificacionPeriodica(segundos: 30);
      });
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final data = await _reporteService.obtenerResumenAlertas();
      setState(() => _datos = data);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, int> _agruparPorTipoSimplificado() {
    final Map<String, int> resumen = {};
    for (var item in _datos) {
      final tipoOriginal = item['tipo']?.toString().toLowerCase() ?? '';
      final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;
      String tipoGeneral = 'Otro';
      if (tipoOriginal.contains('helada')) tipoGeneral = 'Helada';
      else if (tipoOriginal.contains('sequía')) tipoGeneral = 'Sequía';
      else if (tipoOriginal.contains('lluvia')) tipoGeneral = 'Lluvia';
      else if (tipoOriginal.contains('viento')) tipoGeneral = 'Viento';
      else if (tipoOriginal.contains('inund')) tipoGeneral = 'Inundación';
      else if (tipoOriginal.contains('manual')) tipoGeneral = 'Manual';

      if (_categoriasSeleccionadas.contains(tipoGeneral)) {
        resumen[tipoGeneral] = (resumen[tipoGeneral] ?? 0) + cantidad;
      }
    }
    return resumen;
  }

  Map<String, int> _agruparPorNivel() {
    final Map<String, int> resumen = {};
    for (var item in _datos) {
      String nivel = item['nivel']?.toString().toLowerCase() ?? 'desconocido';
      final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;
      if (nivel.contains('moderado') || nivel.contains('medio')) nivel = 'Moderado';
      else if (nivel.contains('alto')) nivel = 'Alto';
      else if (nivel.contains('bajo')) nivel = 'Bajo';
      else nivel = 'Otro';
      resumen[nivel] = (resumen[nivel] ?? 0) + cantidad;
    }
    return resumen;
  }

  Widget _buildFiltros() {
    final tipos = {
      ..._datos.map((e) {
        final tipo = e['tipo']?.toString().toLowerCase() ?? '';
        if (tipo.contains('helada')) return 'Helada';
        if (tipo.contains('sequía')) return 'Sequía';
        if (tipo.contains('lluvia')) return 'Lluvia';
        if (tipo.contains('viento')) return 'Viento';
        if (tipo.contains('inund')) return 'Inundación';
        if (tipo.contains('manual')) return 'Manual';
        return 'Otro';
      })
    }.toList();

    tipos.sort((a, b) {
      const prioridad = ['Helada', 'Sequía', 'Lluvia'];
      int indexA = prioridad.contains(a) ? prioridad.indexOf(a) : 99;
      int indexB = prioridad.contains(b) ? prioridad.indexOf(b) : 99;
      return indexA.compareTo(indexB);
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrar por tipo de alerta:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _categoriasSeleccionadas = tipos.toSet()),
                    icon: const Icon(Icons.check_box, size: 18),
                    label: const Text('Seleccionar todas'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      side: BorderSide(color: Colors.green.shade700),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _categoriasSeleccionadas.clear()),
                    icon: const Icon(Icons.check_box_outline_blank, size: 18),
                    label: const Text('Limpiar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tipos.map((tipo) {
                final seleccionado = _categoriasSeleccionadas.contains(tipo);
                return FilterChip(
                  label: Text(tipo),
                  labelStyle: TextStyle(
                    color: seleccionado ? Colors.white : Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  selected: seleccionado,
                  selectedColor: _colorPorTipo[tipo] ?? Colors.blueGrey,
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (selected) => setState(() {
                    if (selected) _categoriasSeleccionadas.add(tipo);
                    else _categoriasSeleccionadas.remove(tipo);
                  }),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCard(Map<String, int> data) {
    if (data.isEmpty) return const SizedBox();

    final total = data.values.fold(0, (a, b) => a + b);
    final maxEntry = data.entries.reduce((a, b) => a.value > b.value ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue.shade700),
                SizedBox(width: 8),
                Text('Resumen Estadístico',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    )),
              ],
            ),
            SizedBox(height: 12),
            _buildStatItem('📊 Total de alertas', '$total'),
            _buildStatItem('⚠️ Tipo más frecuente', '${maxEntry.key} (${maxEntry.value})'),
            SizedBox(height: 8),
            Text(_recomendacionPorTipo(maxEntry.key),
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _recomendacionPorTipo(String tipo) {
  tipo = tipo.toLowerCase();
  if (tipo.contains('helada')) {
    return '🌡️ Recomendación: Proteger cultivos y usar cobertores térmicos.';
  } else if (tipo.contains('sequía')) {
    return '💧 Recomendación: Implementar sistemas de riego eficiente.';
  } else if (tipo.contains('lluvia') || tipo.contains('inund')) {
    return '🌧️ Recomendación: Verificar drenajes y sistemas de control.';
  } else if (tipo.contains('viento')) {
    return '🌬️ Recomendación: Asegurar estructuras expuestas y monitorear ráfagas.';
  }
  return '📌 Recomendación: Mantener protocolos preventivos.';
}

  Widget _buildBarChart(Map<String, int> data, String titulo) {
    if (data.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay datos disponibles para los filtros seleccionados.'),
        ),
      );
    }

    final entries = data.entries.toList();
    final total = entries.fold(0, (s, e) => s + e.value);
    final maxValue = entries.fold(0, (max, e) => e.value > max ? e.value : max);

    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart, color: Colors.blue.shade700),
                    SizedBox(width: 8),
                    Text(titulo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        )),
                  ],
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxValue * 1.2,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.black87,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final key = entries[group.x.toInt()].key;
                            final val = rod.toY.toInt();
                            final pct = ((val / total) * 100).toStringAsFixed(1);
                            return BarTooltipItem(
                              '$key\n$val alertas ($pct%)',
                              const TextStyle(color: Colors.white, fontSize: 12),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= entries.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  entries[value.toInt()].key,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: max(1, (maxValue / 5).ceilToDouble()),
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: entries.map((entry) {
                        return BarChartGroupData(
                          x: entries.indexOf(entry),
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              width: 24,
                              borderRadius: BorderRadius.circular(4),
                              color: _colorPorTipo[entry.key] ?? Colors.grey,
                            )
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        _buildResumenCard(data),
        SizedBox(height: 16),
        _buildGraficasIndividuales(data),
      ],
    );
  }

  Widget _buildGraficasIndividuales(Map<String, int> data) {
    if (data.isEmpty || data.length <= 1) return SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gráficas Individuales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                )),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.entries.map((entry) {
                return ElevatedButton(
                  onPressed: () => setState(() => _tipoSeleccionado = 
                      _tipoSeleccionado == entry.key ? '' : entry.key),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tipoSeleccionado == entry.key 
                        ? _colorPorTipo[entry.key] 
                        : Colors.grey.shade200,
                    foregroundColor: _tipoSeleccionado == entry.key 
                        ? Colors.white 
                        : Colors.grey.shade800,
                  ),
                  child: Text(entry.key),
                );
              }).toList(),
            ),
            if (_tipoSeleccionado.isNotEmpty) ...[
              SizedBox(height: 16),
              _buildGraficaIndividual(_tipoSeleccionado),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGraficaIndividual(String tipo) {
    final datosFiltrados = _datos.where((d) {
      final tipoOriginal = d['tipo']?.toString().toLowerCase() ?? '';
      String tipoGeneral = 'Otro';
      if (tipoOriginal.contains('helada')) tipoGeneral = 'Helada';
      else if (tipoOriginal.contains('sequía')) tipoGeneral = 'Sequía';
      else if (tipoOriginal.contains('lluvia')) tipoGeneral = 'Lluvia';
      else if (tipoOriginal.contains('viento')) tipoGeneral = 'Viento';
      else if (tipoOriginal.contains('inund')) tipoGeneral = 'Inundación';
      else if (tipoOriginal.contains('manual')) tipoGeneral = 'Manual';
      return tipoGeneral == tipo;
    }).toList();

    if (datosFiltrados.isEmpty) {
      return Text('No hay datos detallados para $tipo');
    }

    // Agrupar por nivel para este tipo específico
    final Map<String, int> datosPorNivel = {};
    for (var item in datosFiltrados) {
      String nivel = item['nivel']?.toString().toLowerCase() ?? 'desconocido';
      final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;
      if (nivel.contains('moderado') || nivel.contains('medio')) nivel = 'Moderado';
      else if (nivel.contains('alto')) nivel = 'Alto';
      else if (nivel.contains('bajo')) nivel = 'Bajo';
      else nivel = 'Otro';
      datosPorNivel[nivel] = (datosPorNivel[nivel] ?? 0) + cantidad;
    }

    return Column(
      children: [
        Text('Distribución de $tipo por nivel de riesgo',
            style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: datosPorNivel.entries.map((entry) {
                final total = datosPorNivel.values.fold(0, (a, b) => a + b);
                final pct = (entry.value / total) * 100;
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  title: '${pct.toStringAsFixed(1)}%',
                  color: _colorPorTipo[entry.key] ?? Colors.grey,
                  radius: 60,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
              sectionsSpace: 0,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, int> data, String titulo) {
    if (data.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay datos disponibles para mostrar.'),
        ),
      );
    }

    final total = data.values.fold(0, (s, v) => s + v);
    final entries = data.entries.toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.blue.shade700),
                SizedBox(width: 8),
                Text(titulo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    )),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: entries.map((entry) {
                          final pct = (entry.value / total) * 100;
                          return PieChartSectionData(
                            value: entry.value.toDouble(),
                            title: '${pct.toStringAsFixed(1)}%',
                            color: _colorPorTipo[entry.key] ?? Colors.grey,
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 0,
                        centerSpaceRadius: 50,
                        startDegreeOffset: -90,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _colorPorTipo[entry.key],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('${entry.key} (${entry.value})',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tipoData = _agruparPorTipoSimplificado();
    final nivelData = _agruparPorNivel();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Estadísticas de Alertas'),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Análisis de Alertas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              )),
                          SizedBox(height: 8),
                          Text(
                            'Visualización estadística de las alertas registradas en el sistema. '
                            'Los datos se alinean con el ODS 13: Acción por el Clima.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildFiltros(),
                  _buildBarChart(tipoData, 'Distribución por Tipo de Alerta'),
                  SizedBox(height: 16),
                  _buildPieChart(nivelData, 'Distribución por Nivel de Riesgo'),
                ],
              ),
            ),
    );
  }
}