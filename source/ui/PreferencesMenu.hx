package ui;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.util.FlxColor;

class PreferencesMenu extends Page
{
	public static var preferences:Map<String, Dynamic> = new Map<String, Dynamic>();
	static final defaultPreferences:Array<Array<Dynamic>> = [
		['censorship', 'censor-naughty', true],
		['flashing menu', 'flashing-menu', true],
		['note splashes', 'note-splashes', true],
		['camera zooming on beat', 'camera-zoom', true],
		['camera follows char', 'camera-follow-char', true],
		['shake on miss', 'miss-shake', false],
		['stepmania clip style', 'sm-clip', false],
		['downscroll', 'downscroll', false],
		['lane underlay', 'lane-underlay', false],
		['ghost tapping', 'ghost-tapping', true],
		#if (desktop || web)
		['auto pause', 'auto-pause', #if web false #else true #end],
		#end
		['gpu rendering', 'gpu-rendering', false],
		['antialiasing', 'antialiasing', true],
		#if !mobile
		['fps counter', 'fps-counter', true], ['memory counter', 'mem-counter', true], ['memory peak counter', 'mem-peak-counter', true],
		['objects counter', 'obj-counter', false], ['fps watermark', 'watermark-counter', false]
		#end
	];

	// public static var isFloatMap:Map<String, Bool> = new Map();
	/*var descs:Array<String> = [
			"",
			"Makes it so your mom doesn't kick your ass.",
			'Makes it flash the selected item in the main menu.',
			"If unchecked, hitting \"Sick!\" notes won't show particles.",
			'If unchecked, the camera won\'t zoom in on a beat hit',
			"Makes it so the camera follows the characters' offsets.",
			"What do you expect it to do? Lol."
			"",
			'Makes it so notes go down instead of up, simple enough.',
			"If checked, you won't get misses from pressing keys, even if there's no notes to hit.",
			"If checked, it'll display lane underlays.",
			"",
			"If checked, the game will pause itself, whenever the window is unfocused.",
			"If checked, the game will be rendered by the GPU, instead of the CPU. Don't turn this on if you have a shitty graphics card."
			#if !mobile 'If checked, it removes the jagged edges of sprites, at the cost of preformance.', 'A debug counter, explains itself.',
			'A debug counter, explains itself.', 'A debug counter, explains itself.', 'A debug counter, explains itself.',
			'A debug counter, explains itself.' #else 'If checked, it removes the jagged edges of sprites, at the cost of preformance.' #end
		]; */
	static var save:FlxSave;

	// first item: title of the section;
	// other items: options below the section;
	final sections:Array<Array<String>> = [
		[
			'visuals',
			'censor-naughty',
			'flashing-menu',
			'note-splashes',
			'camera-zoom',
			'camera-follow-char',
			'miss-shake',
			'sm-clip'
		],
		['gameplay', 'downscroll', 'ghost-tapping', 'lane-underlay'],
		[
			'misc',
			#if (desktop || web)
			'auto-pause',
			#end
			'gpu-rendering',
			'antialiasing',
			#if !mobile 'fps-counter', 'mem-counter', 'mem-peak-counter', 'obj-counter', 'watermark-counter' #end
		]
	];

	var checkboxes:Array<CheckboxThingie> = [];
	var menuCamera:FNFCamera;
	var items:TextMenuList;

	/*var descNameText:FlxText;
		var descText:FlxText;
		var coolFloatText:FlxText; */
	override public function new()
	{
		super();
		menuCamera = new FNFCamera(0.06);
		FlxG.cameras.add(menuCamera, false);
		menuCamera.bgColor = FlxColor.TRANSPARENT;
		camera = menuCamera;
		add(items = new TextMenuList());
		for (i in 0...sections.length)
		{
			var idx:Int = items.length;
			if (i > 0)
				idx += i;
			var sectionText:AtlasText = new AtlasText(0, 120 * idx + 30, sections[i][0], AtlasFont.Bold);
			sectionText.screenCenter(X);
			add(sectionText);
			for (j in 1...sections[i].length)
			{
				for (pref in defaultPreferences)
				{
					if (pref[1] == sections[i][j])
					{
						createPrefItem(120 * (idx + 1) + 30, pref[0], pref[1], pref[2]);
						idx++;
						break;
					}
				}
			}
		}
		menuCamera.camFollow.x = FlxG.width / 2;
		if (items != null)
			menuCamera.camFollow.y = items.members[items.selectedIndex].y;
		menuCamera.snapToPosition(null, null, true);
		menuCamera.target.setSize(140, 70);
		menuCamera.deadzone.set(0, 160, menuCamera.width, 40);
		menuCamera.minScrollY = 0;
		items.onChange.add(function(item:TextMenuItem)
		{
			menuCamera.camFollow.y = item.y;
		});

		/*var descBorder = new FlxSprite(0, 0).makeGraphic(400, 720, 0x99000000);
			add(descBorder);
			descBorder.x = FlxG.width - descBorder.width;
			descNameText = new FlxText(descBorder.x, 0, descBorder.width, '');
			descNameText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, LEFT);
			add(descNameText);
			descText = new FlxText(descBorder.x, 64, descBorder.width, '');
			descText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
			add(descText); */
		/*coolFloatText = new FlxText(descBorder.x, 120, descBorder.width, '< 1 >');
			coolFloatText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
			add(coolFloatText); */
		/*descBorder.scrollFactor.set();
			descNameText.scrollFactor.set();
			descText.scrollFactor.set(); */
		// coolFloatText.scrollFactor.set();
	}

	inline public static function getPref(pref:String)
	{
		return preferences.get(pref);
	}

	inline public static function setPref(identifier:String, value:Dynamic)
	{
		preferences.set(identifier, value);
	}

	public static function initPrefs()
	{
		save = new FlxSave();
		save.bind('preferences', CoolUtil.getSavePath());
		if (save.data.preferences != null)
			preferences = cast save.data.preferences;
		for (pref in defaultPreferences)
		{
			preferenceCheck(pref[1], pref[2]);
			prefUpdate(pref[1]);
		}
		savePrefs();
	}

	public static function savePrefs()
	{
		save.data.preferences = preferences;
		save.flush();
	}

	inline public static function preferenceCheck(identifier:String, defaultValue:Dynamic)
	{
		if (getPref(identifier) == null)
			setPref(identifier, defaultValue);
	}

	public function createPrefItem(y:Float, label:String, identifier, value:Dynamic)
	{
		items.createItem(120, y, label, AtlasFont.Bold, function()
		{
			preferenceCheck(identifier, value);

			switch (Type.typeof(value).getName())
			{
				case 'TBool':
					prefToggle(identifier);
				default:
					// trace('swag');
			}
		});

		switch (Type.typeof(value).getName())
		{
			case 'TBool':
				createCheckbox(identifier, y);
			/*case 'TFloat':
				isFloatMap.set(identifier, true); */
			default:
				// trace('swag');
		}
	}

	public function createCheckbox(identifier:String, y:Float)
	{
		var box:CheckboxThingie = new CheckboxThingie(0, y - 30, getPref(identifier));
		checkboxes.push(box);
		add(box);
	}

	public function prefToggle(identifier:String)
	{
		var value:Bool = getPref(identifier);
		value = !value;
		preferences.set(identifier, value);
		savePrefs();
		checkboxes[items.selectedIndex].daValue = value;
		// trace('toggled? ' + Std.string(value));
		prefUpdate(identifier);
	}

	public static function prefUpdate(identifier:String)
	{
		var value:Dynamic = getPref(identifier);
		switch (identifier)
		{
			#if (desktop || web)
			case 'auto-pause':
				FlxG.autoPause = value;
			#end
			#if !mobile
			case 'fps-counter':
				if (Main.fpsCounter != null)
					Main.fpsCounter.showFPS = value;
			case 'mem-counter':
				if (Main.fpsCounter != null)
					Main.fpsCounter.showMemory = value;
			case 'mem-peak-counter':
				if (Main.fpsCounter != null)
					Main.fpsCounter.showMemoryPeak = value;
			case 'obj-counter':
				if (Main.fpsCounter != null)
					Main.fpsCounter.showObjectCount = value;
			case 'watermark-counter':
				if (Main.fpsCounter != null)
					Main.fpsCounter.showFPSWatermark = value;
			#end
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (items.exists)
			items.forEachAlive(function(item:MenuItem)
			{
				if (item == items.members[items.selectedIndex])
					item.x = 150;
					// descNameText.text = item.label.text;
					// descText.text = descs[item.ID];
				/*else if (isFloatMap.get(item.label.text))
					item.x = 20; */
				else
					item.x = 120;
			});
	}

	override public function destroy()
	{
		super.destroy();
		if (FlxG.cameras.list.contains(menuCamera))
			FlxG.cameras.remove(menuCamera);
	}
}
