; LOVE2.RDF - "Love's Labor Jeopardized", the science lab, with the
; synthesizer. Two gas tanks feed it (oxygen and hydrogen at first; the
; nitrogen tank is elsewhere), through a valve opened with the wrench.
; It combines the two gases (laughing gas, ammonia, water), turns
; polyberylcarbonate into TLTDH, the Romulan laughing gas, and the cure
; sample from room 1 into the cure. The cabinet holds an antigrav unit
; for moving the tanks.
;
; Actors: 8 the cabinet, 9 the chamber door, 10 (0Ah) the door, 11 (0Bh)
; the valve, 12/13 (0Ch/0Dh) the tanks, 14 (0Eh) the antigrav unit,
; 15-19 (0Fh-13h) what comes out of the chamber.
; Objects: 8 the cabinet, 9 the chamber, 0Ah/22h the door (room 1), 0Bh
; the valve, 0Ch/0Dh the tanks, 0Eh the antigrav unit, 0Fh-13h the
; chamber's contents (gas, PBC, culture, sample, cure), 20h the
; synthesizer, 21h the Ardak 1000, 23h the feed lines.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The communicator's four cases (CallEnterprise) all play the same
;   placeholder lines, recorded for other missions.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
have_research	EQU	RS_VARS+1	; McCoy has Dr. Marcus' research on the virus (room 0)
n2o_released	EQU	RS_VARS+3	; laughing gas: the crew laugh (timer 0)
rlg_released	EQU	RS_VARS+4	; Romulan laughing gas: Spock laughs (timer 1)
cabinet_open	EQU	RS_VARS+9	; bit 0
feed_on	EQU	RS_VARS+0Ah	; the gas feed valve is open
gas_made	EQU	RS_VARS+0Bh	; the last gas made: 1 N2O, 2 ammonia, 3 water, 4 TLTDH (RLG)
chamber	EQU	RS_VARS+0Ch	; 0 empty, 1 polyberylcarbonate, 2 culture, 3 cure sample, 9 the product
tank1	EQU	RS_VARS+0Dh	; the gas tank in the first slot: 0 none, 1 O2, 2 H2, 3 N2
tank2	EQU	RS_VARS+0Eh	; the same for the second slot
virus_struck	EQU	RS_VARS+18h	; the virus has floored Spock, and the Romulans below
virus	EQU	RS_VARS+1Ch	; Spock's infection: 3Ch he collapses, 64h he dies
spock_cured	EQU	RS_VARS+1Dh
called_ship	EQU	RS_VARS+1Eh	; Kirk has called the Enterprise
called_ship_cured	EQU	RS_VARS+1Fh	; the same, after the cure
took_gas	EQU	RS_VARS+23h	; the point for the first gas made
made_cure	EQU	RS_VARS+26h	; the cure has been synthesized (room 2)
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
	DW	0A8h
rdf_scale_min	LABEL	BYTE
	DW	100h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	1, 0, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	296,184, 190,190	; entrance 0, crew 0
	DW	296,184, 216,180	; entrance 0, crew 1
	DW	296,184, 254,183	; entrance 0, crew 2
	DW	296,184, 278,196	; entrance 0, crew 3
	DW	164,199, 107,183	; entrance 1, crew 0
	DW	164,199, 198,187	; entrance 1, crew 1
	DW	164,199, 80,195	; entrance 1, crew 2
	DW	164,199, 251,195	; entrance 1, crew 3
	DW	0,0, 0,0	; entrance 2, crew 0
	DW	0,0, 0,0	; entrance 2, crew 1
	DW	0,0, 0,0	; entrance 2, crew 2
	DW	0,0, 0,0	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0
; In the room file, so these start again each time the room loads
tank_gas	LABEL	BYTE	; the tank being fitted, as tank1
	DB	0
dry_runs	LABEL	BYTE	; runs with the feed off: Spock spots it on the third
	DB	0
going_door	LABEL	BYTE
	DB	0
door_steps	LABEL	BYTE	; the walk and the door both done at 2
	DB	0
tank_item	LABEL	BYTE	; word: its item
	DB	0, 0
tank_anim	LABEL	BYTE	; word
	DB	0, 0
crew	LABEL	BYTE	; word: the crew member at the cabinet or synthesizer
	DB	0, 0
crew_anim	LABEL	BYTE	; word
	DB	0, 0
chamber_anim	LABEL	BYTE	; word: what is in the chamber
	DB	0, 0
gas_anim	LABEL	BYTE	; word: the gas bottle made
	DB	0, 0
laugher	LABEL	BYTE	; word: the name of who giggles
	DB	0, 0
roll	LABEL	BYTE	; word: a random number
	DB	0, 0
N_cure	LABEL	BYTE
	DB	'cure',0
N_pbcanm	LABEL	BYTE
	DB	'pbcanm',0
N_dishes	LABEL	BYTE
	DB	'dishes',0
N_dishes_2	LABEL	BYTE
	DB	'dishes',0
N_btle4	LABEL	BYTE
	DB	'btle4',0
N_btle1	LABEL	BYTE
	DB	'btle1',0
N_btle3	LABEL	BYTE
	DB	'btle3',0
N_btle2	LABEL	BYTE
	DB	'btle2',0
N_antigr	LABEL	BYTE
	DB	'antigr',0
N_o2can	LABEL	BYTE
	DB	'o2can',0
N_n2can	LABEL	BYTE
	DB	'n2can',0
N_h2can	LABEL	BYTE
	DB	'h2can',0
N_s3r3d1	LABEL	BYTE
	DB	's3r3d1',0
N_s3r3d1o	LABEL	BYTE
	DB	's3r3d1o',0
N_s3r3d1c	LABEL	BYTE
	DB	's3r3d1c',0
N_s3r3d4	LABEL	BYTE
	DB	's3r3d4',0
N_s3r3d2	LABEL	BYTE
	DB	's3r3d2',0
N_s3r3d2o	LABEL	BYTE
	DB	's3r3d2o',0
N_s3r3d2c	LABEL	BYTE
	DB	's3r3d2c',0
N_s3r3d5	LABEL	BYTE
	DB	's3r3d5',0
N_s3r3d3	LABEL	BYTE
	DB	's3r3d3',0
N_s3r3d3a	LABEL	BYTE
	DB	's3r3d3a',0
N_s3r3v1	LABEL	BYTE
	DB	's3r3v1',0
N_s3r3v2	LABEL	BYTE
	DB	's3r3v2',0
N_s3r3vc	LABEL	BYTE
	DB	's3r3vc',0
N_s3r3vo	LABEL	BYTE
	DB	's3r3vo',0
N_kusehn	LABEL	BYTE
	DB	'kusehn',0
N_susehn	LABEL	BYTE
	DB	'susehn',0
	DB	'musehn',0
	DB	'rusehn',0
N_kusemn	LABEL	BYTE
	DB	'kusemn',0
N_susemn	LABEL	BYTE
	DB	'susemn',0
N_rusemn	LABEL	BYTE
	DB	'rusemn',0
	DB	'kusemw',0
	DB	'kuseme',0
N_kusehw	LABEL	BYTE
	DB	'kusehw',0
N_susehw	LABEL	BYTE
	DB	'susehw',0
N_musehw	LABEL	BYTE
	DB	'musehw',0
N_rusehw	LABEL	BYTE
	DB	'rusehw',0
N_sscans	LABEL	BYTE
	DB	'sscans',0
	DB	'sscann',0
N_mscans	LABEL	BYTE
	DB	'mscans',0

rdf_scripts:
; The room starts: the two gas tanks, the cabinet, the chamber.
H_0200:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0473
StartRoom:
	jmp	SHORT L0211

N_LOV2LOOP	LABEL	BYTE
	DB	'LOV2LOOP',0
L0211:
	push	OFFSET N_LOV2LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("LOV2LOOP")
	add	sp, 4
	cmp	byte ptr [si+tank1], 1
	jne	L022F
	mov	word ptr cs:tank_anim, OFFSET N_o2can
	jmp	SHORT L024F

L022F:
	cmp	byte ptr [si+tank1], 2
	jne	L023E
	mov	word ptr cs:tank_anim, OFFSET N_h2can
	jmp	SHORT L024F

L023E:
	cmp	byte ptr [si+tank1], 3
	jne	L024D
	mov	word ptr cs:tank_anim, OFFSET N_n2can
	jmp	SHORT L024F

L024D:
	jmp	SHORT L0268

L024F:
	push	0
	push	0AEh
	push	0A7h
	push	word ptr cs:tank_anim
	push	0Ch
	push	RC_ANIM0
	SERVICE		; Anim0(12, ?, 167, 174, 0)
	add	sp, 0Ch
L0268:
	cmp	byte ptr [si+tank2], 1
	jne	L0277
	mov	word ptr cs:tank_anim, OFFSET N_o2can
	jmp	SHORT L0297

L0277:
	cmp	byte ptr [si+tank2], 2
	jne	L0286
	mov	word ptr cs:tank_anim, OFFSET N_h2can
	jmp	SHORT L0297

L0286:
	cmp	byte ptr [si+tank2], 3
	jne	L0295
	mov	word ptr cs:tank_anim, OFFSET N_n2can
	jmp	SHORT L0297

L0295:
	jmp	SHORT L02B0

L0297:
	push	0
	push	0AFh
	push	0B1h
	push	word ptr cs:tank_anim
	push	0Dh
	push	RC_ANIM0
	SERVICE		; Anim0(13, ?, 177, 175, 0)
	add	sp, 0Ch
L02B0:
	push	0
	push	75h
	push	0ACh
	push	OFFSET N_s3r3vc
	cmp	byte ptr [si+feed_on], 1
	jne	L02C4
	pop	ax
	push	OFFSET N_s3r3vo
L02C4:
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, ?, 172, 117, 0)
	add	sp, 0Ch
	push	0
	push	0AFh
	push	1Eh
	push	OFFSET N_s3r3d1c
	cmp	byte ptr [si+cabinet_open], 1
	jne	L02E4
	pop	ax
	push	OFFSET N_s3r3d1o
L02E4:
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, ?, 30, 175, 0)
	add	sp, 0Ch
	cmp	byte ptr [si+cabinet_open], 1
	jne	L031D
	push	IT_ANTIGRA
	push	RC_HAVEITEM
	SERVICE		; HaveItem(IT_ANTIGRA)
	add	sp, 4
	AX8	cmp, 0
	jne	L031D
	push	0
	push	0A7h
	push	1Fh
	push	OFFSET N_antigr
	push	0Eh
	push	RC_ANIM0
	SERVICE		; Anim0(14, "antigr", 31, 167, 0)
	add	sp, 0Ch
L031D:
	push	0
	push	8Dh
	push	8Ah
	push	OFFSET N_s3r3d2c
	cmp	byte ptr [si+chamber], 0
	je	L0332
	pop	ax
	push	OFFSET N_s3r3d2o
L0332:
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, ?, 138, 141, 0)
	add	sp, 0Ch
	cmp	byte ptr [si+chamber], 1
	jne	L0355
	mov	word ptr cs:chamber_anim, OFFSET N_pbcanm
	mov	word ptr cs:crew, 10h
	JMPN	L03F1

L0355:
	cmp	byte ptr [si+chamber], 2
	jne	L036C
	mov	word ptr cs:chamber_anim, OFFSET N_dishes
	mov	word ptr cs:crew, 11h
	JMPN	L03F1

L036C:
	cmp	byte ptr [si+chamber], 3
	jne	L0382
	mov	word ptr cs:chamber_anim, OFFSET N_dishes_2
	mov	word ptr cs:crew, 12h
	jmp	SHORT L03F1

L0382:
	cmp	byte ptr [si+chamber], 9
	je	L038B
	JMPN	L0419

L038B:
	cmp	byte ptr [si+gas_made], 1
	jne	L03A1
	mov	word ptr cs:gas_anim, OFFSET N_btle1
	mov	word ptr cs:crew, 0Fh
	jmp	SHORT L03F1

L03A1:
	cmp	byte ptr [si+gas_made], 2
	jne	L03B7
	mov	word ptr cs:gas_anim, OFFSET N_btle2
	mov	word ptr cs:crew, 0Fh
	jmp	SHORT L03F1

L03B7:
	cmp	byte ptr [si+gas_made], 3
	jne	L03CD
	mov	word ptr cs:gas_anim, OFFSET N_btle3
	mov	word ptr cs:crew, 0Fh
	jmp	SHORT L03F1

L03CD:
	cmp	byte ptr [si+gas_made], 4
	jne	L03E3
	mov	word ptr cs:gas_anim, OFFSET N_btle4
	mov	word ptr cs:crew, 0Fh
	jmp	SHORT L03F1

L03E3:
	mov	word ptr cs:gas_anim, OFFSET N_cure
	mov	word ptr cs:crew, 13h
L03F1:
	push	0
	push	8Bh
	push	8Ah
	push	word ptr cs:chamber_anim
	cmp	byte ptr [si+chamber], 9
	jne	L040A
	pop	ax
	push	word ptr cs:gas_anim
L040A:
	push	word ptr cs:crew
	push	RC_ANIM2
	SERVICE		; Anim(?, ?, 138, 139, 0)
	add	sp, 0Ch
L0419:
	cmp	byte ptr [si+n2o_released], 1
	jne	L0431
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS], ax
L0431:
	cmp	byte ptr [si+rlg_released], 1
	jne	L044A
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS+2], ax
L044A:
	mov	word ptr [si+RS_TIMERS+4], 0C8h
	push	0
	push	0B5h
	push	12Ah
	push	OFFSET N_s3r3d3a
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "s3r3d3a", 298, 181, 0)
	add	sp, 0Ch
	mov	byte ptr cs:cure_x, -37h
	mov	byte ptr cs:cure_y, -49h
	retf

; Exit 1 (timer 3): to the bridge, room 0.
H_0473:
	SCRIPT	MSG_EXIT, 1, 0, 0, H_048F
ExitToBridge:
	mov	byte ptr [si+RS_BUSY], 1
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	mov	word ptr [si+RS_TIMERS+6], 0Ah
	retf

H_048F:
	SCRIPT	MSG_TIMER, 3, 0, 0, H_04A8
GoToBridge:
	push	0
	push	0
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(0, 0)
	add	sp, 6
	mov	byte ptr [si+RS_BUSY], 0
	retf

; The door to the lab (room 1): walk (msg 14), it opens (anim msg 1).
H_04A8:
	SCRIPT	MSG_WALK, 0Ah, 0, 0, H_04B0
	jmp	SHORT WalkToDoor

H_04B0:
	SCRIPT	MSG_WALK, 22h, 0, 0, H_04D5
WalkToDoor:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr cs:going_door, 1
	push	0Eh
	push	0BAh
	push	127h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 295, 186, 14)
	add	sp, 0Ah
	retf

H_04D5:
	SCRIPT	MSG_REGION, 0, 0, 0, H_0507
ReachDoor:
	cmp	byte ptr cs:going_door, 1
	jne	L0506
	push	1
	push	0B5h
	push	12Ah
	push	OFFSET N_s3r3d3
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "s3r3d3", 298, 181, 1)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
L0506:
	retf

H_0507:
	SCRIPT	MSG_WALK_DONE, 0Eh, 0, 0, H_050F
	jmp	SHORT ThroughDoor

H_050F:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_0532
ThroughDoor:
	inc	byte ptr cs:door_steps
	cmp	byte ptr cs:door_steps, 2
	je	L0523
	retf

L0523:
	push	1
	push	1
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(1, 1)
	add	sp, 6
	retf

; Looking and talking.
H_0532:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_0541
LookAtCabinet:
	sub	ax, ax
	mov	bx, OFFSET T_LOV2N027
	call	Say
	retf

H_0541:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_0550
LookAtDoor:
	sub	ax, ax
	mov	bx, OFFSET T_LOV2N001
	call	Say
	retf

H_0550:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_055F
LookAtSynthesizer:
	sub	ax, ax
	mov	bx, OFFSET T_LOV2N028
	call	Say
	retf

H_055F:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_056E
LookAtScene:
	sub	ax, ax
	mov	bx, OFFSET T_LOV2N026
	call	Say
	retf

H_056E:
	SCRIPT	MSG_LOOK, 0Eh, 0, 0, H_057D
LookAtAntigrav:
	sub	ax, ax
	mov	bx, OFFSET T_LOV2N006
	call	Say
	retf

H_057D:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_058C
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_LOV2N011
	call	Say
	retf

H_058C:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_059B
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_LOV2N014
	call	Say
	retf

H_059B:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_05AA
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_LOV2N010
	call	Say
	retf

H_05AA:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_05E0
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N009
	call	Say
	jmp	SHORT L05DF

T_LOV2N009	LABEL	BYTE
	DB	'#LOV2\LOV2N009#James Tiberius Kirk.',0
L05DF:
	retf

H_05E0:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_05F9
LookAtArdak:
	mov	ax, OFFSET S_37CE
	mov	bx, OFFSET T_LOV2N045
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_037
	call	Say
	retf

H_05F9:
	SCRIPT	MSG_LOOK, 0Fh, 0, 0, H_0601
	jmp	SHORT LookAtChamber2

H_0601:
	SCRIPT	MSG_LOOK, 10h, 0, 0, H_0609
LookAtChamber2:
	jmp	SHORT LookAtChamber3

H_0609:
	SCRIPT	MSG_LOOK, 12h, 0, 0, H_0611
LookAtChamber3:
	jmp	SHORT LookAtChamber4

H_0611:
	SCRIPT	MSG_LOOK, 13h, 0, 0, H_0619
LookAtChamber4:
	jmp	SHORT LookAtChamber5

H_0619:
	SCRIPT	MSG_LOOK, 11h, 0, 0, H_0621
LookAtChamber5:
	jmp	SHORT LookAtChamber

H_0621:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_0655
LookAtChamber:
	mov	ax, OFFSET S_37CE
	mov	bx, OFFSET T_LOV2N029
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_035
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV2_019
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_033
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV2_016
	call	Say
	retf

H_0655:
	SCRIPT	MSG_LOOK, 0Ch, 0, 0, H_0685
LookAtTank1:
	cmp	byte ptr [si+tank1], 1
	jne	L066B
	mov	ax, OFFSET S_37CE
	mov	bx, OFFSET T_LOV2N004
	call	Say
	retf

L066B:
	cmp	byte ptr [si+tank1], 2
	jne	L067B
	mov	ax, OFFSET S_37CE
	mov	bx, OFFSET T_LOV2N002
	call	Say
	retf

L067B:
	mov	ax, OFFSET S_37CE
	mov	bx, OFFSET T_LOV2N003
	call	Say
	retf

H_0685:
	SCRIPT	MSG_LOOK, 0Dh, 0, 0, H_06B5
LookAtTank2:
	cmp	byte ptr [si+tank2], 1
	jne	L069B
	mov	ax, OFFSET S_37CE
	mov	bx, OFFSET T_LOV2N004
	call	Say
	retf

L069B:
	cmp	byte ptr [si+tank2], 2
	jne	L06AB
	mov	ax, OFFSET S_37CE
	mov	bx, OFFSET T_LOV2N002
	call	Say
	retf

L06AB:
	mov	ax, OFFSET S_37CE
	mov	bx, OFFSET T_LOV2N003
	call	Say
	retf

H_06B5:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0714
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV2_001
	call	Say
	jmp	SHORT L0713

T_LOV2_001	LABEL	BYTE
	DB	'#LOV2\LOV2_001#Well, gentlemen, I believe this equipment may be '
	DB	'of some use.',0
L0713:
	retf

H_0714:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0724
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_029
	call	Say
	retf

H_0724:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0734
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV2_009
	call	Say
	retf

H_0734:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0744
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV2_041
	call	Say
	retf

; Tricorders.
H_0744:
	SCRIPT	MSG_USE, IT_MTRICOR, ANY, 0, H_07F1
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
	cmp	byte ptr [si+have_research], 1
	je	L07E7
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV2_012
	call	Say
	jmp	SHORT L07E6

T_LOV2_012	LABEL	BYTE
	DB	'#LOV2\LOV2_012#I''m picking up some strange, airborne virus. I ca'
	DB	'n''t identify it without more information.',0
L07E6:
	retf

L07E7:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV2_008
	call	Say
	retf

H_07F1:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_0822
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
	mov	bx, OFFSET T_LOV2_027
	call	Say
	retf

; The cabinet, by anyone (msgs 12, 11, 2): open, and the antigrav unit.
H_0822:
	SCRIPT	MSG_USE, OBJ_KIRK, 8, 0, H_0838
KirkOpensCabinet:
	mov	word ptr cs:crew, 0
	mov	word ptr cs:crew_anim, OFFSET N_kusehw
	jmp	SHORT L0878

H_0838:
	SCRIPT	MSG_USE, OBJ_SPOCK, 8, 0, H_084E
SpockOpensCabinet:
	mov	word ptr cs:crew, 1
	mov	word ptr cs:crew_anim, OFFSET N_susehw
	jmp	SHORT L0878

H_084E:
	SCRIPT	MSG_USE, OBJ_MCCOY, 8, 0, H_0864
McCoyOpensCabinet:
	mov	word ptr cs:crew, 2
	mov	word ptr cs:crew_anim, OFFSET N_musehw
	jmp	SHORT L0878

H_0864:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 8, 0, H_088F
FerrisOpensCabinet:
	mov	word ptr cs:crew, 3
	mov	word ptr cs:crew_anim, OFFSET N_rusehw
L0878:
	push	0Ch
	push	0BBh
	push	2Dh
	push	word ptr cs:crew
	push	RC_WALK
	SERVICE		; Walk(?, 45, 187, 12)
	add	sp, 0Ah
	retf

H_088F:
	SCRIPT	MSG_WALK_DONE, 0Ch, 0, 0, H_08B0
AtCabinet:
	push	0Bh
	push	-1
	push	-1
	push	word ptr cs:crew_anim
	push	word ptr cs:crew
	push	RC_ANIM2
	SERVICE		; Anim(?, ?, -1, -1, 11)
	add	sp, 0Ch
	retf

H_08B0:
	SCRIPT	MSG_ANIM_DONE, 0Bh, 0, 0, H_08F9
CabinetToggled:
	push	2
	push	0AFh
	push	1Eh
	push	OFFSET N_s3r3d1
	cmp	byte ptr [si+cabinet_open], 1
	jne	L08CA
	pop	ax
	push	OFFSET N_s3r3d4
L08CA:
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, ?, 30, 175, 2)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	cmp	byte ptr [si+cabinet_open], 1
	jne	L08F4
	push	0Eh
	push	RC_STOPANIM
	SERVICE		; StopAnim(14)
	add	sp, 4
L08F4:
	xor	byte ptr [si+cabinet_open], 1
	retf

H_08F9:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_092D
CabinetOpened:
	cmp	byte ptr [si+cabinet_open], 0
	je	L092C
	push	IT_ANTIGRA
	push	RC_HAVEITEM
	SERVICE		; HaveItem(IT_ANTIGRA)
	add	sp, 4
	AX8	cmp, 1
	je	L092C
	push	0
	push	0A7h
	push	1Fh
	push	OFFSET N_antigr
	push	0Eh
	push	RC_ANIM0
	SERVICE		; Anim0(14, "antigr", 31, 167, 0)
	add	sp, 0Ch
L092C:
	retf

; The wrench on the valve (msgs 1, 12): the gas feed on or off.
H_092D:
	SCRIPT	MSG_USE, IT_WRENCH, 0Bh, 0, H_0948
WrenchOnValve:
	push	1
	push	0B7h
	push	0A8h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 168, 183, 1)
	add	sp, 0Ah
	retf

H_0948:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_097D
KirkAtValve:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_kusehn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 12)
	add	sp, 0Ch
	jmp	SHORT L096D

N_MUR3E1S	LABEL	BYTE
	DB	'MUR3E1S',0
L096D:
	push	OFFSET N_MUR3E1S
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR3E1S")
	add	sp, 4
	retf

H_097D:
	SCRIPT	MSG_ANIM_DONE, 0Ch, 0, 0, H_09D1
ValveTurned:
	cmp	byte ptr [si+feed_on], 1
	je	L09AD
	mov	byte ptr [si+feed_on], 1
	push	0
	push	75h
	push	0ACh
	push	OFFSET N_s3r3v1
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s3r3v1", 172, 117, 0)
	add	sp, 0Ch
	mov	ax, OFFSET S_37CE
	mov	bx, OFFSET T_LOV2N008
	call	Say
	retf

L09AD:
	mov	byte ptr [si+feed_on], 0
	push	0
	push	75h
	push	0ACh
	push	OFFSET N_s3r3v2
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s3r3v2", 172, 117, 0)
	add	sp, 0Ch
	mov	ax, OFFSET S_37CE
	mov	bx, OFFSET T_LOV2N007
	call	Say
	retf

; Fitting a gas tank to the feed lines (msgs 3, 13, 14), only with the
; feed off and a slot free.
H_09D1:
	SCRIPT	MSG_USE, IT_O2GAS, 23h, 0, H_09ED
O2InSlot:
	mov	byte ptr cs:tank_gas, 1
	mov	word ptr cs:tank_anim, OFFSET N_o2can
	mov	word ptr cs:tank_item, 63h
	jmp	SHORT L0A23

H_09ED:
	SCRIPT	MSG_USE, IT_H2GAS, 23h, 0, H_0A09
H2InSlot:
	mov	byte ptr cs:tank_gas, 2
	mov	word ptr cs:tank_anim, OFFSET N_h2can
	mov	word ptr cs:tank_item, 64h
	jmp	SHORT L0A23

H_0A09:
	SCRIPT	MSG_USE, IT_N2GAS, 23h, 0, H_0A38
N2InSlot:
	mov	byte ptr cs:tank_gas, 3
	mov	word ptr cs:tank_anim, OFFSET N_n2can
	mov	word ptr cs:tank_item, 62h
L0A23:
	push	3
	push	0B7h
	push	0A8h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 168, 183, 3)
	add	sp, 0Ah
	retf

H_0A38:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_0AD1
KirkAtSlots:
	cmp	byte ptr [si+feed_on], 1
	jne	L0AB2
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_026
	call	Say
	jmp	SHORT L0AB1

T_LOV2_026	LABEL	BYTE
	DB	'#LOV2\LOV2_026#It would be very dangerous to place the tanks wit'
	DB	'hout first turning off the valve.',0
L0AB1:
	retf

L0AB2:
	cmp	byte ptr [si+tank1], 0
	je	L0ABB
	JMPN	L0B7A

L0ABB:
	push	0Dh
	push	-1
	push	-1
	push	OFFSET N_kusehn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 13)
	add	sp, 0Ch
	retf

H_0AD1:
	SCRIPT	MSG_ANIM_DONE, 0Dh, 0, 0, H_0BD8
Tank1Fitted:
	jmp	SHORT L0AE1

N_SE6FOOD	LABEL	BYTE
	DB	'SE6FOOD',0
L0AE1:
	push	OFFSET N_SE6FOOD
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SE6FOOD")
	add	sp, 4
	push	0
	push	0AEh
	push	0A7h
	push	word ptr cs:tank_anim
	push	0Ch
	push	RC_ANIM0
	SERVICE		; Anim0(12, ?, 167, 174, 0)
	add	sp, 0Ch
	mov	al, byte ptr cs:tank_gas
	mov	byte ptr [si+tank1], al
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N034
	call	Say
	jmp	SHORT L0B64

T_LOV2N034	LABEL	BYTE
	DB	'#LOV2\LOV2N034#You install the gas tank to the synthesizer''s fee'
	DB	'd lines.',0
L0B64:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L0B6A
L0B6A:
	push	word ptr cs:tank_item
	push	RC_TAKEITEM
	SERVICE		; TakeItem(?)
	add	sp, 4
	retf

L0B7A:
	cmp	byte ptr [si+tank2], 0
	je	L0BC2
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N024
	call	Say
	jmp	SHORT L0BC1

T_LOV2N024	LABEL	BYTE
	DB	'#LOV2\LOV2N024#There is no room for another canister.',0
L0BC1:
	retf

L0BC2:
	push	0Eh
	push	-1
	push	-1
	push	OFFSET N_kusehn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 14)
	add	sp, 0Ch
	retf

H_0BD8:
	SCRIPT	MSG_ANIM_DONE, 0Eh, 0, 0, H_0C68
Tank2Fitted:
	push	0
	push	0AFh
	push	0B1h
	push	word ptr cs:tank_anim
	push	0Dh
	push	RC_ANIM0
	SERVICE		; Anim0(13, ?, 177, 175, 0)
	add	sp, 0Ch
	mov	al, byte ptr cs:tank_gas
	mov	byte ptr [si+tank2], al
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N035
	call	Say
	jmp	SHORT L0C52

T_LOV2N035	LABEL	BYTE
	DB	'#LOV2\LOV2N035#You install the gas tank to the synthesizer''s fee'
	DB	'd lines.',0
L0C52:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L0C58
L0C58:
	push	word ptr cs:tank_item
	push	RC_TAKEITEM
	SERVICE		; TakeItem(?)
	add	sp, 4
	retf

; Moving a tank off its slot with the antigrav unit (msgs 4, 15, 5,
; 16), only with the feed off.
H_0C68:
	SCRIPT	MSG_USE, IT_ANTIGRA, 0Ch, 0, H_0C83
AntigravOnTank1:
	push	4
	push	0B7h
	push	0A8h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 168, 183, 4)
	add	sp, 0Ah
	retf

H_0C83:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_0D0B
KirkAtTank1:
	cmp	byte ptr [si+feed_on], 1
	jne	L0CF5
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_025
	call	Say
	jmp	SHORT L0CF4

T_LOV2_025	LABEL	BYTE
	DB	'#LOV2\LOV2_025#I would not recommend removing the canister witho'
	DB	'ut turning off the valve.',0
L0CF4:
	retf

L0CF5:
	push	0Fh
	push	-1
	push	-1
	push	OFFSET N_kusehn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 15)
	add	sp, 0Ch
	retf

H_0D0B:
	SCRIPT	MSG_ANIM_DONE, 0Fh, 0, 0, H_0DA2
Tank1Freed:
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N030
	call	Say
	jmp	SHORT L0D71

T_LOV2N030	LABEL	BYTE
	DB	'#LOV2\LOV2N030#You attach the antigrav unit to the gas tank. It '
	DB	'can be moved freely.',0
L0D71:
	push	0Ch
	push	RC_STOPANIM
	SERVICE		; StopAnim(12)
	add	sp, 4
	cmp	byte ptr [si+tank1], 1
	jne	L0D87
	push	IT_O2GAS
	jmp	SHORT L0D93

L0D87:
	cmp	byte ptr [si+tank1], 2
	jne	L0D91
	push	IT_H2GAS
	jmp	SHORT L0D93

L0D91:
	push	IT_N2GAS
L0D93:
	push	RC_GIVEITEM
	SERVICE		; GiveItem(?)
	add	sp, 4
	mov	byte ptr [si+tank1], 0
	retf

H_0DA2:
	SCRIPT	MSG_USE, IT_ANTIGRA, 0Dh, 0, H_0DBD
AntigravOnTank2:
	push	5
	push	0B7h
	push	0A8h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 168, 183, 5)
	add	sp, 0Ah
	retf

H_0DBD:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_0E5F
KirkAtTank2:
	cmp	byte ptr [si+feed_on], 1
	jne	L0E2F
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_025_2
	call	Say
	jmp	SHORT L0E2E

T_LOV2_025_2	LABEL	BYTE
	DB	'#LOV2\LOV2_025#I would not recommend removing the canister witho'
	DB	'ut turning off the valve.',0
L0E2E:
	retf

L0E2F:
	push	10h
	push	-1
	push	-1
	push	OFFSET N_kusehn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 16)
	add	sp, 0Ch
	jmp	SHORT L0E4F

N_SE3PLBAT	LABEL	BYTE
	DB	'SE3PLBAT',0
L0E4F:
	push	OFFSET N_SE3PLBAT
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SE3PLBAT")
	add	sp, 4
	retf

H_0E5F:
	SCRIPT	MSG_ANIM_DONE, 10h, 0, 0, H_0EF6
Tank2Freed:
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N031
	call	Say
	jmp	SHORT L0EC5

T_LOV2N031	LABEL	BYTE
	DB	'#LOV2\LOV2N031#You attach the antigrav unit to the gas tank. It '
	DB	'can be moved freely.',0
L0EC5:
	push	0Dh
	push	RC_STOPANIM
	SERVICE		; StopAnim(13)
	add	sp, 4
	cmp	byte ptr [si+tank2], 1
	jne	L0EDB
	push	IT_O2GAS
	jmp	SHORT L0EE7

L0EDB:
	cmp	byte ptr [si+tank2], 2
	jne	L0EE5
	push	IT_H2GAS
	jmp	SHORT L0EE7

L0EE5:
	push	IT_N2GAS
L0EE7:
	push	RC_GIVEITEM
	SERVICE		; GiveItem(?)
	add	sp, 4
	mov	byte ptr [si+tank2], 0
	retf

; Running the synthesizer (msgs 13, 17): with the feed on and two tanks,
; it makes a gas from the pair (O2+N2 N2O, H2+N2 ammonia, O2+H2 water)
; or, with something in the chamber, works on that: TLTDH from
; polyberylcarbonate, the cure from the cure sample, goo from the rest.
; With the feed off, after three tries Spock turns it on.
H_0EF6:
	SCRIPT	MSG_USE, OBJ_KIRK, 20h, 0, H_0F0C
KirkUsesSynthesizer:
	mov	word ptr cs:crew, 0
	mov	word ptr cs:crew_anim, OFFSET N_kusemn
	jmp	SHORT L0F4C

H_0F0C:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_0F22
SpockUsesSynthesizer:
	mov	word ptr cs:crew, 1
	mov	word ptr cs:crew_anim, OFFSET N_susemn
	jmp	SHORT L0F4C

H_0F22:
	SCRIPT	MSG_USE, OBJ_MCCOY, 20h, 0, H_0F38
McCoyUsesSynthesizer:
	mov	word ptr cs:crew, 2
	mov	word ptr cs:crew_anim, OFFSET N_musemn
	jmp	SHORT L0F4C

H_0F38:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 20h, 0, H_0F63
FerrisUsesSynthesizer:
	mov	word ptr cs:crew, 3
	mov	word ptr cs:crew_anim, OFFSET N_rusemn
L0F4C:
	push	0Dh
	push	0AEh
	push	46h
	push	word ptr cs:crew
	push	RC_WALK
	SERVICE		; Walk(?, 70, 174, 13)
	add	sp, 0Ah
	retf

H_0F63:
	SCRIPT	MSG_WALK_DONE, 0Dh, 0, 0, H_0F84
AtSynthesizer:
	push	11h
	push	-1
	push	-1
	push	word ptr cs:crew_anim
	push	word ptr cs:crew
	push	RC_ANIM2
	SERVICE		; Anim(?, ?, -1, -1, 17)
	add	sp, 0Ch
	retf

H_0F84:
	SCRIPT	MSG_ANIM_DONE, 11h, 0, 0, H_1083
Synthesize:
	cmp	byte ptr [si+feed_on], 1
	jne	L0F93
	JMPN	L110F

L0F93:
	cmp	byte ptr cs:dry_runs, 3
	je	L0F9E
	JMPN	L10DE

L0F9E:
	push	IT_WRENCH
	push	RC_HAVEITEM
	SERVICE		; HaveItem(IT_WRENCH)
	add	sp, 4
	or	ax, ax
	jne	L1003
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_006
	call	Say
	jmp	SHORT L1002

T_LOV2_006	LABEL	BYTE
	DB	'#LOV2\LOV2_006#Captain, I see the problem: the gas feeds are tur'
	DB	'ned off.',0
L1002:
	retf

L1003:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_005
	call	Say
	jmp	SHORT L106E

T_LOV2_005	LABEL	BYTE
	DB	'#LOV2\LOV2_005#Captain, I see the problem: the gas feeds are tur'
	DB	'ned off. If you''ll permit me...',0
L106E:
	push	10h
	push	0B7h
	push	0A8h
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 168, 183, 16)
	add	sp, 0Ah
	retf

H_1083:
	SCRIPT	MSG_WALK_DONE, 10h, 0, 0, H_109F
SpockAtValve:
	push	12h
	push	-1
	push	-1
	push	OFFSET N_susehn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susehn", -1, -1, 18)
	add	sp, 0Ch
	retf

H_109F:
	SCRIPT	MSG_ANIM_DONE, 12h, 0, 0, H_13C4
SpockTurnsValve:
	mov	byte ptr [si+feed_on], 1
	push	0
	push	75h
	push	0ACh
	push	OFFSET N_s3r3v1
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s3r3v1", 172, 117, 0)
	add	sp, 0Ch
	mov	ax, OFFSET S_37CE
	mov	bx, OFFSET T_LOV2N008
	call	Say
	push	0
	push	0BBh
	push	0C6h
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 198, 187, 0)
	add	sp, 0Ah
	jmp	SHORT L110F

L10DE:
	inc	byte ptr cs:dry_runs
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N012
	call	Say
	jmp	SHORT L110E

T_LOV2N012	LABEL	BYTE
	DB	'#LOV2\LOV2N012#Nothing Happens.',0
L110E:
	retf

L110F:
	cmp	byte ptr [si+tank1], 0
	je	L1118
	JMPN	L1202

L1118:
	jmp	SHORT L1120

N_EFX24	LABEL	BYTE
	DB	'EFX24',0
L1120:
	push	OFFSET N_EFX24
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EFX24")
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N005
	call	Say
	jmp	SHORT L1168

T_LOV2N005	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L1168:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_024
	call	Say
	JMPN	L1201

T_LOV2_024	LABEL	BYTE
	DB	'#LOV2\LOV2_024#I recommend we follow the design specifications o'
	DB	'f the machine. Two gas tanks should always be attached before ac'
	DB	'tivating it.',0
L1201:
	retf

L1202:
	cmp	byte ptr [si+tank2], 0
	je	L120B
	JMPN	L12E5

L120B:
	jmp	SHORT L1213

N_EFX24_2	LABEL	BYTE
	DB	'EFX24',0
L1213:
	push	OFFSET N_EFX24_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EFX24")
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N005_2
	call	Say
	jmp	SHORT L125B

T_LOV2N005_2	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L125B:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV2_010
	call	Say
	jmp	SHORT L12E4

T_LOV2_010	LABEL	BYTE
	DB	'#LOV2\LOV2_010#I think I''ll stick to combining two gases in futu'
	DB	're experiments. That''s how the machine''s designed, after all.',0
L12E4:
	retf

L12E5:
	cmp	byte ptr [si+tank1], 1
	jne	L12F5
	cmp	byte ptr [si+tank2], 2
	jne	L12F3
	jmp	SHORT L130F

L12F3:
	jmp	SHORT L1371

L12F5:
	cmp	byte ptr [si+tank1], 2
	jne	L1305
	cmp	byte ptr [si+tank2], 1
	jne	L1303
	jmp	SHORT L130F

L1303:
	jmp	SHORT L1340

L1305:
	cmp	byte ptr [si+tank2], 1
	jne	L130D
	jmp	SHORT L1371

L130D:
	jmp	SHORT L1340

L130F:
	cmp	byte ptr [si+chamber], 1
	jne	L1318
	JMPN	L1987

L1318:
	cmp	byte ptr [si+chamber], 2
	jne	L1321
	JMPN	L19C9

L1321:
	cmp	byte ptr [si+chamber], 3
	jne	L132A
	JMPN	L1A6F

L132A:
	cmp	byte ptr [si+chamber], 9
	jne	L1333
	JMPN	L1B0D

L1333:
	mov	byte ptr [si+gas_made], 3
	mov	word ptr cs:gas_anim, OFFSET N_btle3
	jmp	SHORT L13A0

L1340:
	cmp	byte ptr [si+chamber], 1
	jne	L1349
	JMPN	L1B6E

L1349:
	cmp	byte ptr [si+chamber], 2
	jne	L1352
	JMPN	L1C1E

L1352:
	cmp	byte ptr [si+chamber], 3
	jne	L135B
	JMPN	L1EB8

L135B:
	cmp	byte ptr [si+chamber], 9
	jne	L1364
	JMPN	L1B0D

L1364:
	mov	byte ptr [si+gas_made], 2
	mov	word ptr cs:gas_anim, OFFSET N_btle2
	jmp	SHORT L13A0

L1371:
	cmp	byte ptr [si+chamber], 1
	jne	L137A
	JMPN	L1B6E

L137A:
	cmp	byte ptr [si+chamber], 2
	jne	L1383
	JMPN	L1DB5

L1383:
	cmp	byte ptr [si+chamber], 3
	jne	L138C
	JMPN	L1A6F

L138C:
	cmp	byte ptr [si+chamber], 9
	jne	L1395
	JMPN	L1B0D

L1395:
	mov	byte ptr [si+gas_made], 1
	mov	word ptr cs:gas_anim, OFFSET N_btle1
L13A0:
	push	3
	push	8Dh
	push	8Ah
	push	OFFSET N_s3r3d2
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s3r3d2", 138, 141, 3)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	retf

; The results come out of the chamber (anim msgs 3, 4, 27, 8-10).
H_13C4:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_1401
ChamberOpensGas:
	jmp	SHORT L13D4

N_LD1SCAN	LABEL	BYTE
	DB	'LD1SCAN',0
L13D4:
	push	OFFSET N_LD1SCAN
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("LD1SCAN")
	add	sp, 4
	push	4
	push	8Dh
	push	8Ah
	push	word ptr cs:gas_anim
	push	0Fh
	push	RC_ANIM0
	SERVICE		; Anim0(15, ?, 138, 141, 4)
	add	sp, 0Ch
	mov	byte ptr [si+chamber], 9
	retf

H_1401:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_19B5
GasMade:
	cmp	byte ptr [si+gas_made], 1
	je	L1410
	JMPN	L159F

L1410:
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N017
	call	Say
	jmp	SHORT L145C

T_LOV2N017	LABEL	BYTE
	DB	'#LOV2\LOV2N017#The machine synthesizes a liter of nitrous oxide.',0
L145C:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_032
	call	Say
	JMPN	L14F6

T_LOV2_032	LABEL	BYTE
	DB	'#LOV2\LOV2_032#Be careful with that canister, Captain. I think y'
	DB	'ou would not care to fall under the effects of laughing gas in t'
	DB	'hese straits.',0
L14F6:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV2_015
	call	Say
	jmp	SHORT L153C

T_LOV2_015	LABEL	BYTE
	DB	'#LOV2\LOV2_015#Do you mean to say it''s undignified, Spock?',0
L153C:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_036
	call	Say
	jmp	SHORT L159E

T_LOV2_036	LABEL	BYTE
	DB	'#LOV2\LOV2_036#It is, at the least, inappropriate for a starship'
	DB	' crew on duty, Doctor.',0
L159E:
	retf

L159F:
	cmp	byte ptr [si+gas_made], 2
	je	L15A8
	JMPN	L16A0

L15A8:
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N016
	call	Say
	jmp	SHORT L15EE

T_LOV2N016	LABEL	BYTE
	DB	'#LOV2\LOV2N016#The machine synthesizes a liter of ammonia.',0
L15EE:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L15F7
	JMPN	L169F

L15F7:
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV2_043
	call	Say
	jmp	SHORT L164F

T_LOV2_043	LABEL	BYTE
	DB	'#LOV2\LOV2_043#I hope you don''t want me to swab the deck with th'
	DB	'at, Captain.',0
L164F:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV2_003
	call	Say
	jmp	SHORT L169F

T_LOV2_003	LABEL	BYTE
	DB	'#LOV2\LOV2_003#I think we can set this aside and not worry about'
	DB	' it.',0
L169F:
	retf

L16A0:
	cmp	byte ptr [si+gas_made], 3
	je	L16A9
	JMPN	L1772

L16A9:
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N018
	call	Say
	jmp	SHORT L16F2

T_LOV2N018	LABEL	BYTE
	DB	'#LOV2\LOV2N018#The machine synthesizes a liter of pure water.',0
L16F2:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_004
	call	Say
	jmp	SHORT L1771

T_LOV2_004	LABEL	BYTE
	DB	'#LOV2\LOV2_004#A clean drink of water, but I don''t see its appli'
	DB	'cation in the context of our difficulties, Captain.',0
L1771:
	retf

L1772:
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N019
	call	Say
	jmp	SHORT L17BC

T_LOV2N019	LABEL	BYTE
	DB	'#LOV2\LOV2N019#The machine synthesizes one liter of TLTDH gas.',0
L17BC:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_031
	call	Say
	JMPN	L185D

T_LOV2_031	LABEL	BYTE
	DB	'#LOV2\LOV2_031#An unusual compound, Captain. It can induce laugh'
	DB	'ter and feelings of exhiliration in some, much the way nitrous o'
	DB	'xide affects humans.',0
L185D:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV2_018
	call	Say
	jmp	SHORT L189D

T_LOV2_018	LABEL	BYTE
	DB	'#LOV2\LOV2_018#It doesn''t affect Vulcans, of course.',0
L189D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_030
	call	Say
	jmp	SHORT L18F7

T_LOV2_030	LABEL	BYTE
	DB	'#LOV2\LOV2_030#Actually, Doctor, both Romulans and Vulcans suffe'
	DB	'r its effects.',0
L18F7:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV2_022
	call	Say
	jmp	SHORT L193D

T_LOV2_022	LABEL	BYTE
	DB	'#LOV2\LOV2_022#Why that''s just dandy! Vulcan laughing gas!',0
L193D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_038
	call	Say
	jmp	SHORT L1986

T_LOV2_038	LABEL	BYTE
	DB	'#LOV2\LOV2_038#Please, Doctor. This is not a laughing matter.',0
L1986:
	retf

L1987:
	push	1Bh
	push	-1
	push	-1
	push	OFFSET N_s3r3d5
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s3r3d5", -1, -1, 27)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	push	10h
	push	RC_STOPANIM
	SERVICE		; StopAnim(16)
	add	sp, 4
	retf

H_19B5:
	SCRIPT	MSG_ANIM_DONE, 1Bh, 0, 0, H_1EE8
ChamberResult:
	mov	byte ptr [si+gas_made], 4
	mov	word ptr cs:gas_anim, OFFSET N_btle4
	JMPN	L13A0

L19C9:
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N051
	call	Say
	jmp	SHORT L1A17

T_LOV2N051	LABEL	BYTE
	DB	'#LOV2\LOV2N051#The machine synthesizes a quantity of wet grey go'
	DB	'o.',0
L1A17:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV2_002
	call	Say
	jmp	SHORT L1A60

T_LOV2_002	LABEL	BYTE
	DB	'#LOV2\LOV2_002#I think we can call that one a failure, Bones.',0
L1A60:
	push	11h
	push	RC_STOPANIM
	SERVICE		; StopAnim(17)
	add	sp, 4
	JMPN	L1E90

L1A6F:
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N050
	call	Say
	jmp	SHORT L1ABD

T_LOV2N050	LABEL	BYTE
	DB	'#LOV2\LOV2N050#The machine synthesizes a quantity of wet grey go'
	DB	'o.',0
L1ABD:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV2_021
	call	Say
	jmp	SHORT L1AFE

T_LOV2_021	LABEL	BYTE
	DB	'#LOV2\LOV2_021#We must be doing something wrong, Jim.',0
L1AFE:
	push	12h
	push	RC_STOPANIM
	SERVICE		; StopAnim(18)
	add	sp, 4
	JMPN	L1E90

L1B0D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_028
	call	Say
	jmp	SHORT L1B6D

T_LOV2_028	LABEL	BYTE
	DB	'#LOV2\LOV2_028#The machine does not seem to be able to process t'
	DB	'hat particular item.',0
L1B6D:
	retf

L1B6E:
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N049
	call	Say
	jmp	SHORT L1BBC

T_LOV2N049	LABEL	BYTE
	DB	'#LOV2\LOV2N049#The machine synthesizes a quantity of inert matte'
	DB	'r.',0
L1BBC:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_1BC7
	call	Say
	jmp	SHORT L1C0F

S_1BC7	LABEL	BYTE
	DB	'#LOV2\LOV2-039#This does not appear to provide us with anything '
	DB	'useful.',0
L1C0F:
	push	10h
	push	RC_STOPANIM
	SERVICE		; StopAnim(16)
	add	sp, 4
	JMPN	L1E90

L1C1E:
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N048
	call	Say
	jmp	SHORT L1C6D

T_LOV2N048	LABEL	BYTE
	DB	'#LOV2\LOV2N048#The machine synthesizes a quantity of colorless g'
	DB	'oo.',0
L1C6D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_1C78
	call	Say
	jmp	SHORT L1CBF

S_1C78	LABEL	BYTE
	DB	'#LOV2\LOV2-034#I don''t think that''s useful in your experiment, D'
	DB	'octor.',0
L1CBF:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV2_023
	call	Say
	JMPN	L1DA6

T_LOV2_023	LABEL	BYTE
	DB	'#LOV2\LOV2_023#You''re wrong, Spock. Look... the virus culture ha'
	DB	's been eliminated. That''s why it''s clear. It''d be more useful fo'
	DB	'r me to see how the virus might grow in the presence of a limite'
	DB	'd quantity of ammonia gas.',0
L1DA6:
	push	11h
	push	RC_STOPANIM
	SERVICE		; StopAnim(17)
	add	sp, 4
	JMPN	L1E90

L1DB5:
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N047
	call	Say
	jmp	SHORT L1E08

T_LOV2N047	LABEL	BYTE
	DB	'#LOV2\LOV2N047#The machine synthesizes a quantity of bubbling gr'
	DB	'ey goo.',0
L1E08:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV2_017
	call	Say
	jmp	SHORT L1E82

T_LOV2_017	LABEL	BYTE
	DB	'#LOV2\LOV2_017#I think I''d have more luck hypergrowing the virus'
	DB	' in the presence of a limited quantity of gas.',0
L1E82:
	push	11h
	push	RC_STOPANIM
	SERVICE		; StopAnim(17)
	add	sp, 4
	jmp	SHORT L1E90

L1E90:
	push	0
	push	8Dh
	push	8Ah
	push	OFFSET N_s3r3d5
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s3r3d5", 138, 141, 0)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	mov	byte ptr [si+chamber], 0
	retf

L1EB8:
	push	12h
	push	RC_STOPANIM
	SERVICE		; StopAnim(18)
	add	sp, 4
	push	8
	push	8Dh
	push	8Ah
	push	OFFSET N_s3r3d5
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s3r3d5", 138, 141, 8)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	retf

H_1EE8:
	SCRIPT	MSG_ANIM_DONE, 8, 0, 0, H_1F12
ChamberOpensCure:
	push	9
	push	8Dh
	push	8Ah
	push	OFFSET N_s3r3d2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s3r3d2", 138, 141, 9)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	retf

H_1F12:
	SCRIPT	MSG_ANIM_DONE, 9, 0, 0, H_1F34
CureAppears:
	push	0Ah
	push	8Bh
	push	8Ah
	push	OFFSET N_cure
	push	13h
	push	RC_ANIM0
	SERVICE		; Anim0(19, "cure", 138, 139, 10)
	add	sp, 0Ch
	mov	byte ptr [si+chamber], 9
	retf

H_1F34:
	SCRIPT	MSG_ANIM_DONE, 0Ah, 0, 0, H_1FF1
CureMade:
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N046
	call	Say
	jmp	SHORT L1F88

T_LOV2N046	LABEL	BYTE
	DB	'#LOV2\LOV2N046#The machine synthesizes a quantity serum in a hyp'
	DB	'o.',0
L1F88:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV2_020
	call	Say
	jmp	SHORT L1FF0

T_LOV2_020	LABEL	BYTE
	DB	'#LOV2\LOV2_020#That''s it, Jim. We''ve got enough serum here to cu'
	DB	're everybody on the station!',0
L1FF0:
	retf

; Putting things in the chamber (msgs 6-8, 5-7, 19-21).
H_1FF1:
	SCRIPT	MSG_USE, IT_PBC, 9, 0, H_2010
PBCInChamber:
	push	6
	push	0ADh
	push	85h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 133, 173, 6)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL], 0
	retf

H_2010:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_2086
KirkAtChamber:
	cmp	byte ptr [si+chamber], 0
	je	L2062
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N025
	call	Say
	jmp	SHORT L2061

T_LOV2N025	LABEL	BYTE
	DB	'#LOV2\LOV2N025#There is something already in the chamber.',0
L2061:
	retf

L2062:
	push	5
	push	8Dh
	push	8Ah
	push	OFFSET N_s3r3d2
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s3r3d2", 138, 141, 5)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	retf

H_2086:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_20A2
ChamberOpen:
	push	13h
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 19)
	add	sp, 0Ch
	retf

H_20A2:
	SCRIPT	MSG_ANIM_DONE, 13h, 0, 0, H_20D0
PBCIn:
	push	0
	push	8Bh
	push	8Ah
	push	OFFSET N_pbcanm
	push	10h
	push	RC_ANIM0
	SERVICE		; Anim0(16, "pbcanm", 138, 139, 0)
	add	sp, 0Ch
	push	IT_PBC
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_PBC)
	add	sp, 4
	mov	byte ptr [si+chamber], 1
	retf

H_20D0:
	SCRIPT	MSG_USE, IT_DISHES, 9, 0, H_20EF
DishesInChamber:
	push	7
	push	0ADh
	push	85h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 133, 173, 7)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL], 0
	retf

H_20EF:
	SCRIPT	MSG_WALK_DONE, 7, 0, 0, H_2165
KirkAtChamber2:
	cmp	byte ptr [si+chamber], 0
	je	L2141
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N025_2
	call	Say
	jmp	SHORT L2140

T_LOV2N025_2	LABEL	BYTE
	DB	'#LOV2\LOV2N025#There is something already in the chamber.',0
L2140:
	retf

L2141:
	push	6
	push	8Dh
	push	8Ah
	push	OFFSET N_s3r3d2
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s3r3d2", 138, 141, 6)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	retf

H_2165:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_2181
ChamberOpen2:
	push	14h
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 20)
	add	sp, 0Ch
	retf

H_2181:
	SCRIPT	MSG_ANIM_DONE, 14h, 0, 0, H_21AF
DishesIn:
	push	0
	push	8Bh
	push	8Ah
	push	OFFSET N_dishes
	push	11h
	push	RC_ANIM0
	SERVICE		; Anim0(17, "dishes", 138, 139, 0)
	add	sp, 0Ch
	push	IT_DISHES
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_DISHES)
	add	sp, 4
	mov	byte ptr [si+chamber], 2
	retf

H_21AF:
	SCRIPT	MSG_USE, IT_SAMPLE, 9, 0, H_21CE
SampleInChamber:
	push	8
	push	0ADh
	push	85h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 133, 173, 8)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL], 0
	retf

H_21CE:
	SCRIPT	MSG_WALK_DONE, 8, 0, 0, H_2235
KirkAtChamber3:
	cmp	byte ptr [si+chamber], 0
	je	L2211
	mov	ax, 0
	mov	bx, OFFSET S_21E5
	call	Say
	jmp	SHORT L2210

S_21E5	LABEL	BYTE
	DB	'There is something already in the chamber.',0
L2210:
	retf

L2211:
	push	7
	push	8Dh
	push	8Ah
	push	OFFSET N_s3r3d2
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s3r3d2", 138, 141, 7)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	retf

H_2235:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_2251
ChamberOpen3:
	push	15h
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 21)
	add	sp, 0Ch
	retf

H_2251:
	SCRIPT	MSG_ANIM_DONE, 15h, 0, 0, H_227F
SampleIn:
	push	0
	push	8Bh
	push	8Ah
	push	OFFSET N_dishes_2
	push	12h
	push	RC_ANIM0
	SERVICE		; Anim0(18, "dishes", 138, 139, 0)
	add	sp, 0Ch
	push	IT_SAMPLE
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_SAMPLE)
	add	sp, 4
	mov	byte ptr [si+chamber], 3
	retf

; Other things.
H_227F:
	SCRIPT	MSG_USE, ANY, 9, 0, H_22D4
UseChamber:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV2_014
	call	Say
	jmp	SHORT L22D3

T_LOV2_014	LABEL	BYTE
	DB	'#LOV2\LOV2_014#That''s not the right material to put in there, Ji'
	DB	'm.',0
L22D3:
	retf

H_22D4:
	SCRIPT	MSG_USE, ANY, 20h, 0, H_2343
UseSynthesizer:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV2_007
	call	Say
	jmp	SHORT L2342

T_LOV2_007	LABEL	BYTE
	DB	'#LOV2\LOV2_007#Fascinating, Captain, but it doesn''t appear to ge'
	DB	't us any closer to our goal.',0
L2342:
	retf

; Getting things: the tanks are too heavy; the antigrav unit; whatever
; is in the chamber (the first gas +4, the cure +5, once).
H_2343:
	SCRIPT	MSG_GET, 0Dh, 0, 0, H_234B
	jmp	SHORT GetTank

H_234B:
	SCRIPT	MSG_GET, 0Ch, 0, 0, H_23EF
GetTank:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L239E
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV2_040
	call	Say
	jmp	SHORT L239D

T_LOV2_040	LABEL	BYTE
	DB	'#LOV2\LOV2_040#The can looks much too heavy to carry, sir.',0
L239D:
	retf

L239E:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV2_011
	call	Say
	jmp	SHORT L23EE

T_LOV2_011	LABEL	BYTE
	DB	'#LOV2\LOV2_011#I wouldn''t try to lift that. You might hurt yours'
	DB	'elf.',0
L23EE:
	retf

H_23EF:
	SCRIPT	MSG_GET, 0Eh, 0, 0, H_2409
GetAntigrav:
	push	9
	push	0B4h
	push	37h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 55, 180, 9)
	add	sp, 0Ah
	retf

H_2409:
	SCRIPT	MSG_WALK_DONE, 9, 0, 0, H_2429
KirkAtAntigrav:
	push	16h
	push	-1
	push	-1
	push	OFFSET N_kusehw
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehw", -1, -1, 22)
	add	sp, 0Ch
	mov	byte ptr [si+RS_FALL], 3
	retf

H_2429:
	SCRIPT	MSG_ANIM_DONE, 16h, 0, 0, H_247E
TookAntigrav:
	push	0Eh
	push	RC_STOPANIM
	SERVICE		; StopAnim(14)
	add	sp, 4
	push	IT_ANTIGRA
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_ANTIGRA)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N042
	call	Say
	jmp	SHORT L247D

T_LOV2N042	LABEL	BYTE
	DB	'#LOV2\LOV2N042#You take the antigrav unit.',0
L247D:
	retf

H_247E:
	SCRIPT	MSG_GET, 10h, 0, 0, H_249D
GetPBC:
	push	12h
	push	0ADh
	push	85h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 133, 173, 18)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL], 0
	retf

H_249D:
	SCRIPT	MSG_WALK_DONE, 12h, 0, 0, H_24B9
KirkAtPBC:
	push	1Ah
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 26)
	add	sp, 0Ch
	retf

H_24B9:
	SCRIPT	MSG_ANIM_DONE, 1Ah, 0, 0, H_253A
TookPBC:
	push	10h
	push	RC_STOPANIM
	SERVICE		; StopAnim(16)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N044
	call	Say
	jmp	SHORT L2506

T_LOV2N044	LABEL	BYTE
	DB	'#LOV2\LOV2N044#You take the Polyberylcarbonate.',0
L2506:
	push	IT_PBC
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_PBC)
	add	sp, 4
	mov	byte ptr [si+chamber], 0
	push	0
	push	8Dh
	push	8Ah
	push	OFFSET N_s3r3d5
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s3r3d5", 138, 141, 0)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	retf

H_253A:
	SCRIPT	MSG_GET, 11h, 0, 0, H_2559
GetDishes:
	push	11h
	push	0ADh
	push	85h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 133, 173, 17)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL], 0
	retf

H_2559:
	SCRIPT	MSG_WALK_DONE, 11h, 0, 0, H_2575
KirkAtDishes:
	push	19h
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 25)
	add	sp, 0Ch
	retf

H_2575:
	SCRIPT	MSG_ANIM_DONE, 19h, 0, 0, H_25F3
TookDishes:
	push	11h
	push	RC_STOPANIM
	SERVICE		; StopAnim(17)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N036
	call	Say
	jmp	SHORT L25BF

T_LOV2N036	LABEL	BYTE
	DB	'#LOV2\LOV2N036#Oroborus virus culture taken.',0
L25BF:
	push	IT_DISHES
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_DISHES)
	add	sp, 4
	mov	byte ptr [si+chamber], 0
	push	0
	push	8Dh
	push	8Ah
	push	OFFSET N_s3r3d5
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s3r3d5", 138, 141, 0)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	retf

H_25F3:
	SCRIPT	MSG_GET, 12h, 0, 0, H_2612
GetSample:
	push	13h
	push	0ADh
	push	85h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 133, 173, 19)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL], 0
	retf

H_2612:
	SCRIPT	MSG_WALK_DONE, 13h, 0, 0, H_262E
KirkAtSample:
	push	1Ch
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 28)
	add	sp, 0Ch
	retf

H_262E:
	SCRIPT	MSG_ANIM_DONE, 1Ch, 0, 0, H_26B0
TookSample:
	push	12h
	push	RC_STOPANIM
	SERVICE		; StopAnim(18)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N037
	call	Say
	jmp	SHORT L267C

T_LOV2N037	LABEL	BYTE
	DB	'#LOV2\LOV2N037#Oroborus virus cure sample taken.',0
L267C:
	push	IT_SAMPLE
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_SAMPLE)
	add	sp, 4
	mov	byte ptr [si+chamber], 0
	push	0
	push	8Dh
	push	8Ah
	push	OFFSET N_s3r3d5
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s3r3d5", 138, 141, 0)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	retf

H_26B0:
	SCRIPT	MSG_GET, 0Fh, 0, 0, H_26CF
GetGas:
	push	0Ah
	push	0ADh
	push	85h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 133, 173, 10)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL], 0
	retf

H_26CF:
	SCRIPT	MSG_WALK_DONE, 0Ah, 0, 0, H_26EB
KirkAtGas:
	push	17h
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 23)
	add	sp, 0Ch
	retf

H_26EB:
	SCRIPT	MSG_ANIM_DONE, 17h, 0, 0, H_2882
TookGas:
	cmp	byte ptr [si+gas_made], 1
	jne	L2747
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N040
	call	Say
	jmp	SHORT L2742

T_LOV2N040	LABEL	BYTE
	DB	'#LOV2\LOV2N040#You take a one litre container of Nitrous Oxide.',0
L2742:
	push	IT_N2O
	JMPN	L2840

L2747:
	cmp	byte ptr [si+gas_made], 2
	jne	L2797
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N039
	call	Say
	jmp	SHORT L2792

T_LOV2N039	LABEL	BYTE
	DB	'#LOV2\LOV2N039#You take a one litre container of Ammonia.',0
L2792:
	push	IT_NH3
	JMPN	L2840

L2797:
	cmp	byte ptr [si+gas_made], 3
	jne	L27E9
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N041
	call	Say
	jmp	SHORT L27E5

T_LOV2N041	LABEL	BYTE
	DB	'#LOV2\LOV2N041#You take a one litre container of pure water.',0
L27E5:
	push	IT_H2O
	jmp	SHORT L2840

L27E9:
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N038
	call	Say
	jmp	SHORT L2830

T_LOV2N038	LABEL	BYTE
	DB	'#LOV2\LOV2N038#You take a one litre container of TLTDH gas.',0
L2830:
	cmp	byte ptr [si+took_gas], 1
	je	L283E
	mov	byte ptr [si+took_gas], 1
	add	word ptr [si+score], 4
L283E:
	push	IT_RLG
L2840:
	push	RC_GIVEITEM
	SERVICE		; GiveItem(?)
	add	sp, 4
	push	0Fh
	push	RC_STOPANIM
	SERVICE		; StopAnim(15)
	add	sp, 4
	push	0
	push	8Dh
	push	8Ah
	push	OFFSET N_s3r3d5
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s3r3d5", 138, 141, 0)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	mov	byte ptr [si+chamber], 0
	mov	byte ptr [si+gas_made], 0
	retf

H_2882:
	SCRIPT	MSG_GET, 13h, 0, 0, H_28A1
GetCure:
	push	0Bh
	push	0ADh
	push	85h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 133, 173, 11)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL], 0
	retf

H_28A1:
	SCRIPT	MSG_WALK_DONE, 0Bh, 0, 0, H_28BD
KirkAtCure:
	push	18h
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 24)
	add	sp, 0Ch
	retf

H_28BD:
	SCRIPT	MSG_ANIM_DONE, 18h, 0, 0, H_2968
TookCure:
	cmp	byte ptr [si+made_cure], 1
	je	L28D1
	mov	byte ptr [si+made_cure], 1
	add	word ptr [si+score], 5
L28D1:
	push	IT_CURE
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_CURE)
	add	sp, 4
	push	13h
	push	RC_STOPANIM
	SERVICE		; StopAnim(19)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_LOV2N043
	call	Say
	jmp	SHORT L292F

T_LOV2N043	LABEL	BYTE
	DB	'#LOV2\LOV2N043#You take the hypo with Oroborus toxin cure.',0
L292F:
	push	0
	push	8Dh
	push	8Ah
	push	OFFSET N_s3r3d5
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s3r3d5", 138, 141, 0)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	mov	byte ptr [si+chamber], 0
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
H_2968:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_2B85
CrewLaugh:
	push	2
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 2)
	add	sp, 6
	mov	word ptr cs:roll, ax
	cmp	word ptr cs:roll, 0
	jne	L2991
	mov	word ptr cs:laugher, OFFSET N_Dr_McCoy
	jmp	SHORT L29CE

L2991:
	cmp	word ptr cs:roll, 1
	jne	L29B2
	mov	word ptr cs:laugher, OFFSET N_Lt_Ferris
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L29B0
	mov	word ptr cs:laugher, OFFSET N_Dr_McCoy
	JMPN	L2A79

L29B0:
	jmp	SHORT L29CE

L29B2:
	mov	ax, 0
	mov	bx, OFFSET N_get_name_error
	call	Say
	jmp	SHORT L29CD

N_get_name_error	LABEL	BYTE
	DB	'get name error.',0
L29CD:
	retf

L29CE:
	mov	word ptr cs:laugher, OFFSET N_Dr_McCoy
	push	0Ah
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 10)
	add	sp, 6
	mov	word ptr cs:roll, ax
	cmp	word ptr cs:roll, 0
	jne	L29F5
	mov	bx, OFFSET T_LOV0_011
	JMPN	L2B20

L29F5:
	cmp	word ptr cs:roll, 1
	jne	L2A03
	mov	bx, OFFSET T_LOV0_020
	JMPN	L2B20

L2A03:
	cmp	word ptr cs:roll, 2
	jne	L2A11
	mov	bx, OFFSET T_LOV0_016
	JMPN	L2B20

L2A11:
	cmp	word ptr cs:roll, 3
	jne	L2A1F
	mov	bx, OFFSET T_LOV0_012
	JMPN	L2B20

L2A1F:
	cmp	word ptr cs:roll, 4
	jne	L2A2D
	mov	bx, OFFSET T_LOV0_014
	JMPN	L2B20

L2A2D:
	cmp	word ptr cs:roll, 5
	jne	L2A3B
	mov	bx, OFFSET T_LOV0_022
	JMPN	L2B20

L2A3B:
	cmp	word ptr cs:roll, 6
	jne	L2A49
	mov	bx, OFFSET T_LOV0_015
	JMPN	L2B20

L2A49:
	cmp	word ptr cs:roll, 7
	jne	L2A57
	mov	bx, OFFSET T_LOV0_021
	JMPN	L2B20

L2A57:
	cmp	word ptr cs:roll, 8
	jne	L2A65
	mov	bx, OFFSET T_LOV0_013
	JMPN	L2B20

L2A65:
	cmp	word ptr cs:roll, 9
	jne	L2A73
	mov	bx, OFFSET T_LOV0_019
	JMPN	L2B20

L2A73:
	mov	bx, OFFSET T_LOV0_017
	JMPN	L2B20

L2A79:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L2A80
	retf

L2A80:
	mov	word ptr cs:laugher, OFFSET N_Lt_Ferris
	push	0Ah
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 10)
	add	sp, 6
	mov	word ptr cs:roll, ax
	cmp	word ptr cs:roll, 0
	jne	L2AA6
	mov	bx, OFFSET T_LOV0_039
	jmp	SHORT L2B20

L2AA6:
	cmp	word ptr cs:roll, 1
	jne	L2AB3
	mov	bx, OFFSET T_LOV0_048
	jmp	SHORT L2B20

L2AB3:
	cmp	word ptr cs:roll, 2
	jne	L2AC0
	mov	bx, OFFSET T_LOV0_045
	jmp	SHORT L2B20

L2AC0:
	cmp	word ptr cs:roll, 3
	jne	L2ACD
	mov	bx, OFFSET T_LOV0_040
	jmp	SHORT L2B20

L2ACD:
	cmp	word ptr cs:roll, 4
	jne	L2ADA
	mov	bx, OFFSET T_LOV0_042
	jmp	SHORT L2B20

L2ADA:
	cmp	word ptr cs:roll, 5
	jne	L2AE7
	mov	bx, OFFSET T_LOV0_050
	jmp	SHORT L2B20

L2AE7:
	cmp	word ptr cs:roll, 6
	jne	L2AF4
	mov	bx, OFFSET T_LOV0_043
	jmp	SHORT L2B20

L2AF4:
	cmp	word ptr cs:roll, 7
	jne	L2B01
	mov	bx, OFFSET T_LOV0_049
	jmp	SHORT L2B20

L2B01:
	cmp	word ptr cs:roll, 8
	jne	L2B0E
	mov	bx, OFFSET T_LOV0_041
	jmp	SHORT L2B20

L2B0E:
	cmp	word ptr cs:roll, 9
	jne	L2B1B
	mov	bx, OFFSET T_LOV0_047
	jmp	SHORT L2B20

L2B1B:
	mov	bx, OFFSET T_LOV0_046
	jmp	SHORT L2B20

L2B20:
	mov	ax, word ptr cs:laugher
	call	Say
	cmp	byte ptr [si+rlg_released], 1
	jne	L2B2E
	retf

L2B2E:
	push	3
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 3)
	add	sp, 6
	mov	word ptr cs:roll, ax
	mov	ax, OFFSET N_Mr_Spock
	cmp	word ptr cs:roll, 0
	jne	L2B50
	mov	bx, OFFSET T_LOV0_029
	jmp	SHORT L2B6F

L2B50:
	cmp	word ptr cs:roll, 1
	jne	L2B5D
	mov	bx, OFFSET T_LOV0_033
	jmp	SHORT L2B6F

L2B5D:
	cmp	word ptr cs:roll, 2
	jne	L2B6A
	mov	bx, OFFSET T_LOV0_026
	jmp	SHORT L2B6F

L2B6A:
	mov	bx, OFFSET T_LOV0_124
	jmp	SHORT L2B6F

L2B6F:
	call	Say
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS], ax
	retf

; Timer 1 (after Romulan laughing gas): Spock laughs.
H_2B85:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_2C17
SpockLaughs:
	push	7
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 7)
	add	sp, 6
	mov	word ptr cs:roll, ax
	mov	ax, OFFSET N_Mr_Spock
	cmp	word ptr cs:roll, 0
	jne	L2BAD
	mov	bx, OFFSET T_LOV0_025
	jmp	SHORT L2C00

L2BAD:
	cmp	word ptr cs:roll, 1
	jne	L2BBA
	mov	bx, OFFSET T_LOV0_101
	jmp	SHORT L2C00

L2BBA:
	cmp	word ptr cs:roll, 2
	jne	L2BC7
	mov	bx, OFFSET T_LOV0_102
	jmp	SHORT L2C00

L2BC7:
	cmp	word ptr cs:roll, 3
	jne	L2BD4
	mov	bx, OFFSET T_LOV0_103
	jmp	SHORT L2C00

L2BD4:
	cmp	word ptr cs:roll, 4
	jne	L2BE1
	mov	bx, OFFSET T_LOV0_104
	jmp	SHORT L2C00

L2BE1:
	cmp	word ptr cs:roll, 5
	jne	L2BEE
	mov	bx, OFFSET T_LOV0_105
	jmp	SHORT L2C00

L2BEE:
	cmp	word ptr cs:roll, 6
	jne	L2BFB
	mov	bx, OFFSET T_LOV0_106
	jmp	SHORT L2C00

L2BFB:
	mov	bx, OFFSET T_LOV0_107
	jmp	SHORT L2C00

L2C00:
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
H_2C17:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_SPOCK, 0, H_2CA5
MedkitOnSpock:
	cmp	byte ptr [si+spock_cured], 1
	je	L2C71
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_019
	call	Say
	jmp	SHORT L2C70

T_LOV5_019	LABEL	BYTE
	DB	'#LOV5\LOV5_019#I don''t have the proper medicine to cure him, Jim'
	DB	'.',0
L2C70:
	retf

L2C71:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_015
	call	Say
	jmp	SHORT L2CA4

T_LOV5_015	LABEL	BYTE
	DB	'#LOV5\LOV5_015#He''s already cured, Jim.',0
L2CA4:
	retf

H_2CA5:
	SCRIPT	MSG_USE, IT_SAMPLE, OBJ_SPOCK, 0, H_2D18
SampleOnSpock:
	cmp	byte ptr [si+spock_cured], 1
	jne	L2CB4
	JMPN	L2D58

L2CB4:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F55
	call	Say
	jmp	SHORT L2D17

T_LOVA_F55	LABEL	BYTE
	DB	'#LOVA\LOVA_F55#Jim, we need to sysnthesize more to make the seru'
	DB	'm before we can use it.',0
L2D17:
	retf

H_2D18:
	SCRIPT	MSG_USE, IT_CURE, OBJ_SPOCK, 0, H_2D94
CureSpock:
	cmp	byte ptr [si+spock_cured], 1
	jne	L2D58
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_015_2
	call	Say
	jmp	SHORT L2D57

T_LOV5_015_2	LABEL	BYTE
	DB	'#LOV5\LOV5_015#He''s already cured, Jim.',0
L2D57:
	retf

L2D58:
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

H_2D94:
	SCRIPT	MSG_WALK_DONE, 63h, 0, 0, H_2DBE
AtSpock:
	inc	byte ptr cs:cure_steps
	cmp	byte ptr cs:cure_steps, 2
	je	L2DA8
	retf

L2DA8:
	push	63h
	push	-1
	push	-1
	push	OFFSET N_musemn
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musemn", -1, -1, 99)
	add	sp, 0Ch
	retf

H_2DBE:
	SCRIPT	MSG_ANIM_DONE, 63h, 0, 0, H_2E7D
SpockCured:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_030
	call	Say
	jmp	SHORT L2DF7

T_LOV5_030	LABEL	BYTE
	DB	'#LOV5\LOV5_030#There. You''re now cured.',0
L2DF7:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV5_038
	call	Say
	jmp	SHORT L2E24

T_LOV5_038	LABEL	BYTE
	DB	'#LOV5\LOV5_038#Thank you, Doctor.',0
L2E24:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_027
	call	Say
	jmp	SHORT L2E59

T_LOV5_027	LABEL	BYTE
	DB	'#LOV5\LOV5_027#Finally, a human response!',0
L2E59:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_2E64
	call	Say
	jmp	SHORT L2E78

S_2E64	LABEL	BYTE
	DB	'(raises an eyebrow)',0
L2E78:
	mov	byte ptr [si+spock_cured], 1
	retf

; Timer 2, every 200 ticks until Spock is cured: the virus advances,
; with a line at 0Fh, 1Eh, 2Dh; at 3Ch Spock collapses, at 64h he dies.
H_2E7D:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_3033
VirusProgresses:
	cmp	byte ptr [si+spock_cured], 1
	jne	L2E8A
	retf

L2E8A:
	inc	byte ptr [si+virus]
	cmp	byte ptr [si+virus], 64h
	jl	L2E96
	JMPN	L2FE3

L2E96:
	cmp	byte ptr [si+virus], 0Fh
	jne	L2ECD
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_spokcoff
	call	Say
	jmp	SHORT L2EC7

T_spokcoff	LABEL	BYTE
	DB	'#sfx\spokcoff#cough... cough...',0
L2EC7:
	inc	byte ptr [si+virus]
	JMPN	L2FDD

L2ECD:
	cmp	byte ptr [si+virus], 1Eh
	jne	L2F33
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F08
	call	Say
	jmp	SHORT L2F2D

T_LOVA_F08	LABEL	BYTE
	DB	'#LOVA\LOVA_F08#It''s what I was afraid of, Jim. I think spock is '
	DB	'getting worse.',0
L2F2D:
	inc	byte ptr [si+virus]
	JMPN	L2FDD

L2F33:
	cmp	byte ptr [si+virus], 2Dh
	jne	L2F69
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_spokcoff_2
	call	Say
	jmp	SHORT L2F64

T_spokcoff_2	LABEL	BYTE
	DB	'#sfx\spokcoff#cough... cough...',0
L2F64:
	inc	byte ptr [si+virus]
	jmp	SHORT L2FDD

L2F69:
	cmp	byte ptr [si+virus], 3Ch
	jne	L2FDD
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOVA_F54
	call	Say
	jmp	SHORT L2FD4

T_LOVA_F54	LABEL	BYTE
	DB	'#LOVA\LOVA_F54#The virus has spread to me, Captain.Isuggestyouco'
	DB	'ncentrateyoureffortsonthe',0
L2FD4:
	mov	byte ptr [si+virus_struck], 1
	inc	byte ptr [si+virus]
	jmp	SHORT L2FDD

L2FDD:
	mov	word ptr [si+RS_TIMERS+4], 0C8h
	retf

L2FE3:
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
	jmp	SHORT L3028

T_GENER004	LABEL	BYTE
	DB	'#GENE\GENER004#Game Over',0
L3028:
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	retf

; McCoy's tricorder on Spock follows the virus; on the others, normal.
H_3033:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_SPOCK, 0, H_32A4
McCoyScansSpock:
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	cmp	byte ptr [si+spock_cured], 1
	jne	L308D
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F01
	call	Say
	jmp	SHORT L308C

T_LOVA_F01	LABEL	BYTE
	DB	'#LOVA\LOVA_F01#He''s been cured of the Oroborus virus.',0
L308C:
	retf

L308D:
	cmp	byte ptr [si+have_research], 1
	je	L30FF
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F02
	call	Say
	jmp	SHORT L30FE

T_LOVA_F02	LABEL	BYTE
	DB	'#LOVA\LOVA_F02#I''m picking up some kind of virus. I can''t identi'
	DB	'fy it without more information.',0
L30FE:
	retf

L30FF:
	cmp	byte ptr [si+virus], 0Ah
	jge	L3154
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F04
	call	Say
	jmp	SHORT L3153

T_LOVA_F04	LABEL	BYTE
	DB	'#LOVA\LOVA_F04#The virus affects the Romulan-Vulcan genotype, Ji'
	DB	'm.',0
L3153:
	retf

L3154:
	cmp	byte ptr [si+virus], 1Eh
	jge	L3198
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F03
	call	Say
	jmp	SHORT L3197

T_LOVA_F03	LABEL	BYTE
	DB	'#LOVA\LOVA_F03#He''s infected with the virus, Jim.',0
L3197:
	retf

L3198:
	cmp	byte ptr [si+virus], 32h
	jge	L31F9
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F08_2
	call	Say
	jmp	SHORT L31F8

T_LOVA_F08_2	LABEL	BYTE
	DB	'#LOVA\LOVA_F08#It''s what I was afraid of, Jim. I think spock is '
	DB	'getting worse.',0
L31F8:
	retf

L31F9:
	cmp	byte ptr [si+virus], 46h
	jne	L323F
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG2_010
	call	Say
	jmp	SHORT L323E

T_TUG2_010	LABEL	BYTE
	DB	'#TUG2\TUG2_010#I don''t like the looks of this, Jim.',0
L323E:
	retf

L323F:
	cmp	byte ptr [si+virus], 64h
	jge	L3279
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F10
	call	Say
	jmp	SHORT L3278

T_LOVA_F10	LABEL	BYTE
	DB	'#LOVA\LOVA_F10#He has weak vital signs.',0
L3278:
	retf

L3279:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_100
	call	Say
	jmp	SHORT L32A3

T_LOVA_100	LABEL	BYTE
	DB	'#LOVA\LOVA_100#He''s dead, Jim.',0
L32A3:
	retf

H_32A4:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_KIRK, 0, H_32AC
	jmp	SHORT McCoyScansMcCoy

H_32AC:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_MCCOY, 0, H_32B4
McCoyScansMcCoy:
	jmp	SHORT McCoyScansCrew

H_32B4:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_REDSHIRT, 0, H_32FB
McCoyScansCrew:
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F07
	call	Say
	jmp	SHORT L32FA

T_LOVA_F07	LABEL	BYTE
	DB	'#LOVA\LOVA_F07#All lifesigns are normal.',0
L32FA:
	retf

; Opening a gas canister: Romulan laughing gas sets Spock laughing,
; nitrous oxide the crew, ammonia nothing.
H_32FB:
	SCRIPT	MSG_USE, IT_RLG, ANY, 0, H_334B
ReleaseRLG:
	mov	ax, OFFSET S_37CE
	mov	bx, OFFSET T_LOV2N005_3
	call	Say
	jmp	SHORT L333A

T_LOV2N005_3	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L333A:
	mov	byte ptr [si+rlg_released], 1
	push	IT_RLG
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_RLG)
	add	sp, 4
	retf

H_334B:
	SCRIPT	MSG_USE, IT_N2O, ANY, 0, H_33DD
ReleaseN2O:
	mov	ax, OFFSET S_37CE
	mov	bx, OFFSET T_LOV2N005_4
	call	Say
	jmp	SHORT L338A

T_LOV2N005_4	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L338A:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD2_040
	call	Say
	jmp	SHORT L33C0

T_MUD2_040	LABEL	BYTE
	DB	'#MUD2\MUD2_040#You look troubled, Captain.',0
L33C0:
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

H_33DD:
	SCRIPT	MSG_USE, IT_NH3, ANY, 0, H_3443
ReleaseNH3:
	mov	ax, OFFSET S_37CE
	mov	bx, OFFSET T_LOV2N005_5
	call	Say
	jmp	SHORT L341C

T_LOV2N005_5	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L341C:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L3422
L3422:
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
H_3443:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, rdf_scripts_end
CallEnterprise:
	cmp	byte ptr [si+made_cure], 1
	jne	L3452
	JMPN	L359F

L3452:
	cmp	byte ptr [si+called_ship], 1
	jne	L345B
	JMPN	L34FF

L345B:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018
	call	Say
	jmp	SHORT L34A0

T_MUD4_018	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L34A0:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146
	call	Say
	jmp	SHORT L34D6

T_BRIDU146	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L34D6:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41
	call	Say
	jmp	SHORT L34FA

T_VENA_F41	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L34FA:
	mov	byte ptr [si+called_ship], 1
	retf

L34FF:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_2
	call	Say
	jmp	SHORT L3544

T_MUD4_018_2	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L3544:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_2
	call	Say
	jmp	SHORT L357A

T_BRIDU146_2	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L357A:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_2
	call	Say
	jmp	SHORT L359E

T_VENA_F41_2	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L359E:
	retf

L359F:
	cmp	byte ptr [si+called_ship_cured], 1
	jne	L35A8
	JMPN	L364C

L35A8:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_3
	call	Say
	jmp	SHORT L35ED

T_MUD4_018_3	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L35ED:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_3
	call	Say
	jmp	SHORT L3623

T_BRIDU146_3	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L3623:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_3
	call	Say
	jmp	SHORT L3647

T_VENA_F41_3	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L3647:
	mov	byte ptr [si+called_ship_cured], 1
	retf

L364C:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_4
	call	Say
	jmp	SHORT L3691

T_MUD4_018_4	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L3691:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_4
	call	Say
	jmp	SHORT L36C7

T_BRIDU146_4	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L36C7:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_4
	call	Say
	jmp	SHORT L36EB

T_VENA_F41_4	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L36EB:
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
	DW	23h, 4	; id, points
	DW	161,116, 183,116, 183,177, 161,177
	DW	20h, 4	; id, points
	DW	44,129, 95,129, 95,171, 44,171
	DW	20h, 4	; id, points
	DW	96,110, 151,110, 151,171, 96,171
	DW	21h, 4	; id, points
	DW	172,85, 242,85, 242,178, 172,178
	DW	22h, 4	; id, points
	DW	276,173, 312,173, 312,194, 276,194
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	1, 4	; id, points
	DW	0,198, 319,198, 319,199, 0,199
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	265,180, 309,180, 309,194, 265,194
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's3r3l1',0
	DB	's3r3l2',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Ferris	LABEL	BYTE
	DB	'Lt. Ferris',0
S_37CE	LABEL	BYTE
	DB	0
	DB	'Computer',0
	DB	'wes',0
T_LOV2N006	LABEL	BYTE
	DB	'#LOV2\LOV2N006#A small field-effect anti-gravity unit, useful fo'
	DB	'r moving things too heavy to lift and carry by muscle alone.',0
T_LOV2N028	LABEL	BYTE
	DB	'#LOV2\LOV2N028#This is a synthesizer, used to combine and replic'
	DB	'ate chemicals and form new compounds. This particular model has '
	DB	'twin gas feeds.',0
T_LOV2N004	LABEL	BYTE
	DB	23h, 4Ch, 4Fh, 56h, 32h, 5Ch, 4Ch, 4Fh, 56h, 32h, 4Eh, 30h
	DB	30h, 34h, 23h, 41h, 20h, 67h, 61h, 73h, 20h, 74h, 61h, 6Eh
	DB	6Bh, 20h, 6Dh, 61h, 72h, 6Bh, 65h, 64h, 20h, 27h, 4Fh, 1Dh
	DB	27h, 2Eh, 0
T_LOV2N002	LABEL	BYTE
	DB	23h, 4Ch, 4Fh, 56h, 32h, 5Ch, 4Ch, 4Fh, 56h, 32h, 4Eh, 30h
	DB	30h, 32h, 23h, 41h, 20h, 67h, 61h, 73h, 20h, 74h, 61h, 6Eh
	DB	6Bh, 20h, 6Dh, 61h, 72h, 6Bh, 65h, 64h, 20h, 27h, 48h, 1Dh
	DB	27h, 2Eh, 0
T_LOV2N003	LABEL	BYTE
	DB	23h, 4Ch, 4Fh, 56h, 32h, 5Ch, 4Ch, 4Fh, 56h, 32h, 4Eh, 30h
	DB	30h, 33h, 23h, 41h, 20h, 67h, 61h, 73h, 20h, 74h, 61h, 6Eh
	DB	6Bh, 20h, 6Dh, 61h, 72h, 6Bh, 65h, 64h, 20h, 27h, 4Eh, 1Dh
	DB	27h, 2Ch, 0
T_LOV2N011	LABEL	BYTE
	DB	'#LOV2\LOV2N011#McCoy is fidgeting around.',0
T_LOV2N014	LABEL	BYTE
	DB	'#LOV2\LOV2N014#Spock is analyzing the surroundings.',0
T_LOV2N010	LABEL	BYTE
	DB	'#LOV2\LOV2N010#Lt. Ferris is carefully watching the hallway',0
T_LOV2N026	LABEL	BYTE
	DB	'#LOV2\LOV2N026#This is a science lab.',0
T_LOV2N027	LABEL	BYTE
	DB	'#LOV2\LOV2N027#This is a storage cabinet.',0
T_LOV2N029	LABEL	BYTE
	DB	'#LOV2\LOV2N029#This is the door to the synthesis chamber.',0
T_LOV2_035	LABEL	BYTE
	DB	'#LOV2\LOV2_035#In principle, Captain, this device is quite simpl'
	DB	'e. When this chamber is empty and gas tanks are attached, it wil'
	DB	'l combine the gases to make new compounds. If chemicals are plac'
	DB	'ed in the chamber, the machine will combine them with the gases '
	DB	'to create new materials.',0
T_LOV2_019	LABEL	BYTE
	DB	'#LOV2\LOV2_019#Next he''ll tell us the DNA molecule is simple!',0
T_LOV2_033	LABEL	BYTE
	DB	'#LOV2\LOV2_033#Compared to many molecular models, it is, Doctor.',0
T_LOV2_016	LABEL	BYTE
	DB	'#LOV2\LOV2_016#I rest my case.',0
T_LOV2N045	LABEL	BYTE
	DB	'#LOV2\LOV2N045#An Ardak 1000, the last word in molecular replica'
	DB	'tion, one of the most advanced pieces of scientific equipment ev'
	DB	'er constructed.',0
T_LOV2_037	LABEL	BYTE
	DB	'#LOV2\LOV2_037#It would take us several hours to get this machin'
	DB	'e working, Captain. I do not believe we will need it. The synthe'
	DB	'sis chamber should be able to give us what we need.',0
T_LOV2N001	LABEL	BYTE
	DB	'#LOV2\LOV2N001#A door.',0
T_LOV2_009	LABEL	BYTE
	DB	'#LOV2\LOV2_009#Go bother Spock. This is the kind of place he lik'
	DB	'es.',0
T_LOV2_029	LABEL	BYTE
	DB	'#LOV2\LOV2_029#This is an outstanding facility, Captain.',0
T_LOV2_041	LABEL	BYTE
	DB	'#LOV2\LOV2_041#This room is very defensible, Captain -- if thing'
	DB	's get nasty, we may want to retreat to here.',0
T_LOV2_008	LABEL	BYTE
	DB	'#LOV2\LOV2_008#Except for the Oroborus virus, I''m not picking up'
	DB	' anything unusual.',0
T_LOV2_027	LABEL	BYTE
	DB	'#LOV2\LOV2_027#Nothing unusual is detected.',0
	DB	'? added to inventory.',0
	DB	'#LOV2\LOV2N000#You already have the ?.',0
T_LOV2N008	LABEL	BYTE
	DB	'#LOV2\LOV2N008#Gas feed is on.',0
T_LOV2N007	LABEL	BYTE
	DB	'#LOV2\LOV2N007#Gas feed is off.',0
	DB	'#LOV2\LOV2N013#Nothing happens.',0
	DB	'#LOV2\LOV2N015#The item is much soggier than it used to be, but '
	DB	'otherwise undamaged.',0
	DB	'#LOV2\LOV2N033#You have synthesized one liter of Romulan Laughin'
	DB	'g Gas.',0
	DB	'#LOV2\LOV2_010#Ouch!',0
	DB	'dialog error',0
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
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
