REBOL [
	title: "URL Grabber"
	author: "Frank Sievertsen"
	version: 0.0.1
	type: 'irc-plugin
]

input: func [str [string!] conn [object!] /local chat nick] [
	if str = "/url" [
		open-window
		return none
	]
	str
]

url-chars: charset [
	#"a" - #"z"
	#"A" - #"Z"
	#"0" - #"9"
	"./_-~"
]

url-scheme: [
	"http:"
	| "ftp:"
]

url-data: [
	url-scheme some url-chars
]

message: func [msg [object!] conn [object!] /local url] [
	all [
		not empty? msg/params
		string? last msg/params
		parse/all last msg/params [any [
			copy url url-data (
				if not find urls url [
					append urls url
					sort urls
					do url-list/init
					show url-list
				]
			)
			| skip
		]]
	]
]

url-list: none
urls: []

lay: layout [
	styles sty backdrop
	url-list: text-list 300x300 data urls [error? try [
		browse to-url value
	]]
]

open-window: does [
	close-window
	view/new/title win: lay "URL-Grabber"
]
