MATCH (:cCompStart)-[pt:varWriteIn|parWriteIn|retWriteIn]->()
MATCH ()-[vif:varInfFunc]->(:cFunction)
WITH *, apoc.cfgPath.rosFindPaths(pt, {
    relSequence : "varWrite|parWrite|retWrite*",
    endEdge : vif,
    cfgCheck : false,
    nodeFilter : "cVariable,cReturn",
    allShortestPath : true
}) As paths
UNWIND paths As path
RETURN DISTINCT path;