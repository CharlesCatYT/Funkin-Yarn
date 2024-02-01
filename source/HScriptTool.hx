package;

import flixel.util.FlxDestroyUtil;
import flixel.math.FlxMath;
import flixel.*;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import haxe.io.Path;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import hscript.Expr;
import hscript.Parser;
import hscript.Interp;
import haxe.Constraints.Function;
import haxe.DynamicAccess;
import lime.app.Application;
import openfl.utils.Assets;

/*
	HEAVILY BASED ON YOSHICRAFTER ENGINE'S SCRIPT CODE
	HAVE A LOOK: https://raw.githubusercontent.com/YoshiCrafter29/YoshiCrafterEngine
	I'mma probably remake this to be either original or modified to be like Codename, or just better in any way possibl
 */
class HScriptTool implements IFlxDestroyable
{
	public var fileName:String = "";
	public var filePath:String = null;

	public function new()
	{
		// why does haxe need this vfjsdkrtvcfuydtrg
	}

	public static function loadScript(path:String):HScriptTool
	{
		// #if HSCRIPT_ALLOWED
		if (!PlayState.canRunScript)
			return null;

		var script = create(path);
		if (script != null)
		{
			script.loadFile();
			return script;
		}
		else
			return null;
		// #else
		// return null;
		// #end
	}

	public static function create(path:String):HScriptTool
	{
		var p = path.toLowerCase();
		var ext = Path.extension(p);

		var script = switch (ext.toLowerCase())
		{
			case 'hx': new Script();
			default: null;
		}

		if (script == null)
			return null;
		var quickSplit = path.replace("\\", "/").split("/");
		script.filePath = p;
		script.fileName = quickSplit[quickSplit.length];
		return script;
		// #else
		return null;
	}

	public function executeFunc(funcName:String, ?args:Array<Any>):Dynamic
	{
		// #if HSCRIPT_ALLOWED
		var ret = _executeFunc(funcName, args);
		return ret;
		// #else
		// return null;
		// #end
	}

	public function _executeFunc(funcName:String, ?args:Array<Any>):Dynamic
	{
		return null;
	}

	public function setVariable(name:String, val:Dynamic)
	{
	}

	public function getVariable(name:String):Dynamic
	{
		return null;
	}

	public function trace(text:String, error:Bool = false)
	{
		trace(text);
	}

	public function loadFile()
	{
	}

	public function destroy()
	{
	}
}

class Script extends HScriptTool
{
	public var hscript:Interp;

	public function new()
	{
		hscript = new Interp();
		hscript.errorHandler = function(e)
		{
			this.trace('Script Error! $e', true);
		};
		super();
	}

	public override function executeFunc(funcName:String, ?args:Array<Any>):Dynamic
	{
		// #if HSCRIPT_ALLOWED
		super.executeFunc(funcName, args);
		if (hscript == null)
			return null;
		if (hscript.variables.exists(funcName))
		{
			var f = hscript.variables.get(funcName);
			if (Reflect.isFunction(f))
			{
				if (args == null || args.length < 1)
					return f();
				else
					return Reflect.callMethod(null, f, args);
			}
		}
		return null;
		// #else
		// return null;
		// #end
	}

	public override function loadFile()
	{
		// #if HSCRIPT_ALLOWED
		super.loadFile();
		if (filePath == null || filePath.trim() == "")
			return;
		var content:String = sys.io.File.getContent(filePath);
		var parser = new hscript.Parser();
		try
		{
			hscript.execute(parser.parseString(content));
		}
		catch (e)
		{
			this.trace('${e.message}', true);
		}
		// #else
		// return;
		// #end
	}

	public override function trace(text:String, error:Bool = false)
	{
		// #if HSCRIPT_ALLOWED
		var posInfo = hscript.posInfos();

		var lineNumber = Std.string(posInfo.lineNumber);
		var methodName = posInfo.methodName;
		var className = posInfo.className;
		// #end
	}

	public override function setVariable(name:String, val:Dynamic)
	{
		if (!PlayState.canRunScript || hscript == null)
			return;
		// #if HSCRIPT_ALLOWED
		hscript.variables.set(name, val);
		@:privateAccess
		hscript.locals.set(name, {r: val, depth: 0});
		// #end
	}

	public override function getVariable(name:String):Dynamic
	{
		if (!PlayState.canRunScript || hscript == null)
			return null;

		// #if HSCRIPT_ALLOWED
		if (@:privateAccess hscript.locals.exists(name) && @:privateAccess hscript.locals[name] != null)
		{
			@:privateAccess
			return hscript.locals.get(name).r;
		}
		else if (hscript.variables.exists(name))
			return hscript.variables.get(name);

		return null;
		// #else
		// return null;
		// #end
	}

	public function setDefaultVars()
	{
		trace('loading default vars for script');
		// default classes
		// yeah its a lot.
		setVariable('FlxG', flixel.FlxG);
		setVariable('FlxMath', flixel.math.FlxMath);
		setVariable('FlxSprite', flixel.FlxSprite);
		setVariable('FNFSprite', FNFSprite);
		setVariable('FNFCamera', FNFCamera);
		setVariable('FlxCamera', flixel.FlxCamera);
		setVariable('FlxTimer', flixel.util.FlxTimer);
		setVariable('FlxSound', flixel.sound.FlxSound);
		setVariable('FlxTween', flixel.tweens.FlxTween);
		setVariable('FlxEase', flixel.tweens.FlxEase);
		setVariable('FlxSave', flixel.util.FlxSave);
		setVariable('FlxButton', flixel.ui.FlxButton);
		setVariable('FlxBar', flixel.ui.FlxBar);
		setVariable('FlxDestroyUtil', flixel.util.FlxDestroyUtil);
		setVariable('FlxBasic', flixel.FlxBasic);
		setVariable('FlxObject', flixel.FlxObject);
		// setVariable('FlxColor', flixel.util.FlxColor);
		setVariable('FlxText', flixel.text.FlxText);
		setVariable('FlxStringUtil', flixel.util.FlxStringUtil);
		setVariable('OpenFlAssets', openfl.utils.Assets);
		setVariable('LimeAssets', lime.utils.Assets);
		setVariable('Application', lime.app.Application);
		setVariable('AudioSource', lime.media.AudioSource);
		setVariable('AudioBuffer', lime.media.AudioBuffer);
		setVariable('Json', haxe.Json);
		#if sys
		setVariable('SysFileSystem', sys.FileSystem);
		setVariable('SysFile', sys.io.File);
		setVariable('SysProcess', sys.io.Process);
		#end
		setVariable('IoBytes', haxe.io.Bytes);
		setVariable('FlxState', flixel.FlxState);
		setVariable('FlxSubState', flixel.FlxSubState);
		setVariable('FlxFlicker', flixel.effects.FlxFlicker);
		setVariable('FlxGroup', flixel.group.FlxGroup);
		setVariable('ColorSwap', shaders.ColorSwap);
		setVariable('YarnPrefs', ui.PreferencesMenu);
		setVariable('Controls', Controls.instance);
		setVariable('CoolUtil', CoolUtil);
		setVariable('PlayerSettings', PlayerSettings);
		setVariable('CoolCounter', CoolCounter);
		setVariable('Character', Character);
		setVariable('InputFormatter', InputFormatter);
		setVariable('Strumline', Strumline);
		setVariable('Cache', Cache);
		setVariable('AttachedSprite', AttachedSprite);
		setVariable('Paths', Paths);
		setVariable('Note', Note);
		setVariable('NoteSplash', NoteSplash);
		setVariable('Alphabet', Alphabet);
		setVariable('CoolCounter', CoolCounter);
		setVariable('Conductor', Conductor);
		setVariable('Song', Song);
		setVariable("PlayState", PlayState.instance);
		setVariable('StringTools', StringTools);

		// keyboard functions
		setVariable('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		setVariable('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		setVariable('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

		// other stuff
		setVariable("getColorFromHex", function(color:String)
		{
			if (!color.startsWith('0x'))
				color = '0xff' + color;
			return Std.parseInt(color);
		});
		setVariable('addLibrary', function(libName:String, ?libPackage:String = '')
		{
			try
			{
				var str:String = '';
				if (libPackage.length > 0)
					str = libPackage + '.';

				setVariable(libName, Type.resolveClass(str + libName));
			}
			catch (e:Dynamic)
			{
				var msg:String = e.message.substr(0, e.message.indexOf('\n'));
				trace('You missed a spot.' + msg, true);
			}
		});
		setVariable('getBuildTarget', function()
		{
			#if windows
			return 'windows';
			#elseif linux
			return 'linux';
			#elseif mac
			return 'mac';
			#elseif html5
			return 'browser';
			#elseif android
			return 'android';
			#elseif switch
			return 'switch';
			#elseif hl
			return 'hashlink';
			#elseif neko
			return 'neko';
			#elseif ios
			return 'ios';
			#else
			return 'unknown';
			#end
		});
		setVariable("checkFileExists", function(filename:String, ?absolute:Bool = false)
		{
			if (absolute)
			{
				return Assets.exists(filename);
			}
			return Assets.exists(Paths.getPath('assets/$filename', TEXT));
		});
		setVariable("saveFile", function(path:String, content:String, ?absolute:Bool = false)
		{
			try
			{
				#if MODS_ALLOWED
				if (!absolute)
					File.saveContent(Paths.mods(path), content);
				else
				#end
				File.saveContent(path, content);

				return true;
			}
			catch (e:Dynamic)
			{
				trace("saveFile: Error trying to save " + path + ": " + e, true);
			}
			return false;
		});
		setVariable("deleteFile", function(path:String)
		{
			try
			{
				var lePath:String = Paths.getPath(path, TEXT);
				if (Assets.exists(lePath))
				{
					FileSystem.deleteFile(lePath);
					return true;
				}
			}
			catch (e:Dynamic)
			{
				trace("deleteFile: Error trying to delete " + path + ": " + e, true);
			}
			return false;
		});

		setVariable("stringStartsWith", function(str:String, start:String)
		{
			return str.startsWith(start);
		});
		setVariable("stringEndsWith", function(str:String, end:String)
		{
			return str.endsWith(end);
		});
		setVariable("stringSplit", function(str:String, split:String)
		{
			return str.split(split);
		});
		setVariable("stringTrim", function(str:String)
		{
			return str.trim();
		});

		setVariable("getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '')
		{
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];
			for (i in 0...excludeArray.length)
			{
				if (exclude == '')
					break;
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			}
			return FlxG.random.int(min, max, toExclude);
		});
		setVariable("getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '')
		{
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];
			for (i in 0...excludeArray.length)
			{
				if (exclude == '')
					break;
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			}
			return FlxG.random.float(min, max, toExclude);
		});
		setVariable("getRandomBool", function(chance:Float = 50)
		{
			return FlxG.random.bool(chance);
		});

		setVariable('this', this);
		setVariable('game', FlxG.state);
		setVariable('add', FlxG.state.add);
		setVariable('insert', FlxG.state.insert);
		setVariable('remove', FlxG.state.remove);

		// INGAME VARIABLES
		setVariable('curStage', PlayState.curStage);
		setVariable('screenWidth', FlxG.width);
		setVariable('screenHeight', FlxG.height);
		setVariable('seenCutscene', PlayState.seenCutscene);
		setVariable('isStoryMode', PlayState.isStoryMode);
		setVariable('difficulty', PlayState.storyDifficulty);
		setVariable('curBpm', Conductor.bpm);
		setVariable('bpm', PlayState.SONG.bpm);
		setVariable('scrollSpeed', PlayState.SONG.speed);
		setVariable('crochet', Conductor.crochet);
		setVariable('stepCrochet', Conductor.stepCrochet);
		setVariable('songLength', FlxG.sound.music.length);
		setVariable('songName', PlayState.SONG.song);
		setVariable('version', MainMenuState.version.trim());
		trace('i think i got it. :)');
	}
}
