import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:punch_app/data/helper/download_helper.dart';
import 'package:punch_app/data/helper/file_helper_native.dart';
import 'package:punch_app/data/models/attendance_log_model.dart';

// ─── PDF ─────────────────────────────────────────────────────────────────────
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ─── Excel ───────────────────────────────────────────────────────────────────
import 'package:excel/excel.dart';

// ─── File I/O ─────────────────────────────────────────────────────────
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';


class AttendanceExportService {
  // ─────────────────────────── helpers ──────────────────────────────────────

  static String _fmtTime(DateTime dt) => DateFormat('HH:mm').format(dt);
  static String _fmtDate(DateTime d)  => DateFormat('dd/MM/yyyy').format(d);

  static String _totalHrs(int totalMins) {
    if (totalMins <= 0) return '-';          // ASCII dash — no Unicode em-dash
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PDF EXPORT
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> exportPDF({
    required BuildContext context,
    required List<Map<String, dynamic>> rows,
    required DateTime fromDate,
    required DateTime toDate,
    required String companyName,
  }) async {
    final pdf = pw.Document();

    // ── colours (PdfColor components, no fromHex to avoid parse edge cases) ──
    const headerBg   = PdfColor(0.231, 0.357, 0.859);
    const rowAltBg   = PdfColor(0.973, 0.980, 0.988);
    const successClr = PdfColor(0.086, 0.639, 0.369);
    const errorClr   = PdfColor(0.863, 0.149, 0.149);
    const mutedClr   = PdfColor(0.580, 0.639, 0.722);
    const txtPrimary = PdfColor(0.059, 0.090, 0.165);
    const txtSec     = PdfColor(0.282, 0.337, 0.412);
    const greenBadge = PdfColor(0.863, 0.988, 0.902);
    const greyBadge  = PdfColor(0.930, 0.930, 0.930);
    const manualBg   = PdfColor(0.996, 0.953, 0.773);
    const manualClr  = PdfColor(0.855, 0.549, 0.024);

    // ── Use built-in Helvetica BUT load a TTF fallback for non-Latin chars ───
    // We avoid ALL Unicode special chars in strings, so Helvetica works fine.
    final font         = pw.Font.helvetica();
    final fontBold     = pw.Font.helveticaBold();

    // ── stats ─────────────────────────────────────────────────────────────
    final totalMinsAll =
        rows.fold<int>(0, (s, r) => s + (r['totalMins'] as int? ?? 0));
    final avgMins = rows.isNotEmpty ? totalMinsAll ~/ rows.length : 0;

    // Date range as ASCII only: "01 May 2026 to 27 May 2026"
    final dateRange =
        '${DateFormat('dd MMM yyyy').format(fromDate)} to ${DateFormat('dd MMM yyyy').format(toDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 26),

        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const pw.BoxDecoration(
                color: headerBg,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ATTENDANCE REPORT',
                          style: pw.TextStyle(
                              font: fontBold, fontSize: 14,
                              color: PdfColors.white)),
                      pw.SizedBox(height: 2),
                      pw.Text(companyName,
                          style: pw.TextStyle(
                              font: font, fontSize: 9,
                              color: PdfColors.white)),
                    ],
                  ),
                  pw.Text(dateRange,
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 9,
                          color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _statCard('Records', '${rows.length}', fontBold, font),
                pw.SizedBox(width: 8),
                _statCard('Total Hours', _totalHrs(totalMinsAll), fontBold, font),
                pw.SizedBox(width: 8),
                _statCard('Avg / Day', _totalHrs(avgMins), fontBold, font),
              ],
            ),
            pw.SizedBox(height: 4),
          ],
        ),

        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey500),
              ),
              pw.Text(
                'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey500),
              ),
            ],
          ),
        ),

        build: (_) => [
          pw.SizedBox(height: 10),

          // Table header row
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: const pw.BoxDecoration(
              color: headerBg,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(flex: 3, child: _th('Employee', fontBold)),
                pw.Expanded(flex: 2, child: _th('Date', fontBold)),
                pw.Expanded(flex: 5, child: _th('Punch History', fontBold)),
                pw.Expanded(flex: 2, child: _th('Total Hrs', fontBold, center: true)),
              ],
            ),
          ),

          // Data rows
          ...rows.asMap().entries.map((entry) {
            final idx     = entry.key;
            final row     = entry.value;
            final emp     = row['employee']  as dynamic;
            final date    = row['date']      as DateTime;
            final inLogs  = row['inLogs']    as List<AttendanceLogModel>;
            final outLogs = row['outLogs']   as List<AttendanceLogModel>;
            final totalMins = row['totalMins'] as int? ?? 0;
            final empName = emp?.fullName         as String? ?? 'Unknown';
            final empCode = emp?.employeeCode     as String? ?? '';
            final dept    = emp?.department?.name as String? ?? '';
            final isManual = (inLogs + outLogs).any((l) => l.isManual);
            final bg = idx.isEven ? PdfColors.white : rowAltBg;

            // ASCII-only time strings: "(M)" instead of Unicode superscript
            final inStr  = inLogs.isEmpty  ? '-'
                : inLogs.map((l)  => '${_fmtTime(l.punchTime)}${l.isManual ? "(M)" : "(F)"}').join('  ');
            final outStr = outLogs.isEmpty ? '-'
                : outLogs.map((l) => '${_fmtTime(l.punchTime)}${l.isManual ? "(M)" : "(F)"}').join('  ');

            return pw.Container(
              decoration: pw.BoxDecoration(
                color: bg,
                border: const pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200),
                  left:   pw.BorderSide(color: PdfColors.grey200),
                  right:  pw.BorderSide(color: PdfColors.grey200),
                ),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Employee
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(empName,
                            style: pw.TextStyle(
                                font: fontBold, fontSize: 9,
                                color: txtPrimary)),
                        if (empCode.isNotEmpty)
                          pw.Text(empCode,
                              style: pw.TextStyle(
                                  font: font, fontSize: 7.5,
                                  color: mutedClr)),
                        if (dept.isNotEmpty)
                          pw.Text(dept,
                              style: pw.TextStyle(
                                  font: font, fontSize: 7.5,
                                  color: mutedClr)),
                      ],
                    ),
                  ),
                  // Date
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(_fmtDate(date),
                        style: pw.TextStyle(
                            font: fontBold, fontSize: 9,
                            color: txtSec)),
                  ),
                  // Punch history
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _punchLine(
                          label: 'IN',
                          times: inStr,
                          labelBg: inLogs.isNotEmpty ? successClr : greyBadge,
                          font: font,
                          fontBold: fontBold,
                        ),
                        pw.SizedBox(height: 3),
                        _punchLine(
                          label: 'OUT',
                          times: outStr,
                          labelBg: outLogs.isNotEmpty ? errorClr : greyBadge,
                          font: font,
                          fontBold: fontBold,
                        ),
                      ],
                    ),
                  ),
                  // Total hours badge
                  pw.Expanded(
                    flex: 2,
                    child: pw.Center(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: totalMins > 0 ? greenBadge : greyBadge,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          _totalHrs(totalMins),
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 9,
                            color: totalMins > 0 ? successClr : mutedClr,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            );
          }),

          pw.SizedBox(height: 10),
          // Legend — ASCII only
          pw.Row(
            children: [
              _dot(successClr), pw.SizedBox(width: 3),
              pw.Text('IN   ',
                  style: pw.TextStyle(font: font, fontSize: 8, color: mutedClr)),
              _dot(errorClr), pw.SizedBox(width: 3),
              pw.Text('OUT   ',
                  style: pw.TextStyle(font: font, fontSize: 8, color: mutedClr)),
              pw.Text('  (M) = Manual   (F) = Face/Device',
                  style: pw.TextStyle(font: font, fontSize: 8, color: mutedClr)),
            ],
          ),
        ],
      ),
    );

    final filename =
        'Attendance_${DateFormat('ddMMyyyy').format(fromDate)}_${DateFormat('ddMMyyyy').format(toDate)}.pdf';
    final pdfBytes = await pdf.save();

    await _saveAndOpen(
      context: context,
      bytes: Uint8List.fromList(pdfBytes),
      filename: filename,
      mimeType: 'application/pdf',
    );
  }

  // ── PDF widget helpers ─────────────────────────────────────────────────────

  static pw.Widget _statCard(
      String label, String value, pw.Font fontBold, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  font: fontBold, fontSize: 11,
                  color: const PdfColor(0.059, 0.090, 0.165))),
          pw.Text(label,
              style: pw.TextStyle(
                  font: font, fontSize: 7.5,
                  color: const PdfColor(0.580, 0.639, 0.722))),
        ],
      ),
    );
  }

  static pw.Widget _th(String label, pw.Font font, {bool center = false}) {
    return pw.Text(label,
        style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.white),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left);
  }

  static pw.Widget _punchLine({
    required String label,
    required String times,
    required PdfColor labelBg,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 24,
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: pw.BoxDecoration(
            color: labelBg,
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Text(label,
              style: pw.TextStyle(
                  font: fontBold, fontSize: 7,
                  color: PdfColors.white),
              textAlign: pw.TextAlign.center),
        ),
        pw.SizedBox(width: 5),
        pw.Flexible(
          child: pw.Text(times,
              style: pw.TextStyle(
                  font: font, fontSize: 8.5,
                  color: const PdfColor(0.059, 0.090, 0.165))),
        ),
      ],
    );
  }

  static pw.Widget _dot(PdfColor color) {
    return pw.Container(
      width: 7, height: 7,
      decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  EXCEL EXPORT
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> exportExcel({
    required BuildContext context,
    required List<Map<String, dynamic>> rows,
    required DateTime fromDate,
    required DateTime toDate,
    required String companyName,
  }) async {
    final excel = Excel.createExcel();

    // Create the target sheet FIRST, then delete the default Sheet1.
    // The excel package refuses to delete the last remaining sheet,
    // so we must ensure another sheet exists before calling delete().
    final sheet = excel['Attendance Report'];
    _writeAttendanceSheet(sheet, rows, fromDate, toDate, companyName);

    // Delete any default sheets the package auto-creates.
    for (final defaultName in ['Sheet1', 'FlutterExcel']) {
      if (excel.sheets.containsKey(defaultName)) {
        excel.delete(defaultName);
      }
    }

    // Use encode() instead of save() — save() triggers its own browser download
    // on web as a side-effect, causing the double-download issue.
    final bytes = excel.encode();
    if (bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate Excel file'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final filename =
        'Attendance_${DateFormat("ddMMyyyy").format(fromDate)}_${DateFormat("ddMMyyyy").format(toDate)}.xlsx';

    await _saveAndOpen(
      context: context,
      bytes: Uint8List.fromList(bytes),
      filename: filename,
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  // ─── Single-sheet writer ───────────────────────────────────────────────────

  static void _writeAttendanceSheet(
    Sheet sheet,
    List<Map<String, dynamic>> rows,
    DateTime fromDate,
    DateTime toDate,
    String companyName,
  ) {
    final dateRange =
        '${DateFormat('dd MMM yyyy').format(fromDate)} - ${DateFormat('dd MMM yyyy').format(toDate)}';
    final totalMinsAll =
        rows.fold<int>(0, (s, r) => s + (r['totalMins'] as int? ?? 0));
    final avgMins = rows.isNotEmpty ? totalMinsAll ~/ rows.length : 0;

    // Row 0: title
    final t = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    t.value = TextCellValue('ATTENDANCE REPORT  |  $dateRange');
    // Span title across columns A-G so it's fully visible
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0));
    t.cellStyle = CellStyle(
      bold: true, fontSize: 13,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#3B5BDB'),
    );

    // Row 1: stats
    final s = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    s.value = TextCellValue(
        'Records: ${rows.length}     '
        'Total Hours: ${_totalHrs(totalMinsAll)}     '
        'Avg/Day: ${_totalHrs(avgMins)}     '
        'Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}');
    s.cellStyle = CellStyle(
      italic: true, fontSize: 9,
      fontColorHex: ExcelColor.fromHexString('#475569'),
    );
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 1));

    // Row 2: spacer
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value =  TextCellValue('');

    // Row 3: column headers
    const headers = [
      'Emp Code', 'Employee Name', 'Department',
      'Date', 'IN Punches', 'OUT Punches', 'Total Hours',
    ];
    for (var c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = CellStyle(
        bold: true, fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#3B5BDB'),
      );
    }

    // Rows 4+: data
    for (var i = 0; i < rows.length; i++) {
      final row     = rows[i];
      final emp     = row['employee']  as dynamic;
      final date    = row['date']      as DateTime;
      final inLogs  = row['inLogs']    as List<AttendanceLogModel>;
      final outLogs = row['outLogs']   as List<AttendanceLogModel>;
      final totalMins = row['totalMins'] as int? ?? 0;
      final r = 4 + i;
      final rowBg = i.isEven
          ? ExcelColor.fromHexString('#FFFFFF')
          : ExcelColor.fromHexString('#F8FAFC');

      final inStr  = inLogs.isEmpty  ? '-'
          : inLogs.map((l)  => '${_fmtTime(l.punchTime)}${l.isManual ? "(M)" : "(F)"}').join('   ');
      final outStr = outLogs.isEmpty ? '-'
          : outLogs.map((l) => '${_fmtTime(l.punchTime)}${l.isManual ? "(M)" : "(F)"}').join('   ');

      void writeCell(int col, String val,
          {bool bold = false, String fgHex = '#0F172A'}) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: r));
        cell.value = TextCellValue(val);
        cell.cellStyle = CellStyle(
          bold: bold, fontSize: 10,
          backgroundColorHex: rowBg,
          fontColorHex: ExcelColor.fromHexString(fgHex),
        );
      }

      writeCell(0, emp?.employeeCode     as String? ?? '');
      writeCell(1, emp?.fullName         as String? ?? 'Unknown', bold: true);
      writeCell(2, emp?.department?.name as String? ?? '');
      writeCell(3, _fmtDate(date));
      writeCell(4, inStr,  fgHex: inLogs.isNotEmpty  ? '#16A34A' : '#94A3B8');
      writeCell(5, outStr, fgHex: outLogs.isNotEmpty ? '#DC2626' : '#94A3B8');
      writeCell(6, _totalHrs(totalMins),
          bold: totalMins > 0,
          fgHex: totalMins > 0 ? '#16A34A' : '#94A3B8');
    }

    sheet.setColumnWidth(0, 16);
    sheet.setColumnWidth(1, 26);
    sheet.setColumnWidth(2, 24);
    sheet.setColumnWidth(3, 14);
    sheet.setColumnWidth(4, 45);
    sheet.setColumnWidth(5, 45);
    sheet.setColumnWidth(6, 14);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SHARED SAVE + OPEN
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _saveAndOpen({
    required BuildContext context,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    if (kIsWeb) {
      // Web: inject a temporary <a download> element and click it
      _webDownload(bytes: bytes, filename: filename, mimeType: mimeType);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading $filename...'),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Mobile / Desktop: save to documents then open
      final dir  = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$filename';
      await writeFileBytes(path, bytes);
      await OpenFile.open(path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: $filename'),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Triggers a browser file download — delegates to dart:html helper.
  static void _webDownload({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) {
    triggerWebDownload(bytes: bytes, filename: filename, mimeType: mimeType);
  }
}