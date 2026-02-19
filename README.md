# MTASA-ReadyRaceServer
# READ EVERYTHING! VERY IMPORTANT

A ready race server repository. Contains various scripts that racing servers use and some new scripts too. Ready for casual racing or pro racing.

Will contain most important scripts, like Pole Remover (it will not work from the start of the server, don't worry) Offroad Wheels and much more. There will be also a classic clanwar script by Vally, redesigned and remixed.

Map Uploader script info:

It fetches one file (for now) from this repository: https://github.com/AlfredoAnonym/MTASA-Race-Server so if you don't have "30 Fps Cap" script that will allow you to turn on 30 fps in your map that you'll upload, you don't need to have it. It's fetched by the fetchRemote function inside the script ;)

I have a server that I launch frequently (not 24/h server) if you'll see me - you can jump in and we can play mtasa://51.75.58.35:10899

Changes for some classic scripts

- Map Ratings - Now correctly working, with its own F4 gui where you can sort best rated / worst rated maps
- VallyCW - Race League (clanwar) script by Vally. Completely overhauled, added bunch of new things - including ability to set captains, new point system more used in FFA games, /tech pause (it locks after 10 seconds) and much more. One of the most amazing implementations is the ability to export stats now - it should export the match stats to the VallyCW folder to stats.txt, which will give you full score and player scores.
- cw_script - Edited by BurN, now edited by Mateoryt. Also added new points system, and overhauled the script with new features.
- Toptimes - Retained more classic look, but edited few things like colors (1st, 2nd, 3rd toptimes), similar to SiK server back in the day. Only bad thing about it is spacing between the country flag. I'll probably upload robson race_toptimes here too, but if country flags will not work there for you, then use this one or remix the Robson script. It uses the flags from the scoreboard resource
- Carhide - the classic carhide from servers like GTA.RU back in the day. Fixed and working on newer servers
- Delay Indicator - smaller delay indicator, with an new command /clearsplits to clear splits when you delete a toptime. They will not show up anymore if you do that :)

Installation:

- First off, do not wipe everything from resources. Only wipe the [addons] and [maps] folder from the [race] gamemodes folder. You can also keep voicepack or whatever I don't use it, but if you delete it it might cause you some warnings
- Put everything (or replace some stuff) to your server resources folder. Replacing i mean one thing in gamemodes / race / race client and server.lua to support onSpectateRequest so it warps people to spectator mode if clanwar script is running and they are in the spectators team
- Important thing: First off, type in the server console aclrequest list and check if any of the resources need acl requests, if they do - type aclrequest allow all or aclrequest allow (resource name) <right> or all. Then you'll give all the scripts that need this acl rights so they can function properly.

