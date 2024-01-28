package;

#if discord_rpc
import Discord.DiscordClient;
#end
#if target.threaded
import sys.thread.Thread;
import sys.thread.Mutex;
import openfl.media.Sound;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import lime.utils.Assets;
import flash.text.TextField;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	#if target.threaded
	var curPlaying:Int = -1;
	var playThread:Thread;
	var mutex:Mutex;
	var songToPlay:Sound;
	#end

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Float = 0;
	var intendedScore:Int = 0;

	private var grpText:FlxTypedGroup<Alphabet>;

	public static var coolColors:Array<Int> = [];
	public static var initSongList:Array<String> = [];

	private var iconArray:Array<HealthIcon> = [];
	var trackedAssets:Array<Dynamic> = [];

	override function create()
	{
		#if discord_rpc
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		initSongList = CoolUtil.coolTextFile(Paths.txt('freeplayList'));

		#if target.threaded
		mutex = new Mutex();
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
		#else
		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			CoolUtil.resetMusic();
		#end

		addWeek(['Tutorial'], 0, ['gf']);
		addWeek(['Bopeebo', 'Fresh', 'Dadbattle'], 1, ['dad']);
		addWeek(['Spookeez', 'South', 'Monster'], 2, ['spooky', 'spooky', 'monster']);
		addWeek(['Pico', 'Philly', 'Blammed'], 3, ['pico']);
		addWeek(['Satin-Panties', 'High', 'Milf'], 4, ['mom']);
		addWeek(['Cocoa', 'Eggnog', 'Winter-Horrorland'], 5, ['parents-christmas', 'parents-christmas', 'monster-christmas']);
		addWeek(['Senpai', 'Roses', 'Thorns'], 6, ['senpai', 'senpai', 'spirit']);
		addWeek(['Ugh', 'Guns', 'Stress'], 7, ['tankman']);
		for (i in 0...initSongList.length)
		{
			var songArray:Array<String> = initSongList[i].split(":");
			addSong(songArray[0], Std.parseInt(songArray[2]), songArray[3]);
			songs[songs.length - 1].color = Std.parseInt(songArray[4]);
		}
		var colorsList = CoolUtil.coolTextFile(Paths.txt('freeplayColors'));
		for (i in 0...colorsList.length)
		{
			coolColors.push(Std.parseInt(colorsList[i]));
		}

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);

		grpText = new FlxTypedGroup<Alphabet>();
		add(grpText);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpText.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.antialiasing = false;
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		#if target.threaded
		playThread = Thread.create(function()
		{
			while (true)
			{
				var index:Int = cast Thread.readMessage(true);
				if (index >= 0)
				{
					if (index == curSelected && index != curPlaying)
					{
						var sound = Paths.inst(songs[index].songName);
						if (index == curSelected)
						{
							mutex.acquire();
							songToPlay = sound;
							mutex.release();
						}
					}
				}
				else
					break;
			}
		});
		#end

		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		changeSelection();
		changeDiff();

		super.create();

		#if target.threaded
		checkSongChange();
		#end
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		lerpScore = CoolUtil.coolLerp(lerpScore, intendedScore, 0.4);
		// bg.color = FlxColor.interpolate(bg.color, coolColors[songs[curSelected].week % coolColors.length], CoolUtil.camLerpShit(0.045));

		scoreText.text = "PERSONAL BEST:" + Math.round(lerpScore);
		positionHighscore();

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.UI_LEFT_P)
			changeDiff(-1);
		if (controls.UI_RIGHT_P)
			changeDiff(1);

		#if target.threaded
		checkSongChange();
		#end

		if (controls.BACK)
		{
			if (colorTween != null)
			{
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound("cancelMenu"));
			Main.switchState(new MainMenuState());
			#if target.threaded
			if (curPlaying > -1)
				CoolUtil.resetMusic();
			#end
		}

		if (controls.ACCEPT)
		{
			PlayState.SONG = Song.loadFromJson(Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty),
				songs[curSelected].songName.toLowerCase());
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			PlayState.storyWeek = songs[curSelected].week;
			LoadingState.loadAndSwitchState(new PlayState(), true);

			var songLowercase:String = songs[curSelected].songName.toLowerCase();
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			if (!OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop)))
			{
				poop = songLowercase;
				curDifficulty = 1;
				trace('No chart found!');
			}
			trace(poop);

			if (colorTween != null)
			{
				colorTween.cancel();
			}

			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			PlayState.storyWeek = songs[curSelected].week;
			LoadingState.loadAndSwitchState(new PlayState(), true);

			unloadAssets();
			FlxG.switchState(new PlayState());
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
		}
	}

	#if target.threaded
	override function destroy()
	{
		playThread.sendMessage(-1);
		super.destroy();
	}
	#end

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = '< ' + CoolUtil.difficultyString() + ' >';
		positionHighscore();
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		var newColor:Int = songs[curSelected].color;
		if (newColor != intendedColor)
		{
			if (colorTween != null)
			{
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween)
				{
					colorTween = null;
				}
			});
		}

		#if target.threaded
		playThread.sendMessage(curSelected);
		#end

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
			iconArray[i].alpha = 0.6;

		if (iconArray[curSelected] != null)
			iconArray[curSelected].alpha = 1;

		for (item in grpText.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}

	#if target.threaded
	function checkSongChange()
	{
		var changedSong:Bool = false;
		mutex.acquire();
		if (songToPlay != null)
		{
			FlxG.sound.playMusic(songToPlay);
			if (curPlaying > -1)
				Cache.removeSound(Paths.instPath(songs[curPlaying].songName));
			changedSong = true;
			curPlaying = curSelected;
			songToPlay = null;
		}
		mutex.release();
		if (changedSong)
		{
			if (FlxG.sound.music.fadeTween != null)
				FlxG.sound.music.fadeTween.cancel();
			FlxG.sound.music.volume = 0;
			FlxG.sound.music.fadeIn();
		}
	}
	#end

	function positionHighscore()
	{
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - scoreBG.scale.x / 2;
		diffText.x = scoreBG.x + scoreBG.width / 2;
		diffText.x -= diffText.width / 2;
	}

	override function add(Object:flixel.FlxBasic):flixel.FlxBasic
	{
		trackedAssets.insert(trackedAssets.length, Object);
		return super.add(Object);
	}

	function unloadAssets():Void
	{
		for (asset in trackedAssets)
		{
			remove(asset);
		}
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;

	public function new(song:String, week:Int, songCharacter:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = FreeplayState.coolColors[week];
	}
}
