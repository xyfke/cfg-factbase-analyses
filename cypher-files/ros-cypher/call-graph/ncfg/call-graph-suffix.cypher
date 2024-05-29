MATCH (:rosTopic)-[sub:subscribe]->(:rosSubscriber)
WITH *, apoc.cfgPath.rosFindPaths(sub, {
    relSeq : "call+",
    cfg : false,
    filter : "cFunction,rosSubscriber"
}) As paths
UNWIND paths As path
RETURN DISTINCT path;