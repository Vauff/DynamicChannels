# Dynamic Game_Text Channels

Provides a native for plugins to implement that handles automatic game_text channel assigning based on what channels the current map uses.

**For this plugin to work properly, all plugins using ShowHudText() or game_text entity creation need to use GetDynamicChannel() for the channel number. ShowSyncHudText() should not be used at all.**