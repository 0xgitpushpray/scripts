#!/usr/bin/env python3
"""
Scene-based video splitter using PySceneDetect + FFmpeg NVENC
Usage:
    python split_scenes_gpu.py input.mp4
Output:
    input_scene_0.mp4, input_scene_1.mp4, ...
Requirements:
    - PySceneDetect: pip install scenedetect
    - FFmpeg with NVIDIA NVENC support
    - NVIDIA drivers installed
"""

import os
import subprocess
import sys
from scenedetect import VideoManager, SceneManager
from scenedetect.detectors import ContentDetector

# -----------------------------
# Check input
# -----------------------------
if len(sys.argv) < 2:
    print("Usage: python split_scenes_gpu.py input.mp4")
    sys.exit(1)

input_file = sys.argv[1]
basename = os.path.splitext(os.path.basename(input_file))[0]

# -----------------------------
# Step 1: Detect scenes
# -----------------------------
video_manager = VideoManager([input_file])
scene_manager = SceneManager()
scene_manager.add_detector(ContentDetector(threshold=30.0))  # tune threshold if needed

video_manager.start()
scene_manager.detect_scenes(frame_source=video_manager)
scene_list = scene_manager.get_scene_list()

video_manager.release()

if not scene_list:
    print("No scenes detected.")
    sys.exit(1)

print(f"Detected {len(scene_list)} scenes.")

# -----------------------------
# Step 2: Split video with FFmpeg NVENC
# -----------------------------
for i, (start, end) in enumerate(scene_list):
    start_time = start.get_seconds()
    end_time = end.get_seconds()
    output_file = f"{basename}_scene_{i}.mp4"

    # FFmpeg command with NVIDIA NVENC encoding
    cmd = [
        "ffmpeg",
        "-hwaccel", "cuda",        # GPU decode
        "-i", input_file,
        "-ss", str(start_time),
        "-to", str(end_time),
        "-c:v", "h264_nvenc",      # GPU encode
        "-preset", "fast",
        "-cq", "23",               # quality
        "-c:a", "copy",
        output_file
    ]
    print(f"Processing scene {i}: {start_time:.2f}s → {end_time:.2f}s")
    subprocess.run(cmd, check=True)

print("Done! Scenes saved as *_scene_#.mp4")

