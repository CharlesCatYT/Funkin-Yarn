package;

using StringTools;

class HealthIcon extends AttachedSprite
{
	public var char:String;
	public var isPlayer:Bool = false;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		offsetY = -30;
		changeIcon(char);
		if (char == 'bf-pixel' || char == 'spirit' || char == 'senpai')
			antialiasing = false;
		else
			antialiasing = PreferencesMenu.getPref('antialiasing');
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public function changeIcon(char:String)
	{
		if (char != 'bf-pixel' && char != 'bf-old')
			char = char.split('-')[0].trim();

		if (char != this.char)
		{
			if (!animation.exists(char))
			{
				var name:String = 'icons/icon-' + char;
				if (!Paths.fileExists('images/' + name + '.png', IMAGE))
					name = 'icons/icon-face'; // no more of these icon crashes!!!!!!!!! :D
				var file:Dynamic = Paths.image(name);
				loadGraphic(file, true, 150, 150);
				animation.add(char, [0, 1], 0, false, isPlayer);
			}
			animation.play(char);
			this.char = char;
		}
	}
}
