import sys
import os
import yt_dlp

DOWNLOADS_DIR = '/storage/emulated/0/Download'

def download_best_video(url):
    ydl_opts = {
        'format': 'bestvideo+bestaudio/best',
        'merge_output_format': 'mp4',  
        'outtmpl': os.path.join(DOWNLOADS_DIR, '%(title)s.%(ext)s'),
        'noplaylist': True,
        'quiet': False,
        'nooverwrites': True,
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        ydl.download([url])

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python video_dl.py <YouTube_URL>")
        sys.exit(1)

    video_url = sys.argv[1]
    print("Downloading best quality video...")
    download_best_video(video_url)
    print("Video downloaded to Downloads folder.")
