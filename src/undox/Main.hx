package undox;

import undox.writers.XmlWriter;
import undox.writers.HxWriter;
import undox.readers.XmlReader;

class Main {

	public static function main():Void {
		new Main().run();
	}

	public function new() return;

	public function run():Void {
		var args = new Args();
		var context = new Context();
		for (xml in args.xmls) XmlReader.readXml(xml, context);
		switch (args.format) {
			case "xml":
				new XmlWriter(args.output).write(context);
			case _:
				new HxWriter(args.output).write(context);
		}
	}
}
