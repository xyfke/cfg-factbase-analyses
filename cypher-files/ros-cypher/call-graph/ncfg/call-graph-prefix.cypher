MATCH (a:cFunction)
MATCH (:rosPublisher)-[pub:publish]->(:rosTopic)
WITH *, apoc.cfgPath.rosFindPaths(a, {
    relSeq : "call+",
    filter : "cFunction,rosPublisher",
    cfg : false,
    endE : pub
}) As paths
UNWIND paths As path
RETURN DISTINCT path;