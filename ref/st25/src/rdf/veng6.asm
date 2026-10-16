; VENG6.RDF - "Vengeance", the Republic's engineering section. Two power
; cables run the impulse engines and the fusion mixture regulator into a
; junction box; with the engineering journals Spock sets its impedance and
; impulse power returns. The oil for the hypo is here too.
;
; Actors: 8/9 the cables at the engines and the regulator, 0Ah (10) the
; junction box, 0Bh (11) the journals, 0Ch (12) the door, 0Dh (13) a
; body, 0Eh (14) the power light, 0Fh (15) the closet. Objects: those,
; 20h/21h the power ports, 22h the oil, 23h the closet, 24h the regulator,
; 25h the engines, 26h their controls, 27h the door. Exit 2: the corridor
; (room 5).
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 21D3: the engine reads its bytes
;   as key 50 B8 03 00 and next 2E50 (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
power_on	EQU	RS_VARS+0Bh	; impulse power is back
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
wired	EQU	RS_VARS+34h	; bits: 1 engines cabled to the junction, 2 regulator cabled, 4 power on
read_journals	EQU	RS_VARS+38h	; Spock has read the engineering journals (room 2)
journals_taken	EQU	RS_VARS+39h	; Kirk has taken the engineering journals
closet_open	EQU	RS_VARS+3Ah	; the storage closet is open

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0B4h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	9Ah
rdf_scale_min	LABEL	BYTE
	DW	0FAh	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, -1, 5, -1	; room for each exit
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
	DW	308,171, 228,180	; entrance 2, crew 0
	DW	308,171, 240,170	; entrance 2, crew 1
	DW	308,171, 248,190	; entrance 2, crew 2
	DW	308,171, 289,174	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0
; In the room file, so these start again each time the room loads
at_engines	LABEL	BYTE	; Kirk or Spock has reached the engines
	DB	0
at_regulator	LABEL	BYTE	; Kirk or Spock has reached the regulator
	DB	0
cable_item	LABEL	BYTE	; the cable being used (IT_CABLE1 or IT_CABLE2)
	DB	0, 0

rdf_scripts:
; The room starts: the door, the cables, the power light, the closet.
H_00CE:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0245
StartRoom:
	jmp	SHORT L00DE

N_s7r6d1c	LABEL	BYTE
	DB	's7r6d1c',0
L00DE:
	push	0
	push	0A8h
	push	13Eh
	push	OFFSET N_s7r6d1c
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s7r6d1c", 318, 168, 0)
	add	sp, 0Ch
	jmp	SHORT L00FE

N_s7r6c1	LABEL	BYTE
	DB	's7r6c1',0
L00FE:
	push	0
	push	5Ch
	push	82h
	push	OFFSET N_s7r6c1
	push	0Dh
	push	RC_ANIM2
	SERVICE		; Anim(13, "s7r6c1", 130, 92, 0)
	add	sp, 0Ch
	jmp	SHORT L011D

N_s7r6j1	LABEL	BYTE
	DB	's7r6j1',0
L011D:
	push	0
	push	0AFh
	push	9Ah
	push	OFFSET N_s7r6j1
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s7r6j1", 154, 175, 0)
	add	sp, 0Ch
	test	byte ptr [si+wired], 1
	je	L0159
	jmp	SHORT L0143

N_s7r6cl	LABEL	BYTE
	DB	's7r6cl',0
L0143:
	push	0
	push	95h
	push	5Dh
	push	OFFSET N_s7r6cl
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s7r6cl", 93, 149, 0)
	add	sp, 0Ch
L0159:
	test	byte ptr [si+wired], 2
	je	L017F
	jmp	SHORT L0168

N_s7r6cr	LABEL	BYTE
	DB	's7r6cr',0
L0168:
	push	0
	push	94h
	push	107h
	push	OFFSET N_s7r6cr
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s7r6cr", 263, 148, 0)
	add	sp, 0Ch
L017F:
	cmp	byte ptr [si+power_on], 1
	jne	L01BF
	jmp	SHORT L018E

N_s7r6i1	LABEL	BYTE
	DB	's7r6i1',0
L018E:
	push	0
	push	59h
	push	9Eh
	push	OFFSET N_s7r6i1
	push	0Eh
	push	RC_ANIM2
	SERVICE		; Anim(14, "s7r6i1", 158, 89, 0)
	add	sp, 0Ch
	jmp	SHORT L01AE

N_VEN6LON	LABEL	BYTE
	DB	'VEN6LON',0
L01AE:
	push	OFFSET N_VEN6LON
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("VEN6LON")
	add	sp, 4
	jmp	SHORT L01D9

L01BF:
	jmp	SHORT L01CA

N_VEN6LOFF	LABEL	BYTE
	DB	'VEN6LOFF',0
L01CA:
	push	OFFSET N_VEN6LOFF
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("VEN6LOFF")
	add	sp, 4
L01D9:
	cmp	byte ptr [si+journals_taken], 1
	je	L01FE
	jmp	SHORT L01E8

N_s7r6ej	LABEL	BYTE
	DB	's7r6ej',0
L01E8:
	push	0
	push	82h
	push	24h
	push	OFFSET N_s7r6ej
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r6ej", 36, 130, 0)
	add	sp, 0Ch
L01FE:
	jmp	SHORT L0208

N_s7r6p1c	LABEL	BYTE
	DB	's7r6p1c',0
L0208:
	push	0
	push	86h
	push	19h
	push	OFFSET N_s7r6p1c
	push	0Fh
	push	RC_ANIM2
	SERVICE		; Anim(15, "s7r6p1c", 25, 134, 0)
	add	sp, 0Ch
	cmp	byte ptr [si+closet_open], 1
	jne	L0244
	jmp	SHORT L022E

N_s7r6p1o	LABEL	BYTE
	DB	's7r6p1o',0
L022E:
	push	0
	push	86h
	push	19h
	push	OFFSET N_s7r6p1o
	push	0Fh
	push	RC_ANIM2
	SERVICE		; Anim(15, "s7r6p1o", 25, 134, 0)
	add	sp, 0Ch
L0244:
	retf

; Walking out to the corridor (msg 2, anim msg 1).
H_0245:
	SCRIPT	MSG_WALK, 0Ch, 0, 0, H_024D
	jmp	SHORT WalkToDoor

H_024D:
	SCRIPT	MSG_WALK, 27h, 0, 0, H_0270
WalkToDoor:
	mov	ax, 2
	push	ax
	mov	ax, 0ADh
	push	ax
	mov	ax, 120h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 288, 173, 2)
	add	sp, 0Ah
	retf

H_0270:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_02AB
AtDoor:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	jmp	SHORT L0293

N_s7r6d1	LABEL	BYTE
	DB	's7r6d1',0
L0293:
	push	1
	push	0A8h
	push	13Eh
	push	OFFSET N_s7r6d1
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s7r6d1", 318, 168, 1)
	add	sp, 0Ch
	retf

H_02AB:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_02CE
DoorOpened:
	mov	ax, 0
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 136h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 310, 170, 0)
	add	sp, 0Ah
	retf

; Looking.
H_02CE:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_02DE
LookAtPowerPort:
	mov	ax, OFFSET S_230E
	mov	bx, OFFSET T_VEN6N018
	call	Say
	retf

H_02DE:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_02EE
LookAtRegulatorPort:
	mov	ax, OFFSET S_230E
	mov	bx, OFFSET T_VEN6N016
	call	Say
	retf

H_02EE:
	SCRIPT	MSG_LOOK, 27h, 0, 0, H_02F6
	jmp	SHORT LookAtDoor

H_02F6:
	SCRIPT	MSG_LOOK, 0Ch, 0, 0, H_033C
LookAtDoor:
	mov	ax, 0
	mov	bx, OFFSET T_VEN5N007
	call	Say
	jmp	SHORT L033B

T_VEN5N007	LABEL	BYTE
	DB	'#VEN5\VEN5N007#This door leads to main engineering.',0
L033B:
	retf

H_033C:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_03B7
LookAtOil:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N011
	call	Say
	jmp	SHORT L03B6

T_VEN6N011	LABEL	BYTE
	DB	'#VEN6\VEN6N011#This is a canister of high grade multipurpose oil'
	DB	'. Very useful for lubricating machinery.',0
L03B6:
	retf

H_03B7:
	SCRIPT	MSG_LOOK, 0Fh, 0, 0, H_03BF
	jmp	SHORT LookAtCloset

H_03BF:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_0403
LookAtCloset:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N015
	call	Say
	jmp	SHORT L0402

T_VEN6N015	LABEL	BYTE
	DB	'#VEN6\VEN6N015#This is a standard storage closet.',0
L0402:
	retf

H_0403:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_040B
	jmp	SHORT LookAtCable

H_040B:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_0462
LookAtCable:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N013
	call	Say
	jmp	SHORT L0461

T_VEN6N013	LABEL	BYTE
	DB	'#VEN6\VEN6N013#This is a length of heavy duty insulated power ca'
	DB	'ble.',0
L0461:
	retf

H_0462:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_04CC
LookAtRegulator:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N017
	call	Say
	jmp	SHORT L04CB

T_VEN6N017	LABEL	BYTE
	DB	'#VEN6\VEN6N017#This is the fusion mixture regulator for the Repu'
	DB	'blic''s impulse engines.',0
L04CB:
	retf

H_04CC:
	SCRIPT	MSG_LOOK, 0Eh, 0, 0, H_04D4
	jmp	SHORT LookAtEngines

H_04D4:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_0525
LookAtEngines:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N010
	call	Say
	jmp	SHORT L0524

T_VEN6N010	LABEL	BYTE
	DB	'#VEN6\VEN6N010#These are the impulse engines for the Republic.',0
L0524:
	retf

H_0525:
	SCRIPT	MSG_LOOK, 26h, 0, 0, H_0580
LookAtControls:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N009
	call	Say
	jmp	SHORT L057F

T_VEN6N009	LABEL	BYTE
	DB	'#VEN6\VEN6N009#These are the controls to the Republic''s impulse '
	DB	'engines.',0
L057F:
	retf

H_0580:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_05EF
LookAtJunction:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N012
	call	Say
	jmp	SHORT L05EE

T_VEN6N012	LABEL	BYTE
	DB	'#VEN6\VEN6N012#This is a junction box used for temporary re-rout'
	DB	'ing of engineering circuits.',0
L05EE:
	retf

H_05EF:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_06E4
LookAtJournals:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N025
	call	Say
	jmp	SHORT L0644

T_VEN6N025	LABEL	BYTE
	DB	'#VEN6\VEN6N025#This is a library of engineering technical journa'
	DB	'ls.',0
L0644:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN6_021
	call	Say
	JMPN	L06E3

T_VEN6_021	LABEL	BYTE
	DB	'#VEN6\VEN6_021#These journals may prove useful in our attempt to'
	DB	' reestablish power. A functioning computer terminal will allow u'
	DB	's to examine them.',0
L06E3:
	retf

H_06E4:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_0740
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N001
	call	Say
	jmp	SHORT L073F

T_VEN6N001	LABEL	BYTE
	DB	'#VEN6\VEN6N001#Kirk wonders if the landing party has overlooked '
	DB	'anything.',0
L073F:
	retf

H_0740:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_07BE
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N003
	call	Say
	jmp	SHORT L07BD

T_VEN6N003	LABEL	BYTE
	DB	'#VEN6\VEN6N003#Spock glances at his tricorder, making certain th'
	DB	'e superstructure of the Republic is stable.',0
L07BD:
	retf

H_07BE:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_0822
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N002
	call	Say
	jmp	SHORT L0821

T_VEN6N002	LABEL	BYTE
	DB	'#VEN6\VEN6N002#McCoy wonders when it will be his turn to die in '
	DB	'the line of duty.',0
L0821:
	retf

H_0822:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_085B
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N000
	call	Say
	jmp	SHORT L085A

T_VEN6N000	LABEL	BYTE
	DB	'#VEN6\VEN6N000#Kije fidgets nervously.',0
L085A:
	retf

H_085B:
	SCRIPT	MSG_LOOK, 0Dh, 0, 0, H_088E
LookAtBody:
	mov	ax, 0
	mov	bx, OFFSET T_VEN0N016
	call	Say
	jmp	SHORT L088D

T_VEN0N016	LABEL	BYTE
	DB	'#VEN0\VEN0N016#This man is dead.',0
L088D:
	retf

H_088E:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_08E8
LookAtEngineering:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N019
	call	Say
	jmp	SHORT L08E7

T_VEN6N019	LABEL	BYTE
	DB	'#VEN6\VEN6N019#This was the engineering section of the U.S.S. Re'
	DB	'public.',0
L08E7:
	retf

H_08E8:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_09D5
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN6_005
	call	Say
	JMPN	L098E

T_VEN6_005	LABEL	BYTE
	DB	'#VEN6\VEN6_005#This reminds me of a poem I read when I was a chi'
	DB	'ld. "I am Ozymandius, King of Kings, look ><upon my works, ye mi'
	DB	'ghty, and despair."',0
L098E:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN6_009
	call	Say
	jmp	SHORT L09D4

T_VEN6_009	LABEL	BYTE
	DB	'#VEN6\VEN6_009#You have good reason to despair, here, Jim.',0
L09D4:
	retf

H_09D5:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0A61
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN6_014
	call	Say
	jmp	SHORT L0A60

T_VEN6_014	LABEL	BYTE
	DB	'#VEN6\VEN6_014#There has been a .0003 degradation in hull integr'
	DB	'ity in the last hour. There should be no danger, Captain.',0
L0A60:
	retf

H_0A61:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0B79
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN6_008
	call	Say
	jmp	SHORT L0AD1

T_VEN6_008	LABEL	BYTE
	DB	'#VEN6\VEN6_008#Remind me to compliment Mr. Scott on the efficien'
	DB	'cy of his engineering section.',0
L0AD1:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN6_018
	call	Say
	JMPN	L0B78

T_VEN6_018	LABEL	BYTE
	DB	'#VEN6\VEN6_018#Given that Mr. Scott has received a Starfleet Cit'
	DB	'ation on five occasions for efficiency, I do not see the logic i'
	DB	'n your suggestion, Doctor.',0
L0B78:
	retf

H_0B79:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0BE7
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN6_023
	call	Say
	jmp	SHORT L0BE6

T_VEN6_023	LABEL	BYTE
	DB	'#VEN6\VEN6_023#Tragic, Captain. This is one of the greatest disa'
	DB	'sters in Starfleet history.',0
L0BE6:
	retf

; Either cable on the engines' power port: Kirk and Spock both walk
; over (msgs 3, 4, anim 5) and cable it to the junction box.
H_0BE7:
	SCRIPT	MSG_USE, IT_CABLE1, 20h, 0, H_0BEF
	jmp	SHORT Cable1OnEngines

H_0BEF:
	SCRIPT	MSG_USE, IT_CABLE1, 26h, 0, H_0BFE
Cable1OnEngines:
	mov	word ptr cs:cable_item, 84h
	jmp	SHORT L0C13

H_0BFE:
	SCRIPT	MSG_USE, IT_CABLE2, 20h, 0, H_0C06
	jmp	SHORT Cable2OnEngines

H_0C06:
	SCRIPT	MSG_USE, IT_CABLE2, 26h, 0, H_0C57
Cable2OnEngines:
	mov	word ptr cs:cable_item, 85h
L0C13:
	test	byte ptr [si+wired], 1
	je	L0C1A
	retf

L0C1A:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 3
	push	ax
	mov	ax, 0B4h
	push	ax
	mov	ax, 91h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 145, 180, 3)
	add	sp, 0Ah
	mov	ax, 4
	push	ax
	mov	ax, 0A0h
	push	ax
	mov	ax, 5Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 92, 160, 4)
	add	sp, 0Ah
	retf

H_0C57:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_0C5F
	jmp	SHORT AtEngines

H_0C5F:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_0CC6
AtEngines:
	cmp	byte ptr cs:at_engines, 1
	je	L0C73
	inc	byte ptr cs:at_engines
	retf

L0C73:
	jmp	SHORT L0C7C

N_kuseln	LABEL	BYTE
	DB	'kuseln',0
L0C7C:
	push	5
	push	-1
	push	-1
	push	OFFSET N_kuseln
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseln", -1, -1, 5)
	add	sp, 0Ch
	jmp	SHORT L0C9A

N_suseln	LABEL	BYTE
	DB	'suseln',0
L0C9A:
	push	0
	push	-1
	push	-1
	push	OFFSET N_suseln
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "suseln", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0CB6

N_EFX4	LABEL	BYTE
	DB	'EFX4',0
L0CB6:
	push	OFFSET N_EFX4
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EFX4")
	add	sp, 4
	retf

H_0CC6:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_0D6E
EnginesWired:
	jmp	SHORT L0CD5

N_s7r6cl_2	LABEL	BYTE
	DB	's7r6cl',0
L0CD5:
	push	0
	push	95h
	push	5Dh
	push	OFFSET N_s7r6cl_2
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s7r6cl", 93, 149, 0)
	add	sp, 0Ch
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N020
	call	Say
	jmp	SHORT L0D54

T_VEN6N020	LABEL	BYTE
	DB	'#VEN6\VEN6N020#You connect a length of cable between the impulse'
	DB	' engine and the junction box.',0
L0D54:
	or	byte ptr [si+wired], 1
	mov	ax, word ptr cs:cable_item
	push	ax
	mov	ax, RC_TAKEITEM
	push	ax
	SERVICE		; TakeItem(?)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Either cable on the regulator's port (msgs 6, 7, anim 8): the same
; from the junction box to the fusion mixture regulator.
H_0D6E:
	SCRIPT	MSG_USE, IT_CABLE1, 21h, 0, H_0D76
	jmp	SHORT Cable1OnRegulator

H_0D76:
	SCRIPT	MSG_USE, IT_CABLE1, 24h, 0, H_0D85
Cable1OnRegulator:
	mov	word ptr cs:cable_item, 84h
	jmp	SHORT L0D9A

H_0D85:
	SCRIPT	MSG_USE, IT_CABLE2, 21h, 0, H_0D8D
	jmp	SHORT Cable2OnRegulator

H_0D8D:
	SCRIPT	MSG_USE, IT_CABLE2, 24h, 0, H_0DDE
Cable2OnRegulator:
	mov	word ptr cs:cable_item, 85h
L0D9A:
	test	byte ptr [si+wired], 2
	je	L0DA1
	retf

L0DA1:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 6
	push	ax
	mov	ax, 0B4h
	push	ax
	mov	ax, 0ACh
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 172, 180, 6)
	add	sp, 0Ah
	mov	ax, 7
	push	ax
	mov	ax, 0A0h
	push	ax
	mov	ax, 107h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 263, 160, 7)
	add	sp, 0Ah
	retf

H_0DDE:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_0DE6
	jmp	SHORT AtRegulator

H_0DE6:
	SCRIPT	MSG_WALK_DONE, 7, 0, 0, H_0E4D
AtRegulator:
	cmp	byte ptr cs:at_regulator, 1
	je	L0DFA
	inc	byte ptr cs:at_regulator
	retf

L0DFA:
	jmp	SHORT L0E03

N_kuseln_2	LABEL	BYTE
	DB	'kuseln',0
L0E03:
	push	8
	push	-1
	push	-1
	push	OFFSET N_kuseln_2
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseln", -1, -1, 8)
	add	sp, 0Ch
	jmp	SHORT L0E21

N_suseln_2	LABEL	BYTE
	DB	'suseln',0
L0E21:
	push	0
	push	-1
	push	-1
	push	OFFSET N_suseln_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "suseln", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0E3D

N_EFX4_2	LABEL	BYTE
	DB	'EFX4',0
L0E3D:
	push	OFFSET N_EFX4_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EFX4")
	add	sp, 4
	retf

H_0E4D:
	SCRIPT	MSG_ANIM_DONE, 8, 0, 0, H_0EFA
RegulatorWired:
	jmp	SHORT L0E5C

N_s7r6cr_2	LABEL	BYTE
	DB	's7r6cr',0
L0E5C:
	push	0
	push	94h
	push	107h
	push	OFFSET N_s7r6cr_2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s7r6cr", 263, 148, 0)
	add	sp, 0Ch
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N022
	call	Say
	jmp	SHORT L0EE0

T_VEN6N022	LABEL	BYTE
	DB	'#VEN6\VEN6N022#You connect a length of cable between the regulat'
	DB	'or circuits and the junction box.',0
L0EE0:
	or	byte ptr [si+wired], 2
	mov	ax, word ptr cs:cable_item
	push	ax
	mov	ax, RC_TAKEITEM
	push	ax
	SERVICE		; TakeItem(?)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	retf

; The junction box, both cables in: Spock sets the impedance, but only
; from the engineering journals (msgs 9, anim 0Ah). Impulse power returns.
H_0EFA:
	SCRIPT	MSG_USE, OBJ_SPOCK, 0Ah, 0, H_0F02
	jmp	SHORT McCoyOnJunction

H_0F02:
	SCRIPT	MSG_USE, OBJ_MCCOY, 0Ah, 0, H_0F0A
McCoyOnJunction:
	jmp	SHORT KijeOnJunction

H_0F0A:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 0Ah, 0, H_0F12
KijeOnJunction:
	jmp	SHORT UseJunction

H_0F12:
	SCRIPT	MSG_USE, OBJ_KIRK, 0Ah, 0, H_11BE
UseJunction:
	cmp	byte ptr [si+power_on], 1
	jne	L0F8B
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN6_012
	call	Say
	jmp	SHORT L0F8A

T_VEN6_012	LABEL	BYTE
	DB	'#VEN6\VEN6_012#The impedance is correctly set, Captain. Changing'
	DB	' the setting could be dangerous.',0
L0F8A:
	retf

L0F8B:
	test	byte ptr [si+wired], 1
	jne	L0F94
	JMPN	L1276

L0F94:
	test	byte ptr [si+wired], 2
	jne	L0F9D
	JMPN	L1276

L0F9D:
	mov	ax, OFFSET N_computer
	mov	bx, OFFSET T_COMPA185
	call	Say
	jmp	SHORT L0FD3

T_COMPA185	LABEL	BYTE
	DB	'#COMP\COMPA185#Please select an impedence.',0
L0FD3:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN6_003
	call	Say
	jmp	SHORT L0FF4

T_VEN6_003	LABEL	BYTE
	DB	'#VEN6\VEN6_003#Spock?',0
L0FF4:
	cmp	byte ptr [si+read_journals], 1
	jne	L0FFD
	JMPN	L10BD

L0FFD:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN6_017
	call	Say
	JMPN	L10BC

T_VEN6_017	LABEL	BYTE
	DB	'#VEN6\VEN6_017#Captain, the wrong setting on this particular dev'
	DB	'ice may cause the fusion reactors to melt down. We will have to '
	DB	'do some research to determine the correct setting.',0
L10BC:
	retf

L10BD:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN6_016
	call	Say
	JMPN	L115E

T_VEN6_016	LABEL	BYTE
	DB	'#VEN6\VEN6_016#Captain, the information obtained from the engine'
	DB	'ering journals indicates the correct impedance setting to be nin'
	DB	'eteen thousand ohms.',0
L115E:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN6_002
	call	Say
	jmp	SHORT L11A1

T_VEN6_002	LABEL	BYTE
	DB	'#VEN6\VEN6_002#Go ahead and adjust the settings, Spock.',0
L11A1:
	mov	ax, 9
	push	ax
	mov	ax, 0B4h
	push	ax
	mov	ax, 99h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 153, 180, 9)
	add	sp, 0Ah
	retf

H_11BE:
	SCRIPT	MSG_WALK_DONE, 9, 0, 0, H_11E3
SpockAtJunction:
	jmp	SHORT L11CD

N_suseln_3	LABEL	BYTE
	DB	'suseln',0
L11CD:
	push	0Ah
	push	-1
	push	-1
	push	OFFSET N_suseln_3
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "suseln", -1, -1, 10)
	add	sp, 0Ch
	retf

H_11E3:
	SCRIPT	MSG_ANIM_DONE, 0Ah, 0, 0, H_12DF
PowerRestored:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN6_019
	call	Say
	jmp	SHORT L1229

T_VEN6_019	LABEL	BYTE
	DB	'#VEN6\VEN6_019#Power has now been restored, Captain.',0
L1229:
	jmp	SHORT L1232

N_s7r6i1_2	LABEL	BYTE
	DB	's7r6i1',0
L1232:
	push	0
	push	59h
	push	9Eh
	push	OFFSET N_s7r6i1_2
	push	0Eh
	push	RC_ANIM2
	SERVICE		; Anim(14, "s7r6i1", 158, 89, 0)
	add	sp, 0Ch
	mov	byte ptr [si+power_on], 1
	mov	ax, RC_DIGIOFF
	push	ax
	SERVICE		; DigiOff()
	add	sp, 2
	jmp	SHORT L1262

N_VEN6LON_2	LABEL	BYTE
	DB	'VEN6LON',0
L1262:
	push	OFFSET N_VEN6LON_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("VEN6LON")
	add	sp, 4
	or	byte ptr [si+wired], 4
	retf

L1276:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN6_011
	call	Say
	jmp	SHORT L12DE

T_VEN6_011	LABEL	BYTE
	DB	'#VEN6\VEN6_011#It is illogical to use this machine before we hav'
	DB	'e something connected to it.',0
L12DE:
	retf

; Filling the hypo from the oil canister (msgs 0Dh, 0Eh).
H_12DF:
	SCRIPT	MSG_USE, IT_HYPO, 22h, 0, H_134C
HypoOnOil:
	cmp	byte ptr [si+hypo_oiled], 1
	je	L130C
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0Dh
	push	ax
	mov	ax, 9Eh
	push	ax
	mov	ax, 3Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 60, 158, 13)
	add	sp, 0Ah
	retf

L130C:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N006
	call	Say
	jmp	SHORT L134B

T_VEN6N006	LABEL	BYTE
	DB	'#VEN6\VEN6N006#The hypo is already filled with oil.',0
L134B:
	retf

H_134C:
	SCRIPT	MSG_WALK_DONE, 0Dh, 0, 0, H_1371
KirkAtOil:
	jmp	SHORT L135B

N_kusehw	LABEL	BYTE
	DB	'kusehw',0
L135B:
	push	0Eh
	push	-1
	push	-1
	push	OFFSET N_kusehw
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehw", -1, -1, 14)
	add	sp, 0Ch
	retf

H_1371:
	SCRIPT	MSG_ANIM_DONE, 0Eh, 0, 0, H_13C8
FilledHypo:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N007
	call	Say
	jmp	SHORT L13C3

T_VEN6N007	LABEL	BYTE
	DB	'#VEN6\VEN6N007#The hypo is now filled with multipurpose oil.',0
L13C3:
	mov	byte ptr [si+hypo_oiled], 1
	retf

; Opening and closing the closet (msgs 0Fh, 10h).
H_13C8:
	SCRIPT	MSG_USE, OBJ_KIRK, 0Fh, 0, H_13EF
UseCloset:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0Fh
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 36h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 54, 159, 15)
	add	sp, 0Ah
	retf

H_13EF:
	SCRIPT	MSG_WALK_DONE, 0Fh, 0, 0, H_1414
KirkAtCloset:
	jmp	SHORT L13FE

N_kusehw_2	LABEL	BYTE
	DB	'kusehw',0
L13FE:
	push	10h
	push	-1
	push	-1
	push	OFFSET N_kusehw_2
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehw", -1, -1, 16)
	add	sp, 0Ch
	retf

H_1414:
	SCRIPT	MSG_ANIM_DONE, 10h, 0, 0, H_14F4
ClosetToggled:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+closet_open], 1
	jne	L1458
	jmp	SHORT L142D

N_s7r6p2	LABEL	BYTE
	DB	's7r6p2',0
L142D:
	push	0
	push	86h
	push	19h
	push	OFFSET N_s7r6p2
	push	0Fh
	push	RC_ANIM2
	SERVICE		; Anim(15, "s7r6p2", 25, 134, 0)
	add	sp, 0Ch
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	mov	byte ptr [si+closet_open], 0
	retf

L1458:
	jmp	SHORT L1461

N_s7r6p1	LABEL	BYTE
	DB	's7r6p1',0
L1461:
	push	0
	push	86h
	push	19h
	push	OFFSET N_s7r6p1
	push	0Fh
	push	RC_ANIM2
	SERVICE		; Anim(15, "s7r6p1", 25, 134, 0)
	add	sp, 0Ch
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	mov	byte ptr [si+closet_open], 1
	cmp	byte ptr [si+journals_taken], 1
	je	L14F3
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N005
	call	Say
	jmp	SHORT L14F3

T_VEN6N005	LABEL	BYTE
	DB	'#VEN6\VEN6N005#The closet opens revealing a library of engineeri'
	DB	'ng technical journals.',0
L14F3:
	retf

; Spock's tricorder and the fusion pack.
H_14F4:
	SCRIPT	MSG_USE, IT_STRICOR, 25h, 0, H_167D
SpockScansEngines:
	jmp	SHORT L1503

N_sscans	LABEL	BYTE
	DB	'sscans',0
L1503:
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
	cmp	byte ptr [si+power_on], 1
	jne	L1570
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN6_010
	call	Say
	jmp	SHORT L156F

T_VEN6_010	LABEL	BYTE
	DB	'#VEN6\VEN6_010#Impulse power is functioning, Captain.',0
L156F:
	retf

L1570:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN6_020
	call	Say
	JMPN	L1638

T_VEN6_020	LABEL	BYTE
	DB	'#VEN6\VEN6_020#The impulse engines are intact, Captain. We could'
	DB	' use the fusion reactors from the impulse engines to restore pow'
	DB	'er, but the lines have been severed to the power regulator.',0
L1638:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN6_001
	call	Say
	jmp	SHORT L1673

T_VEN6_001	LABEL	BYTE
	DB	'#VEN6\VEN6_001#Can we re-route the power lines?',0
L1673:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN6_022
	call	Say
	retf

H_167D:
	SCRIPT	MSG_USE, IT_STRICOR, 24h, 0, H_17F4
SpockScansRegulator:
	jmp	SHORT L168C

N_sscans_2	LABEL	BYTE
	DB	'sscans',0
L168C:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscans_2
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
	cmp	byte ptr [si+power_on], 1
	jne	L16BA
	JMPN	L1748

L16BA:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN6_007
	call	Say
	JMPN	L1747

T_VEN6_007	LABEL	BYTE
	DB	'#VEN6\VEN6_007#Captain, this is the fusion mixture regulator for'
	DB	' the impulse engines. There is currently no power running to it.',0
L1747:
	retf

L1748:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN6_013
	call	Say
	JMPN	L17F3

T_VEN6_013	LABEL	BYTE
	DB	'#VEN6\VEN6_013#The regulator is fully operating from the power t'
	DB	'ap run from the impulse engines. We can allocate power to ship''s'
	DB	' systems in Auxiliary Control.',0
L17F3:
	retf

H_17F4:
	SCRIPT	MSG_USE, IT_STRICOR, 0Ah, 0, H_18F6
SpockScansJunction:
	jmp	SHORT L1803

N_sscans_3	LABEL	BYTE
	DB	'sscans',0
L1803:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscans_3
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
	mov	bx, OFFSET T_VEN6_015
	call	Say
	JMPN	L18F5

T_VEN6_015	LABEL	BYTE
	DB	'#VEN6\VEN6_015#This is an engineering circuit junction box. It i'
	DB	's used for temporary re-routing of power. Without using one of t'
	DB	'hese devices set to the proper impedance, an overload can occur.',0
L18F5:
	retf

H_18F6:
	SCRIPT	MSG_USE, IT_FUSION, 26h, 0, H_1985
FusionOnControls:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN6_006
	call	Say
	jmp	SHORT L1984

T_VEN6_006	LABEL	BYTE
	DB	'#VEN6\VEN6_006#Captain, the energy output of the Fusion Power pa'
	DB	'ck is insufficient to power any of the major ship''s systems.',0
L1984:
	retf

; Taking things.
H_1985:
	SCRIPT	MSG_GET, 0Ah, 0, 0, H_19C6
GetJunction:
	mov	ax, 0
	mov	bx, OFFSET T_MUD1N014
	call	Say
	jmp	SHORT L19C5

T_MUD1N014	LABEL	BYTE
	DB	'#MUD1\MUD1N014#This is much too heavy to lift.',0
L19C5:
	retf

H_19C6:
	SCRIPT	MSG_GET, 22h, 0, 0, H_1A22
GetOil:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N008
	call	Say
	jmp	SHORT L1A21

T_VEN6N008	LABEL	BYTE
	DB	'#VEN6\VEN6N008#The oil canister is bolted to the hull and can''t '
	DB	'be taken.',0
L1A21:
	retf

; Taking the journals (msgs 0Bh, 0Ch).
H_1A22:
	SCRIPT	MSG_GET, 0Bh, 0, 0, H_1A49
GetJournals:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0Bh
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 36h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 54, 159, 11)
	add	sp, 0Ah
	retf

H_1A49:
	SCRIPT	MSG_WALK_DONE, 0Bh, 0, 0, H_1A6E
KirkAtJournals:
	jmp	SHORT L1A58

N_kusemw	LABEL	BYTE
	DB	'kusemw',0
L1A58:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_kusemw
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemw", -1, -1, 12)
	add	sp, 0Ch
	retf

H_1A6E:
	SCRIPT	MSG_ANIM_DONE, 0Ch, 0, 0, H_1AE4
TookJournals:
	mov	ax, 0Bh
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(11)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N024
	call	Say
	jmp	SHORT L1ACF

T_VEN6N024	LABEL	BYTE
	DB	'#VEN6\VEN6N024#You take the engineering technical journals.',0
L1ACF:
	mov	byte ptr [si+journals_taken], 1
	mov	ax, IT_TECH
	push	ax
	mov	ax, RC_GIVEITEM
	push	ax
	SERVICE		; GiveItem(IT_TECH)
	add	sp, 4
	retf

; Every tick, common to the mission's rooms: the Elasi deadlines set on
; the bridge (room 2). Until the Enterprise returns: boarding unless the
; shields are up, the thirty minutes, the wait after Kirk complies (then
; a warning and the torpedoes), the chance after they lower their
; shields. When one runs out, the game is over.
H_1AE4:
	SCRIPT	MSG_TICK, ANY, ANY, ANY, H_1D08
ElasiDeadlines:
	cmp	word ptr [si+board_timer], 0
	je	L1AFE
	dec	word ptr [si+board_timer]
	jne	L1AFE
	cmp	byte ptr [si+power_to], 2
	je	L1AFE
	JMPN	L1BFE

L1AFE:
	cmp	word ptr [si+stall_timer], 0
	je	L1B12
	dec	word ptr [si+stall_timer]
	jne	L1B12
	cmp	byte ptr [si+complied], 1
	je	L1B12
	JMPN	L1BFE

L1B12:
	cmp	word ptr [si+comply_timer], 0
	je	L1B71
	dec	word ptr [si+comply_timer]
	jne	L1B71
	cmp	byte ptr [si+rescued], 1
	je	L1B71
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_098
	call	Say
	jmp	SHORT L1B6C

T_VEN2_098	LABEL	BYTE
	DB	'#VEN2\VEN2_098#What are you stalling for? Lower your shields.',0
L1B6C:
	mov	word ptr [si+torpedo_timer], 0A8Ch
L1B71:
	cmp	word ptr [si+torpedo_timer], 0
	je	L1BEA
	dec	word ptr [si+torpedo_timer]
	jne	L1BEA
	cmp	byte ptr [si+rescued], 1
	je	L1BEA
	mov	ax, 0
	mov	bx, OFFSET T_VENA_F40
	call	Say
	jmp	SHORT L1BDE

T_VENA_F40	LABEL	BYTE
	DB	'#VENA\VENA_F40#The Elasi fire photon torpedoes. The Republic has'
	DB	' been destroyed.',0
L1BDE:
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
L1BEA:
	cmp	word ptr [si+attack_timer], 0
	je	L1BFD
	dec	word ptr [si+attack_timer]
	jne	L1BFD
	cmp	byte ptr [si+rescued], 1
	je	L1BFD
	jmp	SHORT L1BFE

L1BFD:
	retf

L1BFE:
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

H_1D08:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_1D10
	jmp	SHORT KillAnything

H_1D10:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_1DA5
KillAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VENA_F34
	call	Say
	JMPN	L1DA4

T_VENA_F34	LABEL	BYTE
	DB	'#VENA\VENA_F34#Captain, it would be unwise to use your phaser co'
	DB	'nsidering the already extensive damage sustained by the Republic'
	DB	'.',0
L1DA4:
	retf

; The hypo, empty or full of oil.
H_1DA5:
	SCRIPT	MSG_LOOK, IT_HYPO, 0, 0, H_1E3B
LookAtHypo:
	cmp	byte ptr [si+hypo_oiled], 1
	je	L1DF2
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N010
	call	Say
	jmp	SHORT L1DF1

T_VEN4N010	LABEL	BYTE
	DB	'#VEN4\VEN4N010#This is an empty hypodermic injector.',0
L1DF1:
	retf

L1DF2:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N007_2
	call	Say
	jmp	SHORT L1E3A

T_VEN6N007_2	LABEL	BYTE
	DB	'#VEN6\VEN6N007#The hypo is now filled with multipurpose oil.',0
L1E3A:
	retf

; The communicator: before the Enterprise leaves, Uhura; while the Elasi
; jam it, Spock; otherwise Uhura, tracking the distress call.
H_1E3B:
	SCRIPT	MSG_USE, IT_COMM, OBJ_KIRK, 0, H_2040
CallEnterprise:
	cmp	byte ptr [si+enterprise_away], 1
	je	L1EC3
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018
	call	Say
	jmp	SHORT L1E8C

T_MUD4_018	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L1E8C:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146
	call	Say
	jmp	SHORT L1EC2

T_BRIDU146	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L1EC2:
	retf

L1EC3:
	cmp	byte ptr [si+elasi_here], 1
	jne	L1ECC
	JMPN	L1FC9

L1ECC:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_2
	call	Say
	jmp	SHORT L1F10

T_MUD4_018_2	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise, Kirk to Enterprise...',0
L1F10:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_VEN2U093
	call	Say
	jmp	SHORT L1F7B

T_VEN2U093	LABEL	BYTE
	DB	'#VEN2\VEN2U093#Enterprise here. We''re still tracking the distres'
	DB	's call. Are you all right, Sir?',0
L1F7B:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_028
	call	Say
	jmp	SHORT L1FC8

T_VEN2_028	LABEL	BYTE
	DB	'#VEN2\VEN2_028#Yes, Uhura. Just wanted a status report. Kirk out'
	DB	'.',0
L1FC8:
	retf

L1FC9:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_066
	call	Say
	jmp	SHORT L203D

T_VEN2_066	LABEL	BYTE
	DB	'#VEN2\VEN2_066#They are jamming all frequencies, Captain. We wil'
	DB	'l not be able to contact the Enterprise.',0
L203D:
	retf

mccoy_line	LABEL	BYTE	; which of McCoy's lines
	DB	0, 0

; McCoy and the body.
H_2040:
	SCRIPT	MSG_USE, IT_MEDKIT, 0Dh, 0, H_2048
	jmp	SHORT MTricorderOnBody

H_2048:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Dh, 0, H_2050
MTricorderOnBody:
	jmp	SHORT McCoyOnBody

H_2050:
	SCRIPT	MSG_USE, OBJ_MCCOY, 0Dh, 0, Talk
McCoyOnBody:
	push	5
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 5)
	add	sp, 6
	mov	word ptr cs:mccoy_line, ax
	cmp	word ptr cs:mccoy_line, 0
	jne	L209B
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_019
	call	Say
	jmp	SHORT L209A

T_DEM3_019	LABEL	BYTE
	DB	'#DEM3\DEM3_019#He''s dead, jim.',0
L209A:
	retf

L209B:
	cmp	word ptr cs:mccoy_line, 1
	jne	L20E3
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN4_016
	call	Say
	jmp	SHORT L20E2

T_VEN4_016	LABEL	BYTE
	DB	'#VEN4\VEN4_016#Jim...there''s nothing more I can do.',0
L20E2:
	retf

L20E3:
	cmp	word ptr cs:mccoy_line, 2
	jne	L211C
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_G_014
	call	Say
	jmp	SHORT L211B

T_G_014	LABEL	BYTE
	DB	'#GENE\G_014#This person''s dead, Jim.',0
L211B:
	retf

L211C:
	cmp	word ptr cs:mccoy_line, 3
	jne	L2155
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_G_014_2
	call	Say
	jmp	SHORT L2154

T_G_014_2	LABEL	BYTE
	DB	'#GENE\G_014#This person''s dead, Jim.',0
L2154:
	retf

L2155:
	cmp	word ptr cs:mccoy_line, 4
	jne	L2198
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_016
	call	Say
	jmp	SHORT L2197

T_VEN0_016	LABEL	BYTE
	DB	'#VEN0\VEN0_016#They''re dead, Jim. All of them.',0
L2197:
	retf

L2198:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_016_2
	call	Say
	jmp	SHORT L21D2

T_VEN0_016_2	LABEL	BYTE
	DB	'#VEN0\VEN0_016#They''re dead, Jim. All of them.',0
L21D2:
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
	DW	89,142, 95,142, 95,148, 89,148
	DW	21h, 4	; id, points
	DW	259,142, 265,142, 265,148, 259,148
	DW	22h, 4	; id, points
	DW	33,100, 39,100, 39,116, 33,116
	DW	23h, 4	; id, points
	DW	23,98, 39,100, 39,129, 23,135
	DW	24h, 4	; id, points
	DW	179,120, 270,120, 282,138, 179,138
	DW	25h, 4	; id, points
	DW	98,37, 222,37, 222,90, 98,90
	DW	26h, 4	; id, points
	DW	51,120, 142,120, 142,137, 41,137
	DW	26h, 4	; id, points
	DW	88,141, 97,141, 97,149, 88,149
	DW	27h, 4	; id, points
	DW	299,84, 319,78, 319,171, 299,160
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	2, 4	; id, points
	DW	288,161, 309,161, 318,169, 318,181
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's7r6',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Ensign_Kije	LABEL	BYTE
	DB	'Ensign Kije',0
N_computer	LABEL	BYTE
	DB	'computer',0
	DB	'wes',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
N_Elasi_Captain	LABEL	BYTE
	DB	'Elasi Captain',0
S_230E	LABEL	BYTE
	DB	0
T_VEN6N016	LABEL	BYTE
	DB	'#VEN6\VEN6N016#This is the emergency power input port for the fu'
	DB	'sion mixture regulator.',0
T_VEN6N018	LABEL	BYTE
	DB	'#VEN6\VEN6N018#This port is used to connect emergency power from'
	DB	' the impulse engines to other systems if dedicated lines are dam'
	DB	'aged.',0
T_VEN6_022	LABEL	BYTE
	DB	'#VEN6\VEN6_022#We should be able to, Captain, if we can find a s'
	DB	'uitable supply of power cable. We will need to route the power t'
	DB	'hrough a junction box so we can set an impedance level. A direct'
	DB	' connection to the regulator would cause an overload.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
