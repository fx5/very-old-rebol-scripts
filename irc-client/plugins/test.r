REBOL [
	title: "Test Plugin"
	author: "Frank Sievertsen"
	version: 0.0.1
	type: 'irc-plugin
]

open-window: func [] [
	close-window
	win: view/new center-face layout [
		styles sty
		backdrop
		title "Here I am"
	]
]
