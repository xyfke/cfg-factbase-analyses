MATCH (:rosTopic)-[pt:pubTarget]->(:cVariable)
MATCH (b:cVariable)
WITH *, apoc.cfgPath.rosFindPaths(pt, {
    relSequence : "varWrite|parWrite|retWrite*",
    endNode : b,
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
}) As results
UNWIND results As p
WITH b, COLLECT(p) As path
WHERE size(path) > 1
RETURN DISTINCT path;