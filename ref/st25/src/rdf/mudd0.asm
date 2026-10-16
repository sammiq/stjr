; MUDD0.RDF - "Another Fine Mess", the storage bay of Harry Mudd's
; alien ship, where Mudd welcomes the landing party: he found the derelict
; and has been selling off its contents, and the Elasi want it too. The
; bay holds the alien lenses, the memory disks and a de-grimer; the
; cleaned lenses make the alien device. Common to all of the mission's
; rooms: the failing life support, the device and the de-grimer.
;
; Actors: 8 Mudd, 9 the device's explosion, 10 (0Ah) the upper door.
; Objects: 8 Mudd, 20h the disks, 21h the lenses, 22h the de-grimer,
; 23h/24h crates, 25h/26h by the doors.
; Exits: 0 room 1, 1 room 5. Regions 0, 1: the doorsteps.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
mudd_talk	EQU	RS_VARS+0	; 0 until Mudd has welcomed the party, 2 after (and the crew's talk)
used_device	EQU	RS_VARS+13h	; the alien device has been fired, anywhere (+5 once)
air_failing	EQU	RS_VARS+1Dh	; life support is failing: the countdown runs (room 5)
took_disks	EQU	RS_VARS+1Fh
took_lenses	EQU	RS_VARS+20h
took_degrimer	EQU	RS_VARS+21h
air_left	EQU	RS_VARS+27h	; word: ticks of air left, from 6978h
air_countdown	EQU	RS_VARS+29h	; word: the countdown has started
music_started	EQU	RS_VARS+2Bh
score	EQU	RS_VARS+31h	; word: the mission's score

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0A8h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	6Bh
rdf_scale_min	LABEL	BYTE
	DW	55h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	1, 5, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	160,111, 187,141	; entrance 0, crew 0
	DW	160,111, 208,137	; entrance 0, crew 1
	DW	160,111, 170,133	; entrance 0, crew 2
	DW	160,111, 191,131	; entrance 0, crew 3
	DW	104,178, 135,163	; entrance 1, crew 0
	DW	87,187, 100,153	; entrance 1, crew 1
	DW	117,187, 90,169	; entrance 1, crew 2
	DW	103,198, 103,183	; entrance 1, crew 3
	DW	0,0, 0,0	; entrance 2, crew 0
	DW	0,0, 0,0	; entrance 2, crew 1
	DW	0,0, 0,0	; entrance 2, crew 2
	DW	0,0, 0,0	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	187,141, 208,137, 170,133, 191,131	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	0,0, 0,0
; (the header is cut short at 00C2, where the room's data starts)
rdf_objects	LABEL	BYTE
	DW	80FFh, 116, 165	; actions (bit 15 set), walk to (x, y)
	DW	20h, 6	; id, points
	DW	107,158, 107,153, 116,150, 124,150, 124,155, 120,158
	DW	80FFh, 105, 188	; actions (bit 15 set), walk to (x, y)
	DW	21h, 4	; id, points
	DW	104,184, 140,182, 145,197, 121,198
	DW	80FFh, 77, 169	; actions (bit 15 set), walk to (x, y)
	DW	22h, 6	; id, points
	DW	35,142, 71,142, 72,152, 49,159, 34,156, 36,146
	DW	80FFh, 188, 161	; actions (bit 15 set), walk to (x, y)
	DW	23h, 8	; id, points
	DW	166,147, 166,137, 176,131, 196,131, 209,135, 208,145
	DW	199,154, 172,154
	DW	80FFh, 241, 168	; actions (bit 15 set), walk to (x, y)
	DW	24h, 5	; id, points
	DW	235,154, 264,162, 261,196, 235,192, 220,176
	DW	25h, 4	; id, points
	DW	153,87, 170,87, 180,121, 143,121
	DW	26h, 4	; id, points
	DW	71,199, 71,186, 133,186, 133,199
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	0, 4	; id, points
	DW	153,103, 170,103, 170,106, 153,106
	DW	1, 4	; id, points
	DW	71,199, 71,196, 133,196, 133,199
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	143,105, 180,105, 180,121, 143,121
	DW	1, 4	; id, points
	DW	71,195, 71,186, 133,186, 133,195

rdf_scripts:
rdf_regions_end:
rdf_bans:
rdf_bans_end:
; The room starts: Mudd, the first time.
H_01E0:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0225
StartRoom:
	jmp	SHORT L01F1

N_MUD0LOOP	LABEL	BYTE
	DB	'MUD0LOOP',0
L01F1:
	push	OFFSET N_MUD0LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUD0LOOP")
	add	sp, 4
	cmp	byte ptr [si+mudd_talk], 0
	mov	byte ptr [si+RS_BUSY], 2
	push	0
	push	0A9h
	push	0A2h
	push	OFFSET N_s4cbhr
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s4cbhr", 162, 169, 0)
	add	sp, 0Ch
	retf

	DB	0C6h, 44h, 29h, 2, 0CBh

; Tick 50: the music, once.
H_0225:
	SCRIPT	MSG_TICK, 32h, 0, 0, H_0242
MusicStarts:
	cmp	byte ptr [si+music_started], 0
	jne	L0241
	push	3
	push	RC_MUSIC
	SERVICE		; Music(3)
	add	sp, 4
	mov	byte ptr [si+music_started], 1
L0241:
	retf

; Tick 60, the first time: Mudd explains himself, nine lines in a row
; (one Talk per conversation pushed).
H_0242:
	SCRIPT	MSG_TICK, 3Ch, 0, 0, H_0281
MuddWelcomes:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+mudd_talk], 0
	jne	L0280
	inc	byte ptr [si+mudd_talk]
	push	OFFSET MuddWelcome9
	push	OFFSET KirkWelcome8
	push	OFFSET MuddWelcome7
	push	OFFSET KirkWelcome6
	push	OFFSET MuddWelcome5
	push	OFFSET McCoyWelcome4
	push	OFFSET MuddWelcome3
	push	OFFSET KirkWelcome2
	push	OFFSET MuddWelcome1
	mov	di, 9
L0273:
	push	RC_TALK
	SERVICE		; Talk(MuddWelcome1); Talk(KirkWelcome2); Talk(MuddWelcome3); Talk(McCoyWelcome4); Talk(MuddWelcome5); Talk(KirkWelcome6); Talk(MuddWelcome7); Talk(KirkWelcome8); Talk(MuddWelcome9)
	add	sp, 4
	dec	di
	jne	L0273
L0280:
	retf

; Phasers on Mudd, and the communicator (static).
H_0281:
	SCRIPT	MSG_USE, IT_PHASERS, 8, 0, H_0289
	jmp	SHORT PhaserMudd

H_0289:
	SCRIPT	MSG_USE, IT_PHASERK, 8, 0, H_0299
PhaserMudd:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD0_025
	call	Say
	retf

H_0299:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_0307
CallEnterprise:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD0_001
	call	Say
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_STATICU1
	call	Say
	retf

T_MUD0_001	LABEL	BYTE
	DB	'#MUD0\MUD0_001#Kirk to Enterprise...',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
T_STATICU1	LABEL	BYTE
	DB	'#SFX\STATICU1#Ent... neu ... trans...',0

; Looking: narration conversations (no speaker), through TalkPushed.
H_0307:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_032B
LookAtFoodCrate:
	mov	byte ptr [si+RS_FALL], 1
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	push	OFFSET FoodCrate
TalkPushed:
	push	RC_TALK
	SERVICE		; Talk(?)
	add	sp, 4
	retf

H_032B:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_0346
LookAtPartsCrate:
	mov	byte ptr [si+RS_FALL], 1
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	push	OFFSET PartsCrate
	jmp	SHORT TalkPushed

H_0346:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_0351
LookAtScene:
	push	OFFSET ScanBay
	jmp	SHORT TalkPushed

H_0351:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_036C
LookAtDisks:
	mov	byte ptr [si+RS_FALL], 0
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	push	OFFSET Disks
	jmp	SHORT TalkPushed

H_036C:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_0387
LookAtDegrimer:
	mov	byte ptr [si+RS_FALL], 3
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	push	OFFSET Degrimer
	jmp	SHORT TalkPushed

H_0387:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_03A3
LookAtLenses:
	mov	byte ptr [si+RS_FALL], 2
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	push	OFFSET Lenses
	JMPN	TalkPushed

H_03A3:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_03D0
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
	push	OFFSET Bay
	JMPN	TalkPushed

H_03D0:
	SCRIPT	MSG_USE, IT_MTRICOR, ANY, 0, H_03FD
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
	push	OFFSET McCoyOnBay
	JMPN	TalkPushed

; Tricorders.
H_03FD:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_042E
SpockScansDisks:
	mov	byte ptr [si+RS_FALL+1], 0
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
	push	OFFSET SpockOnDisks
	JMPN	TalkPushed

H_042E:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_045F
SpockScansDegrimer:
	mov	byte ptr [si+RS_FALL+1], 3
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
	push	OFFSET Device
	JMPN	TalkPushed

H_045F:
	SCRIPT	MSG_USE, IT_MTRICOR, 21h, 0, H_049A
McCoyScansLenses:
	mov	byte ptr [si+RS_FALL+2], 2
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscane
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscane", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET McCoyOnLenses
	cmp	byte ptr [si+used_device], 0
	je	L0496
	mov	ax, OFFSET McCoyOnLenses2
L0496:
	push	ax
	JMPN	TalkPushed

; Common to all of the mission's rooms: the de-grimer on the lenses makes
; the alien device (+1); firing the device sets off an explosion at Kirk
; (anim msg 9), +5 the first time anywhere; the de-grimer on anything else
; just cleans it.
H_049A:
	SCRIPT	MSG_USE, IT_LENSES, IT_DEGRIME, 0, H_04C4
CleanLenses:
	push	IT_LENSES
	push	RC_TAKEITEM
	push	IT_DEGRIME
	push	RC_TAKEITEM
	push	IT_ALIENDV
	push	RC_GIVEITEM
	mov	di, 3
L04AF:
	SERVICE		; GiveItem(IT_ALIENDV); TakeItem(IT_DEGRIME); TakeItem(IT_LENSES)
	add	sp, 4
	dec	di
	jne	L04AF
	add	word ptr [si+score], 1
	push	OFFSET LensesFit
	JMPN	TalkPushed

H_04C4:
	SCRIPT	MSG_USE, IT_ALIENDV, ANY, 0, H_0517
FireDevice:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 1
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	push	0
	push	RC_ACTORPOS
	SERVICE		; ActorPos(0)
	add	sp, 4
	push	9
	push	0Ah
	push	ax
	push	OFFSET N_s4cbxp
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s4cbxp", ?, 10, 9)
	add	sp, 0Ch
	jmp	SHORT L0507

N_EXPLO3	LABEL	BYTE
	DB	'EXPLO3',0
L0507:
	push	OFFSET N_EXPLO3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EXPLO3")
	add	sp, 4
	retf

H_0517:
	SCRIPT	MSG_ANIM_DONE, 9, 0, 0, H_0536
DeviceFired:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+used_device], 0
	jne	L0535
	mov	byte ptr [si+used_device], 1
	add	word ptr [si+score], 5
	push	OFFSET KirkOnDevice
	JMPN	TalkPushed

L0535:
	retf

H_0536:
	SCRIPT	MSG_USE, IT_DEGRIME, ANY, 0, H_0542
UseDegrimer:
	push	OFFSET Degrimed
	JMPN	TalkPushed

; Taking the lenses, the disks and the de-grimer (+1 each, once).
H_0542:
	SCRIPT	MSG_GET, 21h, 0, 0, H_0584
GetLenses:
	cmp	byte ptr [si+took_lenses], 0
	je	L0551
	JMPN	L05F8

L0551:
	mov	byte ptr [si+took_lenses], 1
	add	word ptr [si+score], 1
	push	IT_LENSES
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_LENSES)
	add	sp, 4
	mov	byte ptr [si+RS_FALL], 2
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r1kg
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r1kg", -1, -1, 0)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+2], 1Bh
	retf

H_0584:
	SCRIPT	MSG_GET, 20h, 0, 0, H_05BE
GetDisks:
	cmp	byte ptr [si+took_disks], 0
	jne	L05F8
	mov	byte ptr [si+took_disks], 1
	add	word ptr [si+score], 1
	push	IT_DISKS
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_DISKS)
	add	sp, 4
	mov	byte ptr [si+RS_FALL], 0
	push	1
	push	-1
	push	-1
	push	OFFSET N_kuseln
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseln", -1, -1, 1)
	add	sp, 0Ch
	retf

H_05BE:
	SCRIPT	MSG_GET, 22h, 0, 0, H_05FE
GetDegrimer:
	cmp	byte ptr [si+took_degrimer], 0
	jne	L05F8
	mov	byte ptr [si+took_degrimer], 1
	add	word ptr [si+score], 1
	push	IT_DEGRIME
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_DEGRIME)
	add	sp, 4
	mov	byte ptr [si+RS_FALL], 1
	push	1
	push	-1
	push	-1
	push	OFFSET N_kusemw
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemw", -1, -1, 1)
	add	sp, 0Ch
	retf

L05F8:
	push	OFFSET AlreadyHave
	JMPN	TalkPushed

; Timer 1, or the reaching animation done (msg 1): "Done."
H_05FE:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_0612
TookItem:
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	jmp	SHORT TookItem2

H_0612:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_0622
TookItem2:
	mov	byte ptr [si+RS_BUSY], 0
	push	OFFSET Done
	JMPN	TalkPushed

; The doors: walk there; at the step the door slides (regions 0, 1).
H_0622:
	SCRIPT	MSG_WALK, 26h, 0, 0, H_0646
WalkToLowerDoor:
	mov	byte ptr cs:going_door, 1
	mov	byte ptr [si+RS_BUSY], 1
	push	0
	push	0C7h
	push	5Ah
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 90, 199, 0)
	add	sp, 0Ah
	retf

H_0646:
	SCRIPT	MSG_REGION, 1, 0, 0, H_066F
ReachLowerDoor:
	cmp	byte ptr cs:going_door, 1
	jne	L066E
	jmp	SHORT L065F

N_SMADOOR3	LABEL	BYTE
	DB	'SMADOOR3',0
L065F:
	push	OFFSET N_SMADOOR3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SMADOOR3")
	add	sp, 4
L066E:
	retf

H_066F:
	SCRIPT	MSG_WALK, 25h, 0, 0, H_069F
WalkToUpperDoor:
	mov	byte ptr cs:going_door, 1
	mov	byte ptr [si+RS_BUSY], 1
	push	0
	push	68h
	push	0A0h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 160, 104, 0)
	add	sp, 0Ah
	retf

; Talk: conversation AX (speaker, choices, 0); returns the choice.
Talk:
	push	ax
	push	RC_TALK
	SERVICE		; Talk(?)
	add	sp, 4
	ret

H_069F:
	SCRIPT	MSG_REGION, 0, 0, 0, H_06DE
ReachUpperDoor:
	cmp	byte ptr cs:going_door, 1
	jne	L06DD
	jmp	SHORT L06B8

N_SMADOOR3_2	LABEL	BYTE
	DB	'SMADOOR3',0
L06B8:
	push	OFFSET N_SMADOOR3_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SMADOOR3")
	add	sp, 4
	push	0
	push	6Bh
	push	0A0h
	push	OFFSET N_s4cbdo
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "s4cbdo", 160, 107, 0)
	add	sp, 0Ch
L06DD:
	retf

; The medkit, and looking and talking.
H_06DE:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, H_0741
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD0_011
	call	Say
	retf

T_MUD0_011	LABEL	BYTE
	DB	'#MUD0\MUD0_011#Everyone is healthy, Jim, there''s no need for the'
	DB	' medical kit here.',0

H_0741:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_0750
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_MUD0N004
	call	Say
	retf

H_0750:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_075F
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_MUD0N007
	call	Say
	retf

H_075F:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_076E
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_MUD0N001
	call	Say
	retf

H_076E:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_077D
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_MUD0N005
	call	Say
	retf

H_077D:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_078C
LookAtMudd:
	sub	ax, ax
	mov	bx, OFFSET T_MUD0N003
	call	Say
	retf

H_078C:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_07BE
TalkToKirk:
	cmp	byte ptr [si+mudd_talk], 2
	je	L07B4
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD0_010
	call	Say
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD0_031
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD0_007
	call	Say
	retf

L07B4:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD0_010
	call	Say
	retf

H_07BE:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0802
TalkToSpock:
	cmp	byte ptr [si+mudd_talk], 2
	je	L07F8
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD0_022
	call	Say
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD0_034
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD0_023
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD0_015
	call	Say
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD0_038
	call	Say
	retf

L07F8:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD0_022
	call	Say
	retf

H_0802:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_083D
TalkToMcCoy:
	cmp	byte ptr [si+mudd_talk], 2
	je	L0833
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD0_016
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD0_003
	call	Say
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD0_027
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD0_014
	call	Say
	retf

L0833:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD0_016
	call	Say
	retf

H_083D:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0881
TalkToRedshirt:
	cmp	byte ptr [si+mudd_talk], 2
	je	L086E
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD0_040
	call	Say
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD0_030
	call	Say
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD0_041
	call	Say
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD0_036
	call	Say
	retf

L086E:
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD0_039
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD0_008
	call	Say
	retf

H_0881:
	SCRIPT	MSG_TALK, 8, 0, 0, H_08AC
TalkToMudd:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD0_032
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD0_024
	call	Say
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD0_035
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD0_004
	call	Say
	retf

; Every tick, common to all of the mission's rooms: while life support is
; failing, the air runs down from 6978h, with warnings at 4F1Ah, 34BCh
; and 1A5Eh; at 1 the crew collapse (walk msgs 9-12) and the game is
; over.
H_08AC:
	SCRIPT	MSG_TICK, ANY, ANY, ANY, H_0A54
AirRunsOut:
	cmp	byte ptr [si+air_failing], 0
	jne	L08BB
	JMPN	L0958

L08BB:
	cmp	word ptr [si+air_countdown], 1
	je	L08CB
	mov	word ptr [si+air_countdown], 1
	mov	word ptr [si+air_left], 6978h
L08CB:
	dec	word ptr [si+air_left]
	cmp	word ptr [si+air_left], 1A5Eh
	jne	L08D8
	JMPN	L096D

L08D8:
	cmp	word ptr [si+air_left], 34BCh
	jne	L08E2
	JMPN	L0963

L08E2:
	cmp	word ptr [si+air_left], 4F1Ah
	je	L0959
	cmp	word ptr [si+air_left], 1
	jne	L0958
	mov	byte ptr [si+RS_BUSY], 1
	push	9
	push	8Dh
	push	0BBh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 187, 141, 9)
	add	sp, 0Ah
	push	0Ah
	push	89h
	push	0D0h
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 208, 137, 10)
	add	sp, 0Ah
	push	0Bh
	push	85h
	push	0AAh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 170, 133, 11)
	add	sp, 0Ah
	push	0Ch
	push	83h
	push	0BFh
	push	3
	push	RC_WALK
	SERVICE		; Walk(3, 191, 131, 12)
	add	sp, 0Ah
	mov	ax, OFFSET S_0BB6
	mov	bx, OFFSET T_MUD0N006
	call	Say
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
L0958:
	retf

L0959:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD0_020
	call	Say
	retf

L0963:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD0_019
	call	Say
	retf

L096D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD0_018
	call	Say
	retf

T_MUD0_020	LABEL	BYTE
	DB	'#MUD0\MUD0_020#Life support down to 75%, Captain.',0
T_MUD0_019	LABEL	BYTE
	DB	'#MUD0\MUD0_019#Life support down to 50%, Captain.',0
T_MUD0_018	LABEL	BYTE
	DB	'#MUD0\MUD0_018#Life support down to 25%, Captain.',0
T_MUD0N006	LABEL	BYTE
	DB	'#MUD0\MUD0N006#Life support fails completely and you fall uncons'
	DB	'cious.',0

H_0A54:
	SCRIPT	MSG_WALK_DONE, 9, 0, 0, H_0A71
KirkCollapses:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kgetdw
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kgetdw", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0AC6

H_0A71:
	SCRIPT	MSG_WALK_DONE, 0Ah, 0, 0, H_0A8E
SpockCollapses:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sgetds
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sgetds", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0AC6

H_0A8E:
	SCRIPT	MSG_WALK_DONE, 0Bh, 0, 0, H_0AAB
McCoyCollapses:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mgetdn
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mgetdn", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0AC6

H_0AAB:
	SCRIPT	MSG_WALK_DONE, 0Ch, 0, 0, N_Capt_Kirk
RedshirtCollapses:
	push	0
	push	-1
	push	-1
	push	OFFSET N_rgetde
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rgetde", -1, -1, 0)
	add	sp, 0Ch
L0AC6:
	inc	byte ptr cs:collapsed
	cmp	byte ptr cs:collapsed, 4
	jne	L0ADC
	mov	ax, OFFSET S_0BB6
	mov	bx, OFFSET T_MUD0N009
	call	Say
L0ADC:
	retf

T_MUD0N009	LABEL	BYTE
	DB	'#MUD0\MUD0N009#The atmosphere in the ship has dropped below the '
	DB	'level needed to sustain life. You drop to unconsciousness and sl'
	DB	'owly die.',0
; Say: one line, BX, said by AX (0: narration).
Say:
	mov	word ptr cs:talk_buf, ax
	mov	word ptr cs:talk_buf+2, bx
	mov	ax, OFFSET talk_buf
	call	Talk
	ret

talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0
rdf_scripts_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
	DB	'Prel. Angiven',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Buchert	LABEL	BYTE
	DB	'Lt. Buchert',0
S_0BB6	LABEL	BYTE
	DB	0
N_Harry_Mudd	LABEL	BYTE
	DB	'Harry Mudd',0
MuddWelcome1	LABEL	BYTE
	DW	OFFSET N_Harry_Mudd, OFFSET T_MUD0_037, 0	; speaker, choices, 0
KirkWelcome2	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_MUD0_009, 0	; speaker, choices, 0
MuddWelcome3	LABEL	BYTE
	DW	OFFSET N_Harry_Mudd, OFFSET T_MUD0_028, 0	; speaker, choices, 0
McCoyWelcome4	LABEL	BYTE
	DW	OFFSET N_Dr_McCoy, OFFSET T_MUD0_017, 0	; speaker, choices, 0
MuddWelcome5	LABEL	BYTE
	DW	OFFSET N_Harry_Mudd, OFFSET T_MUD0_026, 0	; speaker, choices, 0
KirkWelcome6	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_MUD0_006, 0	; speaker, choices, 0
MuddWelcome7	LABEL	BYTE
	DW	OFFSET N_Harry_Mudd, OFFSET T_MUD0_033, 0	; speaker, choices, 0
KirkWelcome8	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_MUD0_005, 0	; speaker, choices, 0
MuddWelcome9	LABEL	BYTE
	DW	OFFSET N_Harry_Mudd, OFFSET T_MUD0_029, 0	; speaker, choices, 0
T_MUD0_037	LABEL	BYTE
	DB	'#MUD0\MUD0_037#Welcome, Captain Kirk! So glad you''re here. The E'
	DB	'lasi have been terrible trouble to me.',0
T_MUD0_009	LABEL	BYTE
	DB	'#MUD0\MUD0_009#Well, you''re terrible trouble to me, Harry. Tell '
	DB	'me what this is all about.',0
T_MUD0_028	LABEL	BYTE
	DB	'#MUD0\MUD0_028#I happened upon this ship not long ago, and dutif'
	DB	'ully registered it as salvage, mind you!  In the hold here, I di'
	DB	'scovered one of these devices -- in that box over there. When I '
	DB	'tried one on a wall, it floated off the grease and dirt -- perfe'
	DB	'ct for cleaning, near as I could see. I peddled a few of these M'
	DB	'udd''s Miracle De-Grimers and everything was going perfectly well'
	DB	'.',0
T_MUD0_017	LABEL	BYTE
	DB	'#MUD0\MUD0_017#Then something went wrong, right?',0
T_MUD0_026	LABEL	BYTE
	DB	'#MUD0\MUD0_026#Actually no, Doctor, not then. I''d started offeri'
	DB	'ng a few other little items I found -- Mudd''s Limited coffee sub'
	DB	'stitute -- a great little specialty item; lenses to a firm packa'
	DB	'ging BuildYerOwn telescope kits; a collection of novelty paints '
	DB	'-- things like that.  All of a sudden, the Elasi pirates are ask'
	DB	'ing for me in every quadrant, and wanting to know where I''m gett'
	DB	'ing my goods!',0
T_MUD0_006	LABEL	BYTE
	DB	'#MUD0\MUD0_006#I see, Harry. Well, we''ll look around here while '
	DB	'the Enterprise remains close by.',0
T_MUD0_033	LABEL	BYTE
	DB	'#MUD0\MUD0_033#Look around all you like, Captain, but I''ll be ke'
	DB	'eping an eye on you.  I''ve registered this derelict as my salvag'
	DB	'e, and I don''t want you running off with all my prizes! ',0
T_MUD0_005	LABEL	BYTE
	DB	'#MUD0\MUD0_005#Harry, as official representatives of the Federat'
	DB	'ion, and of Starfleet, we recognize your rights to legitimate sa'
	DB	'lvage.  Need I say more?  ',0
T_MUD0_029	LABEL	BYTE
	DB	'#MUD0\MUD0_029#I understand perfectly, Captain -- Carry on, Capt'
	DB	'ain.',0
FoodCrate	LABEL	BYTE
	DW	0, OFFSET T_MUD0N012, 0	; speaker, choices, 0
PartsCrate	LABEL	BYTE
	DW	0, OFFSET T_MUD0N013, 0	; speaker, choices, 0
ScanBay	LABEL	BYTE
	DW	0, OFFSET T_MUD0N019, 0	; speaker, choices, 0
Bay	LABEL	BYTE
	DW	0, OFFSET T_MUD0N015, 0	; speaker, choices, 0
McCoyOnBay	LABEL	BYTE
	DW	OFFSET N_Dr_McCoy, OFFSET T_MUD0N015, 0	; speaker, choices, 0
Disks	LABEL	BYTE
	DW	0, OFFSET T_MUD0N010, 0	; speaker, choices, 0
SpockOnDisks	LABEL	BYTE
	DW	OFFSET N_Mr_Spock, OFFSET T_MUD0_021, 0	; speaker, choices, 0
	DB	0A0h, 0Bh, 5Fh, 14h, 0, 0
Degrimer	LABEL	BYTE
	DW	0, OFFSET T_MUD0N008, 0	; speaker, choices, 0
Device	LABEL	BYTE
	DW	0, OFFSET T_MUD0N000, 0	; speaker, choices, 0
Degrimed	LABEL	BYTE
	DW	0, OFFSET T_MUD0N002, 0	; speaker, choices, 0
Lenses	LABEL	BYTE
	DW	0, OFFSET T_MUD0N014, 0	; speaker, choices, 0
McCoyOnLenses	LABEL	BYTE
	DW	OFFSET N_Dr_McCoy, OFFSET T_MUD0_013, 0	; speaker, choices, 0
McCoyOnLenses2	LABEL	BYTE
	DW	OFFSET N_Dr_McCoy, OFFSET T_MUD0_012, 0	; speaker, choices, 0
LensesFit	LABEL	BYTE
	DW	0, OFFSET T_MUD0N011, 0	; speaker, choices, 0
Done	LABEL	BYTE
	DW	0, OFFSET T_LOV1N007, 0	; speaker, choices, 0
AlreadyHave	LABEL	BYTE
	DW	0, OFFSET T_MUD0N016, 0	; speaker, choices, 0
	DB	0, 0, 85h, 22h, 0, 0
KirkOnDevice	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_MUD0_002, 0	; speaker, choices, 0
T_MUD0N012	LABEL	BYTE
	DB	'#MUD0\MUD0N012#This container holds bricks of what might have be'
	DB	'en preprocessed food -- a long time ago.',0
T_MUD0N013	LABEL	BYTE
	DB	'#MUD0\MUD0N013#This container holds small mechanical components '
	DB	'unfamiliar to you.',0
T_MUD0N019	LABEL	BYTE
	DB	'#MUD0\MUD0N019#This place is cluttered with stored goods of ever'
	DB	'y sort. It would take an army of workers weeks to examine every '
	DB	'container and determine what is inside.',0
T_MUD0N015	LABEL	BYTE
	DB	'#MUD0\MUD0N015#This storage bay is stockpiled with all manner of'
	DB	' goods.',0
T_MUD0N010	LABEL	BYTE
	DB	'#MUD0\MUD0N010#There are shiny, multi-sided, spherical objects i'
	DB	'n this box.',0
T_MUD0_021	LABEL	BYTE
	DB	'#MUD0\MUD0_021#These are computer memory transfer media, probabl'
	DB	'y designed for use with the alien computer system.',0
T_MUD0N008	LABEL	BYTE
	DB	'#MUD0\MUD0N008#Odd-looking contraptions small enough to hold in '
	DB	'one hand.',0
T_MUD0N000	LABEL	BYTE
	DB	'#MUD0\MUD0N000#A small energy device with a flanged opening at t'
	DB	'he front, about the size of one''s thumbnail.',0
T_MUD0N002	LABEL	BYTE
	DB	'#MUD0\MUD0N002#Dust and grease lifts off the surface, leaving th'
	DB	'is item clean as new.',0
T_MUD0N014	LABEL	BYTE
	DB	'#MUD0\MUD0N014#This lense, about the size of one''s thumbnail, ma'
	DB	'gnifies like a fine optical glass.  ',0
T_MUD0_013	LABEL	BYTE
	DB	'#MUD0\MUD0_013#These lenses are finely made magnifiers, but I ca'
	DB	'n''t help but wonder if that''s what the aliens really used them f'
	DB	'or. ',0
T_MUD0_012	LABEL	BYTE
	DB	'#MUD0\MUD0_012#These lenses were definitely not made to correct '
	DB	'the aliens'' vision. Mudd might''ve been able to sell these among '
	DB	'humans as magnifiers, but these people must have had another use'
	DB	' for them.',0
T_MUD0N011	LABEL	BYTE
	DB	'#MUD0\MUD0N011#These two things fit together like they were made'
	DB	' for each other.',0
T_MUD0N004	LABEL	BYTE
	DB	'#MUD0\MUD0N004#James T. Kirk looks rather exasperated right now.'
	DB	' ',0
T_MUD0N007	LABEL	BYTE
	DB	'#MUD0\MUD0N007#Mr. Spock is as close to annoyed as a Vulcan can '
	DB	'get. ',0
T_MUD0N001	LABEL	BYTE
	DB	'#MUD0\MUD0N001#Dr. McCoy looks like he would like to violate the'
	DB	' Hippocratic Oath on Harry Mudd, but you know he won''t. ',0
T_MUD0N005	LABEL	BYTE
	DB	'#MUD0\MUD0N005#Lieutenant Buchert is standing around, watching e'
	DB	'veryone else converse with Harry Mudd. ',0
T_MUD0N003	LABEL	BYTE
	DB	'#MUD0\MUD0N003#Harcourt Fenton Mudd. Of course, he''s going to be'
	DB	' honest and fair with you... ',0
T_MUD0_010	LABEL	BYTE
	DB	'#MUD0\MUD0_010#Why do I have the feeling that I am about to have'
	DB	' a bad day? ',0
T_MUD0_031	LABEL	BYTE
	DB	'#MUD0\MUD0_031#Kirk! Now that we''re together... ',0
T_MUD0_007	LABEL	BYTE
	DB	'#MUD0\MUD0_007#It was a rhetorical question, Harry. ',0
T_MUD0_022	LABEL	BYTE
	DB	'#MUD0\MUD0_022#Given the past record of Harry Mudd, Captain, I s'
	DB	'trongly recommend that you do not trust him. ',0
T_MUD0_034	LABEL	BYTE
	DB	'#MUD0\MUD0_034#Mr. Spock! Whatever gave you that impression! I t'
	DB	'hought Vulcans were supposed to be logical. ',0
T_MUD0_023	LABEL	BYTE
	DB	'#MUD0\MUD0_023#I am. Your record is that of a greedy, amoral, so'
	DB	'ciopathic fraud who preys upon human emotion, most notably, gull'
	DB	'ability. ',0
T_MUD0_015	LABEL	BYTE
	DB	'#MUD0\MUD0_015#For once Spock, I couldn''t have said it better my'
	DB	'self. ',0
T_MUD0_038	LABEL	BYTE
	DB	'#MUD0\MUD0_038#Why I''ve never been so insulted in all my life! ',0
T_MUD0_016	LABEL	BYTE
	DB	'#MUD0\MUD0_016#Jim? You can''t seriously be thinking of helping M'
	DB	'udd after all he''s done. ',0
T_MUD0_003	LABEL	BYTE
	DB	'#MUD0\MUD0_003#Bones, Federation law is clear on this. Federatio'
	DB	'n law protects everyone, even Harry Mudd. ',0
T_MUD0_027	LABEL	BYTE
	DB	'#MUD0\MUD0_027#And we all know how devoted I am to Federation la'
	DB	'w. ',0
T_MUD0_014	LABEL	BYTE
	DB	'#MUD0\MUD0_014#About as much as the Klingons are devoted to paci'
	DB	'fism... ',0
T_MUD0_032	LABEL	BYTE
	DB	'#MUD0\MUD0_032#Kirk, my friend! When have I ever given you the s'
	DB	'lightest bit of trouble? ',0
T_MUD0_024	LABEL	BYTE
	DB	'#MUD0\MUD0_024#There was the time that you tried to commandeer t'
	DB	'he Enterprise to sell wives to miners, and then there was the ti'
	DB	'me you stole the Enterprise to exchange us for androids who were'
	DB	' holding you prisoner... ',0
T_MUD0_035	LABEL	BYTE
	DB	'#MUD0\MUD0_035#Perhaps there have been a few minor misunderstand'
	DB	'ings... ',0
T_MUD0_004	LABEL	BYTE
	DB	'#MUD0\MUD0_004#Don''t push your luck, Harry. ',0
T_MUD0_040	LABEL	BYTE
	DB	'#MUD0\MUD0_040#So you say you know how to break the gambling mac'
	DB	'hines on Curalon IV? ',0
T_MUD0_030	LABEL	BYTE
	DB	'#MUD0\MUD0_030#It''s a system that cost a gambler his life, boy. '
	DB	'He crawled up to me and whispered it with his dying breath, and '
	DB	'it can be yours for a mere... 200 credits. ',0
T_MUD0_041	LABEL	BYTE
	DB	'#MUD0\MUD0_041#Sorry Mr. Mudd. My mother didn''t raise any fools '
	DB	'in her family. ',0
T_MUD0_036	LABEL	BYTE
	DB	'#MUD0\MUD0_036#Starfleet! You''re all the same. No sense of adven'
	DB	'ture! ',0
T_MUD0_039	LABEL	BYTE
	DB	'#MUD0\MUD0_039#Didn''t Mudd bring those tribbles on board the Ent'
	DB	'erprise?',0
T_MUD0_008	LABEL	BYTE
	DB	'#MUD0\MUD0_008#No Lieutenant, that was Horatio Jones, but Harry '
	DB	'Mudd is worse.',0
T_MUD0_025	LABEL	BYTE
	DB	'#MUD0\MUD0_025#Kirk, after all we''ve been through you wouldn''t s'
	DB	'hoot me would you?',0
T_MUD0_002	LABEL	BYTE
	DB	'#MUD0\MUD0_002#Well! Now I think we know why the Elasi pirates w'
	DB	'ere so interested in finding out where Mudd was getting these!',0
T_LOV1N007	LABEL	BYTE
	DB	'#LOV1\LOV1N007#Done.',0
T_MUD0N016	LABEL	BYTE
	DB	'#MUD0\MUD0N016#You already have that.',0
	DB	'#MUD0\MUD0N017#You can''t take that.',0
; In the room file, so these start again each time the room loads
going_door	LABEL	BYTE	; Kirk is on his way to a door
	DB	0
collapsed	LABEL	BYTE	; crew members down when the air ran out
	DB	0
N_s4cbhr	LABEL	BYTE
	DB	's4cbhr',0
N_s4cbdo	LABEL	BYTE
	DB	's4cbdo',0
N_s4cbxp	LABEL	BYTE
	DB	's4cbxp',0
N_s5r1kg	LABEL	BYTE
	DB	's5r1kg',0
N_kusemw	LABEL	BYTE
	DB	'kusemw',0
N_kuseln	LABEL	BYTE
	DB	'kuseln',0
N_kgetdw	LABEL	BYTE
	DB	'kgetdw',0
N_sgetds	LABEL	BYTE
	DB	'sgetds',0
N_mgetdn	LABEL	BYTE
	DB	'mgetdn',0
N_rgetde	LABEL	BYTE
	DB	'rgetde',0
N_sscann	LABEL	BYTE
	DB	'sscann',0
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_sscanw	LABEL	BYTE
	DB	'sscanw',0
N_mscans	LABEL	BYTE
	DB	'mscans',0
N_mscane	LABEL	BYTE
	DB	'mscane',0

RDF	ENDS
	END
