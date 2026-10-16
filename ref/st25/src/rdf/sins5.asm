; SINS5.RDF - "Sins of Omission", the operations centre of the Scythe
; base: two twin computers, Alpha and Omega, drive the missile launch
; computer. The virus-ridden Alpha unit has the wrong launch time; linked
; with the connector (room 3), the Omega unit's time wins and the
; missiles fall short of Proxtrey. The end of the mission.
;
; Actors: 8-10 (0Ah) phaser hits, 11 (0Bh) the connector cable.
; Objects: 20h the Alpha unit, 21h the Omega unit, 22h the launch
; computer, 23h the radiation door, 24h lights, 25h-28h missiles.
; Exit 1: room 4.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The point-once flags (mccoy_scan_point ... omega_use_point) are never
;   set, so those points come every time.
; - The conversation at 00DA is built at run time.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
computers_seen	EQU	RS_VARS+11h	; bits: Omega scanned 1, Alpha scanned 2, Omega used 4, Alpha used 8
connected	EQU	RS_VARS+12h	; the connector joins the two computers
connected2	EQU	RS_VARS+13h	; set with connected
seen_brain	EQU	RS_VARS+1Eh	; Spock has explained the room
mccoy_scan_point	EQU	RS_VARS+21h	; never set: the point is given every time
alpha_scan_point	EQU	RS_VARS+22h	; never set
omega_scan_point	EQU	RS_VARS+23h	; never set
alpha_use_point	EQU	RS_VARS+24h	; never set
omega_use_point	EQU	RS_VARS+25h	; never set
out_of_sync	EQU	RS_VARS+26h	; Mosher has spotted that the computers disagree
music_started	EQU	RS_VARS+28h
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
	DW	64h
rdf_scale_min	LABEL	BYTE
	DW	96h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	96h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, 4, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	0,0, 0,0	; entrance 0, crew 0
	DW	0,0, 0,0	; entrance 0, crew 1
	DW	0,0, 0,0	; entrance 0, crew 2
	DW	0,0, 0,0	; entrance 0, crew 3
	DW	142,163, 142,153	; entrance 1, crew 0
	DW	112,172, 112,162	; entrance 1, crew 1
	DW	187,174, 187,164	; entrance 1, crew 2
	DW	154,186, 154,176	; entrance 1, crew 3
	DW	0,0, 0,0	; entrance 2, crew 0
	DW	0,0, 0,0	; entrance 2, crew 1
	DW	0,0, 0,0	; entrance 2, crew 2
	DW	0,0, 0,0	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	142,163, 112,172, 187,174, 154,186	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	142,163, 112,172, 187,174, 154,186
; In the room file, so these start again each time the room loads
at_computers	LABEL	BYTE	; Kirk and Spock at the computers: 2
	DB	0
gathered	LABEL	BYTE	; crew members gathered to beam up: 4
	DB	0
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_mscans	LABEL	BYTE
	DB	'mscans',0
talk_buf	LABEL	BYTE
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
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
	mov	word ptr cs:talk_buf+4, 0
	mov	ax, OFFSET talk_buf
	call	Talk
	ret

N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Ensign_Mosher	LABEL	BYTE
	DB	'Ensign Mosher',0
	DB	'Lt. Uhura',0
N_Mr_Scott	LABEL	BYTE
	DB	'Mr. Scott',0
N_Computer	LABEL	BYTE
	DB	'Computer',0
rdf_objects	LABEL	BYTE
	DW	20h, 5	; id, points
	DW	199,140, 227,140, 237,175, 207,175, 199,163
	DW	21h, 5	; id, points
	DW	50,175, 59,140, 88,140, 88,163, 80,175
	DW	22h, 4	; id, points
	DW	123,134, 131,101, 155,101, 163,135
	DW	23h, 4	; id, points
	DW	125,43, 160,42, 160,77, 125,77
	DW	24h, 5	; id, points
	DW	0,0, 319,0, 174,41, 115,43, 0,13
	DW	25h, 4	; id, points
	DW	28,113, 89,113, 88,131, 28,128
	DW	26h, 4	; id, points
	DW	65,90, 109,90, 106,109, 67,110
	DW	27h, 4	; id, points
	DW	179,90, 219,90, 220,107, 180,108
	DW	28h, 4	; id, points
	DW	198,113, 259,113, 260,131, 199,129
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	1, 4	; id, points
	DW	86,199, 89,192, 195,192, 189,199
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's5b1',0
	DB	's5b2',0
	DB	's5b3',0
	DB	's5b4',0
	DB	's5b5',0
	DB	's5b6',0
	DB	's5b7',0
	DB	's5b8',0

rdf_scripts:
rdf_bans_end:
; The room starts: the connector if fitted. Until Spock's survey (tick 20)
; the party can't move.
H_0269:
	SCRIPT	MSG_TICK, 1, 0, 0, H_02E4
StartRoom:
	jmp	SHORT L027A

N_SIN5LOOP	LABEL	BYTE
	DB	'SIN5LOOP',0
L027A:
	push	OFFSET N_SIN5LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SIN5LOOP")
	add	sp, 4
	cmp	byte ptr [si+seen_brain], 0
	jne	L0293
	mov	byte ptr [si+RS_BUSY], 2
L0293:
	cmp	byte ptr [si+connected], 1
	jne	L02BD
	cmp	byte ptr [si+connected2], 1
	jne	L02BD
	jmp	SHORT L02A8

N_s5cabl	LABEL	BYTE
	DB	's5cabl',0
L02A8:
	push	0
	push	0
	push	0
	push	OFFSET N_s5cabl
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s5cabl", 0, 0, 0)
	add	sp, 0Ch
L02BD:
	cmp	byte ptr [si+music_started], 1
	je	L02D5
	push	-1
	push	0
	push	RC_MUSIC
	SERVICE		; Music(0, -1)
	add	sp, 6
	mov	byte ptr [si+music_started], 1
L02D5:
	push	-3
	push	1Bh
	push	RC_MUSIC
	SERVICE		; Music(27, -3)
	add	sp, 6
	retf

; Tricorders on the computers (+1 each, every time: the once-flags are
; never set).
H_02E4:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_0372
SpockScans:
	jmp	SHORT L02F3

N_sscans_2	LABEL	BYTE
	DB	'sscans',0
L02F3:
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
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN5_013
	call	Say
	jmp	SHORT L0371

T_SIN5_013	LABEL	BYTE
	DB	'#SIN5\SIN5_013#All three of the computers in this room are fully'
	DB	' operational.',0
L0371:
	retf

H_0372:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_0423
SpockScansAlpha:
	cmp	byte ptr [si+alpha_scan_point], 1
	je	L0382
	add	word ptr [si+score], 1
L0382:
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
	mov	bx, OFFSET T_SIN5_030
	call	Say
	jmp	SHORT L0416

T_SIN5_030	LABEL	BYTE
	DB	'#SIN5\SIN5_030#This computer is functional and performing an ave'
	DB	'rage 1.2 million operations per second.',0
L0416:
	mov	si, word ptr cs:rdf_state
	or	byte ptr [si+computers_seen], 2
	JMPN	L0DBD

	DB	0CBh

H_0423:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_04D4
SpockScansOmega:
	cmp	byte ptr [si+omega_scan_point], 1
	je	L0433
	add	word ptr [si+score], 1
L0433:
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
	mov	bx, OFFSET T_SIN5_029
	call	Say
	jmp	SHORT L04C7

T_SIN5_029	LABEL	BYTE
	DB	'#SIN5\SIN5_029#This computer is functional and performing an ave'
	DB	'rage .75 million operations per second.',0
L04C7:
	mov	si, word ptr cs:rdf_state
	or	byte ptr [si+computers_seen], 1
	JMPN	L0DBD

	DB	0CBh

H_04D4:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_05AD
SpockScansLauncher:
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
	mov	bx, OFFSET T_SIN5_028
	call	Say
	JMPN	L05AC

T_SIN5_028	LABEL	BYTE
	DB	'#SIN5\SIN5_028#This computer directly controls the missile launc'
	DB	'h system. There is no way to interface with it directly, but the'
	DB	' other two computers are accessible.',0
L05AC:
	retf

; The crew on the computers: only Spock can use them.
H_05AD:
	SCRIPT	MSG_USE, OBJ_KIRK, 20h, 0, H_0609
KirkOnAlpha:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN5_003
	call	Say
	jmp	SHORT L0606

T_SIN5_003	LABEL	BYTE
	DB	'#SIN5\SIN5_003#Mr. Spock, why don''t you take a look at those com'
	DB	'puters.',0
L0606:
	JMPN	SpockOnAlpha

H_0609:
	SCRIPT	MSG_USE, OBJ_KIRK, 21h, 0, H_0665
KirkOnOmega:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN5_004
	call	Say
	jmp	SHORT L0662

T_SIN5_004	LABEL	BYTE
	DB	'#SIN5\SIN5_004#Mr. Spock, why don''t you take a look at those com'
	DB	'puters.',0
L0662:
	JMPN	SpockOnOmega

H_0665:
	SCRIPT	MSG_USE, OBJ_KIRK, 22h, 0, H_06B6
KirkOnLauncher:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN5_001
	call	Say
	jmp	SHORT L06B5

T_SIN5_001	LABEL	BYTE
	DB	'#SIN5\SIN5_001#Hmmmm... This computer doesn''t have a keyboard.',0
L06B5:
	retf

H_06B6:
	SCRIPT	MSG_USE, OBJ_MCCOY, 20h, 0, H_06BE
	jmp	SHORT McCoyOnOmega

H_06BE:
	SCRIPT	MSG_USE, OBJ_MCCOY, 21h, 0, H_06C6
McCoyOnOmega:
	jmp	SHORT McCoyOnComputers

H_06C6:
	SCRIPT	MSG_USE, OBJ_MCCOY, 22h, 0, H_073E
McCoyOnComputers:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN5_015
	call	Say
	jmp	SHORT L073D

T_SIN5_015	LABEL	BYTE
	DB	'#SIN5\SIN5_015#Jim, I don''t know anything about these things! Wh'
	DB	'y don''t you ask your science officer.',0
L073D:
	retf

H_073E:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 20h, 0, H_0746
	jmp	SHORT MosherOnOmega

H_0746:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 21h, 0, H_074E
MosherOnOmega:
	jmp	SHORT MosherOnComputers

H_074E:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 22h, 0, H_07D2
MosherOnComputers:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN5_042
	call	Say
	jmp	SHORT L07D1

T_SIN5_042	LABEL	BYTE
	DB	'#SIN5\SIN5_042#Sir, I don''t think I''m qualified for that assignm'
	DB	'ent. Mr. Spock would be a better choice, I think.',0
L07D1:
	retf

H_07D2:
	SCRIPT	MSG_USE, OBJ_SPOCK, 22h, 0, H_084B
SpockOnLauncher:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN5_027
	call	Say
	jmp	SHORT L084A

T_SIN5_027	LABEL	BYTE
	DB	'#SIN5\SIN5_027#This computer cannot be accessed directly. It is '
	DB	'controlled by the other two computers.',0
L084A:
	retf

; Spock at the Alpha unit (msgs 11, 13) and the Omega unit (msgs 10, 12):
; their launch times. With the connector fitted, the Omega unit's timing
; takes over: the missiles will fall short of Proxtrey. Everyone gathers
; (msg 16), Scott beams them home: +19, BeamUp(score, 28, 0).
H_084B:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_0880
SpockOnAlpha:
	cmp	byte ptr [si+alpha_use_point], 1
	je	L085B
	add	word ptr [si+score], 1
L085B:
	mov	byte ptr [si+RS_FALL+1], 1
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0Bh
	push	ax
	mov	ax, 0B3h
	push	ax
	mov	ax, 0E1h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 225, 179, 11)
	add	sp, 0Ah
	retf

H_0880:
	SCRIPT	MSG_WALK_DONE, 0Bh, 0, 0, H_08A5
SpockAtAlpha:
	jmp	SHORT L088F

N_susemn	LABEL	BYTE
	DB	'susemn',0
L088F:
	push	0Dh
	push	-1
	push	-1
	push	OFFSET N_susemn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemn", -1, -1, 13)
	add	sp, 0Ch
	retf

H_08A5:
	SCRIPT	MSG_ANIM_DONE, 0Dh, 0, 0, H_0946
AlphaReports:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Computer
	mov	bx, OFFSET T_SIN5_039
	call	Say
	jmp	SHORT L0939

T_SIN5_039	LABEL	BYTE
	DB	'#SIN5\SIN5_039#Welcome to Scythe Operations Center, Alpha Unit. '
	DB	'Estimated time to optimal launch range is 3.21 hours adjusted.',0
L0939:
	mov	si, word ptr cs:rdf_state
	or	byte ptr [si+computers_seen], 8
	JMPN	L0DBD

	DB	0CBh

H_0946:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_097B
SpockOnOmega:
	cmp	byte ptr [si+omega_use_point], 1
	je	L0956
	add	word ptr [si+score], 1
L0956:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL+1], 1
	mov	ax, 0Ah
	push	ax
	mov	ax, 0B3h
	push	ax
	mov	ax, 40h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 64, 179, 10)
	add	sp, 0Ah
	retf

H_097B:
	SCRIPT	MSG_WALK_DONE, 0Ah, 0, 0, H_09A0
SpockAtOmega:
	jmp	SHORT L098A

N_susemn_2	LABEL	BYTE
	DB	'susemn',0
L098A:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_susemn_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemn", -1, -1, 12)
	add	sp, 0Ch
	retf

H_09A0:
	SCRIPT	MSG_ANIM_DONE, 0Ch, 0, 0, H_0BDE
OmegaReports:
	cmp	byte ptr [si+connected], 1
	je	L09AF
	JMPN	L0AD2

L09AF:
	cmp	byte ptr [si+connected2], 1
	je	L09B8
	JMPN	L0AD2

L09B8:
	mov	ax, OFFSET N_Computer
	mov	bx, OFFSET T_SIN5_041
	call	Say
	jmp	SHORT L0A42

T_SIN5_041	LABEL	BYTE
	DB	'#SIN5\SIN5_041#Welcome to Scythe Operations Center, Omega Unit. '
	DB	'Estimated time to optimal launch range is 1.54 hours adjusted.',0
L0A42:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN5_025
	call	Say
	JMPN	L0ACE

T_SIN5_025	LABEL	BYTE
	DB	'#SIN5\SIN5_025#The launched missiles will run out of fuel before'
	DB	' they reach Proxtrey. They will drift into the sun and burn up.',0
L0ACE:
	JMPN	L0B6D

	DB	0CBh
L0AD2:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Computer
	mov	bx, OFFSET T_SIN5_040
	call	Say
	jmp	SHORT L0B60

T_SIN5_040	LABEL	BYTE
	DB	'#SIN5\SIN5_040#Welcome to Scythe Operations Center, Omega Unit. '
	DB	'Estimated time to optimal launch range is 1.31 hours adjusted.',0
L0B60:
	mov	si, word ptr cs:rdf_state
	or	byte ptr [si+computers_seen], 4
	JMPN	L0DBD

	DB	0CBh
L0B6D:
	mov	ax, 10h
	push	ax
	mov	ax, 0B5h
	push	ax
	mov	ax, 8Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 140, 181, 16)
	add	sp, 0Ah
	mov	ax, 10h
	push	ax
	mov	ax, 0ABh
	push	ax
	mov	ax, 82h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 130, 171, 16)
	add	sp, 0Ah
	mov	ax, 10h
	push	ax
	mov	ax, 0ABh
	push	ax
	mov	ax, 96h
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 150, 171, 16)
	add	sp, 0Ah
	mov	ax, 10h
	push	ax
	mov	ax, 0A1h
	push	ax
	mov	ax, 91h
	push	ax
	mov	ax, 3
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(3, 145, 161, 16)
	add	sp, 0Ah
	retf

H_0BDE:
	SCRIPT	MSG_WALK_DONE, 10h, 0, 0, H_0CEE
CrewGathered:
	inc	byte ptr cs:gathered
	cmp	byte ptr cs:gathered, 4
	je	L0BF2
	retf

L0BF2:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN5_008
	call	Say
	jmp	SHORT L0C42

T_SIN5_008	LABEL	BYTE
	DB	'#SIN5\SIN5_008#Kirk to Enterprise. how are the transporters, Sco'
	DB	'tty?',0
L0C42:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_SIN5_S19
	call	Say
	jmp	SHORT L0CAB

T_SIN5_S19	LABEL	BYTE
	DB	'#SIN5\SIN5_S19#They''re operational again, Captain. We''re ready t'
	DB	'o bring you back at any time.',0
L0CAB:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN5_005
	call	Say
	jmp	SHORT L0CD4

T_SIN5_005	LABEL	BYTE
	DB	'#SIN5\SIN5_005#Bring us home.',0
L0CD4:
	add	word ptr [si+score], 13h
	push	0
	push	1Ch
	push	word ptr [si+score]
	push	RC_BEAMUP
	SERVICE		; BeamUp(?, 28, 0)
	add	sp, 8
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Tick 20: Spock explains the two isolated computers; once both have been
; scanned and used, Mosher notices they disagree.
H_0CEE:
	SCRIPT	MSG_TICK, 14h, 0, 0, H_114E
BrainOfScythe:
	cmp	byte ptr [si+seen_brain], 0
	je	L0CFD
	JMPN	L0DBC

L0CFD:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN5_026
	call	Say
	JMPN	L0DB8

T_SIN5_026	LABEL	BYTE
	DB	'#SIN5\SIN5_026#This appears to be the brain of Scythe. There are'
	DB	' two identical but isolated computers that communicate with a th'
	DB	'ird which controls the launch of missiles.',0
L0DB8:
	mov	byte ptr [si+seen_brain], 1
L0DBC:
	retf

L0DBD:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+computers_seen], 0Fh
	je	L0DC9
	retf

L0DC9:
	cmp	byte ptr [si+out_of_sync], 1
	jne	L0DD0
	retf

L0DD0:
	mov	byte ptr [si+out_of_sync], 1
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN5_044
	call	Say
	jmp	SHORT L0E4D

T_SIN5_044	LABEL	BYTE
	DB	'#SIN5\SIN5_044#Captain, something is wrong with the computers. T'
	DB	'hey may be twins, but they are not identical.',0
L0E4D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN5_036
	call	Say
	JMPN	L0EF8

T_SIN5_036	LABEL	BYTE
	DB	'#SIN5\SIN5_036#It appears they are out of sync, Captain. I have '
	DB	'to assume the Alpha Unit has a virus which is using up an incred'
	DB	'ible amount of computing time.',0
L0EF8:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN5_020
	call	Say
	jmp	SHORT L0F4E

T_SIN5_020	LABEL	BYTE
	DB	'#SIN5\SIN5_020#They report different optimum launch times. Which'
	DB	' is right?',0
L0F4E:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN5_035
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN5_006
	call	Say
	jmp	SHORT L0FB7

T_SIN5_006	LABEL	BYTE
	DB	'#SIN5\SIN5_006#Can you reprogram the Lucrs computer to give us t'
	DB	'hat time, Mr. Spock?',0
L0FB7:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN5_037
	call	Say
	jmp	SHORT L103E

T_SIN5_037	LABEL	BYTE
	DB	'#SIN5\SIN5_037#Reprogramming an old Alien computer is not simple'
	DB	', Captain. The odds against success are 10221 to 1 against.',0
L103E:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN5_021
	call	Say
	jmp	SHORT L10A2

T_SIN5_021	LABEL	BYTE
	DB	'#SIN5\SIN5_021#Too bad old Omega here couldn''t just take a sick '
	DB	'day and miss the firing.',0
L10A2:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN5_032
	call	Say
	jmp	SHORT L1113

T_SIN5_032	LABEL	BYTE
	DB	'#SIN5\SIN5_032#Because the two machines are isolated, the virus '
	DB	'did not spread from one to the other.',0
L1113:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN5_007
	call	Say
	jmp	SHORT L114D

T_SIN5_007	LABEL	BYTE
	DB	'#SIN5\SIN5_007#If we could only bridge them...',0
L114D:
	retf

; The connector between the computers (msgs 14, 15): connected.
H_114E:
	SCRIPT	MSG_USE, IT_CONECT, 21h, 0, H_1156
	jmp	SHORT ConnectorOnAlpha

H_1156:
	SCRIPT	MSG_USE, IT_CONECT, 20h, 0, H_1199
ConnectorOnAlpha:
	mov	ax, 0Eh
	push	ax
	mov	ax, 0ABh
	push	ax
	mov	ax, 60h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 96, 171, 14)
	add	sp, 0Ah
	mov	ax, 0Eh
	push	ax
	mov	ax, 0ABh
	push	ax
	mov	ax, 0BCh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 188, 171, 14)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

H_1199:
	SCRIPT	MSG_WALK_DONE, 0Eh, 0, 0, H_11EA
AtComputers:
	inc	byte ptr cs:at_computers
	cmp	byte ptr cs:at_computers, 2
	je	L11AD
	retf

L11AD:
	jmp	SHORT L11B6

N_suselw	LABEL	BYTE
	DB	'suselw',0
L11B6:
	push	0Fh
	push	-1
	push	-1
	push	OFFSET N_suselw
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "suselw", -1, -1, 15)
	add	sp, 0Ch
	jmp	SHORT L11D4

N_kusele	LABEL	BYTE
	DB	'kusele',0
L11D4:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusele
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusele", -1, -1, 0)
	add	sp, 0Ch
	retf

H_11EA:
	SCRIPT	MSG_ANIM_DONE, 0Fh, 0, 0, H_1275
ConnectorFitted:
	cmp	byte ptr [si+connected], 0
	jne	L1270
	mov	byte ptr [si+connected], 1
	mov	byte ptr [si+connected2], 1
	jmp	SHORT L1207

N_s5cabl_2	LABEL	BYTE
	DB	's5cabl',0
L1207:
	push	0
	push	0
	push	0
	push	OFFSET N_s5cabl_2
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s5cabl", 0, 0, 0)
	add	sp, 0Ch
	mov	ax, 0
	mov	bx, OFFSET T_SIN5N004
	call	Say
	jmp	SHORT L1256

T_SIN5N004	LABEL	BYTE
	DB	'#SIN5\SIN5N004#The connector snaps into place.',0
L1256:
	push	IT_CONECT
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_CONECT)
	add	sp, 4
	push	-1
	push	1Eh
	push	RC_MUSIC
	SERVICE		; Music(30, -1)
	add	sp, 6
L1270:
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Phasers on the computers (msgs 2-7, timers 0-2): the consoles explode
; and the defences kill the party (anim msg 1): game over.
H_1275:
	SCRIPT	MSG_USE, IT_PHASERS, 21h, 0, H_127D
	jmp	SHORT StunLauncher

H_127D:
	SCRIPT	MSG_USE, IT_PHASERS, 22h, 0, H_1285
StunLauncher:
	jmp	SHORT StunComputer

H_1285:
	SCRIPT	MSG_USE, IT_PHASERS, 20h, 0, H_12C8
StunComputer:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN5_043
	call	Say
	jmp	SHORT L12C7

T_SIN5_043	LABEL	BYTE
	DB	'#SIN5\SIN5_043#The stun setting won''t work, Sir!',0
L12C7:
	retf

H_12C8:
	SCRIPT	MSG_USE, IT_PHASERK, 21h, 0, H_12EF
KillOmega:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 2
	push	ax
	mov	ax, 0BCh
	push	ax
	mov	ax, 84h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 132, 188, 2)
	add	sp, 0Ah
	retf

H_12EF:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_1314
KirkAtOmega:
	jmp	SHORT L12FE

N_kdraww	LABEL	BYTE
	DB	'kdraww',0
L12FE:
	push	3
	push	-1
	push	-1
	push	OFFSET N_kdraww
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kdraww", -1, -1, 3)
	add	sp, 0Ch
	retf

H_1314:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_1353
OmegaHit:
	jmp	SHORT L1323

N_s5phal	LABEL	BYTE
	DB	's5phal',0
L1323:
	push	1
	push	0AFh
	push	0
	push	OFFSET N_s5phal
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s5phal", 0, 175, 1)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	mov	word ptr [si+RS_TIMERS+6], 0Ah
	mov	word ptr [si+RS_TIMERS], 18h
	retf

H_1353:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_1372
Timer0Done:
	mov	byte ptr [si+RS_FALL], 3
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_1372:
	SCRIPT	MSG_USE, IT_PHASERK, 22h, 0, H_1399
KillLauncher:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 6
	push	ax
	mov	ax, 0BCh
	push	ax
	mov	ax, 8Bh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 139, 188, 6)
	add	sp, 0Ah
	retf

H_1399:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_13BE
KirkAtLauncher:
	jmp	SHORT L13A8

N_kfiren	LABEL	BYTE
	DB	'kfiren',0
L13A8:
	push	7
	push	-1
	push	-1
	push	OFFSET N_kfiren
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kfiren", -1, -1, 7)
	add	sp, 0Ch
	retf

H_13BE:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_13FE
LauncherHit:
	jmp	SHORT L13CD

N_s5phac	LABEL	BYTE
	DB	's5phac',0
L13CD:
	push	1
	push	8Ch
	push	0
	push	OFFSET N_s5phac
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s5phac", 0, 140, 1)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	mov	word ptr [si+RS_TIMERS+6], 0Ah
	mov	word ptr [si+RS_TIMERS+2], 18h
	retf

H_13FE:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_141D
Timer1Done:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_141D:
	SCRIPT	MSG_USE, IT_PHASERK, 20h, 0, H_1444
KillAlpha:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 4
	push	ax
	mov	ax, 0BCh
	push	ax
	mov	ax, 9Eh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 158, 188, 4)
	add	sp, 0Ah
	retf

H_1444:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_1469
KirkAtAlpha:
	jmp	SHORT L1453

N_kdrawe	LABEL	BYTE
	DB	'kdrawe',0
L1453:
	push	5
	push	-1
	push	-1
	push	OFFSET N_kdrawe
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kdrawe", -1, -1, 5)
	add	sp, 0Ch
	retf

H_1469:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_14A9
AlphaHit:
	jmp	SHORT L1478

N_s5phar	LABEL	BYTE
	DB	's5phar',0
L1478:
	push	1
	push	0AFh
	push	0
	push	OFFSET N_s5phar
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s5phar", 0, 175, 1)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	mov	word ptr [si+RS_TIMERS+6], 0Ah
	mov	word ptr [si+RS_TIMERS+4], 18h
	retf

H_14A9:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_14C8
Timer2Done:
	mov	byte ptr [si+RS_FALL], 2
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_14C8:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_161F
DefencesTriggered:
	push	-1
	push	2
	push	RC_MUSIC
	SERVICE		; Music(2, -1)
	add	sp, 6
	mov	ax, 0
	mov	bx, OFFSET T_SIN5N012
	call	Say
	JMPN	L15C0

T_SIN5N012	LABEL	BYTE
	DB	'#SIN5\SIN5N012#Computer consoles do not take well to phasering. '
	DB	'Sparks explode and, in a defensive maneuver prompted by this att'
	DB	'ack from within, the base launches a full spread of nuclear miss'
	DB	'iles at the Enterprise.',0
L15C0:
	mov	ax, 0
	mov	bx, OFFSET T_SIN5N013
	call	Say
	jmp	SHORT L1612

T_SIN5N013	LABEL	BYTE
	DB	'#SIN5\SIN5N013#History will not be kind to you. Better luck next'
	DB	' time.',0
L1612:
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
	retf

H_161F:
	SCRIPT	MSG_TIMER, 3, 0, 0, H_1770
Timer3Sound:
	mov	ax, 14h
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(20)
	add	sp, 4
	retf

	DB	0B8h, 2Eh, 1, 0BBh, 41h, 16h, 0E8h, 0CDh, 0EAh, 0EBh
	DB	'o#SIN5\SIN5_022#Unbelievable, isn''t it? Putting this much time a'
	DB	'nd effort into building devices to kill people.',0
	DB	0B8h, 38h, 1, 0BBh, 0BBh, 16h, 0E8h, 53h, 0EAh, 0EBh
	DB	'a#SIN5\SIN5_031#A great waste, doctor. A technologically advance'
	DB	'd society, an advanced culture...',0
	DB	0B8h, 23h, 1, 0BBh, 27h, 17h, 0E8h, 0E7h, 0E9h, 0EBh
	DB	'H#SIN5\SIN5_009#Let''s just find a way to stop this from happenin'
	DB	'g again.',0
	DB	0CBh

; Looking and talking.
H_1770:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_17E0
LookAtScene:
	mov	ax, 0
	mov	bx, OFFSET T_SIN5N005
	call	Say
	jmp	SHORT L17DF

T_SIN5N005	LABEL	BYTE
	DB	'#SIN5\SIN5N005#The control center for the base. Computers and nu'
	DB	'clear missiles fill the room.',0
L17DF:
	retf

H_17E0:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_186B
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_SIN5N000
	call	Say
	jmp	SHORT L186A

T_SIN5N000	LABEL	BYTE
	DB	'#SIN5\SIN5N000#Captain James T. Kirk, fingering his communicator'
	DB	', wonders if anything else is happening aboard his ship.',0
L186A:
	retf

H_186B:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_18D4
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_SIN5N006
	call	Say
	jmp	SHORT L18D3

T_SIN5N006	LABEL	BYTE
	DB	'#SIN5\SIN5N006#These instruments of war make Spock uncomfortable'
	DB	', but he says nothing.',0
L18D3:
	retf

H_18D4:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_192D
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_SIN5N001
	call	Say
	jmp	SHORT L192C

T_SIN5N001	LABEL	BYTE
	DB	'#SIN5\SIN5N001#Dr. McCoy takes several deep sighs and closes his'
	DB	' eyes.',0
L192C:
	retf

H_192D:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_196B
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_SIN5N002
	call	Say
	jmp	SHORT L196A

T_SIN5N002	LABEL	BYTE
	DB	'#SIN5\SIN5N002#Ensign Mosher awaits orders.',0
L196A:
	retf

H_196B:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_19C0
LookAtLights:
	mov	ax, 0
	mov	bx, OFFSET T_SIN5N007
	call	Say
	jmp	SHORT L19BF

T_SIN5N007	LABEL	BYTE
	DB	'#SIN5\SIN5N007#These lights are still operational after centurie'
	DB	's.',0
L19BF:
	retf

H_19C0:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_1A24
LookAtOmega:
	mov	ax, 0
	mov	bx, OFFSET T_SIN5N010
	call	Say
	jmp	SHORT L1A23

T_SIN5N010	LABEL	BYTE
	DB	'#SIN5\SIN5N010#This computer is marked with the last letter of t'
	DB	'he Lucr alphabet.',0
L1A23:
	retf

H_1A24:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_1AA6
LookAtLauncher:
	mov	ax, 0
	mov	bx, OFFSET T_SIN5N008
	call	Say
	jmp	SHORT L1AA5

T_SIN5N008	LABEL	BYTE
	DB	'#SIN5\SIN5N008#This computer controls the launch of missiles. It'
	DB	' is directly controlled by the other computers.',0
L1AA5:
	retf

H_1AA6:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_1B0B
LookAtAlpha:
	mov	ax, 0
	mov	bx, OFFSET T_SIN5N009
	call	Say
	jmp	SHORT L1B0A

T_SIN5N009	LABEL	BYTE
	DB	'#SIN5\SIN5N009#This computer is marked with the first letter of '
	DB	'the Lucr alphabet.',0
L1B0A:
	retf

H_1B0B:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_1B13
	jmp	SHORT LookAtMissiles

H_1B13:
	SCRIPT	MSG_LOOK, 26h, 0, 0, H_1B1B
	jmp	SHORT LookAtMissiles

H_1B1B:
	SCRIPT	MSG_LOOK, 27h, 0, 0, H_1B23
	jmp	SHORT LookAtMissiles

H_1B23:
	SCRIPT	MSG_LOOK, 28h, 0, 0, H_1BA3
LookAtMissiles:
	mov	ax, 0
	mov	bx, OFFSET T_SIN5N003
	call	Say
	jmp	SHORT L1BA2

T_SIN5N003	LABEL	BYTE
	DB	'#SIN5\SIN5N003#Missiles of death and destruction. The Lucr belie'
	DB	'ved that you could never have enough of them.',0
L1BA2:
	retf

H_1BA3:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_1BF8
LookAtHazardDoor:
	mov	ax, 0
	mov	bx, OFFSET T_SIN5N011
	call	Say
	jmp	SHORT L1BF7

T_SIN5N011	LABEL	BYTE
	DB	'#SIN5\SIN5N011#This door is marked with a radiation hazard symbo'
	DB	'l.',0
L1BF7:
	retf

H_1BF8:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_KIRK, 0, H_1C00
	jmp	SHORT MedkitOnSpock

H_1C00:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_SPOCK, 0, H_1C08
MedkitOnSpock:
	jmp	SHORT MedkitOnMcCoy

H_1C08:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_MCCOY, 0, H_1C10
MedkitOnMcCoy:
	jmp	SHORT MedkitOnRedshirt

H_1C10:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_REDSHIRT, 0, H_1C5C
MedkitOnRedshirt:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN5_017
	call	Say
	jmp	SHORT L1C5B

T_SIN5_017	LABEL	BYTE
	DB	'#SIN5\SIN5_017#We''re safe from the cosmic radiation, Jim.',0
L1C5B:
	retf

H_1C5C:
	SCRIPT	MSG_USE, IT_MTRICOR, ANY, 0, H_1D08
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
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN5_016
	call	Say
	jmp	SHORT L1CFD

T_SIN5_016	LABEL	BYTE
	DB	'#SIN5\SIN5_016#Thank goodness. I was worried that there might be'
	DB	' a radiation leak, but there''s no sign of any.',0
L1CFD:
	cmp	byte ptr [si+mccoy_scan_point], 1
	je	L1D07
	add	word ptr [si+score], 1
L1D07:
	retf

H_1D08:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_1D58
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN5_002
	call	Say
	jmp	SHORT L1D57

T_SIN5_002	LABEL	BYTE
	DB	'#SIN5\SIN5_002#I don''t have anything to say right now, Bones.',0
L1D57:
	retf

H_1D58:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_1EE3
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN5_038
	call	Say
	jmp	SHORT L1DBA

T_SIN5_038	LABEL	BYTE
	DB	'#SIN5\SIN5_038#These warheads are not a very efficient delivery '
	DB	'system, Captain.',0
L1DBA:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN5_023
	call	Say
	jmp	SHORT L1E1F

T_SIN5_023	LABEL	BYTE
	DB	'#SIN5\SIN5_023#Who needs efficiency, when the end of the world i'
	DB	's everywhere around here!',0
L1E1F:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN5_033
	call	Say
	jmp	SHORT L1E7F

T_SIN5_033	LABEL	BYTE
	DB	'#SIN5\SIN5_033#Curb your emotions, doctor. They serve no constru'
	DB	'ctive purpose here. ',0
L1E7F:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN5_019
	call	Say
	jmp	SHORT L1EE2

T_SIN5_019	LABEL	BYTE
	DB	'#SIN5\SIN5_019#There''s nothing constructive about this place, Sp'
	DB	'ock! It''s an obscenity!',0
L1EE2:
	retf

H_1EE3:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_1F9B
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN5_018
	call	Say
	jmp	SHORT L1F25

T_SIN5_018	LABEL	BYTE
	DB	'#SIN5\SIN5_018#I wish I hadn''t seen any of this.',0
L1F25:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN5_010
	call	Say
	jmp	SHORT L1F9A

T_SIN5_010	LABEL	BYTE
	DB	'#SIN5\SIN5_010#Sometimes it''s useful to confront the dark side o'
	DB	'f our nature, that which we might become.',0
L1F9A:
	retf

H_1F9B:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_213E
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN5_046
	call	Say
	jmp	SHORT L2018

T_SIN5_046	LABEL	BYTE
	DB	'#SIN5\SIN5_046#No intruders, Captain. I think everyone died a lo'
	DB	'ng, long time ago. I wonder what caused it.',0
L2018:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN5_034
	call	Say
	JMPN	L20D7

T_SIN5_034	LABEL	BYTE
	DB	'#SIN5\SIN5_034#For people with emotions, Ensign, there are many '
	DB	'things that can cause hatreds. And each new hatred breeds more h'
	DB	'atred, and makes the path of peace harder to find.',0
L20D7:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN5_045
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN5_011
	call	Say
	jmp	SHORT L213D

T_SIN5_011	LABEL	BYTE
	DB	'#SIN5\SIN5_011#Well, gentlemen. Here''s one fire we can put out. '
	DB	'Let''s go to work.',0
L213D:
	retf

; Tricorders and the medkit.
H_213E:
	SCRIPT	MSG_USE, IT_STRICOR, 25h, 0, H_2146
	jmp	SHORT SpockScansMissiles

H_2146:
	SCRIPT	MSG_USE, IT_STRICOR, 26h, 0, H_214E
	jmp	SHORT SpockScansMissiles

H_214E:
	SCRIPT	MSG_USE, IT_STRICOR, 27h, 0, H_2156
	jmp	SHORT SpockScansMissiles

H_2156:
	SCRIPT	MSG_USE, IT_STRICOR, 28h, 0, H_21FF
SpockScansMissiles:
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
	mov	bx, OFFSET T_SIN5_012
	call	Say
	jmp	SHORT L21FE

T_SIN5_012	LABEL	BYTE
	DB	'#SIN5\SIN5_012#A crude Uranium 235 nuclear device with Lithium -'
	DB	' Beryllium shells to increase heavy particle fallout.',0
L21FE:
	retf

H_21FF:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_22B4
SpockScansHazardDoor:
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
	mov	bx, OFFSET T_SIN5_024
	call	Say
	JMPN	L22B3

T_SIN5_024	LABEL	BYTE
	DB	'#SIN5\SIN5_024#Readings indicate an extremely high radiation lev'
	DB	'el beyond those doors. It would be fatal to proceed beyond them.',0
L22B3:
	retf

H_22B4:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_KIRK, 0, H_22BC
	jmp	SHORT McCoyScansRedshirt

H_22BC:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_SPOCK, 0, H_22C4
	jmp	SHORT McCoyScansRedshirt

H_22C4:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_MCCOY, 0, H_22CC
	jmp	SHORT McCoyScansRedshirt

H_22CC:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_REDSHIRT, 0, T_SIN5_035
McCoyScansRedshirt:
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
	mov	bx, OFFSET T_SIN5_014
	call	Say
	jmp	SHORT L2364

T_SIN5_014	LABEL	BYTE
	DB	'#SIN5\SIN5_014#All readings are normal. The structure seems to b'
	DB	'e protecting us from the cosmic rays.',0
L2364:
	retf

rdf_scripts_end	LABEL	BYTE
T_SIN5_035	LABEL	BYTE
	DB	'#SIN5\SIN5_035#Given the elliptical orbit and the range at which'
	DB	' they will pass Proxtrey, the Omega unit is correct, but the win'
	DB	'dow is very narrow. A variation of minutes will mean the missile'
	DB	's run out of fuel and fall harmlessly into the sun.',0
T_SIN5_045	LABEL	BYTE
	DB	'#SIN5\SIN5_045#It''s easy to say when you''re not involved persona'
	DB	'lly, Mr. Spock. But when people have treated you like a second c'
	DB	'lass being because you are different, hate can become the only t'
	DB	'hing they can''t take away from you. That is what started most of'
	DB	' the firestorms of history.',0

RDF	ENDS
	END
