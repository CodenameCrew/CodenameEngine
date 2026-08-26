package funkin.menus.charSelect;

typedef SelectCharacterData =
{
	public var displayName:String;
	public var character:String;
	public var ?partner:String;
	public var ?partnerSpeakers:String;

	public var ?selectTheme:String;
	public var ?selectPortrait:String;

	public var icon:String;
	public var ?partnerIcon:String;
	public var ?showPartnerIcon:Bool;

	public var ?unselectedAnim:String;
	public var ?transitionsAnim:String;
	public var ?selectedAnim:String;
	public var ?transitionuAnim:String;

	public var charScrX:Int;
	public var charScrY:Int;
}
