package undox.writers;

import haxe.xml.Printer;
import sys.FileSystem;
import sys.io.File;
import undox.data.UType;

class XmlWriter {

	private var path:String;
	private var document:Xml;
	private var haxeXml:Xml;

	public function new(path:String) {
		this.path = path;
	}

	public function write(context:Context):Void {
		this.document = Xml.createDocument();
		this.haxeXml = Xml.createElement("haxe");
		this.document.addChild(this.haxeXml);
		for (utypeDef in context.utypeDefs) {
			writeUTypeDef(utypeDef);
		}
		var dir = new haxe.io.Path(path).dir;
		if (dir != null) FileSystem.createDirectory(dir);
		File.saveContent(path, Printer.print(this.document, true));
	}

	private function writeUTypeDef(utypeDef:UTypeDef):Void {
		switch (utypeDef.type) {
			case Class(def): writeClass(utypeDef, def);
			case Enum(def): writeEnum(utypeDef, def);
			case Type(def): writeType(utypeDef, def);
			case Abstract(def): writeAbstract(utypeDef, def);
		}
	}

	private function writeAccess(xml:Xml, access:Array<UAccessMod>):Void {
		for (mod in access) {
			switch mod {
				case Private:
					xml.set("private", "1");
				case Public:
					xml.set("public", "1");
				case Static:
					xml.set("static", "1");
				case Override:
					xml.set("override", "1");
				case Dynamic:
					xml.set("set", "dynamic");
				case Inline:
					xml.set("get", "inline");
					xml.set("set", "null");
				case Extern:
					xml.set("extern", "1");
				case Final:
					// TODO
			}
		}
	}

	private function writeDoc(xml:Xml, doc:UDoc):Void {
		if (doc != null) {
			var haxeDoc = Xml.createElement("haxe_doc");
			haxeDoc.addChild(Xml.createCData(doc));
			xml.addChild(haxeDoc);
		}
	}

	private function writeUTypeInst(xml:Xml, p:UTypeInst) {
		xml.set("path", p.path);
		for (param in p.params) writeUType(xml, param);
	}

	private function writeUFuncInst(xml:Xml, fun:UFuncInst) {
		var f:Xml = Xml.createElement("f");
		f.set("a", fun.args.map(arg -> arg.name).join(":"));
		for (arg in fun.args) {
			writeUType(f, arg.type);
		}
		writeUType(f, fun.ret);
		xml.addChild(f);
	}

	private function writeUType(xml:Xml, utype:UType):Void {
		switch (utype) {
			case Unknown:
				xml.addChild(Xml.createElement("unknown"));
			case Path(p):
				var c:Xml = Xml.createElement("c");
				writeUTypeInst(c, p);
				xml.addChild(c);
			case Function(fun):
				writeUFuncInst(xml, fun);
			case Anon(fields):
				var a:Xml = Xml.createElement("a");
				for (field in fields) writeField(a, field);
				xml.addChild(a);
		}
	}

	private function writeField(xml:Xml, field:UField):Void {
		var node:Xml = Xml.createElement(field.name);
		switch (field.field) {
			case UVar(type, defaultValue):
				writeUType(node, type);
			case UProp(type, get, set, defaultValue):
				writeUType(node, type);
				switch get {
					case "null": node.set("get", "null");
					case "get": node.set("get", "accessor");
					case _:
				}
				switch set {
					case "null": node.set("set", "null");
					case "set": node.set("set", "accessor");
					case _:
				}
			case UFun(fun):
				writeUFuncInst(node, fun);
		}
		writeAccess(node, field.access);
		if (node.get("set") == null) node.set("set", "method");
		writeDoc(node, field.doc); // must be after type
		xml.addChild(node);
	}

	private function writeEnumField(xml:Xml, field:UEnumField):Void {
		var node:Xml = Xml.createElement(field.name);
		writeAccess(xml, field.access);
		writeDoc(xml, field.doc);
	}

	private function writeClass(def:UTypeDef, classDef:UClassDef):Void {
		var xml:Xml = Xml.createElement("class");
		xml.set("path", def.path.toString());
		xml.set("params", def.params.map(x -> x.toString()).join(":"));
		writeAccess(xml, def.access);
		writeDoc(xml, def.doc);
		if (classDef.isInterface) xml.set("interface", "1");
		if (classDef.superClass != null) {
			var extend:Xml = Xml.createElement("extends");
			writeUTypeInst(extend, classDef.superClass);
			xml.addChild(extend);
		}
		for (intf in classDef.interfaces) {
			var implement:Xml = Xml.createElement("implements");
			writeUTypeInst(implement, intf);
			xml.addChild(implement);
		}
		for (field in classDef.fields) writeField(xml, field);
		haxeXml.addChild(xml);
	}

	private function writeEnum(def:UTypeDef, enumDef:UEnumDef):Void {
		var xml:Xml = Xml.createElement("enum");
		xml.set("path", def.path.toString());
		xml.set("params", def.params.map(x -> x.toString()).join(":"));
		writeAccess(xml, def.access);
		writeDoc(xml, def.doc);
		for (field in enumDef.fields) writeEnumField(xml, field);
		haxeXml.addChild(xml);
	}

	private function writeType(def:UTypeDef, typeDef:UTypeAliasDef):Void {
		var xml:Xml = Xml.createElement("typedef");
		xml.set("path", def.path.toString());
		xml.set("params", def.params.map(x -> x.toString()).join(":"));
		writeAccess(xml, def.access);
		writeDoc(xml, def.doc);
		writeUType(xml, typeDef.type);
		haxeXml.addChild(xml);
	}

	private function writeAbstract(def:UTypeDef, abstractDef:UAbstractDef):Void {
		var xml:Xml = Xml.createElement("abstract");
		xml.set("path", def.path.toString());
		xml.set("params", def.params.map(x -> x.toString()).join(":"));
		writeAccess(xml, def.access);
		writeDoc(xml, def.doc);
		if (abstractDef.implicitFrom.length > 0) {
			var from:Xml = Xml.createElement("from");
			for (implicitFrom in abstractDef.implicitFrom) {
				var icast:Xml = Xml.createElement("icast");
				writeUType(icast, implicitFrom);
				from.addChild(icast);
			}
			xml.addChild(from);
		}
		if (abstractDef.aThis != null) {
			var thiss:Xml = Xml.createElement("this");
			writeUType(thiss, abstractDef.aThis);
			xml.addChild(thiss);
		}
		if (abstractDef.implicitFrom.length > 0) {
			var to:Xml = Xml.createElement("to");
			for (implicitTo in abstractDef.implicitTo) {
				var icast:Xml = Xml.createElement("icast");
				writeUType(icast, implicitTo);
				to.addChild(icast);
			}
			xml.addChild(to);
		}
		var impl:Xml = Xml.createElement("impl");
		var implClass:Xml = Xml.createElement("class");
		implClass.set("path", def.path.toString() + "_Impl_"); // FIXME
		implClass.set("params", def.params.map(x -> x.toString()).join(":"));
		for (field in abstractDef.fields) writeField(implClass, field);
		xml.addChild(impl);
		impl.addChild(implClass);
		haxeXml.addChild(xml);
	}
}
