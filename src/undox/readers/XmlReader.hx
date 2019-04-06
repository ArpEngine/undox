package undox.readers;

import undox.data.UType;
import haxe.rtti.CType;
import haxe.io.Path;
import sys.io.File;

class XmlReader {

	private var platform:String;
	private var context:Context;

	public function new(platform:String, context:Context) {
		this.platform = platform;
		this.context = context;
	}

	public static function readXml(path:String, context:Context):Void {
		var platform = new Path(path).file;
		var xml = Xml.parse(File.getContent(path)).firstElement();

		var reader:XmlReader = new XmlReader(platform, context);
		var parser:XmlParser = new XmlParser();
		parser.process(xml, platform);
		reader.readTypeRoot(parser.root);
	}

	public function readTypeRoot(typeRoot:TypeRoot):Void {
		for (typeTree in typeRoot) readTypeTree(typeTree);
	}

	private function isAbstractImpl(path:String):Bool {
		var packs = path.split(".");
		for (p in packs) if (StringTools.startsWith(p, "_")) return StringTools.endsWith(path, "_Impl_");
		return false;
	}

	private function readTypeTree(t:TypeTree):Void {
		switch (t) {
			case TPackage(_, _, subs):
				for (sub in subs) readTypeTree(sub);
			case TClassdecl(def):
				if (isAbstractImpl(def.path)) return;
				context.utypeDefs.push(XmlReaderTools.classdefToUTypeDef(def));
			case TEnumdecl(def):
				if (isAbstractImpl(def.path)) return;
				context.utypeDefs.push(XmlReaderTools.enumdefToUTypeDef(def));
			case TTypedecl(def):
				if (isAbstractImpl(def.path)) return;
				context.utypeDefs.push(XmlReaderTools.typedefToUTypeDef(def));
			case TAbstractdecl(def):
				if (isAbstractImpl(def.path)) return;
				context.utypeDefs.push(XmlReaderTools.abstractdefToUTypeDef(def));
		}
	}
}
