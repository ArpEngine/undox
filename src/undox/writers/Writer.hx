package undox.writers;

import sys.io.File;
import haxe.rtti.CType;
import sys.FileSystem;

class Writer {

	private var path:String;

	public function new(path:String) {
		this.path = path;
	}

	public function write(context:Context):Void {
		FileSystem.createDirectory(path);
		Sys.setCwd(path);
		for (data in context.data) writeData(data);
	}

	private function writeData(data:TypeTree):Void {
		switch (data) {
			case TPackage(_, _, subs): for (sub in subs) writeData(sub);
			case TClassdecl(c): writeClass(c);
			case TEnumdecl(e): writeEnum(e);
			case TTypedecl(t): writeType(t);
			case TAbstractdecl(a): writeAbstract(a);
		}
	}

	private function typePathToFilePath(typePath:Path):String {
		var filePath:String = typePath.split(".").join("/") + ".hx";
		var dir = new haxe.io.Path(filePath).dir;
		if (dir != null) FileSystem.createDirectory(dir);
		return filePath;
	}

	private function typePathToPack(typePath:Path):String {
		var p = typePath.split(".");
		p.pop();
		return p.join(".");
	}

	private function classPathToName(typePath:Path):String {
		var p = typePath.split(".");
		return p.pop();
	}

	private function functionArgumentName(arg:FunctionArgument) {
		var l:String = "";
		if (arg.opt) l += "?";
		if (arg.name != "") l += arg.name + ":";
		l += ctypeToString(arg.t);
		if (arg.value != null) l += " = " +arg.value;
		return l;
	}

	private function ctypeToString(t:CType):String {
		return switch (t) {
			case CUnknown:
				"unknown";
			case CClass(name, params), CEnum(name, params), CTypedef(name, params), CAbstract(name, params):
				nameWithParams(name, params);
			case CFunction(args, ret):
				if (args.length == 0) {
					"Void -> " +CTypeTools.toString(ret);
				} else {
					args.map(functionArgumentName).join(" -> ")+" -> "+CTypeTools.toString(ret);
				}
			case CDynamic(d):
				if (d == null) {
					"Dynamic";
				} else {
					"Dynamic<" + CTypeTools.toString(d) + ">";
				}
			case CAnonymous(fields):
				"{ " + fields.map(@:privateAccess CTypeTools.classField).join(", ") + " }";
		}
	}

	private function nameWithParams(name:String, params:Array<CType>) {
		var realName:String = name;
		if (params.length == 0) {
			return realName;
		}
		return realName + "<" + params.map(ctypeToString).join(", ") + ">";
	}

	private function writeMeta(buf:StringBuffer, metas:MetaData) {
		for (meta in metas) {
			if (meta.params.length == 0) {
				buf += '@${meta.name}';
			} else {
				buf += '@${meta.name}(${meta.params.join(", ")})';
			}
		}
	}

	private function writeDoc(buf:StringBuffer, doc:String) {
		if (doc != null) {
			buf >>= '/**';
			buf *= doc;
			buf <<= '*/';
		}
	}

	private function writeClassField(buf:StringBuffer, field:ClassField, isStatic:Bool = false) {
		var l:String = "";
		buf += '';
		buf += '/* ${Std.string(field)} */';
		writeDoc(buf, field.doc);
		writeMeta(buf, field.meta);

		var isInline:Bool = false;
		var isDynamic:Bool = false;
		var access = switch [field.get, field.set] {
			case [Rights.RNormal, Rights.RNormal]: "";
			case [Rights.RInline, Rights.RNo]: isInline = true; "";
			case [Rights.RNormal, Rights.RDynamic]: isDynamic = true; "";
			case _:
				var getAccess = switch (field.get) {
					case RNormal: 'default';
					case RNo: 'null';
					case RCall(_): 'get';
					case _: Std.string(field.get);
				}
				var setAccess = switch (field.set) {
					case RNormal: 'default';
					case RNo: 'null';
					case RCall(_): 'set';
					case _: Std.string(field.set);
				}
				'(${getAccess}, ${setAccess})';
		};

		l += if (field.isPublic) "public " else "private ";
		if (field.isOverride) l += "override ";
		if (isInline) l += "inline ";
		if (isDynamic) l += "dynamic ";
		if (field.isFinal) l += "final ";
		var isReallyStatic = isStatic;
		var realName = field.name;
		switch (field.type) {
			case CFunction(args, ret):
				var realArgs:Array<FunctionArgument> = args;
				if (isStatic) {
					if (realArgs.length > 0 && realArgs[0].name == "this") {
						realArgs = realArgs.copy();
						realArgs.shift();
						isReallyStatic = false;
					} else if (realName == "_new") {
						realName = "new";
						isReallyStatic = false;
					}
				}
				if (isReallyStatic) l += "static ";
				l += 'function ${realName}(${realArgs.map(functionArgumentName).join(", ")}):${ctypeToString(ret)};';
			case _:
				if (isReallyStatic) l += "static ";
				l += 'var ${realName}${access}:${ctypeToString(field.type)}';
				if (field.expr != null) l += " = " + field.expr;
				l += ";";
		}
		buf += l;
	}

	private function writeEnumField(buf:StringBuffer, field:EnumField) {
		var l:String = "";
		buf += '';
		buf += '/* ${Std.string(field)} */';
		writeDoc(buf, field.doc);
		writeMeta(buf, field.meta);
		var realName = field.name;
		if (field.args == null) {
			buf += '${field.name};';
		} else {
			buf += '${field.name}(${field.args.map(cast functionArgumentName).join(", ")});';
		}
	}

	private function writeClass(def:Classdef) {
		var buf:StringBuffer = 0;
		buf += 'package ${typePathToPack(def.path)};';
		buf += '';
		writeDoc(buf, def.doc);
		writeMeta(buf, def.meta);
		var l = "";
		if (def.isPrivate) l += "private ";
		l += if (def.isInterface) "interface " else "class ";
		l += classPathToName(def.path);
		if (def.superClass != null) {
			l += " extends " + nameWithParams(def.superClass.path, def.superClass.params);
		}
		for (intf in def.interfaces) {
			l += " implements " + nameWithParams(intf.path, intf.params);
		}
		buf >>= l + " {";
		for (field in def.fields) {
			writeClassField(buf, field);
		}
		for (fStatic in def.statics) {
			writeClassField(buf, fStatic, true);
		}
		buf <<= '}';
		File.saveContent(typePathToFilePath(def.path), buf.toString());
	}

	private function writeEnum(def:Enumdef) {
		var buf:StringBuffer = 0;
		buf += 'package ${typePathToPack(def.path)};';
		buf += '';
		writeDoc(buf, def.doc);
		writeMeta(buf, def.meta);
		buf >>= 'enum ${classPathToName(def.path)} {';
		for (field in def.constructors) {
			buf += '${field.name};';
		}
		buf <<= '}';
		File.saveContent(typePathToFilePath(def.path), buf.toString());
	}

	private function writeType(def:Typedef) {
		var buf:StringBuffer = 0;
		buf += 'package ${typePathToPack(def.path)};';
		buf += '';
		writeDoc(buf, def.doc);
		writeMeta(buf, def.meta);
		switch (def.type) {
			case CAnonymous(fields):
				buf >>= 'typedef ${classPathToName(def.path)} = {';
				for (field in fields) {
					writeClassField(buf, field);
				}
				buf <<= '};';
		case _:
			buf += 'typedef ${classPathToName(def.path)} = ${ctypeToString(def.type)};';
		}
		File.saveContent(typePathToFilePath(def.path), buf.toString());
	}

	private function writeAbstract(def:Abstractdef) {
		var buf:StringBuffer = 0;
		buf += 'package ${typePathToPack(def.path)};';
		buf += '';
		writeDoc(buf, def.doc);
		writeMeta(buf, def.meta);
		var aThis:CType = def.athis;
		var implicitTo:CType = null;
		var implicitFrom:CType = null;
		for (from in def.from) if (from.field == null) implicitFrom = from.t;
		for (to in def.to) if (to.field == null) implicitTo = to.t;
		var l = "abstract " + classPathToName(def.path);
		if (aThis != null) l += '(${ctypeToString(def.athis)})';
		if (implicitFrom != null) l += ' from ${ctypeToString(implicitFrom)}';
		if (implicitTo != null) l += ' to ${ctypeToString(implicitTo)}';
		buf >>= '$l {';
		if (def.impl != null) {
			for (field in def.impl.fields) {
				writeClassField(buf, field);
			}
			for (fStatic in def.impl.statics) {
				writeClassField(buf, fStatic, true);
			}
		}
		buf <<= '}';
		File.saveContent(typePathToFilePath(def.path), buf.toString());
	}
}
