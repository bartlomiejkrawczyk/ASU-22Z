#!/bin/bash

# set -euxo pipefail
set -euo pipefail

help () {
    cat << EOF
Usage: files.sh [OPTION] [CATALOG]...
    -h --help        Display this message
    -x --catalog     Specify the default catalog X
       --default     Use default values instead of user input
    -d --duplicates  Remove duplicates
    -e --empty       Remove empty files
    -t --temporary   Remove temporary files
    -s --same-name   Remove files with same name
    -a --access      Change permissions to default value
    -c --copy        Copy files to directory X
    -r --rename      Rename files
EOF
exit 0;
}

source ./.clean_files

# ===================
# = PARSE ARGUMENTS =
# ===================

CATALOGS=()
OPERATIONS=()
DEFAULT_CATALOG="./X"
DEFAULT="n"

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
    -d|--duplicates)
        OPERATIONS+=("DUPLICATES")
        shift
        ;;
    -e|--empty)
        OPERATIONS+=("EMPTY")
        shift
        ;;
    -t|--temporary)
        OPERATIONS+=("TEMPORARY")
        shift
        ;;
    -s|--same-name)
        OPERATIONS+=("SAME")
        shift
        ;;
    -a|--access)
        OPERATIONS+=("ACCESS")
        shift
        ;;
    -c|--copy)
        OPERATIONS+=("COPY")
        shift
        ;;
    -r|--rename)
        OPERATIONS+=("RENAME")
        shift
        ;;
    --default)
        DEFAULT="y"
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

    if [[ "$DEFAULT" = "y" ]]; then
        for FILE in "${FILES[@]}"; do
            if [[ "$FILE" != "$FILE_CREATED_FIRST" ]]; then
                echo "Removing duplicate file: $FILE"
                rm "$FILE"
            fi
        done
    else
        read -p "Do you want to remove all the duplicates and leave only: $FILE_CREATED_FIRST? [y/n] " REMOVE_DUPLICATES </dev/tty

        if [[ "$REMOVE_DUPLICATES" = "y" ]]; then
            for FILE in "${FILES[@]}"; do
                if [[ "$FILE" != "$FILE_CREATED_FIRST" ]]; then
                    rm "$FILE"
                fi
            done
        fi
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

# ===============
# = EMPTY FILES =
# ===============

empty () {
    find "${CATALOGS[@]}" -type f -size 0 -print0
}

handle_empty () {
    empty  | {
        while IFS= read -r -d $'\0' FILENAME; do

            if [[ "$DEFAULT" = "y" ]]; then
                echo "Removing empty file: $FILENAME"
                rm "$FILENAME"
            else
                read -p "Do you want to remove empty file: $FILENAME? [y/n] " REMOVE_EMPTY </dev/tty

                if [[ "$REMOVE_EMPTY" = "y" ]]; then
                    rm "$FILENAME"
                fi
            fi
        done
    }
}

# ===================
# = TEMPORARY FILES =
# ===================

temporary () {
    find "${CATALOGS[@]}" -type f -regex "$TMP_FILES" -print0
}

handle_temporary () {
    temporary  | {
        while IFS= read -r -d $'\0' FILENAME; do
            if [[ "$DEFAULT" = "y" ]]; then
                echo "Removing temprary file: $FILENAME"
                rm "$FILENAME"
            else
                read -p "Do you want to remove temporary file: $FILENAME? [y/n] " REMOVE_TEMPORARY </dev/tty

                if [[ "$REMOVE_TEMPORARY" = "y" ]]; then
                    rm "$FILENAME"
                fi
            fi
        done
    }
}

# ===================
# = SAME NAME FILES =
# ===================

same_name () {
    find "${CATALOGS[@]}" -type f -print0 | sed 's_.*/__' -z | sort -z |  uniq -z -d
}

handle_same_name_files () {
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
        done

        if [[ "$DEFAULT" = "y" ]]; then
            for FILE in "${FILES[@]}"; do
                if [[ "$FILE" != "$FILE_LAST_CREATED" ]]; then
                    echo "Removing same name file: $FILE"
                    rm "$FILE"
                fi
            done
        else
            echo "Found files with same name: ${FILES[@]}"
            read -p "Do you want to leave only: $FILE_LAST_CREATED? [y/n] " REMOVE_SAME_NAME </dev/tty

            if [[ "$REMOVE_SAME_NAME" = "y" ]]; then
                for FILE in "${FILES[@]}"; do
                    if [[ "$FILE" != "$FILE_LAST_CREATED" ]]; then
                        rm "$FILE"
                    fi
                done
            fi
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

# =============================
# = FILES WITH STRANGE ACCESS =
# =============================

strange_access () {
    find "${CATALOGS[@]}" -type f -not -perm "$SUGGESTED_ACCESS" -print0
}

handle_strange_access () {
    strange_access | {
        while IFS= read -r -d $'\0' FILENAME; do

            if [[ "$DEFAULT" = "y" ]]; then
                echo "Modifying access to file: $FILENAME"
                chmod "-777" "$FILENAME"
                chmod "+$SUGGESTED_ACCESS" "$FILENAME"
            else
                echo "Detected file with strange access: $FILENAME"
                read -p "Do you want to change the access to default value? [y/n] "  CHANGE_STRANGE_ACCESS </dev/tty
                if [[ "$CHANGE_STRANGE_ACCESS" = "y" ]]; then
                    chmod "-777" "$FILENAME"
                    chmod "+$SUGGESTED_ACCESS" "$FILENAME"
                fi
            fi
        done
    }
}

# ===================================
# = FILES CONTAINING TRICKY LETTERS =
# ===================================

tricky_letters () {
    find "${CATALOGS[@]}" -type f -print0 | grep -e "[${TRICKY_LETTERS}]" -z
}

handle_tricky_letters () {
    tricky_letters | {
        while IFS= read -r -d $'\0' FILENAME; do

            if [[ "$DEFAULT" = "y" ]]; then
                NEW_NAME=$(echo "$FILENAME" | sed "s/[${TRICKY_LETTERS}]/${TRICKY_LETTER_SUBSTITUTE}/g")
                echo "Replacing $FILENAME with $NEW_NAME"
                mv -f -- "$FILENAME" "$NEW_NAME"
            else
                echo "Detected file with tricky letters: $FILENAME"

                read -p "Do you want to replace those letters with default value? [y/n] "  REPLACE_TRICKY_LETTERS </dev/tty

                if [[ "$REPLACE_TRICKY_LETTERS" = "y" ]]; then
                    NEW_NAME=$(echo "$FILENAME" | sed "s/[${TRICKY_LETTERS}]/${TRICKY_LETTER_SUBSTITUTE}/g")
                    mv -- "$FILENAME" "$NEW_NAME"
                fi
            fi
        done
    }
}

# =======================
# = MOVE TO DIRECTORY X =
# =======================


handle_files_from_other_directories () {
    SEARCH_CATALOGS=()
    for CATALOG in "${CATALOGS[@]}"; do
        if [[ "$CATALOG" != "$DEFAULT_CATALOG" ]]; then
            find "$CATALOG" -type f -print0 | {
                while IFS= read -r -d $'\0' FILENAME; do

                    if [[ "$DEFAULT" = "y" ]]; then
                        echo "Copying $FILENAME to catalog $DEFAULT_CATALOG"
                        CLEAR_CATALOG=$(echo "$CATALOG" | sed 's/\//\\\//g')
                        CLEAR_DEFAULT=$(echo "$DEFAULT_CATALOG" | sed 's/\//\\\//g')
                        NEW_FILENAME=$(echo "$FILENAME" | sed "0,/$CLEAR_CATALOG/{s/$CLEAR_CATALOG/$CLEAR_DEFAULT/}")
                        mkdir -p $(dirname "$NEW_FILENAME")
                        cp -r -- "$FILENAME" "$NEW_FILENAME"
                    else
                        read -p "Do you want to copy the file $FILENAME to $DEFAULT_CATALOG? [y/n] " COPY_FILE </dev/tty

                        if [[ "$COPY_FILE" = "y" ]]; then
                            CLEAR_CATALOG=$(echo "$CATALOG" | sed 's/\//\\\//g')
                            CLEAR_DEFAULT=$(echo "$DEFAULT_CATALOG" | sed 's/\//\\\//g')
                            NEW_FILENAME=$(echo "$FILENAME" | sed "0,/$CLEAR_CATALOG/{s/$CLEAR_CATALOG/$CLEAR_DEFAULT/}")
                            mkdir -p $(dirname "$NEW_FILENAME")
                            cp -r -- "$FILENAME" "$NEW_FILENAME"
                        fi
                    fi
                done
            }
        fi
    done

}

# ===============
# = RENAME FILE =
# ===============

handle_rename_files () {
    find "${CATALOGS[@]}" -type f -print0 | {
        while IFS= read -r -d $'\0' FILENAME; do
            read -p "Do you want to rename file: $FILENAME? [y/n] "  RENAME_FILE </dev/tty

            if [[ "$RENAME_FILE" = "y" ]]; then
                read -p "Provide new name: " NEW_FILENAME </dev/tty
                mv -- "$FILENAME" "$NEW_FILENAME"
            fi
        done
    }
}

# ===========================
# = LOOP THROUGH OPERATIONS =
# ===========================

for OPERATION in "${OPERATIONS[@]}"; do
    case "$OPERATION" in
        DUPLICATES)
            handle_duplicates
            ;;
        EMPTY)
            handle_empty
            ;;
        TEMPORARY)
            handle_temporary
            ;;
        SAME)
            handle_same_name
            ;;
        ACCESS)
            handle_strange_access
            ;;
        COPY)
            handle_files_from_other_directories
            ;;
        RENAME)
            handle_rename_files
            ;;
    esac
done
