from neo4j import GraphDatabase
from datetime import datetime
import csv
import os
from CypherFile import append_nodes_edges_command_line, run_query_write_results, \
    create_output_folder, load_global_var, stop_neo4j
import sys
import shutil

# script json location
json_directory = "/tank/home/xyke/neo4jscripts/fileCypher/neo4jCypher/script-json/"
cypher_path="/tank/home/xyke/neo4jscripts/fileCypher/"

"""
# global variables 
# Neo4J Data
uri="bolt://localhost:7689"
username="neo4j"
password="test1234"

# Folder that contains script and Rex files
output_folder_path="/tank/home/xyke/autoOutput/"
fact_folder_path="/tank/home/xyke/neo4jscripts/autonomoose/facts_0721/"
main_folder_path="/tank/home/xyke/neo4jscripts/autonomoose/"
neo4j_path="/tank/home/xyke/n-autonomoose/"
cypher_path="/tank/home/xyke/neo4jscripts/fileCypher/"
"""



if __name__=='__main__':

    # load default settings
    software_name = input("Enter the name of the software (json file name): ")
    try:
        neo4j_path, uri, username, password, fact_folder_path, _, output_folder_path, component_path \
            = load_global_var(json_directory + software_name + ".json")
    except:
        print("Unable to find software json file. Please try running the script again.")
        exit(0)

    cypher_type = input("Enter cypher type: ")
    cypher_name = input("Enter cypher name: ")
    check_cfg = input("Do you want to perform CFG check? (y/n) ") == "y"
    multiple = input("Are there multiple paths? (y/n) ") == "y"
    unique = input("Unique path (y/n)") == "y"

    check_cfg = "cfg" if (check_cfg) else "ncfg"

    # construct input cypher file path
    ros_cypher_file = "{}{}/{}/{}/{}.cypher".format(cypher_path, cypher_type, cypher_name, 
                                                    check_cfg, cypher_name)
    
    if (not os.path.exists(ros_cypher_file)):
        print("Input query file does not exists. Please recheck \
              your user inputs")
        exit(0)

    actual_folder, _ = create_output_folder(check_cfg=check_cfg, cypher_name=cypher_name, 
                output_folder_path=output_folder_path, classification=cypher_type, is_remove=True)

    cmd_log_file = open(actual_folder + "/cmd.log", "a")
    query_log_file = open(actual_folder + "/query.log", "a")
    actual_output_file = open(actual_folder + "/path.txt","a")

    print("[{}] Start appending Facts".format(datetime.now()), file=query_log_file)

    fact_time = datetime.now()
    total_time = fact_time

    append_nodes_edges_command_line(check_cfg + "/allNodes.csv", check_cfg + "/edges.csv", 
                                    cmd_log_file, neo4j_path, fact_folder_path)
    
    fact_time = ((datetime.now() - fact_time).total_seconds() - 60)*1000
    print("[{}] Finished appending Facts {:f}".format(datetime.now(), fact_time), 
            file=query_log_file)
    
    # create neo4j session values
    driver = GraphDatabase.driver(uri, auth=(username, password), max_connection_lifetime=-1)
    session = driver.session()

    #run_query_write_results(session, ros_cypher_file, actual_output_file, None, 
    #                                           check_cfg + "/" + cypher_name , query_log_file,
    #                                           "", multiple)

    run_query_write_results(session=session, cypher_file_path=ros_cypher_file, 
            path_file=actual_output_file, summary_name=None, 
            query_name=check_cfg + "/" + cypher_name, query_file=query_log_file,
            multiple=multiple)
    #try:
    #    
    #except:
    #    print("[{}] Something went wrong when running the query.".format(datetime.now()), 
    #    file=query_log_file)

    total_time = ((datetime.now() - total_time).total_seconds() - 60)*1000
    print("[{}] Total fact + query time: {:f}".format(datetime.now(), total_time), 
            file=query_log_file)
    print(file=query_log_file)
    print("[{}] Total fact + query time: {:f}".format(datetime.now(), total_time))
    print()

    # close driver and session
    session.close()
    driver.close()

    stop_neo4j(neo4j_path=neo4j_path, cmd_log_file=cmd_log_file)

    # close related files
    cmd_log_file.close()
    query_log_file.close()
    actual_output_file.close()
    query_log_file.close()
    
    

