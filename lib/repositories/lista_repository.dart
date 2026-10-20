import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class ListaRepository {
  static final ListaRepository _singleton = ListaRepository._internal();
  factory ListaRepository() => _singleton;
  ListaRepository._internal();

  Database? _db;
  final _store = stringMapStoreFactory.store('listas');

  Future<Database> get database async {
    if (_db != null) return _db!;
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDocDir.path, 'banco_dinamico.db');
    _db = await databaseFactoryIo.openDatabase(dbPath);
    return _db!;
  }

  Future<void> salvarLista(ListaEntidades lista) async {
    final db = await database;
    await _store.record(lista.id).put(db, lista.toJson());
  }

  Future<ListaEntidades?> obterLista(String id) async {
    final db = await database;
    final record = await _store.record(id).get(db);
    if (record != null) {
      return ListaEntidades.fromJson(record);
    }
    return null;
  }
}
