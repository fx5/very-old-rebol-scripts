REBOL [
	title: "Lego-View"
	author: "Frank Sievertsen"
	version: 1.0.0
]

do-nothing: yes

view/new layout [
	title "Hole Programm aus dem Netz..."
]

context [
	do-thru: func [url [url!]] [
		if connected? [request-download url]
		do load-thru url
	]
	do-thru http://proton.cl-ki.uni-osnabrueck.de/REBOL/lego.r
	do-thru http://proton.cl-ki.uni-osnabrueck.de/REBOL/lego-test.r
	do-thru http://proton.cl-ki.uni-osnabrueck.de/REBOL/form-error.r

	unview/all

	real-port: none
	real-portnum: none
	busy-face: none
	busy: func [info] [
	   if none? busy-face [
		append lay/pane busy-face: make face [
			color: none
			effect: [blur blur blur blur blur multiply 100.100.100] 
			size: lay/size offset: 0x0
			font: make font [size: 30 color: 255.255.100 valign: 'middle]
		]
		show lay
	   ]
	   busy-face/text: info
	   show busy-face
	]
	ready: does [if busy-face [hide busy-face]]

	port: func [/local win] [
		if real-portnum <> index? port-choice/data [
			busy "Initialisiere Cybermaster"
			real-portnum: 0
			if real-port [close real-port]
			real-port: none
			real-port: open join lego://port index? port-choice/data
			real-portnum: index? port-choice/data
			insert real-port [init]
			wait 2
		]
		system/words/port: :real-port
		real-port
	]
	act-error: func [block /local e] [
		if error? set/any 'e try block [
			inform layout [
				title "Fehler" area form-error e
				button "Ok" [hide-popup]
			]
		]
		ready
	]
	prg: port-choice: f1: f2: f3: f4: none
	print "Download Window"
 	view lay: layout [
		origin 5
		backdrop effect compose [gradient 1x1 (sky) (aqua)]
		title "Lego-Programm"
		prg: area 600x250 (join mold/only programm "^/^/")

		across

		port-choice: choice data system/ports/serial
		button "Download" [
		    act-error [
			port
			busy "Downloading..."
			insert port load prg/data
		    ]
		]
		button "Init" [
		    act-error [
			real-portnun: 0
			port
		    ]
		]
		
		return
		button "Stop" [act-error [port stop]]
		return
		f1: field "0" button "Move" [act-error [port move to-decimal f1/data]]
		return
		f2: field "0" button "Turn" [act-error [port turn to-decimal f2/data]]
		return
		f3: field "0" f4: field "0"
		return 
		button "Kurve FW" [act-error [
			port curve-fw to-decimal f3/data to-decimal f4/data
		]]
		button "Kurve RW" [act-error [
			port curve-rw to-decimal f3/data to-decimal f4/data
		]]
	]
	if real-port [
		close real-port
	]
]
