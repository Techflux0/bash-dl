#!/usr/bin/env bash
detect_os() {
    case "$(uname -o 2>/dev/null || uname)" in
        *Android*) echo "android" ;;
        *Linux*) echo "linux" ;;
        *Darwin*) echo "macos" ;;
        *Msys*|*CYGWIN*|*Windows*) echo "windows" ;;
        *) echo "unknown" ;;
    esac
}
OS=$(detect_os)

case "$OS" in
    android) DOWNLOAD_DIR="/storage/emulated/0/Download/Techflux0" ;;
    windows) DOWNLOAD_DIR="$USERPROFILE/Downloads/Techflux0" ;;
    linux|macos) DOWNLOAD_DIR="$HOME/Downloads/Techflux0" ;;
    *) DOWNLOAD_DIR="./Techflux0" ;;
esac
mkdir -p "$DOWNLOAD_DIR"


install_python() {
    echo "[*] Checking Python..."
    if command -v python >/dev/null 2>&1; then return; fi

    echo "[!] Python not found — installing automatically..."

    case "$OS" in
        android)
            pkg update -y >/dev/null 2>&1
            pkg install -y python >/dev/null 2>&1 ;;
        linux)
            if command -v apt >/dev/null 2>&1; then
                sudo apt update -y >/dev/null 2>&1
                sudo apt install -y python3 python3-pip >/dev/null 2>&1
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y python3 python3-pip >/dev/null 2>&1
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -Syu --noconfirm python python-pip >/dev/null 2>&1
            fi ;;
        macos)
            if ! command -v brew >/dev/null 2>&1; then
                echo "[*] Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
            brew install python >/dev/null 2>&1 ;;
        windows)
            powershell -Command "winget install -e --id Python.Python.3.10 -h" 2>/dev/null ;;
    esac

    if ! command -v python >/dev/null 2>&1; then
        echo "[!] Python installation failed."
        echo "    Please install manually: https://www.python.org/downloads/"
        exit 1
    fi
}
install_python

python -m ensurepip --default-pip >/dev/null 2>&1
python - <<'EOF'
import subprocess, sys

deps = ["yt-dlp", "tqdm", "imageio[ffmpeg]"]

def install(pkg):
    subprocess.run(
        [sys.executable, "-m", "pip", "install", "--upgrade", "-q", pkg],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

for d in deps:
    try:
        __import__(d.split('[')[0])
    except ImportError:
        print(f"[*] Installing {d}...")
        install(d)
EOF

if [ "$OS" = "android" ] && [ ! -d "$DOWNLOAD_DIR" ]; then
    termux-setup-storage >/dev/null 2>&1
fi


while true; do
    echo ""
    echo "===== Techflux YouTube Downloader ====="
    echo "1 = Audio only (MP3)"
    echo "2 = Video (MKV)"
    echo "3 = Playlist (MKV)"
    echo "0 = Exit"
    read -p "Choice [0/1/2/3]: " choice

    [ "$choice" = "0" ] && echo "Exiting..." && break

    read -p "YouTube URL: " url

    python - <<EOF
import os, yt_dlp, imageio_ffmpeg as ffmpeg, threading
from tqdm import tqdm

url = "$url"
choice = "$choice"
download_dir = r"$DOWNLOAD_DIR"
os.makedirs(download_dir, exist_ok=True)
ffmpeg_path = ffmpeg.get_ffmpeg_exe()

# GUI setup
gui_supported = True
try:
    from tkinter import Tk, Label, DoubleVar, ttk

    root = Tk()
    root.title("Github: Techflux0")
    root.geometry("450x200")
    root.resizable(False, False)

    MAC_BG = '#77d1ca'
    MAC_TEXT = '#101012'
    MAC_SECONDARY_TEXT = '#515154'
    MAC_BLUE = '#007AFF'

    style = ttk.Style()
    style.theme_use('clam')

    style.configure('Mac.TFrame', background=MAC_BG)
    style.configure('MacSubtitle.TLabel',
                   font=('SF Pro Text', 12),
                   background=MAC_BG,
                   foreground=MAC_SECONDARY_TEXT)
    style.configure('MacProgress.Horizontal.TProgressbar',
                   background=MAC_BLUE,
                   troughcolor='#e5e5ea',
                   borderwidth=0,
                   thickness=12)

    main_frame = ttk.Frame(root, style='Mac.TFrame', padding=25)
    main_frame.pack(fill='both', expand=True)

    status_label = ttk.Label(main_frame, text="Downloading...", style='MacSubtitle.TLabel')
    status_label.pack(anchor='w', pady=(5, 0))

    card_frame = ttk.Frame(main_frame, style='Mac.TFrame')
    card_frame.pack(fill='x', pady=(0, 20))

    video_label = ttk.Label(card_frame, text="Video info loading...", style='MacSubtitle.TLabel', padding=(12, 8))
    video_label.pack(anchor='w')

    progress_var = DoubleVar()
    progress_bar = ttk.Progressbar(main_frame,
                                   variable=progress_var,
                                   maximum=100,
                                   style='MacProgress.Horizontal.TProgressbar',
                                   orient='horizontal',
                                   length=450)
    progress_bar.pack(fill='x', pady=(0, 8))

    percent_label = ttk.Label(main_frame, text="0%", style='MacSubtitle.TLabel')
    percent_label.pack(anchor='e')

    root.configure(bg=MAC_BG)
    root.update_idletasks()
    x = (root.winfo_screenwidth() // 2) - (root.winfo_width() // 2)
    y = (root.winfo_screenheight() // 2) - (root.winfo_height() // 2)
    root.geometry(f'+{x}+{y}')

except Exception:
    gui_supported = False

# Progress update
def progress_hook(d):
    if d['status'] == 'downloading':
        total = d.get('total_bytes') or d.get('total_bytes_estimate')
        done = d.get('downloaded_bytes', 0)
        if total:
            percent = done / total * 100
            if gui_supported:
                progress_var.set(percent)
                percent_label.config(text=f"{percent:.2f}%")
                root.update_idletasks()
            else:
                print(f"\rDownloading: {percent:.2f}%", end='', flush=True)
    elif d['status'] == 'finished':
        if gui_supported:
            progress_var.set(100)
            percent_label.config(text="100%")
            root.update_idletasks()
        print("\nDownload complete!")

opts = {
    'ffmpeg_location': ffmpeg_path,
    'progress_hooks': [progress_hook],
    'quiet': False,
    'noplaylist': choice != "3",
}

if choice == "1":
    opts.update({
        'format': 'bestaudio/best',
        'outtmpl': os.path.join(download_dir, '%(title)s.%(ext)s'),
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'mp3',
            'preferredquality': '192',
        }],
    })
elif choice in ["2","3"]:
    outtmpl = os.path.join(download_dir, '%(playlist)s/%(title)s.%(ext)s') if choice=="3" else os.path.join(download_dir, '%(title)s.%(ext)s')
    opts.update({
        'format': 'bestvideo+bestaudio/best',
        'outtmpl': outtmpl,
        'merge_output_format': 'mkv',
    })

def start_download():
    with yt_dlp.YoutubeDL(opts) as ydl:
        info = ydl.extract_info(url, download=False)
        entries = info.get('entries', [info])
        for i, entry in enumerate(entries, start=1):
            if gui_supported:
                video_label.config(text=f"{entry.get('title')}")
                root.update_idletasks()
            print(f"\nDownloading [{i}/{len(entries)}]: {entry.get('title')}")
            ydl.download([entry['webpage_url']])
    if gui_supported:
        root.destroy()

if gui_supported:
    threading.Thread(target=start_download).start()
    root.mainloop()
else:
    start_download()
EOF

    echo ""
    echo "[✓] Download complete in $DOWNLOAD_DIR"
done
