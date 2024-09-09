#!/usr/bin/env bash

die() {
    echo >&2 "$1"
    exit "${2:1}"
}

_trace="false"
_leaks="false"

POSITIONAL=()
while (($# > 0)); do
    case "${1}" in
    -t | --trace)
        _trace="true"
        shift
        ;;
    -l | --leaks)
        _leaks="true"
        shift
        ;;
    *) # unknown flag/switch
        POSITIONAL+=("${1}")
        shift
        ;;
    esac
done

set -- "${POSITIONAL[@]}" # restore positional params

if ! [ "$(command -v odin)" ]; then
    die "Odin is not installed. Please install Odin first." 1
fi

# Validate that building with "-vet -define:leaks=true -define:trace=true" we don't have build errors
odin build . -vet -define:leaks=true -define:trace=true || die "Build failed" 1

# Build with or without our debug options
odin build . -define:leaks="${_leaks}" -define:trace="${_trace}" || die "Build failed" 1
