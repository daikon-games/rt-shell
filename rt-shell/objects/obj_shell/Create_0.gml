isOpen = false;
isAutocompleteOpen = false;

shellSurface = noone;
scrollSurface = noone;
shellOriginX = 0;
shellOriginY = 0;
visibleWidth = 0;
visibleHeight = 0;

cursorPos = 1;
consoleString = "";
savedConsoleString = "";
scrollPosition = 0;
maxScrollPosition = 0;
targetScrollPosition = 0;
commandSubmitted = false; // Need to update scroll position one frame after a command is submitted
insertMode = true;

historyPos = 0;
history = [];
output = [];
outputHeight = 0;

filteredSuggestions = [];
inputArray = [];
suggestionIndex = 0;
autocompleteMaxWidth = 0;
autocompleteScrollPosition = 0;
autocompleteOriginX = 0;
autocompleteOriginY = 0;
mousePreviousX = device_mouse_x_to_gui(0);
mousePreviousY = device_mouse_y_to_gui(0);

shellPropertiesHash = "";

// for the bash-style "kill" copy/paste
killedString = "";
// whether we just performed a meta-action, as the keyboard_check_pressed for that key will still register on the next frame...
metaDeleted = false;
metaMovedLeft = false;
metaMovedRight = false;

// Initialize native shell scripts
event_user(0);

// If another instance of rt-shell already exists, destroy ourself
// Must do after initializing surface and lists so our clean-up step succeeds
if (instance_number(object_index) > 1) {
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
function _close_autocomplete() {
	array_resize(filteredSuggestions, 0);
}

// Create a list of shell functions in the global namespace to
// filter for autocompletion
availableFunctions = [];
allFunctions = [];
functionData = {};
var globalVariables = variable_instance_get_names(global);
// Fetch the metadata first so we can utilize it in the available function storage
for (var i = 0; i < array_length(globalVariables); i++) {
	// Only looking for variables that start with meta_
	if (string_pos("meta_", string_lower(globalVariables[i])) == 1) {
		// Strip off the meta_ when we store them in our data struct
		var name = string_delete(string_lower(globalVariables[i]), 1, 5);
		functionData[$ name] = variable_instance_get(global, globalVariables[i])();
	}
}
// Then fetch all the functions themselves
for (var i = 0; i < array_length(globalVariables); i++) {
	// Only looking for variables that start with sh_
	if (string_pos("sh_", string_lower(globalVariables[i])) == 1) {
		// Strip off the sh_ when we store them in our array
		var name = string_delete(string_lower(globalVariables[i]), 1, 3);
		// #32 : don't display hidden functions in the autocomplete
		var hidden = false;
		var metadata = functionData[$ name];
		if (!is_undefined(metadata)) {
			if (variable_struct_exists(metadata, "hidden")) {
				hidden = metadata.hidden;
			}
		}
		if (!hidden) {
			array_push(availableFunctions, name);
		}
		array_push(allFunctions, name);
	}
	// Sort available functions list alphabetically for help command
	array_sort(availableFunctions, true);
}

// Update the list of functions prefixed by the user's current input
// for use in autocompletion
function _update_filtered_suggestions() {
	array_resize(filteredSuggestions, 0);
	autocompleteMaxWidth = 0;
	suggestionIndex = 0;
	var inputString = string_lower(consoleString);
	inputArray = self._string_split(inputString, " ");
	
	// Return if we have nothing to parse
	if (string_length(inputString) == 0 || array_length(inputArray) == 0) { return; }
	
	// Set font for string_width calculation
	draw_set_font(consoleFont);
	
	// Parse through functions
	var spaceCount = string_count(" ", inputString);
	if (spaceCount == 0) {
		for (var i = 0; i < array_length(availableFunctions); i++) {
			if (string_pos(inputString, availableFunctions[i]) == 1 && inputString != availableFunctions[i]) {
				array_push(filteredSuggestions, availableFunctions[i]);
				autocompleteMaxWidth = max(autocompleteMaxWidth, string_width(availableFunctions[i]));
			}
		}
	} else {
		// Parse through argument suggestions
		var functionName = inputArray[0];
		var argumentIndex = spaceCount - 1;
		var dataExists = variable_struct_exists(functionData, functionName);
		var noExtraSpace = (string_char_at(inputString, string_last_pos(" ", inputString) - 1) != " ");
		if (dataExists && noExtraSpace && spaceCount <= array_length(inputArray)) {
			var suggestionData = functionData[$ inputArray[0]][$ "suggestions"];
			var argumentSuggestions = [];
			if (argumentIndex < array_length(suggestionData)) {
				if (is_array(suggestionData[argumentIndex])) {
					// Suggestion data is a static array
					argumentSuggestions = suggestionData[argumentIndex];
				} else if (is_method(suggestionData[argumentIndex])) {
					// #18: Suggestion data is a dynamic function that returns an array
					argumentSuggestions = suggestionData[argumentIndex]();
				}
				var currentArgument = inputArray[array_length(inputArray) - 1];
				for (var i = 0; i < array_length(argumentSuggestions); i++) {
					var prefixMatch = string_pos(currentArgument, string_lower(argumentSuggestions[i])) == 1;
					if (string_last_pos(" ", inputString) == string_length(inputString) || prefixMatch) {
						array_push(filteredSuggestions, argumentSuggestions[i]);
						autocompleteMaxWidth = max(autocompleteMaxWidth, string_width(argumentSuggestions[i]));
					}
				}
			}
		}
	}
	
	array_sort(filteredSuggestions, true);
}

// Find the prefix string that the list of suggestions has in common
// used to update the consoleString when user is tab-completing
function _find_common_prefix() {
	if (array_length(filteredSuggestions) == 0) {
		return "";
	}
	
	var first = string_lower(filteredSuggestions[0]);
	var last = string_lower(filteredSuggestions[array_length(filteredSuggestions) - 1]);
		
	var result = "";
	var spaceCount = string_count(" ", consoleString);
	if (spaceCount > 0) {
		for (var i = 0; i < spaceCount; i++) {
			result += inputArray[i] + " ";
		}
	}
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

function _string_split( _input, _delimiter )
{
	var inpstr = _input;
	
	var arr = [];
	
	while (string_length(inpstr) > 0)
	{
		var delim_pos = string_pos(_delimiter, inpstr);
		
		if (delim_pos == 0) delim_pos = string_length(inpstr)+1;
		
		var copy = string_copy( inpstr, 1, delim_pos-1 );
		// "quoted string" string
		if (string_pos("\"", copy) == 1)
		{
			var end_quote_pos = string_pos_ext("\"", inpstr, 2);
			
			if (end_quote_pos > 0)
			{
				copy = string_copy( inpstr, 2, end_quote_pos-2 );
				delim_pos = end_quote_pos + 2;
			}
		}
		
		inpstr = string_delete( inpstr, 1, delim_pos );
		
		array_push(arr, copy);
	}
	
	return arr;
}

function _key_combo_pressed(modifier_array, key) {
	for (var i = 0; i < array_length(modifier_array); i++) {
		if (!keyboard_check(modifier_array[i])) {
			return false;
		}
	}

	if (keyboard_check_pressed(key)) {
		if (array_length(modifier_array) == 0) {
			if (keyboard_check(vk_shift) || keyboard_check(vk_control) || keyboard_check(vk_alt)) {
				return false;
			}
		}
		
		return true;
	}
}

delayFrame = 0;
delayFrames = 1;
function _keyboard_check_delay(input) {
	if (keyboard_check_released(input)) {
		delayFrame = 0;
		delayFrames = 1;
		return false;
	} else if (!keyboard_check(input)) {
		return false;
	}
	delayFrame = (delayFrame + 1) % delayFrames;
	if (delayFrame == 0) {
		delayFrames = keyRepeatDelay;
	}
	if (keyboard_check_pressed(input)) {
		delayFrame = 0;
		delayFrames = keyRepeatInitialDelay;
		return true;
	} else {
		if (keyboard_check(input) && delayFrame == 0) {
			return true;
		}
	}
	return false;
}

// Calculates a hash of the configurable variables that would cause shell properties to 
// need recalculation if they changed
function _shell_properties_hash() {
	return md5_string_unicode(string(width) + "~" + string(height) + "~" + string(anchorMargin) 
			+ "~" + string(consolePaddingH) + "~" + string(scrollbarWidth) + "~" + 
			string(consolePaddingV) + "~" + string(screenAnchorPointH) + "~" + string(screenAnchorPointV));
}


// Recalculates origin, mainly for changing themes and intializing
function _recalculate_shell_properties() {
	var screenCenterX = display_get_gui_width() / 2;
	var screenCenterY = display_get_gui_height() / 2;
	draw_set_font(consoleFont);
	var emHeight = string_height("M");
	
	// Clamp size of shell to available screen dimensions
	var maxWidth = display_get_gui_width() - (anchorMargin * 2);
	var maxHeight = display_get_gui_height() - (anchorMargin * 2);
	width = clamp(width, 50, maxWidth);
	height = clamp(height, emHeight, maxHeight);
	
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
	
	// Calculate the width of the visible text area, taking into account all margins
	visibleWidth = width - (2 * anchorMargin) - scrollbarWidth - (2 * consolePaddingH);
	visibleHeight = height - (2 * consolePaddingV);
	
	// Save a hash of the shell properties, so we can detect if we need to recalculate
	shellPropertiesHash = self._shell_properties_hash();
}

// Recalculates the scroll offset/position based on the suggestion index within the autocomplete list
function _calculate_scroll_from_suggestion_index() {
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

function _confirm_current_suggestion() {
	var spaceCount = string_count(" ", consoleString);
	consoleString = "";
	for (var i = 0; i < spaceCount; i++) {
		consoleString += inputArray[i] + " ";
	}
	consoleString += filteredSuggestions[suggestionIndex] + " ";
	cursorPos = string_length(consoleString) + 1;
}

/*
 * Returns true if the array contains any instances that match the provided element
 * otherwise returns false
 */
function _array_contains(array, element) {
	for (var i = 0; i < array_length(array); i++) {
		if (array[i] == element) {
			return true;
		}
	}
	return false;
}

/// @param value
/// @param min_input
/// @param max_input
/// @param min_output
/// @param max_output
function _remap(value, min_input, max_input, min_output, max_output) {
	var _t = (value - min_input) / (max_input - min_input);
	return lerp(min_output, max_output, _t);
}

/*
// OLD SPLIT
// Graciously borrowed from here: https://www.reddit.com/r/gamemaker/comments/3zxota/splitting_strings/
function _string_split(_input, _delimiter, _capture_start="\"", _capture_end="\"") {
	var slot = 0;
	var splits = []; //array to hold all splits
	var str2 = ""; //var to hold the current split we're working on building
	var capture = false; // if capture is true, all characters are pulled into a single array element until it's false

	for (var i = 1; i < (string_length(_input) + 1); i++) {
	    var currStr = string_char_at(_input, i);
		
		if (currStr == _capture_start)
		{
			capture = true;
			continue;
		}
		
	    if (currStr == _delimiter  && !capture || capture && currStr == _capture_end) {
			if (str2 != "") { // Make sure we don't include the _delimiter
		        splits[slot] = str2; //add this split to the array of all splits
		        slot++;
				capture = false;
			}
	        str2 = "";
	    } else {
	        str2 = str2 + currStr;
	        splits[slot] = str2;
	    }
	}
	// If we ended on our delimiter character, include an empty string as the final split
	if (str2 == "") {
		splits[slot] = str2;
	}

	return splits;
}

*/