import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BancoDinamicoApp());
}

class BancoDinamicoApp extends StatelessWidget {
  const BancoDinamicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Banco Dinâmico',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ListasPage(),
    );
  }
}

class ListasPage extends StatefulWidget {
  const ListasPage({super.key});

  @override
  State<ListasPage> createState() => _ListasPageState();
}

class _ListasPageState extends State<ListasPage> {
  final List<ListaEntidades> _listas = [];
  final Uuid _uuid = const Uuid();

  Color _obterCorTema(String tema) {
    switch (tema) {
      case 'verde':
        return Colors.teal;
      case 'roxo':
        return Colors.deepPurple;
      case 'cinza':
        return Colors.blueGrey;
      case 'laranja':
        return Colors.deepOrange;
      case 'rosa':
        return Colors.pink;
      case 'azul':
      default:
        return Colors.blue;
    }
  }

  void _criarNovaLista() {
    final titleController = TextEditingController();
    String corSelecionada = 'azul';

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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Cor do Tema:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['azul', 'verde', 'roxo', 'cinza', 'laranja', 'rosa'].map((cor) {
                      final selected = corSelecionada == cor;
                      return ChoiceChip(
                        label: Text(cor),
                        selected: selected,
                        selectedColor: _obterCorTema(cor).withOpacity(0.3),
                        onSelected: (val) {
                          if (val) setDialogState(() => corSelecionada = cor);
                        },
                      );
                    }).toList(),
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
                    corTema: corSelecionada,
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

  void _renomearEConfigurarLista(ListaEntidades lista) {
    final titleController = TextEditingController(text: lista.titulo);
    String corSelecionada = lista.corTema;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Editar Lista'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: ['azul', 'verde', 'roxo', 'cinza', 'laranja', 'rosa'].map((cor) {
                    return ChoiceChip(
                      label: Text(cor),
                      selected: corSelecionada == cor,
                      onSelected: (val) {
                        if (val) setDialogState(() => corSelecionada = cor);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    lista.titulo = titleController.text.trim();
                    lista.corTema = corSelecionada;
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
          obterCor: _obterCorTema,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banco Dinâmico'),
        centerTitle: true,
      ),
      body: _listas.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma lista cadastrada.\nToque no botão + para criar sua primeira tabela.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _listas.length,
              itemBuilder: (context, index) {
                final lista = _listas[index];
                final cor = _obterCorTema(lista.corTema);

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
                    subtitle: Text('${lista.linhas.length} registros | ${lista.colunas.length} colunas'),
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
                            const PopupMenuItem(value: 'editar', child: Text('Editar / Tema')),
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
  final Color Function(String) obterCor;

  const DetalhesGrelhaPage({
    super.key,
    required this.lista,
    required this.onSalvar,
    required this.obterCor,
  });

  @override
  State<DetalhesGrelhaPage> createState() => _DetalhesGrelhaPageState();
}

class _DetalhesGrelhaPageState extends State<DetalhesGrelhaPage> {
  final Uuid _uuid = const Uuid();

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

  void _adicionarLinha() {
    if (widget.lista.isLocked) return;

    final Map<String, String> novosValores = {};
    for (var col in widget.lista.colunas) {
      novosValores[col.id] = col.tipo == 'checkbox' ? 'false' : '';
    }

    setState(() {
      widget.lista.linhas.add(
        Entidade(id: _uuid.v4(), valores: novosValores),
      );
    });
    widget.onSalvar();
  }

  @override
  Widget build(BuildContext context) {
    final corTema = widget.obterCor(widget.lista.corTema);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lista.titulo),
        backgroundColor: corTema,
        foregroundColor: Colors.white,
        actions: [
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
                  columns: widget.lista.colunas.map((col) {
                    return DataColumn(
                      label: Text(
                        col.nome,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                  rows: widget.lista.linhas.map((linha) {
                    return DataRow(
                      cells: widget.lista.colunas.map((col) {
                        final val = linha.valores[col.id] ?? '';

                        if (col.tipo == 'checkbox') {
                          final isChecked = val.toLowerCase() == 'true';
                          return DataCell(
                            Checkbox(
                              value: isChecked,
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
                      }).toList(),
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
