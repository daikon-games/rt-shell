if (isOpen) {
	if (!surface_exists(shellSurface)) {
		shellSurface = surface_create(display_get_gui_width(), display_get_gui_height());
		recalculate_origin();
		// Resize width if larger than gui
		if (width > display_get_gui_width()) { width = display_get_gui_width() - anchorMargin * 2; }
		if (height > display_get_gui_height()) { height = display_get_gui_height() - anchorMargin * 2; }
	} else if (surface_get_width(shellSurface) != display_get_gui_width() or surface_get_height(shellSurface) != display_get_gui_height()) {
		surface_resize(shellSurface, display_get_gui_width(), display_get_gui_height());
	}
	
	var lineHeight = string_height(prompt);
	var lineWidth = string_width(prompt);
	
	var textXOffset = 10 + anchorMargin;
	
	surface_set_target(shellSurface);
		// Draw shell background
		draw_clear_alpha(c_black, 0.0);
		draw_set_alpha(consoleAlpha);
		draw_set_color(consoleColor);
		draw_roundrect_ext(shellOriginX, shellOriginY, shellOriginX + width, shellOriginY + height, cornerRadius, cornerRadius, false);
	
		draw_set_font(consoleFont);
		
		// Draw our command prompt
		draw_set_color(promptColor);
		draw_text(shellOriginX + 6, shellOriginY + height - lineHeight, prompt);
	
		// Draw whatever text has been entered so far
		draw_set_color(fontColor);
		draw_text(shellOriginX + textXOffset + lineWidth, shellOriginY + height - lineHeight, consoleString);
	
		// Draw some lines of previous output
		var outputSize = min(array_length(output), (height - lineHeight) div lineHeight);
		var outputOffset = array_length(output) - outputSize;
		var xOffset = lineWidth;
		var yOffset = height - (1) * lineHeight;
		
		scrollPosition = clamp(scrollPosition, 0, array_length(output) - outputSize);
		for (var i = outputSize - scrollPosition; i > -scrollPosition; i--) {
			var outputStr = array_get(output, i + outputOffset - 1);
			var lineHeight = string_height(outputStr);
			yOffset -= lineHeight;
			if (string_char_at(outputStr, 1) == ">") {
				draw_set_color(fontColorSecondary);
				draw_text(shellOriginX + 6, shellOriginY + yOffset, prompt);
				draw_text(shellOriginX + textXOffset + xOffset, shellOriginY + yOffset, string_delete(outputStr, 1, 1));
			} else {
				draw_set_color(fontColor);
				draw_text(shellOriginX + textXOffset + xOffset, shellOriginY + yOffset, outputStr);
			}
		}
		
		// Draw scrollbar
		if (array_length(output) > outputSize) {
			var x1 = shellOriginX + width - anchorMargin - scrollbarWidth;
			var y1 = shellOriginY + anchorMargin;
			var x2 = x1 + scrollbarWidth;
			var y2 = shellOriginY + height - anchorMargin;
			
			draw_set_color(fontColorSecondary);
			draw_roundrect_ext(x1, y1, x2, y2, cornerRadius, cornerRadius, false);
			
			var scrollbarTotalHeight = y2 - y1;
			var scrollbarHeight = (outputSize / array_length(output)) * scrollbarTotalHeight;
			var scrollbarProgress = (array_length(output) - scrollPosition) / (array_length(output));
			
			y1 = y1 + ((scrollbarTotalHeight * scrollbarProgress) - scrollbarHeight);
			y2 = y1 + scrollbarHeight;
			
			draw_set_color(fontColor);
			draw_roundrect_ext(x1, y1, x2, y2, cornerRadius, cornerRadius, false);
		}
		
		// Draw autocomplete
		if (array_length(filteredFunctions) != 0 and consoleString != filteredFunctions[0]) {
			// Draw tab suggestion
			draw_set_color(fontColorSecondary);
			var ff = filteredFunctions[suggestionIndex];
			var suggestion = string_copy(ff, string_length(consoleString) + 1, string_length(ff) - string_length(consoleString));
			draw_text(shellOriginX + textXOffset + lineWidth + string_width(consoleString), shellOriginY + height - lineHeight, suggestion);
			
			if (enableAutocomplete and autocompleteMaxLines > 0) {
				isAutocompleteOpen = true;
				var suggestionsAmount = min(autocompleteMaxLines, array_length(filteredFunctions));
				
				var x1 = shellOriginX + textXOffset + (font_get_size(consoleFont) / 2);
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
				if (suggestionsAmount < array_length(filteredFunctions)) {
					draw_rectangle(x2 - (scrollbarWidth / 2), y1, x2, y2, false);
					var scrollbarTotalHeight = y2 - y1;
					var scrollbarHeight = (suggestionsAmount / array_length(filteredFunctions)) * scrollbarTotalHeight;
					var scrollbarProgress = (array_length(filteredFunctions) - autocompleteScrollPosition) / array_length(filteredFunctions);
					var yScroll1 = y1 + (scrollbarTotalHeight * (1 - scrollbarProgress)) + 1;
					var yScroll2 = yScroll1 + scrollbarHeight - 1;
				
					draw_set_color(fontColor);
					draw_rectangle(x2 - (scrollbarWidth / 2), yScroll1, x2 + 1, yScroll2, false);
				}
				
				// Draw autocomplete suggestions
				draw_set_color(fontColor);
				for (var i = 0; i < array_length(filteredFunctions); i++) {
					if (i < suggestionsAmount) {
						// Enable mouse detection
						if (point_in_rectangle(mouse_x - 1, mouse_y - 1, x1, y1 + (i * lineHeight), x2, y1 + (i * lineHeight) + lineHeight - 1)) {
							if (mouse_x != mousePreviousX or mouse_y != mousePreviousY) {
								suggestionIndex = i + autocompleteScrollPosition;
								mousePreviousX = mouse_x;
								mousePreviousY = mouse_y;
							}
							if (mouse_check_button_pressed(mb_left)) {
								if (suggestionIndex == i + autocompleteScrollPosition) {
									consoleString = filteredFunctions[suggestionIndex];
									cursorPos = string_length(consoleString) + 1;
									self.updateFilteredFunctions(consoleString);
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
						
						draw_text(x1 + (lineWidth / 2), y1 + (i * lineHeight), filteredFunctions[i + autocompleteScrollPosition]);
					}
				}
			}
		} else {
			isAutocompleteOpen = false;
			autocompleteScrollPosition = 0;
		}
		
		// Draw a flashing text prompt
		draw_set_color(fontColor);
		if (delayFrames > 1 || current_time % 1000 < 600) {
			draw_text(shellOriginX + textXOffset + lineWidth + string_width(string_copy(consoleString + " ", 1, cursorPos - 1)) - 3, shellOriginY + height - lineHeight, "|");
		} else if (keyboard_check(vk_anykey)) {
			draw_text(shellOriginX + textXOffset + lineWidth + string_width(string_copy(consoleString + " ", 1, cursorPos - 1)) - 3, shellOriginY + height - lineHeight, "|");
		}
		
		draw_set_color(c_white);
		draw_set_alpha(1);
	surface_reset_target();
	
	draw_surface(shellSurface, 0, 0);
}