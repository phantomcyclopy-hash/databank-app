import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'models.dart';

class PdfRelatorioService {
  static Future<void> gerarEImprimirRelatorio(
    material.BuildContext context, {
    required ListaEntidades lista,
    required List<Entidade> entidades,
  }) async {
    final tituloCtrl = material.TextEditingController(text: lista.titulo);
    final comentarioCtrl = material.TextEditingController();
    bool incluirDataHora = true;

    final confirmar = await material.showDialog<bool>(
      context: context,
      builder: (context) => material.StatefulBuilder(
        builder: (context, setStateDialog) => material.AlertDialog(
          title: const material.Text('Configurar Relatório PDF'),
          content: material.SingleChildScrollView(
            child: material.Column(mainAxisSize: material.MainAxisSize.min, children: [
              material.TextField(
                controller: tituloCtrl,
                decoration: const material.InputDecoration(labelText: 'Título do Relatório'),
              ),
              const material.SizedBox(height: 12),
              material.TextField(
                controller: comentarioCtrl,
                maxLines: 3,
                decoration: const material.InputDecoration(
                  labelText: 'Comentário / Observações (Opcional)',
                  border: material.OutlineInputBorder(),
                ),
              ),
              const material.SizedBox(height: 12),
              material.SwitchListTile(
                title: const material.Text('Incluir Data, Hora e Ano no topo'),
                value: incluirDataHora,
                onChanged: (v) => setStateDialog(() => incluirDataHora = v),
              ),
            ]),
          ),
          actions: [
            material.TextButton(
              onPressed: () => material.Navigator.pop(context, false),
              child: const material.Text('Cancelar'),
            ),
            material.FilledButton(
              onPressed: () => material.Navigator.pop(context, true),
              child: const material.Text('Gerar e Imprimir / Partilhar'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true) return;

    final pdf = pw.Document();
    final agoraStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      tituloCtrl.text.trim().isEmpty ? lista.titulo : tituloCtrl.text,
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                    if (comentarioCtrl.text.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        comentarioCtrl.text,
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ],
                ),
                if (incluirDataHora)
                  pw.Text(
                    'Gerado em: $agoraStr',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: [
              'Nome / Item',
              ...lista.colunas.map((c) => c.nome),
            ],
            data: entidades.map((ent) {
              return [
                ent.nome,
                ...lista.colunas.map((coluna) {
                  final valor = ent.valoresAtributos[coluna.id];
                  return valor?.toString() ?? '—';
                }),
              ];
            }).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${lista.titulo}_relatorio.pdf',
    );
  }
}
