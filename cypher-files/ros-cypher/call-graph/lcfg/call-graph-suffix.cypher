MATCH (:rosTopic)-[sub:subscribe]->(:rosSubscriber)
WITH *, apoc.cfgPath.rosFindPaths(sub, {
    relSeq : "call+",
    filter : "cFunction,rosSubscriber",
    cfg : true,
    config : [
        {name : "call", startLabel : "cFunction", endLabel : "cFunction",
        attribute : "cfgInvoke", length : "1"}
    ]
}) As paths
UNWIND paths As path
RETURN DISTINCT path;