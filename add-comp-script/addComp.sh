#!/bin/bash

echo "Enter fact folder path: "
read factFolderPath

echo "Enter ROS software package component column: "
read pkgCol

echo "${factFolderPath}"

cfgNodeFact="${factFolderPath}/cfg/nodes.csv"
cfgCompNodeFact="${factFolderPath}/cfg/allNodes.csv"
#cfgEdgeFact = "${factFolderPath}/cfg/edges.csv"
ncfgNodeFact="${factFolderPath}/ncfg/nodes.csv"
ncfgCompNodeFact="${factFolderPath}/ncfg/allNodes.csv"
#ncfgEdgeFact = "${factFolderPath}/ncfg/edges.csv"

echo "Start appending component names to cfg nodes"
gawk -v packageCol=${pkgCol} '{
    if (FNR == 1) {FS=OFS="\t"; header = $0 OFS "compName"; print header; }
    else {
        n = split($13, fileArray, "/");
        compName = fileArray[packageCol];
        print $0 OFS compName;
    }
}' "${cfgNodeFact}" > "${cfgCompNodeFact}"
echo "Finish appending component names to cfg nodes"


echo "Start appending component names to ncfg nodes"
gawk -v packageCol=${pkgCol} '{
    if (FNR == 1) {FS=OFS="\t"; header = $0 OFS "compName"; print header; }
    else {
        n = split($13, fileArray, "/");
        compName = fileArray[packageCol];
        print $0 OFS compName;
    }
}' "${ncfgNodeFact}" > "${ncfgCompNodeFact}"
echo "Finish appending component names to ncfg nodes"
