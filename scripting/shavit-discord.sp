#include <sourcemod>
#include <shavit>
#include <SteamWorks>
#include <json>

#pragma newdecls required
#pragma semicolon 1


char g_sMapName[PLATFORM_MAX_PATH];
char g_sSteamApiKey[64];
char g_sWebhook[1024];
char g_sFooterUrl[1024];
char g_sMapPicUrl[1024];
char g_sBotProfilePicUrl[1024];
char g_sBotUsername[64];
char g_sHostname[128];

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
ConVar g_cvSteamWebAPIKey;

public Plugin myinfo =
{
	name = "[shavit] Discord WR Bot (Steamworks)",
	author = "SlidyBat, improved by Sarrus / nimmy",
	description = "Makes discord bot post message when server WR is beaten",
	version = "2.2",
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
	g_cvSteamWebAPIKey = CreateConVar("shavit-discord-steam-api-key", "", "Allows the use of the player profile picture, leave blank to disable. The key can be obtained here: https://steamcommunity.com/dev/apikey", FCVAR_PROTECTED);
	g_cvHostname = FindConVar("hostname");

	HookConVarChange(g_cvWebhook, CvarChanged);
	HookConVarChange(g_cvHostname, CvarChanged);
	HookConVarChange(g_cvSteamWebAPIKey, CvarChanged);
	HookConVarChange(g_cvFooterUrl, CvarChanged);
	HookConVarChange(g_cvBotUsername, CvarChanged);
	HookConVarChange(g_cvMainEmbedColor, CvarChanged);
	HookConVarChange(g_cvBonusEmbedColor, CvarChanged);

	UpdateCvarStringCache();

	RegAdminCmd("sm_discordtest", CommandDiscordTest, ADMFLAG_ROOT);
	AutoExecConfig(true, "plugin.shavit-discord-steamworks");
}

public void UpdateCvarStringCache()
{
	g_cvWebhook.GetString(g_sWebhook, sizeof(g_sWebhook));
	g_cvHostname.GetString( g_sHostname, sizeof(g_sHostname));
	g_cvSteamWebAPIKey.GetString(g_sSteamApiKey, sizeof(g_sSteamApiKey));
	g_cvFooterUrl.GetString(g_sFooterUrl, sizeof(g_sFooterUrl));
	g_cvBotUsername.GetString(g_sBotUsername, sizeof(g_sBotUsername));
	g_cvBotProfilePicture.GetString(g_sBotProfilePicUrl, sizeof(g_sBotProfilePicUrl));

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
	UpdateCvarStringCache();
}

public void OnMapStart()
{
	GetCurrentMap(g_sMapName, sizeof(g_sMapName));
	RemoveWorkshop(g_sMapName, sizeof(g_sMapName));
	Format(g_sMapPicUrl, sizeof(g_sMapPicUrl), "");
	BananaAPIRequest();
}

public Action CommandDiscordTest(int client, int args)
{
	int iTrack = GetCmdArgInt(1);
	int iStyle = GetCmdArgInt(2);
	Shavit_OnWorldRecord(client, iStyle, 12.3, 35, 23, 93.25, iTrack, 17.01);
	//SteamAPIRequest(client, iStyle, 12.3, 35, 23, 93.25, iTrack, 17.01);
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
	if(!StrEqual(g_sSteamApiKey, ""))
	{
		SteamAPIRequest(client, style, time, jumps, strafes, sync, track, oldwr);
	}
	else
	{
		FormatEmbedMessage(client, style, time, jumps, strafes, sync, track, oldwr, "");
	}
}

//http

void FormatEmbedMessage(int client, int style, float time, int jumps, int strafes, float sync, int track, float oldwr, char profileUrl[1024])
{

	char sMessage[512];
	Shavit_GetStyleStrings(style, sStyleName, sMessage, sizeof(sMessage));

	char recordTxt[512];
	if(track == Track_Main) {
		Format(recordTxt, sizeof(recordTxt), "__**%s**__ - **Main** - **%s**", g_sMapName, sMessage);
	} else {
		Format(recordTxt, sizeof(recordTxt), "__**%s**__ - **Bonus #%i** - **%s**", g_sMapName, track, sMessage);
	}

	GetClientAuthId(client, AuthId_SteamID64, sMessage, sizeof(sMessage));

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	SanitizeName(name);

	char playerUrl[512];
	Format(playerUrl, sizeof(playerUrl), "http://www.steamcommunity.com/profiles/%s", sMessage);

	JSON_Object author = new JSON_Object();
	author.SetString("name", name);
	author.SetString("url", playerUrl);
	author.SetString("icon_url", profileUrl);


	FormatSeconds(time, sMessage, sizeof(sMessage));
	Format(sMessage, sizeof(sMessage), "%ss", sMessage);
	char sOldTime[128];
	FormatSeconds(time - oldwr, sOldTime, sizeof(sOldTime));
	Format(sMessage, sizeof(sMessage), "%s (%ss)", sMessage, sOldTime);


	JSON_Object timeField = new JSON_Object();
	timeField.SetString("name", "Time");
	timeField.SetString("value", sMessage);
	timeField.SetBool("inline", true);

	JSON_Object statsField = new JSON_Object();
	Format(sMessage, sizeof(sMessage), "**Strafes**: %i  **Sync**: %.2f%%  **Jumps**: %i", strafes, sync, jumps);
	statsField.SetString("name", "Stats");
	statsField.SetString("value", sMessage);
	statsField.SetBool("inline", true);

	JSON_Object footerField = new JSON_Object();
	Format(sMessage, sizeof(sMessage), "%s", g_sHostname);
	footerField.SetString("text", sMessage);
	if (!StrEqual(g_sFooterUrl, ""))
	{
		footerField.SetString("icon_url", g_sFooterUrl);
	}

	JSON_Object thumb = new JSON_Object();
	if(!StrEqual(g_sMapPicUrl, ""))
	{
		thumb.SetString("url", g_sMapPicUrl);
	}

	JSON_Array fields = new JSON_Array();
	fields.PushObject(timeField);
	fields.PushObject(statsField);

	JSON_Object embed = new JSON_Object();
	embed.SetString("title", recordTxt);
	char colorStr[32];
	Format(colorStr, sizeof(colorStr), "%i", (track == Track_Main && style == 0) ? g_iMainColor:g_iBonusColor);
	embed.SetString("color", colorStr);
	embed.SetObject("fields", fields);
	embed.SetObject("author", author);
	embed.SetObject("footer", footerField);
	embed.SetObject("thumbnail", thumb);

	JSON_Array embeds = new JSON_Array();
	embeds.PushObject(embed);

	JSON_Object json = new JSON_Object();
	json.SetString("username", "Server Records");
	json.SetString("avatar_url", g_sBotProfilePicUrl);
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

void SteamAPIRequest(int client, int style, float time, int jumps, int strafes, float sync, int track, float oldwr)
{
	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.WriteCell(style);
	pack.WriteCell(time);
	pack.WriteCell(jumps);
	pack.WriteCell(strafes);
	pack.WriteCell(sync);
	pack.WriteCell(track);
	pack.WriteCell(oldwr);
	pack.Reset();

	char steamid[64];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	char endpoint[1024];
	Format(endpoint, sizeof(endpoint), "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=%s&steamids=%s", g_sSteamApiKey, steamid);

	Handle request;
	if (!(request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, endpoint))
	  || !SteamWorks_SetHTTPRequestHeaderValue(request, "accept", "application/json")
	  || !SteamWorks_SetHTTPRequestContextValue(request, pack)
	  || !SteamWorks_SetHTTPRequestAbsoluteTimeoutMS(request, 4000)
	  || !SteamWorks_SetHTTPCallbacks(request, RequestCompletedCallback)
	  || !SteamWorks_SendHTTPRequest(request)
	)
	{
		CloseHandle(pack);
		CloseHandle(request);
		LogError("Shavit-Discord: failed to setup & send HTTP request");
	}
	return;
}

public void RequestCompletedCallback(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, DataPack pack)
{
	if (bFailure || !bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{
		LogError("Shavit-Discord: API request failed");
		return;
	}
	SteamWorks_GetHTTPResponseBodyCallback(request, ResponseBodyCallback, pack);
}

void ResponseBodyCallback(const char[] data, DataPack pack)
{

	pack.Reset();
	int client = pack.ReadCell();
	int style = pack.ReadCell();
	float time = pack.ReadCell();
	int jumps = pack.ReadCell();
	int strafes = pack.ReadCell();
	float sync = pack.ReadCell();
	int track = pack.ReadCell();
	float oldwr = pack.ReadCell();
	CloseHandle(pack);

	JSON_Object objects = view_as<JSON_Object>(json_decode(data));

	char pfpUrl[1024];
	if (objects != INVALID_HANDLE)
	{
		JSON_Object response = objects.GetObject("response");
		JSON_Array players = view_as<JSON_Array>(response.GetObject("players"));

		int playerlen = players.Length;
		JSON_Object player;
		for (int i = 0; i < playerlen; i++)
		{
			player = view_as<JSON_Object>(players.GetObject(i));
			player.GetString("avatarmedium", pfpUrl, sizeof(pfpUrl));
		}
		json_cleanup_and_delete(player);
	}
	FormatEmbedMessage(client, style, time, jumps, strafes, sync, track, oldwr, pfpUrl);
}

void BananaAPIRequest()
{
	char endpoint[1024];
	Format(endpoint, sizeof(endpoint), "https://gamebanana.com/apiv11/Util/Search/Results?_sSearchString=%s", g_sMapName);
	PrintToConsoleAll("Trying: %s", endpoint);
	Handle request;
	if (!(request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, endpoint))
	  || !SteamWorks_SetHTTPRequestHeaderValue(request, "accept", "application/json")
	  || !SteamWorks_SetHTTPRequestAbsoluteTimeoutMS(request, 4000)
	  || !SteamWorks_SetHTTPCallbacks(request,  BananaRequestCompletedCallback)
	  || !SteamWorks_SendHTTPRequest(request)
	)
	{
		CloseHandle(request);
		LogError("Shavit-Discord: failed to setup & send HTTP request");
	}
	return;
}

public void BananaRequestCompletedCallback(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, DataPack pack)
{
	if (bFailure || !bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{
		LogError("Shavit-Discord: API request failed");
		return;
	}
	SteamWorks_GetHTTPResponseBodyCallback(request, BananaResponseBodyCallback);
}

void BananaResponseBodyCallback(const char[] data, DataPack pack)
{
	JSON_Object objects = view_as<JSON_Object>(json_decode(data));
	if (objects == null)
	{
		return;
	}
	JSON_Array aRecords = view_as<JSON_Array>(objects.GetObject("_aRecords"));
	if(aRecords.Length < 1)
	{
		return;
	}
	JSON_Object response = aRecords.GetObject(0);
	JSON_Object media = response.GetObject("_aPreviewMedia");
	JSON_Array images = view_as<JSON_Array>(media.GetObject("_aImages"));
	JSON_Object picture = images.GetObject(0);
	char sUrl[1024];
	picture.GetString("_sBaseUrl", sUrl, sizeof(sUrl));
	char sFile[512];
	picture.GetString("_sFile", sFile, sizeof(sFile));
	Format(g_sMapPicUrl, sizeof(g_sMapPicUrl), "%s/%s", sUrl, sFile);
	json_cleanup_and_delete(picture);
}

//util

void SanitizeName(char[] name)
{
	ReplaceString(name, MAX_NAME_LENGTH, "(", "", false);
	ReplaceString(name, MAX_NAME_LENGTH, ")", "", false);
	ReplaceString(name, MAX_NAME_LENGTH, "]", "", false);
	ReplaceString(name, MAX_NAME_LENGTH, "[", "", false);
}

void RemoveWorkshop(char[] szMapName, int len)
{
	int i=0;
	char szBuffer[16], szCompare[1] = "/";

	// Return if "workshop/" is not in the mapname
	if(ReplaceString(szMapName, len, "workshop/", "", true) != 1)
	{
		return;
	}

	// Find the index of the last /
	while(szMapName[i] != szCompare[0])
	{
		szBuffer[i] = szMapName[i];
		i++;
	}

	szBuffer[i] = szCompare[0];
	ReplaceString(szMapName, len, szBuffer, "", true);
}
