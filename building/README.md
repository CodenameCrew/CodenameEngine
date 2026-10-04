# Compiling Codename Engine

Do note that compiling is ***NOT*** the intended manner of modding with Codename Engine, as the softcoding system is designed in your favor. The exception to this is if you want to contribute to CNE's development by making a pull request.

<details>
	<summary>"Why not?"</summary>

- The version you downloaded is yours to keep forever. If a new release of CNE goes live, you bear the responsibility of merging by hand and testing it.
- You lose compatibility with other mods. Softcoded mods stack on top of each other. Source mods cannot.
- Changed something? In softcoding, it takes two seconds. In hardcoding, it now requires a rebuild, up to a few minutes to an hour if you have not compiled the engine beforehand.
- Bugs caused by your changes will now be your reponsibility to fix.
- HScript has a safety net that catches errors and (mostly) prevents crashes. Source modding does not have this. This means that if something goes wrong, HScript with catch it, but your source mod would not and it'll take the entire game down.

</details>

<details>
	<summary>Pros of source modding</summary>

- Full access. Literally.
- Code is compiled to bytecode, which is magnitudes faster than HScript's interpreter.
- The engine now becomes your template.

</details>

<details>
	<summary>Cons of source modding</summary>

- Syncs with the original repo usually causes conflicts. This means that you'll be stuck on whatever version you forked from.
- Modpacks made for your fork are only compatible with your forks and not any releases of Codename.
- Testing is *VERY* slow compared to softcoding.
- Crashes are your responsibilty. A fork needs someone willing to maintain it.

</details>

</br>

## Initialization

Here is what you'll need:
- [Haxe v4.3.7](https://haxe.org/download/version/4.3.7/). You shouldn't grab the latest version just because it's newer.
- [Git](https://git-scm.com/), more specifically `git-scm`.
  - When installing, make sure to **leave the installation options at its defaults**.
- A C++ compiler. Depending on your platform, it could be any of the following:
  - For Windows, that's **Visual Studio Build Tools 2019** with the component *MSVC v143 C++ x64/x86 build tools* as well the *Windows SDK*.
  - For Mac, you will need `Xcode` as it provides the compiler.
  - For Linux, that's `gcc` and `g++`. `libvlc` must also be installed for video playback functionality.
- The engine's libaries.
  - You can run `setup-windows.bat` to set these up in Windows, or `setup-unix.sh` for both Mac and Linux. Ensure that your `haxelib` is up to date.
  - After running either of this, you might be given a warning similar to `warning: repository requires reformatting`. Ignore these warnings and do not run the command listed as it will break the structure of the libraries installed.

> [!TIP]
> You can also run `./cne-windows.bat -help` or `./cne-unix.sh -help` (depending on your platform) to check out more useful commands!<br>
> For example `./cne-windows test` or `./cne-unix.sh test` builds the game and uses the source assets folder instead of the export one for easier development (although you can still use `lime test` normally).
> - If you're running the terminal from the project's main folder, use instead `./building/cne-windows.bat -COMMAND HERE` or `./building/cne-unix.sh -COMMAND HERE` depending on your platform.

# Generating Codename Engine's API documentation
**Mainly recommended if you intend to fork the engine and make your own custom version to publish.**<br>Do you want to generate an API documentation so people can understand and mod your playable build? This documentation can be uploaded to your website.<br>If you just want to compile the engine normally for your hardcoded mod or for yourself you can skip this step.
> **Select your platform to continue.**
<details>
    <summary>Windows</summary>

1. Run `generate-docs-windows.bat` using cmd or double-clicking it and wait for the `doc.xml` to be generated inside the `docs` folder.
</details>
<details>
    <summary>MacOS/Linux</summary>

1. Run `generate-docs-unix.sh` using the terminal or double-clicking it and wait for the `doc.xml` to be generated inside the `docs` folder.
</details>

2. You can use this `doc.xml` file to generate a full HTML documentation (that you can open in your browser for example) using Haxe's [dox](https://github.com/HaxeFoundation/dox) generator; check [Codename Engine's webiste](https://github.com/CodenameCrew/codename-website/tree/main/api-generator) for example.

> [!CAUTION]
> The doc.xml might contain some sensible paths of your computer: make sure to filter the file before publishing it for everyone if you want to keep those paths private!<br>To filter and delete those paths, you may use Codename Engine's website's [doc filter Python script](https://github.com/CodenameCrew/codename-website/blob/main/api-generator/api/filter.py) by simply running it in the same folder of your `doc.xml` file. This script will also delete everything irrelevant to the engine that was generated in your documentation, such as libraries' (like OpenFL or Flixel) APIs.