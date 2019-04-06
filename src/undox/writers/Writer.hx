package undox.writers;

import undox.data.UType;
import sys.FileSystem;
import sys.io.File;

class Writer {

	private var path:String;

	public function new(path:String) {
		this.path = path;
	}

	public function write(context:Context):Void {
		FileSystem.createDirectory(path);
		var pwd = Sys.getCwd();
		Sys.setCwd(path);
		for (utypeDef in context.utypeDefs) writeUtypeDef(utypeDef);
		Sys.setCwd(pwd);
	}

	private function writeUtypeDef(utypeDef:UTypeDef):Void {
		switch (utypeDef.type) {
			case Class(def): writeClass(utypeDef, def);
			case Enum(def): writeEnum(utypeDef, def);
			case Type(def): writeType(utypeDef, def);
			case Abstract(def): writeAbstract(utypeDef, def);
		}
	}

	private function ufuncArgToString(arg:UFuncArg) {
		var l:String = "";
		if (arg.optional) l += "?";
		if (arg.name != "") l += arg.name + ":";
		l += utypeToString(arg.type);
		if (arg.defaultValue != null) l += " = " +arg.defaultValue;
		return l;
	}

	private function utypeToString(t:UType):String {
		return switch (t) {
			case Unknown:
				"unknown";
			case Path(utypeInst):
				utypeInstToString(utypeInst);
			case Function(ufuncInst):
				'(${ufuncInst.args.map(ufuncArgToString).join(", ")}) -> ${utypeToString(ufuncInst.ret)}';
			case Anon(fields):
				"{ " + fields.map(ufieldToString).join("") + " }";
		}
	}

	private function utypeInstToString(utypeInst:UTypeInst):String {
		var realName:String = utypeInst.path;
		if (utypeInst.params.length == 0) {
			return realName;
		}
		return realName + "<" + utypeInst.params.map(utypeToString).join(", ") + ">";
	}

	private function writeMeta(buf:StringBuffer, metas:Array<UMeta>) {
		for (meta in metas) {
			if (meta.params.length == 0) {
				buf += '@${meta.name}';
			} else {
				buf += '@${meta.name}(${meta.params.join(", ")})';
			}
		}
	}

	private function writeDoc(buf:StringBuffer, doc:UDoc) {
		if (doc != null) {
			buf >>= '/**';
			buf *= doc;
			buf <<= '*/';
		}
	}

	private function writeUField(buf:StringBuffer, field:UField) {
		var l:String = "";
		buf += '';
		buf += '/* ${field.raw} */';
		writeDoc(buf, field.doc);
		writeMeta(buf, field.meta);

		l += field.access.toString();
		var name = field.name;
		switch (field.field) {
			case UVar(type, defaultValue):
				l += ' var ${name}:${utypeToString(type)}';
				if (defaultValue != null) l += " = " + defaultValue;
				l += ";";
			case UProp(type, get, set, defaultValue):
				l += ' var ${name}($get, $set):${utypeToString(type)}';
				if (defaultValue != null) l += " = " + defaultValue;
				l += ";";
			case UFun(f):
				l += ' function ${name}(${f.args.map(ufuncArgToString).join(", ")}):${utypeToString(f.ret)};';
		}
		buf += l;
	}

	private function ufieldToString(field:UField):String {
		var buf:StringBuffer = 0;
		writeUField(buf, field);
		return buf.toString();
	}

	private function writeUEnumField(buf:StringBuffer, field:UEnumField) {
		var l:String = "";
		buf += '';
		buf += '/* ${field.raw} */';
		writeDoc(buf, field.doc);
		writeMeta(buf, field.meta);

		l += field.access.toString();
		var name = field.name;
		if (field.args.length == 0) {
			l += '${name};';
		} else {
			l += '${name}(${field.args.map(ufuncArgToString).join(", ")});';
		}
		buf += l;
	}

	private function writeClass(def:UTypeDef, classDef:UClassDef) {
		var buf:StringBuffer = 0;
		buf += 'package ${def.path.pack};';
		buf += '';
		writeDoc(buf, def.doc);
		writeMeta(buf, def.meta);
		var l = "";
		l += def.access.toString();
		if (l != "") l += " ";
		l += '${if (classDef.isInterface) "interface" else "class"} ${def.path.name}';
		if (def.params.length > 0) l += '<${def.params.join(", ")}>';
		if (classDef.superClass != null) {
			l += " extends " + utypeInstToString(classDef.superClass);
		}
		for (intf in classDef.interfaces) {
			l += " implements " + utypeInstToString(intf);
		}
		buf >>= l + " {";
		for (field in classDef.fields) {
			writeUField(buf, field);
		}
		buf <<= '}';
		File.saveContent(def.path.hxFile(), buf.toString());
	}

	private function writeEnum(def:UTypeDef, enumDef:UEnumDef) {
		var buf:StringBuffer = 0;
		buf += 'package ${def.path.pack};';
		buf += '';
		writeDoc(buf, def.doc);
		writeMeta(buf, def.meta);
		var l = "";
		l += def.access.toString();
		if (l != "") l += " ";
		l += 'enum ${def.path.name}';
		if (def.params.length > 0) l += '<${def.params.join(", ")}>';
		buf >>= '$l {';
		for (field in enumDef.fields) {
			writeUEnumField(buf, field);
		}
		buf <<= '}';
		File.saveContent(def.path.hxFile(), buf.toString());
	}

	private function writeType(def:UTypeDef, typeDef:UTypeAliasDef) {
		var buf:StringBuffer = 0;
		buf += 'package ${def.path.pack};';
		buf += '';
		writeDoc(buf, def.doc);
		writeMeta(buf, def.meta);

		var l = "";
		l += def.access.toString();
		if (l != "") l += " ";
		l += 'typedef ${def.path.name}';
		if (def.params.length > 0) l += '<${def.params.join(", ")}>';
		switch (typeDef.type) {
			case Anon(fields):
				buf >>= '$l = {';
				for (field in fields) {
					writeUField(buf, field);
				}
				buf <<= '};';
		case _:
			buf += '$l = ${utypeToString(typeDef.type)};';
		}
		File.saveContent(def.path.hxFile(), buf.toString());
	}

	private function writeAbstract(def:UTypeDef, abstractDef:UAbstractDef) {
		var buf:StringBuffer = 0;
		buf += 'package ${def.path.pack};';
		buf += '';
		writeDoc(buf, def.doc);
		writeMeta(buf, def.meta);
		var l = "";
		l += def.access.toString();
		if (l != "") l += " ";
		l += "abstract " + def.path.name;
		if (def.params.length > 0) l += '<${def.params.join(", ")}>';
		if (abstractDef.aThis != null) l += '(${utypeToString(abstractDef.aThis)})';
		for (from in abstractDef.implicitFrom) l += ' from ${utypeToString(from)}';
		for (to in abstractDef.implicitTo) l += ' to ${utypeToString(to)}';
		buf >>= '$l {';
		for (field in abstractDef.fields) {
			writeUField(buf, field);
		}
		buf <<= '}';
		File.saveContent(def.path.hxFile(), buf.toString());
	}
}
