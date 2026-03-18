import json
import jsonpickle
from json import JSONEncoder
def read_json_file(file_path):
    """
    Reads a JSON file from a given path.

    Args:
        file_path (str): The path to the JSON file.

    Returns:
        dict: A dictionary representation of the JSON data.
    """

    try:
        with open(file_path, 'r') as file:
            # Read the file content
            json_data = file.read()
            
            # Load the JSON data from the string
            data = json.loads(json_data)
            
            return data
    
    except FileNotFoundError:
        print(f"File not found at path: {file_path}")
        return None
    
    except json.JSONDecodeError as e:
        print(f"Failed to parse JSON: {e}")
        return None

def write_json_file(file_path, data):
    """
    Writes data to a JSON file.

    Args:
        file_path (str): The path where the JSON file will be saved.
        data (dict or list): The data to be written to the JSON file.
    """

    try:
        # Open the file in write mode (`'w'`)
        with open(file_path, 'w') as file:
            # Convert the data to a string and write it to the file
            json_data = None
            if data is Point:
                json_data = json.dumps(data, indent=4, cls=Point)
            elif data is District:
                json_data = json.dumps(data, indent=4, cls=District)
            else:
                json_data = jsonpickle.encode(data, indent=4)
            # Write the JSON data to the file
            file.write(json_data)
        
        print(f"Data written to JSON file: {file_path}")
    
    except Exception as e:
        print(f"Error writing JSON data: {e}")

# it is partly broken
def in_polygon(x, y, polygon):
    """
    Checks if a point (x, y) is inside a given polygon.

    Args:
        x (float): The x-coordinate of the point.
        y (float): The y-coordinate of the point.
        polygon (list of tuples): A list of tuples representing the vertices of the polygon.

    Returns:
        bool: True if the point is inside the polygon, False otherwise.
    """

    num_vertices = len(polygon)
    p1 = polygon[0]
    inside = False
    for i in range(1, num_vertices):
        p2 = polygon[i % num_vertices]
        
        if y > min(p1.y, p2.y):
            if y <= max(p1.y, p2.y):
                if x <= max(p1.x, p2.x):
                    x_intersection = ((y - p1.y) * (p2.x - p1.x)) / (p2.y - p1.y) + p1.x
                    
                    if p1.x == p2.x or x <= x_intersection:
                        inside = not inside
        p1 = p2
    return inside

fast_travel_points = read_json_file('AIRecordVoice/fasttravelmarkref.json')
districts = read_json_file('AIRecordVoice/districts/districts.json')

class District:
    def __init__(self, name, subdistricts, enum_name, polygon, fast_travel_points):
        self.name = name
        self.subdistricts = subdistricts
        self.enum_name = enum_name
        self.polygon = polygon
        self.fast_travel_points = fast_travel_points
    def toJson(self):
        return json.dumps(self, default=lambda o: o.__dict__)

class Point:
    def __init__(self, x, y, z, markerref, name):
        self.x = x
        self.y = y
        self.z = z
        self.markerref = markerref
        self.name = name

    def toJson(self):
        return json.dumps(self, default=lambda o: o.__dict__)

def to_point(p):
    point = Point(p['x'], p['y'], None, None, None)
    return point

districts_conv = []
for district in districts:
    d = District(district['Name'], district['SubDistrict'], district['EnumName'], list(map(lambda p: to_point(p), district['Polygon'])), [])    
    districts_conv.append(d)

for fast_travel in fast_travel_points:    
    if not 'x' in fast_travel or not 'y' in fast_travel:
        continue
    for district in districts_conv:
        if in_polygon(fast_travel['x'], fast_travel['y'], district.polygon):
            fast_travel_point = Point(fast_travel['x'], fast_travel['y'], fast_travel['z'], fast_travel['markerref'], fast_travel['name'])
            district.fast_travel_points.append(fast_travel_point)

for district in districts_conv:
    print(str(district.name) + '-----------------------')
    write_json_file(str(district.name)+'.json',  district.fast_travel_points)
    print("\n".join(map(lambda tp: tp.name, district.fast_travel_points)))