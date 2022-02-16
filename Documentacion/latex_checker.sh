#!/bin/bash

# 
# Defining a few variables...
#
LATEXCMD="/usr/bin/pdflatex"
LATEXDOC_DIR="/home/javi/Nextcloud/Universidad/Master/TFM/Documentacion"
MD5SUMS_FILE="$LATEXDOC_DIR/md5.sum"

#
# This function checks whether a file needs to be updated,
# and calls LATEXCMD if necessary. It is called for each
# .tex file in LATEXDOC_DIR (see below the function).
#
update_file()
{
    [[ $# -ne 1 ]] && return;
    [[ ! -r "$1" ]] && return;

    # Old MD5 hash is in $MD5SUMS_FILE, let's get it.
    OLD_MD5=$(grep "$file" "$MD5SUMS_FILE" | awk '{print $1}')

    # New MD5 hash is obtained through md5sum.
    NEW_MD5=$(md5sum "$file" | awk '{print $1}')

    # If the two MD5 hashes are different, then the files changed.
    if [ "$OLD_MD5" != "$NEW_MD5" ]; then
        echo "$LATEXCMD" -output-directory $(dirname "$file") "$file"

        # Calling the compiler.
        "$LATEXCMD" -output-directory $(dirname "$file") "$file" > /dev/null
        LTX=$?

        # There was no "old MD5", the file is new. Add its hash to $MD5SUMS_FILE.
        if [ -z "$OLD_MD5" ]; then
            echo "$NEW_MD5 $file" >> "$MD5SUMS_FILE"
        # There was an "old MD5", let's use sed to replace it.
        elif [ $LTX -eq 0 ]; then
            sed "s|^.*\b$OLD_MD5\b.*$|$NEW_MD5 $file|" "$MD5SUMS_FILE" -i
        fi
    fi
}

# Create the MD5 hashes file.
[[ ! -f "$MD5SUMS_FILE" ]] && touch "$MD5SUMS_FILE"

IFS=$'\n'
find "$LATEXDOC_DIR" -iname "*.tex" | while read file; do
    # For each .tex file, call update_file.
    update_file "$file"
done
