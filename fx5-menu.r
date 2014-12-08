REBOL [
	title: "View Menu"
	author: "Frank Sievertsen"
	date: 19-7-01/16:35
	version: 1.0.0
	purpose: "Adds a grafical menu to a window or a face"
]


context [

menu-i-styles: stylize [
	menu-item: txt "" with [
		pane-size: 900x900
		colors: reduce [180.180.250 none]
		append init [state: no]
		state: no
		menu-description: none
		menu-action: none
		init: [
			size: 900x900
			size: (size-text self) + para/origin + para/margin
		]
		para: make para [
			marin: origin: 4x2
		]
	]
	feel [
		redraw: func [face] [
			face/color: pick face/colors face/state
		]
		over: func [face action event] [
			face/state: action
			show face
		]
		engage: func [face action event] [
			switch action [
				down [
					unview-menu
					face/menu-action face
					if face/menu-description [
						unview-menu
						view-menu face
					]
				]
				away [
					over face no event
				]
				over [
					over face yes event
				]
			]
		]
	]
]

; Menu-Functions

menu: none

unview-menu: func [] [
	if menu [
		remove find menu/parent-face/pane menu
		show menu/parent-face
		menu: none
	]
]

view-menu: func [face /local tmp] [
	append face/parent-face/parent-face/pane menu: make system/words/face [
		dirty?: yes
	]
	menu/edge: make menu/edge [
		effect: 'bevel
		color: 200.200.200
		size: 1x1
	]
	menu/color: none
	menu/effect: [
		gradmul 0x1 245.245.245 245.245.245
		multiply 100.100.100
		gradcol 0x1 140.127.127 127.140.127
	]
	menu/offset: face/offset + 0x20 + face/parent-face/offset
	build-menu/below menu face/menu-description
	menu/size: 1x1
	menu/size/x: face/size/x
	foreach item menu/pane [
		menu/size: max menu/size item/offset + item/size
	]
	foreach item menu/pane [
		item/size/x: menu/size/x
	]
	menu/size: menu/size + 2x2
	show face/parent-face/parent-face
	unfocus
	system/view/focal-face: menu
	menu/action: func [face value] [
		unview-menu
	]
]

; LOCAL PARSE - VARS
t1: t2: t3: t4: none
name: none
out-block: none
out-face: none
offset: 0x0

direction: 1x0

; PARSE - RULES
menu-data: [
	(offset: 0x0)
	any menu-item
]
menu-item: [
	set name string!
	(out-face: make menu-i-styles/menu-item [])
	(out-face/text: copy name)
	(out-face/offset: offset)
	any menu-options
	(do out-face/init)
	(offset: out-face/size * direction + offset)
	(append out-block out-face)
	|
	'--- (
		append out-block t1: make face [size: 10x3 edge: make edge [
			effect: 'ibevel
			size: 1x1
			color: none
			color: 200.200.200
		]]
		t1/offset: offset
		offset: t1/size * direction + offset
	)
]
menu-options: [
	'sub set t1 block! (
		out-face/menu-description: t1
	)
	| set t1 block! (
		out-face/menu-action: func [face] t1
	)
]

; Help function
build-menu: func [face [object!] descr [block!] /below] [
	face/pane: out-block: copy []
	direction: either below [0x1] [1x0]
	if not parse compose descr [
		menu-data
	] [
		make error! "menu-parse error"
	]
]

system/words/menu-styles: stylize [
	menu: box 1x1 with [
		append init: init [
			size: 1x1
			build-menu self second :action
		]
		words: [
			sub [
				print "sub"
			]
		]
	] feel [
		engage: none
		redraw: func [face] [
			face/offset: -1x-1
			face/size: face/parent-face/size + 10x1
			face/size/y: 20
		]
	]
	edge [effect: 'bevel size: 1x1 color: 200.200.200] 
]

]
