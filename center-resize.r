REBOL []

center-resize: func [face [object!] center [pair!] /deep /local mem-size changed size] [
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
	if all [deep changed] [center-resize/deep f center - f/offset]
	show f
    ]]
    if mem-size = 'mem-size [
	    face/mem-size: size
    ]
]

if not value? 'fx5-resize-function [
    insert-event-func func [face event] [
	if all [find [close resize] event/type event/face in event/face/feel 'engage] [
		event/face/feel/engage event/face event/type event
	]
	event
    ]
    fx5-resize-function: yes
]


