; FEATHER6.RDF - "The Feathered Serpent", the cave beyond the river. A
; cluster of raw dilithium crystals grows under unstable stalactites: the
; knife pries a crystal loose; hammering it with a rock, or throwing one at
; the stalactites, brings a stalactite down on Kirk, and a strange force
; carries his body on to room 7.
;
; Actors: 8 the crystal, 9 the stalactite, 10 (0Ah) the thrown rock.
; Objects: 8 the crystal, 20h the way back, 21h rocks, 22h the
; stalactites, 23h the stalagmites. Exit 3: room 7. Region 0: the way
; back to the river.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - Two scripts share the key MSG_USE, IT_ROCK, ANY: the second never runs.
; - The script chain runs on into code at 083F: the engine reads its bytes
;   as key 50 6A 03 2E and next 1EFF (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
died_in_cave	EQU	RS_VARS+0	; Kirk was killed by the stalactite and revived (room 7)
score	EQU	RS_VARS+0Dh	; word: the mission's score

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0C7h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	82h
rdf_scale_min	LABEL	BYTE
	DW	0F0h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, -1, -1, 7	; room for each exit
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
	DW	260,146, 176,160	; entrance 2, crew 0
	DW	278,149, 92,184	; entrance 2, crew 1
	DW	281,143, 72,145	; entrance 2, crew 2
	DW	273,140, 195,169	; entrance 2, crew 3
	DW	34,153, 176,160	; entrance 3, crew 0
	DW	20,161, 92,184	; entrance 3, crew 1
	DW	24,143, 72,145	; entrance 3, crew 2
	DW	10,150, 195,169	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	176,160, 92,184, 72,145, 195,169
; In the room file, so these start again each time the room loads
blows	LABEL	BYTE	; the rock has hit the crystal
	DB	0
N_s5r1kt	LABEL	BYTE
	DB	's5r1kt',0
N_s5r6kr	LABEL	BYTE
	DB	's5r6kr',0
N_s5r6kp	LABEL	BYTE
	DB	's5r6kp',0
N_s5r6kd	LABEL	BYTE
	DB	's5r6kd',0
N_s5r1ru	LABEL	BYTE
	DB	's5r1ru',0
N_s5r6cx	LABEL	BYTE
	DB	's5r6cx',0
N_s5r6ts	LABEL	BYTE
	DB	's5r6ts',0
N_s5r6tm	LABEL	BYTE
	DB	's5r6tm',0
N_s5r6tf	LABEL	BYTE
	DB	's5r6tf',0
N_sscann	LABEL	BYTE
	DB	'sscann',0
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_sscane	LABEL	BYTE
	DB	'sscane',0
N_mscane	LABEL	BYTE
	DB	'mscane',0

rdf_scripts:
; The room starts: the crystal, the stalactite.
H_0126:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0180
StartRoom:
	jmp	SHORT L0137

N_FEA6LOOP	LABEL	BYTE
	DB	'FEA6LOOP',0
L0137:
	push	OFFSET N_FEA6LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("FEA6LOOP")
	add	sp, 4
	push	1Bh
	push	RC_MUSIC
	SERVICE		; Music(27)
	add	sp, 4
	push	0
	push	91h
	push	8Ah
	push	OFFSET N_s5r6cx
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s5r6cx", 138, 145, 0)
	add	sp, 0Ch
	push	0
	push	25h
	push	90h
	push	OFFSET N_s5r6ts
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s5r6ts", 144, 37, 0)
	add	sp, 0Ch
	retf

; Region 0: McCoy won't go back across the river.
H_0180:
	SCRIPT	MSG_REGION, 0, 0, 0, H_0190
BackToRiver:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA6_014
	call	Say
	retf

; The crew on the crystal: it needs prying loose.
H_0190:
	SCRIPT	MSG_USE, OBJ_SPOCK, 8, 0, H_01A0
SpockOnCrystal:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_020
	call	Say
	retf

H_01A0:
	SCRIPT	MSG_USE, OBJ_MCCOY, 8, 0, H_01B0
McCoyOnCrystal:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA6_009
	call	Say
	retf

H_01B0:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 8, 0, H_01C0
StrageyOnCrystal:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA6_040
	call	Say
	retf

; A rock at the stalactites (msg 7): one falls and kills Kirk (anim msg
; 2): -3, but a strange force takes him on to room 7.
H_01C0:
	SCRIPT	MSG_USE, IT_ROCK, 9, 0, H_01C8
	jmp	SHORT RockAtStalactites

H_01C8:
	SCRIPT	MSG_USE, IT_ROCK, 22h, 0, H_01E7
RockAtStalactites:
	mov	byte ptr [si+RS_BUSY], 1
	push	1
	push	97h
	push	94h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 148, 151, 1)
	add	sp, 0Ah
	retf

H_01E7:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_0219
KirkThrows:
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r1kt
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r1kt", -1, -1, 0)
	add	sp, 0Ch
	push	7
	push	4Eh
	push	96h
	push	OFFSET N_s5r1ru
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "s5r1ru", 150, 78, 7)
	add	sp, 0Ch
	retf

H_0219:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_0262
StalactiteFalls:
	push	0Bh
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(11)
	add	sp, 4
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r6tf
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s5r6tf", -1, -1, 0)
	add	sp, 0Ch
	push	2
	push	-1
	push	-1
	push	OFFSET N_s5r6kd
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r6kd", -1, -1, 2)
	add	sp, 0Ch
	push	1
	push	RC_MUSIC
	SERVICE		; Music(1)
	add	sp, 4
	retf

H_0262:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_0295
KirkKilled:
	add	word ptr [si+score], -3
	mov	byte ptr [si+died_in_cave], 1
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET S_0941
	mov	bx, OFFSET T_FEA6N000
	call	Say
	mov	ax, OFFSET S_0941
	mov	bx, OFFSET T_FEA6N004
	call	Say
	push	5
	push	7
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(7)
	add	sp, 4
	retf

; Hammering the crystal with a rock (msgs 4): the first blow loosens the
; stalactite (timer 2, rumbling), the second brings it down (msg 9).
H_0295:
	SCRIPT	MSG_USE, IT_ROCK, 8, 0, H_02B4
RockOnCrystal:
	mov	byte ptr [si+RS_BUSY], 1
	push	4
	push	97h
	push	9Ah
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 154, 151, 4)
	add	sp, 0Ah
	retf

H_02B4:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_030D
KirkHammers:
	mov	word ptr [si+RS_TIMERS+4], 0AEh
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r6tm
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s5r6tm", -1, -1, 0)
	add	sp, 0Ch
	cmp	byte ptr cs:blows, 0
	jne	L02F7
	inc	byte ptr cs:blows
	push	0Ah
	push	-1
	push	-1
	push	OFFSET N_s5r6kr
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r6kr", -1, -1, 10)
	add	sp, 0Ch
	retf

L02F7:
	push	9
	push	-1
	push	-1
	push	OFFSET N_s5r6kr
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r6kr", -1, -1, 9)
	add	sp, 0Ch
	retf

; Every tick: rumbles as timer 2 counts down after a blow.
H_030D:
	SCRIPT	MSG_TICK, ANY, ANY, ANY, H_0333
Rumbles:
	cmp	word ptr [si+RS_TIMERS+4], 37h
	je	L0326
	cmp	word ptr [si+RS_TIMERS+4], 59h
	je	L0326
	cmp	word ptr [si+RS_TIMERS+4], 77h
	je	L0326
	retf

L0326:
	push	0Bh
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(11)
	add	sp, 4
	retf

H_0333:
	SCRIPT	MSG_ANIM_DONE, 0Ah, 0, 0, H_0353
FewMoreBlows:
	mov	byte ptr [si+RS_BUSY], 0
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_FEA6_001
	call	Say
	retf

H_0353:
	SCRIPT	MSG_ANIM_DONE, 9, 0, 0, H_0390
StalactiteLoose:
	push	2
	push	-1
	push	-1
	push	OFFSET N_s5r6kd
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r6kd", -1, -1, 2)
	add	sp, 0Ch
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r6tf
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s5r6tf", -1, -1, 0)
	add	sp, 0Ch
	push	0
	push	RC_MUSIC
	SERVICE		; Music(0)
	add	sp, 4
	retf

; Rocks and the knife elsewhere. The two USE IT_ROCK, ANY scripts share a
; key, so the second never runs.
H_0390:
	SCRIPT	MSG_USE, IT_ROCK, 23h, 0, H_03A0
RockAtStalagmites:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_019
	call	Say
	retf

H_03A0:
	SCRIPT	MSG_USE, IT_ROCK, 20h, 0, H_03B0
RockAtEntrance:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_019
	call	Say
	retf

H_03B0:
	SCRIPT	MSG_USE, IT_ROCK, ANY, 0, H_03C0
UseRock:
	mov	ax, OFFSET S_0941
	mov	bx, OFFSET T_FEA6N009
	call	Say
	retf

H_03C0:
	SCRIPT	MSG_USE, IT_ROCK, ANY, 0, H_03D0
UseRockNever:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_021
	call	Say
	retf

H_03D0:
	SCRIPT	MSG_USE, IT_KNIFE, 23h, 0, H_03E0
KnifeOnStalagmites:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_028
	call	Say
	retf

H_03E0:
	SCRIPT	MSG_USE, IT_KNIFE, ANY, 0, H_03F0
UseKnife:
	mov	ax, OFFSET S_0941
	mov	bx, OFFSET T_FEA6N010
	call	Say
	retf

H_03F0:
	SCRIPT	MSG_USE, IT_KNIFE, OBJ_MCCOY, 0, H_0400
KnifeOnMcCoy:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_039
	call	Say
	retf

H_0400:
	SCRIPT	MSG_USE, IT_KNIFE, OBJ_SPOCK, 0, H_0410
KnifeOnSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_039
	call	Say
	retf

H_0410:
	SCRIPT	MSG_USE, IT_KNIFE, OBJ_REDSHIRT, 0, H_0420
KnifeOnStragey:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_039
	call	Say
	retf

H_0420:
	SCRIPT	MSG_USE, IT_CRYSTAL, ANY, 0, H_0430
UseCrystal:
	mov	ax, OFFSET S_0941
	mov	bx, OFFSET T_FEA6N015
	call	Say
	retf

H_0430:
	SCRIPT	MSG_USE, IT_SNAKE, ANY, 0, H_0440
UseSnake:
	mov	ax, OFFSET S_0941
	mov	bx, OFFSET T_FEA6N001
	call	Say
	retf

H_0440:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, H_04A3
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA6_011
	call	Say
	retf

T_FEA6_011	LABEL	BYTE
	DB	'#FEA6\FEA6_011#Everyone is healthy, Jim, there''s no need for the'
	DB	' medical kit here.',0

H_04A3:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_04B3
StunAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_023
	call	Say
	retf

H_04B3:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_04C3
KillAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_023
	call	Say
	retf

; Looking and talking.
H_04C3:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_04D2
LookAtEntrance:
	sub	ax, ax
	mov	bx, OFFSET T_FEA6N016
	call	Say
	retf

H_04D2:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_04E1
LookAtScene:
	sub	ax, ax
	mov	bx, OFFSET T_FEA6N003
	call	Say
	retf

H_04E1:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_04F0
LookAtRocks:
	sub	ax, ax
	mov	bx, OFFSET T_FEA6N014
	call	Say
	retf

H_04F0:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_04FF
LookAtStalagmites:
	sub	ax, ax
	mov	bx, OFFSET T_FEA6N013
	call	Say
	retf

H_04FF:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_050E
LookAtCrystal:
	sub	ax, ax
	mov	bx, OFFSET T_FEA6N005
	call	Say
	retf

H_050E:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_051D
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_FEA6N007
	call	Say
	retf

H_051D:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_052C
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_FEA6N011
	call	Say
	retf

H_052C:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_053B
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_FEA6N002
	call	Say
	retf

H_053B:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_054A
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_FEA6N008
	call	Say
	retf

H_054A:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_05AB
LookAtStalactites:
	mov	ax, OFFSET S_0941
	mov	bx, OFFSET T_FEA6N012
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_034
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA6_017
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_033
	call	Say
	mov	ax, OFFSET KirkOnArguing
	call	Talk
	AX8	cmp, 0
	jne	L0581
	jmp	SHORT L058D

L0581:
	AX8	cmp, 1
	jne	L0588
	jmp	SHORT L0597

L0588:
	AX8	cmp, 2
	jmp	SHORT L05A1

L058D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_032
	call	Say
	retf

L0597:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_036
	call	Say
	retf

L05A1:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_037
	call	Say
	retf

H_05AB:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_05BB
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA6_013
	call	Say
	retf

H_05BB:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_05EF
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA6_042
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_FEA6_002
	call	Say
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA6_041
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA6_016
	call	Say
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA6_043
	call	Say
	retf

H_05EF:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0645
TalkToSpock:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L063B
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_038
	call	Say
	mov	ax, OFFSET KirkOnQuetzecoatl
	call	Talk
	AX8	cmp, 0
	jne	L0611
	jmp	SHORT L061D

L0611:
	AX8	cmp, 1
	jne	L0618
	jmp	SHORT L0627

L0618:
	AX8	cmp, 2
	jmp	SHORT L0631

L061D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_029
	call	Say
	retf

L0627:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_030
	call	Say
	retf

L0631:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_031
	call	Say
	retf

L063B:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA6_035
	call	Say
	retf

; Tricorders.
H_0645:
	SCRIPT	MSG_USE, IT_MTRICOR, 20h, 0, H_0676
McCoyScansEntrance:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscane
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscane", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA6_012
	call	Say
	retf

H_0676:
	SCRIPT	MSG_USE, IT_MTRICOR, 21h, 0, H_0686
McCoyScansRocks:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA6_015
	call	Say
	retf

H_0686:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_06B7
SpockScansEntrance:
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
	mov	bx, OFFSET T_FEA6_024
	call	Say
	retf

H_06B7:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_06E8
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
	mov	bx, OFFSET T_FEA6_022
	call	Say
	retf

H_06E8:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_0719
SpockScansRocks:
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
	mov	bx, OFFSET T_FEA6_018
	call	Say
	retf

H_0719:
	SCRIPT	MSG_USE, IT_STRICOR, 8, 0, H_074A
SpockScansCrystal:
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
	mov	bx, OFFSET T_FEA6_027
	call	Say
	retf

H_074A:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_077B
SpockScansStalactites:
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
	mov	bx, OFFSET T_FEA6_025
	call	Say
	retf

H_077B:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_07AC
SpockScansStalagmites:
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
	mov	bx, OFFSET T_FEA6_026
	call	Say
	retf

; The crystal: pried loose with the knife (msgs 2, 3), +1; timer 4 takes
; it off the wall.
H_07AC:
	SCRIPT	MSG_GET, 8, 0, 0, H_07BC
GetCrystal:
	mov	ax, OFFSET S_0941
	mov	bx, OFFSET T_FEA6N020
	call	Say
	retf

H_07BC:
	SCRIPT	MSG_USE, IT_KNIFE, 8, 0, H_07DB
KnifeOnCrystal:
	mov	byte ptr [si+RS_BUSY], 1
	push	2
	push	97h
	push	9Ah
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 154, 151, 2)
	add	sp, 0Ah
	retf

H_07DB:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_07FC
KirkPries:
	push	3
	push	-1
	push	-1
	push	OFFSET N_s5r6kp
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r6kp", -1, -1, 3)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+8], 7Ah
	retf

H_07FC:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_082C
TookCrystal:
	mov	byte ptr [si+RS_BUSY], 0
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	add	word ptr [si+score], 1
	push	IT_CRYSTAL
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_CRYSTAL)
	add	sp, 4
	mov	ax, OFFSET S_0941
	mov	bx, OFFSET T_FEA6N017
	call	Say
	retf

H_082C:
	SCRIPT	MSG_TIMER, 4, 0, 0, Talk
CrystalGone:
	push	8
	push	RC_STOPANIM
	SERVICE		; StopAnim(8)
	add	sp, 4
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
	DW	21h, 3	; id, points
	DW	125,71, 155,145, 85,135
	DW	21h, 3	; id, points
	DW	166,64, 230,143, 167,144
	DW	22h, 4	; id, points
	DW	40,8, 290,8, 290,54, 40,54
	DW	23h, 4	; id, points
	DW	15,153, 286,153, 286,185, 15,185
	DW	20h, 4	; id, points
	DW	281,66, 304,66, 304,148, 281,148
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	3, 4	; id, points
	DW	0,130, 20,130, 20,175, 0,175
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	307,133, 318,133, 318,185, 307,185
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's5r61',0
	DB	's5r62',0
	DB	's5r63',0
	DB	's5r64',0
	DB	's5r65',0
	DB	's5r66',0
	DB	's5r67',0
	DB	's5r69',0
	DB	's5r610',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Stragey	LABEL	BYTE
	DB	'Lt. Stragey',0
S_0941	LABEL	BYTE
	DB	0
T_FEA6_020	LABEL	BYTE
	DB	'#FEA6\FEA6_020#I would suggest using something to pry that loose'
	DB	', Captain.',0
T_FEA6_009	LABEL	BYTE
	DB	'#FEA6\FEA6_009#Damn it Jim, I''m a surgeon not a geologist.',0
T_FEA6_040	LABEL	BYTE
	DB	'#FEA6\FEA6_040#I don''t think I''ll be able to get a good grip sir'
	DB	'. You might try prying it loose.',0
T_FEA6N000	LABEL	BYTE
	DB	'#FEA6\FEA6N000#A stalagtite breaks loose and falls. You are mort'
	DB	'ally injured and die.',0
T_FEA6_001	LABEL	BYTE
	DB	'#FEA6\FEA6_001#I think I can get it with a few more blows.',0
T_FEA6N009	LABEL	BYTE
	DB	'#FEA6\FEA6N009#Nothing happens.',0
T_FEA6_021	LABEL	BYTE
	DB	'#FEA6\FEA6_021#It is unwise to use a rock here, Captain.',0
T_FEA6N010	LABEL	BYTE
	DB	'#FEA6\FEA6N010#Nothing happens.',0
T_FEA6_039	LABEL	BYTE
	DB	'#FEA6\FEA6_039#Captain, have we done something wrong?',0
	DB	'#FEA6\FEA6N029#You scratch your initials. No dilithium crystals '
	DB	'were found.',0
	DB	'#FEA6\FEA6N028#You manage to pry loose one dilithium crystal.',0
T_FEA6N015	LABEL	BYTE
	DB	'#FEA6\FEA6N015#This is one place where dilithium crystals don''t '
	DB	'seem to be very useful.',0
T_FEA6N001	LABEL	BYTE
	DB	'#FEA6\FEA6N001#An interesting, but useless, manuever.',0
T_FEA6_019	LABEL	BYTE
	DB	'#FEA6\FEA6_019#I fail to see any logic in that action, Captain I'
	DB	't may also cause stalactites to fall.',0
T_FEA6_028	LABEL	BYTE
	DB	'#FEA6\FEA6_028#This illogical action would only dull the knife.',0
	DB	'#FEA6\FEA6N006#It''s Game Over man...',0
T_FEA6N005	LABEL	BYTE
	DB	'#FEA6\FEA6N005#It is a large cluster of crystals.',0
T_FEA6N016	LABEL	BYTE
	DB	'#FEA6\FEA6N016#This is the way that you entered the cave. If you'
	DB	' leave this way, the tentacled creature that attack you will pro'
	DB	'bably try to get a second course for its dinner.',0
T_FEA6N003	LABEL	BYTE
	DB	'#FEA6\FEA6N003#Darkness, leading into the unknown.',0
T_FEA6N014	LABEL	BYTE
	DB	'#FEA6\FEA6N014#They appear to be ordinary rocks. Spock''s tricord'
	DB	'er might say otherwise.',0
T_FEA6N012	LABEL	BYTE
	DB	'#FEA6\FEA6N012#Stalactites descend from the ceiling.',0
T_FEA6N013	LABEL	BYTE
	DB	'#FEA6\FEA6N013#Stalagmites rise from the floor of the cave.',0
T_FEA6_034	LABEL	BYTE
	DB	'#FEA6\FEA6_034#I should warn you that the stalactites could coll'
	DB	'apse quite easily. Any sudden motion could cause large quantitie'
	DB	's of stalactites to fall on us.',0
T_FEA6_017	LABEL	BYTE
	DB	'#FEA6\FEA6_017#Well isn''t that just great!',0
T_FEA6_033	LABEL	BYTE
	DB	'#FEA6\FEA6_033#Doctor, I would point out that your voice could a'
	DB	'lso trigger such a collapse.',0
T_FEA6_008	LABEL	BYTE
	DB	'#FEA6\FEA6_008#Will you two morons stop arguing just once!',0
T_FEA6_006	LABEL	BYTE
	DB	'#FEA6\FEA6_006#Then, gentlemen, I would advise you to stop argui'
	DB	'ng.',0
T_FEA6_004	LABEL	BYTE
	DB	'#FEA6\FEA6_004#Sometimes I feel like I''m the Captain of a nurser'
	DB	'y school.',0
T_FEA6_032	LABEL	BYTE
	DB	'#FEA6\FEA6_032#Captain, I cannot speak for Dr. McCoy, but my int'
	DB	'elligence quotient is far higher than humans...',0
T_FEA6_036	LABEL	BYTE
	DB	'#FEA6\FEA6_036#It would seem to be a prudent course of action Ca'
	DB	'ptain, if Doctor McCoy would agree.',0
T_FEA6_037	LABEL	BYTE
	DB	'#FEA6\FEA6_037#Really? That''s fascinating Captain.',0
T_FEA6N007	LABEL	BYTE
	DB	'#FEA6\FEA6N007#James Kirk remembers the last time he was in a ca'
	DB	've, and is glad that this one seems more peaceful.',0
T_FEA6N011	LABEL	BYTE
	DB	'#FEA6\FEA6N011#Spock is his usual stoic self.',0
T_FEA6N002	LABEL	BYTE
	DB	'#FEA6\FEA6N002#As usual, Dr. McCoy looks annoyed by the mission.'
	DB	' ',0
T_FEA6N008	LABEL	BYTE
	DB	'#FEA6\FEA6N008#Lieutenant Stragey looks nervously at the stalact'
	DB	'ites hovering precariously above you.',0
T_FEA6_042	LABEL	BYTE
	DB	'#FEA6\FEA6_042#Reminds me of some spelunking I did on Hades IV. '
	DB	'Ever do any climbing, Captain?',0
T_FEA6_002	LABEL	BYTE
	DB	'#FEA6\FEA6_002#Have you ever made it up the face of Half Dome, L'
	DB	'ieutenant?',0
T_FEA6_041	LABEL	BYTE
	DB	'#FEA6\FEA6_041#If we ever get back to Earth, one hundred credits'
	DB	' says I''ll beat you.',0
T_FEA6_016	LABEL	BYTE
	DB	'#FEA6\FEA6_016#Captains and security officers. They don''t realiz'
	DB	'e how fragile the human body can be.',0
T_FEA6_043	LABEL	BYTE
	DB	'#FEA6\FEA6_043#Sure we do. That''s the challenge.',0
T_FEA6_035	LABEL	BYTE
	DB	'#FEA6\FEA6_035#I would suggest we continue on, Captain. It would'
	DB	' not be logical to endanger ourselves by remaining here.',0
T_FEA6_038	LABEL	BYTE
	DB	'#FEA6\FEA6_038#There is a contradiction, Captain. If Quetzecoatl'
	DB	' is really an entity of peace, then Lt. Stragey should not have '
	DB	'died.',0
T_FEA6_003	LABEL	BYTE
	DB	'#FEA6\FEA6_003#Perhaps we should hold onto that hope, Mr. Spock,'
	DB	' that a civilised being will not kill for trivial motives.',0
T_FEA6_005	LABEL	BYTE
	DB	'#FEA6\FEA6_005#That creature was quite real Mr. Spock. We will d'
	DB	'iscuss this with our host, when we see him.',0
T_FEA6_007	LABEL	BYTE
	DB	'#FEA6\FEA6_007#Unfortunately, human history is full of people wh'
	DB	'o did not practice what they preached. Quetzecoatl is just one i'
	DB	'n a long line of them.',0
T_FEA6_029	LABEL	BYTE
	DB	'#FEA6\FEA6_029#Agreed, Captain.',0
T_FEA6_030	LABEL	BYTE
	DB	'#FEA6\FEA6_030#This whole experience feels like a test. The equi'
	DB	'valent of 20th Century earth lab rats running through a maze.',0
T_FEA6_031	LABEL	BYTE
	DB	'#FEA6\FEA6_031#I would wait until we meet him before judging him'
	DB	', Captain.',0
T_FEA6_013	LABEL	BYTE
	DB	'#FEA6\FEA6_013#I''ve lost any appetite I may have had for squid, '
	DB	'Jim',0
T_FEA6_012	LABEL	BYTE
	DB	'#FEA6\FEA6_012#It would appear that our tentacled friend wants d'
	DB	'essert. You can''t go back that way, unless you enjoy being eaten'
	DB	'.',0
T_FEA6_015	LABEL	BYTE
	DB	'#FEA6\FEA6_015#Well, they''re not organic. What did you think the'
	DB	'y were, calcified tribbles?',0
T_FEA6_024	LABEL	BYTE
	DB	'#FEA6\FEA6_024#The creature is still there, Captain.',0
T_FEA6_022	LABEL	BYTE
	DB	'#FEA6\FEA6_022#My tricorder indicates unusual energy patterns in'
	DB	' this direction, Captain.',0
T_FEA6_025	LABEL	BYTE
	DB	'#FEA6\FEA6_025#These stalactites were made from limestone deposi'
	DB	'ts. They took millennia to form.',0
T_FEA6_026	LABEL	BYTE
	DB	'#FEA6\FEA6_026#These stalagmites were made from limestone deposi'
	DB	'ts. They took millennia to form.',0
T_FEA6_018	LABEL	BYTE
	DB	'#FEA6\FEA6_018#Fascinating. These rocks are limestone, but conta'
	DB	'in an unusually high content of heavy metals. There are dilithiu'
	DB	'm crystals here, but in a very raw form.',0
T_FEA6_027	LABEL	BYTE
	DB	'#FEA6\FEA6_027#This appears to be a formation of raw dilithium c'
	DB	'rystals, Captain.',0
T_FEA6N017	LABEL	BYTE
	DB	'#FEA6\FEA6N017#You have one dilithium crystal, in raw form.',0
T_FEA6N020	LABEL	BYTE
	DB	'#FEA6\FEA6N020#You will need something to pry it loose.',0
T_FEA6_014	LABEL	BYTE
	DB	'#FEA6\FEA6_014#Jim! Going back across that river would be insane'
	DB	'.',0
T_FEA6N004	LABEL	BYTE
	DB	'#FEA6\FEA6N004#However, a strange force envelopes your body...',0
T_FEA6_023	LABEL	BYTE
	DB	'#FEA6\FEA6_023#Still inoperative, Captain.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0
KirkOnArguing	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_FEA6_008, OFFSET T_FEA6_006, OFFSET T_FEA6_004, 0	; speaker, choices, 0
KirkOnQuetzecoatl	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_FEA6_003, OFFSET T_FEA6_005, OFFSET T_FEA6_007, 0	; speaker, choices, 0

RDF	ENDS
	END
