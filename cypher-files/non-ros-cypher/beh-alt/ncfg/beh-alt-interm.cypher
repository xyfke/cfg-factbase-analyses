MATCH (:cCompStart)-[pt:varWriteIn|parWriteIn|retWriteIn]->()
MATCH ()-[pv:varWriteOut|parWriteOut|retWriteOut]->(:cCompEnd)
WITH *, apoc.cfgPath.rosFindPaths(pt, {
    relSeq : "varWrite|parWrite|retWrite*",
    endE : pv,
    cfg : false,
    filter : "cVariable,cReturn",
    shortest : true
}) As paths
UNWIND paths As path
RETURN DISTINCT path;