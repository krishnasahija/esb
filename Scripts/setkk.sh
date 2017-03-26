#!/bin/bash

# alias
# alias ls='ls -h'
alias ll='ls -l'
alias l='ls -ltr'
alias l.='ll -d .*'
alias lla='ll -ad .*'

alias ..='cd ..'
alias 1.='cd ..'
alias 2.='cd ../..'
alias 3.='cd ../../..'
alias 4.='cd ../../../..'

alias grep='grep --color'
alias igrep='grep -i'
alias psef='ps -ef | igrep'
export LESS='-FRin'
alias less='less -i'

alias c='clear'
alias h='history'
alias j='jobs -l'

alias df='df -hP'
alias du.='du -a --max-depth 1'

PATH=$PATH:$HOME/scripts
alias path='echo -e ${PATH//:/\\n}'
alias cpath='echo -e ${CLASSPATH//:/\\n}'

PS1='\[\e]0;\w\a\]\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\] [exit $?] \n$ '

export EXINIT="se ic nu aw ts=4 sw=4"

shopt -s autocd
shopt -s cdspell
shopt -s dirspell
shopt -s expand_aliases
# umask 0002

function nocom(){
	if [[ -f $1 ]]; then
		sed -e '/^[ ]*#/d' -e '/^[ ]*;/d' -e '/^$/d' "$1"
	else
		echo "Usaage: $FUNCNAME filename"
	fi
}

function move_files_to_current_dir(){
	find . -type f -print0 -exec mv -t . {} \;
}

# function rename_files_with_hyphen(){
	# find . -type f -print0 -exec mv -t . {} \;
	# for f in `find . -iname ''`; do 
	
	# done
# }

function remove_empty_dirs(){
	find . -type d -empty -print;
	echo "Sleeping 10 secs before deleting empty folders" && sleep 10 && find . -type d -empty -delete;
}


function find_move_files_by_year(){
	[[ -z $1 ]] && echo "No Arguments"
	find . -type f -name ${1} -print0 -exec mv -t ${1} {} \;
	
}

function cmod775(){
	chmod -R 775 *
}



