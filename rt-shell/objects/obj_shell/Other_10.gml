/// @description Init Native Scripts

/// @desc Clears the console
variable_global_set("sh_clear", function(args) {
	if (array_length(args) > 1 and args[1] == "all") {
		array_resize(output, 0);
		return "";
	} else {
		array_push(output, ">" + consoleString);
		var _newLinesCount = floor(height / string_height(prompt)) - 1;
		repeat(_newLinesCount) {
			array_push(output, "\n");
		}
		return "";
	}
});

/// @desc closes the console
variable_global_set("sh_close", function() {
	close();
	return "";
});

/// @desc updates the console's width
variable_global_set("sh_shell_set_width", function(args) {
	if (array_length(args) > 1) {
		if (string_digits(args[1]) != "") {
			width = real(string_digits(args[1]));
			recalculate_shell_properties();
		} else {
			return "Invalid argument: " + args[1];
		}
	} else {
		return "No argument provided.";
	}
});

/// @desc updates the console's height
variable_global_set("sh_shell_set_height", function(args) {
	if (array_length(args) > 1) {
		if (string_digits(args[1]) != "") {
			height = real(string_digits(args[1]));
			recalculate_shell_properties();
		} else {
			return "Invalid argument: " + args[1];
		}
	} else {
		return "No argument provided.";
	}
});

/// @desc updates the vertical anchor point
variable_global_set("sh_shell_set_anchor_v", function(args) {
	if (array_length(args) > 1) {
		var newAnchor = args[1];
		if (newAnchor == "top" || newAnchor == "middle" || newAnchor == "bottom") {
			screenAnchorPointV = newAnchor;
			recalculate_shell_properties();
		} else {
			return "Invalid anchor point.\nPossible values: [top, middle, bottom]";
		}
	} else {
		return "No argument provided.";
	}
});

/// @desc updates the horizontal anchor point
variable_global_set("sh_shell_set_anchor_h", function(args) {
	if (array_length(args) > 1) {
		var newAnchor = args[1];
		if (newAnchor == "left" || newAnchor == "center" || newAnchor == "right") {
			screenAnchorPointH = newAnchor;
			recalculate_shell_properties();
		} else {
			return "Invalid anchor point.\nPossible values: [left, center, right]";
		}
	} else {
		return "No argument provided.";
	}
});