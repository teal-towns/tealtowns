import csv

import mongo_db

def ImportToDB(csvPath: str = './neighborhood/certification_levels.csv'):
    certificationLevels = []
    headerMap = {
        'uName': 'uName',
        'order': 'order',
        'category': 'category',
        'scale': 'scale',
        '1 point': 'point1',
        '2 points': 'point2',
        '3 points': 'point3',
        '4 points': 'point4',
        '5 points': 'point5',
        '6 points': 'point6',
    }
    headerIndices = {}
    with open(csvPath, newline='') as csvfile:
        reader = csv.reader(csvfile, delimiter=',')
        for index, row in enumerate(reader):
            if index == 2:
                for indexCol, col in enumerate(row):
                    if col in headerMap:
                        headerIndices[headerMap[col]] = indexCol
                print ('headerIndices', headerIndices)
            elif index >= 3:
                certificationLevel = {
                    'scorings': [],
                }
                rowLen = len(row)
                for field in headerIndices:
                    index = headerIndices[field]
                    if index < rowLen:
                        value = row[index].strip()
                        if len(value) > 0:
                            if value[-1] == '.':
                                value = value[:-1]
                            if 'point' in field and len(value) > 0:
                                certificationLevel['scorings'].append(value)
                            else:
                                if field == 'order':
                                    value = int(value)
                                else:
                                    value = value[0].lower() + value[1:]
                                certificationLevel[field] = value
                certificationLevels.append(certificationLevel)
    print ('certificationLevels', len(certificationLevels))
    mongo_db.insert_many('certificationLevel', certificationLevels)
