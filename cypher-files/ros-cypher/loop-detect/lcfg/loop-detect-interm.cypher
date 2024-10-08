MATCH (:rosTopic)-[pt:pubTarget]->(:cVariable)
MATCH (b:cVariable)-[pv:pubVar]->(:rosTopic)
WITH *, apoc.cfgPath.rosFindPaths(pt, {
    relSeq : "varWrite|parWrite|retWrite*",
    endE : pv,
    shortest : true,
    filter : "cVariable,cReturn",
    checkLine : true,
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