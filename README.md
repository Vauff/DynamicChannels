# Dynamic Game_Text Channels

Provides a native for plugins to implement that handles automatic game_text channel assigning based on what channels the current map uses. This means game_text channel conflicts can be completely be avoided when dealing with 6 or less total channels. When going over 6 channels, conflicts are inevitable, however effects are minimized. The **sm_debugchannels** command is also available to root admins to see the overall state of all channel assignments.

[DHooks](https://forums.alliedmods.net/showpost.php?p=2588686&postcount=589) is an optional (but recommended) dependency for this plugin, it enables hooking of live game_text channel updates from maps for better accuracy.

The plugin should theoretically work for any Source game with a 6 channel game_text entity. However, DHooks support is only added for CS:GO & CS:S, so the plugin won't be able to hook live game_text channel updates from maps on other games.

**For this plugin to work properly, game_text channels must only be used by maps and by plugins via the GetDynamicChannel native. This means that all plugins using ShowHudText() need to use GetDynamicChannel() for the channel number. ShowSyncHudText() or game_text entity creation should not be used by plugins at all.**

## Example Usage

```
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
```

## Diagrams

Still not getting it? Here's a couple diagrams going over how the plugin could assign channels in different scenarios.

Note that since group channel assignment is based on the order of function calls, the exact channel that each plugin group is assigned will likely not be the same as shown in the diagrams.

![Diagram 1](https://i.imgur.com/VEFmc71.png "Diagram 1")

![Diagram 2](https://i.imgur.com/ICaicVG.png "Diagram 2")

![Diagram 3](https://i.imgur.com/sIiVx1k.png "Diagram 3")

![Diagram 4](https://i.imgur.com/Ebbgdpj.png "Diagram 4")

![Diagram 5](https://i.imgur.com/sIQ0O9Y.png "Diagram 5")