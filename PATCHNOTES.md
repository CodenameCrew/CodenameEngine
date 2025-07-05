# The Charter Update
## All major chart editors are finished as of this update (finally...)
## Engine goes from alpha to beta state : D

<details>
  <summary><h2>Patch Notes</h2></summary>

- CHARTER FEATURES
	- BIG BOY FEATURES
		- Ability to add Note Types in the charter
		- In-engine Difficulty Creation is now implemented
		- Snaps for notes/events in the charter
		- Multiple Vocals Support (per strumline)
		- Playback speed in the charter
		- New SEXY editor assets by paige and nex!!!! (and lunar, does 16x16 even count??? 😭)
		- NEW EVENTS (Camera events, play animation, scroll speed change)
		- Events window is now scrollable (more events, more room)
		- Custom Properities in Meta AND Character (Editable in Charter and Character Editor :D) (accessible with SONG.meta.customValues.[property] and [character].extras.[property])
	- SMALLER BUT STILL COOL
		- Multiple Icons now show up on strumlines with multiple characters in the charter
		- Note hoverer to show where your note is going to be placed
		- Editor UI got some slight reworks (top bar/elements)
		- Event files can be packed together into one (image/script/json all in a .pack file)
		- Optimized notes in the charter (Faster loading, can handle a billion now so cool neeo!!)
		- Editor Song pos now stays the same even after playtesting
		- Other smaller stuff i forgot 😭
	- BUG FIXES:
		- COPY PASTED EVENTS NOW WON'T BREAK!!!
		- Song position line no longer jitters
		- UNDOs are more stable now
		- Drags work much better
		- Freezes fixed (deleting strumlines)
- ENGINE FEATURES
	- BIG BOY FEATURES
		- Position custom characters in the stage xml using char="" attribute
		- Aseprite sprites support (for characters and many more)
		- Edit Draw calls directly from the sprite (sprite.onDraw = (spr:FlxSprite) -> {spr.draw();})
		- Addons will now properly function together (changed how state scripts and scripts overall load)
		- MusicBeatTransition is more scriptable
		- Moddable Game Over Events!!
		- Reworked Lagless Credits Codename Engine's Contributors Menu
		- New Credit Method for GitHub accounts (also lagless) in Mod Credits (First gets the data normally, if fails uses the ratelimited api)
		- MANY OG GAME WEEK STUFF!! (still wip and softcoded and also many reworks by nex!)
		- Senpai Cutscene got reworked! (https://github.com/CodenameCrew/CodenameEngine/assets/87421482/3b3f32fc-78d1-40fa-8398-776554cab1d6)
		- Thorns got reworked with a cool chromatic aberration effect! (https://github.com/CodenameCrew/CodenameEngine/assets/87421482/73d9f7c5-1c9c-407e-baf0-e8e2c381ecbb)
		- Winter Horrorland got reworked with a bloody vignette effect! (https://github.com/CodenameCrew/CodenameEngine/assets/87421482/1e10c3e2-32dc-4de2-b31a-d9d577d516da - https://github.com/CodenameCrew/CodenameEngine/assets/87421482/cad852c3-1ee2-409e-a70e-b3571ab5cf7b)
	- SMALLER BUT STILL COOL
		- Ability to set Controls.hx variables (Being able to block inputs or even trigger them (needs to be in an if statement))
		- You can now easily check if a cutscene was played (by default is disabled and makes it auto play or not; Check startCutscene() code for more details in PlayState)
		- onScriptCreated event in global.hx
		- Addons priority (Being able to set addons to load before or after a mod)
		- Added Script.fromString to add scripts without making pesky new files!!
		- 9 Splice Sprites can render smaller than their intended size
		- Ability to turn off gitaroo easter egg (finally...)
		- Auto complete for certain text fields (characters/stages/notetypes)
	- HSCRIPT FEATURES:
		- Added "is" for checking var type
		- Maps are now iterable (for (key=>value in map))
		- FIXED CRASH ON EMPTY SCRIPTS!!!!!
- BUG FIXES
	- Fix events to be more stable
	- Fix for onBeat sprites type with also customizable beat intervals and offset (and decide if also skipping negative beats so for example before the song starts)
	- Fix for pressing F5 in an editor breaking it
	- Fix when getting GitHub data and a redirect happens
	- Fix for healthbar incorrectly colored in opponent mode
	- Video cutscenes are ALOT more stable (thanks majigsaw :D)
	- 3D now works again (so cool i love away3d in 2024)
	- Lots and lots of grammar and wording fixes (so true bro -lunar)
	- Lots and lots of other optimizations made
- CHANGES
	- onDestroy has been renamed to destroy in all instances
	- Strumline Pos X in editors is now a ratio (0.25 for bf, 0.75 for dad)
	- BY DEFAULT when in Story Mode, the arrows tween in only when there was a transition
	- onBeatHit renamed to beatHit in gameover substate (stepHit added)
	- Alt Animation Events can now control both poses and idle (may need to be readded in pre existing charts)
	- Some other shit idk ill add it whenever someone tells me backward compat is broke 💔
</details>

thanks so much for the support and always being there, it really does mean alot to us < 3
we are one step closer to turning beta so we really can't wait !