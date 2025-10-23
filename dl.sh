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
esac
mkdir -p "$DOWNLOAD_DIR"

if [ "$OS" = "windows" ]; then
    if ! command -v python >/dev/null 2>&1; then
        powershell -Command "winget install -e --id Python.Python.3.10 -h" 2>/dev/null
        if ! command -v python >/dev/null 2>&1; then
            echo "[!] Install Python manually: https://www.python.org/downloads/"
            exit 1
        fi
    fi
else
    command -v python >/dev/null 2>&1 || { echo "[!] Python missing"; exit 1; }
fi

python -m ensurepip >/dev/null 2>&1
pip install --upgrade -q yt-dlp "imageio[ffmpeg]" tqdm >/dev/null 2>&1

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

    if [ "$choice" = "0" ]; then
        echo "Exiting..."
        break
    fi

    read -p "YouTube URL: " url

    python - <<EOF
import os
import yt_dlp
import imageio_ffmpeg as ffmpeg
import threading
from tqdm import tqdm
from tkinter import Tk, Label, DoubleVar, ttk

url = "$url"
choice = "$choice"
download_dir = r"$DOWNLOAD_DIR"
os.makedirs(download_dir, exist_ok=True)
ffmpeg_path = ffmpeg.get_ffmpeg_exe()

# GUI setup
gui_supported = True
try:
    root = Tk()
    root.title("Github: Techflux0")
    root.geometry("450x200")
    root.resizable(False, False)

    MAC_BG = '#77d1ca'
    MAC_TEXT = '#101012'
    MAC_SECONDARY_TEXT = '#515154'
    MAC_BLUE = '#007AFF'
    MAC_BORDER = '#0c0c12'

    style = ttk.Style()
    style.theme_use('clam')

    style.configure('Mac.TFrame', background=MAC_BG)
    style.configure('MacTitle.TLabel', 
                   font=('SF Pro Display', 16, 'bold'),
                   background=MAC_BG,
                   foreground=MAC_TEXT)
    style.configure('MacSubtitle.TLabel',
                   font=('SF Pro Text', 12),
                   background=MAC_BG,
                   foreground=MAC_SECONDARY_TEXT)
    style.configure('MacProgress.Horizontal.TProgressbar',
                   background=MAC_BLUE,
                   troughcolor='#e5e5ea',
                   borderwidth=0,
                   lightcolor=MAC_BLUE,
                   darkcolor=MAC_BLUE,
                   thickness=12) 

    style.configure('MacCard.TFrame',
                   background='#ffffff',
                   relief='solid',
                   borderwidth=2)

    # Main container
    main_frame = ttk.Frame(root, style='Mac.TFrame', padding=25)
    main_frame.pack(fill='both', expand=True)

    # Header section
    header_frame = ttk.Frame(main_frame, style='Mac.TFrame')
    header_frame.pack(fill='x', pady=(0, 20))

    status_label = ttk.Label(header_frame, text="Downloading...", style='MacSubtitle.TLabel')
    status_label.pack(anchor='w', pady=(5, 0))

    card_frame = ttk.Frame(main_frame, style='MacCard.TFrame')
    card_frame.pack(fill='x', pady=(0, 20))

    video_label = ttk.Label(card_frame, text="Video info loading...", style='MacSubtitle.TLabel', padding=(12, 8))
    video_label.pack(anchor='w')

    progress_frame = ttk.Frame(main_frame, style='Mac.TFrame')
    progress_frame.pack(fill='x')

    progress_var = DoubleVar()
    progress_bar = ttk.Progressbar(progress_frame,
                                   variable=progress_var,
                                   maximum=100,
                                   style='MacProgress.Horizontal.TProgressbar',
                                   orient='horizontal',
                                   length=450) 
    progress_bar.pack(fill='x', pady=(0, 8))

    # Progress info
    progress_info_frame = ttk.Frame(progress_frame, style='Mac.TFrame')
    progress_info_frame.pack(fill='x')

    percent_label = ttk.Label(progress_info_frame, text="0%", style='MacSubtitle.TLabel', font=('SF Pro Text', 11))
    percent_label.pack(side='right')

    # Set window background
    root.configure(bg=MAC_BG)

    # Center window
    root.update_idletasks()
    x = (root.winfo_screenwidth() // 2) - (root.winfo_width() // 2)
    y = (root.winfo_screenheight() // 2) - (root.winfo_height() // 2)
    root.geometry(f'+{x}+{y}')

except Exception as e:
    print(f"GUI initialization failed: {e}")
    gui_supported = False


def progress_hook(d):
    if d['status'] == 'downloading':
        total_bytes = d.get('total_bytes') or d.get('total_bytes_estimate')
        done = d.get('downloaded_bytes', 0)
        if total_bytes:
            percent = done / total_bytes * 100
            if gui_supported:
                progress_var.set(percent)
                percent_label.config(text=f"{percent:.2f}%")
                root.update_idletasks()
            else:
                print(f"\rDownloading: {percent:.2f}%", end='')
    elif d['status'] == 'finished':
        if gui_supported:
            progress_var.set(100)
            percent_label.config(text="100%")
            root.update_idletasks()
        print("\nDownload finished, processing...")


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
        info_dict = ydl.extract_info(url, download=False)
        # Playlist handling
        entries = info_dict.get('entries', [info_dict])
        for idx, entry in enumerate(entries, start=1):
            print(f"\nDownloading [{idx}/{len(entries)}]: {entry.get('title')}")
            if gui_supported:
                video_label.config(text=f"{entry.get('title')}")
                root.update_idletasks()
            ydl.download([entry['webpage_url']])
    if gui_supported:
        root.destroy()

if gui_supported:
    threading.Thread(target=start_download).start()
    root.mainloop()
else:
    start_download()
EOF

    echo "[✓] Download complete in $DOWNLOAD_DIR"
done
