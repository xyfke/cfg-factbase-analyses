MATCH (:rosTopic)-[sub:subscribe]->(:rosSubscriber)
MATCH (:rosPublisher)-[pub:publish]->(:rosTopic)
WITH *, apoc.cfgPath.rosFindPaths(sub, {
    relSeq : "call+",
    filter : "cFunction,rosPublisher",
    endE : pub,
    config : [
        {name : "call", startLabel : "cFunction", endLabel : "cFunction",
        attribute : "cfgInvoke", length : "1"}
    ]
}) As paths
UNWIND paths As path
RETURN DISTINCT path;