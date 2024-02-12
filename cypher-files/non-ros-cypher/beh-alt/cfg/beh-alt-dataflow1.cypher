MATCH path = (:cCompEnd)-[:dataflow|compCall|compWrite|compReturn*3..]->(:cCompStart) 
RETURN DISTINCT path ORDER BY length(path) DESC;