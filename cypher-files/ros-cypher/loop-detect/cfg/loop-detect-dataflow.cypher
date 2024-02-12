MATCH path = (a:cVariable)-[:pubVar]->(startPubTopic:rosTopic)-[:dataflow*0..]->(endSubTopic:rosTopic)-[:pubTarget]->(b:cVariable)
WHERE a.compName = b.compName
RETURN DISTINCT path ORDER BY length(path) DESC;