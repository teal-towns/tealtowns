from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
from user import user_interest as _user_interest

def addRoutes():
    def Save(data, auth, websocket):
        return _user_interest.Save(data['userInterest'])
    _socket.add_route('SaveUserInterest', Save)

    def GetInterestsByNeighborhood(data, auth, websocket):
        data = lodash.extend_object({
            'groupByInterest': 1,
            'groupedSortKey': '',
        }, data)
        return _user_interest.GetInterestsByNeighborhood(data['neighborhoodUName'],
            groupByInterest = data['groupByInterest'], groupedSortKey = data['groupedSortKey'])
    _socket.add_route('GetInterestsByNeighborhood', GetInterestsByNeighborhood)

    def GetEventInterests(data, auth, websocket):
        return _user_interest.GetEventInterests()
    _socket.add_route('GetEventInterests', GetEventInterests)

addRoutes()
