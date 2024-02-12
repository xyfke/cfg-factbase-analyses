MATCH (a:cFunction)
CALL apoc.path.expandConfig(a, {
    relationshipFilter: 'call>',
    labelFilter: 'cFunction',
    minLevel: 1
}) YIELD path
RETURN path;