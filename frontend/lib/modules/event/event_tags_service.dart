class EventTagsService {
  EventTagsService._privateConstructor();
  static final EventTagsService _instance = EventTagsService._privateConstructor();
  factory EventTagsService() {
    return _instance;
  }

  Map<String, List<String>> _tags = {
    'artCrafts': ['ceramic', 'glass', 'textile', 'clothing', 'paper', 'wood', 'stone', 'metal'],
    // 'family': ['infant', 'toddler', 'child', 'preteen', 'teenage', 'parent'],
    'family': ['kid', 'parent'],
    'fitness': ['strength', 'cardio', 'dance', 'swim', 'run', 'bike', 'yoga', 'pilates', 'stretch'],
    'food': ['breakfast', 'lunch', 'dinner', 'drinks', 'snack', 'cook', 'bake'],
    'games': ['boardGame', 'puzzle', 'lawnGames', 'poolGames', 'cardGames', 'partyGames'],
    'health': ['walk', 'hike', 'meditate', 'spirituality', 'nature'],
    'musicLanguage': ['musicInstrument', 'language'],
    // 'selfImprovement': [''],
    // 'spirituality': [''],
    'sports': ['acrobatics', 'waterSports', 'archery', 'baseball', 'basketball', 'football', 'soccer', 'hockey', 'lacrosse', 'badminton', 'pickleball', 'tennis', 'tableTennis', 'volleyball', 'skateboard', 'climbing', 'martialArts', 'discGolf', 'ultimateFrisbee', 'gymnastics', 'parkour',],
    'sustainability': ['garden', 'renewableEnergy', 'farm', 'zeroWaste', 'compost', 'lendLibrary',],
    // 'volunteerCauses': ['animalShelter',],
  };

  Map<String, List<String>> GetTags() {
    return _tags;
  }

  List<String> GetSubcategories(String category) {
    if (_tags.containsKey(category)) {
      return _tags[category]!;
    } else {
      return [];
    }
  }

  List<String> GetCategories() {
    return _tags.keys.toList();
  }

  List<Map<String, dynamic>> GetTagsOpts() {
    List<Map<String, dynamic>> optsTags = [];
    for (String category in _tags.keys) {
      Map<String, dynamic> opt = {'value': category, 'label': category, };
      optsTags.add(opt);
      List<String> subcats = _tags[category]!;
      for (String subcat in subcats) {
        Map<String, dynamic> opt = {'value': subcat, 'label': subcat, };
        optsTags.add(opt);
      }
    }
    return optsTags;
  }
}
