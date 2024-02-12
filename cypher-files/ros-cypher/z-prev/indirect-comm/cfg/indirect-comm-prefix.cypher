MATCH path=(:cVariable)-[pv:pubVar]->(:rosTopic)
RETURN DISTINCT path ORDER BY length(path) DESC;