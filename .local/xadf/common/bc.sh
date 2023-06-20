#!/bin/bash
########################################################################
## Do some calculation with bc
########################################################################
function bcalc {
bc -lq $@
}

## This function loads xbc extensions first
function bcxt {
bc -lq ~/.local/share/bc/extensions.bc $@
}

## This function loads xbc extensions and xbc
## scientific constants
function bcsc {
bc -lq ~/.local/share/bc/extensions.bc ~/.local/share/bc/scientific_constants.bc $@
}
