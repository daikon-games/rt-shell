waveFrame = (waveFrame + 1) % waveFrames;

if (obj_shell.isOpen) {
	msg = closeMsg;
} else {
	msg = openMsg;
}