MATCH (:rosTopic)-[sub:subscribe]->(:rosSubscriber)
WITH *, apoc.cfgPath.rosFindPaths(sub, {
    relSequence : "call+",
    nodeFilter : "cFunction,rosSubscriber",
    cfgCheck : true,
    cfgConfiguration : [
        {name : "call", startLabel : "cFunction", endLabel : "cFunction",
        attribute : "cfgInvoke", length : "1"}
    ]
}) As paths
UNWIND paths As path
RETURN DISTINCT path;