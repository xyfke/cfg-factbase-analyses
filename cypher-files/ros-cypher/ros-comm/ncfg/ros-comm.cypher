MATCH path=(a)-[:pubVar]->(t:rosTopic)-[:pubTarget]->(c)
WHERE a.compName = c.compName AND a.filename <> c.filename
RETURN path;