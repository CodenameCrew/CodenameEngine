package funkin.backend.utils;

#if sys
import haxe.io.Input;
import haxe.zip.Reader;
import sys.io.File;
import sys.io.FileInput;

import haxe.io.Bytes;

/**
 * Class that extends Reader allowing you to load ZIP entries without blowing your RAM up!!
 * ~~Half of the code is taken from haxe libraries btw~~ Reworked by ItsLJcool to actually work for zip files.
 */
class SysZip {
	var fileInput:FileInput;
	var filePath:String;

	public var entries:List<SysZipEntry> = new List();

	/**
	 * Opens a zip from a specified path.
	 * @param path Path to the zip file. (With the extension)
	 */
	public static function openFromFile(path:String) { return new SysZip(path); } // keeping for compatibility.

	/**
	 * Creates a new SysZip from a specified path.
	 * @param path Path to the zip file. (With the extension)
	 */
	public function new(path:String) {
		this.filePath = path;
		fileInput = File.read(path, true);

		updateEntries(); // automatic but if you feel like you don't want it to be automatic, you can remove this.
	}

	/**
	 * Unzips and returns all of the data present in an entry.
	 * @param f Entry to read from.
	 */
	public function unzipEntry(f:SysZipEntry):Bytes {
		fileInput.seek(f.seekPos, SeekBegin);
		var data = fileInput.read(f.compressedSize);
		
		if (!f.compressed) return data;

		var c = new haxe.zip.Uncompress(-15);
		var s = Bytes.alloc(f.fileSize);
		var r = c.execute(data, 0, s, 0);
		c.close();

		if (!r.done || r.read != data.length || r.write != f.fileSize) throw "Invalid compressed data for " + f.fileName;
		return s;
	}

	/**
	 * Updates the `entries` list with the current contents of the zip file.
	 * This is done when the zip is read from SysZip the first time, but if you REALLY need to re-update the entries, you can call this again.
	 * 
	 * Note: Calling this function will hold up the game as it has to read the ENTIRE zip, so if it's large like 1GiB or more, it might take a second or more.
	 */
	public function updateEntries() {
		if (entries.length > 0) {
			entries.clear();
			entries = new List();
		}
		
		// --- locate End of Central Directory (EOCD) ---
		var fileSize:Int = sys.FileSystem.stat(this.filePath).size; // probably need a better way to check the size of the file.
		var scanSize:Int = (65535 < fileSize) ? 65535 : fileSize;
		
		// It seems this usually ends up being 0 anyways, but for cases where it might not be?? I'd just make sure. but Someone do some digging I don't know if this required.
		fileInput.seek(fileSize - scanSize, SeekBegin);
		
		var buf = fileInput.read(scanSize);
		var b = new haxe.io.BytesInput(buf);
		b.position = (buf.length - 22) + 16; // offset to start of central directory

		// --- read central directory ---
		fileInput.seek(b.readInt32(), SeekBegin);
		while (true) {
			if (fileInput.readInt32() != 0x02014b50) break; // central dir file header signature

			fileInput.seek(6, SeekCur); // version/flags
			var compression_method = fileInput.readUInt16();
			fileInput.seek(8, SeekCur); // time/date + CRC32 (4, 4)
			var compressed_size = fileInput.readInt32();
			var uncompressed_size = fileInput.readInt32();
			var nameLen = fileInput.readUInt16();
			var extraLen = fileInput.readUInt16();
			var commentLen = fileInput.readUInt16();
			fileInput.seek(8, SeekCur); // skip disk number/start attrs
			var localHeaderOffset = fileInput.readInt32();

			var name = fileInput.read(nameLen).toString();

			// skip central directory extra/comment
			fileInput.seek(extraLen + commentLen, SeekCur);

			// --- compute correct seekPos using local header ---
			var curPos = fileInput.tell();
			fileInput.seek(localHeaderOffset + 26, SeekBegin);
			var localNameLen = fileInput.readUInt16();
			var localExtraLen = fileInput.readUInt16();
			fileInput.seek(curPos, SeekBegin);

			var zipEntry:SysZipEntry = {
				fileName: name,
				fileSize: uncompressed_size,
				// I don't remember what the `+ 30` is for, but probably to offset something
				seekPos: (localHeaderOffset + 30 + localNameLen + localExtraLen),
				compressedSize: compressed_size,
				compressed: (compression_method == 8),
			};
			entries.add(zipEntry);
		}
	}

	/**
	 * calling `dispose` doesn't actually kill the class, you can still access the entries.
	 * disposing of SysZip will free the compressed file from being used by the engine.
	 */
	public function dispose() {
		if (fileInput != null) fileInput.close();
	}
}

typedef SysZipEntry = {
	var fileName:String;
	var fileSize:Int;
	var seekPos:Int;
	var compressedSize:Int;
	var compressed:Bool;
}
#end