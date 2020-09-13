surface_set_target(shellSurface);
	draw_clear_alpha(c_black, 0.0);
	draw_set_color(consoleColor);
	draw_set_alpha(consoleAlpha);
	draw_roundrect_ext(0, 0, width, height, cornerRadius, cornerRadius, false);
	
	draw_set_font(consoleFont);
	var lineHeight = string_height(prompt);
	
	// Draw our command prompt
	draw_set_color(promptColor);
	draw_text(6, height - lineHeight, prompt);
	
	// Draw whatever text has been entered so far
	draw_set_color(fontColor);
	draw_text(10 + string_width(prompt), height - lineHeight, consoleString);
	
	// Draw a flashing text prompt
	if (delayFrames > 1 || current_time % 1000 < 600) {
		draw_text(10 + string_width(prompt) + string_width(string_copy(consoleString + " ", 1, cursorPos - 1)) - 3, height - lineHeight, "|");
	}
	
	// Draw an autocomplete suggestion
	if (ds_list_size(filteredFunctions) != 0) {
		draw_set_color(fontColorSecondary);
		var ff = filteredFunctions[| suggestionIndex];
		var suggestion = string_copy(ff, string_length(consoleString) + 1, string_length(ff) - string_length(consoleString));
		draw_text(10 + string_width(prompt) + string_width(consoleString), height - lineHeight, suggestion);
	}
	
	// Draw some lines of previous output
	var outputSize = ds_list_size(output);
	for (var i = outputSize; i > 0; i--) {
		var outputStr = ds_list_find_value(output, i - 1);
		var xOffset = string_width(prompt);
		var yOffset = height - (outputSize - i + 2) * lineHeight;
		if (string_char_at(outputStr, 1) == ">") {
			draw_set_color(fontColorSecondary);
			draw_text(6, yOffset, prompt);
			draw_text(10 + xOffset, yOffset, string_delete(outputStr, 1, 1));
		} else {
			draw_set_color(fontColor);
			draw_text(10 + xOffset, yOffset, outputStr);
		}
	}
	draw_set_alpha(1);
surface_reset_target();

if (isOpen) {
	var yPos = 0;
	switch (screenAnchorPoint) {
	case "top": yPos = anchorMargin; break;
	case "bottom": yPos = (display_get_gui_height() - height - anchorMargin); break;
	}
	draw_surface(shellSurface, (display_get_gui_width() - width) / 2, yPos);
}