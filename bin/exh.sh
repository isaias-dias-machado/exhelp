#!/bin/bash

source /home/isaias/hacking/elixir/help/cli-configs.env

exh=/home/isaias/hacking/elixir/help/bin/exh
tags=/home/isaias/.cache/exh/tags

if [ $# -eq "0" ]; then
	if [ ! -f ${tags} ]; then
		echo "No tags file. Run 'exh fetch'"
		exit 0
	fi

	selected=$(cat ${tags} | fzf)
	if [ -n "$selected" ]; then
		${exh} $selected | less -R
	fi
elif [ $1 = "fetch" ]; then
	mix docs.cache
elif [ $1 = "clear" ]; then
	${exh} --clear
else
	${exh} --help
fi
