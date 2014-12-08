#!/home/fx5/xper/rebol
REBOL []

vektoren: []
k: 3
d: 2

fuzzy-k-means: load-thru http://proton.cl-ki.uni-osnabrueck.de/fuzzy-k-means.r

use [event-port bild runner size t1 t2 t3 gif punkt] [
	gif: make image! [8x8 #{
		FFFFFFFFFFFF0000FF0000FF0000FF0000FFFFFFFFFFFFFFFFFFFF0000FF
		0000FF0000FF0000FF0000FF000000FFFFFF0000FF0000FF0000FF0000FF
		0000FF0000FF0000FFFFFFFF0000FF0000FF0000FF0000FF0000FF0000FF
		0000FF0000000000FF0000FF0000FF0000FF0000FF0000FF0000FF000000
		FFFFFF0000FF0000FF0000FF0000FF0000FF000000FFFFFFFFFFFF0000FF
		0000FF0000FF0000FF000000000000FFFFFFFFFFFFFFFFFFFFFFFF000000
		000000FFFFFFFFFFFFFFFFFF
	}]
	layout [punkt: image gif effect [key 255.255.255]]
	size: 300x300
	view/new layout [
	    title "fuzzy-k-means" 255.255.0
	    subtitle "von Frank Sievertsen" 255.255.0
	    bild: image (size) 255.255.255 feel [
		engage: func [face action event /local x y] [
		    if all [action = 'down not runner/data] [
			x: event/offset/x y: event/offset/y
			change at bild/image (bild/image/size/x) * y + x 0.0.0
			show bild
			repend/only vektoren [x / bild/image/size/x y / bild/image/size/y]
			show t3
		    ]
		]
	    ]
	    across
	    runner: toggle "Run" [
		if vektoren = [] [face/data: face/state: false show face exit]
		show face
		catch/name [
		    if value [
			clear bild/pane
			loop k [append bild/pane make punkt []]
			do fuzzy-k-means
		    ]
		] 'runner
	    ]
	    button "Clear" [
		if not runner/data [
			clear vektoren
			clear bild/pane
			change/dup bild/image #{ffffff00} (length? bild/image) / 4
			show bild
			show t3
		]
	    ]
	    return text "Klassen:" 100 text "d:" 100 text "Vektoren:" 100
	    return
		t1: text "3" 100 center
		t2: text "2" 100 center
		t3: text "0" 100 center feel [
			redraw: func [face] [
				insert clear face/text length? vektoren
		]	]
	    return
	    slider 100x15 with [data: 0.2] [
		if runner/data [
			face/data: k / 10 - 0.1
			show face/pane
			exit
		]
		k: to-integer value + 0.1 * 10
		insert clear t1/text k
		show t1
	    ]
	    slider 100x15 [
		d: value * 10 + 2
		insert clear t2/text d
		show t2
	    ]
	    return
	]

	bild/image: make image! bild
	bild/pane: copy []
	event-port: open [scheme: 'event]
	to-do: func [/local x y n] [
		while [wait [0 event-port]] [
			do first event-port
			if not runner/data [throw/name none 'runner]
		]
		n: 0
		foreach v v [
			v: first v
			n: n + 1
			x: to-integer v/1 * bild/size/x
			y: to-integer v/2 * bild/size/y
			bild/pane/:n/offset: (to-pair reduce [x y]) - 4x4
		]
		show bild
		if empty? system/view/screen-face/pane [quit]
		recycle
	]
	do-events
]
