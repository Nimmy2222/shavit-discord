# shavit-discord


## Description ##
Makes discord bot post message when server record is beaten.

## Requirements ##
* [SteamWorks](https://github.com/KyleSanderson/SteamWorks/releases)


## Installation ##
1. Press green "Code" button top right, download/extract zip. 
2. Drag plugins folder into addons/sourcemod.
3. The config file will be automatically generated in `cfg/sourcemod/` and is named `plugin.shavit-discord-steamworks.cfg`.
4. IMPORTANT: If you want to use the profile picture feature, make sure to add your steam web api key in `cfg/sourcemod/plugin.shavit-discord.cfg`.
5. IMPORTANT: If you are updating from the old version of shavit-discord, this CFG is different and you might need to copy over your webhook/apikey.

## Cvars ##
* shavit-discord-min-record - Minimum number of records before they are sent to the discord channel
*	shavit-discord-webhook - The webhook to the discord channel where you want record messages to be sent
*	shavit-discord-profilepic - link to pfp for the bot, leave blank to disable
*	shavit-discord-footer-url - The url of the footer icon, leave blank to disable
* sm_bhop_discord_username - Username of the bot
*	shavit-discord-main-color - Color of embed for when the main track default style wr is beaten
*	shavit-discord-bonus-color - Color of embed when a bonus/off style wr is beaten
*	shavit-discord-send-bonus - Whether to send bonus records or not 1 Enabled 0 Disabled
* shavit-discord-send-offstyle - Whether to send off style records or not 1 Enabled 0 Disabled
* shavit-discord-steam-api-key - Allows the use of the player profile picture, leave blank to disable. The key can be obtained here: https://steamcommunity.com/dev/apikey



