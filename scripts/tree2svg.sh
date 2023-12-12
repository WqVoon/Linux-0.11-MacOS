#!/bin/bash
#
# tree2svg -- Generate the graph for a tree
#

# Tree2Dot
tree2dotx=scripts/tree2dotx

tree2dotx | dot -Tsvg -o out/tree.svg

ls out/tree.svg
