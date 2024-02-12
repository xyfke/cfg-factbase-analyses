MATCH path = ()-[:pubVar]->(startPubTopic:rosTopic)-[:dataflow*1..]->(endSubTopic:rosTopic)-[:pubTarget]->(:cVariable) 
RETURN DISTINCT path ORDER BY length(path) DESC;