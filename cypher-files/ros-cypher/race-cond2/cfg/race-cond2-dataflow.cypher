MATCH path1 = (a)-[:pubVar]->(t1:rosTopic)-[:dataflow]->(c:cVariable)
MATCH path2 = (b)-[:pubVar]->(t2:rosTopic)-[:dataflow]->(c)
WHERE a <> b AND t1 <> t2
RETURN [path1, path2] As path;