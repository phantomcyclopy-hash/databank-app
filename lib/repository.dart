import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart'; //
import 'package:sembast/sembast_io.dart';

import 'models.dart';

/// Contrato de persistência. A UI só conhece esta interface, então o backend
/// (Sembast, Drift, Isar...) e a sincronização na nuvem podem mudar sem
/// tocar nas telas.
abstract class EntidadeRepository {
  Stream<List<Entidade>> observarEntidades();
  Stream<Entidade?> observar(String id);
  Future<Entidade?> buscar(String id);

  Future<Entidade> adicionarEntidade({
    required String nome,
    required TipoEntidade tipo,
    List<AtributoDinamico> atributos = const [],
  });
  Future<void> renomearEntidade(String id, String nome);
  Future<void> removerEntidade(String id);

  /// Insere ou altera (por id) uma especificação. Os demais atributos
  /// e as presenças não são afetados.
  Future<void> salvarAtributo(String entidadeId, AtributoDinamico atributo);
  Future<void> removerAtributo(String entidadeId, String atributoId);

  Future<RegistroPresenca> registrarPresenca(String entidadeId,
      {DateTime? quando});

  /// Alterna isVisible. O registro permanece no banco.
  Future<void> alternarVisibilidade(String presencaId);
}

class SembastEntidadeRepository implements EntidadeRepository {
  SembastEntidadeRepository._(this._db);

  final Database _db;
  final _entidades = stringMapStoreFactory.store('entidades');
  final _presencas = stringMapStoreFactory.store('presencas');

  /// Abre (ou cria) o arquivo local. Funciona offline em
  /// Android, iOS, Windows, macOS e Linux.
  static Future<SembastEntidadeRepository> abrir() async {
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    final db = await databaseFactoryIo.openDatabase(
      p.join(dir.path, 'banco_dinamico.db'),
      version: 1,
      // Ponto de extensão para migrações futuras (schemaVersion).
      onVersionChanged: (db, oldVersion, newVersion) async {},
    );
    return SembastEntidadeRepository._(db);
  }

  Future<void> fechar() => _db.close();

  // ----------------------------- Leitura ----------------------------------

  @override
  Stream<List<Entidade>> observarEntidades() => _entidades
          .query(finder: Finder(filter: Filter.isNull('excluidoEm')))
          .onSnapshots(_db)
          .map((snaps) {
        final lista = snaps.map((s) => Entidade.fromMap(s.value)).toList()
          ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
        return lista;
      });

  @override
  Future<Entidade?> buscar(String id) async {
    final bruto = await _entidades.record(id).get(_db);
    if (bruto == null) return null;
    final entidade = Entidade.fromMap(bruto);
    if (entidade.excluidoEm != null) return null;

    final snaps = await _presencas.find(
      _db,
      finder: Finder(
        filter: Filter.equals('entidadeId', id),
        sortOrders: [SortOrder('timestamp', false)], // mais recentes primeiro
      ),
    );
    return entidade.copyWith(
      presencas: snaps.map((s) => RegistroPresenca.fromMap(s.value)).toList(),
    );
  }

  /// Reemite a entidade completa quando o documento OU suas presenças mudam.
  @override
  Stream<Entidade?> observar(String id) {
    late StreamController<Entidade?> ctrl;
    final subs = <StreamSubscription<Object?>>[];

    Future<void> emitir() async {
      if (!ctrl.isClosed) ctrl.add(await buscar(id));
    }

    ctrl = StreamController<Entidade?>(
      onListen: () {
        subs.add(_entidades.record(id).onSnapshot(_db).listen((_) => emitir()));
        subs.add(_presencas
            .query(finder: Finder(filter: Filter.equals('entidadeId', id)))
            .onSnapshots(_db)
            .listen((_) => emitir()));
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
        await ctrl.close();
      },
    );
    return ctrl.stream;
  }

  // ----------------------------- Escrita ----------------------------------

  @override
  Future<Entidade> adicionarEntidade({
    required String nome,
    required TipoEntidade tipo,
    List<AtributoDinamico> atributos = const [],
  }) async {
    final entidade =
        Entidade.nova(nome: nome.trim(), tipo: tipo, atributos: atributos);
    await _entidades
        .record(entidade.id)
        .put(_db, entidade.toMap(incluirPresencas: false));
    return entidade;
  }

  @override
  Future<void> renomearEntidade(String id, String nome) =>
      _mutar(id, (e) => e.copyWith(nome: nome.trim()));

  @override
  Future<void> removerEntidade(String id) =>
      _mutar(id, (e) => e.copyWith(excluidoEm: DateTime.now()));

  @override
  Future<void> salvarAtributo(String entidadeId, AtributoDinamico atributo) =>
      _mutar(entidadeId, (e) => e.comAtributo(atributo));

  @override
  Future<void> removerAtributo(String entidadeId, String atributoId) =>
      _mutar(entidadeId, (e) => e.semAtributo(atributoId));

  @override
  Future<RegistroPresenca> registrarPresenca(String entidadeId,
      {DateTime? quando}) {
    return _db.transaction((txn) async {
      if (!await _entidades.record(entidadeId).exists(txn)) {
        throw StateError('Entidade $entidadeId não existe.');
      }
      final registro = RegistroPresenca.agora(entidadeId, quando: quando);
      await _presencas.record(registro.id).put(txn, registro.toMap());
      return registro;
    });
  }

  @override
  Future<void> alternarVisibilidade(String presencaId) {
    return _db.transaction((txn) async {
      final ref = _presencas.record(presencaId);
      final bruto = await ref.get(txn);
      if (bruto == null) return;
      final atual = RegistroPresenca.fromMap(bruto);
      final novo = atual.copyWith(
        isVisible: !atual.isVisible,
        atualizadoEm: DateTime.now(),
      );
      await ref.put(txn, novo.toMap());
    });
  }

  /// Ler-modificar-gravar dentro de uma transação: evita perder alterações
  /// concorrentes e mantém atualizadoEm coerente (base para a sync).
  Future<void> _mutar(String id, Entidade Function(Entidade) alterar) {
    return _db.transaction((txn) async {
      final ref = _entidades.record(id);
      final bruto = await ref.get(txn);
      if (bruto == null) throw StateError('Entidade $id não existe.');
      final novo =
          alterar(Entidade.fromMap(bruto)).copyWith(atualizadoEm: DateTime.now());
      await ref.put(txn, novo.toMap(incluirPresencas: false));
    });
  }
}
