class Contract {
  final int id;
  final String title;
  final String? fileUrl;
  final String status;
  final List<Clause> clauses;

  Contract({
    required this.id,
    required this.title,
    this.fileUrl,
    this.status = 'uploaded',
    this.clauses = const [],
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'],
      title: json['title'],
      fileUrl: json['file_url'],
      status: json['status'] ?? 'uploaded',
      clauses: (json['clauses'] as List?)
          ?.map((c) => Clause.fromJson(c))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'file_url': fileUrl,
    'status': status,
    'clauses': clauses.map((c) => c.toJson()).toList(),
  };
}

class Clause {
  final int id;
  final int order;
  final String originalText;
  final String? simpleEn;
  final String? arabic;
  final List<KeyTerm> keyTerms;
  final bool completed;
  final bool isDefinition;
  final List<int> relatedOrders;

  Clause({
    required this.id,
    required this.order,
    required this.originalText,
    this.simpleEn,
    this.arabic,
    this.keyTerms = const [],
    this.completed = false,
    this.isDefinition = false,
    this.relatedOrders = const [],
  });

  factory Clause.fromJson(Map<String, dynamic> json) {
    return Clause(
      id: json['id'],
      order: json['order'],
      originalText: json['original_text'],
      simpleEn: json['simple_en'],
      arabic: json['arabic'],
      keyTerms: (json['key_terms'] as List?)
          ?.map((kt) => KeyTerm.fromJson(kt))
          .toList() ?? [],
      completed: json['completed'] as bool? ?? false,
      isDefinition: json['is_definition'] as bool? ?? false,
      relatedOrders: (json['related_orders'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order': order,
    'original_text': originalText,
    'simple_en': simpleEn,
    'arabic': arabic,
    'key_terms': keyTerms.map((kt) => kt.toJson()).toList(),
  };
}

class KeyTerm {
  final String term;
  final String meaning;

  KeyTerm({required this.term, required this.meaning});

  factory KeyTerm.fromJson(Map<String, dynamic> json) {
    return KeyTerm(term: json['term'], meaning: json['meaning']);
  }

  Map<String, dynamic> toJson() => {'term': term, 'meaning': meaning};
}
