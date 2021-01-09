/// @description Init
isOpen = false;
isAutocompleteOpen = false;

shellSurface = noone;
shellOriginX = 0;
shellOriginY = 0;

cursorPos = 1;
consoleString = "";
savedConsoleString = "";
scrollPosition = 0;

historyPos = 0;
history = [];
output = [];

filteredFunctions = [];
suggestionIndex = 0;
autocompleteMaxWidth = 0;
autocompleteScrollPosition = 0;
autocompleteOriginX = 0;
autocompleteOriginY = 0;
mousePreviousX = mouse_x;
mousePreviousY = mouse_y;

// Init native shell scripts
event_user(0);

// If another instance of rt-shell already exists, destroy ourself
// Must do after initializing surface and lists so our clean-up step succeeds
if (instance_number(obj_shell) > 1) {
	instance_destroy();
}

/// Opens the shell
function open() {
	isOpen = true;
	keyboard_string = "";
	if (!is_undefined(openFunction)) {
		openFunction();
	}
}

/// Closes the shell
function close() {
	isOpen = false;
	if (!is_undefined(closeFunction)) {
		closeFunction();
	}
}

/// Closes autocomplete
function close_autocomplete() {
	array_resize(filteredFunctions, 0);
}

// Create a list of shell functions in the global namespace to
// filter for autocompletion
autocompleteFunctions = [];
var globalVariables = variable_instance_get_names(global);
for (var i = 0; i < array_length(globalVariables); i++) {
	// Only looking for variables that start with sh_
	if (string_pos("sh_", string_lower(globalVariables[i])) == 1) {
		// Strip off the sh_ when we store them in our array
		array_push(autocompleteFunctions, string_delete(globalVariables[i], 1, 3));
	}
}
// Add native shell scripts to functions list
//array_push(autocompleteFunctions, 


// Update the list of functions prefixed by the user's current input
// for use in autocompletion
function updateFilteredFunctions(userInput) {
	array_resize(filteredFunctions, 0);
	autocompleteMaxWidth = 0;
	for (var i = 0; i < array_length(autocompleteFunctions); i++) {
		if (string_pos(userInput, autocompleteFunctions[i]) == 1) {
			array_push(filteredFunctions, autocompleteFunctions[i]);
			autocompleteMaxWidth = max(autocompleteMaxWidth, string_width(autocompleteFunctions[i]));
		}
	}
	array_sort(filteredFunctions, true);
	suggestionIndex = 0;
}

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

function keyComboPressed(modifier_array, key) {
	for (var i = 0; i < array_length(modifier_array); i++) {
		if (!keyboard_check(modifier_array[i])) {
			return false;
		}
	}

	if (keyboard_check_pressed(key)) {
		if (array_length(modifier_array) == 0) {
			if (keyboard_check(vk_shift) or keyboard_check(vk_control) or keyboard_check(vk_alt)) {
				return false;
			}
		}
		
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

// Recalculates origin, mainly for changing themes and intializing
function recalculate_shell_properties() {
	var screenCenterX = display_get_gui_width() / 2;
	var screenCenterY = display_get_gui_height() / 2;
	var halfWidth = width / 2;
	var halfHeight = height / 2;
	
	switch (screenAnchorPointH) {
		case "left":
			shellOriginX = anchorMargin - 1;
			break;
		case "center":
			shellOriginX = screenCenterX - halfWidth - 1;
			break;
		case "right":
			shellOriginX = display_get_gui_width() - width - anchorMargin - 1;
			break;
	}
	
	switch (screenAnchorPointV) {
		case "top":
			shellOriginY = anchorMargin - 1;
			break;
		case "middle":
			shellOriginY = screenCenterY - halfHeight - 1;
			break;
		case "bottom":
			shellOriginY = display_get_gui_height() - height - anchorMargin - 1;
			break;
	}
	
	// Resize width if larger than gui
	if (width > display_get_gui_width()) { width = display_get_gui_width() - anchorMargin * 2; }
	if (height > display_get_gui_height()) { height = display_get_gui_height() - anchorMargin * 2; }
}

// Recalculates the scroll offset/position based on the suggestion index within the autocomplete list
function calculate_scroll_from_suggestion_index() {
	if (suggestionIndex == 0)  {
		autocompleteScrollPosition = 0;
	} else {
		if (suggestionIndex >= autocompleteScrollPosition + autocompleteMaxLines) {
			autocompleteScrollPosition = max(0, suggestionIndex - autocompleteMaxLines + 1);
		} else if (suggestionIndex < autocompleteScrollPosition) {
			autocompleteScrollPosition = autocompleteScrollPosition - suggestionIndex;
		}
	}
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