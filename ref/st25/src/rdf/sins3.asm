; SINS3.RDF - "Sins of Omission", an old mining room with a laser drill.
; With the pattern of the keycard lock (room 4) the drill cuts a mould in
; the stone, and with the silver-bearing rocks from the surface (room 0)
; in the mould it fuses a keycard. A box holds a connector.
;
; Actors: 8 the mould, 11 (0Bh) the box.
; Objects: 8 the mould, 0Bh/22h the box, 20h the drill, 21h its controls,
; 23h the ore, 24h the way out, 25h/26h the displays. Exit 3: room 4.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - UseDrillNever is keyed MSG_USE, 20h, ANY; 20h is no item, so it never runs.
; - The conversation at 00D8 is built at run time.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
scanned_lock	EQU	RS_VARS+0Dh	; Spock has scanned the keycard lock (room 4)
drill_power	EQU	RS_VARS+0Eh	; the setting chosen: 1-3
drill_ready	EQU	RS_VARS+0Fh	; 0 not programmed, 1 programmed, 2 rocks in the mould
rocks_known	EQU	RS_VARS+10h	; bits: the rocks' silver (rooms 0, 3, 4): 7 all, 8 Spock's idea
mould	EQU	RS_VARS+17h	; -1 rock vaporized, 0 nothing, 2 mould cut, 3 rocks in it, 4 the keycard
box	EQU	RS_VARS+18h	; 0 shut, 1 open, 2 emptied
seen_mine	EQU	RS_VARS+1Ch	; the party has been in the mining room

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0C7h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	32h
rdf_scale_min	LABEL	BYTE
	DW	80h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, -1, -1, 4	; room for each exit
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
	DW	0,0, 0,0	; entrance 2, crew 0
	DW	0,0, 0,0	; entrance 2, crew 1
	DW	0,0, 0,0	; entrance 2, crew 2
	DW	0,0, 0,0	; entrance 2, crew 3
	DW	57,141, 75,153	; entrance 3, crew 0
	DW	75,133, 134,125	; entrance 3, crew 1
	DW	58,134, 75,132	; entrance 3, crew 2
	DW	45,138, 53,147	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	84,137, 84,137, 84,137, 84,137	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	84,137, 84,137, 84,137, 84,137
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_mscans	LABEL	BYTE
	DB	'mscans',0
talk_buf	LABEL	BYTE
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0
choice_jumps	LABEL	BYTE
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0
; Talk: conversation AX (speaker, choices, 0); returns the choice.
Talk:
	push	ax
	mov	ax, RC_TALK
	push	ax
	SERVICE		; Talk(?)
	add	sp, 4
	ret

; Say: one line, BX, said by AX (0: narration).
Say:
	mov	word ptr cs:talk_buf, ax
	mov	word ptr cs:talk_buf+2, bx
	mov	word ptr cs:talk_buf+4, 0
	mov	ax, OFFSET talk_buf
	call	Talk
	ret

N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Ensign_Mosher	LABEL	BYTE
	DB	'Ensign Mosher',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
	DB	'Mr. Scott',0
rdf_objects	LABEL	BYTE
	DW	20h, 4	; id, points
	DW	172,30, 222,30, 222,103, 172,73
	DW	21h, 4	; id, points
	DW	149,96, 168,96, 165,104, 148,104
	DW	22h, 6	; id, points
	DW	153,160, 171,153, 198,157, 199,174, 182,184, 151,177
	DW	23h, 4	; id, points
	DW	268,152, 296,87, 319,87, 319,182
	DW	24h, 6	; id, points
	DW	42,65, 59,65, 69,80, 69,114, 58,132, 42,136
	DW	25h, 5	; id, points
	DW	148,82, 174,81, 183,87, 183,94, 148,94
	DW	26h, 4	; id, points
	DW	227,82, 261,82, 261,94, 233,94
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	3, 4	; id, points
	DW	38,127, 74,130, 49,146, 26,143
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's3b1',0
	DB	's3b2',0
	DB	's3b3',0
	DB	's3b4',0
	DB	's3b5',0
	DB	's3b6',0

rdf_scripts:
rdf_bans_end:
; The room starts: the box, the mould and what is in it.
H_0234:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0327
StartRoom:
	jmp	SHORT L0245

N_SIN3LOOP	LABEL	BYTE
	DB	'SIN3LOOP',0
L0245:
	push	OFFSET N_SIN3LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SIN3LOOP")
	add	sp, 4
	cmp	byte ptr [si+seen_mine], 0
	jne	L025E
	mov	byte ptr [si+RS_BUSY], 2
L025E:
	cmp	byte ptr [si+box], 1
	jne	L0283
	jmp	SHORT L026C

N_s3bxo	LABEL	BYTE
	DB	's3bxo',0
L026C:
	push	0
	push	0B8h
	push	0AFh
	push	OFFSET N_s3bxo
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s3bxo", 175, 184, 0)
	add	sp, 0Ch
L0283:
	cmp	byte ptr [si+box], 2
	jne	L02A8
	jmp	SHORT L0291

N_s3bxe	LABEL	BYTE
	DB	's3bxe',0
L0291:
	push	0
	push	0B8h
	push	0AFh
	push	OFFSET N_s3bxe
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s3bxe", 175, 184, 0)
	add	sp, 0Ch
L02A8:
	cmp	byte ptr [si+mould], 2
	jne	L02CC
	jmp	SHORT L02B7

N_s3mold	LABEL	BYTE
	DB	's3mold',0
L02B7:
	push	0
	push	0
	push	0
	push	OFFSET N_s3mold
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s3mold", 0, 0, 0)
	add	sp, 0Ch
L02CC:
	cmp	byte ptr [si+mould], 3
	jne	L02F0
	jmp	SHORT L02DB

N_s3rock	LABEL	BYTE
	DB	's3rock',0
L02DB:
	push	0
	push	0
	push	0
	push	OFFSET N_s3rock
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s3rock", 0, 0, 0)
	add	sp, 0Ch
L02F0:
	cmp	byte ptr [si+mould], 4
	jne	L0314
	jmp	SHORT L02FF

N_s3card	LABEL	BYTE
	DB	's3card',0
L02FF:
	push	0
	push	0
	push	0
	push	OFFSET N_s3card
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s3card", 0, 0, 0)
	add	sp, 0Ch
L0314:
	or	byte ptr [si+rocks_known], 2
	push	-3
	push	1Bh
	push	RC_MUSIC
	SERVICE		; Music(27, -3)
	add	sp, 6
	retf

; Tricorders.
H_0327:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_03B4
SpockScansBox:
	jmp	SHORT L0336

N_sscans_2	LABEL	BYTE
	DB	'sscans',0
L0336:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscans_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscans", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN3_003
	call	Say
	jmp	SHORT L03B3

T_SIN3_003	LABEL	BYTE
	DB	'#SIN3\SIN3_003#A storage box of some kind. I detect no dangerous'
	DB	' substances.',0
L03B3:
	retf

H_03B4:
	SCRIPT	MSG_USE, IT_STRICOR, 25h, 0, H_03BC
	jmp	SHORT SpockScansDisplays

H_03BC:
	SCRIPT	MSG_USE, IT_STRICOR, 26h, 0, H_0454
SpockScansDisplays:
	jmp	SHORT L03CB

N_sscann	LABEL	BYTE
	DB	'sscann',0
L03CB:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscann
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscann", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN3_018
	call	Say
	jmp	SHORT L0453

T_SIN3_018	LABEL	BYTE
	DB	'#SIN3\SIN3_018#These are display panels for the laser drill. The'
	DB	'y are still functional.',0
L0453:
	retf

H_0454:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_0503
SpockScans:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscans
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscans", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN3_017
	call	Say
	jmp	SHORT L0502

T_SIN3_017	LABEL	BYTE
	DB	'#SIN3\SIN3_017#The mineshaft was drilled out of the lunar rock b'
	DB	'y a laser device similar to the one mounted in the ceiling.',0
L0502:
	retf

H_0503:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_05A9
SpockScansDrill:
	jmp	SHORT L0512

N_sscane	LABEL	BYTE
	DB	'sscane',0
L0512:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscane
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscane", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN3_016
	call	Say
	jmp	SHORT L05A8

T_SIN3_016	LABEL	BYTE
	DB	'#SIN3\SIN3_016#The drill is unremarkable except its aiming compo'
	DB	'nent is corroded and frozen in place.',0
L05A8:
	retf

H_05A9:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_0707
SpockScansControls:
	jmp	SHORT L05B8

N_sscane_2	LABEL	BYTE
	DB	'sscane',0
L05B8:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscane_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscane", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	cmp	byte ptr [si+scanned_lock], 0
	jne	L0654
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN3_019
	call	Say
	jmp	SHORT L0653

T_SIN3_019	LABEL	BYTE
	DB	'#SIN3\SIN3_019#This is the laser drill''s control panel. It is fu'
	DB	'nctional and power is flowing to it.',0
L0653:
	retf

L0654:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN3_015
	call	Say
	JMPN	L06FD

T_SIN3_015	LABEL	BYTE
	DB	'#SIN3\SIN3_015#I used the keycard pattern, scanned from the lock'
	DB	', to program the drill. It should now be able to make a template'
	DB	' of the keycard in the rock.',0
L06FD:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+drill_ready], 1
	retf

; Looking.
H_0707:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_0748
LookAtDrill:
	mov	ax, 0
	mov	bx, OFFSET T_SIN3N012
	call	Say
	jmp	SHORT L0747

T_SIN3N012	LABEL	BYTE
	DB	'#SIN3\SIN3N012#This is an ancient laser drill.',0
L0747:
	retf

H_0748:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_078E
LookAtControls:
	mov	ax, 0
	mov	bx, OFFSET T_SIN3N011
	call	Say
	jmp	SHORT L078D

T_SIN3N011	LABEL	BYTE
	DB	'#SIN3\SIN3N011#This is a laser drill control panel.',0
L078D:
	retf

H_078E:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_0796
	jmp	SHORT LookAtDisplays

H_0796:
	SCRIPT	MSG_LOOK, 26h, 0, 0, H_07E5
LookAtDisplays:
	mov	ax, 0
	mov	bx, OFFSET T_SIN3N007
	call	Say
	jmp	SHORT L07E4

T_SIN3N007	LABEL	BYTE
	DB	'#SIN3\SIN3N007#These are display panels for the laser drill.',0
L07E4:
	retf

H_07E5:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_084F
LookAtScene:
	mov	ax, 0
	mov	bx, OFFSET T_SIN3N013
	call	Say
	jmp	SHORT L084E

T_SIN3N013	LABEL	BYTE
	DB	'#SIN3\SIN3N013#This room looks like it was once used for some ty'
	DB	'pe of mining operation.',0
L084E:
	retf

H_084F:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_08D6
SpockScansOre:
	jmp	SHORT L085E

N_sscane_3	LABEL	BYTE
	DB	'sscane',0
L085E:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscane_3
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscane", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN3_023
	call	Say
	jmp	SHORT L08D5

T_SIN3_023	LABEL	BYTE
	DB	'#SIN3\SIN3_023#Unlike the surface rocks, the ore here is unremar'
	DB	'kable.',0
L08D5:
	retf

; The box: anyone opens it (msgs 4-8, timer 0); inside, the connector
; (msgs 3, 17).
H_08D6:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_08DE
	jmp	SHORT LookAtBox

H_08DE:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_09A5
LookAtBox:
	cmp	byte ptr [si+box], 0
	jne	L0925
	mov	ax, 0
	mov	bx, OFFSET T_SIN3N000
	call	Say
	jmp	SHORT L0924

T_SIN3N000	LABEL	BYTE
	DB	'#SIN3\SIN3N000#A closed box sits on the floor.',0
L0924:
	retf

L0925:
	cmp	byte ptr [si+box], 1
	jne	L0971
	mov	ax, 0
	mov	bx, OFFSET T_SIN3N008
	call	Say
	jmp	SHORT L0970

T_SIN3N008	LABEL	BYTE
	DB	'#SIN3\SIN3N008#This box contains old wire and connectors.',0
L0970:
	retf

L0971:
	cmp	byte ptr [si+box], 2
	jne	L09A4
	mov	ax, 0
	mov	bx, OFFSET T_SIN3N005
	call	Say
	jmp	SHORT L09A3

T_SIN3N005	LABEL	BYTE
	DB	'#SIN3\SIN3N005#The box is empty.',0
L09A3:
	retf

L09A4:
	retf

H_09A5:
	SCRIPT	MSG_USE, OBJ_KIRK, 22h, 0, H_09D6
KirkOpensBox:
	cmp	byte ptr [si+box], 0
	jne	L0A27
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 2
	mov	ax, 4
	push	ax
	mov	ax, 0A9h
	push	ax
	mov	ax, 8Fh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 143, 169, 4)
	add	sp, 0Ah
	retf

H_09D6:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_0A28
KirkAtBox:
	jmp	SHORT L09E5

N_kusele	LABEL	BYTE
	DB	'kusele',0
L09E5:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusele
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusele", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0A03

N_s3bxop	LABEL	BYTE
	DB	's3bxop',0
L0A03:
	push	8
	push	0B8h
	push	0AFh
	push	OFFSET N_s3bxop
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s3bxop", 175, 184, 8)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS], 0Ah
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+box], 1
L0A27:
	retf

H_0A28:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_0A3F
Timer0Sound:
	mov	ax, 0Ch
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(12)
	add	sp, 4
	retf

H_0A3F:
	SCRIPT	MSG_USE, OBJ_SPOCK, 22h, 0, H_0A70
SpockOpensBox:
	cmp	byte ptr [si+box], 0
	jne	L0ABD
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL+1], 2
	mov	ax, 5
	push	ax
	mov	ax, 0A9h
	push	ax
	mov	ax, 8Fh
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 143, 169, 5)
	add	sp, 0Ah
	retf

H_0A70:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_0ABE
SpockAtBox:
	jmp	SHORT L0A7F

N_susele	LABEL	BYTE
	DB	'susele',0
L0A7F:
	push	0
	push	-1
	push	-1
	push	OFFSET N_susele
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susele", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0A9D

N_s3bxop_2	LABEL	BYTE
	DB	's3bxop',0
L0A9D:
	push	8
	push	0B8h
	push	0AFh
	push	OFFSET N_s3bxop_2
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s3bxop", 175, 184, 8)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+box], 1
L0ABD:
	retf

H_0ABE:
	SCRIPT	MSG_USE, OBJ_MCCOY, 22h, 0, H_0AEF
McCoyOpensBox:
	cmp	byte ptr [si+box], 0
	jne	L0B3C
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL+2], 2
	mov	ax, 6
	push	ax
	mov	ax, 0A9h
	push	ax
	mov	ax, 8Fh
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 143, 169, 6)
	add	sp, 0Ah
	retf

H_0AEF:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_0B3D
McCoyAtBox:
	jmp	SHORT L0AFE

N_musele	LABEL	BYTE
	DB	'musele',0
L0AFE:
	push	0
	push	-1
	push	-1
	push	OFFSET N_musele
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musele", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0B1C

N_s3bxop_3	LABEL	BYTE
	DB	's3bxop',0
L0B1C:
	push	8
	push	0B8h
	push	0AFh
	push	OFFSET N_s3bxop_3
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s3bxop", 175, 184, 8)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+box], 1
L0B3C:
	retf

H_0B3D:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 22h, 0, H_0B6E
MosherOpensBox:
	cmp	byte ptr [si+box], 0
	jne	L0BBB
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL+3], 2
	mov	ax, 7
	push	ax
	mov	ax, 0A9h
	push	ax
	mov	ax, 8Fh
	push	ax
	mov	ax, 3
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(3, 143, 169, 7)
	add	sp, 0Ah
	retf

H_0B6E:
	SCRIPT	MSG_WALK_DONE, 7, 0, 0, H_0BBC
MosherAtBox:
	jmp	SHORT L0B7D

N_rusele	LABEL	BYTE
	DB	'rusele',0
L0B7D:
	push	0
	push	-1
	push	-1
	push	OFFSET N_rusele
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rusele", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0B9B

N_s3bxop_4	LABEL	BYTE
	DB	's3bxop',0
L0B9B:
	push	8
	push	0B8h
	push	0AFh
	push	OFFSET N_s3bxop_4
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s3bxop", 175, 184, 8)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+box], 1
L0BBB:
	retf

H_0BBC:
	SCRIPT	MSG_ANIM_DONE, 8, 0, 0, H_0BE6
BoxOpen:
	jmp	SHORT L0BCA

N_s3bxo_2	LABEL	BYTE
	DB	's3bxo',0
L0BCA:
	push	0
	push	0B8h
	push	0AFh
	push	OFFSET N_s3bxo_2
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s3bxo", 175, 184, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_0BE6:
	SCRIPT	MSG_GET, 0Bh, 0, 0, H_0BEE
	jmp	SHORT GetConnector

H_0BEE:
	SCRIPT	MSG_GET, 22h, 0, 0, H_0C2E
GetConnector:
	cmp	byte ptr [si+box], 0
	jne	L0BFB
	retf

L0BFB:
	cmp	byte ptr [si+box], 1
	jne	L0C26
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 2
	mov	ax, 3
	push	ax
	mov	ax, 0ABh
	push	ax
	mov	ax, 91h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 145, 171, 3)
	add	sp, 0Ah
	retf

L0C26:
	cmp	byte ptr [si+box], 2
	jne	L0C2D
	retf

L0C2D:
	retf

H_0C2E:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_0C5F
KirkAtBox2:
	push	IT_CONECT
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_CONECT)
	add	sp, 4
	jmp	SHORT L0C49

N_kusele_2	LABEL	BYTE
	DB	'kusele',0
L0C49:
	push	11h
	push	-1
	push	-1
	push	OFFSET N_kusele_2
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusele", -1, -1, 17)
	add	sp, 0Ch
	retf

H_0C5F:
	SCRIPT	MSG_ANIM_DONE, 11h, 0, 0, H_0C92
TookConnector:
	jmp	SHORT L0C6D

N_s3bxe_2	LABEL	BYTE
	DB	's3bxe',0
L0C6D:
	push	0
	push	0B8h
	push	0AFh
	push	OFFSET N_s3bxe_2
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s3bxe", 175, 184, 0)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+box], 2
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Tick 30, the first time: the crew on the room.
H_0C92:
	SCRIPT	MSG_TICK, 1Eh, 0, 0, H_0D67
FirstLook:
	cmp	byte ptr [si+seen_mine], 0
	je	L0CA1
	JMPN	L0D66

L0CA1:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN3_012
	call	Say
	jmp	SHORT L0CD7

T_SIN3_012	LABEL	BYTE
	DB	'#SIN3\SIN3_012#Can''t say I like the decor.',0
L0CD7:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN3_024
	call	Say
	jmp	SHORT L0D35

T_SIN3_024	LABEL	BYTE
	DB	'#SIN3\SIN3_024#The Lucrs did not leave behind many examples of t'
	DB	'heir architecture.',0
L0D35:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN3_013
	call	Say
	jmp	SHORT L0D5E

T_SIN3_013	LABEL	BYTE
	DB	'#SIN3\SIN3_013#I can see why.',0
L0D5E:
	mov	byte ptr [si+seen_mine], 1
	mov	byte ptr [si+RS_BUSY], 0
L0D66:
	retf

; Tick 60: with the silver rocks and the lock scanned, Spock's idea: a keycard.
H_0D67:
	SCRIPT	MSG_TICK, 3Ch, 0, 0, H_0D86
SpockHasIdea:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+rocks_known], 7
	jne	L0D85
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN3_007
	call	Say
	or	byte ptr [si+rocks_known], 8
L0D85:
	retf

; The drill controls: Spock (msg 10) programs the drill with the lock's
; pattern and a power setting; it cuts the mould.
H_0D86:
	SCRIPT	MSG_USE, OBJ_KIRK, 21h, 0, H_0DE3
KirkOnControls:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN3_001
	call	Say
	jmp	SHORT L0DE1

T_SIN3_001	LABEL	BYTE
	DB	'#SIN3\SIN3_001#Spock, why don''t you check out those laser drill '
	DB	'controls.',0
L0DE1:
	jmp	SHORT SpockOnControls

H_0DE3:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_0E06
SpockOnControls:
	mov	ax, 0Ah
	push	ax
	mov	ax, 78h
	push	ax
	mov	ax, 96h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 150, 120, 10)
	add	sp, 0Ah
	retf

H_0E06:
	SCRIPT	MSG_WALK_DONE, 0Ah, 0, 0, H_10CF
SpockAtControls:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L0E28

S_0E15	LABEL	BYTE
	DB	'Laser Setting: 001',0
L0E28:
	mov	word ptr cs:talk_buf+2, OFFSET S_0E15
	mov	word ptr cs:choice_jumps, OFFSET L0EB0
	jmp	SHORT L0E4B

S_0E38	LABEL	BYTE
	DB	'Laser Setting: 010',0
L0E4B:
	mov	word ptr cs:talk_buf+4, OFFSET S_0E38
	mov	word ptr cs:choice_jumps+2, OFFSET L0EBD
	jmp	SHORT L0E6E

S_0E5B	LABEL	BYTE
	DB	'Laser Setting: 100',0
L0E6E:
	mov	word ptr cs:talk_buf+6, OFFSET S_0E5B
	mov	word ptr cs:choice_jumps+4, OFFSET L0ECA
	jmp	SHORT L0E85

N_cancel	LABEL	BYTE
	DB	'cancel',0
L0E85:
	mov	word ptr cs:talk_buf+8, OFFSET N_cancel
	mov	word ptr cs:choice_jumps+6, OFFSET L0F52
	mov	word ptr cs:talk_buf+10, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L0EB0:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+drill_power], 1
	JMPN	L0F53

	DB	0CBh
L0EBD:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+drill_power], 2
	JMPN	L0F53

	DB	0CBh
L0ECA:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+drill_power], 3
	cmp	byte ptr [si+drill_ready], 0
	jne	L0F4F
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN3_005
	call	Say
	jmp	SHORT L0F4E

T_SIN3_005	LABEL	BYTE
	DB	'#SIN3\SIN3_005#Captain, the machine requests the proper coordina'
	DB	'tes before it may perform this operation.',0
L0F4E:
	retf

L0F4F:
	jmp	SHORT L0F53

	DB	0CBh
L0F52:
	retf

L0F53:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+mould], -1
	jne	L0F5F
	retf

L0F5F:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+mould], 0
	je	L0F6D
	JMPN	L0FFE

L0F6D:
	jmp	SHORT L0F76

N_susemn	LABEL	BYTE
	DB	'susemn',0
L0F76:
	push	0
	push	-1
	push	-1
	push	OFFSET N_susemn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemn", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0F95

N_LAZERD2	LABEL	BYTE
	DB	'LAZERD2',0
L0F95:
	push	OFFSET N_LAZERD2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("LAZERD2")
	add	sp, 4
	cmp	byte ptr [si+drill_ready], 0
	jne	L0FB3
	cmp	byte ptr [si+drill_power], 1
	jne	L0FB3
	JMPN	L1192

L0FB3:
	cmp	byte ptr [si+drill_ready], 0
	jne	L0FC2
	cmp	byte ptr [si+drill_power], 2
	jne	L0FC2
	JMPN	L1192

L0FC2:
	cmp	byte ptr [si+drill_ready], 0
	jne	L0FD1
	cmp	byte ptr [si+drill_power], 3
	jne	L0FD1
	JMPN	L11C1

L0FD1:
	cmp	byte ptr [si+drill_ready], 1
	jne	L0FE0
	cmp	byte ptr [si+drill_power], 1
	jne	L0FE0
	JMPN	L1192

L0FE0:
	cmp	byte ptr [si+drill_ready], 1
	jne	L0FEF
	cmp	byte ptr [si+drill_power], 2
	jne	L0FEF
	JMPN	L1192

L0FEF:
	cmp	byte ptr [si+drill_ready], 1
	jne	L0FFE
	cmp	byte ptr [si+drill_power], 3
	jne	L0FFE
	JMPN	L11F9

L0FFE:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+mould], 3
	jne	L106E
	jmp	SHORT L1012

N_susemn_2	LABEL	BYTE
	DB	'susemn',0
L1012:
	push	0
	push	-1
	push	-1
	push	OFFSET N_susemn_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemn", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L1031

N_LAZERD2_2	LABEL	BYTE
	DB	'LAZERD2',0
L1031:
	push	OFFSET N_LAZERD2_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("LAZERD2")
	add	sp, 4
	cmp	byte ptr [si+drill_ready], 2
	jne	L104F
	cmp	byte ptr [si+drill_power], 1
	jne	L104F
	JMPN	L1231

L104F:
	cmp	byte ptr [si+drill_ready], 2
	jne	L105E
	cmp	byte ptr [si+drill_power], 2
	jne	L105E
	JMPN	L1231

L105E:
	cmp	byte ptr [si+drill_ready], 2
	jne	L106D
	cmp	byte ptr [si+drill_power], 3
	jne	L106D
	JMPN	L1269

L106D:
	retf

L106E:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN3_006
	call	Say
	jmp	SHORT L10CE

T_SIN3_006	LABEL	BYTE
	DB	'#SIN3\SIN3_006#Captain, the template would be damaged by direct '
	DB	'fire from the laser.',0
L10CE:
	retf

; The rocks in the mould (msgs 1, 18, 2): the drill fuses them into a
; keycard at the right setting (anim msgs 11-14), or vaporizes them (19).
H_10CF:
	SCRIPT	MSG_USE, IT_S8ROCKS, 8, 0, H_10D7
	jmp	SHORT RocksInMould

H_10D7:
	SCRIPT	MSG_USE, IT_S8ROCKS, 23h, 0, H_1111
RocksInMould:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+mould], 2
	jne	L1110
	mov	byte ptr [si+mould], 3
	mov	byte ptr [si+drill_ready], 2
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 1
	push	ax
	mov	ax, 0A7h
	push	ax
	mov	ax, 10Fh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 271, 167, 1)
	add	sp, 0Ah
L1110:
	retf

H_1111:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_1136
KirkAtMould:
	jmp	SHORT L1120

N_kuseme	LABEL	BYTE
	DB	'kuseme',0
L1120:
	push	12h
	push	-1
	push	-1
	push	OFFSET N_kuseme
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseme", -1, -1, 18)
	add	sp, 0Ch
	retf

H_1136:
	SCRIPT	MSG_ANIM_DONE, 12h, 0, 0, H_1187
RocksPlaced:
	push	IT_S8ROCKS
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_S8ROCKS)
	add	sp, 4
	jmp	SHORT L1151

N_s3rock_2	LABEL	BYTE
	DB	's3rock',0
L1151:
	push	0
	push	0
	push	0
	push	OFFSET N_s3rock_2
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s3rock", 0, 0, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_FALL], 2
	mov	ax, 2
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 0FAh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 250, 170, 2)
	add	sp, 0Ah
	retf

H_1187:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_12A5
DrillFires:
	mov	byte ptr [si+RS_BUSY], 0
	retf

L1192:
	jmp	SHORT L119B

N_s3las1	LABEL	BYTE
	DB	's3las1',0
L119B:
	push	0Bh
	push	0
	push	0
	push	OFFSET N_s3las1
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s3las1", 0, 0, 11)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	retf

L11C1:
	jmp	SHORT L11CA

N_s3las2	LABEL	BYTE
	DB	's3las2',0
L11CA:
	push	0Ch
	push	0
	push	0
	push	OFFSET N_s3las2
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s3las2", 0, 0, 12)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+mould], -1
	retf

L11F9:
	jmp	SHORT L1202

N_s3las3	LABEL	BYTE
	DB	's3las3',0
L1202:
	push	0Dh
	push	0
	push	0
	push	OFFSET N_s3las3
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s3las3", 0, 0, 13)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+mould], 2
	retf

L1231:
	jmp	SHORT L123A

N_s3las4	LABEL	BYTE
	DB	's3las4',0
L123A:
	push	0Eh
	push	0
	push	0
	push	OFFSET N_s3las4
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s3las4", 0, 0, 14)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+mould], 4
	retf

L1269:
	jmp	SHORT L1272

N_s3las5	LABEL	BYTE
	DB	's3las5',0
L1272:
	push	13h
	push	0
	push	0
	push	OFFSET N_s3las5
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s3las5", 0, 0, 19)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+mould], 2
	mov	byte ptr [si+drill_ready], 1
	retf

H_12A5:
	SCRIPT	MSG_ANIM_DONE, 0Bh, 0, 0, H_12BC
DrillDone:
	mov	ax, 8
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(8)
	add	sp, 4
	retf

H_12BC:
	SCRIPT	MSG_ANIM_DONE, 0Ch, 0, 0, H_12E1
HoleCut:
	jmp	SHORT L12CB

N_s3hole	LABEL	BYTE
	DB	's3hole',0
L12CB:
	push	0
	push	0
	push	0
	push	OFFSET N_s3hole
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s3hole", 0, 0, 0)
	add	sp, 0Ch
	retf

H_12E1:
	SCRIPT	MSG_ANIM_DONE, 0Dh, 0, 0, H_1306
MouldCut:
	jmp	SHORT L12F0

N_s3mold_2	LABEL	BYTE
	DB	's3mold',0
L12F0:
	push	0
	push	0
	push	0
	push	OFFSET N_s3mold_2
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s3mold", 0, 0, 0)
	add	sp, 0Ch
	retf

H_1306:
	SCRIPT	MSG_ANIM_DONE, 0Eh, 0, 0, H_132B
CardMade:
	jmp	SHORT L1315

N_s3card_2	LABEL	BYTE
	DB	's3card',0
L1315:
	push	0
	push	0
	push	0
	push	OFFSET N_s3card_2
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s3card", 0, 0, 0)
	add	sp, 0Ch
	retf

H_132B:
	SCRIPT	MSG_ANIM_DONE, 13h, 0, 0, H_138D
RockVaporized:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN3_021
	call	Say
	jmp	SHORT L138C

T_SIN3_021	LABEL	BYTE
	DB	'#SIN3\SIN3_021#Too high a setting, Captain. The laser drill vapo'
	DB	'rized the rock.',0
L138C:
	retf

; Key MSG_USE, 20h, ANY: 20h is not an item, so this never runs.
H_138D:
	SCRIPT	MSG_USE, 20h, ANY, 0, H_140B
UseDrillNever:
	mov	ax, 0
	mov	bx, OFFSET T_SIN3N009
	call	Say
	jmp	SHORT L140A

T_SIN3N009	LABEL	BYTE
	DB	'#SIN3\SIN3N009#This is a high powered item that will cause irrev'
	DB	'ocable damage if you use it in this manner.',0
L140A:
	retf

; The keycard (msgs 15, 16).
H_140B:
	SCRIPT	MSG_GET, 8, 0, 0, H_143D
GetCard:
	cmp	byte ptr [si+mould], 4
	jne	L143C
	mov	ax, 0Fh
	push	ax
	mov	ax, 0A7h
	push	ax
	mov	ax, 10Fh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 271, 167, 15)
	add	sp, 0Ah
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 1
L143C:
	retf

H_143D:
	SCRIPT	MSG_WALK_DONE, 0Fh, 0, 0, H_1462
KirkAtCard:
	jmp	SHORT L144C

N_kuseme_2	LABEL	BYTE
	DB	'kuseme',0
L144C:
	push	10h
	push	-1
	push	-1
	push	OFFSET N_kuseme_2
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseme", -1, -1, 16)
	add	sp, 0Ch
	retf

H_1462:
	SCRIPT	MSG_ANIM_DONE, 10h, 0, 0, H_14A4
TookCard:
	push	IT_IDCARD
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_IDCARD)
	add	sp, 4
	jmp	SHORT L147D

N_s3mold_3	LABEL	BYTE
	DB	's3mold',0
L147D:
	push	0
	push	0
	push	0
	push	OFFSET N_s3mold_3
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s3mold", 0, 0, 0)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+mould], 2
	mov	byte ptr [si+drill_ready], 1
	mov	byte ptr [si+RS_BUSY], 0
	retf

; The mould.
H_14A4:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_15B3
LookAtMould:
	cmp	byte ptr [si+mould], 2
	jne	L150B
	mov	ax, 0
	mov	bx, OFFSET T_SIN3N006
	call	Say
	jmp	SHORT L150B

T_SIN3N006	LABEL	BYTE
	DB	'#SIN3\SIN3N006#The laser drill has cut a template for the keycar'
	DB	'd in the stone.',0
L150B:
	cmp	byte ptr [si+mould], 3
	jne	L1557
	mov	ax, 0
	mov	bx, OFFSET T_SIN3N014
	call	Say
	jmp	SHORT L1557

T_SIN3N014	LABEL	BYTE
	DB	'#SIN3\SIN3N014#You have placed the rocks onto the pattern.',0
L1557:
	cmp	byte ptr [si+mould], 4
	jne	L15B2
	mov	ax, 0
	mov	bx, OFFSET T_SIN3N010
	call	Say
	jmp	SHORT L15B2

T_SIN3N010	LABEL	BYTE
	DB	'#SIN3\SIN3N010#This is a keycard made from the tri-phosphate sil'
	DB	'ver rock.',0
L15B2:
	retf

H_15B3:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_1602
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_SIN3N003
	call	Say
	jmp	SHORT L1601

T_SIN3N003	LABEL	BYTE
	DB	'#SIN3\SIN3N003#James T. Kirk, Captain of the USS Enterprise.',0
L1601:
	retf

H_1602:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_166A
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_SIN3N004
	call	Say
	jmp	SHORT L1669

T_SIN3N004	LABEL	BYTE
	DB	'#SIN3\SIN3N004#Mr. Spock puzzles over the illogical design of so'
	DB	'me of these circuits.',0
L1669:
	retf

H_166A:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_16BB
LookAtMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN3N001
	call	Say
	jmp	SHORT L16BA

T_SIN3N001	LABEL	BYTE
	DB	'#SIN3\SIN3N001#Dr. McCoy again wonders why he even came along.',0
L16BA:
	retf

H_16BB:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_173D
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_SIN3N002
	call	Say
	jmp	SHORT L173C

T_SIN3N002	LABEL	BYTE
	DB	'#SIN3\SIN3N002#Ensign Mosher scouts for signs of trouble, as wel'
	DB	'l as glancing at the great-looking laser drill!',0
L173C:
	retf

H_173D:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_177C
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN3_002
	call	Say
	jmp	SHORT L177B

T_SIN3_002	LABEL	BYTE
	DB	'#SIN3\SIN3_002#You''re right. This is a mess.',0
L177B:
	retf

H_177C:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_17F1
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN3_020
	call	Say
	jmp	SHORT L17F0

T_SIN3_020	LABEL	BYTE
	DB	'#SIN3\SIN3_020#This technology is cruder and less efficient than'
	DB	' the rest of the complex, Captain.',0
L17F0:
	retf

H_17F1:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_1860
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN3_011
	call	Say
	jmp	SHORT L185F

T_SIN3_011	LABEL	BYTE
	DB	'#SIN3\SIN3_011#Why was I even brought down on this mission, Jim?'
	DB	' I''m a doctor, not a welder!',0
L185F:
	retf

H_1860:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_191B
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN3_026
	call	Say
	jmp	SHORT L18AA

T_SIN3_026	LABEL	BYTE
	DB	'#SIN3\SIN3_026#Looks like a museum piece to me, Captain.',0
L18AA:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN3_014
	call	Say
	jmp	SHORT L18EA

T_SIN3_014	LABEL	BYTE
	DB	'#SIN3\SIN3_014#This is one heck of a museum, Ensign.',0
L18EA:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN3_027
	call	Say
	jmp	SHORT L191A

T_SIN3_027	LABEL	BYTE
	DB	'#SIN3\SIN3_027#Still a mess, though.',0
L191A:
	retf

H_191B:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_19C2
SpockScansOre2:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscans
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscans", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN3_022
	call	Say
	jmp	SHORT L19C1

T_SIN3_022	LABEL	BYTE
	DB	'#SIN3\SIN3_022#Unlike the mineral samples on the surface, the ro'
	DB	'cks here do not contain any unusual trace elements.',0
L19C1:
	retf

H_19C2:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_1A02
UseCommunicator:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_SIN3U072
	call	Say
	jmp	SHORT L1A01

T_SIN3U072	LABEL	BYTE
	DB	'#SIN3\SIN3U072#Nothing new to report Captain.',0
L1A01:
	retf

; The crew on the drill.
H_1A02:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_1A60
SpockOnDrill:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN3_004
	call	Say
	jmp	SHORT L1A5F

T_SIN3_004	LABEL	BYTE
	DB	'#SIN3\SIN3_004#Captain, nothing can be gained by trying to force'
	DB	' it around.',0
L1A5F:
	retf

H_1A60:
	SCRIPT	MSG_USE, OBJ_MCCOY, 20h, 0, H_1AD4
McCoyOnDrill:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN3_009
	call	Say
	jmp	SHORT L1AD3

T_SIN3_009	LABEL	BYTE
	DB	'#SIN3\SIN3_009#I''m too attached to my head to stick it in front '
	DB	'of the laser that made this cave.',0
L1AD3:
	retf

H_1AD4:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 20h, 0, H_1B21
MosherOnDrill:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN3_025
	call	Say
	jmp	SHORT L1B20

T_SIN3_025	LABEL	BYTE
	DB	'#SIN3\SIN3_025#Uh, what do you want me to do with it, Sir?',0
L1B20:
	retf

; The way back (room 4).
H_1B21:
	SCRIPT	MSG_WALK, 24h, 0, 0, H_1B44
WalkOut:
	mov	ax, 0
	push	ax
	mov	ax, 86h
	push	ax
	mov	ax, 2Bh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 43, 134, 0)
	add	sp, 0Ah
	retf

H_1B44:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_KIRK, 0, H_1B4C
	jmp	SHORT MedkitOnSpock

H_1B4C:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_SPOCK, 0, H_1B54
MedkitOnSpock:
	jmp	SHORT MedkitOnMcCoy

H_1B54:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_MCCOY, 0, H_1B5C
MedkitOnMcCoy:
	jmp	SHORT MedkitOnRedshirt

H_1B5C:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_REDSHIRT, 0, H_1BA8
MedkitOnRedshirt:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN3_010
	call	Say
	jmp	SHORT L1BA7

T_SIN3_010	LABEL	BYTE
	DB	'#SIN3\SIN3_010#We''re safe from the cosmic radiation, Jim.',0
L1BA7:
	retf

H_1BA8:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_KIRK, 0, H_1BB0
	jmp	SHORT McCoyScansRedshirt

H_1BB0:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_SPOCK, 0, H_1BB8
	jmp	SHORT McCoyScansRedshirt

H_1BB8:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_MCCOY, 0, H_1BC0
	jmp	SHORT McCoyScansRedshirt

H_1BC0:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_REDSHIRT, 0, T_SIN3_007
McCoyScansRedshirt:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscans
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscans", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN3_008
	call	Say
	jmp	SHORT L1C58

T_SIN3_008	LABEL	BYTE
	DB	'#SIN3\SIN3_008#All readings are normal. The structure seems to b'
	DB	'e protecting us from the cosmic rays.',0
L1C58:
	retf

rdf_scripts_end	LABEL	BYTE
T_SIN3_007	LABEL	BYTE
	DB	'#SIN3\SIN3_007#Captain, with the 3KAg content of the surface roc'
	DB	'ks and the Tricorder scan of the pattern inside the lock, I beli'
	DB	'eve the laser drill can be used to fashion the ID card needed to'
	DB	' open the sealed door in the other chamber.',0

RDF	ENDS
	END
