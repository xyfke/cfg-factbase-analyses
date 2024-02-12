MATCH (a:cFunction)
WITH *, apoc.path.cfgValidatedPath(a, {
    relSequence : "call*",
    cfgConfiguration : [{
        name : "call",
        startLabel : "cFunction",
        endLabel : "cFunction",
        attribute : "cfgInvoke",
        length : "1"
    }]
}) As paths
UNWIND paths As path
RETURN DISTINCT path ORDER BY length(path) DESC;