import 'package:flutter/material.dart';

class NeighborhoodJourneyService {
  NeighborhoodJourneyService._privateConstructor();
  static final NeighborhoodJourneyService _instance = NeighborhoodJourneyService._privateConstructor();
  factory NeighborhoodJourneyService() {
    return _instance;
  }

  List<Map<String, dynamic>> BelongingSteps() {
    List<Map<String, dynamic>> steps = [
      { 'title': 'Meet first neighbor', 'icon': Icons.person, 'descriptionSteps': [
          'Invite 1 neighbor to eat together',
        ],
        'type': 'user', 'completeCount': 1,
      },
      { 'title': 'Start first weekly shared meal', 'icon': Icons.fastfood, 'descriptionSteps': [
        'Set up a regular weekly time to meet',
        'Set up a weekly shared meal',
      ], 'type': 'weeklyEvent', 'completeCount': 1, },
      { 'title': 'Grow to 25 neighbors', 'icon': Icons.group, 'descriptionSteps': [
        'Meet and invite 1 new neighbor each week',
        'At the end of each weekly event, each person invites a housemate or neighbor to the next event',
      ], 'type': 'user', 'completeCount': 25, },
      { 'title': 'Start shared interest events', 'icon': Icons.sports_soccer, 'descriptionSteps': [
        'People discuss hobbies during the shared meal',
        'When a few people have overlapping interests, create a new weekly event around it',
      ], 'type': 'weeklyEvent', 'completeCount': 5, },
      { 'title': 'Grow to 50 neighbors', 'icon': Icons.groups, 'descriptionSteps': [
        'Meet and invite 1 new neighbor each week',
        'At the end of each weekly event, each person invites a housemate or neighbor to the next event',
      ], 'type': 'user', 'completeCount': 50, },
      { 'title': 'Start shared ownership items', 'icon': Icons.handyman, 'descriptionSteps': [
        'People discuss what they (would like to) own and would like to share',
        'Each person posts 1 shared item they own or want to co-purchase',
      ], 'type': 'sharedItem', 'completeCount': 10, },
      { 'title': 'Grow to 100 to 150 neighbors', 'icon': Icons.diversity_3, 'descriptionSteps': [
        'Meet and invite 1 new neighbor each week',
        'At the end of each weekly event, each person invites a new neighbor to the next event',
      ], 'type': 'user', 'completeCount': 100, },
      { 'title': 'Start green projects', 'icon': Icons.compost, 'descriptionSteps': [
        'Discuss ways to reduce the carbon footprint of your neighborhood',
        'Choose a first project to try out',
      ], 'type': 'greenProject', 'completeCount': 5, },
    ];
    return steps;
  }

  List<Map<String, dynamic>> BelongingStepsWithComplete(int usersCountLastWeek, int weeklyEventsCount, int sharedItemsCount) {
    List<Map<String, dynamic>> steps = BelongingSteps();
    int currentStep = 0;
    for (var i = 0; i < steps.length; i++) {
      steps[i]['complete'] = false;
      if (steps[i]['type'] == 'user') {
        if (usersCountLastWeek >= steps[i]['completeCount']) {
          steps[i]['complete'] = true;
        }
      } else if (steps[i]['type'] == 'weeklyEvent') {
        if (weeklyEventsCount >= steps[i]['completeCount']) {
          steps[i]['complete'] = true;
        }
      } else if (steps[i]['type'] == 'sharedItem') {
        if (sharedItemsCount >= steps[i]['completeCount']) {
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

  List<Map<String, dynamic>> SustainableSteps() {
    List<Map<String, dynamic>> steps = [
      // { 'title': 'Zero Waste', 'icon': Icons.fastfood, 'descriptionSteps': [
      //   'Set up a regular weekly time to meet',
      //   'Set up a weekly shared meal',
      // ], 'type': 'weeklyEvent', 'completeCount': 1, },
      // TODO
    ];
    return steps;
  }
}