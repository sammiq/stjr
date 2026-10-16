; DEMON4.RDF - "Demon World", the alien chamber behind the door, and the
; end of the mission. The "demons" are made by the machines here, which
; guard a Nauian who sleeps in a cryogenic chamber. Working the lever panel
; (the lever puzzle) wakes it. Kirk can then talk to the Nauian, and give it
; the key (the metal piece from Brother Stephen) to shut the guardians down
; and the skull to show it its kind survived. Phasers anger it, and it kills
; the landing party. With the key in, timer 1 beams the party up.
;
; Actors: 8 the Nauian, 9 the lever panel, 10 (0Ah) the chamber.
; Objects: 8 the Nauian, 0Ah the chamber, 20h the art (an eclipse), 21h
; the lever panel, 22h the security console, 23h the floor.
; Exit 1: back out (room 3).
; Timers: 0 the chamber opens, 1 beaming up, 2-5 the Nauian kills Spock,
; Everts, McCoy and Kirk, 6 McCoy remembers the skull.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - never_set is never set, so the Federation ending in TalkToNauian (the
;   same lines as KeyTurned) can't be reached.
; - The script chain runs on into code at 0EA7: the engine reads its bytes
;   as key 50 B8 03 00 and next 2E50 (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
insulted_stephen	EQU	RS_VARS+2	; word: Kirk called his collection junk (room 6)
rude_to_nauian	EQU	RS_VARS+4	; word
healed_miner	EQU	RS_VARS+13h
miner_dead	EQU	RS_VARS+17h	; he died: the party left without treating him
gave_skull	EQU	RS_VARS+1Eh
nauian_awake	EQU	RS_VARS+25h	; the levers have opened the chamber
taken_items	EQU	RS_VARS+26h	; bits: items taken from Stephen's case (room 6): 0 the key, 4 the skull
talked_to_nauian	EQU	RS_VARS+2Ah
chamber_music	EQU	RS_VARS+2Eh	; the music has started
score	EQU	RS_VARS+2Fh	; word: the mission's score

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0BFh	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	82h
rdf_scale_min	LABEL	BYTE
	DW	0F6h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, 3, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	0,0, 0,0	; entrance 0, crew 0
	DW	0,0, 0,0	; entrance 0, crew 1
	DW	0,0, 0,0	; entrance 0, crew 2
	DW	0,0, 0,0	; entrance 0, crew 3
	DW	38,145, 129,144	; entrance 1, crew 0
	DW	38,145, 116,137	; entrance 1, crew 1
	DW	38,145, 110,152	; entrance 1, crew 2
	DW	38,145, 89,144	; entrance 1, crew 3
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
	DW	92,151, 82,141, 82,161, 72,151
; In the room file, so these start again each time the room loads
warned	LABEL	BYTE	; the Nauian has warned against phasers
	DB	0
nauian_out	LABEL	BYTE	; the Nauian has come out
	DB	0
never_set	LABEL	BYTE	; nothing sets it: TalkToNauian never reaches its Federation ending
	DB	0
dead	LABEL	BYTE	; the landing party has been killed
	DB	0
beaming	LABEL	BYTE	; crew members in place to beam up
	DB	0
lever_crew	LABEL	BYTE	; word: the crew member sent to the levers
	DB	0, 0, 0, 0
N_bxfire	LABEL	BYTE
	DB	'bxfire',0
N_bxrise	LABEL	BYTE
	DB	'bxrise',0
N_bxrise2	LABEL	BYTE
	DB	'bxrise2',0
N_ctrl	LABEL	BYTE
	DB	'ctrl',0
N_stpout	LABEL	BYTE
	DB	'stpout',0
N_stpout2	LABEL	BYTE
	DB	'stpout2',0
N_takesk	LABEL	BYTE
	DB	'takesk',0
N_usekey	LABEL	BYTE
	DB	'usekey',0
N_kkille	LABEL	BYTE
	DB	'kkille',0
N_skille	LABEL	BYTE
	DB	'skille',0
N_mkille	LABEL	BYTE
	DB	'mkille',0
N_rkille	LABEL	BYTE
	DB	'rkille',0
	DB	'keylit',0
	DB	'seclit',0
	DB	'boxlit',0
N_kusemn	LABEL	BYTE
	DB	'kusemn',0
N_sscane	LABEL	BYTE
	DB	'sscane',0
N_mscane	LABEL	BYTE
	DB	'mscane',0

rdf_scripts:
; The room starts. The miner dies now if McCoy didn't treat him (room 3).
; If the Nauian is awake, it stands outside its chamber, and if the skull
; hasn't been shown, timer 6 has McCoy suggest it.
H_0151:
	SCRIPT	MSG_TICK, 1, 0, 0, H_01DF
StartRoom:
	jmp	SHORT L0162

N_DEM4LOOP	LABEL	BYTE
	DB	'DEM4LOOP',0
L0162:
	push	OFFSET N_DEM4LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("DEM4LOOP")
	add	sp, 4
	cmp	byte ptr [si+healed_miner], 1
	je	L017B
	mov	byte ptr [si+miner_dead], 1
L017B:
	cmp	byte ptr [si+nauian_awake], 1
	jne	L01C6
	push	0
	push	91h
	push	122h
	push	OFFSET N_bxrise2
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "bxrise2", 290, 145, 0)
	add	sp, 0Ch
	push	0
	push	92h
	push	107h
	push	OFFSET N_stpout2
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "stpout2", 263, 146, 0)
	add	sp, 0Ch
	mov	byte ptr cs:nauian_out, 1
	test	byte ptr [si+taken_items], 10h
	je	L01C6
	cmp	byte ptr [si+gave_skull], 1
	je	L01C6
	mov	word ptr [si+RS_TIMERS+12], 14h
L01C6:
	cmp	byte ptr [si+chamber_music], 1
	je	L01DE
	mov	byte ptr [si+chamber_music], 1
	push	-1
	push	1
	push	RC_MUSIC
	SERVICE		; Music(1, -1)
	add	sp, 6
L01DE:
	retf

; The chamber has opened (anim msg 1): the Nauian steps out.
H_01DF:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_020E
NauianStepsOut:
	push	5
	push	92h
	push	107h
	push	OFFSET N_stpout
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "stpout", 263, 146, 5)
	add	sp, 0Ch
	mov	byte ptr cs:nauian_out, 1
	test	byte ptr [si+taken_items], 10h
	je	L020D
	mov	word ptr [si+RS_TIMERS+12], 2Dh
L020D:
	retf

; Kirk has been killed (anim msg 2): game over, once.
H_020E:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_0239
PartyKilled:
	cmp	byte ptr cs:dead, 1
	je	L022A
	mov	byte ptr cs:dead, 1
	sub	ax, ax
	mov	bx, OFFSET T_DEM4N011
	call	Say
L022A:
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	mov	byte ptr [si+RS_BUSY], 0
	retf

; The Nauian has turned the key (anim msg 3): the guardians stop, and
; the Nauian asks to join the Federation; +5 score, and timer 1.
H_0239:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_03C6
KeyTurned:
	mov	ax, OFFSET N_Nauian
	mov	bx, OFFSET T_DEM4_034
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM4_010
	call	Say
	JMPN	L02E7

T_DEM4_010	LABEL	BYTE
	DB	'#DEM4\DEM4_010#I would be glad to accept your application to the'
	DB	' Federation. We shall have a diplomatic envoy sent to make the f'
	DB	'inal arrangements.',0
L02E7:
	mov	ax, OFFSET N_Nauian
	mov	bx, OFFSET T_DEM4_035
	call	Say
	JMPN	L0387

T_DEM4_035	LABEL	BYTE
	DB	'#DEM4\DEM4_035#We look forward to meeting them. We also look for'
	DB	'ward to having discourse with the colonists. Farewell.  May the '
	DB	'Holy One bless you.',0
L0387:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM4_030
	call	Say
	jmp	SHORT L03B8

T_DEM4_030	LABEL	BYTE
	DB	'#DEM4\DEM4_030#Live long and prosper.',0
L03B8:
	mov	byte ptr [si+RS_BUSY], 1
	add	word ptr [si+score], 5
	mov	word ptr [si+RS_TIMERS+2], 14h
	retf

; Timer 0, after the levers: the chamber rises (msg 1).
H_03C6:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_040E
ChamberOpens:
	push	1
	push	91h
	push	122h
	push	OFFSET N_bxrise
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "bxrise", 290, 145, 1)
	add	sp, 0Ch
	mov	byte ptr [si+RS_FALL], 2
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	jmp	SHORT L03FE

N_SE2POWER	LABEL	BYTE
	DB	'SE2POWER',0
L03FE:
	push	OFFSET N_SE2POWER
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SE2POWER")
	add	sp, 4
	retf

; Timer 1: the crew gather (msg 4)...
H_040E:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_04BC
BeamUp:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM4_011
	call	Say
	jmp	SHORT L045B

T_DEM4_011	LABEL	BYTE
	DB	'#DEM4\DEM4_011#Kirk to Enterprise... Beam us up, Mr. Scott.',0
L045B:
	push	4
	push	0A5h
	push	0BEh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 190, 165, 4)
	add	sp, 0Ah
	push	4
	push	9Bh
	push	0B4h
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 180, 155, 4)
	add	sp, 0Ah
	push	4
	push	9Bh
	push	0C8h
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 200, 155, 4)
	add	sp, 0Ah
	inc	byte ptr cs:beaming
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L04BB
	push	4
	push	91h
	push	0C1h
	push	3
	push	RC_WALK
	SERVICE		; Walk(3, 193, 145, 4)
	add	sp, 0Ah
	dec	byte ptr cs:beaming
L04BB:
	retf

; ...and once all four are there, beam up. +3 if Kirk didn't insult
; Brother Stephen, +2 if Everts is alive.
H_04BC:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_04FA
CrewInPlace:
	inc	byte ptr cs:beaming
	cmp	byte ptr cs:beaming, 4
	je	L04D0
	retf

L04D0:
	cmp	word ptr [si+insulted_stephen], 1
	je	L04DA
	add	word ptr [si+score], 3
L04DA:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 0
	jne	L04E4
	add	word ptr [si+score], 2
L04E4:
	push	0
	push	24h
	push	word ptr [si+score]
	push	RC_BEAMUP
	SERVICE		; BeamUp(?, 36, 0)
	add	sp, 8
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Timers 2-5: the Nauian kills the party, Kirk last (msg 2).
H_04FA:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_0516
KillSpock:
	push	0
	push	-1
	push	-1
	push	OFFSET N_skille
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "skille", -1, -1, 0)
	add	sp, 0Ch
	retf

H_0516:
	SCRIPT	MSG_TIMER, 3, 0, 0, H_0532
KillEverts:
	push	0
	push	-1
	push	-1
	push	OFFSET N_rkille
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rkille", -1, -1, 0)
	add	sp, 0Ch
	retf

H_0532:
	SCRIPT	MSG_TIMER, 4, 0, 0, H_054E
KillMcCoy:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mkille
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mkille", -1, -1, 0)
	add	sp, 0Ch
	retf

H_054E:
	SCRIPT	MSG_TIMER, 5, 0, 0, H_056A
KillKirk:
	push	2
	push	-1
	push	-1
	push	OFFSET N_kkille
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kkille", -1, -1, 2)
	add	sp, 0Ch
	retf

; Timer 6: McCoy on the skull.
H_056A:
	SCRIPT	MSG_TIMER, 6, 0, 0, H_057A
McCoyOnSkull:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM4_017
	call	Say
	retf

; Phasers on the Nauian: a warning, then it kills the party (msg 2,
; and timers 2-5).
H_057A:
	SCRIPT	MSG_USE, IT_PHASERK, 8, 0, H_0582
	jmp	SHORT PhaserNauian

H_0582:
	SCRIPT	MSG_USE, IT_PHASERS, 8, 0, H_05F2
PhaserNauian:
	cmp	byte ptr cs:warned, 1
	je	L05A1
	mov	ax, OFFSET N_Nauian
	mov	bx, OFFSET T_DEM4_033
	call	Say
	mov	byte ptr cs:warned, 1
	jmp	SHORT L05F1

L05A1:
	mov	ax, OFFSET N_Nauian
	mov	bx, OFFSET T_DEM4_032
	call	Say
	push	2
	push	0
	push	0
	push	OFFSET N_bxfire
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "bxfire", 0, 0, 2)
	add	sp, 0Ch
	jmp	SHORT L05CA

N_V0SPOCKT	LABEL	BYTE
	DB	'V0SPOCKT',0
L05CA:
	push	OFFSET N_V0SPOCKT
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("V0SPOCKT")
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 1
	mov	word ptr [si+RS_TIMERS+4], 7
	mov	word ptr [si+RS_TIMERS+6], 8
	mov	word ptr [si+RS_TIMERS+8], 7
	mov	word ptr [si+RS_TIMERS+10], 8
L05F1:
	retf

; The key in the console: it fits, but won't turn.
H_05F2:
	SCRIPT	MSG_USE, IT_METAL, 22h, 0, H_0611
UseKeyOnConsole:
	mov	byte ptr [si+RS_BUSY], 1
	push	5
	push	90h
	push	0F5h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 245, 144, 5)
	add	sp, 0Ah
	retf

H_0611:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_062D
KirkAtConsole:
	push	4
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 4)
	add	sp, 0Ch
	retf

H_062D:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_0697
KeyWontTurn:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, 0
	mov	bx, OFFSET T_DEM4N014
	call	Say
	jmp	SHORT L0696

T_DEM4N014	LABEL	BYTE
	DB	'#DEM4\DEM4N014#You fit the key into the slot, but you cannot fin'
	DB	'd a way to turn it.',0
L0696:
	retf

; The key to the Nauian (msgs 1, 3): +2 score.
H_0697:
	SCRIPT	MSG_USE, IT_METAL, 8, 0, H_06B6
GiveKey:
	push	1
	push	90h
	push	0E9h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 233, 144, 1)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL], 2
	retf

H_06B6:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_06E8
KirkAtNauian:
	push	3
	push	8Eh
	push	107h
	push	OFFSET N_usekey
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "usekey", 263, 142, 3)
	add	sp, 0Ch
	push	IT_METAL
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_METAL)
	add	sp, 4
	add	word ptr [si+score], 2
	and	byte ptr [si+taken_items], -2
	retf

; The skull to the Nauian (msg 2): +1 score.
H_06E8:
	SCRIPT	MSG_USE, IT_SKULL, 8, 0, H_0703
GiveSkull:
	push	2
	push	90h
	push	0E9h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 233, 144, 2)
	add	sp, 0Ah
	retf

H_0703:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_0760
ShowSkull:
	mov	ax, OFFSET N_Nauian
	mov	bx, OFFSET T_DEM4_036
	call	Say
	mov	ax, OFFSET KirkOnSkull
	call	Talk
	AX8	cmp, 0
	jne	L071F
	jmp	SHORT L0730

L071F:
	AX8	cmp, 1
	jne	L0726
	jmp	SHORT L075F

L0726:
	AX8	cmp, 2
	jne	L072D
	jmp	SHORT L075F

L072D:
	JMPN	L09B9

L0730:
	add	word ptr [si+score], 1
	push	0
	push	8Eh
	push	107h
	push	OFFSET N_takesk
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "takesk", 263, 142, 0)
	add	sp, 0Ch
	push	IT_SKULL
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_SKULL)
	add	sp, 4
	and	byte ptr [si+taken_items], -11h
	mov	byte ptr [si+gave_skull], 1
L075F:
	retf

; Phasers on the furniture and the crew.
H_0760:
	SCRIPT	MSG_USE, IT_PHASERS, 21h, 0, H_0770
PhaserLevers:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM4_013
	call	Say
	retf

H_0770:
	SCRIPT	MSG_USE, IT_PHASERS, 20h, 0, H_0780
PhaserArt:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM4_045
	call	Say
	retf

H_0780:
	SCRIPT	MSG_USE, IT_PHASERS, OBJ_MCCOY, 0, H_0790
PhaserMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM4_018
	call	Say
	retf

; Talking to the Nauian, the first time a conversation (rude_to_nauian
; if Kirk is rude), then "Have you found the key?".
H_0790:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_0798
	jmp	SHORT TalkToNauian

H_0798:
	SCRIPT	MSG_TALK, 8, 0, 0, H_09C3
TalkToNauian:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+talked_to_nauian], 1
	jne	L07DB
	mov	ax, OFFSET N_Nauian
	mov	bx, OFFSET T_DEM4_031
	call	Say
	jmp	SHORT L07DA

T_DEM4_031	LABEL	BYTE
	DB	'#DEM4\DEM4_031#Have you found the key?',0
L07DA:
	retf

L07DB:
	mov	byte ptr [si+talked_to_nauian], 1
	mov	ax, OFFSET NauianWakes
	call	Talk
	mov	ax, OFFSET KirkGreets
	call	Talk
	AX8	cmp, 0
	jne	L07F7
	mov	word ptr [si+rude_to_nauian], 1
	jmp	SHORT L0808

L07F7:
	AX8	cmp, 1
	jne	L07FE
	jmp	SHORT L0810

L07FE:
	AX8	cmp, 2
	jne	L0805
	jmp	SHORT L0818

L0805:
	JMPN	L09B9

L0808:
	mov	ax, OFFSET NauianOnTrespass
	call	Talk
	jmp	SHORT L0810

L0810:
	mov	ax, OFFSET NauianOnSleep
	call	Talk
	jmp	SHORT L0820

L0818:
	mov	ax, OFFSET NauianOnRepairs
	call	Talk
	jmp	SHORT L0810

L0820:
	mov	ax, OFFSET KirkAsks
	call	Talk
	AX8	cmp, 0
	jne	L0832
	mov	word ptr [si+rude_to_nauian], 1
	jmp	SHORT L083C

L0832:
	AX8	cmp, 1
	jne	L0839
	jmp	SHORT L0844

L0839:
	JMPN	L09B9

L083C:
	mov	ax, OFFSET NauianOnCivilization
	call	Talk
	jmp	SHORT L0844

L0844:
	mov	ax, OFFSET NauianOnDemons
	call	Talk
	cmp	byte ptr cs:never_set, 1
	je	L0855
	JMPN	L09AF

L0855:
	mov	ax, OFFSET N_Nauian
	mov	bx, OFFSET T_DEM4_037
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET S_086A
	call	Say
	JMPN	L08EE

S_086A	LABEL	BYTE
	DB	'I would be glad to accept your application to the Federation. We'
	DB	' shall have a diplomatic envoy sent to make the final arrangemen'
	DB	'ts.',0
L08EE:
	mov	ax, OFFSET N_Nauian
	mov	bx, OFFSET S_08FA
	call	Say
	JMPN	L097F

S_08FA	LABEL	BYTE
	DB	'We look forward to meeting them. We also look forward to having '
	DB	'discourse with the colonists. Farewell.  May the Holy One bless '
	DB	'you.',0
L097F:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_098A
	call	Say
	jmp	SHORT L09A1

S_098A	LABEL	BYTE
	DB	'Live long and prosper.',0
L09A1:
	mov	byte ptr [si+RS_BUSY], 1
	add	word ptr [si+score], 5
	mov	word ptr [si+RS_TIMERS+2], 14h
	retf

L09AF:
	mov	ax, OFFSET N_Nauian
	mov	bx, OFFSET T_DEM4_038
	call	Say
	retf

L09B9:
	mov	ax, 0
	mov	bx, OFFSET N_dialog_error
	call	Say
	retf

; Looking at things.
H_09C3:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_09D2
LookAtArt:
	sub	ax, ax
	mov	bx, OFFSET T_DEM4N002
	call	Say
	retf

H_09D2:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_09E1
LookAtNauian:
	sub	ax, ax
	mov	bx, OFFSET T_DEM4N007
	call	Say
	retf

H_09E1:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_09F0
LookAtScene:
	sub	ax, ax
	mov	bx, OFFSET T_DEM4N004
	call	Say
	retf

H_09F0:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_09FF
LookAtConsole:
	sub	ax, ax
	mov	bx, OFFSET T_DEM4N008
	call	Say
	retf

H_09FF:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_0A0E
LookAtFloor:
	sub	ax, ax
	mov	bx, OFFSET T_DEM4N009
	call	Say
	retf

H_0A0E:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_0A1D
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_DEM4N003
	call	Say
	retf

H_0A1D:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_0A2C
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_DEM4N000
	call	Say
	retf

H_0A2C:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_0A3B
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_DEM4N005
	call	Say
	retf

H_0A3B:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_0A4A
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_DEM4N001
	call	Say
	retf

H_0A4A:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_0A59
LookAtChamber:
	sub	ax, ax
	mov	bx, OFFSET T_DEM4N006
	call	Say
	retf

H_0A59:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_0AAD
LookAtLevers:
	mov	ax, 0
	mov	bx, OFFSET T_DEM4N012
	call	Say
	jmp	SHORT L0AAC

T_DEM4N012	LABEL	BYTE
	DB	'#DEM4\DEM4N012#It looks like a control panel with slide switches'
	DB	'.',0
L0AAC:
	retf

; A crew member on the levers (lever_crew): walk there (msg 3) and play
; the lever puzzle; solved: +3 score, and timer 0 opens the chamber.
H_0AAD:
	SCRIPT	MSG_USE, OBJ_KIRK, 21h, 0, H_0ABC
KirkUsesLevers:
	mov	word ptr cs:lever_crew, 0
	jmp	SHORT L0AE7

H_0ABC:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_0ACB
SpockUsesLevers:
	mov	word ptr cs:lever_crew, 1
	jmp	SHORT L0AE7

H_0ACB:
	SCRIPT	MSG_USE, OBJ_MCCOY, 21h, 0, H_0ADA
McCoyUsesLevers:
	mov	word ptr cs:lever_crew, 2
	jmp	SHORT L0AE7

H_0ADA:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 21h, 0, H_0B15
EvertsUsesLevers:
	mov	word ptr cs:lever_crew, 3
L0AE7:
	cmp	byte ptr [si+nauian_awake], 1
	je	L0B14
	push	3
	push	83h
	push	0DAh
	push	word ptr cs:lever_crew
	push	RC_WALK
	SERVICE		; Walk(?, 218, 131, 3)
	add	sp, 0Ah
	mov	bx, word ptr cs:lever_crew
	sub	bx, 0
	mov	byte ptr [bx+si+25h], 0
	mov	byte ptr [si+RS_BUSY], 1
L0B14:
	retf

H_0B15:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_0B93
AtLevers:
	push	RC_LEVERS
	SERVICE		; Levers()
	add	sp, 2
	or	ax, ax
	jne	L0B56
	mov	ax, 0
	mov	bx, OFFSET T_DEM4N013
	call	Say
	jmp	SHORT L0B54

T_DEM4N013	LABEL	BYTE
	DB	'#DEM4\DEM4N013#Nothing Happens.',0
L0B54:
	jmp	SHORT L0B77

L0B56:
	mov	byte ptr [si+nauian_awake], 1
	push	0
	push	0
	push	0
	push	OFFSET N_ctrl
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "ctrl", 0, 0, 0)
	add	sp, 0Ch
	add	word ptr [si+score], 3
	mov	word ptr [si+RS_TIMERS], 0Ah
L0B77:
	push	0
	push	93h
	push	0AEh
	push	word ptr cs:lever_crew
	push	RC_WALK
	SERVICE		; Walk(?, 174, 147, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Talking to the crew.
H_0B93:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0BE3
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM4_001
	call	Say
	jmp	SHORT L0BE2

T_DEM4_001	LABEL	BYTE
	DB	'#DEM4\DEM4_001#I think we''ve found the answer to our mystery.',0
L0BE2:
	retf

H_0BE3:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0C05
TalkToMcCoy:
	cmp	byte ptr cs:nauian_out, 1
	je	L0BFB
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM4_015
	call	Say
	retf

L0BFB:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM4_019
	call	Say
	retf

H_0C05:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0C27
TalkToSpock:
	cmp	byte ptr cs:nauian_out, 1
	je	L0C1D
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM4_024
	call	Say
	retf

L0C1D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM4_022
	call	Say
	retf

H_0C27:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0C49
TalkToRedshirt:
	cmp	byte ptr cs:nauian_out, 1
	je	L0C3F
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM4_046
	call	Say
	retf

L0C3F:
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM4_047
	call	Say
	retf

; Tricorders.
H_0C49:
	SCRIPT	MSG_USE, IT_STRICOR, 0Ah, 0, H_0CC5
SpockScansChamber:
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
	mov	bx, OFFSET T_DEM4_012
	call	Say
	jmp	SHORT L0CC4

T_DEM4_012	LABEL	BYTE
	DB	'#DEM4\DEM4_012#This seems to be a Cryogenic Suspension chamber, '
	DB	'Captain.',0
L0CC4:
	retf

H_0CC5:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_0CFF
SpockScansArt:
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
	mov	bx, OFFSET T_DEM4_014
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM4_025
	call	Say
	retf

H_0CFF:
	SCRIPT	MSG_USE, IT_MTRICOR, 20h, 0, H_0D0F
McCoyScansArt:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM4_021
	call	Say
	retf

H_0D0F:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_0D40
SpockScansLevers:
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
	mov	bx, OFFSET T_DEM4_027
	call	Say
	retf

H_0D40:
	SCRIPT	MSG_USE, IT_MTRICOR, 21h, 0, H_0D71
McCoyScansLevers:
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
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM4_027
	call	Say
	retf

H_0D71:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_0D79
	jmp	SHORT SpockScans

H_0D79:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_0DAA
SpockScans:
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
	mov	bx, OFFSET T_DEM4_023
	call	Say
	retf

H_0DAA:
	SCRIPT	MSG_USE, IT_MTRICOR, 23h, 0, H_0DB2
	jmp	SHORT McCoyScans

H_0DB2:
	SCRIPT	MSG_USE, IT_MTRICOR, ANY, 0, H_0DE3
McCoyScans:
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
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM4_020
	call	Say
	retf

H_0DE3:
	SCRIPT	MSG_USE, IT_STRICOR, 8, 0, H_0E14
SpockScansNauian:
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
	mov	bx, OFFSET T_DEM4_029
	call	Say
	retf

H_0E14:
	SCRIPT	MSG_USE, IT_MTRICOR, 8, 0, H_0E45
McCoyScansNauian:
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
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM4_029
	call	Say
	retf

H_0E45:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_0E76
SpockScansConsole:
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
	mov	bx, OFFSET T_DEM4_026
	call	Say
	retf

H_0E76:
	SCRIPT	MSG_USE, IT_MTRICOR, 22h, 0, Talk
McCoyScansConsole:
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
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM4_026
	call	Say
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
	DW	201,81, 235,81, 235,95, 201,95
	DW	21h, 4	; id, points
	DW	213,96, 227,96, 227,109, 213,109
	DW	23h, 4	; id, points
	DW	95,131, 319,131, 319,185, 95,185
	DW	22h, 4	; id, points
	DW	240,99, 251,99, 251,109, 240,109
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	1, 4	; id, points
	DW	12,128, 65,128, 65,154, 12,154
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	'boxlit',0
	DB	'keylit',0
	DB	'seclit',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Nauian	LABEL	BYTE
	DB	'Nauian',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Ensign_Everts	LABEL	BYTE
	DB	'Ensign Everts',0
	DB	0
T_DEM4_044	LABEL	BYTE
	DB	'#DEM4\DEM4_044#Welcome to our home. Thank you for repairing our '
	DB	'Sonambutron.',0
T_DEM4_002	LABEL	BYTE
	DB	'#DEM4\DEM4_002#Stop! You''re trespassing on Federation territory.',0
T_DEM4_004	LABEL	BYTE
	DB	'#DEM4\DEM4_004#I welcome you on behalf of the United Federation '
	DB	'of Planets. Who are you? Where do you come from?',0
T_DEM4_009	LABEL	BYTE
	DB	'#DEM4\DEM4_009#We did fix your machine. Can we write the repair '
	DB	'bill off against rent on this land?',0
T_DEM4_042	LABEL	BYTE
	DB	'#DEM4\DEM4_042#Violence is hardly necessary, Captain Kirk. We ow'
	DB	'e you a debt for your service to us, and are more than willing t'
	DB	'o peacefully co-exist with your kind.',0
T_DEM4_043	LABEL	BYTE
	DB	'#DEM4\DEM4_043#We call ourselves Nauians. Thousands of years ago'
	DB	', we saw that meteor impacts were going to cause an Ice Age. We '
	DB	'created this huge underground shelter to preserve our race, keep'
	DB	'ing us in suspended animation until the planet had recovered. We'
	DB	' programmed the machinery to revive us at the next eclipse, but '
	DB	'we did not count on the destruction of our moon.',0
T_DEM4_039	LABEL	BYTE
	DB	'#DEM4\DEM4_039#So the Ferengi are not the only traders in the un'
	DB	'iverse! Yes, Captain Kirk, excusing the settlers'' debts is an ex'
	DB	'cellent way of ensuring that our people will be friends.',0
T_DEM4_008	LABEL	BYTE
	DB	'#DEM4\DEM4_008#Some advanced civilization!',0
T_DEM4_007	LABEL	BYTE
	DB	'#DEM4\DEM4_007#Perhaps you can tell us about the demons.',0
T_DEM4_041	LABEL	BYTE
	DB	'#DEM4\DEM4_041#There is no need for disrespect, intruder. Our ra'
	DB	'ce is old and powerful, wise in many things. Like our guardians,'
	DB	' for example.',0
T_DEM4_040	LABEL	BYTE
	DB	'#DEM4\DEM4_040#The demons, as you call them, are created by a ma'
	DB	'chine designed to keep intruders away from our sleep chambers. I'
	DB	't pulls from the minds of any approaching creature their most fe'
	DB	'ared enemy and produces replicas to scare them away. For you and'
	DB	' your crew it was Klingons, for the Tellarite a wolf-demon, and '
	DB	'for the other Humans a demon from their religion. On behalf of m'
	DB	'y people, thank you for waking us.  I will turn off the machiner'
	DB	'y which creates our guardians, so that they no longer bedevil th'
	DB	'ose with whom we now share our home.',0
T_DEM4_038	LABEL	BYTE
	DB	'#DEM4\DEM4_038#Oh woe! Alas!  The key is missing, I can do nothi'
	DB	'ng!  Even we will suffer the attacks of our own guardians unless'
	DB	' the key can be found!  I implore you, if you can help, please d'
	DB	'o so.',0
T_DEM4_037	LABEL	BYTE
	DB	'#DEM4\DEM4_037#I see you have already shut off the machinery tha'
	DB	't creates the guardians. I have no way to thank you, Captain, bu'
	DB	't please carry this request from my people to yours. We have muc'
	DB	'h ancient knowledge we can share, and we would like to join your'
	DB	' Federation. Go in peace.',0
T_DEM4N002	LABEL	BYTE
	DB	'#DEM4\DEM4N002#It appears to be an abstract piece of alien art.',0
	DB	'#DEM4\DEM4N010#This is where the panel should pop up.',0
T_DEM4N008	LABEL	BYTE
	DB	'#DEM4\DEM4N008#This appears to control some unusual security equ'
	DB	'ipment.',0
T_DEM4N007	LABEL	BYTE
	DB	'#DEM4\DEM4N007#The alien is humanoid, with green reptilian skin.'
	DB	' It appears unarmed.',0
T_DEM4N000	LABEL	BYTE
	DB	'#DEM4\DEM4N000#Dr. McCoy looks back.',0
T_DEM4N005	LABEL	BYTE
	DB	'#DEM4\DEM4N005#Spock is analyzing the alien machines.',0
T_DEM4N001	LABEL	BYTE
	DB	'#DEM4\DEM4N001#Ensign Everts is looking around.',0
T_DEM4N004	LABEL	BYTE
	DB	'#DEM4\DEM4N004#Many alien machines fill the room.',0
T_DEM4N003	LABEL	BYTE
	DB	'#DEM4\DEM4N003#James T. Kirk, Captain of the Enterprise.',0
T_DEM4_015	LABEL	BYTE
	DB	'#DEM4\DEM4_015#I wonder who, or what, constructed all this.',0
T_DEM4_024	LABEL	BYTE
	DB	'#DEM4\DEM4_024#Logically, the machinery is sustaining some type '
	DB	'of life in suspended animation. If we can reactivate the machine'
	DB	's, then we may be able to meet its creators.',0
T_DEM4_046	LABEL	BYTE
	DB	'#DEM4\DEM4_046#I''m just a security officer, sir.',0
T_DEM4_019	LABEL	BYTE
	DB	'#DEM4\DEM4_019#Perhaps we should try to communicate with the ali'
	DB	'en.',0
T_DEM4_022	LABEL	BYTE
	DB	'#DEM4\DEM4_022#Fascinating. this lifeform may represent what wou'
	DB	'ld have happened had the dinosaurs of your earth not become exti'
	DB	'nct.',0
T_DEM4_047	LABEL	BYTE
	DB	'#DEM4\DEM4_047#What is that?',0
T_DEM4_021	LABEL	BYTE
	DB	'#DEM4\DEM4_021#You should ask Spock, Jim.',0
T_DEM4_020	LABEL	BYTE
	DB	'#DEM4\DEM4_020#This is a very old and very complex life-support '
	DB	'system. It appears to still be operational.',0
T_DEM4_014	LABEL	BYTE
	DB	'#DEM4\DEM4_014#Fascinating, Captain. It is a diagram of a lunar '
	DB	'eclipse of this planet. See how the red ball, the moon, is casti'
	DB	'ng a shadow on the blue ball, Pollux V. This must be a very old '
	DB	'piece of work, because this planet''s moon was destroyed thousand'
	DB	's of years ago.',0
T_DEM4_025	LABEL	BYTE
	DB	'#DEM4\DEM4_025#The machinery is waiting for the gravitational pu'
	DB	'll of another eclipse to activate it, an eclipse that will never'
	DB	' come. And one other thing, Captain. This may also be a diagram '
	DB	'showing the proper settings on that control panel.',0
T_DEM4_023	LABEL	BYTE
	DB	'#DEM4\DEM4_023#It is an alien life-support system, Captain, util'
	DB	'izing geothermal energy. It is still functioning, waiting for so'
	DB	'me sort of signal.',0
T_DEM4_027	LABEL	BYTE
	DB	'#DEM4\DEM4_027#This control panel is a manual override for the a'
	DB	'lien life-support equipment.',0
T_DEM4_026	LABEL	BYTE
	DB	'#DEM4\DEM4_026#This alien construction takes readings of mental '
	DB	'activity. It also activates manufacturing equipment related to s'
	DB	'ecurity, and includes a short-distance transportation device.',0
T_DEM4_029	LABEL	BYTE
	DB	'#DEM4\DEM4_029#This lifeform appears to be intelligent, a new se'
	DB	'ntient race. There appear to be resemblances between it and the '
	DB	'silotis, although the present forms are quite small and definite'
	DB	'ly nonsentient.',0
T_DEM4_033	LABEL	BYTE
	DB	'#DEM4\DEM4_033#There is no need for violence, Captain. We are a '
	DB	'peaceful people.',0
T_DEM4_032	LABEL	BYTE
	DB	'#DEM4\DEM4_032#Our patience is exhausted! Now feel our wrath!',0
T_DEM4_013	LABEL	BYTE
	DB	'#DEM4\DEM4_013#Captain, Starfleet would not be pleased.',0
T_DEM4_045	LABEL	BYTE
	DB	'#DEM4\DEM4_045#I do not think that would be a prudent action, si'
	DB	'r.',0
T_DEM4_018	LABEL	BYTE
	DB	'#DEM4\DEM4_018#Ouch!',0
T_DEM4N011	LABEL	BYTE
	DB	'#DEM4\DEM4N011#You meet your death at the hands of a race that c'
	DB	'ould have been your ally. What a waste. Better luck next time.',0
T_DEM4_034	LABEL	BYTE
	DB	'#DEM4\DEM4_034#You found the key! I can now turn off the machine'
	DB	'ry creating our guardians, and no more sentients shall be at ris'
	DB	'k. Surely the Holy One smiles upon us all. I have no way to than'
	DB	'k you, Captain, but please carry this request from my people to '
	DB	'yours. We have much ancient knowledge we can share, and we would'
	DB	' like to join your Federation. Go in peace.',0
T_DEM4_017	LABEL	BYTE
	DB	'#DEM4\DEM4_017#Jim, think about that skull we picked up from Bro'
	DB	'ther Stephen. Now look at this alien.  See the resemblance?',0
T_DEM4_036	LABEL	BYTE
	DB	'#DEM4\DEM4_036#A child?  No, I see many differences. This must b'
	DB	'e what our people who did not slumber have become. Still, I woul'
	DB	'd like to see these remains properly interred, according to the '
	DB	'precepts of our religion. May I keep this?',0
T_DEM4_006	LABEL	BYTE
	DB	'#DEM4\DEM4_006#Of course. I think you will get along well with t'
	DB	'he Pollux inhabitants, and I''m sure you will have interesting th'
	DB	'eological discussions.',0
T_DEM4_003	LABEL	BYTE
	DB	'#DEM4\DEM4_003#I think I should return it to where I got it from'
	DB	'.',0
T_DEM4_005	LABEL	BYTE
	DB	'#DEM4\DEM4_005#No, I want to keep it as a memento for myself.',0
	DB	'At this point, the crew should beam back up to the Enterprise.',0
T_DEM4N009	LABEL	BYTE
	DB	'#DEM4\DEM4N009#This floor contains conduits for conducting geoth'
	DB	'ermal energy.',0
T_DEM4N006	LABEL	BYTE
	DB	'#DEM4\DEM4N006#The alien emerged from this metal chamber.',0
N_dialog_error	LABEL	BYTE
	DB	'dialog error',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0
NauianWakes	LABEL	BYTE
	DW	OFFSET N_Nauian, OFFSET T_DEM4_044, 0	; speaker, choices, 0
KirkGreets	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_DEM4_002, OFFSET T_DEM4_004, OFFSET T_DEM4_009, 0	; speaker, choices, 0
NauianOnTrespass	LABEL	BYTE
	DW	OFFSET N_Nauian, OFFSET T_DEM4_042, 0	; speaker, choices, 0
NauianOnSleep	LABEL	BYTE
	DW	OFFSET N_Nauian, OFFSET T_DEM4_043, 0	; speaker, choices, 0
NauianOnRepairs	LABEL	BYTE
	DW	OFFSET N_Nauian, OFFSET T_DEM4_039, 0	; speaker, choices, 0
KirkAsks	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_DEM4_008, OFFSET T_DEM4_007, 0	; speaker, choices, 0
NauianOnCivilization	LABEL	BYTE
	DW	OFFSET N_Nauian, OFFSET T_DEM4_041, 0	; speaker, choices, 0
NauianOnDemons	LABEL	BYTE
	DW	OFFSET N_Nauian, OFFSET T_DEM4_040, 0	; speaker, choices, 0
KirkOnSkull	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_DEM4_006, OFFSET T_DEM4_003, OFFSET T_DEM4_005, 0	; speaker, choices, 0

RDF	ENDS
	END
