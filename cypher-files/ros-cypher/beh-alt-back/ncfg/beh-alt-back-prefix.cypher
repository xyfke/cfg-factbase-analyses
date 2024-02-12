MATCH (:cVariable)-[vw:varWrite]->(:cVariable)
MATCH (:cVariable)-[pv:pubVar]->(:rosTopic)
WITH *, apoc.cfgPath.rosFindPaths(vw, {
    relSequence : "varWrite|parWrite|retWrite*",
    endEdge : pv,
    cfgCheck : false,
    nodeFilter : "cVariable,cReturn",
    allShortestPath : true,
    backward : true
}) As paths
UNWIND paths As path
RETURN DISTINCT path;