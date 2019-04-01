package undox;

import undox.writers.Writer;
import undox.readers.XmlReader;

class Main {

	public static function main():Void {
		new Main().run();
	}

	public function new() return;

	public function run():Void {
		var args = new Args();
		var context = new Context();
		for (xml in args.xmls) new XmlReader(xml).read(context);
		new Writer(args.output).write(context);
	}
}
