#!/bin/bash

# -------------------------
# Check command-line input
# -------------------------

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


# -------------------------
# Read first line
# -------------------------

first_line=$(sed -n '1p' "$1")

# First line can only be 0 or 2
if [[ "$first_line" != "0" && "$first_line" != "2" ]]; then
    echo "usage: invalid first line – no .bin file is produced"
    exit 1
fi


# -------------------------
# QUIT program
# -------------------------

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


# -------------------------
# ADD/SUB program
# -------------------------

if [ "$first_line" -eq 2 ]; then

    value1=$(sed -n '2p' "$1")
    value2=$(sed -n '3p' "$1")


    # Check static values are integers
    if ! [[ "$value1" =~ ^[0-9]+$ ]]; then
        echo "usage: invalid static value – no .bin file is produced"
        exit 1
    fi

    if ! [[ "$value2" =~ ^[0-9]+$ ]]; then
        echo "usage: invalid static value – no .bin file is produced"
        exit 1
    fi


    # Check allowed range
    if [ "$value1" -lt 0 ] || [ "$value1" -gt 128 ]; then
        echo "usage: invalid static value – no .bin file is produced"
        exit 1
    fi

    if [ "$value2" -lt 0 ] || [ "$value2" -gt 128 ]; then
        echo "usage: invalid static value – no .bin file is produced"
        exit 1
    fi


    echo "It is an ADD/SUB program"

    output_file="${1%.vsc}.bin"


    # Write static values
    printf "\\x$(printf '%02x' "$value1")" > "$output_file"
    printf "\\x$(printf '%02x' "$value2")" >> "$output_file"


    # -------------------------
    # Read instructions
    # -------------------------

    instruction_count=0
    found_quit=0

    while IFS=',' read -r instruction reg mem
    do
        instruction_count=$((instruction_count + 1))


        # Day 3:
        # Maximum 100 instructions
        if [ "$instruction_count" -gt 100 ]; then
            echo "usage: too many instructions – no .bin file is produced"
            rm -f "$output_file"
            exit 1
        fi


        # Check empty parts
        if [ -z "$instruction" ] || [ -z "$reg" ] || [ -z "$mem" ]; then
            echo "usage: invalid instruction format – no .bin file is produced"
            rm -f "$output_file"
            exit 1
        fi


        # Check instruction and assign opcode
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


        # Register must be 0, 1, 2 or 3
        if ! [[ "$reg" =~ ^[0-3]$ ]]; then
            echo "usage: invalid register – no .bin file is produced"
            rm -f "$output_file"
            exit 1
        fi


        # Memory address must be an integer
        if ! [[ "$mem" =~ ^[0-9]+$ ]]; then
            echo "usage: invalid memory address – no .bin file is produced"
            rm -f "$output_file"
            exit 1
        fi


        # Memory address must be 0-255
        if [ "$mem" -lt 0 ] || [ "$mem" -gt 255 ]; then
            echo "usage: invalid memory address – no .bin file is produced"
            rm -f "$output_file"
            exit 1
        fi


        # Convert opcode + register into first byte
        first_byte=$(( (opcode << 2) | reg ))


        # Write instruction to .bin
        printf "\\x$(printf '%02x' "$first_byte")" >> "$output_file"
        printf "\\x$(printf '%02x' "$mem")" >> "$output_file"


        # Stop when QUIT is found
        if [ "$instruction" = "QUIT" ]; then
            found_quit=1
            break
        fi

    done < <(tail -n +4 "$1")


    # Make sure a QUIT instruction existed
    if [ "$found_quit" -ne 1 ]; then
        echo "usage: QUIT instruction not found – no .bin file is produced"
        rm -f "$output_file"
        exit 1
    fi


    echo "The content of the .bin file is"
    xxd -p -c 1 "$output_file"

    exit 0
fi