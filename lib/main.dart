import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models.dart';
import 'repository.dart';

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
// 1. Página Inicial: Gestão de Múltiplas Listas
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
        appBar: AppBar(title: const Text('Minhas Listas e Grades')),
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
// 2. Página da Grade (Colunas Globais + Linhas de Entidades + Botão PDF)
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

  @override
  void initState() {
    super.initState();
    _entidadesStream = widget.repo.observarEntidadesDaLista(widget.lista.id);
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

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Entidade>>(
        stream: _entidadesStream,
        builder: (context, snap) {
          final entidades = snap.data ?? [];

          return Scaffold(
            appBar: AppBar(
              title: Text(widget.lista.titulo),
              actions: [
                // Botão de Relatório PDF Integrado
                IconButton(
                  icon: const Icon(Icons.print),
                  tooltip: 'Gerir Relatório PDF / Imprimir',
                  onPressed: () async {
                    if (entidades.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'A lista está vazia. Adicione itens antes de exportar.')),
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
                IconButton(
                  icon: const Icon(Icons.view_column),
                  tooltip: 'Gerir Colunas',
                  onPressed: _adicionarColunaDialog,
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _adicionarEntidadeDialog,
              tooltip: 'Adicionar Linha',
              child: const Icon(Icons.person_add),
            ),
            body: snap.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : entidades.isEmpty
                    ? const Center(
                        child: Text(
                            'Nenhum item na grade. Adicione colunas e linhas.'))
                    : ListView.builder(
                        itemCount: entidades.length,
                        itemBuilder: (context, i) {
                          final ent = entidades[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(ent.nome,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  'Valores preenchidos: ${ent.valoresAtributos.length}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () =>
                                    widget.repo.removerEntidade(ent.id),
                              ),
                              onTap: () {
                                // Futura edição de colunas individuais por linha
                              },
                            ),
                          );
                        },
                      ),
          );
        },
      );
}
