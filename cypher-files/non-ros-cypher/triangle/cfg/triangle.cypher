MATCH (a:cVariable)
WITH *, apoc.cfgPath.rosFindPaths(a, {
    endN : a,
    relSeq : "varWrite|parWrite,varWrite|parWrite,varWrite|parWrite",
    config : [
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