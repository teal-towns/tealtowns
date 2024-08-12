// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

// import '../../app_scaffold.dart';
// // import '../../common/style.dart';
// import './user_availability_save.dart';
// import './user_interest_save.dart';
// import './current_user_state.dart';

// class UserInterestAvailabilitySave extends StatefulWidget {
//   @override
//   _UserInterestAvailabilitySaveState createState() => _UserInterestAvailabilitySaveState();
// }

// class _UserInterestAvailabilitySaveState extends State<UserInterestAvailabilitySave> {
//   @override
//   void initState() {
//     super.initState();

//     if (!Provider.of<CurrentUserState>(context, listen: false).isLoggedIn) {
//       Timer(Duration(milliseconds: 200), () {
//         context.go('/login');
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     CurrentUserState currentUserState = context.watch<CurrentUserState>();
//     if (!currentUserState.isLoggedIn) {
//       return AppScaffoldComponent(
//         listWrapper: true,
//         body: Column(children: [ LinearProgressIndicator() ]),
//       );
//     }
//     return AppScaffoldComponent(
//       listWrapper: true,
//       width: 900,
//       body: Column(
//         children: [
//           UserInterestSave(),
//           UserAvailabilitySave(),
//         ],
//       ),
//     );
//   }
// }
