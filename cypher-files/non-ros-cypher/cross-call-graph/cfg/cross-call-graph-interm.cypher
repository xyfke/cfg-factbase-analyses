MATCH (cs:cCompStart)
WITH *, apoc.cfgPath.rosFindPaths(cs, {
    relSequence : "callIn,call*,callOut",
    nodeFilter : "cFunction,cCompEnd",
    cfgConfiguration : [
        {name : "call", startLabel : "cFunction", endLabel : "cFunction",
        attribute : "cfgInvoke", length : "1"}
    ]
}) As paths
UNWIND paths As path
RETURN DISTINCT path;