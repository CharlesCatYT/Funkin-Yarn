package;

import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxSignal.FlxTypedSignal;
import ui.PreferencesMenu;

using StringTools;

class Receptor extends FNFSprite
{
	public var noteData:Int;

	public var direction:Float = 90;
	public var downscroll:Bool = false;
	public var sustainReduce:Bool = true;

	var resetTimer:Float = 0;

	override public function new(x:Float, y:Float, noteData:Int, downscroll:Bool)
	{
		super(x, y);

		this.noteData = noteData;
		this.downscroll = downscroll;

		if (PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/arrows-pixels'), true, 17, 17);

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			switch (noteData)
			{
				case 0:
					animation.add('static', [0], 12);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 12, false);
				case 1:
					animation.add('static', [1], 12);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 12, false);
				case 2:
					animation.add('static', [2], 12);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3], 12);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 12, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas('NOTE_assets');

			antialiasing = PreferencesMenu.getPref('antialiasing');
			setGraphicSize(Std.int(width * 0.7));

			switch (noteData)
			{
				case 0:
					animation.addByPrefix('static', 'arrowLEFT', 24);
					animation.addByPrefix('pressed', 'left press', 24, false);
					animation.addByPrefix('confirm', 'left confirm', 24, false);

					addOffset('confirm', -0.9, -4);
				case 1:
					animation.addByPrefix('static', 'arrowDOWN', 24);
					animation.addByPrefix('pressed', 'down press', 24, false);
					animation.addByPrefix('confirm', 'down confirm', 24, false);

					addOffset('confirm', -2.85, -1.7);
				case 2:
					animation.addByPrefix('static', 'arrowUP', 24);
					animation.addByPrefix('pressed', 'up press', 24, false);
					animation.addByPrefix('confirm', 'up confirm', 24, false);

					addOffset('confirm', -1.5, -1);
				case 3:
					animation.addByPrefix('static', 'arrowRIGHT', 24);
					animation.addByPrefix('pressed', 'right press', 24, false);
					animation.addByPrefix('confirm', 'right confirm', 24, false);

					addOffset('confirm', -3, 0.5);
			}
		}

		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		if (resetTimer > 0)
		{
			resetTimer -= elapsed;
			if (resetTimer <= 0)
			{
				playAnim('static');
				resetTimer = 0;
			}
		}

		super.update(elapsed);
	}

	override function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		super.playAnim(AnimName, Force, Reversed, Frame);
		var leOffset:FlxPoint = offset.copyTo(FlxPoint.weak());
		centerOffsets();
		offset.addPoint(leOffset);
		centerOrigin();
		origin.addPoint(leOffset);
		leOffset.put();
	}

	public function autoConfirm(time:Float)
	{
		playAnim('confirm', true);
		resetTimer = time;
	}

	public function postAddedToGroup()
	{
		scrollFactor.set();
		playAnim('static');
		x += Note.swagWidth * noteData;
	}
}

class Strumline extends FlxGroup
{
	public var receptors(default, null):FlxTypedGroup<Receptor>;

	public var allNotes(default, null):FlxTypedGroup<Note>;
	public var notesGroup(default, null):FlxTypedGroup<Note>;
	public var holdsGroup(default, null):FlxTypedGroup<Note>;

	public var splashesGroup(default, null):FlxTypedGroup<NoteSplash>;

	public var botplay:Bool = false;

	public var onNoteBotHit(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();
	public var onNoteUpdate(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

	public var characters:Array<Character> = [];
	public var singingCharacters:Array<Character> = [];

	inline public static function isOutsideScreen(strumTime:Float)
	{
		var limit:Float = 300;
		if (PlayState.instance != null)
			limit /= PlayState.instance.songSpeed;
		return Conductor.songPosition > strumTime + limit;
	}

	public function new(x:Float, y:Float, downscroll:Bool, botplay:Bool = false)
	{
		super();

		this.botplay = botplay;

		var smClipStyle:Bool = PreferencesMenu.getPref('sm-clip');

		if (smClipStyle)
		{
			holdsGroup = new FlxTypedGroup<Note>();
			add(holdsGroup);
		}

		receptors = new FlxTypedGroup<Receptor>();
		add(receptors);

		for (i in 0...4)
		{
			var babyArrow:Receptor = new Receptor(x, y, i, downscroll);
			var colorswap:ColorSwap = new ColorSwap();
			babyArrow.shader = colorswap.shader;
			colorswap.update(Note.arrowColors[i]);
			receptors.add(babyArrow);
			babyArrow.postAddedToGroup();
		}

		allNotes = new FlxTypedGroup<Note>();

		if (!smClipStyle)
		{
			holdsGroup = new FlxTypedGroup<Note>();
			add(holdsGroup);
		}

		notesGroup = new FlxTypedGroup<Note>();
		add(notesGroup);

		splashesGroup = new FlxTypedGroup<NoteSplash>();
		add(splashesGroup);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		splash.alpha = 0.00001;
		splashesGroup.add(splash);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// i had to do this because of the change bpm stuff -stilic
		var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;
		var roundedSpeed:Float = PlayState.instance != null ? FlxMath.roundDecimal(PlayState.instance.songSpeed, 2) : 1;
		allNotes.forEachAlive(function(note:Note)
		{
			var shouldRemove:Bool = isOutsideScreen(note.strumTime);
			note.active = !shouldRemove;
			note.visible = !shouldRemove;

			var receptor:Receptor = receptors.members[note.noteData % receptors.members.length];

			var distance:Float = note.strumTime;
			// overengineered bullshit bruh -stilic
			if (note.isSustainNote && roundedSpeed != 1)
			{
				var fakeStepCrochet:Float = fakeCrochet / 4;
				distance -= fakeStepCrochet;
				distance += fakeStepCrochet / roundedSpeed;
			}
			distance = (0.45 * (receptor.downscroll ? 1 : -1)) * (Conductor.songPosition - distance) * roundedSpeed;
			var angleDir:Float = (receptor.direction * Math.PI) / 180;
			if (note.copyX)
				note.x = receptor.x + note.offsetX + FlxMath.fastCos(angleDir) * distance;
			if (note.copyY)
				note.y = receptor.y + note.offsetY + FlxMath.fastSin(angleDir) * distance;

			if (note.copyAngle)
			{
				note.angle = receptor.direction - 90;
				if (!note.isSustainNote)
					note.angle += receptor.angle;
				note.angle += note.offsetAngle;
			}

			if (note.isSustainNote)
			{
				if (receptor.downscroll)
				{
					if (note.isSustainEnd)
					{
						note.y += 10.75 * (fakeCrochet / 400) * 1.5 * roundedSpeed + 46 * (roundedSpeed - 1) - 46 * (1 - fakeCrochet / 600) * roundedSpeed;
						if (PlayState.isPixelStage)
							note.y += 8;
					}
					note.y += Note.swagWidth / 2 - 60.5 * (roundedSpeed - 1) + 27.5 * (PlayState.SONG.bpm / 100 - 1) * (roundedSpeed - 1);
				}

				if (receptor.sustainReduce
					&& (botplay || (note.wasGoodHit || (note.prevNote != null && note.prevNote.wasGoodHit && !note.canBeHit))))
				{
					var center:Float = receptor.y + Note.swagWidth / 2;
					var vert:Float = (center - note.y) / note.scale.y;
					var swagRect:FlxRect = null;
					if (receptor.downscroll)
					{
						if (note.y - note.offset.y * note.scale.y + note.height >= center)
							swagRect = new FlxRect(0, note.frameHeight - vert, note.frameWidth, vert);
					}
					else if (note.y + note.offset.y * note.scale.y <= center)
						swagRect = new FlxRect(0, vert, note.width / note.scale.x, note.height / note.scale.y - vert);
					if (swagRect != null)
						note.clipRect = swagRect;
				}
			}

			if (botplay && ((!note.isSustainNote && note.strumTime <= Conductor.songPosition) || (note.isSustainNote && note.canBeHit)))
				onNoteBotHit.dispatch(note);
			onNoteUpdate.dispatch(note);

			if (shouldRemove)
				removeNote(note);
		});
	}

	public function addNote(note:Note)
	{
		allNotes.add(note);
		var leGroup:FlxTypedGroup<Note>;
		if (note.isSustainNote)
			leGroup = holdsGroup;
		else
			leGroup = notesGroup;
		leGroup.add(note);
		leGroup.sort(CoolUtil.sortNotes);
	}

	public function removeNote(note:Note)
	{
		if (note.alive)
		{
			note.kill();
			allNotes.remove(note, true);
			if (note.isSustainNote)
				holdsGroup.remove(note, true);
			else
				notesGroup.remove(note, true);
			note.destroy();
		}
	}

	public function tweenReceptors()
	{
		receptors.forEachAlive(function(receptor:Receptor)
		{
			receptor.y -= 10;
			receptor.alpha = 0;
			FlxTween.tween(receptor, {y: receptor.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * receptor.noteData)});
		});
	}

	public function spawnSplash(noteData:Int)
	{
		var receptor:Receptor = receptors.members[noteData];
		var splash:NoteSplash = splashesGroup.recycle(NoteSplash);
		splash.setupNoteSplash(receptor.x, receptor.y, noteData);
		splashesGroup.add(splash);
	}
}
