class ColunaEspecificacao {
  String id;
  String nome;
  String tipo; // 'texto', 'numero', 'checkbox'

  ColunaEspecificacao({required this.id, required this.nome, this.tipo = 'texto'});

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'tipo': tipo};

  factory ColunaEspecificacao.fromJson(Map<String, dynamic> json) {
    return ColunaEspecificacao(
      id: json['id'],
      nome: json['nome'],
      tipo: json['tipo'] ?? 'texto',
    );
  }
}

class Entidade {
  String id;
  Map<String, String> valores;

  Entidade({required this.id, required this.valores});

  Entidade copiar() {
    return Entidade(id: id, valores: Map.from(valores));
  }

  Map<String, dynamic> toJson() => {'id': id, 'valores': valores};

  factory Entidade.fromJson(Map<String, dynamic> json) {
    return Entidade(
      id: json['id'],
      valores: Map<String, String>.from(json['valores'] ?? {}),
    );
  }
}

class ListaEntidades {
  String id;
  String titulo;
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
    this.mostrarData = true,
    this.formatoData = 'dd/mm/aaaa',
    this.mostrarHora = true,
    this.formatoHora = '24h',
    this.corTema = 'azul',
    this.isLocked = false,
    required this.colunas,
    required this.linhas,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
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
      id: json['id'],
      titulo: json['titulo'] ?? '',
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
