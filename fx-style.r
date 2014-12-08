REBOL [
]

fx-style-words: []

fx-update-word: func [word [word!] /local pos /without face] [
	pos: fx-style-words
	while [pos: find pos word] [
		if all [same? pos/1 word not same? face pos/2] [
			pos/2/fx-update pos/2
			if pos/2/type = 'face [show pos/2]
		]
		pos: next pos
	]
]

fx-on-update: func [word [word!] block [block!]] [
	repend fx-style-words [
		word
		make object! [
			type: 'on-update
			fx-update: does block
		]
	]
]

fx-set-between: func [word [word!] low hi] [
	insert fx-style-words reduce [
		word
		make object! [
			type: 'between
			w: word
			l: low
			h: hi
			fx-update: does compose [
				set w min max get w l h
			]
		]
	]
]

fx-styles: stylize [
    fx-set-field: field rate 1 with [
	words: append copy words [
		type [ use [tmp] [
			set [tmp args] do/next next args
			if not datatype? :tmp [
				make error! [user message "type requires datatype"]
			]
			new/datatype: tmp
			back args
		]]
		word [
			new/word: args/2
			if not word? args/2 [
				make error! [user message "word requires word"]
			]
			repend fx-style-words [new/word new]
			next args
		]
		max-value [
			new/max-value: args/2
			if not number? args/2 [
				make error! [user message "max-value requires number"]
			]
			next args
		]
		min-value [
			new/min-value: args/2
			if not number? args/2 [
				make error! [user message "min-value requires number"]
			]
			next args
		]
	]
	init: bind head insert init [
		if none? datatype [datatype: type? get word]
		if none? text [text: mold get word]
	] 'insert
	min-value: max-value: none
	datatype: none
	word: none
	fx-update: func [face] [
		insert clear face/text mold get word
	]
    ] [use [tmp] [
	error? try [
		tmp: to face/datatype face/data
		if face/datatype = type? tmp [set face/word tmp]
	]
	if face/min-value [set face/word max get face/word face/min-value]
	if face/max-value [set face/word min get face/word face/max-value]
	insert clear face/data mold get face/word
	fx-update-word face/word
    ]]

    fx-get-text: text feel [
	redraw: func [face] [
		if none? face/text [face/text: copy ""]
		insert clear face/text mold get face/word
	]
    ] with [
	words: [
		word [
			new/word: args/2
			if not word? args/2 [
				make error! [user message "word requires word"]
			]
			repend fx-style-words [new/word new]
			next args
		]
	]
	word: none
	fx-update: none
    ] 



    fx-set-slider: slider with [
	words: [
		type [ use [tmp] [
			set [tmp args] do/next next args
			if not datatype? :tmp [
				make error! [user message "type requires datatype"]
			]
			new/datatype: tmp
			back args
		]]
		word [
			new/word: args/2
			if not word? args/2 [
				make error! [user message "word requires word"]
			]
			repend fx-style-words [new/word new]
			next args
		]
		max-value [
			new/max-value: args/2
			if not number? args/2 [
				make error! [user message "max-value requires number"]
			]
			next args
		]
		min-value [
			new/min-value: args/2
			if not number? args/2 [
				make error! [user message "min-value requires number"]
			]
			next args
		]
	]
	max-value: 10
	min-value: 0
	word: none
	datatype: integer!
	init: insert copy init [
		fx-update self
	]
	fx-update: func [face] [
		face/data: (get word) - min-value / (max-value - min-value)
	]
    ] [
	unfocus
	set face/word to face/datatype face/max-value - face/min-value * value + face/min-value
	fx-update-word/without face/word face
    ]
    fx-slider-button: button 20x20 with [
	words: [
	    up down left right [
		new/data: args/1
		args
	    ]
	    word [
		new/word: args/2
		next args
	    ]
	    value [
		new/value: args/2
		next args
	    ]
	]
	data: 'up
	slider: none
	word: none
	value: 1
	init: head insert copy init [
		if none? effect [effect: copy []]
		insert effect compose [
			arrow rotate ((index? find [up right down left] data) - 1 * 90)
		]
	]
    ] feel [
	engage: func [face action event] [
		switch action [
		    down [
			face/state: on
			(face/action face 'down)
			face/rate: 5
			show face
		    ]
		    up [
			face/state: off
			face/rate: none
			show face
		    ]
		    time [
			if face/state [face/action face 'time]
		    ]
		]
	]
    ] [use [fun tmp] [
	fun: either find [left up] face/data [:subtract] [:add]
	either all [pair? get face/word not pair? face/value] [
		tmp: either find [left right] face/data [1x0] [0x1]
		set face/word fun (get face/word) tmp * face/value
		fx-update-word face/word
	] [
		set face/word fun (get face/word) face/value
		fx-update-word face/word
	]
    ]]
    fx-get-progress: progress with [
	min-value: 0
	max-value: 1
	word: none
	words: [
	    word [
		new/word: args/2
		repend fx-style-words [new/word new]
		next args
	    ]
	]
	fx-update: func [face] [
		face/data: (get word) - face/min-value / (face/max-value - face/min-value)
	]
	init: append copy init [
		fx-update self
	]
    ]
]

print "Ok"
use [p i pos mrk] [
	fx-set-between 'i 0 10
	fx-set-between 'p 0x0 100x100
	p: 10x10
	i: 10
	view layout [
		styles fx-styles
		fx-set-field word 'p type pair!
		fx-set-field word 'p type pair!
		fx-get-text word 'p 100
		fx-get-text word 'p 100
		pad 10
		fx-set-field word 'i
		fx-set-field word 'i
		pad 10
		fx-get-text word 'i 100
		fx-get-text word 'i 100

		across
		fx-set-slider word 'i
		fx-set-slider word 'i
		pos: at
		below
		return
		panel 110x110 0.0.0 [ at p
			mrk: image 255.255.255 10x10 with [
			   fx-update: func [face] [
				face/offset: p
			   ]
			] feel [engage: func [face action event] [
			    switch action [
				down [face/data: event/offset]
				up [face/data: none]
			    ]
			    if all [face/data find [over away] action] [
				p: face/offset - face/data + event/offset
				fx-update-word 'p
			    ]
			]]
			do [repend fx-style-words ['p mrk]]
		] feel [engage: func [face action event] [
		    if action = 'down [p: event/offset - 5x5 fx-update-word 'p]
		]]
		across
		origin pos
		at pos
		text "Integer:" 50
		fx-slider-button left word 'i
		fx-slider-button right word 'i
		fx-slider-button up word 'i
		fx-slider-button down word 'i
		return
		text "Pair:" 50
		fx-slider-button left word 'p value 5
		fx-slider-button right word 'p value 5
		fx-slider-button up word 'p value 5
		fx-slider-button down word 'p value 5
		return
		fx-get-progress word 'i with [min-value: 0 max-value: 10]
		return
		fx-get-progress word 'i with [min-value: 0 max-value: 10]
		return
		button "Output" [print [i p]]
	]
]
