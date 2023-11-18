def VertexToString(vertex: list, precision: int = 4):
    return str(round(vertex[0], precision)) + ',' + \
        str(round(vertex[1], precision)) + ',' + str(round(vertex[2], precision))

def StringToVertex(vertexString: str):
    vertex = vertexString.split(',')
    return [float(vertex[0]), float(vertex[1]), float(vertex[2])]

def VerticesToStrings(vertices: list):
    return [VertexToString(vertex) for vertex in vertices]

def StringsToVertices(verticesStrings: list):
    return [StringToVertex(vertexString) for vertexString in verticesStrings]
