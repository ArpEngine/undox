package undox;

import haxe.rtti.XmlParser;
import haxe.rtti.CType;

class Context {

	private var impl:ContextImpl;

	public var data(get, never):TypeRoot;
	private function get_data():TypeRoot return impl.root;

	public function new() {
		this.impl = new ContextImpl();
	}

	public function mergeXml(xml:Xml, platform:String) {
		this.impl.process(xml, platform);
	}
}

private class ContextImpl extends XmlParser {
}
