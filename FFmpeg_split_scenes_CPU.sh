#!/bin/bash
# Usage: ./split_scenes.sh input.mp4

INPUT="$1"
BASENAME=$(basename "$INPUT" .mp4)
SCENES_FILE="scenes.txt"

# Step 1: Detect scene changes and save timestamps
ffmpeg -i "$INPUT" -filter_complex "select='gt(scene,0.4)',metadata=print:file=$SCENES_FILE" -vsync vfr -f null -

# Step 2: Parse timestamps
TIMES=($(grep -oP "(?<=pts_time:)[0-9.]+" $SCENES_FILE))

# Add start (0.0) and end (video duration)
DURATION=$(ffprobe -i "$INPUT" -show_entries format=duration -v quiet -of csv="p=0")
TIMES=(0.0 "${TIMES[@]}" "$DURATION")

# Step 3: Cut video by timestamps
for ((i=0; i<${#TIMES[@]}-1; i++)); do
    START=${TIMES[$i]}
    END=${TIMES[$((i+1))]}
    ffmpeg -i "$INPUT" -ss "$START" -to "$END" -c copy "${BASENAME}_scene_$i.mp4"
done

echo "Done! Scenes saved as ${BASENAME}_scene_0.mp4, _scene_1.mp4, ..."
