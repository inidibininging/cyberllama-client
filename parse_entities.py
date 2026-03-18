import json

def read_json_file(file_path):
    try:
        with open(file_path, 'r') as file:
            json_data = file.read()
            data = json.loads(json_data)
            return data
    
    except FileNotFoundError:
        print(f"File not found at path: {file_path}")
        return None
    
    except json.JSONDecodeError as e:
        print(f"Failed to parse JSON: {e}")
        return None

def write_json_file(file_path, data):
    try:
        with open(file_path, 'w') as file:
            json_data = json.dumps(data, indent=4)
            file.write(json_data)
        
        print(f"Data written to JSON file: {file_path}")
    
    except Exception as e:
        print(f"Error writing JSON data: {e}")


# Example usage
file_path = "./entitieshash_json.json"
data = read_json_file(file_path)

scavenger = []
animal = []
voodoo = []
sixthstreet = []
valentino = []
aldecaldo = []
wraith = []
tyger = []
cyberpunk = []
mox = []
maelstrom = []
arasaka = []
militech = []
generic = []
kangtao = []
max_tac = []
zetatech = []

if data is not None:
    # Do something with the loaded data
    for e in data:
        entity = data[e]
        entity_name = entity['entity_entname']
        entity_path = entity['entity_entpath']
        # if 'gang__ep1' in entity_name:
        #     if 'scavenger' in entity_name:                
        #         scavenger.append(entity)
        #     elif 'animal' in entity_name:
        #         animal.append(entity)
        #     elif 'voodoo' in entity_name:
        #         voodoo.append(entity)
        #     elif 'valentino' in entity_name:
        #         valentino.append(entity)
        #     elif '6thstreet' in entity_name:
        #         sixthstreet.append(entity)
        #     elif 'aldecaldo' in entity_name:
        #         aldecaldo.append(entity)
        #     elif 'wraith' in entity_name:
        #         wraith.append(entity)
        #     elif 'tyger' in entity_name:
        #         tyger.append(entity)
        #     elif 'cyberpunk' in entity_name:
        #         cyberpunk.append(entity)
        #     elif 'mox' in entity_name:
        #         mox.append(entity)
        #     elif 'maelstrom' in entity_name:
        #         maelstrom.append(entity)
            
        # if 'corpo__ep1' in entity_name or\
        #     'android' in entity_path or\
        #     'android' in entity_name:
            # elif 'generic' in entity_name:
            #     generic.append(entity)
        if not 'vehicles' in entity_path:
            if 'arasaka' in entity_name or\
                'arasaka' in entity_path:
                arasaka.append(entity)
            elif 'militech' in entity_name or\
                'militech' in entity_path:
                militech.append(entity)
            elif 'kangtao' in entity_name or\
                'kangtao' in entity_path:
                kangtao.append(entity)
            elif 'max_tac' in entity_name or\
                'max_tac' in entity_path:
                max_tac.append(entity)
            elif 'zetatech' in entity_name or\
                'zetatech' in entity_path:
                zetatech.append(entity)
            

# write_json_file('scavenger.json', scavenger)
# write_json_file('animal.json', animal)
# write_json_file('voodoo.json', voodoo)
# write_json_file('sixthstreet.json', sixthstreet)
# write_json_file('valentino.json', valentino)
# write_json_file('aldecaldo.json', aldecaldo)
# write_json_file('wraith.json', wraith)
# write_json_file('tyger.json', tyger)
# write_json_file('cyberpunk.json', cyberpunk)
# write_json_file('mox.json', mox)
# write_json_file('maelstrom.json', maelstrom)
# write_json_file('generic.json', generic)
write_json_file('./factions/arasaka.json', arasaka)
write_json_file('./factions/militech.json', militech)
write_json_file('./factions/kangtao.json', kangtao)
write_json_file('./factions/max_tac.json', max_tac)
write_json_file('./factions/zetatech.json', zetatech)