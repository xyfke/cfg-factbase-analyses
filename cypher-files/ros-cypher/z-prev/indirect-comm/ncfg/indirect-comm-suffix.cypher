MATCH path=(:rosTopic)-[pt:pubTarget]->(:cVariable)
RETURN DISTINCT path ORDER BY length(path) DESC;