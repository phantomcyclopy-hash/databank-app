import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'models.dart';

class PdfRelatorioService {
  static Future<void> gerarEImprimirRelatorio(
    BuildContext context, {
    required ListaEntidades lista,
    required List<Entidade> entidades,
  }) async {
    // Controladores para o diálogo de customização
    final tituloCtrl = TextEditingController(text: lista.titulo);
    final comentarioCtrl = TextEditingController();
    bool incluirDataHora = true;

    // 1. Janela de diálogo para customizar o relatório antes de exportar
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Configurar Relatório PDF'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: tituloCtrl,
                decoration: const InputDecoration(labelText: 'Título do Relatório'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: comentarioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentário / Observações (Opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Incluir Data, Hora e Ano no topo'),
                value: incluirDataHora,
                onChanged: (v) => setStateDialog(() => incluirDataHora = v),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Gerar e Imprimir / Partilhar'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true) return;

    // 2. Construção do documento PDF
    final pdf = pw.Document();
    final agoraStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // Formato paisagem ótimo para grades
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          // Cabeçalho
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
                        style: const TextStyle(fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ],
                ),
                if (incluirDataHora)
                  pw.Text(
                    'Gerado em: $agoraStr',
                    style: const TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Tabela Estilo Grade
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

    // 3. Abre o painel nativo de impressão / partilha do dispositivo (Android / Windows / etc.)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${lista.titulo}_relatorio.pdf',
    );
  }
}
