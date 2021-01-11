var screen_center_x = display_get_gui_width()/2;
var screen_center_y = display_get_gui_height()/2;

draw_set_color(c_white);
draw_set_font(font_demo);
draw_set_halign(fa_center);

var stringCharCount = string_length(msg);
for (var i = 1; i <= stringCharCount; i++) {
	var char = string_char_at(msg, i);
	var xOffset = -18 * ((stringCharCount/2) - i);
	var waveDeg = (((waveFrame + (3 * i)) % waveFrames)/waveFrames) * 360;
	var yOffset = dsin(waveDeg) * waveAmount;
	draw_text(screen_center_x + xOffset, screen_center_y + yOffset, char);
}

draw_set_halign(fa_left);