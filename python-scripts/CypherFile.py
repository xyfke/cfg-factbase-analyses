import time
import os
import shutil
from subprocess import run, PIPE
from datetime import datetime
import json


# get cypher from a .cypher file
def file_to_cypher(cypher_file_path):
    """
    ------------------------------------------------------------------------
    Given a cypher file path, read the query from the cypher file and return
    the query in a string variable
    ------------------------------------------------------------------------
    Parameters:
       cypher_file_path -  absolute path of a cypher file (string)
    Returns:
       cypher_query - the cypher query (string)
    ------------------------------------------------------------------------
    """
    with open(cypher_file_path, 'r') as cypher_file:
        cypher_query = cypher_file.read().strip()
        #print(cypher_file_path)

    return cypher_query

def run_query(session, cypher_query, summary_name, comp_name, multiple):
    """
    ------------------------------------------------------------------------
    Run query, store result paths in an array. Also record and return start
    and end points if it is a intermediate subquery.
    ------------------------------------------------------------------------
    Parameters:
       session - A Neo4J database session to run the query (neo4j.Session)
       cypher_query - the cypher query to run (string)
       summary_name - the type of summary relationship (string)
       comp_name - the name of the component factbase that we are running the
                    query on (string)
       multiple - whether or not query results have multiple paths (boolean)
    Returns:
       cypher_result - list of result paths (list of string)
       df - list of unique head and tail nodes 
            (list of tuples[startID, endID, summary_name, comp_name])
    ------------------------------------------------------------------------
    """
    # define return variables
    cypher_result = set()
    df = []

    # Run query and loop through results
    for record in session.run(cypher_query):
        # Intermediate subquery - record result path and also record the head and tail nodes for 
        # each path to create summary links in phase 2
        if (summary_name is not None):
            cypher_result.add(tuple([record["path"].nodes[0]["id"], record["path"].nodes[-1]["id"], 
                                 summary_name, comp_name]))
            df.append(getPath(record["path"].nodes, record["path"].relationships))
        # Other queries  - record results in array
        else:
            if (multiple):          # Handles and store multiple paths
                y = []
                for i in range(0, len(record["path"])):
                    y.append(getPath(record["path"][i].nodes, record["path"][i].relationships))

                y.sort()
                ins = ""
                for p in y:
                    ins += p + "\t"
                
                cypher_result.add(ins)
                #cypher_result.append(getPath(record["path"][i].nodes, record["path"][i].relationships))
                #cypher_result.append("")
            else:                   # Store single path returns
                cypher_result.add(getPath(record["path"].nodes, record["path"].relationships))

    return cypher_result, df

def getPath(nodes, relationships):
    """
    ------------------------------------------------------------------------
    Converts nodes and relationships from a Neo4J path into a string 
    representation made out of node ids and relationship types
    ------------------------------------------------------------------------
    Parameters:
       nodes - list of nodes in a path (list of neo4j.Node)
       relationships - list of relationships in a path 
                        (list of neo4j.Relationships)
    Returns:
       path - string representation of a Neo4J path (string)
    ------------------------------------------------------------------------
    """
    path = ""
    for i in (range(len(relationships))):
        path += "{0}---[:{1}]--->".format(nodes[i]["id"], relationships[i].type)
    path += nodes[-1]["id"]
    return path

# sort path and write results to file
def write_path(path_result, f, unique):
    """
    ------------------------------------------------------------------------
    Given path results stored in an array, write these results to 
    corresponding file object
    ------------------------------------------------------------------------
    Parameters:
       path_result - list of elements to write to file object 
                        (list of string or tuple)
       f - file object to write to path_result to (file object)
       unique - whether or not make sure all results are unique (boolean)
    Returns:
       None
    ------------------------------------------------------------------------
    """
    # make sure results are unique if requested
    if (unique):
        path_array = list(set(path_result))
        path_array.sort(key = len, reverse=True)
    else:
        path_array = path_result

    # write to path
    for path in path_array:
        print(path, file=f)


def command_line(cmd, cmd_log_file):
    """
    ------------------------------------------------------------------------
    Run bash command and record results in command log file
    ------------------------------------------------------------------------
    Parameters:
       cmd - the command line input to run (string)
       cmd_log_file - log file to record command line output (file object)
    Returns:
       result.returncode - success or fail code (string)
    ------------------------------------------------------------------------
    """
    result = run(cmd, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    print(result.returncode, file=cmd_log_file) 
    print(result.stdout.decode("utf-8"), file=cmd_log_file)
    return result.returncode

def stop_neo4j(neo4j_path, cmd_log_file):
    # Stop neo4j database
    os.chdir(neo4j_path + "bin/")
    cmd = "./neo4j stop".split(" ")
    returnCode = command_line(cmd, cmd_log_file)
    time.sleep(30)
    return returnCode


def append_nodes_edges_command_line(component_node, component_edge, cmd_log_file, 
                                    neo4j_path, fact_path):
    """
    ------------------------------------------------------------------------
    Clear existing database and load new factbase provided with the 
    respective node and edge filenames 
    ------------------------------------------------------------------------
    Parameters:
       component_node - name of node file (string)
       component_edge - name of edge file (string)
       cmd_log_file - log file to record command line output (file object)
       neo4j_path - folder path of neo4j instance (string)
       fact_path - folder path of factbase (string)
    Returns:
       success or fail boolean value (boolean)
    ------------------------------------------------------------------------
    """

    # Stop neo4j database
    time.sleep(30)
    os.chdir(neo4j_path + "bin/")
    cmd = "./neo4j stop".split(" ")
    returnCode = command_line(cmd, cmd_log_file)
    #time.sleep(30)

    # construct component factbase path
    component_node = fact_path + component_node
    component_edge = fact_path + component_edge

    # Clear database
    print("Remove databases and transactions files", file=cmd_log_file)
    shutil.rmtree(neo4j_path + "/data/databases/")
    os.mkdir(neo4j_path + "/data/databases/")
    shutil.rmtree(neo4j_path + "/data/transactions/")
    os.mkdir(neo4j_path + "/data/transactions/")
    print("Success", file=cmd_log_file)

    # import the files into the database
    print("Setup neo4j", file=cmd_log_file)
    cmd = r"""./neo4j-admin import --delimiter=\t --nodes {} --relationships {}""".format(component_node, component_edge).split(" ")
    print(cmd, file=cmd_log_file)
    returnCode = command_line(cmd, cmd_log_file)
    if (returnCode != 0):
        print("Import failed.")
        return False

    cmd = r"""./neo4j-admin set-initial-password test1234""".split( )
    returnCode = command_line(cmd, cmd_log_file)
    print(file=cmd_log_file)
    if (returnCode != 0):
        print("Set password failed.")
        return False

    cmd = r"./neo4j start".split(" ")
    returnCode = command_line(cmd, cmd_log_file)
    if (returnCode != 0):
        print("Restart Neo4J failed.")
        return False
    time.sleep(30)

    return True

def run_query_write_results(session, cypher_file_path, path_file, 
                            summary_name, query_name, query_file, comp_name="", multiple=False,
                            unique=False, df_csv=None):
    """
    ------------------------------------------------------------------------
    Run query and record results in specified files
    ------------------------------------------------------------------------
    Parameters:
       session - A Neo4J database session to run the query (neo4j.Session)
       cypher_file_path -  absolute path of a cypher file (string)
       path_file - file to output path results from running query (file obejct)
       summary_name - the type of summary relationship (string)
       query_name - the name of the query (string)
       query_file - log file that records query running information 
                    (file object) 
       comp_name - the name of the component factbase that we are running the
                    query on (string, default: "")
       multiple - whether or not query results have multiple paths 
                    (boolean, default: False)
       unique - whether or not make sure all results are unique 
                (boolean, default: False)
       df_csv - csv file to record summary path between start and end node 
                (file object, default: None)
    Returns:
       None
    ------------------------------------------------------------------------
    """
    print("[{}] Start running {} query".format(datetime.now(), query_name), file=query_file)
    print("[{}] Start running {} query".format(datetime.now(), query_name))

    # Get query and run query
    query_time = datetime.now()
    cypher_query = file_to_cypher(cypher_file_path)
    result_array, df = run_query(session, cypher_query, summary_name, comp_name, multiple)

    # record results
    if (summary_name is None):
        write_path(result_array, path_file, unique)
    else:
        df_csv.writerows(result_array)
        write_path(df, path_file, True)  

    query_time = (datetime.now() - query_time).total_seconds() * 1000

    # log query output information
    print("[{}] Time: {}ms, Size: {} paths".format(datetime.now(), query_time, 
                                                   len(result_array)), file=query_file)
    print("[{}] Time: {}ms, Size: {} paths".format(datetime.now(), query_time, 
                                                   len(result_array)))

    print("[{}] Finish running {} query".format(datetime.now(), query_name), file=query_file)
    print("[{}] Finish running {} query".format(datetime.now(), query_name))

    return query_time, len(result_array)


def create_output_folder(check_cfg, cypher_name, output_folder_path, classification,
                         phase_n = None, is_remove = False, date = datetime.today().strftime('%m-%d'), 
                         min_interm = ""):
    """
    ------------------------------------------------------------------------
    Create output directory and related files
    ------------------------------------------------------------------------
    Parameters:
       check_cfg - whether or not query performs CFG validation (boolean)
       cypher_name - the name of cypher that we are about to run (string)
       output_folder_path - general folder directory path to output folder 
                            (string)
       classification - general classification of query (string)
       phase_n - the phase number (int, default: None)
       is_remove - remove direcotry to clear previous results
                    (boolean, default: True)
       date - date in string format mm-dd (string, default: today's date)
       min_interm - number of intermediate component (string, default: "")
    Returns:
       None
    ------------------------------------------------------------------------
    """
    
    # construct cypher path
    output_folder_cypher_path = output_folder_path + date + "/" + classification + "-" + \
        cypher_name + "/"
    if (not os.path.exists(output_folder_cypher_path)):
        os.makedirs(output_folder_cypher_path)

    # check if there is a phase number
    if (phase_n is not None):
        new_path = output_folder_cypher_path + "phase" + str(phase_n) + min_interm + "/"
        if (is_remove and os.path.exists(new_path)):
            shutil.rmtree(new_path)
        if (not os.path.exists(new_path)):
            os.makedirs(new_path)
        is_remove = False
        output_folder_cypher_path = new_path

    # separate cfg and ncfg output
    actual_folder = output_folder_cypher_path + check_cfg + "/"
    if (is_remove and os.path.exists(actual_folder)):
        shutil.rmtree(actual_folder)
    if (not os.path.exists(actual_folder)):
        os.mkdir(actual_folder)

    #print(actual_folder, output_folder_cypher_path)

    return actual_folder, output_folder_cypher_path


def load_global_var(json_file_path):
    """
    ------------------------------------------------------------------------
    Get neo4j information and fact csv information from a specified json
    file
    ------------------------------------------------------------------------
    Parameters:
       json_file_path - the default configuration json file (string)
    Returns:
       neo4j_path - folder direcotry path of neo4j instance (string)
       neo4j_bolt - bolt uri for the neo4j instance (string)
       neo4j_username - username of neo4j instance (string)
       neo4j_password - password of neo4j instance (string)
       fact_path - folder directory path of factbase (string)
       output_path - output directory path of query results (string)
       input_path - input direcotry path of query results (string)
       component_path - the csv file path that lists all the component 
                        (string)
    ------------------------------------------------------------------------
    """
    json_file = open(json_file_path)

    configuraitons = json.load(json_file)

    # Neo4J settings
    neo4j_path = configuraitons['neo4jInstancePath'].replace("~", os.path.expanduser("~"))
    neo4j_bolt = "bolt://localhost:" + configuraitons['neo4jBoltPort']
    neo4j_username = configuraitons['neo4jUsername']
    neo4j_password = configuraitons['neo4jPassword']

    # Fact and input/output settings
    fact_path = configuraitons["neo4jFactPath"].replace("~", os.path.expanduser("~"))
    output_path = configuraitons['neo4jOutputPath'].replace("~", os.path.expanduser("~"))
    input_path = configuraitons['neo4jInputPath'].replace("~", os.path.expanduser("~"))
    component_path = configuraitons['neo4jComponentCSV'].replace("~", os.path.expanduser("~"))

    # Print all the configuration values to standard output
    print("Neo4J Instance: {}".format(neo4j_path))
    print("Neo4J Bolt: {}".format(neo4j_bolt))
    print("Neo4J Username: {}".format(neo4j_username))
    print("Neo4J Password: {}".format(neo4j_password))

    print()

    print("Neo4J Fact Path: {}".format(fact_path))
    print("Output Path: {}".format(output_path))
    print("Input Instance: {}".format(input_path))
    print("Component Path: {}".format(component_path))
    print()

    return neo4j_path, neo4j_bolt, neo4j_username, neo4j_password, \
        fact_path, output_path, input_path, component_path
