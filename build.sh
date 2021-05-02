#!/bin/bash

# https://dlang.org/download.html
source ~/dlang/dmd-2.095.0/activate

rm sponskrub
dub build --yes --force --build release :sponskrub

deactivate
