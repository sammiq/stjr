; DEMON0.RDF - "Demon World", the colony on Pollux V where the landing
; party beams down. Prelate Angiven walks out to meet them; the doors of
; the two buildings open when the crew walks to them.
;
; Actors: 8 Prelate Angiven, 9 the right door, 10 (0Ah) the left door.
; Objects: 20h the buildings, 21h/22h the trees, 23h the snow, 24h the
; bushes, 25h the sign, 26h/27h the ground in front of the left/right door.
; Regions 0/1: the doorsteps. Exit 0: the path to the mountain.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 0838: the engine reads its bytes
;   as key 50 B8 03 00 and next 2E50 (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
was_rude	EQU	RS_VARS+0	; word: lost points for doubting the Prelate
met_prelate	EQU	RS_VARS+0Ah	; talked to the Prelate
prelate_greeted	EQU	RS_VARS+0Ch	; he has said hello
asked_witnesses	EQU	RS_VARS+0Dh	; asked to see the witnesses
flora_said	EQU	RS_VARS+0Fh	; McCoy has remarked on the plants
came_from	EQU	RS_VARS+11h	; 1: from the colony, 2: from the mine; which way the crew face
score	EQU	RS_VARS+2Fh	; word: the mission's score

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0BFh	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	6Eh
rdf_scale_min	LABEL	BYTE
	DW	32h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	1, 5, 6, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	60,114, 86,158	; entrance 0, crew 0
	DW	60,114, 66,153	; entrance 0, crew 1
	DW	60,114, 106,147	; entrance 0, crew 2
	DW	60,114, 80,140	; entrance 0, crew 3
	DW	250,162, 99,172	; entrance 1, crew 0
	DW	250,162, 128,171	; entrance 1, crew 1
	DW	250,162, 146,176	; entrance 1, crew 2
	DW	250,162, 177,170	; entrance 1, crew 3
	DW	157,134, 78,155	; entrance 2, crew 0
	DW	157,134, 64,146	; entrance 2, crew 1
	DW	157,134, 98,155	; entrance 2, crew 2
	DW	157,134, 86,139	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	86,158, 66,153, 106,147, 80,140	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0
; In the room file, so these start at 0 each time the room loads
right_door_steps	LABEL	BYTE
	DB	0
left_door_steps	LABEL	BYTE
	DB	0
going_left_door	LABEL	BYTE
	DB	0
going_right_door	LABEL	BYTE
	DB	0
N_prelclap	LABEL	BYTE
	DB	'prelclap',0
N_prel	LABEL	BYTE
	DB	'prel',0
N_s0r0d1	LABEL	BYTE
	DB	's0r0d1',0
N_s0r0d3	LABEL	BYTE
	DB	's0r0d3',0
N_s0r0d2	LABEL	BYTE
	DB	's0r0d2',0
N_s0r0d4	LABEL	BYTE
	DB	's0r0d4',0
	DB	'skille',0
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_mscans	LABEL	BYTE
	DB	'mscans',0

rdf_scripts:
; The room starts: wind, and the closed doors.
H_010D:
	SCRIPT	MSG_TICK, 1, 0, 0, H_015C
StartRoom:
	jmp	SHORT L011E

N_DEM0LOOP	LABEL	BYTE
	DB	'DEM0LOOP',0
L011E:
	push	OFFSET N_DEM0LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("DEM0LOOP")
	add	sp, 4
	push	0
	push	99h
	push	0FCh
	push	OFFSET N_s0r0d3
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s0r0d3", 252, 153, 0)
	add	sp, 0Ch
	push	0
	push	82h
	push	9Eh
	push	OFFSET N_s0r0d4
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "s0r0d4", 158, 130, 0)
	add	sp, 0Ch
	retf

; The Prelate walks out to meet the landing party...
H_015C:
	SCRIPT	MSG_TICK, 2, 0, 0, H_017F
PrelateEnters:
	cmp	byte ptr [si+met_prelate], 1
	je	L017E
	push	0
	push	0BEh
	push	78h
	push	OFFSET N_prel
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "prel", 120, 190, 0)
	add	sp, 0Ch
L017E:
	retf

; ...claps his hands...
H_017F:
	SCRIPT	MSG_TICK, 3Ch, 0, 0, H_01A2
PrelateClaps:
	cmp	byte ptr [si+met_prelate], 1
	je	L01A1
	push	0
	push	0BEh
	push	78h
	push	OFFSET N_prelclap
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "prelclap", 120, 190, 0)
	add	sp, 0Ch
L01A1:
	retf

; ...and welcomes them, once.
H_01A2:
	SCRIPT	MSG_TICK, 64h, 0, 0, H_01BF
PrelateGreets:
	cmp	byte ptr [si+met_prelate], 1
	je	L01BE
	cmp	byte ptr [si+prelate_greeted], 1
	je	L01BE
	mov	byte ptr [si+prelate_greeted], 1
	mov	ax, OFFSET PrelateHello
	call	Talk
L01BE:
	retf

; McCoy admires the plants, once.
H_01BF:
	SCRIPT	MSG_TICK, 8Ch, 0, 0, H_025A
McCoyFlora:
	cmp	byte ptr [si+flora_said], 1
	jne	L01CE
	JMPN	L0259

L01CE:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM0_016
	call	Say
	jmp	SHORT L0255

T_DEM0_016	LABEL	BYTE
	DB	'#DEM0\DEM0_016#Captain, the flora on this planet is very interes'
	DB	'ting. I wonder how useful it may be for medicinal purposes.',0
L0255:
	mov	byte ptr [si+flora_said], 1
L0259:
	retf

; Leaving by the path to the mountain. RS_MORE: the engine goes on to
; its default (load exit_room[0]).
H_025A:
	SCRIPT	MSG_EXIT, 0, 0, 0, H_0269
LeaveRoom:
	mov	byte ptr [si+came_from], 1
	mov	byte ptr [si+RS_MORE], 1
	retf

; Walking to the right door (or clicking it): Kirk walks to its step
; (msg 1 when he arrives), to stop facing east (RS_FALL, 2 = 'e').
H_0269:
	SCRIPT	MSG_WALK, 27h, 0, 0, H_0271
	jmp	SHORT WalkToRightDoor

H_0271:
	SCRIPT	MSG_WALK, 9, 0, 0, H_029A
WalkToRightDoor:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr cs:going_right_door, 1
	mov	byte ptr [si+RS_FALL], 2
	push	1
	push	9Eh
	push	0F3h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 243, 158, 1)
	add	sp, 0Ah
	retf

; Region 1, the right doorstep: if Kirk is on his way in, the door
; opens (msg 1 when done).
H_029A:
	SCRIPT	MSG_REGION, 1, 0, 0, H_02CC
ReachRightDoor:
	cmp	byte ptr cs:going_right_door, 1
	jne	L02CB
	push	1
	push	99h
	push	0FEh
	push	OFFSET N_s0r0d1
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s0r0d1", 254, 153, 1)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
L02CB:
	retf

; Kirk has arrived (walk msg 1) or the door has opened (anim msg 1):
; when both have happened, go through to room 5.
H_02CC:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_02D4
	jmp	SHORT EnterRightDoor

H_02D4:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_02F7
EnterRightDoor:
	inc	byte ptr cs:right_door_steps
	cmp	byte ptr cs:right_door_steps, 2
	je	L02E8
	retf

L02E8:
	push	0
	push	5
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(5, 0)
	add	sp, 6
	retf

; The same for the left door, msg 2, into room 6 by entrance 3.
H_02F7:
	SCRIPT	MSG_WALK, 26h, 0, 0, H_02FF
	jmp	SHORT WalkToLeftDoor

H_02FF:
	SCRIPT	MSG_WALK, 0Ah, 0, 0, H_0328
WalkToLeftDoor:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr cs:going_left_door, 1
	mov	byte ptr [si+RS_FALL], 2
	push	2
	push	86h
	push	9Dh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 157, 134, 2)
	add	sp, 0Ah
	retf

H_0328:
	SCRIPT	MSG_REGION, 0, 0, 0, H_035A
ReachLeftDoor:
	cmp	byte ptr cs:going_left_door, 1
	jne	L0359
	push	2
	push	82h
	push	9Eh
	push	OFFSET N_s0r0d2
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s0r0d2", 158, 130, 2)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
L0359:
	retf

H_035A:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_0362
	jmp	SHORT EnterLeftDoor

H_0362:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_0385
EnterLeftDoor:
	inc	byte ptr cs:left_door_steps
	cmp	byte ptr cs:left_door_steps, 2
	je	L0376
	retf

L0376:
	push	3
	push	6
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(6, 3)
	add	sp, 6
	retf

; Talking to the Prelate, once: +3 to the score, then a conversation in
; which each sceptical answer costs points (RudeToPrelate, once).
H_0385:
	SCRIPT	MSG_TALK, 8, 0, 0, H_03F9
TalkToPrelate:
	cmp	byte ptr [si+met_prelate], 0
	je	L0394
	jmp	SHORT L0393

L0393:
	retf

L0394:
	add	word ptr [si+score], 3
	mov	byte ptr [si+met_prelate], 1
	mov	ax, OFFSET KirkIntroduces
	call	Talk			; returns the choice, 0 to 2
	AX8	cmp, 0
	jne	NotTellMore
	mov	ax, OFFSET PrelateOnDemons
	jmp	SHORT PrelateAnswers

NotTellMore:
	AX8	cmp, 1
	jne	Skeptic
	mov	ax, OFFSET PrelateOnGates
	jmp	SHORT PrelateAnswers

Skeptic:
	call	RudeToPrelate
	jmp	SHORT AskEvidence

PrelateAnswers:
	call	Talk
AskEvidence:
	mov	ax, OFFSET KirkAsksEvidence
	call	Talk
	or	ax, ax
	je	Skeptics
	call	RudeToPrelate
Skeptics:
	mov	ax, OFFSET PrelateOnSkeptics
	call	Talk
	mov	ax, OFFSET KirkAsksMine
	call	Talk
	or	ax, ax
	je	Mine
	call	RudeToPrelate
Mine:
	mov	ax, OFFSET PrelateOnMine
	call	Talk
	mov	ax, OFFSET PrelateByeRude
	mov	bx, word ptr cs:rdf_state
	cmp	word ptr [bx+was_rude], 0
	jne	L03F5
	mov	ax, OFFSET PrelateByePolite
L03F5:
	call	Talk
	retf

; Looking at the Prelate (no speaker: narration).
H_03F9:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_0409
LookAtPrelate:
	mov	ax, 0
	mov	bx, OFFSET T_DEM0N004
	call	Say
	retf

; Phasers on the snow (23h), the sign (25h), the buildings (20h) and the
; Prelate (8): the crew objects.
H_0409:
	SCRIPT	MSG_USE, IT_PHASERS, 23h, 0, H_0411
	jmp	SHORT PhaserSnow

H_0411:
	SCRIPT	MSG_USE, IT_PHASERK, 23h, 0, H_0476
PhaserSnow:
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM0_039
	call	Say
	jmp	SHORT L0475

T_DEM0_039	LABEL	BYTE
	DB	'#DEM0\DEM0_039#Aw, Captain, please don''t melt the snow. I''ve nev'
	DB	'er seen it before.',0
L0475:
	retf

H_0476:
	SCRIPT	MSG_USE, IT_PHASERS, 25h, 0, H_047E
	jmp	SHORT PhaserSign

H_047E:
	SCRIPT	MSG_USE, IT_PHASERK, 25h, 0, H_04C0
PhaserSign:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM0_017
	call	Say
	jmp	SHORT L04BF

T_DEM0_017	LABEL	BYTE
	DB	'#DEM0\DEM0_017#Quite the vandal aren''t we, Jim?',0
L04BF:
	retf

H_04C0:
	SCRIPT	MSG_USE, IT_PHASERK, 20h, 0, H_05BC
PhaserBuilding:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM0_015
	call	Say
	jmp	SHORT L052B

T_DEM0_015	LABEL	BYTE
	DB	'#DEM0\DEM0_015#Burning down their house is not the best way to g'
	DB	'ain their confidence Jim!',0
L052B:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM0_013
	call	Say
	jmp	SHORT L0567

T_DEM0_013	LABEL	BYTE
	DB	'#DEM0\DEM0_013#Captain, Doctor McCoy is correct.',0
L0567:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L05BB
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM0_040
	call	Say
	jmp	SHORT L05BB

T_DEM0_040	LABEL	BYTE
	DB	'#DEM0\DEM0_040#Is he always this trigger happy on ground mission'
	DB	's?',0
L05BB:
	retf

H_05BC:
	SCRIPT	MSG_USE, IT_PHASERK, 8, 0, H_05CC
PhaserPrelate:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM0_020
	call	Say
	retf

; Looking at things.
H_05CC:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_0602
LookAtSign:
	mov	ax, OFFSET N_Sign
	mov	bx, OFFSET S_05DD
	call	Say
	jmp	SHORT L0601

S_05DD	LABEL	BYTE
	DB	'All mining equipment use this road.',0
L0601:
	retf

H_0602:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_0611
LookAtTrees:
	sub	ax, ax
	mov	bx, OFFSET T_DEM0N006
	call	Say
	retf

H_0611:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_0620
LookAtTrees2:
	sub	ax, ax
	mov	bx, OFFSET T_DEM0N006
	call	Say
	retf

H_0620:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_062F
LookAtSnow:
	sub	ax, ax
	mov	bx, OFFSET T_DEM0N007
	call	Say
	retf

H_062F:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_063E
LookAtScene:
	sub	ax, ax
	mov	bx, OFFSET T_DEM0N000
	call	Say
	retf

H_063E:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_064D
LookAtBushes:
	sub	ax, ax
	mov	bx, OFFSET T_DEM0N010
	call	Say
	retf

H_064D:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_065C
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_DEM0N005
	call	Say
	retf

H_065C:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_066B
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_DEM0N002
	call	Say
	retf

H_066B:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_067A
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_DEM0N003
	call	Say
	retf

H_067A:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_0689
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_DEM0N009
	call	Say
	retf

H_0689:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_0691
	jmp	SHORT LookAtDoor

H_0691:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_0699
LookAtDoor:
	jmp	SHORT LookAtBuilding

H_0699:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_06A9
LookAtBuilding:
	mov	ax, OFFSET S_0A64
	mov	bx, OFFSET T_DEM0N001
	call	Say
	retf

; Talking to the crew.
H_06A9:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_06D4
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM0_009
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM0_027
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM0_004
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM0_024
	call	Say
	retf

H_06D4:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0711
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM0_043
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM0_026
	call	Say
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM0_042
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM0_025
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM0_007
	call	Say
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM0_044
	call	Say
	retf

H_0711:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0758
TalkToMcCoy:
	cmp	byte ptr [si+met_prelate], 1
	jne	L0748
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM0_011
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM0_023
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM0_029
	call	Say
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L0747
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM0_041
	call	Say
L0747:
	retf

L0748:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM0_019
	call	Say
	cmp	byte ptr [si+asked_witnesses], 1
	jne	AskWitnesses
	retf

H_0758:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0795
TalkToSpock:
	cmp	byte ptr [si+met_prelate], 1
	jne	L076E
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM0_014
	call	Say
	retf

L076E:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM0_014
	call	Say
	cmp	byte ptr [si+asked_witnesses], 1
	jne	AskWitnesses
	retf

AskWitnesses:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM0_001
	call	Say
	mov	ax, OFFSET N_Prel_Angiven
	mov	bx, OFFSET T_DEM0_030
	call	Say
	mov	byte ptr [si+asked_witnesses], 1
	retf

; Tricorders: Spock's on anything, McCoy's on anything and on the
; Prelate. The last script: its next is Talk (see the quirk above).
H_0795:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_07C6
ScanWithSTricorder:
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
	mov	bx, OFFSET T_DEM0_028
	call	Say
	retf

H_07C6:
	SCRIPT	MSG_USE, IT_MTRICOR, ANY, 0, H_07F7
ScanWithMTricorder:
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
	mov	bx, OFFSET T_DEM0_021
	call	Say
	retf

H_07F7:
	SCRIPT	MSG_USE, IT_MTRICOR, 8, 0, Talk
ScanPrelate:
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
	cmp	byte ptr [si+met_prelate], 1
	je	L082E
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM0_022
	call	Say
	retf

L082E:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM0_018
	call	Say
	retf

; Talk: conversation AX (speaker, choices, 0); returns the choice.
Talk:
	push	ax
	mov	ax, RC_TALK
	push	ax
	SERVICE		; Talk(?)
	add	sp, 4
	ret

; The first sceptical answer: -3 to the score, and the Prelate takes
; offence. BX: &room, read again as SI may not be (it is, from scripts).
RudeToPrelate:
	mov	bx, word ptr cs:rdf_state
	cmp	word ptr [bx+was_rude], 0
	jne	L0860
	sub	word ptr [si+score], 3
	mov	word ptr [bx+was_rude], 1
	mov	ax, OFFSET PrelateOffended
	call	Talk
L0860:
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
	DW	26h, 4	; id, points
	DW	137,131, 160,131, 160,139, 137,139
	DW	27h, 4	; id, points
	DW	232,153, 265,153, 265,171, 232,171
	DW	20h, 4	; id, points
	DW	122,90, 144,55, 227,55, 227,90
	DW	20h, 3	; id, points
	DW	205,54, 223,20, 223,54
	DW	20h, 4	; id, points
	DW	228,13, 295,13, 295,90, 228,90
	DW	20h, 4	; id, points
	DW	122,91, 295,91, 295,132, 122,132
	DW	20h, 3	; id, points
	DW	228,133, 295,133, 295,167
	DW	21h, 4	; id, points
	DW	12,12, 224,13, 209,51, 15,51
	DW	23h, 3	; id, points
	DW	114,158, 177,131, 299,158
	DW	23h, 6	; id, points
	DW	142,182, 237,169, 252,159, 295,179, 295,195, 147,195
	DW	23h, 4	; id, points
	DW	10,171, 42,171, 42,195, 10,195
	DW	23h, 4	; id, points
	DW	43,193, 70,193, 70,195, 43,195
	DW	23h, 4	; id, points
	DW	71,190, 111,190, 111,195, 71,195
	DW	23h, 4	; id, points
	DW	112,178, 152,178, 152,195, 112,195
	DW	23h, 4	; id, points
	DW	153,175, 235,175, 235,195, 153,195
	DW	22h, 4	; id, points
	DW	12,54, 136,55, 107,107, 12,109
	DW	25h, 4	; id, points
	DW	29,120, 36,120, 36,140, 29,140
	DW	24h, 4	; id, points
	DW	10,169, 10,120, 54,115, 39,162
	DW	24h, 4	; id, points
	DW	66,116, 72,104, 108,128, 84,131
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	0, 4	; id, points
	DW	39,97, 78,97, 78,117, 39,117
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	137,131, 160,131, 160,139, 137,139
	DW	1, 4	; id, points
	DW	232,153, 265,153, 265,171, 232,171
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Prel_Angiven	LABEL	BYTE
	DB	'Prel. Angiven',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Ensign_Everts	LABEL	BYTE
	DB	'Ensign Everts',0
	DB	'wes',0
S_0A64	LABEL	BYTE
	DB	0
N_Sign	LABEL	BYTE
	DB	'Sign',0
T_DEM0_036	LABEL	BYTE
	DB	'#DEM0\DEM0_036#This is so much better, gentlefolk. We are honore'
	DB	'd at your presence and hope you will find peace here in our have'
	DB	'n.',0
T_DEM0_006	LABEL	BYTE
	DB	'#DEM0\DEM0_006#I''m Captain James T. Kirk of the U.S.S. Enterpris'
	DB	'e. We have received word that alien lifeforms are creating probl'
	DB	'ems at your mining facilities at Idyll Mountain. Tell me more.',0
T_DEM0_008	LABEL	BYTE
	DB	'#DEM0\DEM0_008#Most High Prelate Angiven, I am honored to meet y'
	DB	'ou. I consider it my divine duty to assist you in any possible w'
	DB	'ay with the spawn of the devil.',0
T_DEM0_003	LABEL	BYTE
	DB	'#DEM0\DEM0_003#Been seeing ghosts and bogeymen eh? I find that a'
	DB	' little hard to believe.',0
T_DEM0_038	LABEL	BYTE
	DB	'#DEM0\DEM0_038#Certainly, Captain Kirk. Not aliens, per se -- we'
	DB	' have encountered what we believe are demons at Idyll Mountain, '
	DB	'creatures surely emerging from the very gates of Hell. Our God w'
	DB	'ould not test us thus without reason, so we believe your might a'
	DB	'nd insight are our God''s method to help us discover what is goin'
	DB	'g on.',0
T_DEM0_032	LABEL	BYTE
	DB	'#DEM0\DEM0_032#Captain Kirk. I had no idea we were blessed with '
	DB	'one of our order in the ranks of Starfleet. We believe we have l'
	DB	'ocated the very Gates of Hell below Idyll Mountain.',0
T_DEM0_033	LABEL	BYTE
	DB	'#DEM0\DEM0_033#Starfleet recognizes our freedom to worship and b'
	DB	'elieve as we see fit, Captain. I am surprised that you do not sh'
	DB	'are that feeling. Rest assured that Starfleet Command will be in'
	DB	'formed of your rudeness.',0
T_DEM0_002	LABEL	BYTE
	DB	'#DEM0\DEM0_002#Aside from seeing demons, has any hard data been '
	DB	'collected? Any evidence I could see?',0
T_DEM0_005	LABEL	BYTE
	DB	'#DEM0\DEM0_005#Demons? Gates of Hell? This is the 23rd Century!',0
T_DEM0_031	LABEL	BYTE
	DB	'#DEM0\DEM0_031#A skeptic would consider everything merely anecdo'
	DB	'tal or unproven. My people will gladly tell you their own storie'
	DB	's, so you need not hear it secondhand through me.',0
T_DEM0_010	LABEL	BYTE
	DB	'#DEM0\DEM0_010#What can you tell me about the mine itself?',0
T_DEM0_012	LABEL	BYTE
	DB	'#DEM0\DEM0_012#You''re wasting the time of a starship capable of '
	DB	'destroying this planet with campfire stories? No wonder you were'
	DB	' dumped out here in the middle of nowhere.',0
T_DEM0_035	LABEL	BYTE
	DB	'#DEM0\DEM0_035#The area is exceptionally stable tectonically, an'
	DB	'd easy for our machinery to work in, praise God. We''ve mined for'
	DB	' hafnium and a variety of useful trace elements. The deeper we d'
	DB	'ig, however, the more anomalous the variety of minerals seems to'
	DB	' be. Our Ignaciate, Brother Stephen, has his own theories about '
	DB	'why this might be. Either way, the anomalies inspired Brother Ka'
	DB	'ndrey to conduct studies inside the mine. Yesterday, he reported'
	DB	' discovering a strange door -- a gate to Hell, surely, for the d'
	DB	'emons caused a cave-in immediately. Kandrey was trapped, unconsc'
	DB	'ious, and the demons prevent us from rescuing him. We can only h'
	DB	'ope he is still alive.',0
T_DEM0_037	LABEL	BYTE
	DB	'#DEM0\DEM0_037#We need your help, Kirk. You may have no respect '
	DB	'for our beliefs, but I hope you will look beyond that. Godspeed.',0
T_DEM0_034	LABEL	BYTE
	DB	'#DEM0\DEM0_034#Thank you for your courtesy, Kirk. May you receiv'
	DB	'e the guidance and protection of our God as you complete this di'
	DB	'vine mission.',0
T_DEM0N004	LABEL	BYTE
	DB	'#DEM0\DEM0N004#High Prelate Angiven waits patiently for you to d'
	DB	'ecide what you will do next.',0
	DB	'#DEM0\DEM0N008#Some colonists.',0
T_DEM0N000	LABEL	BYTE
	DB	'#DEM0\DEM0N000#A beautiful, snow covered scene with a path leadi'
	DB	'ng off to Mount Idyll.',0
T_DEM0N006	LABEL	BYTE
	DB	'#DEM0\DEM0N006#On the other side of the trees is Idyll Mountain.'
	DB	' A tall, forbidding place. You have a vague feeling of danger.',0
T_DEM0N001	LABEL	BYTE
	DB	'#DEM0\DEM0N001#A quickly constructed spartan shelter, primarily '
	DB	'used by fledgling colonies.',0
T_DEM0N007	LABEL	BYTE
	DB	'#DEM0\DEM0N007#Remnants of a recent snowfall cover the ground.',0
T_DEM0N010	LABEL	BYTE
	DB	'#DEM0\DEM0N010#Various bushes and shrubs grow along the edge of '
	DB	'the forest.',0
T_DEM0N009	LABEL	BYTE
	DB	'#DEM0\DEM0N009#Spock raises an eyebrow.',0
T_DEM0N005	LABEL	BYTE
	DB	'#DEM0\DEM0N005#James Tiberius Kirk, Captain of the Enterprise. H'
	DB	'e''s always happy to run an errand of mercy.',0
T_DEM0N002	LABEL	BYTE
	DB	'#DEM0\DEM0N002#Dr. Leonard McCoy, the finest doctor in Starfleet'
	DB	', wishes that he were on a warmer planet.',0
T_DEM0N003	LABEL	BYTE
	DB	'#DEM0\DEM0N003#Ensign Everts, who has never been this close to s'
	DB	'now before in his life, gazes with child-like fascination at the'
	DB	' ground.',0
T_DEM0_019	LABEL	BYTE
	DB	'#DEM0\DEM0_019#I don''t know if the problem is real, the result o'
	DB	'f a new illness, or mass hysteria. But at the very least, there'''
	DB	's an injured miner who needs my help.',0
T_DEM0_014	LABEL	BYTE
	DB	'#DEM0\DEM0_014#Captain, demons and supernatural creatures are, a'
	DB	'lmost by definition, illogical. Yet it is evident these people b'
	DB	'elieve what they have seen. Barring illness or mass hysteria, I '
	DB	'agree that a real problem seems to exist.',0
T_DEM0_011	LABEL	BYTE
	DB	'#DEM0\DEM0_011#You look rather cold, Bones.',0
T_DEM0_023	LABEL	BYTE
	DB	'#DEM0\DEM0_023#I''m not cold, I''m freezing! And that damn transpo'
	DB	'rter just had to set me down in the middle of a snow drift!',0
T_DEM0_029	LABEL	BYTE
	DB	'#DEM0\DEM0_029#A centimeter of snow does not technically constit'
	DB	'ute a drift, Doctor.',0
T_DEM0_041	LABEL	BYTE
	DB	'#DEM0\DEM0_041#And doctors say that patients complain too much!',0
T_DEM0_043	LABEL	BYTE
	DB	'#DEM0\DEM0_043#I''ve never seen snow like this before. This is gr'
	DB	'eat!',0
T_DEM0_026	LABEL	BYTE
	DB	'#DEM0\DEM0_026#You mean you''ve never built a snowman, ensign?',0
T_DEM0_042	LABEL	BYTE
	DB	'#DEM0\DEM0_042#I''ve never even thrown a snowball. Do you think a'
	DB	'nyone would mind?',0
T_DEM0_025	LABEL	BYTE
	DB	'#DEM0\DEM0_025#Well...',0
T_DEM0_007	LABEL	BYTE
	DB	'#DEM0\DEM0_007#Later Ensign. We have work to do.',0
T_DEM0_044	LABEL	BYTE
	DB	'#DEM0\DEM0_044#Of course, sir.',0
T_DEM0_009	LABEL	BYTE
	DB	'#DEM0\DEM0_009#This planet''s as beautiful as everyone says it is'
	DB	'.',0
T_DEM0_027	LABEL	BYTE
	DB	'#DEM0\DEM0_027#The trees. The fresh air. The freezing cold...',0
T_DEM0_004	LABEL	BYTE
	DB	'#DEM0\DEM0_004#C''mon Bones, the cold will improve your circulati'
	DB	'on.',0
T_DEM0_024	LABEL	BYTE
	DB	'#DEM0\DEM0_024#Some people get too much circulation!',0
T_DEM0_030	LABEL	BYTE
	DB	'#DEM0\DEM0_030#They are already gathered in the chapel, and will'
	DB	' cooperate in any way with you. First door on my right.',0
T_DEM0_001	LABEL	BYTE
	DB	'#DEM0\DEM0_001#Doctor, you need to investigate the possibility o'
	DB	'f disease, mental or physical, among these people, before we go '
	DB	'chasing up the mountains. Prelate Angiven, may we see those who '
	DB	'have encountered the demons?',0
T_DEM0_022	LABEL	BYTE
	DB	'#DEM0\DEM0_022#The man''s in perfect health.',0
T_DEM0_018	LABEL	BYTE
	DB	'#DEM0\DEM0_018#His blood pressure''s up a bit, but he believes he'
	DB	'''s telling the truth.',0
T_DEM0_021	LABEL	BYTE
	DB	'#DEM0\DEM0_021#Jim, I am not picking up any unusual life here, j'
	DB	'ust native lifeforms and the settlers. The colonists are all hum'
	DB	'an, except for the one Tellarite. If there are demons here, they'
	DB	' don''t register on my tricorder.',0
T_DEM0_028	LABEL	BYTE
	DB	'#DEM0\DEM0_028#Captain, reading the rocks in this area, I find t'
	DB	'hat this locality may have been disturbed in the distant past. R'
	DB	'ecent disturbances created by the colonists'' construction and mi'
	DB	'ning prevent me from discovering anything further.',0
T_DEM0_020	LABEL	BYTE
	DB	'#DEM0\DEM0_020#Jim! Are you out of your mind?',0
PrelateHello	LABEL	BYTE
	DW	OFFSET N_Prel_Angiven, OFFSET T_DEM0_036, 0	; speaker, choices, 0
KirkIntroduces	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_DEM0_006, OFFSET T_DEM0_008, OFFSET T_DEM0_003, 0	; speaker, choices, 0
PrelateOnDemons	LABEL	BYTE
	DW	OFFSET N_Prel_Angiven, OFFSET T_DEM0_038, 0	; speaker, choices, 0
PrelateOnGates	LABEL	BYTE
	DW	OFFSET N_Prel_Angiven, OFFSET T_DEM0_032, 0	; speaker, choices, 0
KirkAsksEvidence	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_DEM0_002, OFFSET T_DEM0_005, 0	; speaker, choices, 0
PrelateOnSkeptics	LABEL	BYTE
	DW	OFFSET N_Prel_Angiven, OFFSET T_DEM0_031, 0	; speaker, choices, 0
KirkAsksMine	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_DEM0_010, OFFSET T_DEM0_012, 0	; speaker, choices, 0
PrelateOnMine	LABEL	BYTE
	DW	OFFSET N_Prel_Angiven, OFFSET T_DEM0_035, 0	; speaker, choices, 0
PrelateByeRude	LABEL	BYTE
	DW	OFFSET N_Prel_Angiven, OFFSET T_DEM0_037, 0	; speaker, choices, 0
PrelateByePolite	LABEL	BYTE
	DW	OFFSET N_Prel_Angiven, OFFSET T_DEM0_034, 0	; speaker, choices, 0
PrelateOffended	LABEL	BYTE
	DW	OFFSET N_Prel_Angiven, OFFSET T_DEM0_033, 0	; speaker, choices, 0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
