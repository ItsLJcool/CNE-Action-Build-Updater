//a
import funkin.options.type.Checkbox;
import funkin.options.type.TextOption;
import funkin.options.OptionsScreen;

import funkin.editors.ui.UIState;
import flixel.effects.FlxFlicker;

function postCreate() {
    main.add(
        new TextOption("Action Build Updater >", "Settings for the Auto Action Builds Updater", function() {
            optionsTree.add(new OptionsScreen("Action Builds Updater", "Change settings for the Action Builds Updater", getOptions()));
        })
    );
}

function getOptions() {
    var updateText = new TextOption("Check For Updates", "Check if there is an update now!");
    updateText.selectCallback = () -> {
        FlxFlicker.stopFlickering(updateText);
        var update = checkActionUpdates();
        if (!update) return CoolUtil.playMenuSFX(2);
        FlxG.switchState(new UIState(true, "update.ActionBuildsUpdater"));
    }
    return [
        new Checkbox("Auto Check for Updates", "If you want to have Automatic Updates", "autoUpdate", FlxG.save.data),
        updateText
    ];
}