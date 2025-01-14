package ui;

import flixel.FlxG;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxOutlineEffect;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;

class ColorsMenu extends Page
{
	var curSelected:Int = 0;

	var grpNotes:FlxTypedGroup<Note>;

	public function new()
	{
		super();

		grpNotes = new FlxTypedGroup<Note>();
		add(grpNotes);

		for (i in 0...4)
		{
			var note:Note = new Note(0, i);

			note.x = (100 * i) + i;
			note.screenCenter(Y);

			var _effectSpr:FlxEffectSprite = new FlxEffectSprite(note, [new FlxOutlineEffect(FlxOutlineMode.FAST, FlxColor.WHITE, 4, 1)]);
			add(_effectSpr);
			_effectSpr.y = 0;
			_effectSpr.x = i * 130;
			_effectSpr.antialiasing = true;
			_effectSpr.scale.x = _effectSpr.scale.y = 0.7;
			_effectSpr.height = note.height;
			_effectSpr.width = note.width;

			grpNotes.add(note);
		}
	}

	override function update(elapsed:Float)
	{
		if (PlayerSettings.player1.controls.UI_RIGHT_P)
			curSelected += 1;
		if (PlayerSettings.player1.controls.UI_LEFT_P)
			curSelected -= 1;

		if (curSelected < 0)
			curSelected = grpNotes.members.length - 1;
		if (curSelected >= grpNotes.members.length)
			curSelected = 0;

		if (PlayerSettings.player1.controls.UI_UP)
		{
			grpNotes.members[curSelected].colorSwap.update(elapsed * 0.3);
			Note.arrowColors[curSelected] += elapsed * 0.3;
		}

		if (PlayerSettings.player1.controls.UI_DOWN)
		{
			grpNotes.members[curSelected].colorSwap.update(-elapsed * 0.3);
			Note.arrowColors[curSelected] += -elapsed * 0.3;
		}

		if (PlayerSettings.player1.controls.RESET)
		{
			trace('i reset my notes :D');
			Note.arrowColors = [1, 1, 1, 1];
		}

		super.update(elapsed);
	}
}
