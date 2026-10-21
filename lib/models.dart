class ColunaEspecificacao {
  String id;
  String nome;
  String tipo; // 'texto', 'numero', 'checkbox'

  ColunaEspecificacao({
    required this.id,
    required this.nome,
    this.tipo = 'texto',
  });

  Map<String, dynamic> toMap() => toJson();

  factory ColunaEspecificacao.fromMap(Map<String, dynamic> json) =>
      ColunaEspecificacao.fromJson(json);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'tipo': tipo,
      };

  factory ColunaEspecificacao.fromJson(Map<String, dynamic> json) {
    return ColunaEspecificacao(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      tipo: json['tipo'] ?? 'texto',
    );
  }
}

class Entidade {
  String id;
  String nome;
  String? fotoBase64;
  String cpf;
  String rg;
  String idade;
  String sexo;
  String tipoSanguineo;
  String telefone;
  String celular;
  String email;
  Map<String, String> valoresAtributosDinamicos;

  Entidade({
    required this.id,
    required this.nome,
    this.fotoBase64,
    this.cpf = '',
    this.rg = '',
    this.idade = '',
    this.sexo = 'N/A',
    this.tipoSanguineo = 'N/A',
    this.telefone = '',
    this.celular = '',
    this.email = '',
    required this.valoresAtributosDinamicos,
  });

  Entidade copiar() {
    return Entidade(
      id: id,
      nome: nome,
      fotoBase64: fotoBase64,
      cpf: cpf,
      rg: rg,
      idade: idade,
      sexo: sexo,
      tipoSanguineo: tipoSanguineo,
      telefone: telefone,
      celular: celular,
      email: email,
      valoresAtributosDinamicos: Map<String, String>.from(valoresAtributosDinamicos),
    );
  }

  Map<String, dynamic> toMap() => toJson();

  factory Entidade.fromMap(Map<String, dynamic> json) =>
      Entidade.fromJson(json);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'fotoBase64': fotoBase64,
        'cpf': cpf,
        'rg': rg,
        'idade': idade,
        'sexo': sexo,
        'tipoSanguineo': tipoSanguineo,
        'telefone': telefone,
        'celular': celular,
        'email': email,
        'valoresAtributosDinamicos': valoresAtributosDinamicos,
      };

  factory Entidade.fromJson(Map<String, dynamic> json) {
    return Entidade(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      fotoBase64: json['fotoBase64'],
      cpf: json['cpf'] ?? '',
      rg: json['rg'] ?? '',
      idade: json['idade'] ?? '',
      sexo: json['sexo'] ?? 'N/A',
      tipoSanguineo: json['tipoSanguineo'] ?? 'N/A',
      telefone: json['telefone'] ?? '',
      celular: json['celular'] ?? '',
      email: json['email'] ?? '',
      valoresAtributosDinamicos: Map<String, String>.from(
        json['valoresAtributosDinamicos'] ?? json['valores'] ?? {},
      ),
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
  String corTema; // Código Hex
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
    this.corTema = '#2196F3',
    this.isLocked = false,
    required this.colunas,
    required this.linhas,
  });

  Map<String, dynamic> toMap() => toJson();

  factory ListaEntidades.fromMap(Map<String, dynamic> json) =>
      ListaEntidades.fromJson(json);

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
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      mostrarData: json['mostrarData'] ?? true,
      formatoData: json['formatoData'] ?? 'dd/mm/aaaa',
      mostrarHora: json['mostrarHora'] ?? true,
      formatoHora: json['formatoHora'] ?? '24h',
      corTema: json['corTema'] ?? '#2196F3',
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
