scriptpath="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
projectpath="${scriptpath}/../../"
projectpathreal="$(realpath "$projectpath")"

echo "${scriptpath}"
echo "${projectpathreal}/neo4j-instance/"
echo "${projectpathreal}/neo4j-output/"
