; VENG7.RDF - "Vengeance", the corridor outside the Republic's
; transporter room (room 8). A length of power cable lies here, under a
; coolant exhaust port fallen through the ceiling.
;
; Actors: 8 the cable, 9 a body, 0Ah (10) the door. Objects: those, 20h
; the door, 21h the exhaust port. Exit 1: the turbolift.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 0FA7: the engine reads its bytes
;   as key 50 B8 03 00 and next 2E50 (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
enterprise_away	EQU	RS_VARS+0Dh	; the Enterprise has left to follow the distress call (room 0)
hypo_oiled	EQU	RS_VARS+11h	; the hypo holds oil (room 6)
power_to	EQU	RS_VARS+13h	; impulse power: 1 weapons, 2 shields, 3 transporter (room 2)
rescued	EQU	RS_VARS+19h	; the Enterprise is back: the Elasi threats are over
elasi_here	EQU	RS_VARS+1Ah	; the Elasi ship has arrived and jams the communicators
complied	EQU	RS_VARS+1Ch	; Kirk has agreed to the Elasi's terms
board_timer	EQU	RS_VARS+20h	; word: until the Elasi board, unless the shields are up
stall_timer	EQU	RS_VARS+22h	; word: the thirty minutes
comply_timer	EQU	RS_VARS+24h	; word: until the Elasi lose patience after Kirk complies
torpedo_timer	EQU	RS_VARS+26h	; word: until their torpedoes
attack_timer	EQU	RS_VARS+28h	; word: after the Elasi lower their shields
cable_taken	EQU	RS_VARS+35h	; Kirk has taken the power cable

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0A8h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	6Bh
rdf_scale_min	LABEL	BYTE
	DW	0A0h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, 9, -1, 8	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	0,0, 0,0	; entrance 0, crew 0
	DW	0,0, 0,0	; entrance 0, crew 1
	DW	0,0, 0,0	; entrance 0, crew 2
	DW	0,0, 0,0	; entrance 0, crew 3
	DW	154,173, 156,162	; entrance 1, crew 0
	DW	154,173, 140,170	; entrance 1, crew 1
	DW	154,173, 185,170	; entrance 1, crew 2
	DW	154,173, 166,178	; entrance 1, crew 3
	DW	0,0, 0,0	; entrance 2, crew 0
	DW	0,0, 0,0	; entrance 2, crew 1
	DW	0,0, 0,0	; entrance 2, crew 2
	DW	0,0, 0,0	; entrance 2, crew 3
	DW	89,117, 113,124	; entrance 3, crew 0
	DW	89,117, 100,128	; entrance 3, crew 1
	DW	89,117, 111,114	; entrance 3, crew 2
	DW	89,117, 94,118	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0

rdf_scripts:
; The room starts: the door, the cable.
H_00CA:
	SCRIPT	MSG_TICK, 1, 0, 0, H_014F
StartRoom:
	jmp	SHORT L00DB

N_VEN7LOOP	LABEL	BYTE
	DB	'VEN7LOOP',0
L00DB:
	push	OFFSET N_VEN7LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("VEN7LOOP")
	add	sp, 4
	jmp	SHORT L00F4

N_s7r7d1c	LABEL	BYTE
	DB	's7r7d1c',0
L00F4:
	push	0
	push	72h
	push	59h
	push	OFFSET N_s7r7d1c
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s7r7d1c", 89, 114, 0)
	add	sp, 0Ch
	cmp	byte ptr [si+cable_taken], 1
	je	L012F
	jmp	SHORT L0118

N_s7r7ca	LABEL	BYTE
	DB	's7r7ca',0
L0118:
	push	0
	push	8Ah
	push	0ACh
	push	OFFSET N_s7r7ca
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s7r7ca", 172, 138, 0)
	add	sp, 0Ch
L012F:
	jmp	SHORT L0138

N_s7r7c1	LABEL	BYTE
	DB	's7r7c1',0
L0138:
	push	0
	push	49h
	push	0A6h
	push	OFFSET N_s7r7c1
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s7r7c1", 166, 73, 0)
	add	sp, 0Ch
	retf

; Walking into the transporter room (msg 2, anim msg 1; room 8).
H_014F:
	SCRIPT	MSG_WALK, 0Ah, 0, 0, H_0157
	jmp	SHORT WalkToDoor

H_0157:
	SCRIPT	MSG_WALK, 20h, 0, 0, H_017A
WalkToDoor:
	mov	ax, 2
	push	ax
	mov	ax, 76h
	push	ax
	mov	ax, 66h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 102, 118, 2)
	add	sp, 0Ah
	retf

H_017A:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_01B3
AtDoor:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	jmp	SHORT L019D

N_s7r7d1	LABEL	BYTE
	DB	's7r7d1',0
L019D:
	push	1
	push	72h
	push	59h
	push	OFFSET N_s7r7d1
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s7r7d1", 89, 114, 1)
	add	sp, 0Ch
	retf

H_01B3:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_01D6
DoorOpened:
	mov	ax, 0
	push	ax
	mov	ax, 76h
	push	ax
	mov	ax, 5Bh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 91, 118, 0)
	add	sp, 0Ah
	retf

; Exit 1: the turbolift.
H_01D6:
	SCRIPT	MSG_EXIT, 1, 0, 0, H_01FB
ToTurbolift:
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	push	1
	push	7
	push	RC_TURBOLIFT
	SERVICE		; Turbolift(7, 1)
	add	sp, 6
	retf

; Looking.
H_01FB:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_02B3
LookAtExhaust:
	mov	ax, 0
	mov	bx, OFFSET T_VEN7N001
	call	Say
	JMPN	L02B2

T_VEN7N001	LABEL	BYTE
	DB	'#VEN7\VEN7N001#A large piece of equipment has fallen through the'
	DB	' ceiling. The area looks extremely unstable. fortunately, the en'
	DB	'try to the transporter room is near.',0
L02B2:
	retf

H_02B3:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_02E6
LookAtBody:
	mov	ax, 0
	mov	bx, OFFSET T_VEN0N016
	call	Say
	jmp	SHORT L02E5

T_VEN0N016	LABEL	BYTE
	DB	'#VEN0\VEN0N016#This man is dead.',0
L02E5:
	retf

H_02E6:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_02EE
	jmp	SHORT LookAtDoor

H_02EE:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_0338
LookAtDoor:
	mov	ax, 0
	mov	bx, OFFSET T_VEN7N007
	call	Say
	jmp	SHORT L0337

T_VEN7N007	LABEL	BYTE
	DB	'#VEN7\VEN7N007#This door leads to the transporter room.',0
L0337:
	retf

H_0338:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_038F
LookAtCable:
	mov	ax, 0
	mov	bx, OFFSET T_VEN7N008
	call	Say
	jmp	SHORT L038E

T_VEN7N008	LABEL	BYTE
	DB	'#VEN7\VEN7N008#This is a length of heavy duty insulated power ca'
	DB	'ble.',0
L038E:
	retf

H_038F:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_03BF
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_VEN7N003
	call	Say
	jmp	SHORT L03BE

T_VEN7N003	LABEL	BYTE
	DB	'#VEN7\VEN7N003#James T. Kirk.',0
L03BE:
	retf

H_03BF:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_03EE
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_VEN7N005
	call	Say
	jmp	SHORT L03ED

T_VEN7N005	LABEL	BYTE
	DB	'#VEN7\VEN7N005#Mister Spock.',0
L03ED:
	retf

H_03EE:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_041E
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_VEN7N004
	call	Say
	jmp	SHORT L041D

T_VEN7N004	LABEL	BYTE
	DB	'#VEN7\VEN7N004#Leonard McCoy.',0
L041D:
	retf

H_041E:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_044C
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_VEN7N002
	call	Say
	jmp	SHORT L044B

T_VEN7N002	LABEL	BYTE
	DB	'#VEN7\VEN7N002#Ensign Kije.',0
L044B:
	retf

H_044C:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_049A
LookAtCorridor:
	mov	ax, 0
	mov	bx, OFFSET T_VEN7N006
	call	Say
	jmp	SHORT L0499

T_VEN7N006	LABEL	BYTE
	DB	'#VEN7\VEN7N006#This corridor leads to the transporter room.',0
L0499:
	retf

H_049A:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0517
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN7_001
	call	Say
	jmp	SHORT L0516

T_VEN7_001	LABEL	BYTE
	DB	'#VEN7\VEN7_001#I haven''t seen anything this bad since I was aboa'
	DB	'rd the Farragut, and this vampire cloud...',0
L0516:
	retf

H_0517:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_05A3
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN7_005
	call	Say
	jmp	SHORT L05A2

T_VEN7_005	LABEL	BYTE
	DB	'#VEN7\VEN7_005#I do not see the need for conversation, Captain. '
	DB	'Humans have an irrational enjoyment of endless discourse.',0
L05A2:
	retf

H_05A3:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0617
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN1_004
	call	Say
	jmp	SHORT L0616

T_VEN1_004	LABEL	BYTE
	DB	'#VEN1\VEN1_004#I''d like to meet the people responsible for this '
	DB	'and give them a piece of my mind.',0
L0616:
	retf

H_0617:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_066A
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN7_007
	call	Say
	jmp	SHORT L0669

T_VEN7_007	LABEL	BYTE
	DB	'#VEN7\VEN7_007#It does get better than this, doesn''t it Captain?',0
L0669:
	retf

H_066A:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_075D
SpockScansExhaust:
	jmp	SHORT L0679

N_sscans	LABEL	BYTE
	DB	'sscans',0
L0679:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscans
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
	mov	bx, OFFSET T_VEN7_006
	call	Say
	JMPN	L075C

T_VEN7_006	LABEL	BYTE
	DB	'#VEN7\VEN7_006#It appears to be a section from a coolant exhaust'
	DB	' port. I would not recommend too close of an inspection, Captain'
	DB	'. The floor could collapse from our added weight.',0
L075C:
	retf

; Region 0, the fallen exhaust port: Spock warns Kirk off.
H_075D:
	SCRIPT	MSG_REGION, 0, 0, 0, H_07EC
NearFloor:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN7_003
	call	Say
	jmp	SHORT L07EB

T_VEN7_003	LABEL	BYTE
	DB	'#VEN7\VEN7_003#Captain, please be careful. The floor in that are'
	DB	'a is very unstable and might collapse from our added weight.',0
L07EB:
	retf

; Taking the cable (msgs 3, 4).
H_07EC:
	SCRIPT	MSG_GET, 8, 0, 0, H_0813
GetCable:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 3
	push	ax
	mov	ax, 8Bh
	push	ax
	mov	ax, 0ACh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 172, 139, 3)
	add	sp, 0Ah
	retf

H_0813:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_0850
KirkAtCable:
	jmp	SHORT L0822

N_kusehn	LABEL	BYTE
	DB	'kusehn',0
L0822:
	push	4
	push	-1
	push	-1
	push	OFFSET N_kusehn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 4)
	add	sp, 0Ch
	jmp	SHORT L0840

N_MUR4E6	LABEL	BYTE
	DB	'MUR4E6',0
L0840:
	push	OFFSET N_MUR4E6
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR4E6")
	add	sp, 4
	retf

H_0850:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_08B8
TookCable:
	mov	ax, 8
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(8)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_VEN7N009
	call	Say
	jmp	SHORT L089F

T_VEN7N009	LABEL	BYTE
	DB	'#VEN7\VEN7N009#You pick up a length of cable.',0
L089F:
	mov	ax, IT_CABLE1
	push	ax
	mov	ax, RC_GIVEITEM
	push	ax
	SERVICE		; GiveItem(IT_CABLE1)
	add	sp, 4
	mov	byte ptr [si+cable_taken], 1
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Every tick, common to the mission's rooms: the Elasi deadlines set on
; the bridge (room 2). Until the Enterprise returns: boarding unless the
; shields are up, the thirty minutes, the wait after Kirk complies (then
; a warning and the torpedoes), the chance after they lower their
; shields. When one runs out, the game is over.
H_08B8:
	SCRIPT	MSG_TICK, ANY, ANY, ANY, H_0ADC
ElasiDeadlines:
	cmp	word ptr [si+board_timer], 0
	je	L08D2
	dec	word ptr [si+board_timer]
	jne	L08D2
	cmp	byte ptr [si+power_to], 2
	je	L08D2
	JMPN	L09D2

L08D2:
	cmp	word ptr [si+stall_timer], 0
	je	L08E6
	dec	word ptr [si+stall_timer]
	jne	L08E6
	cmp	byte ptr [si+complied], 1
	je	L08E6
	JMPN	L09D2

L08E6:
	cmp	word ptr [si+comply_timer], 0
	je	L0945
	dec	word ptr [si+comply_timer]
	jne	L0945
	cmp	byte ptr [si+rescued], 1
	je	L0945
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_098
	call	Say
	jmp	SHORT L0940

T_VEN2_098	LABEL	BYTE
	DB	'#VEN2\VEN2_098#What are you stalling for? Lower your shields.',0
L0940:
	mov	word ptr [si+torpedo_timer], 0A8Ch
L0945:
	cmp	word ptr [si+torpedo_timer], 0
	je	L09BE
	dec	word ptr [si+torpedo_timer]
	jne	L09BE
	cmp	byte ptr [si+rescued], 1
	je	L09BE
	mov	ax, 0
	mov	bx, OFFSET T_VENA_F40
	call	Say
	jmp	SHORT L09B2

T_VENA_F40	LABEL	BYTE
	DB	'#VENA\VENA_F40#The Elasi fire photon torpedoes. The Republic has'
	DB	' been destroyed.',0
L09B2:
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
L09BE:
	cmp	word ptr [si+attack_timer], 0
	je	L09D1
	dec	word ptr [si+attack_timer]
	jne	L09D1
	cmp	byte ptr [si+rescued], 1
	je	L09D1
	jmp	SHORT L09D2

L09D1:
	retf

L09D2:
	mov	ax, 0
	mov	bx, OFFSET T_VENA_F32
	call	Say
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
	retf

T_VENA_F32	LABEL	BYTE
	DB	'#VENA\VENA_F32#The landing party has been taken captive by the E'
	DB	'lasi, and you know Starfleet does not negotiate with terrorists.'
	DB	' As you look forward to a long captivity you wonder who will tak'
	DB	'e command of the Enterprise. Better luck next time.',0

H_0ADC:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_0AE4
	jmp	SHORT KillAnything

H_0AE4:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_0B79
KillAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VENA_F34
	call	Say
	JMPN	L0B78

T_VENA_F34	LABEL	BYTE
	DB	'#VENA\VENA_F34#Captain, it would be unwise to use your phaser co'
	DB	'nsidering the already extensive damage sustained by the Republic'
	DB	'.',0
L0B78:
	retf

; The hypo, empty or full of oil.
H_0B79:
	SCRIPT	MSG_LOOK, IT_HYPO, 0, 0, H_0C0F
LookAtHypo:
	cmp	byte ptr [si+hypo_oiled], 1
	je	L0BC6
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N010
	call	Say
	jmp	SHORT L0BC5

T_VEN4N010	LABEL	BYTE
	DB	'#VEN4\VEN4N010#This is an empty hypodermic injector.',0
L0BC5:
	retf

L0BC6:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N007
	call	Say
	jmp	SHORT L0C0E

T_VEN6N007	LABEL	BYTE
	DB	'#VEN6\VEN6N007#The hypo is now filled with multipurpose oil.',0
L0C0E:
	retf

; The communicator: before the Enterprise leaves, Uhura; while the Elasi
; jam it, Spock; otherwise Uhura, tracking the distress call.
H_0C0F:
	SCRIPT	MSG_USE, IT_COMM, OBJ_KIRK, 0, H_0E14
CallEnterprise:
	cmp	byte ptr [si+enterprise_away], 1
	je	L0C97
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018
	call	Say
	jmp	SHORT L0C60

T_MUD4_018	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L0C60:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146
	call	Say
	jmp	SHORT L0C96

T_BRIDU146	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L0C96:
	retf

L0C97:
	cmp	byte ptr [si+elasi_here], 1
	jne	L0CA0
	JMPN	L0D9D

L0CA0:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_2
	call	Say
	jmp	SHORT L0CE4

T_MUD4_018_2	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise, Kirk to Enterprise...',0
L0CE4:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_VEN2U093
	call	Say
	jmp	SHORT L0D4F

T_VEN2U093	LABEL	BYTE
	DB	'#VEN2\VEN2U093#Enterprise here. We''re still tracking the distres'
	DB	's call. Are you all right, Sir?',0
L0D4F:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_028
	call	Say
	jmp	SHORT L0D9C

T_VEN2_028	LABEL	BYTE
	DB	'#VEN2\VEN2_028#Yes, Uhura. Just wanted a status report. Kirk out'
	DB	'.',0
L0D9C:
	retf

L0D9D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_066
	call	Say
	jmp	SHORT L0E11

T_VEN2_066	LABEL	BYTE
	DB	'#VEN2\VEN2_066#They are jamming all frequencies, Captain. We wil'
	DB	'l not be able to contact the Enterprise.',0
L0E11:
	retf

; In the room file, so these start again each time the room loads
mccoy_line	LABEL	BYTE	; which of McCoy's lines
	DB	0, 0

; McCoy and the body.
H_0E14:
	SCRIPT	MSG_USE, IT_MEDKIT, 9, 0, H_0E1C
	jmp	SHORT MTricorderOnBody

H_0E1C:
	SCRIPT	MSG_USE, IT_MTRICOR, 9, 0, H_0E24
MTricorderOnBody:
	jmp	SHORT McCoyOnBody

H_0E24:
	SCRIPT	MSG_USE, OBJ_MCCOY, 9, 0, Talk
McCoyOnBody:
	push	5
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 5)
	add	sp, 6
	mov	word ptr cs:mccoy_line, ax
	cmp	word ptr cs:mccoy_line, 0
	jne	L0E6F
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_019
	call	Say
	jmp	SHORT L0E6E

T_DEM3_019	LABEL	BYTE
	DB	'#DEM3\DEM3_019#He''s dead, jim.',0
L0E6E:
	retf

L0E6F:
	cmp	word ptr cs:mccoy_line, 1
	jne	L0EB7
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN4_016
	call	Say
	jmp	SHORT L0EB6

T_VEN4_016	LABEL	BYTE
	DB	'#VEN4\VEN4_016#Jim...there''s nothing more I can do.',0
L0EB6:
	retf

L0EB7:
	cmp	word ptr cs:mccoy_line, 2
	jne	L0EF0
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_G_014
	call	Say
	jmp	SHORT L0EEF

T_G_014	LABEL	BYTE
	DB	'#GENE\G_014#This person''s dead, Jim.',0
L0EEF:
	retf

L0EF0:
	cmp	word ptr cs:mccoy_line, 3
	jne	L0F29
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_G_014_2
	call	Say
	jmp	SHORT L0F28

T_G_014_2	LABEL	BYTE
	DB	'#GENE\G_014#This person''s dead, Jim.',0
L0F28:
	retf

L0F29:
	cmp	word ptr cs:mccoy_line, 4
	jne	L0F6C
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_016
	call	Say
	jmp	SHORT L0F6B

T_VEN0_016	LABEL	BYTE
	DB	'#VEN0\VEN0_016#They''re dead, Jim. All of them.',0
L0F6B:
	retf

L0F6C:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_016_2
	call	Say
	jmp	SHORT L0FA6

T_VEN0_016_2	LABEL	BYTE
	DB	'#VEN0\VEN0_016#They''re dead, Jim. All of them.',0
L0FA6:
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
rdf_objects	LABEL	BYTE
	DW	20h, 4	; id, points
	DW	85,64, 91,68, 91,114, 85,112
	DW	21h, 4	; id, points
	DW	120,42, 193,42, 193,114, 120,114
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	1, 4	; id, points
	DW	67,166, 253,166, 253,172, 67,172
	DW	3, 4	; id, points
	DW	90,115, 97,115, 90,122, 82,122
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	96,108, 198,108, 198,116, 96,116
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's7r7',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Ensign_Kije	LABEL	BYTE
	DB	'Ensign Kije',0
N_Elasi_Captain	LABEL	BYTE
	DB	'Elasi Captain',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
