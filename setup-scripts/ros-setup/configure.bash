#!/bin/bash

# This bash scripts setups the base environment for running the python experiment scripts
# For example: software  = "test"
#   1. Creates a neo4j output direcotry: /output/neo4j-output/testOutput/
#   2. Creates a neo4j instance directory: /output/neo4j-instance/n-test/
#   3. Creates a json file with neo4j instance and factbase information: 
#           /python-scripts/script-json/test.json
#
# Assumptions:
#   1. All factbases are stored in the factbases directory inside this github project
#   2. Inside each respective software factbase folder, there is a components.csv file

read -p "Enter software name: " software
[ -z "$software" ] && echo "Need to provide a software name." && exit 0

read -p "Enter instance number: " instance
[ -z "$instance" ] && instance=""

# get project path
scriptpath="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
projectpath="${scriptpath}/../../"
projectpathreal="$(realpath "$projectpath")"
neo4jpath="$(realpath "$projectpathreal")/output"
neo4jpathP="$(realpath "$projectpathreal")"

# Find neo4j output path
neo4jFactPath="${projectpathreal}/factbases/${software}/"
if [ ! -d ${neo4jFactPath} ]; then
    echo "Invalid fact path, try re-entering date and software name again"
    exit 0
fi

# check if component exits
componentPath="${projectpathreal}/factbases/${software}/components${instance}.csv"
if [ ! -f ${componentPath} ]; then
    echo "Unable to find component file."
    echo "Make sure components.csv is located here: ${componentPath}"
    exit 0
fi

# Neo4J input variables
read -p "Heap size (default: 32G): " heapSize
read -p "Page cache (default: 30G): " cacheSize
read -p "Bolt port (default: 7687): " bolt
read -p "Http port (default: 7474): " http

# If not provided set default values
[ -z "$heapSize" ] && heapSize="32G"
[ -z "$cacheSize" ] && cacheSize="30G"
[ -z "$bolt" ] && bolt="7687"
[ -z "$http" ] && http="7474"

# Get APOC project
neo4jApocProject="${neo4jpath}/neo4j-apoc-CFG-SE"
if [ ! -d ${neo4jApocProject} ]; then
    git clone https://github.com/xyfke/neo4j-apoc-CFG-SE.git "${neo4jpath}/neo4j-apoc-CFG-SE"
fi

# Download Neo4J instance 
neo4jTar="${neo4jpath}/neo4j-community-4.4.8-unix.tar.gz"
if [ ! -f ${neo4jTar} ]; then
    wget http://www.neo4j.com/customer/download/neo4j-community-4.4.8-unix.tar.gz -P "${neo4jpath}"
fi

# tar the neo4j instance and create the file
if [ ! -d "${neo4jpath}/neo4j-instances" ]; then
    mkdir -p "${neo4jpath}/neo4j-instances"
fi

neo4jLocation="${neo4jpath}/neo4j-instances/n-${software}${instance}/"
if [ ! -d ${neo4jLocation} ]; then 
    tar xf ${neo4jTar} -C "${neo4jpath}"
    mv "${neo4jpath}/neo4j-community-4.4.8/" "${neo4jLocation}"
fi;

# copy over the configuration file
confLocation="${neo4jLocation}conf/neo4j.conf"
cp ./neo4j.conf "${confLocation}"

# Modify configuration file for Neo4J
echo "dbms.connector.bolt.listen_address=:${bolt}" >> "${confLocation}"
echo "dbms.connector.bolt.advertised_address=:${bolt}" >> "${confLocation}"
echo "dbms.connector.http.listen_address=:${http}" >> "${confLocation}"
echo "dbms.connector.http.advertised_address=:${http}" >> "${confLocation}"
echo "dbms.memory.heap.max_size=${heapSize}" >> "${confLocation}"
echo "dbms.memory.pagecache.size=${cacheSize}" >> "${confLocation}" 

# Compile the jar files and copy over
cd "${neo4jApocProject}"
git checkout fk-no-add-line
git pull
./gradlew shadow
cp "${neo4jApocProject}/core/build/libs/apoc-4.4.0.8-core.jar" "${neo4jLocation}/plugins/"

# General report of overall settings
echo ""
echo "Report of current setting: "
echo "Software: ${software}"
echo "Neo4J Instance: ${neo4jLocation}"
echo "Heap size: ${heapSize}"
echo "Page cache: ${cacheSize}"
echo "Bolt port: bolt://localhost:${bolt}"
echo "Http port: http://localhost:${http}"

neo4joutput="${neo4jpath}/neo4j-output/${software}-output/"
if [ ! -d ${neo4joutput} ]; then
    mkdir -p ${neo4joutput}
fi

jsonFilePath="${neo4jpathP}/python-scripts/script-json/${software}${instance}.json"

# make sure repo is there
if [ ! -d "${neo4jpathP}/python-scripts/script-json/" ]; then
    mkdir -p "${neo4jpathP}/python-scripts/script-json/"
fi

if [ -f ${jsonFilePath} ]; then 
    rm ${jsonFilePath}
fi

# Create json files
JSON_STRING=$( jq -n \
                  --arg neo4jpath "${neo4jLocation}" \
                  --arg output "${neo4joutput}" \
                  --arg input "${neo4joutput}" \
                  --arg factpath "${neo4jFactPath}" \
                  --arg component "${componentPath}" \
                  --arg bolt "${bolt}" \
                  '{neo4jInstancePath: $neo4jpath,
                    neo4jOutputPath: $output, 
                    neo4jInputPath: $input, 
                    neo4jFactPath : $factpath, 
                    neo4jComponentCSV : $component, 
                    neo4jBoltPort : $bolt, 
                    neo4jUsername : "neo4j", 
                    neo4jPassword : "test1234"}' ) 
echo $JSON_STRING | jq . > ${jsonFilePath}

echo ""
echo "Report of ${software}.json: "
echo $JSON_STRING | jq .

