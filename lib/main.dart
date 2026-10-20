import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models.dart';
import 'repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await SembastEntidadeRepository.abrir();
  runApp(App(repo: repo));
}

class App extends StatelessWidget {
  const App({super.key, required this.repo});
  final EntidadeRepository repo;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Banco Dinâmico',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: ListaEntidadesPage(repo: repo),
      );
}

// ===========================================================================
// Tela 1: lista de entidades
// ===========================================================================

class ListaEntidadesPage extends StatefulWidget {
  const ListaEntidadesPage({super.key, required this.repo});
  final EntidadeRepository repo;

  @override
  State<ListaEntidadesPage> createState() => _ListaEntidadesPageState();
}

class _ListaEntidadesPageState extends State<ListaEntidadesPage> {
  late final Stream<List<Entidade>> _stream = widget.repo.observarEntidades();

  Future<void> _nova() async {
    final r = await showDialog<(String, TipoEntidade)>(
      context: context,
      builder: (_) => const _NovaEntidadeDialog(),
    );
    if (r != null) {
      await widget.repo.adicionarEntidade(nome: r.$1, tipo: r.$2);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Entidades')),
        floatingActionButton: FloatingActionButton(
          onPressed: _nova,
          tooltip: 'Nova entidade',
          child: const Icon(Icons.add),
        ),
        body: StreamBuilder<List<Entidade>>(
          stream: _stream,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('Erro: ${snap.error}'));
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final lista = snap.data!;
            if (lista.isEmpty) {
              return const Center(
                  child: Text('Nenhuma entidade. Toque em + para criar.'));
            }
            return ListView.builder(
              itemCount: lista.length,
              itemBuilder: (context, i) {
                final e = lista[i];
                return ListTile(
                  leading: Icon(e.tipo == TipoEntidade.pessoa
                      ? Icons.person
                      : Icons.inventory_2),
                  title: Text(e.nome),
                  subtitle: Text('${e.atributos.length} especificações'),
                  trailing: IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => widget.repo.removerEntidade(e.id),
                  ),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DetalheEntidadePage(
                        repo: widget.repo, entidadeId: e.id),
                  )),
                );
              },
            );
          },
        ),
      );
}

class _NovaEntidadeDialog extends StatefulWidget {
  const _NovaEntidadeDialog();

  @override
  State<_NovaEntidadeDialog> createState() => _NovaEntidadeDialogState();
}

class _NovaEntidadeDialogState extends State<_NovaEntidadeDialog> {
  final _nome = TextEditingController();
  TipoEntidade _tipo = TipoEntidade.pessoa;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Nova entidade'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _nome,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: 16),
          SegmentedButton<TipoEntidade>(
            segments: const [
              ButtonSegment(value: TipoEntidade.pessoa, label: Text('Pessoa')),
              ButtonSegment(value: TipoEntidade.objeto, label: Text('Objeto')),
            ],
            selected: {_tipo},
            onSelectionChanged: (s) => setState(() => _tipo = s.first),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (_nome.text.trim().isEmpty) return;
              Navigator.pop(context, (_nome.text.trim(), _tipo));
            },
            child: const Text('Criar'),
          ),
        ],
      );
}

// ===========================================================================
// Tela 2: detalhe (especificações dinâmicas + presenças)
// ===========================================================================

class DetalheEntidadePage extends StatefulWidget {
  const DetalheEntidadePage(
      {super.key, required this.repo, required this.entidadeId});
  final EntidadeRepository repo;
  final String entidadeId;

  @override
  State<DetalheEntidadePage> createState() => _DetalheEntidadePageState();
}

class _DetalheEntidadePageState extends State<DetalheEntidadePage> {
  late final Stream<Entidade?> _stream = widget.repo.observar(widget.entidadeId);
  final _fmt = DateFormat('dd/MM/yyyy  HH:mm');
  bool _mostrarOcultos = false;

  Future<void> _editarAtributo(Entidade e, [AtributoDinamico? atual]) async {
    final r = await showDialog<AtributoDinamico>(
      context: context,
      builder: (_) => _AtributoDialog(atual: atual),
    );
    if (r != null) await widget.repo.salvarAtributo(e.id, r);
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Entidade?>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Scaffold(
                appBar: AppBar(),
                body: const Center(child: CircularProgressIndicator()));
          }
          final e = snap.data;
          if (e == null) {
            return Scaffold(
                appBar: AppBar(),
                body: const Center(child: Text('Entidade não encontrada.')));
          }

          final visiveis = _mostrarOcultos
              ? e.presencas
              : e.presencas.where((p) => p.isVisible).toList();
          final titulo = Theme.of(context).textTheme.titleMedium;

          return Scaffold(
            appBar: AppBar(title: Text(e.nome)),
            body: CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text('Especificações', style: titulo),
                      ),
                      for (final a in e.atributos)
                        ListTile(
                          title: Text(a.chave),
                          subtitle: Text(a.valorFormatado),
                          onTap: () => _editarAtributo(e, a),
                          trailing: IconButton(
                            tooltip: 'Remover especificação',
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                widget.repo.removerAtributo(e.id, a.id),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: OutlinedButton.icon(
                          onPressed: () => _editarAtributo(e),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar especificação'),
                        ),
                      ),
                      const Divider(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(children: [
                          Expanded(
                              child: Text('Presenças (${visiveis.length})',
                                  style: titulo)),
                          const Text('Mostrar ocultas'),
                          Switch(
                            value: _mostrarOcultos,
                            onChanged: (v) => setState(() => _mostrarOcultos = v),
                          ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: FilledButton.icon(
                          onPressed: () => widget.repo.registrarPresenca(e.id),
                          icon: const Icon(Icons.how_to_reg),
                          label: const Text('Registrar presença agora'),
                        ),
                      ),
                    ]),
              ),
              // SliverList.builder: só constrói o que aparece na tela,
              // mantendo a rolagem fluida com milhares de registros.
              SliverList.builder(
                itemCount: visiveis.length,
                itemBuilder: (context, i) {
                  final p = visiveis[i];
                  final apagado = Theme.of(context).disabledColor;
                  return ListTile(
                    key: ValueKey(p.id),
                    leading: Icon(
                      p.isVisible
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: p.isVisible ? null : apagado,
                    ),
                    title: Text(
                      _fmt.format(p.timestamp),
                      style: p.isVisible
                          ? null
                          : TextStyle(
                              color: apagado,
                              decoration: TextDecoration.lineThrough),
                    ),
                    subtitle: Text(
                        'Dia ${p.dia} · Mês ${p.mes} · '
                        '${p.hora.toString().padLeft(2, '0')}h'
                        '${p.minuto.toString().padLeft(2, '0')}'),
                    trailing: IconButton(
                      tooltip: p.isVisible ? 'Ocultar' : 'Exibir',
                      icon: Icon(p.isVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => widget.repo.alternarVisibilidade(p.id),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ]),
          );
        },
      );
}

// ===========================================================================
// Diálogo de especificação dinâmica (chave + tipo + valor)
// ===========================================================================

class _AtributoDialog extends StatefulWidget {
  const _AtributoDialog({this.atual});
  final AtributoDinamico? atual;

  @override
  State<_AtributoDialog> createState() => _AtributoDialogState();
}

class _AtributoDialogState extends State<_AtributoDialog> {
  late final _chave = TextEditingController(text: widget.atual?.chave ?? '');
  late final _valor = TextEditingController(
      text: switch (widget.atual?.tipo) {
    TipoAtributo.texto || TipoAtributo.numero => '${widget.atual?.valor ?? ''}',
    _ => '',
  });
  late TipoAtributo _tipo = widget.atual?.tipo ?? TipoAtributo.texto;
  late bool _bool = widget.atual?.valor == true;
  late DateTime? _data = widget.atual?.tipo == TipoAtributo.data
      ? DateTime.tryParse('${widget.atual?.valor}')
      : null;
  String? _erro;

  @override
  void dispose() {
    _chave.dispose();
    _valor.dispose();
    super.dispose();
  }

  void _salvar() {
    final chave = _chave.text.trim();
    if (chave.isEmpty) {
      setState(() => _erro = 'Informe o nome da especificação.');
      return;
    }
    Object? valor;
    switch (_tipo) {
      case TipoAtributo.texto:
      case TipoAtributo.numero:
        valor = AtributoDinamico.interpretar(_valor.text, _tipo);
        if (valor == null) {
          setState(() => _erro = 'Valor inválido para o tipo escolhido.');
          return;
        }
      case TipoAtributo.booleano:
        valor = _bool;
      case TipoAtributo.data:
        valor = _data?.toIso8601String();
    }
    Navigator.pop(
      context,
      AtributoDinamico(
        id: widget.atual?.id ?? novoId(),
        chave: chave,
        valor: valor,
        tipo: _tipo,
      ),
    );
  }

  Widget _campoValor() {
    switch (_tipo) {
      case TipoAtributo.booleano:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Valor'),
          value: _bool,
          onChanged: (v) => setState(() => _bool = v),
        );
      case TipoAtributo.data:
        return Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.event),
            label: Text(_data == null
                ? 'Escolher data'
                : DateFormat('dd/MM/yyyy').format(_data!)),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _data ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (d != null) setState(() => _data = d);
            },
          ),
        );
      default:
        return TextField(
          controller: _valor,
          keyboardType: _tipo == TipoAtributo.numero
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: const InputDecoration(labelText: 'Valor'),
        );
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.atual == null ? 'Nova especificação' : 'Editar'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _chave,
              decoration: const InputDecoration(
                  labelText: 'Nome (ex.: idade, cor, cargo)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TipoAtributo>(
              value: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [
                for (final t in TipoAtributo.values)
                  DropdownMenuItem(value: t, child: Text(t.name)),
              ],
              onChanged: (t) => setState(() {
                _tipo = t ?? _tipo;
                _erro = null;
              }),
            ),
            const SizedBox(height: 8),
            _campoValor(),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_erro!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(onPressed: _salvar, child: const Text('Salvar')),
        ],
      );
}
