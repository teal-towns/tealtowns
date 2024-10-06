// TODO - finish, then use from weekly_events to do 1 click event joining. Need to:
// 1. get user event for all weekly events on load (in weekly_events) and display if user is already signed up
// 2. get event from weekly event
// 3. use event to form userEvent and save that (possibly going to stripe first)

// import '../../common/socket_service.dart';

// class UserEventSaveService {
//   UserEventSaveService._privateConstructor();
//   static final UserEventSaveService _instance = UserEventSaveService._privateConstructor();
//   factory UserEventSaveService() {
//     return _instance;
//   }

//   List<String> _routeIds = [];
//   SocketService _socketService = SocketService();

//   String _eventId = '';
//   Function(Map<String, dynamic>)? _onSave;
//   Map<String, dynamic> _userEvent = {};

//   void Init() {
//     if (_routeIds.length == 0) {
//       _routeIds.add(_socketService.onRoute('StripeGetPaymentLink', callback: (String resString) {
//         var res = jsonDecode(resString);
//         var data = res['data'];
//         if (data['valid'] == 1) {
//           if (data.containsKey('forId') && data.containsKey('forType') &&
//             data['forType'] == 'event' && _eventId.length > 0 && data['forId'] == _eventId) {
//             _linkService.LaunchURL(data['url']);
//           }
//         } else {
//           if (_onSave != null) {
//             _onSave!({ 'message': data['message'].length > 0 ? data['message'] : 'Error, please try again.', });
//             _onSave = null;
//           }
//         }
//       }));

//       _routeIds.add(_socketService.onRoute('StripePaymentComplete', callback: (String resString) {
//         var res = jsonDecode(resString);
//         var data = res['data'];
//         if (data.containsKey('forId') && _eventId.length > 0 && data['forId'] == _eventId &&
//           data.containsKey('forType') && data['forType'] == 'event') {
//           _socketService.emit('SaveUserEvent', { 'userEvent': _userEvent, 'payType': 'paid' });
//         }
//       }));

//       _routeIds.add(_socketService.onRoute('SaveUserEvent', callback: (String resString) {
//         var res = json.decode(resString);
//         var data = res['data'];
//         if (data['valid'] == 1) {
//           if (_onSave != null) {
//             _onSave!({});
//             _onSave = null;
//           }
//         }
//       }));
//     }
//   }

//   void JoinEvent(String title, double priceUSD, String userId, Function(Map<String, dynamic>) onSave,
//     { String eventId = '', Map<String, dynamic> userEvent = const {}, int attendeeCountAsk = 1 }) {
//     double price = priceUSD * attendeeCountAsk;
//     if (priceUSD == 0) {
//       _socketService.emit('SaveUserEvent', { 'userEvent': _formVals, 'payType': 'free' });
//     } else if (_availableCreditUSD >= price) {
//       _socketService.emit('SaveUserEvent', { 'userEvent': _formVals, 'payType': 'creditUSD' });
//     } else if (_availableUSD >= price) {
//       _socketService.emit('SaveUserEvent', { 'userEvent': _formVals, 'payType': 'userMoney' });
//     } else {
//       String title = attendeeCountAsk > 1 ?
//         '${attendeeCountAsk} spots: ${title}' : title;
//       var data = {
//         'amountUSD': price,
//         'userId': userId,
//         'title': title,
//         'forId': _event.id!,
//         'quantity': attendeeCountAsk,
//         'forType': 'event',
//       };
//       _socketService.emit('StripeGetPaymentLink', data);
//     }

//     _eventId = eventId;
//     _onSave = onSave;
//     _userEvent = userEvent;
//   }
// }
