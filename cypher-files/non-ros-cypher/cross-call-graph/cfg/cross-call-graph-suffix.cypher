MATCH (cs:cCompStart)
WITH *, apoc.cfgPath.rosFindPaths(cs, {
    relSequence : "callIn,call*",
    nodeFilter : "cFunction,cCompStart",
    cfgCheck : true,
    cfgConfiguration : [
        {name : "call", startLabel : "cFunction", endLabel : "cFunction",
        attribute : "cfgInvoke", length : "1"}
    ]
}) As paths
UNWIND paths As path
RETURN DISTINCT path;