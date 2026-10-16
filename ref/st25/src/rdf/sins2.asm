; SINS2.RDF - "Sins of Omission", the airlock between the two doors of
; the Lucrs' Scythe missile base. Its terminal tells the base's history;
; the inner door's keypad wants a code in base three.
;
; Actors: 8 the inner door.
; Objects: 8 the chamber beyond, 20h the terminal, 21h the door, 22h the
; keypad. Exits: 0 room 4, 1 room 1.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The conversation at 00D8 is built at run time.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
read_history	EQU	RS_VARS+0Ch	; the points for the terminal
door_open2	EQU	RS_VARS+15h	; the inner door is open
virus_found	EQU	RS_VARS+1Bh	; Uhura has traced the virus
virus_cured	EQU	RS_VARS+1Dh	; Uhura has destroyed the virus (room 4)
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
	DW	32h
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
	DW	4, 1, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	150,160, 135,175	; entrance 0, crew 0
	DW	160,160, 175,175	; entrance 0, crew 1
	DW	150,152, 140,165	; entrance 0, crew 2
	DW	160,152, 170,165	; entrance 0, crew 3
	DW	150,190, 145,175	; entrance 1, crew 0
	DW	160,190, 165,175	; entrance 1, crew 1
	DW	150,199, 140,185	; entrance 1, crew 2
	DW	160,199, 170,185	; entrance 1, crew 3
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
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_mscans	LABEL	BYTE
	DB	'mscans',0
talk_buf	LABEL	BYTE
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
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
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
N_Mr_Scott	LABEL	BYTE
	DB	'Mr. Scott',0
rdf_objects	LABEL	BYTE
	DW	20h, 4	; id, points
	DW	53,124, 75,120, 83,129, 63,135
	DW	21h, 6	; id, points
	DW	103,151, 103,54, 116,42, 196,42, 208,55, 208,151
	DW	22h, 4	; id, points
	DW	210,88, 222,88, 222,108, 210,108
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	0, 4	; id, points
	DW	129,145, 120,135, 192,135, 183,145
	DW	1, 4	; id, points
	DW	53,199, 63,194, 251,194, 259,199
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's2b1',0
	DB	's2b2',0
	DB	's2b3',0
	DB	's2b4',0
	DB	's2b5',0
	DB	's2b6',0

rdf_scripts:
rdf_bans_end:
; The room starts: the inner door. Until Uhura's call (tick 40) the
; party can't move.
H_01F8:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0285
StartRoom:
	jmp	SHORT L0209

N_SIN2LOOP	LABEL	BYTE
	DB	'SIN2LOOP',0
L0209:
	push	OFFSET N_SIN2LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SIN2LOOP")
	add	sp, 4
	push	-3
	push	1Bh
	push	RC_MUSIC
	SERVICE		; Music(27, -3)
	add	sp, 6
	cmp	byte ptr [si+virus_found], 0
	jne	L0230
	mov	byte ptr [si+RS_BUSY], 2
L0230:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+door_open2], 1
	jne	L026F
	jmp	SHORT L0243

N_s2dro	LABEL	BYTE
	DB	's2dro',0
L0243:
	push	1
	push	0
	push	0
	push	OFFSET N_s2dro
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s2dro", 0, 0, 1)
	add	sp, 0Ch
	jmp	SHORT L0261

N_sins22	LABEL	BYTE
	DB	'sins22',0
L0261:
	push	OFFSET N_sins22
	push	RC_LOADMAP
	SERVICE		; LoadMap("sins22")
	add	sp, 4
	retf

L026F:
	jmp	SHORT L0277

N_sins2	LABEL	BYTE
	DB	'sins2',0
L0277:
	push	OFFSET N_sins2
	push	RC_LOADMAP
	SERVICE		; LoadMap("sins2")
	add	sp, 4
	retf

; Phasers and tricorders.
H_0285:
	SCRIPT	MSG_USE, IT_PHASERK, 21h, 0, H_028D
	jmp	SHORT PhaserDoor

H_028D:
	SCRIPT	MSG_USE, IT_PHASERS, 21h, 0, H_02E3
PhaserDoor:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_025
	call	Say
	jmp	SHORT L02E2

T_SIN2_025	LABEL	BYTE
	DB	'#SIN2\SIN2_025#The door will easily withstand our phasers, Capta'
	DB	'in.',0
L02E2:
	retf

H_02E3:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_036B
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
	mov	bx, OFFSET T_SIN2_026
	call	Say
	jmp	SHORT L036A

T_SIN2_026	LABEL	BYTE
	DB	'#SIN2\SIN2_026#The interior of the security lock is unremarkable'
	DB	' and well preserved.',0
L036A:
	retf

; The terminal: Spock reads it (msgs 5, 6, +2 once): the Lucrs' Scythe
; base, a thousand years old, has woken and is about to attack Proxtrey.
H_036B:
	SCRIPT	MSG_USE, OBJ_KIRK, 20h, 0, H_03B3
KirkOnTerminal:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN2_002
	call	Say
	jmp	SHORT L03B1

T_SIN2_002	LABEL	BYTE
	DB	'#SIN2\SIN2_002#Spock, see what you can do with this.',0
L03B1:
	jmp	SHORT SpockOnTerminal

H_03B3:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_03DA
SpockOnTerminal:
	mov	byte ptr [si+RS_FALL+1], 3
	mov	ax, 5
	push	ax
	mov	ax, 0A7h
	push	ax
	mov	ax, 5Fh
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 95, 167, 5)
	add	sp, 0Ah
	retf

H_03DA:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_0417
SpockAtTerminal:
	jmp	SHORT L03E9

N_EFX14S	LABEL	BYTE
	DB	'EFX14S',0
L03E9:
	push	OFFSET N_EFX14S
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EFX14S")
	add	sp, 4
	jmp	SHORT L0401

N_susehw	LABEL	BYTE
	DB	'susehw',0
L0401:
	push	6
	push	-1
	push	-1
	push	OFFSET N_susehw
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susehw", -1, -1, 6)
	add	sp, 0Ch
	retf

H_0417:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_0DA9
BaseHistory:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_042
	call	Say
	jmp	SHORT L045B

T_SIN2_042	LABEL	BYTE
	DB	'#SIN2\SIN2_042#The console reports the following: ',0
L045B:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_044
	call	Say
	JMPN	L052B

T_SIN2_044	LABEL	BYTE
	DB	'#SIN2\SIN2_044#Welcome to Orbital Missile Base. Codename: Scythe'
	DB	'. This base has been operational for the past week. It has compl'
	DB	'eted 1 successful fire mission. Estimation of success is at 22/1'
	DB	'00.',0
L052B:
	cmp	byte ptr [si+read_history], 1
	je	L053E
	add	word ptr [si+score], 2
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+read_history], 1
L053E:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN2_015
	call	Say
	jmp	SHORT L0590

T_SIN2_015	LABEL	BYTE
	DB	'#SIN2\SIN2_015#22%? That''s very low -- hardly something to brag '
	DB	'about.',0
L0590:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_032
	call	Say
	JMPN	L065C

T_SIN2_032	LABEL	BYTE
	DB	'#SIN2\SIN2_032#Doctor, in base 3, 22/100 is equivalent to 8 out '
	DB	'of 9 or 88%. I would think that quite satisfactory given this ba'
	DB	'se''s probable mission of destroying the Sof forces on Proxtrey.',0
L065C:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN2_050
	call	Say
	jmp	SHORT L06D5

T_SIN2_050	LABEL	BYTE
	DB	'#SIN2\SIN2_050#It says the base has been operational for a week,'
	DB	' but this has been here for a thousand years.',0
L06D5:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_035
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_043
	call	Say
	JMPN	L07AA

T_SIN2_043	LABEL	BYTE
	DB	'#SIN2\SIN2_043#There is a substantial amount of data here, but i'
	DB	'n summary, Scythe was created by the Lucrs as a launching platfo'
	DB	'rm for missiles to keep the Sofs subjugated to their influence.',0
L07AA:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_041
	call	Say
	JMPN	L086F

T_SIN2_041	LABEL	BYTE
	DB	'#SIN2\SIN2_041#The Sofs managed to infiltrate the base. however,'
	DB	' their actions triggered Scythe''s auto-attack mechanisms, and in'
	DB	'itiated a holocaust that nearly annihilated the planet. ',0
L086F:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_040
	call	Say
	jmp	SHORT L08F4

T_SIN2_040	LABEL	BYTE
	DB	'#SIN2\SIN2_040#One Sof strike did, in fact, hit the moon and def'
	DB	'lected it from its orbit. It has been dormant since then.',0
L08F4:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN2_021
	call	Say
	jmp	SHORT L0938

T_SIN2_021	LABEL	BYTE
	DB	'#SIN2\SIN2_021#So why has the base been activated again?',0
L0938:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_034
	call	Say
	JMPN	L0A0F

T_SIN2_034	LABEL	BYTE
	DB	'#SIN2\SIN2_034#Given the damage to the moon, its slow rotation a'
	DB	'nd orbit, it has never realized the war is over. On this pass, f'
	DB	'or the first time, it has detected radio-wave transmissions from'
	DB	' Proxtrey.',0
L0A0F:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_031
	call	Say
	jmp	SHORT L0A73

T_SIN2_031	LABEL	BYTE
	DB	'#SIN2\SIN2_031#Because it does not recognize them, it assumes th'
	DB	'e Sofs are still active.',0
L0A73:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_038
	call	Say
	JMPN	L0B08

T_SIN2_038	LABEL	BYTE
	DB	'#SIN2\SIN2_038#Its transmission to the planet, I would assume, w'
	DB	'as some sort of a check beacon to see if it should continue its '
	DB	'mission.',0
L0B08:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN2_020
	call	Say
	jmp	SHORT L0B6D

T_SIN2_020	LABEL	BYTE
	DB	'#SIN2\SIN2_020#Jim, let''s return to the ship and blast this plac'
	DB	'e to destroy its weapons.',0
L0B6D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_033
	call	Say
	jmp	SHORT L0BF2

T_SIN2_033	LABEL	BYTE
	DB	'#SIN2\SIN2_033#Doctor, this moon is a god to the people down the'
	DB	're. If we destroy it we will violate the Prime Directive.',0
L0BF2:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN2_007
	call	Say
	JMPN	L0C88

T_SIN2_007	LABEL	BYTE
	DB	'#SIN2\SIN2_007#Spock is right, Bones. Spock, what are the chance'
	DB	's that we could decode the transmission and send a stop code to '
	DB	'the base?',0
L0C88:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_037
	call	Say
	jmp	SHORT L0CB9

T_SIN2_037	LABEL	BYTE
	DB	'#SIN2\SIN2_037#In Trinary or Decimal?',0
L0CB9:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN2_022
	call	Say
	jmp	SHORT L0CDA

T_SIN2_022	LABEL	BYTE
	DB	'#SIN2\SIN2_022#Spock!',0
L0CDA:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_029
	call	Say
	JMPN	L0DA8

T_SIN2_029	LABEL	BYTE
	DB	'#SIN2\SIN2_029#1.327 million to one, provided the archaeological'
	DB	' studies about Lucrs languages are correct. Our other option is '
	DB	'to get into this base and see if we can bring the computers down'
	DB	'.',0
L0DA8:
	retf

; The others on the terminal.
H_0DA9:
	SCRIPT	MSG_USE, OBJ_MCCOY, 20h, 0, H_0E0E
McCoyOnTerminal:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN2_012
	call	Say
	jmp	SHORT L0E0D

T_SIN2_012	LABEL	BYTE
	DB	'#SIN2\SIN2_012#Damn it Jim, I''m a surgeon not a alien computer s'
	DB	'cience specialist.',0
L0E0D:
	retf

H_0E0E:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 20h, 0, H_0E7B
MosherOnTerminal:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN2_045
	call	Say
	jmp	SHORT L0E7A

T_SIN2_045	LABEL	BYTE
	DB	'#SIN2\SIN2_045#I think Mr. Spock would have a better idea of how'
	DB	' to operate that, Captain.',0
L0E7A:
	retf

; Tricorders.
H_0E7B:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_0F1E
SpockScansTerminal:
	jmp	SHORT L0E8A

N_sscanw	LABEL	BYTE
	DB	'sscanw',0
L0E8A:
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
	mov	bx, OFFSET T_SIN2_009
	call	Say
	jmp	SHORT L0F1D

T_SIN2_009	LABEL	BYTE
	DB	'#SIN2\SIN2_009#A computer terminal, Captain. It uses the lucr al'
	DB	'phabet. I think I can decipher it.',0
L0F1D:
	retf

H_0F1E:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_0FC5
SpockScansKeypad:
	jmp	SHORT L0F2D

N_sscann	LABEL	BYTE
	DB	'sscann',0
L0F2D:
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
	mov	bx, OFFSET T_SIN2_028
	call	Say
	jmp	SHORT L0FC4

T_SIN2_028	LABEL	BYTE
	DB	'#SIN2\SIN2_028#This keypad is fully functional and controls the '
	DB	'door. Its entry code is in base three.',0
L0FC4:
	retf

H_0FC5:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_10CD
SpockScansDoor:
	jmp	SHORT L0FD4

N_sscann_2	LABEL	BYTE
	DB	'sscann',0
L0FD4:
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
	mov	bx, OFFSET T_SIN2_027
	call	Say
	JMPN	L10CC

T_SIN2_027	LABEL	BYTE
	DB	'#SIN2\SIN2_027#This door is similar to the one on the outside of'
	DB	' the securelock except that it has not weathered over the years.'
	DB	' Electrical panels indicate the keypad on the right controls the'
	DB	' door.',0
L10CC:
	retf

; The keypad: Spock enters the code typed (msg 2): "122" opens the
; inner door (anim msgs 3, 1); anything else fails (msg 4).
H_10CD:
	SCRIPT	MSG_USE, OBJ_KIRK, 22h, 0, H_1121
KirkOnKeypad:
	cmp	byte ptr [si+door_open2], 1
	je	L1120
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN2_001
	call	Say
	jmp	SHORT L111E

T_SIN2_001	LABEL	BYTE
	DB	'#SIN2\SIN2_001#Spock, see what you can do with that lock.',0
L111E:
	jmp	SHORT SpockOnKeypad

L1120:
	retf

H_1121:
	SCRIPT	MSG_USE, OBJ_SPOCK, 22h, 0, H_114F
SpockOnKeypad:
	cmp	byte ptr [si+door_open2], 0
	jne	L1149
	mov	ax, 2
	push	ax
	mov	ax, 9Bh
	push	ax
	mov	ax, 0C3h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 195, 155, 2)
	add	sp, 0Ah
L1149:
	retf

N_122	LABEL	BYTE
	DB	'122',0
	DB	0

H_114F:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_11A5
EnterCode:
	mov	ax, OFFSET N_122
	push	ax
	mov	ax, RC_INPUTCODE
	push	ax
	SERVICE		; InputCode("122")
	add	sp, 4
	AX8	cmp, 1
	je	L116D
	JMPN	L1203

L116D:
	jmp	SHORT L1176

N_EFX28S	LABEL	BYTE
	DB	'EFX28S',0
L1176:
	push	OFFSET N_EFX28S
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EFX28S")
	add	sp, 4
	jmp	SHORT L118E

N_susehe	LABEL	BYTE
	DB	'susehe',0
L118E:
	push	3
	push	-1
	push	-1
	push	OFFSET N_susehe
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susehe", -1, -1, 3)
	add	sp, 0Ch
	retf

	DB	0CBh

H_11A5:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_123A
DoorOpens:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+door_open2], 1
	jmp	SHORT L11BD

N_sins22_2	LABEL	BYTE
	DB	'sins22',0
L11BD:
	push	OFFSET N_sins22_2
	push	RC_LOADMAP
	SERVICE		; LoadMap("sins22")
	add	sp, 4
	jmp	SHORT L11D5

N_BIGDOOR3	LABEL	BYTE
	DB	'BIGDOOR3',0
L11D5:
	push	OFFSET N_BIGDOOR3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("BIGDOOR3")
	add	sp, 4
	jmp	SHORT L11ED

N_s2door	LABEL	BYTE
	DB	's2door',0
L11ED:
	push	1
	push	0
	push	0
	push	OFFSET N_s2door
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s2door", 0, 0, 1)
	add	sp, 0Ch
	retf

L1203:
	jmp	SHORT L120C

N_EFX28S_2	LABEL	BYTE
	DB	'EFX28S',0
L120C:
	push	OFFSET N_EFX28S_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EFX28S")
	add	sp, 4
	jmp	SHORT L1224

N_susehe_2	LABEL	BYTE
	DB	'susehe',0
L1224:
	push	4
	push	-1
	push	-1
	push	OFFSET N_susehe_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susehe", -1, -1, 4)
	add	sp, 0Ch
	retf

H_123A:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_12B9
WrongCode:
	mov	ax, 0
	mov	bx, OFFSET T_SIN2_024
	call	Say
	jmp	SHORT L12B8

T_SIN2_024	LABEL	BYTE
	DB	'#SIN2\SIN2_024#That did not work, Captain. It is probable this l'
	DB	'ock also uses a number of some significance.',0
L12B8:
	retf

H_12B9:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_139E
DoorOpened:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_010
	call	Say
	JMPN	L139D

T_SIN2_010	LABEL	BYTE
	DB	'#SIN2\SIN2_010#Fascinating. If the Federation language studies w'
	DB	'ere correct, the ideograph for the word "Scythe" in the Lucrs la'
	DB	'nguage is the 17th symbol in their alphabet. That corresponds wi'
	DB	'th 122 in base 3.',0
L139D:
	retf

; Tick 40, once: Uhura has traced the virus to the moon's computers.
H_139E:
	SCRIPT	MSG_TICK, 28h, 0, 0, H_172B
UhuraFindsVirus:
	cmp	byte ptr [si+virus_found], 0
	je	L13AD
	JMPN	L172A

L13AD:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN2_005
	call	Say
	jmp	SHORT L13F1

T_SIN2_005	LABEL	BYTE
	DB	'#SIN2\SIN2_005#Report, Scotty. How are things going?',0
L13F1:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_SIN2_S05
	call	Say
	jmp	SHORT L1478

T_SIN2_S05	LABEL	BYTE
	DB	'#SIN2\SIN2_S05#About as badly as a kilt in a blast furnace, Capt'
	DB	'ain. Wait a minute, Lieutenant Uhura has some news for you.',0
L1478:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_SIN2U085
	call	Say
	JMPN	L150D

T_SIN2U085	LABEL	BYTE
	DB	'#SIN2\SIN2U085#The virus came from our sensor sweep of the moon'''
	DB	's computers. We believe we have analyzed the memory sectors it a'
	DB	'ttacked.',0
L150D:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN2_008
	call	Say
	jmp	SHORT L1539

T_SIN2_008	LABEL	BYTE
	DB	'#SIN2\SIN2_008#Well done, Uhura.',0
L1539:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_SIN2U097
	call	Say
	JMPN	L15CC

T_SIN2U097	LABEL	BYTE
	DB	'#SIN2\SIN2U097#I wish I could take credit for it. It was Mr. Kyl'
	DB	'e who found the pattern. We are attacking it with anti-virus pro'
	DB	'grams.',0
L15CC:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN2_F26
	call	Say
	jmp	SHORT L161C

T_SIN2_F26	LABEL	BYTE
	DB	'#SIN2\SIN2_F26#Computer science sounds more like medicine every '
	DB	'day.',0
L161C:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_SIN2U096
	call	Say
	jmp	SHORT L16A3

T_SIN2U096	LABEL	BYTE
	DB	'#SIN2\SIN2U096#If we had a doctor as good with computers as you '
	DB	'are with patients, we would be having a lot fewer problems.',0
L16A3:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN2_019
	call	Say
	jmp	SHORT L16E2

T_SIN2_019	LABEL	BYTE
	DB	'#SIN2\SIN2_019#Finally, someone who appreciates me!',0
L16E2:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN2_004
	call	Say
	jmp	SHORT L1721

T_SIN2_004	LABEL	BYTE
	DB	'#SIN2\SIN2_004#Keep working at it, Uhura. Kirk out.',0
L1721:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+virus_found], 1
L172A:
	retf

; Looking and talking.
H_172B:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_179B
LookAtScene:
	mov	ax, 0
	mov	bx, OFFSET T_SIN2N006
	call	Say
	jmp	SHORT L179A

T_SIN2N006	LABEL	BYTE
	DB	'#SIN2\SIN2N006#This looks like some kind of security lock with h'
	DB	'eavy duty doors on both ends.',0
L179A:
	retf

H_179B:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_17D5
LookAtChamber:
	mov	ax, 0
	mov	bx, OFFSET T_SIN2N007
	call	Say
	jmp	SHORT L17D4

T_SIN2N007	LABEL	BYTE
	DB	'#SIN2\SIN2N007#You see another chamber.',0
L17D4:
	retf

H_17D5:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_188C
LookAtTerminal:
	mov	ax, 0
	mov	bx, OFFSET T_SIN2N000
	call	Say
	JMPN	L188B

T_SIN2N000	LABEL	BYTE
	DB	'#SIN2\SIN2N000#A computer terminal. Each word in the Lucr langua'
	DB	'ge has three aspects, Submissive, Neutral, and Aggressive, to su'
	DB	'pply connotation to their language.',0
L188B:
	retf

H_188C:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_18C6
LookAtKeypad:
	mov	ax, 0
	mov	bx, OFFSET T_SIN2N001
	call	Say
	jmp	SHORT L18C5

T_SIN2N001	LABEL	BYTE
	DB	'#SIN2\SIN2N001#A keypad, in base three.',0
L18C5:
	retf

H_18C6:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_1922
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_SIN2N003
	call	Say
	jmp	SHORT L1921

T_SIN2N003	LABEL	BYTE
	DB	'#SIN2\SIN2N003#James Kirk. The burden of command is quite heavy '
	DB	'at times.',0
L1921:
	retf

H_1922:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_1977
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_SIN2N005
	call	Say
	jmp	SHORT L1976

T_SIN2N005	LABEL	BYTE
	DB	'#SIN2\SIN2N005#Spock looks at the equipment and raises an eyebro'
	DB	'w.',0
L1976:
	retf

H_1977:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_19CB
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_SIN2N004
	call	Say
	jmp	SHORT L19CA

T_SIN2N004	LABEL	BYTE
	DB	'#SIN2\SIN2N004#McCoy wishes this place was less... technological'
	DB	'.',0
L19CA:
	retf

H_19CB:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_1A32
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_SIN2N002
	call	Say
	jmp	SHORT L1A31

T_SIN2N002	LABEL	BYTE
	DB	'#SIN2\SIN2N002#Ensign Mosher is scanning the area for potentiall'
	DB	'y hostile lifeforms.',0
L1A31:
	retf

H_1A32:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_1A8B
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN2_003
	call	Say
	jmp	SHORT L1A8A

T_SIN2_003	LABEL	BYTE
	DB	'#SIN2\SIN2_003#The Lucrs did not seem to have a problem with sec'
	DB	'urity.',0
L1A8A:
	retf

H_1A8B:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_1B87
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_039
	call	Say
	JMPN	L1B39

T_SIN2_039	LABEL	BYTE
	DB	'#SIN2\SIN2_039#My tricorder is picking up large supplies of froz'
	DB	'en oxygen, nitrogen, and carbon dioxide beneath the surface. Eno'
	DB	'ugh to last many centuries.',0
L1B39:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN2_016
	call	Say
	jmp	SHORT L1B86

T_SIN2_016	LABEL	BYTE
	DB	'#SIN2\SIN2_016#At least we won''t have to worry about suffocating'
	DB	'.',0
L1B86:
	retf

H_1B87:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_1C8E
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN2_023
	call	Say
	jmp	SHORT L1BE7

T_SIN2_023	LABEL	BYTE
	DB	'#SIN2\SIN2_023#This place does seem to provide protection agains'
	DB	't cosmic rays.',0
L1BE7:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN2_049
	call	Say
	JMPN	L1C8D

T_SIN2_049	LABEL	BYTE
	DB	'#SIN2\SIN2_049#I don''t see why they bothered putting an atmosphe'
	DB	're here, Captain. There hasn''t even been bacteria here in centur'
	DB	'ies, let alone humanoids.',0
L1C8D:
	retf

H_1C8E:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_1D4D
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN2_047
	call	Say
	JMPN	L1D4C

T_SIN2_047	LABEL	BYTE
	DB	'#SIN2\SIN2_047#We appear to be in some type of Security Lock. No'
	DB	' defensive systems are apparent here, but considering the size o'
	DB	'f the doors, they probably don''t need them!',0
L1D4C:
	retf

H_1D4D:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_1D9D
LookAtDoor:
	cmp	byte ptr [si+door_open2], 0
	jne	L1D9C
	mov	ax, 0
	mov	bx, OFFSET T_SIN2N008
	call	Say
	jmp	SHORT L1D9C

T_SIN2N008	LABEL	BYTE
	DB	'#SIN2\SIN2N008#The door has some strange writing on it.',0
L1D9C:
	retf

; Spock reads the writing on the door.
H_1D9D:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_1F9A
SpockReadsDoor:
	cmp	byte ptr [si+door_open2], 0
	je	L1DAC
	JMPN	L1F99

L1DAC:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_F12
	call	Say
	JMPN	L1E68

T_SIN2_F12	LABEL	BYTE
	DB	'#SIN2\SIN2_F12#This says: "Dominant People only to dominate thin'
	DB	'gs beyond >,<these Submissive Walls". My guess is that only auth'
	DB	'orized personnel were allowed beyond this door.',0
L1E68:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN2_048
	call	Say
	jmp	SHORT L1EDE

T_SIN2_048	LABEL	BYTE
	DB	'#SIN2\SIN2_048#Dominance seemed to be very important to these pe'
	DB	'ople. No wonder the Lucr were so war-like.',0
L1EDE:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN2_030
	call	Say
	JMPN	L1F99

T_SIN2_030	LABEL	BYTE
	DB	'#SIN2\SIN2_030#Actually, Ensign, they differ from your culture o'
	DB	'nly in that their language was explicit in their expressions of '
	DB	'dominance and submission, rather than implied.',0
L1F99:
	retf

; The communicator and the medkit.
H_1F9A:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_20E1
UseCommunicator:
	cmp	byte ptr [si+virus_cured], 0
	je	L1FA9
	JMPN	L20A1

L1FA9:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN2_006
	call	Say
	jmp	SHORT L1FE8

T_SIN2_006	LABEL	BYTE
	DB	'#SIN2\SIN2_006#Scotty, any progress on the phasers?',0
L1FE8:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_SIN2_S16
	call	Say
	jmp	SHORT L205D

T_SIN2_S16	LABEL	BYTE
	DB	'#SIN2\SIN2_S16#Sorry Captain, but we cannot do that. We don''t ha'
	DB	've phasers for at least eight more hours.',0
L205D:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN2_017
	call	Say
	jmp	SHORT L20A1

T_SIN2_017	LABEL	BYTE
	DB	'#SIN2\SIN2_017#By then, Proxtrey could be a dead planet.',0
L20A1:
	cmp	byte ptr [si+virus_cured], 1
	jne	L20E0
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_SIN1U070
	call	Say
	jmp	SHORT L20E0

T_SIN1U070	LABEL	BYTE
	DB	'#SIN1\SIN1U070#Nothing new to report Captain.',0
L20E0:
	retf

H_20E1:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_KIRK, 0, H_20E9
	jmp	SHORT MedkitOnSpock

H_20E9:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_SPOCK, 0, H_20F1
MedkitOnSpock:
	jmp	SHORT MedkitOnMcCoy

H_20F1:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_MCCOY, 0, H_20F9
MedkitOnMcCoy:
	jmp	SHORT MedkitOnRedshirt

H_20F9:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_REDSHIRT, 0, H_2145
MedkitOnRedshirt:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN2_014
	call	Say
	jmp	SHORT L2144

T_SIN2_014	LABEL	BYTE
	DB	'#SIN2\SIN2_014#We''re safe from the cosmic radiation, Jim.',0
L2144:
	retf

H_2145:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_KIRK, 0, H_214D
	jmp	SHORT McCoyScansRedshirt

H_214D:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_SPOCK, 0, H_2155
	jmp	SHORT McCoyScansRedshirt

H_2155:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_MCCOY, 0, H_215D
	jmp	SHORT McCoyScansRedshirt

H_215D:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_REDSHIRT, 0, H_21F6
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
	mov	bx, OFFSET T_SIN3_008
	call	Say
	jmp	SHORT L21F5

T_SIN3_008	LABEL	BYTE
	DB	'#SIN2\SIN3_008#All readings are normal. The structure seems to b'
	DB	'e protecting us from the cosmic rays.',0
L21F5:
	retf

H_21F6:
	SCRIPT	MSG_USE, OBJ_MCCOY, 22h, 0, H_225D
McCoyOnKeypad:
	cmp	byte ptr [si+door_open2], 1
	je	L225C
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN2_013
	call	Say
	jmp	SHORT L225C

T_SIN2_013	LABEL	BYTE
	DB	'#SIN2\SIN2_013#I think Spock would have a better chance at crack'
	DB	'ing that, Jim.',0
L225C:
	retf

H_225D:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 22h, 0, H_22A6
MosherOnKeypad:
	cmp	byte ptr [si+door_open2], 1
	je	L22A5
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN2_046
	call	Say
	jmp	SHORT L22A5

T_SIN2_046	LABEL	BYTE
	DB	'#SIN2\SIN2_046#I''m just a security officer, Sir.',0
L22A5:
	retf

; Walking through the open door (room 4).
H_22A6:
	SCRIPT	MSG_WALK, 21h, 0, 0, H_22CF
WalkThrough:
	cmp	byte ptr [si+door_open2], 1
	jne	L22CE
	mov	ax, 0
	push	ax
	mov	ax, 8Bh
	push	ax
	mov	ax, 9Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 156, 139, 0)
	add	sp, 0Ah
L22CE:
	retf

H_22CF:
	SCRIPT	MSG_WALK, 8, 0, 0, T_SIN2_035
WalkThrough2:
	cmp	byte ptr [si+door_open2], 1
	jne	L22F7
	mov	ax, 0
	push	ax
	mov	ax, 8Bh
	push	ax
	mov	ax, 9Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 156, 139, 0)
	add	sp, 0Ah
L22F7:
	retf

rdf_scripts_end	LABEL	BYTE
T_SIN2_035	LABEL	BYTE
	DB	'#SIN2\SIN2_035#If the Lucrs built this base with a clock that to'
	DB	'ld the time by measuring the moon''s rotational speed or the grav'
	DB	'itational forces generated by Proxtrey and the sun, the computer'
	DB	' may have calculated only a week of time has passed since its fi'
	DB	'rst action. I might be able to learn more with another look at t'
	DB	'he console.',0

RDF	ENDS
	END
