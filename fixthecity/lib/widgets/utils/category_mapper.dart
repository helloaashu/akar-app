class CategoryMapper {
  // Map AI categories to your form categories
  static String mapAiCategoryToFormCategory(String aiCategory) {
    final categoryMap = {
      'road': 'Roads',
      'roads': 'Roads',
      'pothole': 'Roads',
      'potholes': 'Roads',
      'road damage': 'Roads',
      'traffic': 'Traffic',
      'traffic light': 'Traffic',
      'water': 'Drinking water',
      'drinking water': 'Drinking water',
      'water supply': 'Drinking water',
      'drainage': 'Drainage',
      'drain': 'Drainage',
      'electricity': 'Electricity',
      'power': 'Electricity',
      'waste': 'Waste Management',
      'garbage': 'Waste Management',
      'trash': 'Waste Management',
      'animal': 'Animals',
      'animals': 'Animals',
      'stray': 'Animals',
    };

    final lowerCategory = aiCategory.toLowerCase();

    // Check for exact match first
    if (categoryMap.containsKey(lowerCategory)) {
      return categoryMap[lowerCategory]!;
    }

    // Check for partial matches
    for (final entry in categoryMap.entries) {
      if (lowerCategory.contains(entry.key) || entry.key.contains(lowerCategory)) {
        return entry.value;
      }
    }

    return 'Others';
  }

  // Map AI issue types to form issue types
  static String mapAiIssueToFormIssue(String category, String aiIssue) {
    final issueMap = {
      'Roads': {
        'pothole': 'Potholes',
        'damage': 'Road damage',
        'obstruction': 'Obstructed walkway',
        'sidewalk': 'Broken sidewalk',
      },
      'Traffic': {
        'light': 'Traffic light malfunction',
        'sign': 'Street sign issues',
        'marking': 'Road markings faded',
      },
      'Drinking water': {
        'interruption': 'Water supply interruption',
        'contaminated': 'Contaminated water',
        'pressure': 'Low water pressure',
        'pipeline': 'Broken pipelines',
        'leak': 'Leaking taps or hydrants',
      },
      // Add more mappings as needed
    };

    final lowerIssue = aiIssue.toLowerCase();
    final categoryMap = issueMap[category] ?? {};

    for (final entry in categoryMap.entries) {
      if (lowerIssue.contains(entry.key) || entry.key.contains(lowerIssue)) {
        return entry.value;
      }
    }

    return 'Other';
  }
}