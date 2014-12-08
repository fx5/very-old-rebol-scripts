REBOL [
	title: "FX5-Request-File"
	author: "Frank Sievertsen"
]

use [do-thru] [
do-thru: func [url /local tmp] [
	load-thru/update url
	tmp: load-thru url
	if none? tmp [
		inform layout [backdrop 200.200.200 h1 "Unable to load" txt form url]
		quit
	]
	do tmp
]

if not value? 'fx5-styles [
	do-thru http://proton.cl-ki.uni-osnabrueck.de/REBOL/fx5-styles.r
]
if not value? 'menu-styles [
	do-thru http://proton.cl-ki.uni-osnabrueck.de/REBOL/fx5-menu.r
]
if not value? 'multi-click [
	do-thru http://proton.cl-ki.uni-osnabrueck.de/REBOL/multi-click.r
]
]



context [

system/words/fx5-request-file: func [
/title
	title-line [string!]
	button-text [string!]
/file
	name [file! url!]
/local file1 file2 dir content img1 img2 sorter rows tmp
	shift slide dir-field file-list new-dir hit
	file-field pattern-field file pattern lay oldies
	pos ok to-file-url
] [
oldies: []
rows: 19
shift: 0
file: ""
pattern: ""
to-file-url: func [file [string!] /local tmp] [
	either all [
		not error? try [tmp: load file]
		url? get/any 'tmp
	] [
		tmp
	] [
		to-file file
	]
	
]
sorter: func [a b /local dira dirb] [
	dira: found? find a "/"
	dirb: found? find b "/"
	not not any [
		dira and not dirb
		all [dira = dirb (to-string a) <= (to-string b)]
	]
]

dir: what-dir
do new-dir: does [
	content: copy []
	error? try [content: read dir]
	if not empty? pattern [
		while [not empty? content] [
			content: either all [
				tmp: find/any/match first content pattern
				empty? tmp
			] [
				next content
			] [either not find first content "/" [
				remove content ][ next content
			]]
		]
		content: head content
	]
	sort/compare content :sorter
]
if not title [
	title-line: "Choose a file..."
	button-text: "Ok"
]
hit: func [col row /local file ori] [
	if not ori: file: pick content col + shift - 1 * rows + row [exit]
	file: clean-path dir/:file
	either dir? file [
		dir-field/text: to-string file
		dir-field/action dir-field file
	] [
		multi-click ori [[] [ok: yes hide-popup]]
		insert clear file-field/text ori
		show file-field
	]
]
lay: layout [
	space 0
	styles fx5-styles
	backdrop
	pad 0x5
	H2 title-line
	across
		dir-field: field 470 to-string dir
		[
			dir: to-file-url dir-field/text
			new-dir
			show file-list
			slide/data: 0
			shift: 0
			slide/auto-redrag
			unfocus
			show dir-field
		]
		button "Up" 30x25 [
			dir-field/text: to-string first split-path dir
			dir-field/action dir-field dir-field/text
		]
	below
	
		file-list: list 500x300 255.255.255 [across at 0x0 space 0
			img1: image 16x16 255.255.255
				feel [redraw: func [face] [
					face/image: either find file1/text "/" [dir.png] [file.png]
					if empty? file1/text [face/image: none]
				]]
				[hit 1 file1/user-data]
			file1: txt 250x15 - 15x0 0.0.0 255.255.255 left
				[hit 1 file1/user-data]
				with [font: [colors: [0.0.0 0.0.0]]]
			img2: image 16x16 255.255.255
				feel [redraw: func [face] [
					face/image: either find file2/text "/" [dir.png] [file.png]
					if empty? file2/text [face/image: none]
				]]
				[hit 2 file2/user-data]
			file2: txt 250x15 - 15x0 0.0.0 255.255.255 left
				[hit 2 file2/user-data]
				with [font: [colors: [0.0.0 0.0.0]]]
		] supply [
		    either all [
				count <= rows
				tmp: pick content shift * rows + count
		    ] [
			file1/text: to-string tmp
			tmp: pick content shift + 1 * rows + count
			file2/text: either tmp [to-string tmp] [""]
		    ][
			file1/text: file2/text: ""
		    ]
		    file1/user-data: file2/user-data: count
		] with [
			edge: [color: 188.188.188]
		]
	slide: slider 500x13
		with [auto-redrag: func [/local tmp] [
			slide/redrag tmp: rows * 2 / (,01 + length? content)
			slide/show?: tmp < 1
			if slide/parent-face [show slide/parent-face]
		]]
		[
			tmp: to-integer (length? content) / rows * value
			if tmp <> shift [
				shift: tmp
				show file-list
			]
		]
	do [slide/auto-redrag]

	pad 5

	across

		label "File"	50x20 left
		file-field: field file 396x20 [hide-popup]
		pad 4
		button button-text	50x20
		[ok: yes hide-popup]
	return pad 0x2
		label "Pattern"	50x20 left
		pattern-field: field pattern 396x20 [new-dir show file-list unfocus]
		pad 4
		button "Cancel"	50x20
		[hide-popup]
	pos: at
	styles menu-styles
	menu  [
		"File" sub [
			"Ok" [hide-popup ok: yes]
			"Cancel" [hide-popup]
			---
			(oldies)
		]
		"Help" sub [
				"About" [
					inform layout [
						styles fx5-styles
						backdrop
						title "FX5-Request-File"
						label "by Frank Sievertsen"
						button "OK" [hide-popup]
					]
				]
			]
		]
		; text "hi"
	]
	lay/size: pos + 15x35
	lay/options: [resize]
	inform lay
	if ok [use [ori] [
		ori: file
		file: clean-path dir/:file
		if not find oldies tmp: to-string file [
			insert oldies reduce [tmp
				compose [dir: (copy dir) file: (copy ori) hide-popup ok: yes]
			]
		]
		file
	]]
]

dir.png: load 64#{iVBORw0KGgoAAAANSUhEUgAAABAAAAANCAIAAAAv2XlzAAAAE3RFWHRTb2Z0d2FyZQBSRUJPTC9WaWV3j9kWeAAAAGdJ
	REFUeJxj+A8G584lw9GcOcn/cQMGiOr3z4vh6Nw1fHoYoAZfS0a2BCuCmALS8B0P+I9gADUAAUzD+xaCiGwN11A1fKe+
	DbTS8B1Zw38SbcCOMKISpCEqmQGkKyoZHUQlYxdPTgYA6SPQ4AYG1EwAAAAASUVORK5CYII=
}
file.png: load 64#{iVBORw0KGgoAAAANSUhEUgAAAA0AAAAQCAIAAABCwWJuAAAAE3RFWHRTb2Z0d2FyZQBSRUJPTC9WaWV3j9kWeAAAAHNJ
REFUeJyNkcEVwCAIQxneo3NxdKUWG0sBRZuDT/EbMVKZVb/p9YrsIogb6+6WY5YRAMktGUdWGz91dVypMu+VA/cQC9Rx
so1+EIpFF34o4Y2KSjrDQI+OCLxr9LOuapxyGlva3ym//D+iX2+ncSq896dus6OnJsh/Bq4AAAAASUVORK5CYII=}

]
