MATCH (cs:cCompStart)
WITH *, apoc.cfgPath.rosFindPaths(cs, {
    relSequence : "callIn,call*",
    nodeFilter : "cFunction,cCompStart",
    cfgCheck : false
}) As paths
UNWIND paths As path
RETURN DISTINCT path;