REBOL []

;do http://proton.cl-ki.uni-osnabrueck.de/REBOL/lego.r
do %lego.r

programm: [
	name #receive1 var 31
	name #receive var 0
	name #id 2
	name #decode1 var 28
	name #decode2 var 27

	name #command var 26
	name #arg1 var 25
	name #arg2 var 24


	task all delete
	sub all delete

	name #count var 10
	; sub 0 [
	; 	play tone 1000 50
	; 	wait 100
	; 	loop #count [
	; 		play tone 900 10
	; 		wait 50
	; 	]
	; 	wait 200
	; ]

	sub 1 [
		set #arg1 * 32 + #arg2
		set #arg2 #arg1
	]

	task 0 [ ; Dekodieren und Task 1 starten
	    forever [
	    	set #receive1 #receive
	    	set #decode2 0
		if #receive1 < 0 [
			set #decode2 1
			set #receive1 * -1
		]
		set #decode1 #receive1 and 7   ; Die ersten drei Bits holen
		if #decode1 = #id [
			; Nachricht für mich
			play tone 800
			set #receive 0
			task 1 stop
			set #arg2 #receive1 / 64 and 31
			set #arg1 #receive1 / 2048 and 15
			if #decode2 = 1 [
				set #arg1 + 16
			]
			set #command #receive1 / 8 and 7
			task 1 start
		]
	    ]
	]

	name #kurve 0
	name #kurve-reverse 1
	;		name #kurve-drehen 2
	;		name #kurve-drehen-reverse 3
	name #other 2
	name #drehen 4
	name #drehen-reverse 5
	name #vorwärts 6
	name #rückwärts 7

	name #right var 1
	name #left var 2
	name #start-left var 3
	name #start-right var 4

	name #tmp var 6
	name #tmp2 var 5

	name #geteilt-arg1 var 7
	name #geteilt-arg2 var 8

	name #tacho-left motor tacho 0
	name #tacho-right motor tacho 1

	task 1 [
		motor both forward
		if #command = #kurve-reverse [
			motor both backward
		]
		if #command = #other [
		 	goto ende
		]
		; if #command = #kurve-drehen-reverse [
		; 	motor left backward
		; ]
		if #command = #drehen-reverse [
			motor left backward
			goto drehen
		]
		if #command = #rückwärts [
			motor both backward
			goto vorwärts
		]
		if #command = #vorwärts [
			vorwärts:
			sub 1 call
			goto kurve-real
		]
		if #command = #drehen [
			motor right backward
			drehen: 
			sub 1 call           ; Argumente zusammenbauen
			goto kurve-real
		]

		kurve:

		set #arg1 * #arg1	; Groessere Werte, weil zu wenig Bits bei zwei Argumenten
		set #arg2 * #arg2

		kurve-real:

		set #left #tacho-left + #arg1
		set #right #tacho-right + #arg2
		set #start-left #tacho-left
		set #start-right #tacho-right
		set #geteilt-arg1 #arg1 / 10
		set #geteilt-arg2 #arg2 / 10

		motor both speed 6 on
		forever [
			set #tmp  #tacho-left  - #start-left * 10 / #geteilt-arg1
			set #tmp2 #tacho-right - #start-right * 10 / #geteilt-arg2
			set #tmp - #tmp2
			if #tmp > -1 [ ; Links genug
				motor right on
				if #tmp > 0 [
				    either #tmp > 1 [
					motor left off
				    ] [
					motor left float
				    ]
				]
			]
			if #tmp < 1 [ ; Rechts genug
				motor left on
				if #tmp < 0 [
				    either #tmp < -1 [
					motor right off
				    ] [
					motor right float
				    ]
				]
			]
			if #tacho-left > #left [
				if #tacho-right >= #right goto ende
			]
		]
		ende:
		motor both off
	]
	task 0 start
]

if not value? 'do-nothing [

	error? try [close port]

	if not value? 'port-num [
		port-num: "port1"
	]

	port: open join lego:// port-num

	insert port [init]
	wait 2 
	insert port programm
]

lego-test1: does [
	forever [
		move 100
		wait 3
		move -100
		wait 3
	]
]
lego-test2: does [
	forever [
		move 100
		wait 2
		turn 180
		wait 1
	]
]

lego-command: func [command [integer!] arg1 [integer!] arg2 [integer!] /local x] [
	x: arg2 * 32 + arg1 * 8 + command * 8 + 2
	if not zero? x and (to-integer 2 ** 15) [
		x: - (x - (to-integer 2 ** 15))
	]
	insert port compose [set var 0 (x)]
]

turn: func [x [number!]] [
	lego-command either negative? x [4] [5] absolute to-integer x 0
]

move: func [x [number!]] [
	lego-command either negative? x [6] [7] absolute to-integer x 0
]

stop: does [
	lego-command 2 0 0
]

curve-rw: func [x [number!] y [number!]] [
	x: to-integer ,5 + square-root x
	y: to-integer ,5 + square-root y
	lego-command 0 x y
]

curve-fw: func [x [number!] y [number!]] [
	x: to-integer ,5 + square-root x
	y: to-integer ,5 + square-root y
	lego-command 1 x y
]
