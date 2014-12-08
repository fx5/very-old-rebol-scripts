REBOL [
	title: "scroll-list-style"
	author: "Frank Sievertsen"
	version: 1.0.0
]

  scroll-list-style: stylize [
    scroll-list: list with [
	the-slider: none
	slider-moved: 0x0
	items: 10
	max-scroll: does [
		max 0 items * old-subface/size/y - face/size/y + (2 * face/edge/size/y)
	]
	old-data-func: select words 'data
	words/data: func [new args] [
		new/items: length? second args
		new/old-data-func new args
	]
	old-subface: none
	append init [
		the-slider: first get in layout/styles [at 0x0
			slider (size * 0x1 + 15x0) [slider-moved/y: to-integer value * max-scroll show self]
		] styles 'pane
		append subface/pane the-slider
		subface/size: min subface/size size - 15x0
		old-subface: make subface []
		the-slider/redrag size/y / (size/y + max-scroll)
		pane: func [face id /local count spane][
		    if pair? id [
			if id/x >= (size/x - 15) [return 1]
			return 2 + second id + slider-moved / subface/size
		    ]
		    if id = 1 [
			subface/offset: subface/old-offset: size * 1x0 - 15x0
			subface/size: subface/old-size: the-slider/size
			foreach face subface/pane [face/show?: no]
			set in last subface/pane 'show? yes
			return subface
		    ]
		    subface/size: subface/old-size: old-subface/size
		    foreach face subface/pane [face/show?: yes]
		    set in last subface/pane 'show? no
		    ; insert clear subface/pane old-subface/pane
		    id: id - 1
		    subface/offset: subface/old-offset: id - 1 * subface/size * 0x1 - slider-moved
		    if subface/offset/y > size/y [return none]
		    count: 0
		    foreach item subface/pane [
		        if object? item [
		            subfunc item id count: count + 1
		        ]
		    ]
		    subface
		]
	]
    ]
  ]
