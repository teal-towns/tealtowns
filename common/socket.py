import asyncio
import json

_routes = {}
_routes_async = {}

def get_route_type(route: str):
    if route in _routes:
        return "sync"
    if route in _routes_async:
        return "async"
    return ""

def socket_router(websocket, route: str, data, auth: dict):
    if route not in _routes:
        raise Exception("route not found")
    return _routes[route](data, auth, websocket)

async def socket_router_async(websocket, route: str, data, auth: dict):
    if route not in _routes_async:
        raise Exception("route not found")
    return await _routes_async[route](data, auth, websocket)

def add_route(route: str, func, mode="sync"):
    if mode == "async":
        _routes_async[route] = func
    else:
        _routes[route] = func

def remove_route(route: str, mode="sync"):
    if mode == "async" and route in _routes_async:
        del _routes_async[route]
    elif route in _routes:
        del _routes[route]

def form_send_data(route, data, auth):
    return {"route": route, "data": data, "auth": auth}

# def Send(websocket, route, data, auth):
#     asyncio.create_task(sendAsync(websocket, route, data, auth))

async def sendAsync(websocket, route, data, auth):
    ret = form_send_data(route, data, auth)
    # await websocket.send_text(json.dumps(ret))
    utf8Bytes = json.dumps(ret).encode(encoding='utf-8')
    await websocket.send_bytes(utf8Bytes)
