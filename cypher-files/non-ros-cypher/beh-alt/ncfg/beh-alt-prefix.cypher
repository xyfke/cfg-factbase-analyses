MATCH (:cVariable)-[vw:varWrite]->(:cVariable)
MATCH ()-[pv:varWriteOut|parWriteOut|retWriteOut]->(:cCompEnd)
WITH *, apoc.cfgPath.rosFindPaths(vw, {
    relSeq : "varWrite|parWrite|retWrite*",
    endE : pv,
    cfg : false,
    filter : "cVariable,cReturn",
    shortest : true
}) As paths
UNWIND paths As path
RETURN DISTINCT path;