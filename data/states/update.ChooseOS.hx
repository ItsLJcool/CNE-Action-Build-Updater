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
var osIdx = 0;
function postCreate() {
    osIdx = #if windows 0 #elseif mac 1 #elseif linux 2 #end; // Thanks crimson lmao
    osDropdown = new UIDropDown(0, 0, winWidth * 0.8, 42, osTypes, osIdx);
    osDropdown.x = winWidth * 0.5 - osDropdown.bWidth * 0.5;
    osDropdown.y = winHeight * 0.5 - osDropdown.bHeight * 0.5;
    add(osDropdown);

    continueButton = new UIButton(0, 0, "Continue", continueUpdate, winWidth*0.4, 50);
    continueButton.x = winWidth - cancelButton.bWidth - 15;
    continueButton.y = osDropdown.y + osDropdown.bHeight + 50;
    add(continueButton);

    cancelButton = new UIButton(0, 0, "Exit", close, winWidth*0.4, 50);
    cancelButton.x = 15;
    cancelButton.y = osDropdown.y + osDropdown.bHeight + 50;
    cancelButton.color = 0xFFFF0000;
    add(cancelButton);
}

function continueUpdate() {
    FlxG.state.stateScripts.call("updateActionBuild", [osTypes[osDropdown.index]]);
    close();
}