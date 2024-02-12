MATCH (a:cFunction)
MATCH (:rosPublisher)-[pub:publish]->(:rosTopic)
WITH *, apoc.cfgPath.rosFindPaths(a, {
    relSequence : "call+",
    nodeFilter : "cFunction,rosPublisher",
    cfgCheck : false,
    endEdge : pub,
    cfgConfiguration : [
        {name : "call", startLabel : "cFunction", endLabel : "cFunction",
        attribute : "cfgInvoke", length : "1"}
    ]
}) As paths
UNWIND paths As path
RETURN DISTINCT path;