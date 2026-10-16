; LOVE1.RDF - "Love's Labor Jeopardized", the station's research lab.
; McCoy grows the cure here: a dish of Oroborus culture from the freezer
; in the replicator's chamber, ammonia on its anti-agent nozzle, and the
; replicator makes a cure sample (to be synthesized in room 2). The
; distillator turns insulation into polyberylcarbonate. A ladder leads
; down to the Romulan-held deck (room 4).
;
; Actors: 8-10 (0Ah) the doors, 11 (0Bh) the freezer, 12 (0Ch) the
; chamber, 13 (0Dh) the hatch, 14 (0Eh) the dish, 15 (0Fh) the bottle.
; Objects: 8, 9, 0Ah the doors, 0Bh/22h the freezer, 0Ch/0Eh the chamber,
; 0Fh/24h the nozzle, 20h the ladder, 21h the distillator, 23h the
; replicator, 25h the neutrino accelerator.
; Regions 0 the ladder, 1-3 the doorsteps.
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
romulans_out	EQU	RS_VARS+2	; the Romulans on the deck below are out of action (room 3)
n2o_released	EQU	RS_VARS+3	; laughing gas: the crew laugh (timer 0)
rlg_released	EQU	RS_VARS+4	; Romulan laughing gas: Spock laughs (timer 1)
made_sample	EQU	RS_VARS+5	; the replicator has produced the cure sample
freezer_open	EQU	RS_VARS+6	; bit 0
dish_in_chamber	EQU	RS_VARS+7
nozzle	EQU	RS_VARS+8	; the bottle on the nozzle: 0 none, 1 N2O, 2 ammonia, 3 water, 4 RLG
virus_struck	EQU	RS_VARS+18h	; the virus has floored Spock, and the Romulans below
virus	EQU	RS_VARS+1Ch	; Spock's infection: 3Ch he collapses, 64h he dies
spock_cured	EQU	RS_VARS+1Dh
called_ship	EQU	RS_VARS+1Eh	; Kirk has called the Enterprise
called_ship_cured	EQU	RS_VARS+1Fh	; the same, after the cure
distilled	EQU	RS_VARS+22h	; the point for distilling
made_cure	EQU	RS_VARS+26h	; the cure has been synthesized (room 2)
score	EQU	RS_VARS+29h	; word: the mission's score

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0BDh	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	76h
rdf_scale_min	LABEL	BYTE
	DW	8Ch	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	3, 2, -1, 0	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	215,130, 168,163	; entrance 0, crew 0
	DW	215,130, 232,151	; entrance 0, crew 1
	DW	215,130, 139,151	; entrance 0, crew 2
	DW	215,130, 231,133	; entrance 0, crew 3
	DW	122,134, 150,160	; entrance 1, crew 0
	DW	122,134, 97,169	; entrance 1, crew 1
	DW	122,134, 191,152	; entrance 1, crew 2
	DW	122,134, 149,137	; entrance 1, crew 3
	DW	253,140, 162,161	; entrance 2, crew 0
	DW	253,140, 228,160	; entrance 2, crew 1
	DW	253,140, 197,135	; entrance 2, crew 2
	DW	253,140, 267,143	; entrance 2, crew 3
	DW	70,150, 145,163	; entrance 3, crew 0
	DW	70,150, 86,151	; entrance 3, crew 1
	DW	70,150, 141,149	; entrance 3, crew 2
	DW	70,150, 61,168	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	253,141, 245,136, 261,135, 253,131
; In the room file, so these start again each time the room loads
warned	LABEL	BYTE	; Ferris has warned of the Romulans below
	DB	0
safety_door_steps	LABEL	BYTE	; each door: the walk and the door both done at 2
	DB	0
bridge_door_steps	LABEL	BYTE
	DB	0
door2_steps	LABEL	BYTE
	DB	0
going_door	LABEL	BYTE	; Kirk is on his way to a door
	DB	0
victim	LABEL	BYTE	; word: the name of who climbs down
	DB	0, 0
back_x	LABEL	BYTE	; word: where the crew member who opened the freezer goes back to
	DB	0, 0
back_y	LABEL	BYTE	; word
	DB	0, 0
unused1	LABEL	BYTE	; word
	DB	0, 0
unused2	LABEL	BYTE	; word
	DB	0, 0
crew	LABEL	BYTE	; word: the crew member using the freezer or ladder
	DB	0, 0
crew_anim	LABEL	BYTE	; word
	DB	0, 0
nozzle_item	LABEL	BYTE	; word: the item on the nozzle (anti-agent)
	DB	0, 0
nozzle_anim	LABEL	BYTE	; word: the bottle's animation
	DB	0, 0
N_s3r2d1	LABEL	BYTE
	DB	's3r2d1',0
N_s3r2d1a	LABEL	BYTE
	DB	's3r2d1a',0
N_s3r2d2	LABEL	BYTE
	DB	's3r2d2',0
N_s3r2d2a	LABEL	BYTE
	DB	's3r2d2a',0
N_s3r2d3	LABEL	BYTE
	DB	's3r2d3',0
N_s3r2d3a	LABEL	BYTE
	DB	's3r2d3a',0
N_s3r2d4	LABEL	BYTE
	DB	's3r2d4',0
N_s3r2d4o	LABEL	BYTE
	DB	's3r2d4o',0
N_s3r2d4a	LABEL	BYTE
	DB	's3r2d4a',0
N_s3r2d5	LABEL	BYTE
	DB	's3r2d5',0
N_s3r2d5o	LABEL	BYTE
	DB	's3r2d5o',0
N_s3r2d5c	LABEL	BYTE
	DB	's3r2d5c',0
N_s3r2d6	LABEL	BYTE
	DB	's3r2d6',0
N_s3r2s1	LABEL	BYTE
	DB	's3r2s1',0
N_s3r2s2	LABEL	BYTE
	DB	's3r2s2',0
N_kkillw	LABEL	BYTE
	DB	'kkillw',0
N_skillw	LABEL	BYTE
	DB	'skillw',0
N_mkillw	LABEL	BYTE
	DB	'mkillw',0
N_rkillw	LABEL	BYTE
	DB	'rkillw',0
N_dishes	LABEL	BYTE
	DB	'dishes',0
N_btle1	LABEL	BYTE
	DB	'btle1',0
N_btle2	LABEL	BYTE
	DB	'btle2',0
N_btle3	LABEL	BYTE
	DB	'btle3',0
N_btle4	LABEL	BYTE
	DB	'btle4',0
N_kusemn	LABEL	BYTE
	DB	'kusemn',0
	DB	'susemn',0
N_musehn	LABEL	BYTE
	DB	'musehn',0
	DB	'rusemn',0
N_kusemw	LABEL	BYTE
	DB	'kusemw',0
	DB	'susemw',0
	DB	'musemw',0
	DB	'rusemw',0
N_kuseme	LABEL	BYTE
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
N_sscann	LABEL	BYTE
	DB	'sscann',0
N_sscane	LABEL	BYTE
	DB	'sscane',0
N_sscanw	LABEL	BYTE
	DB	'sscanw',0
N_mscans	LABEL	BYTE
	DB	'mscans',0
N_mscanw	LABEL	BYTE
	DB	'mscanw',0

rdf_scripts:
; The room starts: the freezer, the chamber, the bottle on the nozzle,
; the gases, the virus timer.
H_0211:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0380
StartRoom:
	jmp	SHORT L0222

N_LOV1LOOP	LABEL	BYTE
	DB	'LOV1LOOP',0
L0222:
	push	OFFSET N_LOV1LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("LOV1LOOP")
	add	sp, 4
	cmp	byte ptr [si+freezer_open], 1
	jne	L024D
	push	0
	push	8Dh
	push	67h
	push	OFFSET N_s3r2d4o
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, "s3r2d4o", 103, 141, 0)
	add	sp, 0Ch
L024D:
	push	0
	push	75h
	push	0B4h
	push	OFFSET N_s3r2d5c
	cmp	byte ptr [si+dish_in_chamber], 0
	je	L0261
	pop	ax
	push	OFFSET N_s3r2d5o
L0261:
	push	0Ch
	push	RC_ANIM0
	SERVICE		; Anim0(12, ?, 180, 117, 0)
	add	sp, 0Ch
	cmp	byte ptr [si+dish_in_chamber], 1
	jne	L0289
	push	0
	push	71h
	push	0B4h
	push	OFFSET N_dishes
	push	0Eh
	push	RC_ANIM0
	SERVICE		; Anim0(14, "dishes", 180, 113, 0)
	add	sp, 0Ch
L0289:
	cmp	byte ptr [si+nozzle], 0
	je	L02FD
	cmp	byte ptr [si+nozzle], 1
	jne	L02A5
	mov	word ptr cs:nozzle_anim, OFFSET N_btle1
	mov	word ptr cs:nozzle_item, 65h
	jmp	SHORT L02E5

L02A5:
	cmp	byte ptr [si+nozzle], 2
	jne	L02BB
	mov	word ptr cs:nozzle_anim, OFFSET N_btle2
	mov	word ptr cs:nozzle_item, 66h
	jmp	SHORT L02E5

L02BB:
	cmp	byte ptr [si+nozzle], 3
	jne	L02D1
	mov	word ptr cs:nozzle_anim, OFFSET N_btle3
	mov	word ptr cs:nozzle_item, 67h
	jmp	SHORT L02E5

L02D1:
	cmp	byte ptr [si+nozzle], 4
	jne	L0315
	mov	word ptr cs:nozzle_anim, OFFSET N_btle4
	mov	word ptr cs:nozzle_item, 49h
L02E5:
	push	0
	push	72h
	push	0A3h
	push	word ptr cs:nozzle_anim
	push	0Fh
	push	RC_ANIM0
	SERVICE		; Anim0(15, ?, 163, 114, 0)
	add	sp, 0Ch
L02FD:
	cmp	byte ptr [si+n2o_released], 1
	jne	L0315
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS], ax
L0315:
	cmp	byte ptr [si+rlg_released], 1
	jne	L032E
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS+2], ax
L032E:
	mov	word ptr [si+RS_TIMERS+4], 0C8h
	push	0
	push	7Eh
	push	0DBh
	push	OFFSET N_s3r2d3a
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "s3r2d3a", 219, 126, 0)
	add	sp, 0Ch
	push	0
	push	0
	push	0
	push	OFFSET N_s3r2d1a
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s3r2d1a", 0, 0, 0)
	add	sp, 0Ch
	push	0
	push	0
	push	0
	push	OFFSET N_s3r2d2a
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s3r2d2a", 0, 0, 0)
	add	sp, 0Ch
	mov	byte ptr cs:cure_x, -70h
	mov	byte ptr cs:cure_y, -59h
	retf

; The doors: walk (msgs 15-17), the door opens at its step (anim msgs
; 2-4), and when both are done, through: the safety door to room 3, the
; bridge (room 0), and room 2.
H_0380:
	SCRIPT	MSG_WALK, 0Ah, 0, 0, H_0388
	jmp	SHORT WalkToSafetyDoor

H_0388:
	SCRIPT	MSG_WALK, 26h, 0, 0, H_03B1
WalkToSafetyDoor:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr cs:going_door, 1
	push	0Fh
	push	81h
	push	0D9h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 217, 129, 15)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL], 0
	retf

H_03B1:
	SCRIPT	MSG_REGION, 1, 0, 0, H_03E2
ReachSafetyDoor:
	cmp	byte ptr cs:going_door, 1
	jne	L03E1
	push	2
	push	7Eh
	push	0DBh
	push	OFFSET N_s3r2d3
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "s3r2d3", 219, 126, 2)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
L03E1:
	retf

H_03E2:
	SCRIPT	MSG_WALK_DONE, 0Fh, 0, 0, H_03EA
	jmp	SHORT ThroughSafetyDoor

H_03EA:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_040D
ThroughSafetyDoor:
	inc	byte ptr cs:safety_door_steps
	cmp	byte ptr cs:safety_door_steps, 2
	je	L03FE
	retf

L03FE:
	push	1
	push	3
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(3, 1)
	add	sp, 6
	retf

H_040D:
	SCRIPT	MSG_WALK, 8, 0, 0, H_0415
	jmp	SHORT WalkToBridgeDoor

H_0415:
	SCRIPT	MSG_WALK, 27h, 0, 0, H_0439
WalkToBridgeDoor:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr cs:going_door, 1
	push	10h
	push	97h
	push	42h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 66, 151, 16)
	add	sp, 0Ah
	retf

H_0439:
	SCRIPT	MSG_REGION, 2, 0, 0, H_0469
ReachBridgeDoor:
	cmp	byte ptr cs:going_door, 1
	jne	L0468
	push	3
	push	0
	push	0
	push	OFFSET N_s3r2d1
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s3r2d1", 0, 0, 3)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
L0468:
	retf

H_0469:
	SCRIPT	MSG_WALK_DONE, 10h, 0, 0, H_0471
	jmp	SHORT ThroughBridgeDoor

H_0471:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_0494
ThroughBridgeDoor:
	inc	byte ptr cs:bridge_door_steps
	cmp	byte ptr cs:bridge_door_steps, 2
	je	L0485
	retf

L0485:
	push	2
	push	0
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(0, 2)
	add	sp, 6
	retf

H_0494:
	SCRIPT	MSG_WALK, 9, 0, 0, H_049C
	jmp	SHORT WalkToDoor2

H_049C:
	SCRIPT	MSG_WALK, 28h, 0, 0, H_04C0
WalkToDoor2:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr cs:going_door, 1
	push	11h
	push	85h
	push	79h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 121, 133, 17)
	add	sp, 0Ah
	retf

H_04C0:
	SCRIPT	MSG_REGION, 3, 0, 0, H_04F0
ReachDoor2:
	cmp	byte ptr cs:going_door, 1
	jne	L04EF
	push	4
	push	0
	push	0
	push	OFFSET N_s3r2d2
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s3r2d2", 0, 0, 4)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
L04EF:
	retf

H_04F0:
	SCRIPT	MSG_WALK_DONE, 11h, 0, 0, H_04F8
	jmp	SHORT ThroughDoor2

H_04F8:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_051B
ThroughDoor2:
	inc	byte ptr cs:door2_steps
	cmp	byte ptr cs:door2_steps, 2
	je	L050C
	retf

L050C:
	push	0
	push	2
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(2, 0)
	add	sp, 6
	retf

; Looking and talking.
H_051B:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_052A
LookAtAccelerator:
	sub	ax, ax
	mov	bx, OFFSET T_LOV1N000
	call	Say
	retf

H_052A:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_0539
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_LOV1N003
	call	Say
	retf

H_0539:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_0548
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_LOV1N004
	call	Say
	retf

H_0548:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_0557
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_LOV1N001
	call	Say
	retf

H_0557:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_0566
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_LOV1N002
	call	Say
	retf

H_0566:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_05C1
LookAtScene:
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N019
	call	Say
	jmp	SHORT L05C0

T_LOV1N019	LABEL	BYTE
	DB	'#LOV1\LOV1N019#This is a research lab, with lots of expensive eq'
	DB	'uipment.',0
L05C0:
	retf

H_05C1:
	SCRIPT	MSG_LOOK, 0Fh, 0, 0, H_05C9
	jmp	SHORT LookAtNozzle

H_05C9:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_0617
LookAtNozzle:
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N022
	call	Say
	jmp	SHORT L0616

T_LOV1N022	LABEL	BYTE
	DB	'#LOV1\LOV1N022#This nozzle is where anti-agents are placed.',0
L0616:
	retf

H_0617:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_067D
LookAtLadder:
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N021
	call	Say
	jmp	SHORT L067C

T_LOV1N021	LABEL	BYTE
	DB	'#LOV1\LOV1N021#This is an access ladder. It appears to lead to t'
	DB	'he next deck below.',0
L067C:
	retf

H_067D:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_0685
	jmp	SHORT LookAtDoor

H_0685:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_06E5
LookAtDoor:
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N020
	call	Say
	jmp	SHORT L06E4

T_LOV1N020	LABEL	BYTE
	DB	'#LOV1\LOV1N020#This is a standard door, leading to another room '
	DB	'on this deck.',0
L06E4:
	retf

H_06E5:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_0769
LookAtSafetyDoor:
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N017
	call	Say
	jmp	SHORT L0768

T_LOV1N017	LABEL	BYTE
	DB	'#LOV1\LOV1N017#This is a large engineering safety door with heav'
	DB	'y shielding. Its entry codes seem to be breached.',0
L0768:
	retf

H_0769:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_07D7
LookAtDistillator:
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N016
	call	Say
	jmp	SHORT L07D6

T_LOV1N016	LABEL	BYTE
	DB	'#LOV1\LOV1N016#This is a distillator, used to isolate specific c'
	DB	'ompounds from raw material.',0
L07D6:
	retf

H_07D7:
	SCRIPT	MSG_LOOK, 0Eh, 0, 0, H_07DF
	jmp	SHORT LookAtChamber

H_07DF:
	SCRIPT	MSG_LOOK, 0Ch, 0, 0, H_08AE
LookAtChamber:
	cmp	byte ptr [si+made_sample], 1
	je	L0836
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N014
	call	Say
	jmp	SHORT L0835

T_LOV1N014	LABEL	BYTE
	DB	'#LOV1\LOV1N014#This chamber is where virus samples are placed.',0
L0835:
	retf

L0836:
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N013
	call	Say
	jmp	SHORT L08AD

T_LOV1N013	LABEL	BYTE
	DB	'#LOV1\LOV1N013#There is a single viral culture dish in here, and'
	DB	' it contains a sample of the Oroborus cure.',0
L08AD:
	retf

H_08AE:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_093A
LookAtReplicator:
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N015
	call	Say
	jmp	SHORT L0939

T_LOV1N015	LABEL	BYTE
	DB	'#LOV1\LOV1N015#This device is used for the rapid reproduction of'
	DB	' virus cultures in the presence of suspected anti-agents.',0
L0939:
	retf

H_093A:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_0942
	jmp	SHORT LookAtFreezer

H_0942:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_09E2
LookAtFreezer:
	cmp	byte ptr [si+freezer_open], 1
	jne	L09A3
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N023
	call	Say
	jmp	SHORT L09A2

T_LOV1N023	LABEL	BYTE
	DB	'#LOV1\LOV1N023#This refrigerator has a number of specimen dishes'
	DB	' inside.',0
L09A2:
	retf

L09A3:
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N018
	call	Say
	jmp	SHORT L09E1

T_LOV1N018	LABEL	BYTE
	DB	'#LOV1\LOV1N018#This is a large refrigeration unit.',0
L09E1:
	retf

H_09E2:
	SCRIPT	MSG_LOOK, IT_DISHES, 0, 0, H_0A5B
LookAtDishes:
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N012
	call	Say
	jmp	SHORT L0A5A

T_LOV1N012	LABEL	BYTE
	DB	'#LOV1\LOV1N012#There are many virus culture dishes, all of them '
	DB	'labeled, "Oroborus Virus -- DANGER!!".',0
L0A5A:
	retf

H_0A5B:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0AEB
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV1_001
	call	Say
	jmp	SHORT L0AEA

T_LOV1_001	LABEL	BYTE
	DB	'#LOV1\LOV1_001#When you are finished admiring all the equipment '
	DB	'Bones, maybe you can help us figure out what''s going on here.',0
L0AEA:
	retf

H_0AEB:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0B6B
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV1_005
	call	Say
	jmp	SHORT L0B6A

T_LOV1_005	LABEL	BYTE
	DB	'#LOV1\LOV1_005#This is a very well-equipped laboratory, Captain.'
	DB	' Perhaps Dr. McCoy could be of some use here.',0
L0B6A:
	retf

H_0B6B:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0BF0
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV1_011
	call	Say
	jmp	SHORT L0BEF

T_LOV1_011	LABEL	BYTE
	DB	'#LOV1\LOV1_011#Jim, this lab is incredible! What I wouldn''t give'
	DB	' to have some of this equipment on the Enterprise.',0
L0BEF:
	retf

H_0BF0:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0C7C
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV1_027
	call	Say
	jmp	SHORT L0C7B

T_LOV1_027	LABEL	BYTE
	DB	'#LOV1\LOV1_027#This level appears to be deserted, sir, but I''m w'
	DB	'orried about a Romulan counter-attack. They outnumber us.',0
L0C7B:
	retf

; Tricorders.
H_0C7C:
	SCRIPT	MSG_USE, IT_MTRICOR, IT_DISHES, 0, H_0D05
McCoyScansDishes:
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
	mov	bx, OFFSET T_LOV1_017
	call	Say
	jmp	SHORT L0D04

T_LOV1_017	LABEL	BYTE
	DB	'#LOV1\LOV1_017#Jim, these viral cultures are alive. I can use th'
	DB	'em to work on a cure.',0
L0D04:
	retf

H_0D05:
	SCRIPT	MSG_USE, IT_MTRICOR, ANY, 0, H_0E07
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
	je	L0DA8
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV1_010
	call	Say
	jmp	SHORT L0DA7

T_LOV1_010	LABEL	BYTE
	DB	'#LOV1\LOV1_010#I''m picking up some strange, airborne virus. I ca'
	DB	'n''t identify it without more information.',0
L0DA7:
	retf

L0DA8:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV1_009
	call	Say
	jmp	SHORT L0E06

T_LOV1_009	LABEL	BYTE
	DB	'#LOV1\LOV1_009#Except for the Oroborus virus, I''m not picking up'
	DB	' anything unusual.',0
L0E06:
	retf

H_0E07:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_0E0F
	jmp	SHORT SpockScansChamber

H_0E0F:
	SCRIPT	MSG_USE, IT_STRICOR, 0Ch, 0, H_0E40
SpockScansChamber:
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
	mov	bx, OFFSET T_LOV1_022
	call	Say
	retf

H_0E40:
	SCRIPT	MSG_USE, OBJ_SPOCK, 25h, 0, H_0E48
	jmp	SHORT SpockScansAccelerator

H_0E48:
	SCRIPT	MSG_USE, IT_STRICOR, 25h, 0, H_0E79
SpockScansAccelerator:
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
	mov	bx, OFFSET T_LOV1_006
	call	Say
	retf

H_0E79:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_0EAA
SpockScansFreezer:
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
	mov	bx, OFFSET T_LOV1_023
	call	Say
	retf

H_0EAA:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_0F0B
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
	mov	bx, OFFSET T_LOV1_003
	call	Say
	jmp	SHORT L0F0A

T_LOV1_003	LABEL	BYTE
	DB	'#LOV1\LOV1_003#It is a standard research lab.',0
L0F0A:
	retf

H_0F0B:
	SCRIPT	MSG_USE, IT_STRICOR, IT_DISHES, 0, H_0F93
SpockScansDishes:
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
	mov	bx, OFFSET T_LOV1_004
	call	Say
	jmp	SHORT L0F92

T_LOV1_004	LABEL	BYTE
	DB	'#LOV1\LOV1_004#The seals on these dishes are intact, but that''s '
	DB	'all I can determine.',0
L0F92:
	retf

H_0F93:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_0FC4
SpockScansDistillator:
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
	mov	bx, OFFSET T_LOV1_007
	call	Say
	retf

; The freezer, once open: Kirk takes a dish of virus culture (msgs 14, 9).
H_0FC4:
	SCRIPT	MSG_GET, 0Bh, 0, 0, H_0FCC
	jmp	SHORT GetFromFreezer

H_0FCC:
	SCRIPT	MSG_GET, 22h, 0, 0, H_0FE6
GetFromFreezer:
	push	0Eh
	push	8Eh
	push	71h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 113, 142, 14)
	add	sp, 0Ah
	retf

H_0FE6:
	SCRIPT	MSG_WALK_DONE, 0Eh, 0, 0, H_104A
KirkAtFreezer:
	cmp	byte ptr [si+freezer_open], 1
	je	L1034
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N010
	call	Say
	jmp	SHORT L1033

T_LOV1N010	LABEL	BYTE
	DB	'#LOV1\LOV1N010#The Freezer unit is too large to take.',0
L1033:
	retf

L1034:
	push	9
	push	-1
	push	-1
	push	OFFSET N_kusehw
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehw", -1, -1, 9)
	add	sp, 0Ch
	retf

H_104A:
	SCRIPT	MSG_ANIM_DONE, 9, 0, 0, H_1066
TookDishes:
	push	IT_DISHES
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_DISHES)
	add	sp, 4
	mov	ax, OFFSET S_2C3E
	mov	bx, OFFSET T_LOV1N006
	call	Say
	retf

; The replicator's chamber: the cure sample, else the dish.
H_1066:
	SCRIPT	MSG_GET, 0Eh, 0, 0, H_106E
	jmp	SHORT GetFromChamber2

H_106E:
	SCRIPT	MSG_GET, 0Ch, 0, 0, H_1076
GetFromChamber2:
	jmp	SHORT GetFromChamber

H_1076:
	SCRIPT	MSG_GET, 23h, 0, 0, H_109A
GetFromChamber:
	cmp	byte ptr [si+dish_in_chamber], 0
	jne	L1085
	JMPN	L1159

L1085:
	push	8
	push	8Ch
	push	0B5h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 181, 140, 8)
	add	sp, 0Ah
	retf

H_109A:
	SCRIPT	MSG_WALK_DONE, 8, 0, 0, H_10B6
KirkAtChamber:
	push	0Ah
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 10)
	add	sp, 0Ch
	retf

H_10B6:
	SCRIPT	MSG_ANIM_DONE, 0Ah, 0, 0, H_118A
TookFromChamber:
	cmp	byte ptr [si+made_sample], 1
	jne	L1111
	push	IT_SAMPLE
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_SAMPLE)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N035
	call	Say
	jmp	SHORT L110F

T_LOV1N035	LABEL	BYTE
	DB	'#LOV1\LOV1N035#You retrieve the Oroborus cure sample.',0
L110F:
	jmp	SHORT L1126

L1111:
	push	IT_DISHES
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_DISHES)
	add	sp, 4
	mov	ax, OFFSET S_2C3E
	mov	bx, OFFSET T_LOV1N006
	call	Say
L1126:
	push	0Eh
	push	RC_STOPANIM
	SERVICE		; StopAnim(14)
	add	sp, 4
	push	0
	push	75h
	push	0B4h
	push	OFFSET N_s3r2d6
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s3r2d6", 180, 117, 0)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	mov	byte ptr [si+dish_in_chamber], 0
	retf

L1159:
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N009
	call	Say
	jmp	SHORT L1189

T_LOV1N009	LABEL	BYTE
	DB	'#LOV1\LOV1N009#The chamber is empty.',0
L1189:
	retf

; The nozzle: take the bottle back (msgs 2, 11), or fit a bottle of
; N2O, water, ammonia or Romulan laughing gas (msgs 3, 12).
H_118A:
	SCRIPT	MSG_GET, 0Fh, 0, 0, H_1192
	jmp	SHORT GetBottle

H_1192:
	SCRIPT	MSG_GET, 24h, 0, 0, H_11AD
GetBottle:
	push	2
	push	90h
	push	0A6h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 166, 144, 2)
	add	sp, 0Ah
	retf

H_11AD:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_11FF
KirkAtNozzle:
	cmp	byte ptr [si+nozzle], 0
	jne	L11E9
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N011
	call	Say
	jmp	SHORT L11E8

T_LOV1N011	LABEL	BYTE
	DB	'#LOV1\LOV1N011#The nozzle is empty.',0
L11E8:
	retf

L11E9:
	push	0Bh
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 11)
	add	sp, 0Ch
	retf

H_11FF:
	SCRIPT	MSG_ANIM_DONE, 0Bh, 0, 0, H_128D
TookBottle:
	cmp	byte ptr [si+nozzle], 1
	jne	L120F
	push	IT_N2O
	jmp	SHORT L124B

L120F:
	cmp	byte ptr [si+nozzle], 2
	jne	L1219
	push	IT_NH3
	jmp	SHORT L124B

L1219:
	cmp	byte ptr [si+nozzle], 3
	jne	L1223
	push	IT_H2O
	jmp	SHORT L124B

L1223:
	cmp	byte ptr [si+nozzle], 4
	jne	L122D
	push	IT_RLG
	jmp	SHORT L124B

L122D:
	mov	ax, OFFSET N_wes
	mov	bx, OFFSET S_1238
	call	Say
	jmp	SHORT L124A

S_1238	LABEL	BYTE
	DB	'Get Bottle Error!',0
L124A:
	retf

L124B:
	push	RC_GIVEITEM
	SERVICE		; GiveItem(?)
	add	sp, 4
	mov	byte ptr [si+nozzle], 0
	push	0Fh
	push	RC_STOPANIM
	SERVICE		; StopAnim(15)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N007
	call	Say
	jmp	SHORT L1285

T_LOV1N007	LABEL	BYTE
	DB	'#LOV1\LOV1N007#Done.',0
L1285:
	mov	word ptr cs:nozzle_item, 0
	retf

H_128D:
	SCRIPT	MSG_USE, IT_N2O, 24h, 0, H_12AE
N2OOnNozzle:
	cmp	byte ptr [si+nozzle], 0
	je	L129A
	retf

L129A:
	mov	word ptr cs:nozzle_item, 65h
	mov	word ptr cs:nozzle_anim, OFFSET N_btle1
	mov	byte ptr [si+nozzle], 1
	jmp	SHORT L130F

H_12AE:
	SCRIPT	MSG_USE, IT_H2O, 24h, 0, H_12CF
H2OOnNozzle:
	cmp	byte ptr [si+nozzle], 0
	je	L12BB
	retf

L12BB:
	mov	word ptr cs:nozzle_item, 67h
	mov	word ptr cs:nozzle_anim, OFFSET N_btle3
	mov	byte ptr [si+nozzle], 3
	jmp	SHORT L130F

H_12CF:
	SCRIPT	MSG_USE, IT_NH3, 24h, 0, H_12F0
NH3OnNozzle:
	cmp	byte ptr [si+nozzle], 0
	je	L12DC
	retf

L12DC:
	mov	word ptr cs:nozzle_item, 66h
	mov	word ptr cs:nozzle_anim, OFFSET N_btle2
	mov	byte ptr [si+nozzle], 2
	jmp	SHORT L130F

H_12F0:
	SCRIPT	MSG_USE, IT_RLG, 24h, 0, H_1324
RLGOnNozzle:
	cmp	byte ptr [si+nozzle], 0
	je	L12FD
	retf

L12FD:
	mov	word ptr cs:nozzle_item, 49h
	mov	word ptr cs:nozzle_anim, OFFSET N_btle4
	mov	byte ptr [si+nozzle], 4
L130F:
	push	3
	push	90h
	push	0A6h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 166, 144, 3)
	add	sp, 0Ah
	retf

H_1324:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_1340
KirkAtNozzle2:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 12)
	add	sp, 0Ch
	retf

H_1340:
	SCRIPT	MSG_ANIM_DONE, 0Ch, 0, 0, H_136E
BottleFitted:
	push	0
	push	72h
	push	0A3h
	push	word ptr cs:nozzle_anim
	push	0Fh
	push	RC_ANIM0
	SERVICE		; Anim0(15, ?, 163, 114, 0)
	add	sp, 0Ch
	push	word ptr cs:nozzle_item
	push	RC_TAKEITEM
	SERVICE		; TakeItem(?)
	add	sp, 4
	retf

H_136E:
	SCRIPT	MSG_USE, ANY, 24h, 0, H_13B9
UseNozzle:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV1_012
	call	Say
	jmp	SHORT L13B8

T_LOV1_012	LABEL	BYTE
	DB	'#LOV1\LOV1_012#That nozzle is for anti-agents only, Jim.',0
L13B8:
	retf

; Running the replicator: only McCoy (msgs 4, 13), with a bottle on the
; nozzle and a dish in the chamber. Only ammonia gives the cure sample
; (msgs 7, 8): made_sample.
H_13B9:
	SCRIPT	MSG_USE, OBJ_SPOCK, 23h, 0, H_1427
SpockUsesReplicator:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV1_002
	call	Say
	jmp	SHORT L1426

T_LOV1_002	LABEL	BYTE
	DB	'#LOV1\LOV1_002#Captain, I believe Dr. McCoy has the necessary sk'
	DB	'ills to run that equipment.',0
L1426:
	retf

H_1427:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 23h, 0, H_147E
FerrisUsesReplicator:
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV1_026
	call	Say
	jmp	SHORT L147D

T_LOV1_026	LABEL	BYTE
	DB	'#LOV1\LOV1_026#Sir, I think Dr. McCoy should run it. I may break'
	DB	' it.',0
L147D:
	retf

H_147E:
	SCRIPT	MSG_USE, OBJ_MCCOY, 0Fh, 0, H_1486
	jmp	SHORT McCoyUsesChamber

H_1486:
	SCRIPT	MSG_USE, OBJ_MCCOY, 0Eh, 0, H_148E
McCoyUsesChamber:
	jmp	SHORT McCoyUsesReplicator

H_148E:
	SCRIPT	MSG_USE, OBJ_MCCOY, 23h, 0, H_14A9
McCoyUsesReplicator:
	push	4
	push	8Ch
	push	0B1h
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 177, 140, 4)
	add	sp, 0Ah
	retf

H_14A9:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_151E
McCoyAtReplicator:
	cmp	byte ptr [si+nozzle], 0
	jne	L14C1
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV1_021
	call	Say
	JMPN	L1565

L14C1:
	cmp	byte ptr [si+dish_in_chamber], 0
	jne	L1508
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV1_015
	call	Say
	jmp	SHORT L1506

T_LOV1_015	LABEL	BYTE
	DB	'#LOV1\LOV1_015#There is no specimen in the chamber.',0
L1506:
	jmp	SHORT L1565

L1508:
	push	0Dh
	push	-1
	push	-1
	push	OFFSET N_musehn
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musehn", -1, -1, 13)
	add	sp, 0Ch
	retf

H_151E:
	SCRIPT	MSG_ANIM_DONE, 0Dh, 0, 0, H_157A
Replicated:
	cmp	word ptr cs:nozzle_item, 66h
	je	L1537
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV1_019
	call	Say
	jmp	SHORT L1565

L1537:
	push	0Eh
	push	RC_STOPANIM
	SERVICE		; StopAnim(14)
	add	sp, 4
	push	7
	push	75h
	push	0B4h
	push	OFFSET N_s3r2d6
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s3r2d6", 180, 117, 7)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
L1565:
	push	0
	push	98h
	push	0BFh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 191, 152, 0)
	add	sp, 0Ah
	retf

H_157A:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_15A3
ChamberOpens:
	push	8
	push	75h
	push	0B4h
	push	OFFSET N_s3r2d5
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s3r2d5", 180, 117, 8)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	retf

H_15A3:
	SCRIPT	MSG_ANIM_DONE, 8, 0, 0, H_15CD
CureSampleMade:
	push	0
	push	71h
	push	0B4h
	push	OFFSET N_dishes
	push	0Eh
	push	RC_ANIM0
	SERVICE		; Anim0(14, "dishes", 180, 113, 0)
	add	sp, 0Ch
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV1_018
	call	Say
	mov	byte ptr [si+made_sample], 1
	retf

H_15CD:
	SCRIPT	MSG_USE, ANY, 0Ch, 0, H_1613
UseChamber:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV1_013
	call	Say
	jmp	SHORT L1612

T_LOV1_013	LABEL	BYTE
	DB	'#LOV1\LOV1_013#That''s for Virus Cultures only, Jim.',0
L1612:
	retf

; The dish into the chamber (msgs 5, 1, 14).
H_1613:
	SCRIPT	MSG_USE, IT_DISHES, 0Ch, 0, H_161B
	jmp	SHORT DishesInReplicator

H_161B:
	SCRIPT	MSG_USE, IT_DISHES, 23h, 0, H_1636
DishesInReplicator:
	push	5
	push	8Ch
	push	0B3h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 179, 140, 5)
	add	sp, 0Ah
	retf

H_1636:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_16AB
KirkAtReplicator:
	cmp	byte ptr [si+dish_in_chamber], 0
	je	L1688
	mov	ax, 0
	mov	bx, OFFSET T_LOV1_014
	call	Say
	jmp	SHORT L1687

T_LOV1_014	LABEL	BYTE
	DB	'#LOV1\LOV1_014#There is already something in the chamber.',0
L1687:
	retf

L1688:
	push	1
	push	75h
	push	0B4h
	push	OFFSET N_s3r2d5
	push	0Ch
	push	RC_ANIM0
	SERVICE		; Anim0(12, "s3r2d5", 180, 117, 1)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	retf

H_16AB:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_16C7
ChamberOpen:
	push	0Eh
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 14)
	add	sp, 0Ch
	retf

H_16C7:
	SCRIPT	MSG_ANIM_DONE, 0Eh, 0, 0, H_16F4
DishesIn:
	push	0
	push	71h
	push	0B4h
	push	OFFSET N_dishes
	push	0Eh
	push	RC_ANIM0
	SERVICE		; Anim0(14, "dishes", 180, 113, 0)
	add	sp, 0Ch
	push	IT_DISHES
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_DISHES)
	add	sp, 4
	mov	byte ptr [si+dish_in_chamber], 1
	retf

; The distillator turns insulation into polyberylcarbonate (+1, once).
H_16F4:
	SCRIPT	MSG_USE, IT_INSULAT, 21h, 0, H_170F
DistillInsulation:
	push	6
	push	0C1h
	push	0BEh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 190, 193, 6)
	add	sp, 0Ah
	retf

H_170F:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_1745
KirkAtDistillator:
	push	0Fh
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 15)
	add	sp, 0Ch
	jmp	SHORT L1735

N_LD1PROCE	LABEL	BYTE
	DB	'LD1PROCE',0
L1735:
	push	OFFSET N_LD1PROCE
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("LD1PROCE")
	add	sp, 4
	retf

H_1745:
	SCRIPT	MSG_ANIM_DONE, 0Fh, 0, 0, H_17C1
Distilled:
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N034
	call	Say
	jmp	SHORT L179A

T_LOV1N034	LABEL	BYTE
	DB	'#LOV1\LOV1N034#You have distilled a quantity of Polyberylcarbona'
	DB	'te.',0
L179A:
	cmp	byte ptr [si+distilled], 1
	je	L17A8
	mov	byte ptr [si+distilled], 1
	add	word ptr [si+score], 1
L17A8:
	push	IT_PBC
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_PBC)
	add	sp, 4
	push	IT_INSULAT
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_INSULAT)
	add	sp, 4
	retf

; Opening or closing the freezer (msgs 7, 16).
H_17C1:
	SCRIPT	MSG_USE, OBJ_KIRK, 22h, 0, H_17C9
	jmp	SHORT KirkOpensFreezer

H_17C9:
	SCRIPT	MSG_USE, OBJ_KIRK, 0Bh, 0, H_17F0
KirkOpensFreezer:
	push	7
	mov	word ptr cs:back_y, 0A0h
	mov	word ptr cs:back_x, 96h
	mov	word ptr cs:crew, 0
	mov	word ptr cs:crew_anim, OFFSET N_kusehw
	JMPN	L1878

H_17F0:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 22h, 0, H_17F8
	jmp	SHORT FerrisOpensFreezer

H_17F8:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 0Bh, 0, H_181E
FerrisOpensFreezer:
	push	7
	mov	word ptr cs:back_y, 89h
	mov	word ptr cs:back_x, 95h
	mov	word ptr cs:crew, 3
	mov	word ptr cs:crew_anim, OFFSET N_rusehw
	jmp	SHORT L1878

H_181E:
	SCRIPT	MSG_USE, OBJ_SPOCK, 22h, 0, H_1826
	jmp	SHORT SpockOpensFreezer

H_1826:
	SCRIPT	MSG_USE, OBJ_SPOCK, 0Bh, 0, H_184C
SpockOpensFreezer:
	push	7
	mov	word ptr cs:back_y, 0A9h
	mov	word ptr cs:back_x, 61h
	mov	word ptr cs:crew, 1
	mov	word ptr cs:crew_anim, OFFSET N_susehw
	jmp	SHORT L1878

H_184C:
	SCRIPT	MSG_USE, OBJ_MCCOY, 22h, 0, H_1854
	jmp	SHORT McCoyOpensFreezer

H_1854:
	SCRIPT	MSG_USE, OBJ_MCCOY, 0Bh, 0, H_1891
McCoyOpensFreezer:
	push	7
	mov	word ptr cs:back_y, 98h
	mov	word ptr cs:back_x, 0BFh
	mov	word ptr cs:crew, 2
	mov	word ptr cs:crew_anim, OFFSET N_musehw
L1878:
	push	8Eh
	push	71h
	push	word ptr cs:crew
	push	RC_WALK
	SERVICE		; Walk(?, 113, 142, ?)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

H_1891:
	SCRIPT	MSG_WALK_DONE, 7, 0, 0, H_18B2
AtFreezer:
	push	10h
	push	-1
	push	-1
	push	word ptr cs:crew_anim
	push	word ptr cs:crew
	push	RC_ANIM2
	SERVICE		; Anim(?, ?, -1, -1, 16)
	add	sp, 0Ch
	retf

H_18B2:
	SCRIPT	MSG_ANIM_DONE, 10h, 0, 0, H_1908
FreezerToggled:
	push	0
	push	8Dh
	push	67h
	push	OFFSET N_s3r2d4
	cmp	byte ptr [si+freezer_open], 1
	jne	L18CC
	pop	ax
	push	OFFSET N_s3r2d4a
L18CC:
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, ?, 103, 141, 0)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	xor	byte ptr [si+freezer_open], 1
	push	0
	push	word ptr cs:back_y
	push	word ptr cs:back_x
	push	word ptr cs:crew
	push	RC_WALK
	SERVICE		; Walk(?, ?, ?, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Other things on the equipment.
H_1908:
	SCRIPT	MSG_USE, ANY, 22h, 0, H_1922
UseFreezer:
	push	0Bh
	push	8Eh
	push	6Fh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 111, 142, 11)
	add	sp, 0Ah
	retf

H_1922:
	SCRIPT	MSG_WALK_DONE, 0Bh, 0, 0, H_193E
KirkAtFreezer2:
	push	11h
	push	-1
	push	-1
	push	OFFSET N_kusemw
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemw", -1, -1, 17)
	add	sp, 0Ch
	retf

H_193E:
	SCRIPT	MSG_ANIM_DONE, 11h, 0, 0, H_1992
FreezerColder:
	mov	ax, 0
	mov	bx, OFFSET T_LOV1N008
	call	Say
	jmp	SHORT L1991

T_LOV1N008	LABEL	BYTE
	DB	'#LOV1\LOV1N008#It gets a little colder, but nothing else happens'
	DB	'.',0
L1991:
	retf

H_1992:
	SCRIPT	MSG_USE, ANY, 23h, 0, H_19AD
UseReplicator:
	push	0Ch
	push	8Ch
	push	0B5h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 181, 140, 12)
	add	sp, 0Ah
	retf

H_19AD:
	SCRIPT	MSG_WALK_DONE, 0Ch, 0, 0, H_19C9
KirkAtReplicator2:
	push	12h
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 18)
	add	sp, 0Ch
	retf

H_19C9:
	SCRIPT	MSG_ANIM_DONE, 12h, 0, 0, H_1A2E
NotAMicrowave:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV1_016
	call	Say
	jmp	SHORT L1A2D

T_LOV1_016	LABEL	BYTE
	DB	'#LOV1\LOV1_016#This isn''t a microwave, Jim! This is a delicate p'
	DB	'iece of equipment!',0
L1A2D:
	retf

H_1A2E:
	SCRIPT	MSG_USE, ANY, 21h, 0, H_1A49
UseDistillator:
	push	0Dh
	push	0B2h
	push	0C2h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 194, 178, 13)
	add	sp, 0Ah
	retf

H_1A49:
	SCRIPT	MSG_WALK_DONE, 0Dh, 0, 0, H_1A65
KirkAtDistillator2:
	push	13h
	push	-1
	push	-1
	push	OFFSET N_kuseme
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseme", -1, -1, 19)
	add	sp, 0Ch
	retf

H_1A65:
	SCRIPT	MSG_ANIM_DONE, 13h, 0, 0, H_1ABC
NotACanOpener:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV1_008
	call	Say
	jmp	SHORT L1ABB

T_LOV1_008	LABEL	BYTE
	DB	'#LOV1\LOV1_008#Careful, Jim! That''s a distillator, not a can-ope'
	DB	'ner.',0
L1ABB:
	retf

; The ladder to the deck below (room 4): unless the Romulans there are
; out, a Romulan shoots whoever goes first (msg 6); Kirk's death ends the
; game.
H_1ABC:
	SCRIPT	MSG_USE, OBJ_KIRK, 20h, 0, H_1ACF
KirkClimbsDown:
	mov	word ptr cs:crew, 0
	mov	byte ptr [si+RS_FALL], 0
	jmp	SHORT L1B06

H_1ACF:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_1AE2
SpockClimbsDown:
	mov	word ptr cs:crew, 1
	mov	byte ptr [si+RS_FALL+1], 0
	jmp	SHORT L1B06

H_1AE2:
	SCRIPT	MSG_USE, OBJ_MCCOY, 20h, 0, H_1AF5
McCoyClimbsDown:
	mov	word ptr cs:crew, 2
	mov	byte ptr [si+RS_FALL+2], 0
	jmp	SHORT L1B06

H_1AF5:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 20h, 0, H_1B22
FerrisClimbsDown:
	mov	word ptr cs:crew, 3
	mov	byte ptr [si+RS_FALL+3], 0
L1B06:
	push	1
	push	89h
	push	102h
	push	word ptr cs:crew
	push	RC_WALK
	SERVICE		; Walk(?, 258, 137, 1)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

H_1B22:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_1BF5
AtLadder:
	cmp	byte ptr [si+romulans_out], 1
	je	L1B5A
	cmp	byte ptr [si+virus_struck], 1
	je	L1B5A
	push	0
	push	89h
	push	0F3h
	push	OFFSET N_s3r2s2
	push	0Dh
	push	RC_ANIM0
	SERVICE		; Anim0(13, "s3r2s2", 243, 137, 0)
	add	sp, 0Ch
	push	6
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L1B69

	DB	0CBh
L1B5A:
	push	3
	push	4
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(4, 3)
	add	sp, 6
	retf

L1B69:
	push	6
	push	89h
	push	102h
	cmp	word ptr cs:crew, 0
	jne	L1B8A
	mov	word ptr cs:victim, OFFSET N_Capt_Kirk
	push	OFFSET N_kkillw
	push	word ptr cs:crew
	jmp	SHORT L1BEA

L1B8A:
	cmp	word ptr cs:crew, 1
	jne	L1BA3
	mov	word ptr cs:victim, OFFSET N_Mr_Spock
	push	OFFSET N_skillw
	push	word ptr cs:crew
	jmp	SHORT L1BEA

L1BA3:
	cmp	word ptr cs:crew, 2
	jne	L1BBC
	mov	word ptr cs:victim, OFFSET N_Dr_McCoy
	push	OFFSET N_mkillw
	push	word ptr cs:crew
	jmp	SHORT L1BEA

L1BBC:
	cmp	word ptr cs:crew, 3
	jne	L1BCE
	push	OFFSET N_rkillw
	push	word ptr cs:crew
	jmp	SHORT L1BEA

L1BCE:
	mov	ax, 0
	mov	bx, OFFSET N_Animation_Error
	call	Say
	jmp	SHORT L1BE9

N_Animation_Error	LABEL	BYTE
	DB	'Animation Error',0
L1BE9:
	retf

L1BEA:
	push	RC_ANIM0
	SERVICE		; Anim0(?, ?, 258, 137, 6)
	add	sp, 0Ch
	retf

H_1BF5:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_1C67
ShotOnLadder:
	cmp	word ptr cs:crew, 3
	jne	L1C35
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV1_024
	call	Say
	jmp	SHORT L1C2C

T_LOV1_024	LABEL	BYTE
	DB	'#LOV1\LOV1_024#Arrggghhh!',0
L1C2C:
	mov	byte ptr [si+RS_REDSHIRT_DEAD], 1
	mov	byte ptr [si+RS_BUSY], 0
	retf

L1C35:
	mov	ax, word ptr cs:victim
	mov	bx, OFFSET T_LOV1_025
	call	Say
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	retf

T_LOV1_025	LABEL	BYTE
	DB	'#LOV1\LOV1_025#Aieee!!',0

; Region 0, near the ladder: Ferris warns of the Romulans, once.
H_1C67:
	SCRIPT	MSG_REGION, 0, 0, 0, H_1D2C
NearLadder:
	cmp	byte ptr [si+romulans_out], 1
	jne	L1C76
	JMPN	L1D1A

L1C76:
	cmp	byte ptr [si+virus_struck], 1
	jne	L1C7F
	JMPN	L1D1A

L1C7F:
	push	0
	push	89h
	push	0F3h
	push	OFFSET N_s3r2s1
	push	0Dh
	push	RC_ANIM0
	SERVICE		; Anim0(13, "s3r2s1", 243, 137, 0)
	add	sp, 0Ch
	push	6
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	mov	byte ptr cs:warned, 1
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L1D1A
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV1_028
	call	Say
	jmp	SHORT L1D1A

T_LOV1_028	LABEL	BYTE
	DB	'#LOV1\LOV1_028#Watch out, sir! It looks like the Romulans have t'
	DB	'aken control of the lower decks.',0
L1D1A:
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
H_1D2C:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_1F49
CrewLaugh:
	push	2
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 2)
	add	sp, 6
	mov	word ptr cs:unused2, ax
	cmp	word ptr cs:unused2, 0
	jne	L1D55
	mov	word ptr cs:unused1, OFFSET N_Dr_McCoy
	jmp	SHORT L1D92

L1D55:
	cmp	word ptr cs:unused2, 1
	jne	L1D76
	mov	word ptr cs:unused1, OFFSET N_Lt_Ferris
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L1D74
	mov	word ptr cs:unused1, OFFSET N_Dr_McCoy
	JMPN	L1E3D

L1D74:
	jmp	SHORT L1D92

L1D76:
	mov	ax, 0
	mov	bx, OFFSET N_get_name_error
	call	Say
	jmp	SHORT L1D91

N_get_name_error	LABEL	BYTE
	DB	'get name error.',0
L1D91:
	retf

L1D92:
	mov	word ptr cs:unused1, OFFSET N_Dr_McCoy
	push	0Ah
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 10)
	add	sp, 6
	mov	word ptr cs:unused2, ax
	cmp	word ptr cs:unused2, 0
	jne	L1DB9
	mov	bx, OFFSET T_LOV0_011
	JMPN	L1EE4

L1DB9:
	cmp	word ptr cs:unused2, 1
	jne	L1DC7
	mov	bx, OFFSET T_LOV0_020
	JMPN	L1EE4

L1DC7:
	cmp	word ptr cs:unused2, 2
	jne	L1DD5
	mov	bx, OFFSET T_LOV0_016
	JMPN	L1EE4

L1DD5:
	cmp	word ptr cs:unused2, 3
	jne	L1DE3
	mov	bx, OFFSET T_LOV0_012
	JMPN	L1EE4

L1DE3:
	cmp	word ptr cs:unused2, 4
	jne	L1DF1
	mov	bx, OFFSET T_LOV0_014
	JMPN	L1EE4

L1DF1:
	cmp	word ptr cs:unused2, 5
	jne	L1DFF
	mov	bx, OFFSET T_LOV0_022
	JMPN	L1EE4

L1DFF:
	cmp	word ptr cs:unused2, 6
	jne	L1E0D
	mov	bx, OFFSET T_LOV0_015
	JMPN	L1EE4

L1E0D:
	cmp	word ptr cs:unused2, 7
	jne	L1E1B
	mov	bx, OFFSET T_LOV0_021
	JMPN	L1EE4

L1E1B:
	cmp	word ptr cs:unused2, 8
	jne	L1E29
	mov	bx, OFFSET T_LOV0_013
	JMPN	L1EE4

L1E29:
	cmp	word ptr cs:unused2, 9
	jne	L1E37
	mov	bx, OFFSET T_LOV0_019
	JMPN	L1EE4

L1E37:
	mov	bx, OFFSET T_LOV0_017
	JMPN	L1EE4

L1E3D:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L1E44
	retf

L1E44:
	mov	word ptr cs:unused1, OFFSET N_Lt_Ferris
	push	0Ah
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 10)
	add	sp, 6
	mov	word ptr cs:unused2, ax
	cmp	word ptr cs:unused2, 0
	jne	L1E6A
	mov	bx, OFFSET T_LOV0_039
	jmp	SHORT L1EE4

L1E6A:
	cmp	word ptr cs:unused2, 1
	jne	L1E77
	mov	bx, OFFSET T_LOV0_048
	jmp	SHORT L1EE4

L1E77:
	cmp	word ptr cs:unused2, 2
	jne	L1E84
	mov	bx, OFFSET T_LOV0_045
	jmp	SHORT L1EE4

L1E84:
	cmp	word ptr cs:unused2, 3
	jne	L1E91
	mov	bx, OFFSET T_LOV0_040
	jmp	SHORT L1EE4

L1E91:
	cmp	word ptr cs:unused2, 4
	jne	L1E9E
	mov	bx, OFFSET T_LOV0_042
	jmp	SHORT L1EE4

L1E9E:
	cmp	word ptr cs:unused2, 5
	jne	L1EAB
	mov	bx, OFFSET T_LOV0_050
	jmp	SHORT L1EE4

L1EAB:
	cmp	word ptr cs:unused2, 6
	jne	L1EB8
	mov	bx, OFFSET T_LOV0_043
	jmp	SHORT L1EE4

L1EB8:
	cmp	word ptr cs:unused2, 7
	jne	L1EC5
	mov	bx, OFFSET T_LOV0_049
	jmp	SHORT L1EE4

L1EC5:
	cmp	word ptr cs:unused2, 8
	jne	L1ED2
	mov	bx, OFFSET T_LOV0_041
	jmp	SHORT L1EE4

L1ED2:
	cmp	word ptr cs:unused2, 9
	jne	L1EDF
	mov	bx, OFFSET T_LOV0_047
	jmp	SHORT L1EE4

L1EDF:
	mov	bx, OFFSET T_LOV0_046
	jmp	SHORT L1EE4

L1EE4:
	mov	ax, word ptr cs:unused1
	call	Say
	cmp	byte ptr [si+rlg_released], 1
	jne	L1EF2
	retf

L1EF2:
	push	3
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 3)
	add	sp, 6
	mov	word ptr cs:unused2, ax
	mov	ax, OFFSET N_Mr_Spock
	cmp	word ptr cs:unused2, 0
	jne	L1F14
	mov	bx, OFFSET T_LOV0_029
	jmp	SHORT L1F33

L1F14:
	cmp	word ptr cs:unused2, 1
	jne	L1F21
	mov	bx, OFFSET T_LOV0_033
	jmp	SHORT L1F33

L1F21:
	cmp	word ptr cs:unused2, 2
	jne	L1F2E
	mov	bx, OFFSET T_LOV0_026
	jmp	SHORT L1F33

L1F2E:
	mov	bx, OFFSET T_LOV0_124
	jmp	SHORT L1F33

L1F33:
	call	Say
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS], ax
	retf

; Timer 1 (after Romulan laughing gas): Spock laughs.
H_1F49:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_1FDB
SpockLaughs:
	push	7
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 7)
	add	sp, 6
	mov	word ptr cs:unused2, ax
	mov	ax, OFFSET N_Mr_Spock
	cmp	word ptr cs:unused2, 0
	jne	L1F71
	mov	bx, OFFSET T_LOV0_025
	jmp	SHORT L1FC4

L1F71:
	cmp	word ptr cs:unused2, 1
	jne	L1F7E
	mov	bx, OFFSET T_LOV0_101
	jmp	SHORT L1FC4

L1F7E:
	cmp	word ptr cs:unused2, 2
	jne	L1F8B
	mov	bx, OFFSET T_LOV0_102
	jmp	SHORT L1FC4

L1F8B:
	cmp	word ptr cs:unused2, 3
	jne	L1F98
	mov	bx, OFFSET T_LOV0_103
	jmp	SHORT L1FC4

L1F98:
	cmp	word ptr cs:unused2, 4
	jne	L1FA5
	mov	bx, OFFSET T_LOV0_104
	jmp	SHORT L1FC4

L1FA5:
	cmp	word ptr cs:unused2, 5
	jne	L1FB2
	mov	bx, OFFSET T_LOV0_105
	jmp	SHORT L1FC4

L1FB2:
	cmp	word ptr cs:unused2, 6
	jne	L1FBF
	mov	bx, OFFSET T_LOV0_106
	jmp	SHORT L1FC4

L1FBF:
	mov	bx, OFFSET T_LOV0_107
	jmp	SHORT L1FC4

L1FC4:
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
H_1FDB:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_SPOCK, 0, H_2069
MedkitOnSpock:
	cmp	byte ptr [si+spock_cured], 1
	je	L2035
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_019
	call	Say
	jmp	SHORT L2034

T_LOV5_019	LABEL	BYTE
	DB	'#LOV5\LOV5_019#I don''t have the proper medicine to cure him, Jim'
	DB	'.',0
L2034:
	retf

L2035:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_015
	call	Say
	jmp	SHORT L2068

T_LOV5_015	LABEL	BYTE
	DB	'#LOV5\LOV5_015#He''s already cured, Jim.',0
L2068:
	retf

H_2069:
	SCRIPT	MSG_USE, IT_SAMPLE, OBJ_SPOCK, 0, H_20DC
SampleOnSpock:
	cmp	byte ptr [si+spock_cured], 1
	jne	L2078
	JMPN	L211C

L2078:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F55
	call	Say
	jmp	SHORT L20DB

T_LOVA_F55	LABEL	BYTE
	DB	'#LOVA\LOVA_F55#Jim, we need to sysnthesize more to make the seru'
	DB	'm before we can use it.',0
L20DB:
	retf

H_20DC:
	SCRIPT	MSG_USE, IT_CURE, OBJ_SPOCK, 0, H_2158
CureSpock:
	cmp	byte ptr [si+spock_cured], 1
	jne	L211C
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_015_2
	call	Say
	jmp	SHORT L211B

T_LOV5_015_2	LABEL	BYTE
	DB	'#LOV5\LOV5_015#He''s already cured, Jim.',0
L211B:
	retf

L211C:
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

H_2158:
	SCRIPT	MSG_WALK_DONE, 63h, 0, 0, H_2182
AtSpock:
	inc	byte ptr cs:cure_steps
	cmp	byte ptr cs:cure_steps, 2
	je	L216C
	retf

L216C:
	push	63h
	push	-1
	push	-1
	push	OFFSET N_musemn
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musemn", -1, -1, 99)
	add	sp, 0Ch
	retf

H_2182:
	SCRIPT	MSG_ANIM_DONE, 63h, 0, 0, H_2241
SpockCured:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_030
	call	Say
	jmp	SHORT L21BB

T_LOV5_030	LABEL	BYTE
	DB	'#LOV5\LOV5_030#There. You''re now cured.',0
L21BB:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV5_038
	call	Say
	jmp	SHORT L21E8

T_LOV5_038	LABEL	BYTE
	DB	'#LOV5\LOV5_038#Thank you, Doctor.',0
L21E8:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_027
	call	Say
	jmp	SHORT L221D

T_LOV5_027	LABEL	BYTE
	DB	'#LOV5\LOV5_027#Finally, a human response!',0
L221D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_2228
	call	Say
	jmp	SHORT L223C

S_2228	LABEL	BYTE
	DB	'(raises an eyebrow)',0
L223C:
	mov	byte ptr [si+spock_cured], 1
	retf

; Timer 2, every 200 ticks until Spock is cured: the virus advances,
; with a line at 0Fh, 1Eh, 2Dh; at 3Ch Spock collapses, at 64h he dies.
H_2241:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_23F7
VirusProgresses:
	cmp	byte ptr [si+spock_cured], 1
	jne	L224E
	retf

L224E:
	inc	byte ptr [si+virus]
	cmp	byte ptr [si+virus], 64h
	jl	L225A
	JMPN	L23A7

L225A:
	cmp	byte ptr [si+virus], 0Fh
	jne	L2291
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_spokcoff
	call	Say
	jmp	SHORT L228B

T_spokcoff	LABEL	BYTE
	DB	'#sfx\spokcoff#cough... cough...',0
L228B:
	inc	byte ptr [si+virus]
	JMPN	L23A1

L2291:
	cmp	byte ptr [si+virus], 1Eh
	jne	L22F7
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F08
	call	Say
	jmp	SHORT L22F1

T_LOVA_F08	LABEL	BYTE
	DB	'#LOVA\LOVA_F08#It''s what I was afraid of, Jim. I think spock is '
	DB	'getting worse.',0
L22F1:
	inc	byte ptr [si+virus]
	JMPN	L23A1

L22F7:
	cmp	byte ptr [si+virus], 2Dh
	jne	L232D
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_spokcoff_2
	call	Say
	jmp	SHORT L2328

T_spokcoff_2	LABEL	BYTE
	DB	'#sfx\spokcoff#cough... cough...',0
L2328:
	inc	byte ptr [si+virus]
	jmp	SHORT L23A1

L232D:
	cmp	byte ptr [si+virus], 3Ch
	jne	L23A1
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOVA_F54
	call	Say
	jmp	SHORT L2398

T_LOVA_F54	LABEL	BYTE
	DB	'#LOVA\LOVA_F54#The virus has spread to me, Captain.Isuggestyouco'
	DB	'ncentrateyoureffortsonthe',0
L2398:
	mov	byte ptr [si+virus_struck], 1
	inc	byte ptr [si+virus]
	jmp	SHORT L23A1

L23A1:
	mov	word ptr [si+RS_TIMERS+4], 0C8h
	retf

L23A7:
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
	jmp	SHORT L23EC

T_GENER004	LABEL	BYTE
	DB	'#GENE\GENER004#Game Over',0
L23EC:
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	retf

; McCoy's tricorder on Spock follows the virus; on the others, normal.
H_23F7:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_SPOCK, 0, H_2668
McCoyScansSpock:
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	cmp	byte ptr [si+spock_cured], 1
	jne	L2451
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F01
	call	Say
	jmp	SHORT L2450

T_LOVA_F01	LABEL	BYTE
	DB	'#LOVA\LOVA_F01#He''s been cured of the Oroborus virus.',0
L2450:
	retf

L2451:
	cmp	byte ptr [si+have_research], 1
	je	L24C3
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F02
	call	Say
	jmp	SHORT L24C2

T_LOVA_F02	LABEL	BYTE
	DB	'#LOVA\LOVA_F02#I''m picking up some kind of virus. I can''t identi'
	DB	'fy it without more information.',0
L24C2:
	retf

L24C3:
	cmp	byte ptr [si+virus], 0Ah
	jge	L2518
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F04
	call	Say
	jmp	SHORT L2517

T_LOVA_F04	LABEL	BYTE
	DB	'#LOVA\LOVA_F04#The virus affects the Romulan-Vulcan genotype, Ji'
	DB	'm.',0
L2517:
	retf

L2518:
	cmp	byte ptr [si+virus], 1Eh
	jge	L255C
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F03
	call	Say
	jmp	SHORT L255B

T_LOVA_F03	LABEL	BYTE
	DB	'#LOVA\LOVA_F03#He''s infected with the virus, Jim.',0
L255B:
	retf

L255C:
	cmp	byte ptr [si+virus], 32h
	jge	L25BD
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F08_2
	call	Say
	jmp	SHORT L25BC

T_LOVA_F08_2	LABEL	BYTE
	DB	'#LOVA\LOVA_F08#It''s what I was afraid of, Jim. I think spock is '
	DB	'getting worse.',0
L25BC:
	retf

L25BD:
	cmp	byte ptr [si+virus], 46h
	jne	L2603
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG2_010
	call	Say
	jmp	SHORT L2602

T_TUG2_010	LABEL	BYTE
	DB	'#TUG2\TUG2_010#I don''t like the looks of this, Jim.',0
L2602:
	retf

L2603:
	cmp	byte ptr [si+virus], 64h
	jge	L263D
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F10
	call	Say
	jmp	SHORT L263C

T_LOVA_F10	LABEL	BYTE
	DB	'#LOVA\LOVA_F10#He has weak vital signs.',0
L263C:
	retf

L263D:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_100
	call	Say
	jmp	SHORT L2667

T_LOVA_100	LABEL	BYTE
	DB	'#LOVA\LOVA_100#He''s dead, Jim.',0
L2667:
	retf

H_2668:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_KIRK, 0, H_2670
	jmp	SHORT McCoyScansMcCoy

H_2670:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_MCCOY, 0, H_2678
McCoyScansMcCoy:
	jmp	SHORT McCoyScansCrew

H_2678:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_REDSHIRT, 0, H_26BF
McCoyScansCrew:
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F07
	call	Say
	jmp	SHORT L26BE

T_LOVA_F07	LABEL	BYTE
	DB	'#LOVA\LOVA_F07#All lifesigns are normal.',0
L26BE:
	retf

; Opening a gas canister: Romulan laughing gas sets Spock laughing,
; nitrous oxide the crew, ammonia nothing.
H_26BF:
	SCRIPT	MSG_USE, IT_RLG, ANY, 0, H_270F
ReleaseRLG:
	mov	ax, OFFSET S_2C3E
	mov	bx, OFFSET T_LOV2N005
	call	Say
	jmp	SHORT L26FE

T_LOV2N005	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L26FE:
	mov	byte ptr [si+rlg_released], 1
	push	IT_RLG
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_RLG)
	add	sp, 4
	retf

H_270F:
	SCRIPT	MSG_USE, IT_N2O, ANY, 0, H_27A1
ReleaseN2O:
	mov	ax, OFFSET S_2C3E
	mov	bx, OFFSET T_LOV2N005_2
	call	Say
	jmp	SHORT L274E

T_LOV2N005_2	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L274E:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD2_040
	call	Say
	jmp	SHORT L2784

T_MUD2_040	LABEL	BYTE
	DB	'#MUD2\MUD2_040#You look troubled, Captain.',0
L2784:
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

H_27A1:
	SCRIPT	MSG_USE, IT_NH3, ANY, 0, H_2807
ReleaseNH3:
	mov	ax, OFFSET S_2C3E
	mov	bx, OFFSET T_LOV2N005_3
	call	Say
	jmp	SHORT L27E0

T_LOV2N005_3	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L27E0:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L27E6
L27E6:
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
H_2807:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, rdf_scripts_end
CallEnterprise:
	cmp	byte ptr [si+made_cure], 1
	jne	L2816
	JMPN	L2963

L2816:
	cmp	byte ptr [si+called_ship], 1
	jne	L281F
	JMPN	L28C3

L281F:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018
	call	Say
	jmp	SHORT L2864

T_MUD4_018	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L2864:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146
	call	Say
	jmp	SHORT L289A

T_BRIDU146	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L289A:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41
	call	Say
	jmp	SHORT L28BE

T_VENA_F41	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L28BE:
	mov	byte ptr [si+called_ship], 1
	retf

L28C3:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_2
	call	Say
	jmp	SHORT L2908

T_MUD4_018_2	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L2908:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_2
	call	Say
	jmp	SHORT L293E

T_BRIDU146_2	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L293E:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_2
	call	Say
	jmp	SHORT L2962

T_VENA_F41_2	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L2962:
	retf

L2963:
	cmp	byte ptr [si+called_ship_cured], 1
	jne	L296C
	JMPN	L2A10

L296C:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_3
	call	Say
	jmp	SHORT L29B1

T_MUD4_018_3	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L29B1:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_3
	call	Say
	jmp	SHORT L29E7

T_BRIDU146_3	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L29E7:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_3
	call	Say
	jmp	SHORT L2A0B

T_VENA_F41_3	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L2A0B:
	mov	byte ptr [si+called_ship_cured], 1
	retf

L2A10:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_4
	call	Say
	jmp	SHORT L2A55

T_MUD4_018_4	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L2A55:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_4
	call	Say
	jmp	SHORT L2A8B

T_BRIDU146_4	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L2A8B:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_4
	call	Say
	jmp	SHORT L2AAF

T_VENA_F41_4	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L2AAF:
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
	DW	246,102, 259,102, 259,127, 246,127
	DW	21h, 4	; id, points
	DW	198,140, 301,140, 302,188, 201,189
	DW	24h, 4	; id, points
	DW	158,101, 170,101, 170,117, 158,117
	DW	23h, 4	; id, points
	DW	158,77, 189,77, 189,128, 158,128
	DW	22h, 4	; id, points
	DW	94,88, 109,89, 109,133, 94,137
	DW	25h, 4	; id, points
	DW	210,22, 266,22, 266,65, 210,65
	DW	25h, 4	; id, points
	DW	210,66, 252,66, 290,115, 213,78
	DW	26h, 4	; id, points
	DW	192,125, 241,125, 241,134, 192,134
	DW	27h, 4	; id, points
	DW	48,144, 98,144, 98,165, 48,165
	DW	28h, 4	; id, points
	DW	107,130, 139,130, 139,139, 107,139
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	238,129, 269,129, 269,139, 238,139
	DW	1, 4	; id, points
	DW	192,125, 241,125, 241,134, 192,134
	DW	2, 4	; id, points
	DW	48,144, 98,144, 98,165, 48,165
	DW	3, 4	; id, points
	DW	107,130, 139,130, 139,139, 107,139
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's3r2l1',0
	DB	's3r2l2',0
	DB	's3r2l3',0
	DB	's3r2l5',0
	DB	's3r2l6',0
	DB	's3r2l7',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Ferris	LABEL	BYTE
	DB	'Lt. Ferris',0
N_wes	LABEL	BYTE
	DB	'wes',0
S_2C3E	LABEL	BYTE
	DB	0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0
	DB	'#LOV1\LOV1N005#You already have a culture dish.',0
T_LOV1N006	LABEL	BYTE
	DB	'#LOV1\LOV1N006#You take the Oroborus virus culture.',0
T_LOV1_018	LABEL	BYTE
	DB	'#LOV1\LOV1_018#Eureka! This is it, Jim! There''s not much, but al'
	DB	'l I need to do is synthesize some more, and we''re in business.',0
T_LOV1_019	LABEL	BYTE
	DB	'#LOV1\LOV1_019#This isn''t the result I was hoping for, Jim.',0
T_LOV1_021	LABEL	BYTE
	DB	'#LOV1\LOV1_021#We have to attach something to the nozzle first.',0
T_LOV1N000	LABEL	BYTE
	DB	'#LOV1\LOV1N000#A device to accelerate neutrinos. Not much good f'
	DB	'or anything else.',0
T_LOV1N003	LABEL	BYTE
	DB	'#LOV1\LOV1N003#James Tiberius Kirk.',0
T_LOV1N004	LABEL	BYTE
	DB	'#LOV1\LOV1N004#Mr. Spock is thinking about chemical formulas.',0
T_LOV1N001	LABEL	BYTE
	DB	'#LOV1\LOV1N001#Dr. McCoy is thinking about chemical formulas.',0
T_LOV1N002	LABEL	BYTE
	DB	'#LOV1\LOV1N002#Ensign Ferris doesn''t know much about chemical fo'
	DB	'rmulas.',0
T_LOV1_007	LABEL	BYTE
	DB	'#LOV1\LOV1_007#A Khrygellian II Basic Compound Distillator. Exce'
	DB	'llent piece of equipment for reducing complex materials to their'
	DB	' basic compounds.',0
T_LOV1_023	LABEL	BYTE
	DB	'#LOV1\LOV1_023#There are multiple culture samples of the virus w'
	DB	'ithin the freezer, Captain.',0
T_LOV1_006	LABEL	BYTE
	DB	'#LOV1\LOV1_006#A Hawking Neutrino Accelerator. It is one of the '
	DB	'finest in production today.',0
T_LOV1_022	LABEL	BYTE
	DB	'#LOV1\LOV1_022#Residue of a viral agent is still within the cham'
	DB	'ber.',0
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

RDF	ENDS
	END
