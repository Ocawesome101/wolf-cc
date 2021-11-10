#!/bin/bash
# convert PNG textures into TEX files

set -e

for tex in $(ls *.png); do
  tex=${tex:0:-4}
  echo Converting $tex
  stream -map rgb $tex.png - | lua raw2tex.lua > ../textures/$tex.tex
done
