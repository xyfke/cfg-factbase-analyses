MATCH (:rosTopic)-[pt:pubTarget]->(:cVariable)
MATCH ()-[vif:varInfluence]->(:rosPublisher)
WITH *, apoc.cfgPath.rosFindPaths(pt, {
    relSequence : "varWrite|parWrite|retWrite*",
    endEdge : vif,
    nodeFilter : "cVariable,cReturn",
    allShortestPath : true,
    cfgConfiguration : [
        {name : "parWrite", startLabel : "cReturn", endLabel : "cVariable",
        attribute : "cfgReturn,cfgInvoke", length : "2"}, 
        {name : "parWrite", startLabel : "cVariable", endLabel : "cVariable",
        attribute : "cfgInvoke", length : "1"}, 
        {name : "retWrite", startLabel : "cReturn", endLabel : "cVariable",
        attribute : "cfgReturn", length : "1"}, 
        {name : "retWrite", startLabel : "cReturn", endLabel : "cReturn",
        attribute : "cfgReturn", length : "1"},
        {name : "varInfluence", startLabel : "cVariable", endLabel : "rosPublisher",
        length : "+"},
        {name : "varInfluence", startLabel : "cReturn", endLabel : "rosPublisher",
        length : "+"}
    ]
}) As paths
UNWIND paths As path
RETURN path;