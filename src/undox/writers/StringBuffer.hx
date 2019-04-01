package undox.writers;

abstract StringBuffer(StringBufferImpl) {

	inline private function new(impl:StringBufferImpl) this = impl;

	@:op(a+b)
	public function opAdd(lines:String):StringBuffer {
		this.writeLines(lines);
		return new StringBuffer(this);
	}

	@:op(a*b)
	public function opAmp(line:String):StringBuffer {
		this.writeLine(line);
		return new StringBuffer(this);
	}

	@:op(a<<b)
	public function opUnindent(lines:String):StringBuffer {
		this.indent(-1);
		this.writeLines(lines);
		return new StringBuffer(this);
	}

	@:op(a>>b)
	public function opIndent(lines:String):StringBuffer {
		this.writeLines(lines);
		this.indent(1);
		return new StringBuffer(this);
	}

	@:from
	public static function fromInt(_:Int):StringBuffer {
		return new StringBuffer(new StringBufferImpl());
	}

	@:to
	public function toString():String return this.toString();
}
