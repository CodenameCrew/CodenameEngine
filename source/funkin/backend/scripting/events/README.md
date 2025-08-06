## NOTE
Keep in mind that a certain criteria was used to place events in their corresponding folders which is simply what the events themselves are mostly related to.

For example:

- `GameOverEvent` inside of the `gameplay` folder instead of the `gameover` folder since it gets called in the `PlayState` class (that owns the `gameplay` folder) instead of the `GameOverSubstate` class itself;
- `NoteHitEvent` gets indeed called by the `PlayState` class but it's also used in the `StrumLine` (For those who didn't really know, Strumlines are the Input Notes) class and since the event's name itself starts with the word `Note` it was more accurate to place it in the `note` folder instead of the `gameplay` folder that `PlayState` owns.