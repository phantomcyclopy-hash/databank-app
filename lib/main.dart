import 'dart00:00:00.000'; // reservado
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DatabankApp());
}

class DatabankApp extends StatefulWidget {
  const DatabankApp({super.key});

  @override
  State<DatabankApp> createState() => _DatabankAppState();
}

class _DatabankAppState extends State<DatabankApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.dark;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Databank',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: ListasPage(
        onToggleTheme: _toggleTheme,
        currentThemeMode: _themeMode,
      ),
    );
  }
}

class ListasPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode currentThemeMode;

  const ListasPage({
    super.key,
    required this.onToggleTheme,
    required this.currentThemeMode,
  });

  @override
  State<ListasPage> createState() => _ListasPageState();
}

class _ListasPageState extends State<ListasPage> {
  final List<ListaEntidades> _listas = [];
  final Uuid _uuid = const Uuid();

  Color _converterHexParaColor(String hex) {
    try {
      String cleanHex = hex.replaceAll('#', '').trim();
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse('0x$cleanHex'));
    } catch (_) {
      return Colors.blue;
    }
  }

  String _converterColorParaHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  void _abrirSeletorCorHex(Color corAtual, Function(Color) onColorSelected) {
    Color tempColor = corAtual;
    final hexController = TextEditingController(text: _converterColorParaHex(corAtual));

    final List<Color> coresRapidas = [
      Colors.blue,
      Colors.indigo,
      Colors.teal,
      Colors.green,
      Colors.amber,
      Colors.deepOrange,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.blueGrey,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setPickerState) {
          return AlertDialog(
            title: const Text('Escolher Cor do Tema'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: tempColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hexController,
                    decoration: const InputDecoration(
                      labelText: 'Código Hexadecimal / RGB',
                      hintText: '#FF0000 ou #00FF00',
                      prefixIcon: Icon(Icons.color_lens),
                    ),
                    onChanged: (val) {
                      if (val.length == 7 || val.length == 9) {
                        setPickerState(() {
                          tempColor = _converterHexParaColor(val);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Paleta Rápida:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: coresRapidas.map((c) {
                      return GestureDetector(
                        onTap: () {
                          setPickerState(() {
                            tempColor = c;
                            hexController.text = _converterColorParaHex(c);
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: c,
                          radius: 18,
                          child: tempColor.value == c.value
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  onColorSelected(tempColor);
                  Navigator.pop(ctx);
                },
                child: const Text('Selecionar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _criarNovaLista() {
    final titleController = TextEditingController();
    Color corSelecionada = Colors.blue;
    bool mostrarData = true;
    String formatoData = 'dd/mm/aaaa';
    bool mostrarHora = true;
    String formatoHora = '24h';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Nova Lista / Tabela'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título da Tabela',
                      hintText: 'Ex: Finanças, Tarefas, Inventário',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cor da Grade / Tema'),
                    trailing: CircleAvatar(
                      backgroundColor: corSelecionada,
                      radius: 16,
                    ),
                    onTap: () {
                      _abrirSeletorCorHex(corSelecionada, (novaCor) {
                        setDialogState(() => corSelecionada = novaCor);
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mostrar Data'),
                    value: mostrarData,
                    onChanged: (v) => setDialogState(() => mostrarData = v),
                  ),
                  if (mostrarData)
                    DropdownButtonFormField<String>(
                      value: formatoData,
                      decoration: const InputDecoration(labelText: 'Formato da Data'),
                      items: const [
                        DropdownMenuItem(value: 'dd/mm/aaaa', child: Text('dd/mm/aaaa')),
                        DropdownMenuItem(value: 'mm/aaaa', child: Text('mm/aaaa')),
                      ],
                      onChanged: (v) => setDialogState(() => formatoData = v!),
                    ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mostrar Hora'),
                    value: mostrarHora,
                    onChanged: (v) => setDialogState(() => mostrarHora = v),
                  ),
                  if (mostrarHora)
                    DropdownButtonFormField<String>(
                      value: formatoHora,
                      decoration: const InputDecoration(labelText: 'Formato da Hora'),
                      items: const [
                        DropdownMenuItem(value: '24h', child: Text('24 horas (14:30)')),
                        DropdownMenuItem(value: '12h', child: Text('12 horas (02:30 PM)')),
                      ],
                      onChanged: (v) => setDialogState(() => formatoHora = v!),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final titulo = titleController.text.trim();
                  if (titulo.isEmpty) return;

                  final novaLista = ListaEntidades(
                    id: _uuid.v4(),
                    titulo: titulo,
                    mostrarData: mostrarData,
                    formatoData: formatoData,
                    mostrarHora: mostrarHora,
                    formatoHora: formatoHora,
                    corTema: _converterColorParaHex(corSelecionada),
                    colunas: [
                      ColunaEspecificacao(id: _uuid.v4(), nome: 'Item', tipo: 'texto'),
                      ColunaEspecificacao(id: _uuid.v4(), nome: 'Valor', tipo: 'numero'),
                    ],
                    linhas: [],
                  );

                  setState(() {
                    _listas.add(novaLista);
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Criar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _importarListaJSON() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.bytes != null) {
        final jsonString = utf8.decode(result.files.single.bytes!);
        final Map<String, dynamic> jsonData = jsonDecode(jsonString);

        final listaImportada = ListaEntidades.fromJson(jsonData);

        setState(() {
          listaImportada.id = _uuid.v4();
          _listas.add(listaImportada);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lista importada com sucesso!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao importar ficheiro: $e')),
      );
    }
  }

  void _renomearEConfigurarLista(ListaEntidades lista) {
    final titleController = TextEditingController(text: lista.titulo);
    Color corSelecionada = _converterHexParaColor(lista.corTema);
    bool mostrarData = lista.mostrarData;
    String formatoData = lista.formatoData;
    bool mostrarHora = lista.mostrarHora;
    String formatoHora = lista.formatoHora;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Configurar Tabela'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cor da Grade / Tema'),
                    trailing: CircleAvatar(
                      backgroundColor: corSelecionada,
                      radius: 16,
                    ),
                    onTap: () {
                      _abrirSeletorCorHex(corSelecionada, (novaCor) {
                        setDialogState(() => corSelecionada = novaCor);
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mostrar Data'),
                    value: mostrarData,
                    onChanged: (v) => setDialogState(() => mostrarData = v),
                  ),
                  if (mostrarData)
                    DropdownButtonFormField<String>(
                      value: formatoData,
                      decoration: const InputDecoration(labelText: 'Formato da Data'),
                      items: const [
                        DropdownMenuItem(value: 'dd/mm/aaaa', child: Text('dd/mm/aaaa')),
                        DropdownMenuItem(value: 'mm/aaaa', child: Text('mm/aaaa')),
                      ],
                      onChanged: (v) => setDialogState(() => formatoData = v!),
                    ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mostrar Hora'),
                    value: mostrarHora,
                    onChanged: (v) => setDialogState(() => mostrarHora = v),
                  ),
                  if (mostrarHora)
                    DropdownButtonFormField<String>(
                      value: formatoHora,
                      decoration: const InputDecoration(labelText: 'Formato da Hora'),
                      items: const [
                        DropdownMenuItem(value: '24h', child: Text('24 horas (14:30)')),
                        DropdownMenuItem(value: '12h', child: Text('12 horas (02:30 PM)')),
                      ],
                      onChanged: (v) => setDialogState(() => formatoHora = v!),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    lista.titulo = titleController.text.trim();
                    lista.corTema = _converterColorParaHex(corSelecionada);
                    lista.mostrarData = mostrarData;
                    lista.formatoData = formatoData;
                    lista.mostrarHora = mostrarHora;
                    lista.formatoHora = formatoHora;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _abrirDetalhesGrelha(ListaEntidades lista) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalhesGrelhaPage(
          lista: lista,
          onSalvar: () => setState(() {}),
          converterHex: _converterHexParaColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Databank'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Importar Lista (JSON)',
            onPressed: _importarListaJSON,
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Alternar Modo Escuro',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: _listas.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma lista cadastrada.\nToque no botão + ou importe um ficheiro JSON.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _listas.length,
              itemBuilder: (context, index) {
                final lista = _listas[index];
                final cor = _converterHexParaColor(lista.corTema);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cor,
                      child: Icon(
                        lista.isLocked ? Icons.lock : Icons.table_chart,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      lista.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${lista.linhas.length} registos | ${lista.colunas.length} colunas'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            lista.isLocked ? Icons.lock : Icons.lock_open,
                            color: lista.isLocked ? Colors.red : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              lista.isLocked = !lista.isLocked;
                            });
                          },
                        ),
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'editar') _renomearEConfigurarLista(lista);
                            if (val == 'excluir') {
                              setState(() => _listas.removeAt(index));
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'editar', child: Text('Editar / Configurações')),
                            const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => _abrirDetalhesGrelha(lista),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _criarNovaLista,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DetalhesGrelhaPage extends StatefulWidget {
  final ListaEntidades lista;
  final VoidCallback onSalvar;
  final Color Function(String) converterHex;

  const DetalhesGrelhaPage({
    super.key,
    required this.lista,
    required this.onSalvar,
    required this.converterHex,
  });

  @override
  State<DetalhesGrelhaPage> createState() => _DetalhesGrelhaPageState();
}

class _DetalhesGrelhaPageState extends State<DetalhesGrelhaPage> {
  final Uuid _uuid = const Uuid();

  String _formatarDataHoraAtual() {
    final agora = DateTime.now();
    String dataStr = '';
    String horaStr = '';

    if (widget.lista.mostrarData) {
      if (widget.lista.formatoData == 'mm/aaaa') {
        dataStr = DateFormat('MM/yyyy').format(agora);
      } else {
        dataStr = DateFormat('dd/MM/yyyy').format(agora);
      }
    }

    if (widget.lista.mostrarHora) {
      if (widget.lista.formatoHora == '12h') {
        horaStr = DateFormat('hh:mm a').format(agora);
      } else {
        horaStr = DateFormat('HH:mm').format(agora);
      }
    }

    if (dataStr.isNotEmpty && horaStr.isNotEmpty) {
      return '$dataStr $horaStr';
    }
    return dataStr.isNotEmpty ? dataStr : horaStr;
  }

  void _adicionarColuna() {
    if (widget.lista.isLocked) return;

    final nomeController = TextEditingController();
    String tipoSelecionado = 'texto';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Nova Coluna'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome da Coluna'),
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: tipoSelecionado,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'texto', child: Text('Texto')),
                    DropdownMenuItem(value: 'numero', child: Text('Número')),
                    DropdownMenuItem(value: 'checkbox', child: Text('Checkbox')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => tipoSelecionado = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  final nome = nomeController.text.trim();
                  if (nome.isEmpty) return;

                  setState(() {
                    widget.lista.colunas.add(
                      ColunaEspecificacao(id: _uuid.v4(), nome: nome, tipo: tipoSelecionado),
                    );
                  });
                  widget.onSalvar();
                  Navigator.pop(ctx);
                },
                child: const Text('Adicionar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _opcoesColuna(ColunaEspecificacao col) {
    if (widget.lista.isLocked) return;

    final controller = TextEditingController(text: col.nome);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Gerenciar Coluna "${col.nome}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Novo Nome da Coluna'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                widget.lista.colunas.removeWhere((c) => c.id == col.id);
                for (var linha in widget.lista.linhas) {
                  linha.valores.remove(col.id);
                }
              });
              widget.onSalvar();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir Coluna'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final novoNome = controller.text.trim();
              if (novoNome.isNotEmpty) {
                setState(() {
                  col.nome = novoNome;
                });
                widget.onSalvar();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _adicionarLinha() {
    if (widget.lista.isLocked) return;

    final Map<String, String> novosValores = {};
    for (var col in widget.lista.colunas) {
      novosValores[col.id] = col.tipo == 'checkbox' ? 'false' : '';
    }

    if (widget.lista.mostrarData || widget.lista.mostrarHora) {
      novosValores['_dataHora'] = _formatarDataHoraAtual();
    }

    setState(() {
      widget.lista.linhas.add(
        Entidade(id: _uuid.v4(), valores: novosValores),
      );
    });
    widget.onSalvar();
  }

  Future<void> _exportarEImprimirPDF() async {
    final pdf = pw.Document();

    final headers = <String>[];
    if (widget.lista.mostrarData || widget.lista.mostrarHora) {
      headers.add('Data/Hora');
    }
    headers.addAll(widget.lista.colunas.map((c) => c.nome));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(widget.lista.titulo, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: headers,
              data: widget.lista.linhas.map((linha) {
                final rowData = <String>[];
                if (widget.lista.mostrarData || widget.lista.mostrarHora) {
                  rowData.add(linha.valores['_dataHora'] ?? '');
                }
                rowData.addAll(widget.lista.colunas.map((col) {
                  return linha.valores[col.id] ?? '';
                }));
                return rowData;
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  void _exportarJSON() {
    final jsonStr = jsonEncode(widget.lista.toJson());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportar Dados (JSON)'),
        content: SingleChildScrollView(
          child: SelectableText(jsonStr),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final corTema = widget.converterHex(widget.lista.corTema);
    final incluirDataHora = widget.lista.mostrarData || widget.lista.mostrarHora;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lista.titulo),
        backgroundColor: corTema,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir / Salvar PDF',
            onPressed: _exportarEImprimirPDF,
          ),
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'Exportar JSON',
            onPressed: _exportarJSON,
          ),
          IconButton(
            icon: const Icon(Icons.view_column),
            tooltip: 'Adicionar Coluna',
            onPressed: widget.lista.isLocked ? null : _adicionarColuna,
          ),
        ],
      ),
      body: widget.lista.colunas.isEmpty
          ? const Center(child: Text('Adicione colunas para começar a montar sua tabela.'))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(corTema.withOpacity(0.15)),
                  border: TableBorder.all(
                    color: corTema.withOpacity(0.4),
                    width: 1,
                  ),
                  columns: [
                    if (incluirDataHora)
                      const DataColumn(
                        label: Text(
                          'Data/Hora',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ...widget.lista.colunas.map((col) {
                      return DataColumn(
                        label: InkWell(
                          onTap: () => _opcoesColuna(col),
                          child: Row(
                            children: [
                              Text(
                                col.nome,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  rows: widget.lista.linhas.map((linha) {
                    return DataRow(
                      cells: [
                        if (incluirDataHora)
                          DataCell(
                            Text(
                              linha.valores['_dataHora'] ?? '',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ...widget.lista.colunas.map((col) {
                          final val = linha.valores[col.id] ?? '';

                          if (col.tipo == 'checkbox') {
                            final isChecked = val.toLowerCase() == 'true';
                            return DataCell(
                              Checkbox(
                                value: isChecked,
                                activeColor: corTema,
                                onChanged: widget.lista.isLocked
                                    ? null
                                    : (bool? nv) {
                                        setState(() {
                                          linha.valores[col.id] = (nv ?? false).toString();
                                        });
                                        widget.onSalvar();
                                      },
                              ),
                            );
                          }

                          return DataCell(
                            Text(val.isEmpty ? '-' : val),
                            showEditIcon: !widget.lista.isLocked,
                            onTap: widget.lista.isLocked
                                ? null
                                : () {
                                    final controller = TextEditingController(text: val);
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text('Editar ${col.nome}'),
                                        content: TextField(
                                          controller: controller,
                                          keyboardType: col.tipo == 'numero'
                                              ? TextInputType.number
                                              : TextInputType.text,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                linha.valores[col.id] = controller.text;
                                              });
                                              widget.onSalvar();
                                              Navigator.pop(ctx);
                                            },
                                            child: const Text('Salvar'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.lista.isLocked ? null : _adicionarLinha,
        backgroundColor: widget.lista.isLocked ? Colors.grey : corTema,
        child: const Icon(Icons.playlist_add, color: Colors.white),
      ),
    );
  }
}
