#!/bin/bash
# ============================================================
# Scene-based video splitter using FFmpeg + NVIDIA GPU (CUDA)
#
# Usage:
#   ./split_scenes_nvidia.sh input.mp4
#
# Output:
#   input_scene_0.mp4, input_scene_1.mp4, ...
#
# Notes:
# - Step 1 detects scene changes with FFmpeg and saves timestamps.
# - Step 2 parses those timestamps into an array.
# - Step 3 cuts the video into scene clips using NVIDIA NVENC.
#
# Requirements:
# - FFmpeg compiled with --enable-nvenc
# - NVIDIA drivers installed and working
# ============================================================

INPUT="$1"
BASENAME=$(basename "$INPUT" .mp4)
SCENES_FILE="scenes.txt"

# ------------------------------------------------------------
# STEP 1: Detect scene changes
# - "gt(scene,0.4)" means detect a new scene if difference > 40%
# - Increase sensitivity with lower values (e.g., 0.3)
# - Output timestamps into scenes.txt
# - "-hwaccel cuda" enables GPU-accelerated decoding
# ------------------------------------------------------------
ffmpeg -hwaccel cuda -i "$INPUT" \
    -filter_complex "select='gt(scene,0.4)',metadata=print:file=$SCENES_FILE" \
    -vsync vfr -f null -

# ------------------------------------------------------------
# STEP 2: Parse timestamps into an array
# - Extracts pts_time values from scenes.txt
# - Adds 0.0 as the start and full video duration as the end
# ------------------------------------------------------------
TIMES=($(grep -oP "(?<=pts_time:)[0-9.]+" $SCENES_FILE))
DURATION=$(ffprobe -i "$INPUT" -show_entries format=duration -v quiet -of csv="p=0")
TIMES=(0.0 "${TIMES[@]}" "$DURATION")

# ------------------------------------------------------------
# STEP 3: Cut video by timestamps
# - Loops through start and end pairs
# - "-c:v h264_nvenc" encodes with NVIDIA NVENC (fast + accurate cuts)
# - "-preset fast" speeds up encoding
# - "-cq 23" sets quality (lower = better quality, larger file size)
# - "-c:a copy" copies audio without re-encoding
#
# TIP: For keyframe-only fast splitting without re-encode,
#      replace "-c:v h264_nvenc ..." with "-c copy"
# ------------------------------------------------------------
for ((i=0; i<${#TIMES[@]}-1; i++)); do
    START=${TIMES[$i]}
    END=${TIMES[$((i+1))]}
    ffmpeg -hwaccel cuda -i "$INPUT" \
        -ss "$START" -to "$END" \
        -c:v h264_nvenc -preset fast -cq 23 \
        -c:a copy "${BASENAME}_scene_$i.mp4"
done

echo "Done! Scenes saved as ${BASENAME}_scene_0.mp4, _scene_1.mp4, ..."

