import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../utils/historico_manager.dart';

class DetalhesListaScreen extends StatefulWidget {
  final ListaEntidades lista;
  const DetalhesListaScreen({super.key, required this.lista});

  @override
  State<DetalhesListaScreen> createState() => _DetalhesListaScreenState();
}

class _DetalhesListaScreenState extends State<DetalhesListaScreen> {
  late TextEditingController _tituloController;
  final GridHistoricoManager _historico = GridHistoricoManager();

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.lista.titulo);
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

  void _gravarAlteracao() {
    _historico.gravarEstado(widget.lista.linhas);
    setState(() {});
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
            onPressed: _historico.podeDesfazer && !widget.lista.isLocked
                ? () {
                    setState(() {
                      final estadoAnterior = _historico.desfazer(widget.lista.linhas);
                      if (estadoAnterior != null) widget.lista.linhas = estadoAnterior;
                    });
                  }
                : null,
          ),
          // Botão Refazer
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _historico.podeRefazer && !widget.lista.isLocked
                ? () {
                    setState(() {
                      final estadoSeguinte = _historico.refazer(widget.lista.linhas);
                      if (estadoSeguinte != null) widget.lista.linhas = estadoSeguinte;
                    });
                  }
                : null,
          ),
          // Botão Trancar / Destrancar
          IconButton(
            icon: Icon(widget.lista.isLocked ? Icons.lock : Icons.lock_open),
            onPressed: () {
              setState(() {
                widget.lista.isLocked = !widget.lista.isLocked;
              });
            },
          ),
        ],
      ),
      body: widget.lista.linhas.isEmpty
          ? Center(
              child: Text(
                'Nenhum item na grade. Adicione linhas usando o botão abaixo.',
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
                              : () {
                                  _mostrarEditorCelula(context, entidade, coluna);
                                },
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
                _gravarAlteracao();
                setState(() {
                  final novaEntidade = Entidade(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    valores: {},
                  );
                  for (var col in widget.lista.colunas) {
                    novaEntidade.valores[col.id] = '';
                  }
                  widget.lista.linhas.add(novaEntidade);
                });
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
          decoration: InputDecoration(
            hintText: 'Digite o valor',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _gravarAlteracao();
              setState(() {
                entidade.valores[coluna.id] = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
