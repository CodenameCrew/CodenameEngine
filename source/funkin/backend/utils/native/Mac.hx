package funkin.backend.utils.native;

#if (mac && cpp)
import funkin.backend.utils.NativeAPI.CodeCursor;
import openfl.ui.Mouse;

@:headerInclude('sys/sysctl.h')
@:headerInclude('mach/mach.h')
@:dox(hide)
final class Mac
{
	@:functionCode('
	int mib [] = { CTL_HW, HW_MEMSIZE };
	int64_t value = 0;
	size_t length = sizeof(value);

	if(-1 == sysctl(mib, 2, &value, &length, NULL, 0))
		return -1; // An error occurred

	return value / 1024 / 1024;
	')
	public static function getTotalRam():Float
	{
		return 0;
	}

	@:functionCode('
		task_basic_info_data_t info;
		mach_msg_type_number_t count = TASK_BASIC_INFO_COUNT;
		if (task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &count) == KERN_SUCCESS) {
			return (double)info.resident_size;
		}
		return 0.0;
	')
	public static function getCurrentProcessMemory():Float
	{
		return 0;
	}

	public static function setMouseCursorIcon(icon:CodeCursor):Void
	{
		final valid:Bool = external.ExternalMac.setCursorIcon(icon.toInt(), null, 0, 0);

		if (!valid)
			Mouse.cursor = icon.toOpenFL();
	}
}
#end


/*

Cursor

Description
The arrow cursor (arrow)
The I-beam cursor for indicating insertion points (iBeam)
The cross-hair cursor (crosshair)
The closed-hand cursor (closedHand)
The open-hand cursor (openHand)
The pointing-hand cursor (pointingHand)
The resize-left cursor (resizeLeft)
The resize-right cursor (resizeRight)
The resize-left-and-right cursor (resizeLeftRight)
The resize-up cursor (resizeUp)
The resize-down cursor (resizeDown)
The resize-up-and-down cursor (resizeUpDown)
The disappearing item cursor (disappearingItem)
The I-Beam text cursor for vertical layout (iBeamCursorForVerticalLayout).
The not allowed cursor (operationNotAllowed).
The drag link cursor (dragLink).
The drag copy cursor (dragCopy).
The contextual menu cursor (contextualMenu).
*/
