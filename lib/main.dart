import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
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
      title: 'Databank - Gestão de Membros',
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
            title: const Text('Nova Lista de Membros'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título da Tabela',
                      hintText: 'Ex: Cadastro Geral, Membros Ativos, Evento',
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
                      ColunaEspecificacao(id: _uuid.v4(), nome: 'Cargo / Função', tipo: 'texto'),
                      ColunaEspecificacao(id: _uuid.v4(), nome: 'Observação', tipo: 'texto'),
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
        title: const Text('Databank - Membros'),
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
                        lista.isLocked ? Icons.lock : Icons.people_alt,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      lista.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${lista.linhas.length} membros | ${lista.colunas.length} campos extras'),
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
  final ImagePicker _picker = ImagePicker();

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
            title: const Text('Novo Campo Personalizado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome do Campo'),
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
        title: Text('Gerenciar Campo "${col.nome}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Novo Nome do Campo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                widget.lista.colunas.removeWhere((c) => c.id == col.id);
                for (var linha in widget.lista.linhas) {
                  linha.valoresAtributosDinamicos.remove(col.id);
                }
              });
              widget.onSalvar();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir Campo'),
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

  void _abrirFormularioMembro({Entidade? membroExistente, int? indexExistente}) {
    if (widget.lista.isLocked) return;

    final nomeCtrl = TextEditingController(text: membroExistente?.nome ?? '');
    final cpfCtrl = TextEditingController(text: membroExistente?.cpf ?? '');
    final rgCtrl = TextEditingController(text: membroExistente?.rg ?? '');
    final idadeCtrl = TextEditingController(text: membroExistente?.idade ?? '');
    final telCtrl = TextEditingController(text: membroExistente?.telefone ?? '');
    final celCtrl = TextEditingController(text: membroExistente?.celular ?? '');
    final emailCtrl = TextEditingController(text: membroExistente?.email ?? '');

    String sexoSel = membroExistente?.sexo ?? 'N/A';
    String sangueSel = membroExistente?.tipoSanguineo ?? 'N/A';
    String? fotoBase64 = membroExistente?.fotoBase64;

    final Map<String, String> atributosDinamicos = Map.from(membroExistente?.valoresAtributosDinamicos ?? {});
    for (var col in widget.lista.colunas) {
      atributosDinamicos.putIfAbsent(col.id, () => col.tipo == 'checkbox' ? 'false' : '');
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setFormState) {
          return AlertDialog(
            title: Text(membroExistente == null ? 'Cadastrar Membro' : 'Editar Ficha do Membro'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setFormState(() {
                          fotoBase64 = base64Encode(bytes);
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: fotoBase64 != null ? MemoryImage(base64Decode(fotoBase64!)) : null,
                      child: fotoBase64 == null
                          ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome Completo')),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: cpfCtrl, decoration: const InputDecoration(labelText: 'CPF'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: rgCtrl, decoration: const InputDecoration(labelText: 'RG'))),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: idadeCtrl, decoration: const InputDecoration(labelText: 'Idade'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: sexoSel,
                          decoration: const InputDecoration(labelText: 'Sexo'),
                          items: const [
                            DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                            DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
                            DropdownMenuItem(value: 'N/A', child: Text('N/A')),
                          ],
                          onChanged: (v) => setFormState(() => sexoSel = v!),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: sangueSel,
                          decoration: const InputDecoration(labelText: 'Tipo Sanguíneo'),
                          items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'N/A'].map((s) {
                            return DropdownMenuItem(value: s, child: Text(s));
                          }).toList(),
                          onChanged: (v) => setFormState(() => sangueSel = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: celCtrl, decoration: const InputDecoration(labelText: 'Celular'))),
                    ],
                  ),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'E-mail')),
                  const Divider(height: 24),
                  const Text('Campos Personalizados:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...widget.lista.colunas.map((col) {
                    final currentVal = atributosDinamicos[col.id] ?? '';
                    return TextField(
                      decoration: InputDecoration(labelText: col.nome),
                      controller: TextEditingController(text: currentVal),
                      onChanged: (v) => atributosDinamicos[col.id] = v,
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  final nome = nomeCtrl.text.trim();
                  if (nome.isEmpty) return;

                  final novoMembro = Entidade(
                    id: membroExistente?.id ?? _uuid.v4(),
                    nome: nome,
                    fotoBase64: fotoBase64,
                    cpf: cpfCtrl.text.trim(),
                    rg: rgCtrl.text.trim(),
                    idade: idadeCtrl.text.trim(),
                    sexo: sexoSel,
                    tipoSanguineo: sangueSel,
                    telefone: telCtrl.text.trim(),
                    celular: celCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    valoresAtributosDinamicos: atributosDinamicos,
                  );

                  setState(() {
                    if (indexExistente != null) {
                      widget.lista.linhas[indexExistente] = novoMembro;
                    } else {
                      widget.lista.linhas.add(novoMembro);
                    }
                  });
                  widget.onSalvar();
                  Navigator.pop(ctx);
                },
                child: const Text('Salvar Cadastro'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _excluirLinha(int index) {
    if (widget.lista.isLocked) return;

    setState(() {
      widget.lista.linhas.removeAt(index);
    });
    widget.onSalvar();
  }

  Future<void> _imprimirFichaMembro(Entidade membro) async {
    final pdf = pw.Document();
    Uint8List? imageBytes;
    if (membro.fotoBase64 != null) {
      imageBytes = base64Decode(membro.fotoBase64!);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            cross: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('FICHA CADASTRAL DO MEMBRO', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Databank', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                cross: pw.CrossAxisAlignment.start,
                children: [
                  if (imageBytes != null)
                    pw.Container(
                      width: 90,
                      height: 110,
                      margin: const pw.EdgeInsets.only(right: 16),
                      child: pw.Image(pw.MemoryImage(imageBytes)),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      cross: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Nome: ${membro.nome}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('CPF: ${membro.cpf} | RG: ${membro.rg}'),
                        pw.Text('Idade: ${membro.idade} | Sexo: ${membro.sexo}'),
                        pw.Text('Tipo Sanguíneo: ${membro.tipoSanguineo}'),
                        pw.Text('Celular: ${membro.celular} | E-mail: ${membro.email}'),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Text('Especificações & Atributos Adicionais:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 8),
              ...widget.lista.colunas.map((col) {
                final val = membro.valoresAtributosDinamicos[col.id] ?? '';
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text('${col.nome}: $val'),
                );
              }),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _imprimirListaPresencaPDF() async {
    final pdf = pw.Document();
    final dataHoraSubtit = _formatarDataHoraAtual();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('LISTA DE PRESENÇA - ${widget.lista.titulo}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  if (dataHoraSubtit.isNotEmpty)
                    pw.Text(dataHoraSubtit, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: ['Nº', 'Nome do Membro', 'CPF / RG', 'Assinatura'],
              data: widget.lista.linhas.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final m = entry.value;
                final doc = m.cpf.isNotEmpty ? m.cpf : m.rg;
                return [
                  '$idx',
                  m.nome,
                  doc,
                  '____________________________________',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _exportarJSON() {
    final jsonStr = jsonEncode(widget.lista.toJson());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportar Dados (JSON)'),
        content: SingleChildScrollView(child: SelectableText(jsonStr)),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final corTema = widget.converterHex(widget.lista.corTema);
    final dataHoraStr = _formatarDataHoraAtual();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    widget.lista.titulo,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (dataHoraStr.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '($dataHoraStr)',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ],
        ),
        backgroundColor: corTema,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_turned_in),
            tooltip: 'Lista de Presença (PDF)',
            onPressed: _imprimirListaPresencaPDF,
          ),
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'Exportar JSON',
            onPressed: _exportarJSON,
          ),
          IconButton(
            icon: const Icon(Icons.add_card),
            tooltip: 'Adicionar Campo Extra',
            onPressed: widget.lista.isLocked ? null : _adicionarColuna,
          ),
        ],
      ),
      body: widget.lista.linhas.isEmpty
          ? const Center(child: Text('Nenhum membro cadastrado nesta lista.\nToque no botão + para adicionar.'))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(corTema.withOpacity(0.15)),
                  border: TableBorder.all(color: corTema.withOpacity(0.4), width: 1),
                  columns: [
                    const DataColumn(label: Text('Foto', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('CPF / RG', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Contato', style: TextStyle(fontWeight: FontWeight.bold))),
                    ...widget.lista.colunas.map((col) {
                      return DataColumn(
                        label: InkWell(
                          onTap: () => _opcoesColuna(col),
                          child: Row(
                            children: [
                              Text(col.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (!widget.lista.isLocked)
                      const DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: widget.lista.linhas.asMap().entries.map((entry) {
                    final index = entry.key;
                    final membro = entry.value;

                    return DataRow(
                      cells: [
                        DataCell(
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: membro.fotoBase64 != null ? MemoryImage(base64Decode(membro.fotoBase64!)) : null,
                            child: membro.fotoBase64 == null ? const Icon(Icons.person, size: 18) : null,
                          ),
                        ),
                        DataCell(
                          Text(membro.nome, style: const TextStyle(fontWeight: FontWeight.w500)),
                          onTap: () => _abrirFormularioMembro(membroExistente: membro, indexExistente: index),
                        ),
                        DataCell(Text(membro.cpf.isNotEmpty ? membro.cpf : membro.rg)),
                        DataCell(Text(membro.celular.isNotEmpty ? membro.celular : membro.email)),
                        ...widget.lista.colunas.map((col) {
                          final val = membro.valoresAtributosDinamicos[col.id] ?? '';
                          return DataCell(Text(val.isEmpty ? '-' : val));
                        }),
                        if (!widget.lista.isLocked)
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.badge_outlined, color: Colors.blue, size: 20),
                                  tooltip: 'Imprimir Ficha Cadastral',
                                  onPressed: () => _imprimirFichaMembro(membro),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  tooltip: 'Excluir membro',
                                  onPressed: () => _excluirLinha(index),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.lista.isLocked ? null : () => _abrirFormularioMembro(),
        backgroundColor: widget.lista.isLocked ? Colors.grey : corTema,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
