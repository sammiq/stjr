; LOVE4.RDF - "Love's Labor Jeopardized", the station's crew quarters,
; on the deck the Romulans took. The virus has floored them (or the
; Romulan laughing gas has); McCoy can cure all four with the cure from
; room 2, and water helps their dehydration.
;
; Actors: 8 the door, 9-12 (0Ch) the Romulans.
; Objects: 8/20h the door (room 5), 9-0Ch the Romulans, 21h the ladder up
; to the lab (room 1). Region 0: the doorstep.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The communicator's four cases (CallEnterprise) all play the same
;   placeholder lines, recorded for other missions.
; - Watering the Romulans gives its point every time: gave_water is set to
;   2 but tested against 1.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
have_research	EQU	RS_VARS+1	; McCoy has Dr. Marcus' research on the virus (room 0)
romulans_out	EQU	RS_VARS+2	; the Romulan laughing gas has put the Romulans out (room 3)
n2o_released	EQU	RS_VARS+3	; laughing gas: the crew laugh (timer 0)
rlg_released	EQU	RS_VARS+4	; Romulan laughing gas: Spock laughs (timer 1)
been_below	EQU	RS_VARS+16h	; the party has been here
romulans_cured	EQU	RS_VARS+17h
virus_struck	EQU	RS_VARS+18h	; the virus has floored Spock, and the Romulans below
virus	EQU	RS_VARS+1Ch	; Spock's infection: 3Ch he collapses, 64h he dies
spock_cured	EQU	RS_VARS+1Dh
called_ship	EQU	RS_VARS+1Eh	; Kirk has called the Enterprise
called_ship_cured	EQU	RS_VARS+1Fh	; the same, after the cure
made_cure	EQU	RS_VARS+26h	; the cure has been synthesized (room 2)
gave_water	EQU	RS_VARS+28h	; set to 2, but tested against 1 (see the quirks)
score	EQU	RS_VARS+29h	; word: the mission's score

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0C7h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	0A2h
rdf_scale_min	LABEL	BYTE
	DW	0E6h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	0ECh
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	5, -1, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	146,154, 157,179	; entrance 0, crew 0
	DW	146,154, 107,178	; entrance 0, crew 1
	DW	146,154, 188,165	; entrance 0, crew 2
	DW	146,154, 124,188	; entrance 0, crew 3
	DW	0,0, 0,0	; entrance 1, crew 0
	DW	0,0, 0,0	; entrance 1, crew 1
	DW	0,0, 0,0	; entrance 1, crew 2
	DW	0,0, 0,0	; entrance 1, crew 3
	DW	0,0, 0,0	; entrance 2, crew 0
	DW	0,0, 0,0	; entrance 2, crew 1
	DW	0,0, 0,0	; entrance 2, crew 2
	DW	0,0, 0,0	; entrance 2, crew 3
	DW	249,172, 220,193	; entrance 3, crew 0
	DW	249,172, 224,187	; entrance 3, crew 1
	DW	249,172, 272,177	; entrance 3, crew 2
	DW	249,172, 243,175	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	249,182, 260,175, 233,174, 248,163
; In the room file, so these start again each time the room loads
watered	LABEL	BYTE	; the Romulans have had water this visit
	DB	0
door_steps	LABEL	BYTE	; the walk and the door both done at 2
	DB	0
going_door	LABEL	BYTE
	DB	0
laugher	LABEL	BYTE	; word: the name of who giggles
	DB	0, 0
roll	LABEL	BYTE	; word: a random number
	DB	0, 0
N_s3r5d1	LABEL	BYTE
	DB	's3r5d1',0
N_s3r5d1a	LABEL	BYTE
	DB	's3r5d1a',0
N_s3r5r1	LABEL	BYTE
	DB	's3r5r1',0
N_s3r5r2	LABEL	BYTE
	DB	's3r5r2',0
N_s3r5r3	LABEL	BYTE
	DB	's3r5r3',0
N_s3r5r4	LABEL	BYTE
	DB	's3r5r4',0
N_s3r5r1a	LABEL	BYTE
	DB	's3r5r1a',0
N_s3r5r2a	LABEL	BYTE
	DB	's3r5r2a',0
N_s3r5r3a	LABEL	BYTE
	DB	's3r5r3a',0
N_s3r5r4a	LABEL	BYTE
	DB	's3r5r4a',0
N_s3r5r1b	LABEL	BYTE
	DB	's3r5r1b',0
N_s3r5r2b	LABEL	BYTE
	DB	's3r5r2b',0
N_s3r5r3b	LABEL	BYTE
	DB	's3r5r3b',0
N_s3r5r4b	LABEL	BYTE
	DB	's3r5r4b',0
N_musele	LABEL	BYTE
	DB	'musele',0
N_museme	LABEL	BYTE
	DB	'museme',0
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_mscans	LABEL	BYTE
	DB	'mscans',0

rdf_scripts:
; The room starts: the four Romulans, sick or cured.
H_0158:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0290
StartRoom:
	jmp	SHORT L0169

N_LOV4LOOP	LABEL	BYTE
	DB	'LOV4LOOP',0
L0169:
	push	OFFSET N_LOV4LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("LOV4LOOP")
	add	sp, 4
	cmp	byte ptr [si+romulans_cured], 1
	jne	L01DB
	push	0
	push	0B3h
	push	36h
	push	OFFSET N_s3r5r1b
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s3r5r1b", 54, 179, 0)
	add	sp, 0Ch
	push	0
	push	0BBh
	push	0B9h
	push	OFFSET N_s3r5r2b
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s3r5r2b", 185, 187, 0)
	add	sp, 0Ch
	push	0
	push	0C4h
	push	0EFh
	push	OFFSET N_s3r5r3b
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s3r5r3b", 239, 196, 0)
	add	sp, 0Ch
	push	0
	push	0AAh
	push	12Ah
	push	OFFSET N_s3r5r4b
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s3r5r4b", 298, 170, 0)
	add	sp, 0Ch
	jmp	SHORT L0236

L01DB:
	push	0
	push	0B3h
	push	36h
	push	OFFSET N_s3r5r1a
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s3r5r1a", 54, 179, 0)
	add	sp, 0Ch
	push	0
	push	0BBh
	push	0B9h
	push	OFFSET N_s3r5r2a
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s3r5r2a", 185, 187, 0)
	add	sp, 0Ch
	push	0
	push	0C4h
	push	0EFh
	push	OFFSET N_s3r5r3a
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s3r5r3a", 239, 196, 0)
	add	sp, 0Ch
	push	0
	push	0AAh
	push	12Ah
	push	OFFSET N_s3r5r4a
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s3r5r4a", 298, 170, 0)
	add	sp, 0Ch
L0236:
	cmp	byte ptr [si+n2o_released], 1
	jne	L024E
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS], ax
L024E:
	cmp	byte ptr [si+rlg_released], 1
	jne	L0267
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS+2], ax
L0267:
	mov	word ptr [si+RS_TIMERS+4], 0C8h
	push	0
	push	99h
	push	90h
	push	OFFSET N_s3r5d1a
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s3r5d1a", 144, 153, 0)
	add	sp, 0Ch
	mov	byte ptr cs:cure_x, 6Bh
	mov	byte ptr cs:cure_y, -4Eh
	retf

; Tick 10: the music, the first time.
H_0290:
	SCRIPT	MSG_TICK, 0Ah, 0, 0, H_02AF
FirstVisit:
	cmp	byte ptr [si+been_below], 1
	je	L02AE
	push	-1
	push	1
	push	RC_MUSIC
	SERVICE		; Music(1, -1)
	add	sp, 6
	mov	byte ptr [si+been_below], 1
L02AE:
	retf

; The door to room 5 (msg 1, anim msg 1).
H_02AF:
	SCRIPT	MSG_WALK, 8, 0, 0, H_02B7
	jmp	SHORT WalkToDoor

H_02B7:
	SCRIPT	MSG_WALK, 20h, 0, 0, H_02E0
WalkToDoor:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr cs:going_door, 1
	push	1
	push	9Ch
	push	91h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 145, 156, 1)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL], 0
	retf

H_02E0:
	SCRIPT	MSG_REGION, 0, 0, 0, H_0312
ReachDoor:
	cmp	byte ptr cs:going_door, 1
	jne	L0311
	push	1
	push	99h
	push	90h
	push	OFFSET N_s3r5d1
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s3r5d1", 144, 153, 1)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
L0311:
	retf

H_0312:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_031A
	jmp	SHORT ThroughDoor

H_031A:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_033D
ThroughDoor:
	inc	byte ptr cs:door_steps
	cmp	byte ptr cs:door_steps, 2
	je	L032E
	retf

L032E:
	push	1
	push	5
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(5, 1)
	add	sp, 6
	retf

; The ladder back up to the lab (msg 2).
H_033D:
	SCRIPT	MSG_USE, OBJ_KIRK, 21h, 0, H_0358
ClimbLadder:
	push	2
	push	0ACh
	push	0F6h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 246, 172, 2)
	add	sp, 0Ah
	retf

H_0358:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_036D
AtLadder:
	push	2
	push	1
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(1, 2)
	add	sp, 6
	retf

; Phasers on the Romulans.
H_036D:
	SCRIPT	MSG_USE, IT_PHASERS, 9, 0, H_0375
	jmp	SHORT PhaserRomulan2

H_0375:
	SCRIPT	MSG_USE, IT_PHASERS, 0Ah, 0, H_037D
PhaserRomulan2:
	jmp	SHORT PhaserRomulan3

H_037D:
	SCRIPT	MSG_USE, IT_PHASERS, 0Bh, 0, H_0385
PhaserRomulan3:
	jmp	SHORT PhaserRomulan

H_0385:
	SCRIPT	MSG_USE, IT_PHASERS, 0Ch, 0, H_0395
PhaserRomulan:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV4_007
	call	Say
	retf

; Looking and talking.
H_0395:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_03A4
LookAtScene:
	sub	ax, ax
	mov	bx, OFFSET T_LOV4N009
	call	Say
	retf

H_03A4:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_03B3
LookAtLadder:
	sub	ax, ax
	mov	bx, OFFSET T_LOV4N010
	call	Say
	retf

H_03B3:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_03C2
LookAtDoor:
	sub	ax, ax
	mov	bx, OFFSET T_LOV4N008
	call	Say
	retf

H_03C2:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_03D1
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_LOV4N002
	call	Say
	retf

H_03D1:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_03E0
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_LOV4_025
	call	Say
	retf

H_03E0:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_03EF
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_LOV4N003
	call	Say
	retf

H_03EF:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_03FE
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_LOV4N001
	call	Say
	retf

H_03FE:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_0406
	jmp	SHORT LookAtRomulan2

H_0406:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_040E
LookAtRomulan2:
	jmp	SHORT LookAtRomulan3

H_040E:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_0416
LookAtRomulan3:
	jmp	SHORT LookAtRomulan

H_0416:
	SCRIPT	MSG_LOOK, 0Ch, 0, 0, H_0436
LookAtRomulan:
	cmp	byte ptr [si+romulans_cured], 0
	jne	L042C
	mov	ax, OFFSET S_1C8C
	mov	bx, OFFSET T_LOV4N006
	call	Say
	retf

L042C:
	mov	ax, OFFSET S_1C8C
	mov	bx, OFFSET T_LOV4N011
	call	Say
	retf

H_0436:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_04FE
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV4_005
	call	Say
	jmp	SHORT L0481

T_LOV4_005	LABEL	BYTE
	DB	'#LOV4\LOV4_005#Well, there''s a first time for everything.',0
L0481:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV4_024
	call	Say
	jmp	SHORT L04B0

T_LOV4_024	LABEL	BYTE
	DB	'#LOV4\LOV4_024#First time for what?',0
L04B0:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV4_002
	call	Say
	jmp	SHORT L04FD

T_LOV4_002	LABEL	BYTE
	DB	'#LOV4\LOV4_002#Being surrounded by Romulans and not at gun point'
	DB	'.',0
L04FD:
	retf

H_04FE:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0563
TalkToMcCoy:
	cmp	byte ptr [si+romulans_cured], 1
	jne	L0559
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV4_022
	call	Say
	jmp	SHORT L0558

T_LOV4_022	LABEL	BYTE
	DB	'#LOV4\LOV4_022#They''ll be fine now, Jim. They just need some res'
	DB	't.',0
L0558:
	retf

L0559:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV4_010
	call	Say
	retf

H_0563:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0573
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV4_028
	call	Say
	retf

H_0573:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0592
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV4_027
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV4_003
	call	Say
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L0591
L0591:
	retf

H_0592:
	SCRIPT	MSG_TALK, 9, 0, 0, H_059A
	jmp	SHORT TalkToRomulan2

H_059A:
	SCRIPT	MSG_TALK, 0Ah, 0, 0, H_05A2
TalkToRomulan2:
	jmp	SHORT TalkToRomulan3

H_05A2:
	SCRIPT	MSG_TALK, 0Bh, 0, 0, H_05AA
TalkToRomulan3:
	jmp	SHORT TalkToRomulan

H_05AA:
	SCRIPT	MSG_TALK, 0Ch, 0, 0, H_05EE
TalkToRomulan:
	cmp	byte ptr [si+romulans_cured], 1
	jne	L05ED
	mov	ax, 0
	mov	bx, OFFSET S_05C1
	call	Say
	jmp	SHORT L05ED

S_05C1	LABEL	BYTE
	DB	'They are in no condition to talk right now.',0
L05ED:
	retf

; Tricorders.
H_05EE:
	SCRIPT	MSG_USE, IT_MTRICOR, 9, 0, H_05F6
	jmp	SHORT McCoyScansRomulan2

H_05F6:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Ah, 0, H_05FE
McCoyScansRomulan2:
	jmp	SHORT McCoyScansRomulan3

H_05FE:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Bh, 0, H_0606
McCoyScansRomulan3:
	jmp	SHORT McCoyScansRomulan

H_0606:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Ch, 0, H_0707
McCoyScansRomulan:
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
	cmp	byte ptr [si+romulans_cured], 1
	je	L0636
	JMPN	L06BA

L0636:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV4_018
	call	Say
	jmp	SHORT L06B9

T_LOV4_018	LABEL	BYTE
	DB	'#LOV4\LOV4_018#The Romulans have been cured of the Oroborus viru'
	DB	's, but they are severely dehydrated and need some rest.',0
L06B9:
	retf

L06BA:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV4_015
	call	Say
	jmp	SHORT L0706

T_LOV4_015	LABEL	BYTE
	DB	'#LOV4\LOV4_015#Jim, we''ve got to help these men before they die.',0
L0706:
	retf

H_0707:
	SCRIPT	MSG_USE, IT_MTRICOR, ANY, 0, H_079D
McCoyScans:
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
	cmp	byte ptr [si+romulans_cured], 1
	jne	L0783
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV4_019
	call	Say
	jmp	SHORT L0782

T_LOV4_019	LABEL	BYTE
	DB	'#LOV4\LOV4_019#The Romulans have been cured of the Oroborus viru'
	DB	's.',0
L0782:
	retf

L0783:
	cmp	byte ptr [si+romulans_out], 1
	jne	L0793
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV4_020
	call	Say
	retf

L0793:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV4_021
	call	Say
	retf

H_079D:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_07CE
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
	mov	bx, OFFSET T_LOV4_006
	call	Say
	retf

; The cure on the Romulans (+2, once): McCoy injects all four in turn
; (walk msgs 3-6, anim msgs 2-5).
H_07CE:
	SCRIPT	MSG_USE, IT_CURE, 9, 0, H_07D6
	jmp	SHORT CureRomulan2

H_07D6:
	SCRIPT	MSG_USE, IT_CURE, 0Ah, 0, H_07DE
CureRomulan2:
	jmp	SHORT CureRomulan3

H_07DE:
	SCRIPT	MSG_USE, IT_CURE, 0Bh, 0, H_07E6
CureRomulan3:
	jmp	SHORT CureRomulans

H_07E6:
	SCRIPT	MSG_USE, IT_CURE, 0Ch, 0, H_0859
CureRomulans:
	cmp	byte ptr [si+romulans_cured], 1
	je	L0813
	add	word ptr [si+score], 2
	mov	byte ptr [si+romulans_cured], 1
	mov	byte ptr [si+RS_BUSY], 1
	push	3
	push	0B1h
	push	10Eh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 270, 177, 3)
	add	sp, 0Ah
	retf

L0813:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV4_013
	call	Say
	jmp	SHORT L0858

T_LOV4_013	LABEL	BYTE
	DB	'#LOV4\LOV4_013#I don''t think they need another shot, Jim.',0
L0858:
	retf

H_0859:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_0875
McCoyAtRomulan4:
	push	2
	push	-1
	push	-1
	push	OFFSET N_museme
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "museme", -1, -1, 2)
	add	sp, 0Ch
	retf

H_0875:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_08A7
Romulan4Cured:
	push	0
	push	0AAh
	push	12Ah
	push	OFFSET N_s3r5r4
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s3r5r4", 298, 170, 0)
	add	sp, 0Ch
	push	4
	push	0C4h
	push	0EBh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 235, 196, 4)
	add	sp, 0Ah
	retf

H_08A7:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_08C3
McCoyAtRomulan3:
	push	3
	push	-1
	push	-1
	push	OFFSET N_musele
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musele", -1, -1, 3)
	add	sp, 0Ch
	retf

H_08C3:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_08F5
Romulan3Cured:
	push	0
	push	0C4h
	push	0EFh
	push	OFFSET N_s3r5r3
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s3r5r3", 239, 196, 0)
	add	sp, 0Ch
	push	5
	push	0C3h
	push	0B9h
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 185, 195, 5)
	add	sp, 0Ah
	retf

H_08F5:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_0911
McCoyAtRomulan2:
	push	4
	push	-1
	push	-1
	push	OFFSET N_musemn
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musemn", -1, -1, 4)
	add	sp, 0Ch
	retf

H_0911:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_0942
Romulan2Cured:
	push	0
	push	0BBh
	push	0B9h
	push	OFFSET N_s3r5r2
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s3r5r2", 185, 187, 0)
	add	sp, 0Ch
	push	6
	push	0BAh
	push	36h
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 54, 186, 6)
	add	sp, 0Ah
	retf

H_0942:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_095E
McCoyAtRomulan1:
	push	5
	push	-1
	push	-1
	push	OFFSET N_musemn
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musemn", -1, -1, 5)
	add	sp, 0Ch
	retf

H_095E:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_0A4C
RomulansCured:
	push	0
	push	0B3h
	push	36h
	push	OFFSET N_s3r5r1
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s3r5r1", 54, 179, 0)
	add	sp, 0Ch
	mov	ax, 0
	mov	bx, OFFSET T_LOV4N005
	call	Say
	jmp	SHORT L09DE

T_LOV4N005	LABEL	BYTE
	DB	'#LOV4\LOV4N005#The Romulans stir weakly, then begin to get up...'
	DB	' they''ve all been cured!',0
L09DE:
	cmp	byte ptr cs:watered, 1
	je	L0A47
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV4_023
	call	Say
	jmp	SHORT L0A47

T_LOV4_023	LABEL	BYTE
	DB	'#LOV4\LOV4_023#They''re severely dehydrated, but they''ll live. We'
	DB	' got to them in time.',0
L0A47:
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Water for the Romulans: +1 for the cured ones, every time (gave_water
; is set to 2 but tested against 1).
H_0A4C:
	SCRIPT	MSG_USE, IT_H2O, 9, 0, H_0A54
	jmp	SHORT WaterRomulan2

H_0A54:
	SCRIPT	MSG_USE, IT_H2O, 0Ah, 0, H_0A5C
WaterRomulan2:
	jmp	SHORT WaterRomulan3

H_0A5C:
	SCRIPT	MSG_USE, IT_H2O, 0Bh, 0, H_0A64
WaterRomulan3:
	jmp	SHORT WaterRomulans

H_0A64:
	SCRIPT	MSG_USE, IT_H2O, 0Ch, 0, H_0DA8
WaterRomulans:
	mov	byte ptr cs:watered, 1
	cmp	byte ptr [si+romulans_cured], 1
	je	L0A79
	JMPN	L0BAA

L0A79:
	mov	ax, 0
	mov	bx, OFFSET T_LOV4N013
	call	Say
	jmp	SHORT L0AC9

T_LOV4N013	LABEL	BYTE
	DB	'#LOV4\LOV4N013#The Romulans drink thirstily and empty the contai'
	DB	'ner.',0
L0AC9:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV4_026
	call	Say
	jmp	SHORT L0B48

T_LOV4_026	LABEL	BYTE
	DB	'#LOV4\LOV4_026#Take it easy now... You''ll feel better in a few m'
	DB	'inutes. Good thing we had the water available, Jim.',0
L0B48:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV4_001
	call	Say
	jmp	SHORT L0B9C

T_LOV4_001	LABEL	BYTE
	DB	'#LOV4\LOV4_001#We aren''t barbarians, in spite of what some peopl'
	DB	'e think.',0
L0B9C:
	cmp	byte ptr [si+gave_water], 1
	je	L0BAA
	add	word ptr [si+score], 1
	mov	byte ptr [si+gave_water], 2
L0BAA:
	JMPN	L0D9B

	DB	80h, 7Ch, 41h, 1, 74h, 3, 0E9h, 0C5h, 0, 0B8h, 0, 0
	DB	0BBh, 0C2h, 0Bh, 0E8h, 49h, 10h, 0E9h, 0B6h, 0
	DB	'#LOV4\LOV4_009#Careful there! They''re suffering from dehydration'
	DB	' but it''s dangerous to give water to someone while they''re uncon'
	DB	'scious. These men need serum or they''re going to die!',0
	DB	0E9h, 20h, 1, 0B8h, 0, 0, 0BBh, 86h, 0Ch, 0E8h, 84h, 0Fh
	DB	0EBh
	DB	'H#LOV4\LOV4N004#The Romulans come to weakly, reaching for their '
	DB	'weapons.',0
	DB	80h, 7Ch, 1Eh, 1, 74h, 79h, 0B8h, 81h, 1Ch, 0BBh, 0DFh, 0Ch
	DB	0E8h, 2Bh, 0Fh, 0EBh
	DB	'1#LOV4\LOV4_029#Freeze, Romulans! You''re covered!',0
	DB	0B8h, 62h, 1Ch, 0BBh, 1Bh, 0Dh, 0E8h, 0EFh, 0Eh, 0EBh
	DB	'2#LOV4\LOV4_004#Lt. Ferris, collect their weapons.',0
	DB	0B8h, 6Dh, 1Ch, 0BBh, 58h, 0Dh, 0E8h, 0B2h, 0Eh, 0EBh
	DB	'C#LOV4\LOV4_011#Dammit, Jim, these men are sick! They need my he'
	DB	'lp!',0
L0D9B:
	push	IT_H2O
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_H2O)
	add	sp, 4
	retf

; Other things on the Romulans.
H_0DA8:
	SCRIPT	MSG_USE, IT_MEDKIT, 9, 0, H_0DB0
	jmp	SHORT MedkitOnRomulan2

H_0DB0:
	SCRIPT	MSG_USE, IT_MEDKIT, 0Ah, 0, H_0DB8
MedkitOnRomulan2:
	jmp	SHORT MedkitOnRomulan3

H_0DB8:
	SCRIPT	MSG_USE, IT_MEDKIT, 0Bh, 0, H_0DC0
MedkitOnRomulan3:
	jmp	SHORT MedkitOnRomulan

H_0DC0:
	SCRIPT	MSG_USE, IT_MEDKIT, 0Ch, 0, H_0E15
MedkitOnRomulan:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV4_012
	call	Say
	jmp	SHORT L0E14

T_LOV4_012	LABEL	BYTE
	DB	'#LOV4\LOV4_012#I don''t have the proper medicine to cure them, Ji'
	DB	'm.',0
L0E14:
	retf

H_0E15:
	SCRIPT	MSG_USE, IT_SAMPLE, 9, 0, H_0E1D
	jmp	SHORT SampleOnRomulan2

H_0E1D:
	SCRIPT	MSG_USE, IT_SAMPLE, 0Ah, 0, H_0E25
SampleOnRomulan2:
	jmp	SHORT SampleOnRomulan3

H_0E25:
	SCRIPT	MSG_USE, IT_SAMPLE, 0Bh, 0, H_0E2D
SampleOnRomulan3:
	jmp	SHORT SampleOnRomulan

H_0E2D:
	SCRIPT	MSG_USE, IT_SAMPLE, 0Ch, 0, H_0E3D
SampleOnRomulan:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV4_014
	call	Say
	retf

H_0E3D:
	SCRIPT	MSG_USE, ANY, 9, 0, H_0E45
	jmp	SHORT UseOnRomulan2

H_0E45:
	SCRIPT	MSG_USE, ANY, 0Ah, 0, H_0E4D
UseOnRomulan2:
	jmp	SHORT UseOnRomulan3

H_0E4D:
	SCRIPT	MSG_USE, ANY, 0Bh, 0, H_0E55
UseOnRomulan3:
	jmp	SHORT UseOnRomulan

H_0E55:
	SCRIPT	MSG_USE, ANY, 0Ch, 0, H_0E76
UseOnRomulan:
	mov	ax, OFFSET S_1C8C
	mov	bx, OFFSET T_LOV4_017
	call	Say
	retf

N_musemn	LABEL	BYTE
	DB	'musemn',0
N_sgetdn	LABEL	BYTE
	DB	'sgetdn',0
cure_steps	LABEL	BYTE	; Spock and McCoy at the cure spot: 2
	DB	0
cure_x	LABEL	BYTE	; the cure spot
	DB	0
cure_y	LABEL	BYTE
	DB	0

; The gases, common to all of the mission's rooms. Timer 0 (after
; laughing gas): a random crew member giggles, and again in 200-400 ticks.
H_0E76:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_1093
CrewLaugh:
	push	2
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 2)
	add	sp, 6
	mov	word ptr cs:roll, ax
	cmp	word ptr cs:roll, 0
	jne	L0E9F
	mov	word ptr cs:laugher, OFFSET N_Dr_McCoy
	jmp	SHORT L0EDC

L0E9F:
	cmp	word ptr cs:roll, 1
	jne	L0EC0
	mov	word ptr cs:laugher, OFFSET N_Lt_Ferris
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L0EBE
	mov	word ptr cs:laugher, OFFSET N_Dr_McCoy
	JMPN	L0F87

L0EBE:
	jmp	SHORT L0EDC

L0EC0:
	mov	ax, 0
	mov	bx, OFFSET N_get_name_error
	call	Say
	jmp	SHORT L0EDB

N_get_name_error	LABEL	BYTE
	DB	'get name error.',0
L0EDB:
	retf

L0EDC:
	mov	word ptr cs:laugher, OFFSET N_Dr_McCoy
	push	0Ah
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 10)
	add	sp, 6
	mov	word ptr cs:roll, ax
	cmp	word ptr cs:roll, 0
	jne	L0F03
	mov	bx, OFFSET T_LOV0_011
	JMPN	L102E

L0F03:
	cmp	word ptr cs:roll, 1
	jne	L0F11
	mov	bx, OFFSET T_LOV0_020
	JMPN	L102E

L0F11:
	cmp	word ptr cs:roll, 2
	jne	L0F1F
	mov	bx, OFFSET T_LOV0_016
	JMPN	L102E

L0F1F:
	cmp	word ptr cs:roll, 3
	jne	L0F2D
	mov	bx, OFFSET T_LOV0_012
	JMPN	L102E

L0F2D:
	cmp	word ptr cs:roll, 4
	jne	L0F3B
	mov	bx, OFFSET T_LOV0_014
	JMPN	L102E

L0F3B:
	cmp	word ptr cs:roll, 5
	jne	L0F49
	mov	bx, OFFSET T_LOV0_022
	JMPN	L102E

L0F49:
	cmp	word ptr cs:roll, 6
	jne	L0F57
	mov	bx, OFFSET T_LOV0_015
	JMPN	L102E

L0F57:
	cmp	word ptr cs:roll, 7
	jne	L0F65
	mov	bx, OFFSET T_LOV0_021
	JMPN	L102E

L0F65:
	cmp	word ptr cs:roll, 8
	jne	L0F73
	mov	bx, OFFSET T_LOV0_013
	JMPN	L102E

L0F73:
	cmp	word ptr cs:roll, 9
	jne	L0F81
	mov	bx, OFFSET T_LOV0_019
	JMPN	L102E

L0F81:
	mov	bx, OFFSET T_LOV0_017
	JMPN	L102E

L0F87:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L0F8E
	retf

L0F8E:
	mov	word ptr cs:laugher, OFFSET N_Lt_Ferris
	push	0Ah
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 10)
	add	sp, 6
	mov	word ptr cs:roll, ax
	cmp	word ptr cs:roll, 0
	jne	L0FB4
	mov	bx, OFFSET T_LOV0_039
	jmp	SHORT L102E

L0FB4:
	cmp	word ptr cs:roll, 1
	jne	L0FC1
	mov	bx, OFFSET T_LOV0_048
	jmp	SHORT L102E

L0FC1:
	cmp	word ptr cs:roll, 2
	jne	L0FCE
	mov	bx, OFFSET T_LOV0_045
	jmp	SHORT L102E

L0FCE:
	cmp	word ptr cs:roll, 3
	jne	L0FDB
	mov	bx, OFFSET T_LOV0_040
	jmp	SHORT L102E

L0FDB:
	cmp	word ptr cs:roll, 4
	jne	L0FE8
	mov	bx, OFFSET T_LOV0_042
	jmp	SHORT L102E

L0FE8:
	cmp	word ptr cs:roll, 5
	jne	L0FF5
	mov	bx, OFFSET T_LOV0_050
	jmp	SHORT L102E

L0FF5:
	cmp	word ptr cs:roll, 6
	jne	L1002
	mov	bx, OFFSET T_LOV0_043
	jmp	SHORT L102E

L1002:
	cmp	word ptr cs:roll, 7
	jne	L100F
	mov	bx, OFFSET T_LOV0_049
	jmp	SHORT L102E

L100F:
	cmp	word ptr cs:roll, 8
	jne	L101C
	mov	bx, OFFSET T_LOV0_041
	jmp	SHORT L102E

L101C:
	cmp	word ptr cs:roll, 9
	jne	L1029
	mov	bx, OFFSET T_LOV0_047
	jmp	SHORT L102E

L1029:
	mov	bx, OFFSET T_LOV0_046
	jmp	SHORT L102E

L102E:
	mov	ax, word ptr cs:laugher
	call	Say
	cmp	byte ptr [si+rlg_released], 1
	jne	L103C
	retf

L103C:
	push	3
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 3)
	add	sp, 6
	mov	word ptr cs:roll, ax
	mov	ax, OFFSET N_Mr_Spock
	cmp	word ptr cs:roll, 0
	jne	L105E
	mov	bx, OFFSET T_LOV0_029
	jmp	SHORT L107D

L105E:
	cmp	word ptr cs:roll, 1
	jne	L106B
	mov	bx, OFFSET T_LOV0_033
	jmp	SHORT L107D

L106B:
	cmp	word ptr cs:roll, 2
	jne	L1078
	mov	bx, OFFSET T_LOV0_026
	jmp	SHORT L107D

L1078:
	mov	bx, OFFSET T_LOV0_124
	jmp	SHORT L107D

L107D:
	call	Say
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS], ax
	retf

; Timer 1 (after Romulan laughing gas): Spock laughs.
H_1093:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_1125
SpockLaughs:
	push	7
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 7)
	add	sp, 6
	mov	word ptr cs:roll, ax
	mov	ax, OFFSET N_Mr_Spock
	cmp	word ptr cs:roll, 0
	jne	L10BB
	mov	bx, OFFSET T_LOV0_025
	jmp	SHORT L110E

L10BB:
	cmp	word ptr cs:roll, 1
	jne	L10C8
	mov	bx, OFFSET T_LOV0_101
	jmp	SHORT L110E

L10C8:
	cmp	word ptr cs:roll, 2
	jne	L10D5
	mov	bx, OFFSET T_LOV0_102
	jmp	SHORT L110E

L10D5:
	cmp	word ptr cs:roll, 3
	jne	L10E2
	mov	bx, OFFSET T_LOV0_103
	jmp	SHORT L110E

L10E2:
	cmp	word ptr cs:roll, 4
	jne	L10EF
	mov	bx, OFFSET T_LOV0_104
	jmp	SHORT L110E

L10EF:
	cmp	word ptr cs:roll, 5
	jne	L10FC
	mov	bx, OFFSET T_LOV0_105
	jmp	SHORT L110E

L10FC:
	cmp	word ptr cs:roll, 6
	jne	L1109
	mov	bx, OFFSET T_LOV0_106
	jmp	SHORT L110E

L1109:
	mov	bx, OFFSET T_LOV0_107
	jmp	SHORT L110E

L110E:
	call	Say
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS+2], ax
	retf

; Curing Spock, common to all of the mission's rooms: with the cure,
; Spock and McCoy walk to the cure spot (msg 99), and McCoy injects him.
H_1125:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_SPOCK, 0, H_11B3
MedkitOnSpock:
	cmp	byte ptr [si+spock_cured], 1
	je	L117F
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_019
	call	Say
	jmp	SHORT L117E

T_LOV5_019	LABEL	BYTE
	DB	'#LOV5\LOV5_019#I don''t have the proper medicine to cure him, Jim'
	DB	'.',0
L117E:
	retf

L117F:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_015
	call	Say
	jmp	SHORT L11B2

T_LOV5_015	LABEL	BYTE
	DB	'#LOV5\LOV5_015#He''s already cured, Jim.',0
L11B2:
	retf

H_11B3:
	SCRIPT	MSG_USE, IT_SAMPLE, OBJ_SPOCK, 0, H_1226
SampleOnSpock:
	cmp	byte ptr [si+spock_cured], 1
	jne	L11C2
	JMPN	L1266

L11C2:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F55
	call	Say
	jmp	SHORT L1225

T_LOVA_F55	LABEL	BYTE
	DB	'#LOVA\LOVA_F55#Jim, we need to sysnthesize more to make the seru'
	DB	'm before we can use it.',0
L1225:
	retf

H_1226:
	SCRIPT	MSG_USE, IT_CURE, OBJ_SPOCK, 0, H_12A2
CureSpock:
	cmp	byte ptr [si+spock_cured], 1
	jne	L1266
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_015_2
	call	Say
	jmp	SHORT L1265

T_LOV5_015_2	LABEL	BYTE
	DB	'#LOV5\LOV5_015#He''s already cured, Jim.',0
L1265:
	retf

L1266:
	push	63h
	xor	ah, ah
	mov	al, byte ptr cs:cure_y
	push	ax
	xor	ah, ah
	mov	al, byte ptr cs:cure_x
	push	ax
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, ?, ?, 99)
	add	sp, 0Ah
	push	63h
	xor	ah, ah
	mov	al, byte ptr cs:cure_y
	AX8	add, 0Ah
	push	ax
	xor	ah, ah
	mov	al, byte ptr cs:cure_x
	push	ax
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, ?, ?, 99)
	add	sp, 0Ah
	retf

H_12A2:
	SCRIPT	MSG_WALK_DONE, 63h, 0, 0, H_12CC
AtSpock:
	inc	byte ptr cs:cure_steps
	cmp	byte ptr cs:cure_steps, 2
	je	L12B6
	retf

L12B6:
	push	63h
	push	-1
	push	-1
	push	OFFSET N_musemn
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musemn", -1, -1, 99)
	add	sp, 0Ch
	retf

H_12CC:
	SCRIPT	MSG_ANIM_DONE, 63h, 0, 0, H_138B
SpockCured:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_030
	call	Say
	jmp	SHORT L1305

T_LOV5_030	LABEL	BYTE
	DB	'#LOV5\LOV5_030#There. You''re now cured.',0
L1305:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV5_038
	call	Say
	jmp	SHORT L1332

T_LOV5_038	LABEL	BYTE
	DB	'#LOV5\LOV5_038#Thank you, Doctor.',0
L1332:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_027
	call	Say
	jmp	SHORT L1367

T_LOV5_027	LABEL	BYTE
	DB	'#LOV5\LOV5_027#Finally, a human response!',0
L1367:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_1372
	call	Say
	jmp	SHORT L1386

S_1372	LABEL	BYTE
	DB	'(raises an eyebrow)',0
L1386:
	mov	byte ptr [si+spock_cured], 1
	retf

; Timer 2, every 200 ticks until Spock is cured: the virus advances,
; with a line at 0Fh, 1Eh, 2Dh; at 3Ch Spock collapses, at 64h he dies.
H_138B:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_1541
VirusProgresses:
	cmp	byte ptr [si+spock_cured], 1
	jne	L1398
	retf

L1398:
	inc	byte ptr [si+virus]
	cmp	byte ptr [si+virus], 64h
	jl	L13A4
	JMPN	L14F1

L13A4:
	cmp	byte ptr [si+virus], 0Fh
	jne	L13DB
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_spokcoff
	call	Say
	jmp	SHORT L13D5

T_spokcoff	LABEL	BYTE
	DB	'#sfx\spokcoff#cough... cough...',0
L13D5:
	inc	byte ptr [si+virus]
	JMPN	L14EB

L13DB:
	cmp	byte ptr [si+virus], 1Eh
	jne	L1441
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F08
	call	Say
	jmp	SHORT L143B

T_LOVA_F08	LABEL	BYTE
	DB	'#LOVA\LOVA_F08#It''s what I was afraid of, Jim. I think spock is '
	DB	'getting worse.',0
L143B:
	inc	byte ptr [si+virus]
	JMPN	L14EB

L1441:
	cmp	byte ptr [si+virus], 2Dh
	jne	L1477
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_spokcoff_2
	call	Say
	jmp	SHORT L1472

T_spokcoff_2	LABEL	BYTE
	DB	'#sfx\spokcoff#cough... cough...',0
L1472:
	inc	byte ptr [si+virus]
	jmp	SHORT L14EB

L1477:
	cmp	byte ptr [si+virus], 3Ch
	jne	L14EB
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOVA_F54
	call	Say
	jmp	SHORT L14E2

T_LOVA_F54	LABEL	BYTE
	DB	'#LOVA\LOVA_F54#The virus has spread to me, Captain.Isuggestyouco'
	DB	'ncentrateyoureffortsonthe',0
L14E2:
	mov	byte ptr [si+virus_struck], 1
	inc	byte ptr [si+virus]
	jmp	SHORT L14EB

L14EB:
	mov	word ptr [si+RS_TIMERS+4], 0C8h
	retf

L14F1:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sgetdn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sgetdn", -1, -1, 0)
	add	sp, 0Ch
	push	2
	push	RC_MUSIC
	SERVICE		; Music(2)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_GENER004
	call	Say
	jmp	SHORT L1536

T_GENER004	LABEL	BYTE
	DB	'#GENE\GENER004#Game Over',0
L1536:
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	retf

; McCoy's tricorder on Spock follows the virus; on the others, normal.
H_1541:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_SPOCK, 0, H_17B2
McCoyScansSpock:
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	cmp	byte ptr [si+spock_cured], 1
	jne	L159B
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F01
	call	Say
	jmp	SHORT L159A

T_LOVA_F01	LABEL	BYTE
	DB	'#LOVA\LOVA_F01#He''s been cured of the Oroborus virus.',0
L159A:
	retf

L159B:
	cmp	byte ptr [si+have_research], 1
	je	L160D
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F02
	call	Say
	jmp	SHORT L160C

T_LOVA_F02	LABEL	BYTE
	DB	'#LOVA\LOVA_F02#I''m picking up some kind of virus. I can''t identi'
	DB	'fy it without more information.',0
L160C:
	retf

L160D:
	cmp	byte ptr [si+virus], 0Ah
	jge	L1662
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F04
	call	Say
	jmp	SHORT L1661

T_LOVA_F04	LABEL	BYTE
	DB	'#LOVA\LOVA_F04#The virus affects the Romulan-Vulcan genotype, Ji'
	DB	'm.',0
L1661:
	retf

L1662:
	cmp	byte ptr [si+virus], 1Eh
	jge	L16A6
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F03
	call	Say
	jmp	SHORT L16A5

T_LOVA_F03	LABEL	BYTE
	DB	'#LOVA\LOVA_F03#He''s infected with the virus, Jim.',0
L16A5:
	retf

L16A6:
	cmp	byte ptr [si+virus], 32h
	jge	L1707
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F08_2
	call	Say
	jmp	SHORT L1706

T_LOVA_F08_2	LABEL	BYTE
	DB	'#LOVA\LOVA_F08#It''s what I was afraid of, Jim. I think spock is '
	DB	'getting worse.',0
L1706:
	retf

L1707:
	cmp	byte ptr [si+virus], 46h
	jne	L174D
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG2_010
	call	Say
	jmp	SHORT L174C

T_TUG2_010	LABEL	BYTE
	DB	'#TUG2\TUG2_010#I don''t like the looks of this, Jim.',0
L174C:
	retf

L174D:
	cmp	byte ptr [si+virus], 64h
	jge	L1787
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F10
	call	Say
	jmp	SHORT L1786

T_LOVA_F10	LABEL	BYTE
	DB	'#LOVA\LOVA_F10#He has weak vital signs.',0
L1786:
	retf

L1787:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_100
	call	Say
	jmp	SHORT L17B1

T_LOVA_100	LABEL	BYTE
	DB	'#LOVA\LOVA_100#He''s dead, Jim.',0
L17B1:
	retf

H_17B2:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_KIRK, 0, H_17BA
	jmp	SHORT McCoyScansMcCoy

H_17BA:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_MCCOY, 0, H_17C2
McCoyScansMcCoy:
	jmp	SHORT McCoyScansCrew

H_17C2:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_REDSHIRT, 0, H_1809
McCoyScansCrew:
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F07
	call	Say
	jmp	SHORT L1808

T_LOVA_F07	LABEL	BYTE
	DB	'#LOVA\LOVA_F07#All lifesigns are normal.',0
L1808:
	retf

; Opening a gas canister: Romulan laughing gas sets Spock laughing,
; nitrous oxide the crew, ammonia nothing.
H_1809:
	SCRIPT	MSG_USE, IT_RLG, ANY, 0, H_1859
ReleaseRLG:
	mov	ax, OFFSET S_1C8C
	mov	bx, OFFSET T_LOV2N005
	call	Say
	jmp	SHORT L1848

T_LOV2N005	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L1848:
	mov	byte ptr [si+rlg_released], 1
	push	IT_RLG
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_RLG)
	add	sp, 4
	retf

H_1859:
	SCRIPT	MSG_USE, IT_N2O, ANY, 0, H_18EB
ReleaseN2O:
	mov	ax, OFFSET S_1C8C
	mov	bx, OFFSET T_LOV2N005_2
	call	Say
	jmp	SHORT L1898

T_LOV2N005_2	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L1898:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD2_040
	call	Say
	jmp	SHORT L18CE

T_MUD2_040	LABEL	BYTE
	DB	'#MUD2\MUD2_040#You look troubled, Captain.',0
L18CE:
	mov	byte ptr [si+n2o_released], 1
	push	IT_N2O
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_N2O)
	add	sp, 4
	push	3
	push	RC_MUSIC
	SERVICE		; Music(3)
	add	sp, 4
	retf

H_18EB:
	SCRIPT	MSG_USE, IT_NH3, ANY, 0, H_1951
ReleaseNH3:
	mov	ax, OFFSET S_1C8C
	mov	bx, OFFSET T_LOV2N005_3
	call	Say
	jmp	SHORT L192A

T_LOV2N005_3	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L192A:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L1930
L1930:
	push	IT_NH3
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_NH3)
	add	sp, 4
	retf

	DB	'Mr. Scott',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0

; The communicator: four cases (first call, later calls, the same after
; the cure), all with the same three lines borrowed from other missions'
; speech files.
H_1951:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, rdf_scripts_end
CallEnterprise:
	cmp	byte ptr [si+made_cure], 1
	jne	L1960
	JMPN	L1AAD

L1960:
	cmp	byte ptr [si+called_ship], 1
	jne	L1969
	JMPN	L1A0D

L1969:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018
	call	Say
	jmp	SHORT L19AE

T_MUD4_018	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L19AE:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146
	call	Say
	jmp	SHORT L19E4

T_BRIDU146	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L19E4:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41
	call	Say
	jmp	SHORT L1A08

T_VENA_F41	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L1A08:
	mov	byte ptr [si+called_ship], 1
	retf

L1A0D:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_2
	call	Say
	jmp	SHORT L1A52

T_MUD4_018_2	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L1A52:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_2
	call	Say
	jmp	SHORT L1A88

T_BRIDU146_2	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L1A88:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_2
	call	Say
	jmp	SHORT L1AAC

T_VENA_F41_2	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L1AAC:
	retf

L1AAD:
	cmp	byte ptr [si+called_ship_cured], 1
	jne	L1AB6
	JMPN	L1B5A

L1AB6:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_3
	call	Say
	jmp	SHORT L1AFB

T_MUD4_018_3	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L1AFB:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_3
	call	Say
	jmp	SHORT L1B31

T_BRIDU146_3	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L1B31:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_3
	call	Say
	jmp	SHORT L1B55

T_VENA_F41_3	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L1B55:
	mov	byte ptr [si+called_ship_cured], 1
	retf

L1B5A:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_4
	call	Say
	jmp	SHORT L1B9F

T_MUD4_018_4	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L1B9F:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_4
	call	Say
	jmp	SHORT L1BD5

T_BRIDU146_4	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L1BD5:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_4
	call	Say
	jmp	SHORT L1BF9

T_VENA_F41_4	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L1BF9:
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
	DW	105,150, 187,150, 187,172, 105,172
	DW	21h, 4	; id, points
	DW	237,12, 254,12, 254,168, 237,168
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	105,150, 187,150, 187,172, 105,172
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's3r5l1',0
	DB	's3r5l2',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Ferris	LABEL	BYTE
	DB	'Lt. Ferris',0
S_1C8C	LABEL	BYTE
	DB	0
T_LOV4N006	LABEL	BYTE
	DB	'#LOV4\LOV4N006#These Romulans are totally out of it.',0
T_LOV4N009	LABEL	BYTE
	DB	'#LOV4\LOV4N009#This is the ARK7''s crew quarters. There are only '
	DB	'Romulans here.',0
T_LOV4N011	LABEL	BYTE
	DB	'#LOV4\LOV4N011#This Romulan is groggy, but conscious.',0
T_LOV4N010	LABEL	BYTE
	DB	'#LOV4\LOV4N010#This ladder leads back to the research lab.',0
T_LOV4N002	LABEL	BYTE
	DB	'#LOV4\LOV4N002#James Kirk views the scene with concern.',0
T_LOV4_025	LABEL	BYTE
	DB	'#LOV4\LOV4_025#McCoy thinks to himself: ''Dammit, I''m a doctor, n'
	DB	'ot a diplomat!''',0
T_LOV4N003	LABEL	BYTE
	DB	'#LOV4\LOV4N003#Mr. Spock is his usual stoic self.',0
T_LOV4N001	LABEL	BYTE
	DB	'#LOV4\LOV4N001#Ensign Ferris is looking at the Romulans, in case'
	DB	' one of them decides to try something.',0
T_LOV4N008	LABEL	BYTE
	DB	'#LOV4\LOV4N008#This door leads into another section of the base.',0
T_LOV4_014	LABEL	BYTE
	DB	'#LOV4\LOV4_014#Jim, we need to synthesize more before we can use'
	DB	' it.',0
T_LOV4_007	LABEL	BYTE
	DB	'#LOV4\LOV4_007#Are you crazy, Jim! That''s not going to help in t'
	DB	'he least!',0
	DB	'#FEA5\FEA5_008#Captain, I''ll declare you unfit to command if you'
	DB	' keep this up!',0
T_LOV4_017	LABEL	BYTE
	DB	'#LOV4\LOV4_017#That''s not working, Jim.',0
	DB	'#LOV4\LOV4N000#Door Opens.',0
T_LOV4_010	LABEL	BYTE
	DB	'#LOV4\LOV4_010#Dammit, Jim, I''m a doctor, not a diplomat. I''ve g'
	DB	'ot to try and save these men.',0
T_LOV4_028	LABEL	BYTE
	DB	'#LOV4\LOV4_028#These Romulans appear to be a negligible threat, '
	DB	'sir.',0
T_LOV4_027	LABEL	BYTE
	DB	'#LOV4\LOV4_027#I have been in more comfortable situations, Capta'
	DB	'in.',0
T_LOV4_003	LABEL	BYTE
	DB	'#LOV4\LOV4_003#I know Mr. Spock. But we''ll get through this.',0
T_LOV4_020	LABEL	BYTE
	DB	'#LOV4\LOV4_020#The laughing gas did the trick, Jim, but these Ro'
	DB	'mulans are still very, very sick -- they''ve only got hours left.',0
T_LOV4_021	LABEL	BYTE
	DB	'#LOV4\LOV4_021#These Romulans will die soon if we can''t cure the'
	DB	'm.',0
T_LOV4_006	LABEL	BYTE
	DB	'#LOV4\LOV4_006#Except for the Romulans, I can detect no other li'
	DB	'feforms in this room.',0
T_LOV0_011	LABEL	BYTE
	DB	'#LOV0\LOV0_011#Hee hee hee hee...',0
T_LOV0_020	LABEL	BYTE
	DB	'#LOV0\LOV0_020#The hills are alive... With the sounds of...',0
T_LOV0_016	LABEL	BYTE
	DB	'#LOV0\LOV0_016#Ooka! Ooka! Ooka!',0
T_LOV0_012	LABEL	BYTE
	DB	'#LOV0\LOV0_012#I think we''re all feeling just woooonderful!',0
T_LOV0_014	LABEL	BYTE
	DB	'#LOV0\LOV0_014#I''m floating up and up and up...',0
T_LOV0_022	LABEL	BYTE
	DB	'#LOV0\LOV0_022#This is how I want to feel all the time!',0
T_LOV0_015	LABEL	BYTE
	DB	'#LOV0\LOV0_015#I''m so happy, I want to hug the world!',0
T_LOV0_021	LABEL	BYTE
	DB	'#LOV0\LOV0_021#The moon in June''s a boon to tunes... er, somethi'
	DB	'ng like that.',0
T_LOV0_013	LABEL	BYTE
	DB	'#LOV0\LOV0_013#I''m a little teapot short and stout...',0
T_LOV0_019	LABEL	BYTE
	DB	'#LOV0\LOV0_019#Spock, ol'' buddy, ol'' friend, you look soo funny '
	DB	'standing there!',0
T_LOV0_017	LABEL	BYTE
	DB	'#LOV0\LOV0_017#Row, row, row, your boat. Aww, come on Spock.',0
T_LOV0_039	LABEL	BYTE
	DB	'#LOV0\LOV0_039#Hee hee hee hee...',0
T_LOV0_048	LABEL	BYTE
	DB	'#LOV0\LOV0_048#The hills are alive... With the sounds of...',0
T_LOV0_045	LABEL	BYTE
	DB	'#LOV0\LOV0_045#Ooka! Ooka! Ooka!',0
T_LOV0_040	LABEL	BYTE
	DB	'#LOV0\LOV0_040#I think we''re all feeling just woooonderful!',0
T_LOV0_042	LABEL	BYTE
	DB	'#LOV0\LOV0_042#I''m floating up and up and up...',0
T_LOV0_050	LABEL	BYTE
	DB	'#LOV0\LOV0_050#This is how I want to feel all the time!',0
T_LOV0_043	LABEL	BYTE
	DB	'#LOV0\LOV0_043#I''m so happy, I want to hug the world!',0
T_LOV0_049	LABEL	BYTE
	DB	'#LOV0\LOV0_049#The moon in June''s a boon to tunes... er, somethi'
	DB	'ng like that.',0
T_LOV0_041	LABEL	BYTE
	DB	'#LOV0\LOV0_041#I''m a little teapot short and stout...',0
T_LOV0_047	LABEL	BYTE
	DB	'#LOV0\LOV0_047#Spock, ol'' buddy, ol'' friend, you look soo funny '
	DB	'standing there!',0
T_LOV0_046	LABEL	BYTE
	DB	'#LOV0\LOV0_046#Row, row, row, your boat. Aww, come on Spock.',0
T_LOV0_029	LABEL	BYTE
	DB	'#LOV0\LOV0_029#Please, gentlemen, try to control yourselves',0
T_LOV0_033	LABEL	BYTE
	DB	'#LOV0\LOV0_033#Try taking deep breaths to clear your heads.',0
T_LOV0_026	LABEL	BYTE
	DB	'#LOV0\LOV0_026#I don''t believe you''d behave like this if you cou'
	DB	'ld avoid it.',0
T_LOV0_124	LABEL	BYTE
	DB	'#LOV0\LOV0_124#I''m trying to be patient, Captain.',0
T_LOV0_025	LABEL	BYTE
	DB	'#LOV0\LOV0_025#How many Admirals does it take to wire in a logic'
	DB	' transmogrifier?',0
T_LOV0_101	LABEL	BYTE
	DB	'#LOV0\LOV0_101#Fascinating. I am experiencing an urge to laugh.',0
T_LOV0_102	LABEL	BYTE
	DB	'#LOV0\LOV0_102#I am a Vulcan. I must resist these unchecked emot'
	DB	'ions.',0
T_LOV0_103	LABEL	BYTE
	DB	'#LOV0\LOV0_103#Logic...What happened to my logic?',0
T_LOV0_104	LABEL	BYTE
	DB	'#LOV0\LOV0_104#Jim, is this how you feel on shore leave?',0
T_LOV0_105	LABEL	BYTE
	DB	'#LOV0\LOV0_105#I remember my mother trying to tell me jokes when'
	DB	' I was a child. Now, I finally understand them.',0
T_LOV0_106	LABEL	BYTE
	DB	'#LOV0\LOV0_106#Romulan laughing gas. My father would never appro'
	DB	've.',0
T_LOV0_107	LABEL	BYTE
	DB	'#LOV0\LOV0_107#Why do they call you "Bones", doctor?',0
	DB	'#LOV4\LOV4_016#Ouch!',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
