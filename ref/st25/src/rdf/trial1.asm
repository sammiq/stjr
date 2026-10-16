; TRIAL1.RDF - "The Feathered Serpent", the trial's Test of Life, first
; chamber, deep under Hrakkour. An electrical entity guards a door with a
; keypad: an iron rod, made by dipping a wooden rod in rock melted by a
; phaser, puts it in stasis; Spock scans the keypad and Uhura works out
; the codes. One opens the door (room 2); another, found through an
; anomaly, leads elsewhere (room 5).
;
; Actors: 8 the entity, 9 the molten rock, 10 (0Ah) the door, 11 (0Bh) the
; iron rod.
; Objects: 8 the entity, 9 the molten rock, 0Bh the iron rod, 20h the
; door, 21h the coder, 22h the rods, 23h the wall, 24h the floor.
; Regions 0 the entity's path, 1 the door.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The conversation at 00CA is built at run time.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
score	EQU	RS_VARS+0	; word: the mission's score
entity_stopped	EQU	RS_VARS+8	; the iron rod has put the entity in stasis
door_open	EQU	RS_VARS+9
scanned_coder	EQU	RS_VARS+0Ah	; Spock has scanned the door's coder
code	EQU	RS_VARS+0Bh	; from Uhura: 0 none, 2 the door's code, 5 the code for the other way (room 5)
can_leave	EQU	RS_VARS+34h	; room 3 is done: Uhura offers to beam the party up
uhura_analysed	EQU	RS_VARS+35h	; Uhura has analysed the coder
ending	EQU	RS_VARS+36h	; word: how it ended, for room 9: 0 Kirk let the trial run, 1 he beamed back mid-trial, 2 Quetzecoatl was lost, 3 the Klingons leave, 4 Vlict was executed
took_rod	EQU	RS_VARS+38h	; the point for the rod
made_iron_rod	EQU	RS_VARS+39h	; the point for the iron rod

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
	DW	-1, -1, -1, -1	; room for each exit
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
	DW	0,0, 0,0	; entrance 2, crew 0
	DW	0,0, 0,0	; entrance 2, crew 1
	DW	0,0, 0,0	; entrance 2, crew 2
	DW	0,0, 0,0	; entrance 2, crew 3
	DW	53,171, 81,177	; entrance 3, crew 0
	DW	57,170, 56,173	; entrance 3, crew 1
	DW	58,174, 51,179	; entrance 3, crew 2
	DW	51,176, 69,191	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	170,170, 150,160, 200,170, 180,160	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	170,170, 150,160, 200,170, 180,160
talk_buf	LABEL	BYTE
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0
choice_jumps	LABEL	BYTE
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0
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
N_Ensign_Bennie	LABEL	BYTE
	DB	'Ensign Bennie',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
N_Entity	LABEL	BYTE
	DB	'Entity',0
rdf_objects	LABEL	BYTE
	DW	20h, 6	; id, points
	DW	36,101, 52,106, 63,129, 54,170, 37,176, 18,142
	DW	21h, 5	; id, points
	DW	3,144, 10,126, 22,126, 22,157, 11,160
	DW	22h, 4	; id, points
	DW	238,157, 285,149, 308,157, 255,168
	DW	23h, 4	; id, points
	DW	281,79, 319,69, 319,182, 281,157
	DW	24h, 5	; id, points
	DW	0,199, 96,152, 238,163, 319,179, 319,199
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	0,199, 81,158, 141,165, 110,199
	DW	1, 4	; id, points
	DW	31,167, 55,169, 36,177, 18,178

rdf_scripts:
rdf_regions_end:
rdf_bans:
rdf_bans_end:
; The room starts: the door, the entity unless stopped.
H_01ED:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0261
StartRoom:
	cmp	byte ptr [si+door_open], 0
	jne	L01FD
	mov	byte ptr [si+RS_BUSY], 2
L01FD:
	cmp	byte ptr [si+door_open], 1
	je	L0220
	jmp	SHORT L020B

N_t1drc	LABEL	BYTE
	DB	't1drc',0
L020B:
	push	0
	push	0
	push	0
	push	OFFSET N_t1drc
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "t1drc", 0, 0, 0)
	add	sp, 0Ch
L0220:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+entity_stopped], 1
	je	L0260
	jmp	SHORT L0230

N_ec	LABEL	BYTE
	DB	'ec',0
L0230:
	push	3
	push	0B1h
	push	5Fh
	push	OFFSET N_ec
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "ec", 95, 177, 3)
	add	sp, 0Ch
	jmp	SHORT L0251

N_TRI1LOOP	LABEL	BYTE
	DB	'TRI1LOOP',0
L0251:
	push	OFFSET N_TRI1LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("TRI1LOOP")
	add	sp, 4
L0260:
	retf

; Tick 50, the first time: the crew take stock of the Test of Life.
H_0261:
	SCRIPT	MSG_TICK, 32h, 0, 0, H_0628
CrewArrive:
	cmp	byte ptr [si+door_open], 0
	jne	L0271
	mov	byte ptr [si+RS_BUSY], 0
L0271:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+entity_stopped], 0
	je	L027D
	retf

L027D:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI1_056
	call	Say
	jmp	SHORT L02AB

T_TRI1_056	LABEL	BYTE
	DB	'#TRI1\TRI1_056#What is this place?',0
L02AB:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI1_047
	call	Say
	JMPN	L0356

T_TRI1_047	LABEL	BYTE
	DB	'#TRI1\TRI1_047#Not much is known about Hrakkour, Ensign. This wo'
	DB	'uld appear to be some sort of a mining installation; that creatu'
	DB	're might be a native lifeform.',0
L0356:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_032
	call	Say
	jmp	SHORT L039C

T_TRI1_032	LABEL	BYTE
	DB	'#TRI1\TRI1_032#A test of courage? That is the Klingon way.',0
L039C:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI1_007
	call	Say
	JMPN	L0469

T_TRI1_007	LABEL	BYTE
	DB	'#TRI1\TRI1_007#I somehow doubt that Vlict intends for us to surv'
	DB	'ive this, whatever the outcome. We''re the only thing that stands'
	DB	' between him and the killing of Quetzecoatl that he can justify.',0
L0469:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI1_057
	call	Say
	jmp	SHORT L04F0

T_TRI1_057	LABEL	BYTE
	DB	'#TRI1\TRI1_057#Why should he worry about justification, Captain?'
	DB	' He''s a Klingon. Murder is as natural to them as breathing!',0
L04F0:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI1_010
	call	Say
	JMPN	L05D3

T_TRI1_010	LABEL	BYTE
	DB	'#TRI1\TRI1_010#That''s not true, Ensign. However, I suspect that '
	DB	'Vlict''s attack on Hrakkour exceeded his orders. He needs Quetzec'
	DB	'oatl as a scapegoat, and he needs a fair trial to avoid an inqui'
	DB	'ry of his own actions.',0
L05D3:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI1_055
	call	Say
	jmp	SHORT L0627

T_TRI1_055	LABEL	BYTE
	DB	'#TRI1\TRI1_055#And our deaths will be the only way he can get it'
	DB	'. Great.',0
L0627:
	retf

; The door has opened (anim msg 9).
H_0628:
	SCRIPT	MSG_ANIM_DONE, 9, 0, 0, H_0648
DoorOpened:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+door_open], 1
	mov	ax, 0Ah
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(10)
	add	sp, 4
	retf

; Region 0: walking into the active entity kills Kirk (anim msg 1).
H_0648:
	SCRIPT	MSG_REGION, 0, 0, 0, H_0678
IntoTheEntity:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+entity_stopped], 1
	je	L0677
	jmp	SHORT L0662

N_kkills	LABEL	BYTE
	DB	'kkills',0
L0662:
	push	1
	push	-1
	push	-1
	push	OFFSET N_kkills
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kkills", -1, -1, 1)
	add	sp, 0Ch
L0677:
	retf

H_0678:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_06A9
KirkKilled:
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	mov	ax, 0
	mov	bx, OFFSET S_0693
	call	Say
	jmp	SHORT L06A8

S_0693	LABEL	BYTE
	DB	'***Game over man!***',0
L06A8:
	retf

; Region 1, the door open: on to room 2.
H_06A9:
	SCRIPT	MSG_REGION, 1, 0, 0, H_06CA
ThroughDoor:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+door_open], 1
	jne	L06C9
	mov	byte ptr [si+RS_BUSY], 1
	push	2
	push	2
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(2, 2)
L06C9:
	retf

; The wooden rods (msgs 4, 5): +1 once.
H_06CA:
	SCRIPT	MSG_GET, 22h, 0, 0, H_06F1
GetRod:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 4
	push	ax
	mov	ax, 0A9h
	push	ax
	mov	ax, 0E9h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 233, 169, 4)
	add	sp, 0Ah
	retf

H_06F1:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_0732
KirkAtRods:
	jmp	SHORT L0700

N_t1pkup	LABEL	BYTE
	DB	't1pkup',0
L0700:
	push	5
	push	0A9h
	push	0E9h
	push	OFFSET N_t1pkup
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "t1pkup", 233, 169, 5)
	add	sp, 0Ch
	push	IT_WROD
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_WROD)
	add	sp, 4
	cmp	byte ptr [si+took_rod], 0
	jne	L0731
	mov	byte ptr [si+took_rod], 1
	add	word ptr [si+score], 1
L0731:
	retf

H_0732:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_073D
TookRod:
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_073D:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_0781
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N003
	call	Say
	jmp	SHORT L0780

T_TRI1N003	LABEL	BYTE
	DB	'#TRI1\TRI1N003#James T. Kirk, hero of the galaxy!',0
L0780:
	retf

H_0781:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_07C3
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N017
	call	Say
	jmp	SHORT L07C2

T_TRI1N017	LABEL	BYTE
	DB	'#TRI1\TRI1N017#Your ever logical friend, Spock.',0
L07C2:
	retf

H_07C3:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_080B
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N016
	call	Say
	jmp	SHORT L080A

T_TRI1N016	LABEL	BYTE
	DB	'#TRI1\TRI1N016#Your ever emotional friend, Dr. McCoy.',0
L080A:
	retf

H_080B:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_0859
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N015
	call	Say
	jmp	SHORT L0858

T_TRI1N015	LABEL	BYTE
	DB	'#TRI1\TRI1N015#Your ever dependable crewman, Ensign Bennie.',0
L0858:
	retf

; Looking and talking.
H_0859:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_08B8
LookAtWall:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N011
	call	Say
	jmp	SHORT L08B7

T_TRI1N011	LABEL	BYTE
	DB	'#TRI1\TRI1N011#This section of wall was carved by some sort of p'
	DB	'lasma field.',0
L08B7:
	retf

H_08B8:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_0913
LookAtFloor:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N006
	call	Say
	jmp	SHORT L0912

T_TRI1N006	LABEL	BYTE
	DB	'#TRI1\TRI1N006#The floor is incomplete, made of unrefined, natur'
	DB	'al rock.',0
L0912:
	retf

H_0913:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_096E
LookAtRods:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N009
	call	Say
	jmp	SHORT L096D

T_TRI1N009	LABEL	BYTE
	DB	'#TRI1\TRI1N009#These wooden rods are support beams that were not'
	DB	' placed.',0
L096D:
	retf

H_096E:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_09CE
LookAtDoor:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N001
	call	Say
	jmp	SHORT L09CD

T_TRI1N001	LABEL	BYTE
	DB	'#TRI1\TRI1N001#A slightly antiquated Klingon door, opened by a k'
	DB	'eycode entry.',0
L09CD:
	retf

H_09CE:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_0A1D
LookAtCoder:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N002
	call	Say
	jmp	SHORT L0A1C

T_TRI1N002	LABEL	BYTE
	DB	'#TRI1\TRI1N002#A slightly antiquated Klingon lock-mechanism.',0
L0A1C:
	retf

H_0A1D:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_0A89
LookAtEntity:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N000
	call	Say
	jmp	SHORT L0A88

T_TRI1N000	LABEL	BYTE
	DB	'#TRI1\TRI1N000#A field of static lightning. It seems to be movin'
	DB	'g in a purposeful manner.',0
L0A88:
	retf

H_0A89:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_0AEB
LookAtMoltenRock:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N007
	call	Say
	jmp	SHORT L0AEA

T_TRI1N007	LABEL	BYTE
	DB	'#TRI1\TRI1N007#The melted rock is cooling, but still remains in '
	DB	'a molten state.',0
L0AEA:
	retf

H_0AEB:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0B48
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI1_J00
	call	Say
	jmp	SHORT L0B47

T_TRI1_J00	LABEL	BYTE
	DB	'#TRI1\TRI1_J00#Why do I have the feeling that I''m about to have '
	DB	'a bad day?',0
L0B47:
	retf

H_0B48:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0BCE
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI1_046
	call	Say
	jmp	SHORT L0BA4

T_TRI1_046	LABEL	BYTE
	DB	'#TRI1\TRI1_046#Captain, I have calculated the odds of surviving '
	DB	'this at...',0
L0BA4:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_034
	call	Say
	jmp	SHORT L0BCD

T_TRI1_034	LABEL	BYTE
	DB	'#TRI1\TRI1_034#Shut up Spock!',0
L0BCD:
	retf

H_0BCE:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0C68
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_019
	call	Say
	JMPN	L0C67

T_TRI1_019	LABEL	BYTE
	DB	'#TRI1\TRI1_019#How could you do it, Jim? I spent hours trying to'
	DB	' save his life, and you just gave him away in seconds to the Kli'
	DB	'ngons!',0
L0C67:
	retf

H_0C68:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0CCE
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI1_053
	call	Say
	jmp	SHORT L0CCD

T_TRI1_053	LABEL	BYTE
	DB	'#TRI1\TRI1_053#You handled those Klingons well, sir. We''ve got t'
	DB	'hem on the run now.',0
L0CCD:
	retf

H_0CCE:
	SCRIPT	MSG_TALK, 8, 0, 0, H_0CFA
TalkToEntity:
	mov	ax, OFFSET N_Entity
	mov	bx, OFFSET S_0CDF
	call	Say
	jmp	SHORT L0CF9

S_0CDF	LABEL	BYTE
	DB	'Zzzt! Sptttz! Zzzt! Tttt!',0
L0CF9:
	retf

; Phasers on the crew, the entity, the walls, the door.
H_0CFA:
	SCRIPT	MSG_USE, IT_PHASERS, OBJ_KIRK, 0, H_0D02
StunKirk:
	jmp	SHORT L0D3A

H_0D02:
	SCRIPT	MSG_USE, IT_PHASERK, OBJ_KIRK, 0, H_0D0A
KillKirk:
	jmp	SHORT L0D3A

H_0D0A:
	SCRIPT	MSG_USE, IT_PHASERS, OBJ_SPOCK, 0, H_0D12
StunSpock:
	jmp	SHORT L0D3A

H_0D12:
	SCRIPT	MSG_USE, IT_PHASERK, OBJ_SPOCK, 0, H_0D1A
KillSpock:
	jmp	SHORT L0D3A

H_0D1A:
	SCRIPT	MSG_USE, IT_PHASERS, OBJ_MCCOY, 0, H_0D22
StunMcCoy:
	jmp	SHORT L0D3A

H_0D22:
	SCRIPT	MSG_USE, IT_PHASERK, OBJ_MCCOY, 0, H_0D2A
KillMcCoy:
	jmp	SHORT L0D3A

H_0D2A:
	SCRIPT	MSG_USE, IT_PHASERS, OBJ_REDSHIRT, 0, H_0D32
StunBennie:
	jmp	SHORT L0D3A

H_0D32:
	SCRIPT	MSG_USE, IT_PHASERK, OBJ_REDSHIRT, 0, H_0DE0
KillBennie:
	jmp	SHORT L0D3A

L0D3A:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI1_048
	call	Say
	JMPN	L0DDF

T_TRI1_048	LABEL	BYTE
	DB	'#TRI1\TRI1_048#Captain, my instructor at the Academy always told'
	DB	' me that if you don''t know what you''re going to do with a phaser'
	DB	', you shouldn''t draw it.',0
L0DDF:
	retf

H_0DE0:
	SCRIPT	MSG_USE, IT_PHASERS, 8, 0, H_0DE8
	jmp	SHORT PhaserEntity

H_0DE8:
	SCRIPT	MSG_USE, IT_PHASERK, 8, 0, H_0E14
PhaserEntity:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N004
	call	Say
	jmp	SHORT L0E13

T_TRI1N004	LABEL	BYTE
	DB	'#TRI1\TRI1N004#No effect.',0
L0E13:
	retf

H_0E14:
	SCRIPT	MSG_USE, IT_PHASERS, 23h, 0, H_0E1C
	jmp	SHORT PhaserWall

H_0E1C:
	SCRIPT	MSG_USE, IT_PHASERK, 23h, 0, H_0E63
PhaserWall:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N008
	call	Say
	jmp	SHORT L0E62

T_TRI1N008	LABEL	BYTE
	DB	'#TRI1\TRI1N008#The wall is resistant to phaser fire.',0
L0E62:
	retf

; Phasers on the floor: stun does nothing, kill melts the rock (+1).
H_0E63:
	SCRIPT	MSG_USE, IT_PHASERS, 24h, 0, H_0E8E
StunFloor:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 2
	mov	ax, 0Ch
	push	ax
	mov	ax, 0BCh
	push	ax
	mov	ax, 0CAh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 202, 188, 12)
	add	sp, 0Ah
	retf

H_0E8E:
	SCRIPT	MSG_WALK_DONE, 0Ch, 0, 0, H_0EC5
KirkStunsFloor:
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0EAD

N_t1mlts	LABEL	BYTE
	DB	't1mlts',0
L0EAD:
	push	0Dh
	push	0BCh
	push	0CAh
	push	OFFSET N_t1mlts
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "t1mlts", 202, 188, 13)
	add	sp, 0Ch
	retf

H_0EC5:
	SCRIPT	MSG_ANIM_DONE, 0Dh, 0, 0, H_0EE9
FloorStunned:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr [si+RS_FALL], 2
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	retf

H_0EE9:
	SCRIPT	MSG_USE, IT_PHASERK, 24h, 0, H_0F14
KillFloor:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 2
	mov	ax, 0Eh
	push	ax
	mov	ax, 0BCh
	push	ax
	mov	ax, 0CAh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 202, 188, 14)
	add	sp, 0Ah
	retf

H_0F14:
	SCRIPT	MSG_WALK_DONE, 0Eh, 0, 0, H_0F4B
KirkMeltsFloor:
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0F33

N_t1mltk	LABEL	BYTE
	DB	't1mltk',0
L0F33:
	push	0Fh
	push	0BCh
	push	0CAh
	push	OFFSET N_t1mltk
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "t1mltk", 202, 188, 15)
	add	sp, 0Ch
	retf

H_0F4B:
	SCRIPT	MSG_ANIM_DONE, 0Fh, 0, 0, H_0FC8
RockMelted:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N014
	call	Say
	jmp	SHORT L0F86

T_TRI1N014	LABEL	BYTE
	DB	'#TRI1\TRI1N014#You melt some of the rock.',0
L0F86:
	jmp	SHORT L0F8F

N_t1mltd	LABEL	BYTE
	DB	't1mltd',0
L0F8F:
	push	0
	push	0BCh
	push	0CAh
	push	OFFSET N_t1mltd
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "t1mltd", 202, 188, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_FALL], 2
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	add	word ptr [si+score], 1
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_0FC8:
	SCRIPT	MSG_USE, IT_PHASERS, 22h, 0, H_0FD0
	jmp	SHORT PhaserRods

H_0FD0:
	SCRIPT	MSG_USE, IT_PHASERK, 22h, 0, H_100B
PhaserRods:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N012
	call	Say
	jmp	SHORT L100A

T_TRI1N012	LABEL	BYTE
	DB	'#TRI1\TRI1N012#You burn one of the rods.',0
L100A:
	retf

H_100B:
	SCRIPT	MSG_USE, IT_PHASERS, 20h, 0, H_1013
	jmp	SHORT PhaserDoor

H_1013:
	SCRIPT	MSG_USE, IT_PHASERK, 20h, 0, H_108C
PhaserDoor:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI1_040
	call	Say
	jmp	SHORT L108B

T_TRI1_040	LABEL	BYTE
	DB	'#TRI1\TRI1_040#There is a high probability that shooting the doo'
	DB	'r would be hasardous to our wellbeing.',0
L108B:
	retf

H_108C:
	SCRIPT	MSG_USE, IT_PHASERS, 21h, 0, H_1094
	jmp	SHORT PhaserCoder

H_1094:
	SCRIPT	MSG_USE, IT_PHASERK, 21h, 0, H_10E0
PhaserCoder:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_021
	call	Say
	jmp	SHORT L10DF

T_TRI1_021	LABEL	BYTE
	DB	'#TRI1\TRI1_021#Jim! Are you mad? that''s our only way out!',0
L10DF:
	retf

; Tricorders: scanning the entity and the floor is +1 each.
H_10E0:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_KIRK, 0, H_1158
McCoyScansKirk:
	mov	byte ptr [si+RS_FALL+2], 1
	jmp	SHORT L10F3

N_mscans	LABEL	BYTE
	DB	'mscans',0
L10F3:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscans
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscans", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_024
	call	Say
	jmp	SHORT L1157

T_TRI1_024	LABEL	BYTE
	DB	'#TRI1\TRI1_024#Male Human, good physical condition.',0
L1157:
	retf

H_1158:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_SPOCK, 0, H_11B1
McCoyScansSpock:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_025
	call	Say
	jmp	SHORT L11B0

T_TRI1_025	LABEL	BYTE
	DB	'#TRI1\TRI1_025#Male Human-Vulcan hybrid. Excellent physical cond'
	DB	'ition.',0
L11B0:
	retf

H_11B1:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_MCCOY, 0, H_1230
McCoyScansMcCoy:
	mov	byte ptr [si+RS_FALL+2], 1
	jmp	SHORT L11C4

N_mscans_2	LABEL	BYTE
	DB	'mscans',0
L11C4:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscans_2
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscans", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_022
	call	Say
	jmp	SHORT L122F

T_TRI1_022	LABEL	BYTE
	DB	'#TRI1\TRI1_022#One Male Human, average physical condition.',0
L122F:
	retf

H_1230:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_REDSHIRT, 0, H_12B4
McCoyScansBennie:
	mov	byte ptr [si+RS_FALL+2], 1
	jmp	SHORT L1243

N_mscans_3	LABEL	BYTE
	DB	'mscans',0
L1243:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscans_3
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscans", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_023
	call	Say
	jmp	SHORT L12B3

T_TRI1_023	LABEL	BYTE
	DB	'#TRI1\TRI1_023#He''s a Male Human, excellent physical condition.',0
L12B3:
	retf

H_12B4:
	SCRIPT	MSG_USE, IT_MTRICOR, 8, 0, H_132F
McCoyScansEntity:
	mov	byte ptr [si+RS_FALL+2], 1
	jmp	SHORT L12C7

N_mscans_4	LABEL	BYTE
	DB	'mscans',0
L12C7:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscans_4
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscans", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_017
	call	Say
	jmp	SHORT L132E

T_TRI1_017	LABEL	BYTE
	DB	'#TRI1\TRI1_017#Does not register as a known life form.',0
L132E:
	retf

H_132F:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_13AE
SpockScansWall:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L1342

N_sscans	LABEL	BYTE
	DB	'sscans',0
L1342:
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
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI1_043
	call	Say
	jmp	SHORT L13AD

T_TRI1_043	LABEL	BYTE
	DB	'#TRI1\TRI1_043#This wall was carved from the natural rock.',0
L13AD:
	retf

H_13AE:
	SCRIPT	MSG_USE, IT_STRICOR, 8, 0, H_14A0
SpockScansEntity:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L13C1

N_sscans_2	LABEL	BYTE
	DB	'sscans',0
L13C1:
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
	mov	bx, OFFSET T_TRI1_012
	call	Say
	JMPN	L149B

T_TRI1_012	LABEL	BYTE
	DB	'#TRI1\TRI1_012#This creature is composed of electrical fields. I'
	DB	' would not recommend approaching it. A metal projectile might di'
	DB	'srupt its fields and render it harmless.',0
L149B:
	add	word ptr [si+score], 1
	retf

H_14A0:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_152D
SpockScansRods:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L14B3

N_sscans_3	LABEL	BYTE
	DB	'sscans',0
L14B3:
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
	mov	bx, OFFSET T_TRI1_041
	call	Say
	jmp	SHORT L152C

T_TRI1_041	LABEL	BYTE
	DB	'#TRI1\TRI1_041#These wooden rods are support beams that were not'
	DB	' placed.',0
L152C:
	retf

H_152D:
	SCRIPT	MSG_USE, IT_STRICOR, 24h, 0, H_15A7
SpockScansFloor:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L1540

N_sscans_4	LABEL	BYTE
	DB	'sscans',0
L1540:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscans_4
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
	mov	bx, OFFSET T_TRI1_042
	call	Say
	jmp	SHORT L15A2

T_TRI1_042	LABEL	BYTE
	DB	'#TRI1\TRI1_042#This rock has a high iron content.',0
L15A2:
	add	word ptr [si+score], 1
	retf

H_15A7:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_1625
SpockScansDoor:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L15BA

N_sscans_5	LABEL	BYTE
	DB	'sscans',0
L15BA:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscans_5
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
	mov	bx, OFFSET T_TRI1_013
	call	Say
	jmp	SHORT L1624

T_TRI1_013	LABEL	BYTE
	DB	'#TRI1\TRI1_013#A Klingon entry door, slightly antiquated.',0
L1624:
	retf

; Spock scans the coder: Uhura can now work on it.
H_1625:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_1761
SpockScansCoder:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L1638

N_sscans_6	LABEL	BYTE
	DB	'sscans',0
L1638:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscans_6
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
	mov	bx, OFFSET T_TRI1_014
	call	Say
	JMPN	L16FC

T_TRI1_014	LABEL	BYTE
	DB	'#TRI1\TRI1_014#An entry coder for the door, keyed to a number se'
	DB	'quence. The tricorder is unable to determine the code, but can s'
	DB	'can the mechanism.',0
L16FC:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+scanned_coder], 1
	add	word ptr [si+score], 1
	retf

L170A:
	mov	si, word ptr cs:rdf_state
	mov	word ptr [si+ending], 1
	push	1
	push	1
	push	1
	push	RC_BEAMUP
	SERVICE		; BeamUp(1, 1, 1)
	add	sp, 8
	retf

L1725:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI1U080
	call	Say
	jmp	SHORT L1751

T_TRI1U080	LABEL	BYTE
	DB	'#TRI1\TRI1U080#Affirmative, sir.',0
L1751:
	mov	byte ptr [si+1Dh], 1
	push	4
	push	4
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(4, 4)
L1760:
	retf

; The communicator: once room 3 is done, Uhura offers to beam the party
; up (ending 1). Otherwise, with the coder scanned, Uhura finds its code
; (2, +1) and an anomaly that offers another code (5, +3).
H_1761:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_1E6F
CallUhura:
	cmp	byte ptr [si+can_leave], 1
	je	L1770
	JMPN	L1885

L1770:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI1U090
	call	Say
	jmp	SHORT L17B3

T_TRI1U090	LABEL	BYTE
	DB	'#TRI1\TRI1U090#Do you wish to be beamed up now Captain?',0
L17B3:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L17F5

T_TRI1_005	LABEL	BYTE
	DB	'#TRI1\TRI1_005#Beam us back to the Enterprise. Kirk out.',0
L17F5:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI1_005
	mov	word ptr cs:choice_jumps, OFFSET L170A
	jmp	SHORT L1831

T_TRI1_004	LABEL	BYTE
	DB	'#TRI1\TRI1_004#Beam us to Vlict''s position.',0
L1831:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI1_004
	mov	word ptr cs:choice_jumps+2, OFFSET L1725
	jmp	SHORT L185A

T_TRI1_009	LABEL	BYTE
	DB	'#TRI1\TRI1_009#Negative.',0
L185A:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI1_009
	mov	word ptr cs:choice_jumps+4, OFFSET L1760
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L1885:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+uhura_analysed], 1
	jne	L18CB
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI1U068
	call	Say
	jmp	SHORT L18CA

T_TRI1U068	LABEL	BYTE
	DB	'#TRI1\TRI1U068#Nothing else to report Captain.',0
L18CA:
	retf

L18CB:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI1U086
	call	Say
	jmp	SHORT L1920

T_TRI1U086	LABEL	BYTE
	DB	'#TRI1\TRI1U086#Captain, there is a force field between us and th'
	DB	'e planet.',0
L1920:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI1U106
	call	Say
	JMPN	L19CA

T_TRI1U106	LABEL	BYTE
	DB	'#TRI1\TRI1U106#We have your position at approximately thirty met'
	DB	'ers beneath the surface of Hrakkour, in what appears to be the r'
	DB	'uins of an archeological dig.',0
L19CA:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI1U098
	call	Say
	jmp	SHORT L1A4F

T_TRI1U098	LABEL	BYTE
	DB	'#TRI1\TRI1U098#Keep us informed, we''ll help you all we can. We c'
	DB	'an analyze any data you gather through the main computer.',0
L1A4F:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+scanned_coder], 1
	je	L1A5D
	JMPN	L1CC1

L1A5D:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI1_011
	call	Say
	JMPN	L1B17

T_TRI1_011	LABEL	BYTE
	DB	'#TRI1\TRI1_011#Uhura, prepare to receive a tricorder message. Th'
	DB	'ere is a door with an entry coder here; try to analyze the circu'
	DB	'its and let the main computer crack the code.',0
L1B17:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI1U101
	call	Say
	JMPN	L1BB3

T_TRI1U101	LABEL	BYTE
	DB	'#TRI1\TRI1U101#Scan complete. Main computer has the code. We als'
	DB	'o read an anomaly. Something else has tapped into the keycode. S'
	DB	'hall I analyze?',0
L1BB3:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L1BE2

T_TRI1_006	LABEL	BYTE
	DB	'#TRI1\TRI1_006#I want that door open.',0
L1BE2:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI1_006
	mov	word ptr cs:choice_jumps, OFFSET L1C40
	jmp	SHORT L1C15

T_TRI1_002	LABEL	BYTE
	DB	'#TRI1\TRI1_002#Affirmative, Uhura.',0
L1C15:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI1_002
	mov	word ptr cs:choice_jumps+2, OFFSET L1CC2
	mov	word ptr cs:talk_buf+6, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L1C40:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI1U079
	call	Say
	jmp	SHORT L1CB0

T_TRI1U079	LABEL	BYTE
	DB	'#TRI1\TRI1U079#Affirmative sir. We will transmit code when you a'
	DB	'ctivate the keycode. Uhura out.',0
L1CB0:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+code], 2
	mov	byte ptr [si+uhura_analysed], 1
	add	word ptr [si+score], 1
L1CC1:
	retf

L1CC2:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI1U102
	call	Say
	JMPN	L1D8E

T_TRI1U102	LABEL	BYTE
	DB	'#TRI1\TRI1U102#Sir, we have a secondary code that is nested in t'
	DB	'he Klingon program. Computer is unable to analyze its function. '
	DB	'Shall we broadcast it to you when you activate the keypad?',0
L1D8E:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L1DB3

T_TRI1_003	LABEL	BYTE
	DB	'#TRI1\TRI1_003#Affirmative.',0
L1DB3:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI1_003
	mov	word ptr cs:choice_jumps, OFFSET L1E2A
	jmp	SHORT L1DFF

T_TRI1_008	LABEL	BYTE
	DB	'#TRI1\TRI1_008#Negative. Transmit the door entry code only.',0
L1DFF:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI1_008
	mov	word ptr cs:choice_jumps+2, OFFSET L1C40
	mov	word ptr cs:talk_buf+6, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L1E2A:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI1U095
	call	Say
	jmp	SHORT L1E5D

T_TRI1U095	LABEL	BYTE
	DB	'#TRI1\TRI1U095#Good luck, Captain.',0
L1E5D:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+code], 5
	mov	byte ptr [si+uhura_analysed], 1
	add	word ptr [si+score], 3
	retf

; The crew on the coder: Spock or Bennie keys in the code once the entity
; is stopped: the door's code opens it (msgs 18/24, 19/25); the other
; code takes the party to room 5 (msgs 20/26, 21/27).
H_1E6F:
	SCRIPT	MSG_USE, OBJ_MCCOY, 8, 0, H_1EE4
McCoyOnEntity:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_016
	call	Say
	jmp	SHORT L1EE3

T_TRI1_016	LABEL	BYTE
	DB	'#TRI1\TRI1_016#Do you know what ten million volts can do to a ma'
	DB	'n? It can ruin his whole damn day.',0
L1EE3:
	retf

H_1EE4:
	SCRIPT	MSG_USE, OBJ_MCCOY, 21h, 0, H_2002
McCoyOnCoder:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+entity_stopped], 1
	je	L1F43
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_018
	call	Say
	jmp	SHORT L1F42

T_TRI1_018	LABEL	BYTE
	DB	'#TRI1\TRI1_018#Find someone else to be a volunteer. I''ve retired'
	DB	'.',0
L1F42:
	retf

L1F43:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+code], 0
	jne	L1F80
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_020
	call	Say
	jmp	SHORT L1F7F

T_TRI1_020	LABEL	BYTE
	DB	'#TRI1\TRI1_020#I don''t know the code.',0
L1F7F:
	retf

L1F80:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_029
	call	Say
	jmp	SHORT L1FC0

T_TRI1_029	LABEL	BYTE
	DB	'#TRI1\TRI1_029#This is not in my field of expertise.',0
L1FC0:
	retf

	DB	0B8h, 1Eh, 1, 0BBh, 0CCh, 1Fh, 0E8h, 32h, 0E1h, 0EBh
	DB	'5#TRI1\TRI1_030#This is not in my field of expertise.',0
	DB	0CBh

H_2002:
	SCRIPT	MSG_USE, OBJ_MCCOY, 24h, 0, H_2053
McCoyOnFloor:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_031
	call	Say
	jmp	SHORT L2052

T_TRI1_031	LABEL	BYTE
	DB	'#TRI1\TRI1_031#What the blazes do you want me to do on a rock?',0
L2052:
	retf

H_2053:
	SCRIPT	MSG_USE, OBJ_SPOCK, 8, 0, H_20C0
SpockOnEntity:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI1_039
	call	Say
	jmp	SHORT L20BF

T_TRI1_039	LABEL	BYTE
	DB	'#TRI1\TRI1_039#The odds of surviving contact with the creature a'
	DB	're too small to calculate.',0
L20BF:
	retf

H_20C0:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_2242
SpockOnCoder:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+door_open], 1
	jne	L210E
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI1_038
	call	Say
	jmp	SHORT L210D

T_TRI1_038	LABEL	BYTE
	DB	'#TRI1\TRI1_038#The door is already open Captain.',0
L210D:
	retf

L210E:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+entity_stopped], 0
	je	L211C
	JMPN	L21B5

L211C:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI1_036
	call	Say
	JMPN	L21B4

T_TRI1_036	LABEL	BYTE
	DB	'#TRI1\TRI1_036#If you will observe the position of the creature,'
	DB	' Captain, I think that you will find that it prevents access to '
	DB	'the keypad.',0
L21B4:
	retf

L21B5:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+code], 0
	jne	L21FD
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI1_044
	call	Say
	jmp	SHORT L21FC

T_TRI1_044	LABEL	BYTE
	DB	'#TRI1\TRI1_044#We do not know the code, Captain.',0
L21FC:
	retf

L21FD:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+code], 2
	jne	L2225
	mov	ax, 12h
	push	ax
	mov	ax, 0B8h
	push	ax
	mov	ax, 1Fh
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 31, 184, 18)
	add	sp, 0Ah
	retf

L2225:
	mov	ax, 14h
	push	ax
	mov	ax, 0B8h
	push	ax
	mov	ax, 1Fh
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 31, 184, 20)
	add	sp, 0Ah
	retf

H_2242:
	SCRIPT	MSG_WALK_DONE, 12h, 0, 0, H_2277
SpockAtCoder:
	mov	ax, 7
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(7)
	add	sp, 4
	jmp	SHORT L2261

N_susemw	LABEL	BYTE
	DB	'susemw',0
L2261:
	push	13h
	push	-1
	push	-1
	push	OFFSET N_susemw
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemw", -1, -1, 19)
	add	sp, 0Ch
	retf

H_2277:
	SCRIPT	MSG_ANIM_DONE, 13h, 0, 0, H_22C9
SpockOpensDoor:
	mov	byte ptr [si+RS_FALL+1], 3
	mov	ax, 1
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(1)
	add	sp, 4
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	jmp	SHORT L22AA

N_t1drco	LABEL	BYTE
	DB	't1drco',0
L22AA:
	push	9
	push	-1
	push	-1
	push	OFFSET N_t1drco
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "t1drco", -1, -1, 9)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+door_open], 1
	retf

H_22C9:
	SCRIPT	MSG_WALK_DONE, 14h, 0, 0, H_22FE
SpockAtCoder2:
	mov	ax, 7
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(7)
	add	sp, 4
	jmp	SHORT L22E8

N_susemw_2	LABEL	BYTE
	DB	'susemw',0
L22E8:
	push	15h
	push	-1
	push	-1
	push	OFFSET N_susemw_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemw", -1, -1, 21)
	add	sp, 0Ch
	retf

H_22FE:
	SCRIPT	MSG_ANIM_DONE, 15h, 0, 0, H_2328
SpockOpensOtherWay:
	mov	byte ptr [si+RS_FALL+1], 3
	mov	ax, 1
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(1)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 1
	push	5
	push	5
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(5, 5)
	retf

H_2328:
	SCRIPT	MSG_USE, OBJ_SPOCK, 24h, 0, H_237B
SpockOnFloor:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI1_035
	call	Say
	jmp	SHORT L237A

T_TRI1_035	LABEL	BYTE
	DB	'#TRI1\TRI1_035#I do not understand the desired course of action.',0
L237A:
	retf

H_237B:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 8, 0, H_23DA
BennieOnEntity:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI1_050
	call	Say
	jmp	SHORT L23D9

T_TRI1_050	LABEL	BYTE
	DB	'#TRI1\TRI1_050#I refuse, Captain, on the grounds that it might e'
	DB	'liminate me.',0
L23D9:
	retf

H_23DA:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 21h, 0, H_24F9
BennieOnCoder:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+door_open], 1
	jne	L23EC
	retf

L23EC:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+entity_stopped], 0
	jne	L2450
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI1_051
	call	Say
	jmp	SHORT L244F

T_TRI1_051	LABEL	BYTE
	DB	'#TRI1\TRI1_051#I refuse, Captain, on the grounds that it might e'
	DB	'liminate me.',0
L244F:
	retf

L2450:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+code], 0
	jne	L24B4
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI1_054
	call	Say
	jmp	SHORT L24B3

T_TRI1_054	LABEL	BYTE
	DB	'#TRI1\TRI1_054#You want me to smash it? But that''s our only way '
	DB	'out of here.',0
L24B3:
	retf

L24B4:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+code], 2
	jne	L24DC
	mov	ax, 18h
	push	ax
	mov	ax, 0B8h
	push	ax
	mov	ax, 1Fh
	push	ax
	mov	ax, 3
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(3, 31, 184, 24)
	add	sp, 0Ah
	retf

L24DC:
	mov	ax, 1Ah
	push	ax
	mov	ax, 0B8h
	push	ax
	mov	ax, 1Fh
	push	ax
	mov	ax, 3
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(3, 31, 184, 26)
	add	sp, 0Ah
	retf

H_24F9:
	SCRIPT	MSG_WALK_DONE, 18h, 0, 0, H_252E
BennieAtCoder:
	mov	ax, 7
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(7)
	add	sp, 4
	jmp	SHORT L2518

N_rusemw	LABEL	BYTE
	DB	'rusemw',0
L2518:
	push	19h
	push	-1
	push	-1
	push	OFFSET N_rusemw
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rusemw", -1, -1, 25)
	add	sp, 0Ch
	retf

H_252E:
	SCRIPT	MSG_ANIM_DONE, 19h, 0, 0, H_2580
BennieOpensDoor:
	mov	byte ptr [si+RS_FALL+3], 3
	mov	ax, 3
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(3)
	add	sp, 4
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	jmp	SHORT L2561

N_t1drco_2	LABEL	BYTE
	DB	't1drco',0
L2561:
	push	9
	push	-1
	push	-1
	push	OFFSET N_t1drco_2
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "t1drco", -1, -1, 9)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+door_open], 1
	retf

H_2580:
	SCRIPT	MSG_WALK_DONE, 1Ah, 0, 0, H_25B5
BennieAtCoder2:
	mov	ax, 7
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(7)
	add	sp, 4
	jmp	SHORT L259F

N_rusemw_2	LABEL	BYTE
	DB	'rusemw',0
L259F:
	push	1Bh
	push	-1
	push	-1
	push	OFFSET N_rusemw_2
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rusemw", -1, -1, 27)
	add	sp, 0Ch
	retf

H_25B5:
	SCRIPT	MSG_ANIM_DONE, 1Bh, 0, 0, H_25DF
BennieOpensOtherWay:
	mov	byte ptr [si+RS_FALL+3], 3
	mov	ax, 3
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(3)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 1
	push	5
	push	5
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(5, 5)
	retf

H_25DF:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 24h, 0, H_2645
BennieOnFloor:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI1_049
	call	Say
	jmp	SHORT L2644

T_TRI1_049	LABEL	BYTE
	DB	'#TRI1\TRI1_049#Do you want me to arrest it, interrogate it, or b'
	DB	'eat it up, Captain?',0
L2644:
	retf

; The rods: the wooden one dipped in the molten rock (msgs 16, 17, +1)
; becomes an iron rod; thrown at the entity (msgs 11, 7) it freezes it
; (+1).
H_2645:
	SCRIPT	MSG_USE, IT_WROD, OBJ_MCCOY, 0, H_266C
RodOnMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_027
	call	Say
	jmp	SHORT L266B

T_TRI1_027	LABEL	BYTE
	DB	'#TRI1\TRI1_027#Ouch!',0
L266B:
	retf

H_266C:
	SCRIPT	MSG_USE, IT_WROD, OBJ_SPOCK, 0, H_2693
RodOnSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI1_037
	call	Say
	jmp	SHORT L2692

T_TRI1_037	LABEL	BYTE
	DB	'#TRI1\TRI1_037#Ouch!',0
L2692:
	retf

H_2693:
	SCRIPT	MSG_USE, IT_WROD, OBJ_REDSHIRT, 0, H_26BA
RodOnBennie:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI1_052
	call	Say
	jmp	SHORT L26B9

T_TRI1_052	LABEL	BYTE
	DB	'#TRI1\TRI1_052#Ouch!',0
L26B9:
	retf

H_26BA:
	SCRIPT	MSG_USE, IT_WROD, 24h, 0, H_26D3
RodOnFloor:
	mov	ax, 0
	mov	bx, OFFSET N_Clunk
	call	Say
	jmp	SHORT L26D2

N_Clunk	LABEL	BYTE
	DB	'Clunk.',0
L26D2:
	retf

H_26D3:
	SCRIPT	MSG_USE, IT_WROD, 23h, 0, H_26EC
RodOnWall:
	mov	ax, 0
	mov	bx, OFFSET N_Clunk_2
	call	Say
	jmp	SHORT L26EB

N_Clunk_2	LABEL	BYTE
	DB	'Clunk.',0
L26EB:
	retf

H_26EC:
	SCRIPT	MSG_USE, IT_WROD, 8, 0, H_271F
RodAtEntity:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0Ah
	push	ax
	mov	ax, 0ADh
	push	ax
	mov	ax, 0E9h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 233, 173, 10)
	add	sp, 0Ah
	push	IT_WROD
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_WROD)
	add	sp, 4
	retf

H_271F:
	SCRIPT	MSG_WALK_DONE, 0Ah, 0, 0, H_2746
KirkThrowsRod:
	jmp	SHORT L272E

N_kthrwr	LABEL	BYTE
	DB	'kthrwr',0
L272E:
	push	6
	push	0ADh
	push	0E9h
	push	OFFSET N_kthrwr
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kthrwr", 233, 173, 6)
	add	sp, 0Ch
	retf

H_2746:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_2751
RodThrown:
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_2751:
	SCRIPT	MSG_USE, IT_WROD, 21h, 0, H_277D
RodOnCoder:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N005
	call	Say
	jmp	SHORT L277C

T_TRI1N005	LABEL	BYTE
	DB	'#TRI1\TRI1N005#No effect.',0
L277C:
	retf

H_277D:
	SCRIPT	MSG_USE, IT_WROD, 9, 0, H_27A4
RodInMoltenRock:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 10h
	push	ax
	mov	ax, 0C4h
	push	ax
	mov	ax, 0E4h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 228, 196, 16)
	add	sp, 0Ah
	retf

H_27A4:
	SCRIPT	MSG_WALK_DONE, 10h, 0, 0, H_27CA
KirkDipsRod:
	jmp	SHORT L27B2

N_t1dip	LABEL	BYTE
	DB	't1dip',0
L27B2:
	push	11h
	push	0C4h
	push	0E4h
	push	OFFSET N_t1dip
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "t1dip", 228, 196, 17)
	add	sp, 0Ch
	retf

H_27CA:
	SCRIPT	MSG_ANIM_DONE, 11h, 0, 0, H_284C
IronRod:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N013
	call	Say
	jmp	SHORT L2825

T_TRI1N013	LABEL	BYTE
	DB	'#TRI1\TRI1N013#You coat the rod with molten iron. It hardens qui'
	DB	'ckly.',0
L2825:
	push	IT_WROD
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_WROD)
	add	sp, 4
	push	IT_IROD
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_IROD)
	add	sp, 4
	cmp	byte ptr [si+made_iron_rod], 0
	jne	L284B
	mov	byte ptr [si+made_iron_rod], 1
	add	word ptr [si+score], 1
L284B:
	retf

H_284C:
	SCRIPT	MSG_USE, IT_IROD, OBJ_MCCOY, 0, H_2864
IronRodOnMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET S_285D
	call	Say
	jmp	SHORT L2863

S_285D	LABEL	BYTE
	DB	'Ouch!',0
L2863:
	retf

H_2864:
	SCRIPT	MSG_USE, IT_IROD, OBJ_SPOCK, 0, H_287C
IronRodOnSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_2875
	call	Say
	jmp	SHORT L287B

S_2875	LABEL	BYTE
	DB	'Ouch!',0
L287B:
	retf

H_287C:
	SCRIPT	MSG_USE, IT_IROD, OBJ_REDSHIRT, 0, H_2894
IronRodOnBennie:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET S_288D
	call	Say
	jmp	SHORT L2893

S_288D	LABEL	BYTE
	DB	'Ouch!',0
L2893:
	retf

H_2894:
	SCRIPT	MSG_USE, IT_IROD, 24h, 0, H_28AD
IronRodOnFloor:
	mov	ax, 0
	mov	bx, OFFSET N_Clunk_3
	call	Say
	jmp	SHORT L28AC

N_Clunk_3	LABEL	BYTE
	DB	'Clunk.',0
L28AC:
	retf

H_28AD:
	SCRIPT	MSG_USE, IT_IROD, 23h, 0, H_28C6
IronRodOnWall:
	mov	ax, 0
	mov	bx, OFFSET N_Clunk_4
	call	Say
	jmp	SHORT L28C5

N_Clunk_4	LABEL	BYTE
	DB	'Clunk.',0
L28C5:
	retf

H_28C6:
	SCRIPT	MSG_USE, IT_IROD, 8, 0, H_2902
IronRodAtEntity:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0Bh
	push	ax
	mov	ax, 0ACh
	push	ax
	mov	ax, 0E9h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 233, 172, 11)
	add	sp, 0Ah
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+entity_stopped], 1
	push	IT_IROD
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_IROD)
	add	sp, 4
	retf

H_2902:
	SCRIPT	MSG_WALK_DONE, 0Bh, 0, 0, H_2938
KirkThrowsIronRod:
	jmp	SHORT L2910

N_kthri	LABEL	BYTE
	DB	'kthri',0
L2910:
	push	7
	push	0ACh
	push	0E9h
	push	OFFSET N_kthri
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kthri", 233, 172, 7)
	add	sp, 0Ch
	mov	ax, 8
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(8)
	add	sp, 4
	retf

H_2938:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_2A2A
EntityStopped:
	jmp	SHORT L2947

N_t1irod	LABEL	BYTE
	DB	't1irod',0
L2947:
	push	8
	push	0ACh
	push	0E9h
	push	OFFSET N_t1irod
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "t1irod", 233, 172, 8)
	add	sp, 0Ch
	mov	byte ptr [si+RS_FALL], 3
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, RC_DIGIOFF
	push	ax
	SERVICE		; DigiOff()
	add	sp, 2
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI1_045
	call	Say
	jmp	SHORT L29F4

T_TRI1_045	LABEL	BYTE
	DB	'#TRI1\TRI1_045#As I suspected, Captain. The creature is in stasi'
	DB	's. It should awaken in 3.48 days.',0
L29F4:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_033
	call	Say
	jmp	SHORT L2A25

T_TRI1_033	LABEL	BYTE
	DB	'#TRI1\TRI1_033#I''ll bet it''ll be mad.',0
L2A25:
	add	word ptr [si+score], 1
	retf

H_2A2A:
	SCRIPT	MSG_USE, IT_IROD, 21h, 0, H_2A56
IronRodOnCoder:
	mov	ax, 0
	mov	bx, OFFSET T_TRI1N004_2
	call	Say
	jmp	SHORT L2A55

T_TRI1N004_2	LABEL	BYTE
	DB	'#TRI1\TRI1N004#No effect.',0
L2A55:
	retf

H_2A56:
	SCRIPT	MSG_GET, 0Bh, 0, 0, H_2B01
GetIronRod:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI1_015
	call	Say
	JMPN	L2B00

T_TRI1_015	LABEL	BYTE
	DB	'#TRI1\TRI1_015#Captain, I would strongly recommend against distu'
	DB	'rbing the rod. It could result in awakening the creature or poss'
	DB	'ibly electrocuting you.',0
L2B00:
	retf

H_2B01:
	SCRIPT	MSG_WALK, 20h, 0, 0, H_2B2A
WalkToDoor:
	cmp	byte ptr [si+door_open], 1
	jne	L2B29
	mov	ax, 1Ch
	push	ax
	mov	ax, 0ACh
	push	ax
	mov	ax, 1Ah
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 26, 172, 28)
	add	sp, 0Ah
L2B29:
	retf

H_2B2A:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, rdf_scripts_end
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI1_026
	call	Say
	jmp	SHORT L2B8B

T_TRI1_026	LABEL	BYTE
	DB	'#TRI1\TRI1_026#Nobody needs healing, Jim, but you will if they h'
	DB	'arm my patient.',0
L2B8B:
	retf

rdf_scripts_end	LABEL	BYTE

RDF	ENDS
	END
