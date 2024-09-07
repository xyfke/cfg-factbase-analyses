MATCH (:rosTopic)-[pt:pubTarget]->(:cVariable)
MATCH ()-[vif:varInfluence]->(:rosPublisher)
WITH *, apoc.cfgPath.rosFindPaths(pt, {
    relSeq : "varWrite|parWrite|retWrite*",
    endE : vif,
    filter : "cVariable,cReturn",
    shortest : true,
    checkLine : true,
    config : [
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