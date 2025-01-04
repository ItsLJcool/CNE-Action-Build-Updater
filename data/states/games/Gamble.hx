//b
var cam:FlxCamera;
var gambel;
var canClick = true;
var sound = FlxG.sound.load(Paths.sound("fuck you"));

function create() {
        cam = new FlxCamera();
        cam.bgColor = 0;
        cameras = [cam];
        FlxG.cameras.add(cam, false);

        var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        bg.alpha = 0.5;
        bg.scrollFactor.set();
        add(bg);

        gambel = new FlxSprite();
        gambel.frames = Paths.getSparrowAtlas('games/gambling/fuck');
        gambel.animation.addByPrefix('idle', 'idle', 24, true);
        gambel.animation.addByPrefix('gambling', 'aw danging', 24, false);
        gambel.animation.play('idle');
        gambel.scrollFactor.set();
        gambel.screenCenter();
        add(gambel);
}

function update(elapsed:Float) {
        if (controls.BACK) {
                FlxG.state.stateScripts.call("onCloseSubState");
                close();
        }

        if (FlxG.mouse.overlaps(gambel) && FlxG.mouse.pressed && canClick) {
                canClick = false;
                sound.play();
                gambel.animation.play('gambling');
        }

        if (gambel.animation.name == "gambling" && gambel.animation.finished) {
                canClick = true;
                gambel.animation.play('idle');
        }
}