import '../models/models.dart';

class GridHistoricoManager {
  final List<List<Entidade>> _undoStack = [];
  final List<List<Entidade>> _redoStack = [];

  void gravarEstado(List<Entidade> estadoAtual) {
    _undoStack.add(estadoAtual.map((e) => e.copiar()).toList());
    _redoStack.clear();
  }

  List<Entidade>? desfazer(List<Entidade> estadoAtual) {
    if (_undoStack.isEmpty) return null;
    _redoStack.add(estadoAtual.map((e) => e.copiar()).toList());
    return _undoStack.removeLast();
  }

  List<Entidade>? refazer(List<Entidade> estadoAtual) {
    if (_redoStack.isEmpty) return null;
    _undoStack.add(estadoAtual.map((e) => e.copiar()).toList());
    return _redoStack.removeLast();
  }

  bool get podeDesfazer => _undoStack.isNotEmpty;
  bool get podeRefazer => _redoStack.isNotEmpty;
}
