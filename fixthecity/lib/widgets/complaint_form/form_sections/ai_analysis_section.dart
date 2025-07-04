import 'package:flutter/material.dart';
import '../../models/road_issue_analysis.dart';

class AiAnalysisSection extends StatelessWidget {
  final RoadIssueAnalysis? analysis;
  final bool isAnalyzing;
  final VoidCallback? onAcceptSuggestions;
  final VoidCallback? onRejectSuggestions;

  const AiAnalysisSection({
    Key? key,
    required this.analysis,
    required this.isAnalyzing,
    this.onAcceptSuggestions,
    this.onRejectSuggestions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isAnalyzing) {
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'AI is analyzing your image...',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (analysis == null) return const SizedBox.shrink();

    if (!analysis!.isRelevant) {
      return Card(
        color: Colors.orange.shade50,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'The AI couldn\'t identify a relevant issue in this image. Please fill the form manually.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'AI Analysis Complete',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${(analysis!.confidence * 100).toStringAsFixed(0)}% confident',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Category', analysis!.category),
            _buildInfoRow('Severity', _getSeverityText(analysis!.severity)),
            _buildInfoRow('Department', analysis!.department),
            const SizedBox(height: 8),
            Text(
              'Analysis: ${analysis!.explanation}',
              style: const TextStyle(fontSize: 14),
            ),
            if (analysis!.suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Suggestions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...analysis!.suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAcceptSuggestions,
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Use AI Suggestions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRejectSuggestions,
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text('Fill Manually'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _getSeverityText(int severity) {
    switch (severity) {
      case 1:
      case 2:
        return 'Low (General maintenance request)';
      case 3:
        return 'Medium (Significant inconvenience)';
      case 4:
      case 5:
        return 'High (Major disruption, safety risk)';
      default:
        return 'Unknown';
    }
  }
}