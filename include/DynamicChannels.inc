#if defined _DynamicChannels_included_
  #endinput
#endif
#define _DynamicChannels_included_
 
/**
 * Provides a game_text channel for plugins to use that will prevent conflict with map channels.
 * The group number is a way of sharing the same game_text channel between certain plugins, using the same group number will always return the same game_text channel (for the session that is)
 *
 * @param group		Integer value of the group you want to get a game_text channel for. Must be between 0-5.
 * @return			The integer value of the assigned game_text channel.
 */
native int GetDynamicChannel(int group);