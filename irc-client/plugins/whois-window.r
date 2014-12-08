REBOL [
	title: "Whois Windows"
	author: "Frank Sievertsen"
	version: 1.0.0
	type: 'irc-plugin
]

message: func [msg [object!] conn [object!] /local] [
	if msg/command = "311" [
		view/new win
		insert clear nick/text msg/params/2
		insert clear real-name/text msg/params/6
		insert clear host/text rejoin [msg/params/3 "@" msg/params/4]
		clear area/text
		area/line-list: none
		show [area nick real-name host]
	]
	if all [
		find ["312" "313" "317" "318" "319"] msg/command
		msg/params/2 = nick/text
	] [
		append area/text join form next next msg/params "^/^/"
		area/line-list: none
		show area
	]
]
nick: area: host: real-name: none
win: layout [
	styles sty backdrop
	nick: h1 400
	host: h2 400
	real-name: h2 400

	area: area 400x200 wrap feel [engage: none]
]
win/text: "Whois"

open-window: does [view/new win]
close-window: does [unview/only win]
