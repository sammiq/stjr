; FEATHER5.RDF - "The Feathered Serpent", a muddy river crossed by a log,
; with a lit cave beyond. A carnivorous squid lurks under the log. A
; piece of the thorny plant, cut with Tlaoxac's knife (room 3) and thrown
; in the water, repels it; sending Stragey across first feeds him to it.
;
; Actors: 8 the creature, 10 (0Ah) the thrown plant.
; Objects: 8 the creature, 0Ah the lights, 20h the log, 21h the plant,
; 22h the log, 23h the river, 24h/25h insects, 26h the cave.
; Exits: 2 room 4, 3 room 6. Region 0: the log.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - KnifeOnKirk gives Kirk McCoy's line ("Jim! Are you out of your mind?").
; - The script chain runs on into code at 07DF: the engine reads its bytes
;   as key 50 6A 03 2E and next 1EFF (beyond rdf_scripts_end, so the search
;   stops).
; - Code at 0343 runs on into the script header at 0346.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
have_fern	EQU	RS_VARS+7	; Kirk has a piece of the plant
creature_gone	EQU	RS_VARS+0Bh	; the creature has left the log
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
	DW	3Ch
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
	DW	-1, -1, 4, 6	; room for each exit
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
	DW	287,130, 286,130	; entrance 2, crew 0
	DW	282,189, 281,189	; entrance 2, crew 1
	DW	305,156, 304,156	; entrance 2, crew 2
	DW	244,126, 243,126	; entrance 2, crew 3
	DW	70,100, 134,100	; entrance 3, crew 0
	DW	60,100, 109,100	; entrance 3, crew 1
	DW	50,100, 88,100	; entrance 3, crew 2
	DW	40,100, 66,100	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	286,130, 281,189, 305,156, 243,126
N_s5r5kf	LABEL	BYTE
	DB	's5r5kf',0
N_s5r5kt	LABEL	BYTE
	DB	's5r5kt',0
N_s5r5pt	LABEL	BYTE
	DB	's5r5pt',0
N_s5r5os	LABEL	BYTE
	DB	's5r5os',0
N_s5r5oh	LABEL	BYTE
	DB	's5r5oh',0
N_s5r5ol	LABEL	BYTE
	DB	's5r5ol',0
N_sscann	LABEL	BYTE
	DB	'sscann',0
N_sscanw	LABEL	BYTE
	DB	'sscanw',0
N_mscanw	LABEL	BYTE
	DB	'mscanw',0
N_feath5b	LABEL	BYTE
	DB	'feath5b',0

rdf_scripts:
; The room starts: the creature by the log, which can't be crossed.
H_0111:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0168
StartRoom:
	jmp	SHORT L0122

N_FEA5LOOP	LABEL	BYTE
	DB	'FEA5LOOP',0
L0122:
	push	OFFSET N_FEA5LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("FEA5LOOP")
	add	sp, 4
	push	1Dh
	push	RC_MUSIC
	SERVICE		; Music(29)
	add	sp, 4
	cmp	byte ptr [si+creature_gone], 0
	jne	L015A
	push	0
	push	0A4h
	push	4Eh
	push	OFFSET N_s5r5os
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s5r5os", 78, 164, 0)
	add	sp, 0Ch
	retf

L015A:
	push	OFFSET N_feath5b
	push	RC_LOADMAP
	SERVICE		; LoadMap("feath5b")
	add	sp, 4
	retf

; Region 0, the log: Spock and Stragey warn while the creature is there.
H_0168:
	SCRIPT	MSG_REGION, 0, 0, 0, H_018D
AtTheLog:
	cmp	byte ptr [si+creature_gone], 0
	jne	L018C
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA5_005
	call	Say
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L018C
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA5_033
	call	Say
L018C:
	retf

; The crew on the plant: it needs cutting.
H_018D:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_019D
SpockOnPlant:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA5_004
	call	Say
	retf

H_019D:
	SCRIPT	MSG_USE, OBJ_MCCOY, 21h, 0, H_01AD
McCoyOnPlant:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA5_009
	call	Say
	retf

H_01AD:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 21h, 0, H_01BD
StrageyOnPlant:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA5_035
	call	Say
	retf

; Stragey tries the log first (msg 8): the creature takes him (anim
; msg 9), and is gone.
H_01BD:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 20h, 0, H_01F7
StrageyCrosses:
	cmp	byte ptr [si+creature_gone], 0
	jne	L01F6
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA5_034
	call	Say
	mov	byte ptr [si+RS_BUSY], 1
	push	OFFSET N_feath5b
	push	RC_LOADMAP
	SERVICE		; LoadMap("feath5b")
	add	sp, 4
	push	8
	push	64h
	push	8Fh
	push	3
	push	RC_WALK
	SERVICE		; Walk(3, 143, 100, 8)
	add	sp, 0Ah
L01F6:
	retf

H_01F7:
	SCRIPT	MSG_WALK_DONE, 8, 0, 0, H_0258
StrageyOnLog:
	push	2
	push	RC_MUSIC
	SERVICE		; Music(2)
	add	sp, 4
	jmp	SHORT L0214

N_TENTICL2	LABEL	BYTE
	DB	'TENTICL2',0
L0214:
	push	OFFSET N_TENTICL2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("TENTICL2")
	add	sp, 4
	push	0
	push	0A4h
	push	4Eh
	push	OFFSET N_s5r5oh
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s5r5oh", 78, 164, 0)
	add	sp, 0Ch
	push	9
	push	64h
	push	8Fh
	push	OFFSET N_s5r5ol
	push	3
	push	RC_ANIM0
	SERVICE		; Anim0(3, "s5r5ol", 143, 100, 9)
	add	sp, 0Ch
	mov	byte ptr [si+creature_gone], 1
	mov	byte ptr [si+RS_REDSHIRT_DEAD], 1
	retf

H_0258:
	SCRIPT	MSG_ANIM_DONE, 9, 0, 0, H_026F
StrageyEaten:
	push	3
	push	RC_STOPANIM
	SERVICE		; StopAnim(3)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_026F:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_0285
SpockCrosses:
	cmp	byte ptr [si+creature_gone], 0
	jne	L0284
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA5_002
	call	Say
L0284:
	retf

H_0285:
	SCRIPT	MSG_USE, OBJ_MCCOY, 20h, 0, H_029B
McCoyCrosses:
	cmp	byte ptr [si+creature_gone], 0
	jne	L029A
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA5_015
	call	Say
L029A:
	retf

; The snake and the knife on people and things.
H_029B:
	SCRIPT	MSG_USE, IT_SNAKE, OBJ_KIRK, 0, H_02AB
SnakeOnKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_FEA5N010
	call	Say
	retf

H_02AB:
	SCRIPT	MSG_USE, IT_SNAKE, OBJ_SPOCK, 0, H_02BB
SnakeOnSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA5_032
	call	Say
	retf

H_02BB:
	SCRIPT	MSG_USE, IT_SNAKE, OBJ_MCCOY, 0, H_02CB
SnakeOnMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA5_020
	call	Say
	retf

H_02CB:
	SCRIPT	MSG_USE, IT_SNAKE, OBJ_REDSHIRT, 0, H_02DB
SnakeOnStragey:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA5_040
	call	Say
	retf

H_02DB:
	SCRIPT	MSG_USE, IT_SNAKE, 23h, 0, H_02F7
SnakeInRiver:
	mov	ax, OFFSET S_097C
	mov	bx, OFFSET T_FEA5N011
	call	Say
	push	IT_SNAKE
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_SNAKE)
	add	sp, 4
	retf

H_02F7:
	SCRIPT	MSG_USE, IT_KNIFE, OBJ_KIRK, 0, H_0307
KnifeOnKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM0_020
	call	Say
	retf

H_0307:
	SCRIPT	MSG_USE, IT_KNIFE, OBJ_SPOCK, 0, H_0317
KnifeOnSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA5_029
	call	Say
	retf

H_0317:
	SCRIPT	MSG_USE, IT_KNIFE, OBJ_MCCOY, 0, H_0327
KnifeOnMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA5_008
	call	Say
	retf

H_0327:
	SCRIPT	MSG_USE, IT_KNIFE, OBJ_REDSHIRT, 0, H_0337
KnifeOnStragey:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA5_039
	call	Say
	retf

H_0337:
	SCRIPT	MSG_USE, IT_KNIFE, 23h, 0, H_0346
KnifeInRiver:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA5_018
	call	Say
				; NOTE: runs on into the next script's header, executing its six bytes as code

H_0346:
	SCRIPT	MSG_USE, IT_KNIFE, 8, 0, H_0356
KnifeOnCreature:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA5_006
	call	Say
	retf

; The plant: cut with the knife (msgs 1); a piece thrown in the river
; (+2, msgs 2, 3) drives the creature away.
H_0356:
	SCRIPT	MSG_GET, 21h, 0, 0, H_0366
GetPlant:
	mov	ax, OFFSET S_097C
	mov	bx, OFFSET T_FEA5N008
	call	Say
	retf

H_0366:
	SCRIPT	MSG_USE, IT_KNIFE, 21h, 0, H_0395
CutPlant:
	cmp	byte ptr [si+have_fern], 1
	jne	L037C
	mov	ax, OFFSET S_097C
	mov	bx, OFFSET T_FEA5N015
	call	Say
	retf

L037C:
	push	1
	push	8Ah
	push	106h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 262, 138, 1)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

H_0395:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_03B1
KirkAtPlant:
	push	1
	push	-1
	push	-1
	push	OFFSET N_s5r5kf
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r5kf", -1, -1, 1)
	add	sp, 0Ch
	retf

H_03B1:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_03D8
GotFern:
	mov	byte ptr [si+RS_BUSY], 0
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	push	IT_FERN
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_FERN)
	add	sp, 4
	mov	byte ptr [si+have_fern], 1
	retf

H_03D8:
	SCRIPT	MSG_USE, IT_FERN, 8, 0, H_03E0
	jmp	SHORT FernInRiver

H_03E0:
	SCRIPT	MSG_USE, IT_FERN, 23h, 0, H_0403
FernInRiver:
	add	word ptr [si+score], 2
	push	2
	push	8Ah
	push	106h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 262, 138, 2)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

H_0403:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_0435
KirkThrowsFern:
	push	2
	push	-1
	push	-1
	push	OFFSET N_s5r5kt
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r5kt", -1, -1, 2)
	add	sp, 0Ch
	push	3
	push	52h
	push	0E6h
	push	OFFSET N_s5r5pt
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s5r5pt", 230, 82, 3)
	add	sp, 0Ch
	retf

H_0435:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_045C
FernThrown:
	mov	byte ptr [si+RS_BUSY], 0
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	push	IT_FERN
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_FERN)
	add	sp, 4
	mov	byte ptr [si+have_fern], 0
	retf

H_045C:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_048B
CreatureLeaves:
	cmp	byte ptr [si+creature_gone], 0
	jne	L048A
	mov	byte ptr [si+creature_gone], 1
	mov	word ptr [si+RS_TIMERS+2], 14h
	push	8
	push	RC_STOPANIM
	SERVICE		; StopAnim(8)
	add	sp, 4
	push	OFFSET N_feath5b
	push	RC_LOADMAP
	SERVICE		; LoadMap("feath5b")
	add	sp, 4
L048A:
	retf

H_048B:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_049B
SpockOnPlantSap:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA5_025
	call	Say
	retf

; Rocks, and the crew on the lights and the creature.
H_049B:
	SCRIPT	MSG_USE, IT_ROCK, OBJ_SPOCK, 0, H_04AB
RockAtSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA5_027
	call	Say
	retf

H_04AB:
	SCRIPT	MSG_USE, IT_ROCK, OBJ_MCCOY, 0, H_04BB
RockAtMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA5_019
	call	Say
	retf

H_04BB:
	SCRIPT	MSG_USE, IT_ROCK, OBJ_REDSHIRT, 0, H_04CB
RockAtStragey:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA5_038
	call	Say
	retf

H_04CB:
	SCRIPT	MSG_USE, OBJ_SPOCK, 0Ah, 0, H_04D3
SpockOnLight:
	jmp	SHORT L04E3

H_04D3:
	SCRIPT	MSG_USE, OBJ_MCCOY, 0Ah, 0, H_04DB
McCoyOnLight:
	jmp	SHORT L04E3

H_04DB:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 0Ah, 0, H_04ED
StrageyOnLight:
	jmp	SHORT L04E3

L04E3:
	mov	ax, OFFSET S_097C
	mov	bx, OFFSET T_FEA5N003
	call	Say
	retf

H_04ED:
	SCRIPT	MSG_USE, OBJ_SPOCK, 8, 0, H_04FD
SpockOnCreature:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA5_003
	call	Say
	retf

H_04FD:
	SCRIPT	MSG_USE, OBJ_MCCOY, 8, 0, H_050D
McCoyOnCreature:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA5_016
	call	Say
	retf

H_050D:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 8, 0, H_051D
StrageyOnCreature:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA5_037
	call	Say
	retf

H_051D:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_052D
StunAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA5_028
	call	Say
	retf

H_052D:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_053D
KillAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA5_028
	call	Say
	retf

; Looking and talking.
H_053D:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_054C
LookAtScene:
	sub	ax, ax
	mov	bx, OFFSET T_FEA5N012
	call	Say
	retf

H_054C:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_055B
LookAtLog:
	sub	ax, ax
	mov	bx, OFFSET T_FEA5N007
	call	Say
	retf

H_055B:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_056A
LookAtRiver:
	sub	ax, ax
	mov	bx, OFFSET T_FEA5N009
	call	Say
	retf

H_056A:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_0579
LookAtPlant:
	sub	ax, ax
	mov	bx, OFFSET T_FEA5N014
	call	Say
	retf

H_0579:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_0588
LookAtInsects1:
	sub	ax, ax
	mov	bx, OFFSET T_FEA5N005
	call	Say
	retf

H_0588:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_0597
LookAtInsects2:
	sub	ax, ax
	mov	bx, OFFSET T_FEA5N005
	call	Say
	retf

H_0597:
	SCRIPT	MSG_LOOK, 26h, 0, 0, H_05A6
LookAtCave:
	sub	ax, ax
	mov	bx, OFFSET T_FEA5N013
	call	Say
	retf

H_05A6:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_05B5
LookAtCreature:
	sub	ax, ax
	mov	bx, OFFSET T_FEA5N000
	call	Say
	retf

H_05B5:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_05C4
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_FEA5N006
	call	Say
	retf

H_05C4:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_05DA
LookAtKirk:
	cmp	byte ptr [si+creature_gone], 0
	jne	L05D9
	mov	ax, 0
	mov	bx, OFFSET T_FEA5N001
	call	Say
L05D9:
	retf

H_05DA:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_05F0
LookAtMcCoy:
	cmp	byte ptr [si+creature_gone], 0
	jne	L05EF
	mov	ax, 0
	mov	bx, OFFSET T_FEA5N002
	call	Say
L05EF:
	retf

H_05F0:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_0606
LookAtRedshirt:
	cmp	byte ptr [si+creature_gone], 0
	jne	L0605
	mov	ax, 0
	mov	bx, OFFSET T_FEA5N004
	call	Say
L0605:
	retf

H_0606:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0616
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA5_007
	call	Say
	retf

H_0616:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0626
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA5_022
	call	Say
	retf

H_0626:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0636
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA5_036
	call	Say
	retf

; Tricorders.
H_0636:
	SCRIPT	MSG_USE, IT_MTRICOR, 23h, 0, H_0677
McCoyScansRiver:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscanw
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscanw", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	cmp	byte ptr [si+creature_gone], 0
	jne	L066D
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA5_014
	call	Say
	retf

L066D:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA5_011
	call	Say
	retf

H_0677:
	SCRIPT	MSG_USE, IT_MTRICOR, 8, 0, H_06A8
McCoyScansCreature:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscanw
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscanw", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA5_013
	call	Say
	retf

H_06A8:
	SCRIPT	MSG_USE, IT_STRICOR, 8, 0, H_06D9
SpockScansCreature:
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
	mov	bx, OFFSET T_FEA5_024
	call	Say
	retf

H_06D9:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_070A
SpockScans:
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
	mov	bx, OFFSET T_FEA5_026
	call	Say
	retf

H_070A:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_074B
SpockScansRiver:
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
	cmp	byte ptr [si+creature_gone], 0
	jne	L0741
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA5_030
	call	Say
	retf

L0741:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA5_031
	call	Say
	retf

H_074B:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_077C
SpockScansPlant:
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
	mov	bx, OFFSET T_FEA5_023
	call	Say
	retf

H_077C:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, Talk
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA5_010
	call	Say
	retf

T_FEA5_010	LABEL	BYTE
	DB	'#FEA5\FEA5_010#Everyone is healthy, Jim, there''s no need for the'
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
	DW	20h, 4	; id, points
	DW	0,87, 174,87, 174,103, 0,103
	DW	21h, 4	; id, points
	DW	235,120, 262,120, 262,138, 235,138
	DW	22h, 4	; id, points
	DW	57,96, 259,96, 259,130, 57,130
	DW	22h, 4	; id, points
	DW	173,87, 205,87, 205,95, 173,95
	DW	22h, 4	; id, points
	DW	206,74, 270,74, 270,95, 206,95
	DW	23h, 4	; id, points
	DW	111,60, 205,60, 205,87, 111,87
	DW	23h, 4	; id, points
	DW	128,88, 172,88, 172,95, 128,95
	DW	23h, 4	; id, points
	DW	81,131, 267,131, 267,199, 81,199
	DW	23h, 4	; id, points
	DW	32,162, 80,162, 80,199, 32,199
	DW	24h, 4	; id, points
	DW	267,81, 317,81, 317,196, 267,196
	DW	25h, 4	; id, points
	DW	32,118, 58,118, 58,190, 32,190
	DW	26h, 4	; id, points
	DW	0,57, 22,57, 22,80, 0,80
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	2, 4	; id, points
	DW	305,115, 319,115, 319,199, 305,199
	DW	3, 4	; id, points
	DW	0,78, 20,78, 20,110, 0,110
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	175,87, 207,87, 207,103, 175,103
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's5r5l1',0
	DB	's5r5l2',0
	DB	's5r5l3',0
	DB	's5r5l4',0
	DB	's5r5l5',0
	DB	's5r5l6',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Stragey	LABEL	BYTE
	DB	'Lt. Stragey',0
S_097C	LABEL	BYTE
	DB	0
T_FEA5N015	LABEL	BYTE
	DB	'#FEA5\FEA5N015#You already have a piece of the plant.',0
T_FEA5N008	LABEL	BYTE
	DB	'#FEA5\FEA5N008#The plant is tough. You will need something sharp'
	DB	' to cut it.',0
T_FEA5N005	LABEL	BYTE
	DB	'#FEA5\FEA5N005#Luminescent insects swarm near a large tree.',0
T_FEA5_005	LABEL	BYTE
	DB	'#FEA5\FEA5_005#Captain, it would not be wise to cross while the '
	DB	'creature is near.',0
T_FEA5_002	LABEL	BYTE
	DB	'#FEA5\FEA5_002#Captain, I believe it would be suicide to try cro'
	DB	'ssing the log while the creature is near.',0
T_FEA5_015	LABEL	BYTE
	DB	'#FEA5\FEA5_015#Jim, that''s ludicrous!',0
T_FEA5_034	LABEL	BYTE
	DB	'#FEA5\FEA5_034#I''ll give it a try, Captain.',0
T_FEA5N010	LABEL	BYTE
	DB	'#FEA5\FEA5N010#The snake bites you.',0
T_FEA5_032	LABEL	BYTE
	DB	'#FEA5\FEA5_032#Was there a reason for that, Captain?',0
T_FEA5_020	LABEL	BYTE
	DB	'#FEA5\FEA5_020#You weren''t a snake handler in a previous life we'
	DB	're you? I don''t like snakes.',0
T_FEA5_040	LABEL	BYTE
	DB	'#FEA5\FEA5_040#You''re weird, sir.',0
T_FEA5N011	LABEL	BYTE
	DB	'#FEA5\FEA5N011#The snake disapears beneath the surface of the wa'
	DB	'ter.',0
T_FEA5_018	LABEL	BYTE
	DB	'#FEA5\FEA5_018#Jim, with our phaser not working, we may need tha'
	DB	't knife to protect ourselves!',0
T_DEM0_020	LABEL	BYTE
	DB	'#DEM0\DEM0_020#Jim! Are you out of your mind?',0
T_FEA5_029	LABEL	BYTE
	DB	'#FEA5\FEA5_029#Thank you Captain, but Vulcans do not use knives.',0
T_FEA5_008	LABEL	BYTE
	DB	'#FEA5\FEA5_008#Captain, I''ll declare you unfit to command if you'
	DB	' keep this up!',0
T_FEA5_039	LABEL	BYTE
	DB	'#FEA5\FEA5_039#Thanks Captain, but I can take care of myself. I '
	DB	'finished second in my weight class in wrestling at the Academy. '
	DB	'You keep the knife.',0
T_FEA5_006	LABEL	BYTE
	DB	'#FEA5\FEA5_006#Due to the small size of the knife, I doubt it wo'
	DB	'uld harm such a large creature.',0
T_FEA5_025	LABEL	BYTE
	DB	'#FEA5\FEA5_025#It would appear that the plant secretes a chemica'
	DB	'l that is a natural repellent to the creature. It has retreated '
	DB	'far down stream, Captain.',0
	DB	'#FEA5\FEA5_021#Good throw, Captain. However, I think the creatur'
	DB	'e was merely startled. It may return in a little while.',0
T_FEA5_027	LABEL	BYTE
	DB	'#FEA5\FEA5_027#Please stop that Captain. I have enough distracti'
	DB	'ons from Dr. McCoy.',0
T_FEA5_019	LABEL	BYTE
	DB	'#FEA5\FEA5_019#This planet is starting to get to me. I''m sure so'
	DB	'mething just hit me.',0
T_FEA5_038	LABEL	BYTE
	DB	'#FEA5\FEA5_038#Sir, you dropped your rock.',0
T_FEA5N003	LABEL	BYTE
	DB	'#FEA5\FEA5N003#He will not do that.',0
T_FEA5_003	LABEL	BYTE
	DB	'#FEA5\FEA5_003#Captain, I do not believe that my service to Star'
	DB	'fleet includes, as humans say, ''throwing my life away''.',0
T_FEA5_016	LABEL	BYTE
	DB	'#FEA5\FEA5_016#Jim, we''ve been friends a long time, but... I mea'
	DB	'n... you''re not serious?',0
T_FEA5_037	LABEL	BYTE
	DB	'#FEA5\FEA5_037#Sir, I finished second in my weight class in wres'
	DB	'tling at the Academy, but I don''t think that thing''s in my weigh'
	DB	't class.',0
T_FEA5N007	LABEL	BYTE
	DB	'#FEA5\FEA5N007#The log looks quite old but sturdy.',0
T_FEA5N009	LABEL	BYTE
	DB	'#FEA5\FEA5N009#The river water is too muddy to get an idea of it'
	DB	's depth or what may be beneath the surface.',0
T_FEA5N012	LABEL	BYTE
	DB	'#FEA5\FEA5N012#There is a slow muddy river blocking your path. A'
	DB	' strong thick log serves as a footbridge. The river is unmoving,'
	DB	' and the heat and stillness are oppressive.',0
T_FEA5N014	LABEL	BYTE
	DB	'#FEA5\FEA5N014#This plant has a rather thick stem and  prickly l'
	DB	'eaves.',0
T_FEA5N000	LABEL	BYTE
	DB	'#FEA5\FEA5N000#A pair of eyes are all that you can see of the re'
	DB	'st of this creature. Most of it is hidden beneath the murky wate'
	DB	'r.',0
T_FEA5N013	LABEL	BYTE
	DB	'#FEA5\FEA5N013#There seems to be a lit cave beyond the log.',0
T_FEA5N001	LABEL	BYTE
	DB	'#FEA5\FEA5N001#Captain Kirk is looking at the big creature in th'
	DB	'e water.',0
T_FEA5N006	LABEL	BYTE
	DB	'#FEA5\FEA5N006#Mr. Spock is looking ahead to a cave opening on t'
	DB	'he other side of the log.',0
T_FEA5N002	LABEL	BYTE
	DB	'#FEA5\FEA5N002#Dr. McCoy is looking at the big creature in the w'
	DB	'ater.',0
T_FEA5N004	LABEL	BYTE
	DB	'#FEA5\FEA5N004#Lt. Stragey is looking at the big creature in the'
	DB	' water.',0
T_FEA5_022	LABEL	BYTE
	DB	'#FEA5\FEA5_022#I recommend caution here, Captain.',0
T_FEA5_007	LABEL	BYTE
	DB	'#FEA5\FEA5_007#Anyone for a campfire?',0
T_FEA5_036	LABEL	BYTE
	DB	'#FEA5\FEA5_036#Reminds me of a planet I was stationed on once. T'
	DB	'he native girls were real friendly. Ensign Shou had his bachelor'
	DB	' party there, great time. You ever been to Omicron Draconis, Cap'
	DB	'tain?',0
T_FEA5_004	LABEL	BYTE
	DB	'#FEA5\FEA5_004#Captain, I would recommend using something to cut'
	DB	' the plant. There are numerous small thorns along the stem.',0
T_FEA5_009	LABEL	BYTE
	DB	'#FEA5\FEA5_009#Damn! That''s gonna hurt Jim. Take a look at those'
	DB	' thorns.You might try cutting that with something.',0
T_FEA5_035	LABEL	BYTE
	DB	'#FEA5\FEA5_035#It looks like that plant fights back sir. You mig'
	DB	'ht want to use something to cut it loose.',0
T_FEA5_014	LABEL	BYTE
	DB	'#FEA5\FEA5_014#Jim! There''s some kind of an aquatic creature dow'
	DB	'n there.',0
T_FEA5_011	LABEL	BYTE
	DB	'#FEA5\FEA5_011#I''m not reading that creature anymore, Jim.',0
T_FEA5_013	LABEL	BYTE
	DB	'#FEA5\FEA5_013#It''s some kind of squid, and it doesn''t look very'
	DB	' friendly.',0
T_FEA5_026	LABEL	BYTE
	DB	'#FEA5\FEA5_026#Nothing unusual here, Captain.',0
T_FEA5_030	LABEL	BYTE
	DB	'#FEA5\FEA5_030#The tricorder registers a lifeform, a large marin'
	DB	'e creature, lurking just below the surface of the water.',0
T_FEA5_031	LABEL	BYTE
	DB	'#FEA5\FEA5_031#The tricorder shows nothing unusual, Captain. The'
	DB	' creature is still down stream.',0
T_FEA5_024	LABEL	BYTE
	DB	'#FEA5\FEA5_024#It is some kind of mollusk; the river seems to be'
	DB	' its home, and it is carnivorous, eating land and river based fo'
	DB	'rms of life.',0
T_FEA5_023	LABEL	BYTE
	DB	'#FEA5\FEA5_023#It appears that the leaves are slightly toxic. I '
	DB	'would not recommend touching it for an extended amount of time, '
	DB	'Captain.',0
T_FEA5_033	LABEL	BYTE
	DB	'#FEA5\FEA5_033#Captain, perhaps I should try to cross first.',0
	DB	'#FEA5\FEA5_028#Still inoperative, Captain.',0
T_FEA5_028	LABEL	BYTE
	DB	'#FEA5\FEA5_028#Still inoperative, Captain.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
