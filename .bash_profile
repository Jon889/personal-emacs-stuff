export PS1="\W \u\$ "

alias glb='git -c color.ui=always branch --list | tr -d " *" | awk '\''{printf("%d %s\n", NR, $0)}'\'' 1>&2'
alias gbn='git checkout -b'
alias gs='git status'
alias gbname='git symbolic-ref --short -q HEAD'
gbnum() {
	BRANCH_NO=$1
	if [ -z "$BRANCH_NO" ]
	then
		glb
		read BRANCH_NO
	fi
	echo `git branch --list | tr -d " *" | sed -n "${BRANCH_NO}p"`
}
gco() {
	CURR_BRANCH=`gbname`
	re='^[0-9]+$'
	case $1 in
	''|[0-9]|[0-9][0-9])
		git checkout "`gbnum $1`"
		;;
	d|dev)
		git checkout develop
		;;
	-)
		git checkout "$OLD_GBNAME"
		;;
	*)
		git checkout "$1"
		;;
	esac
	export OLD_GBNAME=$CURR_BRANCH
}


gbd() {
	git branch -d `gbnum $1`
}

gstash() {
	git stash save "$1"
}

gmr() {
	UNMERGED=`git diff --name-only --diff-filter=U`
	echo "Unmerged files:"

	echo -e "\033[31m"
	echo "$UNMERGED" | \
	while read FILE; do
		echo -e "\t$FILE"
	done
	echo -e "\033[0m"

	echo "$UNMERGED" | \
	while read FILE; do
		echo "Opening $FILE"
		open "$FILE"
		read -p "Resolved? [y|n]" </dev/tty
		if [ "$REPLY" != "" ]
		then
			git add "$FILE"
		fi
	done
}

gbnt() {
	gbn `jatbn`
}

gcot() {
	gco `jatbn`
}

parsejson() {
	python -c "import json,sys;print(json.load(sys.stdin)$1);"
}
jatjson() {
	PSWD=`security find-internet-password -ws "jira.global.tesco.org" -a "$TESCO_TPX"`
	curl -s -u "$TESCO_TPX":"$PSWD" "https://jira.global.tesco.org/rest/api/latest/search?jql=project=ONA%20AND%20status=\"In%20Dev\"%20AND%20assignee=$TESCO_TPX&fields=summary,description"
	echo ""
}
jat() {
	RESP=`jatjson`
#	echo -en "\033[32m"
	echo $RESP | parsejson "['issues'][0]['key']"
	echo $RESP | parsejson "['issues'][0]['fields']['summary']"
#	echo -en "\033[0m"
	echo $RESP | parsejson "['issues'][0]['fields']['description']"
}

jatbn() {
	RESP=`jatjson`
	NUM_ISSUES=`echo $RESP | parsejson "['issues'].__len__()"`
	if [[ $NUM_ISSUES -eq 1 ]]; then
		KEY=`echo $RESP | parsejson "['issues'][0]['key']" | sed s/ONA-//`
		SUMMARY=`echo $RESP | parsejson "['issues'][0]['fields']['summary']" | tr '[:upper:]' '[:lower:]' | sed s/^\\\[ios\\\]\ *-*\ *//g | tr " " "-" | sed 's/-\{2,\}/-/g'`
		read -p "Summary: [$SUMMARY]" </dev/tty
		if [ "$REPLY" != "" ]
		then
			SUMMARY="$REPLY"
		fi
		echo feature/jon-$KEY-$SUMMARY
	else
		echo "Multiple In Dev issues not supported yet"
	fi
}
