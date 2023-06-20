#!/bin/bash
########################################################################
## Useful simple error redirection functions
########################################################################

function caterr { cat "$@" >&2; }
function echoerr { echo "$@" >&2; }
