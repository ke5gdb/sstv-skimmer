from mastodon import Mastodon
from discord import SyncWebhook, File, Embed
import os
import traceback

from watchdog.observers.polling import PollingObserver
from watchdog.events import FileSystemEventHandler

import os
import sys

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("event")
parser.add_argument("image")
parser.add_argument("log")
parser.add_argument("audio")
args = parser.parse_args()

if args.event != "RECEIVE_END":
    sys.exit()

print(f"Parsing image {args.image}")

# Establish environment variables
if "M_URL" in os.environ:
    client_id = os.environ["M_CLIENT_ID"],
    client_secret = os.environ["M_CLIENT_SECRET"],
    api_base_url = os.environ["M_URL"]

    mastodon = Mastodon(
        client_id = os.environ["M_CLIENT_ID"],
        client_secret = os.environ["M_CLIENT_SECRET"],
        api_base_url = os.environ["M_URL"]
    )
    mastodon.log_in(
        os.environ["M_USERNAME"],
        os.environ["M_PASSWORD"]
    )
    print("Logged into Mastodon")
else:
    mastodon = None

if "D_WH" in os.environ:
    discord = SyncWebhook.from_url(os.environ["D_WH"])
    print("Established Discord webhook")
else:
    discord = None

if int(os.environ['FREQ']) < 54e6: # 6m and below
    freq = f"{int(os.environ['FREQ'])/1000:.0f}kHz"
else:
    freq = f"{int(os.environ['FREQ'])/1000000:.3f}MHz"

try: 
    filename = args.image.split("/")[-1].split("-")
    date = f"{filename[0]}-{filename[1]}-{filename[2].split('T')[0]}"
    time_var = f"{filename[2].split('T')[1]}:{filename[3]}"
    sstv_mode = filename[4].split('.')[0]
    callsign = ""
    if len(filename) == 6:
        callsign = f" from {filename[5].split('.')[0]}"

    message = f"SSTV {sstv_mode} Image received on {int(os.environ['FREQ'])/1000000:.3f} MHz {os.environ['MODE']}{callsign} at {date} {time_var} UTC\n#sstv #{sstv_mode} #{freq}\n"
        
    print(message)

    if mastodon:
        media = mastodon.media_post(args.image, "image/png", description="Image received by slow scan television")
        media_ids = [media["id"]]

        if sstv_mode != "BW12":
            mastodon.status_post(message, media_ids=media_ids, visibility="unlisted")

    if discord:
        filename = args.image.split('/')[-1]
        embed = Embed()
        file = File(args.image, filename=filename)
        embed.set_image(url=f"attachment://{filename}")
        discord.send(content=message, file=file, embed=embed)

except:
    print(traceback.format_exc())