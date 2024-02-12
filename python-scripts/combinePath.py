from datetime import datetime
from CypherFile import create_output_folder, load_global_var
import sys
import os
import time

# script json location
project_folder = os.path.dirname(os.path.realpath(__file__))
json_directory = os.path.realpath(project_folder + "/script-json/") + "/"

B_TO_GB = (1 << 30)

def combine(suffix_file, prefix_file, dataflow_file, out_file_path, validate_dataflow_file, 
            cmd_log, keep_output):
    """
    ------------------------------------------------------------------------
    Combines prefix, suffix, and intermediate subquery results 
    ------------------------------------------------------------------------
    Parameters:
       suffix_file - file containing suffix subquery results (file object)
       prefix_file - file containing prefix subquery results (file object)
       dataflow_file - file containing intermdidate subquery results 
            (file object)
       out_file_path - output path of final results after combining the 
            subqueries (string)
       validate_dataflow_file - file to record intermediate paths that have
            a prefix and a suffix (file object)
       cmd_log - log file to record command line output (file object)
    Returns:
       None
    ------------------------------------------------------------------------
    """
    preDict = {}
    sufDict = {}

    t1 = datetime.now()
    b_estimate = 0
    total_b = 0
    count = 0
    total_count = 0
    batch = 1

    print("Batch 1: ")

    for line in prefix_file:
        prefix = line.strip().split("---")
        key = prefix[-1].lstrip(">")
        if key not in preDict:
            preDict[key] = []
        preDict[key].append(prefix)

    for line in suffix_file:
        suffix = line.strip().split("---")
        key = suffix[0]
        if key not in sufDict:
            sufDict[key] = []
        sufDict[key].append(suffix)

    # create output file
    out_file = open(out_file_path, "a")

    for line in dataflow_file:
        dataflow = line.strip().split("---")
        subTopic = dataflow[0]
        pubTopic = dataflow[-1].lstrip(">")

        hasPrefix = True
        hasSuffix = True

        if ((subTopic not in preDict)):
            hasPrefix = False

        if ((pubTopic not in sufDict)):
            hasSuffix = False
        
        #print("{0},{1},{2},{3}".format(line.strip(), hasPrefix, hasSuffix, hasSuffix and hasPrefix), file=validateDF)
        if (not (hasPrefix and hasSuffix)):
            continue
        print("{0},{1},{2},{3}".format(line.strip(), hasPrefix, hasSuffix, hasSuffix and hasPrefix), 
              file=validate_dataflow_file)

        sufArray = sufDict[pubTopic]
        preArray = preDict[subTopic]

        for pre in preArray:
            for suf in sufArray:
                if (pre != [] and suf != []):
                    
                    preA = pre[:-1]
                    sufA = suf[1:]
                    count += 1
                    path = "---".join(preA) + "---" + line.strip() + "---" + "---".join(sufA)
                    b_estimate += len(path.encode('utf-8'))
                    print(path, file=out_file)

                    # If estimate size is over 50GB then delete
                    #print(int(b_estimate/B_TO_GB))
                    if ((not keep_output) and (int(b_estimate/B_TO_GB) > 20)):
                        # print size
                        print("Size of batch: {:,} GB".format(int(b_estimate/B_TO_GB)))
                        print("Path in batch: {:,} paths".format(int(count)))

                        # reset variables
                        total_count += count
                        total_b += b_estimate
                        count = 0
                        b_estimate = 0
                        batch += 1

                        out_file.close()
                        #time.sleep(30)
                        os.remove(out_file_path)
                        #time.sleep(30)
                        out_file = open(out_file_path, "a")

                        print()
                        print("Batch {}: ".format(batch))

     # print size
    total_count += count
    total_b += b_estimate
    print("Size of batch: {:,} GB".format(int(b_estimate/B_TO_GB)))
    print("Path in batch: {:,} paths".format(int(count)))
    print()

    t1 = ((datetime.now()-t1).total_seconds())*1000
    print("Summary: ", file=cmd_log)
    print("[{}] Combine path time: {:,}ms".format(datetime.now(), t1), file=cmd_log)
    print("[{}] Number of path: {:,}".format(datetime.now(), total_count), file=cmd_log)
    print("Total size: {:,} GB".format(int(total_b/B_TO_GB)),file=cmd_log)
    print("Total size: {:,} B".format(total_b),file=cmd_log)

    print("Summary: ")
    print("[{}] Combine path time: {:,}ms".format(datetime.now(), t1))
    print("[{}] Number of path: {:,}".format(datetime.now(), total_count))
    print("Total size: {:,} GB".format(int(total_b/B_TO_GB)))
    print("Total size: {:,} B".format(total_b))

    out_file.close()

    if (not keep_output):
        os.remove(out_file_path)



if __name__=='__main__':    

    # load default settings
    software_name = input("Enter the name of the software (json file name): ")
    try:
        _, _, _, _, _, _, output_folder_path, _ \
            = load_global_var(json_directory + software_name + ".json")
    except:
        print("Unable to find software json file. Please try running the script again.")
        exit(0)

    cypher_type = input("Enter cypher type: ")
    cypher_name = input("Enter cypher name: ")
    min_cross = input("Enter minimum components (default: zero or more): ")
    date = input("Enter date (default: today): ")
    keep_result = input("Do you want to keep the output paths? (y/n) ") == "y"

    if (date == ""):
        date = datetime.today().strftime('%m-%d')

    print()

    # get phase1
    try:
        phase1_cfg_path, _ = create_output_folder(check_cfg="cfg", cypher_name=cypher_name, 
                                output_folder_path=output_folder_path, phase_n=1, is_remove=False, 
                                date=date, classification=cypher_type)
        phase1_ncfg_path, _ = create_output_folder(check_cfg="ncfg", cypher_name=cypher_name, 
                                output_folder_path=output_folder_path, phase_n=1, is_remove=False, 
                                date=date,classification=cypher_type)
    except:
        print("Unable to locate results from phase 1. Please check input date.")
        exit(0)

    # get phase2
    try:
        phase2_cfg_path, _ = create_output_folder(check_cfg="cfg", cypher_name=cypher_name, 
                                output_folder_path=output_folder_path, phase_n=2, is_remove=False, 
                                date=date, min_interm=min_cross, classification=cypher_type)
        phase2_ncfg_path, _ = create_output_folder(check_cfg="ncfg", cypher_name=cypher_name, 
                                output_folder_path=output_folder_path, phase_n=2, is_remove=False, 
                                date=date, min_interm=min_cross, classification=cypher_type)
    except:
        print("Unable to locate results from previoous phase. Please check input date.")
        exit(0)

    # get phase 3
    phase3_cfg_path, _ = create_output_folder(check_cfg="cfg", cypher_name=cypher_name, 
                            output_folder_path=output_folder_path, phase_n=3, is_remove=True, 
                            date=date, min_interm=min_cross, classification=cypher_type)
    phase3_ncfg_path, general_path = create_output_folder(check_cfg="ncfg", 
            cypher_name=cypher_name, output_folder_path=output_folder_path, phase_n=3, 
            is_remove=False, date=date, min_interm=min_cross, classification=cypher_type)
    
    # log file
    cmd_log = open(general_path + "cmd.log", "a")
    
    # Open file for ncfg
    combine_time = datetime.now()
    print("[{}] Start NCFG combine path: ".format(datetime.now()), file=cmd_log)
    print("[{}] Start NCFG combine path: ".format(datetime.now()))
    try:
        prefix_ncfg = open(phase1_ncfg_path + "prefix_ncfg.txt", "r")
        suffix_ncfg = open(phase1_ncfg_path + "suffix_ncfg.txt", "r")
        dfs_ncfg = open(phase2_ncfg_path + "ncfgOutput.txt", "r")
    except:
        print("Unable to locate results from previoous phase. Please check input date.")
        exit(0)
    #ncfg_output_path = open(phase3_ncfg_path + "NCFG.txt", "a")
    combined_ncfg_df = open(phase3_ncfg_path + "validatedDF.txt", "a")
    combine(suffix_ncfg, prefix_ncfg, dfs_ncfg, phase3_ncfg_path + "NCFG.txt", 
        combined_ncfg_df, cmd_log, keep_result)
    print("[{}] Finish NCFG combine path.".format(datetime.now()), file=cmd_log)
    print("[{}] Finish NCFG combine path.".format(datetime.now()))
    combine_time = (datetime.now() - combine_time).total_seconds() * 1000
    print("[{}] Time: {:,}ms".format(datetime.now(), combine_time), file=cmd_log)
    print("[{}] Time: {:,}ms".format(datetime.now(), combine_time))
    print()

    # close ncfg files
    prefix_ncfg.close()
    suffix_ncfg.close()
    dfs_ncfg.close()
    #ncfg_output.close()
    combined_ncfg_df.close()

    # Open file for cfg
    combine_time = datetime.now()
    print("[{}] Start CFG combine path: ".format(datetime.now()), file=cmd_log)
    print("[{}] Start CFG combine path: ".format(datetime.now()))
    prefix_cfg = open(phase1_cfg_path + "prefix_cfg.txt", "r")
    suffix_cfg = open(phase1_cfg_path + "suffix_cfg.txt", "r")
    dfs_cfg = open(phase2_cfg_path + "otfOutput.txt", "r")
    #cfg_output = open(phase3_cfg_path + "CFG.txt", "a")
    combined_cfg_df = open(phase3_cfg_path + "validatedDF.txt", "a")
    combine(suffix_cfg, prefix_cfg, dfs_cfg, phase3_cfg_path + "CFG.txt", combined_cfg_df, 
            cmd_log, True)
    print("[{}] Finish CFG combine path.".format(datetime.now()), file=cmd_log)
    print("[{}] Finish CFG combine path.".format(datetime.now()))
    combine_time = (datetime.now() - combine_time).total_seconds() * 1000
    print("[{}] Time: {:,}ms".format(datetime.now(), combine_time), file=cmd_log)
    print("[{}] Time: {:,}ms".format(datetime.now(), combine_time))
    print()

    # close cfg files
    prefix_cfg.close()
    suffix_cfg.close()
    dfs_cfg.close()
    #cfg_output.close()
    combined_cfg_df.close()

    cmd_log.close()



    

