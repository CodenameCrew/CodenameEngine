# Codename Engine v0.4.idk

### This is the first ever public release of Codename Engine **BETA**.
Shoutout to the people who stuck with us throughout the alpha and supported us! \
<br />

# Features available in this version:
- ### Simple but advanced modding system!
	- Mods have been reworked to run in it's entirety instead of just limited to songs.
	- Uses an advanced scripting system based on haxe which is capable of modifying the game beyond source code.
		- Uses a system of events based on actions going on in the game allowing change of those actions to your needs. (ex. when a player hits a note, when it confirms on a menu etc.)
		- Ability to bind scripts to characters or stages.
		- Ability to bind scripts to states/menus.
		- Ability to create your own states/classes just like source code.
		- Ability to create even more advanced stuff using systems like ndll.
	- Uses a brand new song structure for cleanliness.
		- Uses a brand new chart format for optimization and extensibility.
		- Uses meta system for storing important values instead of in the chart file.
	- Characters, stages, weeks use an xml format for cleanliness.
	- Native custom shaders support.
	- Native 3D renderer.
	- Addon system for adding scripts or skins to run in any mod.
	- Ability to add your own options.
- ### Multiple Overhauls
	- Settings are more streamlined.
	- Strumlines are more flexible than before (unlike base game's hardcoded 2)
	- Characters are also flexible (unlike base game's hardcoded 3)
	- New input system
	- New accuracy and misses system, added to fix the base game UI.
	- New options, including:
	    - Controls rebinds (for P1 and P2)
	    - Downscroll
	    - Ghost Tapping
	- Countless of rewrites around the code (menus, gameplay, system etc.)
- ### New Features
	- Opponent & Co-op modes
	- New volume change SFX (no more loud flixel beep, customizable)
	- New FPS counter allowing you to see advanced info by pressing F3 (infos can be selected and copied too when in advanced).
	- (Windows) FNF is no longer blurry on 125-150% DPI
    - FNF auto fixes audio on state change when you plug in/out your headphones.
    - FNF auto applies dark titlebar
	- Week 7 uses softcoded cutscenes (no MP4)
	- Auto updating: Once the engine updates, a prompt will be available at launch. If you accept to update, the engine will auto install the newest version. All of the following update files will be downloaded from the GitHub releases:
    	- `Update-Windows.exe` - Containing the latest Windows executable. (~60mb)
    	- `Update-Assets.zip` - Every asset change from the latest version to the 	newest. If upgrading from even older version, all of the `Update-Assets.zip` 	files for the versions in between and the latest one will be downloaded.
- ### Optimizations
	- optimizations idk fill this with stuff
	- Memory has been optimized (most of the game runs < 500mb)
    - Usage of [flxanimate](https://github.com/Dot-Stuff/flxanimate) on big sprites, such as Girlfriend to save memory.
    - Ability to add more optimizations to your mod using the `Low Memory Mode` option.

- ### Editors
	- Charter
		- Has been reworked entirely to have new, more streamlined UI.
		- idk too lazy to fill this in
	- Undos/Redos supported 
	- Warning on closing unsaved work
	- Clean UI (for ocd freaks)
	- Mature Chart editor (Character editor rework soon)
	- Features not found in other editors!
- Every single state & substate can be modified via HScript (`data/statesStateName.hx`)