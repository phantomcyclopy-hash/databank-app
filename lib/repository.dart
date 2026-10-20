import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

import 'models.dart';

abstract class AppRepository {
  // Gestão de Listas
  Stream<List<ListaEntidades>> observarListas();
  Future<ListaEntidades> criarLista({required String titulo, String descricao = ''});
  Future<void> atualizarLista(ListaEntidades lista);
  Future<void> removerLista(String listaId);

  // Gestão de Colunas globais da Lista (Especificações da Grade)
  Future<void> adicionarColuna(String listaId, String nome, TipoAtributo tipo);
  Future<void> removerColuna(String listaId, String colunaId);

  // Gestão de Entidades (Linhas da Grade) dentro de uma Lista
  Stream<List<Entidade>> observarEntidadesDaLista(String listaId);
  Future<Entidade> adicionarEntidade({required String listaId, required String nome});
  Future<void> atualizarValorAtributo(String entidadeId, String colunaId, Object? valor);
  Future<void> removerEntidade(String id);

  // Gestão de Presenças / Histórico
  Stream<List<RegistroPresenca>> observarPresencas(String entidadeId);
  Future<RegistroPresenca> registrarPresenca(String entidadeId, {DateTime? quando});
  Future<void> alternarVisibilidadePresenca(String presencaId);
}

class SembastAppRepository implements AppRepository {
  SembastAppRepository._(this._db);

  final Database _db;
  final _storeListas = stringMapStoreFactory.store('listas');
  final _storeEntidades = stringMapStoreFactory.store('entidades');
  final _storePresencas = stringMapStoreFactory.store('presencas');

  static Future<SembastAppRepository> abrir() async {
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    final db = await databaseFactoryIo.openDatabase(
      p.join(dir.path, 'banco_dinamico_v2.db'),
      version: 1,
      onVersionChanged: (db, oldVersion, newVersion) async {},
    );
    return SembastAppRepository._(db);
  }

  // --- Listas ---

  @override
  Stream<List<ListaEntidades>> observarListas() => _storeListas
          .query(finder: Finder(filter: Filter.isNull('excluidoEm')))
          .onSnapshots(_db)
          .map((snaps) {
        final lista = snaps.map((s) => ListaEntidades.fromMap(s.value)).toList()
          ..sort((a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()));
        return lista;
      });

  @override
  Future<ListaEntidades> criarLista({required String titulo, String descricao = ''}) async {
    final novaLista = ListaEntidades(
      id: novoId(),
      titulo: titulo.trim(),
      descricao: descricao.trim(),
    );
    await _storeListas.record(novaLista.id).put(_db, novaLista.toMap());
    return novaLista;
  }

  @override
  Future<void> atualizarLista(ListaEntidades lista) async {
    final atualizada = ListaEntidades(
      id: lista.id,
      titulo: lista.titulo,
      descricao: lista.descricao,
      colunas: lista.colunas,
      criadoEm: lista.criadoEm,
      atualizadoEm: DateTime.now(),
      excluidoEm: lista.excluidoEm,
    );
    await _storeListas.record(lista.id).put(_db, atualizada.toMap());
  }

  @override
  Future<void> removerLista(String listaId) async {
    await _db.transaction((txn) async {
      // Exclusão lógica da lista
      final ref = _storeListas.record(listaId);
      final bruto = await ref.get(txn);
      if (bruto != null) {
        final lista = ListaEntidades.fromMap(bruto);
        await ref.put(txn, {
          ...lista.toMap(),
          'excluidoEm': _ms(DateTime.now()),
        });
      }
    });
  }

  // --- Colunas da Grade ---

  @override
  Future<void> adicionarColuna(String listaId, String nome, TipoAtributo tipo) async {
    await _db.transaction((txn) async {
      final ref = _storeListas.record(listaId);
      final bruto = await ref.get(txn);
      if (bruto == null) return;
      
      final lista = ListaEntidades.fromMap(bruto);
      final novaColuna = ColunaEspecificacao(id: novoId(), nome: nome.trim(), tipo: tipo);
      
      final colunasAtualizadas = [...lista.colunas, novaColuna];
      final listaModificada = ListaEntidades(
        id: lista.id,
        titulo: lista.titulo,
        descricao: lista.descricao,
        colunas: colunasAtualizadas,
        criadoEm: lista.criadoEm,
        atualizadoEm: DateTime.now(),
      );
      
      await ref.put(txn, listaModificada.toMap());
    });
  }

  @override
  Future<void> removerColuna(String listaId, String colunaId) async {
    await _db.transaction((txn) async {
      final ref = _storeListas.record(listaId);
      final bruto = await ref.get(txn);
      if (bruto == null) return;
      
      final lista = ListaEntidades.fromMap(bruto);
      final colunasAtualizadas = lista.colunas.where((c) => c.id != colunaId).toList();
      
      final listaModificada = ListaEntidades(
        id: lista.id,
        titulo: lista.titulo,
        descricao: lista.descricao,
        colunas: colunasAtualizadas,
        criadoEm: lista.criadoEm,
        atualizadoEm: DateTime.now(),
      );
      
      await ref.put(txn, listaModificada.toMap());
    });
  }

  // --- Entidades (Linhas) ---

  @override
  Stream<List<Entidade>> observarEntidadesDaLista(String listaId) => _storeEntidades
          .query(finder: Finder(
            filter: Filter.and([
              Filter.equals('listaId', listaId),
              Filter.isNull('excluidoEm'),
            ]),
          ))
          .onSnapshots(_db)
          .map((snaps) {
        final lista = snaps.map((s) => Entidade.fromMap(s.value)).toList()
          ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
        return lista;
      });

  @override
  Future<Entidade> adicionarEntidade({required String listaId, required String nome}) async {
    final novaEntidade = Entidade(
      id: novoId(),
      listaId: listaId,
      nome: nome.trim(),
    );
    await _storeEntidades.record(novaEntidade.id).put(_db, novaEntidade.toMap());
    return novaEntidade;
  }

  @override
  Future<void> atualizarValorAtributo(String entidadeId, String colunaId, Object? valor) async {
    await _db.transaction((txn) async {
      final ref = _storeEntidades.record(entidadeId);
      final bruto = await ref.get(txn);
      if (bruto == null) return;

      final entidade = Entidade.fromMap(bruto);
      final novosValores = Map<String, Object?>.from(entidade.valoresAtributos);
      if (valor == null) {
        novosValores.remove(colunaId);
      } else {
        novosValores[colunaId] = valor;
      }

      final entidadeAtualizada = Entidade(
        id: entidade.id,
        listaId: entidade.listaId,
        nome: entidade.nome,
        valoresAtributos: novosValores,
        criadoEm: entidade.criadoEm,
        atualizadoEm: DateTime.now(),
      );

      await ref.put(txn, entidadeAtualizada.toMap());
    });
  }

  @override
  Future<void> removerEntidade(String id) async {
    await _db.transaction((txn) async {
      final ref = _storeEntidades.record(id);
      final bruto = await ref.get(txn);
      if (bruto != null) {
        final entidade = Entidade.fromMap(bruto);
        await ref.put(txn, {
          ...entidade.toMap(),
          'excluidoEm': _ms(DateTime.now()),
        });
      }
    });
  }

  // --- Presenças ---

  @override
  Stream<List<RegistroPresenca>> observarPresencas(String entidadeId) => _storePresencas
          .query(finder: Finder(
            filter: Filter.equals('entidadeId', entidadeId),
            sortOrders: [SortOrder('timestamp', false)],
          ))
          .onSnapshots(_db)
          .map((snaps) => snaps.map((s) => RegistroPresenca.fromMap(s.value)).toList());

  @override
  Future<RegistroPresenca> registrarPresenca(String entidadeId, {DateTime? quando}) async {
    final registro = RegistroPresenca(
      id: novoId(),
      entidadeId: entidadeId,
      timestamp: quando ?? DateTime.now(),
    );
    await _storePresencas.record(registro.id).put(_db, registro.toMap());
    return registro;
  }

  @override
  Future<void> alternarVisibilidadePresenca(String presencaId) async {
    await _db.transaction((txn) async {
      final ref = _storePresencas.record(presencaId);
      final bruto = await ref.get(txn);
      if (bruto == null) return;
      final atual = RegistroPresenca.fromMap(bruto);
      final modificado = RegistroPresenca(
        id: atual.id,
        entidadeId: atual.entidadeId,
        timestamp: atual.timestamp,
        isVisible: !atual.isVisible,
      );
      await ref.put(txn, modificado.toMap());
    });
  }
}
