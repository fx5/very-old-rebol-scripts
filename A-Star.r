REBOL []

context [

do load-thru http://proton.cl-ki.uni-osnabrueck.de/REBOL/fx5-styles.r

out-box: none
opened: copy []
closed: copy []
highlight: copy []
again: none

mode: "New"
use-heuristic: yes

view/new/title layout [
	styles fx5-styles backdrop
	across
	h2 "A*"
	choice "New" "Move" "Delete" "Connect" "Start Point" "End Point"
		[mode: value/1 connect: none]
	h3 "Use heuristic"
	check on [use-heuristic: value]
	below
	out-box: box 500x300 white feel [
		engage: func [f a e] [
		    if all [a = 'down   mode = "New"] [
			new-ball e/offset
		    ]
		]
	] with [pane: []] effect [draw []] font [
		size: 10 color: red align: 'left valign: 'top shadow: 1x1
	]
	across
	button "Clear" [
		clear out-box/pane
		clear connections
		clear balls
		start-point: end-point: none
		show-connections
		show out-box
	]
	button "Start" [if all [start-point end-point] [
		out-box/text: none
		clear highlight
		a* start-point end-point :edge :heuristic
		show out-box
	]]
	button "Step" [use [tmp] [
		if not 8 = tmp: do does [do again 8] [
			out-box/text: either tmp [highlight: tmp/2 "Found"] ["Not found"]
		]
		show out-box
	]]
] "A*"

ball-num: 0
ball: none
balls: copy []
tmp: none
connect: none
start-point: none
end-point: none
connections: copy []

layout [
	ball: box 10x10 effect [draw [fill-pen 255.0.0 pen 0.0.0
		circle 5x5 4
	]] font [
		color: white
		size: 10
		shadow: none
		align: 'center
		valign: 'middle
	] with [color: none ball-num: none state: none] feel [
	    redraw: func [f] [
		f/effect/draw/fill-pen: 80.80.80
		f/effect/draw/pen: 0.0.0
		if all [mode = "Connect" connect = f] [
			f/effect/draw/pen: 255.255.0
		]
		f/text: none
		if start-point = f [
			f/text: "S"
		]
		if end-point = f [
			f/text: "E"
		]
		if find closed f [
			f/effect/draw/fill-pen: 255.0.0
		]
		if find opened f [
			f/effect/draw/fill-pen: 0.255.0
		]
		if find highlight f [
			f/effect/draw/fill-pen: 0.0.255
		]
	    ]
	    engage: func [f a e] [
		if all [find [over away] a f/state] [
			f/offset: f/offset - f/state + e/offset
			show-connections
			show f/parent-face
		]
		if a = 'up [f/state: none]
		if a = 'down [
		    switch mode [
			"Move" [f/state: e/offset]
			"Delete" [use [pos] [
			    remove any [find f/parent-face/pane f ""]
			    pos: connections
			    while [not empty? pos] [
				either any [pos/1 = f pos/2 = f] [
					remove/part pos 2
				] [
					pos: skip pos 2
				]
			    ]
			    show-connections
			    show f/parent-face
			]]
			"Connect" [
			    either connect [
				either not any [
				    tmp: find/skip connections reduce [connect f] 2
				    tmp: find/skip connections reduce [f connect] 2
				] [ if connect <> f [
					repend connections [
				    		connect f
					]
				]] [remove/part tmp 2]
				connect: none
			    ] [
				connect: f
			    ]
			    show-connections
			    show f/parent-face
			]
			"Start Point" [
			    start-point: f
			    show f/parent-face
			]
			"End Point" [
			    end-point: f
			    show f/parent-face
			]			
		    ]
		]
	    ]
	]
]

new-ball: func [offset /local tmp] [
	append out-box/pane tmp: make ball []
	tmp/offset: offset - 5x5
	tmp/ball-num: ball-num: ball-num + 1
	append balls tmp
	show out-box
]

show-connections: func [/local draw draw2 diff] [
	draw: clear out-box/effect/draw
	draw2: copy [pen 0.0.0]
	append draw [pen 255.0.0]
	foreach [c1 c2] connections [
		repend draw ['line c1/offset + 5x5   c2/offset + 5x5]
		diff: c2/offset - c1/offset
		diff: square-root (diff/x ** 2) + (diff/y ** 2)
		diff: to-integer diff + ,5
		repend draw2 ['text (c1/offset + c2/offset / 2) form diff]
	]
	append draw draw2
]

heuristic: func [
	node
	/local tmp
] [
	if not use-heuristic [return 0]
	tmp: end-point/offset - node/offset
	square-root (tmp/x ** 2) + (tmp/y ** 2)
]

edge: func [
	node
	/local dat diff
] [
	dat: copy []
	foreach [c1 c2] connections [
		diff: c1/offset - c2/offset
		if c1 = node [repend dat [
			c2	square-root (diff/x ** 2) + (diff/y ** 2)
		]]
		if c2 = node [repend dat [
			c1	square-root (diff/x ** 2) + (diff/y ** 2)
		]]
	]
	dat
]



    A*: func [
	"A* search"

	start "Start node"
	end "End node"

	expand [any-function!] "Expand function, must reply block of [node costs]"
	heuristic [any-function!] "Heuristic function, given a node"

	/target
		is-target? [any-function!]
	/local
;		opened
;		closed
		best
		tmp
    ] [
	opened: reduce [start reduce [
		(heuristic start)	; f=g+h
		0			; g
		none			; mother
		copy []			; daughters
		start			; "Name"
	]]
	closed: copy []
	if not target [is-target?: func [node] [node = end]]
	again: [
		sort/reverse/skip/compare opened 2 [2]
		if empty? opened [
			return none
		]
		best: back back tail opened
		if is-target? best/1 [use [out out2] [
			out2: reduce [best/2/2 out: copy []]
			while [best] [
				append out best/1
				all [
					best: best/2/3
					best: find closed best
				]
			]
			reverse out
			return out2
		]]
		foreach [node costs] expand best/1 [catch/name [
			costs: best/2/2 + costs
			if tmp: find/skip closed node 2 [
				if costs < tmp/2/2 [
					update-all tmp/2 best/2 costs
					append/only best/2/4 tmp/2
				]
				throw/name none 'continue
			]
			if tmp: find/skip opened node 2 [
				if costs < tmp/2/2 [
					update-all tmp/2 best/2 costs
					append/only best/2/4 tmp/2
				]
				throw/name none 'continue
			]
			repend opened [
				node tmp: reduce [
					(costs + heuristic node)
					costs
					best/1
					copy []
					node
				]
			]
			append/only best/2/4 tmp
		] 'continue]
		insert/part tail closed best 2
		remove/part best 2
	]
	
    ]

    update-all: func [node [block!] from [block!] costs [number!] /local better] [
	if all [
		node/3 <> from/5
		node/2 > costs 
	] [
		better: node/2 - costs
		node/1: costs + node/1 - node/2
		node/2: costs
		node/3: from/5
		foreach suc node/4 [
			update-all suc node suc/2 - better
		]
	]
    ]


do-events

]


