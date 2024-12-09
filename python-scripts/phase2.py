from neo4j import GraphDatabase
from datetime import datetime
import csv
import os
from CypherFile import append_nodes_edges_command_line, run_query_write_results, \
    create_output_folder, load_global_var, stop_neo4j

# script json location
project_folder = os.path.dirname(os.path.realpath(__file__))
json_directory = os.path.realpath(project_folder + "/script-json/") + "/"
cypher_path = os.path.realpath(project_folder + "/../cypher-files/") + "/"

# global variables 
# Neo4J Data
"""
uri="bolt://localhost:7689"
username="neo4j"
password="test1234"

# Folder that contains script and Rex files
output_folder_path="/tank/home/xyke/autoOutput/"
input_folder_path="/tank/home/xyke/autoOutput/"
fact_folder_path="/tank/home/xyke/neo4jscripts/autonomoose/facts_0721/"
main_folder_path="/tank/home/xyke/neo4jscripts/autonomoose/"
neo4j_path="/tank/home/xyke/n-autonomoose/"
cypher_path="/tank/home/xyke/neo4jscripts/fileCypher/"
"""

def clearDataflowEdges(session):
    """
    ------------------------------------------------------------------------
    Clear all nodes and edges in the database to prepare for the next 
    component
    ------------------------------------------------------------------------
    Parameters:
       session - A Neo4J database session to run the query (neo4j.Session)
    Returns:
       None
    ------------------------------------------------------------------------
    """
    session.run("MATCH ()-[r:dataflow]->() DELETE r;")
    print("[{}] Cleared databse.".format(datetime.now()))


def createDFRelationship(session, df_reader, query_log):
    """
    ------------------------------------------------------------------------
    Add Dataflow relationships to Neo4J project with all the facts
    ------------------------------------------------------------------------
    Parameters:
       session - A Neo4J database session to run the query (neo4j.Session)
       df_csv - the csv reader describing all the dataflow summary facts (csv)
    Returns:
       None
    ------------------------------------------------------------------------
    """
    addedEdge = []
    for dfEdge in df_reader:
        key = dfEdge[":START_ID"] + dfEdge[":END_ID"] + dfEdge["compName"]
        if (key not in addedEdge):
            createStatement = """MATCH (from {{ id:"{0}" }}), (to {{ id:"{1}" }}) 
            CREATE (from)-[:{2} {{compName : "{3}"}}]->(to);""".format(dfEdge[":START_ID"], 
                                                                    dfEdge[":END_ID"], dfEdge[":TYPE"], 
                                                                    dfEdge["compName"])                  
            res = session.run(createStatement)
            res.consume()
            addedEdge.append(key)

    


def run_analyses(output_path, neo4j_path, fact_folder_path,
                 cmd_log, query_log, check_cfg, df_csv, cypher_path, min_interm,
                 is_ros, multiple):
    """
    ------------------------------------------------------------------------
    Run dataflow query and report results
    ------------------------------------------------------------------------
    Parameters:
       output_path - output path for query (string)
       neo4j_path - folder path of neo4j instance (string)
       fact_folder_path - folder path of factbase (string)
       cmd_log - log file to record command line output (file object)
       query_log - log file that records query running information 
                    (file object)
       check_cfg - whether or not query performs CFG validation (boolean)
       df_csv - csv file to record summary path between start and end node 
                (file object, default: None)
       cypher_path - path for ros cypher files (string)
       min_interm - the minimum number of component (string)
       is_ros - is this a ros program (boolean)
       multiple - is multiple path (boolean)
    Returns:
       None
    ------------------------------------------------------------------------
    """
    # Add factbase
    fact_time = datetime.now()
    if (is_ros):
        node_path = check_cfg + "/allNodes.csv"
        edge_path = check_cfg + "/edges.csv"
    else:
        node_path = check_cfg + "/allCompNodes.csv"
        edge_path = check_cfg + "/allCompEdges.csv"

    success = append_nodes_edges_command_line(node_path, edge_path,
                                    cmd_log, neo4j_path, 
                                    fact_folder_path)
    
    if (not success):
        return -1, -1
    
    # create neo4j session values
    driver = GraphDatabase.driver(uri, auth=(username, password), max_connection_lifetime=-1)
    session = driver.session()

    # create summary facts
    df_reader = csv.DictReader(df_csv, delimiter="\t")
    createDFRelationship(session, df_reader, query_log)

    fact_time = ((datetime.now() - fact_time).total_seconds()-60) * 1000
    print("[{}] Import fact time: {}ms".format(datetime.now(), fact_time))
    print("[{}] Import fact time: {}ms".format(datetime.now(), fact_time), file=query_log)

    # Run query
    df_time, df_size = run_query_write_results(session=session, 
        cypher_file_path=cypher_path + "-dataflow" + min_interm + ".cypher", 
        path_file=output_path, summary_name=None, 
        query_name="dataflow " + check_cfg, query_file=query_log, multiple=multiple)

    return df_time, df_size

if __name__=='__main__':

    # load default settings
    software_name = input("Enter the name of the software (json file name): ")
    try:
        neo4j_path, uri, username, password, fact_folder_path, _, output_folder_path, _ \
            = load_global_var(json_directory + software_name + ".json")
    except:
        print("Unable to find software json file. Please try running the script again.")
        exit(0)

    cypher_type = input("Enter cypher type: ")
    cypher_name = input("Enter cypher name: ")
    min_interm = input("Enter minimum intermediate components (default: zero or more): ")
    date = input("Enter date (default: today): ")
    multiple = input("Are there multiple paths? (y/n) ") == "y"
    check_line = input("Check line queries? (y/n) ") == "y"
    p_cfg = input("Check cfg? (y/n) ") == "y"
    p_ncfg = input("No cfg queries? (y/n) ") == "y"
    phase_n = input("Enter phase number: ")
    is_ros = input("Is this a ROS program? ") == "y"
    

    if (phase_n == ""):
        phase_n = 2

    phase_n = int(phase_n)

    if (date == ""):
        date = datetime.today().strftime('%m-%d')

    # Get output path
    if p_cfg:
        output_cfg_path, general_path = create_output_folder(check_cfg="cfg", cypher_name=cypher_name, 
                            output_folder_path=output_folder_path, phase_n=phase_n, is_remove=True,
                            date=date, min_interm=min_interm, classification=cypher_type)
    if check_line:
        output_lcfg_path, general_path = create_output_folder(check_cfg="lcfg", cypher_name=cypher_name, 
                                output_folder_path=output_folder_path, phase_n=phase_n, is_remove=False, date=date, min_interm=min_interm, classification=cypher_type)
    
    if p_ncfg:
        output_ncfg_path, general_path = create_output_folder(check_cfg="ncfg",
                            cypher_name=cypher_name, output_folder_path=output_folder_path, phase_n=phase_n, is_remove=False, 
                            date=date, min_interm=min_interm, classification=cypher_type)

    # Get input path
    try:
        if p_cfg:
            input_cfg_path, _ = create_output_folder(check_cfg="cfg", cypher_name=cypher_name, 
                                output_folder_path=output_folder_path, phase_n=phase_n-1, 
                                is_remove=False, date=date, classification=cypher_type)
        if (check_line):
            input_lcfg_path, _ = create_output_folder(check_cfg="lcfg", cypher_name=cypher_name, 
                                    output_folder_path=output_folder_path, phase_n=phase_n-1, 
                                    is_remove=False, date=date, classification=cypher_type)
        if p_ncfg:
            input_ncfg_path, _ = create_output_folder(check_cfg="ncfg", cypher_name=cypher_name, 
                                output_folder_path=output_folder_path, phase_n=phase_n-1, 
                                is_remove=False, date=date, classification=cypher_type)
    except:
        print("Unable to locate results from previous phase. Please check input date.")
        exit(0)

    # query path
    cypher_cfg_path = "{}{}/{}/{}/{}".format(cypher_path, cypher_type, cypher_name, "cfg", cypher_name)
    cypher_lcfg_path = "{}{}/{}/{}/{}".format(cypher_path, cypher_type, cypher_name, "lcfg", cypher_name)
    cypher_ncfg_path = "{}{}/{}/{}/{}".format(cypher_path, cypher_type, cypher_name, "ncfg", cypher_name)

    if not (os.path.exists(cypher_cfg_path + "-dataflow" + min_interm + ".cypher") \
        and os.path.exists(cypher_ncfg_path + "-dataflow" + min_interm + ".cypher")):
        print("Input dataflow query file does not exists. Please recheck \
              your user inputs")
        exit(0)

    # create output directory
    query_log = open(general_path + "query.log", "a")
    cmd_log = open(general_path + "cmd.log", "a")

    # CFG phase2 analysis
    if p_cfg:
        df_cfg_file = open(input_cfg_path + "dataflow_cfg_edges.csv", "r")
        otf_output = open(output_cfg_path + "otfOutput.txt", "a")

        df_cfg_time, df_cfg_size = run_analyses(output_path=otf_output, neo4j_path=neo4j_path,
            fact_folder_path=fact_folder_path, cmd_log=cmd_log, query_log=query_log, check_cfg="cfg",
            df_csv=df_cfg_file, cypher_path=cypher_cfg_path, min_interm=min_interm,is_ros=is_ros,
            multiple=multiple)

    
        df_cfg_file.close()
        otf_output.close()

    # CFG phase2 analysis
    if (check_line):
        df_lcfg_file = open(input_lcfg_path + "dataflow_lcfg_edges.csv", "r")
        lotf_output = open(output_lcfg_path + "lotfOutput.txt", "a")

        df_lcfg_time, df_lcfg_size = run_analyses(output_path=lotf_output, neo4j_path=neo4j_path,
            fact_folder_path=fact_folder_path, cmd_log=cmd_log, query_log=query_log, check_cfg="lcfg",
            df_csv=df_lcfg_file, cypher_path=cypher_lcfg_path, min_interm=min_interm,is_ros=is_ros,
            multiple=multiple)

        
        df_lcfg_file.close()
        lotf_output.close()

    # NCFG phase2 analysis
    if (p_ncfg):
        df_ncfg_file = open(input_ncfg_path + "dataflow_ncfg_edges.csv", "r")
        ncfg_output = open(output_ncfg_path + "ncfgOutput.txt", "a")

        df_ncfg_time, df_ncfg_size = run_analyses(output_path=ncfg_output, neo4j_path=neo4j_path,
            fact_folder_path=fact_folder_path, cmd_log=cmd_log, query_log=query_log, check_cfg="ncfg",
            df_csv=df_ncfg_file, cypher_path=cypher_ncfg_path, min_interm=min_interm, is_ros=is_ros,
            multiple=multiple)
    
    
        df_ncfg_file.close()
        ncfg_output.close()

    stop_neo4j(neo4j_path=neo4j_path, cmd_log_file=cmd_log)
    
    query_log.close()
    cmd_log.close()





