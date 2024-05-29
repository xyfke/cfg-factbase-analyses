MATCH (:rosTopic)-[pt:pubTarget]->(:cVariable)
MATCH ()-[vif:varInfFunc]->(:cFunction)
WITH *, apoc.cfgPath.rosFindPaths(pt, {
    relSeq : "varWrite|parWrite|retWrite*",
    endE : vif,
    cfg : false,
    filter : "cVariable,cReturn",
    shortest : true,
    backward : true
}) As paths
UNWIND paths As path
RETURN DISTINCT path;