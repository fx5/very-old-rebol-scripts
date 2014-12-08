REBOL [
	title: "REBtroids"
	author: "Frank Sievertsen"
	version: 0.4.0
	date: 9-4-01
]
rebtroids: make object! [
    troid: none
    registered: []
    rotate: func [face [object!] /local degree len block] [
	block: next face/effect/draw
	foreach pos face/normal-pos [
		pos: pos - face/center
		degree: arcsine pos/x / len: square-root (pos/x ** 2) + (pos/y ** 2)
		if pos/y > 0 [degree: degree + 180]
		degree: degree + face/direction // 360 + 360 // 360
		pos/x: (sine degree) * len
		pos/y: (cosine 180 + degree) * len
		pos: pos + face/center
		block: change block pos
	]
    ]
    move: func [face [object!]] [
		face/direction: face/direction + face/rotate-speed // 360 + 360 // 360
		face/decimal-pos/1: face/decimal-pos/1 + face/speed/1
		face/decimal-pos/2: face/decimal-pos/2 + face/speed/2
		if face/decimal-pos/1 > win-max/1 [face/decimal-pos/1: face/decimal-pos/1 - win-calc/x]
		if face/decimal-pos/2 > win-max/2 [face/decimal-pos/2: face/decimal-pos/2 - win-calc/y]
		if face/decimal-pos/1 < win-min/1 [face/decimal-pos/1: face/decimal-pos/1 + win-calc/x]
		if face/decimal-pos/2 < win-min/2 [face/decimal-pos/2: face/decimal-pos/2 + win-calc/y]
		face/offset/x: face/decimal-pos/1
		face/offset/y: face/decimal-pos/2
		if face/die [
			face/die: face/die - 1
			if face/die < 0 [
				hide face
				remove find face/parent-face/pane face
				remove find registered face
			]
		]
    ]

    collision?: func [o1 [object!] o2 [object!] /local b1 b2 up] [
	if any [
		((o1/offset/x < o2/offset/x) <> ((o1/offset/x + o1/size/x) < o2/offset/x)) and
		((o1/offset/y < o2/offset/y) <> ((o1/offset/y + o1/size/y) < o2/offset/y))
		((o2/offset/x < o1/offset/x) <> ((o2/offset/x + o2/size/x) < o1/offset/x)) and
		((o2/offset/y < o1/offset/y) <> ((o2/offset/y + o2/size/y) < o1/offset/y))
	] [
		b1: next o1/effect/draw
		b2: next o2/effect/draw
		while [not empty? next b2] [
			if cutting?
				reduce [b1/1 + o1/offset b1/2 + o1/offset]
				reduce [b2/1 + o2/offset b2/2 + o2/offset]
			[return true]

			b1: next b1
			if empty? next b1 [
				b1: next head b1
				b2: next b2
			]
		]
	]
	false
    ]
    cutting?: func [
	a [block!]
	b [block!]
	/local s x m1 m2
    ] [
	if zero? a/1/x - a/2/x [
		a/1: reverse a/1
		b/1: reverse b/1
		a/2: reverse a/2
		b/2: reverse b/2
	]
	s: (a/2/y - a/1/y) / (a/2/x - a/1/x)
	all [
		((m1: b/1/x - a/1/x * s + a/1/y - b/1/y) < 0) <> ((m2: b/2/x - a/1/x * s + a/1/y - b/2/y) < 0)
		m1: absolute m1
		m2: absolute m2
		x: (b/1/x * m2) + (b/2/x * m1) / (m1 + m2)
		(x < a/1/x) <> (x < a/2/x)
	]
    ]
    resize: func [face [object!] value [number!] /local block p] [
	face/size: face/size * (value * 100) / 100
	block: face/normal-pos
	forall block [
		change block block/1 * (value * 100) / 100
	]
	head block
	p: 0x0
	foreach pos face/normal-pos [
		p: p + pos
	]
	face/center: p / length? face/normal-pos
    ]

    win-max: 450x450
    win-min: -50x-50
    win-calc: win-max - win-min

    register: func [face [object!]] [
	append registered face
    ]
    deregister: func [face [object!]] [
	remove find registered face
    ]


    troids-style: stylize [
	troid: box 21x21
	  effect [draw [line]]
	  with [
		troids-type: none
		direction: 0
		speed: [0 0]
		center: none
		rotate-speed: 0
		decimal-pos: none
		normal-pos: none
		die: none
		check: none
		init: [
			use [p] [
				p: 0x0
				foreach pos normal-pos [
					p: p + pos
				]
				center: p / length? normal-pos
			]
			decimal-pos: reduce [offset/x offset/y]
			rotate self
			register self
		]
	  ]
	ship: troid 21x21
	  with [
		troids-type: 'ship
		normal-pos: [10x0 15x20 5x20 10x0]
	  ]
        asteroid: troid 21x21
	  with [
		troids-type: 'asteroid
		normal-pos: [10x10 20x20 10x20 5x20 10x10]
		init: append init [
			speed/1: (random 50) - (random 50) / 30
			speed/2: (random 50) - (random 50) / 30
		]
		check: func [] [
			if collision? self ship [
				show-title
			]
			foreach bul parent-face/pane [
				if all [
					in bul 'troids-type
					'bullet = bul/troids-type
					collision? bul self
				] [
					resize self ,5
					either size/x < 10 [
						hide self
						remove find parent-face/pane self
						remove find registered self
					] [
						append parent-face/pane make self [
							speed: reduce [0 - speed/1 0 - speed/2]
							register self
						]
					]
					hide bul
					remove find parent-face/pane bul
					remove find registered bul
					show parent-face
					break
				]
			]
		]
	  ]
	bullet: troid 21x20
	  with [
		troids-type: 'bullet
		normal-pos: [10x1 10x20]
		die: 40
	  ]
    ]
    resize troids-style/asteroid 2.5
    ship: bd: none
    lay: layout [
	size 400x400
	styles troids-style
	s: sensor rate 20 feel [engage: func [face action event] [
	    if action = 'time [
		foreach face registered [
			rotate face
			move face
			face/check
			show face
		]
		if (length? registered) = 1 [start]
	    ]
	]] keycode [#" " left right up down] [if ship [
		switch value [
			left [ship/direction: ship/direction - 8 + 360 // 360]
			right [ship/direction: ship/direction + 8 // 360]
			up [
				ship/speed: reduce [
					ship/speed/1 + (sine ship/direction)
					ship/speed/2 + (cosine ship/direction + 180)
				]
			]
			#" " [
				append ship/parent-face/pane make troids-style/bullet [
					offset: ship/offset
					speed: reduce [
						ship/speed/1 + (5 * sine ship/direction)
						ship/speed/2 + (5 * cosine ship/direction + 180)
					]
					direction: ship/direction
					do init
				]
				show ship/parent-face
			]
		]
	]]
	bd: backdrop black
    ]
    lay-pos: tail lay/pane
    title: get in layout [
	banner 350 "REBtroid"
	H2 350 white "by Frank Sievertsen" center
	button "Start" 350 [start]
	h3 white "Preview Alpha Version"
    ] 'pane
    do show-title: func [] [
	ship: none
	level: 0
	clear lay-pos
	clear registered
	append lay-pos title
	show lay
    ]
    level: 0
    start: func [/local ] [
	clear lay-pos
	clear registered
	append lay-pos get in layout head insert/dup copy [styles troids-style
		at 200x200 ship: ship
	] 'asteroid to-integer (level: level + 1) * 3 'pane
	show lay
    ]
]
if none? system/script/args [
	view/title REBtroids/lay system/script/title
]