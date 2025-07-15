#!/data/data/com.termux/files/usr/bin/bash

DOWNLOAD_DIR="/storage/emulated/0/Download"

# ---------- Setup: Environment ---------- #

# Function to install a package if not already installed
install_if_missing() {
    if ! command -v "$1" > /dev/null; then
        echo "[*] Installing $1..."
        pkg install -y "$1"
    fi
}

echo "[*] Checking and installing required packages..."
install_if_missing python
install_if_missing ffmpeg
install_if_missing curl

# pip install yt-dlp if not already
if ! python -c "import yt_dlp" 2>/dev/null; then
    echo "[*] Installing yt-dlp..."
    pip install -U yt-dlp
fi

# Setup storage permission
if [ ! -d "$DOWNLOAD_DIR" ]; then
    echo "[*] Setting up Termux storage..."
    termux-setup-storage
    sleep 2
fi

# ---------- Setup: Starship Prompt ---------- #

echo "[*] Checking and installing starship prompt..."
if ! command -v starship > /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Add starship init to .bashrc if not already present
if ! grep -q 'starship init bash' ~/.bashrc; then
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
fi

# Create starship config
mkdir -p ~/.config
cat > ~/.config/starship.toml << 'EOF'
add_newline = true
format = """
$directory\
$git_branch\
$git_status\
$nodejs\
$python\
$cmd_duration\
$line_break\
$character
"""

[directory]
style = "blue"
truncate_to_repo = false

[git_branch]
symbol = "🌱 "
style = "green"

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✗](bold red)"
EOF


echo ""
echo "=============================="
echo "   Downloader Menu"
echo "=============================="
echo "1 = Audio only"
echo "2 = Full Video"
read -p "Enter choice [1 or 2]: " choice


read -p "Paste YouTube URL: " url
echo "$url" > .url.txt


if [ "$choice" == "1" ]; then
    echo "[*] Running audio downloader..."
    python dl.py "$(cat .url.txt)"
elif [ "$choice" == "2" ]; then
    echo "[*] Running video downloader..."
    python video_dl.py "$(cat .url.txt)"
else
    echo "Invalid choice."
    exit 1
fi


rm -f .url.txt

echo ""
echo "[✓] Done! If it's your first time, restart Termux or run: source ~/.bashrc"
