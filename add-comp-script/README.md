# Scripts For Differentiating Components

These scripts each either add component name as an attribute to existing facts or splits the factbase into different components.

## `splitComp.sh`

This is the script that is used to split Non-ROS factbases into components. In this script, we also create temporary nodes to clarify component boundaries in each component factbase. (This is one way of speeding up the searching process)

<b>THIS IS THE SCRIPT YOU WANT TO FOCUS ON</b>

Inputs:
- `factbase path`
- `division path`

## `addComp.sh`

This script takes a factbase path and inside each node csv file, assign a component name to each node fact, and create new node files with this new attribute. Filename (attribute #13) will be used to differentiate the components

Inputs:
- `factbase path`
- `column`: the directory level inside a path, that will be used as component name (e.g. /tank/test/t-ware/compA/src/main.cpp, if we enter 4, then `compA` will be used as component name)

## `addCompCP.sh`
Instead of using a level number, we use a csv file to specify the prefixes of component, only paths matching the prefix, belongs to that specific component

Inputs:
- `factbase path`
- `division path`

