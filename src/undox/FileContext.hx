package undox;

import haxe.io.Path;
import sys.io.File;
import haxe.io.Output;
import sys.FileSystem;
import undox.data.UType.UPath;

class FileContext {

	private var touchedFiles:Map<String, Bool>;
	private var path:String;
	private var relativePath:String;
	private var oldCwd:String;

	private function new(path:String, relativePath:String, touchedFiles:Map<String, Bool>) {
		this.touchedFiles = touchedFiles;
		this.path = path;
		this.relativePath = relativePath;
	}

	public static function root(path:String):FileContext {
		return new FileContext(path, "", new Map<String, Bool>());
	}

	public function child(name:String):FileContext {
		return new FileContext(Path.join([path, name]), Path.join([relativePath, name]), touchedFiles);
	}

	public function open():Void {
		FileSystem.createDirectory(path);
		oldCwd = Sys.getCwd();
		Sys.setCwd(path);
	}

	public function writeHx(path:UPath, value:String):Void {
		var modulePath:Array<String> = if (path.pack == "") [] else path.pack.split(".");
		modulePath.push(path.module);
		var filePath:String = Path.join(modulePath) + ".hx";
		var relativePath:String = Path.join([relativePath, filePath]);
		var dir = new haxe.io.Path(filePath).dir;
		if (dir != null) FileSystem.createDirectory(dir);
		var output:Output;
		if (this.touchedFiles.exists(relativePath)) {
			output = File.append(filePath, true);
		} else {
			this.touchedFiles.set(relativePath, true);
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
