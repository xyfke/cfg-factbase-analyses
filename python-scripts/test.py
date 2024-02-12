import os

project_folder = os.path.dirname(os.path.realpath(__file__))
json_directory = os.path.realpath(project_folder + "/script-json/") + "/"
cypher_path = os.path.realpath(project_folder + "/../cypher-files/") + "/"

print(project_folder)
print(json_directory)
print(cypher_path)