package undox.readers;

import sys.FileSystem;
import sys.io.File;

class HxReader {

	private var platform:String;
	private var context:Context;
	private var fileContext:FileContext;

	public function new(platform:String, path:String, context:Context) {
		this.context = context;
		this.fileContext = new FileContext(path);
	}

	public static function readHx(path:String, context:Context):Void {
		var platform = "swf";
		var xml = Xml.parse(File.getContent(path)).firstElement();

		var reader:HxReader = new HxReader(platform, path, context);
		reader.readDirectoryRoot();
	}

	public function readDirectoryRoot():Void {
		readDirectory(this.fileContext);
	}

	private function readDirectory(fileContext:FileContext):Void {
		fileContext.open();
		for (f in FileSystem.readDirectory(".")) {
			if (FileSystem.isDirectory(f)) {
				readDirectory(fileContext.child(f));
			} else {
				readSource(fileContext.read(f, fileName));
			}
		}
		fileContext.close();
	}

	private function readSource(fileContent:String, fileName:String):Void {
		Sys.stderr.writeString(Std.string(fileName));
	}
}
