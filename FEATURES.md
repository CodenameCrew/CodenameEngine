# Codename Engine features
This markdown file contains every single feature Codename has, separated into multiple categories. List may be incomplete.

_**QOL = Quality of Life**_

<details>
  <summary><h2>Player QOL Features</h2></summary>

- New input system
- New accuracy and misses system, added to fix the base game UI.
- New options, including:
    - Controls rebinds (for P1 and P2)
    - Downscroll
    - Ghost Tapping
- Opponent & Co-op modes
- Memory optimisation (most of the game runs < 500mb)
    - Usage of [flxanimate](https://github.com/Dot-Stuff/flxanimate) on big sprites, such as Girlfriend to save memory.
    - You can further optimize it on certain stages by enabling `Low Memory Mode` in `Options > Appearance`.
- New volume change SFX (no more loud flixel beep, customizable)
- New FPS counter allowing you to see advanced info by pressing F3 (infos can be selected and copied too when in advanced).
- Simple but advanced modding system (press TAB on main menu)
- **Windows only:**
    - (Windows) FNF is no longer blurry on 125-150% DPI
    - FNF auto fixes audio on state change when you plug in/out your headphones.
    - FNF auto applies dark titlebar
- **Week 7 included** with softcoded cutscenes (no MP4)
- Auto updating: Once the engine updates, a prompt will be available at launch. If you accept to update, the engine will auto install the newest version. All of the following update files will be downloaded from the GitHub releases:
    - `Update-Windows.exe` - Containing the latest Windows executable. (~60mb)
    - `Update-Assets.zip` - Every asset change from the latest version to the newest. If upgrading from even older version, all of the `Update-Assets.zip` files for the versions in between and the latest one will be downloaded.
</details>

<details>
    <summary><h2>Modding QOL features</h2></summary>

- New assets and scripting management - **Applies both to the `assets` folder and mods.**
    - Support for `hscript-improved`, a fork made to allow HScript to push modding even further
        - Allows for imports
        - Allows for public variables (variables shared between every script in a ScriptPack such as a song scripts)
        - Allows for static variables (variabels shared between every single script ran in this mod)
        - Allows you to use for example `boyfriend` instead of `PlayState.boyfriend` or `game.boyfriend`, for smaller and easier to comprehend code.
        - Allows you to use `@:bypassAccessor`
        - Allows you to use maps
    - Usage of XML files for Characters instead of hardcoding them.
        - Animation names, prefixes, indices, etc... can be set in the XML without an additional line of code.
        - Offsets are automatically fixed. That means changes such as scaling, rotation, and playing as an opponent character wont break them.
    - Entirely new song structure (`songs/name/`)
        - Usage of `meta.json`, which allows you to synchronize data between charts and the Freeplay menu.
            - Charts can use their own by specifying `meta` in the JSON (Codename charts only)
        - Charts are now located in `songs/name/charts/`, and are named after the difficulty `hard.json` instead of `name-hard.json`
            - Difficulties are auto-detected in case they aren't specified in the `meta.json` file.
        - Scripts are located in `songs/name/scripts/`, and only applies to the current song.
            - Script that applies on every song are located in `data/charts/`.
        - Song files are now located in `songs/name/song/`. They still follow their `Inst.ogg` and `Voices.ogg` names.
            - Inst/Voices for custom difficulties can be set by naming those files `Inst-difficulty.ogg` and/or `Voices-difficulty.ogg`.
            - Song length limits
    - Usage of XML files for stages. XMLs can:
        - Change camera zooms, camera offsets, etc...
        - Add elements to the stage and
            - Position them
            - Add animations
            - Change their scale
            - Change their scrollfactor
            - Change their zoomfactor
            - Turn on/off their antialiasing (on by default)
            - Change additional properties via child nodes.
        - Change boyfriend, girlfriend and dad's info
            - Moving the `<boyfriend />`, `<girlfriend />` and `<dad />` nodes will move them in the layers
            - Adding x and y attributes to them will change their position
            - You can add positioning for custom characters by adding `<character name="name" />`
    - Usage of XML files for weeks.
        - Characters are located in `data/weeks/characters`.
        - Weeks are located in `data/weeks/weeks/`
        - If you need to rearrange the weeks in-game, you can use the `data/weeks/weeks.txt` file.
	- Editors for Charts and Characters (Stage coming soon)
		- Undos/Redos supported
		- Warning on closing unsaved work
		- Clean UI (for ocd freaks)
		- Mature Chart editor (Character editor rework soon)
		- Features not found in other editors!
    - Every single state & substate can be modified via HScript (`data/states/StateName.hx`)
- **Instances launched via `lime test windows` will automatically use assets from source.**
</details>