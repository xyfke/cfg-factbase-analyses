MATCH (:rosTopic)-[sub:subscribe]->(:rosSubscriber)
WITH *, apoc.cfgPath.rosFindPaths(sub, {
    relSequence : "call+",
    cfgCheck : false,
    nodeFilter : "cFunction,rosSubscriber",
    cfgConfiguration : [
        {name : "call", startLabel : "cFunction", endLabel : "cFunction",
        attribute : "cfgInvoke", length : "1"}
    ]
}) As paths
UNWIND paths As path
RETURN DISTINCT path;