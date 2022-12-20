#!/bin/bash


help () {
    cat << EOF
Usage: files.sh [OPTION]... [POSITIONAL_ARGUMENT]...
Hmm, how should it work?!
EOF
exit 0;
}


# ===================
# = PARSE ARGUMENTS =
# ===================

POSITIONAL_ARGUMENTS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
        help
        ;;
    -s|--searchpath)
        SEARCHPATH="$2"
        shift
        shift # past value
        ;;
    --default)
        DEFAULT=YES
        shift
        ;;
    -*|--*)
        echo "Unknown option $1" 1>&2
        help
        exit 1
        ;;
    *)
        POSITIONAL_ARGUMENTS+=("$1")
        shift
        ;;
  esac
done

echo "${POSITIONAL_ARGUMENTS[@]}"

set -- "${POSITIONAL_ARGUMENTS[@]}"


echo "FILE EXTENSION  = ${EXTENSION}"
echo "SEARCH PATH    = ${SEARCHPATH}"
echo "DEFAULT        = ${DEFAULT}"
# echo "Number files in SEARCH PATH with EXTENSION:" $(ls -1 "${SEARCHPATH}"/*."${EXTENSION}" | wc -l)

# ================
# = LOAD FOLDERS =
# ================




# ==============
# = LOAD FILES =
# ==============




# ======================
# = LOOP THROUGH FILES =
# ======================







# ================================
# = FIND DUPLICATE CONTENT FILES =
# ================================

find ./ -type f -print0 | xargs -0 md5sum | sort -k1,32 | uniq -w32 -D


# ====================
# = FIND EMPTY FILES =
# ====================

find ./ -type f -size 0


# ========================
# = FIND SAME NAME FILES =
# ========================

find $DIRECTORY -type f | sed 's_.*/__' | sort|  uniq -d | 
while read fileName;do
    find $DIRECTORY -type f | grep "$fileName"
done
