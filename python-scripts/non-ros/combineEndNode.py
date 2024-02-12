from datetime import datetime
from CypherFile import create_output_folder, load_global_var
import sys

# script json location
json_directory = "/tank/home/xyke/neo4jscripts/fileCypher/neo4jCypher/script-json/"

if __name__=='__main__':    

    # load default settings
    software_name = input("Enter the name of the software (json file name): ")
    _, _, _, _, _, _, output_folder_path, _ \
        = load_global_var(json_directory + software_name + ".json")

    cypher_type = input("Enter cypher type: ")
    cypher_name = input("Enter cypher name: ")
    min_cross = input("Enter minimum components (default: zero or more): ")
    date = input("Enter date (default: today): ")

    if (date == ""):
        date = datetime.today().strftime('%m-%d')

    