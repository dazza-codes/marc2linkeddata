#!/usr/bin/env bash

# See loc_downloads.sh to get the data
# This script assumes the data are ntriples in *.nt files.

# For reference, note that there is an allegrograph ruby gem, see
# https://github.com/emk/rdf-agraph

files=$(find ./ -name '*.nt')
for f in ${files}; do
    filesize=$(du -h "$f" | cut -f1)
    echo "$filesize" | grep -q -F 'G'
    if [ $? -eq 0 ]; then
        echo "Running import for $f ($filesize); this could take some time ..."
    else
        echo "Running import for $f ($filesize)"
    fi
    # Usage: agload <kbname> <rdf files> ...
    # TODO: add option for skipping errors?
    agload -d delete-spo -i ntriples --port 8080 --bulk --rapper loc $f
done

