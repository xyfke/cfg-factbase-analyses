MATCH (:cCompStart)-[pt:varWriteIn|parWriteIn|retWriteIn]->()
MATCH ()-[vif:varInfFunc]->(:cFunction)
WITH *, apoc.cfgPath.rosFindPaths(pt, {
    relSeq : "varWrite|parWrite|retWrite*",
    endE : vif,
    cfg : false,
    filter : "cVariable,cReturn",
    shortest : true
}) As paths
UNWIND paths As path
RETURN DISTINCT path;