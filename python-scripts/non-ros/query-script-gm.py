from neo4j import GraphDatabase
from datetime import datetime
import csv
import os
from CypherFile import append_nodes_edges_command_line, run_query_write_results, \
    create_output_folder, load_global_var
import sys
import shutil

# script json location
json_directory = "/tank/home/xyke/neo4jscripts/fileCypher/neo4jCypher/script-json/"
cypher_path="/tank/home/xyke/neo4jscripts/fileCypher/"

"""
# global variables 
# Neo4J Data
uri="bolt://localhost:7694"
username="neo4j"
password="test1234"

# Folder that contains script and Rex files
output_folder_path="/tank/home/xyke/gmOutput/"
fact_folder_path="/tank/home/xyke/split_again/"
main_folder_path="/tank/home/xyke/split_again/"
neo4j_path="/tank/home/xyke/n2-gm-controller/"
cypher_path="/tank/home/xyke/neo4jscripts/fileCypher/"
"""


if __name__=='__main__':

    # load default settings
    software_name = input("Enter the name of the software (json file name): ")
    neo4j_path, uri, username, password, fact_folder_path, _, output_folder_path, component_path \
        = load_global_var(json_directory + software_name + ".json")

    cypher_type = input("Enter cypher type: ")
    cypher_name = input("Enter cypher name: ")
    check_cfg = input("Do you want to perform CFG check? (y/n) ") == "y"
    multiple = input("Are there multiple paths? (y/n) ") == "y"

    check_cfg = "cfg" if (check_cfg) else "ncfg"

    """
    cmd_args = sys.argv

    if (len(cmd_args) < 4):
        print("[{}] Unable to run script due to missing arguments".format(datetime.now()))
        print("\tCall python script with command line arguments in the following order: ")
        print("\tcypher_type (folder name), check_cfg (boolean), cypher_name (cypher file name)")
        exit(0)
    
    # get command line arguments
    cypher_type = cmd_args[1]
    check_cfg = "cfg" if (cmd_args[2] == "true") else "ncfg"
    cypher_name = cmd_args[3]
    """

    # construct input cypher file path
    ros_cypher_file = "{}{}/{}/{}/{}.cypher".format(cypher_path, cypher_type, cypher_name, 
                                                    check_cfg, cypher_name)
    actual_folder, _ = create_output_folder(check_cfg, cypher_name, output_folder_path)

    cmd_log_file = open(actual_folder + "/cmd.log", "a")
    query_log_file = open(actual_folder + "/query.log", "a")
    actual_output_file = open(actual_folder + "/path.txt","a")

    print("[{}] Start appending Facts".format(datetime.now()), file=query_log_file)
    fact_time = datetime.now()
    total_time = fact_time

    append_nodes_edges_command_line("allNodes.csv", "reEdges.csv", cmd_log_file, neo4j_path, 
        fact_folder_path)
    
    fact_time = ((datetime.now() - fact_time).total_seconds() - 60)*1000
    print("[{}] Finished appending Facts {:f}".format(datetime.now(), fact_time), 
            file=query_log_file)
    print(file=query_log_file)
    
    # create neo4j session values
    driver = GraphDatabase.driver(uri, auth=(username, password), max_connection_lifetime=-1)
    session = driver.session()

    #run_query_write_results(session, ros_cypher_file, actual_output_file, None, 
    #                                           check_cfg + "/" + cypher_name , query_log_file)

    try:
        run_query_write_results(session, ros_cypher_file, actual_output_file, None, 
                                               check_cfg + "/" + cypher_name , query_log_file,
                                               "", multiple)
    except:
        print("[{}] Something went wrong when running the query.".format(datetime.now()), 
        file=query_log_file)

    total_time = ((datetime.now() - total_time).total_seconds() - 60)*1000
    print("[{}] Total fact + query time: {:f}".format(datetime.now(), total_time), 
            file=query_log_file)
    print(file=query_log_file)
    print("[{}] Total fact + query time: {:f}".format(datetime.now(), total_time))
    print()

    # close driver and session
    session.close()
    driver.close()

    # close related files
    cmd_log_file.close()
    query_log_file.close()
    actual_output_file.close()
    query_log_file.close()
    
    

