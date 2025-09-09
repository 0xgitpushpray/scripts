#!/bin/bash
# =====================================================
# Full Pop!_OS Cleanup Script (Interactive Large File Deletion Fixed)
# - System caches (APT, logs, temp, Snap)
# - Python caches
# - Empty Trash
# - Interactive deletion of files >500MB in /home
# =====================================================

echo "🧹 Starting full disk cleanup..."

# Show disk usage before cleanup
echo "📊 Disk usage before cleanup:"
df -h

# -----------------------------------------------------
# 1. Remove APT cache
# -----------------------------------------------------
echo "📦 Cleaning APT cache..."
sudo apt-get clean
sudo apt-get autoclean

# -----------------------------------------------------
# 2. Remove unused packages
# -----------------------------------------------------
echo "📦 Removing unused packages..."
sudo apt-get autoremove -y

# -----------------------------------------------------
# 3. Remove old log files
# -----------------------------------------------------
echo "📝 Removing old log files..."
sudo journalctl --vacuum-time=7d

# -----------------------------------------------------
# 4. Clear temp directories
# -----------------------------------------------------
echo "🗑 Clearing temporary files..."
sudo rm -rf /tmp/* /var/tmp/*

# -----------------------------------------------------
# 5. Clean Snap package cache
# -----------------------------------------------------
if command -v snap >/dev/null 2>&1; then
    echo "🐚 Cleaning Snap cache..."
    sudo rm -rf /var/lib/snapd/cache/*
fi

# -----------------------------------------------------
# 6. Clean Python caches
# -----------------------------------------------------
echo "🐍 Cleaning Python cache..."
sudo find / -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
sudo find / -type f -name "*.pyc" -delete 2>/dev/null

# -----------------------------------------------------
# 7. Empty Trash for current user
# -----------------------------------------------------
echo "🗑 Emptying Trash..."
rm -rf ~/.local/share/Trash/* 2>/dev/null

# -----------------------------------------------------
# 8. Interactive deletion of large files in /home
# -----------------------------------------------------
echo "💾 Interactive cleanup of files >500MB in /home..."
while IFS= read -r file; do
    size=$(ls -lh "$file" 2>/dev/null | awk '{print $5}')
    echo -e "\nFile: $file ($size)"
    
    # Read directly from terminal to ensure prompt works
    read -n1 -p "Press 'd' to delete, any other key to skip: " choice </dev/tty
    echo
    if [[ "$choice" == "d" || "$choice" == "D" ]]; then
        rm -f "$file" && echo "✅ Deleted: $file"
    else
        echo "⏭ Skipped: $file"
    fi
done < <(find /home -type f -size +500M)

# -----------------------------------------------------
# Show disk usage after cleanup
# -----------------------------------------------------
echo "📊 Disk usage after cleanup:"
df -h

echo "✅ Full cleanup complete!"

