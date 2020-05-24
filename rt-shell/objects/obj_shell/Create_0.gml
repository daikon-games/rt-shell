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
		delayFrames = 5;
	}
	if (keyboard_check_pressed(input)) {
		delayFrame = 0;
		delayFrames = 30;
		return true;
	} else {
		if (keyboard_check(input) && delayFrame == 0) {
			return true;
		}
	}
	return false;
}

// Graciously borrowed from here: https://www.reddit.com/r/gamemaker/comments/3zxota/splitting_strings/
function string_split(input, delimiter) {
	var slot = 0;
	var splits; //array to hold all splits
	var str2 = ""; //var to hold the current split we're working on building

	var i;
	for (i = 1; i < (string_length(input)+1); i++) {
	    var currStr = string_copy(input, i, 1);
	    if (currStr == delimiter) {
	        splits[slot] = str2; //add this split to the array of all splits
	        slot++;
	        str2 = "";
	    } else {
	        str2 = str2 + currStr;
	        splits[slot] = str2;
	    }
	}

	return splits;
}