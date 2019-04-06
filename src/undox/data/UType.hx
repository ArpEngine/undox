package undox.data;

@:structInit
private class UPathImpl {
	public var pack:String;
	public var module:String;
	public var name:String;

	public function toString():String {
		if (module == "") return name;
		return (if (pack != "") '$pack.' else "") + module + (if (module != name) '.$name' else "");
	}
}

@:forward(pack, module, name, toString)
abstract UPath(UPathImpl) {
	inline private function new(impl:UPathImpl) this = impl;

	@:from
	private static function fromString(value:String):UPath {
		var p = value.split(".");
		p = p.map(s -> ~/^_/.replace(s, ""));
		var name = p.pop();
		var module = if (p.length > 0 && p[p.length - 1].charCodeAt(0) < 0x60) {
			p.pop();
		} else {
			name;
		}
		var pack = p.join(".");
		switch (name) {
			case "K" | "V" | "X" | "W" | "Hit" | "T":
				module = "";
		}
		return new UPath({ pack: pack, module: module, name: name });
	}

	@:to
	public function toString():String return this.toString();
}

abstract URaw(String) from String to String { }

abstract UDoc(String) from String to String { }

@:structInit
class UMeta {
	public var name:String;
	public var params:Array<String>;
}

enum UType {
	Unknown;
	Path(p:UTypeInst);
	Function(f:UFuncInst);
	Anon(fields:Array<UField>);
	// Extend(p:Array<UTypeInst>, fields:Array<UField>);
	// Intersection(tl:Array<UType>);
}

@:structInit
class UTypeInst {
	public var path:UPath;
	public var params:Array<UType>;
}

@:structInit
class UFuncInst {
	public var args:Array<UFuncArg>;
	public var ret:UType;
}

@:structInit
class UFuncArg {
	public var name:String;
	public var optional:Bool;
	public var type:UType;
	public var defaultValue:String;
}

abstract UAccess(Array<UAccessMod>) from Array<UAccessMod> to Array<UAccessMod> {
	public function toString() {
		return this.map(mod -> switch mod {
			case Private: "private";
			case Public: "public";
			case Static: "static";
			case Override: "override";
			case Dynamic: "dynamic";
			case Inline: "inline";
			case Extern: "extern";
			case Final: "final";
		}).join(" ");
	}
}

enum UAccessMod {
	Private;
	Public;
	Static;
	Override;
	Dynamic;
	Inline;
	Extern;
	Final;
}

@:structInit
class UTypeDef {
	public var platform:String;
	public var path:UPath;
	public var params:Array<UPath>;
	public var raw:URaw;
	public var doc:UDoc;
	public var meta:Array<UMeta>;
	public var access:UAccess;
	public var type:UTypeKind;
}

enum UTypeKind {
	Class(def:UClassDef);
	Enum(def:UEnumDef);
	Type(def:UTypeAliasDef);
	Abstract(def:UAbstractDef);
}

@:structInit
class UClassDef {
	public var superClass:UTypeInst;
	public var interfaces:Array<UTypeInst>;
	public var isInterface:Bool;
	public var fields:Array<UField>;
}

@:structInit
class UEnumDef {
	public var fields:Array<UEnumField>;
}

@:structInit
class UTypeAliasDef {
	public var type:UType;
}

@:structInit
class UAbstractDef {
	public var implicitFrom:Array<UType>;
	public var implicitTo:Array<UType>;
	public var aThis:UType;
	public var fields:Array<UField>;
}

@:structInit
class UField {
	public var name:String;
	public var raw:URaw;
	public var doc:UDoc;
	public var meta:Array<UMeta>;
	public var access:UAccess;
	public var field:UFieldKind;
}

enum UFieldKind {
	UVar(type:UType, defaultValue:String);
	UProp(type:UType, get:String, set:String, defaultValue:String);
	UFun(f:UFuncInst);
}

@:structInit
class UEnumField {
	public var name:String;
	public var raw:URaw;
	public var doc:UDoc;
	public var meta:Array<UMeta>;
	public var access:UAccess;
	public var args:Array<UFuncArg>;
}

