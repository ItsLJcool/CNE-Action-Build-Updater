//a
import flixel.text.FlxTextBorderStyle;
import flixel.text.FlxTextFormatMarkerPair;
import flixel.text.FlxTextFormat;
import funkin.options.Options;

import haxe.io.Path;
import sys.io.File;

import flixel.util.FlxGradient;
import sys.io.Process;

import funkin.menus.BetaWarningState;
import funkin.editors.ui.UIState;
import funkin.backend.system.Main;

import funkin.backend.utils.ZipUtil;
import funkin.backend.utils.HttpUtil;
import sys.Http;
import sys.Sys;

import StringTools;
import Type;

var os = data.os ?? "windows";
var link = "https://nightly.link/CodenameCrew/CodenameEngine/workflows/"+os+"/main/Codename%20Engine.zip";

var timeSinceText:FlxText;
var timeText = "Seconds since downloading:\n";
var progressText = "Progress:\n$percent\n\nFiles:\n$files\n\nSize:\n$size";
function create() {
    link = StringTools.replace(link, " ", "%20");
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

    timeSinceText = new FlxText(0, 0, 0, "Seconds since downloading:\n0", 48);
	timeSinceText.setFormat(Paths.font("Funkin'.ttf"), timeSinceText.size, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
    timeSinceText.borderSize = 3;
	timeSinceText.screenCenter();
    add(timeSinceText);
    
    getZip();
    // FlxG?.sound?.music?.volume = 1;
    // FlxG?.sound?.music?.fadeOut(1, 0, completed);
}


var done = true;
var timeSince:Float = 0;
function update(elapsed:Float) {
    if (controls.BACK) FlxG.switchState(new UIState(true, "update.ActionBuildsUpdater"));

    if (!done) {
        timeSince += elapsed;
        timeSinceText.text = timeText + Math.floor(timeSince);
        timeSinceText.screenCenter();
        if (bytes == null) return;
        done = true;
        extractZip(bytes);
    }
}

var bytes = null;
function getZip() {
    done = false;
    timeSince = 0;
    
    Main.execAsync(() -> {
        bytes = HttpUtil.requestBytes(link);
    });
    
}

var progressTimer:FlxTimer = new FlxTimer();
function extractZip(daBytes) {
    done = true;
    var path = "./.temp/Codename Engine "+os+".zip";
    var size = CoolUtil.getSizeString(0);
    if (daBytes != null) {
        CoolUtil.safeSaveFile(path, daBytes);
        size = CoolUtil.getSizeString(daBytes.length);
    }

    var progress = ZipUtil.uncompressZipAsync(ZipUtil.openZip(path), "./.cache/");

    var prev_percent = 0;
    var showWhile:Bool = false;
    progressTimer.start(0.5, (tmr) -> {
        var loops = -tmr.loopsLeft;
        var text = progressText;
        text = StringTools.replace(text, "$percent", Std.string(FlxMath.roundDecimal(progress.percentage*100, 2))+"%");
        text = StringTools.replace(text, "$files", Std.string(progress.curFile) + " / " + Std.string(progress.fileCount));
        text = StringTools.replace(text, "$size", Std.string(size));

        if (prev_percent == progress.percentage && loops % 16 == 0) showWhile = true;
        else if (prev_percent != progress.percentage) showWhile = false;

        if (showWhile) text += "\n\nTaking a while to extract, please wait...";

        timeSinceText.text = text;
        timeSinceText.screenCenter();

        prev_percent = progress.percentage;
        if (progress.percentage == 1) {
            stopPlayingSong = true;
            File.copy('CodenameEngine.exe', 'temp.exe');
            FlxG?.sound?.music?.volume = 0;
            completed();
            progressTimer.cancel();
        }
    }, 0);
}

function completed() {
    CoolUtil.playMenuSFX(1);
    var fader = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
    fader.alpha = 0;
    add(fader);
    FlxTween.tween(fader, {alpha: 1}, 0.75, {startDelay: 1.5, ease: FlxEase.quadInOut, onComplete: () -> {
		new Process('start /B temp.exe update', null);
        Sys.exit(0);
    }});
}