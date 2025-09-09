#!/usr/bin/env python3
"""
TransNetV2 scene-based video splitter with FFmpeg NVENC
Automatically installs missing Python modules if needed.

Usage:
    python split_scenes_transnet.py input.mp4

Output:
    input_scene_0.mp4, input_scene_1.mp4, ...
Requirements:
    - FFmpeg with NVIDIA NVENC support
    - NVIDIA drivers installed
    - CUDA GPU recommended for faster detection
"""

import subprocess
import sys
import os

# -----------------------------
# AUTO-INSTALL REQUIRED MODULES
# -----------------------------
required_modules = ["torch", "transnetv2"]

for module in required_modules:
    try:
        __import__(module)
    except ImportError:
        print(f"Module '{module}' not found. Installing...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", module])

# Now import the modules
import torch
import transnetv2

# -----------------------------
# CHECK INPUT
# -----------------------------
if len(sys.argv) < 2:
    print("Usage: python split_scenes_transnet.py input.mp4")
    sys.exit(1)

video_path = sys.argv[1]
basename = os.path.splitext(os.path.basename(video_path))[0]

# -----------------------------
# STEP 1: Load TransNetV2 model
# -----------------------------
device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"Using device: {device}")
model = transnetv2.TransNetV2()
model.load_model(device=device)

# -----------------------------
# STEP 2: Detect scenes
# -----------------------------
print("Detecting scenes with TransNetV2...")
predictions = model.detect_scenes_video(video_path)

if not predictions:
    print("No scene changes detected.")
    sys.exit(1)

# -----------------------------
# STEP 3: Filter very short scenes (<2 sec)
# -----------------------------
min_duration = 2.0  # seconds
filtered_predictions = [predictions[0]]
for t in predictions[1:]:
    if t - filtered_predictions[-1] >= min_duration:
        filtered_predictions.append(t)
predictions = filtered_predictions

print(f"Detected {len(predictions)-1} scenes after filtering short scenes.")

# -----------------------------
# STEP 4: Split video with FFmpeg NVENC
# -----------------------------
for i in range(len(predictions)-1):
    start = predictions[i]
    end = predictions[i+1]
    output_file = f"{basename}_scene_{i}.mp4"

    cmd = [
        "ffmpeg",
        "-hwaccel", "cuda",        # GPU decode
        "-i", video_path,
        "-ss", str(start),
        "-to", str(end),
        "-c:v", "h264_nvenc",      # GPU encode
        "-preset", "fast",
        "-cq", "23",               # quality
        "-c:a", "copy",
        output_file
    ]
    print(f"Processing scene {i}: {start:.2f}s → {end:.2f}s")
    subprocess.run(cmd, check=True)

print(" Done! Scenes saved as *_scene_#.mp4")

