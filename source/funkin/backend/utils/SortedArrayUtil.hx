package funkin.backend.utils;

/**
 * Tools to work with sorted arrays, in a more efficient way.
 *
 * DISCLAIMER: All types of utils only usable in a sorted array.
 */
final class SortedArrayUtil {
	/**
	 * Gets the index of a possible new element of an Array of T using an efficient algorithm.
	 * @param array Array of T to check in
	 * @param getVal Function that returns the position value of T
	 * @return The index of the element
	 */
	public static function binarySearch<T>(array:Array<T>, val:Float, getVal:T->Float):Int {
		if (array.length <= 0) return 0; // if the array is empty, it should be equal to zero (the beginning)
		if (getVal(array[0]) > val) return 0; // in case its the minimum
		if (getVal(array[array.length-1]) < val) return array.length; // in case its the maximum

		// binary search
		var iMin:Int = 0;
		var iMax:Int = array.length-1;

		var i:Int = 0;
		var mid:Float;
		while(iMin <= iMax) {
			i = Math.floor(iMin + (iMax - iMin) / 2);
			mid = getVal(array[i]);
			if (mid < val)
				iMin = i+1
			else if (mid > val)
				iMax = i-1;
			else {
				iMin = i;
				break;
			}
		}
		return iMin;
	}

	/**
	 * Adds to a sorted array, using binary search.
	 * @param array Array to add to
	 * @param val Value to add
	 * @param getVal Function that returns the value that needs to be sorted
	 */
	public static inline function addSorted<T>(array:Array<T>, val:T, getVal:T->Float) {
		if (val != null)
			array.insert(binarySearch(array, getVal(val), getVal), val);
	}

	/**
	 * Removes from a sorted array, using binary search.
	 * @param array Array to remove from
	 * @param val Value to remove
	 * @param getVal Function that returns the value that needs to be sorted
	 */
	public static inline function removeSorted<T>(array:Array<T>, val:T, getVal:T->Float) {
		var index = binarySearch(array, getVal(val), getVal);
		if (index != -1)
			array.splice(index, 1);
	}
}