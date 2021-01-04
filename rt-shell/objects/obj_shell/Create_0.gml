isOpen = false;

shellSurface = surface_create(width, height);

cursorPos = 1;
consoleString = "";
savedConsoleString = "";

historyPos = 0;
history = [];
output = [];

filteredFunctions = [];
suggestionIndex = 0;

// If another instance of rt-shell already exists, destroy ourself
// Must do after initializing surface and lists so our clean-up step succeeds 
if (instance_number(obj_shell) > 1) {
	instance_destroy();
}

/// @function open
/// Opens the shell
function open() {
	isOpen = true;
	keyboard_string = "";
	if (!is_undefined(openFunction)) {
		openFunction();
	}
}

/// @function close
/// Closes the shell
function close() {
	isOpen = false;
	if (!is_undefined(closeFunction)) {
		closeFunction();
	}
}

// Create a list of shell functions in the global namespace to
// filter for autocompletion
autocompleteFunctions = [];
var globalVariables = variable_instance_get_names(global);
for (var i = 0; i < array_length(globalVariables); i++) {
	// Only looking for variables that start with sh_
	if (string_pos("sh_", string_lower(globalVariables[i])) == 1) {
		// Strip off the sh_ when we store them in our array
		autocompleteFunctions[array_length(autocompleteFunctions)] = string_delete(globalVariables[i], 1, 3);
	}
}

// Update the list of functions prefixed by the user's current input
// for use in autocompletion
function updateFilteredFunctions(userInput) {
	array_resize(filteredFunctions, 0);
	for (var i = 0; i < array_length(autocompleteFunctions); i++) {
		if (string_pos(userInput, autocompleteFunctions[i]) == 1) {
			array_push(filteredFunctions, autocompleteFunctions[i]);
		}
	}
	array_sort(filteredFunctions, true);
	suggestionIndex = 0;
}

window_get_width()

// Find the prefix string that the list of suggestions has in common
// used to update the consoleString when user is tab-completing
function findCommonPrefix() {
	if (array_length(filteredFunctions) == 0) {
		return "";
	} else if (array_length(filteredFunctions) == 1) {
		return filteredFunctions[0];
	}
	
	var first = filteredFunctions[0];
	var last = filteredFunctions[array_length(filteredFunctions) - 1];
		
	var result = "";
	// string_char_at is 1-indexed.... sigh
	for (var i = 1; i < string_length(first) + 1; i++) {
		if (string_char_at(first, i) == string_char_at(last, i)) {
			result += string_char_at(first, i);
		} else {
			break;
		}
	}
	
	return result;
}

function keyComboPressed() {
	for (var i = 0; i < array_length(modifierKeys); i++) {
		if (!keyboard_check(modifierKeys[i])) {
			return false;
		}
	}
	if (keyboard_check_pressed(ord(string_upper(openKey)))) {
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
	var splits = []; //array to hold all splits
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