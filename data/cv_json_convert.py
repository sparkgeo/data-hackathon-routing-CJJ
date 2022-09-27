import csv, json
from re import L
from geojson import Feature, FeatureCollection, Point

#Latitude	Longitude	Location	Municipality	Crash Type	Year	Crash Count
features = []
with open('/Users/cpapalaz/hackathon_pgrouting/data-hackathon-routing-CJJ/data/LowerMainlandCrashes_FullData_data.csv', newline='') as csvfile:
    reader = csv.reader(csvfile, delimiter='\t')
    next(reader, None) 
    for Latitude, Longitude, Location, Municipality, Type, Year, Count in reader:
        print(Latitude, Longitude)
        Latitude, Longitude = map(float, (Latitude, Longitude))
        features.append(
            Feature(
                geometry = Point((Longitude, Latitude)),
                properties = {
                    'Location': Location,
                    'Municipality': Municipality,
                    'Type': Type,
                    'Year': Year,
                    'Count': Count
                }
            )
        )

collection = FeatureCollection(features)
with open("crash_data.json", "w") as f:
    f.write('%s' % collection)