#macro version "1.0.0"

isOpen = false;

shellSurface = surface_create(width, height);

cursorPos = 1;
consoleString = "";
savedConsoleString = "";

historyPos = 0;
history = ds_list_create();
output = ds_list_create();

function keyComboPressed() {
	for (var i = 0; i < array_length(modifierKeys); i++) {
		if (!keyboard_check(modifierKeys[i])) {
			return false;
		}
	}
	if (keyboard_check_pressed(ord(openKey))) {
		return true;
	}
}

delayFrame = 0;
delayFrames = 1;
function keyboardCheckDelay(input) {
	if (keyboard_check_released(input)) {
		delayFrame = 0;
		delayFrames = 1;
		return false;
	} else if (!keyboard_check(input)) {
		return false;
	}
	delayFrame = (delayFrame + 1) % delayFrames;
	if (delayFrame == 0) {
		delayFrames = 10;
	}
	if (keyboard_check_pressed(input)) {
		delayFrame = 0;
		delayFrames = 50;
		return true;
	} else {
		if (keyboard_check(input) && delayFrame == 0) {
			return true;
		}
	}
	return false;
}