; rdf.inc - definitions for the room scripts in src/rdf (MASM 5.0)
;
; A room's .RDF file is a single segment, loaded whole at offset 0 and
; called with CS = the file (CallScript in src/seg008.c). It holds the Rdf
; header (include/room.h), the scripts, which are 16-bit machine code, and
; their data. Scripts run with SI = DS:&room (the RoomState); they reach
; the engine through the far pointer at offset 0 (ScriptService), C style:
; the arguments pushed right to left, then the command, and the caller pops
; them. Everything is addressed from the start of the file, so the source
; is one segment, RDF, assembled at offset 0.

	.286

; ---------------------------------------------------------------- service
; ScriptService commands: service(cmd, a1, a2, a3, a4, a5). Results come
; back in DX:AX.
RC_ANIM0	EQU	0	; (actor, name, x, y, msg) play name.anm; same as RC_ANIM2
RC_STOPANIM	EQU	1	; (actor) end it, or stand
RC_ANIM2	EQU	2	; (actor, name, x, y, msg) actors 0-7 scaled for depth;
				;   x or y -1: where the actor is; msg: MSG_ANIM_DONE arg
RC_TALK		EQU	3	; (conv) conversation table; returns the choice
RC_GIVEITEM	EQU	4	; (item)
RC_LEVERS	EQU	5	; () the lever puzzle
RC_GOTOROOM	EQU	6	; (room, entrance) does not return
RC_TAKEITEM	EQU	7	; (item)
RC_WALK		EQU	8	; (crew, x, y, msg) msg: MSG_WALK_DONE arg
RC_LOADMAP	EQU	9	; (name) the room's walk map
RC_FLASHBMP	EQU	10	; (name)
RC_HAVEITEM	EQU	11	; (item) returns 1 if carried
RC_ITEMCASE	EQU	12	; (mask)
RC_ACTORPOS	EQU	13	; (actor) returns x | y << 16
RC_RANDOM	EQU	14	; (lo, hi) returns lo..hi
RC_BRIDGESFX	EQU	15	; (n)
RC_MUSIC	EQU	16	; (a, b)
RC_BEAMUP	EQU	17	; (score, max score, outcome) end the mission; the
				;   outcome picks the bridge's ending (0 usual, 1 and
				;   2 failures: seg030)
RC_GAMEOVER	EQU	18	; () then falls into RC_INPUTCODE
RC_INPUTCODE	EQU	19	; (codes) NUL separated, "" ends; returns 1-based match or 0
RC_TURBOLIFT	EQU	20	; (unused, deck)
RC_SFX		EQU	21	; (name)
RC_BAD		EQU	22	; Fatal("unknown room cmd")
RC_DIGIOFF	EQU	23	; () shut digital sound down

; ---------------------------------------------------------------- messages
; A script's key: message type, then three argument bytes. RunWildScripts
; treats FFh in a script's key as "anything".
MSG_TICK	EQU	0	; ticks low, ticks high
MSG_WALK	EQU	1	; object
MSG_USE		EQU	2	; object, used on
MSG_GET		EQU	3	; object
MSG_LOOK	EQU	4	; object
MSG_TALK	EQU	5	; object
MSG_EXIT	EQU	6	; exit polygon Kirk walked into
MSG_REGION	EQU	7	; region polygon Kirk walked into
MSG_TIMER	EQU	8	; room timer 0-7
MSG_ANIM_DONE	EQU	10	; the animation's msg
MSG_WALK_DONE	EQU	12	; the walk's msg
ANY		EQU	0FFh

; ---------------------------------------------------------------- objects
; 0-3 the crew, 8-1Fh room actors, 20h-3Fh room polygons, 40h-88h items
OBJ_KIRK	EQU	0
OBJ_SPOCK	EQU	1
OBJ_MCCOY	EQU	2
OBJ_REDSHIRT	EQU	3
OBJ_INVENTORY	EQU	1Fh

IT_PHASERS	EQU	040h
IT_PHASERK	EQU	041h
IT_HAND		EQU	042h
IT_ROCK		EQU	043h
IT_STRICOR	EQU	044h
IT_MTRICOR	EQU	045h
IT_DEADGUY	EQU	046h
IT_COMM		EQU	047h
IT_PBC		EQU	048h
IT_RLG		EQU	049h
IT_WRENCH	EQU	04Ah
IT_INSULAT	EQU	04Bh
IT_SAMPLE	EQU	04Ch
IT_CURE		EQU	04Dh
IT_DISHES	EQU	04Eh
IT_RT		EQU	04Fh
IT_RTWB		EQU	050h
IT_COMBBIT	EQU	051h
IT_JNKMETL	EQU	052h
IT_WIRING	EQU	053h
IT_WIRSCRP	EQU	054h
IT_PWF		EQU	055h
IT_PWE		EQU	056h
IT_DEADPH	EQU	057h
IT_BOMB		EQU	058h
IT_METAL	EQU	059h
IT_SKULL	EQU	05Ah
IT_MINERAL	EQU	05Bh
IT_METEOR	EQU	05Ch
IT_SHELLS	EQU	05Dh
IT_DEGRIME	EQU	05Eh
IT_LENSES	EQU	05Fh
IT_DISKS	EQU	060h
IT_ANTIGRA	EQU	061h
IT_N2GAS	EQU	062h
IT_O2GAS	EQU	063h
IT_H2GAS	EQU	064h
IT_N2O		EQU	065h
IT_NH3		EQU	066h
IT_H2O		EQU	067h
IT_WROD		EQU	068h
IT_IROD		EQU	069h
IT_REDGEM1	EQU	06Ah
IT_REDGEM2	EQU	06Bh
IT_REDGEM3	EQU	06Ch
IT_GRNGEM1	EQU	06Dh
IT_GRNGEM2	EQU	06Eh
IT_GRNGEM3	EQU	06Fh
IT_BLUGEM1	EQU	070h
IT_BLUGEM2	EQU	071h
IT_BLUGEM3	EQU	072h
IT_CONECT	EQU	073h
IT_S8ROCKS	EQU	074h
IT_IDCARD	EQU	075h
IT_SNAKE	EQU	076h
IT_FERN		EQU	077h
IT_CRYSTAL	EQU	078h
IT_KNIFE	EQU	079h
IT_DETOXIN	EQU	07Ah
IT_BERRY	EQU	07Bh
IT_DOOVER	EQU	07Ch
IT_ALIENDV	EQU	07Dh
IT_CAPSULE	EQU	07Eh
IT_MEDKIT	EQU	07Fh
IT_BEAM		EQU	080h
IT_DRILL	EQU	081h
IT_HYPO		EQU	082h
IT_FUSION	EQU	083h
IT_CABLE1	EQU	084h
IT_CABLE2	EQU	085h
IT_LMD		EQU	086h
IT_DECK		EQU	087h
IT_TECH		EQU	088h

; ---------------------------------------------------------------- room
; RoomState fields (include/room.h), as offsets from SI
RS_TIMERS	EQU	00h	; 8 words; MSG_TIMER when one reaches 0
RS_SAVED_X	EQU	10h
RS_SAVED_Y	EQU	12h
RS_STUN		EQU	14h	; 4 words: crew stunned for this many ticks
RS_NO_WALK	EQU	1Ch
RS_BUSY		EQU	1Dh	; the player can't act
RS_REDSHIRT_DEAD EQU	1Eh
RS_ACTION	EQU	1Fh	; 1 walk, 2 use, 3 get, 4 look, 5 talk
RS_TARGET	EQU	20h
RS_TARGET2	EQU	21h
RS_UNK22	EQU	22h
RS_MORE		EQU	23h	; set: keep looking for scripts with this key
RS_FLAGS	EQU	24h	; bits 0-3 crew stunned
RS_FALL		EQU	25h	; 4 bytes: the way (0-3: n s e w) each crew member
				;   faces when their walk ends or they get up; FFh none
RS_VARS		EQU	29h	; 100h bytes for the scripts

; ---------------------------------------------------------------- macros
; A script: its key and the offset of the next script. The engine follows
; the chain from Rdf.scripts while it stays below Rdf.scripts_end.
SCRIPT	MACRO	t, a, b, c, next
	DB	t, a, b, c
	DW	OFFSET next
	ENDM

; Call ScriptService through the header's far pointer
SERVICE	MACRO
	call	dword ptr cs:rdf_service
	ENDM

; jmp with a 16-bit displacement: MASM 5.0 turns "jmp NEAR PTR" into a
; short jump whenever the target is in range
JMPN	MACRO	t
	DB	0E9h
	DW	t-($+2)
	ENDM

; op ax, n with n sign-extended from a byte (83h /r ib): MASM 5.0 always
; uses the accumulator form (3Dh iw for cmp) instead
AX8	MACRO	op, n
	DB	83h
	IFIDNI	<op>, <add>
	DB	0C0h
	ENDIF
	IFIDNI	<op>, <or>
	DB	0C8h
	ENDIF
	IFIDNI	<op>, <and>
	DB	0E0h
	ENDIF
	IFIDNI	<op>, <sub>
	DB	0E8h
	ENDIF
	IFIDNI	<op>, <xor>
	DB	0F0h
	ENDIF
	IFIDNI	<op>, <cmp>
	DB	0F8h
	ENDIF
	DB	n
	ENDM
