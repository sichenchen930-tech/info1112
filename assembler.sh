#!/bin/bash

if [ "$#" -eq 0 ]; then
    echo "usage: no argument is provided"
    exit 1
fi

if [ "$#" -gt 1 ]; then
    echo "usage: more than one arguments are provided"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "usage: input is not a file or it does not exist"
    exit 1
fi

if [[ "$1" != *.vsc ]]; then
    echo "usage: input does not have the extension .vsc"
    exit 1
fi

if [ ! -s "$1" ]; then
    echo "usage: the file is empty – no .bin file is produced"
    exit 1
fi

first_line=$(sed -n '1p' "$1")
second_line=$(sed -n '2p' "$1")

if [ "$first_line" -eq 0 ]; then
    if [ "$second_line" = "QUIT,0,0" ]; then
        echo "It is a QUIT program"

        output_file="${1%.vsc}.bin"

        printf '\x20\x00' > "$output_file"

        echo "The content of the .bin file is"
        xxd -p -c 1 "$output_file"

        exit 0
    else
        echo "usage: invalid QUIT program – no .bin file is produced"
        exit 1
    fi
fi