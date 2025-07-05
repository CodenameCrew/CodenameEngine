function create() {
	isSpooky = true;

	// Make transition work between school types
	if(PlayState.smoothTransitionData?.stage == "school") PlayState.smoothTransitionData.stage = curStage;

	disableScript();
}