from common import location as _location

def test_LngLatToAddress():
    ret = _location.LngLatToAddress(-122.03378, 37.97317)
    print ('ret', ret)
