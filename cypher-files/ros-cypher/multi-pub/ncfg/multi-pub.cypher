MATCH path1=(a)-[:pubVar]->(t:rosTopic)-[:pubTarget]->(c)
MATCH path2=(b)-[:pubVar]->(t)-[:pubTarget]->(c)
WHERE a <> b AND a.compName <> b.compName
RETURN [path1, path2] As path;