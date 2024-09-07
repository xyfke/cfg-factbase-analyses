MATCH (:rosTopic)-[pt:pubTarget]->(:cVariable)
MATCH (b:cVariable)
WITH *, apoc.cfgPath.rosFindPaths(pt, {
    relSeq : "varWrite|parWrite|retWrite*",
    endN : b,
    shortest : true,
    filter : "cVariable,cReturn",
    cfg : false
}) As paths
UNWIND paths As path
RETURN DISTINCT path;