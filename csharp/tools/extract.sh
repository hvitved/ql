#!/bin/sh

set -eu

if [ "$CODEQL_PLATFORM" != "linux64" ] && [ "$CODEQL_PLATFORM" != "osx64" ] ; then
    echo "Extraction for $CODEQL_PLATFORM is not implemented."
    exit 1
fi

# Disable the CLR tracer for the extractor
COR_ENABLE_PROFILING=0 CORECLR_ENABLE_PROFILING=0 "$CODEQL_EXTRACTOR_CSHARP_ROOT/tools/$CODEQL_PLATFORM/Semmle.Extraction.CSharp.Driver" "$@" || exit $?
