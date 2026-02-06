ghstack() {
	if [[ "$1" == "--up" || "$1" == "--down" ]]; then
		local target
		target=$(command ghstack "$@") || return $?
		if [[ -d "$target" ]]; then
			cd "$target"
		fi
	else
		command ghstack "$@"
	fi
}
