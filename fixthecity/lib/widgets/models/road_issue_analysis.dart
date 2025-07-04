class RoadIssueAnalysis {
  final bool isRelevant;
  final String category;
  final int severity;
  final String department;
  final String explanation;
  final List<String> suggestions;
  final double confidence;

  const RoadIssueAnalysis({
    required this.isRelevant,
    required this.category,
    required this.severity,
    required this.department,
    required this.explanation,
    required this.suggestions,
    required this.confidence,
  });

  factory RoadIssueAnalysis.fromJson(Map<String, dynamic> json) {
    List<String> _safeList(dynamic raw) =>
        raw is List ? raw.whereType<String>().toList() : <String>[];

    return RoadIssueAnalysis(
      isRelevant: json['isRelevant'] as bool? ?? false,
      category: json['category'] as String? ?? 'unknown',
      severity: (json['severity'] as num?)?.toInt() ?? 1,
      department: json['department'] as String? ?? 'municipality',
      explanation: json['explanation'] as String? ?? 'No explanation',
      suggestions: _safeList(json['suggestions']),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'isRelevant': isRelevant,
    'category': category,
    'severity': severity,
    'department': department,
    'explanation': explanation,
    'suggestions': suggestions,
    'confidence': confidence,
  };
}
