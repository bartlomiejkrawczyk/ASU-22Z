#!/bin/bash


help () {
    cat << EOF
Usage: files.sh [OPTION]... [CATALOG]...
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

set -- "${CATALOGS[@]}"

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

duplicates () {
    find "${CATALOGS[@]}" -type f -print0 | xargs -0 md5sum | sort -k1,32 | uniq -w32 -D | cut -c 35-
}

# duplicates

# ====================
# = FIND EMPTY FILES =
# ====================

empty () {
    find "${CATALOGS[@]}" -type f -size 0
}

# empty

# ========================
# = FIND SAME NAME FILES =
# ========================

same_name () {
    find "${CATALOGS[@]}" -type f | cat | sed 's_.*/__' | sort |  uniq -d | {
        while read FILENAME;do
            find "${CATALOGS[@]}" -name "$FILENAME"
        done
    }
}

# same_name

# ========================
# = FIND TEMPORARY FILES =
# ========================

temporary () {
    find "${CATALOGS[@]}" -type f -regex "$TMP_FILES"
}

# temporary

# ==================================
# = FIND FILES WITH STRANGE ACCESS =
# ==================================

strange_access () {
    find "${CATALOGS[@]}" -type f -not -perm "$SUGGESTED_ACCESS"
}

# strange_access

# ========================================
# = FIND FILES CONTAINING TRICKY LETTERS =
# ========================================


tricky_letters () {
    find "${CATALOGS[@]}" -type f | grep -e "[${TRICKY_LETTERS}]"
}

# tricky_letters