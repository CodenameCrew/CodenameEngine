function next(event:DialogueNextLineEvent) {
	var first = event.playFirst;
	if(first && canProceed) {
		canProceed = false;
		dialogueLines[0].playSound.play();
		new FlxTimer().start(1, (_) -> this.next(true));
	}
	else if(this.lastLine == null) canProceed = true;  // If its not null means the dialogue is not at the first one!  - Nex
}