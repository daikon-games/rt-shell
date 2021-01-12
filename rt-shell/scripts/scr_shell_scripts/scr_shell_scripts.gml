// Shell scripts can be defined here
// Method names must start with sh_, but will not include that when being invoked
// For example, to invoke sh_test_method from an rt-shell, you would simply type test_method
// 
// If a method returns a string value, it will be print to the shell output

// Just for example
function sh_create_balloon (args) {
	//var balloon = instance_create_layer(args[1], args[2], "balloon_layer", obj_balloon);
	//balloon.type = args[3];
	//balloon.color = args[4];
}

// meta_* functions must follow this return output
// "arguments" is for showing the arguments in your input string
// "suggestions" is for showing you autocomplete suggestions for each argument
// The index of "suggestions" corresponds to the argument number
function meta_create_balloon() {
	return {
		arguments: ["x", "y", "type", "color"],
		suggestions: [
			[],
			[],
			["normal", "animal_dog", "animal_snake"],
			["pink", "blue", "brown", "green"]
		]
	}
}

function sh_get_bgspeed() {
	var bgHspeed = obj_test_room.bgHspeed;
	var bgVspeed = obj_test_room.bgVspeed;
	return "hspeed: " + string(bgHspeed) + ", vspeed: " + string(bgVspeed);
}
function meta_get_bgspeed() {
	return {
		description: "gets the speed of the background image"
	}
}

// If you want a method to take arguments at the command line, pass in an args object here
// args[0] will always be the function name, args[1] and onwards will be your actual arguments
function sh_set_bg_hspeed(args) {
	var newHspeed = args[1];
	try {
		obj_test_room.bgHspeed = real(newHspeed);
	} catch (e) {
		return e.message;
	}
}
function meta_set_bg_hspeed() {
	return {
		description: "set the horizontal speed of the background",
		arguments: ["speed"],
		argumentDescriptions: [
			"The desired horizontal speed."
		]
	}
}

function sh_set_bg_vspeed(args) {
	var newVspeed = args[1];
	try {
		obj_test_room.bgVspeed = real(newVspeed);
	} catch (e) {
		return e.message;
	}
}
function meta_set_bg_vspeed() {
	return {
		description: "set the vertical speed of the background",
		arguments: ["speed"],
		argumentDescriptions: [
			"The desired vertical speed."
		]
	}
}

// Here is an example of a shell script that takes multiple command line arguments
// See how I've assigned args[1], args[2], and args[3] into local variables for easier use
function sh_set_bg_color(args) {
	var red = args[1];
	var green = args[2];
	var blue = args[3];
	
	var backgroundId = layer_background_get_id(layer_get_id("Background"));
	layer_background_blend(backgroundId, make_color_rgb(red, green, blue));
}

function meta_set_bg_color() {
	return {
		description: "set the color of the background",
		arguments: ["red", "green", "blue"],
		argumentDescriptions: [
			"red value from 0 to 255",
			"green value from 0 to 255",
			"blue value from 0 to 255"
		]
	}
}

function sh_say_greeting(args) {
	var whomToGreet = args[1];
	return "Hello " + whomToGreet + "!";
}
function meta_say_greeting() {
	return {
		description: "print a hello world type statement",
		arguments: ["whomToGreet"],
		argumentDescriptions: [
			"a name of an entity to be greeted"
		]
	}
}

function sh_test_duplicate_spawn() {
	instance_create_layer(0, 0, "Instances", obj_shell);
}

function sh_test_error_handling() {
	return undefined.property;
}

function sh_theme_rtshell_dark() {
	obj_shell.consoleAlpha = 0.9;
	obj_shell.consoleColor = c_black;
	obj_shell.fontColor = make_color_rgb(255, 242, 245);
	obj_shell.fontColorSecondary = make_color_rgb(140, 118, 123);
	obj_shell.cornerRadius = 12;
	obj_shell.anchorMargin = 4;
	obj_shell.consolePaddingH = 6;
	obj_shell.consolePaddingV = 4;
	obj_shell.autocompletePadding = 2;
	obj_shell.promptColor = make_color_rgb(237, 0, 54);
	obj_shell.prompt = "$";
}

function sh_theme_rtshell_light() {
	obj_shell.consoleAlpha = 0.9;
	obj_shell.consoleColor = make_color_rgb(235, 235, 235);
	obj_shell.fontColor = make_color_rgb(40, 40, 45);
	obj_shell.fontColorSecondary = make_color_rgb(120, 120, 128);
	obj_shell.cornerRadius = 12;
	obj_shell.anchorMargin = 4;
	obj_shell.consolePaddingH = 6;
	obj_shell.consolePaddingV = 4;
	obj_shell.autocompletePadding = 2;
	obj_shell.promptColor = make_color_rgb(29, 29, 196);
	obj_shell.prompt = "$";
}

function sh_theme_ocean_blue() {
	obj_shell.consoleAlpha = 1;
	obj_shell.consoleColor = make_color_rgb(29, 31, 33);
	obj_shell.fontColor = make_color_rgb(197, 200, 198);
	obj_shell.fontColorSecondary = make_color_rgb(116, 127, 140);
	obj_shell.cornerRadius = 0;
	obj_shell.anchorMargin = 0;
	obj_shell.consolePaddingH = 2;
	obj_shell.consolePaddingV = 2;
	obj_shell.autocompletePadding = 2;
	obj_shell.promptColor = make_color_rgb(57, 113, 237);
	obj_shell.prompt = "%";
}

function sh_theme_dracula() {
	obj_shell.consoleAlpha = 1;
	obj_shell.consoleColor = make_color_rgb(40, 42, 54);
	obj_shell.fontColor = make_color_rgb(248, 248, 242);
	obj_shell.fontColorSecondary = make_color_rgb(98, 114, 164);
	obj_shell.cornerRadius = 8;
	obj_shell.anchorMargin = 4;
	obj_shell.consolePaddingH = 6;
	obj_shell.consolePaddingV = 2;
	obj_shell.autocompletePadding = 0;
	obj_shell.promptColor = make_color_rgb(80, 250, 123);
	obj_shell.prompt = "->";
}

function sh_theme_solarized_light() {
	obj_shell.consoleAlpha = 1;
	obj_shell.consoleColor = make_color_rgb(253, 246, 227);
	obj_shell.fontColor = make_color_rgb(101, 123, 131);
	obj_shell.fontColorSecondary = make_color_rgb(147, 161, 161);
	obj_shell.cornerRadius = 2;
	obj_shell.anchorMargin = 4;
	obj_shell.consolePaddingH = 2;
	obj_shell.consolePaddingV = 2;
	obj_shell.autocompletePadding = 0;
	obj_shell.promptColor = make_color_rgb(42, 161, 152);
	obj_shell.prompt = "~";
}

function sh_theme_solarized_dark() {
	obj_shell.consoleAlpha = 1;
	obj_shell.consoleColor = make_color_rgb(0, 43, 54);
	obj_shell.fontColor = make_color_rgb(131, 148, 150);
	obj_shell.fontColorSecondary = make_color_rgb(88, 110, 117);
	obj_shell.cornerRadius = 2;
	obj_shell.anchorMargin = 4;
	obj_shell.consolePaddingH = 2;
	obj_shell.consolePaddingV = 2;
	obj_shell.autocompletePadding = 0;
	obj_shell.promptColor = make_color_rgb(42, 161, 152);
	obj_shell.prompt = "~";
}