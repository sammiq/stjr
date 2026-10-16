; MUDD1.RDF - "Another Fine Mess", the alien ship's weapons room. A claw
; loads cylinders, which Spock and Buchert recognise as powerboosters,
; into a weapons-delivery system; the buttons work it. Once Spock has
; studied it, Kirk decides whether the Enterprise should take it.
;
; Actors: 8 the claw, 9 the cartridge, 10 (0Ah) the loading, 11, 12
; (0Bh, 0Ch) the doors.
; Objects: 8 the claw, 9/20h/21h the cylinders, 22h the weapon, 23h the
; blue buttons, 24h the yellow, 25h the red.
; Exits: 0 room 3, 1 room 0, 3 room 2. Regions 0-2: the doorsteps.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 0AE3: the engine reads its bytes
;   as key 50 6A 03 2E and next 1EFF (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
loaded	EQU	RS_VARS+0Ah	; the claw has loaded a cartridge into the weapon
weapon_examined	EQU	RS_VARS+0Bh	; Spock has worked out the weapon
used_device	EQU	RS_VARS+13h	; the alien device has been fired, anywhere (+5 once)
take_weapon	EQU	RS_VARS+14h	; Kirk has decided to take the weapon to the Enterprise
air_failing	EQU	RS_VARS+1Dh	; life support is failing: the countdown runs (room 5)
air_left	EQU	RS_VARS+27h	; word: ticks of air left, from 6978h
air_countdown	EQU	RS_VARS+29h	; word: the countdown has started
pressed_blue	EQU	RS_VARS+2Ch	; the points for loading
pressed_red	EQU	RS_VARS+2Dh	; the points for firing
music_started	EQU	RS_VARS+2Fh
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
	DW	70h
rdf_scale_min	LABEL	BYTE
	DW	90h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	3, 0, -1, 2	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	69,132, 172,150	; entrance 0, crew 0
	DW	56,129, 159,143	; entrance 0, crew 1
	DW	61,117, 185,142	; entrance 0, crew 2
	DW	47,113, 172,136	; entrance 0, crew 3
	DW	170,185, 170,165	; entrance 1, crew 0
	DW	131,192, 131,172	; entrance 1, crew 1
	DW	188,193, 188,173	; entrance 1, crew 2
	DW	161,199, 161,179	; entrance 1, crew 3
	DW	0,0, 0,0	; entrance 2, crew 0
	DW	0,0, 0,0	; entrance 2, crew 1
	DW	0,0, 0,0	; entrance 2, crew 2
	DW	0,0, 0,0	; entrance 2, crew 3
	DW	172,126, 172,150	; entrance 3, crew 0
	DW	159,119, 159,143	; entrance 3, crew 1
	DW	185,118, 185,142	; entrance 3, crew 2
	DW	172,112, 172,136	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	170,165, 131,172, 188,173, 161,179
; In the room file, so these start again each time the room loads
going_door	LABEL	BYTE	; 1 the lower or right door, 2 the left
	DB	0
collapsed	LABEL	BYTE	; crew members down when the air ran out
	DB	0
N_s4wbhs	LABEL	BYTE
	DB	's4wbhs',0
N_s4wbcs	LABEL	BYTE
	DB	's4wbcs',0
N_s4wbcr	LABEL	BYTE
	DB	's4wbcr',0
N_s4wbcn	LABEL	BYTE
	DB	's4wbcn',0
N_s4wbsl	LABEL	BYTE
	DB	's4wbsl',0
N_s4wbhb	LABEL	BYTE
	DB	's4wbhb',0
N_s4wbcb	LABEL	BYTE
	DB	's4wbcb',0
N_s4wbsb	LABEL	BYTE
	DB	's4wbsb',0
N_susemn	LABEL	BYTE
	DB	'susemn',0
N_s4wbd1	LABEL	BYTE
	DB	's4wbd1',0
N_s4wbd2	LABEL	BYTE
	DB	's4wbd2',0
N_s4cbxp	LABEL	BYTE
	DB	's4cbxp',0
N_kgetdn	LABEL	BYTE
	DB	'kgetdn',0
N_sgetde	LABEL	BYTE
	DB	'sgetde',0
N_mgetds	LABEL	BYTE
	DB	'mgetds',0
N_rgetdw	LABEL	BYTE
	DB	'rgetdw',0
N_sscanw	LABEL	BYTE
	DB	'sscanw',0

rdf_scripts:
; The room starts: the claw, and the cartridge if loaded.
H_0143:
	SCRIPT	MSG_TICK, 1, 0, 0, H_01AB
StartRoom:
	cmp	byte ptr [si+music_started], 1
	je	L0179
	push	0
	push	RC_MUSIC
	SERVICE		; Music(0)
	add	sp, 4
	mov	byte ptr [si+music_started], 1
	jmp	SHORT L016A

N_MUD1LOOP	LABEL	BYTE
	DB	'MUD1LOOP',0
L016A:
	push	OFFSET N_MUD1LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUD1LOOP")
	add	sp, 4
L0179:
	push	0
	push	31h
	push	9Bh
	push	OFFSET N_s4wbhs
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s4wbhs", 155, 49, 0)
	add	sp, 0Ch
	cmp	byte ptr [si+loaded], 0
	jne	L01AA
	push	0
	push	65h
	push	32h
	push	OFFSET N_s4wbcs
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s4wbcs", 50, 101, 0)
	add	sp, 0Ch
L01AA:
	retf

; Timer 1: a sound.
H_01AB:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_01BE
Timer1Sound:
	push	7
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(7)
	add	sp, 4
	retf

H_01BE:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_01FC
CallEnterprise:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD1_001
	call	Say
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_STATICU1
	call	Say
	retf

T_MUD1_001	LABEL	BYTE
	DB	'#MUD1\MUD1_001#Kirk to Enterprise...',0

; The buttons, Spock only: blue loads a cartridge (msgs 1, 1, 2, +2 once),
; yellow unloads it (msgs 2, 3), red (loaded) has Spock work out the
; weapon (msgs 3, 4, +3 once), and Kirk decides what to do with it.
H_01FC:
	SCRIPT	MSG_USE, OBJ_SPOCK, 23h, 0, H_022E
SpockPressesBlue:
	cmp	byte ptr [si+loaded], 0
	jne	L022D
	push	1
	push	9Fh
	push	2Fh
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 47, 159, 1)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	cmp	byte ptr [si+pressed_blue], 1
	je	L022D
	mov	byte ptr [si+pressed_blue], 1
	add	word ptr [si+score], 2
L022D:
	retf

H_022E:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_0253
SpockAtButtons:
	mov	byte ptr [si+RS_FALL+1], 2
	push	1
	push	-1
	push	-1
	push	OFFSET N_susemn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemn", -1, -1, 1)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+2], 5
	retf

H_0253:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_02B7
ClawLoads:
	jmp	SHORT L0263

N_crn2can	LABEL	BYTE
	DB	'crn2can',0
L0263:
	push	OFFSET N_crn2can
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("crn2can")
	add	sp, 4
	push	0
	push	-1
	push	-1
	push	OFFSET N_s4wbcr
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s4wbcr", -1, -1, 0)
	add	sp, 0Ch
	push	0
	push	-1
	push	-1
	push	OFFSET N_s4wbcn
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s4wbcn", -1, -1, 0)
	add	sp, 0Ch
	push	2
	push	83h
	push	77h
	push	OFFSET N_s4wbsl
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "s4wbsl", 119, 131, 2)
	add	sp, 0Ch
	mov	byte ptr [si+loaded], 1
	retf

H_02B7:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_02EE
ClawDone:
	mov	byte ptr [si+RS_BUSY], 0
	push	0
	push	9Fh
	push	43h
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 67, 159, 0)
	add	sp, 0Ah
	cmp	byte ptr [si+loaded], 1
	je	L02E4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD1_016
	call	Say
	retf

L02E4:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD1_017
	call	Say
	retf

H_02EE:
	SCRIPT	MSG_USE, OBJ_SPOCK, 24h, 0, H_0316
SpockPressesYellow:
	cmp	byte ptr [si+loaded], 1
	jne	L0315
	mov	byte ptr [si+RS_FALL+1], 2
	push	2
	push	9Fh
	push	2Fh
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 47, 159, 2)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
L0315:
	retf

H_0316:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_0337
SpockAtButtons2:
	push	3
	push	-1
	push	-1
	push	OFFSET N_susemn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemn", -1, -1, 3)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+2], 5
	retf

H_0337:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_039B
ClawUnloads:
	jmp	SHORT L0348

N_crn2rack	LABEL	BYTE
	DB	'crn2rack',0
L0348:
	push	OFFSET N_crn2rack
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("crn2rack")
	add	sp, 4
	push	0
	push	-1
	push	-1
	push	OFFSET N_s4wbhb
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s4wbhb", -1, -1, 0)
	add	sp, 0Ch
	push	0
	push	65h
	push	32h
	push	OFFSET N_s4wbcb
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s4wbcb", 50, 101, 0)
	add	sp, 0Ch
	push	2
	push	-1
	push	-1
	push	OFFSET N_s4wbsb
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s4wbsb", -1, -1, 2)
	add	sp, 0Ch
	mov	byte ptr [si+loaded], 0
	retf

H_039B:
	SCRIPT	MSG_USE, OBJ_SPOCK, 25h, 0, H_03CD
SpockPressesRed:
	cmp	byte ptr [si+loaded], 1
	jne	L03CC
	push	3
	push	9Fh
	push	2Fh
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 47, 159, 3)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	cmp	byte ptr [si+pressed_red], 1
	je	L03CC
	mov	byte ptr [si+pressed_red], 1
	add	word ptr [si+score], 3
L03CC:
	retf

H_03CD:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_03EE
SpockAtButtons3:
	push	4
	push	-1
	push	-1
	push	OFFSET N_susemn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemn", -1, -1, 4)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+2], 5
	retf

H_03EE:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_0461
SpockOnWeapon:
	push	0
	push	9Fh
	push	43h
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 67, 159, 0)
	add	sp, 0Ah
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD1_022
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD1_021
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD1_023
	call	Say
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr [si+weapon_examined], 1
	mov	ax, OFFSET KirkDecides
	call	Talk
	AX8	cmp, 0
	jne	L0444
	mov	word ptr [si+take_weapon], 0
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_1388
	call	Say
	retf

L0444:
	AX8	cmp, 1
	jne	L0452
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD1_007
	call	Say
L0452:
	mov	word ptr [si+take_weapon], 1
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_STATICU1
	call	Say
	retf

H_0461:
	SCRIPT	MSG_USE, IT_DEGRIME, ANY, 0, H_0471
UseDegrimer:
	mov	ax, OFFSET S_0C64
	mov	bx, OFFSET T_MUD1N004
	call	Say
	retf

; Common to all of the mission's rooms: the de-grimer on the lenses makes
; the alien device (+1); firing the device sets off an explosion at Kirk
; (anim msg 9), +5 the first time anywhere; the de-grimer on anything else
; just cleans it.
H_0471:
	SCRIPT	MSG_USE, IT_LENSES, IT_DEGRIME, 0, H_049F
CleanLenses:
	push	IT_LENSES
	push	RC_TAKEITEM
	push	IT_DEGRIME
	push	RC_TAKEITEM
	push	IT_ALIENDV
	push	RC_GIVEITEM
	mov	di, 3
L0486:
	SERVICE		; GiveItem(IT_ALIENDV); TakeItem(IT_DEGRIME); TakeItem(IT_LENSES)
	add	sp, 4
	dec	di
	jne	L0486
	add	word ptr [si+score], 1
	mov	ax, OFFSET S_0C64
	mov	bx, OFFSET T_MUD1N013
	call	Say
	retf

H_049F:
	SCRIPT	MSG_USE, IT_ALIENDV, ANY, 0, H_04F2
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
	push	0Dh
	push	RC_ANIM0
	SERVICE		; Anim0(13, "s4cbxp", ?, 10, 9)
	add	sp, 0Ch
	jmp	SHORT L04E2

N_EXPLO3	LABEL	BYTE
	DB	'EXPLO3',0
L04E2:
	push	OFFSET N_EXPLO3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EXPLO3")
	add	sp, 4
	retf

; The alien device has gone off here (anim msg 9).
H_04F2:
	SCRIPT	MSG_ANIM_DONE, 9, 0, 0, H_0514
DeviceFired:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+used_device], 0
	jne	L0513
	mov	byte ptr [si+used_device], 1
	add	word ptr [si+score], 5
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD1_002
	call	Say
L0513:
	retf

; Getting the cylinders: too heavy.
H_0514:
	SCRIPT	MSG_GET, 9, 0, 0, H_051C
	jmp	SHORT GetCylinders

H_051C:
	SCRIPT	MSG_GET, 21h, 0, 0, H_0524
GetCylinders:
	jmp	SHORT GetCylinders2

H_0524:
	SCRIPT	MSG_GET, 20h, 0, 0, H_0534
GetCylinders2:
	mov	ax, OFFSET S_0C64
	mov	bx, OFFSET T_MUD1N014
	call	Say
	retf

; Tricorders: the cylinders are powerboosters.
H_0534:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_053C
	jmp	SHORT SpockScansCylinders

H_053C:
	SCRIPT	MSG_USE, IT_STRICOR, 9, 0, H_0544
SpockScansCylinders:
	jmp	SHORT SpockScansCylinders2

H_0544:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_0599
SpockScansCylinders2:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscanw
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscanw", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD1_025
	call	Say
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD1_027
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD1_020
	call	Say
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD1_028
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD1_024
	call	Say
	retf

H_0599:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_05CA
SpockScansWeapon:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscanw
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscanw", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD1_010
	call	Say
	retf

H_05CA:
	SCRIPT	MSG_USE, IT_STRICOR, 25h, 0, H_05D2
	jmp	SHORT SpockScansBlue

H_05D2:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_05DA
SpockScansBlue:
	jmp	SHORT SpockScansButtons

H_05DA:
	SCRIPT	MSG_USE, IT_STRICOR, 24h, 0, H_05EA
SpockScansButtons:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD1_015
	call	Say
	retf

H_05EA:
	SCRIPT	MSG_USE, IT_STRICOR, 8, 0, H_05FA
SpockScansClaw:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD1_014
	call	Say
	retf

H_05FA:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, H_065D
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD1_011
	call	Say
	retf

T_MUD1_011	LABEL	BYTE
	DB	'#MUD1\MUD1_011#Everyone is healthy, Jim, there''s no need for the'
	DB	' medical kit here.',0

H_065D:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_066C
LookAtScene:
	sub	ax, ax
	mov	bx, OFFSET T_MUD1N011
	call	Say
	retf

; Looking.
H_066C:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_067B
LookAtCylinders:
	sub	ax, ax
	mov	bx, OFFSET T_MUD1N002
	call	Say
	retf

H_067B:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_068A
LookAtCylinders2:
	sub	ax, ax
	mov	bx, OFFSET T_MUD1N002
	call	Say
	retf

H_068A:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_0699
LookAtFallenCylinders:
	sub	ax, ax
	mov	bx, OFFSET T_MUD1N012
	call	Say
	retf

H_0699:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_06A8
LookAtWeapon:
	sub	ax, ax
	mov	bx, OFFSET T_MUD1N003
	call	Say
	retf

H_06A8:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_06B7
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_MUD1N005
	call	Say
	retf

H_06B7:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_06C6
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_MUD1N009
	call	Say
	retf

H_06C6:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_06D5
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_MUD1N008
	call	Say
	retf

H_06D5:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_06E4
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_MUD1N006
	call	Say
	retf

H_06E4:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_06F3
LookAtClaw:
	sub	ax, ax
	mov	bx, OFFSET T_MUD1N000
	call	Say
	retf

H_06F3:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_0702
LookAtRedButton:
	sub	ax, ax
	mov	bx, OFFSET T_MUD1N001
	call	Say
	retf

H_0702:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_0711
LookAtBlueButtons:
	sub	ax, ax
	mov	bx, OFFSET T_MUD1N015
	call	Say
	retf

H_0711:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_0720
LookAtYellowButtons:
	sub	ax, ax
	mov	bx, OFFSET T_MUD1N016
	call	Say
	retf

H_0720:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0742
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD1_006
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD1_013
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD1_005
	call	Say
	retf

H_0742:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_075B
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD1_019
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD1_008
	call	Say
	retf

H_075B:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_076B
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD1_012
	call	Say
	retf

H_076B:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0784
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD1_026
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD1_009
	call	Say
	retf

; The doors: walk there; at the step the door slides (regions 0-2).
H_0784:
	SCRIPT	MSG_WALK, 28h, 0, 0, H_07A9
WalkToLowerDoor:
	mov	byte ptr cs:going_door, 1
	mov	byte ptr [si+RS_BUSY], 1
	push	0
	push	0C7h
	push	0A0h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 160, 199, 0)
	add	sp, 0Ah
	retf

H_07A9:
	SCRIPT	MSG_REGION, 2, 0, 0, H_07D2
ReachLowerDoor:
	cmp	byte ptr cs:going_door, 1
	jne	L07D1
	jmp	SHORT L07C2

N_SMADOOR3	LABEL	BYTE
	DB	'SMADOOR3',0
L07C2:
	push	OFFSET N_SMADOOR3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SMADOOR3")
	add	sp, 4
L07D1:
	retf

H_07D2:
	SCRIPT	MSG_WALK, 27h, 0, 0, H_07F6
WalkToRightDoor:
	mov	byte ptr cs:going_door, 1
	mov	byte ptr [si+RS_BUSY], 1
	push	0
	push	71h
	push	0ABh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 171, 113, 0)
	add	sp, 0Ah
	retf

H_07F6:
	SCRIPT	MSG_REGION, 1, 0, 0, H_0835
ReachRightDoor:
	cmp	byte ptr cs:going_door, 1
	jne	L0834
	jmp	SHORT L080F

N_SMADOOR3_2	LABEL	BYTE
	DB	'SMADOOR3',0
L080F:
	push	OFFSET N_SMADOOR3_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SMADOOR3")
	add	sp, 4
	push	0
	push	73h
	push	0ABh
	push	OFFSET N_s4wbd1
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, "s4wbd1", 171, 115, 0)
	add	sp, 0Ch
L0834:
	retf

H_0835:
	SCRIPT	MSG_WALK, 26h, 0, 0, H_0858
WalkToLeftDoor:
	mov	byte ptr cs:going_door, 2
	mov	byte ptr [si+RS_BUSY], 1
	push	0
	push	71h
	push	35h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 53, 113, 0)
	add	sp, 0Ah
	retf

H_0858:
	SCRIPT	MSG_REGION, 0, 0, 0, H_0896
ReachLeftDoor:
	cmp	byte ptr cs:going_door, 2
	jne	L0895
	jmp	SHORT L0871

N_SMADOOR3_3	LABEL	BYTE
	DB	'SMADOOR3',0
L0871:
	push	OFFSET N_SMADOOR3_3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SMADOOR3")
	add	sp, 4
	push	0
	push	73h
	push	37h
	push	OFFSET N_s4wbd2
	push	0Ch
	push	RC_ANIM0
	SERVICE		; Anim0(12, "s4wbd2", 55, 115, 0)
	add	sp, 0Ch
L0895:
	retf

; Every tick, common to all of the mission's rooms: while life support is
; failing, the air runs down from 6978h, with warnings at 4F1Ah, 34BCh
; and 1A5Eh; at 1 the crew collapse (walk msgs 9-12) and the game is
; over.
H_0896:
	SCRIPT	MSG_TICK, ANY, ANY, ANY, H_09E0
AirRunsOut:
	cmp	byte ptr [si+air_failing], 0
	je	L0911
	cmp	word ptr [si+air_countdown], 1
	je	L08B2
	mov	word ptr [si+air_countdown], 1
	mov	word ptr [si+air_left], 6978h
L08B2:
	dec	word ptr [si+air_left]
	cmp	word ptr [si+air_left], 1A5Eh
	je	L0926
	cmp	word ptr [si+air_left], 34BCh
	je	L091C
	cmp	word ptr [si+air_left], 4F1Ah
	je	L0912
	cmp	word ptr [si+air_left], 1
	jne	L0911
	mov	byte ptr [si+RS_BUSY], 1
	push	9
	push	0A5h
	push	0AAh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 170, 165, 9)
	add	sp, 0Ah
	push	0Ah
	push	0ACh
	push	83h
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 131, 172, 10)
	add	sp, 0Ah
	mov	ax, OFFSET S_0C64
	mov	bx, OFFSET T_MUD1N007
	call	Say
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
L0911:
	retf

L0912:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_0930
	call	Say
	retf

L091C:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_0953
	call	Say
	retf

L0926:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_0976
	call	Say
	retf

S_0930	LABEL	BYTE
	DB	'Life support down to 75%, Captain.',0
S_0953	LABEL	BYTE
	DB	'Life support down to 50%, Captain.',0
S_0976	LABEL	BYTE
	DB	'Life support down to 25%, Captain.',0
T_MUD1N007	LABEL	BYTE
	DB	'#MUD1\MUD1N007#Life support fails completely and you fall uncons'
	DB	'cious.',0

H_09E0:
	SCRIPT	MSG_WALK_DONE, 9, 0, 0, H_0A27
KirkCollapses:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kgetdn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kgetdn", -1, -1, 0)
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
	jmp	SHORT L0A42

H_0A27:
	SCRIPT	MSG_WALK_DONE, 0Ah, 0, 0, Talk
SpockCollapses:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sgetde
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sgetde", -1, -1, 0)
	add	sp, 0Ch
L0A42:
	inc	byte ptr cs:collapsed
	cmp	byte ptr cs:collapsed, 2
	jne	L0A58
	mov	ax, OFFSET S_0C64
	mov	bx, OFFSET T_MUD1N010
	call	Say
L0A58:
	retf

T_MUD1N010	LABEL	BYTE
	DB	'#MUD1\MUD1N010#The atmosphere in the ship has dropped below the '
	DB	'level needed to sustain life. You drop to unconsciousness and sl'
	DB	'owly die.',0
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
	DW	22h, 5	; id, points
	DW	84,29, 173,148, 155,158, 95,148, 49,46
	DW	20h, 4	; id, points
	DW	21,73, 44,71, 44,102, 21,99
	DW	21h, 4	; id, points
	DW	20,165, 76,167, 56,193, 21,182
	DW	23h, 4	; id, points
	DW	30,132, 63,132, 63,136, 30,136
	DW	24h, 4	; id, points
	DW	38,128, 56,128, 56,131, 38,131
	DW	25h, 4	; id, points
	DW	43,122, 51,122, 51,127, 43,127
	DW	26h, 4	; id, points
	DW	48,75, 67,75, 67,128, 48,128
	DW	27h, 4	; id, points
	DW	154,75, 188,75, 188,134, 154,134
	DW	28h, 4	; id, points
	DW	64,199, 64,185, 319,185, 319,199
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	0, 4	; id, points
	DW	48,113, 67,113, 67,116, 48,116
	DW	1, 4	; id, points
	DW	64,199, 64,196, 319,196, 319,199
	DW	3, 4	; id, points
	DW	154,113, 188,113, 188,116, 154,116
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	48,117, 67,117, 67,128, 48,128
	DW	1, 4	; id, points
	DW	154,117, 188,117, 188,134, 154,134
	DW	2, 4	; id, points
	DW	64,195, 64,185, 319,185, 319,195
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
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
S_0C64	LABEL	BYTE
	DB	0
T_MUD1N011	LABEL	BYTE
	DB	'#MUD1\MUD1N011#The room reminds you of the weapons-room of some '
	DB	'old-style warships from the early days of starfaring.',0
T_MUD1N002	LABEL	BYTE
	DB	'#MUD1\MUD1N002#A row of unmarked cylindrical containers.',0
T_MUD1N012	LABEL	BYTE
	DB	'#MUD1\MUD1N012#These cylinders have fallen down from the rest.',0
T_MUD1N003	LABEL	BYTE
	DB	'#MUD1\MUD1N003#An elaborate piece of alien-looking machinery.',0
T_MUD1_026	LABEL	BYTE
	DB	'#MUD1\MUD1_026#It looks to me like these people knew how to defe'
	DB	'nd themselves, Captain.',0
T_MUD1_009	LABEL	BYTE
	DB	'#MUD1\MUD1_009#That machinery in the middle of the room, however'
	DB	', is like nothing I recognize -- and I thought I''d seen just abo'
	DB	'ut everything.',0
T_MUD1N014	LABEL	BYTE
	DB	'#MUD1\MUD1N014#This is much too heavy to lift.',0
T_MUD1_010	LABEL	BYTE
	DB	'#MUD1\MUD1_010#A weapons-delivery system.  It appears to be an a'
	DB	'ccessory tied directly to the alien equivalent of our ship''s pha'
	DB	'sers and photon torpedoes.',0
T_MUD1_025	LABEL	BYTE
	DB	'#MUD1\MUD1_025#Unique, Captain.  I believe these are self-refere'
	DB	'ncing packed-quantum cartridges.  ',0
T_MUD1_027	LABEL	BYTE
	DB	'#MUD1\MUD1_027#Powerboosters!  I''ve read about those --  but the'
	DB	'y''re just theoretical.',0
T_MUD1_020	LABEL	BYTE
	DB	'#MUD1\MUD1_020#Evidently these are more than theoretical, Lt. Bu'
	DB	'chert.  The energy initially released is infinitesimally small b'
	DB	'ut boosts itself until the power finally released is comparable '
	DB	'to our photon torpedoes.',0
T_MUD1_028	LABEL	BYTE
	DB	'#MUD1\MUD1_028#The technical journals discussing the possibiliti'
	DB	'es indicated it would create a weapon of greater range than thos'
	DB	'e we have now, if not a greater punch.  ',0
T_MUD1_024	LABEL	BYTE
	DB	'#MUD1\MUD1_024#The machinery to deliver these cartridges would b'
	DB	'e an engineering feat as well, Captain.',0
T_MUD1_022	LABEL	BYTE
	DB	'#MUD1\MUD1_022#I believe, Captain, that this weapon must be hook'
	DB	'ed up through the main weapons battery.',0
T_MUD1_021	LABEL	BYTE
	DB	'#MUD1\MUD1_021#However, I''ve already examined the weapons consol'
	DB	'e and the main weapons battery on this ship was completely destr'
	DB	'oyed in the action which made her a derelict.',0
T_MUD1_023	LABEL	BYTE
	DB	'#MUD1\MUD1_023#Mr. Scott would have to go over this thoroughly, '
	DB	'but I would recommend we try to take this weapon with us to the '
	DB	'Enterprise.',0
S_1388	LABEL	BYTE
	DB	'(Spock raises eyebrow)',0
T_MUD1_004	LABEL	BYTE
	DB	'#MUD1\MUD1_004#I don''t think we should tinker with technology we'
	DB	' don''t understand, Spock. And I''m surprised you''d suggest such a'
	DB	' thing.',0
	DB	0
T_MUD1_003	LABEL	BYTE
	DB	'#MUD1\MUD1_003#I agree that we should take it aboard the Enterpr'
	DB	'ise.  ',0
T_MUD1_007	LABEL	BYTE
	DB	'#MUD1\MUD1_007#I''ll try to raise the ship... Kirk to Enterprise,'
	DB	' Kirk to Enterprise...',0
T_STATICU1	LABEL	BYTE
	DB	'#SFX\STATICU1#Ent... neu ... trans...',0
	DB	0
T_MUD1N005	LABEL	BYTE
	DB	'#MUD1\MUD1N005#James T. Kirk, dwarfed by the technology that sur'
	DB	'rounds him. ',0
T_MUD1N009	LABEL	BYTE
	DB	'#MUD1\MUD1N009#Mr. Spock is looking forward to the moment that h'
	DB	'e can sit down at the main computer and analyze the findings of '
	DB	'this mission. ',0
T_MUD1N008	LABEL	BYTE
	DB	'#MUD1\MUD1N008#McCoy is scowling, probably from your meeting wit'
	DB	'h Harcourt Fenton Mudd. ',0
T_MUD1N006	LABEL	BYTE
	DB	'#MUD1\MUD1N006#Lieutenant Buchert, waiting for a chance to perfo'
	DB	'rm his duty. ',0
T_MUD1_006	LABEL	BYTE
	DB	'#MUD1\MUD1_006#I wonder what''s happening on the Enterprise right'
	DB	' now. ',0
T_MUD1_013	LABEL	BYTE
	DB	'#MUD1\MUD1_013#Scotty will take good care of it, Jim. He has bef'
	DB	'ore. ',0
T_MUD1_005	LABEL	BYTE
	DB	'#MUD1\MUD1_005#I know, Bones. ',0
T_MUD1_019	LABEL	BYTE
	DB	'#MUD1\MUD1_019#A most interesting technology, Captain.',0
T_MUD1_008	LABEL	BYTE
	DB	'#MUD1\MUD1_008#If the Elasi gets hold of this, they''ll make Mudd'
	DB	' seem like a perfect caretaker by comparison. ',0
T_MUD1_012	LABEL	BYTE
	DB	'#MUD1\MUD1_012#I wonder where that Mudd has gone. I wouldn''t let'
	DB	' him out of my sight... mind you, I''m not too crazy about having'
	DB	' him in my sight either. ',0
T_MUD1_017	LABEL	BYTE
	DB	'#MUD1\MUD1_017#The device has finished loading, Captain.',0
T_MUD1_016	LABEL	BYTE
	DB	'#MUD1\MUD1_016#The device has been unloaded, Captain.',0
T_MUD1N000	LABEL	BYTE
	DB	'#MUD1\MUD1N000#A large claw-like device hanging from the ceiling'
	DB	'.',0
T_MUD1N001	LABEL	BYTE
	DB	'#MUD1\MUD1N001#A red triangular button.',0
T_MUD1N016	LABEL	BYTE
	DB	'#MUD1\MUD1N016#Two yellow triangular buttons.',0
T_MUD1N015	LABEL	BYTE
	DB	'#MUD1\MUD1N015#Three triangular blue buttons.',0
T_MUD1_014	LABEL	BYTE
	DB	'#MUD1\MUD1_014#It seems to be part of the loading system for the'
	DB	' weapon. It is also fully functional.',0
T_MUD1_015	LABEL	BYTE
	DB	'#MUD1\MUD1_015#The control panel has power running to it, Captai'
	DB	'n.',0
T_MUD1_002	LABEL	BYTE
	DB	'#MUD1\MUD1_002#Well, now! I think we know why the Elasi pirates '
	DB	'were so interested in finding out where Mudd was getting these!',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0
T_MUD1N013	LABEL	BYTE
	DB	'#MUD1\MUD1N013#These two things fit together like they were made'
	DB	' for each other.',0
T_MUD1N004	LABEL	BYTE
	DB	'#MUD1\MUD1N004#Dust and grease lifts off the surface, leaving th'
	DB	'is item clean as new.',0
KirkDecides	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_MUD1_004, OFFSET T_MUD1_003, OFFSET T_MUD1_007, 0	; speaker, choices, 0

RDF	ENDS
	END
