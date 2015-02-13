#!/bin/bash

export DEBUG=false

# Runs a lot slower on jruby, even with threading enabled.
export JRUBY_OPTS=-J-Xmx2g

export THREAD=false
export GET_LOC=false  # if this is true, be prepared to wait a very long time!

export LOG_FILE='./log/marc2ld.log'
export LIB_PREFIX='http://www.linked-data.org/library/'

# Additional config options should be in .env;
# the .env values will not replace those above.
if [ ! -s .env ]; then
    cp -u .env_example .env
fi

SCRIPT_FILE='.binstubs/marcAuthority2LD'
if [ ! -s ${SCRIPT_FILE} ]; then
    echo "Cannot locate script: $SCRIPT_FILE"
    exit 1
fi

AUTH_FILE="./data/auth.mrc"
AUTH_PATH="./data/auth_turtle/"
if [ ! -s ${AUTH_FILE} ]; then
    echo "Place a MARC21 authority file into: $AUTH_FILE"
    exit 1
fi

${SCRIPT_FILE} ${AUTH_FILE}

DATA_LOG_FILE="./log/run_test_data.log"
echo -e "\n\n" > ${DATA_LOG_FILE}

echo -e "Output file count should be 100000:" >> ${DATA_LOG_FILE}
find ${AUTH_PATH} -type f | wc -l  >> ${DATA_LOG_FILE}
echo -e "\n\n" > ${DATA_LOG_FILE}

# count all the different types of authority files
echo -e "Different types of authority records:\n" >> ${DATA_LOG_FILE}
find ${AUTH_PATH} -type f | xargs grep 'linked-data' | sed -e 's/^.*> a/a/' | sort -u >> ${DATA_LOG_FILE}
echo -e "\n\n" > ${DATA_LOG_FILE}

echo -e "Count for 'Person' authority records:" >> ${DATA_LOG_FILE}
find ${AUTH_PATH} -type f | xargs grep 'linked-data' | grep -c -F 'Person' >> ${DATA_LOG_FILE}
echo -e "Count for 'Organization' authority records:" >> ${DATA_LOG_FILE}
find ${AUTH_PATH} -type f | xargs grep 'linked-data' | grep -c -F 'Organization' >> ${DATA_LOG_FILE}
echo -e "Count for 'Place' authority records:" >> ${DATA_LOG_FILE}
find ${AUTH_PATH} -type f | xargs grep 'linked-data' | grep -c -F 'Place' >> ${DATA_LOG_FILE}
echo -e "Count for 'event' authority records:" >> ${DATA_LOG_FILE}
find ${AUTH_PATH} -type f | xargs grep 'linked-data' | grep -c -F 'event' >> ${DATA_LOG_FILE}
echo -e "Count for 'v1#NameTitle' authority records:" >> ${DATA_LOG_FILE}
find ${AUTH_PATH} -type f | xargs grep 'linked-data' | grep -c -F 'v1#NameTitle' >> ${DATA_LOG_FILE}
echo -e "Count for 'v1#Title' authority records:" >> ${DATA_LOG_FILE}
find ${AUTH_PATH} -type f | xargs grep 'linked-data' | grep -c -F 'v1#Title' >> ${DATA_LOG_FILE}

# # check the syntax of the output files
# echo -e "\n\n\n" >> ${DATA_LOG_FILE}
# for f in $(find ${AUTH_PATH} -type f); do
#      rapper -c -i turtle $f >> ${DATA_LOG_FILE} 2>&1
# done

# cleanup
rm -rf ${AUTH_PATH}

