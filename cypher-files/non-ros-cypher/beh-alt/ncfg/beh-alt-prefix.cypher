MATCH (:cVariable)-[vw:varWrite]->(:cVariable)
MATCH ()-[pv:varWriteOut|parWriteOut|retWriteOut]->(:cCompEnd)
WITH *, apoc.cfgPath.rosFindPaths(vw, {
    relSequence : "varWrite|parWrite|retWrite*",
    endEdge : pv,
    cfgCheck : false,
    nodeFilter : "cVariable,cReturn",
    allShortestPath : true
}) As paths
UNWIND paths As path
RETURN DISTINCT path;