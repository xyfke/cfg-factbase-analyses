MATCH subPath=(subTopic:rosTopic)-[pt:pubTarget]->(a:cVariable)
MATCH pubPath=(b:cVariable)-[pv:pubVar]->(pubTopic:rosTopic)
WITH *, apoc.path.allDataflowPathsV2(null, null, pt, pv, false) As dataflowPaths
WHERE dataflowPaths is not null and size(dataflowPaths) > 0
UNWIND dataflowPaths as df
RETURN DISTINCT df As path;