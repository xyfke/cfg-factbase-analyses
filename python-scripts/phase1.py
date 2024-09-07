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
    check_line = input("Are there check line queries? ") == "y"
    phase_n = "1"
    summary_fact_type = input("Enter type for summary fact(default = dataflow): ")

    if (summary_fact_type == ""):
        summary_fact_type = "dataflow"

    # Create output cfg and ncfg directories
    output_cfg_path, _ = create_output_folder(check_cfg="cfg", cypher_name=cypher_name, 
                            output_folder_path=output_folder_path, classification=cypher_type,
                            phase_n=phase_n, is_remove=True)
    output_lcfg_path, _ = create_output_folder(check_cfg="lcfg", 
                                        cypher_name=cypher_name,
                                        output_folder_path=output_folder_path, 
                                        classification=cypher_type, phase_n=phase_n)
    output_ncfg_path, general_path = create_output_folder(check_cfg="ncfg", 
                                        cypher_name=cypher_name,
                                        output_folder_path=output_folder_path, 
                                        classification=cypher_type, phase_n=phase_n)


    input_cfg_path = "{}{}/{}/{}/{}".format(cypher_path, cypher_type, cypher_name, "cfg", cypher_name)
    input_lcfg_path = "{}{}/{}/{}/{}".format(cypher_path, cypher_type, cypher_name, "lcfg", cypher_name)
    input_ncfg_path = "{}{}/{}/{}/{}".format(cypher_path, cypher_type, cypher_name, "ncfg", cypher_name)

    # Check if all files exists 
    if not (os.path.exists(input_cfg_path + "-interm.cypher") \
        and os.path.exists(input_ncfg_path + "-interm.cypher") \
        and os.path.exists(input_lcfg_path + "-interm.cypher")):
        print("Interm query file does not exists. Please recheck your user inputs")
        exit(0)

    if (run_prefix_suffix):
        if not (os.path.exists(input_cfg_path + "-prefix.cypher") \
            and os.path.exists(input_ncfg_path + "-prefix.cypher") \
            and os.path.exists(input_cfg_path + "-suffix.cypher") \
            and os.path.exists(input_ncfg_path + "-suffix.cypher")):
            print("Prefix or suffix query files does not exists. Please recheck your user inputs")
            exit(0)
    
    if (check_line and run_prefix_suffix):
        if not (os.path.exists(input_lcfg_path + "-prefix.cypher") \
            and os.path.exists(input_lcfg_path + "-suffix.cypher")):
            print("Prefix or suffix query files does not exists. Please recheck your user inputs")
            exit(0)

    query_log = open(general_path + "query.log", "a")
    cmd_log = open(general_path + "cmd.log", "a")

    # get components
    components = extract_component(component_csv_path=component_path, query_file=query_log)
    print(file=query_log)
    print(file=query_log)

    # Intermediate Dataflow (CFG)
    interm_file_cfg = open(output_cfg_path + "dataflow_cfg_edges.csv", "a")
    interm_file_cfg_writer = csv.writer(interm_file_cfg, delimiter="\t")
    interm_file_cfg_writer.writerow([":START_ID", ":END_ID", ":TYPE", "compName"])

    # Intermediate Dataflow (CFG-line)
    interm_file_lcfg = open(output_lcfg_path + "dataflow_lcfg_edges.csv", "a")
    interm_file_lcfg_writer = csv.writer(interm_file_lcfg, delimiter="\t")
    interm_file_lcfg_writer.writerow([":START_ID", ":END_ID", ":TYPE", "compName"])

    # Intermediate Dataflow (NCFG)
    interm_file_ncfg = open(output_ncfg_path + "dataflow_ncfg_edges.csv", "a")
    interm_file_ncfg_writer = csv.writer(interm_file_ncfg, delimiter="\t")
    interm_file_ncfg_writer.writerow([":START_ID", ":END_ID", ":TYPE", "compName"])

    # Subquery file output
    if (run_prefix_suffix):
        suffix_cfg_file = open(output_cfg_path + "suffix_cfg.txt", "a")
        prefix_cfg_file = open(output_cfg_path + "prefix_cfg.txt", "a")
        suffix_ncfg_file = open(output_ncfg_path + "suffix_ncfg.txt", "a")
        prefix_ncfg_file = open(output_ncfg_path + "prefix_ncfg.txt", "a")
        if (check_line):
            suffix_lcfg_file = open(output_lcfg_path + "suffix_lcfg.txt", "a")
            prefix_lcfg_file = open(output_lcfg_path + "prefix_lcfg.txt", "a")

    else:
        suffix_cfg_file = None
        prefix_cfg_file = None
        suffix_ncfg_file = None
        prefix_ncfg_file = None
        if (check_line):
            suffix_lcfg_file = None
            prefix_lcfg_file = None

    df_cfg_file = open(output_cfg_path + "df_cfg.txt", "a")
    df_ncfg_file = open(output_ncfg_path + "df_cfg.txt", "a")

    if (check_line):
        df_lcfg_file = open(output_lcfg_path + "df_lcfg.txt", "a")

    # timing file
    time_file = open(general_path + "timeQuery.csv", "a")
    time_file_writer=csv.writer(time_file, delimiter=",")

    if (check_line):
        time_file_writer.writerow(["Component", "fact-ncfg-time", "fact-cfg-time",
                                "ncfg", "ncfg-size", "cfg-otf", "cfg-otf-size", 
                                "lcfg-otf", "lcfg-otf-size",
                                "prefixNCFG", "prefixNCFG-size", "prefixCFG", "prefixCFG-size",
                                "prefixLCFG", "prefixLCFG-size",  
                                "suffixNCFG", "suffixNCFG-size", "suffixCFG", "suffixCFG-size","suffixLCFG", "suffixLCFG-size"])
    else:
        time_file_writer.writerow(["Component", "fact-ncfg-time", "fact-cfg-time",
                                "ncfg", "ncfg-size", "cfg-otf", "cfg-otf-size", 
                                "prefixNCFG", "prefixNCFG-size", "prefixCFG", "prefixCFG-size", 
                                "suffixNCFG", "suffixNCFG-size", "suffixCFG", "suffixCFG-size"])
    
    
    sys.stdout.flush()

    for [k, v] in components.items():
        print("Component: {0}".format(k), file=query_log)
        
        # Run CFG query
        fact_cfg_time, prefix_cfg_time, prefix_cfg_size, suffix_cfg_time, \
        suffix_cfg_size, interm_cfg_time, interm_cfg_size = run_analyses(node_file=v[0], 
                edge_file=v[1], neo4j_path=neo4j_path, cypher_folder=input_cfg_path,
                prefix_file=prefix_cfg_file, suffix_file=suffix_cfg_file, 
                interm_file=df_cfg_file,cmd_log=cmd_log, query_log=query_log, 
                check_cfg="cfg", fact_folder_path=fact_folder_path, comp_name=k, 
                df_csv=interm_file_cfg_writer,summary_type=summary_fact_type)
        
        print(file=query_log)

        # Run CFG query
        if (check_line):
            fact_lcfg_time, prefix_lcfg_time, prefix_lcfg_size, suffix_lcfg_time, \
            suffix_lcfg_size, interm_lcfg_time, interm_lcfg_size = run_analyses(node_file=v[0], 
                    edge_file=v[1], neo4j_path=neo4j_path, cypher_folder=input_lcfg_path,
                    prefix_file=prefix_lcfg_file, suffix_file=suffix_lcfg_file, 
                    interm_file=df_lcfg_file,cmd_log=cmd_log, query_log=query_log, 
                    check_cfg="lcfg", fact_folder_path=fact_folder_path, comp_name=k, 
                    df_csv=interm_file_lcfg_writer,summary_type=summary_fact_type)
            print(file=query_log)
        

        # Run NCFG query
        fact_ncfg_time, prefix_ncfg_time, prefix_ncfg_size, suffix_ncfg_time, \
        suffix_ncfg_size, interm_ncfg_time, interm_ncfg_size = run_analyses(node_file=v[2], 
                edge_file=v[3], neo4j_path=neo4j_path, cypher_folder=input_ncfg_path,
                prefix_file=prefix_ncfg_file, suffix_file=suffix_ncfg_file, 
                interm_file=df_ncfg_file,cmd_log=cmd_log, query_log=query_log, 
                check_cfg="ncfg", fact_folder_path=fact_folder_path, comp_name=k, 
                df_csv=interm_file_ncfg_writer,summary_type=summary_fact_type)

        if (check_line):
            time_file_writer.writerow([k, fact_ncfg_time, fact_cfg_time,
                                    interm_ncfg_time, interm_ncfg_size,
                                    interm_cfg_time, interm_cfg_size, 
                                    interm_lcfg_time, interm_lcfg_size,
                                    prefix_ncfg_time, prefix_ncfg_size,
                                    prefix_cfg_time, prefix_cfg_size, 
                                    prefix_lcfg_time, prefix_lcfg_size, 
                                    suffix_ncfg_time, suffix_ncfg_size, 
                                    suffix_cfg_time, suffix_cfg_size,
                                    suffix_lcfg_time, suffix_lcfg_size])
        else:
            time_file_writer.writerow([k, fact_ncfg_time, fact_cfg_time,
                                    interm_ncfg_time, interm_ncfg_size,
                                    interm_cfg_time, interm_cfg_size, 
                                    prefix_ncfg_time, prefix_ncfg_size,
                                    prefix_cfg_time, prefix_cfg_size, 
                                    suffix_ncfg_time, suffix_ncfg_size, 
                                    suffix_cfg_time, suffix_cfg_size])
        
        print(file=query_log)
        print(file=query_log)
        

        sys.stdout.flush()
        
    stop_neo4j(neo4j_path=neo4j_path, cmd_log_file=cmd_log)

    # close all opened file
    # close log files
    cmd_log.close()
    query_log.close()
    time_file.close()

    # close path reporting files
    interm_file_cfg.close()
    interm_file_ncfg.close()
    if (check_line):
        interm_file_lcfg.close()

    if (run_prefix_suffix):
        prefix_cfg_file.close()
        prefix_ncfg_file.close()
        suffix_cfg_file.close()
        suffix_ncfg_file.close()

        if (check_line):
            prefix_lcfg_file.close()
            suffix_lcfg_file.close()



        
        
