package;

import haxe.Json;
import openfl.utils.Assets;

using StringTools;

typedef SwagSong =
{
	var song:String;
	// var stage:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
}

class Song
{
	public static function loadFromJson(jsonInput:String, folder:String = '')
	{
		if (folder.length > 0)
			folder = folder.toLowerCase() + '/';

		if(jsonInput == 'events') { //Makes the game not crash while trying to load an events chart, doesn't work on HTML tho
			#if sys
			rawJson = sys.io.File.getContent(Paths.json(folder.toLowerCase() + '/events')).trim();
			#else
			rawJson = Assets.getText(Paths.json(folder.toLowerCase() + '/events')).trim();
			#end
		} else {
			rawJson = Assets.getText(Paths.json(folder.toLowerCase() + '/' + jsonInput.toLowerCase())).trim();
		}

		while (!rawJson.endsWith("}"))
			rawJson = rawJson.substr(0, rawJson.length - 1);

		return parseJSONshit(rawJson);
	}

	inline public static function parseJSONshit(rawJson:String):SwagSong
	{
		return cast Json.parse(rawJson).song;
	}
}
