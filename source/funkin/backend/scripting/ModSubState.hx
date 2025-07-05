package funkin.backend.scripting;

class ModSubState extends MusicBeatSubstate {

	/**
	* Name of HScript file in assets/data/states.
	*/
	public static var lastName:String = null;
	/**
	* Last Optional extra data.
	*/
	public static var lastData:Dynamic = null;

	/**
	* Optional extra data.
	*/
	public var data:Dynamic = null;

	/**
	* ModSubState Constructor.
	* Inherits from MusicBeatSubstate and allows the execution of an HScript from assets/data/states passed via parameters.
	*
	* @param _stateName Name or path to a HScript file from assets/data/states.
	* @param _data Optional extra Dynamic data passed from a previous state (JSON suggested).
	*/
	public function new(_stateName:String, ?_data:Dynamic) {
		if(_stateName != null && _stateName != lastName) {
			lastName = _stateName;
			lastData = null;
		}

		if(_data != null)
			lastData = _data;

		data = lastData;
		super(true, lastName);
	}
}