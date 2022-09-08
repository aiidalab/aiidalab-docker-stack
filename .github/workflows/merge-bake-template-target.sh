#!/bin/bash
set -e

input=$(cat; echo x)
input=${input%x}   # Strip the trailing x

# Determine the targets.
TARGETS=$(docker buildx bake --print | jq -cr '.group.default.targets' | jq -r '.[]')

# Generate the meta JSON strings
meta=""
for target in $TARGETS; do
  meta="${meta} ${input//__template__/${target}}"
done

# Combine into merged bake file.
echo $meta | jq -s 'reduce .[] as $x ({}; . * $x)'

#| docker buildx bake -f docker-bake.hcl -f - --print
