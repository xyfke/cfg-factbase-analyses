MATCH path=()-[:pubVar]->(:rosTopic)-[:pubTarget]->(:cVariable)
RETURN DISTINCT path ORDER BY length(path) DESC;