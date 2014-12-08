REBOL [
	title: "form-error"
	author: "Frank Sievertsen"
	date: 28-Jun-2000
	version: 0.0.1
]

form-error: func [error [object! error!] /local desc pre wo] [
	if error? error [error: disarm error]
	do bind [
		desc: system/error/:type/:id
		pre: system/error/:type/type
		wo: near
	] in error 'code
	rejoin [
		"** " pre ": "
		either block? desc [reform bind desc in error 'code] [desc]
		newline
		"** Where: " copy/part form copy/part wo 10 60
	]
]
