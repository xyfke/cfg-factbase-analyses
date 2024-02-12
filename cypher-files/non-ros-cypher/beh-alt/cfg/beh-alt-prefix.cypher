MATCH (:cVariable)-[vw:varWrite]->(:cVariable)
MATCH ()-[pv:varWriteOut|parWriteOut|retWriteOut]->(:cCompEnd)
WITH *, apoc.cfgPath.rosFindPaths(vw, {
    relSequence : "varWrite|parWrite|retWrite*",
    nodeFilter : "cVariable,cReturn",
    endEdge : pv,
    allShortestPath : true,
    cfgConfiguration : [
        {name : "parWrite", startLabel : "cReturn", endLabel : "cVariable",
        attribute : "cfgReturn,cfgInvoke", length : "2"}, 
        {name : "parWrite", startLabel : "cVariable", endLabel : "cVariable",
        attribute : "cfgInvoke", length : "1"}, 
        {name : "retWrite", startLabel : "cReturn", endLabel : "cVariable",
        attribute : "cfgReturn", length : "1"}, 
        {name : "retWrite", startLabel : "cReturn", endLabel : "cReturn",
        attribute : "cfgReturn", length : "1"}
    ]
}) As paths
UNWIND paths As path
RETURN DISTINCT path;