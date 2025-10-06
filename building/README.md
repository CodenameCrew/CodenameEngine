Here's the full guide on how to setup and compile Codename Engine!<br>

> **Open the instructions for your platform**
<details>
    <summary>Windows</summary>

1. Install [version 4.3.7 of Haxe](https://haxe.org/download/version/4.3.7/).
2. Download and install [`git-scm`](https://git-scm.com/download/win).
    - Leave all installation options as default.
3. Run `setup-windows.bat` using cmd or double-clicking it and wait for the libraries to install.
4. Once the libraries are installed, run `haxelib run lime test windows` to compile and launch the game (may take a long time)
    - ℹ You can run `haxelib run lime setup` to make the lime command global, allowing you to execute `lime test windows` directly.
</details>
<details>
    <summary>Linux</summary>

1. Install [version 4.3.7 of Haxe](https://haxe.org/download/version/4.3.7/).
2. Install `libvlc` if not present already.
    - ℹ On certain Arch based distros installing `vlc-plugins-all` might solve if `libvlc` alone doesn't work.
3. Install `g++`, if not present already.
4. Download and install [`git-scm`](https://git-scm.com/download/linux) if not present already.
5. Run `setup-unix.sh` using the terminal or double-clicking it and wait for the libraries to install.
6. Once the libraries are installed, run `haxelib run lime test linux` to compile and launch the game (may take a long time)
    - ℹ You can run `haxelib run lime setup` to make the lime command global, allowing you to execute `lime test linux` directly.
</details>
<details>
    <summary>MacOS</summary>

1. Install [version 4.3.7 of Haxe](https://haxe.org/download/version/4.3.7/).
2. Install `Xcode` to allow C++ app building.
3. Download and install [`git-scm`](https://git-scm.com/download/mac).
4. Run `setup-unix.sh` using the terminal and wait for the libraries to install.
5. Once the libraries are installed, run `haxelib run lime test mac` to compile and launch the game (may take a long time)
    - ℹ You can run `haxelib run lime setup` to make the lime command global, allowing you to execute `lime test mac` directly.
</details>

> [!TIP]
> You can also run `./cne-windows.bat -help` or `./cne-unix.sh -help` (depending on your platform) to check out more useful commands!<br>
> For example `./cne-windows test` or `./cne-unix.sh test` builds the game and uses the source assets folder instead of the export one for easier development (although you can still use `lime test` normally).
> - If you're running the terminal from the project's main folder, use instead `./building/cne-windows.bat -COMMAND HERE` or `./building/cne-unix.sh -COMMAND HERE` depending on your platform.
