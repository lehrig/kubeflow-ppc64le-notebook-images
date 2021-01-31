#!/bin/bash

if [[ "$NB_UID" == "$(id -u jovyan 2>/dev/null)" && "$NB_GID" == "$(id -g jovyan 2>/dev/null)" ]]; then
	# User is not attempting to override user/group via environment
	# variables, but they could still have overridden the uid/gid that
	# container runs as. Check that the user has an entry in the passwd
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
else
	# Warn if looks like user want to override uid/gid but hasn't
	# run the container as root.
	if [[ ! -z "$NB_UID" && "$NB_UID" != "$(id -u)" ]]; then
		echo 'Container must be run as root to set $NB_UID'
	fi
	if [[ ! -z "$NB_GID" && "$NB_GID" != "$(id -g)" ]]; then
		echo 'Container must be run as root to set $NB_GID'
	fi
fi

jupyter lab --notebook-dir=/home/jovyan --ip=0.0.0.0 --no-browser --allow-root --port=8888 --NotebookApp.token='' --NotebookApp.password='' --NotebookApp.allow_origin='*' --NotebookApp.base_url=${NB_PREFIX}

