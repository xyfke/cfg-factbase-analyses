MATCH (:rosTopic)-[pt:pubTarget]->(:cVariable)
MATCH (:cVariable)-[pv:pubVar]->(:rosTopic)
WITH *, apoc.cfgPath.rosFindPaths(pt, {
    relSequence : "varWrite|parWrite|retWrite*",
    endEdge : pv,
    cfgCheck : false,
    nodeFilter : "cVariable,cReturn",
    allShortestPath : true,
    backward : true
}) As paths
UNWIND paths As path
RETURN DISTINCT path;