MATCH path=(a)-[:pubVar]->(:rosTopic)-[:pubTarget]-(b)
WHERE a.compName = b.compName
RETURN DISTINCT path ORDER BY length(path) DESC;