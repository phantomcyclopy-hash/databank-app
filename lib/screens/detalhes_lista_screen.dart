import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../utils/historico_manager.dart';
import '../repositories/lista_repository.dart';

class DetalhesListaScreen extends StatefulWidget {
  final ListaEntidades lista;
  const DetalhesListaScreen({super.key, required this.lista});

  @override
  State<DetalhesListaScreen> createState() => _DetalhesListaScreenState();
}

class _DetalhesListaScreenState extends State<DetalhesListaScreen> {
  late TextEditingController _tituloController;
  final GridHistoricoManager _historico = GridHistoricoManager();
  final ListaRepository _repository = ListaRepository();

  @override
  void initState() {
    super.initState();
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

  Future<void> _persistirESincronizar() async {
    await _repository.salvarLista(widget.lista);
    setState(() {});
  }

  void _gravarAlteracaoParaUndo() {
    _historico.gravarEstado(widget.lista.linhas);
    _persistirESincronizar();
  }

  @override
  Widget build(BuildContext context) {
    final corAtiva = _obterCorTema(widget.lista.corTema);
    final dataHoraStr = _formatarDataHora();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: corAtiva,
        title: Column(
          crossAxisAlignment: CrossAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tituloController,
              enabled: !widget.lista.isLocked,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
              onChanged: (novoTitulo) {
                widget.lista.titulo = novoTitulo;
                _repository.salvarLista(widget.lista);
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
          // Botão Desfazer
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Desfazer',
            onPressed: _historico.podeDesfazer && !widget.lista.isLocked
                ? () {
                    final estadoAnterior = _historico.desfazer(widget.lista.linhas);
                    if (estadoAnterior != null) {
                      widget.lista.linhas = estadoAnterior;
                      _persistirESincronizar();
                    }
                  }
                : null,
          ),
          // Botão Refazer
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Refazer',
            onPressed: _historico.podeRefazer && !widget.lista.isLocked
                ? () {
                    final estadoSeguinte = _historico.refazer(widget.lista.linhas);
                    if (estadoSeguinte != null) {
                      widget.lista.linhas = estadoSeguinte;
                      _persistirESincronizar();
                    }
                  }
                : null,
          ),
          // Menu de Personalização e Cores
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Personalizar',
            onPressed: widget.lista.isLocked ? null : () => _mostrarDialogoConfiguracoes(context),
          ),
          // Botão Trancar / Destrancar
          IconButton(
            icon: Icon(widget.lista.isLocked ? Icons.lock : Icons.lock_open),
            tooltip: widget.lista.isLocked ? 'Destrancar' : 'Trancar',
            onPressed: () {
              widget.lista.isLocked = !widget.lista.isLocked;
              _persistirESincronizar();
            },
          ),
        ],
      ),
      body: widget.lista.linhas.isEmpty
          ? Center(
              child: Text(
                'Nenhum item na grade.\nAdicione linhas usando o botão abaixo.',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(corAtiva.withOpacity(0.12)),
                  columns: widget.lista.colunas.map((coluna) {
                    return DataColumn(
                      label: Text(
                        coluna.nome,
                        style: TextStyle(fontWeight: FontWeight.bold, color: corAtiva),
                      ),
                    );
                  }).toList(),
                  rows: widget.lista.linhas.map((entidade) {
                    return DataRow(
                      cells: widget.lista.colunas.map((coluna) {
                        final valor = entidade.valores[coluna.id] ?? '';
                        return DataCell(
                          Text(valor.isEmpty ? '-' : valor),
                          showEditIcon: !widget.lista.isLocked,
                          onTap: widget.lista.isLocked
                              ? null
                              : () => _mostrarEditorCelula(context, entidade, coluna),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
      floatingActionButton: widget.lista.isLocked
          ? null
          : FloatingActionButton(
              backgroundColor: corAtiva,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                _gravarAlteracaoParaUndo();
                final novaEntidade = Entidade(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  valores: {},
                );
                for (var col in widget.lista.colunas) {
                  novaEntidade.valores[col.id] = '';
                }
                widget.lista.linhas.add(novaEntidade);
                _persistirESincronizar();
              },
            ),
    );
  }

  void _mostrarEditorCelula(BuildContext context, Entidade entidade, ColunaEspecificacao coluna) {
    final controller = TextEditingController(text: entidade.valores[coluna.id] ?? '');
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
            onPressed: () {
              _gravarAlteracaoParaUndo();
              entidade.valores[coluna.id] = controller.text;
              _persistirESincronizar();
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
                  crossAxisAlignment: CrossAlignment.start,
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
                        _persistirESincronizar();
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
                            _persistirESincronizar();
                          }
                        },
                      ),
                    const Divider(height: 24),
                    SwitchListTile(
                      title: const Text('Mostrar Hora'),
                      value: widget.lista.mostrarHora,
                      onChanged: (val) {
                        setDialogState(() => widget.lista.mostrarHora = val);
                        _persistirESincronizar();
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
                            _persistirESincronizar();
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
        _persistirESincronizar();
      },
      child: CircleAvatar(
        backgroundColor: cor,
        radius: 18,
        child: selecionado ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
      ),
    );
  }
}
