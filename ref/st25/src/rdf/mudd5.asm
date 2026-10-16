; MUDD5.RDF - "Another Fine Mess", the alien ship's engine pod, where
; Mudd's salvage hatch joins his own ship and his cheap "Sav-a-Ship" life
; support generator runs. On the party's second visit Mudd comes asking
; for his doover, and the generator fails (the air starts running out in
; every room); Kirk repairs it with the doover.
;
; Actors: 8 Mudd, 9 the generator, 10 (0Ah) the door.
; Objects: 9 the generator, 20h the hatch, 21h the engine, 22h the door,
; 23h the crane. Exit 0: the cargo bay (room 0).
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - Firing the alien device here (DeviceFired) sets used_device without the
;   +5 the other rooms give, so the points are lost if it happens here first.
; - The script chain runs on into code at 0A04: the engine reads its bytes
;   as key 50 6A 03 2E and next 1EFF (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
used_device	EQU	RS_VARS+13h	; the alien device has been fired, anywhere (+5 once)
mudd_incident	EQU	RS_VARS+16h	; Mudd is causing trouble somewhere: no other scene with him starts
air_failing	EQU	RS_VARS+1Dh	; life support is failing: the countdown runs (room 5)
visits	EQU	RS_VARS+1Eh	; visits to this room, up to 2: Mudd's scene
air_left	EQU	RS_VARS+27h	; word: ticks of air left, from 6978h
air_countdown	EQU	RS_VARS+29h	; word: the countdown has started
generator_fixed	EQU	RS_VARS+30h	; Kirk has repaired the generator (+2)
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
	DW	74h
rdf_scale_min	LABEL	BYTE
	DW	78h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	0, -1, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	135,131, 139,172	; entrance 0, crew 0
	DW	119,122, 111,153	; entrance 0, crew 1
	DW	147,121, 179,166	; entrance 0, crew 2
	DW	132,117, 206,153	; entrance 0, crew 3
	DW	0,0, 0,0	; entrance 1, crew 0
	DW	0,0, 0,0	; entrance 1, crew 1
	DW	0,0, 0,0	; entrance 1, crew 2
	DW	0,0, 0,0	; entrance 1, crew 3
	DW	0,0, 0,0	; entrance 2, crew 0
	DW	0,0, 0,0	; entrance 2, crew 1
	DW	0,0, 0,0	; entrance 2, crew 2
	DW	0,0, 0,0	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	139,172, 111,153, 179,166, 206,153	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	139,172, 111,153, 179,166, 206,153
; In the room file, so these start again each time the room loads
going_door	LABEL	BYTE
	DB	0
collapsed	LABEL	BYTE	; crew members down when the air ran out
	DB	0
N_s4epdo	LABEL	BYTE
	DB	's4epdo',0
N_s4eplo	LABEL	BYTE
	DB	's4eplo',0
N_s4epls	LABEL	BYTE
	DB	's4epls',0
N_kuseln	LABEL	BYTE
	DB	'kuseln',0
N_s4ephh	LABEL	BYTE
	DB	's4ephh',0
N_s4ephc	LABEL	BYTE
	DB	's4ephc',0
N_kgetdn	LABEL	BYTE
	DB	'kgetdn',0
N_sgetde	LABEL	BYTE
	DB	'sgetde',0
N_mgetds	LABEL	BYTE
	DB	'mgetds',0
N_rgetdw	LABEL	BYTE
	DB	'rgetdw',0
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_sscanw	LABEL	BYTE
	DB	'sscanw',0
N_sscane	LABEL	BYTE
	DB	'sscane',0
N_s4cbxp	LABEL	BYTE
	DB	's4cbxp',0

rdf_scripts:
; The room starts: the generator, failing or not. On the second visit,
; with no other trouble with Mudd, Mudd comes in (timer 1).
H_012E:
	SCRIPT	MSG_TICK, 1, 0, 0, H_01DE
StartRoom:
	jmp	SHORT L013F

N_MUD5LOOP	LABEL	BYTE
	DB	'MUD5LOOP',0
L013F:
	push	OFFSET N_MUD5LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUD5LOOP")
	add	sp, 4
	mov	byte ptr [si+RS_FALL+3], 2
	cmp	byte ptr [si+air_failing], 1
	jne	L017B
	push	13h
	push	RC_MUSIC
	SERVICE		; Music(19)
	add	sp, 4
	push	0
	push	0B0h
	push	54h
	push	OFFSET N_s4epls
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s4epls", 84, 176, 0)
	add	sp, 0Ch
	retf

L017B:
	push	0
	push	0B0h
	push	54h
	push	OFFSET N_s4eplo
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s4eplo", 84, 176, 0)
	add	sp, 0Ch
	inc	byte ptr [si+visits]
	cmp	byte ptr [si+visits], 2
	jne	L01DD
	cmp	byte ptr [si+mudd_incident], 0
	jne	L01DD
	cmp	byte ptr [si+generator_fixed], 0
	jne	L01DD
	mov	byte ptr [si+mudd_incident], 1
	mov	byte ptr [si+visits], 1
	mov	byte ptr [si+RS_BUSY], 2
	push	3
	push	RC_MUSIC
	SERVICE		; Music(3)
	add	sp, 4
	push	0
	push	0A7h
	push	0Eh
	push	OFFSET N_s4ephh
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s4ephh", 14, 167, 0)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+2], 70h
	mov	byte ptr [si+RS_FALL], 3
L01DD:
	retf

; Timer 1: Mudd asks for his doover and leaves...
H_01DE:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_0217
MuddWantsDoover:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD5_034
	call	Say
	mov	ax, OFFSET KirkOnDoover
	call	Talk
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD5_037
	call	Say
	push	0
	push	-1
	push	-1
	push	OFFSET N_s4ephc
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s4ephc", -1, -1, 0)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+4], 8Ch
	retf

; ...and timer 2: the life support generator fails (air_failing).
H_0217:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_0248
LifeSupportFails:
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr [si+air_failing], 1
	push	13h
	push	RC_MUSIC
	SERVICE		; Music(19)
	add	sp, 4
	push	0
	push	0B0h
	push	54h
	push	OFFSET N_s4epls
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s4epls", 84, 176, 0)
	add	sp, 0Ch
	retf

H_0248:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_02B6
CallEnterprise:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD5_003
	call	Say
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_STATICU1
	call	Say
	retf

T_MUD5_003	LABEL	BYTE
	DB	'#MUD5\MUD5_003#Kirk to Enterprise...',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
T_STATICU1	LABEL	BYTE
	DB	'#SFX\STATICU1#Ent... neu ... trans...',0

H_02B6:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_02E7
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
	mov	bx, OFFSET T_MUD5_022
	call	Say
	retf

; Tricorders and phasers.
H_02E7:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_0318
SpockScansEngine:
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
	mov	bx, OFFSET T_MUD5_011
	call	Say
	retf

H_0318:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_0349
SpockScansCrane:
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
	mov	bx, OFFSET T_MUD5_023
	call	Say
	retf

H_0349:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_0383
SpockScansHatch:
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
	mov	bx, OFFSET T_MUD5_024
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD5_001
	call	Say
	retf

H_0383:
	SCRIPT	MSG_USE, IT_STRICOR, 9, 0, H_03C4
SpockScansGenerator:
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
	cmp	byte ptr [si+air_failing], 0
	je	L03BA
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD5_019
	call	Say
	retf

L03BA:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD5_021
	call	Say
	retf

H_03C4:
	SCRIPT	MSG_USE, IT_PHASERS, 20h, 0, H_03E6
StunHatch:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD5_025
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD5_015
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD5_030
	call	Say
	retf

H_03E6:
	SCRIPT	MSG_USE, IT_PHASERK, 20h, 0, H_03FF
KillHatch:
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD5_039
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD5_027
	call	Say
	retf

; The doover on the failing generator: Kirk walks there (msg 2), works on
; it (anim msg 2): the air is safe again; timer 4: fixed, +2. Timer 3:
; Mudd looks in.
H_03FF:
	SCRIPT	MSG_USE, ANY, 9, 0, H_040F
UseOnGenerator:
	mov	ax, OFFSET S_0AE6
	mov	bx, OFFSET T_MUD5_014
	call	Say
	retf

H_040F:
	SCRIPT	MSG_USE, IT_DOOVER, 9, 0, H_0441
DooverOnGenerator:
	cmp	byte ptr [si+air_failing], 1
	jne	L0437
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 0
	push	2
	push	0B4h
	push	57h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 87, 180, 2)
	add	sp, 0Ah
	retf

L0437:
	mov	ax, OFFSET S_0AE6
	mov	bx, OFFSET T_MUD5_014
	call	Say
	retf

H_0441:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_0462
KirkAtGenerator:
	push	2
	push	-1
	push	-1
	push	OFFSET N_kuseln
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseln", -1, -1, 2)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+8], 14h
	retf

H_0462:
	SCRIPT	MSG_TIMER, 4, 0, 0, H_0492
GeneratorFixed:
	push	-1
	push	RC_MUSIC
	SERVICE		; Music(-1)
	add	sp, 4
	push	0
	push	-1
	push	-1
	push	OFFSET N_s4eplo
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s4eplo", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+generator_fixed], 1
	add	word ptr [si+score], 2
	retf

H_0492:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_04EE
Repaired:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD5_007
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD5_028
	call	Say
	mov	byte ptr [si+air_failing], 0
	mov	byte ptr [si+mudd_incident], 0
	push	3
	push	RC_MUSIC
	SERVICE		; Music(3)
	add	sp, 4
	push	0
	push	0A7h
	push	0Eh
	push	OFFSET N_s4ephh
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s4ephh", 14, 167, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 3
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	word ptr [si+RS_TIMERS+6], 6Eh
	retf

H_04EE:
	SCRIPT	MSG_TIMER, 3, 0, 0, H_0529
MuddReturns:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD5_035
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD5_005
	call	Say
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD5_036
	call	Say
	push	0
	push	-1
	push	-1
	push	OFFSET N_s4ephc
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s4ephc", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Common to all of the mission's rooms: the de-grimer on the lenses makes
; the alien device (+1); firing the device sets off an explosion at Kirk
; (anim msg 9), +5 the first time anywhere; the de-grimer on anything else
; just cleans it.
H_0529:
	SCRIPT	MSG_USE, IT_LENSES, IT_DEGRIME, 0, H_0557
CleanLenses:
	push	IT_LENSES
	push	RC_TAKEITEM
	push	IT_DEGRIME
	push	RC_TAKEITEM
	push	IT_ALIENDV
	push	RC_GIVEITEM
	mov	di, 3
L053E:
	SERVICE		; GiveItem(IT_ALIENDV); TakeItem(IT_DEGRIME); TakeItem(IT_LENSES)
	add	sp, 4
	dec	di
	jne	L053E
	add	word ptr [si+score], 1
	mov	ax, OFFSET S_0AE6
	mov	bx, OFFSET T_MUD5N009
	call	Say
	retf

H_0557:
	SCRIPT	MSG_USE, IT_ALIENDV, ANY, 0, H_05AA
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
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, "s4cbxp", ?, 10, 9)
	add	sp, 0Ch
	jmp	SHORT L059A

N_EXPLO3	LABEL	BYTE
	DB	'EXPLO3',0
L059A:
	push	OFFSET N_EXPLO3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EXPLO3")
	add	sp, 4
	retf

; The alien device has gone off here (anim msg 9): this one sets used_device
; without the +5.
H_05AA:
	SCRIPT	MSG_ANIM_DONE, 9, 0, 0, H_05C8
DeviceFired:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+used_device], 0
	jne	L05C7
	mov	byte ptr [si+used_device], 1
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD2_002
	call	Say
L05C7:
	retf

H_05C8:
	SCRIPT	MSG_USE, IT_DEGRIME, ANY, 0, H_05D8
UseDegrimer:
	mov	ax, OFFSET S_0AE6
	mov	bx, OFFSET T_MUD5N001
	call	Say
	retf

; Looking, and the door back to the cargo bay (room 0).
H_05D8:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_05FA
LookAtHatch:
	mov	ax, OFFSET S_0AE6
	mov	bx, OFFSET T_MUD5N011
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD5_031
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD5_009
	call	Say
	retf

H_05FA:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_0623
LookAtGenerator:
	cmp	byte ptr [si+air_failing], 0
	je	L0610
	mov	ax, OFFSET S_0AE6
	mov	bx, OFFSET T_MUD5N008
	call	Say
	retf

L0610:
	mov	ax, OFFSET S_0AE6
	mov	bx, OFFSET T_MUD5N012
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD5_026
	call	Say
	retf

H_0623:
	SCRIPT	MSG_REGION, 0, 0, 0, H_0662
ReachDoor:
	cmp	byte ptr cs:going_door, 1
	jne	L0661
	jmp	SHORT L063C

N_SMADOOR3	LABEL	BYTE
	DB	'SMADOOR3',0
L063C:
	push	OFFSET N_SMADOOR3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SMADOOR3")
	add	sp, 4
	push	0
	push	74h
	push	85h
	push	OFFSET N_s4epdo
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "s4epdo", 133, 116, 0)
	add	sp, 0Ch
L0661:
	retf

H_0662:
	SCRIPT	MSG_WALK, 22h, 0, 0, H_0686
WalkToDoor:
	mov	byte ptr cs:going_door, 1
	mov	byte ptr [si+RS_BUSY], 1
	push	0
	push	74h
	push	85h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 133, 116, 0)
	add	sp, 0Ah
	retf

; Every tick, common to all of the mission's rooms: while life support is
; failing, the air runs down from 6978h, with warnings at 4F1Ah, 34BCh
; and 1A5Eh; at 1 the crew collapse (walk msgs 9-12) and the game is
; over.
H_0686:
	SCRIPT	MSG_TICK, ANY, ANY, ANY, H_07CF
AirRunsOut:
	cmp	byte ptr [si+air_failing], 0
	je	L0700
	cmp	word ptr [si+air_countdown], 1
	je	L06A2
	mov	word ptr [si+air_countdown], 1
	mov	word ptr [si+air_left], 6978h
L06A2:
	dec	word ptr [si+air_left]
	cmp	word ptr [si+air_left], 1A5Eh
	je	L0715
	cmp	word ptr [si+air_left], 34BCh
	je	L070B
	cmp	word ptr [si+air_left], 4F1Ah
	je	L0701
	cmp	word ptr [si+air_left], 1
	jne	L0700
	mov	byte ptr [si+RS_BUSY], 1
	push	9
	push	0ACh
	push	8Bh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 139, 172, 9)
	add	sp, 0Ah
	push	0Ah
	push	99h
	push	6Fh
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 111, 153, 10)
	add	sp, 0Ah
	mov	ax, OFFSET S_0AE6
	mov	bx, OFFSET T_MUD5N105
	call	Say
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
L0700:
	retf

L0701:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_071F
	call	Say
	retf

L070B:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_0742
	call	Say
	retf

L0715:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_0765
	call	Say
	retf

S_071F	LABEL	BYTE
	DB	'Life support down to 75%, Captain.',0
S_0742	LABEL	BYTE
	DB	'Life support down to 50%, Captain.',0
S_0765	LABEL	BYTE
	DB	'Life support down to 25%, Captain.',0
T_MUD5N105	LABEL	BYTE
	DB	'#MUD5\MUD5N105#Life support fails completely and you fall uncons'
	DB	'cious.',0

H_07CF:
	SCRIPT	MSG_WALK_DONE, 9, 0, 0, H_0816
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
	jmp	SHORT L0833

H_0816:
	SCRIPT	MSG_WALK_DONE, 0Ah, 0, 0, H_08D4
SpockCollapses:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sgetde
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sgetde", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0833

L0833:
	inc	byte ptr cs:collapsed
	cmp	byte ptr cs:collapsed, 2
	jne	L0849
	mov	ax, OFFSET S_0AE6
	mov	bx, OFFSET T_MUD5N007
	call	Say
L0849:
	retf

T_MUD5N007	LABEL	BYTE
	DB	'#MUD5\MUD5N007#The atmosphere in the ship has dropped below the '
	DB	'level needed to sustain life. You drop to unconsciousness and sl'
	DB	'owly die.',0

H_08D4:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_08E3
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_MUD5N002
	call	Say
	retf

H_08E3:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_08F2
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_MUD5N005
	call	Say
	retf

H_08F2:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_0901
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_MUD5N004
	call	Say
	retf

H_0901:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_0910
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_MUD5N003
	call	Say
	retf

H_0910:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_091F
LookAtDoor:
	sub	ax, ax
	mov	bx, OFFSET T_MUD5N010
	call	Say
	retf

H_091F:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_092E
LookAtCrane:
	sub	ax, ax
	mov	bx, OFFSET T_MUD5N000
	call	Say
	retf

H_092E:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_093D
LookAtEngine:
	sub	ax, ax
	mov	bx, OFFSET T_MUD5N006
	call	Say
	retf

H_093D:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0956
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD5_002
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD5_032
	call	Say
	retf

H_0956:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_096F
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD5_033
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD5_016
	call	Say
	retf

H_096F:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0988
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD5_017
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD5_004
	call	Say
	retf

H_0988:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_09A1
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD5_040
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD5_018
	call	Say
	retf

H_09A1:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, Talk
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD5_012
	call	Say
	retf

T_MUD5_012	LABEL	BYTE
	DB	'#MUD5\MUD5_012#Everyone is healthy, Jim, there''s no need for the'
	DB	' medical kit here.',0
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
	DW	133,77, 156,119, 156,132, 109,132, 109,119
	DW	21h, 4	; id, points
	DW	77,74, 96,58, 96,120, 68,109
	DW	21h, 4	; id, points
	DW	222,24, 276,41, 276,162, 225,162
	DW	20h, 4	; id, points
	DW	0,108, 25,108, 25,174, 0,174
	DW	23h, 4	; id, points
	DW	185,0, 208,0, 208,84, 185,84
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	0, 4	; id, points
	DW	110,115, 153,115, 153,118, 110,118
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	109,119, 156,119, 156,132, 109,132
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
N_Harry_Mudd	LABEL	BYTE
	DB	'Harry Mudd',0
S_0AE6	LABEL	BYTE
	DB	0
T_MUD5_022	LABEL	BYTE
	DB	'#MUD5\MUD5_022#This room appears to have been the alien ship''s e'
	DB	'ngine pod. A ship-to-ship access hatch and a temporary life supp'
	DB	'ort generator are evidently recent additions.',0
T_MUD5_011	LABEL	BYTE
	DB	'#MUD5\MUD5_011#An unusual matter-anti-matter engine, reminiscent'
	DB	' of the designs created by the hoopooin of Seginus IV.',0
T_MUD5N011	LABEL	BYTE
	DB	'#MUD5\MUD5N011#A salvage lock hatch, a common type used to link '
	DB	'a derelict to the ship doing the salvaging.',0
T_MUD5_031	LABEL	BYTE
	DB	'#MUD5\MUD5_031#It appears that Harry Mudd managed to emplace thi'
	DB	's access hatch without significantly damaging the alien ship.',0
T_MUD5_009	LABEL	BYTE
	DB	'#MUD5\MUD5_009#Will wonders never cease.',0
T_MUD5_024	LABEL	BYTE
	DB	'#MUD5\MUD5_024#As one would expect, Mr. Mudd has sealed the hatc'
	DB	'h with his personal code. We cannot enter his ship, Captain.',0
T_MUD5_001	LABEL	BYTE
	DB	'#MUD5\MUD5_001#I suspect that''s a blessing in disguise, Mr. Spoc'
	DB	'k!',0
T_MUD5_025	LABEL	BYTE
	DB	'#MUD5\MUD5_025#Captain, the Gomuchi-Grindrod Salvage Hatch is de'
	DB	'signed to withstand low power phaser blasts.  However, I would n'
	DB	'ot trust the integrity of the ship''s hull were we to increase ph'
	DB	'aser power to open this hatch.',0
T_MUD5_015	LABEL	BYTE
	DB	'#MUD5\MUD5_015#Do you really think there''s anything on Mudd''s sh'
	DB	'ip we need, Captain?  I don''t.',0
T_MUD5_030	LABEL	BYTE
	DB	'#MUD5\MUD5_030#In this case, I agree with the good doctor.',0
T_MUD5_039	LABEL	BYTE
	DB	'#MUD5\MUD5_039#Captain, I don''t think we can open this hatch wit'
	DB	'h phasers, and still depend on the integrity of the ship''s hull '
	DB	'to hold atmosphere.',0
T_MUD5_027	LABEL	BYTE
	DB	'#MUD5\MUD5_027#I doubt there''s anything on Mudd''s ship we requir'
	DB	'e, Captain.',0
T_MUD5N008	LABEL	BYTE
	DB	'#MUD5\MUD5N008#There seems to be something wrong with the life s'
	DB	'upport generator.',0
T_MUD5N012	LABEL	BYTE
	DB	'#MUD5\MUD5N012#A "Sav-a-Ship" emergency life support generator, '
	DB	'generally used for temporary life support during evacuation of s'
	DB	'mall damaged ships.',0
T_MUD5_026	LABEL	BYTE
	DB	'#MUD5\MUD5_026#Evidently Mr. Mudd was unwilling to pay the price'
	DB	' for a reliable salvage model.',0
T_MUD5_014	LABEL	BYTE
	DB	'#MUD5\MUD5_014#This life support generator is an unreliable mode'
	DB	'l at the best of times.  Tinkering with it is a gamble with your'
	DB	' life!',0
T_MUD5_019	LABEL	BYTE
	DB	'#MUD5\MUD5_019#The life support generator is malfunctioning. Rep'
	DB	'airs must be made soon or the atmosphere will fall below the lev'
	DB	'el required to sustain us, Captain.',0
T_MUD5_021	LABEL	BYTE
	DB	'#MUD5\MUD5_021#This "Sav-a-Ship" life support generator has seen'
	DB	' a great deal of use.  It was never a reliable model, being pron'
	DB	'e to breakdown without warning.  It is, however, properly connec'
	DB	'ted, with warning alarms for temperature, atmosphere, and radiat'
	DB	'ion.',0
T_MUD5_007	LABEL	BYTE
	DB	'#MUD5\MUD5_007#That was a close one. Too close! If I ever get my'
	DB	' hands on that no good Mudd I''ll...',0
T_MUD5_028	LABEL	BYTE
	DB	'#MUD5\MUD5_028#I would not suggest we take the time to seek him.'
	DB	'This emergency could occur again. I would suggest we hasten our '
	DB	'departure.',0
	DB	'#MUD5\MUD5_020#The life support system must be repaired soon. Re'
	DB	'adings indicate the environment is dropping quickly.',0
	DB	'#MUD5\MUD5_013#Our lives won''t be worth a plugged nickel if we d'
	DB	'on''t get that makeshift life support generator back in working o'
	DB	'rder!',0
	DB	'#MUD5\MUD5_038#Captain, I''m not feeling well. Without life suppo'
	DB	'rt, we can''t remain here much longer.',0
T_MUD5_034	LABEL	BYTE
	DB	'#MUD5\MUD5_034#Captain, you wouldn''t have seen my Multipurpose D'
	DB	'oover anywhere? I need to, uh, fix something.',0
T_MUD5_006	LABEL	BYTE
	DB	'#MUD5\MUD5_006#No, Harry, but I figure it''s probably where you''l'
	DB	'l find your lost marbles.',0
T_MUD5_010	LABEL	BYTE
	DB	'#MUD5\MUD5_010#Yes, I''ve got it but you can''t have it.',0
T_MUD5_037	LABEL	BYTE
	DB	'#MUD5\MUD5_037#You really can be a headache, Captain. Maybe I ca'
	DB	'n find a spare somewhere else. Good lu...I mean goodbye.',0
T_MUD5_035	LABEL	BYTE
	DB	'#MUD5\MUD5_035#Oh! Was there a problem?',0
T_MUD5_005	LABEL	BYTE
	DB	'#MUD5\MUD5_005#Mudd! I oughta...',0
T_MUD5_036	LABEL	BYTE
	DB	'#MUD5\MUD5_036#Sorry, no time to chat. I''m a busy man you know.',0
T_MUD2_002	LABEL	BYTE
	DB	'#MUD2\MUD2_002#Well, now! I think we know why the Elasi pirates '
	DB	'were so interested in finding out where Mudd was getting these!',0
T_MUD5N009	LABEL	BYTE
	DB	'#MUD5\MUD5N009#These two things fit together like they were made'
	DB	' for each other.',0
T_MUD5N001	LABEL	BYTE
	DB	'#MUD5\MUD5N001#Dust and grease lifts off the surface, leaving th'
	DB	'is item clean as new.',0
T_MUD5N002	LABEL	BYTE
	DB	'#MUD5\MUD5N002#James T. Kirk. Exploring the unknown is one of th'
	DB	'e few pleasures that the burden of command allows him. ',0
T_MUD5N005	LABEL	BYTE
	DB	'#MUD5\MUD5N005#Spock continues to examine the equipment with a s'
	DB	'cientist''s eye. ',0
T_MUD5N004	LABEL	BYTE
	DB	'#MUD5\MUD5N004#McCoy glances back and forth, looking for a sign '
	DB	'of Harry Mudd. ',0
T_MUD5N003	LABEL	BYTE
	DB	'#MUD5\MUD5N003#Lieutenant Buchert watches and says nothing. He''s'
	DB	' the strong, silent type. ',0
T_MUD5_002	LABEL	BYTE
	DB	'#MUD5\MUD5_002#Just think of it, Spock. An advanced civilization'
	DB	', with powerful technology and nearly unlimited knowledge, and y'
	DB	'et all of that didn''t save them. ',0
T_MUD5_032	LABEL	BYTE
	DB	'#MUD5\MUD5_032#It is a sobering thought, Captain. ',0
T_MUD5_033	LABEL	BYTE
	DB	'#MUD5\MUD5_033#Unlike humans, I do not decrease my efficiency wi'
	DB	'th meaningless dialogue. ',0
T_MUD5_016	LABEL	BYTE
	DB	'#MUD5\MUD5_016#Spock! Meaningless conversation is one of life''s '
	DB	'great pleasures. ',0
T_MUD5_017	LABEL	BYTE
	DB	'#MUD5\MUD5_017#Well Jim, as long as we don''t strangle Harry Mudd'
	DB	', I can''t see very much for me to do on this mission. ',0
T_MUD5_004	LABEL	BYTE
	DB	'#MUD5\MUD5_004#Let''s hope there isn''t too much for you to do bac'
	DB	'k at the Enterprise. ',0
T_MUD5_040	LABEL	BYTE
	DB	'#MUD5\MUD5_040#When we get back to the Enterprise, you''re going '
	DB	'to have to tell me everything you know about this Mudd guy. ',0
T_MUD5_018	LABEL	BYTE
	DB	'#MUD5\MUD5_018#You know, lieutenant, they say if you can''t say a'
	DB	'nything good about a person, you shouldn''t say anything at all. '
	DB	'In that case, I''ve got a lot I shouldn''t say about Harry Mudd. ',0
T_MUD5N006	LABEL	BYTE
	DB	'#MUD5\MUD5N006#Tall, transparent columns run through the ceiling'
	DB	'. Energy crackles in between the duo-decahedrons inside them.',0
T_MUD5N000	LABEL	BYTE
	DB	'#MUD5\MUD5N000#A large claw-like device hangs from the ceiling.',0
T_MUD5_023	LABEL	BYTE
	DB	'#MUD5\MUD5_023#This seems to be a crane of some sort, Captain. C'
	DB	'urrently, no power is running to it.',0
T_MUD5N010	LABEL	BYTE
	DB	'#MUD5\MUD5N010#This door leads back to the main cargo bay.',0
KirkOnDoover	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_MUD5_006, OFFSET T_MUD5_010, 0	; speaker, choices, 0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
