// the non-dataflow portion of the suffix path
MATCH suffixPubTarget=(endSubTopic:rosTopic)-[pt:pubTarget]->(c:cVariable)
MATCH suffixVarInfFunc=()-[vif:varInfFunc]->(f:cFunction)

// the dataflow portion of the suffix path 
WITH *, apoc.path.allDataflowPathsV2(null, null, pt, vif, false) As suffixDataflows
WHERE suffixDataflows is not null and size(suffixDataflows) > 0

// return entire suffixPath by length in descending order
UNWIND suffixDataflows As sdf
RETURN DISTINCT sdf As path
ORDER BY length(path) DESC;