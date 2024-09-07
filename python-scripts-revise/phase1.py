from neo4j import GraphDatabase
from datetime import datetime
import csv
from CypherFile import append_nodes_edges_command_line, run_query_write_results, \
    create_output_folder, load_global_var, stop_neo4j
import sys
import os

# script json location
project_folder = os.path.dirname(os.path.realpath(__file__))
json_directory = os.path.realpath(project_folder + "/script-json/") + "/"
cypher_path = os.path.realpath(project_folder + "/../cypher-files/") + "/"

def extract_component(component_csv_path, query_file):
    """
    ------------------------------------------------------------------------
    Extract component names from csv file (summaryFile) to create partial 
    file paths for each component the variables nodeFile and edgeFile are 
    the partial file paths for the component
    ------------------------------------------------------------------------
    Parameters:
       component_csv_path -  absolute path of a csv file that lists all the 
                                components (string)
       query_file - log file that records query running information 
                    (file object) 
    Returns:
       components - dictionary of components with cfg and ncfg 
                    (dictionary of list of string)
    ------------------------------------------------------------------------
    """
    components = {}
    component_file = open(component_csv_path, "r", encoding='utf-8-sig')
    comp_reader = csv.DictReader(component_file)

    # Read csv file and extract component
    for line in comp_reader:
        component = line["components"]
        node_cfg_file = "cfg/nodes/" + component + "-nodes.csv"
        edge_cfg_file = "cfg/edges/" + component + "-edges.csv"
        node_ncfg_file = "ncfg/nodes/" + component + "-nodes.csv"
        edge_ncfg_file = "ncfg/edges/" + component + "-edges.csv"
        components[component] = [node_cfg_file, edge_cfg_file, node_ncfg_file, edge_ncfg_file]

    component_file.close()
    print("[{}] All components extracted: {}".format(datetime.now(), components.keys()), 
          file=query_file)
    return components

def run_analyses(node_file, edge_file, neo4j_path, fact_folder_path, cypher_folder,
                 prefix_file, suffix_file, interm_file,
                 cmd_log, query_log, check_cfg, comp_name, df_csv, summary_type):
    """
    ------------------------------------------------------------------------
    Append facts to neo4j and run query
    ------------------------------------------------------------------------
    Parameters:
       node_file - name of node file (string)
       edge_file - name of edge file (string)
       neo4j_path - folder path of neo4j instance (string)
       fact_folder_path - folder path of factbase (string)
       cypher_folder - path for ros cypher folder (string)
       prefix_file - output path for prefix subquery (string)
       suffix_file - output path for suffix subquery (string)
       interm_file - output path for interm subquery (string)
       cmd_log - log file to record command line output (file object)
       query_log - log file that records query running information 
                    (file object)
       check_cfg - whether or not query performs CFG validation (boolean)
       comp_name - the name of the component factbase that we are running the
                    query on (string)
       df_csv - csv file to record summary path between start and end node 
                (file object, default: None)
    Returns:
       components - dictionary of components with cfg and ncfg 
                    (dictionary of list of string)
    ------------------------------------------------------------------------
    """
    
    # Print to log
    print("[{}] Run {} queries:".format(datetime.now(), check_cfg), file=query_log)
    
    # Append facts to Neo4J graph database
    print("[{}] Start appending Facts".format(datetime.now()), file=query_log)
    fact_time = datetime.now()
    success = append_nodes_edges_command_line(node_file, edge_file, cmd_log, neo4j_path, fact_folder_path)
    fact_time = ((datetime.now() - fact_time).total_seconds() - 60)*1000
    print("[{}] Finished appending Facts {:f}".format(datetime.now(), fact_time), 
            file=query_log)
    
    if (not success):
        return -1, -1, -1, -1, -1, -1, -1
    
    # Establish database connection
    driver = GraphDatabase.driver(uri, auth=(username, password), max_connection_lifetime=-1)
    session = driver.session()

    print("Start running queries for component {}".format(k))

    # Run prefix and suffix subquery analyses (if present)
    prefix_time, prefix_size, suffix_time, suffix_size = 0, 0, 0, 0
    if (run_prefix_suffix):
        prefix_time, prefix_size = run_query_write_results(session=session, 
            cypher_file_path=cypher_folder + "-prefix.cypher", path_file=prefix_file,
            summary_name=None, query_name="prefix " + check_cfg, query_file=query_log)
        suffix_time, suffix_size = run_query_write_results(session=session, 
            cypher_file_path=cypher_folder + "-suffix.cypher", path_file=suffix_file,
            summary_name=None, query_name="suffix " + check_cfg, query_file=query_log)
        
    # Run interm subquery analyses
    interm_time, interm_size = run_query_write_results(session=session, 
            cypher_file_path=cypher_folder + "-interm.cypher", path_file=interm_file,
            summary_name=summary_type, query_name="interm " + check_cfg, query_file=query_log, 
            unique=True, comp_name=comp_name, df_csv=df_csv)
    
    print()
    
    return fact_time, prefix_time, prefix_size, suffix_time, suffix_size, interm_time, interm_size


if __name__=='__main__':

    # load default settings
    software_name = input("Enter the name of the software (json file name): ")
    try:
        neo4j_path, uri, username, password, fact_folder_path, _, output_folder_path, \
        component_path = load_global_var(json_directory + software_name + ".json")
    except:
        print("Unable to find software json file. Please try running the script again.")
        exit(0)

    # Get user input
    cypher_type = input("Enter cypher type: ")
    cypher_name = input("Enter cypher name: ")
    run_prefix_suffix = input("Are there prefix and suffix queries? (y/n) ") == "y"
    phase_n = "1"
    summary_fact_type = input("Enter type for summary fact(default = dataflow): ")

    if (summary_fact_type == ""):
        summary_fact_type = "dataflow"

    