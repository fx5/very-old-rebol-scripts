REBOL [
	title: "Lego CYBERMASTER Control"
	author: "Frank Sievertsen"
	version: 0.9.2
	date: 21-12-00
	history: [
		0.9.2 21-12-00 [
			"Bugfixing: parsing of subblocks"
			"Better error handling"
		]
		0.9.1 21-12-00 [
			"Implemented full command-set"
		]
	]
	usage: {
		Try this:

		do http://proton.cl-ki.uni-osnabrueck.de/REBOL/lego.r

		port: open lego://port1   ; For serial port 1 (or 0)

		insert port [motor both forward speed 6 on]
			; Turn on both motors forward with speed 6

		insert port [motor both off]
			; Turn both motors off

		insert port [task 0 [
			motor both forward speed 6 on
			wait 100
			motor both off
		] ]	; Define a task

		insert port [task 0 start]


		Have a look at the examples at
			http://proton.cl-ki.uni-osnabrueck.de/REBOL/lego-examples.r
	}

	comment: {
		You may find this useful for Linux:
		insert clear system/ports/serial [cua0 cua1]
	}
]



lego: make object! [
	quiet: no  ; Set this to yes for no prints
	out: copy []
	pos: none
	names: copy []
	mode: copy []
	markers: copy []
	bytes: 0
	iprint: func [sth] [
		if not quiet [print sth]
	]
	
	tmp: tmp2: none

	cmd: func [code [block! binary!]] [
		repend/only out code
	]
	low: func [i [integer!]] [
		i and 255
	]
	high: func [i [integer!]] [
		i and (255 * 256) / 256
	]
	get-length: func [block /local count] [
		count: 0
		foreach b block [count: count + length? b]
		count
	]
	lock-mode: func ['word [word!]] [
		if find mode word [
			make error! compose [user message (join "not allowed here:" word)]
		]
		append mode word
	]
	free-mode: func ['word [word!]] [
		remove find mode word
	]
	
	root: [
		(clear out) 
		(clear mode)
		(clear markers)
		some command
	]

	code: [
		any command end 
		| (make error! [user message "parse error"]) to end
	]

	command: [
		pos:
		init 
		| motor
		| name
		| set-cmd
		| binary
		| wait-cmd
		| task
		| play
		| power 
		| program
		| marker
		| goto
		| while-cmd
		| if-cmd
		| forever-cmd
		| for-cmd
		| subroutine
		| clear-cmd
		| datalog
		| loop-cmd
	]

	init: [ 'init (
		cmd to-binary replace/all [254 0 0 255 165  90  68  187  111  144  32  223  121  134  111  144  117  138  32  223  98  157  121  134  116  139  101 - 154 - 44
		- 211 - 32 - 223 - 119 - 136 - 104 - 151 - 101 - 154 - 110 - 145 - 32 - 223 - 73 - 182 - 32 - 223 - 107 - 148 - 110 - 145 - 111 - 144 - 99 - 156 - 107 - 148 - 63 -
		192 - 133 - 122] '- [])
	]
	int-tmp: none
	integer: [
		set tmp integer!
		| set int-tmp issue! (
			if not tmp: select names int-tmp [
				make error! compose [user message (join "Not defined:" int-tmp)]
			]
			if tmp/1 <> 2 [make error! [user message "Only constants allowed here"]]
			tmp: to-integer tmp/3 * 255 + tmp/2
		)
	]
	int-tmp2: none
	integer2: [
		(int-tmp2: tmp)
		integer
		(tmp2: tmp tmp: int-tmp2)
		| (tmp: int-tmp2)
	]
	motor: [
		'motor some [motors some [
			  ['on | 'start] (cmd [33 128 or motor-dat])
			| ['off | 'stop] (cmd [33 64 or motor-dat])
			| ['float] (cmd [33 motor-dat])
			| ['speed | 'power] source
				(cmd [19 motor-dat source-dat1 source-dat2])
			| 'forward
				(cmd [225 motor-dat or 128])
			| 'backward
				(cmd [225 motor-dat])
			| ['change | 'flip] opt 'direction
				(cmd [225 motor-dat or 64])
		]]
	]

	motor-dat: none
	motors: [(motor-dat: 0) some [
		'all (motor-dat: 1 + 2 + 4)
		| integer (motor-dat: motor-dat or to-integer 2 ** (tmp - 1))
		| 'left (motor-dat: motor-dat or 1)
		| 'right (motor-dat: motor-dat or 2)
		| 'extern (motor-dat: motor-dat or 4)
		| 'both (motor-dat: motor-dat or 3)
	]]
	
	cmp-dat1: cmp-dat2: cmp-dat3: cmp-dat4: cmp-dat5: cmp-not: none

	neg-comparator: [
		; force (if possible) a not
		comparator
		(
			if all [
				not cmp-not
				(to-integer cmp-dat1 / 64) > 1
			] [
				cmp-dat1: cmp-dat1 xor 64
				cmp-not: yes
			]
			if all [
				not cmp-not
				(to-integer cmp-dat1 / 64) <= 1
				cmp-dat1 and 63 = 2
			] [
				cmp-dat3: cmp-dat3 + either zero? cmp-dat1 and 64 [-1] [1]
				cmp-dat1: cmp-dat1 xor 64
				cmp-not: yes
			]
		)
	]

	pos-comparator: [
		; doesn't allow nots
		comparator
		(
			if cmp-not [make error! [user message "< and > not allowed here"]]
		)
	]

	comparator: [
		source copy-source
		compare-sign
		source
		(
			if 2 = source-dat1 [
				tmp: source-copy1
				tmp2: source-copy2
				source-copy1: source-dat1
				source-copy2: source-dat2
				source-copy3: source-dat3
				source-dat1: tmp
				source-dat2: tmp2
				if cmp-dat1 < 2 [
					cmp-dat1: cmp-dat1 xor 1
				]
			]
			if 2 = source-dat1 [
				 make error! [user message "Illegal comparator constant <=> constant"]
			]
			cmp-dat1: cmp-dat1 * 64 + source-copy1
			cmp-dat2: source-dat1
			cmp-dat3: source-copy2
			cmp-dat4: source-copy3
			cmp-dat5: source-dat2
		)
	]
	not-equal: reduce [to-lit-word first [<>]]
	less-or-equal: reduce [to-lit-word first [<=]]
	greater-or-equal: reduce [to-lit-word first [>=]]
	less: reduce [to-lit-word first [< ]]
	greater: reduce [to-lit-word first [ > ]]
	compare-sign: [(cmp-not: false)
		'=		   (cmp-dat1: 3)
		| not-equal	   (cmp-dat1: 2)
		| greater-or-equal	   (cmp-dat1: 1)
		| less-or-equal (cmp-dat1: 0)
		| less    (cmp-not: true cmp-dat1: 1)
		| greater (cmp-not: true cmp-dat1: 0)
	]

	source-dat1: source-dat2: source-dat3: none
	source-copy1: source-copy: source-copy: none
	test: dummy: var: dec-loop: test: none
	source-var: source: [
		(source-dat1: 2)
		opt [
			  'var (source-dat1: 0)
			| 'motor 'tacho 'speed (source-dat1: 6)
			| 'motor 'tacho opt 'count (source-dat1: 5)
			| 'motor 'status (source-dat1: 3)
			| 'sensor 'type (source-dat1: 10)
			| 'sensor 'mode (source-dat1: 11)
			| 'sensor opt 'value (source-dat1: 9)
		]
		set tmp integer! (source-dat2: low tmp source-dat3: high tmp)
		| set tmp issue! (
			if not tmp2: select names tmp [
				make error! compose [user message (join "Not defined:" tmp)]
			]
			set [source-dat1 source-dat2 source-dat3] tmp2
		)
	]
	
	copy-source: [(
		source-copy1: source-dat1
		source-copy2: source-dat2
		source-copy3: source-dat3
	)]
	name-tmp: none
	name: [ 'name some [
		set name-tmp issue!
		source
		(
			tmp2: reduce [source-dat1 source-dat2 source-dat3]
			if find names name-tmp[
				make error! compose [user message (join "Name already defined:" name-tmp)]
			]
			if find/only names tmp2 [
				iprint ["Source named twice:" tmp]
			]
			repend names [name-tmp tmp2]
		)]
		| 'names [set tmp word! | set tmp block!] (
			if word? tmp [
				tmp: get tmp
				if not block? tmp [make error! [user message "names expects block"]]
			]
			if not parse block [any [
				issue! into [integer! integer! integer!]
			]] [
				make error! [user message "Bad data for names"]
			]
			append names tmp
		)
	]

	clear-cmd: ['clear [
		'sensor integer (cmd [209 tmp])
		| 'timer integer (cmd [161 tmp])
	]]
	datalog: ['datalog [
		source (cmd [98 source-dat1 source-dat2 source-dat3])
		| 'size integer (cmd [82 low tmp high tmp])
	]]
	program: ['program [
		integer (cmd [145 tmp])
	]]

	set-var: none
	division: reduce [to-lit-word first [/]]
	set-cmd: [
		opt 'set 'sensor integer2 'mode [
			integer
			| 'raw (tmp: 0)
			| 'boolean (tmp: 1)
			| 'edge opt 'count (tmp: 2)
			| 'pulse opt 'count (tmp: 3)
			| ['percentage | 'percent] (tmp: 4)
			| 'temperature '°f (tmp: 6)
			| 'temperature opt '°c (tmp: 5)
			| 'angel (tmp: 7)
		] ( cmd [66 tmp2 tmp * 32]
		)
		| opt 'set 'sensor integer2 'type [
			integer
			| 'raw (tmp: 0)
			| 'touch (tmp: 1)
			| 'temperature (tmp: 2)
			| 'light (tmp: 3)
			| 'rotation (tmp: 4)
		] (cmd [50 tmp2 tmp])
		| out 'set 'time integer integer2
		  (cmd [34 tmp tmp2])
		| 'set source-var (
			if source-dat1 <> 0 [make error! [user message "You can set variables only"]]
			set-var: source-dat2
		)
		opt [
			opt '=
			source
			(cmd [20 set-var source-dat1 source-dat2 source-dat3])
		]
		any [
			'+ source
			(cmd [36 set-var source-dat1 source-dat2 source-dat3])
			
			| 'and source
			(cmd [132 set-var source-dat1 source-dat2 source-dat3])
			
			| division source
			(cmd [68 set-var source-dat1 source-dat2 source-dat3])
			
			| '* source
			(cmd [84 set-var source-dat1 source-dat2 source-dat3])
			
			| 'or source
			(cmd [148 set-var source-dat1 source-dat2 source-dat3])
			
			| 'sgn source
			(cmd [100 set-var source-dat1 source-dat2 source-dat3])
			
			| '- source
			(cmd [52 set-var source-dat1 source-dat2 source-dat3])
		]
	]

	binary: [
		set tmp binary! (append out tmp)
	]

	wait-cmd: [
		'wait source (cmd [67 source-dat1 source-dat2 source-dat3])
	]
	if-cmd: [
	'if comparator ['goto set tmp word! | into ['goto set tmp word!]] (
		if cmp-not [make error! [user message "< > not allowed here"]]
		cmd ['test cmp-dat1 cmp-dat2 cmp-dat3 cmp-dat4 cmp-dat5 tmp 'dummy]
	)
	| [
		'if neg-comparator set tmp block! (tmp2: none)
		| 'either comparator set tmp block! set tmp2 block!
	] (use [block1 count1 block2 count2 b1 b2 pos cn mem] copy/deep [
		b1: tmp
		b2: tmp2
		if not b2 [b2: []]
		cn: cmp-not
		cmd ['test cmp-dat1 cmp-dat2 cmp-dat3 cmp-dat4 cmp-dat5 'dummy 'dummy]
		mem: last out
		pos: tail out
		either cn [
			parse b1 code
		] [
			parse b2 code
		]
		tmp: 1 + length? out
		if any [
			cn and not empty? b2
			not cn and not empty? b1
		] [
			tmp: tmp + 1
		]
		mem/7: tmp
		either cn [
			if not empty? b2 [
				cmd ['goto 'dummy 'dummy]
				mem: last out
				pos: tail out
				parse b2 code
				mem/2: 1 + length? out
			]
		] [
			if not empty? b1 [
				cmd ['goto 'dummy 'dummy]
				mem: last out
				pos: tail out
				parse b1 code
				mem/2: 1 + length? out
			]
		]
	])
	]
	while-cmd: [
		'while
		[pos-comparator | into pos-comparator]
		set tmp block! (use [pos block count mem1 mem2] copy/deep [
			cmd ['goto 'dummy 'dummy]
			mem1: reduce ['test cmp-dat1 cmp-dat2 cmp-dat3 cmp-dat4 cmp-dat5 1 + length? out 'dummy]
			mem2: last out
			parse tmp code
			append/only out mem1
			mem2/2: length? out
		])
	]
	forever-cmd: [
		'forever
		set tmp block! (use [obj mrk] copy/deep [
			mrk: length? out
			parse tmp code
			cmd ['goto mrk + 1 'dummy]
		])
	]
	for-tmp1: for-tmp2: for-tmp3: for-tmp4: none
	for-cmd: [
		'for
		copy for-tmp1 source
		opt '= copy for-tmp2 source
		opt 'to copy for-tmp3 source (for-tmp4: [1])
		opt [opt 'bump copy for-tmp4 source]
		set tmp block! (
			parse compose/deep [
				set (for-tmp1) (for-tmp2)
				while (for-tmp3) >= (for-tmp1) [
					(tmp)
					set (for-tmp1) + (for-tmp4)
				]
			] code
		)
	]
	loop-cmd: [
		'push 'loop source (cmd [130 source-dat1 source-dat2])
		| 'dec 'loop set tmp word! (cmd ['dec-loop tmp 'dummy])
		| 'loop source set tmp block! (use [pos] copy/deep [
			cmd [130 source-dat1 source-dat2]
			cmd ['dec-loop 'dummy 'dummy]
			pos: length? out
			parse tmp code
			cmd ['goto pos 'dummy]
			out/:pos/2: 1 + length? out
		])
	]
	flatten: func [pos [block!] /local out] [
	    out: copy []
	    foreach e pos [
		append out e
	    ]
	    out
	]
	task: [
		'task
		integer [
			opt 'download
			  set tmp2 block! ( use [pos task block count data build chk] copy/deep [
				pos: tail out
				task: tmp
				parse tmp2 code
				solve-gotos out
				block: flatten pos
				clear pos
				iprint ["Task-length" task ":" tmp: length? block "bytes (" to-integer tmp / 394 * 100 + 0,5 "%)"]
				bytes: bytes + tmp
				cmd [37 0 low task high task low tmp high tmp]
				count: 0
				forskip block 20 [
					count: count + 1
					data: copy/part block 20
					if (length? block) <= 20 [count: 0]
					build: append reduce [69 low count high count low length? data high length? data] data
					chk: 0
					foreach x data [chk: chk + x]
					chk: chk and 255
					cmd append build chk
				]
			  ])
			| 'start (cmd [113 tmp])
			| 'stop (cmd [129 tmp])
			| 'delete (cmd [97 tmp])
		]
		| 'task 'all [
			'delete (cmd [64])
			| 'stop (cmd [80])
		]
	]
	
	play: [ 'play [
		'sound [
			integer
			| 'blip (tmp: 0)
			| 'beep 'beep (tmp: 1)
			| 'down (tmp: 2)
			| 'up (tmp: 3)
			| 'low (tmp: 4)
			| 'fast opt 'up (tmp: 5)
		 ] (cmd [81 tmp])
		| 'tone integer (tmp2: 20)
		   opt integer2
		   (tmp tmp2 cmd [35 low tmp high tmp tmp2])
	]]
	power: [
		'power 'off (cmd [96])
		| 'power opt 'down 'delay integer (cmd [177 tmp])
	]
	program: [
		'program integer (cmd [145 low tmp])
	]
	marker: [
		set tmp set-word! (
			repend markers [to-word :tmp 1 + length? out]
		)
	]
	goto: [
		'goto set tmp word! (
			cmd ['goto tmp 'dummy]
		)
	]
	subroutine: [
		['sub | 'subroutine] [
		    integer [
		   	  opt 'download
			  set tmp2 block! ( use [obj count data build chk] [
				obj: make self []
			  	tmp2: obj/byte-list tmp2
				iprint ["Sub-length" tmp ":" length? tmp2 "bytes (" to-integer (length? tmp2) / 394 * 100 + ,5 "%)"]
				bytes: bytes + tmp
				cmd [53 0 low tmp high tmp low length? tmp2 high length? tmp2]
				count: 0
				forskip tmp2 20 [
					count: count + 1
					data: copy/part tmp2 20
					if (length? tmp2) <= 20 [count: 0]
					build: append reduce [69 low count high count low length? data high length? data] data
					chk: 0
					foreach x data [chk: chk + x]
					chk: chk and 255
					cmd append build chk
				]
			  ])
			| ['call | 'start] (cmd [23 tmp])
			| 'delete (cmd [193 tmp])
		    ]
		    | 'all 'delete (cmd [112])
		]
		| 'return (cmd [246])
	]
	
	; ------------ end of commands ---------




	create: func [[catch] block [block!] /no-solve /local e a b] [
		if error? set/any 'e catch [throw-on-error [
			if not parse block root [
				throw make error! [
					user message
					"parse-error"
				]
			]
		]] [
			parse mold copy/part pos 5 [copy b 0 80 skip [end | to end (append b " ... ]")]]
			if none? b [b: "[]"]
			a: disarm e
			a/arg1: rejoin [a/arg1 " -- " b]
			throw e
		]
		solve-gotos
		out
	]
	byte-list: func [block [block!] /local out] [
		block: create block
		out: copy []
		foreach b block [append out b]
		out
	]
	acht: yes
	sequence: func [block [block!] /local out sum tmp start] [
		clear names
		bytes: 0
		block: create block
		out: make block! length? block
		foreach e block [
			either binary? e [
				append out e
			] [
				append out copy #{FE0000FF}
				sum: 0
			 	acht: not acht
				start: yes
				foreach a e [
					if start [
						if acht [
							a: a xor 8
						]
					]
					start: no
					tmp: to-binary reduce [a 255 - a]
					dada: tmp
					append last out tmp
					sum: sum + a
				]
				sum: sum and 255
				append last out to-binary reduce [sum 255 - sum]
			]
		]
		if bytes > 0 [
			iprint ["Downloading" bytes "bytes (" to-integer bytes / 394 * 100 + 0,5 "%)"]
		]
		out
	]
	define: func [block [block!]] [
		if not parse block [
			(clear names)
			any name
		] [
			make error! [user message "define"]
		]
		names
	]
	goto-diff: func [
		word [word! integer!]
		from [integer!]
		/local to count mrk
	] [
		either word? word [
			if not to: select markers word [
				make error! compose [user message (join "Marker not found:" word)]
			]
		] [
			to: word
		]
		if from = to [return 0]
		either from < to [
			to: to - 1
		] [
			from: from - 1
			mrk: yes
		]
		count: 0
		for x min from to max from to 1 [
		    if out/:x [
			count: count + length? out/:x
		    ]
		]
		if mrk [count: - count]
		count
	]
	opti-gotos: func [
		/local tmp tmp2 count diff
	] [
		; exit
		count: 0
		parse out [any [ (count: count + 1)
			set tmp2 into ['goto set tmp [word! | integer!] 'dummy]
			(
				diff: goto-diff tmp count
				if (absolute diff - 1) <= 127 [remove back tail tmp2]
			)
			| set tmp2 into ['test 5 integer! set tmp [word! | integer!] 'dummy]
			(
				diff: goto-diff tmp count
				if (absolute diff - 6) <= 127 [remove back tail tmp2]
			)
			| set tmp2 into ['dec-loop set tmp [word! | integer!] 'dummy]
			(
				diff: goto-diff tmp count
				if diff - 1 <= 255 [remove back tail tmp2]
			)
			| skip
		]]
	]
	solve-gotos: func [
		/local count diff tmp tmp2 out1 out2
	] [
		count: 0
		loop 5 [opti-gotos]
		parse out [any [ (count: count + 1)
			set tmp2 into ['goto set tmp [word! | integer!] 'dummy]
			(
				diff: goto-diff tmp count
				diff: diff - 1
				clear tmp2
				out1: (absolute diff) and 127
				if diff < 0 [out1: out1 or 128]
				out2: to-integer (absolute diff) / 128
				repend tmp2 [114 out1 out2]
			)
			| set tmp2 into ['test 5 integer! set tmp [word! | integer!] 'dummy]
			(
				diff: goto-diff tmp count
				diff: diff - 6
				tmp2/1: 149
				tmp2/7: low diff
				tmp2/8: high diff
			)
			| set tmp2 into ['dec-loop set tmp [word! | integer!] 'dummy] (
				diff: goto-diff tmp count
				diff: diff - 1
				if diff < 0 [
					make error! [user message "Loops can only jump forward"]
				]
				tmp2/1: 146
				change next tmp2 reduce [low diff high diff]
			)
			| set tmp2 into ['goto set tmp [word! | integer!]]
			(
				diff: goto-diff tmp count
				diff: diff - 1
				clear tmp2
				out1: absolute diff
				if diff < 0 [out1: out1 or 128]
				repend tmp2 [39 out1]
			)
			| set tmp2 into ['test 5 integer! set tmp [word! | integer!]]
			(
				diff: goto-diff tmp count
				diff: diff - 6
				tmp2/1: 133
				tmp2/7: low diff
			)
			| set tmp2 into ['dec-loop set tmp [word! | integer!]] (
				diff: goto-diff tmp count
				diff: diff - 1
				if diff < 0 [
					make error! [user message "Loops can only jump forward"]
				]
				tmp2/1: 55
				tmp2/2: diff
			)			
			| skip
		]]
	]
]



make Root-Protocol [
	scheme: 'lego
	port-id: 8881
	port-flags: system/standard/port-flags/pass-thru
	device: 'port1
	init: func [[catch] port spec /local tmp] [
		if not parse/all spec [
			"lego://"
			[
				copy tmp ["port" ["1" | "2" | "3" | "4"]]
					(port/device: to-word tmp)
				| end   (port/device: 'port1)
			]
		] [
			throw make error! [user message "Bad lego-URL"]
		]
	]
	open: func [[catch] port] [ throw-on-error [
		port/sub-port: system/words/open/binary/direct/no-wait compose [
			scheme: 'serial
			device: (to-lit-word port/device)
			speed: 2400
			parity: 'odd
			rts-cts: no
		]
		port/state/flags: port/state/flags or port-flags
		port
	]]
	insert: func [[catch] port buf /local e] [
		if block? buf [
			if error? set/any 'e try [
				buf: lego/sequence buf
			] [
				throw e
			]
			if none? buf [
				throw make error! [user message "Lego-Protocol"]
			]
		]
		if not block? buf [buf: reduce buf]
		foreach buf buf [
			system/words/insert port/sub-port buf
			wait 0,5
		]
		port
	]
	net-utils/net-install :scheme self :port-id
]

