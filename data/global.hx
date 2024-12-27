//a
import funkin.menus.BetaWarningState;
import funkin.editors.ui.UIState;

import funkin.backend.system.macros.GitCommitMacro;
import funkin.backend.utils.HttpUtil;

import funkin.backend.system.Conductor;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import funkin.backend.utils.NativeAPI;
import funkin.backend.utils.NativeAPI.FileAttribute;
import funkin.backend.utils.FileAttribute;

import Sys;
import Type;
import StringTools;

var url = "https://api.github.com/repos/CodenameCrew/CodenameEngine/branches/main";
var needsUpdate = false;
var args = [];

function new() {
    var temp = [];
    for (arg in Sys.args()) {
        if (StringTools.startsWith(arg, "/")) temp.push('-'+arg.substr(1))
        else temp.push(arg);
    }
    args = temp;

    if (args.contains('update')) {
        trace("Updating !!!");
        copyFolder('./.cache', '.');
        new Process('start /B CodenameEngine.exe', null);
        Sys.exit(0);
        return;
    }
    CoolUtil.deleteFolder('./.cache');
    CoolUtil.safeAddAttributes('./.cache/', FileAttribute.HIDDEN); // 0x2
    if (FileSystem.exists("temp.exe")) FileSystem.deleteFile('temp.exe');
    if (FlxG.save.data.autoUpdate) doCheck();
}

function copyFolder(path:String, destPath:String) {
    CoolUtil.addMissingFolders(path);
    CoolUtil.addMissingFolders(destPath);
    for (f in FileSystem.readDirectory(path)) {
        var fPath = path+"/"+f;
        var fDest = destPath+"/"+f;
        if (FileSystem.isDirectory(fPath)) {
            copyFolder(fPath, fDest);
        } else {
            trace("fPath: " + fPath);
            trace("fPath: " + fDest);
            try {
                File.copy(fPath, fDest);
            } catch(e:Error) {
                trace("Failed to copy file: " + e);
            }
        }
    }
}

static var updater_currentGithubHash = null;
static var updater_data = null;
function doCheck() {
    var http = null;
    try {
        http = Json.parse(HttpUtil.requestText(url));
        updater_data = http;
        currentGithubHash = http.commit.sha;
    } catch(e:Error) { trace("Failed to get current github hash"); }
    trace("checking...");
    if (currentGithubHash == null || StringTools.startsWith(currentGithubHash, GitCommitMacro.commitHash)) return;
    needsUpdate = true;
}

function preStateSwitch() {
    stopPlayingSong = false;
    if (!needsUpdate) return;
    if (!(FlxG.game._requestedState is BetaWarningState)) return;
    
    FlxG.save.data.autoUpdate ??= true;
    FlxG.save.data.osChoice ??= "Windows";
    FlxG.save.flush();

    needsUpdate = false;
    FlxG.game._requestedState = new UIState(true, "update.ActionBuildsUpdater");
}


function destroy() {
    stopPlayingSong = funny_playSong = updater_data = updater_currentGithubHash = null;
}

var allSongs = Paths.getFolderContent("music/updateMusic");
var temp = [];
for (song in allSongs) temp.push(Path.withoutExtension(song));
allSongs = temp;

public static var stopPlayingSong = false;

var timeFadeOut = 5;
var time = -1;

public static function funny_playSong() {
    if (stopPlayingSong) return;
	Conductor.reset();
	var randomSong = allSongs[FlxG.random.int(0, allSongs.length-1)];
	FlxG.sound.playMusic(Paths.music("updateMusic/"+randomSong), 0, false);
	FlxG.sound.music.fadeIn(0.25, 0, 0.4);

    time = FlxG.sound.music.length/1000 - timeFadeOut;
}

function update(elapsed:Float) {
    if (time >= 0 && !stopPlayingSong) return time -= elapsed;
    if (time == -1) return;
    time = -1;
    FlxG.sound.music.fadeOut(timeFadeOut, 0, funny_playSong);
}