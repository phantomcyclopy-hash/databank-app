import 'dart:convert';

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// ID único e estável (também é a chave de sincronização na nuvem).
String novoId() => _uuid.v4();

DateTime _lerData(Object? v) =>
    v is int ? DateTime.fromMillisecondsSinceEpoch(v) : DateTime.now();

DateTime? _lerDataOpcional(Object? v) =>
    v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;

/// Datas são persistidas como epoch em milissegundos UTC:
/// ordenação trivial, sem ambiguidade de fuso, compatível com Firestore/Supabase.
int _ms(DateTime d) => d.toUtc().millisecondsSinceEpoch;

// ---------------------------------------------------------------------------
// Enums (leitura tolerante: valor desconhecido nunca quebra dados legados)
// ---------------------------------------------------------------------------

enum TipoAtributo {
  texto,
  numero,
  booleano,
  data;

  static TipoAtributo deNome(String? nome) => TipoAtributo.values
      .firstWhere((t) => t.name == nome, orElse: () => TipoAtributo.texto);
}

enum TipoEntidade {
  pessoa,
  objeto,
  outro;

  static TipoEntidade deNome(String? nome) => TipoEntidade.values
      .firstWhere((t) => t.name == nome, orElse: () => TipoEntidade.outro);
}

// ---------------------------------------------------------------------------
// AtributoDinamico
// ---------------------------------------------------------------------------

class AtributoDinamico {
  const AtributoDinamico({
    required this.id,
    required this.chave,
    required this.valor,
    this.tipo = TipoAtributo.texto,
  });

  factory AtributoDinamico.novo({
    required String chave,
    Object? valor,
    TipoAtributo tipo = TipoAtributo.texto,
  }) =>
      AtributoDinamico(id: novoId(), chave: chave, valor: valor, tipo: tipo);

  /// Identificador próprio: permite renomear a chave sem perder a identidade
  /// do atributo (importante para sincronização).
  final String id;
  final String chave;

  /// Sempre um valor compatível com JSON: String, num, bool ou null.
  /// Datas são guardadas como String ISO-8601.
  final Object? valor;
  final TipoAtributo tipo;

  AtributoDinamico copyWith({String? chave, Object? valor, TipoAtributo? tipo}) =>
      AtributoDinamico(
        id: id,
        chave: chave ?? this.chave,
        valor: valor ?? this.valor,
        tipo: tipo ?? this.tipo,
      );

  /// Converte o texto digitado para o tipo (somente texto e número).
  /// Retorna null se o texto for inválido para o tipo.
  static Object? interpretar(String bruto, TipoAtributo tipo) {
    switch (tipo) {
      case TipoAtributo.numero:
        return num.tryParse(bruto.trim().replaceAll(',', '.'));
      case TipoAtributo.texto:
        return bruto.trim();
      default:
        return null;
    }
  }

  String get valorFormatado {
    final v = valor;
    if (v == null) return '—';
    switch (tipo) {
      case TipoAtributo.booleano:
        return v == true ? 'Sim' : 'Não';
      case TipoAtributo.data:
        final d = DateTime.tryParse(v.toString());
        if (d == null) return v.toString();
        return '${d.day.toString().padLeft(2, '0')}/'
            '${d.month.toString().padLeft(2, '0')}/${d.year}';
      default:
        return v.toString();
    }
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'chave': chave,
        'valor': valor,
        'tipo': tipo.name,
      };

  factory AtributoDinamico.fromMap(Map<String, Object?> map) =>
      AtributoDinamico(
        id: (map['id'] as String?) ?? novoId(),
        chave: (map['chave'] as String?) ?? '',
        valor: map['valor'],
        tipo: TipoAtributo.deNome(map['tipo'] as String?),
      );

  String toJson() => jsonEncode(toMap());

  factory AtributoDinamico.fromJson(String fonte) =>
      AtributoDinamico.fromMap(
          Map<String, Object?>.from(jsonDecode(fonte) as Map));
}

// ---------------------------------------------------------------------------
// RegistroPresenca
// ---------------------------------------------------------------------------

class RegistroPresenca {
  RegistroPresenca({
    required this.id,
    required this.entidadeId,
    required this.timestamp,
    this.isVisible = true,
    DateTime? atualizadoEm,
  }) : atualizadoEm = atualizadoEm ?? DateTime.now();

  factory RegistroPresenca.agora(String entidadeId, {DateTime? quando}) =>
      RegistroPresenca(
          id: novoId(), entidadeId: entidadeId, timestamp: quando ?? DateTime.now());

  final String id;
  final String entidadeId;
  final DateTime timestamp;

  /// Apenas controla a exibição. O registro nunca é apagado ao ocultar.
  final bool isVisible;
  final DateTime atualizadoEm;

  // Data, mês, hora e minuto derivados de uma única fonte da verdade
  // (o timestamp): impossível ficarem inconsistentes entre si.
  DateTime get data => DateTime(timestamp.year, timestamp.month, timestamp.day);
  int get dia => timestamp.day;
  int get mes => timestamp.month;
  int get ano => timestamp.year;
  int get hora => timestamp.hour;
  int get minuto => timestamp.minute;

  RegistroPresenca copyWith({bool? isVisible, DateTime? atualizadoEm}) =>
      RegistroPresenca(
        id: id,
        entidadeId: entidadeId,
        timestamp: timestamp,
        isVisible: isVisible ?? this.isVisible,
        atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'entidadeId': entidadeId,
        'timestamp': _ms(timestamp),
        'isVisible': isVisible,
        'atualizadoEm': _ms(atualizadoEm),
      };

  factory RegistroPresenca.fromMap(Map<String, Object?> map) =>
      RegistroPresenca(
        id: map['id'] as String,
        entidadeId: (map['entidadeId'] as String?) ?? '',
        timestamp: _lerData(map['timestamp']),
        isVisible: (map['isVisible'] as bool?) ?? true,
        atualizadoEm: _lerData(map['atualizadoEm']),
      );

  String toJson() => jsonEncode(toMap());

  factory RegistroPresenca.fromJson(String fonte) => RegistroPresenca.fromMap(
      Map<String, Object?>.from(jsonDecode(fonte) as Map));
}

// ---------------------------------------------------------------------------
// Entidade
// ---------------------------------------------------------------------------

class Entidade {
  Entidade({
    required this.id,
    required this.nome,
    required this.tipo,
    this.atributos = const [],
    this.presencas = const [],
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    this.excluidoEm,
    this.schemaVersion = 1,
  })  : criadoEm = criadoEm ?? DateTime.now(),
        atualizadoEm = atualizadoEm ?? DateTime.now();

  factory Entidade.nova({
    required String nome,
    required TipoEntidade tipo,
    List<AtributoDinamico> atributos = const [],
  }) =>
      Entidade(id: novoId(), nome: nome, tipo: tipo, atributos: atributos);

  final String id;
  final String nome;
  final TipoEntidade tipo;
  final List<AtributoDinamico> atributos;

  /// Preenchida pelo repositório ao carregar o detalhe (mais recentes primeiro).
  final List<RegistroPresenca> presencas;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  /// Exclusão lógica (tombstone): necessária para propagar deleções na sync.
  final DateTime? excluidoEm;

  /// Versão do formato do documento, para migrações futuras.
  final int schemaVersion;

  Entidade copyWith({
    String? nome,
    TipoEntidade? tipo,
    List<AtributoDinamico>? atributos,
    List<RegistroPresenca>? presencas,
    DateTime? atualizadoEm,
    DateTime? excluidoEm,
  }) =>
      Entidade(
        id: id,
        nome: nome ?? this.nome,
        tipo: tipo ?? this.tipo,
        atributos: atributos ?? this.atributos,
        presencas: presencas ?? this.presencas,
        criadoEm: criadoEm,
        atualizadoEm: atualizadoEm ?? this.atualizadoEm,
        excluidoEm: excluidoEm ?? this.excluidoEm,
        schemaVersion: schemaVersion,
      );

  /// Inclui ou substitui (por id) uma especificação.
  Entidade comAtributo(AtributoDinamico novo) {
    final lista = [...atributos];
    final i = lista.indexWhere((a) => a.id == novo.id);
    if (i >= 0) {
      lista[i] = novo;
    } else {
      lista.add(novo);
    }
    return copyWith(atributos: lista);
  }

  Entidade semAtributo(String atributoId) =>
      copyWith(atributos: atributos.where((a) => a.id != atributoId).toList());

  Map<String, Object?> toMap({bool incluirPresencas = true}) => {
        'id': id,
        'nome': nome,
        'tipo': tipo.name,
        'atributos': atributos.map((a) => a.toMap()).toList(),
        if (incluirPresencas)
          'presencas': presencas.map((p) => p.toMap()).toList(),
        'criadoEm': _ms(criadoEm),
        'atualizadoEm': _ms(atualizadoEm),
        'excluidoEm': excluidoEm == null ? null : _ms(excluidoEm!),
        'schemaVersion': schemaVersion,
      };

  factory Entidade.fromMap(Map<String, Object?> map) => Entidade(
        id: map['id'] as String,
        nome: (map['nome'] as String?) ?? '',
        tipo: TipoEntidade.deNome(map['tipo'] as String?),
        atributos: _lerAtributos(map['atributos']),
        presencas: _lerPresencas(map['presencas']),
        criadoEm: _lerData(map['criadoEm']),
        atualizadoEm: _lerData(map['atualizadoEm']),
        excluidoEm: _lerDataOpcional(map['excluidoEm']),
        schemaVersion: (map['schemaVersion'] as int?) ?? 1,
      );

  static List<AtributoDinamico> _lerAtributos(Object? bruto) {
    if (bruto is List) {
      return bruto
          .whereType<Map>()
          .map((m) => AtributoDinamico.fromMap(Map<String, Object?>.from(m)))
          .toList();
    }
    // Formato legado: {"idade": 30, "cor": "azul"} -> lista de atributos.
    if (bruto is Map) {
      return bruto.entries
          .map((e) => AtributoDinamico(
                id: 'legado_${e.key}',
                chave: e.key.toString(),
                valor: e.value,
              ))
          .toList();
    }
    return const [];
  }

  static List<RegistroPresenca> _lerPresencas(Object? bruto) {
    if (bruto is! List) return const [];
    return bruto
        .whereType<Map>()
        .map((m) => RegistroPresenca.fromMap(Map<String, Object?>.from(m)))
        .toList();
  }

  String toJson() => jsonEncode(toMap());

  factory Entidade.fromJson(String fonte) =>
      Entidade.fromMap(Map<String, Object?>.from(jsonDecode(fonte) as Map));
}
