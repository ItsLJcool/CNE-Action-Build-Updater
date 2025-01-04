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
        gambel.animation.finishCallback = () -> {
                new FlxTimer().start(0.25, (timer) -> {
                        canClick = true;
                });
                gambel.animation.play('idle');
        };
        gambel.onDraw = (spr) -> {
                var overlaps = FlxG.mouse.overlaps(spr);
                if (overlaps && FlxG.mouse.pressed && canClick) {
                        canClick = false;
                        sound.play();
                        spr.animation.play('gambling');
                }
                var _alpha = (overlaps && canClick) ? 0.6 : 1;
                spr.alpha = FlxMath.lerp(spr.alpha, _alpha, FlxG.elapsed*5);
                spr.draw();
        };
        gambel.scale.set(0.8, 0.8);
        gambel.updateHitbox();
        gambel.screenCenter();
        gambel.alpha = 0.0001;
        add(gambel);
}

function update(elapsed:Float) {
        if (controls.BACK) {
                FlxG.state.stateScripts.call("onCloseSubState");
                close();
        }
}