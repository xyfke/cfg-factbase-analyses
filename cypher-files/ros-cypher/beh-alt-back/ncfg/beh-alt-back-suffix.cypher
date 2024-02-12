MATCH (:rosTopic)-[pt:pubTarget]->(:cVariable)
MATCH ()-[vif:varInfFunc]->(:cFunction)
WITH *, apoc.cfgPath.rosFindPaths(pt, {
    relSequence : "varWrite|parWrite|retWrite*",
    endEdge : vif,
    cfgCheck : false,
    nodeFilter : "cVariable,cReturn",
    allShortestPath : true,
    backward : true
}) As paths
UNWIND paths As path
RETURN DISTINCT path;