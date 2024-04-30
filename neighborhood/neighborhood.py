from common import mongo_db_crud as _mongo_db_crud
from event import weekly_event as _weekly_event
from shared_item import shared_item as _shared_item

def GetByUName(uName: str, withWeeklyEvents: int = 0, withSharedItems: int = 0, withSustainability: int = 0,
    withConnections: int = 0, weeklyEventsCount: int = 3, sharedItemsCount: int = 3, maxMeters: float = 500,
    limitCount: int = 250):
    ret = _mongo_db_crud.GetByUName('neighborhood', uName)

    lngLat = ret['neighborhood']['location']['coordinates']
    if withWeeklyEvents:
        items = _weekly_event.SearchNear(lngLat, maxMeters, limit = limitCount)['weeklyEvents']
        ret['weeklyEventsCount'] = len(items)
        ret['weeklyEvents'] = items[slice(0, weeklyEventsCount)] if len(items) > weeklyEventsCount else items
    if withSharedItems:
        items = _shared_item.SearchNear(lngLat, maxMeters, limit = limitCount)['sharedItems']
        ret['sharedItemsCount'] = len(items)
        ret['sharedItems'] = items[slice(0, sharedItemsCount)] if len(items) > sharedItemsCount else items
    if withSustainability:
        # TODO
        pass
    if withConnections:
        # TODO
        pass
    return ret
