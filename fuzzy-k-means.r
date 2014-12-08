REBOL [
	title: "Fuzzy-k-means"
	author: "Frank Sievertsen"
	date: 27-10-2000
]

recycle/off

if not value? 'k [
	k: 3   ; Anzahl der Klassen
]
if not value? 'd [
	d: 2
]

file: http://www-lehre.inf.uos.de/~soft/Uebung/blatt2/digits.pat

; Einige Hilfsfunktion zur Vektorrechnung
map: func [
	{Wendet auf arg1 die Funktion func mit arg2 an.
	 Beispiel: map [1 2 3] :+ [3 2 1]   ergibt: [4 4 4]
        }  [catch]
	arg1 [block! number!]
	func [any-function! string!] "Die Funktion muss direkt oder als String gegeben werden"
	arg2 [block! number!]
	/local a2 out length
] [
	if all [block? arg1 block? arg2 (length? arg1) <> (length? arg2)] [
		throw make error! [user message "unterschiedliche laenge!"]
	]
	if string? :func [func: get/any to-word func]
	if number? arg1 [arg1: array/initial length? arg2 arg1]
	out: make block! length? arg1 
	foreach a1 arg1 [
		either number? arg2 [a2: arg2] [a2: first arg2 arg2: next arg2]
		append out do :func a1 a2
	]
	out
]

summe: func [
	{ Berechnet eine Mathematische Summe (wie das Summenzeichen)
	  Beispiel: summe j 10 [j + 1]   ergibt: 65
	}
	'var [word!]		"Die Laufvariable"
	max-val [integer!]	"Bis zu diesem Wert (von eins an) laufen"
	body [block!]		"Und diesen Block ausrechnen"
	/local sum val
] [
	var: use to-block var to-block to-lit-word var ; Eigenen Context erzeugen
	body: bind copy body var                       ; Koerper an den Context binden
	sum: 0
	repeat z max-val copy/deep [
		set var z
		val: do body
		either block? val [sum: map sum :+ val] [sum: sum + val]
	]
	sum
]

v-len: func [
	"Berechnet die Laenge eines Vektors"
	vektor [block!]
	/local sum
] [
	sum: 0
	foreach val vektor [
		sum: sum + (val ** 2)
	]
	square-root sum
]

; Datei einlesen

if unset? get/any 'vektoren [use [nums zahl vektor] [
	vektoren: []
	nums: charset "1234567890"
	vektor: copy []
	if not parse/all trim to-string read-thru file [
		some [
			copy zahl some nums
				(append vektor to-decimal zahl)
			| " "
			| newline newline
				(append/only vektoren vektor)
				(vektor: copy [])
			| newline
	]	] [
		print "Datei konnte nicht geparsed werden"
		quit
	]
]]

; Jetzt enthaelt 'vektoren alle Vektoren

; Initialisierung
use [tmp B n] [
	; Zufallsgenerator initialisieren
	random/seed now

	; A enthaelt die Klassen
	A: array reduce [k length? vektoren 1]

	; B dient zur spaeteren Normierung
	B: array/initial reduce [length? vektoren 1] 0

	foreach Ai A [
		; Ai ist die aktuelle Klasse
		repeat n length? vektoren [
			Ai/:n/1: tmp: (random 10000) / 10000
			B/:n/1: b/:n/1 + tmp
		]
	]

	; Und normieren
	foreach Ai A [
		repeat n length? vektoren [
			Ai/:n/1: Ai/:n/1 / B/:n/1
		]
	]
]

; Jetzt enthaelt A zufaellige Initialisierungen zwischen 0 .. 1

; Jetzt der eigentliche Algorithmus
use [unter j old-E] [
	; v enthaelt die Klassenmittelpunkte
	v: array reduce [k 1]
	forever [recycle
		; Klassenmittelpunkte v/i berechnen
		repeat i k [
			oben: array/initial length? vektoren/1
			unten: 0   ; Das sind die beiden Summen
			           ; Ueber bzw. unter dem Bruchstrich
			j: 0
			v/:i/1: map 
				summe j length? vektoren [map A/:i/:j/1 ** d :* vektoren/:j]
				"/"
				summe j length? vektoren [A/:i/:j/1 ** d]
		]
		; Zuordnung berechnen
		repeat j length? vektoren [
			if error? try [
				unten: summe i k [1 / ((v-len (map vektoren/:j :- v/:i/1)) ** 2) ** (1 / (d - 1))]
			] [unten: 1e10]		   ; Bei Division durch 0 -> 0 setzen
			repeat i k [
				if error? try [
				a/:i/:j/1:
					(1 / ((v-len (map vektoren/:j :- v/:i/1)) ** 2) ** (1 / (d - 1)))
					/
				        unten
				] [a/:i/:j/1: 1]   ; Bei Division durch 0 -> 1 setzen
			]
		]
		print E: summe j k [
			summe i length? vektoren [
				A/:j/:i/1 ** d * ((v-len map vektoren/:i :- v/:j/1) ** 2)
			]
		]
		if value? 'to-do [to-do]
	]
]

