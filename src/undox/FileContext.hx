package undox;

import sys.io.File;
import haxe.io.Output;
import sys.FileSystem;
import undox.data.UType.UPath;

class FileContext {

	private var touchedFiles:Map<String, Bool>;
	private var path:String;
	private var oldCwd:String;

	public function new(path:String) {
		this.touchedFiles = new Map<String, Bool>();
		this.path = path;
	}

	public function open():Void {
		FileSystem.createDirectory(path);
		oldCwd = Sys.getCwd();
		Sys.setCwd(path);
	}

	public function writeHx(path:UPath, value:String):Void {
		var modulePath:Array<String> = if (path.pack == "") [] else path.pack.split(".");
		modulePath.push(path.module);
		var filePath:String = modulePath.join("/") + ".hx";
		var dir = new haxe.io.Path(filePath).dir;
		if (dir != null) FileSystem.createDirectory(dir);
		var output:Output;
		if (this.touchedFiles.exists(filePath)) {
			output = File.append(filePath, true);
		} else {
			this.touchedFiles.set(filePath, true);
			output = File.write(filePath, true);
			output.writeString('package ${path.pack};\n');
		}
		output.writeString('\n');
		output.writeString(value);
		output.close();
	}

	public function close():Void {
		Sys.setCwd(oldCwd);
	}
}
