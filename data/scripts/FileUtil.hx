//a
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import openfl.display.BitmapData;

function copyFolder(path:String, destPath:String, ?onComplete:Void->Void, ?onError:Void->Void) {
    var complete = onComplete ?? () -> return;
    var failed = onError ?? () -> return;

    trace("Start");

    CoolUtil.addMissingFolders(path);
    CoolUtil.addMissingFolders(destPath);
    for (f in FileSystem.readDirectory(path)) {
        var fPath = path+"/"+f;
        var fDest = destPath+"/"+f;
        if (FileSystem.isDirectory(fPath)) {
            copyFolder(fPath, fDest);
        } else {
            try {
                File.copy(fPath, fDest);
            } catch(e:Error) {
                trace("Failed to copy file: " + e);
                failed(e);
            }
        }
    }
    complete();
}

function loadImageFromUrl(url:String, ?onComplete:BitmapData->Void, ?onError:Void->Void) {
    var error = onError ?? () -> return;
    var complete = onComplete ?? () -> return;
    try {
        BitmapData.loadFromFile(url).onComplete(function(bitmap:BitmapData) {
            complete(bitmap);
        });
    } catch(e:Error) {
        trace("Failed to load image from url: " + e);
        error(e);
    }
}