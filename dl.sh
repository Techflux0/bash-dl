#!/data/data/com.termux/files/usr/bin/bash

DOWNLOAD_DIR="/storage/emulated/0/Download"

if ! command -v python > /dev/null; then
    echo "[*] Installing Python..."
    pkg install -y python
fi

if ! command -v pip > /dev/null; then
    echo "[*] Installing pip..."
    pkg install -y python-pip
fi

if ! command -v ffmpeg > /dev/null; then
    echo "[*] Installing ffmpeg..."
    pkg install -y ffmpeg
fi

if ! python -c "import yt_dlp" 2>/dev/null; then
    echo "[*] Installing yt-dlp..."
    pip install -U yt-dlp
fi

if [ ! -d "$DOWNLOAD_DIR" ]; then
    echo "[*] Setting up Termux storage..."
    termux-setup-storage
    sleep 2
fi

echo "What do you want to download?"
echo "1 = Audio only"
echo "2 = Full Video"
read -p "Enter choice [1 or 2]: " choice

read -p "Paste YouTube URL: " url

echo "$url" > .url.txt

if [ "$choice" == "1" ]; then
    echo "[*] Running audio downloader..."
    python audio.py "$(cat .url.txt)"
elif [ "$choice" == "2" ]; then
    echo "[*] Running video downloader..."
    python video.py "$(cat .url.txt)"
else
    echo "Invalid choice."
    exit 1
fi

rm -f .url.txt


