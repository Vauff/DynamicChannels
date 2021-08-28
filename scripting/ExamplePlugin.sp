#include <sourcemod>
#include <DynamicChannels>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Example plugin",
	author = "Vauff",
	description = "Example usage plugin for Dynamic Game_Text Channels",
	version = "2.0",
	url = "https://github.com/Vauff/DynamicChannels"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_basicexample", Command_BasicExample, "Basic code example for using the dynamic channels plugin");
	RegConsoleCmd("sm_grouptest", Command_GroupTest, "Displays a game_text message saying what group number and channel number it is running on, takes the group number as only argument");
}

public Action Command_BasicExample(int client, int args)
{
	/*
		This is the most basic usage case for the DynamicChannels plugin
		Calling GetDynamicChannel(0) will find an open channel for the group 0
		If you need to use a different channel number somewhere, use a different group number like 1
		What channel it chooses depends on what's available, if a map uses no game_text channels, it will pick channel 0
		If a map uses channels 0 and 1 for example, group 0 will pick channel 2 instead, group 1 channel 3 etc...
		Group numbers will return the same channel number anywhere in your plugin stack, this can change over time though, so call GetDynamicChannel() frequently and don't store it long term
		There are 6 groups maximum, and 6 engine channels maximum, each ranging from 0-5
		If map channels + plugin groups exceeds 6, DynamicChannels will begin assigning plugin groups a channel number already used by the map
		If the warnings convar is enabled, this will output a warning to root admins when it happens
	*/

	SetHudTextParams(0.5, 0.5, 5.0, 255, 0, 0, 0, 0, 1.0, 1.0, 1.0);
	ShowHudText(client, GetDynamicChannel(0), "Hello world!");

	return Plugin_Handled;
}

public Action Command_GroupTest(int client, int args)
{
	/*
		This works similar to the above command
		Main difference is that the group number is provided as a command argument
		Both the group number and channel number are then provided in the game_text message
		This can be used to test how DynamicChannels assigns channels in different maps/used groups scenarios
	*/

	char arg[2];
	GetCmdArg(1, arg, sizeof(arg));
	int group = StringToInt(arg);
	int channel = GetDynamicChannel(group);
	SetHudTextParams(0.5, 0.5, 5.0, 255, 0, 0, 0, 0, 1.0, 1.0, 1.0);
	ShowHudText(client, channel, "Group %i on channel %i", group, channel);

	return Plugin_Handled;
}