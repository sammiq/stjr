; VENG1.RDF - "Vengeance", the corridor to auxiliary control on the
; Republic. The door is jammed: drill the seal off its maintenance panel,
; open it, oil the debris in the gears with the hypo (filled in room 6)
; and pull it out. A molecular saw lies here.
;
; Actors: 8 the door, 9 the open panel, 0Ah the saw, 0Bh a body, 0Ch the
; panel (closed, then cleared). Objects: those, 9 the debris, 20h the
; door, 21h the panel, 22h a vent. Exit 1: the turbolift.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 1D35: the engine reads its bytes
;   as key 50 B8 03 00 and next 2E50 (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
enterprise_away	EQU	RS_VARS+0Dh	; the Enterprise has left to follow the distress call (room 0)
panel_open	EQU	RS_VARS+0Eh	; the door's maintenance panel is open
panel_unsealed	EQU	RS_VARS+0Fh	; the drill has broken the panel's seal
gears_cleared	EQU	RS_VARS+10h	; the debris is out of the door's gears
hypo_oiled	EQU	RS_VARS+11h	; the hypo holds oil (room 6)
debris_oiled	EQU	RS_VARS+12h	; the hypo's oil has loosened the debris
power_to	EQU	RS_VARS+13h	; impulse power: 1 weapons, 2 shields, 3 transporter (room 2)
rescued	EQU	RS_VARS+19h	; the Enterprise is back: the Elasi threats are over
elasi_here	EQU	RS_VARS+1Ah	; the Elasi ship has arrived and jams the communicators
complied	EQU	RS_VARS+1Ch	; Kirk has agreed to the Elasi's terms
board_timer	EQU	RS_VARS+20h	; word: until the Elasi board, unless the shields are up
stall_timer	EQU	RS_VARS+22h	; word: the thirty minutes
comply_timer	EQU	RS_VARS+24h	; word: until the Elasi lose patience after Kirk complies
torpedo_timer	EQU	RS_VARS+26h	; word: until their torpedoes
attack_timer	EQU	RS_VARS+28h	; word: after the Elasi lower their shields
saw_taken	EQU	RS_VARS+37h	; Kirk has taken the molecular saw

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	7Eh	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	60h
rdf_scale_min	LABEL	BYTE
	DW	96h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	2, 9, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	161,136, 169,154	; entrance 0, crew 0
	DW	161,136, 147,147	; entrance 0, crew 1
	DW	161,136, 184,145	; entrance 0, crew 2
	DW	161,136, 164,141	; entrance 0, crew 3
	DW	160,195, 176,162	; entrance 1, crew 0
	DW	160,195, 160,170	; entrance 1, crew 1
	DW	160,195, 205,170	; entrance 1, crew 2
	DW	160,195, 186,178	; entrance 1, crew 3
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
door_done	LABEL	BYTE	; counts the walk and the door animation; both done, go through
	DB	0
door_opening	LABEL	BYTE	; Kirk is walking to the cleared door
	DB	0

rdf_scripts:
; The room starts: the door, the body, the saw and the panel as they were left.
H_00CC:
	SCRIPT	MSG_TICK, 1, 0, 0, H_01DB
StartRoom:
	jmp	SHORT L00DD

N_VEN1LOOP	LABEL	BYTE
	DB	'VEN1LOOP',0
L00DD:
	push	OFFSET N_VEN1LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("VEN1LOOP")
	add	sp, 4
	jmp	SHORT L00F6

N_s7r1d1c	LABEL	BYTE
	DB	's7r1d1c',0
L00F6:
	push	0
	push	7Eh
	push	0A1h
	push	OFFSET N_s7r1d1c
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s7r1d1c", 161, 126, 0)
	add	sp, 0Ch
	jmp	SHORT L0115

N_s7r1c1	LABEL	BYTE
	DB	's7r1c1',0
L0115:
	push	0
	push	0A2h
	push	103h
	push	OFFSET N_s7r1c1
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r1c1", 259, 162, 0)
	add	sp, 0Ch
	cmp	byte ptr [si+saw_taken], 1
	je	L0151
	jmp	SHORT L013B

N_s7r1md	LABEL	BYTE
	DB	's7r1md',0
L013B:
	push	0
	push	9Fh
	push	3Dh
	push	OFFSET N_s7r1md
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s7r1md", 61, 159, 0)
	add	sp, 0Ch
L0151:
	jmp	SHORT L015A

N_s7r1p1	LABEL	BYTE
	DB	's7r1p1',0
L015A:
	push	0
	push	6Ah
	push	0D1h
	push	OFFSET N_s7r1p1
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s7r1p1", 209, 106, 0)
	add	sp, 0Ch
	cmp	byte ptr [si+panel_open], 1
	jne	L01A5
	jmp	SHORT L017F

N_s7r1p2	LABEL	BYTE
	DB	's7r1p2',0
L017F:
	push	0
	push	6Ah
	push	0D1h
	push	OFFSET N_s7r1p2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s7r1p2", 209, 106, 0)
	add	sp, 0Ch
	mov	ax, 0Ch
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(12)
	add	sp, 4
L01A5:
	cmp	byte ptr [si+gears_cleared], 1
	jne	L01DA
	jmp	SHORT L01B4

N_s7r1p3	LABEL	BYTE
	DB	's7r1p3',0
L01B4:
	push	0
	push	6Ah
	push	0D1h
	push	OFFSET N_s7r1p3
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s7r1p3", 209, 106, 0)
	add	sp, 0Ch
	mov	ax, 9
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(9)
	add	sp, 4
L01DA:
	retf

; Walking to the door: with the gears cleared, Kirk walks up (msg 2) and
; it opens as he reaches it (region 0, anim msg 1). Once both are done,
; on to auxiliary control (room 2).
H_01DB:
	SCRIPT	MSG_WALK, 20h, 0, 0, H_01E3
	jmp	SHORT WalkToDoor

H_01E3:
	SCRIPT	MSG_WALK, 8, 0, 0, H_024E
WalkToDoor:
	cmp	byte ptr [si+gears_cleared], 1
	jne	L021A
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 2
	push	ax
	mov	ax, 82h
	push	ax
	mov	ax, 0A0h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 160, 130, 2)
	add	sp, 0Ah
	mov	byte ptr cs:door_opening, 1
	mov	byte ptr [si+RS_FALL], 0
	retf

L021A:
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N007
	call	Say
	jmp	SHORT L024D

T_VEN1N007	LABEL	BYTE
	DB	'#VEN1\VEN1N007#The door is jammed shut.',0
L024D:
	retf

H_024E:
	SCRIPT	MSG_REGION, 0, 0, 0, H_02AB
DoorOpens:
	cmp	byte ptr cs:door_opening, 1
	jne	L02AA
	jmp	SHORT L0265

N_s7r1d1	LABEL	BYTE
	DB	's7r1d1',0
L0265:
	push	1
	push	7Eh
	push	0A1h
	push	OFFSET N_s7r1d1
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s7r1d1", 161, 126, 1)
	add	sp, 0Ch
	jmp	SHORT L0284

N_s7r1g1	LABEL	BYTE
	DB	's7r1g1',0
L0284:
	push	0
	push	79h
	push	0D8h
	push	OFFSET N_s7r1g1
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s7r1g1", 216, 121, 0)
	add	sp, 0Ch
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
L02AA:
	retf

H_02AB:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_02B3
	jmp	SHORT ThroughDoor

H_02B3:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_02D3
ThroughDoor:
	inc	byte ptr cs:door_done
	cmp	byte ptr cs:door_done, 2
	je	L02C7
	retf

L02C7:
	push	1
	push	2
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(2, 1)
	retf

; Exit 1: the turbolift.
H_02D3:
	SCRIPT	MSG_EXIT, 1, 0, 0, H_02F8
ToTurbolift:
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	push	0
	push	1
	push	RC_TURBOLIFT
	SERVICE		; Turbolift(1, 0)
	add	sp, 6
	retf

; Looking.
H_02F8:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_0362
LookAtBody:
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N014
	call	Say
	jmp	SHORT L0361

T_VEN4N014	LABEL	BYTE
	DB	'#VEN4\VEN4N014#Yet another crewman of the Republic whose life wa'
	DB	's unfairly abbreviated.',0
L0361:
	retf

H_0362:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_036A
	jmp	SHORT LookAtVent

H_036A:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_042D
LookAtVent:
	jmp	SHORT L0379

N_sscanw	LABEL	BYTE
	DB	'sscanw',0
L0379:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscanw
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscanw", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN1_011
	call	Say
	JMPN	L042C

T_VEN1_011	LABEL	BYTE
	DB	'#VEN1\VEN1_011#The vent is far too small for any one of us to fi'
	DB	't through. It is also blocked point three meters inside the duct'
	DB	'.',0
L042C:
	retf

H_042D:
	SCRIPT	MSG_LOOK, 0Ch, 0, 0, H_0435
	jmp	SHORT LookAtPanel

H_0435:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_054D
LookAtPanel:
	cmp	byte ptr [si+panel_open], 1
	je	L049F
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N022
	call	Say
	jmp	SHORT L049E

T_VEN1N022	LABEL	BYTE
	DB	'#VEN1\VEN1N022#This is the maintenance panel for the auxiliary c'
	DB	'ontrol room door.',0
L049E:
	retf

L049F:
	cmp	byte ptr [si+gears_cleared], 1
	je	L04F9
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N019
	call	Say
	jmp	SHORT L04F8

T_VEN1N019	LABEL	BYTE
	DB	'#VEN1\VEN1N019#There appears to be debris jammed in the gear mec'
	DB	'hanism.',0
L04F8:
	retf

L04F9:
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N010
	call	Say
	jmp	SHORT L054C

T_VEN1N010	LABEL	BYTE
	DB	'#VEN1\VEN1N010#The gear mechanism for the door is now fully func'
	DB	'tional.',0
L054C:
	retf

H_054D:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_0555
	jmp	SHORT LookAtDoor

H_0555:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_059C
LookAtDoor:
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N021
	call	Say
	jmp	SHORT L059B

T_VEN1N021	LABEL	BYTE
	DB	'#VEN1\VEN1N021#This door leads to auxiliary control.',0
L059B:
	retf

H_059C:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_05F8
LookAtSaw:
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N001
	call	Say
	jmp	SHORT L05F7

T_VEN1N001	LABEL	BYTE
	DB	'#VEN1\VEN1N001#A Molecular Saw. The 23rd century equivalent of a'
	DB	' hacksaw.',0
L05F7:
	retf

H_05F8:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_0649
LookAtDebris:
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N000
	call	Say
	jmp	SHORT L0648

T_VEN1N000	LABEL	BYTE
	DB	'#VEN1\VEN1N000#A knot of debris is jamming the gear mechanism.',0
L0648:
	retf

H_0649:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_06C8
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N002
	call	Say
	jmp	SHORT L06C7

T_VEN1N002	LABEL	BYTE
	DB	'#VEN1\VEN1N002#Captain Kirk hopes that he will never see the day'
	DB	' when the Enterprise is this badly battered.',0
L06C7:
	retf

H_06C8:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_071E
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N004
	call	Say
	jmp	SHORT L071D

T_VEN1N004	LABEL	BYTE
	DB	'#VEN1\VEN1N004#Leonard McCoy wishes he were back on the Enterpri'
	DB	'se.',0
L071D:
	retf

H_071E:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_07C1
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N003
	call	Say
	JMPN	L07C0

T_VEN1N003	LABEL	BYTE
	DB	'#VEN1\VEN1N003#Irritated by the emotions of the humans that are '
	DB	'accompanying him, Spock does his best to keep his mind on the pr'
	DB	'oblems at hand.',0
L07C0:
	retf

H_07C1:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_082B
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N005
	call	Say
	jmp	SHORT L082A

T_VEN1N005	LABEL	BYTE
	DB	'#VEN1\VEN1N005#Kije wishes that everyone would stop fidgeting. I'
	DB	't''s making him nervous.',0
L082A:
	retf

H_082B:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_0889
LookAtCorridor:
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N020
	call	Say
	jmp	SHORT L0888

T_VEN1N020	LABEL	BYTE
	DB	'#VEN1\VEN1N020#This corridor leads to auxiliary control. It is a'
	DB	' real mess.',0
L0888:
	retf

H_0889:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_08E4
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN1_001
	call	Say
	jmp	SHORT L08E3

T_VEN1_001	LABEL	BYTE
	DB	'#VEN1\VEN1_001#I wonder if anything will be working in Auxilary '
	DB	'Control.',0
L08E3:
	retf

H_08E4:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_09AC
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN1_013
	call	Say
	jmp	SHORT L0964

T_VEN1_013	LABEL	BYTE
	DB	'#VEN1\VEN1_013#The Starfleet Engineers did their work well Capta'
	DB	'in. A surprising amount of the ship is intact.',0
L0964:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN1_005
	call	Say
	jmp	SHORT L09AB

T_VEN1_005	LABEL	BYTE
	DB	'#VEN1\VEN1_005#Too bad you can''t say the same for the crew.',0
L09AB:
	retf

H_09AC:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0A64
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN1_004
	call	Say
	jmp	SHORT L0A1F

T_VEN1_004	LABEL	BYTE
	DB	'#VEN1\VEN1_004#I''d like to meet the people responsible for this '
	DB	'and give them a piece of my mind.',0
L0A1F:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN1_002
	call	Say
	jmp	SHORT L0A63

T_VEN1_002	LABEL	BYTE
	DB	'#VEN1\VEN1_002#You''ll get your chance, Bones. I promise.',0
L0A63:
	retf

H_0A64:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0AAF
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN1_016
	call	Say
	jmp	SHORT L0AAE

T_VEN1_016	LABEL	BYTE
	DB	'#VEN1\VEN1_016#I''m not in a talking mood right now, sir.',0
L0AAE:
	retf

; Phasers on the door and the panel.
H_0AAF:
	SCRIPT	MSG_USE, IT_PHASERK, 8, 0, H_0AB7
	jmp	SHORT PhaserDoor

H_0AB7:
	SCRIPT	MSG_USE, IT_PHASERK, 20h, 0, H_0ABF
PhaserDoor:
	jmp	SHORT PhaserDoor2

H_0ABF:
	SCRIPT	MSG_USE, IT_PHASERS, 8, 0, H_0AC7
PhaserDoor2:
	jmp	SHORT PhaserDoor3

H_0AC7:
	SCRIPT	MSG_USE, IT_PHASERS, 20h, 0, H_0B8F
PhaserDoor3:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN1_015
	call	Say
	JMPN	L0B8E

T_VEN1_015	LABEL	BYTE
	DB	'#VEN1\VEN1_015#From my lessons at the Academy, sir, we were told'
	DB	' that a standard issue Federation phaser does not have enough po'
	DB	'wer to cut through a security door such as this one.',0
L0B8E:
	retf

H_0B8F:
	SCRIPT	MSG_USE, IT_PHASERS, 0Ch, 0, H_0B97
	jmp	SHORT PhaserPanel

H_0B97:
	SCRIPT	MSG_USE, IT_PHASERS, 0Ch, 0, H_0B9F
PhaserPanel:
	jmp	SHORT PhaserPanel2

H_0B9F:
	SCRIPT	MSG_USE, IT_PHASERS, 9, 0, H_0BA7
PhaserPanel2:
	jmp	SHORT PhaserPanel3

H_0BA7:
	SCRIPT	MSG_USE, IT_PHASERK, 9, 0, H_0BAF
PhaserPanel3:
	jmp	SHORT PhaserPanel4

H_0BAF:
	SCRIPT	MSG_USE, IT_PHASERS, 21h, 0, H_0BB7
PhaserPanel4:
	jmp	SHORT PhaserPanel5

H_0BB7:
	SCRIPT	MSG_USE, IT_PHASERK, 21h, 0, H_0C3B
PhaserPanel5:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN1_008
	call	Say
	jmp	SHORT L0C3A

T_VEN1_008	LABEL	BYTE
	DB	'#VEN1\VEN1_008#That may not be wise, Captain. It could damage th'
	DB	'e entire door assembly in its weakened condition.',0
L0C3A:
	retf

; Spock's tricorder.
H_0C3B:
	SCRIPT	MSG_USE, IT_STRICOR, 0Ah, 0, H_0D0A
SpockScansSaw:
	jmp	SHORT L0C4A

N_sscanw_2	LABEL	BYTE
	DB	'sscanw',0
L0C4A:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscanw_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscanw", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN1_012
	call	Say
	JMPN	L0D09

T_VEN1_012	LABEL	BYTE
	DB	'#VEN1\VEN1_012#This is a molecular saw, Captain. It is used for '
	DB	'precision cutting. My tricorder reads that the power cells are f'
	DB	'ully charged.',0
L0D09:
	retf

H_0D0A:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_0D12
	jmp	SHORT SpockScansDoor

H_0D12:
	SCRIPT	MSG_USE, IT_STRICOR, 8, 0, H_0DE0
SpockScansDoor:
	jmp	SHORT L0D21

N_sscann	LABEL	BYTE
	DB	'sscann',0
L0D21:
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
	cmp	byte ptr [si+gears_cleared], 1
	je	L0DA2
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN1_007
	call	Say
	jmp	SHORT L0DA1

T_VEN1_007	LABEL	BYTE
	DB	'#VEN1\VEN1_007#Readings of the door indicate a jam in the gear m'
	DB	'echanism.',0
L0DA1:
	retf

L0DA2:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN1_009
	call	Say
	jmp	SHORT L0DDF

T_VEN1_009	LABEL	BYTE
	DB	'#VEN1\VEN1_009#The gear mechanism is now cleared.',0
L0DDF:
	retf

H_0DE0:
	SCRIPT	MSG_USE, IT_STRICOR, 0Ch, 0, H_0DE8
	jmp	SHORT SpockScansPanel

H_0DE8:
	SCRIPT	MSG_USE, IT_STRICOR, 9, 0, H_0DF0
SpockScansPanel:
	jmp	SHORT SpockScansPanel2

H_0DF0:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_0F7B
SpockScansPanel2:
	jmp	SHORT L0DFF

N_sscane	LABEL	BYTE
	DB	'sscane',0
L0DFF:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscane
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscane", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	cmp	byte ptr [si+panel_unsealed], 1
	jne	L0E2D
	JMPN	L0EB0

L0E2D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN1_014
	call	Say
	jmp	SHORT L0EAF

T_VEN1_014	LABEL	BYTE
	DB	'#VEN1\VEN1_014#Tricorder indicates that the panel is currently s'
	DB	'ealed by Federation standard molecular bonding cement.',0
L0EAF:
	retf

L0EB0:
	cmp	byte ptr [si+gears_cleared], 1
	je	L0F26
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN1_006
	call	Say
	jmp	SHORT L0F25

T_VEN1_006	LABEL	BYTE
	DB	'#VEN1\VEN1_006#Initial scans show that the gear mechanism is cur'
	DB	'rently jammed with metallic debris.',0
L0F25:
	retf

L0F26:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN1_010
	call	Say
	jmp	SHORT L0F7A

T_VEN1_010	LABEL	BYTE
	DB	'#VEN1\VEN1_010#The gears are moving freely and are completely op'
	DB	'erative.',0
L0F7A:
	retf

; Opening the panel (msgs 9, 0Ah): sealed until drilled (msgs 5, 6).
H_0F7B:
	SCRIPT	MSG_GET, 0Ch, 0, 0, H_0F83
	jmp	SHORT OpenPanel

H_0F83:
	SCRIPT	MSG_USE, OBJ_KIRK, 0Ch, 0, H_0FAA
OpenPanel:
	mov	ax, 9
	push	ax
	mov	ax, 84h
	push	ax
	mov	ax, 0D3h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 211, 132, 9)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

H_0FAA:
	SCRIPT	MSG_WALK_DONE, 9, 0, 0, H_0FCF
KirkAtPanel:
	jmp	SHORT L0FB9

N_kusemn	LABEL	BYTE
	DB	'kusemn',0
L0FB9:
	push	0Ah
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 10)
	add	sp, 0Ch
	retf

H_0FCF:
	SCRIPT	MSG_ANIM_DONE, 0Ah, 0, 0, H_1127
TriedPanel:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+panel_unsealed], 1
	je	L1052
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N016
	call	Say
	jmp	SHORT L1035

T_VEN1N016	LABEL	BYTE
	DB	'#VEN1\VEN1N016#The panel has been fastened shut with some kind o'
	DB	'f sealant.',0
L1035:
	mov	ax, 0
	push	ax
	mov	ax, 98h
	push	ax
	mov	ax, 0C9h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 201, 152, 0)
	add	sp, 0Ah
	retf

L1052:
	cmp	byte ptr [si+panel_open], 1
	jne	L105B
	JMPN	L10DD

L105B:
	mov	byte ptr [si+panel_open], 1
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N017
	call	Say
	jmp	SHORT L1091

T_VEN1N017	LABEL	BYTE
	DB	'#VEN1\VEN1N017#The panel opens easily.',0
L1091:
	jmp	SHORT L109A

N_s7r1p2_2	LABEL	BYTE
	DB	's7r1p2',0
L109A:
	push	0
	push	6Ah
	push	0D1h
	push	OFFSET N_s7r1p2_2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s7r1p2", 209, 106, 0)
	add	sp, 0Ch
	mov	ax, 0Ch
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(12)
	add	sp, 4
	mov	ax, 0
	push	ax
	mov	ax, 98h
	push	ax
	mov	ax, 0C9h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 201, 152, 0)
	add	sp, 0Ah
	retf

L10DD:
	mov	ax, 0
	mov	bx, OFFSET T_VEN1_F33
	call	Say
	jmp	SHORT L110A

T_VEN1_F33	LABEL	BYTE
	DB	'#VEN1\VEN1_F33#The panel is open.',0
L110A:
	mov	ax, 0
	push	ax
	mov	ax, 98h
	push	ax
	mov	ax, 0C9h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 201, 152, 0)
	add	sp, 0Ah
	retf

; The saw and the drill where they do not work.
H_1127:
	SCRIPT	MSG_USE, IT_LMD, 21h, 0, H_117B
SawOnPanel:
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N013
	call	Say
	jmp	SHORT L117A

T_VEN1N013	LABEL	BYTE
	DB	'#VEN1\VEN1N013#The molecular saw is much too large for the panel'
	DB	'.',0
L117A:
	retf

H_117B:
	SCRIPT	MSG_USE, IT_LMD, 8, 0, H_1183
	jmp	SHORT SawOnDoor

H_1183:
	SCRIPT	MSG_USE, IT_LMD, 20h, 0, H_11DA
SawOnDoor:
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N014
	call	Say
	jmp	SHORT L11D9

T_VEN1N014	LABEL	BYTE
	DB	'#VEN1\VEN1N014#The molecular saw will not penetrate a security d'
	DB	'oor.',0
L11D9:
	retf

H_11DA:
	SCRIPT	MSG_USE, IT_DRILL, 9, 0, H_1237
DrillOnDebris:
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N009
	call	Say
	jmp	SHORT L1236

T_VEN1N009	LABEL	BYTE
	DB	'#VEN1\VEN1N009#The drill is not powerful enough to cut through t'
	DB	'he debris.',0
L1236:
	retf

H_1237:
	SCRIPT	MSG_USE, IT_LMD, 9, 0, H_1289
SawOnDebris:
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N018
	call	Say
	jmp	SHORT L1288

T_VEN1N018	LABEL	BYTE
	DB	'#VEN1\VEN1N018#The saw is too bulky to reach the jammed debris.',0
L1288:
	retf

H_1289:
	SCRIPT	MSG_USE, IT_DRILL, 0Ch, 0, H_12B0
DrillOnPanel:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 5
	push	ax
	mov	ax, 84h
	push	ax
	mov	ax, 0D3h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 211, 132, 5)
	add	sp, 0Ah
	retf

H_12B0:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_12EF
KirkAtPanel2:
	jmp	SHORT L12BF

N_kusemn_2	LABEL	BYTE
	DB	'kusemn',0
L12BF:
	push	6
	push	-1
	push	-1
	push	OFFSET N_kusemn_2
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 6)
	add	sp, 0Ch
	jmp	SHORT L12DF

N_MADR7E2A	LABEL	BYTE
	DB	'MADR7E2A',0
L12DF:
	push	OFFSET N_MADR7E2A
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MADR7E2A")
	add	sp, 4
	retf

H_12EF:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_1371
DrilledPanel:
	mov	ax, 0
	push	ax
	mov	ax, 98h
	push	ax
	mov	ax, 0C9h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 201, 152, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+panel_unsealed], 1
	je	L1370
	mov	byte ptr [si+panel_unsealed], 1
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N008
	call	Say
	jmp	SHORT L1370

T_VEN1N008	LABEL	BYTE
	DB	'#VEN1\VEN1N008#The drill easily breaks through the seal of the p'
	DB	'anel.',0
L1370:
	retf

; Oiling the debris with the hypo (msgs 7, 8).
H_1371:
	SCRIPT	MSG_USE, IT_HYPO, 9, 0, H_1398
HypoOnDebris:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 7
	push	ax
	mov	ax, 84h
	push	ax
	mov	ax, 0D3h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 211, 132, 7)
	add	sp, 0Ah
	retf

H_1398:
	SCRIPT	MSG_WALK_DONE, 7, 0, 0, H_13BD
KirkAtDebris:
	jmp	SHORT L13A7

N_kusemn_3	LABEL	BYTE
	DB	'kusemn',0
L13A7:
	push	8
	push	-1
	push	-1
	push	OFFSET N_kusemn_3
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 8)
	add	sp, 0Ch
	retf

H_13BD:
	SCRIPT	MSG_ANIM_DONE, 8, 0, 0, H_1461
OiledDebris:
	mov	ax, 0
	push	ax
	mov	ax, 98h
	push	ax
	mov	ax, 0C9h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 201, 152, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+hypo_oiled], 1
	je	L1417
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N012
	call	Say
	jmp	SHORT L1416

T_VEN1N012	LABEL	BYTE
	DB	'#VEN1\VEN1N012#The Hypo is empty.',0
L1416:
	retf

L1417:
	mov	byte ptr [si+debris_oiled], 1
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N015
	call	Say
	jmp	SHORT L1460

T_VEN1N015	LABEL	BYTE
	DB	'#VEN1\VEN1N015#The oil seeps into and loosens the debris.',0
L1460:
	retf

; Taking the saw (msgs 3, 4).
H_1461:
	SCRIPT	MSG_GET, 0Ah, 0, 0, H_1488
GetSaw:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 3
	push	ax
	mov	ax, 0A4h
	push	ax
	mov	ax, 32h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 50, 164, 3)
	add	sp, 0Ah
	retf

H_1488:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_14AD
KirkAtSaw:
	jmp	SHORT L1497

N_kuseln	LABEL	BYTE
	DB	'kuseln',0
L1497:
	push	4
	push	-1
	push	-1
	push	OFFSET N_kuseln
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseln", -1, -1, 4)
	add	sp, 0Ch
	retf

H_14AD:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_1516
TookSaw:
	mov	ax, 0Ah
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(10)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N023
	call	Say
	jmp	SHORT L14FD

T_VEN1N023	LABEL	BYTE
	DB	'#VEN1\VEN1N023#You retrieve the molecular saw.',0
L14FD:
	mov	ax, IT_LMD
	push	ax
	mov	ax, RC_GIVEITEM
	push	ax
	SERVICE		; GiveItem(IT_LMD)
	add	sp, 4
	mov	byte ptr [si+saw_taken], 1
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Pulling out the debris, once oiled (msgs 0Bh, 0Ch).
H_1516:
	SCRIPT	MSG_GET, 9, 0, 0, H_153D
GetDebris:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0Bh
	push	ax
	mov	ax, 84h
	push	ax
	mov	ax, 0D3h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 211, 132, 11)
	add	sp, 0Ah
	retf

H_153D:
	SCRIPT	MSG_WALK_DONE, 0Bh, 0, 0, H_1562
KirkAtDebris2:
	jmp	SHORT L154C

N_kusemn_4	LABEL	BYTE
	DB	'kusemn',0
L154C:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_kusemn_4
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 12)
	add	sp, 0Ch
	retf

H_1562:
	SCRIPT	MSG_ANIM_DONE, 0Ch, 0, 0, H_1646
PulledDebris:
	mov	ax, 0
	push	ax
	mov	ax, 98h
	push	ax
	mov	ax, 0C9h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 201, 152, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+debris_oiled], 1
	je	L15CC
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N006
	call	Say
	jmp	SHORT L15CB

T_VEN1N006	LABEL	BYTE
	DB	'#VEN1\VEN1N006#The debris is jammed in too tight.',0
L15CB:
	retf

L15CC:
	mov	ax, 9
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(9)
	add	sp, 4
	jmp	SHORT L15E5

N_s7r1p3_2	LABEL	BYTE
	DB	's7r1p3',0
L15E5:
	push	0
	push	6Ah
	push	0D1h
	push	OFFSET N_s7r1p3_2
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s7r1p3", 209, 106, 0)
	add	sp, 0Ch
	mov	ax, 0
	mov	bx, OFFSET T_VEN1N011
	call	Say
	jmp	SHORT L1641

T_VEN1N011	LABEL	BYTE
	DB	'#VEN1\VEN1N011#The gears are completely cleared of debris.',0
L1641:
	mov	byte ptr [si+gears_cleared], 1
	retf

; Every tick, common to the mission's rooms: the Elasi deadlines set on
; the bridge (room 2). Until the Enterprise returns: boarding unless the
; shields are up, the thirty minutes, the wait after Kirk complies (then
; a warning and the torpedoes), the chance after they lower their
; shields. When one runs out, the game is over.
H_1646:
	SCRIPT	MSG_TICK, ANY, ANY, ANY, H_186A
ElasiDeadlines:
	cmp	word ptr [si+board_timer], 0
	je	L1660
	dec	word ptr [si+board_timer]
	jne	L1660
	cmp	byte ptr [si+power_to], 2
	je	L1660
	JMPN	L1760

L1660:
	cmp	word ptr [si+stall_timer], 0
	je	L1674
	dec	word ptr [si+stall_timer]
	jne	L1674
	cmp	byte ptr [si+complied], 1
	je	L1674
	JMPN	L1760

L1674:
	cmp	word ptr [si+comply_timer], 0
	je	L16D3
	dec	word ptr [si+comply_timer]
	jne	L16D3
	cmp	byte ptr [si+rescued], 1
	je	L16D3
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_098
	call	Say
	jmp	SHORT L16CE

T_VEN2_098	LABEL	BYTE
	DB	'#VEN2\VEN2_098#What are you stalling for? Lower your shields.',0
L16CE:
	mov	word ptr [si+torpedo_timer], 0A8Ch
L16D3:
	cmp	word ptr [si+torpedo_timer], 0
	je	L174C
	dec	word ptr [si+torpedo_timer]
	jne	L174C
	cmp	byte ptr [si+rescued], 1
	je	L174C
	mov	ax, 0
	mov	bx, OFFSET T_VENA_F40
	call	Say
	jmp	SHORT L1740

T_VENA_F40	LABEL	BYTE
	DB	'#VENA\VENA_F40#The Elasi fire photon torpedoes. The Republic has'
	DB	' been destroyed.',0
L1740:
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
L174C:
	cmp	word ptr [si+attack_timer], 0
	je	L175F
	dec	word ptr [si+attack_timer]
	jne	L175F
	cmp	byte ptr [si+rescued], 1
	je	L175F
	jmp	SHORT L1760

L175F:
	retf

L1760:
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

H_186A:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_1872
	jmp	SHORT KillAnything

H_1872:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_1907
KillAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VENA_F34
	call	Say
	JMPN	L1906

T_VENA_F34	LABEL	BYTE
	DB	'#VENA\VENA_F34#Captain, it would be unwise to use your phaser co'
	DB	'nsidering the already extensive damage sustained by the Republic'
	DB	'.',0
L1906:
	retf

; The hypo, empty or full of oil.
H_1907:
	SCRIPT	MSG_LOOK, IT_HYPO, 0, 0, H_199D
LookAtHypo:
	cmp	byte ptr [si+hypo_oiled], 1
	je	L1954
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N010
	call	Say
	jmp	SHORT L1953

T_VEN4N010	LABEL	BYTE
	DB	'#VEN4\VEN4N010#This is an empty hypodermic injector.',0
L1953:
	retf

L1954:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N007
	call	Say
	jmp	SHORT L199C

T_VEN6N007	LABEL	BYTE
	DB	'#VEN6\VEN6N007#The hypo is now filled with multipurpose oil.',0
L199C:
	retf

; The communicator: before the Enterprise leaves, Uhura; while the Elasi
; jam it, Spock; otherwise Uhura, tracking the distress call.
H_199D:
	SCRIPT	MSG_USE, IT_COMM, OBJ_KIRK, 0, H_1BA2
CallEnterprise:
	cmp	byte ptr [si+enterprise_away], 1
	je	L1A25
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018
	call	Say
	jmp	SHORT L19EE

T_MUD4_018	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L19EE:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146
	call	Say
	jmp	SHORT L1A24

T_BRIDU146	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L1A24:
	retf

L1A25:
	cmp	byte ptr [si+elasi_here], 1
	jne	L1A2E
	JMPN	L1B2B

L1A2E:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_2
	call	Say
	jmp	SHORT L1A72

T_MUD4_018_2	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise, Kirk to Enterprise...',0
L1A72:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_VEN2U093
	call	Say
	jmp	SHORT L1ADD

T_VEN2U093	LABEL	BYTE
	DB	'#VEN2\VEN2U093#Enterprise here. We''re still tracking the distres'
	DB	's call. Are you all right, Sir?',0
L1ADD:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_028
	call	Say
	jmp	SHORT L1B2A

T_VEN2_028	LABEL	BYTE
	DB	'#VEN2\VEN2_028#Yes, Uhura. Just wanted a status report. Kirk out'
	DB	'.',0
L1B2A:
	retf

L1B2B:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_066
	call	Say
	jmp	SHORT L1B9F

T_VEN2_066	LABEL	BYTE
	DB	'#VEN2\VEN2_066#They are jamming all frequencies, Captain. We wil'
	DB	'l not be able to contact the Enterprise.',0
L1B9F:
	retf

mccoy_line	LABEL	BYTE	; which of McCoy's lines
	DB	0, 0

; McCoy and the body.
H_1BA2:
	SCRIPT	MSG_USE, IT_MEDKIT, 0Bh, 0, H_1BAA
	jmp	SHORT MTricorderOnBody

H_1BAA:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Bh, 0, H_1BB2
MTricorderOnBody:
	jmp	SHORT McCoyOnBody

H_1BB2:
	SCRIPT	MSG_USE, OBJ_MCCOY, 0Bh, 0, Talk
McCoyOnBody:
	push	5
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 5)
	add	sp, 6
	mov	word ptr cs:mccoy_line, ax
	cmp	word ptr cs:mccoy_line, 0
	jne	L1BFD
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_019
	call	Say
	jmp	SHORT L1BFC

T_DEM3_019	LABEL	BYTE
	DB	'#DEM3\DEM3_019#He''s dead, jim.',0
L1BFC:
	retf

L1BFD:
	cmp	word ptr cs:mccoy_line, 1
	jne	L1C45
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN4_016
	call	Say
	jmp	SHORT L1C44

T_VEN4_016	LABEL	BYTE
	DB	'#VEN4\VEN4_016#Jim...there''s nothing more I can do.',0
L1C44:
	retf

L1C45:
	cmp	word ptr cs:mccoy_line, 2
	jne	L1C7E
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_G_014
	call	Say
	jmp	SHORT L1C7D

T_G_014	LABEL	BYTE
	DB	'#GENE\G_014#This person''s dead, Jim.',0
L1C7D:
	retf

L1C7E:
	cmp	word ptr cs:mccoy_line, 3
	jne	L1CB7
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_G_014_2
	call	Say
	jmp	SHORT L1CB6

T_G_014_2	LABEL	BYTE
	DB	'#GENE\G_014#This person''s dead, Jim.',0
L1CB6:
	retf

L1CB7:
	cmp	word ptr cs:mccoy_line, 4
	jne	L1CFA
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_016
	call	Say
	jmp	SHORT L1CF9

T_VEN0_016	LABEL	BYTE
	DB	'#VEN0\VEN0_016#They''re dead, Jim. All of them.',0
L1CF9:
	retf

L1CFA:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_016_2
	call	Say
	jmp	SHORT L1D34

T_VEN0_016_2	LABEL	BYTE
	DB	'#VEN0\VEN0_016#They''re dead, Jim. All of them.',0
L1D34:
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
	DW	130,61, 192,61, 192,127, 130,127
	DW	21h, 4	; id, points
	DW	202,84, 217,84, 217,100, 202,100
	DW	22h, 4	; id, points
	DW	70,102, 97,102, 97,116, 70,116
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	1, 4	; id, points
	DW	0,183, 319,183, 319,199, 0,199
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	125,128, 196,128, 196,134, 129,134
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's7r1',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Ensign_Kije	LABEL	BYTE
	DB	'Ensign Kije',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
N_Elasi_Captain	LABEL	BYTE
	DB	'Elasi Captain',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
