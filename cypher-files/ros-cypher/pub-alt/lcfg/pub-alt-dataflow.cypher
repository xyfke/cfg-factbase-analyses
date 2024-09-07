MATCH path= (startPubTopic:rosTopic)-[:dataflow*0..]->(endSubTopic:rosTopic) 
RETURN DISTINCT path ORDER BY length(path) DESC;