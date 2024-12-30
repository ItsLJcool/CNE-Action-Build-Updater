//a
import funkin.backend.utils.HttpUtil;
import sys.Http;

import sys.io.Process;

import openfl.events.IOErrorEvent;
import openfl.events.ErrorEvent;
import openfl.events.Event;
import openfl.events.ProgressEvent;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLStream;
import openfl.net.URLRequest;

import StringTools;

function callHttp(url, ?agent:String, ?onStatus:Void->Void) {
    agent ??= "request";
    onStatus ??= () -> return false;
    
    var statusChanged = false;
    var r = null;
    var h = new Http(url);
    h.setHeader("User-Agent", agent);

    h.onStatus = function(s) {
        if (onStatus(h, s) == true) return;
        if (!HttpUtil.isRedirect(s)) return;
        statusChanged = true;
        r = callHttp(h.responseHeaders.get("Location"));
    };
    
    h.onError = function(e) { trace("Error: " + e); };

    h.onBytes = function(bytes) {
        if (statusChanged) return;
        if (bytes == null) return;
        r = bytes;
    };

    h.request(false);
    return r;
}

var downloaders = [];
function requestZip(link:String, ?onProgress:Float->Void, ?onComplete:Void->Void, ?onError:Void->Void) {
    var url = null;
    var data = callHttp(link, "request", (http, s) -> {
        if (!HttpUtil.isRedirect(s)) return;
        url = http.responseHeaders.get("Location");
        return true;
    });
    if (url == null) return;
    var onError = onError ?? () -> return;
    var onComplete = onComplete ?? () -> return;
    var onProgress = onProgress ?? () -> return;

    var downloadStream = new URLLoader();
    downloadStream.dataFormat = 0;
    
    var request = new URLRequest(StringTools.replace(url, " ", "%20"));
    
    var error = (e) -> {
        trace("Error: " + e);
    };
    var complete = (e) -> {
        onComplete(e, downloadStream);
    };
    var progress = (e) -> {
        var percent = e.bytesTotal > 0 ? e.bytesLoaded / e.bytesTotal : 0;
        onProgress(e, percent);
    }
    downloadStream.addEventListener("ioError", error);
    downloadStream.addEventListener("complete", complete);
    downloadStream.addEventListener("progress", progress);

    downloaders.push({stream: downloadStream, onProgress: progress, onComplete: complete, onError: error});
    downloadStream.load(request);
}


function destroy() {
    for (data in downloaders) {
        data.stream.close();
        data.stream.removeEventListener("progress", data.onProgress);
        data.stream.removeEventListener("complete", data.onComplete);
        data.stream.removeEventListener("ioError", data.onError);
    }
    downloaders = [];
}