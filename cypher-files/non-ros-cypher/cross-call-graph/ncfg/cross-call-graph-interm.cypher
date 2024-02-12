MATCH (cs:cCompStart)
WITH *, apoc.cfgPath.rosFindPaths(cs, {
    relSequence : "callIn,call*,callOut",
    nodeFilter : "cFunction,cCompEnd",
    cfgCheck : false
}) As paths
UNWIND paths As path
RETURN DISTINCT path;