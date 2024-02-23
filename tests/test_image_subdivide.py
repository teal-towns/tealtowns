import cv2

from common import image_subdivide as _image_subdivide

# def test_ImageColorsToPolygons():
#     imageUrl = './uploads/land-vision-orig.jpg'

#     ret = _image_subdivide.ImageColorsToPolygons(imageUrl)

def test_PixelsToLngLat():
    pixelOffsets = [ [179,  65], [9, 131], [197,  46], [183,  92],[238,  56] ]
    lngLat = [37.7749,  -122.4194]
    metersPerPixel = 1
    latLngLocs = _image_subdivide.PixelsToLngLats(pixelOffsets,lngLat, metersPerPixel)
    assert len(pixelOffsets) == len(latLngLocs)
