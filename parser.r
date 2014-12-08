REBOL [
	title: "Parser"
	author: "Frank Sievertsen"
	version: 1.0.0
]

parser: make object! [
	rules: [
		expr:	[space on sum]
		sum:	[prod opt ["+" sum]]
		prod:	[integer opt ["*" prod]]
		integer: [some [num]]
		num:	charset [#"0" - #"9"]
	]

	observers: []

	observer: make object! [
		up: out: none
		init: does [
			up: copy []
			out: copy []
		]
		lit: func [ str /local word] [
			either all [word? pick out 1 word: in rules to-word join first out "*"] [
				append out do get word str
			] [
				append out :str
			]
		]
		in-rule: func [word [word!]] [
			; print [head insert/dup clear "" " " length? up ">" word]
			append/only up out
			out: reduce [word]
		]
		failed-rule: func [word [word!]] [
			; print [head insert/dup clear "" " " length? up "<" word]
			out: last up
			remove back tail up
		]
		out-rule: func [word [word!] /local tmp] [
			; print [head insert/dup clear "" " " length? up "<" word]
			either in rules word [
				out: rules/:word next out
			] [
				out: next out
			]
			tmp: :out
			out: last up
			remove back tail up
			lit :tmp
		]
		rules: make object! []
	]

	add-observer: func [rules [block!] /local o pos collect] [
		if not parse rules: copy rules [some [
			set-word! block! pos: (
				collect: copy [mem /local]
				foreach v pos/-1 [
					if all [
						set-word? :v
						not find collect to-word :v 
						not :v = first [local:]
					] [
						append collect to-word :v
					]
				]
				pos: insert back pos reduce [:func collect]
				pos: next pos
				
			) :pos
		]] [
			make error! "Bad observer"
		]
		o: make observer []
		o/rules: make object! rules
		append observers o
		o
	]


	understand: make object! [
	    obj: none
	    pos: none
	    start: stop: none
	    out: []
	    up: []
	    observers: none
	    spc: none
	    spaces: charset " ^-"
	    init: does [
		spc: none
	    ]
	    lit: func [str [series!]] [
		foreach o observers [o/lit str]
		append out str
	    ]
	    in-rule: func ['word [word!]] [
		foreach o observers [o/in-rule word]
		append/only up out
		out: reduce [word]
	    ]
	    failed-rule: func ['word [word!]] [
		foreach o observers [o/failed-rule word]
		out: last up
		remove back tail up
	    ]
	    out-rule: func ['word [word!]] [
		foreach o observers [o/out-rule word]
		append/only last up out
		out: last up
		remove back tail up
	    ]
	    root: [
		any [pos:
			['opt | 'some | 'any | integer! | 'into] (
				if not block? pos/2 [make error! rejoin ["" pos/1 " requires block"]]
			)
			| '|
			| 'space 'on (
				pos: insert/only remove/part pos 2 to-paren [spc: [any spaces]]
			) :pos
			| 'space 'off (
				pos: insert/only remove/part pos 2 to-paren [spc: none]
			) :pos
			| into root
			| [string! | bitset! | char! | lit-word! | 'skip]
			  (
				pos: insert pos [spc start:]
				pos: insert next pos [stop: (lit copy/part start stop) spc]
			  ) :pos
			| word! (
				if all [
					not datatype? get/any pos/1
					not find first obj pos/1
				] [make error! join "Not found: " pos/1]
				either datatype? get/any pos/1 [
					pos: insert pos [start:]
					pos: insert next pos [stop: (lit copy/part start stop)]
				] [
					pos: insert/only next pos to-paren reduce ['out-rule pos/1]
				]
			  ) :pos
		]
	    ]
	]
	compiled: func [
		/local
	] [
		compiled: make object! rules
		foreach [name val] third compiled [
			if not block? val [
				val: reduce [:val]
				set :name val
			]
			understand/obj: compiled
			if not parse val understand/root [
				make error! join "Error in: " to-string :name
			]
			insert val reduce [to-paren reduce [in understand 'in-rule to-word :name]]
			append val reduce ['| to-paren reduce [in understand 'failed-rule to-word :name] 'to 'end "hallo"]
		]
		compiled
	]
	run: func [[catch]
		str [series!]
		'word [word!]
	] [
		understand/out: copy []
		clear understand/up
		understand/observers: observers
		foreach o observers [o/init]
		understand/init
		compiled
		throw-on-error [
		    if not parse/all str compiled/:word [
			throw make error! "Parse error"
		    ]
		]
		foreach o observers [
			o/out-rule word
		]
		understand/out
	]
]

COMMENT [
   do [
	math-parser: make parser [rules: [
		expr:   [space on sum]
		sum:    [prod opt ["+" sum]]
		prod:   [integer opt ["*" prod]]
		integer: [some [num]]
		num:    charset [#"0" - #"9"]
	]]
	calc: math-parser/add-observer [
		integer:	[to-integer rejoin mem]
		sum*:		[either "+" = mem ['+] [mem]]
		sum: 		[do mem]
		prod*: 		[ either "*" = mem ['*] [mem] ]
		prod: 		[do mem]
	]
	math-parser/run "1+2*3+4*5" expr
	print calc/out
   ]
]

