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

if [ "$first_line" -eq 2 ]; then
    echo "It is an ADD/SUB program"

    value1=$(sed -n '2p' "$1")
    value2=$(sed -n '3p' "$1")

    output_file="${1%.vsc}.bin"

    # write static values
    printf "\\x$(printf '%02x' "$value1")" > "$output_file"
    printf "\\x$(printf '%02x' "$value2")" >> "$output_file"

    # read instructions from line 4 onwards
    tail -n +4 "$1" | while IFS=',' read -r instruction reg mem
    do
        case "$instruction" in
            LOAD)
                opcode=1
                ;;
            STORE)
                opcode=2
                ;;
            ADD)
                opcode=3
                ;;
            SUB)
                opcode=4
                ;;
            QUIT)
                opcode=8
                ;;
            PRINT)
                opcode=9
                ;;
            *)
                echo "usage: invalid instruction – no .bin file is produced"
                rm -f "$output_file"
                exit 1
                ;;
        esac

        first_byte=$(( (opcode << 2) | reg ))

        printf "\\x$(printf '%02x' "$first_byte")" >> "$output_file"
        printf "\\x$(printf '%02x' "$mem")" >> "$output_file"

        if [ "$instruction" = "QUIT" ]; then
            break
        fi
    done

    echo "The content of the .bin file is"
    xxd -p -c 1 "$output_file"

    exit 0
fi