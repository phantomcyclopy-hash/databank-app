enum TipoAtributo { texto, numero, checkbox }

class ColunaEspecificacao {
  String id;
  String nome;
  TipoAtributo tipo;

  ColunaEspecificacao({
    required this.id,
    required this.nome,
    this.tipo = TipoAtributo.texto,
  });

  Map<String, dynamic> toMap() => toJson();

  factory ColunaEspecificacao.fromMap(Map<String, dynamic> json) =>
      ColunaEspecificacao.fromJson(json);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'tipo': tipo.name,
      };

  factory ColunaEspecificacao.fromJson(Map<String, dynamic> json) {
    return ColunaEspecificacao(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      tipo: TipoAtributo.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoAtributo.texto,
      ),
    );
  }
}

class Entidade {
  String id;
  String nome;
  Map<String, String> valoresAtributos;

  Entidade({
    required this.id,
    required this.nome,
    required this.valoresAtributos,
  });

  Entidade copiar() {
    return Entidade(
      id: id,
      nome: nome,
      valoresAtributos: Map<String, String>.from(valoresAtributos),
    );
  }

  Map<String, dynamic> toMap() => toJson();

  factory Entidade.fromMap(Map<String, dynamic> json) =>
      Entidade.fromJson(json);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'valoresAtributos': valoresAtributos,
      };

  factory Entidade.fromJson(Map<String, dynamic> json) {
    return Entidade(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      valoresAtributos: Map<String, String>.from(
        json['valoresAtributos'] ?? json['valores'] ?? {},
      ),
    );
  }
}

class ListaEntidades {
  String id;
  String titulo;
  String descricao;
  bool mostrarData;
  String formatoData; // 'dd/mm/aaaa' ou 'mm/aaaa'
  bool mostrarHora;
  String formatoHora; // '12h' ou '24h'
  String corTema; // 'azul', 'verde', 'roxo', 'cinza'
  bool isLocked;
  List<ColunaEspecificacao> colunas;
  List<Entidade> linhas;

  ListaEntidades({
    required this.id,
    required this.titulo,
    this.descricao = '',
    this.mostrarData = true,
    this.formatoData = 'dd/mm/aaaa',
    this.mostrarHora = true,
    this.formatoHora = '24h',
    this.corTema = 'azul',
    this.isLocked = false,
    required this.colunas,
    required this.linhas,
  });

  // Apelidos (aliases) para compatibilidade direta com o import_export_helper.dart
  Map<String, dynamic> toMap() => toJson();

  factory ListaEntidades.fromMap(Map<String, dynamic> json) =>
      ListaEntidades.fromJson(json);

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'descricao': descricao,
        'mostrarData': mostrarData,
        'formatoData': formatoData,
        'mostrarHora': mostrarHora,
        'formatoHora': formatoHora,
        'corTema': corTema,
        'isLocked': isLocked,
        'colunas': colunas.map((c) => c.toJson()).toList(),
        'linhas': linhas.map((l) => l.toJson()).toList(),
      };

  factory ListaEntidades.fromJson(Map<String, dynamic> json) {
    return ListaEntidades(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      mostrarData: json['mostrarData'] ?? true,
      formatoData: json['formatoData'] ?? 'dd/mm/aaaa',
      mostrarHora: json['mostrarHora'] ?? true,
      formatoHora: json['formatoHora'] ?? '24h',
      corTema: json['corTema'] ?? 'azul',
      isLocked: json['isLocked'] ?? false,
      colunas: (json['colunas'] as List? ?? [])
          .map((c) => ColunaEspecificacao.fromJson(c))
          .toList(),
      linhas: (json['linhas'] as List? ?? [])
          .map((l) => Entidade.fromJson(l))
          .toList(),
    );
  }
}
