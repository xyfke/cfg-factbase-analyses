MATCH path = (a)-[:pubVar]->(startPubTopic:rosTopic)-[:dataflow*1..]->(endSubTopic:rosTopic)-[:pubTarget]->(b:cVariable) 
WHERE a.compName <> b.compName
RETURN DISTINCT path ORDER BY length(path) DESC;