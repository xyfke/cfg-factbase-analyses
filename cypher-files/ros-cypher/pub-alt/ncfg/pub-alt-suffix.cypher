MATCH (:rosTopic)-[pt:pubTarget]->(:cVariable)
MATCH ()-[vi:varInfluence]->(:rosPublisher)
WITH *, apoc.cfgPath.rosFindPaths(pt, {
    relSeq : "varWrite|parWrite|retWrite*",
    endE : vi,
    filter : "cVariable,cReturn",
    cfg : false,
    shortest : true
}) As paths
UNWIND paths As path
RETURN DISTINCT path;