REBOL [
	title: "Paint"
]

context [
	color: fill-color: type: start: draw-image: draw-pos: tmp: none
	undos: [] redos: []
	draw: func [offset /local tmp] [
		compose [
			pen (color/color) fill-pen (fill-color/color)
			(type) (start) (either type = 'circle [
				tmp: offset - start
				to-integer square-root add tmp/x ** 2 tmp/y ** 2
			] [offset])
		]
	]
	view lay: layout [
		backdrop effect compose [gradient 1x1 (sky) (water)]
		across
		draw-image: image white 300x300 effect [draw []]
		feel [engage: func [face action event] [
			if all [type start] [
				if find [over away] action [
					append clear draw-pos draw event/offset
					show face
				]
				if action = 'up [
					append/only undos draw-pos
					draw-pos: tail draw-pos
					start: none
				]
			]
			if all [type action = 'down] [
				start: event/offset
			]
		]]
		do [draw-pos: draw-image/effect/draw]
		guide
		style text text [
			tmp: first back find face/parent-face/pane face
			tmp/feel/engage tmp 'down none
			tmp/feel/engage tmp 'up none
		]
		label "Tool:" return
		radio [type: 'line] text "Line"
		return
		radio [type: 'box] text "Box"
		return
		radio [type: 'circle] text "Circle"
		return
		style color-box box 15x15 [
			face/color: either face/color [request-color/color face/color] [request-color]
		] ibevel
		color: color-box 0.0.0 text "Pen"
		return
		fill-color: color-box text "Fill-pen"
		return
		button "Undo" [if not empty? undos [
			append/only redos copy last undos
			draw-pos: clear last undos
			remove back tail undos
			show draw-image
		]]
		return
		button "Redo" [if not empty? redos [
			append/only undos draw-pos
			draw-pos: insert draw-pos last redos
			remove back tail redos
			show draw-image
		]]
	]
]