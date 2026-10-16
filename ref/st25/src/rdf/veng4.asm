; VENG4.RDF - "Vengeance", the Republic's sickbay. Kirk's academy friend
; Brittany Marata is dying here; treated, she says the attackers were the
; Enterprise, then dies. An empty hypo and a medical drill lie about.
;
; Actors: 8 Marata, 9 the door, 0Ah (10) the hypo, 0Bh (11) the drill,
; 0Ch (12) the monitor. Objects: those, 20h the door, 21h Marata's bed,
; 22h a body, 23h the scanner, 24h a monitor. Exit 2: the corridor (room
; 3).
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 104D: the engine reads its bytes
;   as key 50 6A 03 2E and next 1EFF (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
marata_treated	EQU	RS_VARS+0	; McCoy has stabilised Brittany Marata
marata_spoke	EQU	RS_VARS+1	; Marata has said who attacked the Republic
marata_dead	EQU	RS_VARS+2	; Marata has died
knew_marata	EQU	RS_VARS+3	; Kirk has recognised Marata
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
saw_marata	EQU	RS_VARS+2Dh	; McCoy has treated Marata: Kirk turns to the power (room 3)
hypo_taken	EQU	RS_VARS+2Eh	; Kirk has taken the hypo
drill_taken	EQU	RS_VARS+2Fh	; Kirk has taken the medical drill
clue_marata	EQU	RS_VARS+40h	; evidence: Marata's account

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0C7h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	9Bh
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
	DW	-1, -1, 3, -1	; room for each exit
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
	DW	306,174, 220,185	; entrance 2, crew 0
	DW	306,174, 261,194	; entrance 2, crew 1
	DW	306,174, 210,170	; entrance 2, crew 2
	DW	306,174, 276,174	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	268,181, 295,187, 248,170, 276,174	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	268,181, 295,187, 248,170, 276,174
; In the room file, so these start again each time the room loads
door_opening	LABEL	BYTE	; Kirk is walking out
	DB	0
with_medkit	LABEL	BYTE	; McCoy treats (medkit) rather than scans
	DB	0
N_s9r1do	LABEL	BYTE
	DB	's9r1do',0
	DB	's9r1bm',0
N_s9r1bh	LABEL	BYTE
	DB	's9r1bh',0
N_museme	LABEL	BYTE
	DB	'museme',0
N_mscane	LABEL	BYTE
	DB	'mscane',0

rdf_scripts:
; The room starts: Marata alive or dead, the hypo, the drill.
H_00EF:
	SCRIPT	MSG_TICK, 1, 0, 0, H_024E
StartRoom:
	mov	ax, 1Fh
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(31)
	add	sp, 4
	jmp	SHORT L010E

N_s9r1dc	LABEL	BYTE
	DB	's9r1dc',0
L010E:
	push	0
	push	0ABh
	push	13Fh
	push	OFFSET N_s9r1dc
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s9r1dc", 319, 171, 0)
	add	sp, 0Ch
	jmp	SHORT L012E

N_s7r4m2	LABEL	BYTE
	DB	's7r4m2',0
L012E:
	push	0
	push	75h
	push	5Ch
	push	OFFSET N_s7r4m2
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s7r4m2", 92, 117, 0)
	add	sp, 0Ch
	cmp	byte ptr [si+marata_treated], 1
	je	L0184
	jmp	SHORT L0152

N_s9r1bm	LABEL	BYTE
	DB	's9r1bm',0
L0152:
	push	0
	push	0A5h
	push	5Ah
	push	OFFSET N_s9r1bm
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s9r1bm", 90, 165, 0)
	add	sp, 0Ch
	jmp	SHORT L0173

N_VEN4LOOP	LABEL	BYTE
	DB	'VEN4LOOP',0
L0173:
	push	OFFSET N_VEN4LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("VEN4LOOP")
	add	sp, 4
	jmp	SHORT L01BD

L0184:
	jmp	SHORT L018F

N_VE42LOOP	LABEL	BYTE
	DB	'VE42LOOP',0
L018F:
	push	OFFSET N_VE42LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("VE42LOOP")
	add	sp, 4
	jmp	SHORT L01A7

N_s9r1bh_2	LABEL	BYTE
	DB	's9r1bh',0
L01A7:
	push	0
	push	0A5h
	push	5Ah
	push	OFFSET N_s9r1bh_2
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s9r1bh", 90, 165, 0)
	add	sp, 0Ch
L01BD:
	cmp	byte ptr [si+hypo_taken], 1
	je	L01E3
	jmp	SHORT L01CC

N_s7r4h1	LABEL	BYTE
	DB	's7r4h1',0
L01CC:
	push	0
	push	8Bh
	push	0EAh
	push	OFFSET N_s7r4h1
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s7r4h1", 234, 139, 0)
	add	sp, 0Ch
L01E3:
	cmp	byte ptr [si+drill_taken], 1
	je	L0209
	jmp	SHORT L01F2

N_s7r4dl	LABEL	BYTE
	DB	's7r4dl',0
L01F2:
	push	0
	push	87h
	push	0EAh
	push	OFFSET N_s7r4dl
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r4dl", 234, 135, 0)
	add	sp, 0Ch
L0209:
	cmp	byte ptr [si+marata_dead], 1
	jne	L024D
	jmp	SHORT L0218

N_s7r4bd	LABEL	BYTE
	DB	's7r4bd',0
L0218:
	push	0
	push	0A5h
	push	5Ah
	push	OFFSET N_s7r4bd
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s7r4bd", 90, 165, 0)
	add	sp, 0Ch
	jmp	SHORT L0238

N_s7r4m1d	LABEL	BYTE
	DB	's7r4m1d',0
L0238:
	push	0
	push	75h
	push	5Ch
	push	OFFSET N_s7r4m1d
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s7r4m1d", 92, 117, 0)
	add	sp, 0Ch
L024D:
	retf

; Talking.
H_024E:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_025E
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN4_002
	call	Say
	retf

H_025E:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_026E
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN4_015
	call	Say
	retf

H_026E:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_027E
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN4_017
	call	Say
	retf

H_027E:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_028E
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN4_022
	call	Say
	retf

; McCoy, the dead crewman and the hypo.
H_028E:
	SCRIPT	MSG_USE, IT_MEDKIT, 22h, 0, H_0296
	jmp	SHORT MTricorderOnBody

H_0296:
	SCRIPT	MSG_USE, IT_MTRICOR, 22h, 0, H_029E
MTricorderOnBody:
	jmp	SHORT McCoyOnBody

H_029E:
	SCRIPT	MSG_USE, OBJ_MCCOY, 22h, 0, H_02AE
McCoyOnBody:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN4_007
	call	Say
	retf

H_02AE:
	SCRIPT	MSG_USE, IT_HYPO, 8, 0, H_02F2
HypoOnMarata:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN4_008
	call	Say
	jmp	SHORT L02F1

T_VEN4_008	LABEL	BYTE
	DB	'#VEN4\VEN4_008#That will accomplish nothing, Jim.',0
L02F1:
	retf

; McCoy on Marata (msg 5): the tricorder scans her (anim 7), the medkit
; treats her (anim 6), which counts as evidence and is what lets her talk.
H_02F2:
	SCRIPT	MSG_USE, IT_MEDKIT, 8, 0, H_0300
MedkitOnMarata:
	mov	byte ptr cs:with_medkit, 1
	jmp	SHORT L0314

H_0300:
	SCRIPT	MSG_USE, IT_MTRICOR, 8, 0, H_0308
	jmp	SHORT McCoyOnMarata

H_0308:
	SCRIPT	MSG_USE, OBJ_MCCOY, 8, 0, H_0368
McCoyOnMarata:
	mov	byte ptr cs:with_medkit, 0
L0314:
	cmp	byte ptr [si+marata_dead], 1
	je	L035E
	cmp	byte ptr [si+marata_treated], 1
	jne	L032A
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN4_009
	call	Say
	retf

L032A:
	cmp	byte ptr [si+knew_marata], 1
	je	L033D
	mov	byte ptr [si+knew_marata], 1
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN4_005
	call	Say
L033D:
	mov	byte ptr [si+RS_FALL+2], 2
	mov	ax, 5
	push	ax
	mov	ax, 0A0h
	push	ax
	mov	ax, 3Ch
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 60, 160, 5)
	add	sp, 0Ah
	retf

L035E:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN4_013
	call	Say
	retf

H_0368:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_03AE
McCoyAtMarata:
	cmp	byte ptr cs:with_medkit, 1
	je	L0398
	push	7
	push	-1
	push	-1
	push	OFFSET N_mscane
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscane", -1, -1, 7)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	retf

L0398:
	push	6
	push	-1
	push	-1
	push	OFFSET N_museme
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "museme", -1, -1, 6)
	add	sp, 0Ch
	retf

H_03AE:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_03DF
TreatedMarata:
	push	0
	push	-1
	push	-1
	push	OFFSET N_s9r1bh
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s9r1bh", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+clue_marata], 1
	mov	byte ptr [si+marata_treated], 1
	mov	byte ptr [si+saw_marata], 1
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN4_009
	call	Say
	retf

H_03DF:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_0400
ScannedMarata:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN4_011
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN4_001
	call	Say
	mov	byte ptr cs:with_medkit, 1
	JMPN	L032A

; Talking to Marata, once treated: she thought it was the Enterprise, and
; dies.
H_0400:
	SCRIPT	MSG_TALK, 8, 0, 0, H_0530
TalkToMarata:
	cmp	byte ptr [si+marata_spoke], 1
	jne	L040F
	JMPN	L0526

L040F:
	cmp	byte ptr [si+marata_treated], 1
	je	L0418
	JMPN	L04E2

L0418:
	mov	byte ptr [si+marata_spoke], 1
	mov	ax, OFFSET N_Brittany_Marata
	mov	bx, OFFSET T_VEN4_019
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN4_004
	call	Say
	mov	ax, OFFSET N_Brittany_Marata
	mov	bx, OFFSET T_VEN4_020
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN4_006
	call	Say
	mov	ax, OFFSET N_Brittany_Marata
	mov	bx, OFFSET T_VEN4_021
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN4_003
	call	Say
	jmp	SHORT L045B

N_s9r1bm_2	LABEL	BYTE
	DB	's9r1bm',0
L045B:
	push	0
	push	0A5h
	push	5Ah
	push	OFFSET N_s9r1bm_2
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s9r1bm", 90, 165, 0)
	add	sp, 0Ch
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN4_016
	call	Say
	jmp	SHORT L0483

N_s7r4m1	LABEL	BYTE
	DB	's7r4m1',0
L0483:
	push	0
	push	75h
	push	5Ch
	push	OFFSET N_s7r4m1
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s7r4m1", 92, 117, 0)
	add	sp, 0Ch
	jmp	SHORT L04A1

N_s7r4bd_2	LABEL	BYTE
	DB	's7r4bd',0
L04A1:
	push	0
	push	0A5h
	push	5Ah
	push	OFFSET N_s7r4bd_2
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s7r4bd", 90, 165, 0)
	add	sp, 0Ch
	mov	byte ptr [si+marata_dead], 1
	mov	ax, RC_DIGIOFF
	push	ax
	SERVICE		; DigiOff()
	add	sp, 2
	jmp	SHORT L04D2

N_VE42LOOP_2	LABEL	BYTE
	DB	'VE42LOOP',0
L04D2:
	push	OFFSET N_VE42LOOP_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("VE42LOOP")
	add	sp, 4
	retf

L04E2:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN4_010
	call	Say
	jmp	SHORT L0525

T_VEN4_010	LABEL	BYTE
	DB	'#VEN4\VEN4_010#She''s in no condition to talk right now.',0
L0525:
	retf

L0526:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN4_012
	call	Say
	retf

; Looking.
H_0530:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_053F
LookAtBody:
	sub	ax, ax
	mov	bx, OFFSET T_VEN4N014
	call	Say
	retf

H_053F:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_054E
LookAtMonitor:
	sub	ax, ax
	mov	bx, OFFSET T_VEN4N013
	call	Say
	retf

H_054E:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_055D
LookAtDoor:
	sub	ax, ax
	mov	bx, OFFSET T_VEN4N008
	call	Say
	retf

H_055D:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_056C
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_VEN4N002
	call	Say
	retf

H_056C:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_057B
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_VEN4N003
	call	Say
	retf

H_057B:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_058A
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_VEN4N000
	call	Say
	retf

H_058A:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_0599
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_VEN4N001
	call	Say
	retf

H_0599:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_05B9
LookAtBed:
	cmp	byte ptr [si+marata_dead], 1
	jne	L05AF
	mov	ax, OFFSET S_114E
	mov	bx, OFFSET S_140D
	call	Say
	retf

L05AF:
	mov	ax, OFFSET S_114E
	mov	bx, OFFSET T_VEN4N007
	call	Say
	retf

H_05B9:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_062B
LookAtScanner:
	cmp	byte ptr [si+marata_dead], 1
	je	L05CF
	mov	ax, OFFSET S_114E
	mov	bx, OFFSET T_VEN4N006
	call	Say
	retf

L05CF:
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N005
	call	Say
	jmp	SHORT L062A

T_VEN4N005	LABEL	BYTE
	DB	'#VEN4\VEN4N005#The medical scanner has registered the death of B'
	DB	'rittany Marata.',0
L062A:
	retf

H_062B:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_076D
LookAtMarata:
	cmp	byte ptr [si+marata_dead], 1
	jne	L063A
	JMPN	L06DC

L063A:
	cmp	byte ptr [si+knew_marata], 1
	je	L0657
	mov	byte ptr [si+knew_marata], 1
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN4_005
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN4_014
	call	Say
	retf

L0657:
	cmp	byte ptr [si+marata_spoke], 1
	je	L06DC
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N004
	call	Say
	jmp	SHORT L06DB

T_VEN4N004	LABEL	BYTE
	DB	'#VEN4\VEN4N004#Seeing Brittany in this condition stirs you on to'
	DB	' find the culprits responsible for this injustice.',0
L06DB:
	retf

L06DC:
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N017
	call	Say
	JMPN	L076C

T_VEN4N017	LABEL	BYTE
	DB	'#VEN4\VEN4N017#You see the dead body of Brittany. Her life was c'
	DB	'ut short and you won''t stop until you find the persons responsib'
	DB	'le.',0
L076C:
	retf

H_076D:
	SCRIPT	MSG_USE, IT_STRICOR, 0Bh, 0, H_0775
	jmp	SHORT LookAtDrill

H_0775:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_07CA
LookAtDrill:
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N012
	call	Say
	jmp	SHORT L07C9

T_VEN4N012	LABEL	BYTE
	DB	'#VEN4\VEN4N012#This medical drill fires a microscopic phaser bea'
	DB	'm.',0
L07C9:
	retf

H_07CA:
	SCRIPT	MSG_USE, IT_STRICOR, 0Ah, 0, H_07D2
	jmp	SHORT LookAtHypo2

H_07D2:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_0819
LookAtHypo2:
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N010
	call	Say
	jmp	SHORT L0818

T_VEN4N010	LABEL	BYTE
	DB	'#VEN4\VEN4N010#This is an empty hypodermic injector.',0
L0818:
	retf

H_0819:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_0878
LookAtDoor2:
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N009
	call	Say
	jmp	SHORT L0877

T_VEN4N009	LABEL	BYTE
	DB	'#VEN4\VEN4N009#This door leads back to the corridor, and turboli'
	DB	'fts 1 and 2.',0
L0877:
	retf

H_0878:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_08E7
LookAtSickbay:
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N011
	call	Say
	jmp	SHORT L08E6

T_VEN4N011	LABEL	BYTE
	DB	'#VEN4\VEN4N011#This is the Republic''s sickbay. Fortunately, powe'
	DB	'r is still functioning here.',0
L08E6:
	retf

; Taking the hypo (msgs 1, 2) and the drill (msgs 3, 4).
H_08E7:
	SCRIPT	MSG_GET, 0Ah, 0, 0, H_090E
GetHypo:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 1
	push	ax
	mov	ax, 0AEh
	push	ax
	mov	ax, 0EAh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 234, 174, 1)
	add	sp, 0Ah
	retf

H_090E:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_0933
KirkAtHypo:
	jmp	SHORT L091D

N_kusemn	LABEL	BYTE
	DB	'kusemn',0
L091D:
	push	2
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 2)
	add	sp, 0Ch
	retf

H_0933:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_09C3
TookHypo:
	mov	ax, IT_HYPO
	push	ax
	mov	ax, RC_GIVEITEM
	push	ax
	SERVICE		; GiveItem(IT_HYPO)
	add	sp, 4
	mov	byte ptr [si+hypo_taken], 1
	mov	ax, 0Ah
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(10)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N015
	call	Say
	jmp	SHORT L09A2

T_VEN4N015	LABEL	BYTE
	DB	'#VEN4\VEN4N015#You pick up the empty hypodermic injector.',0
L09A2:
	mov	ax, 0
	push	ax
	mov	ax, 0C2h
	push	ax
	mov	ax, 0CDh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 205, 194, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_09C3:
	SCRIPT	MSG_GET, 0Bh, 0, 0, H_09EA
GetDrill:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 3
	push	ax
	mov	ax, 0AEh
	push	ax
	mov	ax, 0EAh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 234, 174, 3)
	add	sp, 0Ah
	retf

H_09EA:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_0A0F
KirkAtDrill:
	jmp	SHORT L09F9

N_kusemn_2	LABEL	BYTE
	DB	'kusemn',0
L09F9:
	push	4
	push	-1
	push	-1
	push	OFFSET N_kusemn_2
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 4)
	add	sp, 0Ch
	retf

H_0A0F:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_0A94
TookDrill:
	mov	ax, IT_DRILL
	push	ax
	mov	ax, RC_GIVEITEM
	push	ax
	SERVICE		; GiveItem(IT_DRILL)
	add	sp, 4
	mov	byte ptr [si+drill_taken], 1
	mov	ax, 0Bh
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(11)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N016
	call	Say
	jmp	SHORT L0A73

T_VEN4N016	LABEL	BYTE
	DB	'#VEN4\VEN4N016#You retrieve the medical drill.',0
L0A73:
	mov	ax, 0
	push	ax
	mov	ax, 0C2h
	push	ax
	mov	ax, 0CDh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 205, 194, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Leaving: the door opens as Kirk reaches it (region 0).
H_0A94:
	SCRIPT	MSG_REGION, 0, 0, 0, H_0AC6
DoorOpens:
	cmp	byte ptr cs:door_opening, 1
	jne	L0AC5
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	push	0
	push	0ABh
	push	13Fh
	push	OFFSET N_s9r1do
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s9r1do", 319, 171, 0)
	add	sp, 0Ch
L0AC5:
	retf

H_0AC6:
	SCRIPT	MSG_WALK, 9, 0, 0, H_0ACE
	jmp	SHORT WalkToDoor

H_0ACE:
	SCRIPT	MSG_WALK, 20h, 0, 0, H_0AF3
WalkToDoor:
	mov	byte ptr cs:door_opening, 1
	mov	byte ptr [si+RS_BUSY], 1
	push	0
	push	0ABh
	push	12Eh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 302, 171, 0)
	add	sp, 0Ah
	retf

; Every tick, common to the mission's rooms: the Elasi deadlines set on
; the bridge (room 2). Until the Enterprise returns: boarding unless the
; shields are up, the thirty minutes, the wait after Kirk complies (then
; a warning and the torpedoes), the chance after they lower their
; shields. When one runs out, the game is over.
H_0AF3:
	SCRIPT	MSG_TICK, ANY, ANY, ANY, H_0D17
ElasiDeadlines:
	cmp	word ptr [si+board_timer], 0
	je	L0B0D
	dec	word ptr [si+board_timer]
	jne	L0B0D
	cmp	byte ptr [si+power_to], 2
	je	L0B0D
	JMPN	L0C0D

L0B0D:
	cmp	word ptr [si+stall_timer], 0
	je	L0B21
	dec	word ptr [si+stall_timer]
	jne	L0B21
	cmp	byte ptr [si+complied], 1
	je	L0B21
	JMPN	L0C0D

L0B21:
	cmp	word ptr [si+comply_timer], 0
	je	L0B80
	dec	word ptr [si+comply_timer]
	jne	L0B80
	cmp	byte ptr [si+rescued], 1
	je	L0B80
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_098
	call	Say
	jmp	SHORT L0B7B

T_VEN2_098	LABEL	BYTE
	DB	'#VEN2\VEN2_098#What are you stalling for? Lower your shields.',0
L0B7B:
	mov	word ptr [si+torpedo_timer], 0A8Ch
L0B80:
	cmp	word ptr [si+torpedo_timer], 0
	je	L0BF9
	dec	word ptr [si+torpedo_timer]
	jne	L0BF9
	cmp	byte ptr [si+rescued], 1
	je	L0BF9
	mov	ax, 0
	mov	bx, OFFSET T_VENA_F40
	call	Say
	jmp	SHORT L0BED

T_VENA_F40	LABEL	BYTE
	DB	'#VENA\VENA_F40#The Elasi fire photon torpedoes. The Republic has'
	DB	' been destroyed.',0
L0BED:
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
L0BF9:
	cmp	word ptr [si+attack_timer], 0
	je	L0C0C
	dec	word ptr [si+attack_timer]
	jne	L0C0C
	cmp	byte ptr [si+rescued], 1
	je	L0C0C
	jmp	SHORT L0C0D

L0C0C:
	retf

L0C0D:
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

H_0D17:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_0D1F
	jmp	SHORT KillAnything

H_0D1F:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_0DB4
KillAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VENA_F34
	call	Say
	JMPN	L0DB3

T_VENA_F34	LABEL	BYTE
	DB	'#VENA\VENA_F34#Captain, it would be unwise to use your phaser co'
	DB	'nsidering the already extensive damage sustained by the Republic'
	DB	'.',0
L0DB3:
	retf

; The hypo, empty or full of oil.
H_0DB4:
	SCRIPT	MSG_LOOK, IT_HYPO, 0, 0, H_0E4A
LookAtHypo:
	cmp	byte ptr [si+hypo_oiled], 1
	je	L0E01
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N010_2
	call	Say
	jmp	SHORT L0E00

T_VEN4N010_2	LABEL	BYTE
	DB	'#VEN4\VEN4N010#This is an empty hypodermic injector.',0
L0E00:
	retf

L0E01:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N007
	call	Say
	jmp	SHORT L0E49

T_VEN6N007	LABEL	BYTE
	DB	'#VEN6\VEN6N007#The hypo is now filled with multipurpose oil.',0
L0E49:
	retf

; The communicator: before the Enterprise leaves, Uhura; while the Elasi
; jam it, Spock; otherwise Uhura, tracking the distress call.
H_0E4A:
	SCRIPT	MSG_USE, IT_COMM, OBJ_KIRK, 0, Talk
CallEnterprise:
	cmp	byte ptr [si+enterprise_away], 1
	je	L0ED2
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018
	call	Say
	jmp	SHORT L0E9B

T_MUD4_018	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L0E9B:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146
	call	Say
	jmp	SHORT L0ED1

T_BRIDU146	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L0ED1:
	retf

L0ED2:
	cmp	byte ptr [si+elasi_here], 1
	jne	L0EDB
	JMPN	L0FD8

L0EDB:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_2
	call	Say
	jmp	SHORT L0F1F

T_MUD4_018_2	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise, Kirk to Enterprise...',0
L0F1F:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_VEN2U093
	call	Say
	jmp	SHORT L0F8A

T_VEN2U093	LABEL	BYTE
	DB	'#VEN2\VEN2U093#Enterprise here. We''re still tracking the distres'
	DB	's call. Are you all right, Sir?',0
L0F8A:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_028
	call	Say
	jmp	SHORT L0FD7

T_VEN2_028	LABEL	BYTE
	DB	'#VEN2\VEN2_028#Yes, Uhura. Just wanted a status report. Kirk out'
	DB	'.',0
L0FD7:
	retf

L0FD8:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_066
	call	Say
	jmp	SHORT L104C

T_VEN2_066	LABEL	BYTE
	DB	'#VEN2\VEN2_066#They are jamming all frequencies, Captain. We wil'
	DB	'l not be able to contact the Enterprise.',0
L104C:
	retf

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
	DW	292,71, 319,67, 319,185, 274,169
	DW	21h, 4	; id, points
	DW	71,121, 112,121, 103,180, 80,180
	DW	22h, 4	; id, points
	DW	163,123, 204,123, 196,179, 173,179
	DW	23h, 4	; id, points
	DW	76,100, 110,100, 110,117, 76,117
	DW	24h, 4	; id, points
	DW	166,100, 200,100, 200,117, 166,117
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	2, 3	; id, points
	DW	293,168, 319,166, 319,177
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	274,169, 292,169, 319,178, 319,185
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's9s1',0
	DB	's9s3',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Ensign_Kije	LABEL	BYTE
	DB	'Ensign Kije',0
N_Brittany_Marata	LABEL	BYTE
	DB	'Brittany Marata',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
N_Elasi_Captain	LABEL	BYTE
	DB	'Elasi Captain',0
S_114E	LABEL	BYTE
	DB	0
T_VEN4_007	LABEL	BYTE
	DB	'#VEN4\VEN4_007#He''s dead, Jim. I can''t bring him back.',0
T_VEN4_011	LABEL	BYTE
	DB	'#VEN4\VEN4_011#She''s suffering from severe trauma and internal b'
	DB	'leeding. I''ll see what I can do.',0
T_VEN4_001	LABEL	BYTE
	DB	'#VEN4\VEN4_001#Do what you can, Bones. I need to find out what h'
	DB	'appened here.',0
T_VEN4N002	LABEL	BYTE
	DB	'#VEN4\VEN4N002#James T. Kirk, in total confusion at the moment.',0
T_VEN4N000	LABEL	BYTE
	DB	'#VEN4\VEN4N000#A very concerned Doctor Leonard McCoy.',0
T_VEN4N003	LABEL	BYTE
	DB	'#VEN4\VEN4N003#Mr. Spock, looking pensive as usual.',0
T_VEN4N001	LABEL	BYTE
	DB	'#VEN4\VEN4N001#A very unhappy looking Ensign Kije.',0
T_VEN4_005	LABEL	BYTE
	DB	'#VEN4\VEN4_005#I can''t believe it. That''s Brittany Marata. I kne'
	DB	'w her from my Academy days. We studied alien history together.',0
T_VEN4_014	LABEL	BYTE
	DB	'#VEN4\VEN4_014#At least she''s still alive, although just barely.',0
T_VEN4N007	LABEL	BYTE
	DB	'#VEN4\VEN4N007#The woman in this sickbed is alive, barely.',0
S_140D	LABEL	BYTE
	DB	'This bed contains the body of a recently deceaced crewman.',0
T_VEN4N014	LABEL	BYTE
	DB	'#VEN4\VEN4N014#Yet another crewman of the Republic whose life wa'
	DB	's unfairly abbreviated.',0
T_VEN4N006	LABEL	BYTE
	DB	'#VEN4\VEN4N006#The medical scanner is monitoring the woman''s con'
	DB	'dition.',0
T_VEN4N013	LABEL	BYTE
	DB	'#VEN4\VEN4N013#This monitor has recorded the death of a patient.',0
T_VEN4N008	LABEL	BYTE
	DB	'#VEN4\VEN4N008#This door leads back to the corridor and turbolif'
	DB	'ts.',0
T_VEN4_002	LABEL	BYTE
	DB	'#VEN4\VEN4_002#You always hope the instruments are wrong...that '
	DB	'you''ll find someone alive.',0
T_VEN4_017	LABEL	BYTE
	DB	'#VEN4\VEN4_017#I believe nothing needs to be said, Captain.',0
T_VEN4_015	LABEL	BYTE
	DB	'#VEN4\VEN4_015#Life support must have gone down during the fight'
	DB	'. Most of the people died from shock before the back-up systems '
	DB	'came on line.',0
	DB	'#VEN4\VEN4_018#An interesting hypothesis, doctor. Had Mr. Scott '
	DB	'been present, he might have been able to verify it.',0
T_VEN4_022	LABEL	BYTE
	DB	'#VEN4\VEN4_022#Captain, did I ever mention how much I hate hospi'
	DB	'tals?',0
T_VEN4_019	LABEL	BYTE
	DB	'#VEN4\VEN4_019#No... you won''t get us...',0
T_VEN4_004	LABEL	BYTE
	DB	'#VEN4\VEN4_004#Marata, what happened?',0
T_VEN4_020	LABEL	BYTE
	DB	'#VEN4\VEN4_020#They said it was the Enterprise...They had visual'
	DB	' confirmation...',0
T_VEN4_006	LABEL	BYTE
	DB	'#VEN4\VEN4_006#What about the Enterprise?',0
T_VEN4_021	LABEL	BYTE
	DB	'#VEN4\VEN4_021#You killed us, Jim. We were friends for... I trus'
	DB	'ted ...',0
T_VEN4_003	LABEL	BYTE
	DB	'#VEN4\VEN4_003#It wasn''t the Enterprise, Marata!',0
T_VEN4_016	LABEL	BYTE
	DB	'#VEN4\VEN4_016#There''s nothing more I can do.',0
T_VEN4_012	LABEL	BYTE
	DB	'#VEN4\VEN4_012#That won''t bring her back. She''s gone.',0
T_VEN4_009	LABEL	BYTE
	DB	'#VEN4\VEN4_009#She''s in bad shape, Jim. I''ve tried to stabilize '
	DB	'her, but it doesn''t look good.',0
T_VEN4_013	LABEL	BYTE
	DB	'#VEN4\VEN4_013#There''s nothing more I can do for her, Jim.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
