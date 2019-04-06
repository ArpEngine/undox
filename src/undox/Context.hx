package undox;

import undox.data.UType;

class Context {

	public var utypeDefs(default, null):Array<UTypeDef>;

	public function new() {
		this.utypeDefs = [];
	}
}
