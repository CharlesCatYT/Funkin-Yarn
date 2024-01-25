package;

import flixel.util.FlxTimer;
import flixel.FlxState;
import ui.MenuItem;
import ui.MenuTypedList;
import ui.AtlasMenuItem;
import ui.OptionsState;
import ui.PreferencesMenu;
#if discord_rpc
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static final version:String = '0.1.0-alpha';

	var menuItems:MainMenuList;

	var magenta:FlxSprite;
	var menuCamera:FNFCamera;

	override function create()
	{
		#if discord_rpc
		DiscordClient.changePresence("In the Menus", null);
		#end

		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			CoolUtil.resetMusic();

		menuCamera = new FNFCamera(0.06);
		FlxG.cameras.reset(menuCamera);

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(null, null, Paths.image('menuBG'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.17;
		bg.setGraphicSize(Std.int(bg.width * 1.2));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = PreferencesMenu.getPref('antialiasing');
		add(bg);

		magenta = new FlxSprite(null, null, Paths.image('menuDesat'));
		magenta.scrollFactor.x = bg.scrollFactor.x;
		magenta.scrollFactor.y = bg.scrollFactor.y;
		magenta.setGraphicSize(Std.int(bg.width));
		magenta.updateHitbox();
		magenta.x = bg.x;
		magenta.y = bg.y;
		magenta.visible = false;
		magenta.antialiasing = PreferencesMenu.getPref('antialiasing');
		magenta.color = 0xFFFD719B;
		if (PreferencesMenu.getPref('flashing-menu'))
			add(magenta);

		menuItems = new MainMenuList();
		add(menuItems);
		menuItems.onChange.add(onMenuItemChange);
		menuItems.onAcceptPress.add(function(item:MenuItem)
		{
			FlxFlicker.flicker(magenta, 1.1, 0.15, false, true);
		});
		menuItems.createItem(null, null, "story mode", function()
		{
			startExitState(new StoryMenuState());
		});
		menuItems.createItem(null, null, "freeplay", function()
		{
			startExitState(new FreeplayState());
		});
		#if polymod
		menuItems.createItem(null, null, "mods", function()
		{
			startExitState(new ModsMenuState());
		});
		#end
		menuItems.createItem(null, null, "credits", function()
		{
			startExitState(new CreditsMenuState());
		});
		menuItems.createItem(0, 0, "options", function()
		{
			startExitState(new OptionsState());
		});

		var pos:Float = (FlxG.height - 160 * (menuItems.length - 1)) / 2;
		for (i in 0...menuItems.length)
		{
			var item:MainMenuItem = menuItems.members[i];
			item.x = FlxG.width / 2;
			item.y = pos + (160 * i);
		}

		var versionShit:FlxText = new FlxText(5, FlxG.height - 18, 0, "FNF v" + FlxG.stage.application.meta.get('version') + ' - Funkin\' Yarn v$version', 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		super.create();
	}

	function onMenuItemChange(item:MenuItem)
		menuCamera.camFollow.copyFrom(item.getGraphicMidpoint());

	function startExitState(nextState:FlxState)
	{
		menuItems.enabled = false;
		menuItems.forEachAlive(function(item:MainMenuItem)
		{
			if (menuItems.selectedIndex != item.ID)
				FlxTween.tween(item, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
			else
				item.visible = false;
		});
		new FlxTimer().start(0.4, function(tmr:FlxTimer)
		{
			Main.switchState(nextState);
		});
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * elapsed;

		if (_exiting)
			menuItems.enabled = false;

		if (controls.BACK && menuItems.enabled && !menuItems.busy)
			Main.switchState(new TitleState());

		super.update(elapsed);
	}
}

class MainMenuItem extends AtlasMenuItem
{
	public function new(?x:Float = 0, ?y:Float = 0, name:String, atlas:FlxAtlasFrames, ?callback:Void->Void)
	{
		super(x, y, name, atlas, callback);
		this.scrollFactor.set();
	}

	override public function changeAnim(anim:String)
	{
		super.changeAnim(anim);
		origin.set(frameWidth * 0.5, frameHeight * 0.5);
		offset.copyFrom(origin);
	}
}

class MainMenuList extends MenuTypedList<MainMenuItem>
{
	var atlas:FlxAtlasFrames;

	public function new()
	{
		atlas = Paths.getSparrowAtlas('main_menu');
		super(Vertical);
	}

	public function createItem(?x:Float = 0, ?y:Float = 0, name:String, ?callback:Void->Void, fireInstantly:Bool = false)
	{
		var item:MainMenuItem = new MainMenuItem(x, y, name, atlas, callback);
		item.fireInstantly = fireInstantly;
		item.ID = length;
		addItem(name, item);
		if (length > 4)
		{
			var scr:Float = (length - 4) * 0.135;
			forEachAlive(function(item:MainMenuItem)
			{
				item.scrollFactor.set(0, scr);
			});
		}
		return item;
	}
}
