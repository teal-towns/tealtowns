import json
import random

import mongo_mock as _mongo_mock
from vector_tiles import vector_tiles_data as _vector_tiles_data
import lodash

_mongo_mock.InitAllCollections()

def test_GetTiles():
    count = 2
    # timeframe = 'actual'
    # year = 2023
    timeframe = ''
    year = ''
    lat = 37.7498
    lng = -122.4546
    zoom = 16
    ret = _vector_tiles_data.GetTiles(lat, lng, timeframe=timeframe, year=year, yCount = count, xCount = count,
        zoom = zoom)
    assert len(ret['tileRows']) == count
    for index, tileRow in enumerate(ret['tileRows']):
        assert len(tileRow) == count

    # Save tile
    tile = ret['tileRows'][0][0]
    latTopLeft = tile['latTopLeft']
    lngTopLeft = tile['lngTopLeft']
    tileSave = {
        'tileX': tile['tileX'],
        'tileY': tile['tileY'],
        'temperatureCelsiusAnnual': {
            'value': 5,
            'confidencePercent': 10,
        },
    }
    ret = _vector_tiles_data.SaveTile(zoom, tileSave, timeframe, year)
    assert ret['valid'] == 1
    tileSaved = ret['tile']

    # Get tile
    ret = _vector_tiles_data.GetTileById(zoom, tileSaved['_id'], timeframe, year)
    assert ret['tile']['_id'] == tileSaved['_id']
    assert ret['tile']['latTopLeft'] == latTopLeft
    assert ret['tile']['lngTopLeft'] == lngTopLeft

    # Re-get same tiles and confirm we got the update.
    ret = _vector_tiles_data.GetTiles(lat, lng, timeframe=timeframe, year=year, yCount = count, xCount = count,
        zoom = zoom)
    assert len(ret['tileRows']) == count
    for index, tileRow in enumerate(ret['tileRows']):
        assert len(tileRow) == count
    assert ret['tileRows'][0][0]['temperatureCelsiusAnnual']['value'] == tileSave['temperatureCelsiusAnnual']['value']
    assert ret['tileRows'][0][0]['latTopLeft'] == latTopLeft
    assert ret['tileRows'][0][0]['lngTopLeft'] == lngTopLeft

    # Save existing tile (with _id)
    tile = tileSaved
    tile['temperatureCelsiusAnnual']['value'] = 10
    ret = _vector_tiles_data.SaveTile(zoom, tile, timeframe, year)
    assert ret['valid'] == 1
    assert ret['tile']['latTopLeft'] == latTopLeft
    assert ret['tile']['lngTopLeft'] == lngTopLeft

    # Re-get same tiles and confirm we got the update.
    ret = _vector_tiles_data.GetTiles(lat, lng, timeframe = timeframe, year = year, yCount = count, xCount = count,
        zoom = zoom)
    assert len(ret['tileRows']) == count
    for index, tileRow in enumerate(ret['tileRows']):
        assert len(tileRow) == count
    assert ret['tileRows'][0][0]['temperatureCelsiusAnnual']['value'] == tile['temperatureCelsiusAnnual']['value']
    assert ret['tileRows'][0][0]['latTopLeft'] == latTopLeft
    assert ret['tileRows'][0][0]['lngTopLeft'] == lngTopLeft

    # Fill all tiles.
    for tileRow in ret['tileRows']:
        for tile in tileRow:
            tileSave = {
                'tileX': tile['tileX'],
                'tileY': tile['tileY'],
                'temperatureCelsiusAnnual': {
                    'value': random.randint(0, 40),
                    'confidencePercent': random.randint(0, 100),
                },
            }
            ret = _vector_tiles_data.SaveTile(zoom, tileSave, timeframe, year)

    ret = _vector_tiles_data.GetTiles(lat, lng, timeframe=timeframe, year=year, yCount = count, xCount = count,
        zoom = zoom)
    assert len(ret['tileRows']) == count
    for index, tileRow in enumerate(ret['tileRows']):
        assert len(tileRow) == count
    assert ret['tileRows'][0][0]['latTopLeft'] == latTopLeft
    assert ret['tileRows'][0][0]['lngTopLeft'] == lngTopLeft

    _mongo_mock.CleanUp()
