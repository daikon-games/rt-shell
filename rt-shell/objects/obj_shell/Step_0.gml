if (!isOpen) {
	if (self.keyComboPressed(openModifiers, openKey)) {
		self.open();
	}
} else {
	var prevConsoleString = consoleString;
	var maxScrollPosition = max(0, surface_get_height(scrollSurface) - visibleHeight);
	
	// Detect if a command was sent last frame, 
	// update scroll position now that output is printed
	if (commandSubmitted) {
		scrollPosition = maxScrollPosition;
		commandSubmitted = false;
	}
	
	// Recalculate shell properties if certain variables have changed
	if (shell_properties_hash() != shellPropertiesHash) {
		recalculate_shell_properties();
	}
	
	if (keyboard_check_pressed(vk_escape)) {
		if (isAutocompleteOpen) {
			self.close_autocomplete();
		} else {
			self.close()
		}
	} else if (self.keyboardCheckDelay(vk_backspace)) {
		consoleString = string_delete(consoleString, cursorPos - 1, 1);
		cursorPos = max(1, cursorPos - 1);
		scrollPosition = maxScrollPosition;
	} else if (self.keyboardCheckDelay(vk_delete)) {
		consoleString = string_delete(consoleString, cursorPos, 1);
		scrollPosition = maxScrollPosition;
	} else if (keyboard_string != "") {
		var t = keyboard_string;
		consoleString = string_insert(t, consoleString, cursorPos);
		cursorPos += string_length(t);
		keyboard_string = "";
		scrollPosition = maxScrollPosition;
	} else if (self.keyboardCheckDelay(vk_left)) { 
		cursorPos = max(1, cursorPos - 1);
		scrollPosition = maxScrollPosition;
	} else if (self.keyboardCheckDelay(vk_right)) {
		if (cursorPos == string_length(consoleString) + 1 &&
			array_length(filteredSuggestions) != 0) {
			consoleString = filteredSuggestions[suggestionIndex];
			cursorPos = string_length(consoleString) + 1;
		} else {
			cursorPos = min(string_length(consoleString) + 1, cursorPos + 1);
		}
		scrollPosition = maxScrollPosition;
	} else if (self.keyComboPressed(historyUpModifiers, historyUpKey)) {
		if (historyPos == array_length(history)) {
			savedConsoleString = consoleString;
		}
		historyPos = max(0, historyPos - 1);
		if (array_length(history) != 0) {
			consoleString = array_get(history, historyPos);
			cursorPos = string_length(consoleString) + 1;
		}
	} else if (self.keyComboPressed(historyDownModifiers, historyDownKey)) {
		if (historyPos < array_length(history)) {
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
			self.confirmCurrentSuggestion();
		} else {
			var args = self.string_split(consoleString, " ");
			if (array_length(args) > 0) {
				var script = variable_global_get("sh_" + args[0]);
				if (script != undefined) {
					var response = script_execute(asset_get_index(script_get_name(script)), args);
					array_push(history, consoleString);
					if (response != "") { array_push(output, ">" + consoleString); }
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
		commandSubmitted = true;
	} else if (self.keyComboPressed(cycleSuggestionsModifiers, cycleSuggestionsKey)) {
		if (array_length(filteredSuggestions) != 0) {
			// Auto-complete up to the common prefix of our suggestions
			var uncompleted = consoleString;
			consoleString = self.findCommonPrefix();
			cursorPos = string_length(consoleString) + 1;
			// If we're already autocompleted as far as we can go, rotate through suggestions
			if (uncompleted == consoleString) {
				suggestionIndex = (suggestionIndex + 1) % array_length(filteredSuggestions);
				if (isAutocompleteOpen) {
					self.calculate_scroll_from_suggestion_index()
				}
			}
		}
	} else if (self.keyComboPressed(cycleSuggestionsReverseModifiers, cycleSuggestionsReverseKey)) {
		suggestionIndex = (suggestionIndex + array_length(filteredSuggestions) - 1) % array_length(filteredSuggestions);
		if (isAutocompleteOpen) {
			self.calculate_scroll_from_suggestion_index()
		}
	}
	
	// Handle scrolling
	if (isAutocompleteOpen) {
		var x1 = autocompleteOriginX;
		var y1 = autocompleteOriginY;
		var x2 = x1 + autocompleteMaxWidth + font_get_size(consoleFont);
		var y2 = y1 + (string_height(prompt) * min(array_length(filteredSuggestions), autocompleteMaxLines));
		if (point_in_rectangle(mouse_x, mouse_y, x1, y1, x2, y2)) {
			if (mouse_wheel_down()) {
				autocompleteScrollPosition++;
				autocompleteScrollPosition = clamp(array_length(filteredSuggestions) - autocompleteMaxLines, 0, autocompleteScrollPosition);
			}
			if (mouse_wheel_up()) {
				autocompleteScrollPosition--;
				autocompleteScrollPosition = max(autocompleteScrollPosition, 0);
			}
		} else if (point_in_rectangle(mouse_x, mouse_y, shellOriginX, shellOriginY, shellOriginX + width, shellOriginY + height)) {
			if (mouse_wheel_down()) {
				scrollPosition += scrollSpeed;
			}
			if (mouse_wheel_up()) {
				scrollPosition -= scrollSpeed;
			}
		}
	} else {
		if (point_in_rectangle(mouse_x, mouse_y, shellOriginX, shellOriginY, shellOriginX + width, shellOriginY + height)) {
			if (mouse_wheel_down()) {
				scrollPosition += scrollSpeed;
			}
			if (mouse_wheel_up()) {
				scrollPosition -= scrollSpeed;
			}
		}
	}
	scrollPosition = clamp(scrollPosition, 0, maxScrollPosition);
	
	if (consoleString != prevConsoleString) {
		// If the text at the prompt has changed, update the list of possible
		// autocomplete suggestions
		self.updateFilteredSuggestions();
		autocompleteScrollPosition = 0;
	}
}
