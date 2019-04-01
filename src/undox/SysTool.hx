package undox;

class SysTool {

	public static function setCwd(dir:String):Void {
		stderr('cd $dir');
		Sys.setCwd(dir);
	}

	public static function stderr(line:String):Void {
		Sys.stderr().writeString('$line\n');
		Sys.stderr().flush();
	}

	public static function exec(cmd:String):Int {
		stderr(cmd);
		return Sys.command(cmd);
	}
}
