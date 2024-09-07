MATCH path= (startPubTopic:rosTopic)-[:callflow*1..]->(endSubTopic:rosTopic)
RETURN DISTINCT path ORDER BY length(path) DESC;