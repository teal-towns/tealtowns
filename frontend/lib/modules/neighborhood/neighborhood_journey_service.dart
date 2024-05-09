import 'package:flutter/material.dart';

class NeighborhoodJourneyService {
  NeighborhoodJourneyService._privateConstructor();
  static final NeighborhoodJourneyService _instance = NeighborhoodJourneyService._privateConstructor();
  factory NeighborhoodJourneyService() {
    return _instance;
  }

  List<Map<String, dynamic>> Steps() {
    List<Map<String, dynamic>> steps = [
      { 'title': 'Meet first neighbor', 'icon': Icons.person, 'descriptionSteps': [
          'Invite 1 neighbor to eat together',
        ],
        'type': 'user', 'complete_count': 1,
      },
      { 'title': 'Start first weekly event', 'icon': Icons.fastfood, 'descriptionSteps': [
        'Set up a regular weekly time to meet',
        'Set up a weekly shared meal',
      ], 'type': 'weekly_event', 'complete_count': 1, },
      { 'title': 'Grow to 25 neighbors', 'icon': Icons.group, 'descriptionSteps': [
        'Meet and invite 1 new neighbor each week',
        'At the end of each weekly event, remind each person to bring a housemate or neighbor',
      ], 'type': 'user', 'complete_count': 25, },
      { 'title': 'Start shared interest events', 'icon': Icons.sports_soccer, 'descriptionSteps': [
        'Have people discuss hobbies during the shared meal',
        'When a few people have overlapping interests, create a new weekly event around it',
      ], 'type': 'weekly_event', 'complete_count': 5, },
      { 'title': 'Grow to 50 neighbors', 'icon': Icons.groups, 'descriptionSteps': [
        'Meet and invite 1 new neighbor each week',
        'At the end of each weekly event, remind each person to bring a housemate or neighbor',
      ], 'type': 'user', 'complete_count': 50, },
      { 'title': 'Start shared ownership items', 'icon': Icons.handyman, 'descriptionSteps': [
        'Have people discuss what they own and would like to share',
        'Have people discuss what they would like to co-purchase',
        'Have each person post 1 shared item',
      ], 'type': 'shared_item', 'complete_count': 10, },
      { 'title': 'Grow to 100 to 150 neighbors', 'icon': Icons.diversity_3, 'descriptionSteps': [
        'Meet and invite 1 new neighbor each week',
        'At the end of each weekly event, remind each person to bring a housemate or neighbor',
      ], 'type': 'user', 'complete_count': 100, },
      { 'title': 'Start green projects', 'icon': Icons.compost, 'descriptionSteps': [
        'Discuss ways to reduce the carbon footprint of your neighborhood',
      ], 'type': 'green_project', 'complete_count': 5, },
    ];
    return steps;
  }

  List<Map<String, dynamic>> StepsWithComplete(int usersCountLastWeek, int weeklyEventsCount, int sharedItemsCount) {
    List<Map<String, dynamic>> steps = Steps();
    int currentStep = 0;
    for (var i = 0; i < steps.length; i++) {
      steps[i]['complete'] = false;
      if (steps[i]['type'] == 'user') {
        if (usersCountLastWeek >= steps[i]['complete_count']) {
          steps[i]['complete'] = true;
        }
      } else if (steps[i]['type'] == 'weekly_event') {
        if (weeklyEventsCount >= steps[i]['complete_count']) {
          steps[i]['complete'] = true;
        }
      } else if (steps[i]['type'] == 'shared_item') {
        if (sharedItemsCount >= steps[i]['complete_count']) {
          steps[i]['complete'] = true;
        }
      }
      // Increment current step if all previous steps are complete.
      if ((steps[i]['complete'] || i == 0) && currentStep >= i) {
        currentStep = i;
        steps[i]['current'] = true;
        if (i > 0) {
          steps[(i-1)]['current'] = false;
        }
      }
    }
    return steps;
  }
}