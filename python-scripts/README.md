# Python Scripts

There are several scripts that we use to perform the analyses. This directory contains python script for phase analyses and also script for running the analyses all at once.

These python scripts are also used to record query results in text files and performance results when running each query.

## Phase Query

The following script divides the analyses into two phases, and we perform each query, combine them and report the results.

General user inputs:
- software name (string)
- cypher type (string)
- cypher name (string)

### `phase1.py`

The phase 1 script runs queries on a component-based level. Usually, there are three cypher queries that it runs: the prefix, the intra-dataflow, and the suffix.

Other user inputs:
- contains prefix and suffix? (y/n)

### `phase2.py`

The phase 2 script runs queries on a full-system level. It creates new summary link facts into the full system factbase, and then runs another query to track these summary links and reports the results.

Other user inputs:
- Enter minimum middle components? (default is empty)
- Multiple reported paths (y/n)
- Enter date (default: today)
- Enter phase number (default: 2)

### `combinePath.py`

The combine path script combines results from phase 1 (the prefix and suffix) and phase 2 to create the overall results. 

Other user inputs:
- Enter minimum middle components? (default is empty)
- Enter date (default: today)

## Single Phase Query

### `query-script.py`

This script loads the full factbase, and runs the corresponding query and reports the results.

User input:
- software name (string)
- cypher type (string)
- cypher name (string)
- check CFG? (boolean)
- Multiple reported paths (y/n)

## script-json
Default settings for each software.

## Queries

The Query files are located one level above under non-ros-cypher and ros-cypher.

| Query Name | ROS Directory | Non-ROS Directory | Analysis Type | Has Prefix/Suffix? | Multiple Paths? |
| -------- | ------- |------- |------- | ------- | ------- |
| Intercomponent-Based Communication | ros-cypher/inter-comm | - | Two-Phased | No | No |
| Loop Detection | ros-cypher/loop-detect | - | Two-Phased | No | No |
| Multiple Publishers  | ros-cypher/multi-pub | - | Single Query | - | Yes |
| Race Condition | ros-cypher/race-cond | - | Single Query | - | Yes |
| Behaviour Alteration | ros-cypher/beh-alt | - | Two-Phased | Yes | No |
| Publisher Alteration | ros-cypher/pub-alt | - | Two-Phased | Yes | No |
| Intra-Component Call Graph | - | non-ros-cypher/call-graph | Single Query | Yes | No |
| Inter-Component Call Graph | ros-cypher/call-graph | non-ros-cypher/cross-call-graph | Two-Phased | Yes | No |
| Recursion | - | non-ros-cypher/recursion | Single Query | - | No |
| Triangle | - | non-ros-cypher/triangle | Single Query | - | No |