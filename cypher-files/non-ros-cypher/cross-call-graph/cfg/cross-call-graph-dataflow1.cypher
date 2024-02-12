MATCH path= (:cCompEnd)-[:compCall|dataflow*3..]->(:cCompStart) 
RETURN DISTINCT path ORDER BY length(path) DESC;