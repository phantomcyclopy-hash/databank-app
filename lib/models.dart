import 'dart:convert';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
String novoId() => _uuid.v4();

int _ms(DateTime d) => d.toUtc().millisecondsSinceEpoch;
DateTime _lerData(Object? v) =>
    v is int ? DateTime.fromMillisecondsSinceEpoch(v) : DateTime.now();

// ---------------------------------------------------------------------------
// Definição de Colunas / Especificações da Lista
// ---------------------------------------------------------------------------

enum TipoAtributo {
  texto,
  numero,
  booleano,
  data;

  static TipoAtributo deNome(String? nome) => TipoAtributo.values
      .firstWhere((t) => t.name == nome, orElse: () => TipoAtributo.texto);
}

/// Define uma coluna na grade da lista (ex: "Telefone", "Cargo", "Preço")
class ColunaEspecificacao {
  const ColunaEspecificacao({
    required this.id,
    required this.nome,
    this.tipo = TipoAtributo.texto,
  });

  final String id;
  final String nome;
  final TipoAtributo tipo;

  Map<String, Object?> toMap() => {
        'id': id,
        'nome': nome,
        'tipo': tipo.name,
      };

  factory ColunaEspecificacao.fromMap(Map<String, Object?> map) =>
      ColunaEspecificacao(
        id: (map['id'] as String?) ?? novoId(),
        nome: (map['nome'] as String?) ?? '',
        tipo: TipoAtributo.deNome(map['tipo'] as String?),
      );
}

// ---------------------------------------------------------------------------
// Modelo da Lista (Container de Linhas e Colunas)
// ---------------------------------------------------------------------------

class ListaEntidades {
  ListaEntidades({
    required this.id,
    required this.titulo,
    this.descricao = '',
    this.colunas = const [],
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    this.excluidoEm,
  })  : criadoEm = criadoEm ?? DateTime.now(),
        atualizadoEm = atualizadoEm ?? DateTime.now();

  final String id;
  final String titulo;
  final String descricao;
  
  /// Todas as colunas/especificações que esta lista possui
  final List<ColunaEspecificacao> colunas;
  
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final DateTime? excluidoEm;

  Map<String, Object?> toMap() => {
        'id': id,
        'titulo': titulo,
        'descricao': descricao,
        'colunas': colunas.map((c) => c.toMap()).toList(),
        'criadoEm': _ms(criadoEm),
        'atualizadoEm': _ms(atualizadoEm),
        'excluidoEm': excluidoEm == null ? null : _ms(excluidoEm!),
      };

  factory ListaEntidades.fromMap(Map<String, Object?> map) => ListaEntidades(
        id: map['id'] as String,
        titulo: (map['titulo'] as String?) ?? 'Sem título',
        descricao: (map['descricao'] as String?) ?? '',
        colunas: (map['colunas'] as List? ?? [])
            .whereType<Map>()
            .map((m) => ColunaEspecificacao.fromMap(Map<String, Object?>.from(m)))
            .toList(),
        criadoEm: _lerData(map['criadoEm']),
        atualizadoEm: _lerData(map['atualizadoEm']),
      );
}

// ---------------------------------------------------------------------------
// Entidade (Linha da Grade)
// ---------------------------------------------------------------------------

class Entidade {
  Entidade({
    required this.id,
    required this.listaId,
    required this.nome,
    this.valoresAtributos = const {}, // Mapeia: colunaId -> valor
    this.presencas = const [],
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    this.excluidoEm,
  })  : criadoEm = criadoEm ?? DateTime.now(),
        atualizadoEm = atualizadoEm ?? DateTime.now();

  final String id;
  final String listaId; // Pertence a uma lista específica
  final String nome;

  /// Guarda os valores das colunas da lista para esta pessoa/objeto: {colunaId: valor}
  final Map<String, Object?> valoresAtributos;
  
  final List<RegistroPresenca> presencas;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final DateTime? excluidoEm;

  Map<String, Object?> toMap() => {
        'id': id,
        'listaId': listaId,
        'nome': nome,
        'valoresAtributos': valoresAtributos,
        'criadoEm': _ms(criadoEm),
        'atualizadoEm': _ms(atualizadoEm),
        'excluidoEm': excluidoEm == null ? null : _ms(excluidoEm!),
      };

  factory Entidade.fromMap(Map<String, Object?> map) => Entidade(
        id: map['id'] as String,
        listaId: (map['listaId'] as String?) ?? '',
        nome: (map['nome'] as String?) ?? '',
        valoresAtributos:
            Map<String, Object?>.from((map['valoresAtributos'] as Map?) ?? {}),
        criadoEm: _lerData(map['criadoEm']),
        atualizadoEm: _lerData(map['atualizadoEm']),
      );
}

// ---------------------------------------------------------------------------
// Registro de Presença (Permanecem vinculados às Entidades)
// ---------------------------------------------------------------------------

class RegistroPresenca {
  RegistroPresenca({
    required this.id,
    required this.entidadeId,
    required this.timestamp,
    this.isVisible = true,
  });

  final String id;
  final String entidadeId;
  final DateTime timestamp;
  final bool isVisible;

  Map<String, Object?> toMap() => {
        'id': id,
        'entidadeId': entidadeId,
        'timestamp': _ms(timestamp),
        'isVisible': isVisible,
      };

  factory RegistroPresenca.fromMap(Map<String, Object?> map) => RegistroPresenca(
        id: map['id'] as String,
        entidadeId: (map['entidadeId'] as String?) ?? '',
        timestamp: _lerData(map['timestamp']),
        isVisible: (map['isVisible'] as bool?) ?? true,
      );
}
