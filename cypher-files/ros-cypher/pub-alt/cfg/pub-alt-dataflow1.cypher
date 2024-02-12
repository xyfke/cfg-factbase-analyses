MATCH path= (startPubTopic:rosTopic)-[:dataflow*1..]->(endSubTopic:rosTopic)
RETURN DISTINCT path ORDER BY length(path) DESC;