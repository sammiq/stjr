; TUG1.RDF - "Hijacked", the corridor outside the Masada's bridge. A
; forcefield covers the bridge door; the pile of junk holds the pieces for
; the transporter repair (room 0): dead phasers, an empty phaser welder,
; wire scraps and junk metal. Charged from a phaser, the welder on the
; door just feeds the field, but on the spot beside it (20h) it shorts the
; field out, and the door opens.
;
; Actors: 8 the junk pile, 9 the door's effects (phaser, welder, opening).
; Objects: 8 the junk, 20h beside the door (the field's power), 21h/22h the
; forcefield, 23h the viewscreen, 24h debris, 25h the brig entrance.
; Exits: 0 the bridge (room 3), 1 the transporter room (room 0), 2 the
; brig (room 2).
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
score	EQU	RS_VARS+0	; word: the mission's score
took_junk	EQU	RS_VARS+16h
field_down	EQU	RS_VARS+1Eh	; the forcefield on the bridge door is off

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0B4h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	5Ah
rdf_scale_min	LABEL	BYTE
	DW	3Ch	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	3, 0, 2, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	190,116, 190,116	; entrance 0, crew 0
	DW	182,111, 182,111	; entrance 0, crew 1
	DW	209,111, 209,111	; entrance 0, crew 2
	DW	194,104, 194,104	; entrance 0, crew 3
	DW	176,162, 176,162	; entrance 1, crew 0
	DW	160,170, 160,170	; entrance 1, crew 1
	DW	205,170, 205,170	; entrance 1, crew 2
	DW	186,178, 186,178	; entrance 1, crew 3
	DW	211,131, 193,125	; entrance 2, crew 0
	DW	220,123, 227,145	; entrance 2, crew 1
	DW	225,138, 214,113	; entrance 2, crew 2
	DW	234,129, 223,128	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	176,162, 160,170, 205,170, 186,178	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0
rdf_objects	LABEL	BYTE
	DW	20h, 4	; id, points
	DW	175,98, 183,98, 183,105, 175,105
	DW	21h, 4	; id, points
	DW	182,81, 206,81, 206,106, 182,106
	DW	22h, 5	; id, points
	DW	164,102, 181,68, 208,68, 220,94, 220,102
	DW	23h, 4	; id, points
	DW	64,109, 99,107, 100,123, 64,128
	DW	24h, 4	; id, points
	DW	96,166, 135,123, 150,124, 135,167
	DW	25h, 4	; id, points
	DW	234,80, 241,77, 244,133, 234,124

rdf_scripts:
rdf_objects_end:
; The room starts: the junk, until Kirk takes it.
H_0146:
	SCRIPT	MSG_TICK, 1, 0, 0, H_019F
StartRoom:
	jmp	SHORT L0157

N_TUG1LOOP	LABEL	BYTE
	DB	'TUG1LOOP',0
L0157:
	push	OFFSET N_TUG1LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("TUG1LOOP")
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	cmp	word ptr [si+took_junk], 1
	je	L0191
	jmp	SHORT L017A

N_jnkpil	LABEL	BYTE
	DB	'jnkpil',0
L017A:
	push	0
	push	0A0h
	push	0FDh
	push	OFFSET N_jnkpil
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "jnkpil", 253, 160, 0)
	add	sp, 0Ch
L0191:
	retf

	DB	'jnkpil',0
	DB	'tug12',0

; Spock's tricorder and the forcefield.
H_019F:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_0247
SpockScans:
	mov	byte ptr [si+RS_FALL+1], 0
	jmp	SHORT L01B2

N_sscann	LABEL	BYTE
	DB	'sscann',0
L01B2:
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
	mov	bx, OFFSET T_TUG1_014
	call	Say
	jmp	SHORT L0246

T_TUG1_014	LABEL	BYTE
	DB	'#TUG1\TUG1_014#Strong electromagnetic readings come from the doo'
	DB	'rway at the far end of the hallway.',0
L0246:
	retf

H_0247:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_02A2
LookAtField:
	cmp	byte ptr [si+field_down], 1
	je	L02A1
	mov	ax, 0
	mov	bx, OFFSET T_TUG1N005
	call	Say
	jmp	SHORT L02A1

T_TUG1N005	LABEL	BYTE
	DB	'#TUG1\TUG1N005#Some kind of forcefield appears to cover the door'
	DB	'. ',0
L02A1:
	retf

H_02A2:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_03B0
SpockScansField:
	cmp	byte ptr [si+field_down], 1
	jne	L02B1
	JMPN	L03AF

L02B1:
	mov	byte ptr [si+RS_FALL+1], 0
	jmp	SHORT L02BE

N_sscann_2	LABEL	BYTE
	DB	'sscann',0
L02BE:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscann_2
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
	mov	bx, OFFSET T_TUG1_002
	call	Say
	JMPN	L03AF

T_TUG1_002	LABEL	BYTE
	DB	'#TUG1\TUG1_002#A forcefield of unusual configurations has been e'
	DB	'rected in front of the doorway which leads into the bridge. I do'
	DB	'n''t think it would be healthy to approach too closely, Captain.',0
L03AF:
	retf

; Phasers on the field (msgs 3, 4, 5): no effect.
H_03B0:
	SCRIPT	MSG_USE, IT_PHASERS, 21h, 0, H_03B8
	jmp	SHORT PhaserField

H_03B8:
	SCRIPT	MSG_USE, IT_PHASERK, 21h, 0, H_0431
PhaserField:
	cmp	byte ptr [si+field_down], 0
	jne	L03E8
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 3
	push	ax
	mov	ax, 78h
	push	ax
	mov	ax, 0BEh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 190, 120, 3)
	add	sp, 0Ah
L03E8:
	cmp	byte ptr [si+field_down], 1
	jne	L0430
	mov	ax, 0
	mov	bx, OFFSET T_TUG1N007
	call	Say
	jmp	SHORT L0430

T_TUG1N007	LABEL	BYTE
	DB	'#TUG1\TUG1N007#The field has already been deactivated.',0
L0430:
	retf

H_0431:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_0456
KirkAtField:
	jmp	SHORT L0440

N_kfiren	LABEL	BYTE
	DB	'kfiren',0
L0440:
	push	4
	push	-1
	push	-1
	push	OFFSET N_kfiren
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kfiren", -1, -1, 4)
	add	sp, 0Ch
	retf

H_0456:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_048B
KirkFires:
	jmp	SHORT L0465

N_t1phas	LABEL	BYTE
	DB	't1phas',0
L0465:
	push	5
	push	0
	push	0
	push	OFFSET N_t1phas
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "t1phas", 0, 0, 5)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	retf

H_048B:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_04B6
FieldHolds:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	ax, 9
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(9)
	add	sp, 4
	retf

H_04B6:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0571
TalkToSpock:
	cmp	byte ptr [si+field_down], 1
	jne	L04C5
	JMPN	L0570

L04C5:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG1_010
	call	Say
	JMPN	L0570

T_TUG1_010	LABEL	BYTE
	DB	'#TUG1\TUG1_010#I don''t think we can bring down that forcefield, '
	DB	'Captain. If we could, though, it might be less risky than trying'
	DB	' to transport onto the bridge.',0
L0570:
	retf

; The junk: Kirk takes all of it (msgs 1, 2), +1 score.
H_0571:
	SCRIPT	MSG_USE, IT_STRICOR, 8, 0, H_0642
SpockScansJunk:
	mov	byte ptr [si+RS_FALL+1], 0
	jmp	SHORT L0584

N_sscann_3	LABEL	BYTE
	DB	'sscann',0
L0584:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscann_3
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
	mov	bx, OFFSET T_TUG1_009
	call	Say
	JMPN	L0641

T_TUG1_009	LABEL	BYTE
	DB	'#TUG1\TUG1_009#Five phasers without power packs, a drained phase'
	DB	'r welder, insulation and bits of wire, and droplets of cooled mo'
	DB	'lten metal.',0
L0641:
	retf

H_0642:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_071D
LookAtJunk:
	mov	ax, 0
	mov	bx, OFFSET T_TUG1N000
	call	Say
	JMPN	L071C

T_TUG1N000	LABEL	BYTE
	DB	'#TUG1\TUG1N000#A tangle of mangled equipment, reduced to junk. T'
	DB	'here are the remains of five phasers without power packs, a drai'
	DB	'ned phaser welder, and scraps of wire and uncertain bits of meta'
	DB	'l junk.',0
L071C:
	retf

H_071D:
	SCRIPT	MSG_GET, 8, 0, 0, H_0740
GetJunk:
	mov	ax, 1
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 0E1h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 225, 170, 1)
	add	sp, 0Ah
	retf

H_0740:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_0767
KirkAtJunk:
	jmp	SHORT L074F

N_kpicke	LABEL	BYTE
	DB	'kpicke',0
L074F:
	push	2
	push	0AAh
	push	0E1h
	push	OFFSET N_kpicke
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kpicke", 225, 170, 2)
	add	sp, 0Ch
	retf

H_0767:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_07C7
TookJunk:
	mov	word ptr [si+took_junk], 1
	push	IT_DEADPH
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_DEADPH)
	add	sp, 4
	push	IT_PWE
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_PWE)
	add	sp, 4
	add	word ptr [si+score], 1
	push	IT_WIRSCRP
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_WIRSCRP)
	add	sp, 4
	push	IT_JNKMETL
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_JNKMETL)
	add	sp, 4
	mov	ax, 8
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(8)
	add	sp, 4
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	retf

; Inventory, as in room 0, but charging the welder here is worth +3
; (+1 there). The comb bit's line is missing its "T" here.
H_07C7:
	SCRIPT	MSG_USE, IT_PHASERS, IT_PWE, 0, H_07CF
	jmp	SHORT ChargeWelder

H_07CF:
	SCRIPT	MSG_USE, IT_PHASERK, IT_PWE, 0, H_082A
ChargeWelder:
	push	IT_PWE
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_PWE)
	add	sp, 4
	push	IT_PWF
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_PWF)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_TUG1N004
	call	Say
	jmp	SHORT L0825

T_TUG1N004	LABEL	BYTE
	DB	'#TUG1\TUG1N004#Phaser Welder is now charged.',0
L0825:
	add	word ptr [si+score], 3
	retf

H_082A:
	SCRIPT	MSG_USE, IT_PWF, IT_WIRSCRP, 0, H_08BB
WeldWireScraps:
	mov	ax, 0
	mov	bx, OFFSET T_TUG1N009
	call	Say
	jmp	SHORT L08AE

T_TUG1N009	LABEL	BYTE
	DB	'#TUG1\TUG1N009#The wire scraps are too small, they melt instead '
	DB	'of fusing together, and you''re left with nothing. ',0
L08AE:
	push	IT_WIRSCRP
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_WIRSCRP)
	add	sp, 4
	retf

H_08BB:
	SCRIPT	MSG_USE, IT_PWF, IT_JNKMETL, 0, H_0969
WeldJunkMetal:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG1_012
	call	Say
	JMPN	L0950

T_TUG1_012	LABEL	BYTE
	DB	'#TUG1\TUG1_012#I think that does it -- a Comb Bit for the transm'
	DB	'ogrifier. Now I can continue repairs on the transporter controls'
	DB	'. ',0
L0950:
	push	IT_JNKMETL
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_JNKMETL)
	add	sp, 4
	push	IT_COMBBIT
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_COMBBIT)
	add	sp, 4
	retf

H_0969:
	SCRIPT	MSG_USE, IT_COMBBIT, IT_RT, 0, H_09D4
FitCombBit:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG1_017
	call	Say
	jmp	SHORT L09AF

T_TUG1_017	LABEL	BYTE
	DB	'#TUG1\TUG1_017#he parts fit together satisfactorily.',0
L09AF:
	push	IT_COMBBIT
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_COMBBIT)
	add	sp, 4
	push	IT_RT
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_RT)
	add	sp, 4
	push	IT_RTWB
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_RTWB)
	add	sp, 4
	retf

; The charged welder on the field (msgs 6, 7) is absorbed; beside the door
; (msgs 8, 9) it brings the field down, +1 score.
H_09D4:
	SCRIPT	MSG_USE, IT_PWF, 22h, 0, H_09DC
	jmp	SHORT WeldField

H_09DC:
	SCRIPT	MSG_USE, IT_PWF, 21h, 0, H_0A55
WeldField:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+field_down], 1
	jne	L0A2F
	mov	ax, 0
	mov	bx, OFFSET T_TUG1N008
	call	Say
	jmp	SHORT L0A2E

T_TUG1N008	LABEL	BYTE
	DB	'#TUG1\TUG1N008#The field has already been deactivated',0
L0A2E:
	retf

L0A2F:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 6
	push	ax
	mov	ax, 6Ah
	push	ax
	mov	ax, 0C2h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 194, 106, 6)
	add	sp, 0Ah
	retf

	DB	0CBh

H_0A55:
	SCRIPT	MSG_USE, IT_PWF, 20h, 0, H_0AD2
WeldBesideDoor:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+field_down], 1
	jne	L0AA8
	mov	ax, 0
	mov	bx, OFFSET T_TUG1N007_2
	call	Say
	jmp	SHORT L0AA7

T_TUG1N007_2	LABEL	BYTE
	DB	'#TUG1\TUG1N007#The field has already been deactivated',0
L0AA7:
	retf

L0AA8:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 8
	push	ax
	mov	ax, 6Ah
	push	ax
	mov	ax, 0B1h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 177, 106, 8)
	add	sp, 0Ah
	retf

H_0AD2:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_0B2E
KirkWeldsField:
	jmp	SHORT L0AE2

N_MUR4E9S	LABEL	BYTE
	DB	'MUR4E9S',0
L0AE2:
	push	OFFSET N_MUR4E9S
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR4E9S")
	add	sp, 4
	jmp	SHORT L0AFA

N_kusemn	LABEL	BYTE
	DB	'kusemn',0
L0AFA:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0B18

N_t1weld	LABEL	BYTE
	DB	't1weld',0
L0B18:
	push	7
	push	0
	push	0
	push	OFFSET N_t1weld
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "t1weld", 0, 0, 7)
	add	sp, 0Ch
	retf

H_0B2E:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_0B86
FieldAbsorbs:
	mov	ax, 9
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(9)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG1_016
	call	Say
	jmp	SHORT L0B81

T_TUG1_016	LABEL	BYTE
	DB	'#TUG1\TUG1_016#The field is absorbing the energy.',0
L0B81:
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_0B86:
	SCRIPT	MSG_WALK_DONE, 8, 0, 0, H_0BE2
KirkWeldsBesideDoor:
	jmp	SHORT L0B96

N_MUR4E9S_2	LABEL	BYTE
	DB	'MUR4E9S',0
L0B96:
	push	OFFSET N_MUR4E9S_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR4E9S")
	add	sp, 4
	jmp	SHORT L0BAE

N_kuseln	LABEL	BYTE
	DB	'kuseln',0
L0BAE:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kuseln
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseln", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0BCC

N_t1weld_2	LABEL	BYTE
	DB	't1weld',0
L0BCC:
	push	9
	push	0
	push	0
	push	OFFSET N_t1weld_2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "t1weld", 0, 0, 9)
	add	sp, 0Ch
	retf

H_0BE2:
	SCRIPT	MSG_ANIM_DONE, 9, 0, 0, H_0C4F
FieldDown:
	mov	ax, 9
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(9)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG1_015
	call	Say
	jmp	SHORT L0C42

T_TUG1_015	LABEL	BYTE
	DB	'#TUG1\TUG1_015#That did it. The field is deactivated, Captain.',0
L0C42:
	mov	byte ptr [si+field_down], 1
	mov	byte ptr [si+RS_BUSY], 0
	add	word ptr [si+score], 1
	retf

; Looking and talking.
H_0C4F:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_0C5E
LookAtScene:
	sub	ax, ax
	mov	bx, OFFSET T_TUG1N013
	call	Say
	retf

H_0C5E:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_0C6D
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_TUG1N003
	call	Say
	retf

H_0C6D:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_0C7C
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_TUG1N006
	call	Say
	retf

H_0C7C:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_0CCF
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_TUG1N002
	call	Say
	jmp	SHORT L0CCE

T_TUG1N002	LABEL	BYTE
	DB	'#TUG1\TUG1N002#Lt. Christensen is carefully watching the hallway',0
L0CCE:
	retf

H_0CCF:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0CDF
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN3_012
	call	Say
	retf

H_0CDF:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0D4E
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Christensen
	mov	bx, OFFSET T_TUG1L005
	call	Say
	jmp	SHORT L0D4D

T_TUG1L005	LABEL	BYTE
	DB	'#TUG1\TUG1L005#This corridor provides access to the transporter '
	DB	'room, Captain. It is secure.',0
L0D4D:
	retf

H_0D4E:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_0D90
SpockScans2:
	mov	byte ptr [si+RS_FALL+1], 0
	jmp	SHORT L0D61

N_sscann_4	LABEL	BYTE
	DB	'sscann',0
L0D61:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscann_4
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
	mov	bx, OFFSET T_TUG1_006
	call	Say
	retf

H_0D90:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_0DF9
LookAtViewscreen:
	mov	ax, 0
	mov	bx, OFFSET T_TUG1N010
	call	Say
	jmp	SHORT L0DF8

T_TUG1N010	LABEL	BYTE
	DB	'#TUG1\TUG1N010#This viewscreen/ communication terminal has been '
	DB	'damaged beyond repair.',0
L0DF8:
	retf

H_0DF9:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_0E5C
LookAtDebris:
	mov	ax, 0
	mov	bx, OFFSET T_TUG1N011
	call	Say
	jmp	SHORT L0E5B

T_TUG1N011	LABEL	BYTE
	DB	'#TUG1\TUG1N011#Twisted debris has been scattered along the side '
	DB	'of the corridor.',0
L0E5B:
	retf

H_0E5C:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_0EDC
LookAtBrig:
	mov	ax, 0
	mov	bx, OFFSET T_TUG1N001
	call	Say
	jmp	SHORT L0EDB

T_TUG1N001	LABEL	BYTE
	DB	'#TUG1\TUG1N001#According to the deckplans of this class of Stars'
	DB	'hip, this is the entrance to the ship''s brig.',0
L0EDB:
	retf

H_0EDC:
	SCRIPT	MSG_USE, IT_STRICOR, 25h, 0, H_0FC1
SpockScansBrig:
	mov	byte ptr [si+RS_FALL+1], 0
	jmp	SHORT L0EEF

N_sscann_5	LABEL	BYTE
	DB	'sscann',0
L0EEF:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscann_5
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
	mov	bx, OFFSET T_TUG1_018
	call	Say
	JMPN	L0FC0

T_TUG1_018	LABEL	BYTE
	DB	'#TUG1\TUG1_018#Tricorder readings indicate an indeterminate numb'
	DB	'er of people in the brig. At least 2 are armed with phasers. I r'
	DB	'ecommend caution when entering.',0
L0FC0:
	retf

H_0FC1:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_106D
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG1_001
	call	Say
	jmp	SHORT L0FFF

T_TUG1_001	LABEL	BYTE
	DB	'#TUG1\TUG1_001#This is a mess now, isn''t it?',0
L0FFF:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG1_008
	call	Say
	jmp	SHORT L106C

T_TUG1_008	LABEL	BYTE
	DB	'#TUG1\TUG1_008#My daddy would have sent me to bed without supper'
	DB	' if I''d done something like this.',0
L106C:
	retf

H_106D:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_1119
UseCommunicator:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG1_011
	call	Say
	JMPN	L1118

T_TUG1_011	LABEL	BYTE
	DB	'#TUG1\TUG1_011#I strongly recommend that we keep our silence, Ca'
	DB	'ptain. The Elasi are quite capable of tracing any communication '
	DB	'from within this vessel.',0
L1118:
	retf

; Walking to the bridge door, once the field is down: it opens (msgs
; 10, 11) and Kirk walks through (exit 0).
H_1119:
	SCRIPT	MSG_WALK, 21h, 0, 0, H_1146
WalkToBridgeDoor:
	cmp	byte ptr [si+field_down], 1
	jne	L1145
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 0Ah
	push	ax
	mov	ax, 6Eh
	push	ax
	mov	ax, 0C2h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 194, 110, 10)
	add	sp, 0Ah
L1145:
	retf

H_1146:
	SCRIPT	MSG_WALK_DONE, 0Ah, 0, 0, H_116D
AtBridgeDoor:
	mov	byte ptr [si+RS_BUSY], 1
	jmp	SHORT L1157

N_h1do	LABEL	BYTE
	DB	'h1do',0
L1157:
	push	0Bh
	push	0
	push	0
	push	OFFSET N_h1do
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "h1do", 0, 0, 11)
	add	sp, 0Ch
	retf

H_116D:
	SCRIPT	MSG_ANIM_DONE, 0Bh, 0, 0, H_1190
DoorOpen:
	mov	ax, 0
	push	ax
	mov	ax, 63h
	push	ax
	mov	ax, 0C2h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 194, 99, 0)
	add	sp, 0Ah
	retf

H_1190:
	SCRIPT	MSG_WALK, 25h, 0, 0, H_11B3
WalkToBrig:
	mov	ax, 0
	push	ax
	mov	ax, 81h
	push	ax
	mov	ax, 0E9h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 233, 129, 0)
	add	sp, 0Ah
	retf

; McCoy's tricorder.
H_11B3:
	SCRIPT	MSG_USE, IT_MTRICOR, ANY, 0, H_1249
McCoyScans:
	mov	byte ptr [si+RS_FALL+2], 0
	jmp	SHORT L11C6

N_mscann	LABEL	BYTE
	DB	'mscann',0
L11C6:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscann
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscann", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG1_003
	call	Say
	jmp	SHORT L1248

T_TUG1_003	LABEL	BYTE
	DB	'#TUG1\TUG1_003#I''m getting life readings both on the bridge and '
	DB	'in the brig, Jim.',0
L1248:
	retf

H_1249:
	SCRIPT	MSG_USE, IT_MTRICOR, 21h, 0, H_1251
	jmp	SHORT McCoyScansField

H_1251:
	SCRIPT	MSG_USE, IT_MTRICOR, 20h, 0, H_1259
	jmp	SHORT McCoyScansField

H_1259:
	SCRIPT	MSG_USE, IT_MTRICOR, 22h, 0, H_12F4
McCoyScansField:
	mov	byte ptr [si+RS_FALL+2], 0
	jmp	SHORT L126C

N_mscann_2	LABEL	BYTE
	DB	'mscann',0
L126C:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscann_2
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscann", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG1_007
	call	Say
	jmp	SHORT L12F3

T_TUG1_007	LABEL	BYTE
	DB	'#TUG1\TUG1_007#The force field is interfering too much to get an'
	DB	' accurate reading, Jim',0
L12F3:
	retf

H_12F4:
	SCRIPT	MSG_USE, IT_MTRICOR, 25h, 0, H_13BF
McCoyScansBrig:
	mov	byte ptr [si+RS_FALL+2], 0
	jmp	SHORT L1307

N_mscann_3	LABEL	BYTE
	DB	'mscann',0
L1307:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscann_3
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscann", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG1_005
	call	Say
	JMPN	L13BE

T_TUG1_005	LABEL	BYTE
	DB	'#TUG1\TUG1_005#Jim, I''m picking up 11 life forms in the brig. Th'
	DB	'at accounts for over half the crew. I don''t like what that indic'
	DB	'ates.',0
L13BE:
	retf

; The crew on the field, before it is down.
H_13BF:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_13C7
	jmp	SHORT SpockUsesField

H_13C7:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_13CF
	jmp	SHORT SpockUsesField

H_13CF:
	SCRIPT	MSG_USE, OBJ_SPOCK, 22h, 0, H_146C
SpockUsesField:
	cmp	byte ptr [si+field_down], 0
	je	L13DE
	JMPN	L146B

L13DE:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG1_013
	call	Say
	JMPN	L146B

T_TUG1_013	LABEL	BYTE
	DB	'#TUG1\TUG1_013#If we could find a point to interrupt the flow of'
	DB	' power to the field we could gain access to the bridge, Captain.',0
L146B:
	retf

H_146C:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 20h, 0, H_1474
	jmp	SHORT ChristensenUsesField

H_1474:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 21h, 0, H_147C
	jmp	SHORT ChristensenUsesField

H_147C:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 22h, 0, H_14DD
ChristensenUsesField:
	cmp	byte ptr [si+field_down], 0
	jne	L14DC
	mov	ax, OFFSET N_Lt_Christensen
	mov	bx, OFFSET T_TUG1L000
	call	Say
	jmp	SHORT L14DC

T_TUG1L000	LABEL	BYTE
	DB	'#TUG1\TUG1L000#I doubt that our phasers could get through that, '
	DB	'Captain.',0
L14DC:
	retf

H_14DD:
	SCRIPT	MSG_USE, IT_MEDKIT, 20h, 0, H_14E5
	jmp	SHORT MedkitOnField

H_14E5:
	SCRIPT	MSG_USE, IT_MEDKIT, 21h, 0, H_14ED
	jmp	SHORT MedkitOnField

H_14ED:
	SCRIPT	MSG_USE, IT_MEDKIT, 22h, 0, rdf_scripts_end
MedkitOnField:
	cmp	byte ptr [si+field_down], 0
	jne	L1552
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG1_004
	call	Say
	jmp	SHORT L1552

T_TUG1_004	LABEL	BYTE
	DB	'#TUG1\TUG1_004#Jim, I can only perform medical miracles not engi'
	DB	'neering ones.',0
L1552:
	retf

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
	mov	ax, OFFSET talk_buf
	call	Talk
	ret

rdf_scripts_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	0, 4	; id, points
	DW	181,96, 207,96, 207,102, 181,102
	DW	1, 4	; id, points
	DW	140,175, 258,175, 258,180, 140,180
	DW	2, 4	; id, points
	DW	225,126, 237,125, 244,134, 229,133
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Christensen	LABEL	BYTE
	DB	'Lt. Christensen',0
T_TUG1N003	LABEL	BYTE
	DB	'#TUG1\TUG1N003#McCoy is fidgeting around.',0
T_TUG1N006	LABEL	BYTE
	DB	'#TUG1\TUG1N006#Spock is analyzing the surroundings.',0
T_TUG1N013	LABEL	BYTE
	DB	'#TUG1\TUG1N013#You are in a typical starship corridor.',0
T_SIN3_012	LABEL	BYTE
	DB	'#SIN3\SIN3_012#Can''t say I like the decor.',0
T_TUG1_006	LABEL	BYTE
	DB	'#TUG1\TUG1_006#Nothing unusual is detected.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
