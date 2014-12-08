REBOL []


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
	menu/effect: [gradmul 0x1 255.255.255 230.230.230 multiply 100.100.100]
	menu/offset: face/offset + 0x20 + face/parent-face/offset
	build-menu/below menu face/menu-description [
		"Neu"
		"Öffnen"
		"Speichern"
		"Speichern unter..."
	]
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
	if not parse descr [
		menu-data
	] [
		make error! "menu-parse error"
	]
]

system/words/menu-styles: stylize [
	menu: box 1x1 200.200.200 with [
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
	edge [effect: 'bevel size: 1x1 color: 150.150.150] 
]

]

; TEST -------------

unview/all

view/options layout [
	styles menu-styles

	; backdrop 200.200.200
	h1 "Hallo"
	h1 "Hallo"
	h1 "Hallo"
 	menu [
		"Datei" sub [
			"Öffnen" [request-file]
			---
			"Schließen" [quit]
			---
			"Speichern"
			"Speichern unter..."
			"Beenden" [quit]
		]
		"Bearbeiten" sub [
			"Ausschneiden"
			"Kopieren"
			"Einfügen"
		]
		"Suchen" sub [
			"Suchen nach.."
			"Ersetzen..."
		]
		"?" sub [
			"Info" [
				inform layout [
					h1 "Copyright by Frank Sievertsen"
					button "Ok" [hide-popup]
				]
			]
		]
	] return
	panel 200x300 [
		menu [
			"Test" sub ["It" "works!"]
			"That's" sub ["Cool"]
			"Quit" [quit]
		]
	]
] [resize]
