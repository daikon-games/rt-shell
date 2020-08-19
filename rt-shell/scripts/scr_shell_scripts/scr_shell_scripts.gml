// Shell scripts can be defined here
// Method names must start with sh_, but will not include that when being invoked
// For example, to invoke sh_test_method from an rt-shell, you would simply type test_method
// 
// If a method returns a string value, it will be print to the shell output

function sh_get_bgspeed() {
	var bgHspeed = obj_test_room.bgHspeed;
	var bgVspeed = obj_test_room.bgVspeed;
	return "hspeed: " + string(bgHspeed) + ", vspeed: " + string(bgVspeed);
}

function sh_set_bg_hspeed(args) {
	var newHspeed = args[1];
	try {
		obj_test_room.bgHspeed = real(newHspeed);
	} catch (e) {
		return e.message;
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

function sh_test_duplicate_spawn() {
	instance_create_layer(0, 0, "Instances", obj_shell);
}

function sh_set_shell_width(args) {
	obj_shell.width = args[1];
}

function sh_set_shell_height(args) {
	obj_shell.height = args[1];
}

function sh_say_greeting(args) {
	var whomToGreet = args[1];
	return "Hello " + whomToGreet + "!";
}

function sh_set_bg_color(args) {
	var red = args[1];
	var green = args[2];
	var blue = args[3];
	
	var backgroundId = layer_background_get_id(layer_get_id("Background"));
	layer_background_blend(backgroundId, make_color_rgb(red, green, blue));
}