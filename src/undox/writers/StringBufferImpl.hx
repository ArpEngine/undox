package undox.writers;

import haxe.io.BytesBuffer;

class StringBufferImpl {

	private var buf:BytesBuffer;
	private var tab:String = "";

	public function new() {
		buf = new BytesBuffer();
	}

	public function indent(value:Int):Void {
		if (value > 0) {
			tab = tab + "\t";
		} else {
			tab = tab.substr(1);
		}
	}

	public function writeLines(lines:String):Void {
		for (line in lines.split("\n")) writeLine(line);
	}

	public function writeLine(line:String):Void {
		buf.addString(if (line == null || line == "") "\n" else '$tab$line\n');
	}

	public function toString():String return buf.getBytes().toString();
}
