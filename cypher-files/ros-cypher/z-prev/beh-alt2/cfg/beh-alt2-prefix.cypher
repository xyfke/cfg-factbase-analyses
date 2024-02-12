// the non-dataflow portion of the prefix path
MATCH (a:cVariable)-[r:varWrite]->(b:cVariable)
MATCH prefixPubVar=(c:cVariable)-[pv:pubVar]->(pubTopic:rosTopic)

// the dataflow portion of the prefix path and perform CFG check
WITH *, apoc.path.allDataflowPathsV2(null, null, r, pv, true) As prefixDataflows
WHERE prefixDataflows is not null and size(prefixDataflows) > 0

// return the whole prefix path in descending order by lengths
UNWIND prefixDataflows As pdf
RETURN DISTINCT pdf As path
ORDER BY length(path) DESC;