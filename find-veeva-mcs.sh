#!/bin/bash

# $version: 1.0.0

usage() {
	cat <<EOF
Find the storage location of a running Veeva iRep simulator slide

Usage: $(basename $0) [--find=val] [--format=val] [--help | -h] ["slide_url"]

slide_url   URL of running slide, copy from Safari debugger. Remember to quote it

--find=html     Find slide HTML directory. This is the default
--find=db       Find iRep database (SQLite) directory

--format=info   Describe discovered location info. This is the default
--format=pipe   Output found directory only, e.g. to be piped to another command

--paste         Copy location into MacOS pasteboard

--help|-h       Show this message
EOF
}

URL=""
FIND=html
FORMAT=info
if [[ ! -t 1 ]] ; then
	FORMAT=pipe
fi
PASTE=0

for arg in $*
do
	case $arg in
		--find=html)
			FIND=html
		;;
		--find=db)
			FIND=db
		;;
		--format=info)
			FORMAT=info
		;;
		--format=pipe)
			FORMAT=pipe
		;;
		--paste)
			PASTE=1
		;;
		--help|-h)
			usage
			exit
		;;
		*)
			URL="$URL$arg"
		;;
	esac
done

if [[ -z "$URL" ]] ; then
	echo
	read -p 'Please paste simulator page URL: ' URL
	if [[ -z "$URL" ]] ; then
		echo "Missing slide_url"
		usage
		exit 1
	fi
fi

T=($(node - "$URL" <<EOF
const m = /^[^\/]+\/\/[^\/]+\/[^\/]+\/([^\/]+)\/([^\/]+)\/([^\/]+)/.exec(process.argv[2]);
process.stdout.write(m[1] + ' ' + m[2] + ' ' + m[3]);
EOF
))
DOCUMENT_OBJECT_ID=${T[0]}
DOCUMENT_VERSION_HASH=${T[1]}
SLIDE_NAME=${T[2]}

# Determine all relevant directories
SIMULATOR_DIR="$HOME/Library/Developer/CoreSimulator/Devices"
DEVICE_DIR=$(dirname $(ls -t "$SIMULATOR_DIR"/*/device.plist|head -1))
APPS_DIR=$(ls -d "$DEVICE_DIR"/data/Containers/Data/Application)
IREP_DIR=$(realpath $(ls -d "$APPS_DIR"/*/Library/Veeva/../..))
SLIDE_DIR=$(ls -d "$IREP_DIR"/Documents/*/Media/$DOCUMENT_OBJECT_ID)
USER_IDENT=$(basename $(realpath "$SLIDE_DIR"/../..))
DB_DIR=$(ls -d "$IREP_DIR"/Library/Veeva/$USER_IDENT)
SLIDE_VERSION_DIR=$(ls -d $SLIDE_DIR/$DOCUMENT_VERSION_HASH)
SLIDE_HTML_DIR=$(ls -d "$SLIDE_VERSION_DIR"/$SLIDE_NAME)

case $FIND in
	db)
		LABEL='SQLite database directory'
		VALUE="$DB_DIR"
		;;
	*)
		LABEL='Slide HTML directory'
		VALUE="$SLIDE_HTML_DIR"
		;;
esac

if [[ $PASTE == 1 ]] ; then
	echo -n "$VALUE"|pbcopy
fi

if [[ $FORMAT == 'pipe' ]] ; then
	echo -n "$VALUE"
	exit
fi

if [[ $PASTE == 1 ]] ; then
	echo
	echo "$LABEL copied to pasteboard (cmd+V to paste)"
fi

echo
if [[ -z "$VALUE" ]]; then
    echo -e "\033[31mError: Could not find slide directory with URL \"$URL\"\033[0m"
else
    echo "Multichannel slide directory found:"
    echo "$VALUE"
fi
echo
exit
