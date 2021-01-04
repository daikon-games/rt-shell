if (!surface_exists(shellSurface)) {
	shellSurface = surface_create(width, height);
} else if (surface_get_width(shellSurface) != width || surface_get_height(shellSurface) != height) {
	shellSurface = surface_create(width, height);
}

if (!isOpen) {
	if (self.keyComboPressed()) {
		self.open();
	}
} else {
	var prevConsoleString = consoleString;
	
	if (keyboard_check_pressed(vk_escape)) {
		self.close()
	} else if (self.keyboardCheckDelay(vk_backspace)) {
		consoleString = string_delete(consoleString, cursorPos - 1, 1);
		cursorPos = max(1, cursorPos - 1);
	} else if (self.keyboardCheckDelay(vk_delete)) {
		consoleString = string_delete(consoleString, cursorPos, 1);
	} else if (keyboard_string != "") {
		var t = keyboard_string;
		consoleString = string_insert(t, consoleString, cursorPos);
		cursorPos += string_length(t);
		keyboard_string = "";
	} else if (self.keyboardCheckDelay(vk_left)) { 
		cursorPos = max(1, cursorPos - 1);
	} else if (self.keyboardCheckDelay(vk_right)) {
		if (cursorPos == string_length(consoleString) + 1 &&
			array_length(filteredFunctions) != 0) {
			consoleString = filteredFunctions[suggestionIndex];
			cursorPos = string_length(consoleString) + 1;
		} else {
			cursorPos = min(string_length(consoleString) + 1, cursorPos + 1);
		}
	} else if (keyboard_check_pressed(vk_up)) {
		if (historyPos == array_length(history)) {
			savedConsoleString = consoleString;
		}
		historyPos = max(0, historyPos - 1);
		if (array_length(history) != 0) {
			consoleString = array_get(history, historyPos);
			cursorPos = string_length(consoleString) + 1;
		}
	} else if (keyboard_check_pressed(vk_down)) {
		historyPos = min(array_length(history), historyPos + 1);
		if (historyPos == array_length(history)) {
			consoleString = savedConsoleString;
		} else {
			consoleString = array_get(history, historyPos);
		}
		cursorPos = string_length(consoleString) + 1;
	} else if (keyboard_check_pressed(vk_enter)) {
		var args = self.string_split(consoleString, " ");
		if (array_length(args) > 0) {
			var script = asset_get_index("sh_" + args[0]);
			if (script > -1) {
				var response = script_execute(script, args);
				array_push(history, consoleString);
				array_push(output, ">" + consoleString);
				if (response != 0) {
					array_push(output, string(response));
				}
				historyPos = array_length(history);
				consoleString = "";
				savedConsoleString = "";
				cursorPos = 1;
			} else {
				array_push(output, ">" + consoleString);
				array_push(output, "No such command: " + consoleString);
				array_push(history, consoleString);
				historyPos = array_length(history);
				consoleString = "";
				savedConsoleString = "";
				cursorPos = 1;
			}
		} else {
			array_push(output, ">");
			consoleString = "";
			savedConsoleString = "";
			cursorPos = 1;
		}
	} else if (keyboard_check_pressed(vk_tab)) {
		if (array_length(filteredFunctions) != 0) {
			// Auto-complete up to the common prefix of our suggestions
			var uncompleted = consoleString;
			consoleString = self.findCommonPrefix();
			cursorPos = string_length(consoleString) + 1;
			// If we're already autocompleted as far as we can go, rotate through suggestions
			if (uncompleted == consoleString) {
				suggestionIndex = (suggestionIndex + 1) % array_length(filteredFunctions);
			}
		}
	}
	
	if (consoleString != prevConsoleString) {
		// If the text at the prompt has changed, update the list of possible
		// autocomplete suggestions
		self.updateFilteredFunctions(consoleString);
	}
}
