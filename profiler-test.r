REBOL []

do to-string request-download http://proton.cl-ki.uni-osnabrueck.de/REBOL/profiler.r
do to-string request-download http://proton.cl-ki.uni-osnabrueck.de/REBOL/fx5-styles.r

context [
input-area: none
view/title layout [styles fx5-styles backdrop
	input-area: area as-is trim/auto {
		context profiler [
			profiler-reset
			f1: func [str /local count] [loop 100 [
				count: 0
				forall str [
					if str/1 = #"e" [count: count + 1]
				] str: head str
				count
			]]
			f2: func [str /local count] [loop 100 [
				count: 0
				foreach chr str [
					if chr = #"e" [count: count + 1]
				]
				count
			]]
			f3: func [str /local count] [loop 100 [
				count: 0
				parse str [any ["e" (count: count + 1) | skip]]
				count
			]]
			f4: func [str /local count] [loop 100 [
				count: 0
				parse str [any [#"e" (count: count + 1) | to #"e"]]
				count
			]]
			f5: func [str /local count] [loop 100 [
				count: 0
				parse str [any [thru #"e" (count: count + 1)]]
				count
			]]
			string: head (insert/dup (copy "") "Hello, this is a test string!" 80)
			do test: does [loop 2 [
				probe f1 string
				probe f2 string
				probe f3 string
				probe f4 string
				probe f5 string
			]]
			view/new/title layout [styles fx5-styles backdrop
				area as-is profiler-info/str font [face: font-fixed]
			] "Result"
		]
	} font [face: font-fixed] 500x300
	across
	button "Do" "Please wait" [
		if error? try [
			do input-area/text
		] [
			print "ERROR"
		]
	]
	label "Try this to see, which function is the fastest"
] "Profiler"
]
