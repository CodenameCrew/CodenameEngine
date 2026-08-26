package funkin.menus.charSelect;

/**
 * Character select modes
 */
enum abstract CharacterSelectMode(Int) from Int
{
	var CHARACTER_AND_MODE = 0;
	var MODE_ONLY = 1;
	var CHARACTER_ONLY = 2;
	var SKIP = 3;
}
