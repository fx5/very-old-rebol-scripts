REBOL []


irc: make object! [
	irc-protocol: make Root-Protocol [
	    scheme: 'irc
	    port-id: 6667
	    port-flags: system/standard/port-flags/pass-thru or system/standard/port-flags/direct

	    open: func [port /local tmp] [
		open-proto port
		write-io port/sub-port tmp: rejoin [
			"USER " port/user " " system/network/host-address " " port/host " " "Frank" crlf
			"NICK " port/user crlf
		] length? tmp
	    ]
	    copy: func [port /part num /local msg] [
		msg: protocol/work probe first port/sub-port
		if msg/command = "PING" [
			insert port compose ['PONG (msg/params)]
		]
		msg
	    ]
	    insert: func [port data] [
		either all [string? :data data/1 = #"/"] [
			foreach data first protocol/input data [
				insert port data
			]
			port
		] [
			if block? :data [data: message/new/string data]
			if object? :data [data: data/string]
			write-io port/sub-port data: join form data "^M^/" length? data
			port
		]
	    ]

	    net-utils/net-install :scheme self port-id
	]

	message: make object! [
		command: none
		params: []
		from: none

		new: func [
			block [block!]
			/string
			/local new named pos tmp
		] [
			new: make self [
			   (
				named: [
					'from pos: (set [from pos] do/next pos) :pos
				]
				if not parse block [
					any named 
					pos: (set [command pos] do/next pos) :pos
					any [
						named
						| pos: skip (set [tmp pos] do/next pos append params tmp) :pos
					]
				] [
					make error! "parse error"
				]
				new: none
			   )
			]
			either string [new/string] [new]
		]
		string: func [ ] [
			rejoin [
				either from [join join ":" from " "] [""]
				command
				" "
				form copy/part params (length? params) - 1
				" "
				either not empty? params [join ":" last params] [""]
			]
		]
	]

	protocol: make object! [
		work: func [string [string!]] [
			out: make message [new: none]
			if not parse/all string root [
				make error! "parse error"
			]
			out
		]
		input: func [
			string [string!]
			/target target-name [any-string!]
			/local tmp1 tmp2 tmp3 out non-slash need-channel
		] [
			non-slash: complement charset "/"
			if not target [non-slash: charset ""]
			out: array [2 0]
			need-channel: [
				(if not target [make error! "Only allowed for channels"])
			]
			if not parse/all string [
				"/" [
				    "msg"
					space copy tmp1 c-to space copy tmp2 trailing
					(
						append out/1 tmp1: message/new ['PRIVMSG tmp1 tmp2]
						append out/2 tmp1
					)
				    | "join"
					space copy tmp1 channel (
						append out/1 message/new ['JOIN tmp1]
					)
				    | "kick" [
					space copy tmp1 channel space copy tmp2 nick [space copy tmp3 to end | opt space (tmp3: none) end] (
						if none? tmp3 [tmp3: []]
						append out/1 message/new ['kick tmp1 tmp2 tmp3]
					)
					| space copy tmp1 nick [space copy tmp2 to end | opt space (tmp2: none) end] need-channel (
						if none? tmp2 [tmp2: []]
						append out/1 message/new ['kick target-name tmp1 tmp2]
					)
				    ]
				]
				| copy tmp1 [non-slash to end] (
						append out/1 tmp1: message/new ['PRIVMSG target-name tmp1]
						append out/2 tmp1
				)
			] [
				make error! "Bad input"
			]
			out
		]
		out: none
		tmp: none

		root: [
			opt [":" copy tmp prefix (out/from: tmp) space]
			copy tmp command (out/command: tmp)
			params
		]
		prefix: [servername | nick opt [ "!" user ] opt [ "@" host ]]
		command: [some letter | 3 number]
		params: [space opt [
			":" copy tmp trailing (append out/params tmp)
			| copy tmp middle (append out/params tmp) [params |]
		]]

		middle: [middlechars any [":" | middlechars]]
		middlechars: complement charset " ^@^M^/:"
		
		trailing: [any trailingchars]
		trailingchars: complement charset "^@^M^/"

		space: [some " "]
		target: [c-to opt "," target]
		c-to: [
			channel
			| user "@" server 
			| nick
			| mask
		]
		channel: [
			["#" | "&"] chstring
		]
		servername: [host]
		host-chars: complement charset [" ^/^M"]
		host: [ some host-chars ]
		nick: [letter any [letter | number | special]]
		mask: [["#" | "$"] chstring]
		chstring: [any chchars]
		chchars: complement charset [" ^G^@^M^/,"]

		nonwhite: complement charset "^/^M ^T"
		user: [some nonwhite]
		letter: charset [#"a" - #"z" #"A" - #"Z"]
		number: charset [#"0" - #"9"]
		special: charset "-[]\`^{}"
	]
]
