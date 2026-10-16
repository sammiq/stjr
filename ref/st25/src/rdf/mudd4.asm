; MUDD4.RDF - "Another Fine Mess", the alien ship's bridge. Two stations:
; Spock works out that the aliens count in sixes, the clue for the library
; (room 3); with the library decoded, the secondary station shows sensors,
; navigation and engineering, and the primary works the viewscreen and
; communications. Through these, once Spock has studied the weapons
; battery (room 1), Kirk reaches Scott, ends the mission, and has a last
; word with Mudd.
;
; Actors: 8 the viewscreen, 10 (0Ah) the doover, 11 (0Bh) Mudd.
; Objects: 0Ah the doover, 20h the viewscreen, 21h-23h the stations.
; Exits: 2 room 2, 3 room 3. Region 0: the doorsteps.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 0EAA: the engine reads its bytes
;   as key 50 6A 03 2E and next 1EFF (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
knows_battery	EQU	RS_VARS+0Bh	; Spock has studied the weapons battery (room 1), and can reach the Enterprise
six_clue	EQU	RS_VARS+0Ch	; Spock has noticed the aliens' fixation on six
know_physiology	EQU	RS_VARS+0Dh	; the library is decoded (room 3)
library_erased	EQU	RS_VARS+0Eh	; Mudd has wiped the databanks (room 3)
mudd_allowed	EQU	RS_VARS+12h	; Kirk let Mudd at the library (room 3)
used_device	EQU	RS_VARS+13h	; the alien device has been fired, anywhere (+5 once)
take_weapon	EQU	RS_VARS+14h	; Kirk decided to take the weapon (room 1): BeamUp's outcome
mudd_incident	EQU	RS_VARS+16h	; Mudd is causing trouble somewhere: no other scene with him starts
read_library	EQU	RS_VARS+18h	; Spock has retrieved the library's topics (room 3)
took_doover	EQU	RS_VARS+19h
called_scott	EQU	RS_VARS+1Bh	; Kirk has talked to Scott once
viewscreen_on	EQU	RS_VARS+1Ch
air_failing	EQU	RS_VARS+1Dh	; life support is failing: the countdown runs (room 5)
air_left	EQU	RS_VARS+27h	; word: ticks of air left, from 6978h
air_countdown	EQU	RS_VARS+29h	; word: the countdown has started
viewscreen_scored	EQU	RS_VARS+2Eh	; the point for the viewscreen
score	EQU	RS_VARS+31h	; word: the mission's score

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0C7h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	7Fh
rdf_scale_min	LABEL	BYTE
	DW	0C8h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, -1, 2, 3	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	0,0, 0,0	; entrance 0, crew 0
	DW	0,0, 0,0	; entrance 0, crew 1
	DW	0,0, 0,0	; entrance 0, crew 2
	DW	0,0, 0,0	; entrance 0, crew 3
	DW	0,0, 0,0	; entrance 1, crew 0
	DW	0,0, 0,0	; entrance 1, crew 1
	DW	0,0, 0,0	; entrance 1, crew 2
	DW	0,0, 0,0	; entrance 1, crew 3
	DW	225,177, 225,177	; entrance 2, crew 0
	DW	216,189, 216,189	; entrance 2, crew 1
	DW	250,193, 250,193	; entrance 2, crew 2
	DW	253,182, 253,182	; entrance 2, crew 3
	DW	131,182, 131,182	; entrance 3, crew 0
	DW	105,183, 105,183	; entrance 3, crew 1
	DW	159,195, 159,195	; entrance 3, crew 2
	DW	42,187, 42,187	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	131,182, 105,183, 159,195, 42,187	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	131,182, 105,183, 159,195, 42,187
; In the room file, so these start again each time the room loads
spock_primary	LABEL	BYTE	; Spock is going to the primary station
	DB	0
kirk_secondary	LABEL	BYTE	; Kirk is going to the secondary station
	DB	0
collapsed	LABEL	BYTE	; crew members down when the air ran out
	DB	0
going_door	LABEL	BYTE
	DB	0
N_s4crks	LABEL	BYTE
	DB	's4crks',0
N_s4crkl	LABEL	BYTE
	DB	's4crkl',0
N_s4crkr	LABEL	BYTE
	DB	's4crkr',0
N_s4crss	LABEL	BYTE
	DB	's4crss',0
N_s4crsl	LABEL	BYTE
	DB	's4crsl',0
N_s4crsr	LABEL	BYTE
	DB	's4crsr',0
N_s4crvs	LABEL	BYTE
	DB	's4crvs',0
N_s4crvo	LABEL	BYTE
	DB	's4crvo',0
N_s4crvf	LABEL	BYTE
	DB	's4crvf',0
N_kuseln	LABEL	BYTE
	DB	'kuseln',0
N_kgetde	LABEL	BYTE
	DB	'kgetde',0
N_sgetdn	LABEL	BYTE
	DB	'sgetdn',0
N_mgetds	LABEL	BYTE
	DB	'mgetds',0
N_rgetdw	LABEL	BYTE
	DB	'rgetdw',0
N_sscann	LABEL	BYTE
	DB	'sscann',0
N_sscane	LABEL	BYTE
	DB	'sscane',0
N_s4crhw	LABEL	BYTE
	DB	's4crhw',0
N_s4crdv	LABEL	BYTE
	DB	's4crdv',0
N_s4cbxp	LABEL	BYTE
	DB	's4cbxp',0

rdf_scripts:
; The room starts: the doover, the viewscreen if on.
H_0153:
	SCRIPT	MSG_TICK, 1, 0, 0, H_01AD
StartRoom:
	jmp	SHORT L0164

N_MUD4LOOP	LABEL	BYTE
	DB	'MUD4LOOP',0
L0164:
	push	OFFSET N_MUD4LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUD4LOOP")
	add	sp, 4
	cmp	byte ptr [si+took_doover], 0
	jne	L0190
	push	0
	push	8Eh
	push	0C9h
	push	OFFSET N_s4crdv
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "s4crdv", 201, 142, 0)
	add	sp, 0Ch
L0190:
	cmp	byte ptr [si+viewscreen_on], 1
	jne	L01AC
	push	0
	push	76h
	push	0A5h
	push	OFFSET N_s4crvo
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s4crvo", 165, 118, 0)
	add	sp, 0Ch
L01AC:
	retf

H_01AD:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_021B
CallEnterprise:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018
	call	Say
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_STATICU1
	call	Say
	retf

T_MUD4_018	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise...',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
T_STATICU1	LABEL	BYTE
	DB	'#SFX\STATICU1#Ent... neu ... trans...',0

; Timers 2, 3: sounds.
H_021B:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_022E
Timer2Sound:
	push	7
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(7)
	add	sp, 4
	retf

H_022E:
	SCRIPT	MSG_TIMER, 3, 0, 0, H_0241
Timer3Sound:
	push	0Ah
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(10)
	add	sp, 4
	retf

; Spock at the stations: before the library, he notices the aliens count
; in sixes (+1). After it, the secondary station (msg 1): sensors,
; navigation, engineering (anim msgs 2-4).
H_0241:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_0249
	jmp	SHORT SpockToPrimary

H_0249:
	SCRIPT	MSG_USE, OBJ_SPOCK, 22h, 0, H_0257
SpockToPrimary:
	mov	byte ptr cs:spock_primary, 1
	jmp	SHORT L0263

H_0257:
	SCRIPT	MSG_USE, OBJ_SPOCK, 23h, 0, H_0306
SpockToSecondary:
	mov	byte ptr cs:spock_primary, 0
L0263:
	mov	byte ptr [si+RS_FALL+1], 0
	push	1
	push	RC_STOPANIM
	SERVICE		; StopAnim(1)
	add	sp, 4
	cmp	byte ptr [si+know_physiology], 0
	jne	L02D9
	cmp	byte ptr [si+six_clue], 0
	jne	L02CE
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_061
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_013
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_062
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD4_048
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_059
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_031
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_060
	call	Say
	cmp	byte ptr [si+six_clue], 1
	je	L02CC
	mov	byte ptr [si+six_clue], 1
	add	word ptr [si+score], 1
L02CC:
	jmp	SHORT L02EA

L02CE:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_062
	call	Say
	jmp	SHORT L02EA

L02D9:
	cmp	byte ptr cs:spock_primary, 0
	jne	L02EA
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_057
	call	Say
L02EA:
	mov	byte ptr [si+RS_FALL+1], 0
	push	1
	push	9Ah
	push	6Dh
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 109, 154, 1)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

H_0306:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_0335
SpockAtStation:
	cmp	byte ptr cs:spock_primary, 1
	jne	L0330
	cmp	byte ptr [si+know_physiology], 1
	jne	L0330
	push	1
	push	-1
	push	-1
	push	OFFSET N_s4crss
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "s4crss", -1, -1, 1)
	add	sp, 0Ch
	retf

L0330:
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_0335:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_03CF
SecondaryStation:
	push	0
	push	98h
	push	55h
	push	OFFSET N_s4crsr
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "s4crsr", 85, 152, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_058
	call	Say
L035E:
	mov	ax, OFFSET SecondaryMenu
	call	Talk
	AX8	cmp, 3
	jne	L0381
	mov	byte ptr [si+RS_FALL+1], 0
	push	0
	push	0B7h
	push	69h
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 105, 183, 0)
	add	sp, 0Ah
	retf

L0381:
	AX8	cmp, 1
	jne	L03A6
	mov	byte ptr [si+RS_BUSY], 1
	push	4
	push	98h
	push	55h
	push	OFFSET N_s4crsl
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "s4crsl", 85, 152, 4)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+4], 5
	retf

L03A6:
	mov	byte ptr [si+RS_BUSY], 1
	AX8	cmp, 0
	jne	L03B3
	push	2
	jmp	SHORT L03B5

L03B3:
	push	3
L03B5:
	push	98h
	push	55h
	push	OFFSET N_s4crsr
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "s4crsr", 85, 152, ?)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+4], 5
	retf

H_03CF:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_03E5
Sensors:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_053
	call	Say
	JMPN	L035E

H_03E5:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_03FB
Engineering:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_056
	call	Say
	JMPN	L035E

H_03FB:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_0411
Navigation:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_055
	call	Say
	JMPN	L035E

H_0411:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_041E
SpockArrives:
	mov	byte ptr [si+RS_BUSY], 0
	JMPN	SpockToPrimary

; Kirk at the stations: before the library, he calls Spock over (msg 3).
; After it, the primary station (msgs 2, 5): the viewscreen (msg 6, +1
; once) and communications (msg 7).
H_041E:
	SCRIPT	MSG_USE, OBJ_KIRK, 21h, 0, H_0426
	jmp	SHORT KirkToSecondary

H_0426:
	SCRIPT	MSG_USE, OBJ_KIRK, 23h, 0, H_0434
KirkToSecondary:
	mov	byte ptr cs:kirk_secondary, 1
	jmp	SHORT L0440

H_0434:
	SCRIPT	MSG_USE, OBJ_KIRK, 22h, 0, H_04A8
KirkToPrimary:
	mov	byte ptr cs:kirk_secondary, 0
L0440:
	mov	byte ptr [si+RS_FALL], 0
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	cmp	byte ptr [si+know_physiology], 0
	jne	L047B
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_006
	call	Say
	mov	byte ptr [si+RS_FALL+1], 0
	push	3
	push	9Ah
	push	6Dh
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 109, 154, 3)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

L047B:
	cmp	byte ptr cs:kirk_secondary, 0
	jne	L048C
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_049
	call	Say
L048C:
	mov	byte ptr [si+RS_FALL], 0
	push	2
	push	98h
	push	7Eh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 126, 152, 2)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

H_04A8:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_04D7
KirkAtStation:
	cmp	byte ptr cs:kirk_secondary, 1
	jne	L04D2
	cmp	byte ptr [si+know_physiology], 1
	jne	L04D2
	push	5
	push	-1
	push	-1
	push	OFFSET N_s4crks
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s4crks", -1, -1, 5)
	add	sp, 0Ch
	retf

L04D2:
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_04D7:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_0571
PrimaryStation:
	push	0
	push	98h
	push	94h
	push	OFFSET N_s4crkl
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s4crkl", 148, 152, 0)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+4], 5
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_052
	call	Say
L0506:
	mov	ax, OFFSET PrimaryMenu
	call	Talk
	AX8	cmp, 0
	je	L0550
	AX8	cmp, 1
	je	L052F
	mov	byte ptr [si+RS_FALL], 0
	push	0
	push	0B6h
	push	83h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 131, 182, 0)
	add	sp, 0Ah
	retf

L052F:
	mov	byte ptr [si+RS_BUSY], 1
	push	6
	push	98h
	push	94h
	push	OFFSET N_s4crkl
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s4crkl", 148, 152, 6)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+4], 5
	retf

L0550:
	mov	byte ptr [si+RS_BUSY], 1
	push	7
	push	98h
	push	94h
	push	OFFSET N_s4crkr
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s4crkr", 148, 152, 7)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+4], 5
	retf

H_0571:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_05EF
ViewscreenToggled:
	cmp	byte ptr [si+viewscreen_on], 0
	jne	L05CA
	mov	byte ptr [si+viewscreen_on], 1
	jmp	SHORT L058C

N_SE2BIGAS	LABEL	BYTE
	DB	'SE2BIGAS',0
L058C:
	push	OFFSET N_SE2BIGAS
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SE2BIGAS")
	add	sp, 4
	push	0
	push	76h
	push	0A5h
	push	OFFSET N_s4crvs
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s4crvs", 165, 118, 0)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+6], 5
	mov	word ptr [si+RS_TIMERS+2], 32h
	cmp	byte ptr [si+viewscreen_scored], 1
	je	L05C9
	mov	byte ptr [si+viewscreen_scored], 1
	add	word ptr [si+score], 1
L05C9:
	retf

L05CA:
	mov	byte ptr [si+viewscreen_on], 0
	push	0
	push	76h
	push	0A5h
	push	OFFSET N_s4crvf
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s4crvf", 165, 118, 0)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+6], 5
	mov	word ptr [si+RS_TIMERS+2], 1Eh
	retf

H_05EF:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_060B
ViewscreenOn:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+viewscreen_on], 1
	jne	L0608
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_004
	call	Say
L0608:
	JMPN	L0506

; Communications, once Spock knows the weapons battery: Scott reports
; (+1). Kirk can leave now (BeamUp: score, 27, take_weapon), later, or
; after a word with Mudd, who comes in (walk msg 4).
H_060B:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_072F
Communications:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+knows_battery], 0
	jne	L0627
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_054
	call	Say
	JMPN	L0506

L0627:
	cmp	byte ptr [si+called_scott], 1
	je	L068E
	add	word ptr [si+score], 1
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_025
	call	Say
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_MUD4_S02
	call	Say
	cmp	word ptr [si+take_weapon], 1
	jne	L0654
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_027
	call	Say
	jmp	SHORT L065D

L0654:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_028
	call	Say
L065D:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_MUD4_S04
	call	Say
	mov	ax, OFFSET KirkToScott
	call	Talk
	AX8	cmp, 1
	jne	L0684
L0671:
	push	word ptr [si+take_weapon]
	push	1Bh
	push	word ptr [si+score]
	push	RC_BEAMUP
	SERVICE		; BeamUp(?, 27, ?)
	add	sp, 8
	retf

L0684:
	AX8	cmp, 0
	jne	L06B1
	mov	byte ptr [si+called_scott], 1
	retf

L068E:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_020
	call	Say
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_MUD4_S03
	call	Say
	mov	ax, OFFSET KirkToScottAgain
	call	Talk
	AX8	cmp, 1
	je	L0671
	AX8	cmp, 2
	je	L06B1
	retf

L06B1:
	cmp	byte ptr [si+mudd_incident], 0
	je	L06B8
	retf

L06B8:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 2
	push	4
	push	0B4h
	push	83h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 131, 180, 4)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+1], 2
	push	0
	push	0B7h
	push	69h
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 105, 183, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+2], 0
	push	2
	push	RC_STOPANIM
	SERVICE		; StopAnim(2)
	add	sp, 4
	mov	byte ptr [si+RS_FALL+3], 2
	push	3
	push	RC_STOPANIM
	SERVICE		; StopAnim(3)
	add	sp, 4
	push	3
	push	RC_MUSIC
	SERVICE		; Music(3)
	add	sp, 4
	push	0
	push	0C7h
	push	13Fh
	push	OFFSET N_s4crhw
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, "s4crhw", 319, 199, 0)
	add	sp, 0Ch
	retf

; Mudd's farewell, depending on what he did in rooms 3 and 5.
H_072F:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_087E
MuddFarewell:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+used_device], 1
	je	L079E
	cmp	byte ptr [si+mudd_allowed], 1
	je	L079E
	cmp	byte ptr [si+library_erased], 1
	je	L079E
	cmp	byte ptr [si+read_library], 0
	je	L079E
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD4_065
	call	Say
	mov	ax, OFFSET KirkOnDegrimer
	call	Talk
	AX8	cmp, 0
	je	L0777
L0765:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD4_074
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_017
	call	Say
L0777:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD4_072
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_008
	call	Say
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD4_068
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_032
	call	Say
	JMPN	L0671

L079E:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD4_066
	call	Say
	mov	ax, OFFSET KirkToMuddLeaving
	call	Talk
	AX8	cmp, 1
	je	L0765
	cmp	byte ptr [si+mudd_allowed], 1
	je	L07BE
	cmp	byte ptr [si+library_erased], 1
	jne	L07C7
L07BE:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_034
	call	Say
L07C7:
	cmp	byte ptr [si+used_device], 1
	jne	L07D6
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_037
	call	Say
L07D6:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_026
	call	Say
	cmp	byte ptr [si+mudd_allowed], 1
	jne	L0811
	cmp	byte ptr [si+library_erased], 1
	jne	L0811
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD4_071
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_036
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_029
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_030
	call	Say
	jmp	SHORT L0869

L0811:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD4_064
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_012
	call	Say
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD4_070
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_010
	call	Say
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD4_067
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_011
	call	Say
	add	word ptr [si+score], 4
	push	1Eh
	push	RC_MUSIC
	SERVICE		; Music(30)
	add	sp, 4
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD4_073
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_035
	call	Say
L0869:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD4_069
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_001
	call	Say
	JMPN	L0671

; McCoy and Buchert can't work the stations.
H_087E:
	SCRIPT	MSG_USE, OBJ_MCCOY, 21h, 0, H_0886
	jmp	SHORT McCoyAtStation

H_0886:
	SCRIPT	MSG_USE, OBJ_MCCOY, 22h, 0, H_088E
	jmp	SHORT McCoyAtStation

H_088E:
	SCRIPT	MSG_USE, OBJ_MCCOY, 23h, 0, H_08B5
McCoyAtStation:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD4_045
	call	Say
	mov	byte ptr [si+RS_FALL+2], 0
	push	0
	push	0C3h
	push	7Dh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 125, 195, 0)
	add	sp, 0Ah
	retf

H_08B5:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 21h, 0, H_08BD
	jmp	SHORT BuchertAtStation

H_08BD:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 22h, 0, H_08C5
	jmp	SHORT BuchertAtStation

H_08C5:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 23h, 0, H_08FD
BuchertAtStation:
	cmp	byte ptr [si+know_physiology], 0
	jne	L08DC
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD4_075
	call	Say
	jmp	SHORT L08E5

L08DC:
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD4_075
	call	Say
L08E5:
	mov	byte ptr [si+RS_FALL+3], 0
	push	0
	push	0BBh
	push	2Ah
	push	3
	push	RC_WALK
	SERVICE		; Walk(3, 42, 187, 0)
	add	sp, 0Ah
	retf

; Tricorders.
H_08FD:
	SCRIPT	MSG_USE, IT_STRICOR, 0Ah, 0, H_092E
SpockScansDoover:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscane
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscane", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_051
	call	Say
	retf

H_092E:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_095F
SpockScansConsole:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscann
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscann", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_042
	call	Say
	retf

H_095F:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_0990
SpockScansViewscreen:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscann
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscann", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_050
	call	Say
	retf

; Common to all of the mission's rooms: the de-grimer on the lenses makes
; the alien device (+1); firing the device sets off an explosion at Kirk
; (anim msg 9), +5 the first time anywhere; the de-grimer on anything else
; just cleans it.
H_0990:
	SCRIPT	MSG_USE, IT_LENSES, IT_DEGRIME, 0, H_09BE
CleanLenses:
	push	IT_LENSES
	push	RC_TAKEITEM
	push	IT_DEGRIME
	push	RC_TAKEITEM
	push	IT_ALIENDV
	push	RC_GIVEITEM
	mov	di, 3
L09A5:
	SERVICE		; GiveItem(IT_ALIENDV); TakeItem(IT_DEGRIME); TakeItem(IT_LENSES)
	add	sp, 4
	dec	di
	jne	L09A5
	add	word ptr [si+score], 1
	mov	ax, OFFSET S_1010
	mov	bx, OFFSET T_MUD4N009
	call	Say
	retf

H_09BE:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, H_0A21
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD4_043
	call	Say
	retf

T_MUD4_043	LABEL	BYTE
	DB	'#MUD4\MUD4_043#Everyone is healthy, Jim, there''s no need for the'
	DB	' medical kit here.',0

H_0A21:
	SCRIPT	MSG_USE, IT_ALIENDV, ANY, 0, H_0A74
FireDevice:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 1
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	push	0
	push	RC_ACTORPOS
	SERVICE		; ActorPos(0)
	add	sp, 4
	push	9
	push	0Ah
	push	ax
	push	OFFSET N_s4cbxp
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s4cbxp", ?, 10, 9)
	add	sp, 0Ch
	jmp	SHORT L0A64

N_EXPLO3	LABEL	BYTE
	DB	'EXPLO3',0
L0A64:
	push	OFFSET N_EXPLO3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EXPLO3")
	add	sp, 4
	retf

; The alien device has gone off here (anim msg 9).
H_0A74:
	SCRIPT	MSG_ANIM_DONE, 9, 0, 0, H_0A96
DeviceFired:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+used_device], 0
	jne	L0A95
	mov	byte ptr [si+used_device], 1
	add	word ptr [si+score], 5
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD2_002
	call	Say
L0A95:
	retf

; The doover (msgs 5, 10): +1.
H_0A96:
	SCRIPT	MSG_GET, 0Ah, 0, 0, H_0AC9
GetDoover:
	cmp	byte ptr [si+took_doover], 0
	jne	L0ABF
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 0
	push	5
	push	9Eh
	push	0CBh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 203, 158, 5)
	add	sp, 0Ah
	retf

L0ABF:
	mov	ax, OFFSET S_1010
	mov	bx, OFFSET T_MUD4N012
	call	Say
	retf

H_0AC9:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_0AE5
KirkAtDoover:
	push	0Ah
	push	-1
	push	-1
	push	OFFSET N_kuseln
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseln", -1, -1, 10)
	add	sp, 0Ch
	retf

H_0AE5:
	SCRIPT	MSG_ANIM_DONE, 0Ah, 0, 0, H_0B10
TookDoover:
	mov	byte ptr [si+RS_BUSY], 0
	push	0Ah
	push	RC_STOPANIM
	SERVICE		; StopAnim(10)
	add	sp, 4
	mov	byte ptr [si+took_doover], 1
	add	word ptr [si+score], 1
	push	IT_DOOVER
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_DOOVER)
	add	sp, 4
	retf

H_0B10:
	SCRIPT	MSG_USE, IT_DEGRIME, ANY, 0, H_0B20
UseDegrimer:
	mov	ax, OFFSET S_1010
	mov	bx, OFFSET T_MUD4N002
	call	Say
	retf

; Every tick, common to all of the mission's rooms: while life support is
; failing, the air runs down from 6978h, with warnings at 4F1Ah, 34BCh
; and 1A5Eh; at 1 the crew collapse (walk msgs 9-12) and the game is
; over.
H_0B20:
	SCRIPT	MSG_TICK, ANY, ANY, ANY, H_0C69
AirRunsOut:
	cmp	byte ptr [si+air_failing], 0
	je	L0B9A
	cmp	word ptr [si+air_countdown], 1
	je	L0B3C
	mov	word ptr [si+air_countdown], 1
	mov	word ptr [si+air_left], 6978h
L0B3C:
	dec	word ptr [si+air_left]
	cmp	word ptr [si+air_left], 1A5Eh
	je	L0BAF
	cmp	word ptr [si+air_left], 34BCh
	je	L0BA5
	cmp	word ptr [si+air_left], 4F1Ah
	je	L0B9B
	cmp	word ptr [si+air_left], 1
	jne	L0B9A
	mov	byte ptr [si+RS_BUSY], 1
	push	9
	push	0B6h
	push	8Bh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 139, 182, 9)
	add	sp, 0Ah
	push	0Ah
	push	0B7h
	push	69h
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 105, 183, 10)
	add	sp, 0Ah
	mov	ax, OFFSET S_1010
	mov	bx, OFFSET T_MUD4N005
	call	Say
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
L0B9A:
	retf

L0B9B:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_0BB9
	call	Say
	retf

L0BA5:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_0BDC
	call	Say
	retf

L0BAF:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_0BFF
	call	Say
	retf

S_0BB9	LABEL	BYTE
	DB	'Life support down to 75%, Captain.',0
S_0BDC	LABEL	BYTE
	DB	'Life support down to 50%, Captain.',0
S_0BFF	LABEL	BYTE
	DB	'Life support down to 25%, Captain.',0
T_MUD4N005	LABEL	BYTE
	DB	'#MUD4\MUD4N005#Life support fails completely and you fall uncons'
	DB	'cious.',0

; The air has run out: Kirk, McCoy and Buchert (walk msg 9), Spock (10).
H_0C69:
	SCRIPT	MSG_WALK_DONE, 9, 0, 0, H_0CB0
CrewCollapse:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kgetde
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kgetde", -1, -1, 0)
	add	sp, 0Ch
	push	0
	push	-1
	push	-1
	push	OFFSET N_mgetds
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mgetds", -1, -1, 0)
	add	sp, 0Ch
	push	0
	push	-1
	push	-1
	push	OFFSET N_rgetdw
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rgetdw", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0CCB

H_0CB0:
	SCRIPT	MSG_WALK_DONE, 0Ah, 0, 0, H_0D6C
SpockCollapses:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sgetdn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sgetdn", -1, -1, 0)
	add	sp, 0Ch
L0CCB:
	inc	byte ptr cs:collapsed
	cmp	byte ptr cs:collapsed, 2
	jne	L0CE1
	mov	ax, OFFSET S_1010
	mov	bx, OFFSET T_MUD4N007
	call	Say
L0CE1:
	retf

T_MUD4N007	LABEL	BYTE
	DB	'#MUD4\MUD4N007#The atmosphere in the ship has dropped below the '
	DB	'level needed to sustain life. You drop to unconsciousness and sl'
	DB	'owly die.',0

; Looking.
H_0D6C:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_0D7B
LookAtConsole:
	sub	ax, ax
	mov	bx, OFFSET T_MUD4N000
	call	Say
	retf

H_0D7B:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_0D9B
LookAtViewscreen:
	cmp	byte ptr [si+viewscreen_on], 0
	jne	L0D91
	mov	ax, OFFSET S_1010
	mov	bx, OFFSET T_MUD4N013
	call	Say
	retf

L0D91:
	mov	ax, OFFSET S_1010
	mov	bx, OFFSET T_MUD4N008
	call	Say
	retf

H_0D9B:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_0DAA
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_MUD4N003
	call	Say
	retf

H_0DAA:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_0DB9
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_MUD4N006
	call	Say
	retf

H_0DB9:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_0DC8
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_MUD4N001
	call	Say
	retf

H_0DC8:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_0DD7
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_MUD4N004
	call	Say
	retf

H_0DD7:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_0DE6
LookAtDoover:
	sub	ax, ax
	mov	bx, OFFSET T_MUD4N011
	call	Say
	retf

H_0DE6:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0DF6
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_005
	call	Say
	retf

H_0DF6:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0E18
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD4_063
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_015
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD4_047
	call	Say
	retf

H_0E18:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0E28
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD4_046
	call	Say
	retf

H_0E28:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0E38
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD4_076
	call	Say
	retf

; The doors.
H_0E38:
	SCRIPT	MSG_WALK, 24h, 0, 0, H_0E5D
WalkToRightDoor:
	mov	byte ptr cs:going_door, 1
	mov	byte ptr [si+RS_BUSY], 1
	push	0
	push	0C7h
	push	0F0h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 240, 199, 0)
	add	sp, 0Ah
	retf

H_0E5D:
	SCRIPT	MSG_WALK, 25h, 0, 0, H_0E81
WalkToLeftDoor:
	mov	byte ptr cs:going_door, 1
	mov	byte ptr [si+RS_BUSY], 1
	push	0
	push	0C7h
	push	50h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 80, 199, 0)
	add	sp, 0Ah
	retf

H_0E81:
	SCRIPT	MSG_REGION, 0, 0, 0, Talk
ReachDoor:
	cmp	byte ptr cs:going_door, 1
	jne	L0EA9
	jmp	SHORT L0E9A

N_SMADOOR3	LABEL	BYTE
	DB	'SMADOOR3',0
L0E9A:
	push	OFFSET N_SMADOOR3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SMADOOR3")
	add	sp, 4
L0EA9:
	retf

; Talk: conversation AX (speaker, choices, 0); returns the choice.
Talk:
	push	ax
	push	RC_TALK
	SERVICE		; Talk(?)
	add	sp, 4
	ret

; Say: one line, BX, said by AX (0: narration).
Say:
	mov	word ptr cs:talk_buf, ax
	mov	word ptr cs:talk_buf+2, bx
	mov	ax, OFFSET talk_buf
	call	Talk
	ret

rdf_scripts_end	LABEL	BYTE
rdf_objects	LABEL	BYTE
	DW	20h, 6	; id, points
	DW	82,78, 123,39, 207,39, 246,78, 207,118, 119,118
	DW	80FFh, 122, 158	; actions (bit 15 set), walk to (x, y)
	DW	21h, 4	; id, points
	DW	59,119, 69,119, 69,134, 42,134
	DW	80FFh, 122, 158	; actions (bit 15 set), walk to (x, y)
	DW	21h, 4	; id, points
	DW	90,119, 140,119, 137,136, 99,136
	DW	80FFh, 122, 158	; actions (bit 15 set), walk to (x, y)
	DW	21h, 4	; id, points
	DW	160,119, 202,120, 226,133, 162,134
	DW	80FFh, 109, 161	; actions (bit 15 set), walk to (x, y)
	DW	22h, 5	; id, points
	DW	80,146, 70,139, 73,108, 81,108, 90,134
	DW	80FFh, 122, 158	; actions (bit 15 set), walk to (x, y)
	DW	23h, 5	; id, points
	DW	151,148, 140,139, 145,107, 155,107, 160,139
	DW	24h, 4	; id, points
	DW	168,186, 319,186, 319,199, 168,199
	DW	25h, 4	; id, points
	DW	0,186, 167,186, 167,199, 0,199
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	2, 4	; id, points
	DW	168,195, 319,195, 319,199, 168,199
	DW	3, 4	; id, points
	DW	0,195, 167,195, 167,199, 0,199
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	0,186, 319,186, 319,194, 0,194
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Buchert	LABEL	BYTE
	DB	'Lt. Buchert',0
N_Mr_Scott	LABEL	BYTE
	DB	'Mr. Scott',0
N_Harry_Mudd	LABEL	BYTE
	DB	'Harry Mudd',0
S_1010	LABEL	BYTE
	DB	0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0
T_MUD4_061	LABEL	BYTE
	DB	'#MUD4\MUD4_061#This is clearly the control center for the ship, '
	DB	'Captain. I cannot deduce much information, but I do observe two '
	DB	'things.',0
T_MUD4_013	LABEL	BYTE
	DB	'#MUD4\MUD4_013#Go on, Mr. Spock.',0
T_MUD4_062	LABEL	BYTE
	DB	'#MUD4\MUD4_062#This station definitely is configured differently'
	DB	' from the one beside me.',0
T_MUD4_048	LABEL	BYTE
	DB	'#MUD4\MUD4_048#This shouldn''t be surprising -- after all, there '
	DB	'are two stations.',0
T_MUD4_059	LABEL	BYTE
	DB	'#MUD4\MUD4_059#That may be, Doctor, but if you will recall, all '
	DB	'the Enterprise''s different stations link into the same computer '
	DB	'network bank and...',0
T_MUD4_031	LABEL	BYTE
	DB	'#MUD4\MUD4_031#What else can you determine at this stage, Mr. Sp'
	DB	'ock?',0
T_MUD4_060	LABEL	BYTE
	DB	'#MUD4\MUD4_060#These people have a fixation for the number six, '
	DB	'and even divisors and multiplicands thereof: threes and twelves '
	DB	'in particular. I believe this may be the necessary first clue to'
	DB	' understanding the aliens.',0
T_MUD4_057	LABEL	BYTE
	DB	'#MUD4\MUD4_057#This appears to be the primary control panel. Per'
	DB	'haps you would be better equipped to man this station, Captain.',0
T_MUD4_058	LABEL	BYTE
	DB	'#MUD4\MUD4_058#This is the secondary station. With the limited u'
	DB	'nderstanding we now have of the library computer data, these con'
	DB	'trols can now be activated. Available are... ',0
T_MUD4_038	LABEL	BYTE
	DB	'#MUD4\MUD4_038#<<Sensors>>',0
T_MUD4_039	LABEL	BYTE
	DB	'#MUD4\MUD4_039#<<Navigation>>',0
T_MUD4_040	LABEL	BYTE
	DB	'#MUD4\MUD4_040#<<Engineering>>',0
T_MUD4_041	LABEL	BYTE
	DB	'#MUD4\MUD4_041#<<Done>>',0
T_MUD4_053	LABEL	BYTE
	DB	'#MUD4\MUD4_053#The Enterprise is in combat with a number of Elas'
	DB	'i pirate ships half a parsec toward the neutron star sector. I r'
	DB	'ead debris identifiable with the pirates, but they continue to h'
	DB	'arass the Enterprise.',0
T_MUD4_056	LABEL	BYTE
	DB	'#MUD4\MUD4_056#The engine pods are damaged but still generating '
	DB	'power, Captain.',0
T_MUD4_055	LABEL	BYTE
	DB	'#MUD4\MUD4_055#The computer reports this ship is incapable of na'
	DB	'vigating anywhere at all without major repairs. We are definitel'
	DB	'y dead in space until the Enterprise returns, Captain.',0
T_MUD4_049	LABEL	BYTE
	DB	'#MUD4\MUD4_049#I think this is the secondary station.',0
T_MUD4_052	LABEL	BYTE
	DB	'#MUD4\MUD4_052#Thanks to the library computer data, limited thou'
	DB	'gh it is, these primary controls give me access to...',0
T_MUD4_006	LABEL	BYTE
	DB	'#MUD4\MUD4_006#Mr. Spock, come take a look at this. This is evid'
	DB	'ently the main bridge. What do you make of it?',0
T_MUD4_002	LABEL	BYTE
	DB	'#MUD4\MUD4_002#<<Communications>>',0
T_MUD4_007	LABEL	BYTE
	DB	'#MUD4\MUD4_007#<<View Screen>>',0
T_MUD4_004	LABEL	BYTE
	DB	'#MUD4\MUD4_004#I guess the universe looks about like it did the '
	DB	'last time we saw it.',0
T_MUD4_054	LABEL	BYTE
	DB	'#MUD4\MUD4_054#The Enterprise is out of range for this equipment'
	DB	', under the conditions of static created by the neutron star.',0
T_MUD4_025	LABEL	BYTE
	DB	'#MUD4\MUD4_025#Scotty!  Report!',0
T_MUD4_S02	LABEL	BYTE
	DB	'#MUD4\MUD4_S02#The Elasi pirates have been driven off, Captain. '
	DB	'We have damage, and injuries among the crew. We just arrived bac'
	DB	'k here a few minutes ago, and we''ve been trying to raise you on '
	DB	'the communicators.',0
T_MUD4_027	LABEL	BYTE
	DB	'#MUD4\MUD4_027#The local star seems to be acting up. Will there '
	DB	'be a problem with the transporter? I want you to beam up the lan'
	DB	'ding party, and I also want you to lock onto and beam aboard an '
	DB	'alien mechanism we came across.',0
T_MUD4_028	LABEL	BYTE
	DB	'#MUD4\MUD4_028#The local star seems to be acting up.  Will there'
	DB	' be a problem with the transporter?',0
T_MUD4_S04	LABEL	BYTE
	DB	'#MUD4\MUD4_S04#We can do it, Captain, no problem. At least right'
	DB	' now, but the situation is only going to get worse. Are you read'
	DB	'y to beam over now?',0
T_MUD4_033	LABEL	BYTE
	DB	'#MUD4\MUD4_033#Yes, bring us home, Mr. Scott.',0
T_MUD4_024	LABEL	BYTE
	DB	'#MUD4\MUD4_024#No, we want to look around some more. We''ll call '
	DB	'you on this channel when we''re ready.',0
T_MUD4_023	LABEL	BYTE
	DB	'#MUD4\MUD4_023#No, I need to have a word with Harry Mudd before '
	DB	'we go.',0
T_MUD4_020	LABEL	BYTE
	DB	'#MUD4\MUD4_020#New developments, Mr. Scott?',0
T_MUD4_S03	LABEL	BYTE
	DB	'#MUD4\MUD4_S03#The neutron star is causing more and more problem'
	DB	's, Captain.  I would recommend beaming over at your earliest pos'
	DB	'sible convenience.',0
T_MUD4_019	LABEL	BYTE
	DB	'#MUD4\MUD4_019#Later, Mr. Scott.',0
T_MUD4_A29	LABEL	BYTE
	DB	'#MUD4\MUD4_A29#Very well, bring us home, Mr. Scott.',0
T_MUD4_045	LABEL	BYTE
	DB	'#MUD4\MUD4_045#I can''t make anything of these controls.',0
T_MUD4_075	LABEL	BYTE
	DB	'#MUD4\MUD4_075#I don''t believe this is the weapons center, Capta'
	DB	'in. There appears to be one, but it''s evidently located elsewher'
	DB	'e on the ship.  I can''t make anything more of these controls.',0
T_MUD4N000	LABEL	BYTE
	DB	'#MUD4\MUD4N000#A control console from which operators run the sh'
	DB	'ip.',0
T_MUD4_042	LABEL	BYTE
	DB	'#MUD4\MUD4_042#Evidently the aliens'' bridge, their centralized c'
	DB	'ontrol. A closer look may provide more information.',0
T_MUD4N013	LABEL	BYTE
	DB	'#MUD4\MUD4N013#You see a plain grey screen.',0
T_MUD4N008	LABEL	BYTE
	DB	'#MUD4\MUD4N008#The starfield is the same one you saw from the br'
	DB	'idge of the Enterprise, with the binary stars swinging majestica'
	DB	'lly past each other.',0
T_MUD4_050	LABEL	BYTE
	DB	'#MUD4\MUD4_050#It appears to be a view screen much like the one '
	DB	'on board the Enterprise.',0
T_MUD4_065	LABEL	BYTE
	DB	'#MUD4\MUD4_065#Captain Kirk! I seem to be missing a Miracle De-G'
	DB	'rimer! Surely you''re not stooping to thievery, are you, Captain?',0
T_MUD4_066	LABEL	BYTE
	DB	'#MUD4\MUD4_066#Captain Kirk! I was hoping to see you. I''m leavin'
	DB	'g soon and wanted to say thanks for the escort. Ta-ta, and I hop'
	DB	'e we never have to cross paths again, Captain.',0
T_MUD4_014	LABEL	BYTE
	DB	'#MUD4\MUD4_014#I was sure you wouldn''t miss them, Harry. The Pat'
	DB	'ent Authority wants these properly registered and I''m sure you w'
	DB	'ant to do the right thing.',0
T_MUD4_021	LABEL	BYTE
	DB	'#MUD4\MUD4_021#No, Harry, we''re going to let you keep them to se'
	DB	'll to the Elasi at incredible profits, so they can use them agai'
	DB	'nst Federation authorites.',0
T_MUD4_074	LABEL	BYTE
	DB	'#MUD4\MUD4_074#You''re. Kidding. Are you kidding, Captain?',0
T_MUD4_017	LABEL	BYTE
	DB	'#MUD4\MUD4_017#Just like you were kidding about this ship regist'
	DB	'ered as a worthless derelict. You are going to change that, aren'
	DB	'''t you?  Matter of fact, I think it would be just the thing for '
	DB	'you to turn it over lock stock and barrel to the Kornephorous Un'
	DB	'iversity.',0
T_MUD4_072	LABEL	BYTE
	DB	'#MUD4\MUD4_072#What! Where''s the profit in that, Captain?',0
T_MUD4_008	LABEL	BYTE
	DB	'#MUD4\MUD4_008#DId you know Stella''s still looking for you? What'
	DB	'''s it worth to you for me not to tell her where to find you, Har'
	DB	'ry?',0
T_MUD4_068	LABEL	BYTE
	DB	'#MUD4\MUD4_068#Consider it done. You have my word, Captain. Now '
	DB	'I''m going to pick up just a few things. Insignificant things, re'
	DB	'ally! Then I''ll be gone. Farewell, Captain! May your path be alw'
	DB	'ays trouble-free, until we meet again.',0
T_MUD4_032	LABEL	BYTE
	DB	'#MUD4\MUD4_032#When we meet, Harry, it always means trouble.',0
T_MUD4_009	LABEL	BYTE
	DB	'#MUD4\MUD4_009#Don''t rush off, Harry. There''s still a few things'
	DB	' we need to discuss.',0
T_MUD4_034	LABEL	BYTE
	DB	'#MUD4\MUD4_034#You destroyed the only known records of a lost ra'
	DB	'ce. That''s a punishable offense.',0
T_MUD4_037	LABEL	BYTE
	DB	'#MUD4\MUD4_037#You were selling high-technology weapons to terro'
	DB	'rists and known criminals.',0
T_MUD4_026	LABEL	BYTE
	DB	'#MUD4\MUD4_026#Tell me why I shouldn''t arrest you on the spot, j'
	DB	'ust on general principles?',0
T_MUD4_016	LABEL	BYTE
	DB	'#MUD4\MUD4_016#In such a hurry? And Stella said she was dropping'
	DB	' everything to meet you here.',0
T_MUD4_071	LABEL	BYTE
	DB	'#MUD4\MUD4_071#Well, Captain, I did manage to take a download of'
	DB	' the computer before I accidentally damaged it. If you''ll just l'
	DB	'et me go back to my ship, I can upload it to the Enterprise''s co'
	DB	'mputers from there.',0
T_MUD4_036	LABEL	BYTE
	DB	'#MUD4\MUD4_036#You made a backup?',0
T_MUD4_029	LABEL	BYTE
	DB	'#MUD4\MUD4_029#I would suggest, Captain, we take him up on his o'
	DB	'ffer.',0
T_MUD4_030	LABEL	BYTE
	DB	'#MUD4\MUD4_030#Very well, Harry. You''re off scot free... this ti'
	DB	'me. But if you don''t upload that data immediately, your measly l'
	DB	'ittle scoutship will be experiencing some difficulties maintaini'
	DB	'ng flight capabilities.',0
T_MUD4_064	LABEL	BYTE
	DB	'#MUD4\MUD4_064#Because I am going to turn over a selection of sa'
	DB	'mples to the Kornephorous Life Sciences University?',0
T_MUD4_012	LABEL	BYTE
	DB	'#MUD4\MUD4_012#For free?',0
T_MUD4_070	LABEL	BYTE
	DB	'#MUD4\MUD4_070#Uh...  of course. One of everything I''ve found he'
	DB	're.',0
T_MUD4_010	LABEL	BYTE
	DB	'#MUD4\MUD4_010#Five of each.',0
T_MUD4_067	LABEL	BYTE
	DB	'#MUD4\MUD4_067#Captain!! Two.',0
T_MUD4_011	LABEL	BYTE
	DB	'#MUD4\MUD4_011#Five. Remember, I could confiscate your entire st'
	DB	'ock as illegal goods.  You might get it back through the courts.'
	DB	'.. in a few years.',0
T_MUD4_073	LABEL	BYTE
	DB	'#MUD4\MUD4_073#You drive a hard bargain, Captain. It''s a deal.',0
T_MUD4_035	LABEL	BYTE
	DB	'#MUD4\MUD4_035#You have no idea what a great bargain it is, Mudd'
	DB	'.',0
T_MUD4_069	LABEL	BYTE
	DB	'#MUD4\MUD4_069#I understand. No problem. Adieu, Captain!',0
T_MUD4N012	LABEL	BYTE
	DB	'#MUD4\MUD4N012#You already have a doover.',0
T_MUD2_002	LABEL	BYTE
	DB	'#MUD2\MUD2_002#Well, now! I think we know why the Elasi pirates '
	DB	'were so interested in finding out where Mudd was getting these!',0
T_MUD4N009	LABEL	BYTE
	DB	'#MUD4\MUD4N009#These two things fit together like they were made'
	DB	' for each other.',0
T_MUD4N002	LABEL	BYTE
	DB	'#MUD4\MUD4N002#Dust and grease lifts off the surface, leaving th'
	DB	'is item clean as new.',0
T_MUD4N003	LABEL	BYTE
	DB	'#MUD4\MUD4N003#James T. Kirk, Captain of the USS Enterprise. ',0
T_MUD4N006	LABEL	BYTE
	DB	'#MUD4\MUD4N006#Mr. Spock, Vulcan''s finest contribution to Starfl'
	DB	'eet. ',0
T_MUD4N001	LABEL	BYTE
	DB	'#MUD4\MUD4N001#Dr. McCoy is still frowning. ',0
T_MUD4N004	LABEL	BYTE
	DB	'#MUD4\MUD4N004#Lieutenant Buchert looks intensely at these contr'
	DB	'ols, and suppresses a childlike impulse to touch them. ',0
T_MUD4N011	LABEL	BYTE
	DB	'#MUD4\MUD4N011#This appears to be some sort of engineering instr'
	DB	'ument. ',0
T_MUD4_005	LABEL	BYTE
	DB	'#MUD4\MUD4_005#I''m speechless, Mr. Spock. Words cannot adequatel'
	DB	'y describe this place. ',0
T_MUD4_063	LABEL	BYTE
	DB	'#MUD4\MUD4_063#We have done quite well so far, Captain. ',0
T_MUD4_015	LABEL	BYTE
	DB	'#MUD4\MUD4_015#In spite of Harry Mudd... ',0
T_MUD4_047	LABEL	BYTE
	DB	'#MUD4\MUD4_047#Speak of the devil, where is that little angel? ',0
T_MUD4_046	LABEL	BYTE
	DB	'#MUD4\MUD4_046#To boldly go, where no man has gone before... we'''
	DB	're here, Jim. ',0
T_MUD4_076	LABEL	BYTE
	DB	'#MUD4\MUD4_076#This may have been their bridge, but this sure do'
	DB	'esn''t look like the Enterprise. ',0
T_MUD4_051	LABEL	BYTE
	DB	'#MUD4\MUD4_051#It is a multi-bit, compact doover with its own dr'
	DB	'acktar traction unit and clamp kit.',0
T_MUD4_001	LABEL	BYTE
	DB	'#MUD4\MUD4_001#Bring us home, Mr. Scott.',0
SecondaryMenu	LABEL	BYTE
	DW	OFFSET N_Mr_Spock, OFFSET T_MUD4_038, OFFSET T_MUD4_039, OFFSET T_MUD4_040, OFFSET T_MUD4_041, 0	; speaker, choices, 0
PrimaryMenu	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_MUD4_002, OFFSET T_MUD4_007, OFFSET T_MUD4_041, 0	; speaker, choices, 0
KirkToScott	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_MUD4_024, OFFSET T_MUD4_033, OFFSET T_MUD4_023, 0	; speaker, choices, 0
KirkToScottAgain	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_MUD4_019, OFFSET T_MUD4_A29, OFFSET T_MUD4_023, 0	; speaker, choices, 0
KirkOnDegrimer	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_MUD4_014, OFFSET T_MUD4_021, 0	; speaker, choices, 0
KirkToMuddLeaving	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_MUD4_009, OFFSET T_MUD4_016, 0	; speaker, choices, 0

RDF	ENDS
	END
