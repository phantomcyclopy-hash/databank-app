import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'models.dart';
import 'repository.dart';

class ImportExportService {
  
  /// Exporta uma lista específica para um ficheiro JSON e abre o menu de partilha/guardar
  static Future<void> exportarLista(BuildContext context, ListaEntidades lista, AppRepository repo) async {
    try {
      // Como o repositório atual foca em fluxos reativos, vamos buscar as entidades da lista
      // (Podes adaptar este passo conforme a tua preferência de leitura direta no repo)
      
      // Monta o mapa de dados completo da lista
      final dadosExportacao = {
        'versao': 1,
        'tipo': 'banco_dinamico_lista',
        'lista': lista.toMap(),
        'exportadoEm': DateTime.now().toIso8601String(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(dadosExportacao);

      // Salva num diretório temporário do telemóvel
      final output = await getTemporaryDirectory();
      final nomeFicheiro = lista.titulo.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final file = File('${output.path}/${nomeFicheiro}_backup.json');
      await file.writeAsString(jsonString);

      // Partilha / Guarda o ficheiro usando o share_plus
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Backup da lista: ${lista.titulo}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar: $e')),
      );
    }
  }

  /// Importa uma lista de um ficheiro JSON selecionado no telemóvel
  static Future<void> importarLista(BuildContext context, AppRepository repo) async {
    try {
      // Abre o seletor de ficheiros do telemóvel filtrando por json
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final conteudoJson = await file.readAsString();
        
        final mapaDados = jsonDecode(conteudoJson) as Map<String, dynamic>;

        if (mapaDados['tipo'] != 'banco_dinamico_lista') {
          throw 'O formato do ficheiro não é compatível com o Banco Dinâmico.';
        }

        final mapaLista = mapaDados['lista'] as Map<String, dynamic>;
        final listaImportada = ListaEntidades.fromMap(mapaLista);

        // Recria a lista no repositório com um novo ID para evitar conflitos de duplicação
        await repo.criarLista(
          titulo: '${listaImportada.titulo} (Importado)',
          descricao: listaImportada.descricao,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lista importada com sucesso!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao importar o ficheiro: $e')),
      );
    }
  }
}
