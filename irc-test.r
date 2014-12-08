REBOL []

sty: stylize [
   chat-txt: tt para [
	origin: 0x0
	margin: 0x0
   ]
   nick-txt: chat-txt with [flag-face self newline] red
   chat-box: box white ibevel 1x1 200.200.200 with [
	pane: []
	message-offset: 0x0
	wrap-pane: func [
		pane
		/offset offset-pos
		/local pos
	] [
		pos: either offset [offset-pos] [pane/1/offset]
		foreach f pane [
			if any [
				flag-face? f newline
				f/size/x + pos/x > size/x
			] [
				pos: pos * 0x1 + 5x12
			]
			f/offset: pos
			pos: f/size * 1x0 + pos
		]
		pos
	]
	append-message: func [
		msg [object!]
		channel
		/local pane data
	] [
		data: parse/all msg/params/1 " "
		forall data [
			data: insert data 'chat-txt
		]
		probe head data
		append self/pane pane: get in layout/styles append copy [
			at message-offset
			nick-txt rejoin ["<" msg/from ">"]
		] head data styles 'pane
		message-offset: wrap-pane pane
		show self
	]
   ]
]

