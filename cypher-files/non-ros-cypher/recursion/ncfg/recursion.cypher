MATCH (a:cFunction)
WITH *, apoc.cfgPath.rosFindPaths(a, {
    relSeq : "call*",
    endNode : a,
    cfg : false
}) As paths
UNWIND paths As path
RETURN DISTINCT path ORDER BY length(path) DESC;