package undox;

class Args {

	public var xmls(default, null):Array<String>;
	public var hxs(default, null):Array<String>;
	public var output(default, null):String;
	public var format(default, null):String;

	public function new() {
		xmls = [];
		hxs = [];
		var args = Sys.args();
		var cwd = args.pop();
		if (cwd != null) SysTool.setCwd(cwd);

		while (args.length > 0) {
			switch (args.shift()) {
				case "-x", "--xml":
					xmls.push(args.shift());
				case "-h", "--hx":
					hxs.push(args.shift());
				case "-o", "--output":
					output = args.shift();
				case "-f", "--format":
					format = args.shift();
			}
		}
	}
}
