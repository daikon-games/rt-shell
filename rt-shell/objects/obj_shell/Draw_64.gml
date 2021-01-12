if (isOpen) {
	draw_set_font(consoleFont);
	// pre-calculate one "em" of height
	var lineHeight = string_height("M");
	
	if (!surface_exists(shellSurface)) {
		shellSurface = surface_create(display_get_gui_width(), display_get_gui_height());
		recalculate_shell_properties();
	} else if (surface_get_width(shellSurface) != display_get_gui_width() || surface_get_height(shellSurface) != display_get_gui_height()) {
		surface_resize(shellSurface, display_get_gui_width(), display_get_gui_height());
	}
	var outputHeight = 0;
	for (var i = 0; i < array_length(output); i++) {
		outputHeight += string_height_ext(output[i], -1, visibleWidth);
	}
	var scrollSurfaceHeight = max(outputHeight + lineHeight, visibleHeight);
	if (!surface_exists(scrollSurface)) {
		scrollSurface = surface_create(display_get_gui_width(), scrollSurfaceHeight);
	} else {
		surface_resize(scrollSurface, display_get_gui_width(), scrollSurfaceHeight);
	}
	
	var promptXOffset = consolePadding + string_width(prompt) + anchorMargin;
	
	surface_set_target(scrollSurface);
		draw_clear_alpha(c_black, 0.0);
		var yOffset = 0;
		
		// Add some blank space if our output is too short so things appear to come from 
		// the bottom of the panel
		if (outputHeight < visibleHeight - lineHeight) {
			yOffset += visibleHeight - outputHeight - lineHeight;
		}
		
		// Draw output history
		for (var i = 0; i < array_length(output); i++) {
			var outputStr = output[i];
			if (string_char_at(outputStr, 1) == ">") {
				draw_set_color(fontColorSecondary);
				draw_text(shellOriginX + consolePadding, yOffset, prompt);
				draw_text_ext(shellOriginX + promptXOffset, yOffset, string_delete(outputStr, 1, 1), -1, visibleWidth - promptXOffset);
			} else {
				draw_set_color(fontColor);
				draw_text_ext(shellOriginX + promptXOffset, yOffset, outputStr, -1, visibleWidth - promptXOffset);
			}
			yOffset += string_height_ext(outputStr, -1, visibleWidth - promptXOffset);
		}
		
		// Draw our command prompt
		draw_set_color(promptColor);
		draw_text(shellOriginX + consolePadding, yOffset, prompt);
	
		// Draw whatever text has been entered so far
		draw_set_color(fontColor);
		draw_text(shellOriginX + promptXOffset, yOffset, consoleString);
		
		// Draw a flashing text prompt
		if (delayFrames > 1 || current_time % 1000 < 600) {
			draw_text(shellOriginX + promptXOffset + string_width(string_copy(consoleString + " ", 1, cursorPos - 1)) - 3, yOffset, "|");
		} else if (keyboard_check(vk_anykey)) {
			draw_text(shellOriginX + promptXOffset + string_width(string_copy(consoleString + " ", 1, cursorPos - 1)) - 3, yOffset, "|");
		}
		
		// Draw current suggestion & argument hints
		if (array_length(inputArray) > 0) {
			var ff = (array_length(filteredSuggestions) > 0 and string_count(" ", consoleString) == 0) ? filteredSuggestions[suggestionIndex] : inputArray[0];
			var data = functionData[$ ff];
			var spaceCount = string_count(" ", consoleString);
			
			var suggestion = spaceCount == 0 ? ff : "";
			if (data != undefined) {
				var args = "";
				if (array_length(filteredSuggestions) > 0 and spaceCount > 0) {
					if (array_length(inputArray) > spaceCount) {
						args += string_copy(filteredSuggestions[suggestionIndex], string_length(inputArray[array_length(inputArray) - 1]) + 1, string_length(filteredSuggestions[suggestionIndex]));
					} else {
						args += filteredSuggestions[suggestionIndex];
					}
				}
				for (var i = spaceCount; i < array_length(data[$ "arguments"]); i++) {
					args += " ";
					args += data.arguments[i];
					
				}
				suggestion += args;
				if (spaceCount == 0) {
					suggestion = string_copy(suggestion, string_length(consoleString) + 1, string_length(suggestion) - string_length(consoleString));
				}
			} else {
				suggestion = string_copy(ff, string_length(consoleString) + 1, string_length(ff) - string_length(consoleString));
			}

			draw_set_color(fontColorSecondary);
			draw_text(shellOriginX + promptXOffset + string_width(consoleString), yOffset, suggestion);
		}		
	surface_reset_target();
	
	surface_set_target(shellSurface);
		// Draw shell background
		draw_clear_alpha(c_black, 0.0);
		draw_set_alpha(consoleAlpha);
		draw_set_color(consoleColor);
		draw_roundrect_ext(shellOriginX, shellOriginY, shellOriginX + width, shellOriginY + height, cornerRadius, cornerRadius, false);
		
		// Draw the scroll surface
		draw_surface_part(scrollSurface, 0, scrollPosition, display_get_gui_width(), visibleHeight, 0, shellOriginY + consolePadding);
		
		// Draw scrollbar
		if (surface_get_height(scrollSurface) > height - (2 * consolePadding)) {
			var x1 = shellOriginX + width - anchorMargin - scrollbarWidth;
			var y1 = shellOriginY + anchorMargin;
			var x2 = x1 + scrollbarWidth;
			var y2 = shellOriginY + height - anchorMargin;
			
			draw_set_color(fontColorSecondary);
			draw_rectangle(x1, y1, x2, y2, false);
			
			var scrollbarHeight = 2 + (visibleHeight/surface_get_height(scrollSurface)) * visibleHeight;
			var scrollbarProgress = 0;
			if (surface_get_height(scrollSurface) > visibleHeight) {
				scrollbarProgress = scrollPosition / (surface_get_height(scrollSurface) - visibleHeight);
			}
			var scrollbarPosition = (visibleHeight - scrollbarHeight) * scrollbarProgress;
			
			y1 = y1 + scrollbarPosition;
			y2 = y1 + scrollbarHeight;
			
			draw_set_color(fontColor);
			draw_rectangle(x1, y1, x2, y2, false);
		}
		
		// Draw autocomplete box
		if (array_length(filteredSuggestions) > 0) {
			if (enableAutocomplete and autocompleteMaxLines > 0) {
				isAutocompleteOpen = true;
				var suggestionsAmount = min(autocompleteMaxLines, array_length(filteredSuggestions));
				
				var suggestionOffsetX = string_width(string_copy(consoleString, 1, string_last_pos(" ", consoleString)));
				var x1 = shellOriginX + promptXOffset - consolePadding + suggestionOffsetX;
				var y1 = (screenAnchorPointV == "bottom") ? shellOriginY + height - (lineHeight * 1.5) - (suggestionsAmount * lineHeight) : shellOriginY + height;
				var x2 = x1 + autocompleteMaxWidth + font_get_size(consoleFont);
				var y2 = (screenAnchorPointV == "bottom") ? shellOriginY + height - (lineHeight * 1.5) : y1 + (suggestionsAmount * lineHeight);
				
				autocompleteOriginX = x1;
				autocompleteOriginY = y1;
				
				// Draw autocomplete background & outline
				draw_set_color(autocompleteBackgroundColor);
				draw_rectangle(x1, y1, x2, y2, false);
				draw_set_color(fontColorSecondary);
				draw_rectangle(x1, y1, x2, y2, true);
				
				// Draw autocomplete scrollbar
				if (suggestionsAmount < array_length(filteredSuggestions)) {
					draw_rectangle(x2 - (scrollbarWidth / 2), y1, x2, y2, false);
					var scrollbarTotalHeight = y2 - y1;
					var scrollbarHeight = (suggestionsAmount / array_length(filteredSuggestions)) * scrollbarTotalHeight;
					var scrollbarProgress = (array_length(filteredSuggestions) - autocompleteScrollPosition) / array_length(filteredSuggestions);
					var yScroll1 = y1 + (scrollbarTotalHeight * (1 - scrollbarProgress)) + 1;
					var yScroll2 = yScroll1 + scrollbarHeight - 1;
				
					draw_set_color(fontColor);
					draw_rectangle(x2 - (scrollbarWidth / 2), yScroll1, x2 + 1, yScroll2, false);
				}
				
				// Draw autocomplete suggestions
				draw_set_color(fontColor);
				for (var i = 0; i < array_length(filteredSuggestions); i++) {
					if (i < suggestionsAmount) {
						// Enable mouse detection
						if (point_in_rectangle(device_mouse_x_to_gui(0) - 1, device_mouse_y_to_gui(0) - 1, x1, y1 + (i * lineHeight), x2, y1 + (i * lineHeight) + lineHeight - 1)) {
							if (device_mouse_x_to_gui(0) != mousePreviousX or device_mouse_y_to_gui(0) != mousePreviousY) {
								suggestionIndex = i + autocompleteScrollPosition;
								mousePreviousX = device_mouse_x_to_gui(0);
								mousePreviousY = device_mouse_y_to_gui(0);
							}
							if (mouse_check_button_pressed(mb_left)) {
								if (suggestionIndex == i + autocompleteScrollPosition) {
									//consoleString = filteredSuggestions[suggestionIndex];
									//cursorPos = string_length(consoleString) + 1;
									self.confirmCurrentSuggestion();
									self.updateFilteredSuggestions();
									break;
								} else {
									suggestionIndex = i + autocompleteScrollPosition;
								}
							}
						}
						
						if ((i + autocompleteScrollPosition) == suggestionIndex) {
							draw_set_color(promptColor);
						} else {
							draw_set_color(fontColorSecondary);
						}
						
						draw_text(x1 + consolePadding, y1 + (i * lineHeight), filteredSuggestions[i + autocompleteScrollPosition]);
					}
				}
			}
		} else {
			isAutocompleteOpen = false;
			autocompleteScrollPosition = 0;
		}
		
		draw_set_color(c_white);
		draw_set_alpha(1);
	surface_reset_target();
	
	draw_surface(shellSurface, 0, 0);
}