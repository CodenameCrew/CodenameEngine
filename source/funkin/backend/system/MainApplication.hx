package funkin.backend.system;

import lime.app.Application;
import funkin.backend.system.Main;

class MainApplication extends Application {
	public function new() {
		super();

		#if openfl
        openfl.Lib.current.stage.addChild(new Main());
        #end
	}
}