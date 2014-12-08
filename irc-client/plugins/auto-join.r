REBOL [
	title: "Auto-Join"
	author: "Frank Sievertsen"
	version: 0.0.1
]


data-file: join irc-system/base-dir "plugin-data/auto-join.r"

channels: []
error? try [
	append channels load data-file
]

in-field: none
tl: none

open-window: func [] [
	close-window
	win: view/new center-face layout [
		styles sty backdrop
		text "Channels"
		guide
		tl: text-list data channels
		return button "Delete" [
			remove any [find channels tl/picked/1 []]
			show tl
			save/header data-file channels []
		]
		across
		in-field: field
		button "Add" [if not empty? in-field/data [
		   if not find channels in-field/data [
			append channels copy in-field/data
			show tl
			save/header data-file channels []
		   ]
		]]
	]
]

message: func [msg [object!] conn [object!]] [
	if msg/command = "001" [foreach channel channels [
		insert conn/conn ['JOIN channel]
	]]
]
