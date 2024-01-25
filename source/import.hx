import Paths;
import ui.PreferencesMenu;
import shaders.ColorSwap;
import openfl.utils.Assets as OpenFlAssets;
#if discord_rpc
import Discord.DiscordClient;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end
using StringTools;