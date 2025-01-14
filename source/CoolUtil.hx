package;

#if cpp
import cpp.NativeGc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end
#if sys
import sys.io.File;
import sys.FileSystem;
#end
#if js
import js.html.Console;
#end
import openfl.utils.Assets;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.util.FlxSort;
import flixel.util.FlxSave;

using StringTools;

class CoolUtil
{
	public static var difficultyArray:Array<String> = ['EASY', "NORMAL", "HARD"];

	inline public static function difficultyString():String
	{
		return difficultyArray[PlayState.storyDifficulty];
	}

	static var fileRef:FileReference;

	public static function openSavePrompt(data:String, ?defaultFileName:String)
	{
		if (data.length > 0)
		{
			fileRef = new FileReference();
			fileRef.addEventListener(Event.COMPLETE, disposeFileRef);
			fileRef.addEventListener(Event.CANCEL, disposeFileRef);
			fileRef.addEventListener(IOErrorEvent.IO_ERROR, disposeFileRef);
			fileRef.save(data, defaultFileName);
		}
	}

	static function disposeFileRef(_)
	{
		fileRef.removeEventListener(Event.COMPLETE, disposeFileRef);
		fileRef.removeEventListener(Event.CANCEL, disposeFileRef);
		fileRef.removeEventListener(IOErrorEvent.IO_ERROR, disposeFileRef);
		fileRef = null;
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = Assets.getText(path).trim().split('\n');
		for (i in 0...daList.length)
			daList[i] = daList[i].trim();
		return daList;
	}

	/**
	 * ALWAYS CALL THIS AFTER THE STATE CHANGE!!!
	 */
	public static function resetMusic(fade:Bool = false):Void
	{
		FlxG.sound.playMusic(Paths.music('freakyMenu'), fade ? 0 : 1);
		if (fade)
			FlxG.sound.music.fadeIn(4, 0, 0.7);
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		var newValue:Float = value;
		if (newValue < min)
			newValue = min;
		else if (newValue > max)
			newValue = max;
		return newValue;
	}

	public static function numberArray(max:Int, ?min:Int = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
			dumbArray.push(i);
		return dumbArray;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1)
			return Math.floor(value);

		var tempMult:Float = 1;
		for (i in 0...decimals)
			tempMult *= 10;
		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}

	public static function destroyGraphic(graphic:FlxGraphic):Null<FlxGraphic>
	{
		if (graphic != null && graphic.bitmap != null)
		{
			graphic.bitmap.lock();
			@:privateAccess
			if (graphic.bitmap.__texture != null)
			{
				graphic.bitmap.__texture.dispose();
				graphic.bitmap.__texture = null;
			}
			graphic.bitmap.disposeImage();

			FlxG.bitmap.remove(graphic);
		}
		return null;
	}

	public static function makeUITabs(tabs:Array<String>)
	{
		var returnArray = [];
		for (tab in tabs)
			returnArray.push({name: tab, label: tab});
		return returnArray;
	}

	inline public static function runGC():Void
	{
		#if cpp
		NativeGc.compact();
		NativeGc.run(true);
		#elseif hl
		Gc.major();
		#elseif (java || neko)
		Gc.run(true);
		#end
	}

	inline public static function isPowerOfTwo(value:Int)
	{
		return value != 0 ? ((value & -value) == value) : false;
	}

	inline public static function hypotenuse(a:Float, b:Float)
	{
		return Math.sqrt(a * 2 + b * 2);
	}

	inline public static function nativeTrace(data:Dynamic):Void
	{
		#if sys
		Sys.println(data);
		#elseif js
		Console.log(data);
		#end
	}

	inline public static function sortNotes(Order:Int, Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(Order, Obj1.strumTime, Obj2.strumTime);
	}

	inline public static function camLerpShit(ratio:Float, negative:Bool = false):Float
	{
		var cock:Float = FlxG.elapsed * (ratio * 60);
		return FlxMath.bound(negative ? 1 - cock : cock, 0, 1);
	}

	inline public static function coolLerp(a:Float, b:Float, ratio:Float, negativeRatio:Bool = false):Float
	{
		return FlxMath.lerp(a, b, camLerpShit(ratio, negativeRatio));
	}

	inline public static function openURL(url:String):Void
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [url]);
		#else
		FlxG.openURL(url);
		#end
	}

	inline public static function getSavePath():String
	{
		@:privateAccess
		return #if (flixel < "5.0.0") 'CharlesCatYT' #else FlxG.stage.application.meta.get('company')
			+ '/'
			+ FlxSave.validate(FlxG.stage.application.meta.get('file')) #end;
	}
}
