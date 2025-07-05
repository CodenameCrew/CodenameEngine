function postHide() {
	if(curTween != null) {
		if(getAnimName() == 'angry-show') curTween.cancel();
		else curTween.percent = 1;
	}
}
