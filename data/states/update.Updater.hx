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

    timeSinceText = new FlxText(0, 0, FlxG.width * 0.5, "Seconds since downloading:\n0", 48);
	timeSinceText.setFormat(Paths.font("Funkin'.ttf"), timeSinceText.size, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
    timeSinceText.borderSize = 3;
	timeSinceText.screenCenter();
    add(timeSinceText);
    
    getZip();
    // FlxG?.sound?.music?.volume = 1;
    // FlxG?.sound?.music?.fadeOut(1, 0, completed);
}


var done = true;
var canExit = true;
var timeSince:Float = 0;
function update(elapsed:Float) {
    if (controls.BACK && canExit) FlxG.switchState(new UIState(true, "update.ActionBuildsUpdater"));

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
    canExit = false;
    done = false;
    timeSince = 0;
    
    Main.execAsync(() -> {
        bytes = HttpUtil.requestBytes(link);
    });
    
}

function saveBytesToLocation(daBytes, path:String) {
    CoolUtil.safeSaveFile(path, daBytes);
    return CoolUtil.getSizeString(daBytes.length);
}

var progressTimer:FlxTimer = new FlxTimer();
function extractZip(daBytes) {
    done = true;
    var path = "./.temp/Codename Engine "+os+".zip";
    #if !windows var path = "./Action Build CodenameEngine for "+os+".zip"; #end
    var size = saveBytesToLocation(daBytes, path);

    #if windows
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
            if (progress.percentage == 1) completed();
        }, 0);
    #else
        completed();
    #end
}

function completed() {
    progressTimer.cancel();
    stopPlayingSong = true;

    FlxG?.sound?.music?.volume = 0;
    CoolUtil.playMenuSFX(1);

    #if windows
        File.copy('CodenameEngine.exe', 'temp.exe');
        fadeOut(() -> {
            new Process('start /B temp.exe update', null);
            Sys.exit(0);
        });
    #else
        canExit = true;
        timeSinceText.size -= 12;
        timeSinceText.text = "Downloaded!\n\nSince your not on windows, This Updater cannot extract the files from engine.\n\nPlease check your CodenameEngine folder for the downloaded compressed file.";
        timeSinceText.screenCenter();
    #end
}

function fadeOut(callback:Void->Void) {
    callback ??= () -> {};
    var fader = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
    fader.alpha = 0.0001;
    add(fader);
    FlxTween.tween(fader, {alpha: 1}, 0.75, {startDelay: 1.5, ease: FlxEase.quadInOut, onComplete: callback});
}