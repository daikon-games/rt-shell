if (!isOpen) {
	if (self.keyComboPressed(openModifiers, openKey)) {
		self.open();
	}
} else {
	
	var prevConsoleString = consoleString;
	
	if (metaDeleted && keyboard_check_released(vk_backspace)) {
		metaDeleted = false;
	}
	if (metaMovedLeft && keyboard_check_released(vk_left)) {
		metaMovedLeft = false;
	}
	if (metaMovedRight && keyboard_check_released(vk_right)) {
		metaMovedRight = false;
	}
	
	if (keyboard_check_pressed(vk_escape)) {
		if (isAutocompleteOpen) {
			self.close_autocomplete();
		} else {
			self.close()
		}
	} else if (self.keyComboPressed([metaKey], ord("A"))) {
		// bash-style jump to beginning of line
		cursorPos = 1;
		targetScrollPosition = maxScrollPosition;
	} else if (self.keyComboPressed([metaKey], ord("E"))) {
		// bash-style jump to end of line
		cursorPos = string_length(consoleString) + 1;
		targetScrollPosition = maxScrollPosition;
	} else if (self.keyComboPressed([metaKey], ord("K"))) {
		// bash-style "kill" (aka delete all characters following cursor)
		var leftSide = string_copy(consoleString, 0, cursorPos - 1);
		var rightSide = string_copy(consoleString, cursorPos, string_length(consoleString) - cursorPos + 1);
		killedString = rightSide;
		consoleString = leftSide;
		cursorPos = string_length(consoleString) + 1;
		targetScrollPosition = maxScrollPosition;
	} else if (self.keyComboPressed([metaKey], ord("Y"))) {
		// bash-style "yank" (aka append the "killed" string at the prompt)
		consoleString += killedString;
		killedString = "";
		cursorPos = string_length(consoleString) + 1;
		targetScrollPosition = maxScrollPosition;
	} else if (self.keyComboPressed([metaKey], ord("C"))) {
		// GNU-style "sigint" (aka abort the current message)
		array_push(output, ">" + consoleString + "^C");
		consoleString = "";
		cursorPos = 1;
		targetScrollPosition = maxScrollPosition;
	} else if (self.keyComboPressed([metaKey], vk_backspace) || (metaKey == vk_control && ord(keyboard_string) == 127)) {
		// delete characters from the cursor position to the preceding space or start of the line
		var precedingSpaceIndex = 1;
		// don't want to check for space at or before the cursor position, so start 2 back
		for (var i = cursorPos - 2; i > 1; i--) {
			if (string_char_at(consoleString, i) == " ") {
				precedingSpaceIndex = i;
				break;
			}
		}
		consoleString = string_delete(consoleString, precedingSpaceIndex, cursorPos - precedingSpaceIndex);
		cursorPos = precedingSpaceIndex;
		targetScrollPosition = maxScrollPosition;
		keyboard_string = "";
		metaDeleted = true;
	} else if (self.keyComboPressed([metaKey], vk_left)) {
		// jump left to the preceding word
		var precedingSpaceIndex = 1;
		// don't want to check for space at or before the cursor position, so start 2 back
		for (var i = cursorPos - 2; i > 1; i--) {
			if (string_char_at(consoleString, i) == " ") {
				precedingSpaceIndex = i;
				break;
			}
		}
		cursorPos = precedingSpaceIndex;
		targetScrollPosition = maxScrollPosition;
		metaMovedLeft = true;
	} else if (self.keyComboPressed([metaKey], vk_right)) {
		var nextSpaceIndex = string_length(consoleString) + 1;
		// jump right to the following word
		for (var i = cursorPos + 2; i <= string_length(consoleString) + 1; i++) {
			if (string_char_at(consoleString, i) == " ") {
				nextSpaceIndex = i;
				break;
			}
		}
		cursorPos = nextSpaceIndex;
		targetScrollPosition = maxScrollPosition;
		metaMovedRight = true;
	} else if (self.keyboardCheckDelay(vk_backspace)) {
		if (!metaDeleted) {
			consoleString = string_delete(consoleString, cursorPos - 1, 1);
			cursorPos = max(1, cursorPos - 1);
			targetScrollPosition = maxScrollPosition;
		}
	} else if (self.keyboardCheckDelay(vk_delete)) {
		consoleString = string_delete(consoleString, cursorPos, 1);
		targetScrollPosition = maxScrollPosition;
	} else if (self.keyboardCheckDelay(vk_left)) { 
		if (!metaMovedLeft) {
			cursorPos = max(1, cursorPos - 1);
			targetScrollPosition = maxScrollPosition;
		}
	} else if (self.keyboardCheckDelay(vk_right)) {
		if (!metaMovedRight) {
			if (cursorPos == string_length(consoleString) + 1 &&
				array_length(filteredSuggestions) != 0) {
				var suggestion = filteredSuggestions[suggestionIndex];
				var consoleWords = _string_split(consoleString, " ").arguments;
				// Do something with params here
				var currentWordLength = string_length(consoleWords[array_length(consoleWords) - 1]);
				consoleString += string_copy(suggestion, currentWordLength + 1, string_length(suggestion) - currentWordLength);
				cursorPos = string_length(consoleString) + 1;
			} else {
				cursorPos = min(string_length(consoleString) + 1, cursorPos + 1);
			}
			targetScrollPosition = maxScrollPosition;
		}
	} else if (self.keyComboPressed(historyUpModifiers, historyUpKey)) {
		if (historyPos == array_length(history)) {
			savedConsoleString = consoleString;
		}
		historyPos = max(0, historyPos - 1);
		if (array_length(history) != 0) {
			consoleString = array_get(history, historyPos);
			cursorPos = string_length(consoleString) + 1;
		}
		targetScrollPosition = maxScrollPosition;
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
		targetScrollPosition = maxScrollPosition;
	} else if (keyboard_check_pressed(vk_enter)) {
		if (isAutocompleteOpen) {
			self.confirmCurrentSuggestion();
		} else {
			var args_params = self._string_split(consoleString, " ");
			var args = args_params.arguments;
			var params = args_params.parameters;
			
			log(args);
			log(params);
			
			if (array_length(args) > 0) {
				var script = variable_global_get("sh_" + args[0]);
				if (script != undefined) {
					var response;
					try {
						response = script_execute(asset_get_index(script_get_name(script)), args);
					} catch (_exception) {
						response = "-- ERROR: see debug output for details --";
						show_debug_message("---- ERROR executing rt-shell command [" + args[0] + "] ----");
						show_debug_message(_exception.message);
						show_debug_message(_exception.longMessage);
						show_debug_message(_exception.script);
						show_debug_message(_exception.stacktrace);
						show_debug_message("----------------------------");
					}
					array_push(history, consoleString);
					if (response != "") { array_push(output, ">" + consoleString); }
					if (response != 0) {
						array_push(output, response);
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
	} else if (keyboard_check_pressed(vk_insert)) {
		insertMode = !insertMode;
	} else if (keyboard_string != "") {
		var t = keyboard_string;
		if (!insertMode) { consoleString = string_delete(consoleString, cursorPos, string_length(t)); }
		consoleString = string_insert(t, consoleString, cursorPos);
		cursorPos += string_length(t);
		keyboard_string = "";
		targetScrollPosition = maxScrollPosition;
	}
	
	// Handle scrolling
	if (isAutocompleteOpen) {
		var x1 = autocompleteOriginX;
		var y1 = autocompleteOriginY;
		var x2 = x1 + autocompleteMaxWidth + font_get_size(consoleFont) + (autocompletePadding * 2) - scrollbarWidth;
		var y2 = y1 + (string_height(prompt) * min(array_length(filteredSuggestions), autocompleteMaxLines)) + autocompletePadding;
		if (point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), x1, y1, x2, y2)) {
			if (mouse_wheel_down()) {
				autocompleteScrollPosition++;
				autocompleteScrollPosition = clamp(array_length(filteredSuggestions) - autocompleteMaxLines, 0, autocompleteScrollPosition);
			}
			if (mouse_wheel_up()) {
				autocompleteScrollPosition--;
				autocompleteScrollPosition = max(autocompleteScrollPosition, 0);
			}
		} else if (point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), shellOriginX, shellOriginY, shellOriginX + width, shellOriginY + height)) {
			if (mouse_wheel_down()) {
				targetScrollPosition = targetScrollPosition + scrollSpeed;
			}
			if (mouse_wheel_up()) {
				targetScrollPosition = targetScrollPosition - scrollSpeed;
			}
		}
	} else {
		if (point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), shellOriginX, shellOriginY, shellOriginX + width, shellOriginY + height)) {
			if (mouse_wheel_down()) {
				targetScrollPosition = targetScrollPosition + scrollSpeed;
			}
			if (mouse_wheel_up()) {
				targetScrollPosition = targetScrollPosition - scrollSpeed;
			}
		}
	}
	
	// Updating scrolling
	var lerpValue = (scrollSmoothness == 0) ? 1 : remap(scrollSmoothness, 1, 0, 0.08, 0.4);
	scrollPosition = lerp(scrollPosition, targetScrollPosition, lerpValue);
	scrollPosition = clamp(scrollPosition, 0, maxScrollPosition)
	if (scrollPosition == 0 || scrollPosition == maxScrollPosition) {
		targetScrollPosition = clamp(targetScrollPosition, 0, maxScrollPosition);
	}
	
	if (consoleString != prevConsoleString) {
		// If the text at the prompt has changed, update the list of possible
		// autocomplete suggestions
		self.updateFilteredSuggestions();
		autocompleteScrollPosition = 0;
	}
	
	// Recalculate shell properties if certain variables have changed
	if (shell_properties_hash() != shellPropertiesHash) {
		recalculate_shell_properties();
	}
}