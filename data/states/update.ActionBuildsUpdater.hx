//a
import flixel.text.FlxTextBorderStyle;
import flixel.text.FlxTextFormatMarkerPair;
import flixel.text.FlxTextFormat;
import funkin.options.Options;

import funkin.backend.system.Conductor;

import haxe.io.Path;

import flixel.util.FlxGradient;

import funkin.backend.MusicBeatState;
import funkin.editors.ui.UISubstateWindow;
import funkin.menus.BetaWarningState;

import StringTools;

var titleCommit:FlxText;
var commitText:FlxText;

var songTimeGradient:FlxSprite;

var needsScrolling:Bool = false;
var placeholderThings = [];
function create() {
	FlxG.autoPause = false;

	var splitLol = updater_data.commit.commit.message.split("\n\n");
	
	var commitTitle = splitLol[0];
	splitLol = splitLol.filter(function(str) {
		return str != commitTitle;
	});
	var temp = [];
	for (str in splitLol) {
		if (str == "---------") break;
		temp.push(str);
	}
	splitLol = temp;
	
	var commitMessage = splitLol.join("\n");
	// commitMessage = "LALALALALALALA\n";
	// for (i in 0...40) commitMessage += "LALALALALALALA\n";
	 
	var colors = [0xff7b3088, 0xff431b53];
    bgGradient = FlxGradient.createGradientFlxSprite(FlxG.width + 5, FlxG.height + 5, colors, 1, 90, true);
	bgGradient.screenCenter();
	bgGradient.scrollFactor.set();
    add(bgGradient);

	var bg = new FlxSprite(0, 0).loadGraphic(Paths.image("menus/menuTransparent"));
	bg.antialiasing = true;
	bg.setGraphicSize(FlxG.width + 5, FlxG.height + 5);
	bg.updateHitbox();
	bg.screenCenter();
	bg.scrollFactor.set();
	bg.alpha = 0.65;
	add(bg);

	songTimeGradient = FlxGradient.createGradientFlxSprite(FlxG.width + 5, 20, colors, 1, 0, true);
	songTimeGradient.scrollFactor.set();
	songTimeGradient.y = FlxG.height - songTimeGradient.height;
	var width = songTimeGradient.width;
	songTimeGradient.onDraw = (spr:FlxSprite) -> {
		spr.x = FlxMath.lerp(-spr.width, 0, Conductor.songPosition/FlxG?.sound?.music?.length);
		spr.color = 0xFF000000;
		spr.setGraphicSize(spr.width+8, spr.height+8);
		spr.draw();

		spr.setGraphicSize(spr.width, spr.height);
		spr.color = 0xFFFFFFFF;
		spr.draw();
	};
    add(songTimeGradient);

	titleCommit = new FlxText(0, 0, 0, "erm not peak", 28);
	titleCommit.antialiasing = true;
	doFormatting(titleCommit, commitTitle);
	titleCommit.screenCenter();
	titleCommit.y = 25;
	addBackground(titleCommit, 10, (bgSprite:FlxSprite) -> bgSprite.alpha = 0.45);
	add(titleCommit);

	commitText = new FlxText(0, 0, 0, "no message :(", 24);
	commitText.antialiasing = true;
	doFormatting(commitText, commitMessage);
	commitText.screenCenter();
	commitText.y = titleCommit.y + titleCommit.height + 25;
	if (commitMessage.length > 0) {
		addBackground(commitText, 8, (bgSprite:FlxSprite) -> {
			bgSprite.alpha = 0.45;
			if (bgSprite.height > FlxG.height + 5) needsScrolling = true;
		});
		add(commitText);
	}

	autoScroll();
	funny_playSong();

	var anims = [
		"backspace to skip",
		"space to check github",
		"enter to update",
	];
	var offset = 5;
	for (i in 0...3) {
		var phIg = new FlxSprite();
		phIg.frames = Paths.getSparrowAtlas('yceLmao');
		phIg.animation.addByPrefix('idle', anims[i], 1, false);
		phIg.animation.play('idle');
		phIg.antialiasing = true;
		phIg.y = FlxG.height - phIg.height - 15;
		phIg.x = switch(i) {
			case 1: FlxG.width * 0.5 - phIg.width * 0.5;
			case 2: FlxG.width * 0.75;
			default: 15;
		};
		phIg.scrollFactor.set();
		add(phIg);
		phIg.onDraw = (spr:FlxSprite) -> {
			var pos = {x: spr.x, y: spr.y};
			spr.color = 0xFF000000;
			spr.setPosition(spr.x + offset, spr.y - offset*0.5);
			spr.draw();
			spr.color = 0xFFFFFFFF;
			spr.setPosition(pos.x, pos.y);
			spr.draw();
		};
		placeholderThings.push(phIg);
		
	}
}

function update(elapsed:Float) {
	if (FlxG.keys.justPressed.ENTER) openSubState(new UISubstateWindow(true, "update.ChooseOS"));
	if (FlxG.keys.justPressed.SPACE && updater_data._links != null) CoolUtil.openURL(updater_data._links.html);
	if (controls.BACK) {
		stopPlayingSong = true;
		FlxG?.sound?.music?.fadeOut(0.2, 0);
		new FlxTimer().start(0.2, () -> {
			FlxG.sound.music.destroy();
			FlxG.sound.music = null;
			FlxG.autoPause = Options.autoPause;
			FlxG.switchState(new BetaWarningState());
		});
	}
}

function updateActionBuild(os:String) {
	trace("OS: " + os);
	var os = os.toLowerCase();
	MusicBeatState.skipTransOut = MusicBeatState.skipTransIn = true;
	new FlxTimer().start(0.125, () -> {
		FlxG.switchState(new ModState("update.Updater", {os: os}));
	});
}

function autoScroll() {
	if (!needsScrolling) return;
	var heightToGo = commitText.height - FlxG.height*0.75 + commitText.y + 25;

	var time = heightToGo / 110;
	FlxTween.tween(FlxG.camera.scroll, {y: heightToGo}, time, {ease: FlxEase.linear, startDelay: 5});
	FlxTween.tween(FlxG.camera.scroll, {y: 0}, time, {ease: FlxEase.linear, startDelay: time + 5 + 2, onComplete: autoScroll});
}

var colorFormatting = [
	new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFF0000), "<r>"),
	new FlxTextFormatMarkerPair(new FlxTextFormat(0xFF00FF00), "<g>"),
	new FlxTextFormatMarkerPair(new FlxTextFormat(0xFF0000FF), "<b>"),
	new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFFFF00), "<y>"),
	new FlxTextFormatMarkerPair(new FlxTextFormat(0xFF00FFFF), "<c>"),
];
function doFormatting(textToFormat:FlxText, _text:String) {
	var text = _text;
	text = StringTools.replace(text, "* ", "- ");

	textToFormat.setFormat(Paths.font("Funkin'.ttf"), textToFormat.size, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
    textToFormat.borderSize = 2;
	textToFormat.applyMarkup(text, colorFormatting);
}

function addBackground(bindingObject, sizeBounds:Float, onSprAdd:Void->Void) {
	var spr = new FlxSprite().makeGraphic(bindingObject.width + sizeBounds, bindingObject.height + sizeBounds, 0xFF000000);
	spr.antialiasing = true;
	spr.updateHitbox();
	spr.onDraw = (theSpr:FlxSprite) -> {
		theSpr.setPosition(bindingObject.x + bindingObject.width * 0.5 - theSpr.width * 0.5, bindingObject.y + bindingObject.height * 0.5 - theSpr.height * 0.5);
		theSpr.draw();
	};
	add(spr);
	onSprAdd(spr);
}