#!/bin/bash
# Script to set ESB environment

####################################################################################
# Change Log
# Name                        Version            Log
# Krishna Kondapalli          1.0                1st Draft
####################################################################################

if [ "`basename $0 2>/dev/null`" = "setEsb.sh" ]; then
  echo ERROR: $0 must be run in the context of this shell, please use \". $0\"
  exit 1
fi

# list all functions
alias fun='funlist'

# Set mq and mb
if [[ -n ${EMMQMGR} || -n ${EMMBROKER} ]]; then
	export EMMQMGR=${EMMQMGR}
	export EMMBROKER=${EMMBROKER}
else
	export EMMQMGR='QMGR1'
	export EMMBROKER='NODE1'
fi

# Check OS
UNAME=`uname -s`
if [ "$UNAME" == "Linux" ]; then
	OPT_IBM="ibm"
elif [ "$UNAME" == "SunOS" ]; then
	OPT_IBM="IBM"
fi

# Queue Manger Check
dspmq &>/dev/null
if [[ $? -eq 0 && $UNAME = "SunOS" ]]; then
	case $(dspmq | grep -c QMNAME) in
		0)
			export EMMQMGR=''
      export EMMBROKER=''
		;;
		*)
			if [[ $(dspmq | grep -c "${EMMQMGR}") -eq 0 ]]; then
				export EMMQMGR=$(dspmq | cut -d')' -f1 | cut -d'(' -f2 | tail -1)
			fi
			echo "Change QueueManger using setmq function"
		;;
	esac
fi

export QM=$EMMQMGR
export BK=$EMMBROKER
[ $USER = "ibm.mq" -o $USER = "mqm" ] && [ -n $QM -o -n $BK ] && echo -e "Environment variables set \nQM=$QM\nBK=$BK\n"

#set environment
# alias setmqe='. /opt/mqm/bin/setmqenv -s'
alias mqexplorer='/opt/mqm/bin/MQExplorer &'
alias mqmb='echo -e "QM = $QM \nBK = $BK"'
alias mqbin='[ -d /opt/mqm/bin ] && PATH=/opt/mqm/bin:$PATH'
[ -x /opt/${OPT_IBM}/mqsi/7.0/bin/mqsiprofile ] && alias mb='. /opt/${OPT_IBM}/mqsi/7.0/bin/mqsiprofile'
[ -x /opt/${OPT_IBM}/mqsi/10.0/server/bin/mqsiprofile ] && alias ib='. /opt/${OPT_IBM}/mqsi/10.0/server/bin/mqsiprofile'
[ -x /opt/${OPT_IBM}/mqsi/10.0/iib ] && alias ibtoolkit='/opt/${OPT_IBM}/mqsi/10.0/iib toolkit without testnode -data $PWD'
alias cdwsrr='cd /var/mqsi/common/wsrr'
alias twlog='itail /var/mqsi/wmbflows.log'
alias lwlog='less +F /var/mqsi/wmbflows.log'
# QLoad & QProg
[[ -f /var/tmp/qload$UNAME ]] && alias qload='/var/tmp/qload$UNAME -m $QM'
[[ -f /var/tmp/q$UNAME ]] && alias qprog='/var/tmp/q$UNAME -m$QM'

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

# MY MY Custom function
function my_my(){
	# [[ -f /var/tmp/qload$UNAME ]] && alias qload='/var/tmp/qload$UNAME -m $QM'
	# Q Prog
	if [[ ! $UNAME = "Linux" ]]; then
		QPROG=$(find /mqha -name 'qSun' 2> /dev/null | head -1)
		[[ -f $QPROG ]] && alias qprog='$QPROG -m $QM'
	else
		QPROG=$(find /tmp -name 'qLinux' 2> /dev/null | head -1)
		[[ -f $QPROG ]] && alias qprog='$QPROG -m $QM'
	fi
	# msgmap_backup to msgmap
	alias backup_to_msgmap='for f in `find . -iname *.msgmap_backup `; do mv $f ${f%%_backup} ; done'

	# msgmap to msgmap_backup
	alias msgmap_to_backup='for f in `find . -iname *.msgmap `; do mv -- $f ${f}_backup; done'

	# for f in `echo ${!M*}`; do echo $f; done | awk '{printf("echo "$1" =  $"$1 "\n")}' | sh
}

# MB stuff
function mb_ls() {

	case $# in
		0) irun mqsilist $EMMBROKER
		;;
		1) 	if [[ "$1" =~ ^[0-9]{1}$ ]]; then
				irun mqsilist $EMMBROKER -d $1
			else
				irun mqsilist $EMMBROKER -e $1
			fi
		;;
		2) irun mqsilist $EMMBROKER -e $1 -d $2
		;;
		*) isay "Usage: $FUNCNAME EMMBROKER EG LEVEL"
		;;
	esac
}

function mb_running_egs() {
	mb_ls | igrep BIP1286I | cut -d "'" -f 2
}

function mbstart() {
	irun mqsistart $EMMBROKER
}

function mbstop() {
	irun mqsistop $EMMBROKER $@
}

function mb_mqservice() {
	mb_running=`ps -ef | grep $EMMBROKER | grep -v grep | wc -l`
	[[ $mb_running != 0 ]] && mbstop
	mqsichangebroker $EMMBROKER -d defined && mbstart
}

function mb_restart() {
	[[ -z $1 ]] && read -p "Restart $EMMBROKER Y/N: " -n 1 -r && echo
	case ${REPLY:-${1}} in
	Y|y)
		irun mqsistop $EMMBROKER
		[[ $? = 0 ]] && echo "sleeping 4 secs" && sleep 4 && irun mqsistart $EMMBROKER
	;;
	N|n) echo "$EMMBROKER not restarted"
	;;
	*)
		echo -e "\nUsage: $FUNCNAME Y/N"
	;;
	esac
}

function mb_cvp() {
	irun mqsicvp $EMMBROKER $@
}

function mb_jdbc() {
	irun mqsireportproperties $EMMBROKER -c JDBCProviders -o AllReportableEntityNames -a
	[[ $? -eq 0 ]] && read -p 'Input JDBC Property name that you need : ' -t 24 PROP
	if [[ -n $PROP ]]; then
		irun mqsireportproperties $EMMBROKER -c JDBCProviders -o $PROP -r
	else
		isay "Usage: $FUNCNAME JDBC - Reports JDBC info"
	fi
}

function mb_getdbparms() {
	if [ $(mqsireportbroker $BK | grep "Multi-instance" | cut -d "'" -f2) = 'false' ]; then
		WORKPATH=/var/mqsi
	else
		WORKPATH=$(mqsireportbroker $BK | grep "Shared Work Path =" | cut -d"'" -f2)
	fi

	[ ! -d $WORKPATH/registry/$EMMBROKER/CurrentVersion ] && echo "Can't find $WORKPATH/registry/$EMMBROKER/CurrentVersion" && return 1

	ls -1 $WORKPATH/registry/$EMMBROKER/CurrentVersion/DSN
	[[ $? -eq 0 ]] && read -p 'Input DSN Property name that you need to get: ' -t 24 PROP
	if [[ -n $PROP ]]; then
		irun more $WORKPATH/registry/$EMMBROKER/CurrentVersion/DSN/$PROP/UserId
	else
		isay "Usage: $FUNCNAME - Input DSN to get UserId "
	fi
}

function mb_setdbparms() {
	ls -1 /var/mqsi/registry/$EMMBROKER/CurrentVersion/DSN
	[[ $? -eq 0 ]] && read -p 'Input DSN name : ' -t 24 PROP
	if [[ -n $PROP ]]; then
		read -p 'Change property NAME : ' -t 24 PROP1
		read -p 'Change property VALUE : ' -t 24 PROP2
		irun mqsisetdbparms $EMMBROKER -n $PROP -u $PROP1 -p $PROP2
	else
		isay "Usage: $FUNCNAME - Input DSN UserId/Pass to setdbparms"
	fi
}

function mb_deploy() {
	if [[ -n $1 && -n $2 ]]; then
		irun mqsideploy $EMMBROKER -w 600 -e $1 -a $2 $3
		[[ $? -eq 0 ]] && sleep 4 && mb_ls $1
	else
		isay "Usage: $FUNCNAME EG BAR (-m) - Deploys bar to EG on $EMMBROKER. -m for clean deploy"
	fi
}

function mb_buildver(){
	echo $bold"Build Versions of running EG's "$normal
	mb_running_egs
	for EG in `mb_running_egs`; do
		linebreaker; echo $EG
		eg_buildver $EG
		linebreaker
	done

	if [[ $(mb_ls | grep -c BIP1287I) -ne 0 ]]; then
		linebreaker; echo -e "Stopped EG's :"
		mb_ls | grep BIP1287I | cut -d "'" -f2
		linebreaker
	fi
}

function mb_report_prop() {
	echo -en 'Report which MB Property: \nBrokerRegistry \nSecurityCache \nHTTPListener \nSecurityCache \nWebAdmin \nMQTT \nAgentJVM\nName: ' && read -t 24 PROP
	case $PROP in
		BrokerRegistry) irun mqsireportproperties $EMMBROKER -o $PROP -r
		;;
		SecurityCache) irun mqsireportproperties $EMMBROKER -o $PROP -r
		;;
		HTTPListener) irun mqsireportproperties $EMMBROKER -b httplistener -o AllReportableEntityNames -r
		;;
		SecurityCache) irun mqsireportproperties $EMMBROKER -b securitycache -o AllReportableEntityNames -r
		;;
		WebAdmin) irun mqsireportproperties $EMMBROKER -b webadmin -o AllReportableEntityNames -r
		;;
		MQTT) irun mqsireportproperties $EMMBROKER -b pubsub -o AllReportableEntityNames -r
		;;
		AgentJVM) irun mqsireportproperties $EMMBROKER -b agent -o ComIbmJVMManager -r
		;;
		*) isay "Usage: $FUNCNAME - Input Property Name from displayed list"
		;;
	esac
}

function mb_toggle_mqtt(){
	CURRENT=`mqsireportproperties $EMMBROKER -b pubsub -o MQTTServer -n enabled | grep -v BIP | grep -v ^$`
	if [[ $CURRENT = "true" ]]; then
		TOGGLE=false
	else
		TOGGLE=true
	fi
	irun mqsireportproperties $EMMBROKER -b pubsub -o AllReportableEntityNames -r
	read -t 24 -p "Toogle Broker MQTT Server > y/n : " -n 1 -r && echo && [[ ! $REPLY =~ ^[Yy]$ ]] && return
	irun mqsichangeproperties $EMMBROKER -b pubsub -o MQTTServer -n enabled -v ${TOGGLE}
	irun mqsichangeproperties $EMMBROKER -b pubsub -o OperationalEvents/MQTT -n enabled -v ${TOGGLE}
	irun mqsichangeproperties $EMMBROKER -b pubsub -o AdminEvents/MQTT -n enabled -v ${TOGGLE}
	irun mqsichangeproperties $EMMBROKER -b pubsub -o BusinessEvents/MQTT -n enabled -v ${TOGGLE}
	irun mqsireportproperties $EMMBROKER -b pubsub -o AllReportableEntityNames -r
	isay "Restart Broker after MQTT Changes"
	mb_restart
}

function eg_buildver() {
	if [[ -n $1 ]]; then
		mb_ls $1 2 | grep -A 1 -e 'Build_Version' -e 'Message flow' -e 'Additional thread instances' | sed  -e '/^$/d' -e 's/BIP1288I:\ //g' -e '/User-defined/d' -e '/Long/d' -e '/--/d'
	else
		isay "Usage: $FUNCNAME EG - Reports MsgFlow Build Version, Additional Instances"
	fi
}

function eg_report_prop() {
	echo -en "Input EG Name (or) return to list EG's running:" && read -t 24 EG
	if [[ -z $EG ]]; then
		echo "Listing all Running EG's in $EMMBROKER: "
		mb_running_egs && echo -en "Input EG Name: " && read -t 24 EG
	fi
	if [[ -n $EG ]]; then
		mqsireportproperties $EMMBROKER -e $EG -o AllReportableEntityNames -a | cut -d "'" -f 2
		read -p 'Input Property that you need : ' PROP
		irun mqsireportproperties $EMMBROKER -e $EG -o $PROP -${1:-r}
	else
		isay "Usage: $FUNCNAME - Input EG  which reports its properties"
	fi
}

function eg_http() {
	if [[ -n $1 ]]; then
		irun mqsireportproperties $EMMBROKER -e $1 -o HTTP${2}Connector -r
	else
		isay "Usage: $FUNCNAME EG ('S' - optional for HTTPSConnector)- Reports EG HTTPConnector info"
	fi
}

function eg_jvm() {
	if [[ -n $1 ]]; then
		irun mqsireportproperties $EMMBROKER -e $1 -o ComIbmJVMManager -r
	else
		isay "Usage: $FUNCNAME EG - Reports EG JVM info"
	fi
}

function eg_change_prop() {
	read -p "Input EG Name (or) return to list EG's running: " -t 24 EG
	if [[ -z $EG ]]; then
		echo "Listing all Running EG's in $EMMBROKER: "
		mb_running_egs && read -p "Input EG Name: " -t 24 EG
	fi
	if [[ -n $EG ]]; then
		mqsireportproperties $EMMBROKER -e $EG -o AllReportableEntityNames -a | cut -d "'" -f 2
		read -p 'Input Property that you need : ' PROP
		mqsireportproperties $EMMBROKER -e $EG -o $PROP -${1:-r}
		read -p 'Change property NAME : ' PROP1
		read -p 'Change property VALUE : ' PROP2
		irun mqsichangeproperties $EMMBROKER -e $EG -o $PROP -n $PROP1 -v $PROP2
		[[ $? -eq 0 ]] && echo "Restarting $EG" && eg_restart $EG
		echo -en 'Reporting changes: '
		irun mqsireportproperties $EMMBROKER -e $EG -o $PROP -${1:-r}
	else
		isay "Usage: $FUNCNAME - Change Properties of EG "
	fi
}

function eg_trace_on() {
	if [[ -n $1 ]]; then
		irun mqsichangetrace $EMMBROKER -${2:-u} -e $1 ${@:3} -r
		irun mqsichangetrace $EMMBROKER -${2:-u} -e $1 ${@:3} -l debug
	else
		isay "Usage: $FUNCNAME EG - starts trace (t) optional for service trace"
	fi
}

function eg_trace_off() {
	if [[ -n $1 ]]; then
		irun mqsichangetrace $EMMBROKER -${2:-u} -e $1 ${@:3} -l none
		irun mqsireadlog $EMMBROKER -${2:-u} -e $1 -o ${2:-u}trace.out
		irun mqsiformatlog -i ${2:-u}trace.out -o ${2:-u}trace.txt
		mv ${2:-u}trace.out ${2:-u}trace.out.$(date +"%m%d%y-%H%M%S")
		# if [[ ${#DISPLAY} -ne 0 ]];then gedit trace.txt; else less trace.txt; fi
		if [[ ${#DISPLAY} -eq 0 ]]; then #checks length of $DISPLAY
			less ${2:-u}trace.txt
		else
			gedit ${2:-u}trace.txt &
		fi
	else
		isay "Usage: $FUNCNAME EG - stops trace"
	fi
}

function rtrace() {
	[ $# -eq 1 ] && irun mqsiformatlog -i ${1} -o ${2:-u}trace.txt
	if [[ ${#DISPLAY} -eq 0 ]]; then #checks length of $DISPLAY
		less ${2:-u}trace.txt
	else
		gedit ${2:-u}trace.txt &
	fi
}

function eg_restart() {
	if [[ -n $1 ]]; then
		# irun mqsireload $EMMBROKER -e $1
		eg_stop $1
		eg_start $1
	else
		isay "Usage: $FUNCNAME EG"
	fi
}

function eg_start() {
	if [[ -n $1 ]]; then
		irun mqsistartmsgflow $EMMBROKER -w 600 -e $@
	else
		isay "Usage: $FUNCNAME EG"
	fi
}

function eg_stop() {
	if [[ -n $1 ]]; then
		irun mqsistopmsgflow $EMMBROKER -w 600 -e $@
	else
		isay "Usage: $FUNCNAME EG"
	fi
}

function eg_start_mflow() {
	if [[ -n $1 && -n $2 ]]; then
		eg_start $1 -m $2
	else
		isay "Usage: $FUNCNAME EG MSGFLOW"
	fi
}

function eg_stop_mflow() {
	if [[ -n $1 && -n $2 ]]; then
		eg_stop $1 -m $2
	else
		isay "Usage: $FUNCNAME EG MSGFLOW"
	fi
}

function eg_start_all_mflow() {
	if [[ -n $1 ]]; then
		eg_start $1 -j
	else
		isay "Usage: $FUNCNAME EG "
	fi
}

function eg_stop_all_mflow() {
	if [[ -n $1 ]]; then
		eg_stop $1 -j
	else
		isay "Usage: $FUNCNAME EG "
	fi
}

# MQ Stuff

function rmq() {
echo -e "${@}" | runmqsc $EMMQMGR
}

function setmq() {
	export EMMQMGR=${1:?"Pass QMGR Name"}
	export QM=$EMMQMGR
	isay QM=$EMMQMGR
}

function setmb() {
	export EMMBROKER=${1:?"Pass BROKER Name"}
	export BK=$EMMBROKER
	isay BK=$EMMBROKER
}

function mq_q() {
	if [[ -n $1 ]]; then
		isay  "dis q('$1')"
		echo "dis q('$1')" | runmqsc $EMMQMGR
	else
		isay "Usage: $FUNCNAME 'QName'"
	fi
}

function mq_curdepth() {
	if [[ -z $1 ]]; then
		isay "dis q(*) where ( curdepth gt 0 )"
		echo "dis q(*) where ( curdepth gt 0 )" | runmqsc $EMMQMGR | grep -A 1 'QUEUE(' | sed '/--/d' | paste - - | awk '{printf "%-50s %-20s %-15s\n", $1, $2, $3}'
	else
		isay "dis q(*) where ( curdepth gt 0 )"
		echo "dis q(*) where ( curdepth gt 0 )" | runmqsc $EMMQMGR | grep -A 1 'QUEUE(' | sed '/--/d' | paste - - | awk '{printf "%-50s %-20s %-15s\n", $1, $2, $3}' | grep -v '(SYSTEM.'
	fi
}

function mq_clusterq() {
	if [[ -n $1 ]]; then
		echo "dis qc('$1')" | runmqsc $EMMQMGR
	else
		isay "Usage: $FUNCNAME 'Cluster QName'"
	fi
}

function mq_qpid() {
	if [[ -n $1 ]]; then
		isay "dis qstatus('$1') TYPE(HANDLE) ALL"
		echo "dis qstatus('$1') TYPE(HANDLE) ALL" | runmqsc $EMMQMGR
	else
		isay "Usage: $FUNCNAME 'QName' gives PID for the process accessing queue"
	fi
}

function mq_qstat() {
	if [[ -n $1 ]]; then
		isay "display qstatus('$1') IPPROCS OPPROCS CURDEPTH"
		echo -e "display qstatus('$1') IPPROCS OPPROCS CURDEPTH" | runmqsc $EMMQMGR
	else
		isay "Usage: $FUNCNAME 'QName'"
	fi
}

function mq_qclear() {
	echo "Use $FUNCNAME with caution as it clears all msgs in Queue"
	for f in `echo "dis q(*) where ( curdepth gt 0 )" | runmqsc $EMMQMGR | grep -i 'queue(' | grep -iv 'queue(system' | cut -d'(' -f 2 | cut -d')' -f1`;
	do
		[[ ! $1 = "all" ]] && read -p "Clear Q - $f > y/n : " -n 1 -r && echo && [[ ! $REPLY =~ ^[Yy]$ ]] && continue
		if [ $(alias | grep -c "qload") -eq 0 ]; then
			isay "Purging Q - ${f}"
			echo "clear ql($f)" | runmqsc -e $EMMQMGR
		else
			isay "Purging Q - ${f}"
			qload -pI $f
		fi
	done
}

function mq_chl() {
	if [[ -n $1 ]]; then
		isay "dis chl('$1') all"
		echo -e "dis chl('$1') all" | runmqsc $EMMQMGR
	else
		isay "Usage: $FUNCNAME 'ChannalName'"
	fi
}

function mq_chstat() {
	if [[ -n $1 ]]; then
		isay "dis chstatus('$1') msgs"
		echo "dis chstatus('$1') msgs" | runmqsc $EMMQMGR
	else
		isay "Usage: $FUNCNAME 'Channel Name'"
	fi
}

function mq_chl_start() {
	if [[ -n $1 ]]; then
		isay "start chl('$1')"
		echo -e "start chl('$1')" | runmqsc $EMMQMGR
		sleep 4;
		mq_chstat $1
	else
		isay "Usage: $FUNCNAME 'ChannalName'"
	fi
}

function mq_chl_stop() {
	if [[ -n $1 ]]; then
		isay "stop chl('$1')"
		echo -e "stop chl('$1')" | runmqsc $EMMQMGR
		[ -z $2 ] && mq_chstat $1
	else
		isay "Usage: $FUNCNAME 'ChannalName'"
	fi
}

function mq_chl_reset() {
	if [[ -n $1 ]]; then
		isay "reset chl('$1')"
		echo -e "reset chl('$1')" | runmqsc $EMMQMGR
	else
		isay "Usage: $FUNCNAME 'ChannalName'"
	fi
}

function mq_chl_retry_start() {
	if [[ -n $1 ]]; then
		mq_chl_stop  $1 nostatus ; sleep 10;
		mq_chl_reset $1
		mq_chl_start $1
	else
		isay "Usage: $FUNCNAME 'ChannalName'"
	fi
}

function mq_chl_retry_start_all() {
	for f in `echo 'dis chs(*) where( status eq retrying )'| runmqsc $EMMQMGR | grep CHANNEL | cut -d '(' -f2 | cut -d ')' -f1`;
	do
		mq_chl_retry_start $f
	done
}

# MQ Sample Scripts
function mq_put() {
	if [[ -n $1 ]]; then
		irun /opt/mqm/samp/bin/amqsput $1 $EMMQMGR
	else
		isay "Usage: $FUNCNAME 'QName'"
	fi
}
function mq_get() {
	if [[ -n $1 ]]; then
		irun /opt/mqm/samp/bin/amqsget $1 $EMMQMGR
	else
		isay "Usage: $FUNCNAME 'QName'"
	fi
}
function mq_bcg() {
	if [[ -n $1 ]]; then
		QSUN=$(find /mqha -name 'qSun' | head -1)
		if [[ -x $QSUN ]]; then
			$QSUN -m$QM -i${1} -dd3
		else
			irun /opt/mqm/samp/bin/amqsbcg $1 $EMMQMGR ${2:-1}
		fi
		newline;
	else
		isay "Usage: $FUNCNAME 'QName'"
	fi
}

function qbrowse(){
	[ $(alias | grep -c "qload") -eq 0 ] && echo "Copy qload$UNAME to /var/tmp/ " && return
	[ -z $1 ] && echo "Usage: $FUNCNAME Qname" && return
	qload -${2:-i} $1 -f stdout -dti${3}
}

function qread(){
	[ -z $1 ] && echo "Usage: $FUNCNAME Qname" && return
	qbrowse $1 I
}

function prjbuild(){
	if [[ -x /usr/bin/xvfb-run && -n ${EMM_ROOT_DIR}  && $# -gt 0 ]]; then
		echo  "Workspace - ${EMM_ROOT_DIR} "
		PROJ=$1; shift
		if [[ -n ${PROJ} ]]; then
			/usr/bin/xvfb-run ant -f ${EMM_ROOT_DIR}/MessageBroker/${PROJ}/project-build.xml $@
		fi
	else
		isay "Usage: $FUNCNAME 'Project' (optional target)"
		[ -n ${EMM_ROOT_DIR} ] && cd ${EMM_ROOT_DIR} && find . -iname 'project-build.xml' | cut -d '/' -f3 | sort
	fi
}

function funlist() {
	cat <<EOF
*************************************************************************************************************************
${bold}FUNCTIONName           -    DESCRIPTION                             -    USAGE${normal}
*************************************************************************************************************************
${bold}MessageBroker${normal}
mbstart                -    MB Start                                -    FunctionName
mbstop                 -    MB Stop                                 -    FunctionName (-i|-q)
mb_restart             -    MB Restart                              -    FunctionName (-i)
mb_ls                  -    MB MQSIList                             -    FunctionName (EG|EG DetailLevel)
mb_cvp                 -    MB mqsicvp to check Broker              -    FunctionName
mb_running_egs         -    MB List Running EG's                    -    FunctionName
mb_deploy              -    MB Deploy Bar                           -    FunctionName EG BAR (-m)
mb_jdbc                -    MB Display JDBC                         -    FunctionName INTERACTIVE
mb_toggle_mqtt         -    MB Toogle MQTT Server                   -    FunctionName INTERACTIVE
mb_report_prop         -    MB Report Properties                    -    FunctionName INTERACTIVE
mb_setdbparms          -    MB SetDB parms                          -    FunctionName INTERACTIVE
mb_getdbparms          -    MB GetDB parms                          -    FunctionName INTERACTIVE
mb_mqservice           -    MB Set as MQ Service                    -    FunctionName
mb_buildver            -    MB Running EG's versions                -    FunctionName
prjbuild               -    CMI Project build                       -    FunctionName ProjectName (target)
*************************************************************************************************************************
${bold}MessageBroker-EG${normal}
eg_buildver            -    EG MsgFlow Version                      -    FunctionName EG
eg_report_prop         -    EG MQSI Report Properties               -    FunctionName (a) INTERACTIVE
eg_change_prop         -    EG Change Properties                    -    FunctionName (a) INTERACTIVE
eg_http                -    EG List HTTP properties                 -    FunctionName EG (S)
eg_jvm                 -    EG List JVM properties                  -    FunctionName EG
eg_restart             -    EG Restart                              -    FunctionName EG
eg_start               -    EG Start                                -    FunctionName EG
eg_stop                -    EG Stop                                 -    FunctionName EG
eg_start_mflow         -    EG MessageFlow Start                    -    FunctionName EG MSGFLOW
eg_stop_mflow          -    EG MessageFlow Stop                     -    FunctionName EG MSGFLOW
eg_start_all_mflow     -    EG MessageFlow Start All                -    FunctionName EG
eg_stop_all_mflow      -    EG MessageFlow Stop All                 -    FunctionName EG
eg_trace_on            -    EG Start Trace                          -    FunctionName EG (t)
eg_trace_off           -    EG Stop Trace                           -    FunctionName EG (t)
*************************************************************************************************************************
${bold}MQ-Queue${normal}
rmq                    -    RUN MQ COMMAND                          -    FunctionName 'CMD'
mq_q                   -    MQ Display Q's                          -    FunctionName 'QNAME'
mq_clusterq            -    MQ Cluster Q's                          -    FunctionName 'QNAME'
mq_qstat               -    MQ Queue Stats                          -    FunctionName 'QNAME'
mq_qpid                -    MQ ProcessId running on Q               -    FunctionName 'QNAME'
mq_curdepth            -    MQ List of all Q's with msgs            -    FunctionName
mq_qclear              -    MQ Clears all Q's with msgs             -    FunctionName
mq_bcg                 -    MQ Browse Msgs in Q                     -    FunctionName 'QNAME'
mq_put                 -    MQ Put Msgs in Q                        -    FunctionName 'QNAME'
mq_get                 -    MQ Get Msgs from Q                      -    FunctionName 'QNAME'
qbrowse                -    qload browse msgs from Q                -    FunctionName 'QNAME'
${bold}MQ-Channel${normal}
mq_chl                 -    MQ channel list                         -    FunctionName 'ChlName'
mq_chstat              -    MQ channel status                       -    FunctionName 'ChlName'
mq_chl_start           -    MQ channel start                        -    FunctionName 'ChlName'
mq_chl_reset           -    MQ channel reset                        -    FunctionName 'ChlName'
mq_chl_stop            -    MQ channel stop                         -    FunctionName 'ChlName'
mq_chl_retry_start     -    MQ start retrying channel               -    FunctionName 'ChlName'
mq_chl_retry_start_all -    MQ start all retrying channels          -    FunctionName
*************************************************************************************************************************
${bold}Utils${normal}
setmq                  -    MQ Change QMGR Name for script          -    FunctionName 'QMGR'
setmb                  -    MQ Change BROKER Name for script        -    FunctionName 'BROKER'
*************************************************************************************************************************
${bold}setmq - Change QMGR Name
setmb - Change BROKER Name
${UL}Notes:${NL}
() - Optional
declare -f FunctionName - For function lookup
*************************************************************************************************************************
EOF
}

# END
