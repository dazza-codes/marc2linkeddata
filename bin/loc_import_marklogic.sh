#!/usr/bin/env bash

# See loc_downloads.sh to get the data
# This script assumes the data are ntriples in *.nt files.

options="-host localhost -port 8049 -username $ML_USER -password $ML_PASS -mode local -input_file_type rdf "

files=$(find ./ -name '*.nt')
for f in ${files}; do
    filesize=$(du -h "$f" | cut -f1)
    echo "$filesize" | grep -q -F 'G'
    if [ $? -eq 0 ]; then
        echo "Running import for $f ($filesize); this could take some time ..."
    else
        echo "Running import for $f ($filesize)"
    fi
    /opt/MarkLogic/mlcp/bin/mlcp.sh import $options -input_file_path $f
done

