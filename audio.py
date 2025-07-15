import sys
import os
import yt_dlp
import subprocess

def download_best_audio(url):
    output_template = '%(title)s.%(ext)s'

    ydl_opts = {
        'format': 'bestaudio/best',
        'outtmpl': output_template,
        'noplaylist': True,
        'quiet': False,
        'nooverwrites': True,
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info_dict = ydl.extract_info(url, download=True)
        filename = ydl.prepare_filename(info_dict)
        return filename 

def convert_to_mp3(input_file):
    if not os.path.exists(input_file):
        print(f"File not found: {input_file}")
        return None

    output_file = os.path.splitext(input_file)[0] + ".mp3"

    command = [
        "ffmpeg", "-y", "-i", input_file,
        "-vn", "-ar", "44100", "-ac", "2", "-b:a", "320k",
        output_file
    ]

    print(f"Converting to MP3: {output_file}")
    subprocess.run(command, check=True)
    print("Conversion complete.")

    return output_file

def delete_file(file_path):
    try:
        os.remove(file_path)
        print(f"Deleted original file: {file_path}")
    except Exception as e:
        print(f"Failed to delete original file: {e}")

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python dl.py <YouTube_URL>")
        sys.exit(1)

    video_url = sys.argv[1]
    print("Downloading best original audio...")
    original_file = download_best_audio(video_url)
    print(f"Downloaded: {original_file}")

    print("Starting conversion to MP3...")
    mp3_file = convert_to_mp3(original_file)

    if mp3_file:
        delete_file(original_file)
