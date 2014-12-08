REBOL [
	title: "Private Chat Windows"
	author: "Frank Sievertsen"
	version: 0.0.1
	type: 'irc-plugin
]

chats: []

input: func [str [string!] conn [object!] /local chat nick] [
	if parse/all str compose/deep [
		"/talk " copy nick [(in irc/protocol 'nick)]
	] [
		foreach test chats [
			if test/nick = nick [return none]
		]
		chat: make chat-window []
		chat/nick: nick
		chat/conn: conn
		chat/open
		return none
	]
	str
]

message: func [msg [object!] conn [object!] /local test nick chat] [
	if all [
		find ["PRIVMSG" "NOTICE"] msg/command
		not find [#"#" #"&"] msg/params/1/1
		not empty? last msg/params
		not equal? #"^A" first last msg/params
	] [
		nick: irc-system/get-nick msg/from
		foreach test chats [
			if test/nick = nick [
				chat: test
				break
			]
		]
		if none? chat [
			chat: make chat-window []
			chat/nick: nick
			chat/open
		]
		chat/conn: conn
		chat/work msg
	] 
]

chat-window: make object! [
	nick: none
	win: none
	orig-size: none
	out: none
	conn: none
	open: does [
                win: view/new/options/title make layout [
                        space 0x0
                        styles sty
                        backdrop
                        out: chat-area 200x100
                        chat-field 200 [
				append out/data rejoin ["*** " value newline]
                                insert conn/conn ['PRIVMSG nick value]
                        ]
                ] [mem-size: size] [resize] join "Chat: " nick
                orig-size: win/size
                win/feel: make win/feel [
                        engage: func [face action event] [
                                if action = 'resize [
                                        win/size: max win/size orig-size
                                        show win
                                        irc-system/resize-face/deep win 100x100
                                        show win
                                ]
                        ]
                ]
		append chats self
	]
	work: func [msg [object!]] [
		append out/data join last msg/params "^/"
		view/new win
	]
]
