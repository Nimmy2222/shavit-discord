#include <sourcemod>
#include <shavit>
#include <SteamWorks>
#include <json>
#include <steamworks-profileurl>

#pragma newdecls required
#pragma semicolon 1


char g_sMapName[PLATFORM_MAX_PATH];

int g_iMainColor;
int g_iBonusColor;

ConVar g_cvHostname;
ConVar g_cvWebhook;
ConVar g_cvBotProfilePicture;
ConVar g_cvMinimumrecords;
ConVar g_cvBotUsername;
ConVar g_cvFooterUrl;
ConVar g_cvMainEmbedColor;
ConVar g_cvBonusEmbedColor;
ConVar g_cvSendBonusRecords;
ConVar g_cvSendOffstyleRecords;

public Plugin myinfo =
{
	name = "[shavit] Discord WR Bot (Steamworks)",
	author = "SlidyBat, improved by Sarrus / nimmy",
	description = "Makes discord bot post message when server WR is beaten",
	version = "2.4",
	url = "https://github.com/Nimmy2222/shavit-discord"
}

public void OnPluginStart()
{
	g_cvMinimumrecords = CreateConVar("shavit-discord-min-record", "0", "Minimum number of records before they are sent to the discord channel.", _, true, 0.0);
	g_cvWebhook = CreateConVar("shavit-discord-webhook", "", "The webhook to the discord channel where you want record messages to be sent.", FCVAR_PROTECTED);
	g_cvBotProfilePicture = CreateConVar("shavit-discord-profilepic", "https://i.imgur.com/fKL31aD.jpg", "link to pfp for the bot");
	g_cvFooterUrl = CreateConVar("shavit-discord-footer-url", "https://images-ext-1.discordapp.net/external/tfTL-r42Kv1qP4FFY6sQYDT1BBA2fXzDjVmcknAOwNI/https/images-ext-2.discordapp.net/external/3K6ho0iMG_dIVSlaf0hFluQFRGqC2jkO9vWFUlWYOnM/https/images-ext-2.discordapp.net/external/aO9crvExsYt5_mvL72MFLp92zqYJfTnteRqczxg7wWI/https/discordsl.com/assets/img/img.png", "The url of the footer icon, leave blank to disable.");
	g_cvBotUsername = CreateConVar("sm_bhop_discord_username", "World Records", "Username of the bot");
	g_cvMainEmbedColor = CreateConVar("shavit-discord-main-color", "255, 0, 0", "Color of embed for when main wr is beaten");
	g_cvBonusEmbedColor = CreateConVar("shavit-discord-bonus-color", "0, 255, 0", "Color of embed for when bonus wr is beaten");
	g_cvSendBonusRecords = CreateConVar("shavit-discord-send-bonus", "1", "Whether to send bonus records or not 1 Enabled 0 Disabled");
	g_cvSendOffstyleRecords = CreateConVar("shavit-discord-send-offstyle", "1", "Whether to send offstyle records or not 1 Enabled 0 Disabled");
	g_cvHostname = FindConVar("hostname");

	HookConVarChange(g_cvMainEmbedColor, CvarChanged);
	HookConVarChange(g_cvBonusEmbedColor, CvarChanged);

	UpdateColorCvars();

	RegAdminCmd("sm_discordtest", CommandDiscordTest, ADMFLAG_ROOT);
	AutoExecConfig(true, "plugin.shavit-discord-steamworks");
}

public void UpdateColorCvars()
{
	char sMainColor[32];
	char sBonusColor[32];
	g_cvMainEmbedColor.GetString(sMainColor, sizeof(sMainColor));
	g_cvBonusEmbedColor.GetString(sBonusColor, sizeof(sBonusColor));
	g_iMainColor = RGBStrToShiftedInt(sMainColor);
	g_iBonusColor = RGBStrToShiftedInt(sBonusColor);
}

int RGBStrToShiftedInt(char fullStr[32])
{
	char rgbStrs[3][5];
	int	 strs = ExplodeString(fullStr, ",", rgbStrs, sizeof(rgbStrs), sizeof(rgbStrs[]));
	if (strs < 3)
	{
		return 255 << (2 * 8);
	}

	int adjustedInt;
	for(int i = 0; i < 3; i++)
	{
		int color = StringToInt(rgbStrs[i]);
		adjustedInt = (adjustedInt & ~(255 << ((2 - i) * 8))) | ((color & 255) << ((2 - i) * 8));
	}
	return adjustedInt;
}

public void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	UpdateColorCvars();
}

public void OnMapStart()
{
	GetCurrentMap(g_sMapName, sizeof(g_sMapName));
	RemoveWorkshop(g_sMapName, sizeof(g_sMapName));
}

public Action CommandDiscordTest(int client, int args)
{
	int track = GetCmdArgInt(1);
	int style = GetCmdArgInt(2);

	Shavit_OnWorldRecord(client, style, 12.3, 35, 23, 93.25, track, 17.01);
	PrintToChat(client, "[shavit-discord] Discord Test Message has been sent.");
	return Plugin_Handled;
}

//listen

public void Shavit_OnWorldRecord(int client, int style, float time, int jumps, int strafes, float sync, int track, float oldwr)
{
	if(g_cvMinimumrecords.IntValue > 0 && Shavit_GetRecordAmount(style, track) < g_cvMinimumrecords.IntValue)
	{
		return;
	}

	if(!(g_cvSendOffstyleRecords.IntValue) && style != 0)
	{
		return;
	}

	if(!(g_cvSendBonusRecords.IntValue) && track != Track_Main)
	{
		return;
	}

	FormatEmbedMessage(client, style, time, jumps, strafes, sync, track, oldwr);
}

//http

void FormatEmbedMessage(int client, int style, float time, int jumps, int strafes, float sync, int track, float oldwr)
{
	char message[512];
	Shavit_GetStyleStrings(style, sStyleName, message, sizeof(message));

	char recordTxt[512];
	if(track == Track_Main)
	{
		Format(recordTxt, sizeof(recordTxt), "__**%s**__ - **Main** - **%s**", g_sMapName, message);
	} else
	{
		Format(recordTxt, sizeof(recordTxt), "__**%s**__ - **Bonus #%i** - **%s**", g_sMapName, track, message);
	}

	GetClientAuthId(client, AuthId_SteamID64, message, sizeof(message));

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	SanitizeName(name);

	char playerUrl[512];
	Format(playerUrl, sizeof(playerUrl), "http://www.steamcommunity.com/profiles/%s", message);

	JSON_Object author = new JSON_Object();
	author.SetString("name", name);
	author.SetString("url", playerUrl);

	char playerProfilePicture[1024];
	if(Sw_GetProfileUrl(client, playerProfilePicture, sizeof(playerProfilePicture)))
	{
		author.SetString("icon_url", playerProfilePicture);
	}
	else
	{
		PrintToConsole(client, "Shavit-Discord: Failed to find profile picture URL");
	}


	FormatSeconds(time, message, sizeof(message));
	Format(message, sizeof(message), "%ss", message);
	char oldTime[128];
	FormatSeconds(time - oldwr, oldTime, sizeof(oldTime));
	Format(message, sizeof(message), "%s (%ss)", message, oldTime);


	JSON_Object timeField = new JSON_Object();
	timeField.SetString("name", "Time");
	timeField.SetString("value", message);
	timeField.SetBool("inline", true);

	JSON_Object statsField = new JSON_Object();
	Format(message, sizeof(message), "**Strafes**: %i  **Sync**: %.2f%%  **Jumps**: %i", strafes, sync, jumps);
	statsField.SetString("name", "Stats");
	statsField.SetString("value", message);
	statsField.SetBool("inline", true);

	JSON_Object footerField = new JSON_Object();
	char hostname[512];
	g_cvHostname.GetString(hostname, sizeof(hostname));
	Format(message, sizeof(message), "%s", hostname);
	footerField.SetString("text", message);

	char footerUrl[1024];
	g_cvFooterUrl.GetString(footerUrl, sizeof(footerUrl));
	if (!StrEqual(footerUrl, ""))
	{
		footerField.SetString("icon_url", footerUrl);
	}

	JSON_Array fields = new JSON_Array();
	fields.PushObject(timeField);
	fields.PushObject(statsField);

	JSON_Object embed = new JSON_Object();
	embed.SetString("title", recordTxt);

	char color[32];
	Format(color, sizeof(color), "%i", (track == Track_Main && style == 0) ? g_iMainColor:g_iBonusColor);

	embed.SetString("color", color);
	embed.SetObject("fields", fields);
	embed.SetObject("author", author);
	embed.SetObject("footer", footerField);

	JSON_Array embeds = new JSON_Array();
	embeds.PushObject(embed);

	JSON_Object json = new JSON_Object();

	char botUserName[128];
	g_cvBotUsername.GetString(botUserName, sizeof(botUserName));
	json.SetString("username", botUserName);

	char profilePictureUrl[1024];
	g_cvBotProfilePicture.GetString(profilePictureUrl, sizeof(profilePictureUrl));
	json.SetString("avatar_url", profilePictureUrl);
	json.SetObject("embeds", embeds);

	SendMessage(json);
	json_cleanup_and_delete(json);
}

void SendMessage(JSON_Object json)
{
	char webhook[256];
	g_cvWebhook.GetString(webhook, sizeof(webhook));

	if (webhook[0] == '\0')
	{
		LogError("Discord webhook is not set.");
		return;
	}

	char body[2048];
	json.Encode(body, sizeof(body));

	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, webhook);
	SteamWorks_SetHTTPRequestRawPostBody(request, "application/json", body, strlen(body));
	SteamWorks_SetHTTPCallbacks(request, OnMessageSent);
	SteamWorks_SendHTTPRequest(request);
}

public void OnMessageSent(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode, DataPack pack)
{
	if (failure || !requestSuccessful || statusCode != k_EHTTPStatusCode204NoContent)
	{
		LogError("Failed to send message to Discord. Response status: %d.", statusCode);
	}

	delete request;
}

//util

void SanitizeName(char[] name)
{
	ReplaceString(name, MAX_NAME_LENGTH, "(", "", false);
	ReplaceString(name, MAX_NAME_LENGTH, ")", "", false);
	ReplaceString(name, MAX_NAME_LENGTH, "]", "", false);
	ReplaceString(name, MAX_NAME_LENGTH, "[", "", false);
}

void RemoveWorkshop(char[] mapName, int len)
{
	// Return if "workshop/" is not in the mapname
	if(ReplaceString(mapName, len, "workshop/", "", true) != 1)
	{
		return;
	}

	// Find the index of the last /
	int i=0;
	char compare[1] = "/";
	char buffer[16];
	while(mapName[i] != compare[0])
	{
		buffer[i] = mapName[i];
		i++;
	}

	buffer[i] = compare[0];
	ReplaceString(mapName, len, buffer, "", true);
}
