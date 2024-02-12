MATCH (:rosTopic)-[sub:subscribe]->(:rosSubscriber)
MATCH (:rosPublisher)-[pub:publish]->(:rosTopic)
WITH *, apoc.cfgPath.rosFindPaths(sub, {
    relSequence : "call+",
    nodeFilter : "cFunction,rosPublisher",
    endEdge : pub,
    cfgConfiguration : [
        {name : "call", startLabel : "cFunction", endLabel : "cFunction",
        attribute : "cfgInvoke", length : "1"}
    ]
}) As paths
UNWIND paths As path
RETURN DISTINCT path;