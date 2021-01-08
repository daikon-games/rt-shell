/// @description Init Native Scripts

/// @desc Clears the console
variable_global_set("sh_clear", function() {
	array_resize(output, 0);
});

/// @desc closes the console
variable_global_set("sh_close", function() {
	close();
});

/// @desc updates the console's width
variable_global_set("sh_shell_set_width", function(args) {
	width = args[1];
});

/// @desc updates the console's height
variable_global_set("sh_shell_set_height", function(args) {
	height = args[1];
});

/// @desc updates the vertical anchor point
variable_global_set("sh_shell_set_anchor_v", function(args) {
	var newAnchor = args[1];
	if (newAnchor == "top" || newAnchor == "middle" || newAnchor == "bottom") {
		screenAnchorPointV = newAnchor;
		recalculate_origin();
	} else {
		return "Invalid anchor point.\nPossible values: [top, middle, bottom]";
	}
});

/// @desc updates the horizontal anchor point
variable_global_set("sh_shell_set_anchor_h", function(args) {
	var newAnchor = args[1];
	if (newAnchor == "left" || newAnchor == "center" || newAnchor == "right") {
		screenAnchorPointH = newAnchor;
		recalculate_origin();
	} else {
		return "Invalid anchor point.\nPossible values: [left, center, right]";
	}
});

/// THEMES
variable_global_set("sh_shell_theme_rtshell_dark", function(args) {
	consoleAlpha = 0.9;
	consoleColor = c_black;
	fontColor = make_color_rgb(255, 242, 245);
	fontColorSecondary = make_color_rgb(140, 118, 123);
	autocompleteBackgroundColor = consoleColor;
	cornerRadius = 12;
	anchorMargin = 4;
	promptColor = make_color_rgb(237, 0, 54);
	prompt = "$";
	recalculate_origin();
});

variable_global_set("sh_shell_theme_rtshell_light", function() {
	consoleAlpha = 0.9;
	consoleColor = make_color_rgb(235, 235, 235);
	fontColor = make_color_rgb(40, 40, 45);
	fontColorSecondary = make_color_rgb(120, 120, 128);
	autocompleteBackgroundColor = consoleColor;
	cornerRadius = 12;
	anchorMargin = 4;
	promptColor = make_color_rgb(29, 29, 196);
	prompt = "$";
	recalculate_origin();
});

variable_global_set("sh_shell_theme_ocean_blue", function() {
	consoleAlpha = 1;
	consoleColor = make_color_rgb(29, 31, 33);
	fontColor = make_color_rgb(197, 200, 198);
	fontColorSecondary = make_color_rgb(116, 127, 140);
	autocompleteBackgroundColor = merge_color(consoleColor, c_black, 0.5);
	cornerRadius = 0;
	anchorMargin = 0;
	promptColor = make_color_rgb(57, 113, 237);
	prompt = "%";
	recalculate_origin();
});

variable_global_set("sh_shell_theme_dracula", function() {
	consoleAlpha = 1;
	consoleColor = make_color_rgb(40, 42, 54);
	fontColor = make_color_rgb(248, 248, 242);
	fontColorSecondary = make_color_rgb(98, 114, 164);
	autocompleteBackgroundColor = make_color_rgb(25, 26, 33);
	cornerRadius = 8;
	anchorMargin = 4;
	promptColor = make_color_rgb(80, 250, 123);
	prompt = "->";
	recalculate_origin();
});

variable_global_set("sh_shell_theme_solarized_light", function() {
	consoleAlpha = 1;
	consoleColor = make_color_rgb(253, 246, 227);
	fontColor = make_color_rgb(101, 123, 131);
	fontColorSecondary = make_color_rgb(147, 161, 161);
	autocompleteBackgroundColor = make_color_rgb(238, 232, 213);
	cornerRadius = 2;
	anchorMargin = 4;
	promptColor = make_color_rgb(42, 161, 152);
	prompt = "~";
	recalculate_origin();
});

variable_global_set("sh_shell_theme_solarized_dark", function() {
	consoleAlpha = 1;
	consoleColor = make_color_rgb(0, 43, 54);
	fontColor = make_color_rgb(131, 148, 150);
	fontColorSecondary = make_color_rgb(88, 110, 117);
	autocompleteBackgroundColor = make_color_rgb(0, 33, 43);
	cornerRadius = 2;
	anchorMargin = 4;
	promptColor = make_color_rgb(42, 161, 152);
	prompt = "~";
	recalculate_origin();
});