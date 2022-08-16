#!/bin/bash
# A shell script for converting a FLAC album to MP3 V0 and MP3 320kbps and creating .torrent files for OPS and RED.

# Arguments:
# 1:    Directory of folders containing FLAC files
# 2:    Torrent output directory
# 3:    RED announce URL
# 4:    OPS announce URL

# Do not modify.
# Strip trailing "/"
INPUT_DIR=$(echo $1 | sed 's:/*$::')
OUTPUT_DIR=$(echo $2 | sed 's:/*$::')
RED_ANN="$3"
OPS_ANN="$4"
SCRIPT_DIR=$(dirname $0)

# Iterate over each folder.
for folder in "$INPUT_DIR"/*/; do
    folder=$(basename "$folder")
    # First, verify ALL files except for cover are FLAC
    for file in "$INPUT_DIR/$folder"/*; do
        if [[ "$file" != *.flac ]] && [[ "$file" != *cover.jpg ]] && [[ "$file" != *cover.png ]]; then
            echo $file
            continue 2
        fi
    done
    # Move folder to one containing [FLAC] if it doesn't currently.
    if ! [[ "$folder" =~ \[.*\] ]]; then
        mv "$INPUT_DIR/$folder" "$INPUT_DIR/$folder [FLAC]"
    fi
    flac_folder=$(sed 's/\s\[FLAC\]//g' <<<"$folder")
    echo "Processing $flac_folder"
    # Create MP3 V0 and 320kbps folders
    mkdir -p "$INPUT_DIR/$flac_folder [MP3 V0]"
    [ -f "$INPUT_DIR/$flac_folder [FLAC]/cover.jpg" ] && cp "$INPUT_DIR/$flac_folder [FLAC]/cover.jpg" "$INPUT_DIR/$flac_folder [MP3 V0]/cover.jpg"
    [ -f "$INPUT_DIR/$flac_folder [FLAC]/cover.png" ] && cp "$INPUT_DIR/$flac_folder [FLAC]/cover.png" "$INPUT_DIR/$flac_folder [MP3 V0]/cover.png"
    mkdir -p "$INPUT_DIR/$flac_folder [MP3 320]"
    [ -f "$INPUT_DIR/$flac_folder [FLAC]/cover.jpg" ] && cp "$INPUT_DIR/$flac_folder [FLAC]/cover.jpg" "$INPUT_DIR/$flac_folder [MP3 320]/cover.jpg"
    [ -f "$INPUT_DIR/$flac_folder [FLAC]/cover.png" ] && cp "$INPUT_DIR/$flac_folder [FLAC]/cover.png" "$INPUT_DIR/$flac_folder [MP3 320]/cover.png"
    # Iterate through flac files and mux to other dirs
    for file in "$INPUT_DIR/$flac_folder [FLAC]"/*; do
        if [[ "$file" == *.flac ]]; then
            echo "Converting $flac_folder/$file"
            file_name=$(basename "$file")
            file_name_no_ext="${file_name%.*}"
            ffmpeg -i "$INPUT_DIR/$flac_folder [FLAC]/$file_name" -v error -qscale:a 0 -map_metadata 0 -id3v2_version 3 -y "$INPUT_DIR/$flac_folder [MP3 V0]/$file_name_no_ext.mp3" &
            ffmpeg -i "$INPUT_DIR/$flac_folder [FLAC]/$file_name" -v error -ab 320k -map_metadata 0 -id3v2_version 3 -y "$INPUT_DIR/$flac_folder [MP3 320]/$file_name_no_ext.mp3" &
        fi
    done
    wait
    # Now create the associated torrent
    mkdir -p "$OUTPUT_DIR/RED"
    mkdir -p "$OUTPUT_DIR/OPS"
    mktorrent -p -d -x -a "$RED_ANN" -s "RED" -o "$OUTPUT_DIR/RED/$flac_folder [FLAC].torrent" "$INPUT_DIR/$flac_folder [FLAC]" &
    mktorrent -p -d -x -a "$RED_ANN" -s "RED" -o "$OUTPUT_DIR/RED/$flac_folder [MP3 V0].torrent" "$INPUT_DIR/$flac_folder [MP3 V0]" &
    mktorrent -p -d -x -a "$RED_ANN" -s "RED" -o "$OUTPUT_DIR/RED/$flac_folder [MP3 320].torrent" "$INPUT_DIR/$flac_folder [MP3 320]" &
    mktorrent -p -d -x -a "$OPS_ANN" -s "OPS" -o "$OUTPUT_DIR/OPS/$flac_folder [FLAC].torrent" "$INPUT_DIR/$flac_folder [FLAC]" &
    mktorrent -p -d -x -a "$OPS_ANN" -s "OPS" -o "$OUTPUT_DIR/OPS/$flac_folder [MP3 V0].torrent" "$INPUT_DIR/$flac_folder [MP3 V0]" &
    mktorrent -p -d -x -a "$OPS_ANN" -s "OPS" -o "$OUTPUT_DIR/OPS/$flac_folder [MP3 320].torrent" "$INPUT_DIR/$flac_folder [MP3 320]" &
    wait
done
