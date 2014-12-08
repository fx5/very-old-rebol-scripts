REBOL []

print "ok"
do %wrap-html.r
do %scroll-panel.r
; do %own-context.r
do %html-to-layout.r

rebrowse: func [url] [
	url: to-url url
	either error? try [
		html: parse-html to-url url
	] [
		tmp: layout [h1 "ERROR RETRIEVING"]
		p/pane: tmp/pane				
	] [
		tmp: layout html-to-layout html
		p/pane: tmp/pane
		layout-wrap p
	]
]

view layout [
	styles scroll-panel-style
	across
	space 0x0
	url-field: field 400 "file:test.html" [use [html tmp] [
		rebrowse url-field/data
		s1/to-vals: s2/to-vals: none
		show p show s1 show s2
	]]
	return
	p: panel 400x400
	[
		h1 "Welcome to REBrowse"
		h2 "This one is only a simple html-viewer"
		h3 "Don't expect too much ;)"
	] do [p: p/parent-face p/color: 255.255.255]
	s1: panel-slider 15x400 to p
	return
	s2: panel-slider 400x15 to p
]