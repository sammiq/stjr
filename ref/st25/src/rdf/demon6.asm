; DEMON6.RDF - "Demon World", Brother Stephen's study. His Ardak-4
; synthesizer turns the Laraxian berries into the Hypo-Dytoxin for Brother
; Chub; Spock repairs the android's hand at the workbench; the computer
; runs a simulation of an eclipse. Stephen's display case holds a
; meteorite, fossil shells, minerals, a skull and a corroded piece of metal
; (the key the Nauian needs, room 4): talk him round and he unlocks it.
;
; Actors: 8 Brother Stephen (here once the berries have been found, or
; after the Klingons until Chub has been examined), 9 the computer screen,
; 10 (0Ah) the door.
; Objects: 8 Brother Stephen, 9/21h the computer, 0Ah/26h the door, 20h
; the case, 22h the workbench, 23h the synthesizer, 24h the skylight,
; 25h the glassware; the case's items by their item numbers.
; Region 0: the doorstep. Exit 3: back to the colony (room 0).
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 0F69: the engine reads its bytes
;   as key 50 B8 03 00 and next 2E50 (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
insulted_stephen	EQU	RS_VARS+2	; word: Kirk called his collection junk
stephen_welcomed	EQU	RS_VARS+0Bh
saw_klingons	EQU	RS_VARS+0Eh	; the Klingons have appeared (room 1)
hand_repaired	EQU	RS_VARS+12h
examined_chub	EQU	RS_VARS+15h
need_berries	EQU	RS_VARS+16h	; McCoy knows the cure needs the berries
taken_items	EQU	RS_VARS+26h	; bits: items taken from the case; see case_items
got_berries	EQU	RS_VARS+27h
made_hypo	EQU	RS_VARS+28h	; McCoy has made the Hypo-Dytoxin
hypo_scored	EQU	RS_VARS+2Bh	; the Hypo-Dytoxin's point has been given
saw_simulation	EQU	RS_VARS+2Ch	; the computer's point has been given
score	EQU	RS_VARS+2Fh	; word: the mission's score

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0C7h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	93h
rdf_scale_min	LABEL	BYTE
	DW	0D2h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, -1, -1, 0	; room for each exit
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
	DW	160,148, 160,160	; entrance 3, crew 0
	DW	160,148, 243,153	; entrance 3, crew 1
	DW	160,148, 209,165	; entrance 3, crew 2
	DW	160,148, 102,155	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	161,169, 145,158, 174,158, 159,148
; In the room file, so these start again each time the room loads
stephen_offended	LABEL	BYTE	; no more talk of the case this visit
	DB	0
stephen_here	LABEL	BYTE
	DB	0, 0
case_open	LABEL	BYTE	; Stephen has unlocked the case
	DB	0
door_steps	LABEL	BYTE	; the walk and the door have both finished at 2
	DB	0
going_out	LABEL	BYTE	; Kirk is on his way to the door
	DB	0, 0, 0
N_oldman	LABEL	BYTE
	DB	'oldman',0
N_scrnan	LABEL	BYTE
	DB	'scrnan',0
N_spokop	LABEL	BYTE
	DB	'spokop',0
N_s0r6d1	LABEL	BYTE
	DB	's0r6d1',0
N_s0r6d2	LABEL	BYTE
	DB	's0r6d2',0
N_musemn	LABEL	BYTE
	DB	'musemn',0
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_mscans	LABEL	BYTE
	DB	'mscans',0

rdf_scripts:
; The room starts: Brother Stephen if he is here, the door, the computer.
H_010A:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0186
StartRoom:
	jmp	SHORT L011B

N_DEM6LOOP	LABEL	BYTE
	DB	'DEM6LOOP',0
L011B:
	push	OFFSET N_DEM6LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("DEM6LOOP")
	add	sp, 4
	cmp	byte ptr [si+got_berries], 1
	je	L013C
	cmp	byte ptr [si+examined_chub], 1
	je	L0158
	cmp	byte ptr [si+saw_klingons], 1
	jne	L0158
L013C:
	push	0
	push	0B1h
	push	5Fh
	push	OFFSET N_oldman
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "oldman", 95, 177, 0)
	add	sp, 0Ch
	mov	byte ptr cs:stephen_here, 1
L0158:
	push	0
	push	92h
	push	0A0h
	push	OFFSET N_s0r6d2
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "s0r6d2", 160, 146, 0)
	add	sp, 0Ch
	push	0
	push	0C7h
	push	0
	push	OFFSET N_scrnan
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "scrnan", 0, 199, 0)
	add	sp, 0Ch
	retf

; Tick 30: Stephen says hello, once.
H_0186:
	SCRIPT	MSG_TICK, 1Eh, 0, 0, H_01B2
StephenWelcomes:
	cmp	byte ptr [si+got_berries], 1
	jne	L01B1
	cmp	byte ptr [si+examined_chub], 1
	je	L01B1
	cmp	byte ptr [si+saw_klingons], 1
	jne	L01B1
	cmp	byte ptr [si+stephen_welcomed], 1
	je	L01B1
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_042
	call	Say
	mov	byte ptr [si+stephen_welcomed], 1
L01B1:
	retf

; Spock has reached the computer (walk msg 3): the eclipse simulation.
H_01B2:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_01C2
SpockAtComputer:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM6_014
	call	Say
	retf

; Leaving: walk to the door (msg 4); at the doorstep it opens (anim
; msg 2), and when both are done, back to the colony.
H_01C2:
	SCRIPT	MSG_WALK, 26h, 0, 0, H_01CA
	jmp	SHORT WalkToDoor

H_01CA:
	SCRIPT	MSG_WALK, 0Ah, 0, 0, H_01EF
WalkToDoor:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr cs:going_out, 1
	push	4
	push	94h
	push	0A0h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 160, 148, 4)
	add	sp, 0Ah
	retf

H_01EF:
	SCRIPT	MSG_REGION, 0, 0, 0, H_0221
ReachDoor:
	cmp	byte ptr cs:going_out, 1
	jne	L0220
	push	2
	push	92h
	push	0A0h
	push	OFFSET N_s0r6d1
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "s0r6d1", 160, 146, 2)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
L0220:
	retf

H_0221:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_0229
	jmp	SHORT GoOut

H_0229:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_024C
GoOut:
	inc	byte ptr cs:door_steps
	cmp	byte ptr cs:door_steps, 2
	je	L023D
	retf

L023D:
	push	2
	push	0
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(0, 2)
	add	sp, 6
	retf

; Phasers.
H_024C:
	SCRIPT	MSG_USE, IT_PHASERK, 8, 0, H_0254
	jmp	SHORT PhaserStephen

H_0254:
	SCRIPT	MSG_USE, IT_PHASERS, 8, 0, H_02B2
PhaserStephen:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_028
	call	Say
	jmp	SHORT L02B1

T_DEM6_028	LABEL	BYTE
	DB	'#DEM6\DEM6_028#There is no need to threaten me if you need to us'
	DB	'e my study.',0
L02B1:
	retf

H_02B2:
	SCRIPT	MSG_USE, IT_PHASERK, 20h, 0, H_02BA
	jmp	SHORT PhaserCase

H_02BA:
	SCRIPT	MSG_USE, IT_PHASERS, 20h, 0, H_0303
PhaserCase:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM6_017
	call	Say
	jmp	SHORT L0302

T_DEM6_017	LABEL	BYTE
	DB	'#DEM6\DEM6_017#Jim, that would destroy the glass case!',0
L0302:
	retf

; Looking at things. The computer's simulation is worth a point, once.
H_0303:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_0312
LookAtWorkbench:
	sub	ax, ax
	mov	bx, OFFSET T_DEM6N003
	call	Say
	retf

H_0312:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_0321
LookAtCase:
	sub	ax, ax
	mov	bx, OFFSET T_DEM6N001
	call	Say
	retf

H_0321:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_0330
LookAtGlassware:
	sub	ax, ax
	mov	bx, OFFSET T_DEM6N007
	call	Say
	retf

H_0330:
	SCRIPT	MSG_LOOK, IT_MINERAL, 0, 0, H_033F
LookAtMinerals:
	sub	ax, ax
	mov	bx, OFFSET T_DEM6N016
	call	Say
	retf

H_033F:
	SCRIPT	MSG_LOOK, IT_SHELLS, 0, 0, H_034E
LookAtShells:
	sub	ax, ax
	mov	bx, OFFSET T_DEM6N011
	call	Say
	retf

H_034E:
	SCRIPT	MSG_LOOK, IT_SKULL, 0, 0, H_035D
LookAtSkull:
	sub	ax, ax
	mov	bx, OFFSET T_DEM6N017
	call	Say
	retf

H_035D:
	SCRIPT	MSG_LOOK, IT_METAL, 0, 0, H_036C
LookAtMetal:
	sub	ax, ax
	mov	bx, OFFSET T_DEM6N005
	call	Say
	retf

H_036C:
	SCRIPT	MSG_LOOK, IT_METEOR, 0, 0, H_037B
LookAtMeteorite:
	sub	ax, ax
	mov	bx, OFFSET T_DEM6N000
	call	Say
	retf

H_037B:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_038A
LookAtSkylight:
	sub	ax, ax
	mov	bx, OFFSET T_DEM6N002
	call	Say
	retf

H_038A:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_0399
LookAtSynthesizer:
	sub	ax, ax
	mov	bx, OFFSET T_DEM6N004
	call	Say
	retf

H_0399:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_03A8
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_DEM6N008
	call	Say
	retf

H_03A8:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_03B7
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_DEM6N015
	call	Say
	retf

H_03B7:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_03C6
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_DEM6N009
	call	Say
	retf

H_03C6:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_03D5
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_DEM6N010
	call	Say
	retf

H_03D5:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_03DD
	jmp	SHORT LookAtComputer

H_03DD:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_03FB
LookAtComputer:
	mov	ax, OFFSET S_1077
	mov	bx, OFFSET T_DEM6N006
	call	Say
	cmp	byte ptr [si+saw_simulation], 1
	je	L03FA
	mov	byte ptr [si+saw_simulation], 1
	add	word ptr [si+score], 1
L03FA:
	retf

H_03FB:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_0462
LookAtScene:
	mov	ax, 0
	mov	bx, OFFSET T_DEM6N024
	call	Say
	jmp	SHORT L0461

T_DEM6N024	LABEL	BYTE
	DB	'#DEM6\DEM6N024#This appears to be a study and lab. The equipment'
	DB	' looks very ancient.',0
L0461:
	retf

H_0462:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_04BF
LookAtStephen:
	mov	ax, 0
	mov	bx, OFFSET T_DEM6N021
	call	Say
	jmp	SHORT L04BE

T_DEM6N021	LABEL	BYTE
	DB	'#DEM6\DEM6N021#Brother Stephen watches patiently as you examine '
	DB	'his study.',0
L04BE:
	retf

; Talking.
H_04BF:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_04CF
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM6_020
	call	Say
	retf

H_04CF:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_04DF
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM6_025
	call	Say
	retf

H_04DF:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_04EF
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM6_002
	call	Say
	retf

H_04EF:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_04FF
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM6_053
	call	Say
	retf

H_04FF:
	SCRIPT	MSG_TALK, 8, 0, 0, H_050F
TalkToStephen:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_035
	call	Say
	retf

H_050F:
	SCRIPT	MSG_USE, IT_BERRY, 8, 0, H_0620
ShowBerriesToStephen:
	cmp	byte ptr [si+need_berries], 1
	je	L051E
	JMPN	L05C2

L051E:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_027
	call	Say
	JMPN	L05C1

T_DEM6_027	LABEL	BYTE
	DB	'#DEM6\DEM6_027#The settings on the Ardak-4 have already been adj'
	DB	'usted. Simply place the berry in the machine and the Hypo-Dytoxi'
	DB	'n will be synthesized.',0
L05C1:
	retf

L05C2:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_026
	call	Say
	jmp	SHORT L061F

T_DEM6_026	LABEL	BYTE
	DB	'#DEM6\DEM6_026#Fascinating, these berries can be used to synthes'
	DB	'ize Hypo-Dytoxin.',0
L061F:
	retf

; McCoy makes the Hypo-Dytoxin from the berries, once he knows they are
; the cure (msgs 1): +1 score, once.
H_0620:
	SCRIPT	MSG_USE, IT_BERRY, 23h, 0, H_0642
UseBerriesOnSynthesizer:
	cmp	byte ptr [si+need_berries], 1
	je	L062D
	retf

L062D:
	push	1
	push	0A5h
	push	104h
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 260, 165, 1)
	add	sp, 0Ah
	retf

H_0642:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_0678
McCoyAtSynthesizer:
	push	1
	push	-1
	push	-1
	push	OFFSET N_musemn
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musemn", -1, -1, 1)
	add	sp, 0Ch
	jmp	SHORT L0668

N_LD1REPLI	LABEL	BYTE
	DB	'LD1REPLI',0
L0668:
	push	OFFSET N_LD1REPLI
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("LD1REPLI")
	add	sp, 4
	retf

H_0678:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_0762
HypoMade:
	push	-1
	push	-1
	push	RC_MUSIC
	SERVICE		; Music(-1, -1)
	add	sp, 6
	mov	ax, 0
	mov	bx, OFFSET T_DEM6N023
	call	Say
	jmp	SHORT L06DA

T_DEM6N023	LABEL	BYTE
	DB	'#DEM6\DEM6N023#The machine synthesizes a quantity of Hypo-Dytoxi'
	DB	'n.',0
L06DA:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM6_018
	call	Say
	jmp	SHORT L0737

T_DEM6_018	LABEL	BYTE
	DB	'#DEM6\DEM6_018#We''ve got to get this to brother Chub as quickly '
	DB	'as possible, Jim!',0
L0737:
	push	IT_DETOXIN
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_DETOXIN)
	add	sp, 4
	mov	byte ptr [si+made_hypo], 1
	push	IT_BERRY
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_BERRY)
	add	sp, 4
	cmp	byte ptr [si+hypo_scored], 1
	je	L0761
	mov	byte ptr [si+hypo_scored], 1
	add	word ptr [si+score], 1
L0761:
	retf

; Spock repairs the hand at the workbench (msgs 2, 3): +2 score.
H_0762:
	SCRIPT	MSG_USE, IT_HAND, 22h, 0, H_07DB
UseHandOnWorkbench:
	cmp	byte ptr [si+hand_repaired], 1
	jne	L0778
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM6N018
	call	Say
	retf

L0778:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM6_005
	call	Say
	jmp	SHORT L07C6

T_DEM6_005	LABEL	BYTE
	DB	'#DEM6\DEM6_005#Mr. Spock, see what you can do about that hand.',0
L07C6:
	push	2
	push	0BBh
	push	0B3h
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 179, 187, 2)
	add	sp, 0Ah
	retf

H_07DB:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_07F9
SpockAtWorkbench:
	push	3
	push	0BBh
	push	0B3h
	push	OFFSET N_spokop
	push	1
	push	RC_ANIM0
	SERVICE		; Anim0(1, "spokop", 179, 187, 3)
	add	sp, 0Ch
	retf

H_07F9:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_0821
HandRepaired:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM6_024
	call	Say
	mov	byte ptr [si+hand_repaired], 1
	add	word ptr [si+score], 2
	push	1
	push	RC_STOPANIM
	SERVICE		; StopAnim(1)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_0821:
	SCRIPT	MSG_USE, ANY, 22h, 0, H_0831
UseWorkbench:
	mov	ax, OFFSET S_1077
	mov	bx, OFFSET T_DEM6N020
	call	Say
	retf

; Asking about the case (with Stephen here): calling it junk offends him
; (insulted_stephen); hearing him out about every item gets it unlocked.
H_0831:
	SCRIPT	MSG_USE, OBJ_KIRK, 20h, 0, H_0839
	jmp	SHORT McCoyAtCase

H_0839:
	SCRIPT	MSG_USE, OBJ_MCCOY, 20h, 0, H_0841
McCoyAtCase:
	jmp	SHORT SpockAtCase

H_0841:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_0849
SpockAtCase:
	jmp	SHORT AskAboutCase

H_0849:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 20h, 0, H_0962
AskAboutCase:
	cmp	byte ptr cs:stephen_here, 1
	je	L086A
	mov	ax, OFFSET S_1077
	mov	bx, OFFSET T_DEM6N012
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM6_019
	call	Say
	retf

L086A:
	cmp	byte ptr cs:stephen_offended, 1
	jne	L0873
	retf

L0873:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_044
	call	Say
	mov	ax, OFFSET KirkOnCollection
	call	Talk
	AX8	cmp, 0
	jne	L0889
	jmp	SHORT L0899

L0889:
	AX8	cmp, 1
	jne	L0890
	jmp	SHORT L08AE

L0890:
	AX8	cmp, 2
	jne	L0897
	jmp	SHORT L08B9

L0897:
	jmp	SHORT L0911

L0899:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_030
	call	Say
	mov	byte ptr cs:stephen_offended, 1
	mov	word ptr [si+insulted_stephen], 1
	retf

L08AE:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_034
	call	Say
	jmp	SHORT L08D8

L08B9:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_031
	call	Say
	mov	ax, OFFSET KirkOnFinds
	call	Talk
	AX8	cmp, 0
	jne	L08CF
	jmp	SHORT L0899

L08CF:
	AX8	cmp, 1
	jne	L08D6
	jmp	SHORT L08AE

L08D6:
	jmp	SHORT L0911

L08D8:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_051
	call	Say
	mov	ax, OFFSET KirkAsksAbout
	call	Talk
	AX8	cmp, 0
	jne	L08EE
	jmp	SHORT L091B

L08EE:
	AX8	cmp, 1
	jne	L08F5
	jmp	SHORT L0926

L08F5:
	AX8	cmp, 2
	jne	L08FC
	jmp	SHORT L0931

L08FC:
	AX8	cmp, 3
	jne	L0903
	jmp	SHORT L093C

L0903:
	AX8	cmp, 4
	jne	L090A
	jmp	SHORT L0947

L090A:
	AX8	cmp, 5
	jne	L0911
	jmp	SHORT L0952

L0911:
	mov	ax, OFFSET S_1077
	mov	bx, OFFSET S_2016
	call	Say
	retf

L091B:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_040
	call	Say
	jmp	SHORT L08D8

L0926:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_033
	call	Say
	jmp	SHORT L08D8

L0931:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_036
	call	Say
	jmp	SHORT L08D8

L093C:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_038
	call	Say
	jmp	SHORT L08D8

L0947:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_039
	call	Say
	jmp	SHORT L08D8

L0952:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_041
	call	Say
	mov	byte ptr cs:case_open, 1
	retf

; The crew at the computer: only Spock will (walk msg 3).
H_0962:
	SCRIPT	MSG_USE, OBJ_KIRK, 21h, 0, H_096A
	jmp	SHORT KirkAtComputer

H_096A:
	SCRIPT	MSG_USE, OBJ_KIRK, 9, 0, H_09DC
KirkAtComputer:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM6_004
	call	Say
	jmp	SHORT L09D8

T_DEM6_004	LABEL	BYTE
	DB	'#DEM6\DEM6_004#Mr. Spock, See what you can dig up from that old '
	DB	'fashioned computer terminal.',0
L09D8:
	JMPN	SpockUsesComputer

	DB	0CBh

H_09DC:
	SCRIPT	MSG_USE, OBJ_MCCOY, 21h, 0, H_09E4
	jmp	SHORT McCoyAtComputer

H_09E4:
	SCRIPT	MSG_USE, OBJ_MCCOY, 9, 0, H_0A46
McCoyAtComputer:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM6_015
	call	Say
	jmp	SHORT L0A45

T_DEM6_015	LABEL	BYTE
	DB	'#DEM6\DEM6_015#Do I look like a pointy eared, green blooded, kno'
	DB	'w-it-all alien?',0
L0A45:
	retf

H_0A46:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 21h, 0, H_0A4E
	jmp	SHORT EvertsAtComputer

H_0A4E:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 9, 0, H_0AA9
EvertsAtComputer:
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM6_052
	call	Say
	jmp	SHORT L0AA8

T_DEM6_052	LABEL	BYTE
	DB	'#DEM6\DEM6_052#I believe Mr. Spock would be more helpful with th'
	DB	'is, sir.',0
L0AA8:
	retf

H_0AA9:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_0AB1
	jmp	SHORT SpockUsesComputer

H_0AB1:
	SCRIPT	MSG_USE, OBJ_SPOCK, 9, 0, H_0ACB
SpockUsesComputer:
	push	3
	push	0C5h
	push	3Dh
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 61, 197, 3)
	add	sp, 0Ah
	retf

; Giving the case's items back to Stephen clears their bits.
H_0ACB:
	SCRIPT	MSG_USE, IT_MINERAL, 8, 0, H_0AD9
ReturnMinerals:
	and	byte ptr [si+taken_items], -9
	push	IT_MINERAL
	jmp	SHORT L0B0F

H_0AD9:
	SCRIPT	MSG_USE, IT_SHELLS, 8, 0, H_0AE7
ReturnShells:
	and	byte ptr [si+taken_items], -3
	push	IT_SHELLS
	jmp	SHORT L0B0F

H_0AE7:
	SCRIPT	MSG_USE, IT_METEOR, 8, 0, H_0AF5
ReturnMeteorite:
	and	byte ptr [si+taken_items], -5
	push	IT_METEOR
	jmp	SHORT L0B0F

H_0AF5:
	SCRIPT	MSG_USE, IT_SKULL, 8, 0, H_0B03
ReturnSkull:
	and	byte ptr [si+taken_items], -11h
	push	IT_SKULL
	jmp	SHORT L0B0F

H_0B03:
	SCRIPT	MSG_USE, IT_METAL, 8, 0, H_0B2C
ReturnMetal:
	and	byte ptr [si+taken_items], -2
	push	IT_METAL
L0B0F:
	push	RC_TAKEITEM
	SERVICE		; TakeItem(?)
	add	sp, 4
	mov	ax, OFFSET S_1077
	mov	bx, OFFSET T_DEM6N019
	call	Say
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_029
	call	Say
	retf

H_0B2C:
	SCRIPT	MSG_USE, IT_HAND, 8, 0, H_0B4C
ShowHandToStephen:
	cmp	byte ptr [si+hand_repaired], 1
	jne	L0B42
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_037
	call	Say
	retf

L0B42:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM6_043
	call	Say
	retf

; Tricorders.
H_0B4C:
	SCRIPT	MSG_USE, IT_MTRICOR, 8, 0, H_0BBF
McCoyScansStephen:
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
	mov	bx, OFFSET T_DEM6_016
	call	Say
	jmp	SHORT L0BBE

T_DEM6_016	LABEL	BYTE
	DB	'#DEM6\DEM6_016#He''s in fine physical and mental condition, Jim.',0
L0BBE:
	retf

H_0BBF:
	SCRIPT	MSG_USE, IT_STRICOR, 25h, 0, H_0C6D
SpockScansGlassware:
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
	mov	bx, OFFSET T_DEM6_009
	call	Say
	jmp	SHORT L0C6C

T_DEM6_009	LABEL	BYTE
	DB	'#DEM6\DEM6_009#Residue of several different compounds are in the'
	DB	' tubes. None of the compounds would explain the sightings.',0
L0C6C:
	retf

H_0C6D:
	SCRIPT	MSG_USE, IT_STRICOR, 9, 0, H_0C75
	jmp	SHORT SpockScansComputer

H_0C75:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_0CFC
SpockScansComputer:
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
	mov	bx, OFFSET T_DEM6_007
	call	Say
	jmp	SHORT L0CFB

T_DEM6_007	LABEL	BYTE
	DB	'#DEM6\DEM6_007#A vintage 801286 of the mid-21st century. It is a'
	DB	' fine museum piece.',0
L0CFB:
	retf

H_0CFC:
	SCRIPT	MSG_USE, IT_STRICOR, IT_MINERAL, 0, H_0D2D
SpockScansMinerals:
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
	mov	bx, OFFSET T_DEM6_013
	call	Say
	retf

H_0D2D:
	SCRIPT	MSG_USE, IT_STRICOR, IT_SHELLS, 0, H_0D5E
SpockScansShells:
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
	mov	bx, OFFSET T_DEM6_021
	call	Say
	retf

H_0D5E:
	SCRIPT	MSG_USE, IT_STRICOR, IT_SKULL, 0, H_0D8F
SpockScansSkull:
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
	mov	bx, OFFSET T_DEM6_012
	call	Say
	retf

H_0D8F:
	SCRIPT	MSG_USE, IT_STRICOR, IT_METAL, 0, H_0DC0
SpockScansMetal:
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
	mov	bx, OFFSET T_DEM6_011
	call	Say
	retf

H_0DC0:
	SCRIPT	MSG_USE, IT_STRICOR, IT_METEOR, 0, H_0DF1
SpockScansMeteorite:
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
	mov	bx, OFFSET T_DEM6_010
	call	Say
	retf

H_0DF1:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_0E22
SpockScansCase:
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
	mov	bx, OFFSET T_DEM6_023
	call	Say
	retf

H_0E22:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_0ECB
SpockScansSynthesizer:
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
	mov	bx, OFFSET T_DEM6_008
	call	Say
	jmp	SHORT L0ECA

T_DEM6_008	LABEL	BYTE
	DB	'#DEM6\DEM6_008#Fascinating, Captain. It is an Ardak-4 molecular '
	DB	'synthesizer. A museum piece in perfect working order.',0
L0ECA:
	retf

; Taking from the case, once it is unlocked: walk there (msg 5), choose
; with the item case, and take what was chosen (taken_items, case_items).
H_0ECB:
	SCRIPT	MSG_GET, 20h, 0, 0, H_0F23
GetFromCase:
	cmp	byte ptr cs:case_open, 1
	je	L0F0E
	mov	ax, 0
	mov	bx, OFFSET T_DEM6N022
	call	Say
	jmp	SHORT L0F0D

T_DEM6N022	LABEL	BYTE
	DB	'#DEM6\DEM6N022#The glass case is locked.',0
L0F0D:
	retf

L0F0E:
	push	5
	push	0BAh
	push	0FFh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 255, 186, 5)
	add	sp, 0Ah
	retf

H_0F23:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, Talk
AtCase:
	mov	al, byte ptr [si+taken_items]
	mov	ah, 0
	AX8	xor, 1Fh
	push	ax
	push	RC_ITEMCASE
	SERVICE		; ItemCase(?)
	add	sp, 4
	AX8	and, 1Fh
	AX8	xor, 1Fh
	mov	byte ptr [si+taken_items], al
	mov	di, OFFSET case_items
L0F48:
	test	al, 1
	je	L0F5E
	push	ax
	sub	ax, ax
	mov	al, byte ptr cs:[di]
	push	ax
	push	RC_GIVEITEM
	SERVICE		; GiveItem(?)
	add	sp, 4
	pop	ax
L0F5E:
	inc	di
	shr	ax, 1
	jne	L0F48
	retf

case_items	LABEL	BYTE	; the item for each bit of taken_items
	DB	59h, 5Dh, 5Ch, 5Bh, 5Ah
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
rdf_objects	LABEL	BYTE
	DW	20h, 6	; id, points
	DW	260,165, 293,155, 315,156, 314,180, 282,198, 254,194
	DW	21h, 4	; id, points
	DW	0,150, 49,150, 49,199, 0,199
	DW	22h, 4	; id, points
	DW	116,161, 204,161, 204,185, 116,185
	DW	23h, 4	; id, points
	DW	260,135, 260,66, 290,60, 290,135
	DW	24h, 4	; id, points
	DW	80,18, 239,18, 238,75, 80,75
	DW	25h, 4	; id, points
	DW	34,149, 88,149, 88,166, 34,166
	DW	26h, 4	; id, points
	DW	132,145, 185,145, 185,159, 132,159
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	132,145, 185,145, 185,159, 132,159
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's0r6l1',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Ensign_Everts	LABEL	BYTE
	DB	'Ensign Everts',0
N_Brother_Stephen	LABEL	BYTE
	DB	'Brother Stephen',0
	DB	'wes',0
S_1077	LABEL	BYTE
	DB	0
T_DEM6_042	LABEL	BYTE
	DB	'#DEM6\DEM6_042#Welcome to my study! Feel free to look around. My'
	DB	' medical and scientific equipment is surely not so sophisticated'
	DB	' as you are accustomed to, but if there is anything you wish to '
	DB	'use, please feel free. Also, I would be interested in anything y'
	DB	'ou might have to show me.',0
T_DEM6N006	LABEL	BYTE
	DB	'#DEM6\DEM6N006#An old-fashioned computer. It appears to have som'
	DB	'e type of simulation running.',0
T_DEM6N003	LABEL	BYTE
	DB	'#DEM6\DEM6N003#A multi-purpose work space, with fine, well-worn '
	DB	'tools and equipment close at hand.',0
T_DEM6N001	LABEL	BYTE
	DB	'#DEM6\DEM6N001#A glass-fronted display of mineral specimens incl'
	DB	'uding a meteorite, a few fossil shells, the skull of a cat-sized'
	DB	' alien animal, and a very encrusted twist of metal.',0
T_DEM6N016	LABEL	BYTE
	DB	'#DEM6\DEM6N016#Pretty rock specimens.',0
T_DEM6N011	LABEL	BYTE
	DB	'#DEM6\DEM6N011#Fossil shells of esthetic interest.',0
T_DEM6N017	LABEL	BYTE
	DB	'#DEM6\DEM6N017#The braincase of a small creature, looking slight'
	DB	'ly insectoid, somewhat reptilian.',0
T_DEM6N005	LABEL	BYTE
	DB	'#DEM6\DEM6N005#An old corroded twist of metal.',0
T_DEM6N000	LABEL	BYTE
	DB	'#DEM6\DEM6N000#A common-looking meteorite, about the size of a f'
	DB	'ist.',0
T_DEM6N002	LABEL	BYTE
	DB	'#DEM6\DEM6N002#A majestic view of Mt. Idyll can be seen through '
	DB	'the skylight.',0
T_DEM6N004	LABEL	BYTE
	DB	'#DEM6\DEM6N004#An antiquated molecular synthesizer sits in the c'
	DB	'orner.',0
T_DEM6N007	LABEL	BYTE
	DB	'#DEM6\DEM6N007#Assorted pieces of glass rest on this table, from'
	DB	' ancient beakers, to double burners.',0
T_DEM6N008	LABEL	BYTE
	DB	'#DEM6\DEM6N008#Captain Kirk wonders what is going to happen on t'
	DB	'his mission.',0
T_DEM6N015	LABEL	BYTE
	DB	'#DEM6\DEM6N015#Mr. Spock finds the scientific equipment in this '
	DB	'room to be rather primitive.',0
T_DEM6N009	LABEL	BYTE
	DB	'#DEM6\DEM6N009#Dr. McCoy is glad that he is in a warm, heated ro'
	DB	'om.',0
T_DEM6N010	LABEL	BYTE
	DB	'#DEM6\DEM6N010#Ensign Everts finds himself fascinated by the Aco'
	DB	'lytes and their planet.',0
T_DEM6N020	LABEL	BYTE
	DB	'#DEM6\DEM6N020#You tinker with it but do nothing significant.',0
T_DEM6_024	LABEL	BYTE
	DB	'#DEM6\DEM6_024#This machinery is delicate but I have managed to '
	DB	'repair the circuitry.',0
	DB	'#DEM6\DEM6_022#I feel like this is delicate as surgery, Captain,'
	DB	' but I''ve got it back in working order now.',0
T_DEM6N018	LABEL	BYTE
	DB	'#DEM6\DEM6N018#The mechanism in the hand has already been repair'
	DB	'ed.',0
T_DEM6N012	LABEL	BYTE
	DB	'#DEM6\DEM6N012#It is locked.',0
T_DEM6_019	LABEL	BYTE
	DB	'#DEM6\DEM6_019#I think we should wait and talk to the owner when'
	DB	' he comes back, Jim.',0
	DB	'#DEM6\DEM6N013#It opens.',0
T_DEM6_044	LABEL	BYTE
	DB	'#DEM6\DEM6_044#You are interested in my little museum of curiosi'
	DB	'ties?',0
T_DEM6_001	LABEL	BYTE
	DB	'#DEM6\DEM6_001#Looks like a pile of junk if you ask me.',0
T_DEM6_006	LABEL	BYTE
	DB	'#DEM6\DEM6_006#Yes, tell us about these things.',0
T_DEM6_003	LABEL	BYTE
	DB	'#DEM6\DEM6_003#Where did you find all this?',0
T_DEM6_030	LABEL	BYTE
	DB	'#DEM6\DEM6_030#Everything of this world is secondary to the perf'
	DB	'ection of the next, Captain.',0
T_DEM6_031	LABEL	BYTE
	DB	'#DEM6\DEM6_031#Here and there.  Much of it was brought to me by '
	DB	'others exploring widely.',0
T_DEM6_034	LABEL	BYTE
	DB	'#DEM6\DEM6_034#I enjoy talking about these treasures.',0
T_DEM6_051	LABEL	BYTE
	DB	'#DEM6\DEM6_051#Shall I go into...',0
T_DEM6_045	LABEL	BYTE
	DB	'#DEM6\DEM6_045#Mineral Specimens,',0
T_DEM6_046	LABEL	BYTE
	DB	'#DEM6\DEM6_046#Meteorite,',0
T_DEM6_047	LABEL	BYTE
	DB	'#DEM6\DEM6_047#Fossil Shells,',0
T_DEM6_048	LABEL	BYTE
	DB	'#DEM6\DEM6_048#Skull of a small alien animal,',0
T_DEM6_049	LABEL	BYTE
	DB	'#DEM6\DEM6_049#Twist of Metal,',0
T_DEM6_050	LABEL	BYTE
	DB	'#DEM6\DEM6_050#or would you rather move on to something else?',0
T_DEM6_039	LABEL	BYTE
	DB	'#DEM6\DEM6_039#This chunk of rock is a greatly weathered example'
	DB	' of a vanadium-tungsten alloy -- which doesn''t occur naturally. '
	DB	' It is my best evidence that the area was previously inhabited.',0
T_DEM6_040	LABEL	BYTE
	DB	'#DEM6\DEM6_040#True curiosities, nothing more.  I think they''re '
	DB	'very pretty, don''t you?',0
T_DEM6_036	LABEL	BYTE
	DB	'#DEM6\DEM6_036#One of the oldest forms I''ve seen on this planet.'
	DB	' Our God makes beautiful things, indeed.',0
T_DEM6_038	LABEL	BYTE
	DB	'#DEM6\DEM6_038#The skull of a modern siloti, the largest creatur'
	DB	'e native to this planet, about the size of a housecat from Earth'
	DB	'.  The silotis combine a rather insectoid pattern with four-legg'
	DB	'ed reptilian form including praying mantis-like forelimbs.',0
T_DEM6_041	LABEL	BYTE
	DB	'#DEM6\DEM6_041#Very well.  I can''t imagine why, but if you have '
	DB	'a further interest in any of this, take what you like.  But plea'
	DB	'se remember to return my treasures when you are done with them.',0
T_DEM6_033	LABEL	BYTE
	DB	'#DEM6\DEM6_033#I believe this is evidence of the cataclysm which'
	DB	' destroyed the moon of Pollux V eons past. I''ve constructed a th'
	DB	'eoretical model based on analysis of the planet''s ring of what t'
	DB	'hings might have been like. I think that the moon, like Earth''s '
	DB	'moon, would have made a total eclipse of the sun possible. I wou'
	DB	'ld have liked to have seen that, for conditions making a perfect'
	DB	' total eclipse are rare in the Universe. Our God creates great w'
	DB	'onders.',0
S_2016	LABEL	BYTE
	DB	'There is a dialog error here.',0
T_DEM6_014	LABEL	BYTE
	DB	'#DEM6\DEM6_014#Captain, this appears to be a model of the Earth.'
	DB	' Notice how it models the proper situation for a total eclipse?',0
T_DEM6N019	LABEL	BYTE
	DB	'#DEM6\DEM6N019#The old man carefully returns the items to his ca'
	DB	'binet.',0
T_DEM6_029	LABEL	BYTE
	DB	'#DEM6\DEM6_029#Bless you for returning my things.',0
T_DEM6_043	LABEL	BYTE
	DB	'#DEM6\DEM6_043#What a fascinating piece of equipment!  Highly ad'
	DB	'vanced technology.  You see here, it seems to have been damaged,'
	DB	' however.  Take it to my workbench and let''s see if it can be re'
	DB	'paired.  I fear my hands are too shaky to perform such fine work'
	DB	', but perhaps one of you can do it.',0
T_DEM6_037	LABEL	BYTE
	DB	'#DEM6\DEM6_037#See how the fingertips have microsized sensors? I'
	DB	' wonder what use they may have.',0
	DB	'#DEM6\DEM6_032#How interesting!  Praise God for this opportunity'
	DB	'. He brings me through you.',0
T_DEM6_020	LABEL	BYTE
	DB	'#DEM6\DEM6_020#This place looks real comfortable, a place to com'
	DB	'bine work and contemplation.  The man''s got an eye for the beaut'
	DB	'y of useful things, and the use of beautiful things.  I think we'
	DB	' could get along fine.',0
T_DEM6_025	LABEL	BYTE
	DB	'#DEM6\DEM6_025#This study represents a man with a keen mind, Cap'
	DB	'tain.  To judge by what I see, there is little which does not in'
	DB	'terest him.  The equipment is antiquated, but practical.',0
T_DEM6_002	LABEL	BYTE
	DB	'#DEM6\DEM6_002#Well, what happens next?',0
T_DEM6_053	LABEL	BYTE
	DB	'#DEM6\DEM6_053#I wonder if any of this stuff might be useful.',0
T_DEM6_035	LABEL	BYTE
	DB	'#DEM6\DEM6_035#I never dreamed that Starfleet would be intereste'
	DB	'd in my discoveries, Captain, but our God often surprises us.',0
T_DEM6_013	LABEL	BYTE
	DB	'#DEM6\DEM6_013#A variety of rock specimens, including native sil'
	DB	'ver, azurite, crystalline forms of various minerals.',0
T_DEM6_021	LABEL	BYTE
	DB	'#DEM6\DEM6_021#Fossil shells in limestone substrate, compatible '
	DB	'with local geologic features.',0
T_DEM6_012	LABEL	BYTE
	DB	'#DEM6\DEM6_012#A sample of a local lifeform called a siloti, the'
	DB	' largest animal reported on this planet.  About the size of an E'
	DB	'arth housecat, the silotis have an insectoid-reptilian genotype '
	DB	'with praying mantis like forelimbs.',0
T_DEM6_011	LABEL	BYTE
	DB	'#DEM6\DEM6_011#A manufactured vanadium-tungsten alloy of conside'
	DB	'rable age and indeterminate use.',0
T_DEM6_010	LABEL	BYTE
	DB	'#DEM6\DEM6_010#A completely ordinary nickel-iron meteorite.',0
T_DEM6_023	LABEL	BYTE
	DB	'#DEM6\DEM6_023#I read a collection of small items of no evident '
	DB	'value.  I would characterize this as a small museum display, Cap'
	DB	'tain.',0
	DB	'There is a take error here.',0
	DB	'#DEM6\DEM6N014#It opens.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0
KirkOnCollection	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_DEM6_001, OFFSET T_DEM6_006, OFFSET T_DEM6_003, 0	; speaker, choices, 0
KirkOnFinds	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_DEM6_001, OFFSET T_DEM6_006, 0	; speaker, choices, 0
KirkAsksAbout	LABEL	BYTE
	DW	OFFSET N_Brother_Stephen, OFFSET T_DEM6_045, OFFSET T_DEM6_046, OFFSET T_DEM6_047, OFFSET T_DEM6_048, OFFSET T_DEM6_049, OFFSET T_DEM6_050, 0	; speaker, choices, 0

RDF	ENDS
	END
