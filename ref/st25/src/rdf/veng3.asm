; VENG3.RDF - "Vengeance", a corridor of the Republic between the two
; turbolifts and sickbay (room 4). Debris from the ceiling blocks
; turbolift 2: wedge in the beam from the bridge, then phaser it clear. A
; power cable lies here.
;
; Actors: 8 the turbolift 2 door, 9 the sickbay door, 0Ah (10) the debris,
; 0Bh (11) the cable, 0Ch (12) a body, 0Dh (13) the beam. Objects: those,
; 20h/21h the doors. Exits 0/1: the turbolifts.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 1A6B: the engine reads its bytes
;   as key 50 B8 03 00 and next 2E50 (beyond rdf_scripts_end, so the search
;   stops).
; - The jump at 0CB7 goes to the script header at 0CF4.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
power_on	EQU	RS_VARS+0Bh	; impulse power is back (room 6)
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
beam_placed	EQU	RS_VARS+2Ah	; the beam from the bridge holds up the ceiling
debris_cleared	EQU	RS_VARS+2Bh	; the debris before turbolift 2 is blasted clear
spock_on_lift	EQU	RS_VARS+2Ch	; Spock has stressed the need for turbolift 2
saw_marata	EQU	RS_VARS+2Dh	; McCoy has treated Marata (room 4): Kirk turns to the power
cable_taken	EQU	RS_VARS+36h	; Kirk has taken the power cable

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	9Fh	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	46h
rdf_scale_min	LABEL	BYTE
	DW	1Eh	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	10Eh
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	9, 9, -1, 4	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	166,100, 164,107	; entrance 0, crew 0
	DW	166,100, 154,102	; entrance 0, crew 1
	DW	166,100, 177,102	; entrance 0, crew 2
	DW	166,100, 166,98	; entrance 0, crew 3
	DW	107,198, 116,176	; entrance 1, crew 0
	DW	107,198, 93,184	; entrance 1, crew 1
	DW	107,198, 127,188	; entrance 1, crew 2
	DW	107,198, 111,194	; entrance 1, crew 3
	DW	0,0, 0,0	; entrance 2, crew 0
	DW	0,0, 0,0	; entrance 2, crew 1
	DW	0,0, 0,0	; entrance 2, crew 2
	DW	0,0, 0,0	; entrance 2, crew 3
	DW	92,133, 120,134	; entrance 3, crew 0
	DW	92,133, 103,141	; entrance 3, crew 1
	DW	92,133, 114,127	; entrance 3, crew 2
	DW	92,133, 94,132	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	176,162, 160,170, 205,170, 186,178	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0
	DB	's7r3d1',0
	DB	's7r3ph',0

rdf_scripts:
; The room starts: the beam, the debris (and its walk map), the cable.
H_00D8:
	SCRIPT	MSG_TICK, 1, 0, 0, H_01D3
StartRoom:
	jmp	SHORT L00E9

N_VEN3LOOP	LABEL	BYTE
	DB	'VEN3LOOP',0
L00E9:
	push	OFFSET N_VEN3LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("VEN3LOOP")
	add	sp, 4
	cmp	byte ptr [si+beam_placed], 1
	jne	L011D
	jmp	SHORT L0107

N_s7r3bm	LABEL	BYTE
	DB	's7r3bm',0
L0107:
	push	0
	push	61h
	push	8Ch
	push	OFFSET N_s7r3bm
	push	0Dh
	push	RC_ANIM2
	SERVICE		; Anim(13, "s7r3bm", 140, 97, 0)
	add	sp, 0Ch
L011D:
	jmp	SHORT L0125

N_veng3	LABEL	BYTE
	DB	'veng3',0
L0125:
	push	OFFSET N_veng3
	push	RC_LOADMAP
	SERVICE		; LoadMap("veng3")
	add	sp, 4
	cmp	byte ptr [si+debris_cleared], 1
	je	L016D
	jmp	SHORT L0141

N_s7r3d2	LABEL	BYTE
	DB	's7r3d2',0
L0141:
	push	0
	push	68h
	push	0A5h
	push	OFFSET N_s7r3d2
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s7r3d2", 165, 104, 0)
	add	sp, 0Ch
	jmp	SHORT L0160

N_veng3b	LABEL	BYTE
	DB	'veng3b',0
L0160:
	push	OFFSET N_veng3b
	push	RC_LOADMAP
	SERVICE		; LoadMap("veng3b")
	add	sp, 4
L016D:
	jmp	SHORT L0176

N_s7r3c1	LABEL	BYTE
	DB	's7r3c1',0
L0176:
	push	0
	push	99h
	push	0C5h
	push	OFFSET N_s7r3c1
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s7r3c1", 197, 153, 0)
	add	sp, 0Ch
	cmp	byte ptr [si+cable_taken], 1
	je	L01B3
	jmp	SHORT L019C

N_s7r3ca	LABEL	BYTE
	DB	's7r3ca',0
L019C:
	push	0
	push	84h
	push	0B7h
	push	OFFSET N_s7r3ca
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r3ca", 183, 132, 0)
	add	sp, 0Ch
L01B3:
	jmp	SHORT L01BC

N_s7r3dc	LABEL	BYTE
	DB	's7r3dc',0
L01BC:
	push	0
	push	80h
	push	5Bh
	push	OFFSET N_s7r3dc
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s7r3dc", 91, 128, 0)
	add	sp, 0Ch
	retf

; Tick 15, back from sickbay with no power yet: Kirk turns to restoring
; it.
H_01D3:
	SCRIPT	MSG_TICK, 0Fh, 0, 0, H_023C
NeedPower:
	cmp	byte ptr [si+saw_marata], 1
	jne	L023B
	cmp	byte ptr [si+power_on], 1
	je	L023B
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN0_010
	call	Say
	jmp	SHORT L0237

T_VEN0_010	LABEL	BYTE
	DB	'#VEN0\VEN0_010#Well, Gentlemen. Let''s see if we can reestablish '
	DB	'power.',0
L0237:
	mov	byte ptr [si+saw_marata], 0
L023B:
	retf

; Exits 0 and 1: the turbolifts.
H_023C:
	SCRIPT	MSG_EXIT, 0, 0, 0, H_0261
ToTurbolift2:
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	push	1
	push	3
	push	RC_TURBOLIFT
	SERVICE		; Turbolift(3, 1)
	add	sp, 6
	retf

H_0261:
	SCRIPT	MSG_EXIT, 1, 0, 0, H_0286
ToTurbolift1:
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	push	0
	push	3
	push	RC_TURBOLIFT
	SERVICE		; Turbolift(3, 0)
	add	sp, 6
	retf

; Walking to turbolift 2, once cleared (msg 2, anim msg 1), and to sickbay
; (msg 9, anim msg 0Ah).
H_0286:
	SCRIPT	MSG_WALK, 0Ah, 0, 0, H_028E
	jmp	SHORT WalkToTurbolift

H_028E:
	SCRIPT	MSG_WALK, 20h, 0, 0, H_02FE
WalkToTurbolift:
	cmp	byte ptr [si+debris_cleared], 1
	jne	L02B7
	mov	ax, 2
	push	ax
	mov	ax, 6Eh
	push	ax
	mov	ax, 0A6h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 166, 110, 2)
	add	sp, 0Ah
	retf

L02B7:
	mov	ax, 0
	mov	bx, OFFSET T_VEN3N006
	call	Say
	jmp	SHORT L02FD

T_VEN3N006	LABEL	BYTE
	DB	'#VEN3\VEN3N006#The debris is blocking the Turbolift doors.',0
L02FD:
	retf

H_02FE:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_0338
AtTurbolift:
	mov	byte ptr [si+RS_BUSY], 1
	jmp	SHORT L0311

N_s7r3db	LABEL	BYTE
	DB	's7r3db',0
L0311:
	push	1
	push	60h
	push	0A6h
	push	OFFSET N_s7r3db
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s7r3db", 166, 96, 1)
	add	sp, 0Ch
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	retf

H_0338:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_035B
IntoTurbolift:
	mov	ax, 0
	push	ax
	mov	ax, 61h
	push	ax
	mov	ax, 0A6h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 166, 97, 0)
	add	sp, 0Ah
	retf

H_035B:
	SCRIPT	MSG_WALK, 9, 0, 0, H_0363
	jmp	SHORT WalkToSickbay

H_0363:
	SCRIPT	MSG_WALK, 21h, 0, 0, H_0386
WalkToSickbay:
	mov	ax, 9
	push	ax
	mov	ax, 83h
	push	ax
	mov	ax, 68h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 104, 131, 9)
	add	sp, 0Ah
	retf

H_0386:
	SCRIPT	MSG_WALK_DONE, 9, 0, 0, H_03C0
AtSickbay:
	mov	byte ptr [si+RS_BUSY], 1
	jmp	SHORT L0399

N_s7r3da	LABEL	BYTE
	DB	's7r3da',0
L0399:
	push	0Ah
	push	80h
	push	5Bh
	push	OFFSET N_s7r3da
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s7r3da", 91, 128, 10)
	add	sp, 0Ch
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	retf

H_03C0:
	SCRIPT	MSG_ANIM_DONE, 0Ah, 0, 0, H_03E3
IntoSickbay:
	mov	ax, 0
	push	ax
	mov	ax, 83h
	push	ax
	mov	ax, 5Eh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 94, 131, 0)
	add	sp, 0Ah
	retf

; Looking.
H_03E3:
	SCRIPT	MSG_USE, IT_STRICOR, 0Dh, 0, H_03EB
	jmp	SHORT LookAtBeam

H_03EB:
	SCRIPT	MSG_LOOK, 0Dh, 0, 0, H_0445
LookAtBeam:
	mov	ax, 0
	mov	bx, OFFSET T_VEN3N007
	call	Say
	jmp	SHORT L0444

T_VEN3N007	LABEL	BYTE
	DB	'#VEN3\VEN3N007#The support beam appears to have stabilized the c'
	DB	'eiling.',0
L0444:
	retf

H_0445:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_0541
LookAtDebris:
	cmp	byte ptr [si+debris_cleared], 1
	jne	L0454
	JMPN	L04ED

L0454:
	mov	ax, 0
	mov	bx, OFFSET T_VEN3N009
	call	Say
	JMPN	L04EC

T_VEN3N009	LABEL	BYTE
	DB	'#VEN3\VEN3N009#There is a twisted mess of wire and metal falling'
	DB	' from the gaping hole in the ceiling. It is blocking access to t'
	DB	'urbolift 2.',0
L04EC:
	retf

L04ED:
	mov	ax, 0
	mov	bx, OFFSET T_VEN3N007_2
	call	Say
	jmp	SHORT L0540

T_VEN3N007_2	LABEL	BYTE
	DB	'#VEN3\VEN3N007#The support beam appears to have stabilized the c'
	DB	'eiling.',0
L0540:
	retf

H_0541:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_067D
LookAtTurbolift:
	mov	ax, 0
	mov	bx, OFFSET T_VEN3N012
	call	Say
	jmp	SHORT L0581

T_VEN3N012	LABEL	BYTE
	DB	'#VEN3\VEN3N012#This door leads to TurboLift 2.',0
L0581:
	cmp	byte ptr [si+spock_on_lift], 1
	jne	L058A
	JMPN	L067C

L058A:
	mov	byte ptr [si+spock_on_lift], 1
	cmp	byte ptr [si+debris_cleared], 1
	jne	L0597
	JMPN	L067C

L0597:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN3_013
	call	Say
	JMPN	L062A

T_VEN3_013	LABEL	BYTE
	DB	'#VEN3\VEN3_013#Captain, it is critical that we gain access to th'
	DB	'is turbolift. It is our only means of exploring the rest of this'
	DB	' ship.',0
L062A:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN3_006
	call	Say
	jmp	SHORT L067C

T_VEN3_006	LABEL	BYTE
	DB	'#VEN3\VEN3_006#I thought you were a science officer, not a tour '
	DB	'guide.',0
L067C:
	retf

H_067D:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_0685
	jmp	SHORT LookAtSickbay

H_0685:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_06C2
LookAtSickbay:
	mov	ax, 0
	mov	bx, OFFSET T_VEN3N011
	call	Say
	jmp	SHORT L06C1

T_VEN3N011	LABEL	BYTE
	DB	'#VEN3\VEN3N011#This door leads to Sickbay.',0
L06C1:
	retf

H_06C2:
	SCRIPT	MSG_USE, IT_STRICOR, 0Bh, 0, H_06CA
	jmp	SHORT LookAtCable

H_06CA:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_0721
LookAtCable:
	mov	ax, 0
	mov	bx, OFFSET T_VEN3N013
	call	Say
	jmp	SHORT L0720

T_VEN3N013	LABEL	BYTE
	DB	'#VEN3\VEN3N013#This is a length of heavy duty insulated power ca'
	DB	'ble.',0
L0720:
	retf

H_0721:
	SCRIPT	MSG_LOOK, 0Ch, 0, 0, H_0791
LookAtBody:
	mov	ax, 0
	mov	bx, OFFSET T_VEN3N005
	call	Say
	jmp	SHORT L0790

T_VEN3N005	LABEL	BYTE
	DB	'#VEN3\VEN3N005#The crewman''s death was pointless. Just like too '
	DB	'many deaths in human history.',0
L0790:
	retf

H_0791:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_07E7
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_VEN3N001
	call	Say
	jmp	SHORT L07E6

T_VEN3N001	LABEL	BYTE
	DB	'#VEN3\VEN3N001#Kirk is increasingly distressed by what he has se'
	DB	'en.',0
L07E6:
	retf

H_07E7:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_085C
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_VEN3N002
	call	Say
	jmp	SHORT L085B

T_VEN3N002	LABEL	BYTE
	DB	'#VEN3\VEN3N002#McCoy examines his tricorder, knowing that his ho'
	DB	'pes are not going to be fulfilled.',0
L085B:
	retf

H_085C:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_08C6
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_VEN3N004
	call	Say
	jmp	SHORT L08C5

T_VEN3N004	LABEL	BYTE
	DB	'#VEN3\VEN3N004#Spock says nothing, but this tragedy stirs someth'
	DB	'ing in his Vulcan soul.',0
L08C5:
	retf

H_08C6:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_091A
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_VEN3N000
	call	Say
	jmp	SHORT L0919

T_VEN3N000	LABEL	BYTE
	DB	'#VEN3\VEN3N000#Kije struggles with emotions he never knew he had'
	DB	'.',0
L0919:
	retf

H_091A:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_09A1
LookAtCorridor:
	mov	ax, 0
	mov	bx, OFFSET T_VEN3N003
	call	Say
	jmp	SHORT L09A0

T_VEN3N003	LABEL	BYTE
	DB	'#VEN3\VEN3N003#One of the many battered corridors of the U.S.S. '
	DB	'Republic. It has seen better days. Much better days.',0
L09A0:
	retf

; Phasers on the debris (msgs 4, 5, anims 3, 6): without the beam to hold
; the ceiling it falls back; with it, the way is clear.
H_09A1:
	SCRIPT	MSG_USE, IT_PHASERS, 0Ah, 0, H_09F5
StunDebris:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN3_002
	call	Say
	jmp	SHORT L09F4

T_VEN3_002	LABEL	BYTE
	DB	'#VEN3\VEN3_002#Captain, using the stun setting is most illogical'
	DB	'.',0
L09F4:
	retf

H_09F5:
	SCRIPT	MSG_USE, IT_PHASERK, 0Ah, 0, H_0A22
PhaserDebris:
	cmp	byte ptr [si+debris_cleared], 1
	je	L0A21
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 4
	push	ax
	mov	ax, 0A8h
	push	ax
	mov	ax, 96h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 150, 168, 4)
	add	sp, 0Ah
L0A21:
	retf

H_0A22:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_0A47
KirkAtDebris:
	jmp	SHORT L0A31

N_kfiren	LABEL	BYTE
	DB	'kfiren',0
L0A31:
	push	5
	push	-1
	push	-1
	push	OFFSET N_kfiren
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kfiren", -1, -1, 5)
	add	sp, 0Ch
	retf

H_0A47:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_0A7E
Fired:
	jmp	SHORT L0A56

N_s7r3ph	LABEL	BYTE
	DB	's7r3ph',0
L0A56:
	push	3
	push	83h
	push	9Ch
	push	OFFSET N_s7r3ph
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s7r3ph", 156, 131, 3)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	retf

H_0A7E:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_0AD5
DebrisHit:
	cmp	byte ptr [si+beam_placed], 1
	jne	L0A8D
	JMPN	L0BA0

L0A8D:
	jmp	SHORT L0A96

N_MUR1E4	LABEL	BYTE
	DB	'MUR1E4',0
L0A96:
	push	OFFSET N_MUR1E4
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR1E4")
	add	sp, 4
	jmp	SHORT L0AAE

N_s7r3df	LABEL	BYTE
	DB	's7r3df',0
L0AAE:
	push	6
	push	60h
	push	0A6h
	push	OFFSET N_s7r3df
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s7r3df", 166, 96, 6)
	add	sp, 0Ch
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	retf

H_0AD5:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_0C27
DebrisFell:
	jmp	SHORT L0AE4

N_s7r3d2_2	LABEL	BYTE
	DB	's7r3d2',0
L0AE4:
	push	0
	push	68h
	push	0A5h
	push	OFFSET N_s7r3d2_2
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s7r3d2", 165, 104, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN3_014
	call	Say
	JMPN	L0B9F

T_VEN3_014	LABEL	BYTE
	DB	'#VEN3\VEN3_014#Captain, the support beam for the ceiling is dama'
	DB	'ged here. There will be no way to safely clear out the debris wi'
	DB	'thout a replacement.',0
L0B9F:
	retf

L0BA0:
	mov	byte ptr [si+RS_BUSY], 0
	jmp	SHORT L0BAC

N_veng3_2	LABEL	BYTE
	DB	'veng3',0
L0BAC:
	push	OFFSET N_veng3_2
	push	RC_LOADMAP
	SERVICE		; LoadMap("veng3")
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN3_015
	call	Say
	jmp	SHORT L0C22

T_VEN3_015	LABEL	BYTE
	DB	'#VEN3\VEN3_015#The ceiling appears stable. We should now be able'
	DB	' to use Turbolift 2, Captain.',0
L0C22:
	mov	byte ptr [si+debris_cleared], 1
	retf

; The crew and the debris.
H_0C27:
	SCRIPT	MSG_USE, OBJ_SPOCK, 0Ah, 0, H_0CF4
SpockOnDebris:
	cmp	byte ptr [si+beam_placed], 1
	je	L0CAE
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN3_008
	call	Say
	jmp	SHORT L0CAD

T_VEN3_008	LABEL	BYTE
	DB	'#VEN3\VEN3_008#The debris appears quite unstable. Any disturbanc'
	DB	'es may trigger an avalanche of debris to fall.',0
L0CAD:
	retf

L0CAE:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN3_011
	call	Say
	jmp	SHORT H_0CF4
				; NOTE: jumps to a script header, executing its six bytes as code

T_VEN3_011	LABEL	BYTE
	DB	'#VEN3\VEN3_011#There is too much debris to remove by hand.',0

H_0CF4:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 0Ah, 0, H_0DE0
KijeOnDebris:
	cmp	byte ptr [si+beam_placed], 1
	jne	L0D03
	JMPN	L0D8A

L0D03:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN3_017
	call	Say
	jmp	SHORT L0D89

T_VEN3_017	LABEL	BYTE
	DB	'#VEN3\VEN3_017#Sir, I really don''t think we should try and mess '
	DB	'with that debris. We may bring the whole thing down on us.',0
L0D89:
	retf

L0D8A:
	jne	L0D8F
	JMPN	L0F8E

L0D8F:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN3_016
	call	Say
	jmp	SHORT L0DDF

T_VEN3_016	LABEL	BYTE
	DB	'#VEN3\VEN3_016#It will take us forever to dig through all that, '
	DB	'sir.',0
L0DDF:
	retf

H_0DE0:
	SCRIPT	MSG_USE, OBJ_MCCOY, 0Ah, 0, H_0E21
McCoyOnDebris:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN3_004
	call	Say
	jmp	SHORT L0E20

T_VEN3_004	LABEL	BYTE
	DB	'#VEN3\VEN3_004#I''m a doctor, not a coal miner.',0
L0E20:
	retf

; Wedging the beam under the ceiling (msgs 7, 8).
H_0E21:
	SCRIPT	MSG_USE, IT_BEAM, 0Ah, 0, H_0E48
BeamOnDebris:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 7
	push	ax
	mov	ax, 6Dh
	push	ax
	mov	ax, 94h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 148, 109, 7)
	add	sp, 0Ah
	retf

H_0E48:
	SCRIPT	MSG_WALK_DONE, 7, 0, 0, H_0E86
KirkAtCeiling:
	jmp	SHORT L0E57

N_kusemn	LABEL	BYTE
	DB	'kusemn',0
L0E57:
	push	8
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 8)
	add	sp, 0Ch
	jmp	SHORT L0E76

N_MUR3E1S	LABEL	BYTE
	DB	'MUR3E1S',0
L0E76:
	push	OFFSET N_MUR3E1S
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR3E1S")
	add	sp, 4
	retf

H_0E86:
	SCRIPT	MSG_ANIM_DONE, 8, 0, 0, H_0EC4
BeamPlaced:
	jmp	SHORT L0E95

N_s7r3bm_2	LABEL	BYTE
	DB	's7r3bm',0
L0E95:
	push	0
	push	61h
	push	8Ch
	push	OFFSET N_s7r3bm_2
	push	0Dh
	push	RC_ANIM2
	SERVICE		; Anim(13, "s7r3bm", 140, 97, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr [si+beam_placed], 1
	mov	ax, IT_BEAM
	push	ax
	mov	ax, RC_TAKEITEM
	push	ax
	SERVICE		; TakeItem(IT_BEAM)
	add	sp, 4
	retf

; Spock's tricorder and the saw.
H_0EC4:
	SCRIPT	MSG_USE, IT_STRICOR, 0Ah, 0, H_0FD6
SpockScansDebris:
	jmp	SHORT L0ED3

N_sscann	LABEL	BYTE
	DB	'sscann',0
L0ED3:
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
	cmp	byte ptr [si+beam_placed], 1
	jne	L0F01
	JMPN	L0F8E

L0F01:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN3_009
	call	Say
	JMPN	L0F8D

T_VEN3_009	LABEL	BYTE
	DB	'#VEN3\VEN3_009#The debris is highly unstable, Captain. I recomme'
	DB	'nd we try to find a support of some kind to secure the ceiling.',0
L0F8D:
	retf

L0F8E:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN3_007
	call	Say
	jmp	SHORT L0FD5

T_VEN3_007	LABEL	BYTE
	DB	'#VEN3\VEN3_007#The beam is supporting the ceiling, Captain.',0
L0FD5:
	retf

H_0FD6:
	SCRIPT	MSG_USE, IT_LMD, 0Ah, 0, H_1050
SawOnDebris:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN3_010
	call	Say
	jmp	SHORT L104F

T_VEN3_010	LABEL	BYTE
	DB	'#VEN3\VEN3_010#The molecular saw is too fine of a cutting tool t'
	DB	'o be of any use in clearing the debris.',0
L104F:
	retf

H_1050:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_1141
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN3_001
	call	Say
	JMPN	L1140

T_VEN3_001	LABEL	BYTE
	DB	'#VEN3\VEN3_001#I wish I were a poet. I wish I had the words to m'
	DB	'atch how this makes me feel. These people were Starfleet officer'
	DB	's, giving their lives to explore the cosmos. I wish I knew some '
	DB	'eulogy that did them justice.',0
L1140:
	retf

H_1141:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_117C
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN3_012
	call	Say
	jmp	SHORT L117B

T_VEN3_012	LABEL	BYTE
	DB	'#VEN3\VEN3_012#Turbolift ahead, Captain.',0
L117B:
	retf

H_117C:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_11D5
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN3_003
	call	Say
	jmp	SHORT L11D4

T_VEN3_003	LABEL	BYTE
	DB	'#VEN3\VEN3_003#Damn this tricorder. Why couldn''t one of them be '
	DB	'alive?',0
L11D4:
	retf

H_11D5:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_1260
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN3_018
	call	Say
	jmp	SHORT L1225

T_VEN3_018	LABEL	BYTE
	DB	'#VEN3\VEN3_018#Be careful, Captain. This ship is a death trap.',0
L1225:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN3_005
	call	Say
	jmp	SHORT L125F

T_VEN3_005	LABEL	BYTE
	DB	'#VEN3\VEN3_005#A poor choice of words, Ensign.',0
L125F:
	retf

H_1260:
	SCRIPT	MSG_GET, 0Ah, 0, 0, H_12B5
GetDebris:
	mov	ax, 0
	mov	bx, OFFSET T_VEN3N010
	call	Say
	jmp	SHORT L12B4

T_VEN3N010	LABEL	BYTE
	DB	'#VEN3\VEN3N010#There is far too much debris to be cleared by han'
	DB	'd.',0
L12B4:
	retf

; Taking the cable (msgs 0Bh, 0Ch).
H_12B5:
	SCRIPT	MSG_GET, 0Bh, 0, 0, H_12DC
GetCable:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0Bh
	push	ax
	mov	ax, 85h
	push	ax
	mov	ax, 0B7h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 183, 133, 11)
	add	sp, 0Ah
	retf

H_12DC:
	SCRIPT	MSG_WALK_DONE, 0Bh, 0, 0, H_1319
KirkAtCable:
	jmp	SHORT L12EB

N_kusehn	LABEL	BYTE
	DB	'kusehn',0
L12EB:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_kusehn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 12)
	add	sp, 0Ch
	jmp	SHORT L1309

N_MUR4E6	LABEL	BYTE
	DB	'MUR4E6',0
L1309:
	push	OFFSET N_MUR4E6
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR4E6")
	add	sp, 4
	retf

H_1319:
	SCRIPT	MSG_ANIM_DONE, 0Ch, 0, 0, H_137C
TookCable:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, 0Bh
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(11)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_VEN3N014
	call	Say
	jmp	SHORT L1367

T_VEN3N014	LABEL	BYTE
	DB	'#VEN3\VEN3N014#You have taken the cable.',0
L1367:
	mov	ax, IT_CABLE2
	push	ax
	mov	ax, RC_GIVEITEM
	push	ax
	SERVICE		; GiveItem(IT_CABLE2)
	add	sp, 4
	mov	byte ptr [si+cable_taken], 1
	retf

; Every tick, common to the mission's rooms: the Elasi deadlines set on
; the bridge (room 2). Until the Enterprise returns: boarding unless the
; shields are up, the thirty minutes, the wait after Kirk complies (then
; a warning and the torpedoes), the chance after they lower their
; shields. When one runs out, the game is over.
H_137C:
	SCRIPT	MSG_TICK, ANY, ANY, ANY, H_15A0
ElasiDeadlines:
	cmp	word ptr [si+board_timer], 0
	je	L1396
	dec	word ptr [si+board_timer]
	jne	L1396
	cmp	byte ptr [si+power_to], 2
	je	L1396
	JMPN	L1496

L1396:
	cmp	word ptr [si+stall_timer], 0
	je	L13AA
	dec	word ptr [si+stall_timer]
	jne	L13AA
	cmp	byte ptr [si+complied], 1
	je	L13AA
	JMPN	L1496

L13AA:
	cmp	word ptr [si+comply_timer], 0
	je	L1409
	dec	word ptr [si+comply_timer]
	jne	L1409
	cmp	byte ptr [si+rescued], 1
	je	L1409
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_098
	call	Say
	jmp	SHORT L1404

T_VEN2_098	LABEL	BYTE
	DB	'#VEN2\VEN2_098#What are you stalling for? Lower your shields.',0
L1404:
	mov	word ptr [si+torpedo_timer], 0A8Ch
L1409:
	cmp	word ptr [si+torpedo_timer], 0
	je	L1482
	dec	word ptr [si+torpedo_timer]
	jne	L1482
	cmp	byte ptr [si+rescued], 1
	je	L1482
	mov	ax, 0
	mov	bx, OFFSET T_VENA_F40
	call	Say
	jmp	SHORT L1476

T_VENA_F40	LABEL	BYTE
	DB	'#VENA\VENA_F40#The Elasi fire photon torpedoes. The Republic has'
	DB	' been destroyed.',0
L1476:
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
L1482:
	cmp	word ptr [si+attack_timer], 0
	je	L1495
	dec	word ptr [si+attack_timer]
	jne	L1495
	cmp	byte ptr [si+rescued], 1
	je	L1495
	jmp	SHORT L1496

L1495:
	retf

L1496:
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

H_15A0:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_15A8
	jmp	SHORT KillAnything

H_15A8:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_163D
KillAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VENA_F34
	call	Say
	JMPN	L163C

T_VENA_F34	LABEL	BYTE
	DB	'#VENA\VENA_F34#Captain, it would be unwise to use your phaser co'
	DB	'nsidering the already extensive damage sustained by the Republic'
	DB	'.',0
L163C:
	retf

; The hypo, empty or full of oil.
H_163D:
	SCRIPT	MSG_LOOK, IT_HYPO, 0, 0, H_16D3
LookAtHypo:
	cmp	byte ptr [si+hypo_oiled], 1
	je	L168A
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N010
	call	Say
	jmp	SHORT L1689

T_VEN4N010	LABEL	BYTE
	DB	'#VEN4\VEN4N010#This is an empty hypodermic injector.',0
L1689:
	retf

L168A:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N007
	call	Say
	jmp	SHORT L16D2

T_VEN6N007	LABEL	BYTE
	DB	'#VEN6\VEN6N007#The hypo is now filled with multipurpose oil.',0
L16D2:
	retf

; The communicator: before the Enterprise leaves, Uhura; while the Elasi
; jam it, Spock; otherwise Uhura, tracking the distress call.
H_16D3:
	SCRIPT	MSG_USE, IT_COMM, OBJ_KIRK, 0, H_18D8
CallEnterprise:
	cmp	byte ptr [si+enterprise_away], 1
	je	L175B
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018
	call	Say
	jmp	SHORT L1724

T_MUD4_018	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L1724:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146
	call	Say
	jmp	SHORT L175A

T_BRIDU146	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L175A:
	retf

L175B:
	cmp	byte ptr [si+elasi_here], 1
	jne	L1764
	JMPN	L1861

L1764:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_2
	call	Say
	jmp	SHORT L17A8

T_MUD4_018_2	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise, Kirk to Enterprise...',0
L17A8:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_VEN2U093
	call	Say
	jmp	SHORT L1813

T_VEN2U093	LABEL	BYTE
	DB	'#VEN2\VEN2U093#Enterprise here. We''re still tracking the distres'
	DB	's call. Are you all right, Sir?',0
L1813:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_028
	call	Say
	jmp	SHORT L1860

T_VEN2_028	LABEL	BYTE
	DB	'#VEN2\VEN2_028#Yes, Uhura. Just wanted a status report. Kirk out'
	DB	'.',0
L1860:
	retf

L1861:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_066
	call	Say
	jmp	SHORT L18D5

T_VEN2_066	LABEL	BYTE
	DB	'#VEN2\VEN2_066#They are jamming all frequencies, Captain. We wil'
	DB	'l not be able to contact the Enterprise.',0
L18D5:
	retf

; In the room file, so these start again each time the room loads
mccoy_line	LABEL	BYTE	; which of McCoy's lines
	DB	0, 0

; McCoy and the body.
H_18D8:
	SCRIPT	MSG_USE, IT_MEDKIT, 0Ch, 0, H_18E0
	jmp	SHORT MTricorderOnBody

H_18E0:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Ch, 0, H_18E8
MTricorderOnBody:
	jmp	SHORT McCoyOnBody

H_18E8:
	SCRIPT	MSG_USE, OBJ_MCCOY, 0Ch, 0, Talk
McCoyOnBody:
	push	5
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 5)
	add	sp, 6
	mov	word ptr cs:mccoy_line, ax
	cmp	word ptr cs:mccoy_line, 0
	jne	L1933
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_019
	call	Say
	jmp	SHORT L1932

T_DEM3_019	LABEL	BYTE
	DB	'#DEM3\DEM3_019#He''s dead, jim.',0
L1932:
	retf

L1933:
	cmp	word ptr cs:mccoy_line, 1
	jne	L197B
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN4_016
	call	Say
	jmp	SHORT L197A

T_VEN4_016	LABEL	BYTE
	DB	'#VEN4\VEN4_016#Jim...there''s nothing more I can do.',0
L197A:
	retf

L197B:
	cmp	word ptr cs:mccoy_line, 2
	jne	L19B4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_G_014
	call	Say
	jmp	SHORT L19B3

T_G_014	LABEL	BYTE
	DB	'#GENE\G_014#This person''s dead, Jim.',0
L19B3:
	retf

L19B4:
	cmp	word ptr cs:mccoy_line, 3
	jne	L19ED
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_G_014_2
	call	Say
	jmp	SHORT L19EC

T_G_014_2	LABEL	BYTE
	DB	'#GENE\G_014#This person''s dead, Jim.',0
L19EC:
	retf

L19ED:
	cmp	word ptr cs:mccoy_line, 4
	jne	L1A30
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_016
	call	Say
	jmp	SHORT L1A2F

T_VEN0_016	LABEL	BYTE
	DB	'#VEN0\VEN0_016#They''re dead, Jim. All of them.',0
L1A2F:
	retf

L1A30:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_016_2
	call	Say
	jmp	SHORT L1A6A

T_VEN0_016_2	LABEL	BYTE
	DB	'#VEN0\VEN0_016#They''re dead, Jim. All of them.',0
L1A6A:
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
	DW	155,73, 177,73, 177,96, 155,96
	DW	21h, 4	; id, points
	DW	83,69, 94,69, 94,125, 83,136
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	0, 4	; id, points
	DW	156,96, 177,96, 177,98, 156,98
	DW	1, 4	; id, points
	DW	24,190, 279,190, 279,199, 24,199
	DW	3, 4	; id, points
	DW	92,127, 100,127, 91,136, 83,136
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
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
	DB	'wes',0
N_Elasi_Captain	LABEL	BYTE
	DB	'Elasi Captain',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
