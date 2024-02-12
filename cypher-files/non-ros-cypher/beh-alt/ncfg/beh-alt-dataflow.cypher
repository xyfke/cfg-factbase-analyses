MATCH path = (:cCompEnd)-[:dataflow|compCall|compWrite|compReturn*1..]->(:cCompStart) 
RETURN DISTINCT path ORDER BY length(path) DESC;