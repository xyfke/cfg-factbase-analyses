MATCH p1=(cE:cCompEnd)-[compEdge:compCall|compWrite|compReturn]->(cS:cCompStart)
WITH *, apoc.cfgPath.rosFindPaths(compEdge, {
    relSequence : "dataflow,compCall|compWrite|compReturn",
    nodeFilter : "cCompStart,cCompEnd",
    cfgCheck : false,
    repeat : true,
    isStartEdgeValid : true
}) As paths
UNWIND paths As path
RETURN DISTINCT path ORDER BY length(path) DESC;