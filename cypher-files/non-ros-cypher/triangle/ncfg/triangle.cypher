MATCH (a:cVariable)
WITH *, apoc.cfgPath.rosFindPaths(a, {
    endNode : a,
    relSeq : "varWrite|parWrite,varWrite|parWrite,varWrite|parWrite",
    cfg : false
}) As paths
UNWIND paths As path
RETURN DISTINCT path;