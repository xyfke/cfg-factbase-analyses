MATCH pubVarPath = (a)-[:pubVar]->(startPubTopic:rosTopic)
MATCH pubTargetPath = (endSubTopic:rosTopic)-[:pubTarget]->(b:cVariable) 
MATCH df=(startPubTopic)-[:dataflow*1..]->(endSubTopic) 
UNWIND relationships(df) As r
WITH pubVarPath, pubTargetPath, a, b, df, COLLECT(DISTINCT r.compName) As compNames
WHERE size(compNames) = length(df) AND (NOT a.compName IN compNames) 
    AND (NOT b.compName IN compNames) 
RETURN DISTINCT apoc.path.combine(apoc.path.combine(pubVarPath, df), pubTargetPath) As path 
ORDER BY length(path) DESC;