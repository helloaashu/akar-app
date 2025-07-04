class IssueTypesData {
  static const List<String> categories = [
    'Roads',
    'Traffic',
    'Drinking water',
    'Drainage',
    'Electricity',
    'Waste Management',
    'Animals',
    'Others'
  ];

  static List<String> getIssueTypesForCategory(String? category) {
    switch (category) {
      case 'Roads':
        return [
          'Potholes',
          'Road damage',
          'Obstructed walkway',
          'Broken sidewalk',
          'Other',
        ];
      case 'Traffic':
        return [
          'Traffic light malfunction',
          'Street sign issues',
          'Road markings faded',
          'Other',
        ];
      case 'Drinking water':
        return [
          'Water supply interruption',
          'Contaminated water',
          'Low water pressure',
          'Broken pipelines',
          'Leaking taps or hydrants',
          'Other',
        ];
      case 'Drainage':
        return [
          'Blocked drains',
          'Damaged drainage system',
          'Overflowing drainage',
          'Foul odor from drains',
          'Broken manholes',
          'Other',
        ];
      case 'Electricity':
        return [
          'Power outage',
          'Faulty streetlights',
          'Exposed wires',
          'Voltage fluctuation',
          'Damaged poles',
          'Other',
        ];
      case 'Waste Management':
        return [
          'Missed garbage collection',
          'Overflowing public trash bin',
          'Illegal dumping',
          'Recycling issues',
          'Other',
        ];
      case 'Animals':
        return [
          'Stray animals causing nuisance',
          'Injured animals needing rescue',
          'Dead animal disposal',
          'Overpopulation of stray animals',
          'Animal cruelty cases',
          'Other',
        ];
      case 'Other':
        return ['Please specify'];
      default:
        return ['Other'];
    }
  }
}