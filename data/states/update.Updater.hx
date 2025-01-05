//a
import haxe.Timer;
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
import openfl.utils.ByteArrayData;
import funkin.backend.scripting.MultiThreadedScript;

import sys.Sys;

import StringTools;
import Type;
import haxe.io.Path;

var allGames = Paths.getFolderContent("data/states/games");
var temp = [];
for (song in allGames) temp.push(Path.withoutExtension(song));
allGames = temp;

// openSubState(new ModSubState(randomGame()));
function randomGame() {
    var game = allGames[FlxG.random.int(0, allGames.length-1)];
    return "games/"+game;
}

var CustomHttpUtil = new MultiThreadedScript(Paths.script("data/scripts/HttpUtil"), this);

var os = Std.string(data.os) ?? "windows";
var link = "https://nightly.link/CodenameCrew/CodenameEngine/workflows/"+os+"/main/Codename%20Engine.zip";

var timeSinceText:FlxText;
var timeText = "Prearing to download...";
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

    timeSinceText = new FlxText(0, 0, FlxG.width * 0.5, timeText, 48);
	timeSinceText.setFormat(Paths.font("Funkin'.ttf"), timeSinceText.size, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
    timeSinceText.borderSize = 3;
	timeSinceText.screenCenter();
    add(timeSinceText);

    gamesText = new FlxText(0, 0, 0, "Games >", 32);
	gamesText.setFormat(Paths.font("Funkin'.ttf"), gamesText.size, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
    gamesText.borderSize = 3;
    gamesText.setPosition(FlxG.width - gamesText.width - 25, FlxG.height - gamesText.height - 15);

    gamesListBG = new FlxSprite().makeGraphic(gamesText.width + 150, FlxG.height, 0xFF000000);
    gamesListBG.alpha = 0.25;
    add(gamesListBG);

    var peakText = allGames.join("\n");
    gameTextList = new FlxText(0, 15, gamesListBG.width, peakText, 32);
	gameTextList.setFormat(Paths.font("Funkin'.ttf"), gameTextList.size, FlxColor.WHITE, "right", FlxTextBorderStyle.OUTLINE, 0xFF000000);
    gameTextList.borderSize = 3;
    add(gameTextList);

    var back = CoolUtil.keyToString(Options.P1_BACK[0]);
    var back2 = CoolUtil.keyToString(Options.P2_BACK[0]);
    if (back == "[←]") back = "Backspace";
    var controlText = "Controls:\nSelect Game - "+CoolUtil.keyToString(Options.P1_ACCEPT[0])
    +"\nChange Selection - "+CoolUtil.keyToString(Options.P1_UP[0])+" / "+CoolUtil.keyToString(Options.P1_DOWN[0])
    +"\nLeave Game - "+back+" ("+back2+")";
    theExplainer = new FlxText(0, 0, 0, controlText, 28);
	theExplainer.setFormat(Paths.font("Funkin'.ttf"), theExplainer.size, FlxColor.WHITE, "right", FlxTextBorderStyle.OUTLINE, 0xFF000000);
    theExplainer.borderSize = 3;
    theExplainer.setPosition(gamesListBG.x - theExplainer.width - 15, FlxG.height - theExplainer.height - 15);
    add(theExplainer);
    gamesListBG.setPosition(FlxG.width + gamesListBG.width + theExplainer.width + 15, 0);

    add(gamesText);

    FlxG.mouse.visible = true;
    changeSelectionGame(0);
    
    getZip();
}

function onCloseSubState() {
    enteredGame = false;
    canChangeSelection = true;
}

var canExit = false;
function update(elapsed:Float) {

    if (!enteredGame) canSelectGame = (FlxG.mouse.x > gamesText.x || FlxG.mouse.x > gamesListBG.x);
    if (canSelectGame) {
        gamesListBG.x = FlxMath.lerp(gamesListBG.x, FlxG.width - gamesListBG.width, elapsed * 10);
    } else gamesListBG.x = FlxMath.lerp(gamesListBG.x, FlxG.width + gamesListBG.width + theExplainer.width + 15, elapsed * 10);
    gameTextList.x = gamesListBG.x - 10;
    theExplainer.setPosition(gamesListBG.x - theExplainer.width - 15, FlxG.height - theExplainer.height - 15);
    gamesText.alpha = FlxMath.lerp(gamesText.alpha, (!canSelectGame) ? 1 : 0.6, elapsed * 5);

    if (controls.BACK && canExit) FlxG.switchState(new UIState(true, "update.ActionBuildsUpdater"));
    if (controls.ACCEPT && canSelectGame) enterGame();

    if (controls.UP_P || controls.DOWN_P) changeSelectionGame(controls.UP_P ? -1 : 1);
}

var selectedGame:Int = 0;
var canSelectGame = false;
var canChangeSelection = true;
function changeSelectionGame(amt:Int) {
    if (!canChangeSelection) return;
    selectedGame += amt;

    var max = allGames.length;
    if (selectedGame < 0) selectedGame = max - 1;
    if (selectedGame >= max) selectedGame = 0;

    var shallowCopy = allGames.copy();
    shallowCopy[selectedGame] = ">     " + shallowCopy[selectedGame];
    var peakText = shallowCopy.join("\n");
    gameTextList.text = peakText;
}

var enteredGame:Bool = false;
function enterGame() {
    enteredGame = true;
    canChangeSelection = canSelectGame = false;
    var game = allGames[selectedGame];
    openSubState(new ModSubState("games/"+game));
}


function customReduce(arr, initial, callback) {
    var accumulator = initial;
    for (item in arr) accumulator = callback(accumulator, item);
    return accumulator;
}
function getZip() {
    canExit = false;
    
    #if !ALLOW_MULTITHREADING
        trace("L - Also not tested lmao");
        bytes = HttpUtil.requestBytes(link);
        extractZip(bytes);
        return;
    #end
    
    var lastProgressTime = 0;
    var pingList = [];
    var pingMaxSize = 50;
    CustomHttpUtil.call("requestZip", [link, (e, percent) -> {
        var currentTime = Timer.stamp();
        var interval = (currentTime - lastProgressTime) * 1000; // Convert to milliseconds
    
        // Collect intervals to calculate average ping
        pingList.push(interval);
        if (pingList.length > pingMaxSize) pingList.shift();
    
        // Calculate the average ping using customReduce
        var totalPing = customReduce(pingList, 0.0, (sum, value) -> sum + value);
        var averagePing = Std.int(totalPing / pingList.length);
    
        lastProgressTime = currentTime;

        var totalBytes = event.bytesTotal;
        var receivedBytes = event.bytesLoaded;
        timeSinceText.text = "Downloading...\n"+Std.int(percent*100)+"%";
        if (pingList.length > (pingMaxSize - 10)) timeSinceText.text += "\n\nAverage ping: " + averagePing + "ms";
        timeSinceText.screenCenter();
    }, (e, loader) -> {
        var data = new ByteArrayData();
        loader.data.readBytes(data, 0, loader.data.length - loader.data.position);

        extractZip(data);
    }]);
}

function saveBytesToLocation(daBytes, path:String) {
    CoolUtil.safeSaveFile(path, daBytes);
    return CoolUtil.getSizeString(daBytes.length);
}

var progressTimer:FlxTimer = new FlxTimer();
function extractZip(daBytes) {
    var path = "./.temp/Codename Engine "+os+".zip";
    #if !windows var path = "./Action Build CodenameEngine for "+os+".zip"; #end
    var size = saveBytesToLocation(daBytes, path);

    #if !ALLOW_MULTITHREADING
        completed();
        timeSinceText.text = "No multithreading, check your CodenameEngine.exe folder for the .zip file.";
        timeSinceText.screenCenter();
        return;
    #end

    #if windows
        var progress = ZipUtil.uncompressZipAsync(ZipUtil.openZip(path), "./.cache/");

        var prev_percent = 0;
        var showWhile:Bool = false;
        progressTimer.start(0.5, (tmr) -> {
            if (progress.fileCount == 0) {
                timeSinceText.text = "Preping Extraction...";
                timeSinceText.screenCenter();
                return;
            }
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

function onStateSwitch() {
    CustomHttpUtil.destroy();
}

function destroy() {
    CustomHttpUtil.destroy();
}