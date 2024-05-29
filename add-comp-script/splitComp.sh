#!/bin/bash

# Assume the fact folder path structure is as below:
# factfolderPath/
#   cfg/
#       nodes.csv
#       edges.csv
#   ncfg/
#       nodes.csv
#       edges.csv

# This script creates a component division based on inputed divisionPath (which is a .csv file)
#   underneath each factfolderPath/cfg/ and factfolderPath/ncfg/ subfolder

echo "Enter fact folder path: "
read factFolderPath

echo "Enter component division csv: "
read divisionPath

# Define output folder paths
cfgNodePath="${factFolderPath}/cfg/nodes.csv"
cfgEdgePath="${factFolderPath}/cfg/edges.csv"
cfgEdgePathSorted="${factFolderPath}/cfg/edges_sorted.csv"
cfgCompNodeFolder="${factFolderPath}/cfg/nodes/"
cfgCompEdgeFolder="${factFolderPath}/cfg/edges/"
allCFGNodePath="${factFolderPath}/cfg/allCompNodes.csv"
allCFGEdgePath="${factFolderPath}/cfg/allCompEdges.csv"

ncfgNodePath="${factFolderPath}/ncfg/nodes.csv"
ncfgEdgePath="${factFolderPath}/ncfg/edges.csv"
ncfgCompNodeFolder="${factFolderPath}/ncfg/nodes/"
ncfgCompEdgeFolder="${factFolderPath}/ncfg/edges/"
allNCFGNodePath="${factFolderPath}/ncfg/allCompNodes.csv"
allNCFGEdgePath="${factFolderPath}/ncfg/allCompEdges.csv"

# Check if previous inputs are there, if yes remove
[ -d ${ncfgCompNodeFolder} ] && rm -r ${ncfgCompNodeFolder}
[ -d ${ncfgCompEdgeFolder} ] && rm -r ${ncfgCompEdgeFolder}
[ -d ${allNCFGNodePath} ] && rm -r ${allNCFGNodePath}
[ -d ${allNCFGEdgePath} ] && rm -r ${allNCFGEdgePath}

[ -d ${cfgCompNodeFolder} ] && rm -r ${cfgCompNodeFolder}
[ -d ${cfgCompEdgeFolder} ] && rm -r ${cfgCompEdgeFolder}
[ -d ${allCFGNodePath} ] && rm -r ${allCFGNodePath}
[ -d ${allCFGEdgePath} ] && rm -r ${allCFGEdgePath}
[ -f ${cfgEdgePathSorted} ] && rm ${cfgEdgePathSorted}

# Create node and edges directories
mkdir ${ncfgCompNodeFolder}
mkdir ${ncfgCompEdgeFolder}
mkdir ${cfgCompNodeFolder}
mkdir ${cfgCompEdgeFolder}

echo "Start dividing NCFG factbase"

### The following gawk is for ncfg
gawk -v compNode=${ncfgCompNodeFolder} -v compEdge=${ncfgCompEdgeFolder} \
    -v allNode=${allNCFGNodePath} -v allEdge=${allNCFGEdgePath} -v division=${divisionPath} \
    -v nodePath=${ncfgNodePath} -v edgePath=${ncfgEdgePath} '{
    # create mapping for division
    if (FILENAME == division && FNR >= 1) {
        FS=OFS=",";   # specify delimiter
        gsub(/\015/, "", $0);
        if ($0 != "component,prefix") {
            prefixToComp[$2]=$1;
        }
    
    } else if (FILENAME == nodePath && FNR == 1) {
        # store header of node file
        FS=OFS="\t";    # specify delimiter
        nheader=$0; 
        print nheader > allNode;

    } else if (FILENAME == nodePath && FNR > 1) {
        OFS=FS="\t";    # specify delimiter
        fl = $13;
        if (fl == "") {
            fl = $14;
        }
        if (fl != "") {
            # look for matching components
            compName = "";
            for (x in prefixToComp) {
                if (index(fl, x) != 0) {
                    compName = prefixToComp[x];
                }
            }
            if (compName != "") {
                nodeToComp[$1]=compName;
                if (!nodefile[compNode "" compName "-nodes.csv"]++) {
                    print nheader > compNode "" compName "-nodes.csv";
                }
                print $0 > compNode "" compName "-nodes.csv";
            }
            print $0 > allNode;
        } else {
            print $0 > "ANoFilename.csv";         # debug purpose - should not get to this stage
            print $0 > allNode;
        }
    } else if (FILENAME == edgePath && FNR == 1) {
        # store header of edge file
        FS="\t"; 
        eheader=$0; 
        print eheader > allEdge;
    } else if (FILENAME == edgePath && FNR > 1) {
        # store header of edge file
        FS="\t"; 

        # Get source node and destination node 
        srcComp=nodeToComp[$1];
        dstComp=nodeToComp[$2];

        # Get source and destination edge files
        srcCompEdge=compEdge srcComp "-edges.csv";
        dstCompEdge=compEdge dstComp "-edges.csv"
        srcCompNode=compNode srcComp "-nodes.csv";
        dstCompNode=compNode dstComp "-nodes.csv"

        # Record in all edge file
        print $0 > allEdge;

        if (srcComp == "" || dstComp == "") {
            next;
        }

        # Check if source and destination edge file exists
        # If not, create them
        if (!edgefile[srcCompEdge]++) {
            print eheader > srcCompEdge;
        }
        if (!edgefile[dstCompEdge]++) {
            print eheader > dstCompEdge;
        }

        if (srcComp == dstComp) {
            print $0 > srcCompEdge;
        }
        # without CFG, we will just map it directly cause we have no idea which function they 
        # belong to
        else if (srcComp != dstComp) {
            endComp=srcComp ";;cCompEnd;;";
            startComp=dstComp ";;cCompStart;;";

            # create the endComps
            if (!eComps[endComp]++) {
                print endComp "\tcCompEnd\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" > srcCompNode;
                print endComp "\tcCompEnd\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" > allNode;
            }

            # create the startComps
            if (!sComps[startComp]++) {
                print startComp "\tcCompStart\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" > dstCompNode;
                print startComp "\tcCompStart\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" > allNode;
            }

            compES="compCall";

            if ($3 == "parWrite") {
                crossOut="parWriteOut";
                crossIn="parWriteIn";
            } else if ($3 == "varWrite") {
                crossOut="varWriteOut";
                crossIn="varWriteIn";
                compES="compWrite";
            } else if ($3 == "retWrite") {
                crossOut="retWriteOut";
                crossIn="retWriteIn";
                compES="compReturn";
            } else if ($3 == "call") {
                crossOut="callOut";
                crossIn="callIn";
            }

            if ((crossOut != "") && (crossIn != "")) {
                if (!crossOuts[$1 endComp crossOut]++) {
                    print $1 "\t" endComp "\t" crossOut "\t\t\t\t\t" > srcCompEdge;
                    print $1 "\t" endComp "\t" crossOut "\t\t\t\t\t" > allEdge;
                }
                if (!crossIns[startComp $2 crossIn]++) {
                    print startComp "\t" $2 "\t" crossIn "\t\t\t\t\t" > dstCompEdge;
                    print startComp "\t" $2 "\t" crossIn "\t\t\t\t\t" > allEdge;
                }

                if (!compRels[endComp startComp compES]++) {
                    print endComp "\t" startComp "\t" compES "\t\t\t\t\t" > allEdge;
                }
            }

        }

    }
}' ${divisionPath} ${ncfgNodePath} ${ncfgEdgePath}

echo "Finish dividing NCFG factbase"

echo "Start dividing CFG factbase"

head -n 1 $cfgEdgePath > $cfgEdgePathSorted
grep -P "\tcontain\t" $cfgEdgePath >> $cfgEdgePathSorted
grep -P "\tnextCFGBlock\t" $cfgEdgePath >> $cfgEdgePathSorted
tail -n +2 $cfgEdgePath |  grep -v -P  "\tnextCFGBlock\t|\tcontain\t" | sort -f -t  $'\t' -k 3 >> $cfgEdgePathSorted
#(head -n 1 $cfgEdgePath && tail -n +2 $cfgEdgePath | sort -f -t  $'\t' -k 3 ) > $cfgEdgePathSorted

### The following gawk is for cfg
gawk -v compNode=${cfgCompNodeFolder} -v compEdge=${cfgCompEdgeFolder} \
    -v allNode=${allCFGNodePath} -v allEdge=${allCFGEdgePath} -v division=${divisionPath} \
    -v nodePath=${cfgNodePath} -v edgePath=${cfgEdgePathSorted} '{
    # create mapping for division
    if (FILENAME == division && FNR >= 1) {
        FS=OFS=",";   # specify delimiter
        gsub(/\015/, "", $0);
        if ($0 != "component,prefix") {
            prefixToComp[$2]=$1;
        }
        
    
    } else if (FILENAME == nodePath && FNR == 1) {
        # store header of node file
        FS=OFS="\t";    # specify delimiter
        nheader=$0; 
        print nheader > allNode;

    } else if (FILENAME == nodePath && FNR > 1) {
        OFS=FS="\t";    # specify delimiter
        fl = $13;
        if (fl == "") {
            fl = $14;
        }
        if (fl != "") {
            # look for matching components
            compName = "";
            for (x in prefixToComp) {
                if (index(fl, x) != 0) {
                    compName = prefixToComp[x];
                }
            }

            if (compName != "") {
                nodeToComp[$1]=compName;
                if (!nodefile[compNode "" compName "-nodes.csv"]++) {
                    print nheader > compNode "" compName "-nodes.csv";
                }
                print $0 > compNode "" compName "-nodes.csv";
            }
            print $0 > allNode;
        } else {
            print $0 > "ANoFilename.csv";         # debug purpose - should not get to this stage
            print $0 > allNode;
        }
    } else if (FILENAME == edgePath && FNR == 1) {
        # store header of edge file
        FS="\t"; 
        eheader=$0; 
        print eheader > allEdge;
    } else if (FILENAME == edgePath && FNR > 1) {
        # store header of edge file
        FS="\t"; 

        # Get source node and destination node 
        srcComp=nodeToComp[$1];
        dstComp=nodeToComp[$2];

        # Get source and destination edge files
        srcCompEdge=compEdge srcComp "-edges.csv";
        dstCompEdge=compEdge dstComp "-edges.csv"

        # Record in all edge file
        print $0 > allEdge;

        if (srcComp == "" || dstComp == "") {
            next;
        }

        # Check if source and destination edge file exists
        # If not, create them
        if (!edgefile[srcCompEdge]++) {
            print eheader > srcCompEdge;
        }
        if (!edgefile[dstCompEdge]++) {
            print eheader > dstCompEdge;
        }

        # Keep track of CFG to function
        if ($3 == "contain") {
            contain[$2] = $1;
        }

        if (srcComp == dstComp) {
            print $0 > srcCompEdge;

            # Keep a record of all the CFG linkages
            if (($3 == "varWriteSource")) {
                if (vwSrc[$1] == "") {
                    vwSrc[$1] = $2 "#";
                } else {
                    vwSrc[$1] = vwSrc[$1] $2 "#";
                }
            } else if ($3 == "varWriteDestination") {
                if (vwDst[$1] == "") {
                    vwDst[$1] = $2 "#";
                } else {
                    vwDst[$1] = vwDst[$1] $2 "#";
                }
            } else if (($3 == "parWriteSource") && ($2 in cfgISrc)) {
                if (pwSrc[$1] == "") {
                    pwSrc[$1] = $2 "#";
                } else {
                    pwSrc[$1] = pwSrc[$1] $2 "#";
                }
            } else if (($3 == "parWriteDestination") && (($2 in cfgIDst))) {
                if (pwDst[$1] == "") {
                    pwDst[$1] = $2 "#";
                } else {
                    pwDst[$1] = pwDst[$1] $2 "#";
                }
            } else if (($3 == "retWriteSource") && (($2 in cfgRSrc))) {
                if (rwSrc[$1] == "") {
                    rwSrc[$1] = $2 "#";
                } else {
                    rwSrc[$1] = rwSrc[$1] $2 "#";
                }
            } else if (($3 == "retWriteDestination") && ($2 in cfgRDst)) {
                if (rwDst[$1] == "") {
                    rwDst[$1] = $2 "#";
                } else {
                    rwDst[$1] = rwDst[$1] $2 "#";
                }
            }
        }
        else if (srcComp != dstComp) {

            # Record the cross component CFG graph edges
            # 4th column is the attribute cfgInvoke
            if ($3 == "nextCFGBlock") {
                if ($4 == "1") {    # get CFG invoke column
                    cfgInvoke[$1][$2] = 1;
                    cfgISrc[$1]++;
                    cfgIDst[$2]++;

                    caller = contain[$1];
                    calling = contain[$2];

                    compSrcEnd = caller srcComp ";;cCompEnd;;";
                    compDstStart = calling dstComp ";;cCompStart;;";

                    callerComp = nodeToComp[caller];
                    callingComp = nodeToComp[calling];

                     # Get the nodes and edge files
                    srcNodeFile = compNode callerComp "-nodes.csv";
                    srcEdgeFile = compEdge callerComp "-edges.csv";
                    dstNodeFile = compNode callingComp "-nodes.csv";
                    dstEdgeFile = compEdge callingComp "-edges.csv";

                    # Create start and end nodes
                    if (!compEnd[compSrcEnd]++) {
                        print compSrcEnd "\tcCompEnd\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" > srcNodeFile; 
                        print compSrcEnd "\tcCompEnd\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" > allNode;
                    }
                    if (!compStart[compDstStart]++) {
                        print compDstStart "\tcCompStart\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" > dstNodeFile; 
                        print compDstStart "\tcCompStart\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" > allNode;
                    }

                    # Create `compCall` edge + CFG linkages (only need to be in all component file)
                    if (!compCall[compSrcEnd compDstStart]++) {
                        print compSrcEnd "\t" compDstStart "\tcompCall\t\t\t\t\t" > allEdge;
                        print compSrcEnd "\t" $1 "\tcompCallSource\t\t\t\t\t" > allEdge;
                        print compDstStart "\t" $2 "\tcompCallDestination\t\t\t\t\t" > allEdge;
                    }

                    # Create `callOut` and `callIn` edge + CFG linkages
                    if (!callOut[caller compSrcEnd]++) {
                        print caller "\t" compSrcEnd "\tcallOut\t\t\t\t\t" > srcEdgeFile;
                        print caller "\t" compSrcEnd "\tcallOut\t\t\t\t\t" > allEdge; 

                        # Link to src CFG
                        print caller "\t" $1 "\tcallOutSource\t\t\t\t\t" > srcEdgeFile;
                        print caller "\t" $1 "\tcallOutSource\t\t\t\t\t" > allEdge;
                        print compSrcEnd "\t" $1 "\tcallOutDestination\t\t\t\t\t" > srcEdgeFile;
                        print compSrcEnd "\t" $1 "\tcallOutDestination\t\t\t\t\t" > allEdge; 
                    }
                    if (!callIn[compDstStart calling]++) {
                        print compDstStart "\t" calling "\tcallIn\t\t\t\t\t" > dstEdgeFile;
                        print compDstStart "\t" calling "\tcallIn\t\t\t\t\t" > allEdge;

                        # Link to dst CFG
                        print compDstStart "\t" $2 "\tcallInSource\t\t\t\t\t" > dstEdgeFile;
                        print compDstStart "\t" $2 "\tcallInSource\t\t\t\t\t" > allEdge;
                        print calling "\t" $2 "\tcallInDestination\t\t\t\t\t" > dstEdgeFile;
                        print calling "\t" $2 "\tcallInDestination\t\t\t\t\t" > allEdge;
                    }


                    

                } else if ($5 == "1") {    # get CFG return column
                    cfgReturn[$1][$2] = 1;
                    cfgRSrc[$1]++;
                    cfgRDst[$2]++;
                }
            } 

            # Keep track of all cross component dataflows
            if ($3 == "varWrite") {
                crossVW[$1][$2]++;
            } else if ($3 == "parWrite") {
                crossPW[$1][$2]++;
            } else if ($3 == "retWrite") {
                crossRW[$1][$2]++;
            }

            if ($3 == "call") {
                crossCall[$1][$2]++;
            }

            if ($3 == "varWriteSource") {
                if (vwSrc[$1] == "") {
                    vwSrc[$1] = $2 "#";
                } else {
                    vwSrc[$1] = vwSrc[$1] $2 "#";
                }
            } else if ($3 == "varWriteDestination") {
                if (vwDst[$1] == "") {
                    vwDst[$1] = $2 "#";
                } else {
                    vwDst[$1] = vwDst[$1] $2 "#";
                }
            }

        }

    }
} END {
    print "Adding temporary nodes and edges";

    # Deal with parWrite first
    for (variable in crossPW) {
        for (param in crossPW[variable]) {
            
            # Get source and destination of related CFG parWrite links
            n1 = split(pwSrc[variable], cfgSrcList, "#");
            n2 = split(pwDst[param], cfgDstList, "#");

            if (variable == "" || param == "") {
                continue;
            }

            # Loop through these possible cross componnet CFG links
            for (i = 1; i <= n1; i++) {
                srcCFG = cfgSrcList[i];
                for (j = 1; j <= n2; j++) {
                    dstCFG = cfgDstList[j];

                    if (dstCFG == "" || srcCFG == "") {
                        continue;
                    }

                    # Check if there is a cfgInvoke that is cross component
                    if (cfgInvoke[srcCFG][dstCFG] != 1) {
                        continue;
                    }

                    # Get component names and start and end points
                    caller = contain[srcCFG];   # get function that makes the paramter passing
                    calling = contain[dstCFG];   # get function of the parameter
                    srcComp = nodeToComp[caller];
                    dstComp = nodeToComp[calling];
                    compSrcEnd = caller srcComp ";;cCompEnd;;";
                    compDstStart = calling dstComp ";;cCompStart;;";

                    # Get the nodes and edge files
                    srcNodeFile = compNode srcComp "-nodes.csv";
                    srcEdgeFile = compEdge srcComp "-edges.csv";
                    dstNodeFile = compNode dstComp "-nodes.csv";
                    dstEdgeFile = compEdge dstComp "-edges.csv";

                    # Create `parWriteOut` and `parWriteIn` edge + CFG linkages
                    if (!parWriteOut[variable compSrcEnd]++) {
                        print variable "\t" compSrcEnd "\tparWriteOut\t\t\t\t\t" > srcEdgeFile;
                        print variable "\t" compSrcEnd "\tparWriteOut\t\t\t\t\t" > allEdge; 

                        # Link to src CFG
                        print variable "\t" srcCFG "\tparWriteOutSource\t\t\t\t\t" > srcEdgeFile;
                        print variable "\t" srcCFG "\tparWriteOutSource\t\t\t\t\t" > allEdge;
                        print compSrcEnd "\t" srcCFG "\tparWriteOutDestination\t\t\t\t\t" > srcEdgeFile;
                        print compSrcEnd "\t" srcCFG "\tparWriteOutDestination\t\t\t\t\t" > allEdge; 
                    }
                    if (!parWriteIn[compDstStart param]++) {
                        print compDstStart "\t" param "\tparWriteIn\t\t\t\t\t" > dstEdgeFile;
                        print compDstStart "\t" param "\tparWriteIn\t\t\t\t\t" > allEdge;

                        # Link to dst CFG
                        print compDstStart "\t" dstCFG "\tparWriteInSource\t\t\t\t\t" > dstEdgeFile;
                        print compDstStart "\t" dstCFG "\tparWriteInSource\t\t\t\t\t" > allEdge;
                        print param "\t" dstCFG "\tparWriteInDestination\t\t\t\t\t" > dstEdgeFile;
                        print param "\t" dstCFG "\tparWriteInDestination\t\t\t\t\t" > allEdge;
                    }
                }
            }


        }
    }

    # Deal with retWrite first
    for (returnNode in crossRW) {
        for (variable in crossRW[returnNode]) {
            
            # Get source and destination of related CFG retWrite links
            n1 = split(rwSrc[returnNode], cfgSrcList, "#");
            n2 = split(rwDst[variable], cfgDstList, "#");

            # Loop through these possible cross componnet CFG links
            for (i = 1; i <= n1; i++) {
                srcCFG = cfgSrcList[i];
                for (j = 1; j <= n2; j++) {
                    dstCFG = cfgDstList[j];

                    if (dstCFG == "" || srcCFG == "") {
                        continue;
                    }

                    # Check if there is a cfgReturn that is cross component
                    if (cfgReturn[srcCFG][dstCFG] != 1) {
                        continue;
                    }

                    # Get component names and start and end points
                    caller = contain[srcCFG];   # returning function
                    calling = contain[dstCFG];   # function returning to
                    srcComp = nodeToComp[caller];
                    dstComp = nodeToComp[calling];
                    compSrcEnd = caller srcComp ";;cCompEnd;;";
                    compDstStart = calling dstComp ";;cCompStart;;";

                    # Get the nodes and edge files
                    srcNodeFile = compNode srcComp "-nodes.csv";
                    srcEdgeFile = compEdge srcComp "-edges.csv";
                    dstNodeFile = compNode dstComp "-nodes.csv";
                    dstEdgeFile = compEdge dstComp "-edges.csv";

                    # Create start and end nodes
                    if (!compEnd[compSrcEnd]++) {
                        print compSrcEnd "\tcCompEnd\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" > srcNodeFile; 
                        print compSrcEnd "\tcCompEnd\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" > allNode;
                    }
                    if (!compStart[compDstStart]++) {
                        print compDstStart "\tcCompStart\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" > dstNodeFile; 
                        print compDstStart "\tcCompStart\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" > allNode;
                    }

                    # Create `compReturn` edge + CFG linkages (only need to be in all component file)
                    if (!compReturn[compSrcEnd compDstStart]++) {
                        print compSrcEnd "\t" compDstStart "\tcompReturn\t\t\t\t\t" > allEdge;
                        print compSrcEnd "\t" $1 "\tcompReturnSource\t\t\t\t\t" > allEdge;
                        print compDstStart "\t" $2 "\tcompReturnDestination\t\t\t\t\t" > allEdge;
                    }

                    # Create `retWriteOut` and `retWriteIn` edge + CFG linkages
                    if (!retWriteOut[returnNode compSrcEnd]++) {
                        print returnNode "\t" compSrcEnd "\tretWriteOut\t\t\t\t\t" > srcEdgeFile;
                        print returnNode "\t" compSrcEnd "\tretWriteOut\t\t\t\t\t" > allEdge; 

                        # Link to src CFG
                        print returnNode "\t" srcCFG "\tretWriteOutSource\t\t\t\t\t" > srcEdgeFile;
                        print returnNode "\t" srcCFG "\tretWriteOutSource\t\t\t\t\t" > allEdge;
                        print compSrcEnd "\t" srcCFG "\tretWriteOutDestination\t\t\t\t\t" > srcEdgeFile;
                        print compSrcEnd "\t" srcCFG "\tretWriteOutDestination\t\t\t\t\t" > allEdge; 
                    }
                    if (!retWriteIn[compDstStart variable]++) {
                        print compDstStart "\t" variable "\tretWriteIn\t\t\t\t\t" > dstEdgeFile;
                        print compDstStart "\t" variable "\tretWriteIn\t\t\t\t\t" > allEdge;

                        # Link to dst CFG
                        print compDstStart "\t" dstCFG "\tretWriteInSource\t\t\t\t\t" > dstEdgeFile;
                        print compDstStart "\t" dstCFG "\tretWriteInSource\t\t\t\t\t" > allEdge;
                        print variable "\t" dstCFG "\tretWriteInDestination\t\t\t\t\t" > dstEdgeFile;
                        print variable "\t" dstCFG "\tretWriteInDestination\t\t\t\t\t" > allEdge;
                    }
                }
            }
        }
    }

    # Deal with varWrite first
    for (variable1 in crossVW) {
        for (variable2 in crossVW[variable1]) {
            
            # Get source and destination of related CFG retWrite links
            n1 = split(vwSrc[variable1], cfgSrcList, "#");
            n2 = split(vwDst[variable2], cfgDstList, "#");

            # Loop through these possible cross componnet CFG links
            for (i = 1; i <= n1; i++) {
                srcCFG = cfgSrcList[i];
                for (j = 1; j <= n2; j++) {
                    dstCFG = cfgDstList[j];

                    if (dstCFG == "" || srcCFG == "") {
                        continue;
                    }

                    # Check if the function node matches
                    if (srcCFG == dstCFG) {
                        continue;
                    }

                    # Get component names and start and end points
                    fun = contain[srcCFG];   # assignment CFG
                    srcComp = nodeToComp[variable1];
                    dstComp = nodeToComp[variable2];
                    compSrcEnd = fun srcComp ";;cCompEnd;;";
                    compDstStart = fun dstComp ";;cCompStart;;";

                    # Get the nodes and edge files
                    srcNodeFile = compNode srcComp "-nodes.csv";
                    srcEdgeFile = compEdge srcComp "-edges.csv";
                    dstNodeFile = compNode dstComp "-nodes.csv";
                    dstEdgeFile = compEdge dstComp "-edges.csv";

                    # Create start and end nodes
                    if (!compEnd[compSrcEnd]++) {
                        print compSrcEnd "\tcCompEnd\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" > srcNodeFile; 
                        print compSrcEnd "\tcCompEnd\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" > allNode;
                    }
                    if (!compStart[compDstStart]++) {
                        print compDstStart "\tcCompStart\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" > dstNodeFile; 
                        print compDstStart "\tcCompStart\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" > allNode;
                    }

                    # Create `compCall` edge + CFG linkages (only need to be in all component file)
                    if (!compWrite[compSrcEnd compDstStart]++) {
                        print compSrcEnd "\t" compDstStart "\tcompWrite\t\t\t\t\t" > allEdge;
                        print compSrcEnd "\t" srcCFG "\tcompWriteSource\t\t\t\t\t" > allEdge;
                        print compDstStart "\t" dstCFG "\tcompWriteDestination\t\t\t\t\t" > allEdge;
                    }

                    # Create `varWriteOut` and `varWriteIn` edge + CFG linkages
                    if (!varWriteOut[variable1 compSrcEnd]++) {
                        print variable1 "\t" compSrcEnd "\tvarWriteOut\t\t\t\t\t" > srcEdgeFile;
                        print variable1 "\t" compSrcEnd "\tvarWriteOut\t\t\t\t\t" > allEdge; 

                        # Link to src CFG
                        #print variable1 "\t" srcCFG "\tvarWriteOutSource\t\t\t\t\t" > srcEdgeFile;
                        #print variable1 "\t" srcCFG "\tvarWriteOutSource\t\t\t\t\t" > allEdge;
                        #print compSrcEnd "\t" srcCFG "\tvarWriteOutDestination\t\t\t\t\t" > srcEdgeFile;
                        #print compSrcEnd "\t" srcCFG "\tvarWriteOutDestination\t\t\t\t\t" > allEdge; 
                    }
                    if (!varWriteIn[compDstStart variable2]++) {
                        print compDstStart "\t" variable2 "\tvarWriteIn\t\t\t\t\t" > dstEdgeFile;
                        print compDstStart "\t" variable2 "\tvarWriteIn\t\t\t\t\t" > allEdge;

                        # Link to dst CFG
                        #print compDstStart "\t" dstCFG "\tvarWriteInSource\t\t\t\t\t" > dstEdgeFile;
                        #print compDstStart "\t" dstCFG "\tvarWriteInSource\t\t\t\t\t" > allEdge;
                        #print variable2 "\t" dstCFG "\tvarWriteInDestination\t\t\t\t\t" > dstEdgeFile;
                        #print variable2 "\t" dstCFG "\tvarWriteInDestination\t\t\t\t\t" > allEdge;
                    }
                }
            }
        }
    }

}' ${divisionPath} ${cfgNodePath} ${cfgEdgePathSorted}
          