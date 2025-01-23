//a
import flixel.util.FlxCollision;
import flixel.effects.FlxFlicker;
import funkin.options.Options;
import haxe.io.Path;

import flixel.text.FlxTextBorderStyle;
import flixel.text.FlxTextFormatMarkerPair;
import flixel.text.FlxTextFormat;

import flixel.math.FlxMath;

var cam:FlxCamera;

var leftSide:FlxSprite;
var rightSide:FlxSprite;

var ball:FlxSprite;

var defaultSize = 300;

var points = {
    cpu: 0,
    player: 0,
};

var scoreText:FlxText;
var colorFormatting = [
	new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFB912E), "<c>"),
	new FlxTextFormatMarkerPair(new FlxTextFormat(0xFF44CCCC), "<p>"),
];

var ballData = [];
function create() {
	cam = new FlxCamera();
	cam.bgColor = 0;
	cameras = [cam];
	FlxG.cameras.add(cam, false);

    var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
    bg.alpha = 0.5;
    bg.scrollFactor.set();
    add(bg);

    leftSide = new FlxSprite().makeGraphic(20, defaultSize, 0xFFFFFFFF);
    leftSide.scrollFactor.set();
    leftSide.screenCenter();
    add(leftSide);

    rightSide = new FlxSprite().makeGraphic(20, defaultSize, 0xFFFFFFFF);
    rightSide.scrollFactor.set();
    rightSide.screenCenter();
    rightSide.y = FlxG.height * 0.5 - rightSide.height * 0.5;
    add(rightSide);

    playerYpos = rightSide.y;
    
    frenzySpritePos = new FlxSprite().loadGraphic(Paths.image("games/pong/INDIE CROCKS")); // .makeGraphic(100, 100, 0xFFFF0000);
    frenzySpritePos.setGraphicSize(100, 100);
    frenzySpritePos.updateHitbox();
    frenzySpritePos.scrollFactor.set();
    frenzySpritePos.onDraw = (spr:FlxSprite) -> {
        if (isInFrenzy) return;
        for (data in frenzyPositions) {
            if (spr.visible) spr.alpha = (data.hasBeenOver) ? 1 : 0.6;
            spr.setPosition(data.x, data.y);
            spr.draw();
        }
    };
    frenzySpritePos.shader = new CustomShader("update.circleProfilePicture");
    // frenzySpritePos.visible = false;
    add(frenzySpritePos);
    generateRandomPoints();

    ball = new FlxSprite();
    ball.loadGraphic(Paths.image("games/pong/ItsLJcool"));
    ball.setGraphicSize(25, 25);
    ball.updateHitbox();
    ball.scrollFactor.set();
    ball.onDraw = (spr:FlxSprite) -> {
        // trace("ballDraw: " + ballData);
        for (data in ballData) {
            spr.setPosition(data.x, data.y);
            spr.draw();
        }
    };
    reset();
    add(ball);

    scoreText = new FlxText(0, 0, FlxG.width, "p", 32);
    scoreText.scrollFactor.set();
    textFormatting(scoreText);
    scoreText.screenCenter();
    scoreText.y = FlxG.height - scoreText.height - 15;
    updateScoreText(false);
    add(scoreText);
}

var playerYpos:Float = 0;
function update(elapsed:Float) {
    if (controls.BACK) {
        FlxG.state.stateScripts.call("onCloseSubState");
        close();
    }

    playerYpos = clamp(playerYpos, 0, FlxG.height - rightSide.height);
    rightSide.y = FlxMath.lerp(rightSide.y, playerYpos, elapsed * 15);

    if (controls.DOWN || controls.UP) playerYpos += 500*elapsed * (controls.UP ? -1 : 1);
    
    aiUpdate(elapsed);

    for (idx=>data in ballData) {
        data.x += data.velocity.x * elapsed;
        data.y += data.velocity.y * elapsed;

        if ((data.x + ball.width) > FlxG.width || data.x < 0) {
            // ball.velocity.x *= -1;
            if (data.x < 0) {
                ai_difficulty += FlxG.random.float(0, 0.02);
                if (FlxG.random.bool(20)) ai_difficulty += FlxG.random.float(0.02, 0.03);
            }
            // if ((data.x + ball.width) > FlxG.width) points.cpu++; // data.x = FlxG.width - data.width;
            ballData.remove(data);
            continue;
        }
        
        if ((data.y + ball.height) > FlxG.height || data.y < 0) {
            data.velocity.y *= -1;
            if (data.y < 0) data.y = 0;
            if ((data.y + ball.height) > FlxG.height) data.y = FlxG.height - ball.height;
        }

        var extraData = { x: data.x, y: data.y, velocity: data.velocity, width: ball.width, height: ball.height, };
        var _data = checkCollision(extraData, leftSide, (item) -> {
            onCollision(item, false);
        });
        _data = checkCollision(extraData, rightSide, (item) -> {
            onCollision(item, true);
        });
        ballData[idx] = { x: _data.x, y: _data.y, velocity: _data.velocity, };
        
        if (!isInFrenzy) {
            for (idx=>frenzy in frenzyPositions) {
                var extraFrenzy = { x: frenzy.x, y: frenzy.y, velocity: {x: 0, y: 0}, width: frenzySpritePos.width, height: frenzySpritePos.height, };
                if (!checkOverlap(extraData, extraFrenzy) || frenzy.hasBeenOver) continue;
                frenzy.hasBeenOver = true;
            }
        }
    }

    // trace(ballData.length);

    if (checkFrenzy && ballData.length < 2 && isInFrenzy) isInFrenzy = checkFrenzy = false;

    var frenzyKILLME = 0;
    for (data in frenzyPositions) {
        if (!data.hasBeenOver) break;
        frenzyKILLME++;
    }
    if (frenzyKILLME == frenzyPositions.length) frenzy();

    if (ballData.length == 0) reset();
}

var ai_difficulty:Float = 0;
var baseSpeed:Float = 100;
function aiUpdate(elapsed) {
    var ballFollowing = ballData[0];
    for (data in ballData) {
        if (data.x < ballFollowing.x && data.x > leftSide.x) ballFollowing = data;
    };
    // leftSide.y = FlxMath.lerp(leftSide.y, ballFollowing.y + ball.height * 0.5 - leftSide.height * 0.5, elapsed * aiLevel);

    // Center of the paddle
    var paddleCenter = leftSide.y + (leftSide.height * 0.5);
    // Center of the ball with randomness based on difficulty
    var randomOffset = (1 - ai_difficulty) * FlxG.random.float(-40, 40); // Larger offset for lower difficulty
    var targetPosition = ballFollowing.y + (ball.height * 0.5) + randomOffset;

    // Adjust speed based on difficulty
    var speed = baseSpeed * (ai_difficulty+1);

    // Move the paddle towards the target position
    if (paddleCenter < targetPosition) {
        leftSide.y += speed * elapsed;
    } else if (paddleCenter > targetPosition) {
        leftSide.y -= speed * elapsed;
    }

    // Clamp the paddle within screen bounds
    leftSide.y = clamp(leftSide.y, 0, FlxG.height - leftSide.height);
    ai_difficulty = clamp(ai_difficulty, 0, 1); 
}

function clamp(value:Float, min:Float, max:Float):Float {
    if (value < min) return min;
    if (value > max) return max;
    return value;
}

var frenzyPositions = [];
function generateRandomPoints() {
    frenzyPositions = [];
    for (idx in 0...FlxG.random.int(3, 5)) {
        var item = frenzyPositions[idx];
        var pos = (item != null) ? {x: item.x, y: item.y, width: frenzySpritePos.width, height: frenzySpritePos.height, } : null;

        var x = FlxG.random.int(250, FlxG.width - 250);
        var y = FlxG.random.int(250, FlxG.height - 250);

        if (pos != null) {
            if (checkOverlap(pos, leftSide)) x = pos.x + pos.width + 20;
            if (checkOverlap(pos, rightSide)) y = pos.y + pos.height + 20;
        }

        var data = {
            x: x,
            y: y,
            hasBeenOver: false,
        };

        frenzyPositions.push(data);
    }
}

var isInFrenzy:Bool = false;
var checkFrenzy:Bool = false;
var frenzyCooldown:FlxTimer = new FlxTimer();
function frenzy() {
    if (isInFrenzy) return;
    frenzyCooldown.cancel();
    generateRandomPoints();
    checkFrenzy = false;
    isInFrenzy = true;

    var sound = FlxG.sound.load(Paths.sound("Frenzy"));
    var frenzyText = new FlxText(0, 0, 0, "Frenzy!", 52);
    frenzyText.scrollFactor.set();
    textFormatting(frenzyText);
    frenzyText.borderSize = 3;
    frenzyText.screenCenter();
    add(frenzyText);
    var colors = [0xFFFF0000, 0xFFFFFF00, 0xFFFF00FF, 0xFF00FFFF, 0xFF00FF00];

    sound.play();

    var timer = new FlxTimer();
    var lastIdx = 0;
    var idx = 0;
    timer.start(0.1, (tmr) -> {
        if (!sound.playing || frenzyText == null) {
            checkFrenzy = true;
            return timer.cancel();
        }
        idx = FlxG.random.int(0, colors.length-1, [idx]);
        frenzyText.color = colors[idx];
    }, 0);
    var time = 0.5;
    FlxTween.tween(frenzyText, {alpha: 0}, time, {startDelay: sound.length*0.001 + 0.5, onComplete: () -> {
        frenzyText.kill();
        frenzyText.destroy();
        remove(frenzyText, true);
    }});

    var amountToSpawn = FlxG.random.int(8, 15);
    // var amountToSpawn = 9999999999999999999;

    var timeToSpawn = 0.25;
    // var timeToSpawn = 0.02;
    new FlxTimer().start(timeToSpawn, () -> {
        if (!timer.active) {
            checkFrenzy = true;
            return;
        }
        addBall();
    }, amountToSpawn);

    
    for (spr in [leftSide, rightSide]) updateBarSize(spr.height + 50);

    frenzyCooldown = new FlxTimer().start(15, () -> {
        isInFrenzy = checkFrenzy = false;
    });
}

function textFormatting(text:FlxText) {
	text.setFormat(Paths.font("Funkin'.ttf"), text.size, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
    text.borderSize = 2;
}

function addBall(?x:Float, ?y:Float, ?velocityX:Float, ?velocityY:Float, ?callback:Dynamic->Void) {
    var dir = (FlxG.random.bool(50)) ? 1 : -1;
    var dir2 = (FlxG.random.bool(50)) ? 1 : -1;

    var x = x ?? FlxG.width * 0.5 + ball.width * 0.5;
    var y = y ?? FlxG.height * 0.5 + ball.height * 0.5;
    var velocityX = velocityX ?? FlxG.random.int(100, 200)*dir;
    var velocityY = velocityY ?? FlxG.random.int(50, 250)*dir2;
    var data = { x: x, y: y, velocity: { x: velocityX, y: velocityY, } };
    ballData.push(data);

    callback ??= () -> {};
    callback(data);
}

function updateScoreText(flicker:Bool = true) {
    flicker ??= true;
    scoreText.text = "<c>CPU: "+points.cpu+"<c>  |  <p>Player: "+points.player+"<p>";
    scoreText.screenCenter();
    scoreText.y = FlxG.height - scoreText.height - 15;
	scoreText.applyMarkup(scoreText.text, colorFormatting);

    if (flicker) {
        scoreText.visible = false;
        FlxFlicker.flicker(scoreText, 0.75, Options.flashingMenu ? 0.06 : 0.15, true, false, function(t) {});
    }
}

// collision detection
var maxMinSize = 150;
function onCollision(ball, playerHit:Bool) {
    var dir = (ball.velocity.x > 0) ? 1 : -1;
    ball.velocity.x += FlxG.random.int(25, 100)*dir;
    ball.velocity.y += FlxG.random.int(50, 150)*dir;


    if (playerHit == null) return;
    var sizeChange = 5;
    
    if (playerHit) {
        points.player++;
        updateBarSize(rightSide.height - sizeChange);
    }
    else {
        points.cpu++;
        updateBarSize(leftSide.height - sizeChange);
    }
    updateScoreText();

}

function reset() {
    ballData = [];
    addBall();
    ballData[0].x = FlxG.width * 0.5 + ball.width * 0.5;
    ballData[0].y = FlxG.height * 0.5 + ball.height * 0.5;
    ballData[0].velocity.x = FlxG.random.int(100, 200);
    ballData[0].velocity.y = FlxG.random.int(100, 200);
    
    updateBarSize(defaultSize);
}

function updateBarSize(instant:Bool = false, height:Float, ?time:Float = 0.5) {
    instant ??= false;
    var fire = (spr:FlxSprite, idx:Int, v:Float) -> {
        spr.setGraphicSize(spr.width, v);
        spr.updateHitbox();
        if (idx == 0) spr.x = spr.width * 1.5;
        else spr.x = FlxG.width - spr.width * 1.5;
    }
    if (instant) return fire(height);
    var height = height;
    var time = time ?? 0.5;
    for (idx=>spr in [leftSide, rightSide]) {
        fire(spr, idx, height);
    }
}

function checkCollision(ball:Dynamic, target:FlxSprit, ?callback:Void->Void) {
    var ballBottom = ball.y + ball.height;
    var ballTop = ball.y;
    var ballRight = ball.x + ball.width;
    var ballLeft = ball.x;

    var targetBottom = target.y + target.height;
    var targetTop = target.y;
    var targetRight = target.x + target.width;
    var targetLeft = target.x;

    if (!checkOverlap(ball, target)) return ball;

    var overlapX = Math.min(ballRight - targetLeft, targetRight - ballLeft);
    var overlapY = Math.min(ballBottom - targetTop, targetBottom - ballTop);

    if (overlapX < overlapY) {
        callback ??= () -> {};
        if (ball.x < target.x) ball.x = target.x - ball.width;
        else ball.x = target.x + target.width;
        ball.velocity.x *= -1;
        callback(ball);
    } else {
        if (ball.y < target.y) ball.y = target.y - ball.height;
        else ball.y = target.y + target.height;
        ball.velocity.y *= -1;
        callback ??= () -> {};
        callback(ball);
    }

    return ball;
}

function checkOverlap(item, target) {
    // because FLXCOLLISION ISN'T PERCISE ENOUGH?!??!??
    var ballBottom = item.y + item.height;
    var ballTop = item.y;
    var ballRight = item.x + item.width;
    var ballLeft = item.x;

    var targetBottom = target.y + target.height;
    var targetTop = target.y;
    var targetRight = target.x + target.width;
    var targetLeft = target.x;
    
    return (ballRight > target.x && item.x < targetRight && ballBottom > target.y && item.y < targetBottom);
}