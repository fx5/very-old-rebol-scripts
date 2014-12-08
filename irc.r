REBOL [
	title: "IRC"
	author: "Frank Sievertsen"
	version: 0.2.1
]



make object! [
	base-dir: join system/options/home "public/www.fx5.de/irc-client/"

	; --- Snip ---

	do-thru: func [url /local in] [
		in: load-thru/update url
		if none? in [in: load-thru url]
		if none? in [inform layout [title join url " not found" button "OK"] quit]
		do in
	]

	#do-thru http://proton.cl-ki.uni-osnabrueck.de/REBOL/irc-protocol.r
	#do-thru http://proton.cl-ki.uni-osnabrueck.de/REBOL/form-error.r
    do %irc-protocol.r
    do %form-error.r

	; --- Snip ---

	make-dir/deep base-dir/plugins
	make-dir/deep base-dir/plugin-data

	plugin: plugins: none
	init-plugins: func [/local tmp plug header] [
		plugin: make object! [
			plugin-file: none
			version: none
			title: none
			author: none

			win: none
			irc-system: none
			sty: none
			active?: yes

			install: func [] []
			uninstall: func [] []

			message: func [msg [object!] conn [object!]] []
			input: func [str [string!] conn [object!]] [
				str
			]

			open-window: none
			close-window: func [] [
				if win [unview/only win]
				win: none
			]
		]
		plugin/irc-system: self
		plugin/sty: sty
		

		plugins: copy []
		tmp: none
		
		foreach file read join base-dir "plugins/" [
		    if error? set/any 'tmp try [
			append plugins plug: make plugin tmp: load/header/all base-dir/plugins/:file
			header: first tmp
			plug/plugin-file: file
			plug/version: header/version
			set bind/copy tmp: [version title author] in plug 'self reduce bind/copy tmp in header 'self
		    ] [
			inform layout [
				title join "Error loading plugin: " file
				area as-is form-error tmp
				button "Ok"
			]
		    ]
		]
		sort/compare plugins func [a b] [a/title < b/title]
	]


	buttons: [
		["+OP" [["/mode +o" user]]]
		["Whois" [["/whois" user]]]
		["Kick" [["/kick" user]]]
		["DCC Chat" [["/dcc chat" user]]]
		["Talk" [["/talk" user]]]
	]
	resize-face: func [face [object!] center [pair!] /deep /local mem-size changed size] [
	    size: face/size
	    if in face 'min-size [face/size: size: max face/min-size face/size]
	    mem-size: either in face 'mem-size ['mem-size] ['old-size]
	    all [any [block? get in face 'pane object? get in face 'pane]
		foreach f compose [(face/pane)] [
		changed: no
		if (f/offset/x <= center/x) and (f/offset/x + f/size/x >= center/x) [
			f/size/x: f/size/x + size/x - face/:mem-size/x
			changed: yes
		]
		if (f/offset/y <= center/y) and (f/offset/y + f/size/y >= center/y) [
			f/size/y: f/size/y + size/y - face/:mem-size/y
			changed: yes
		]
		if (f/offset/x >= center/x) [ f/offset/x: f/offset/x + size/x - face/:mem-size/x ]
		if (f/offset/y >= center/y) [ f/offset/y: f/offset/y + size/y - face/:mem-size/y ]
		if all [deep changed] [resize-face/deep f center - f/offset]
		show f
	    ]]
	    if mem-size = 'mem-size [
		    face/mem-size: size
	    ]
	]

	get-nick: func [str [string! none!] /local out] [
		if none? str [return nick]
		if not parse/all str compose [
			copy out (in irc/protocol 'nick) to end
		] [return none]
		out
	]

	b-tmp: none
	sty: stylize [
		backdrop: backdrop 180.180.180
		field: field with [
			append init [
				alt-action: :action
				action: none
			]
		] feel [
			old-engage: :engage
			engage: func [face action event] [
				either all [action = 'key event/key = cr] [
					face/alt-action face face/data
					system/view/highlight-start: face/data
					system/view/highlight-end: tail face/data
					system/view/caret: face/data
					show face
				] [
					old-engage face action event
				]
			]
		] 
		chat-field: field with [
			flags: [field]
		]
		chat-area: area wrap rate 1 with [
		    append-message: func [msg channel] [
			either none? channel [
				append data join msg/string "^/"
			] [
				append data rejoin [
					"<" get-nick msg/from "> "
					form next msg/params
					newline
				]
			]
		    ]
		    append-command: func [msg channel] [
			append data rejoin [
				"*** " form next msg/params
				newline
			]
		    ]
		    append init [para: make para [] flags: copy []]
		] feel [ engage: func [face action event] [
			if action = 'time [
				remove/part face/data (length? face/data) - 5000
				face/para/origin: face/size - (size-text face) * 0x1 + 2x2
				face/line-list: none
				show face
			]
		]]
		button-list: list 100x100 [
			b-tmp: button 100 with [to-do: none] [
			     use [tmp channel] [
			     all [
				block? face/to-do
				channel: face/parent-face/parent-face/channel
				tmp: bind/copy face/to-do in channel 'user
				foreach b tmp [
					face/parent-face/parent-face/channel/input b
				]
			     ]
			     ]
			]
		] supply [
			b-tmp: face
			b-tmp/text: first any [pick buttons count [""]]
			b-tmp/to-do: second any [pick buttons count reduce ["" none]]
			b-tmp/show?: not empty? b-tmp/text
		] frame 0.0.0 0x0 with [
			color: none
			channel: none
		]

   		chat-txt: tt feel [engage: none] para [
			origin: 0x0
			margin: 0x0
   		] as-is
		nick-txt: chat-txt with [flag-face self newline] red
		chat-box: box white ibevel 1x1 200.200.200 with [
			append init [pane: get in layout [
			    at (size * 1x0 + -12x0)
			    slider (size * 0x1 + 10x-2) [
				face/parent-face/move-pane value
				show face/parent-face
			    ]
			] 'pane]
			message-start: 0x0
			message-offset: 0x0
			wrap-pane: func [
				pane
				/offset offset-pos
				/local pos
			] [
				pos: either offset [offset-pos] [pane/1/offset]
				foreach f pane [
					if any [
						flag-face? f newline
						f/size/x + pos/x + 15 > size/x
					] [
						pos: pos * 0x1 + 5x12
					]
					f/offset: pos
					pos: f/size * 1x0 + pos
				]
				pos
			]
			append-message: func [
				msg [object!]
				channel
				/local pane data p1 p2 move
			] [
				data: copy []
				parse/all last msg/params [
				    p1: any [
					" " p2: (
						repend data ['chat-txt copy/part p1 p2]
						p1: p2
					)
					| skip
				    ]
				    p2: (repend data ['chat-txt copy/part p1 p2])
				]
				append self/pane pane: get in layout/styles append copy [
					at message-offset
					nick-txt rejoin ["<" get-nick msg/from "> "]
				] data styles 'pane
				message-offset: wrap-pane pane
				self/pane/1/data: 1
				self/pane/1/state: 0
				self/pane/1/redrag size/y / (message-offset/y - message-start/y)
				move-pane 1
				show self
			]
			move-pane: func [
				value
				/local move
			] [
				move: size/y - message-offset/y - 20
				move: move + to-integer 1 - value * (max 0 message-offset/y - message-start/y - size/y + 20)
				foreach f next self/pane [
					f/offset/y: f/offset/y + move
				]
				message-offset/y: message-offset/y + move
				message-start/y: message-start/y + move
			]

			append-command: func [
				msg [object!]
				channel
			] [
				append-message make msg [from: "YOU"] channel
			]
   		]
	]
	
	connection: make object! [
		server: none
		nick: none
		port-id: 6667
		real-name: none

		conn: none
		win: none
		out: none
		in: none

		channels: []

		awake: func [
			/local msg tmp e
		] [
			if none? msg: copy conn [error? try [
				error? try [close conn]
				remove any [find system/ports/wait-list conn/sub-port []]
				foreach [tmp channel] copy channels [
					channel/close
				]
				unview/only win
				exit
			]]
 
			foreach plugin plugins [
			  if plugin/active? [
			    if error? set/any 'e try [
				plugin/message msg self
			    ] [
				print ["ERROR IN PLUGIN: " plugin/title]
				print form-error e
			    ]
			  ]
			]
			if all [
				msg/command = "join"
				me? msg/from
			] [
				make channel [
					channel: msg/params/1
					open
				]
			]
			if any [
			    all [
				find ["TOPIC" "PRIVMSG" "NOTICE" "JOIN" "PART" "KICK"] msg/command
				tmp: select channels msg/params/1
			    ]
			    all [
				"353" = msg/command
				tmp: select channels msg/params/3
			    ]
			    all [
				find ["332" "353" "366"] msg/command
				tmp: select channels msg/params/2
			    ]
			] [
				tmp/work msg
			]
			if all [
				msg/command = "NICK"
				me? msg/from
			] [
				nick: msg/params/1
			]
			if find ["NICK" "QUIT"] msg/command [
				foreach [name channel] [channel/work msg]
			]
			out/append-message msg none
		]
		plugin-inputs: func [
			str [string!]
		] [
			foreach plugin plugins [
			    if plugin/active? [
				if none? str: plugin/input str self [return none]
			    ]
			]
			str
		]

		me?: func [sth [any-string! none!]] [
			if none? sth [return none]
			parse/all sth [
				nick opt ["!" to end]
			]
		]

		error-do: func [face [object!] block [block!] /local e] [
			if error? set/any 'e try block [
				append face/data join form-error e newline
			]
			()
		]

		channel: does [channel: make object! [
			channel: none
			out: none
			users: []
			topic: none
			users-new: yes
			tmp: none
			user: none
			input: func [str [string! block!] /local mem] [
			    error-do out [
				if block? str [str: reform str]
				if none? str: plugin-inputs str [exit]
				foreach command first mem: irc/protocol/input/target str channel [
					insert conn command
				]
				foreach command second mem [
					out/append-command command channel
				]
			    ]
			]
			work: func [msg [object!] /local tmp] [
				if msg/command = "353" [; USERS
					if users-new [clear users users-new: no]
					tmp: copy last msg/params
					replace/all tmp "@" ""
					replace/all tmp "+" ""
					append users parse tmp ""
					exit
				]
				if find ["332" "TOPIC"] msg/command [
					insert clear topic/data last msg/params
					show topic
					exit
				]
				if msg/command = "366" [; END OF USERS
					do users-list/init
					show users-list
					users-new: yes
					exit
				]
				if msg/command = "JOIN" [
					if not find users tmp: get-nick msg/from [append users tmp]
					do users-list/init
					show users-list
					exit
				]
				if "PART" = msg/command [
					remove any [find users get-nick msg/from []]
					do users-list/init
					show users-list
					if me? msg/from [close]
					exit
				]
				if "KICK" = msg/command [
					remove any [find users get-nick msg/params/2 []]
					do users-list/init
					show users-list
					if me? msg/params/2 [close]
					exit
				]
				out/append-message msg channel
			]
			win: none
			orig-size: none
			open: func [] [
				out: none
				repend channels [channel self]
				win: view/new/options/title make layout [
					space 0
					styles sty
					backdrop
					topic: chat-field 500 green [
						insert conn ['topic channel value]
						unfocus
					]
					guide
					out: chat-box 300x100
					chat-field 500 [input value]
					return
					pad -200x0
					users-list: text-list 100x100 data users [user: value]
					return
					; pad -100x0
					tmp: button-list 100x100
					do [tmp/channel: self]
				] [mem-size: min-size: size] [resize] rejoin [nick "@" channel "@" server]
				orig-size: win/size
				win/feel: make win/feel [
					engage: func [face action event] [
						if action = 'close [
							close
							insert conn ['part channel "Window closed"]
						]
						if action = 'resize [
							win/size: max win/size orig-size
							show win
							resize-face/deep win 100x100
							do users-list/init
							show users-list
							out/message-start: 0x0
							out/message-offset: out/wrap-pane/offset next out/pane 0x0
							out/move-pane 1
							show win
						]
					]
				]
			]
			close: func [] [
				remove/part find channels channel 2
				unview/only win
			]
		]]

		connect: does [
			conn: open rejoin [irc:// nick "@" server ":" port-id "/" real-name]
			conn/sub-port/awake: func [port] [
				awake
				no
			]
			append system/ports/wait-list conn/sub-port
			win: view/new layout [
				styles sty
				backdrop
				title rejoin [nick "@" server]
				out: chat-area 600x300
				in: chat-field 600 [error-do out [
					if value: plugin-inputs value [
						insert conn value
					]
				]]
			]
			win/feel: make win/feel [
				engage: func [face action event] [
					if action = 'close [error? try [
						error? try [close conn]
						remove find system/ports/wait-list conn/sub-port
						foreach [tmp channel] copy channels [
							channel/close
						]
					]]
				]
			]
		]
	]
	insert-event-func func [face event] [
		if all [find [close resize] event/type event/face in event/face/feel 'engage] [
			event/face/feel/engage event/face event/type event
		]
		event
	]
	init-plugins
	plugin-window: make object! [
	    win: none
	    titles: none
	    title: ""
	    author: ""
	    version: ""
	    active: none
	    hot: none
	    tl: none
	    delete-button: none
	    
	    close: does [
		if win [unview/only win]
	    ]
	    open: does [
		close
		titles: copy []
		foreach plugin plugins [append titles plugin/title]
		clear title
		clear author
		clear version
		hot: none
		open-win: close-win: none
		win: view/new/title layout [
			styles sty
			backdrop
			
			across
			tl: text-list 150x200 data titles [
				foreach plugin plugins [
				    if plugin/title = value [
					hot: plugin
					insert clear title value
					insert clear author plugin/author
					insert clear version plugin/version
					active/state: plugin/active?
					show active
					show delete-button
					either found? get in hot 'open-window [
						show open-win
						show close-win
					] [
						hide open-win
						hide close-win
					]
					show win
					break
				    ]
				]
			]
			guide
			h2 100 "Name:" h3 200 (title)
			return
			h2 100 "Author:" h3 200 author
			return
			h2 100 "Version:" h3 200 version
			return
			pad 40x40
			return
			active: toggle "Disabled" "Enabled" [if hot [
				hot/active?: value
			]] (yes = all [hot hot/active?]) with [show?: no]
			open-win: button "Open window" with [show?: no] [hot/open-window]
			close-win: button "Close window" with [show?: no] [hot/close-window]
			return
			button "Download all" [use [base] [
				base: http://proton.cl-ki.uni-osnabrueck.de/irc-plugins/
				foreach file to-block load base/irc-plugins.r [
					write base-dir/plugins/:file read base/:file
				]
				init-plugins
				open
			]]
			delete-button: button "Delete" [use [tmp] [if hot [error? try [
			   if request rejoin ["Delete Plugin: >" hot/title "< ?"] [
				tmp: hot/plugin-file
				delete base-dir/plugins/:tmp
				remove find plugins hot
				open
			   ]
			]]]] with [show?: no]
		] "IRC-Plugins"
		error? try [
			insert tl/picked first tl/data
			do-face tl first tl/picked
			show win
		]
	    ]
	]
	context [
		server: nick: port-id: real-name: none
		view/new layout [
			styles sty
			backdrop
			across
			text "Server"	tab server: field "irc.leo.org"
			return
			text "Port" tab port-id: field "6667"
			return
			text "Nick"	tab nick: field "FXTest"
			return
			text "Real Name" tab real-name: field
			return
			button "Connect" [use [conn] [
			   if error? try [
				conn: make connection []
				conn/server: copy server/data
				conn/nick: copy nick/data
				conn/port-id: to-integer port-id/data
				conn/nick: copy nick/data
				conn/connect
			   ] [
				inform layout [h2 "Connect error" button "OK"]
			   ]
			]]
			button "Plugins" [plugin-window/open]
		]
	]
	while [error? try [do-events]] []
]
