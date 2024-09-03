from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
from event import featured_event_photo as _featured_event_photo
import lodash

def AddRoutes():
    def GetRecentEventFeedbacks(data, auth, websocket):
        return _featured_event_photo.GetRecentEventFeedbacks()
    _socket.add_route('GetRecentEventFeedbacks', GetRecentEventFeedbacks)

    def CreateFeaturedEventPhoto(data, auth, websocket):
        return _featured_event_photo.CreateFeaturedEventPhoto(data['eventId'], data['imageUrl'])
    _socket.add_route('CreateFeaturedEventPhoto', CreateFeaturedEventPhoto)

    def Search(data, auth, websocket):
        data = lodash.extend_object({
            'title': '',
            'limit': 100,
            'skip': 0,
            'sortKeys': '-start',
        }, data)
        stringKeyVals = { 'title': data['title'] }
        return _mongo_db_crud.Search('featuredEventPhoto', stringKeyVals = stringKeyVals,
            limit = data['limit'], skip = data['skip'], sortKeys = data['sortKeys'])
    _socket.add_route('SearchFeaturedEventPhotos', Search)

    def Remove(data, auth, websocket):
        return _mongo_db_crud.RemoveById('featuredEventPhoto', data['id'])
    _socket.add_route('RemoveFeaturedEventPhoto', Remove)

AddRoutes()
