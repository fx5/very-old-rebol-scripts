REBOL [
	title: "A simple but useful profiler"
	author: "Frank Sievertsen"
	version: 1.0.3
	purpose: "Find out, how much time each of your functions need"
	date: 13-8-01
	usage: {
		insert at the head of your "main"-script:

			profiler: func [block] [block]
                        profiler-info: func [] [print "No Profiler running"]
                        do http://proton.cl-ki.uni-osnabrueck.de/REBOL/profiler.r

		If you want to deactivate the profiler (because it slowes down
		your script!) you must only insert a ";" before the "do http://"

		Now you can do something like:

		do profiler [
			a: func ["first profiled function" a] [probe a]
			....
		]
		make object! profiler [
			a: func ["first profiled function" a] [probe a]
			....
		]
		....
		All the functions in the block will be profiled. After your
		program runs a while, you can use 'profiler-info to output
		the profiler-informations.

		Profiler may or may not work with your program without changes
		in the source.
	}
]

context [

data: make hash! []
count: 0
times: []
start-time: now/time/precise

profiler-register: func [name [string!]] [
	repend data [count: count + 1 name reduce [now/time/precise]]
	count
]
profiler-deregister: func [id [integer!] /local pos time] [
	data: skip tail data -3
	if id <> data/1 [
		if none? pos: find/last head data id [return none]
		clear skip data: pos 3
		prin "e"
	]
	either pos: find times data/2 [
		pos/2/1: pos/2/1 + time: now/time/precise - data/3/1
		pos/2/2: pos/2/2 + 1
	] [
		repend times [data/2 reduce [time: now/time/precise - data/3/1  1]]
	]
	clear data
	foreach [key name val] head data [
		val/1: val/1 + time
	]
]
prof: func [
        "Profiler function"
        name [string!]
        header [block!]
        body [block!]
	/local val
] [
        func compose [(header) /profiler-data profiler-ticket return exit] compose/deep [
		profiler-data: (copy/deep [[]])
		either empty? profiler-data [repend profiler-data [
			return: func [[throw] value [any-type!]] [
				profiler-deregister profiler-ticket
				system/words/return get/any 'value
			]
			exit: func [[throw]] [return]
                ]] [
			set [return exit] profiler-data
		]
                profiler-ticket: profiler-register (name)

                set/any 'val do (reduce [body])
		profiler-deregister profiler-ticket
		get/any 'val
        ]
]

system/words/profiler: func [block [block!] /local t1 t2 t3 pos ff] [
	ff: [
		'func block! block!
		| 'function t2: block! block! block!
			:t2
			(append t2/1 append copy [/local] t2/2
			remove next t2)
		| 'has t2: block! block!
			(insert t2/1 /local)
		| 'does t2: block!
			(insert/only t2 copy [])
	]
        parse block [any [
		[
			set t1 [set-word! | set-path!] pos: ff
			| 'set set t1 lit-word! pos: ff
		]
                        (change/part pos reduce ['prof (form :t1)] 1) :pos
                | skip
        ]]
        block
]
system/words/profiler-reset: func [] [
	clear times ()
	start-time: now/time/precise
]
system/words/profiler-info: func [/str /local time print out] [
	either str [
		print: func [sth] [
			repend out [reform sth newline]
		]
		out: copy ""
	] [
		print: get in system/words 'print
		unset 'out
	]
	time: 0:0
	foreach [key val] head times [
		time: time + val/1
	]

	print "------------FX5 Profiler-------------------------------------------------------------------"
	sort/skip/compare times 2 [2]
	foreach [key val] head times [
		print rejoin [""
			head insert/dup tail copy key "." (50 - length? key) 
			" "
			val/1
			"^-" to-integer (to-decimal val/1) / (to-decimal time) * 100 + ,5 "%"
			"^-" val/2
		]
	]
	print "-------------------------------------------------------------------------------------------"
	print ["Running-time:" now/precise/time - start-time "   Logged-time:" time]
	print "-------------------------------------------------------------------------------------------"
	return get/any 'out
]
]

