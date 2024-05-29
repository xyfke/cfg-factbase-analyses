#!/bin/bash

echo "Enter fact folder path: "
read factFolderPath

echo "Enter component division csv: "
read divisionPath

echo "${factFolderPath}"

#divisionPath="${factFolderPath}/division.csv"

cfgNodeFact="${factFolderPath}/cfg/nodes.csv"
cfgCompNodeFact="${factFolderPath}/cfg/allNodes.csv"

ncfgNodeFact="${factFolderPath}/ncfg/nodes.csv"
ncfgCompNodeFact="${factFolderPath}/ncfg/allNodes.csv"

echo "Start appending component names to cfg nodes"
#gawk -v packageCol=${pkgCol} '{
gawk -v location=${cfgCompNodeFact} -v nodesPath="${cfgNodeFact}" -v divisionPath="${divisionPath}" '{
    # Create dicitonary mapping filename to components
    if (FILENAME == divisionPath && FNR >= 1) {
        FS = ","; 
        gsub(/\015/, "", $2);
        if ($2 != "") {
            division[$2] = $1;
        }
    } 
    else if (FILENAME == nodesPath && FNR == 1) {FS=OFS="\t"; header = $0 OFS "compName"; 
        print header > (location);}
    else if (FILENAME == nodesPath && FNR > 1) {
        #n = split($13, fileArray, "/");
        for (x in division) {
            if (index($13, x) != 0) { 
                compName = division[x];
            }
        }
        #compName = fileArray[packageCol];
        print $0 OFS compName > (location);
    }
}' "${divisionPath}" "${cfgNodeFact}"
echo "Finish appending component names to cfg nodes"


echo "Start appending component names to ncfg nodes"
gawk -v location=${ncfgCompNodeFact} -v nodesPath="${ncfgNodeFact}" -v divisionPath="${divisionPath}"  '{
    # Create dicitonary mapping filename to components
    if (FILENAME == divisionPath && FNR >= 1) {
        FS = ","; 
        gsub(/\015/, "", $2);
        if ($2 != "") {
            division[$2] = $1;
        }
    } 
    else if (FILENAME == nodesPath && FNR == 1) {FS=OFS="\t"; header = $0 OFS "compName"; print header > (location); }
    else if (FILENAME == nodesPath && FNR > 1) {
        #n = split($13, fileArray, "/");
        for (x in division) {
            if (index($13, x) != 0) {
                compName = division[x];
            }
        }
        #compName = fileArray[packageCol];
        print $0 OFS compName > (location);
    }
}' "${divisionPath}" "${ncfgNodeFact}"
echo "Finish appending component names to ncfg nodes"
