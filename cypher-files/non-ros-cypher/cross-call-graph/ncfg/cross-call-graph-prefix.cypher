MATCH (a:cFunction)
WHERE a.id CONTAINS "main"
WITH *, apoc.cfgPath.rosFindPaths(a, {
    relSequence : "call*,callOut",
    nodeFilter : "cFunction,cCompEnd",
    cfgCheck : false
}) As paths
UNWIND paths As path
RETURN DISTINCT path;