function onNoteHit(event) if (event.noteType == "Alt Anim Note") event.animSuffix = "-alt";
function onPlayerMiss(event) if (event.noteType == "Alt Anim Note") event.animSuffix = "miss-alt";