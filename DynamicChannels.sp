#include <sourcemod>
#include <sdktools>
#include <DynamicChannels>

public Plugin myinfo =
{
	name = "Dynamic Game_Text Channels",
	author = "Vauff",
	description = "Provides a native for plugins to implement that handles automatic game_text channel assigning based on what channels the current map uses",
	version = "1.0",
	url = "https://github.com/Vauff/DynamicChannels"
};

ConVar warnings;
bool g_ChannelsOverflowing = false;
bool g_BadMapChannels = false;
bool g_MapChannels[6];
int g_GroupChannels[] = {-1, -1, -1, -1, -1, -1};

public void OnPluginStart()
{
	warnings = CreateConVar("sm_dynamic_channels_warnings", "1", "Should channel overflow & bad channel warnings be sent to high level admins?");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("GetDynamicChannel", Native_GetDynamicChannel);
	return APLRes_Success;
}

public OnMapStart()
{
	int ent = -1;

	g_ChannelsOverflowing = false;
	g_BadMapChannels = false;
	g_GroupChannels = {-1, -1, -1, -1, -1, -1};

	for (int i = 0; i < sizeof(g_MapChannels); i++)
	{
		g_MapChannels[i] = false;
	}

	while ((ent = FindEntityByClassname(ent, "game_text")) != -1)
	{
		if (IsValidEntity(ent))
		{
			int channel = GetEntProp(ent, Prop_Data, "m_textParms.channel");

			if (channel <= 5 && channel >= 0)
			{
				if (!g_MapChannels[channel])
					g_MapChannels[channel] = true;
			}
			else
			{
				if (warnings.IntValue && !g_BadMapChannels)
				{
					for (int client = 1; client <= MaxClients; client++)
					{
						// I highly doubt this will ever be used, but just in case an admin manages to be in-game immediately...
						if (CheckCommandAccess(client, "", ADMFLAG_CHANGEMAP))
							PrintToChat(client, " \x02[Dynamic Channels] \x07This map is using bad channel numbers! It is highly recommended to fix this with stripper to prevent the game auto-assigning the channel and causing conflicts");
					}
				}

				g_BadMapChannels = true;
			}
		}
	}
}

public int Native_GetDynamicChannel(Handle plugin, int params)
{
	int group = GetNativeCell(1);

	if (group > 5 || group < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Dynamic channel group number must be between 0 and 5!");
		return -1;
	}
	else if (g_GroupChannels[group] != -1)
	{
		return g_GroupChannels[group];
	}
	else
	{
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
			if (warnings.IntValue && !g_ChannelsOverflowing)
			{
				for (int client = 1; client <= MaxClients; client++)
				{
					if (CheckCommandAccess(client, "", ADMFLAG_CHANGEMAP))
						PrintToChat(client, " \x02[Dynamic Channels] \x07game_text channels are overflowing! Consider reducing the amount of channels used by the map or plugins");
				}
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
						if (i == 5)
						{
							channel = -1;
							break;
						}

						channel++;
						keepSearching = true;
						break;
					}
				}

				if (!keepSearching)
					break;
			}

			g_GroupChannels[group] = channel;
			return channel;
		}
		else
		{
			g_GroupChannels[group] = channel;
			return channel;
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (CheckCommandAccess(client, "", ADMFLAG_CHANGEMAP) && warnings.IntValue)
		CreateTimer(10.0, MsgAdmin, client);
}

public Action MsgAdmin(Handle timer, int client)
{
	if (g_ChannelsOverflowing)
		PrintToChat(client, " \x02[Dynamic Channels] \x07game_text channels are overflowing! Consider reducing the amount of channels used by the map or plugins");
	if (g_BadMapChannels)
		PrintToChat(client, " \x02[Dynamic Channels] \x07This map is using bad channel numbers! It is highly recommended to fix this with stripper to prevent the game auto-assigning the channel and causing conflicts");
}