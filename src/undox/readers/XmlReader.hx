package undox.readers;

import haxe.io.Path;
import sys.io.File;

class XmlReader {

	private var path:String;

	public function new(path:String) {
		this.path = path;
	}

	public function read(context:Context):Void {
		var xml = Xml.parse(File.getContent(path)).firstElement();
		context.mergeXml(xml, new Path(path).file);
	}
}
