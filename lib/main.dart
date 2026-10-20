import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models.dart';
import 'repository.dart';
import 'pdf_helper.dart';          // Serviço de PDF que criámos
import 'import_export_helper.dart'; // Serviço de Importação/Exportação JSON que criámos

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await SembastAppRepository.abrir();
  runApp(App(repo: repo));
}

class App extends StatelessWidget {
  const App({super.key, required this.repo});
  final AppRepository repo;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Banco Dinâmico',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: ListasPage(repo: repo),
      );
}

// ===========================================================================
// 1. Página Inicial: Gestão de Múltiplas Listas (Com Botão de Importar)
// ===========================================================================

class ListasPage extends StatefulWidget {
  const ListasPage({super.key, required this.repo});
  final AppRepository repo;

  @override
  State<ListasPage> createState() => _ListasPageState();
}

class _ListasPageState extends State<ListasPage> {
  late final Stream<List<ListaEntidades>> _stream = widget.repo.observarListas();

  Future<void> _criarListaDialog() async {
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final r = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Lista'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: tituloCtrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Título da Lista'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descCtrl,
            decoration: const InputDecoration(labelText: 'Descrição (Opcional)'),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (tituloCtrl.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (r == true) {
      await widget.repo.criarLista(
        titulo: tituloCtrl.text,
        descricao: descCtrl.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Minhas Listas e Grades'),
          actions: [
            // Botão para importar lista de um ficheiro JSON
            IconButton(
              icon: const Icon(Icons.file_upload_outlined),
              tooltip: 'Importar Lista de Ficheiro',
              onPressed: () => ImportExportService.importarLista(context, widget.repo),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _criarListaDialog,
          tooltip: 'Nova Lista',
          child: const Icon(Icons.add),
        ),
        body: StreamBuilder<List<ListaEntidades>>(
          stream: _stream,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('Erro: ${snap.error}'));
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final listas = snap.data!;
            if (listas.isEmpty) {
              return const Center(
                  child: Text('Nenhuma lista criada. Toque em + para começar.'));
            }
            return ListView.builder(
              itemCount: listas.length,
              itemBuilder: (context, i) {
                final l = listas[i];
                return ListTile(
                  leading: const Icon(Icons.table_chart_outlined),
                  title: Text(l.titulo),
                  subtitle: Text(l.descricao.isNotEmpty
                      ? l.descricao
                      : '${l.colunas.length} colunas definidas'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => widget.repo.removerLista(l.id),
                  ),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DetalheListaPage(repo: widget.repo, lista: l),
                  )),
                );
              },
            );
          },
        ),
      );
}

// ===========================================================================
// 2. Página da Grade Interativa (DataTable, Cores, Data/Hora, Cadeado)
// ===========================================================================

class DetalheListaPage extends StatefulWidget {
  const DetalheListaPage({super.key, required this.repo, required this.lista});
  final AppRepository repo;
  final ListaEntidades lista;

  @override
  State<DetalheListaPage> createState() => _DetalheListaPageState();
}

class _DetalheListaPageState extends State<DetalheListaPage> {
  late Stream<List<Entidade>> _entidadesStream;
  late TextEditingController _tituloController;

  @override
  void initState() {
    super.initState();
    _entidadesStream = widget.repo.observarEntidadesDaLista(widget.lista.id);
    _tituloController = TextEditingController(text: widget.lista.titulo);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  Color _obterCorTema(String tema) {
    switch (tema) {
      case 'verde':
        return Colors.green.shade700;
      case 'roxo':
        return Colors.deepPurple.shade700;
      case 'cinza':
        return Colors.blueGrey.shade700;
      default:
        return Colors.indigo.shade700;
    }
  }

  String _formatarDataHora() {
    final agora = DateTime.now();
    String resultado = '';

    if (widget.lista.mostrarData) {
      if (widget.lista.formatoData == 'mm/aaaa') {
        resultado += DateFormat('MM/yyyy').format(agora);
      } else {
        resultado += DateFormat('dd/MM/yyyy').format(agora);
      }
    }

    if (widget.lista.mostrarHora) {
      final horaFmt = widget.lista.formatoHora == '12h' ? 'hh:mm a' : 'HH:mm';
      resultado += (resultado.isNotEmpty ? ' • ' : '') + DateFormat(horaFmt).format(agora);
    }

    return resultado;
  }

  Future<void> _adicionarColunaDialog() async {
    final nomeCtrl = TextEditingController();
    TipoAtributo tipoSelecionado = TipoAtributo.texto;

    final r = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Adicionar Coluna à Grade'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nomeCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'Nome da Coluna (ex: Telefone, Idade)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TipoAtributo>(
              value: tipoSelecionado,
              decoration: const InputDecoration(labelText: 'Tipo de Dado'),
              items: TipoAtributo.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) =>
                  setStateDialog(() => tipoSelecionado = v ?? tipoSelecionado),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (nomeCtrl.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );

    if (r == true) {
      await widget.repo.adicionarColuna(
          widget.lista.id, nomeCtrl.text, tipoSelecionado);
      setState(() {});
    }
  }

  Future<void> _adicionarEntidadeDialog() async {
    final nomeCtrl = TextEditingController();
    final r = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Item / Linha'),
        content: TextField(
          controller: nomeCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome / Identificação'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (nomeCtrl.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (r == true) {
      await widget.repo.adicionarEntidade(
        listaId: widget.lista.id,
        nome: nomeCtrl.text,
      );
    }
  }

  void _mostrarEditorCelula(BuildContext context, Entidade entidade, ColunaEspecificacao coluna) {
    final valorAtual = entidade.valoresAtributos[coluna.id] ?? '';
    final controller = TextEditingController(text: valorAtual);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar: ${coluna.nome}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Digite o valor',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.repo.atualizarValorEntidade(
                entidadeId: entidade.id,
                colunaId: coluna.id,
                valor: controller.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoConfiguracoes(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Personalizar Lista'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cor do Tema da Grade', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      children: [
                        _buildColorOption(setDialogState, 'azul', Colors.indigo.shade700),
                        _buildColorOption(setDialogState, 'verde', Colors.green.shade700),
                        _buildColorOption(setDialogState, 'roxo', Colors.deepPurple.shade700),
                        _buildColorOption(setDialogState, 'cinza', Colors.blueGrey.shade700),
                      ],
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      title: const Text('Mostrar Data'),
                      value: widget.lista.mostrarData,
                      onChanged: (val) {
                        setDialogState(() => widget.lista.mostrarData = val);
                        widget.repo.atualizarConfiguracoesLista(widget.lista);
                        setState(() {});
                      },
                    ),
                    if (widget.lista.mostrarData)
                      DropdownButtonFormField<String>(
                        value: widget.lista.formatoData,
                        decoration: const InputDecoration(labelText: 'Formato da Data'),
                        items: const [
                          DropdownMenuItem(value: 'dd/mm/aaaa', child: Text('dd/mm/aaaa')),
                          DropdownMenuItem(value: 'mm/aaaa', child: Text('mm/aaaa')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => widget.lista.formatoData = val);
                            widget.repo.atualizarConfiguracoesLista(widget.lista);
                            setState(() {});
                          }
                        },
                      ),
                    const Divider(height: 24),
                    SwitchListTile(
                      title: const Text('Mostrar Hora'),
                      value: widget.lista.mostrarHora,
                      onChanged: (val) {
                        setDialogState(() => widget.lista.mostrarHora = val);
                        widget.repo.atualizarConfiguracoesLista(widget.lista);
                        setState(() {});
                      },
                    ),
                    if (widget.lista.mostrarHora)
                      DropdownButtonFormField<String>(
                        value: widget.lista.formatoHora,
                        decoration: const InputDecoration(labelText: 'Formato da Hora'),
                        items: const [
                          DropdownMenuItem(value: '24h', child: Text('24 Horas (16:04)')),
                          DropdownMenuItem(value: '12h', child: Text('12 Horas (04:04 PM)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => widget.lista.formatoHora = val);
                            widget.repo.atualizarConfiguracoesLista(widget.lista);
                            setState(() {});
                          }
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Concluir'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorOption(StateSetter setDialogState, String nomeCor, Color cor) {
    final selecionado = widget.lista.corTema == nomeCor;
    return GestureDetector(
      onTap: () {
        setDialogState(() => widget.lista.corTema = nomeCor);
        widget.repo.atualizarConfiguracoesLista(widget.lista);
        setState(() {});
      },
      child: CircleAvatar(
        backgroundColor: cor,
        radius: 18,
        child: selecionado ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Entidade>>(
        stream: _entidadesStream,
        builder: (context, snap) {
          final entidades = snap.data ?? [];
          final corAtiva = _obterCorTema(widget.lista.corTema);
          final dataHoraStr = _formatarDataHora();

          return Scaffold(
            appBar: AppBar(
              backgroundColor: corAtiva,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _tituloController,
                    enabled: !widget.lista.isLocked,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    onChanged: (novoTitulo) {
                      widget.lista.titulo = novoTitulo;
                      widget.lista.descricao = novoTitulo;
                      widget.repo.atualizarConfiguracoesLista(widget.lista);
                    },
                  ),
                  if (dataHoraStr.isNotEmpty)
                    Text(
                      dataHoraStr,
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                ],
              ),
              actions: [
                // 1. Exportar JSON
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Exportar / Fazer Backup',
                  onPressed: () => ImportExportService.exportarLista(context, widget.lista, widget.repo),
                ),
                // 2. Gerar PDF
                IconButton(
                  icon: const Icon(Icons.print),
                  tooltip: 'Gerar Relatório PDF',
                  onPressed: () async {
                    if (entidades.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('A lista está vazia. Adicione itens antes de exportar.')),
                      );
                      return;
                    }
                    await PdfRelatorioService.gerarEImprimirRelatorio(
                      context,
                      lista: widget.lista,
                      entidades: entidades,
                    );
                  },
                ),
                // 3. Gerir / Adicionar Colunas
                IconButton(
                  icon: const Icon(Icons.view_column),
                  tooltip: 'Gerir Colunas',
                  onPressed: _adicionarColunaDialog,
                ),
                // 4. Personalizar Cores e Data/Hora
                IconButton(
                  icon: const Icon(Icons.palette_outlined),
                  tooltip: 'Personalizar',
                  onPressed: widget.lista.isLocked ? null : () => _mostrarDialogoConfiguracoes(context),
                ),
                // 5. Trancar / Destrancar
                IconButton(
                  icon: Icon(widget.lista.isLocked ? Icons.lock : Icons.lock_open),
                  tooltip: widget.lista.isLocked ? 'Destrancar' : 'Trancar',
                  onPressed: () {
                    setState(() {
                      widget.lista.isLocked = !widget.lista.isLocked;
                    });
                    widget.repo.atualizarConfiguracoesLista(widget.lista);
                  },
                ),
              ],
            ),
            floatingActionButton: widget.lista.isLocked
                ? null
                : FloatingActionButton(
                    backgroundColor: corAtiva,
                    onPressed: _adicionarEntidadeDialog,
                    tooltip: 'Adicionar Linha',
                    child: const Icon(Icons.person_add, color: Colors.white),
                  ),
            body: snap.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : widget.lista.colunas.isEmpty || entidades.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum item ou coluna na grade.\nUse os botões superiores para adicionar colunas e o botão inferior para linhas.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(corAtiva.withOpacity(0.12)),
                            columns: [
                              const DataColumn(label: Text('Nome / Item', style: TextStyle(fontWeight: FontWeight.bold))),
                              ...widget.lista.colunas.map((coluna) {
                                return DataColumn(
                                  label: Text(
                                    coluna.nome,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: corAtiva),
                                  ),
                                );
                              }),
                            ],
                            rows: entidades.map((entidade) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(entidade.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        if (!widget.lista.isLocked) ...[
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            onPressed: () => widget.repo.removerEntidade(entidade.id),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                  ...widget.lista.colunas.map((coluna) {
                                    final valor = entidade.valoresAtributos[coluna.id] ?? '';
                                    return DataCell(
                                      Text(valor.isEmpty ? '-' : valor),
                                      showEditIcon: !widget.lista.isLocked,
                                      onTap: widget.lista.isLocked
                                          ? null
                                          : () => _mostrarEditorCelula(context, entidade, coluna),
                                    );
                                  }),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          );
        },
      );
}
