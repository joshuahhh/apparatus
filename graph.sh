#!/bin/bash

madge --dot src --exclude ".*node_modules.*|View/.*|Util/.*|index" > graph.gv
dot graph.gv -Tpng > graph.png
