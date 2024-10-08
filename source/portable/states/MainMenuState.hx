package portable.states;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.util.FlxAxes;
import portable.VirtualMouse;
import portable.objects.MCButton;
import lime.app.Application;
import options.OptionsState;
import states.editors.MasterEditorMenu;
import openfl.Assets;
import states.TitleState;
import portable.objects.MCText;
import portable.utils.WinUtil;
import states.PlayState;
#if !flash
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end
import shaders.Panorama;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.7.3'; // This is also used for Discord RPC

	// Buttons
	var storyButton:MCButton;
	var freeplayButton:MCButton;
	var creditsButton:MCButton;
	var optionsButton:MCButton;
	var exitButton:MCButton;

	// Debug
	var phraseTxt:MCText;

	// optimize
	static var thePhrase:Null<String> = null;

	private var disable_buttons(default, set):Bool;

	private function set_disable_buttons(value:Bool)
	{
		disable_buttons = value;
		for (i in [storyButton, freeplayButton, creditsButton, optionsButton, exitButton])
			i.disabled_callback = disable_buttons;
		return disable_buttons;
	}

	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var bg = new FlxSprite(508).loadGraphic(Paths.image('guineapiguuhh_stuff/backgrounds/final_' + FlxG.random.int(1, 4)));
		bg.antialiasing = false;
		bg.scrollFactor.set(0, 0);
		bg.updateHitbox();
		bg.screenCenter(Y);
		add(bg);
		bg.scale.set(1.5, 1.5);
		FlxTween.tween(bg, {x: -1265}, 50, {type: PINGPONG});

		var logo:FlxSprite = new FlxSprite(0, 50).loadGraphic(Paths.image('guineapiguuhh_stuff/logo'));
		logo.antialiasing = false;
		logo.scrollFactor.set(0, 0); // pemi
		logo.scale.set(0.65, 0.65);
		logo.updateHitbox();
		logo.screenCenter(X);
		add(logo);

		var distanceButtons = 60;
		storyButton = new MCButton("Story mode", 0, 0, LARGE);
		storyButton.callback = function(self)
		{
			self.disabled = true;
			FlxFlicker.flicker(self, 1, 0.1, true, true, function(f) MusicBeatState.switchState(new StoryMenuState()));
			disable_buttons = true;
		};
		storyButton.clickSound = 'confirmMenu';
		storyButton.screenCenter(XY);

		freeplayButton = new MCButton("Freeplay", 0, storyButton.y + distanceButtons, LARGE);
		freeplayButton.callback = function(self)
		{
			MusicBeatState.switchState(new FreeplayState());
			disable_buttons = true;
		};
		freeplayButton.disabled = !ClientPrefs.data.freeplayUnlock;
		freeplayButton.screenCenter(X);

		creditsButton = new MCButton("Credits", 0, freeplayButton.y + distanceButtons, LARGE);
		creditsButton.callback = function(self)
		{
			MusicBeatState.switchState(new CreditsState());
			disable_buttons = true;
		};
		creditsButton.screenCenter(X);

		optionsButton = new MCButton("Options...", 391.5, creditsButton.y + 100, SMALL);
		optionsButton.callback = function(self)
		{
			MusicBeatState.switchState(new OptionsState());
			OptionsState.onPlayState = false;
			if (PlayState.SONG != null)
			{
				PlayState.SONG.arrowSkin = null;
				PlayState.SONG.splashSkin = null;
				PlayState.stageUI = 'normal';
			}
			disable_buttons = true;
		};

		exitButton = new MCButton("Exit Game", 645.5, creditsButton.y + 100, SMALL);
		exitButton.callback = function(self) Sys.exit(0);

		var canalButton = new MCButton("", optionsButton.x - 60, exitButton.y, YOUTUBE);
		canalButton.callback = function(self) CoolUtil.browserLoad("https://www.youtube.com/@lorenzolo2264");

		var githubButton = new MCButton("", exitButton.x + exitButton.width + 10, exitButton.y, GITHUB);
		githubButton.callback = function(self) CoolUtil.browserLoad("https://github.com/GuineaPigUuhh/V.S.-Ei-Mine");

		var vm = new VirtualMouse();
		for (i in [
			canalButton,
			githubButton,
			exitButton,
			creditsButton,
			optionsButton,
			freeplayButton,
			storyButton
		])
		{
			i.mouseParent = vm;
			add(i);
		}

		if (thePhrase == null)
			thePhrase = FlxG.random.getObject(Assets.getText(Paths.txt('phrases')).split('\n'));
		phraseTxt = new MCText(logo.x + logo.width - 200, logo.y + 170, 320, thePhrase, 25);
		phraseTxt.specialText();
		phraseTxt.angle = -22;
		phraseTxt.alignment = CENTER;
		add(phraseTxt);
		FlxTween.tween(phraseTxt, {"scale.x": 1.08, "scale.y": 1.08}, 0.15, {type: PINGPONG});

		var modVer:MCText = new MCText(3, FlxG.height - 30, FlxG.width, "Friday Night Funkin': V.S. Ei Mine " + WinUtil.getVersion());
		add(modVer);

		add(vm);

		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		if (!selectedSomethin)
		{
			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}
			#if !modFinalBuild
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		#if !modFinalBuild
		if (FlxG.keys.justPressed.F1)
			freeplayButton.disabled = !freeplayButton.disabled;
		#end

		super.update(elapsed);
	}
}
