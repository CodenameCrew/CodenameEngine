function next(event)
	if (!event.playFirst) trace("-");

function postNext(event)
	trace(curLine.char + " says: " + curLine.text);