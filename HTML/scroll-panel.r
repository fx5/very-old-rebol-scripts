REBOL [] 

scroll-panel-style: stylize [
	panel-slider: slider feel [
		old-redraw: :redraw
		redraw: func [face act pos /local dir tmp pmin pmax panel psize] [
			if all [
				panel: face/to-panel
				none? face/to-vals
			] [
				pmin: pmax: panel/pane/1/offset
				foreach face panel/pane [
					pmin: min pmin face/offset
					pmax: max pmax face/offset + face/size
				]
				psize: pmax - pmin + 40x40
				dir: either face/size/x > face/size/y ['x] ['y]
				face/to-vals: reduce [0 psize dir]
				face/state: none face/data: 0
				face/redrag 1 - (psize/:dir - panel/size/:dir / panel/size/:dir)
			]
			old-redraw face act pos
		]
	] with [
		to-vals: none
		words: reduce [
			'to func [new args] [
				new/to-panel: args/2
				if not object? args/2 [
					make error! [script expect-arg "to" "panel" "face"]
				]
				if any [
					none? new/to-panel/pane
					object? new/to-panel/pane
					empty? new/to-panel/pane
				] [
					new/to-panel: new/to-panel/parent-face
				]
				next next args
		]	]
		init: head insert copy init [bind/copy action 'self]
		to-panel: to-vals: none
		action: [ if to-vals [use [moved psize dir move] [
			set [moved psize dir] to-vals
			move: to-integer - data * (psize/:dir - to-panel/size/:dir) - moved
			foreach face to-panel/pane [
				either dir = 'x [
					face/offset/x: face/offset/x + move
				] [
					face/offset/y: face/offset/y + move
				]
				show face
			]
			to-vals/1: moved + move
		]]]
	]
]
{

EXAMPLE: 

view layout [
	styles scroll-panel-style
	across space 0x0
	p: panel 400x300 [
		title "Hallo" h1 "ARGHHHHHHHHHHHHHHHHHHHHHHHHHHHHH"
		title "Sie"
		title "Da"
		across
		field "Test Feld" field "Noch eins" field "Ein weiteres"
	]
	panel-slider 15x300 to p
	return panel-slider 400x15 to p
	below
	title "yes"
]






}







