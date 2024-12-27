//a
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UIButton;
import funkin.options.Options;

winWidth = winHeight = 300;
winTitle = "Choose your OS to update";

// no android or ios lmao
var osTypes = [
    "Windows",
    "MacOS",
    "Linux",
];
function postCreate() {
    var bruh = FlxG.save.data.osChoice;
    var osIdx = osTypes.indexOf(bruh);
    if (osIdx == -1) osIdx = 0;
    osDropdown = new UIDropDown(0, 0, winWidth * 0.8, 42, osTypes, osIdx);
    osDropdown.x = winWidth * 0.5 - osDropdown.bWidth * 0.5;
    osDropdown.y = winHeight * 0.5 - osDropdown.bHeight * 0.5;
    add(osDropdown);

    continueButton = new UIButton(0, 0, "Continue", continueUpdate, winWidth*0.5, 50);
    continueButton.x = osDropdown.x + osDropdown.bWidth * 0.5 - continueButton.bWidth * 0.5;
    continueButton.y = osDropdown.y + osDropdown.bHeight + 50;
    add(continueButton);
}

function continueUpdate() {
    FlxG.state.stateScripts.call("updateActionBuild", [osTypes[osDropdown.index]]);
    close();
}