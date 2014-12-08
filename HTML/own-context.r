REBOL []

own-context: func [
	blk [block!]
	/without blk2 [block!]
	/local context
] [
	context: copy []
	if not without [blk2: []]
	foreach e blk [
		if all [
			set-word? :e
			:e <> to-set-word 'self
			not find context :e
			not find blk2 to-word :e
		] [
			append context :e
		]
	]
	append context none
	context: make object! context
	blk: bind/copy blk in context 'self
	insert blk context ; This prevents REBOL from crashing :)
]