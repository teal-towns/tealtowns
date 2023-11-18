We ingest (2D) city data (buildings, streets, plants, etc.) from various sources then convert that to 3D models in Unreal.
We then ALTER the 3D models per project, since we (re)design cities. The final 3D models are a combination of the current state plus edits.
3D model data is: 1. position, 2. rotation, 3. scale, 4. 3D model mesh (rules or reference) and associated metadata to generate the textured 3D model in the correct location.

Data flows through 3 states:
1. input data from a variety of sources and formats, which is then converted and saved to:
2. vector tiles (at about 1 meter per pixel resolution) in meters with (0,0) being the top left (northwest) of the tile and positions being meters from the top left. Vector tiles are inputs to:
3. project data which is also meters but relative to a project center (0,0). As Unreal uses centimeters there is also a final conversion from meters to centimeters, but this happens in Unreal only and should be abstracted out to the last step; all code other than this final step should work in meters.

## Data sources

- Mapbox
  - Satellite (raster images) tiles for trees and green spaces
  - Streets (vector) tiles for roads and building polygon outlines
- `landTilePolygon` Our own vector tiles (points, paths and polygons) that are a combination of other data sources.
  - These store a lngLat from the top left (northwest) and then positions (`vertices`, `posCenter`) are meters from the top left.
  - Each tile stores the x (longitude, west-east) and y (latitude, north-south) meters, which vary by tile as the globe is an ellipsoid.
    - https://docs.mapbox.com/help/glossary/zoom-level/
    - Thus (for small distances, e.g. adjacent tiles), simple addition and subtraction math can be done to convert to and from a project center lngLat (0,0) to the tile top left lngLat (0,0).

## Project data

- We focus on local community projects so each project is no more than 10 x 10 kilometers (usually 5x5 or 2.5x2.5 or less). Thus we do not need to load the whole world at once or navigate around it beyond choosing a project location. Project data is thus stored relative to the project center (latitude and longitude we set to 0,0,0 in x,y,z). Units are all meters (which are later converted to Unreal's centimeter units).
- Each project takes the current state (3D models) then progressively adds and removes to get to the final project state.

We have 2 high level large tasks:
1. Build vector tiles (2D info plus data to generate or link to 3D models) which are points, lines and polygons aggregated from multiple data sources (Mapbox, Google, etc.) and leveraging machine learning, etc. to extract the data.
2. Build 3D models from vector tiles. For example, given a polygon for a building outline and meta data, generate a building. Or given 2D image(s), generate a 3D model. While some may be finding and creating a 3D model library (e.g. 1 tree model per species), we must be able to dynamically generate 3D models from data and 2D images, as many models (e.g. all buildings) will be unique and we will not be able to manually build and store infinite variations of 3D models.

### PairsString

This stores custom data for a point, path or polygon in key value string format, e.g. mesh=buildingBackOfHouse&rot=0.0000,0.0000,300&scale=0.31,0.31,0.31.
This can store any data to help construct and display a 3D model (or set of them). One of: `mesh`, `meshes` or `meshRule` is required. Common fields are:
- mat=green
- mesh=buildingBackOfHouse
- meshes=brackenFern,solidFern,cinnamonFern
- meshRule=cord
- placeOffsetAverage=0.3
- placeScaleMin=0.3
- placeScaleMax=0.75
- rot=0.0000,0.0000,300
- scale=0.31,0.31,0.31
meshRule usually will have additional custom options as well, which vary by meshRule. Certain `type` and `shape` combinations may also have custom options.

### Coordinate System

Use Unreal XYZ coordinate system so assume positive X is forward (front, east), positive Y is right (south). Z is up (altitude). -X is west, -Y is north.
