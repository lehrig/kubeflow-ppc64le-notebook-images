#!/bin/bash

# Check that the user has an entry in the passwd
# file and if not add an entry.
STATUS=0 && whoami &> /dev/null || STATUS=$? && true
if [[ "$STATUS" != "0" ]]; then
	if [[ -w /etc/passwd ]]; then
		echo "Adding passwd file entry for $(id -u)"
		cat /etc/passwd | sed -e "s/^jovyan:/nayvoj:/" > /tmp/passwd
		echo "jovyan:x:$(id -u):$(id -g):,,,:/home/jovyan:/bin/bash" >> /tmp/passwd
		cat /tmp/passwd > /etc/passwd
		rm /tmp/passwd
	else
		echo 'Container must be run with group "root" to update passwd file'
	fi
fi

# Warn if the user isn't going to be able to write files to $HOME.
if [[ ! -w /home/jovyan ]]; then
	echo 'Container must be run with group "users" to update files'
fi

sleep $JUPYTER_START_SLEEP_TIME

post_jupyter_start.sh

jupyter lab --notebook-dir=/home/jovyan --ip=0.0.0.0 --no-browser --allow-root --port=8888 --NotebookApp.token='' --NotebookApp.password='' --NotebookApp.allow_origin='*' --NotebookApp.base_url=${NB_PREFIX}
