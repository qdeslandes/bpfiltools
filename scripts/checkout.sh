#!/bin/sh

set -ueo pipefail

usage()
{
   echo ""
   echo "Usage: $0 -r REPOSITORY_PATH -g GIT_REFERENCE"
   echo -e "\t-r Repository path"
   echo -e "\t-g Git reference to checkout"
   exit 1
}

REPOSITORY_PATH=
GIT_REF=

while getopts "r:g:" opt
do
   case "$opt" in
      r ) REPOSITORY_PATH="$OPTARG" ;;
      g ) GIT_REF="$OPTARG" ;;
      ? ) usage ;;
   esac
done

[ -z "$REPOSITORY_PATH" ] && { echo "Missing repository path"; usage; }
[ -z "$GIT_REF" ] && { echo "Missing git reference"; usage; }

git -C ${REPOSITORY_PATH} fetch --all --prune --tags
git -C ${REPOSITORY_PATH} checkout ${GIT_REF}
