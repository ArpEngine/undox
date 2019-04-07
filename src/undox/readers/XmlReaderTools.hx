package undox.readers;

import haxe.io.Path;
import haxe.rtti.CType;
import undox.data.UType;

class XmlReaderTools {

	public static function toUField(classField:ClassField, isStatic:Bool):UField {
		var access = [];
		var isInline:Bool = false;
		var isDynamic:Bool = false;
		var isVar:Bool = false;
		var get:String;
		var set:String;

		var name = classField.name;

		switch [classField.get, classField.set] {
			case [RInline, RNo]:
				isInline = true;
			case [RNormal, RDynamic]:
				isDynamic = true;
			case _:
		};

		var fieldKind = switch [classField.type, classField.get, classField.set] {
			case
				[CFunction(args, ret), RNormal, RMethod] |
				[CFunction(args, ret), RInline, RNo] |
				[CFunction(args, ret), RNormal, RDynamic]:
				var realArgs:Array<FunctionArgument> = args;
				if (isStatic) {
					if (realArgs.length > 0 && realArgs[0].name == "this") {
						realArgs = realArgs.copy();
						realArgs.shift();
						isStatic = false;
					} else if (name == "_new") {
						name = "new";
						isStatic = false;
					}
				}
				UFun(toUFuncInst(realArgs, ret));
			case
				[_, RNormal, RNormal] |
				[_, RInline, RNo]:
				UVar(toUType(classField.type), classField.expr);
			case _:
				get = switch (classField.get) {
					case RNormal: 'default';
					case RNo: 'null';
					case RCall(_): 'get';
					case _: Std.string(classField.get);
				}
				set = switch (classField.set) {
					case RNormal: 'default';
					case RNo: 'null';
					case RCall(_): 'set';
					case _: Std.string(classField.set);
				}
				UProp(toUType(classField.type), get, set, classField.expr);
		};

		if (!classField.isPublic) access.push(Private);
		if (classField.isPublic) access.push(Public);
		if (isStatic) access.push(Static);
		if (classField.isOverride) access.push(Override);
		if (isDynamic) access.push(Dynamic);
		if (isInline) access.push(Inline);
		if (classField.isFinal) access.push(Final);

		return {
			name: name,
			doc: classField.doc,
			srcDoc: classField.doc,
			raw: toURaw(classField),
			meta: toUMeta(classField.meta),
			access: access,
			field: fieldKind
		}
	}

	public static function toUEnumField(enumField:EnumField):UEnumField {
		var args = if (enumField.args == null) {
			[];
		} else {
			enumField.args.map(arg -> ({
				name: arg.name,
				optional: arg.opt,
				type: toUType(arg.t),
				defaultValue: null
			}:UFuncArg));
		}

		return {
			name: enumField.name,
			doc: enumField.doc,
			srcDoc: enumField.doc,
			raw: toURaw(enumField),
			meta: toUMeta(enumField.meta),
			access: [],
			args: args
		}
	}

	public static function assumeUFuncInst(ctype:CType):UFuncInst {
		return switch(ctype) {
			case CFunction(args, ret): toUFuncInst(args, ret);
			case _: { args: [], ret: Unknown }
		}
	}

	public static function toUType(ctype:CType):UType {
		return switch(ctype) {
			case CUnknown: Unknown;
			case
				CEnum(name, params) |
				CClass(name, params) |
				CTypedef(name, params) |
				CAbstract(name, params):
					Path(toUTypeInst({path: name, params: params}));
			case CFunction(args, ret):
				Function(toUFuncInst(args, ret));
			case CAnonymous(fields):
				Anon(fields.map(field -> toUField(field, false)));
			case CDynamic(t):
				if (t == null) {
					Path(toUTypeInst({ path: "Dynamic", params: [] }));
				} else {
					Path(toUTypeInst({ path: "Dynamic", params: [t] }));
				}
		}
	}

	public static function toUTypeInst(pathParams:PathParams):UTypeInst {
		var path = pathParams.path;
		var params = pathParams.params.map(toUType);

		// try demangle generics
		/*
		if (path.split(".").pop().indexOf("_") > 0) {
			var p = path.split(".").join("_").split("_");
			var genericPath:Array<String> = [];
			var genericPaths:Array<String> = [];
			for (c in p) {
				genericPath.push(c);
				if (c.charCodeAt(0) < 0x60) {
					genericPaths.push(genericPath.join("."));
					genericPath = [];
				}
			}
			if (genericPaths.length > 0) {
				return {
					path: genericPaths.shift(),
					params: genericPaths.map(p -> Path({ path: p, params: [] }))
				}
			}
		}
		*/
		// end try demangle

		return {
			path: path,
			params: params
		}
	}

	public static function toUFuncInst(args:Array<FunctionArgument>, ret:CType):UFuncInst {
		return {
			args: args.map((fa:FunctionArgument) -> ({
				name: fa.name,
				optional: fa.opt,
				type: toUType(fa.t),
				defaultValue: fa.value
			}:UFuncArg)),
			ret: toUType(ret)
		}
	}

	public static function toUMeta(meta:MetaData):Array<UMeta> {
		return meta.filter(data -> data.name != ":build" && data.name != ":autoBuild").map(data -> ({ name: data.name, params: data.params }:UMeta));
	}

	public static function toURaw(raw:Dynamic):URaw {
		return Std.string(raw);
	}

	public static function classdefToUTypeDef(def:Classdef):UTypeDef {
		var access:Array<UAccessMod> = [];
		if (def.isPrivate) access.push(Private);
		// if (!def.isPrivate) access.push(Public);
		if (def.isExtern) access.push(Extern);
		var fields:Array<UField> = [];
		var superClass = if (def.superClass != null) toUTypeInst(def.superClass) else null;
		var interfaces = def.interfaces.map(XmlReaderTools.toUTypeInst);
		for (field in def.fields) {
			fields.push(toUField(field, false));
		}
		for (field in def.statics) {
			fields.push(toUField(field, true));
		}
		return {
			platform: def.platforms[0],
			path: def.path,
			params: def.params.map(s -> (s:UPath)),
			doc: def.doc,
			srcDoc: def.doc,
			raw: toURaw(def),
			meta: toUMeta(def.meta),
			access: access,
			type: UTypeKind.Class({
				isInterface: def.isInterface,
				superClass: superClass,
				interfaces: interfaces,
				fields: fields
			})
		};
	}

	public static function enumdefToUTypeDef(def:Enumdef):UTypeDef {
		var access:Array<UAccessMod> = [];
		if (def.isPrivate) access.push(Private);
		// if (!def.isPrivate) access.push(Public);
		if (def.isExtern) access.push(Extern);
		var fields:Array<UEnumField> = [];
		for (field in def.constructors) {
			fields.push(toUEnumField(field));
		}
		return {
			platform: def.platforms[0],
			path: def.path,
			params: def.params.map(s -> (s:UPath)),
			doc: def.doc,
			srcDoc: def.doc,
			raw: toURaw(def),
			meta: toUMeta(def.meta),
			access: access,
			type: UTypeKind.Enum({
				fields: fields
			})
		}
	}

	public static function typedefToUTypeDef(def:Typedef):UTypeDef {
		var access:Array<UAccessMod> = [];
		if (def.isPrivate) access.push(Private);
		// if (!def.isPrivate) access.push(Public);
		return {
			platform: def.platforms[0],
			path: def.path,
			params: def.params.map(s -> (s:UPath)),
			doc: def.doc,
			srcDoc: def.doc,
			raw: toURaw(def),
			meta: toUMeta(def.meta),
			access: access,
			type: UTypeKind.Type({ type: toUType(def.type) })
		};
	}

	public static function abstractdefToUTypeDef(def:Abstractdef):UTypeDef {
		var access:Array<UAccessMod> = [];
		if (def.isPrivate) access.push(Private);
		// if (!def.isPrivate) access.push(Public);

		var aThis:UType = null;
		var implicitTo:Array<UType> = [];
		var implicitFrom:Array<UType> = [];
		var fields:Array<UField> = [];

		for (from in def.from) if (from.field == null) implicitFrom.push(toUType(from.t));
		for (to in def.to) if (to.field == null) implicitTo.push(toUType(to.t));

		if (def.athis != null) aThis = toUType(def.athis);

		if (def.impl != null) {
			for (field in def.impl.fields) {
				fields.push(toUField(field, false));
			}
			for (field in def.impl.statics) {
				fields.push(toUField(field, true));
			}
		}
		return {
			platform: def.platforms[0],
			path: def.path,
			params: def.params.map(s -> (s:UPath)),
			doc: def.doc,
			srcDoc: def.doc,
			raw: toURaw(def),
			meta: toUMeta(def.meta),
			access: access,
			type: UTypeKind.Abstract({
				aThis: aThis,
				implicitFrom: implicitFrom,
				implicitTo: implicitTo,
				fields: fields
			})
		}
	}
}
