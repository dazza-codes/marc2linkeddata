#!/bin/bash

# This script will start/stop a custom 4store KB called 'cap_vivo'.
# To use a custom KB as the default whenever the system restarts,
# modify the content of /etc/default/4store.  If that file is
# modified, this script should not be required.

which 4s-backend > /dev/null
if [ ! $? ]; then
  echo "4store is not installed on the PATH"
  echo "See http://4store.org/trac/wiki/Documentation"
  exit 1
fi
which 4s-httpd > /dev/null
if [ ! $? ]; then
  echo "4store is not installed on the PATH"
  echo "See http://4store.org/trac/wiki/Documentation"
  exit 1
fi

# The knowledge base (KB) is called 'loc'
# The following is adapted from /etc/init.d/4store
PORT=9001  # avoid the default 4s-httpd port at 9000
KB=loc

case "$1" in
  start)
    # Ensure the 4store KB exists.
    # Only setup the backend once (it erases existing data).
    if [ ! -d "/var/lib/4store/$KB" ]; then
      sudo 4s-backend-setup $KB
    fi
    if ps aux | grep -q -E "[4]s-backend.*$KB"; then
      echo -e "4s-backend\t: already running $KB"
    else
      echo -e "4s-backend\t: starting $KB"
      if sudo 4s-backend $KB; then
        echo -e "4s-backend\t: started $KB"
      else
        echo -e "4s-backend\t: failed!"
        exit 1
      fi
    fi
    if ps aux | grep -q -E "[4]s-httpd.*$PORT.*$KB"; then
      echo -e "4s-httpd\t: already running $KB on $PORT"
    else
      echo -e "4s-httpd\t: starting $KB on $PORT"
      # Start the 4s-httpd server for SPARQL
      #4s-httpd -h # describes the options
      if sudo 4s-httpd -H localhost -p$PORT -U -s -1 $KB; then
        echo -e "4s-httpd\t: started $KB on $PORT"
        echo "See http://localhost:${PORT}/status/"
      else
        echo -e "4s-httpd\t: failed!"
        exit 1
      fi
    fi
    ;;
  stop)
    patterns="[4]s-httpd.*$KB [4]s-backend.*$KB"
    for pattern in $patterns; do
      echo "Stopping processes matching: $pattern"
      pids=$(ps aux | grep -E $pattern | tr -s ' ' | cut -d' ' -f2)
      echo "Stopping process numbers:"
      echo "$pids"
      for pid in $pids; do
        sudo kill $pid
      done
    done
    ;;
  status)
    for p in backend httpd; do
      if ps aux | grep -q -E "[4]s-${p}.*$KB"; then
        echo -e "4s-${p}\t: running $KB"
      else
        echo -e "4s-${p}\t: not running $KB"
      fi
    done
    ;;
  *)
    echo "Usage: $0 {start|stop|status}"
    exit 2
    ;;
esac

