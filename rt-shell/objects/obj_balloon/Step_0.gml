vspeed -= 0.05;

x = lerp(x, xTarget, 0.01);

if (bbox_bottom < 0) {
	instance_destroy();
}

if (mType == "animal_dog") {
	sprite_index = spr_balloon_dog;
} else if (mType == "animal_snake") {
	sprite_index = spr_balloon_snake;
}
if (mColor == "pink") {
	image_blend = #ff2bb1;
} else if (mColor == "blue") {
	image_blend = #0080ff;
} else if (mColor == "red") {
	image_blend = #ff2200;
} else if (mColor == "green") {
	image_blend = #5be625;
}
