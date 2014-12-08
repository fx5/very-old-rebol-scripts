REBOL [
]

dbridge-protocol: make Root-Protocol [
	scheme: 'telnet
	port-id: 23
	port-flags: system/standard/port-flags/pass-thru 
	tmp: none
	open: func [port /local in] [
		open-proto port
		if any [port/target port/path] [
			if not port/target [port/target: ""]
			if port/path [insert port/target port/path]
		]
		port/state/flags: port/state/flags or system/standard/port-flags/direct or 32 or 2051; No-Wait, BINARY (51) (2048)
		; port/state/flags: port/state/flags or 2051 ; No-Wait
		port/sub-port/state/flags: port/sub-port/state/flags or 2051 or 32
		if all [port/user port/pass] [
			in: make string! 100
			until [
				append in copy port
				find in "login:"
			]
			system/words/insert port/sub-port join port/user "^/"
			clear in
			until [
				append in copy port
				find in "password"
			]
			system/words/insert port/sub-port join port/pass "^/"
			while ["" <> copy port] []
			if port/target [
				system/words/insert port/sub-port join port/target ";exit^/"
				clear in
				forever [
					wait port/sub-port
					tmp: make string! 100
			 		if zero? read-io port/sub-port tmp 100 [break]
					append in tmp
				]
				port/user-data: in
			]
		]
	]
	copy: func [port /part range /local in] [
	   either port/user-data [
	      port/user-data
	   ] [
	      in: make string! 100
              out: make string! 100
              forever [
			while [wait [0 port/sub-port]] [
				tmp: make string! 100
				if zero? read-io port/sub-port tmp 100 [break]
				append in tmp
			]
			print ["<<" mold in]
			if parser/incoming in out [
				print [">>" mold out]
				write-io port/sub-port out length? out
				break
			]
			system/words/wait port/sub-port
	      ]
	      in
	   ]
	]
	insert: func [port data] [
		system/words/insert port/sub-port data
	]

	set 'global-parser parser: make object! [
		s-will: to-char 251
		s-wont: to-char 252
		s-do:   to-char 253
		s-dont: to-char 254

		iac:  to-char 255
		sb: to-char 250
		se: to-char 240
		required: to-char 1
		supplied: to-char 0

		r-will: to-char 251
		r-do:   to-char 252
		r-wont: to-char 253
		r-dont: to-char 254
		non-command: complement charset reduce [iac]

		terminal-type: to-char 24
		terminal-speed: to-char 32
		suppress-go-ahead: to-char 3
		echo: to-char 1

		tmp: none

		send: func [block [block!]] [
			system/words/append out-port to-binary join iac reduce block
		]

		sb-data: [
			iac se
			| skip sb-data
		]

		start: end: none
		data: [any [
			start: iac [
				s-do terminal-type (
					send [r-will terminal-type]
				)
				| s-do echo (
;					send [r-wont terminal-type]
				)
				| sb terminal-type required iac se (
					send [sb terminal-type supplied "vt100" iac se]
				)
				; DEFAULTS
				| sb sb-data
				| s-do copy tmp skip (
					send [s-wont tmp]
				)
				| s-will copy tmp skip (
					send [r-dont tmp]
				)
				| s-wont copy tmp skip (
				;	send [r-dont tmp]
				)
				| s-dont copy tmp skip (
				 	send [r-wont tmp]
				)
			] end: (remove/part start end) :start
			| non-command
		]]

		out-port: none
		incoming: func [str [any-string!] port [port! any-string!]] [
			out-port: port
			parse/all str data
		]
	]

	net-utils/net-install :scheme self port-id
]
