MATCH (a:cFunction)
WHERE a.id CONTAINS "main"
WITH *, apoc.cfgPath.rosFindPaths(a, {
    relSequence : "call*,callOut",
    nodeFilter : "cFunction,cCompEnd",
    cfgCheck : true,
    cfgConfiguration : [
        {name : "call", startLabel : "cFunction", endLabel : "cFunction",
        attribute : "cfgInvoke", length : "1"}
    ]
}) As paths
UNWIND paths As path
RETURN DISTINCT path;