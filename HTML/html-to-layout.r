REBOL []


html-to-layout: func [html [block!] /local out tag-data sizes tag name description data] [
	out: copy [across space 1x1 origin 0x0 at 0x0 size 999999999x100000]
	tag-data: [
	"H1"	[size 1] [return pad 0x10] [return]
	"H2"	[size 2] [return pad 0x10] [return]
	"H3"	[size 3] [return pad 0x10] [return]
	"H4"	[size 4] [return pad 0x10] [return]
	"H5"	[size 5] [return pad 0x10] [return]
	"H6"	[size 6] [return pad 0x10] [return]
	"P"	[] [return pad 10x10] [return]
	"BR"    [] [return] []
	"TITLE" [no-show] [] []
	"B"	[bold] [] []
	"A"	[(either tmp: select parse tag "=" "href" [[underline]] [[]])] [] []
	"U"	[underline] [] []
	]
	description: ["root" [size 5]]
	foreach dat html [
	    if tag? dat [
		tag: dat
		name: first parse tag ""
		foreach [nam des act1 act2] tag-data [
			if nam = name [
				append out act1
				des: compose des
				repend description [name append copy last description des]
				; append out act2
			]
		]
		; probe description 
		if all [#"/" = first tag tmp: find/last description first parse next tag ""] [
			clear tmp
		]
	    ]
	    if string? dat [
		data: collect-data last description
		foreach word parse dat "" [
			append out compose [txt (copy word) (data)]
		]
	    ]
	]
	out
]
collect-data: func [descr
	/local size underline sizes tmp1 tmp2 tmp3 out bold
] [
	sizes: [
		1	24
		2	20
		3	18
		4	15
		5	11
		6	10
	]
	size: 6
	underline: no
	bold: no
	if not parse descr [any [
		'size set tmp1 integer! (size: select sizes tmp1)
		| 'underline (underline: yes)
		| 'bold (bold: yes)
		| skip
	]] [print "Parse error"]

	out: compose/deep [font [size: (size)]]
	if underline [append out 'underline]
	if bold [append out 'bold]
	out
]

layout-wrap: func [face /local offset pos height line] [
	offset: 0
	height: 0
	line: none
	foreach f face/pane [
		if (f/offset/x + f/size/x) > face/size/x [
			if (pos + f/size/x) > face/size/x [pos: 0]
			f/offset/x: pos
			if pos = 0 [offset: offset + height]
			pos: f/size/x + f/offset/x
		]
		either line = f/offset/y [
			height: max height f/size/y
		] [
			height: 0
			pos: 0
			line: f/offset/y
		]
		f/offset/y: f/offset/y + offset
	]
	face
]