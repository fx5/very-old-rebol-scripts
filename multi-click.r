REBOL [
	title: "multi-click"
	author: "Frank Sievertsen"
	version: 1.0.0
	purpose: {
		detects double(...)-clicks

		do %multi-click.r
		view layout [
			f: txt 100 "Detector" center
			button "Test" [
				multi-click face [
					[f/text: "One time"]
					[f/text: "Two times"]
					[f/text: "Three times"]
					[f/text: "Four times"]
				]
				show f
			]
		]
	}
]

multi-click: func [
	"Checks for multi-click"

	face [object! word! number! any-string!]
					"The clicked face or id"
	clicks [block!]			"What to do?"
	/max				"Set double-click time"
		max-time [time!]	"default: 00:00:00.5"
	/right				"Right mouse button"

	/local mem tmp
] [
	mem: [0 1-1-01/0:0 0 1-1-01/0:0 0 ]
	if right [mem: skip mem 3]
	if not max [max-time: 0:0:0.5]
	either all [
		same? face mem/1
		mem/2 + max-time >= now/precise
	] [
		mem/3: mem/3 + 1
		do pick clicks mem/3 + 1
	] [
		mem/3: 0
		mem/1: face
		do pick clicks 1
		none
	]
	mem/2: now/precise
]

