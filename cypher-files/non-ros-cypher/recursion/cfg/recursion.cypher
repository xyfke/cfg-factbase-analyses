MATCH (a:cFunction)
WITH *, apoc.cfgPath.rosFindPaths(a, {
    relSeq : "call*",
    endNode : a,
    config : [{
        name : "call",
        startLabel : "cFunction",
        endLabel : "cFunction",
        attribute : "cfgInvoke",
        length : "1"
    }]
}) As paths
UNWIND paths As path
RETURN DISTINCT path ORDER BY length(path) DESC;