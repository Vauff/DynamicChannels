#include <sourcemod>
#include <DynamicChannels>

public Plugin myinfo =
{
	name = "Example Plugin",
	author = "Vauff",
	description = "Example usage plugin for Dynamic Game_Text Channels",
	version = "1.0",
	url = "https://github.com/Vauff/DynamicChannels"
};

public void OnPluginStart() 
{
	RegConsoleCmd("sm_text", ShowText, "Shows a message in the center of the command users screen with a dynamic game_text channel");
}

public Action ShowText(int client, int args) 
{
	char arg[4];
	GetCmdArg(1, arg, sizeof(arg));
	int channel = GetDynamicChannel(StringToInt(arg));
	SetHudTextParams(0.5, 0.5, 5.0, 255, 0, 0, 0, 0, 1.0, 1.0, 1.0);
	ShowHudText(client, channel, "Group %s on channel %i", arg, channel);

	return Plugin_Handled;
}