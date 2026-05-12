import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/energy_history.dart';
import '../providers/history_provider.dart';

class ReportService {
  // ── PDF ─────────────────────────────────────────────────────────────────────

  static Future<void> exportarPDF(
    BuildContext context,
    List<EnergyPoint> puntos,
    HistoryProvider history,
  ) async {
    final Uint8List bytes = await _buildPdf(puntos, history);
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  static Future<Uint8List> _buildPdf(
    List<EnergyPoint> puntos,
    HistoryProvider history,
  ) async {
    final doc = pw.Document();
    final ahora = DateTime.now();
    final fecha =
        '${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year}'
        '  ${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';
    final rango = _etiquetaRango(history.horasEnergy);

    final headerStyle = pw.TextStyle(
      color: PdfColors.white,
      fontWeight: pw.FontWeight.bold,
    );
    const headerDeco = pw.BoxDecoration(color: PdfColor.fromInt(0xFF37474F));
    const oddDeco = pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F5F5));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => [
          // ── Encabezado ──────────────────────────────────────────────────────
          pw.Text(
            'Reporte de Consumo Eléctrico',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generado: $fecha   ·   Período: $rango   ·   Registros: ${puntos.length}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Divider(height: 24, color: PdfColors.blueGrey200),

          // ── Resumen ΔkWh ────────────────────────────────────────────────────
          pw.Text(
            'Consumo por zona (ΔkWh)',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Zona', 'ΔkWh', 'Potencia prom. (W)'],
            data: [
              [
                'Sala / Cuarto / Baño',
                history.deltaKwhSala.toStringAsFixed(4),
                history.avgPowerSala.toStringAsFixed(1),
              ],
              [
                'Cocina',
                history.deltaKwhCocina.toStringAsFixed(4),
                history.avgPowerCocina.toStringAsFixed(1),
              ],
              [
                'Aire Acondicionado',
                history.deltaKwhAc.toStringAsFixed(4),
                history.avgPowerAc.toStringAsFixed(1),
              ],
              ['TOTAL', history.deltaKwhTotal.toStringAsFixed(4), '—'],
            ],
            headerStyle: headerStyle,
            headerDecoration: headerDeco,
            oddRowDecoration: oddDeco,
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
            },
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
            },
          ),

          pw.SizedBox(height: 24),

          // ── Datos históricos ────────────────────────────────────────────────
          pw.Text(
            'Datos históricos',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: [
              'Hora',
              'Sala (W)',
              'Cocina (W)',
              'A/C (W)',
              'Total (W)',
              'Sala (kWh)',
              'Cocina (kWh)',
              'A/C (kWh)',
            ],
            data: puntos.map((p) {
              final h = p.timestamp.hour.toString().padLeft(2, '0');
              final m = p.timestamp.minute.toString().padLeft(2, '0');
              return [
                '$h:$m',
                p.sala.toStringAsFixed(1),
                p.cocina.toStringAsFixed(1),
                p.ac.toStringAsFixed(1),
                p.total.toStringAsFixed(1),
                p.salaKwh.toStringAsFixed(4),
                p.cocinaKwh.toStringAsFixed(4),
                p.acKwh.toStringAsFixed(4),
              ];
            }).toList(),
            headerStyle: headerStyle,
            headerDecoration: headerDeco,
            oddRowDecoration: oddDeco,
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerCellDecoration: headerDeco,
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
              7: pw.Alignment.center,
            },
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ── CSV ─────────────────────────────────────────────────────────────────────

  static Future<void> exportarCSV(List<EnergyPoint> puntos, int horas) async {
    final buf = StringBuffer();
    buf.writeln(
      'timestamp,sala_w,cocina_w,ac_w,total_w,sala_kwh,cocina_kwh,ac_kwh',
    );
    for (final p in puntos) {
      buf.writeln(
        '${p.timestamp.toIso8601String()},'
        '${p.sala.toStringAsFixed(2)},'
        '${p.cocina.toStringAsFixed(2)},'
        '${p.ac.toStringAsFixed(2)},'
        '${p.total.toStringAsFixed(2)},'
        '${p.salaKwh.toStringAsFixed(4)},'
        '${p.cocinaKwh.toStringAsFixed(4)},'
        '${p.acKwh.toStringAsFixed(4)}',
      );
    }

    final nombre =
        'smarthome_${_etiquetaRango(horas).replaceAll(' ', '_')}.csv';
    final bytes = Uint8List.fromList(utf8.encode(buf.toString()));

    await Share.shareXFiles([
      XFile.fromData(bytes, mimeType: 'text/csv', name: nombre),
    ], subject: 'Datos Smart Home — ${_etiquetaRango(horas)}');
  }

  // ── Diálogo de selección ─────────────────────────────────────────────────────

  static void mostrarDialogo(
    BuildContext context,
    List<EnergyPoint> puntos,
    HistoryProvider history,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Exportar reporte',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf,
                color: Color(0xFFEF5350),
              ),
              title: const Text(
                'PDF  (vista previa / imprimir)',
                style: TextStyle(color: Colors.white70),
              ),
              subtitle: Text(
                'Resumen + tabla de datos',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                exportarPDF(context, puntos, history);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Color(0xFF66BB6A)),
              title: const Text(
                'CSV  (hoja de cálculo)',
                style: TextStyle(color: Colors.white70),
              ),
              subtitle: Text(
                'Ideal para análisis en Excel / Python',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                exportarCSV(puntos, history.horasEnergy);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static String _etiquetaRango(int horas) {
    if (horas == 1) return 'Ultima_hora';
    if (horas == 24) return 'Ultimas_24h';
    return 'Ultimos_7_dias';
  }
}
