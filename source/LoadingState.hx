package;

import haxe.io.Path;
import lime.app.Promise;
import lime.app.Future;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets as LimeAssets;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;

class LoadingState extends MusicBeatState
{
	var target:FlxState;
	var targetShit:Float = 0;
	var stopMusic = false;
	var callbacks:MultiCallback;

	var logo:FlxSprite;
	var gfDance:FlxSprite;

	var funkay:FlxSprite;
	var loadBar:FlxSprite;

	public static var MIN_TIME = 1;

	function new(target:FlxState, stopMusic:Bool)
	{
		super();
		this.target = target;
		this.stopMusic = stopMusic;
	}

	override function create()
	{
		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFCAFF4D);
		add(bg);

		funkay = new FlxSprite();
		funkay.loadGraphic(Paths.image('funkay'));
		funkay.setGraphicSize(0, FlxG.height);
		funkay.updateHitbox();
		funkay.antialiasing = PreferencesMenu.getPref('antialiasing');
		add(funkay);
		funkay.scrollFactor.set();
		funkay.screenCenter();

		loadBar = new FlxSprite(0, FlxG.height - 20).makeGraphic(FlxG.width, 10, 0xFFFF16D2);
		loadBar.screenCenter(X);
		add(loadBar);

		initSongsManifest().onComplete(function(lib)
		{
			callbacks = new MultiCallback(onLoad);
			var introComplete = callbacks.add("introComplete");
			checkLoadSong(getSongPath());
			if (PlayState.SONG.needsVoices)
				checkLoadSong(getVocalPath());
			checkLibrary("shared");
			if (PlayState.storyWeek > 1)
				checkLibrary("week" + PlayState.storyWeek);

			FlxG.camera.fade(FlxG.camera.bgColor, 0.5, true);
			new FlxTimer().start(1.5, function(_) introComplete());
		});
	}

	function checkLoadSong(path:String)
	{
		if (!isSoundLoaded(path))
		{
			var callback = callbacks.add("song:" + path);
			OpenFlAssets.loadSound(path).onComplete(function(_)
			{
				Cache.persistantAssets.set(path, true);
				callback();
			});
		}
	}

	function checkLibrary(library:String)
	{
		@:privateAccess
		if (LimeAssets.libraryPaths.exists(library) && !isLibraryLoaded(library))
		{
			var callback = callbacks.add("library:" + library);
			OpenFlAssets.loadLibrary(library).onComplete(function(_)
			{
				callback();
			});
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		var wacky = FlxG.width * 0.88;
		funkay.setGraphicSize(Std.int(wacky + 0.9 * (funkay.width - wacky)));
		funkay.updateHitbox();
		if (controls.ACCEPT)
		{
			funkay.setGraphicSize(Std.int(funkay.width + 60));
			funkay.updateHitbox();
			#if debug
			if (callbacks != null)
				trace('fired: ' + callbacks.getFired() + " unfired:" + callbacks.getUnfired());
			#end
		}
		if (callbacks != null)
		{
			targetShit = FlxMath.remapToRange(callbacks.numRemaining / callbacks.length, 1, 0, 0, 1);
			loadBar.scale.x += 0.5 * (targetShit - loadBar.scale.x);
		}
	}

	function onLoad()
	{
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		Main.switchState(target);
	}

	inline static function getSongPath()
	{
		return Paths.instPath(PlayState.SONG.song);
	}

	inline static function getVocalPath()
	{
		return Paths.voicesPath(PlayState.SONG.song);
	}

	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false)
	{
		Main.switchState(getNextState(target, stopMusic));
	}

	static function getNextState(target:FlxState, stopMusic = false):FlxState
	{
		// stage fallback so mods won't break
		if (PlayState.SONG.stage == null)
		{
			switch (PlayState.SONG.song.toLowerCase())
			{
				case 'tutorial' | 'bopeebo' | 'fresh' | 'dadbattle':
					PlayState.curStage = "stage";
				case 'spookeez' | 'south' | 'monster':
					PlayState.curStage = "spooky";
				case 'pico' | 'philly' | 'blammed':
					PlayState.curStage = "philly";
				case 'satin-panties' | 'high' | 'milf':
					PlayState.curStage = "limo";
				case 'cocoa' | 'eggnog':
					PlayState.curStage = "mall";
				case 'winter-horrorland':
					PlayState.curStage = "mall-evil";
				case 'senpai' | 'roses':
					PlayState.curStage = "school";
				case 'thorns':
					PlayState.curStage = "school-evil";
				default:
					PlayState.curStage = "stage";
			}
		}
		else
			PlayState.curStage = PlayState.SONG.stage;

		Paths.setCurrentLevel(PlayState.curStage);
		switch(PlayState.storyWeek) {
			default:
				Paths.setCurrentLevel("week" + PlayState.storyWeek);
		}
		#if LOADING_SCREEN
		var loaded = isSoundLoaded(getSongPath())
			&& (!PlayState.SONG.needsVoices || isSoundLoaded(getVocalPath()))
			&& isLibraryLoaded("shared");

		if (!loaded)
			return new LoadingState(target, stopMusic);
		#end
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		return target;
	}

	inline static function isSoundLoaded(path:String):Bool
	{
		return OpenFlAssets.cache.hasSound(path);
	}

	inline static function isLibraryLoaded(library:String):Bool
	{
		return OpenFlAssets.getLibrary(library) != null;
	}

	override function destroy()
	{
		super.destroy();

		callbacks = null;
	}

	static function initSongsManifest()
	{
		var id = "songs";
		var promise = new Promise<AssetLibrary>();

		var library = OpenFlAssets.getLibrary(id);

		if (library != null)
			return Future.withValue(library);

		var path = id;
		var rootPath = null;

		@:privateAccess
		var libraryPaths = LimeAssets.libraryPaths;
		if (libraryPaths.exists(id))
		{
			path = libraryPaths[id];
			rootPath = Path.directory(path);
		}
		else
		{
			if (StringTools.endsWith(path, ".bundle"))
			{
				rootPath = path;
				path += "/library.json";
			}
			else
				rootPath = Path.directory(path);
			@:privateAccess
			path = LimeAssets.__cacheBreak(path);
		}

		AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest)
		{
			if (manifest == null)
			{
				promise.error("Cannot parse asset manifest for library \"" + id + "\"");
				return;
			}

			var library = AssetLibrary.fromManifest(manifest);

			if (library == null)
			{
				promise.error("Cannot open library \"" + id + "\"");
			}
			else
			{
				@:privateAccess
				LimeAssets.libraries.set(id, library);
				library.onChange.add(LimeAssets.onChange.dispatch);
				promise.completeWith(Future.withValue(library));
			}
		}).onError(function(_)
		{
				promise.error("There is no asset library with an ID of \"" + id + "\"");
		});

		return promise.future;
	}
}

class MultiCallback
{
	public var callback:Void->Void;
	public var logId:String = null;
	public var length(default, null) = 0;
	public var numRemaining(default, null) = 0;

	var unfired = new Map<String, Void->Void>();
	var fired = new Array<String>();

	public function new(?callback:Void->Void, logId:String = null)
	{
		this.callback = callback;
		this.logId = logId;
	}

	public function add(id = "untitled")
	{
		id = '$length:$id';
		length++;
		numRemaining++;
		var func:Void->Void = function()
		{
			if (unfired.exists(id))
			{
				unfired.remove(id);
				fired.push(id);
				numRemaining--;

				if (logId != null)
					log('fired $id, $numRemaining remaining');

				if (numRemaining == 0)
				{
					if (logId != null)
						log('all callbacks fired');
					callback();
				}
			}
			else
				log('already fired $id');
		}
		unfired[id] = func;
		return func;
	}

	inline function log(msg):Void
	{
		#if debug
		if (logId != null)
			trace('$logId: $msg');
		#end
	}

	public function getFired()
		return fired.copy();

	public function getUnfired()
		return [for (id in unfired.keys()) id];
}
