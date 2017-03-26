#!/bin/bash
# exec &> >(tee -a ${0%.*}_$(date +"%m%d%Y").log)

URL=${1-"https://localhost:443"}
USER='user'
PASS='pass'

URLS=$URL/uri
CTFILE='/tmp/headers.log'

function finish(){
	rm -f $CTFILE
}
# Exit trap
trap finish 0 1 2 3 9

function linebreaker(){
	eval echo ""; printf '%.s*' {1..100}; echo ""
}

function login(){

	linebreaker;
	REQ1=$URLS/login
	echo -e "LOGIN \ncurl -kis -u $USER:$PASS $REQ1"
	# COOKIE=`curl -kis -u $USER:$PASS $REQ1 | grep -i 'cookie' | cut -d: -f2 | cut -d';' -f1`
	curl -kis -u $USER:$PASS $REQ1 | tee $CTFILE
	COOKIE=`cat $CTFILE | grep -i 'cookie' | cut -d: -f2 | cut -d';' -f1`
	echo "Cookie: $COOKIE"
	linebreaker;

	[[ -z $COOKIE ]] && echo -e "Login Failed. No Cookie Found" && exit 1

}

function put(){
	REQ1="$URLS/submit -d @/tmp/test.json"
	echo -e "PUT \ncurl -kis -b "$COOKIE" -X PUT $REQ1 "
	curl -kis -b "$COOKIE" -X PUT $REQ1 
	linebreaker;
}

function get(){
	# REQ1=$URLS/submit?getnumberofmessages=1
	REQ1=$URLS/submit?messageformat=json
	echo -e "GET \ncurl -kis -b "$COOKIE" -X GET $REQ1"
	curl -kis -b "$COOKIE" -X GET $REQ1 
	linebreaker;
}

function delete(){
	REQ1="$URLS/submit?messageformat=json&MessageId=414d5120524e514f514d30352020202057cbdb9a28c8f403&MessageId=414d5120524e514f514d30352020202057cbdb9a28f6c90"
	echo -e "DELETE \ncurl -kis -b "$COOKIE" -X DELETE $REQ1"
	curl -kis -b "$COOKIE" -X DELETE $REQ1 
	linebreaker;
}

function delete_all(){
	REQ1="$URLS/submit?messageformat=json&deleteall"
	echo -e "DELETE_ALL \ncurl -kis -b "$COOKIE" -X DELETE $REQ1"
	curl -kis -b "$COOKIE" -X DELETE $REQ1 
	linebreaker;
}

function logout(){
	REQ1=$URLS/logout
	echo -e "LOGOUT \ncurl -kis -b "$COOKIE" -X GET $REQ1"
	# curl -kis -b "$COOKIE" -o /dev/null -X GET $REQ1 
	curl -kis -b "$COOKIE" -X GET $REQ1 | xmllint --html -
	linebreaker;
}

#####	MAIN	#####

login
# put
get
# delete
# delete_all
# logout


