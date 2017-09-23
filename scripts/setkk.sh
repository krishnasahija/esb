#!/bin/bash
# Script to Linux Environment

####################################################################################
# Change Log
# Name                        Version            Log
# Krishna Kondapalli          1.0                1st Draft
####################################################################################

# THISUSER=`who am i | awk '{print $1}'`

if [ "`basename $0 2>/dev/null`" = "setkk.sh" ]; then
  echo ERROR: $0 must be run in the context of this shell, please use \". $0\"
  exit 1
fi

# list all functions
alias fun='funlist'
alias afun='declare -F'

# Text format
if tty -s; then
	bold=$(tput setaf 1)$(tput bold)
	normal=$(tput sgr0)
	underline=`tput smul`
	nounderline=`tput rmul`
	UL=${bold}${underline}
	NL=${normal}${nounderline}
fi

# Check OS
UNAME=`uname -s`
if [ "$UNAME" == "Linux" ]; then
	alias awk='/usr/bin/awk'
	alias grep='grep --color'
	OPT_IBM="ibm"
elif [ "$UNAME" == "SunOS" ]; then
	alias awk='/usr/xpg4/bin/awk'
	alias grep='/usr/sfw/bin/ggrep --color'
	OPT_IBM="IBM"
	# [ -f /bin/i386 ] && TERM=sun-color && export TERM
fi


#common alias
alias ls='ls -hF'
alias l='ls -ltr'
alias ll='ls -l'
alias lla='ls -la'
alias l.='ls -dl .*'
alias igrep='grep -i'
alias psef='ps -ef | grep -v grep | igrep'
alias psfu='ps -fu'
alias top='top -c'
alias du='du -h'
alias df='df -h'
alias dt='date +"%x %X"'
alias ipaddr='/sbin/ifconfig -a | igrep inet'
export LESS='-FRin'
# alias less='less -I'
# unalias cd 2>/dev/null

# For Linux Only
if [[ $UNAME = "Linux" || $UNAME =~ CYG* ]]; then
	alias ls='ls -hF --color=auto'
	alias rm='rm -I --preserve-root'
	#alias top='top -cM'
	alias du.='du -ha --max-depth 1'
	alias ports='netstat -tulanp'
	alias mountt='mount | column -t'
	alias ping='ping -c 5'
	alias nautilus='nautilus &>/dev/null &'
	# logins
	alias root='sudo su'
	alias mqm='sudo su - mqm'
	# cd to dir without typing cd
	shopt -s autocd
	shopt -s dirspell
	# alias ipt='sudo /sbin/iptables'
	# export HISTCONTROL=ignorespace:erasedups
	export HISTCONTROL=erasedups
	shopt -s histappend
	# PROMPT_COMMAND="history -n; history -w; history -c; history -r; $PROMPT_COMMAND"
	# PROMPT_COMMAND="history -a; history -r; $PROMPT_COMMAND"
fi

# Control History Log
export HISTIGNORE='&:[ ]*:?:??:exit:mqm:hist*:man*:type*:ls*:kill*:[lt][wsx]log*:my*:psef*:lless*:root'

# shows the path variable
alias path='echo -e ${PATH//:/\\n}'
alias cpath='echo -e ${CLASSPATH//:/\\n}'

# lazy alias
alias c='clear'
alias h='history'
alias j='jobs -l'
alias cd..='cd ..'
alias ..='cd ..'
alias 1.='cd ..'
alias 2.='cd ../..'
alias 3.='cd ../../..'
alias 4.='cd ../../../..'
alias newline='echo -e "\n"'

# Custom prompt
if [ $USER = "root" ]; then
	prompt="# "
else
	prompt="$ "
fi
# PS1="[\u@\h:\w]$prompt"
# PS1="\[\e]2;\w\a\]\[\e[32m\]\u@\h : \[\e[31m\]\w \[\e[0m\]\n\$prompt"
# PS1="\[\e]0;\w\a\]\[\e[32m\]\u@\h : \$PWD [exit status-\$?]\[\e[0m\]\n\$prompt"
PS1="\[\e]0;\w\a\]\[\e[32m\]\u@\h : \[\e[31m\]\$PWD \[\e[33m\][exit status-\$?]\[\e[0m\]\n\$prompt"
# PS1="\[\e]0;\w\a\]\[\e[32m\]\u@\h \[\e[31m\][\$PWD] \[\e[34m\] \D{%F %T} \[\e[31m\][exit-status-\$?]\[\e[0m\]\n\$prompt"
# PS1="\[\e]0;\w\a\]\[\e[31m\]\u@\h \[\e[32m\]\D{%T} \[\e[31m\]\$PWD \[\e[32m\][exit-status-\$?]\[\e[0m\]\n\$prompt"

# vi defaults
# alias vi='vi +"set nu | set ic"'
# export EXINIT="se nu ic ai aw sw=4"
export EXINIT="set nu ic ai"
alias svi='sudo vi'
alias edit='vim'

#set environment
alias tslog='itail /var/log/messages'
alias txlog='itail /var/log/Xorg.0.log'
alias lslog='less +F /var/log/messages'
alias lxlog='less +F /var/log/Xorg.0.log'

# shell behavior
shopt -s cdspell # cd corrects any spelling mistakes
shopt -s histappend # History appends even with multiple terminals


# User functions

function linebreaker(){
	eval echo ""; printf '%.s*' {1..100}; echo ""
}

function isay() {
	echo "${bold}$@${normal}"
}

function irun() {
	echo ${bold}$@${normal}
	$@
	# [[ $? -ne 0 ]] && echo "${bold}ERROR - Exit Status $? ${normal}" && return 2
}

function lless() {
	less `ls -tr1 | tail -${1:-1}`
}

function itail() {
	case $# in
		1) tail -f $1 ;;
		2) tail -${2}f $1 ;;
		3) tail -${2}f $1 | grep -i $3 ;;
		*) isay Usage: Arguments 1-fileName 2-noOfLines 3-searchString
	esac
}

function nocom() {
	if [[ -f $1 ]]; then
		# grep -v ^# "$1" | grep -v ^$
		# sed '/./!d' "$1"
		sed -e '/^[ ]*#/d' -e '/^[ ]*;/d' -e '/^$/d' "$1"
	else
		isay Usage: $FUNCNAME filename - get lines without commment/spaces
	fi
}

function ised() {
	if [[ -n $1 ]]; then
		read -t 24 -p "Search String: " SEARCH
		read -t 24 -p "Replace String: " REPLACE
		if [ "$UNAME" == "SunOS" ]; then
			[ -n $SEARCH  ] && sed 's/'"${SEARCH}"'/'"${REPLACE}"'/g' "$1" > /tmp/tmp_sed && mv /tmp/tmp_sed "$1"
		else
			[ -n $SEARCH  ] && sed -i 's/'"${SEARCH}"'/'"${REPLACE}"'/g' "$1"
		fi
	else
		isay "Usage: $FUNCNAME filename - sed replace"
	fi
}

function fsize_100M() {
	echo "Files Over 100MB: "
	if [[ -n $1 ]]; then
		find $1 -type f -size +100000k -exec ls -lh {} \; 2>/dev/null
	else
		find . -type f -size +100000k -exec ls -lh {} \; 2>/dev/null
	fi
	echo "Done"
}

function history_del() {
	if [ "$UNAME" == "SunOS" ]; then
		for f in `history | grep "${2}" | tail -${1:-1} | awk -F' ' '{print $1}' | tail -r`; do history -d $f; done
	else
		for f in `history | grep "${2}" | tail -${1:-1} | awk -F' ' '{print $1}' | tac`; do history -d $f; done
	fi
}

function my_loop(){
	while true; do
		$@ ;
		printf "%.s*" {1..100}
		echo "";
		sleep 1;
	done
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

function crmod(){
	chmod -R ${1:775} *
}

# END
