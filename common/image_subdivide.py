import copy
import cv2
import math
import numpy

import log
from common import math_polygon as _math_polygon
from common import mapbox_polygon as _mapbox_polygon

def NonForestLngLatsByImage(parcelLngLats, zoom = None, thresholdValue = None, thresholdType = 0,
    minAreaMeters = None, maxMetersPerPixel = None, maxTiles = None):
    minAreaMeters = minAreaMeters if minAreaMeters is not None else 1000
    ret = { 'valid': 1, 'polygonsLngLatsNonForest': [], 'countSkippedArea': 0, 'nonForestPercent': 0,
        'nonForestHectares': 0, 'bounds': {} }
    boundsLngLat = _math_polygon.MinMaxBounds(parcelLngLats)['bounds']
    ret['bounds'] = boundsLngLat
    retTiles = _mapbox_polygon.GetImageTiles(boundsLngLat, zoom = zoom,
        maxMetersPerPixel = maxMetersPerPixel, maxTiles = maxTiles)
    metersPerPixel = retTiles['metersPerPixel']
    lngLatTopLeft = retTiles['lngLatTopLeft']
    img = retTiles['img']
    ret['metersPerPixel'] = metersPerPixel
    ret['zoom'] = retTiles['zoom']
    ret['totalTiles'] = retTiles['totalTiles']

    polygonPixels = LngLatsToPixels(parcelLngLats, lngLatTopLeft, metersPerPixel)
    log.log('info', 'image_subdivide.NonForestLngLatsByImage got polygonPixels', len(polygonPixels))
    img = MaskPolygon(img, polygonPixels)

    retPolygons = NonForestPointsFromImage(None, thresholdValue = thresholdValue,
        thresholdType = thresholdType, img = img, imgIsGray = 1)
    # Contours to lngLat
    nonForestArea = 0.0
    for index, polygon in enumerate(retPolygons['polygons']):
        polygonLngLat = []
        for point in polygon:
            offsetEastMeters = point[0][0] * metersPerPixel
            offsetSouthMeters = point[0][1] * metersPerPixel
            retLngLat = _math_polygon.TranslateMetersToLngLat(offsetEastMeters, offsetSouthMeters, lngLatTopLeft[0], lngLatTopLeft[1])
            polygonLngLat.append([retLngLat['lng'], retLngLat['lat']])
        area = _math_polygon.PolygonAreaLngLat(polygonLngLat)
        if (area > minAreaMeters):
            ret['polygonsLngLatsNonForest'].append(polygonLngLat)
            nonForestArea += area
        else:
            ret['countSkippedArea'] += 1

    area = _math_polygon.PolygonAreaLngLat(parcelLngLats)
    ret['nonForestHectares'] = float(nonForestArea / 10000)
    ret['nonForestPercent'] = nonForestArea / area * 100

    return ret

def MaskPolygon(image, polygonPixels, grayscale = 1):
    img = copy.deepcopy(image)
    # TODO - figure out how to keep color version; getting error.
    if grayscale:
        img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # Re shape for expected contours format.
    contours = None
    for index, point in enumerate(polygonPixels):
        if index == 0:
            contours = numpy.array([point])
        else:
            contours = numpy.concatenate((contours, numpy.array([point])))
    contours = numpy.array([contours])
    imgMask = numpy.zeros(img.shape, dtype='uint8')
    cv2.drawContours(imgMask, contours, -1, (255,255,255), -1)
    # cv2.imwrite('./uploads/nonForest-mask.png', imgMask)
    # if convertToGrayscale:
    _, mask = cv2.threshold(imgMask, 100, 255, 0)
    # else:
    #     mask = imgMask
    img = cv2.bitwise_and(img, img, mask = mask)
    # cv2.imwrite('./uploads/nonForest-parcelMask.png', img)
    return img

# Uses openCV image operations to threshold non forest (color) then draw contours (polygons).
# https://docs.opencv.org/4.x/db/d8e/tutorial_threshold.html
def NonForestPointsFromImage(filePath, thresholdValue = None, thresholdType = 0, img = None,
    imgIsGray = 0):
    thresholdValue = thresholdValue if thresholdValue is not None else 75
    maxBinaryValue = 255
    ret = { 'valid': 1, 'polygons': [] }

    if img is None:
        img = cv2.imread(filePath)
    if imgIsGray:
        imgGray = img
    else:
        imgGray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    # cv2.imwrite('./uploads/nonForest.png', imgGray)

    # Blur image to remove noise.
    # https://docs.opencv.org/4.x/d4/d13/tutorial_py_filtering.html
    imgGray = BlurImage(imgGray, kernal = 10)
    # cv2.imwrite('./uploads/nonForest-blur.png', imgGray)

    _, imgThreshold = cv2.threshold(imgGray, thresholdValue, maxBinaryValue, thresholdType)
    # cv2.imwrite('./uploads/nonForest-threshold.png', imgThreshold)

    contours, hierarchy = cv2.findContours(imgThreshold, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    cv2.drawContours(imgThreshold, contours, -1, (255,255,255), 1)
    # cv2.imwrite('./uploads/nonForest-contour.png', imgThreshold)

    ret['polygons'] = contours

    return ret

def BlurImage(img, kernal = 5):
    return cv2.blur(img, (kernal,kernal))

def LngLatsToPixels(polygonLngLats, lngLatOrigin, metersPerPixel):
    polygonPixels = []
    for lngLat in polygonLngLats:
        retOffset = _math_polygon.LngLatOffsetMeters(lngLat, lngLatOrigin)
        pixelX = math.floor(retOffset['offsetEastMeters'] / metersPerPixel)
        pixelY = math.floor(retOffset['offsetSouthMeters'] / metersPerPixel)
        polygonPixels.append([pixelX, pixelY])
    return polygonPixels
