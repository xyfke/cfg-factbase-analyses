MATCH path= (startPubTopic:rosTopic)-[:callflow*0..]->(endSubTopic:rosTopic) 
RETURN DISTINCT path ORDER BY length(path) DESC;