; VENG5.RDF - "Vengeance", the corridor outside the Republic's engineering
; section (room 6). Phasering a pile of debris uncovers a portable fusion
; power pack, very nearly setting it off.
;
; Actors: 8 the door, 9 the debris, 0Ah (10) the fusion pack, 0Bh (11) a
; body. Objects: those, 20h the door, 21h the ladder. Exit 1: the
; turbolift.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 16D8: the engine reads its bytes
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
debris_blasted	EQU	RS_VARS+30h	; the debris is blasted off the fusion pack
found_fusion	EQU	RS_VARS+31h	; Kirk has taken the fusion power pack
sensed_fusion	EQU	RS_VARS+32h	; Spock has sensed the power source
asked_fire	EQU	RS_VARS+33h	; Kirk has asked Spock about the fire

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0AEh	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	7Fh
rdf_scale_min	LABEL	BYTE
	DW	0C8h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, 9, -1, 6	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	0,0, 0,0	; entrance 0, crew 0
	DW	0,0, 0,0	; entrance 0, crew 1
	DW	0,0, 0,0	; entrance 0, crew 2
	DW	0,0, 0,0	; entrance 0, crew 3
	DW	169,186, 176,172	; entrance 1, crew 0
	DW	169,186, 140,180	; entrance 1, crew 1
	DW	169,186, 215,180	; entrance 1, crew 2
	DW	169,186, 196,188	; entrance 1, crew 3
	DW	0,0, 0,0	; entrance 2, crew 0
	DW	0,0, 0,0	; entrance 2, crew 1
	DW	0,0, 0,0	; entrance 2, crew 2
	DW	0,0, 0,0	; entrance 2, crew 3
	DW	106,145, 126,158	; entrance 3, crew 0
	DW	106,145, 114,153	; entrance 3, crew 1
	DW	106,145, 129,143	; entrance 3, crew 2
	DW	106,145, 112,145	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0

rdf_scripts:
; The room starts: the debris or the fusion pack.
H_00CA:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0159
StartRoom:
	jmp	SHORT L00DB

N_VEN5LOOP	LABEL	BYTE
	DB	'VEN5LOOP',0
L00DB:
	push	OFFSET N_VEN5LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("VEN5LOOP")
	add	sp, 4
	cmp	byte ptr [si+debris_blasted], 1
	je	L0112
	jmp	SHORT L00F9

N_s7r5de	LABEL	BYTE
	DB	's7r5de',0
L00F9:
	push	0
	push	89h
	push	0B1h
	push	OFFSET N_s7r5de
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s7r5de", 177, 137, 0)
	add	sp, 0Ch
	jmp	SHORT L0138

L0112:
	cmp	byte ptr [si+found_fusion], 1
	je	L0138
	jmp	SHORT L0121

N_s7r5fu	LABEL	BYTE
	DB	's7r5fu',0
L0121:
	push	0
	push	89h
	push	0B1h
	push	OFFSET N_s7r5fu
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s7r5fu", 177, 137, 0)
	add	sp, 0Ch
L0138:
	jmp	SHORT L0141

N_s7r5c1	LABEL	BYTE
	DB	's7r5c1',0
L0141:
	push	0
	push	91h
	push	0E2h
	push	OFFSET N_s7r5c1
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r5c1", 226, 145, 0)
	add	sp, 0Ch
	retf

; Tick 45, the first time: Spock senses a power source.
H_0159:
	SCRIPT	MSG_TICK, 2Dh, 0, 0, H_01D3
SpockSenses:
	cmp	byte ptr [si+sensed_fusion], 1
	je	L01D2
	mov	byte ptr [si+sensed_fusion], 1
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN5_005
	call	Say
	jmp	SHORT L01D2

T_VEN5_005	LABEL	BYTE
	DB	'#VEN5\VEN5_005#Captain, I''m picking up a functioning energy sour'
	DB	'ce in the immediate vicinity.',0
L01D2:
	retf

; Walking to the engineering door (msg 2, anim msg 1): on into room 6.
H_01D3:
	SCRIPT	MSG_WALK, 20h, 0, 0, H_01F6
WalkToDoor:
	mov	ax, 2
	push	ax
	mov	ax, 8Eh
	push	ax
	mov	ax, 78h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 120, 142, 2)
	add	sp, 0Ah
	retf

H_01F6:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_024C
AtDoor:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	jmp	SHORT L0219

N_s7r5d1	LABEL	BYTE
	DB	's7r5d1',0
L0219:
	push	1
	push	8Ch
	push	6Bh
	push	OFFSET N_s7r5d1
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s7r5d1", 107, 140, 1)
	add	sp, 0Ch
	mov	ax, 0
	push	ax
	mov	ax, 8Eh
	push	ax
	mov	ax, 64h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 100, 142, 0)
	add	sp, 0Ah
	retf

H_024C:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_025E
ToEngineering:
	push	2
	push	6
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(6, 2)
	retf

; Exit 1: the turbolift.
H_025E:
	SCRIPT	MSG_EXIT, 1, 0, 0, H_0283
ToTurbolift:
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	push	1
	push	5
	push	RC_TURBOLIFT
	SERVICE		; Turbolift(5, 1)
	add	sp, 6
	retf

; Looking.
H_0283:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_028B
	jmp	SHORT LookAtDoor

H_028B:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_02D1
LookAtDoor:
	mov	ax, 0
	mov	bx, OFFSET T_VEN5N007
	call	Say
	jmp	SHORT L02D0

T_VEN5N007	LABEL	BYTE
	DB	'#VEN5\VEN5N007#This door leads to main engineering.',0
L02D0:
	retf

H_02D1:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_0370
LookAtLadder:
	mov	ax, 0
	mov	bx, OFFSET T_VEN5N008
	call	Say
	JMPN	L036F

T_VEN5N008	LABEL	BYTE
	DB	'#VEN5\VEN5N008#These ladders are used when turbolifts are unavai'
	DB	'lable. Unfortunately, it is blocked by debris and a small, smold'
	DB	'ering fire.',0
L036F:
	retf

H_0370:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_03CF
LookAtBody:
	mov	ax, 0
	mov	bx, OFFSET T_VEN5N000
	call	Say
	jmp	SHORT L03CE

T_VEN5N000	LABEL	BYTE
	DB	'#VEN5\VEN5N000#A look of terror is still etched on the face of t'
	DB	'his crewman.',0
L03CE:
	retf

H_03CF:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_04A5
LookAtFusion:
	mov	ax, 0
	mov	bx, OFFSET T_VEN5N009
	call	Say
	JMPN	L04A4

T_VEN5N009	LABEL	BYTE
	DB	'#VEN5\VEN5N009#This is the most powerful portable energy storage'
	DB	' device ever developed by man. It is used to provide temporary p'
	DB	'ower to small systems when Main or Auxiliary power is unavailabl'
	DB	'e.',0
L04A4:
	retf

H_04A5:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_04E5
LookAtDebris:
	mov	ax, 0
	mov	bx, OFFSET T_VEN5N001
	call	Say
	jmp	SHORT L04E4

T_VEN5N001	LABEL	BYTE
	DB	'#VEN5\VEN5N001#A rather large pile of debris.',0
L04E4:
	retf

H_04E5:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_052A
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_VEN5N003
	call	Say
	jmp	SHORT L0529

T_VEN5N003	LABEL	BYTE
	DB	'#VEN5\VEN5N003#A sad but determined James T. Kirk.',0
L0529:
	retf

H_052A:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_0561
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_VEN5N002
	call	Say
	jmp	SHORT L0560

T_VEN5N002	LABEL	BYTE
	DB	'#VEN5\VEN5N002#A resolute Mr. Spock.',0
L0560:
	retf

H_0561:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_05B1
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_VEN5N004
	call	Say
	jmp	SHORT L05B0

T_VEN5N004	LABEL	BYTE
	DB	'#VEN5\VEN5N004#Dr. McCoy avoids the glances of his crewmates.',0
L05B0:
	retf

H_05B1:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_0613
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_VEN5N005
	call	Say
	jmp	SHORT L0612

T_VEN5N005	LABEL	BYTE
	DB	'#VEN5\VEN5N005#Ensign Kije, learning that Starfleet isn''t always'
	DB	' very pleasant.',0
L0612:
	retf

H_0613:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_066F
LookAtCorridor:
	mov	ax, 0
	mov	bx, OFFSET T_VEN5N006
	call	Say
	jmp	SHORT L066E

T_VEN5N006	LABEL	BYTE
	DB	'#VEN5\VEN5N006#This corridor leads to the Republic''s Engineering'
	DB	' section.',0
L066E:
	retf

; Phasers: a near miss on the fusion pack; the debris (msgs 4, 5, anim
; 3) uncovers it.
H_066F:
	SCRIPT	MSG_USE, IT_PHASERS, 0Ah, 0, H_0677
	jmp	SHORT PhaserFusion

H_0677:
	SCRIPT	MSG_USE, IT_PHASERK, 0Ah, 0, H_06E3
PhaserFusion:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN5_007
	call	Say
	jmp	SHORT L06E2

T_VEN5_007	LABEL	BYTE
	DB	'#VEN5\VEN5_007#Jim, are you mad? Put that phaser away. You almos'
	DB	't killed us once already.',0
L06E2:
	retf

H_06E3:
	SCRIPT	MSG_USE, IT_PHASERS, 9, 0, H_0734
StunDebris:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN5_013
	call	Say
	jmp	SHORT L0733

T_VEN5_013	LABEL	BYTE
	DB	'#VEN5\VEN5_013#The stun setting would be ineffective, Captain.',0
L0733:
	retf

H_0734:
	SCRIPT	MSG_USE, IT_PHASERK, 9, 0, H_075B
PhaserDebris:
	mov	ax, 4
	push	ax
	mov	ax, 0B9h
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 170, 185, 4)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

H_075B:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_0780
KirkAtDebris:
	jmp	SHORT L076A

N_kfiren	LABEL	BYTE
	DB	'kfiren',0
L076A:
	push	5
	push	-1
	push	-1
	push	OFFSET N_kfiren
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kfiren", -1, -1, 5)
	add	sp, 0Ch
	retf

H_0780:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_07C7
Fired:
	jmp	SHORT L078F

N_s7r5p1	LABEL	BYTE
	DB	's7r5p1',0
L078F:
	push	3
	push	89h
	push	0B1h
	push	OFFSET N_s7r5p1
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s7r5p1", 177, 137, 3)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	mov	ax, 9
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(9)
	add	sp, 4
	retf

H_07C7:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_09D2
DebrisGone:
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN5_011
	call	Say
	jmp	SHORT L0824

T_VEN5_011	LABEL	BYTE
	DB	'#VEN5\VEN5_011#Oh, my God, Jim! Is that what I think it is?',0
L0824:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN5_018
	call	Say
	jmp	SHORT L086F

T_VEN5_018	LABEL	BYTE
	DB	'#VEN5\VEN5_018#Yes, Doctor. It is a portable fusion power pack.',0
L086F:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN5_010
	call	Say
	jmp	SHORT L08EF

T_VEN5_010	LABEL	BYTE
	DB	'#VEN5\VEN5_010#A few centimeters lower with that phaser and half'
	DB	' this section would be history, not to mention us...',0
L08EF:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN5_019
	call	Say
	JMPN	L0983

T_VEN5_019	LABEL	BYTE
	DB	'#VEN5\VEN5_019#Actually, Doctor, three point two centimeters. An'
	DB	'd based on our proximity to the explosion, and the angle of the '
	DB	'beam...',0
L0983:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN5_003
	call	Say
	jmp	SHORT L09C9

T_VEN5_003	LABEL	BYTE
	DB	'#VEN5\VEN5_003#Thank you, Spock, I think we get the point.',0
L09C9:
	mov	byte ptr [si+debris_blasted], 1
	mov	byte ptr [si+RS_BUSY], 0
	retf

; The tricorders.
H_09D2:
	SCRIPT	MSG_USE, IT_MTRICOR, 9, 0, H_0A70
McCoyScansDebris:
	jmp	SHORT L09E1

N_mscanw	LABEL	BYTE
	DB	'mscanw',0
L09E1:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscanw
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscanw", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN5_008
	call	Say
	jmp	SHORT L0A6F

T_VEN5_008	LABEL	BYTE
	DB	'#VEN5\VEN5_008#No lifeforms present, Jim. I''m picking up some ki'
	DB	'nd of energy reading, though.',0
L0A6F:
	retf

H_0A70:
	SCRIPT	MSG_USE, IT_STRICOR, 9, 0, H_0B24
SpockScansDebris:
	jmp	SHORT L0A7F

N_sscann	LABEL	BYTE
	DB	'sscann',0
L0A7F:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscann
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscann", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN5_012
	call	Say
	jmp	SHORT L0B23

T_VEN5_012	LABEL	BYTE
	DB	'#VEN5\VEN5_012#I am picking up a high energy power source somewh'
	DB	'ere under the debris. I recommend caution, Captain.',0
L0B23:
	retf

H_0B24:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Ah, 0, H_0B8E
McCoyScansFusion:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN5_009
	call	Say
	jmp	SHORT L0B8D

T_VEN5_009	LABEL	BYTE
	DB	'#VEN5\VEN5_009#One of those fusion power packs, Jim. What do you'
	DB	' want me to do with it?',0
L0B8D:
	retf

H_0B8E:
	SCRIPT	MSG_USE, IT_STRICOR, 0Ah, 0, H_0C25
SpockScansFusion:
	jmp	SHORT L0B9D

N_sscann_2	LABEL	BYTE
	DB	'sscann',0
L0B9D:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscann_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscann", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN5_004
	call	Say
	jmp	SHORT L0C24

T_VEN5_004	LABEL	BYTE
	DB	'#VEN5\VEN5_004#A standard portable fusion power pack. It is full'
	DB	'y functional, Captain.',0
L0C24:
	retf

H_0C25:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0C6F
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN5_001
	call	Say
	jmp	SHORT L0C6E

T_VEN5_001	LABEL	BYTE
	DB	'#VEN5\VEN5_001#We must complete our mission, gentlemen.',0
L0C6E:
	retf

H_0C6F:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0CBF
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN5_006
	call	Say
	jmp	SHORT L0CBE

T_VEN5_006	LABEL	BYTE
	DB	'#VEN5\VEN5_006#I can''t say that I''m very talkative right now.',0
L0CBE:
	retf

H_0CBF:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0DA6
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN5_017
	call	Say
	jmp	SHORT L0D47

T_VEN5_017	LABEL	BYTE
	DB	'#VEN5\VEN5_017#This corridor seems to have been particularly dam'
	DB	'aged. There have been hull breaches on the deck below.',0
L0D47:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN5_R20
	call	Say
	jmp	SHORT L0DA5

T_VEN5_R20	LABEL	BYTE
	DB	'#VEN5\VEN5_R20#I will monitor the situation, Mr. Spock. I can us'
	DB	'e the distraction.',0
L0DA5:
	retf

H_0DA6:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0DE5
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN5_R19
	call	Say
	jmp	SHORT L0DE4

T_VEN5_R19	LABEL	BYTE
	DB	'#VEN5\VEN5_R19#Is there a question, Captain?',0
L0DE4:
	retf

; Region 0, the fire: Spock warns Kirk off.
H_0DE5:
	SCRIPT	MSG_REGION, 0, 0, 0, H_0F2A
NearFire:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN5_015
	call	Say
	jmp	SHORT L0E57

T_VEN5_015	LABEL	BYTE
	DB	'#VEN5\VEN5_015#Captain, it is unadvisable to approach too closel'
	DB	'y. There is an open fire nearby.',0
L0E57:
	cmp	byte ptr [si+asked_fire], 1
	jne	L0E60
	JMPN	L0F29

L0E60:
	mov	byte ptr [si+asked_fire], 1
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN5_002
	call	Say
	jmp	SHORT L0EA9

T_VEN5_002	LABEL	BYTE
	DB	'#VEN5\VEN5_002#Is the fire in danger of spreading, spock?',0
L0EA9:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN5_016
	call	Say
	jmp	SHORT L0F29

T_VEN5_016	LABEL	BYTE
	DB	'#VEN5\VEN5_016#No, Captain. There is an inadequate supply of fla'
	DB	'mmable material. It will eventually burn itself out.',0
L0F29:
	retf

; Taking the fusion pack (msgs 6, 7).
H_0F2A:
	SCRIPT	MSG_GET, 0Ah, 0, 0, H_0F4D
GetFusion:
	mov	ax, 6
	push	ax
	mov	ax, 8Ch
	push	ax
	mov	ax, 0B1h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 177, 140, 6)
	add	sp, 0Ah
	retf

H_0F4D:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_0F72
KirkAtFusion:
	jmp	SHORT L0F5C

N_kuseln	LABEL	BYTE
	DB	'kuseln',0
L0F5C:
	push	7
	push	-1
	push	-1
	push	OFFSET N_kuseln
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseln", -1, -1, 7)
	add	sp, 0Ch
	retf

H_0F72:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_0FE9
TookFusion:
	cmp	byte ptr [si+found_fusion], 1
	je	L0FE8
	mov	ax, 0Ah
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(10)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_VEN5N010
	call	Say
	jmp	SHORT L0FD4

T_VEN5N010	LABEL	BYTE
	DB	'#VEN5\VEN5N010#You pick up the portable Fusion power pack.',0
L0FD4:
	mov	byte ptr [si+found_fusion], 1
	mov	ax, IT_FUSION
	push	ax
	mov	ax, RC_GIVEITEM
	push	ax
	SERVICE		; GiveItem(IT_FUSION)
	add	sp, 4
L0FE8:
	retf

; Every tick, common to the mission's rooms: the Elasi deadlines set on
; the bridge (room 2). Until the Enterprise returns: boarding unless the
; shields are up, the thirty minutes, the wait after Kirk complies (then
; a warning and the torpedoes), the chance after they lower their
; shields. When one runs out, the game is over.
H_0FE9:
	SCRIPT	MSG_TICK, ANY, ANY, ANY, H_120D
ElasiDeadlines:
	cmp	word ptr [si+board_timer], 0
	je	L1003
	dec	word ptr [si+board_timer]
	jne	L1003
	cmp	byte ptr [si+power_to], 2
	je	L1003
	JMPN	L1103

L1003:
	cmp	word ptr [si+stall_timer], 0
	je	L1017
	dec	word ptr [si+stall_timer]
	jne	L1017
	cmp	byte ptr [si+complied], 1
	je	L1017
	JMPN	L1103

L1017:
	cmp	word ptr [si+comply_timer], 0
	je	L1076
	dec	word ptr [si+comply_timer]
	jne	L1076
	cmp	byte ptr [si+rescued], 1
	je	L1076
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_098
	call	Say
	jmp	SHORT L1071

T_VEN2_098	LABEL	BYTE
	DB	'#VEN2\VEN2_098#What are you stalling for? Lower your shields.',0
L1071:
	mov	word ptr [si+torpedo_timer], 0A8Ch
L1076:
	cmp	word ptr [si+torpedo_timer], 0
	je	L10EF
	dec	word ptr [si+torpedo_timer]
	jne	L10EF
	cmp	byte ptr [si+rescued], 1
	je	L10EF
	mov	ax, 0
	mov	bx, OFFSET T_VENA_F40
	call	Say
	jmp	SHORT L10E3

T_VENA_F40	LABEL	BYTE
	DB	'#VENA\VENA_F40#The Elasi fire photon torpedoes. The Republic has'
	DB	' been destroyed.',0
L10E3:
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
L10EF:
	cmp	word ptr [si+attack_timer], 0
	je	L1102
	dec	word ptr [si+attack_timer]
	jne	L1102
	cmp	byte ptr [si+rescued], 1
	je	L1102
	jmp	SHORT L1103

L1102:
	retf

L1103:
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

H_120D:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_1215
	jmp	SHORT KillAnything

H_1215:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_12AA
KillAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VENA_F34
	call	Say
	JMPN	L12A9

T_VENA_F34	LABEL	BYTE
	DB	'#VENA\VENA_F34#Captain, it would be unwise to use your phaser co'
	DB	'nsidering the already extensive damage sustained by the Republic'
	DB	'.',0
L12A9:
	retf

; The hypo, empty or full of oil.
H_12AA:
	SCRIPT	MSG_LOOK, IT_HYPO, 0, 0, H_1340
LookAtHypo:
	cmp	byte ptr [si+hypo_oiled], 1
	je	L12F7
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N010
	call	Say
	jmp	SHORT L12F6

T_VEN4N010	LABEL	BYTE
	DB	'#VEN4\VEN4N010#This is an empty hypodermic injector.',0
L12F6:
	retf

L12F7:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N007
	call	Say
	jmp	SHORT L133F

T_VEN6N007	LABEL	BYTE
	DB	'#VEN6\VEN6N007#The hypo is now filled with multipurpose oil.',0
L133F:
	retf

; The communicator: before the Enterprise leaves, Uhura; while the Elasi
; jam it, Spock; otherwise Uhura, tracking the distress call.
H_1340:
	SCRIPT	MSG_USE, IT_COMM, OBJ_KIRK, 0, H_1545
CallEnterprise:
	cmp	byte ptr [si+enterprise_away], 1
	je	L13C8
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018
	call	Say
	jmp	SHORT L1391

T_MUD4_018	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L1391:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146
	call	Say
	jmp	SHORT L13C7

T_BRIDU146	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L13C7:
	retf

L13C8:
	cmp	byte ptr [si+elasi_here], 1
	jne	L13D1
	JMPN	L14CE

L13D1:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_2
	call	Say
	jmp	SHORT L1415

T_MUD4_018_2	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise, Kirk to Enterprise...',0
L1415:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_VEN2U093
	call	Say
	jmp	SHORT L1480

T_VEN2U093	LABEL	BYTE
	DB	'#VEN2\VEN2U093#Enterprise here. We''re still tracking the distres'
	DB	's call. Are you all right, Sir?',0
L1480:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_028
	call	Say
	jmp	SHORT L14CD

T_VEN2_028	LABEL	BYTE
	DB	'#VEN2\VEN2_028#Yes, Uhura. Just wanted a status report. Kirk out'
	DB	'.',0
L14CD:
	retf

L14CE:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_066
	call	Say
	jmp	SHORT L1542

T_VEN2_066	LABEL	BYTE
	DB	'#VEN2\VEN2_066#They are jamming all frequencies, Captain. We wil'
	DB	'l not be able to contact the Enterprise.',0
L1542:
	retf

; In the room file, so these start again each time the room loads
mccoy_line	LABEL	BYTE	; which of McCoy's lines
	DB	0, 0

; McCoy and the body.
H_1545:
	SCRIPT	MSG_USE, IT_MEDKIT, 0Bh, 0, H_154D
	jmp	SHORT MTricorderOnBody

H_154D:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Bh, 0, H_1555
MTricorderOnBody:
	jmp	SHORT McCoyOnBody

H_1555:
	SCRIPT	MSG_USE, OBJ_MCCOY, 0Bh, 0, Talk
McCoyOnBody:
	push	5
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 5)
	add	sp, 6
	mov	word ptr cs:mccoy_line, ax
	cmp	word ptr cs:mccoy_line, 0
	jne	L15A0
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_019
	call	Say
	jmp	SHORT L159F

T_DEM3_019	LABEL	BYTE
	DB	'#DEM3\DEM3_019#He''s dead, jim.',0
L159F:
	retf

L15A0:
	cmp	word ptr cs:mccoy_line, 1
	jne	L15E8
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN4_016
	call	Say
	jmp	SHORT L15E7

T_VEN4_016	LABEL	BYTE
	DB	'#VEN4\VEN4_016#Jim...there''s nothing more I can do.',0
L15E7:
	retf

L15E8:
	cmp	word ptr cs:mccoy_line, 2
	jne	L1621
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_G_014
	call	Say
	jmp	SHORT L1620

T_G_014	LABEL	BYTE
	DB	'#GENE\G_014#This person''s dead, Jim.',0
L1620:
	retf

L1621:
	cmp	word ptr cs:mccoy_line, 3
	jne	L165A
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_G_014_2
	call	Say
	jmp	SHORT L1659

T_G_014_2	LABEL	BYTE
	DB	'#GENE\G_014#This person''s dead, Jim.',0
L1659:
	retf

L165A:
	cmp	word ptr cs:mccoy_line, 4
	jne	L169D
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_016
	call	Say
	jmp	SHORT L169C

T_VEN0_016	LABEL	BYTE
	DB	'#VEN0\VEN0_016#They''re dead, Jim. All of them.',0
L169C:
	retf

L169D:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_016_2
	call	Say
	jmp	SHORT L16D7

T_VEN0_016_2	LABEL	BYTE
	DB	'#VEN0\VEN0_016#They''re dead, Jim. All of them.',0
L16D7:
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
	DW	93,80, 107,80, 107,139, 93,147
	DW	21h, 4	; id, points
	DW	170,80, 212,80, 212,126, 170,126
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	1, 4	; id, points
	DW	50,188, 265,188, 265,199, 50,199
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	165,128, 220,128, 220,134, 165,134
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's7r5',0
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
	DB	'wes',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
