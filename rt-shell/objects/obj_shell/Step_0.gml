if (!isOpen) {
	if (self.keyComboPressed(openModifierKeys, openKey)) {
		self.open();
	}
} else {
	var prevConsoleString = consoleString;
	
	if (keyboard_check_pressed(vk_escape)) {
		if (isAutocompleteOpen) {
			self.close_autocomplete();
		} else {
			self.close()
		}
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
		if (isAutocompleteOpen) {
			suggestionIndex = (suggestionIndex + array_length(filteredFunctions) - 1) % array_length(filteredFunctions);
			self.calculate_scroll_from_suggestion_index()
		} else {
			self.close_autocomplete();
			if (historyPos == array_length(history)) {
				savedConsoleString = consoleString;
			}
			historyPos = max(0, historyPos - 1);
			if (array_length(history) != 0) {
				consoleString = array_get(history, historyPos);
				cursorPos = string_length(consoleString) + 1;
			}
		}
	} else if (keyboard_check_pressed(vk_down)) {
		if (isAutocompleteOpen) {
			suggestionIndex = (suggestionIndex + 1) % array_length(filteredFunctions);
			self.calculate_scroll_from_suggestion_index()
		} else {
			historyPos = min(array_length(history), historyPos + 1);
			if (historyPos == array_length(history)) {
				consoleString = savedConsoleString;
			} else {
				consoleString = array_get(history, historyPos);
			}
			cursorPos = string_length(consoleString) + 1;
		}
	} else if (keyboard_check_pressed(vk_enter)) {
		if (isAutocompleteOpen) {
			consoleString = filteredFunctions[suggestionIndex];
			cursorPos = string_length(consoleString) + 1;	
		} else {
			var args = self.string_split(consoleString, " ");
			if (array_length(args) > 0) {
				var script = asset_get_index("sh_" + args[0]);
				if (script > -1) {
					var response = script_execute(script, args);
					array_push(history, consoleString);
					array_push(output, ">" + consoleString);
					if (response != 0) {
						var newLineSplit = self.string_split(response, "\n");
						array_copy(output, array_length(output), newLineSplit, 0, array_length(newLineSplit));
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
		}
	} else if (keyboard_check_pressed(cycleAutocompleteKey)) {
		if (array_length(filteredFunctions) != 0) {
			// Auto-complete up to the common prefix of our suggestions
			var uncompleted = consoleString;
			consoleString = self.findCommonPrefix();
			cursorPos = string_length(consoleString) + 1;
			// If we're already autocompleted as far as we can go, rotate through suggestions
			if (uncompleted == consoleString) {
				suggestionIndex = (suggestionIndex + 1) % array_length(filteredFunctions);
				if (isAutocompleteOpen) {
					self.calculate_scroll_from_suggestion_index()
				}
			}
		}
	}
	
	// Handle scrolling
	if (isAutocompleteOpen) {
		var x1 = autocompleteOriginX;
		var y1 = autocompleteOriginY;
		var x2 = x1 + autocompleteMaxWidth + font_get_size(consoleFont);
		var y2 = y1 + (string_height(prompt) * min(array_length(filteredFunctions), autocompleteMaxLines));
		if (point_in_rectangle(mouse_x, mouse_y, x1, y1, x2, y2)) {
			if (mouse_wheel_down()) {
				autocompleteScrollPosition++;
				autocompleteScrollPosition = clamp(array_length(filteredFunctions) - autocompleteMaxLines, 0, autocompleteScrollPosition);
			}
			if (mouse_wheel_up()) {
				autocompleteScrollPosition--;
				autocompleteScrollPosition = max(autocompleteScrollPosition, 0);
			}
		} else if (point_in_rectangle(mouse_x, mouse_y, shellOriginX, shellOriginY, shellOriginX + width, shellOriginY + height)) {
			if (mouse_wheel_down()) {
				scrollPosition--;
			}
			if (mouse_wheel_up()) {
				scrollPosition++;
			}
		}
	} else {
		if (point_in_rectangle(mouse_x, mouse_y, shellOriginX, shellOriginY, shellOriginX + width, shellOriginY + height)) {
			if (mouse_wheel_down()) {
				scrollPosition--;
			}
			if (mouse_wheel_up()) {
				scrollPosition++;
			}
		}
	}
	
	if (consoleString != prevConsoleString) {
		// If the text at the prompt has changed, update the list of possible
		// autocomplete suggestions
		self.updateFilteredFunctions(consoleString);
		autocompleteScrollPosition = 0;
	}
}
