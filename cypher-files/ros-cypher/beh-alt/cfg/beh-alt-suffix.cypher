MATCH (:rosTopic)-[pt:pubTarget]->(:cVariable)
MATCH ()-[vif:varInfFunc]->(:cFunction)
WITH *, apoc.cfgPath.rosFindPaths(pt, {
    relSequence : "varWrite|parWrite|retWrite*",
    nodeFilter : "cVariable,cReturn",
    endEdge : vif,
    allShortestPath : true,
    cfgConfiguration : [
        {name : "parWrite", startLabel : "cReturn", endLabel : "cVariable",
        attribute : "cfgReturn,cfgInvoke", length : "2"}, 
        {name : "parWrite", startLabel : "cVariable", endLabel : "cVariable",
        attribute : "cfgInvoke", length : "1"}, 
        {name : "retWrite", startLabel : "cReturn", endLabel : "cVariable",
        attribute : "cfgReturn", length : "1"}, 
        {name : "retWrite", startLabel : "cReturn", endLabel : "cReturn",
        attribute : "cfgReturn", length : "1"},
        {name : "varInfFunc", startLabel : "cVariable", endLabel : "cFunction",
        length : "+"},
        {name : "varInfFunc", startLabel : "cReturn", endLabel : "cFunction",
        length : "+"}
    ]
}) As paths
UNWIND paths As path
RETURN DISTINCT path;