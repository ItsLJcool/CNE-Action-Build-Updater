//a
import flixel.addons.display.FlxBackdrop;

var fadeInTween:FlxTween;
function create() {
	cam = new FlxCamera();
	cam.bgColor = 0;
	cameras = [cam];
	FlxG.cameras.add(cam, false);

    var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
    bg.alpha = 0.5;
    bg.scrollFactor.set();
    add(bg);

    paint = new FlxBackdrop(Paths.image("games/paint/paint drying"), FlxAxes.XY);
    paint.velocity.set(50, 1);
    paint.alpha = 0.0001;
    add(paint);


    fadeInTween = FlxTween.tween(paint, {alpha: 1}, 5, {ease: FlxEase.quadInOut});
}

var leaving:Bool = false;
function update(elapsed) {
    if (controls.BACK && !leaving) {
        leaving = true;
        fadeInTween?.cancel();
        fadeInTween = FlxTween.tween(paint, {alpha: 0}, 3, {ease: FlxEase.quadInOut, onComplete: () -> {
            FlxG.state.stateScripts.call("onCloseSubState");
            close();
        }});
    }
}