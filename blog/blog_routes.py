# from fastapi import APIRouter

from blog import blog as _blog
from common import socket as _socket

# router = APIRouter()

def addRoutes():
    def GetBlogs(data, auth, websocket):
        title = data['title'] if 'title' in data else ''
        tags = data['tags'] if 'tags' in data else []
        userIdCreator = data['userIdCreator'] if 'userIdCreator' in data else ''
        slug = data['slug'] if 'slug' in data else ''
        limit = data['limit'] if 'limit' in data else 25
        skip = data['skip'] if 'skip' in data else 0
        sortKey = data['sortKey'] if 'sortKey' in data else ''
        ret = _blog.Get(title, tags, userIdCreator, slug, limit = limit, skip = skip,
            sortKey = sortKey)
        return ret
    _socket.add_route('getBlogs', GetBlogs)

    def RemoveBlog(data, auth, websocket):
        ret = _blog.Remove(data['id'])
        return ret
    _socket.add_route('removeBlog', RemoveBlog)

    def SaveBlog(data, auth, websocket):
        ret = _blog.Save(data['blog'], auth['userId'])
        return ret
    _socket.add_route('saveBlog', SaveBlog)

addRoutes()
