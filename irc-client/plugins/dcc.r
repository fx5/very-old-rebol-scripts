REBOL [
	title: "DCC-Client"
	author: "Frank Sievertsen"
	version: 0.9.0
	type: 'irc-plugin
]

input: func [str [string!] conn [object!] /local nick dcc] [
	if parse/all str compose/deep [
		"/dcc chat " copy nick [(in irc/protocol 'nick)]
	] [
		dcc: make dcc-connection [
			conn: system/words/open/lines/direct/with tcp:// "^/"
		]
		dcc/nick: irc-system/get-nick nick
		dcc/open-server
		insert conn/conn ['PRIVMSG nick rejoin ["^ADCC CHAT chat " enpack-ip system/network/host-address " " dcc/conn/port-id "^A"]]
		return none
	]
	str
]

message: func [msg [object!] conn [object!] /local nums ip port] [
	nums: charset "0123456789"
	if all [
		msg/command = "PRIVMSG"
		parse/all last msg/params [
			"^ADCC CHAT chat" some " "
			copy ip [some nums]
			some " "
			copy port [some nums]
			"^A"
		]
	] [
		ip: depack-ip ip
		make dcc-connection [
			conn: system/words/open/lines/direct/with rejoin [tcp:// ip ":" port] "^/"
			nick: irc-system/get-nick msg/from
			open
		]
	] 
]

dcc-connection: make object! [
	conn: none
	win: none
	nick: none
	out: none
	orig-size: none
	open: does [
		win: view/new/options/title make layout [
			space 0x0
			styles sty
			backdrop
			out: chat-area 200x100
			chat-field 200 [
				insert conn value
			]
		] [mem-size: size] [resize] join "DCC: " nick

		conn/awake: func [port /local tmp] [
			append out/data join tmp: copy/part port 1 newline
			if none? tmp [close]
			no
		]
		orig-size: win/size
		win/feel: make win/feel [
			engage: func [face action event] [
				if action = 'close [
					close
				]
				if action = 'resize [
					win/size: max win/size orig-size
					show win
					irc-system/resize-face/deep win 100x100
					show win
				]
			]
		]
		append system/ports/wait-list conn
	]
	open-server: func [] [
		conn/awake: func [port] [
			remove any [find system/ports/wait-list conn []]
			conn: first port
			system/words/close port
			open
			no
		]
		append system/ports/wait-list conn
	]
	close: func [] [
		if win [unview/only win]
		error? try [system/words/close conn]
		remove any [find system/ports/wait-list conn []]
	]

]

depack-ip: func [str [string!] /local out] [
	str: to-decimal str
	out: make block! 4
	loop 4 [
		insert out to-integer str // 256
		str: str / 256
	]
	to-tuple out
]
enpack-ip: func [ip [tuple!] /local out] [
	out: 0.0
	repeat z 4 [
		out: out * 256 + pick ip z
	]
	out
]

