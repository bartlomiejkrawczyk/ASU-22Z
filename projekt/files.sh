#!/bin/bash

set -euxo pipefail
# set -euo pipefail
# set -eu pipefail

help () {
    cat << EOF
Usage: files.sh [OPTION] [CATALOG]...
    -h --help     Display this message
    -x --catalog  Specify the default catalog X
EOF
exit 0;
}

source ./.clean_files

# ===================
# = PARSE ARGUMENTS =
# ===================

CATALOGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
        help
        ;;
    -x|--catalog)
        DEFAULT_CATALOG="$2"
        shift
        shift
        ;;
    -*|--*)
        echo "Unknown option $1" 1>&2
        help
        exit 1
        ;;
    *)
        CATALOGS+=("$1")
        shift
        ;;
  esac
done

# set -- "${CATALOGS[@]}"


# ===========================
# = DUPLICATE CONTENT FILES =
# ===========================

duplicates () {
    find "${CATALOGS[@]}" -type f -print0 | xargs -0 md5sum -z | sort -k1,32 -z | uniq -w32 -z -D
}

handle_duplicate_files () {
    echo Detected duplicate files: "${FILES[@]}"
    TIMES_CREATED=()

    FILE_CREATED_FIRST="$FILES"
    MIN_TIME=$(stat "$FILE_CREATED_FIRST" -c %Y)

    for FILE in "${FILES[@]}"; do
        TIME=$(stat "$FILE" -c %Y)
        TIMES_CREATED+=("$TIME")

        if [[ ${MIN_TIME} -gt ${TIME} ]]; then
            MIN_TIME="$TIME"
            FILE_CREATED_FIRST="$FILE"
        fi
    done

    echo "${TIMES_CREATED[@]}"

    read -p "Do you want to remove all the duplicates and leave only: $FILE_CREATED_FIRST? [y/n] " REMOVE_DUPLICATES </dev/tty

    if [[ "$REMOVE_DUPLICATES" = "y" ]]; then
        for FILE in "${FILES[@]}"; do
            if [[ "$FILE" != "$FILE_CREATED_FIRST" ]]; then
                rm "$FILE"
            fi
        done
    fi
}

handle_duplicates () {
    duplicates  | {

        FILES=()
        PREVIOUS_HASH=""

        while IFS= read -r -d $'\0' HASH_FILENAME; do

            FILENAME=$(echo "$HASH_FILENAME" | cut -c 35-)

            HASH=$(echo "$HASH_FILENAME" | cut -c -31)

            if [[ "$PREVIOUS_HASH" != "$HASH" ]]; then
                if [[ "$PREVIOUS_HASH" != "" ]]; then
                    handle_duplicate_files
                fi

                FILES=("$FILENAME")
                PREVIOUS_HASH="$HASH"
            else
                FILES+=("$FILENAME")
            fi
        done
    }
}

# handle_duplicates

# ===============
# = EMPTY FILES =
# ===============

empty () {
    find "${CATALOGS[@]}" -type f -size 0 -print0
}

handle_empty () {
    empty  | {
        while IFS= read -r -d $'\0' FILENAME; do

            read -p "Do you want to remove empty file: $FILENAME? [y/n] " REMOVE_EMPTY </dev/tty

            if [[ "$REMOVE_EMPTY" = "y" ]]; then
                rm "$FILENAME"
            fi
        done
    }
}

# handle_empty

# ===================
# = TEMPORARY FILES =
# ===================

temporary () {
    find "${CATALOGS[@]}" -type f -regex "$TMP_FILES" -print0
}

handle_temporary () {
    temporary  | {
        while IFS= read -r -d $'\0' FILENAME; do

            read -p "Do you want to remove temporary file: $FILENAME? [y/n] " REMOVE_TEMPORARY </dev/tty

            if [[ "$REMOVE_TEMPORARY" = "y" ]]; then
                rm "$FILENAME"
            fi
        done
    }
}

# handle_temporary

# ===================
# = SAME NAME FILES =
# ===================

same_name () {
    find "${CATALOGS[@]}" -type f -print0 | sed 's_.*/__' -z | sort -z |  uniq -z -d
}

handle_same_name_files () {
    echo $FILENAME
    FILES=()
    TIMES_CREATED=()
    FILE_LAST_CREATED="a"
    MAX_TIME=0

    find "${CATALOGS[@]}" -name "$FILENAME" -print0 | {
        while IFS= read -r -d $'\0' FILE; do
            FILES+=("$FILE")
            TIME=$(stat "$FILE" -c %Y)
            TIMES_CREATED+=("$TIME")

            if [[ ${TIME} > ${MAX_TIME} ]]; then
                MAX_TIME="$TIME"
                FILE_LAST_CREATED="$FILE"
            fi

            echo $FILE
        done

        echo "Found files with same name: ${FILES[@]}"
        read -p "Do you want to leave only: $FILE_LAST_CREATED? [y/n] " REMOVE_SAME_NAME </dev/tty

        if [[ "$REMOVE_SAME_NAME" = "y" ]]; then
            for FILE in "${FILES[@]}"; do
                if [[ "$FILE" != "$FILE_LAST_CREATED" ]]; then
                    rm "$FILE"
                fi
            done
        fi
    }
}

handle_same_name () {
    same_name  | {
        while IFS= read -r -d $'\0' FILENAME; do
            handle_same_name_files
        done
    }
}

# handle_same_name

# =============================
# = FILES WITH STRANGE ACCESS =
# =============================

strange_access () {
    find "${CATALOGS[@]}" -type f -not -perm "$SUGGESTED_ACCESS" -print0
}

# strange_access

# ===================================
# = FILES CONTAINING TRICKY LETTERS =
# ===================================


tricky_letters () {
    find "${CATALOGS[@]}" -type f -print0 | grep -e "[${TRICKY_LETTERS}]" -z
}

# tricky_letters


# ======================
# = LOOP THROUGH FILES =
# ======================

# set -- "${CATALOGS[@]}"

# while [[ $# -gt 0 ]]; do
#   case $1 in
#     -h|--help)
#         help
#         ;;
#   esac
# done

# set -- "${CATALOGS[@]}"

