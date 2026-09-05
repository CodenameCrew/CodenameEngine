package funkin.backend.system;

import flixel.group.FlxSpriteGroup;

class RotatingSpriteGroup extends FlxSpriteGroup {
	public function recycleLoop(?ObjectClass:Class<FlxSprite>, ?ObjectFactory:Void->FlxSprite, Force:Bool = false, Revive:Bool = true):FlxSprite {
		@:privateAccess {
			if (maxSize <= 0)
				return super.recycle(ObjectClass, ObjectFactory, Force, Revive);
			if (group.members.length < maxSize)
			{
				if (ObjectFactory != null) return add(ObjectFactory());
				if (ObjectClass != null) return add(Type.createInstance(ObjectClass, []));

				return null;
			}
			var spr = group.members.shift();
			group.members.push(spr);
			if (Revive)
				spr.revive();
			return spr;
		}
	}
}