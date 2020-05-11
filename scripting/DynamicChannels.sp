#include <sourcemod>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#include <dhooks>
#define REQUIRE_EXTENSIONS
#include <DynamicChannels>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Dynamic Game_Text Channels",
	author = "Vauff",
	description = "Provides a native for plugins to implement that handles automatic game_text channel assigning based on what channels the current map uses",
	version = "2.0.4",
	url = "https://github.com/Vauff/DynamicChannels"
};

Handle g_AcceptInput;
ConVar g_Warnings;

bool g_dHooks = false;
bool g_ChannelsOverflowing = false;
bool g_BadMapChannels = false;
bool g_MapChannels[6];

int g_GroupChannels[] = {-1, -1, -1, -1, -1, -1};

bool g_NotifiedBadChans[MAXPLAYERS + 1] = false;
bool g_NotifiedOverflow[MAXPLAYERS + 1] = false;

public void OnPluginStart()
{
	g_Warnings = CreateConVar("sm_dynamic_channels_warnings", "1", "Should channel overflow & bad channel warnings be sent to root admins?");

	RegAdminCmd("sm_debugchannels", Command_DebugChannels, ADMFLAG_ROOT, "Prints debugging information to console about the current states of game_text channels");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("GetDynamicChannel", Native_GetDynamicChannel);
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("dhooks"))
	{
		if (!FileExists("addons/sourcemod/gamedata/DynamicChannels.games.txt"))
		{
			LogError("Missing gamedata! The plugin will not be able to hook live game_text channel updates from maps");
			return;
		}

		Handle gameData = LoadGameConfigFile("DynamicChannels.games");

		if (gameData == INVALID_HANDLE)
		{
			LogError("Missing gamedata! The plugin will not be able to hook live game_text channel updates from maps");
			return;
		}

		int offset = GameConfGetOffset(gameData, "AcceptInput");

		if (offset == -1)
		{
			LogError("Failed to find AcceptInput offset! The plugin will not be able to hook live game_text channel updates from maps");
			return;
		}

		g_dHooks = true;

		//bool CBaseEntity::AcceptInput( const char *szInputName, CBaseEntity *pActivator, CBaseEntity *pCaller, variant_t Value, int outputID )
		//game/server/baseentity.cpp line 4457 (in csgo source code leak)
		g_AcceptInput = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, AcceptInput);
		DHookAddParam(g_AcceptInput, HookParamType_CharPtr);
		DHookAddParam(g_AcceptInput, HookParamType_CBaseEntity);
		DHookAddParam(g_AcceptInput, HookParamType_CBaseEntity);
		DHookAddParam(g_AcceptInput, HookParamType_Object, 20, DHookPass_ByVal|DHookPass_ODTOR|DHookPass_OCTOR|DHookPass_OASSIGNOP); //varaint_t is a union of 12 (float[3]) plus two int type params 12 + 8 = 20
		DHookAddParam(g_AcceptInput, HookParamType_Int);
	
		DHookAddEntityListener(ListenType_Created, OnEntityCreated);
		CloseHandle(gameData);
	}
	else
	{
		LogError("DHooks not installed! The plugin will not be able to hook live game_text channel updates from maps");
	}
}

public void OnMapStart()
{
	g_ChannelsOverflowing = false;
	g_BadMapChannels = false;
	g_GroupChannels = {-1, -1, -1, -1, -1, -1};

	CreateTimer(30.0, MsgAdminTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	for (int i = 0; i < sizeof(g_MapChannels); i++)
		g_MapChannels[i] = false;
}

public void OnClientPutInServer(int client)
{
	g_NotifiedBadChans[client] = false;
	g_NotifiedOverflow[client] = false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "game_text"))
	{
		if (g_dHooks)
			DHookEntity(g_AcceptInput, true, entity);

		//have to delay GetEntProp(), otherwise m_textParms.channel is always 0
		CreateTimer(0.1, GameTextCreated, entity);
	}
}

public Action GameTextCreated(Handle timer, int entity)
{
	if (!IsValidEntity(entity))
		return;

	char classname[128];
	GetEntityClassname(entity, classname, sizeof(classname));

	if (StrEqual(classname, "game_text"))
		AddMapChannel(GetEntProp(entity, Prop_Data, "m_textParms.channel"));
}

public MRESReturn AcceptInput(int pThis, Handle hReturn, Handle hParams)
{
	char input[128];
	DHookGetParamString(hParams, 1, input, sizeof(input));

	if (StrEqual("AddOutput", input, false))
	{
		//since a map can provide any string as a parameter, we need to do a few checks to be 100% sure the AddOutput parameter provided here follows conventions to prevent errors
		char parameter[256];
		char splitParameter[256];
		int channel = -1;

		DHookGetParamObjectPtrString(hParams, 4, 0, ObjectValueType_String, parameter, sizeof(parameter));
		SplitString(parameter, " ", splitParameter, sizeof(splitParameter));
		StrCat(splitParameter, sizeof(splitParameter), " ");

		if (StrEqual(splitParameter, "channel ", false))
		{
			ReplaceString(parameter, sizeof(parameter), splitParameter, "", false);

			//StringToInt returns 0 on failure, have to work around it...
			if (StrEqual(parameter, "0"))
				channel = 0;
			else if (StringToInt(parameter) != 0)
				channel = StringToInt(parameter);

			if (channel != -1)
				AddMapChannel(channel);
		}
	}

	DHookSetReturn(hReturn, true);
	return MRES_Handled;
}

public Action Command_DebugChannels(int client, int args)
{
	//have tried to use iteration here already, it always errors for some reason, don't try it again...
	char group0Status[64];
	char group1Status[64];
	char group2Status[64];
	char group3Status[64];
	char group4Status[64];
	char group5Status[64];

	Format(group0Status, sizeof(group0Status), "Assigned to channel %i", g_GroupChannels[0]);
	Format(group1Status, sizeof(group1Status), "Assigned to channel %i", g_GroupChannels[1]);
	Format(group2Status, sizeof(group2Status), "Assigned to channel %i", g_GroupChannels[2]);
	Format(group3Status, sizeof(group3Status), "Assigned to channel %i", g_GroupChannels[3]);
	Format(group4Status, sizeof(group4Status), "Assigned to channel %i", g_GroupChannels[4]);
	Format(group5Status, sizeof(group5Status), "Assigned to channel %i", g_GroupChannels[5]);

	if (client != 0)
		PrintToChat(client, " \x02[Dynamic Channels] \x07See console for channel debug output");

	PrintToConsole(client, "------------- [Dynamic Channels] -------------");
	PrintToConsole(client, "Plugin Group 0: %s", (g_GroupChannels[0] == -1) ? "Free" : group0Status);
	PrintToConsole(client, "Plugin Group 1: %s", (g_GroupChannels[1] == -1) ? "Free" : group1Status);
	PrintToConsole(client, "Plugin Group 2: %s", (g_GroupChannels[2] == -1) ? "Free" : group2Status);
	PrintToConsole(client, "Plugin Group 3: %s", (g_GroupChannels[3] == -1) ? "Free" : group3Status);
	PrintToConsole(client, "Plugin Group 4: %s", (g_GroupChannels[4] == -1) ? "Free" : group4Status);
	PrintToConsole(client, "Plugin Group 5: %s", (g_GroupChannels[5] == -1) ? "Free" : group5Status);
	PrintToConsole(client, "----------------------------------------------");
	PrintToConsole(client, "Map Channel 0: %s", g_MapChannels[0] ? "Used" : "Free");
	PrintToConsole(client, "Map Channel 1: %s", g_MapChannels[1] ? "Used" : "Free");
	PrintToConsole(client, "Map Channel 2: %s", g_MapChannels[2] ? "Used" : "Free");
	PrintToConsole(client, "Map Channel 3: %s", g_MapChannels[3] ? "Used" : "Free");
	PrintToConsole(client, "Map Channel 4: %s", g_MapChannels[4] ? "Used" : "Free");
	PrintToConsole(client, "Map Channel 5: %s", g_MapChannels[5] ? "Used" : "Free");
	PrintToConsole(client, "----------------------------------------------");
	PrintToConsole(client, "Channels Overflowing: %s", g_ChannelsOverflowing ? "Yes" : "No");
	PrintToConsole(client, "Bad Map Channels: %s", g_BadMapChannels ? "Yes" : "No");
	PrintToConsole(client, "----------------------------------------------");

	return Plugin_Handled;
}

public int Native_GetDynamicChannel(Handle plugin, int params)
{
	int group = GetNativeCell(1);

	if (group > 5 || group < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Dynamic channel group number must be between 0 and 5!");
		return -1;
	}

	if (g_GroupChannels[group] != -1)
		return g_GroupChannels[group];

	int channel = -1;

	for (int i = 0; i < sizeof(g_MapChannels); i++)
	{
		if (!g_MapChannels[i])
		{
			bool channelUsed = false;

			for (int j = 0; j < sizeof(g_GroupChannels); j++)
			{
				if (i == g_GroupChannels[j])
				{
					channelUsed = true;
					break;
				}
			}

			if (!channelUsed)
			{
				channel = i;
				break;
			}
		}
	}

	if (channel == -1)
	{
		if (g_Warnings.BoolValue && !g_ChannelsOverflowing)
		{
			char map[128];

			GetCurrentMap(map, sizeof(map));
			LogMessage("game_text channels are overflowing! Consider reducing the amount of channels used by %s or plugins", map);
		}

		g_ChannelsOverflowing = true;
		channel = 0;

		while (channel < 6)
		{
			bool keepSearching = false;

			for (int i = 0; i < sizeof(g_GroupChannels); i++)
			{
				if (g_GroupChannels[i] == channel)
				{
					if (channel == 5)
					{
						ThrowNativeError(SP_ERROR_NATIVE, "Something went very wrong! Please report this issue with the following information: game, map name, plugin version, and sm_debugchannels output");
						return -1;
					}

					channel++;
					keepSearching = true;
					break;
				}
			}

			if (!keepSearching)
				break;
		}
	}

	g_GroupChannels[group] = channel;
	return channel;
}

public Action MsgAdminTimer(Handle timer)
{
	if (!g_Warnings.BoolValue)
		return Plugin_Continue;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client) || !CheckCommandAccess(client, "", ADMFLAG_ROOT))
			continue;

		if (g_ChannelsOverflowing && !g_NotifiedOverflow[client])
		{
			PrintToChat(client, " \x02[Dynamic Channels] \x07game_text channels are overflowing! Consider reducing the amount of channels used by the map or plugins");
			g_NotifiedOverflow[client] = true;
		}
		if (g_BadMapChannels && !g_NotifiedBadChans[client])
		{
			PrintToChat(client, " \x02[Dynamic Channels] \x07This map is using bad channel numbers! It is highly recommended to fix this with stripper to prevent the game auto-assigning the channel and causing conflicts");
			g_NotifiedBadChans[client] = true;
		}
	}

	return Plugin_Continue;
}

void AddMapChannel(int channel)
{
	if (channel <= 5 && channel >= 0)
	{
		if (!g_MapChannels[channel])
		{
			g_MapChannels[channel] = true;

			//map channels have changed, we must now force all plugin group channels to be recalculated
			g_GroupChannels = {-1, -1, -1, -1, -1, -1};
		}
	}
	else
	{
		if (g_Warnings.BoolValue && !g_BadMapChannels)
		{
			char map[128];

			GetCurrentMap(map, sizeof(map));
			LogMessage("%s is using bad channel numbers! It is highly recommended to fix this with stripper to prevent the game auto-assigning the channel and causing conflicts", map);
		}

		g_BadMapChannels = true;
	}
}

bool IsValidClient(int client, bool nobots = false)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
		return false;

	return IsClientInGame(client);
}