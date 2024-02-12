MATCH (:cCompStart)-[pt:varWriteIn|parWriteIn|retWriteIn]->()
MATCH ()-[pv:varWriteOut|parWriteOut|retWriteOut]->(:cCompEnd)
WITH *, apoc.cfgPath.rosFindPaths(pt, {
    relSequence : "varWrite|parWrite|retWrite*",
    endEdge : pv,
    cfgCheck : false,
    nodeFilter : "cVariable,cReturn",
    allShortestPath : true
}) As paths
UNWIND paths As path
RETURN DISTINCT path;