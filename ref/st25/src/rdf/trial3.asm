; TRIAL3.RDF - "The Feathered Serpent", the Test of Life, the way out.
; Daylight ahead, but too easily: three Klingons beam in and open fire,
; and the exit is mined. Once the Klingons are down, Scott has a way
; through the force field: the party can beam up, or carry on.
;
; Actors: 8-10 (0Ah) the Klingons, 11 (0Bh) the explosion.
; Objects: 8-0Ah the Klingons, 20h the exit, 21h the wall.
; Exit 2: room 2. Region 3: the mined exit.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The conversation at 00CA is built at run time.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
score	EQU	RS_VARS+0	; word: the mission's score
max_score	EQU	RS_VARS+2	; word: for the debriefing
seen_daylight	EQU	RS_VARS+11h
shots	EQU	RS_VARS+12h	; Klingon shots that hit: the first kills Bennie, the second Kirk
klingons_down	EQU	RS_VARS+13h	; bits 0-2 for each Klingon down, bit 3 once Uhura has called
klingon1	EQU	RS_VARS+14h	; 14h not here, 15h here, 16h stunned, 17h dead
klingon2	EQU	RS_VARS+16h	; as klingon1
klingon3	EQU	RS_VARS+18h	; as klingon1
can_leave	EQU	RS_VARS+34h	; Scott can breach the force field: Uhura offers to beam the party up
ending	EQU	RS_VARS+36h	; word: how it ended, for room 9: 0 Kirk let the trial run, 1 he beamed back mid-trial, 2 Quetzecoatl was lost, 3 the Klingons leave, 4 Vlict was executed

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
	DW	-1, -1, 2, -1	; room for each exit
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
	DW	312,179, 249,192	; entrance 2, crew 0
	DW	296,179, 272,175	; entrance 2, crew 1
	DW	290,193, 285,190	; entrance 2, crew 2
	DW	314,191, 252,175	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	273,192, 273,182, 263,192, 263,182	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	273,192, 273,182, 263,192, 263,182
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
rdf_objects	LABEL	BYTE
	DW	20h, 5	; id, points
	DW	11,82, 59,82, 74,110, 57,152, 15,154
	DW	21h, 4	; id, points
	DW	0,0, 0,0, 0,0, 0,0
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	2, 3	; id, points
	DW	319,163, 319,199, 294,199
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	205,156, 229,159, 229,199, 205,199
	DW	3, 4	; id, points
	DW	15,153, 63,147, 76,155, 20,164
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	'glis',0

rdf_scripts:
rdf_bans_end:
; The room starts: the music.
H_01B3:
	SCRIPT	MSG_TICK, 1, 0, 0, H_01F6
StartRoom:
	jmp	SHORT L01C4

N_TRI3LOOP	LABEL	BYTE
	DB	'TRI3LOOP',0
L01C4:
	push	OFFSET N_TRI3LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("TRI3LOOP")
	add	sp, 4
	cmp	byte ptr [si+seen_daylight], 0
	jne	L01E1
	mov	byte ptr [si+RS_NO_WALK], 1
	mov	byte ptr [si+RS_BUSY], 2
L01E1:
	mov	ax, -1
	push	ax
	mov	ax, 21h
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(33, -1)
	add	sp, 6
	retf

; Tick 30, the first time: daylight ahead, and doubts.
H_01F6:
	SCRIPT	MSG_TICK, 1Eh, 0, 0, H_0418
Daylight:
	cmp	byte ptr [si+seen_daylight], 0
	jne	L0206
	mov	byte ptr [si+RS_BUSY], 0
L0206:
	cmp	byte ptr [si+seen_daylight], 1
	jne	L020D
	retf

L020D:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+seen_daylight], 1
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI3_030
	call	Say
	jmp	SHORT L0262

T_TRI3_030	LABEL	BYTE
	DB	'#TRI3\TRI3_030#Daylight!  We''re almost there! We''ve beaten them!',0
L0262:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI3_005
	call	Say
	jmp	SHORT L02A0

T_TRI3_005	LABEL	BYTE
	DB	'#TRI3\TRI3_005#I don''t like it. This was too easy.',0
L02A0:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI3_019
	call	Say
	jmp	SHORT L02DA

T_TRI3_019	LABEL	BYTE
	DB	'#TRI3\TRI3_019#Easy! Are you out of your mind?',0
L02DA:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI3_025
	call	Say
	JMPN	L0371

T_TRI3_025	LABEL	BYTE
	DB	'#TRI3\TRI3_025#Admiral Vlict has a reputation for thoroughness, '
	DB	'Doctor. If he means to kill us, we can expect more than we''ve en'
	DB	'countered.',0
L0371:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI3_020
	call	Say
	jmp	SHORT L03E2

T_TRI3_020	LABEL	BYTE
	DB	'#TRI3\TRI3_020#Electrical monsters, things that explode when you'
	DB	' phaser them, what else does he want?',0
L03E2:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI3_004
	call	Say
	jmp	SHORT L0417

T_TRI3_004	LABEL	BYTE
	DB	'#TRI3\TRI3_004#Deaths, Bones. Our deaths.',0
L0417:
	retf

; The Klingons fire in turn (anim msgs 1-6); each round's hit kills Bennie,
; then Kirk (anim msgs 15, 16): game over.
H_0418:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_043E
Klingon1Fires:
	jmp	SHORT L0427

N_t3kfir	LABEL	BYTE
	DB	't3kfir',0
L0427:
	push	4
	push	-1
	push	-1
	push	OFFSET N_t3kfir
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "t3kfir", -1, -1, 4)
	add	sp, 0Ch
	jmp	SHORT L0488

H_043E:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_0464
Klingon2Fires:
	jmp	SHORT L044D

N_t3kfir_2	LABEL	BYTE
	DB	't3kfir',0
L044D:
	push	5
	push	-1
	push	-1
	push	OFFSET N_t3kfir_2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "t3kfir", -1, -1, 5)
	add	sp, 0Ch
	jmp	SHORT L0488

H_0464:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_0552
Klingon3Fires:
	jmp	SHORT L0473

N_t3kfir_3	LABEL	BYTE
	DB	't3kfir',0
L0473:
	push	6
	push	-1
	push	-1
	push	OFFSET N_t3kfir_3
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "t3kfir", -1, -1, 6)
	add	sp, 0Ch
L0488:
	mov	si, word ptr cs:rdf_state
	add	byte ptr [si+shots], 1
	cmp	byte ptr [si+shots], 1
	jne	L04E9
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L04B2

N_t3phas04	LABEL	BYTE
	DB	't3phas04',0
L04B2:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t3phas04
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t3phas04", 5)
	add	sp, 6
	jmp	SHORT L04CF

N_rkillw	LABEL	BYTE
	DB	'rkillw',0
L04CF:
	push	0Fh
	push	-1
	push	-1
	push	OFFSET N_rkillw
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rkillw", -1, -1, 15)
	add	sp, 0Ch
	mov	byte ptr [si+RS_REDSHIRT_DEAD], 1
	retf

L04E9:
	cmp	byte ptr [si+shots], 2
	jne	L0551
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L050A

N_t3phas05	LABEL	BYTE
	DB	't3phas05',0
L050A:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t3phas05
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t3phas05", 5)
	add	sp, 6
	mov	ax, -1
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(2, -1)
	add	sp, 6
	jmp	SHORT L053B

N_kkillw	LABEL	BYTE
	DB	'kkillw',0
L053B:
	push	10h
	push	-1
	push	-1
	push	OFFSET N_kkillw
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kkillw", -1, -1, 16)
	add	sp, 0Ch
	retf

L0551:
	retf

H_0552:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_0578
Klingon1FiresAgain:
	jmp	SHORT L0561

N_t3kfir_4	LABEL	BYTE
	DB	't3kfir',0
L0561:
	push	4
	push	-1
	push	-1
	push	OFFSET N_t3kfir_4
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "t3kfir", -1, -1, 4)
	add	sp, 0Ch
	jmp	SHORT L05C2

H_0578:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_059E
Klingon2FiresAgain:
	jmp	SHORT L0587

N_t3kfir_5	LABEL	BYTE
	DB	't3kfir',0
L0587:
	push	5
	push	-1
	push	-1
	push	OFFSET N_t3kfir_5
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "t3kfir", -1, -1, 5)
	add	sp, 0Ch
	jmp	SHORT L05C2

H_059E:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_0677
Klingon3FiresAgain:
	jmp	SHORT L05AD

N_t3kfir_6	LABEL	BYTE
	DB	't3kfir',0
L05AD:
	push	6
	push	-1
	push	-1
	push	OFFSET N_t3kfir_6
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "t3kfir", -1, -1, 6)
	add	sp, 0Ch
L05C2:
	mov	si, word ptr cs:rdf_state
	add	byte ptr [si+shots], 1
	cmp	byte ptr [si+shots], 1
	jne	L0623
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L05EC

N_t3phas04_2	LABEL	BYTE
	DB	't3phas04',0
L05EC:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t3phas04_2
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t3phas04", 5)
	add	sp, 6
	jmp	SHORT L0609

N_rkillw_2	LABEL	BYTE
	DB	'rkillw',0
L0609:
	push	0Fh
	push	-1
	push	-1
	push	OFFSET N_rkillw_2
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rkillw", -1, -1, 15)
	add	sp, 0Ch
	mov	byte ptr [si+RS_REDSHIRT_DEAD], 1
	retf

L0623:
	cmp	byte ptr [si+shots], 2
	jne	L0676
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0644

N_t3phas05_2	LABEL	BYTE
	DB	't3phas05',0
L0644:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t3phas05_2
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t3phas05", 5)
	add	sp, 6
	jmp	SHORT L0661

N_kkillw_2	LABEL	BYTE
	DB	'kkillw',0
L0661:
	push	10h
	push	-1
	push	-1
	push	OFFSET N_kkillw_2
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kkillw", -1, -1, 16)
	add	sp, 0Ch
L0676:
	retf

H_0677:
	SCRIPT	MSG_ANIM_DONE, 0Fh, 0, 0, H_0682
BennieKilled:
	mov	byte ptr [si+RS_REDSHIRT_DEAD], 1
	retf

H_0682:
	SCRIPT	MSG_ANIM_DONE, 10h, 0, 0, H_06B3
KirkKilled:
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	mov	ax, 0
	mov	bx, OFFSET S_069D
	call	Say
	jmp	SHORT L06B2

S_069D	LABEL	BYTE
	DB	'***Game over man!***',0
L06B2:
	retf

; A Klingon is down (anim msgs 11-13); with all three down, Uhura calls:
; Scott can breach the force field. Beam up (ending 1), or carry on.
H_06B3:
	SCRIPT	MSG_ANIM_DONE, 0Bh, 0, 0, H_06C4
Klingon1Down:
	mov	si, word ptr cs:rdf_state
	or	byte ptr [si+klingons_down], 1
	jmp	SHORT L06DF

H_06C4:
	SCRIPT	MSG_ANIM_DONE, 0Ch, 0, 0, H_06D5
Klingon2Down:
	mov	si, word ptr cs:rdf_state
	or	byte ptr [si+klingons_down], 2
	jmp	SHORT L06DF

H_06D5:
	SCRIPT	MSG_ANIM_DONE, 0Dh, 0, 0, H_09E3
Klingon3Down:
	or	byte ptr [si+klingons_down], 4
L06DF:
	cmp	byte ptr [si+klingons_down], 1
	je	L06E6
	retf

L06E6:
	or	byte ptr [si+klingons_down], 8
	mov	byte ptr [si+RS_NO_WALK], 0
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI3U084
	call	Say
	jmp	SHORT L0775

T_TRI3U084	LABEL	BYTE
	DB	'#TRI3\TRI3U084#Captain, our sensors have picked up phaser fire! '
	DB	'Are you all right? Captain, come in please!',0
L0775:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI3_007
	call	Say
	jmp	SHORT L07A7

T_TRI3_007	LABEL	BYTE
	DB	'#TRI3\TRI3_007#We''re fine, lieutenant.',0
L07A7:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI3U099
	call	Say
	jmp	SHORT L07F6

T_TRI3U099	LABEL	BYTE
	DB	'#TRI3\TRI3U099#Mr. Scott has found a way to breach the force fie'
	DB	'ld!',0
L07F6:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+can_leave], 1
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L0849

T_TRI3_006	LABEL	BYTE
	DB	'#TRI3\TRI3_006#We''ll call you if we want to transport. Kirk out.',0
L0849:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI3_006
	mov	word ptr cs:choice_jumps, OFFSET L09E2
	jmp	SHORT L088C

T_TRI3_002	LABEL	BYTE
	DB	'#TRI3\TRI3_002#Beam us directly to the Enterprise.',0
L088C:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI3_002
	mov	word ptr cs:choice_jumps+2, OFFSET L08FC
	jmp	SHORT L08D1

T_TRI3_003	LABEL	BYTE
	DB	'#TRI3\TRI3_003#Beam us directly to Vlict''s position.',0
L08D1:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI3_003
	mov	word ptr cs:choice_jumps+4, OFFSET L0919
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L08FC:
	mov	si, word ptr cs:rdf_state
	mov	word ptr [si+ending], 1
	push	1
	push	word ptr [si+max_score]
	push	word ptr [si+score]
	push	RC_BEAMUP
	SERVICE		; BeamUp(?, ?, 1)
	add	sp, 8
	retf

L0919:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI3U080
	call	Say
	jmp	SHORT L094A

T_TRI3U080	LABEL	BYTE
	DB	'#TRI3\TRI3U080#Affirmative, sir.',0
L094A:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 8
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(8)
	add	sp, 4
	jmp	SHORT L096C

N_kteled	LABEL	BYTE
	DB	'kteled',0
L096C:
	push	13h
	push	-1
	push	-1
	push	OFFSET N_kteled
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kteled", -1, -1, 19)
	add	sp, 0Ch
	jmp	SHORT L098A

N_steled	LABEL	BYTE
	DB	'steled',0
L098A:
	push	13h
	push	-1
	push	-1
	push	OFFSET N_steled
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "steled", -1, -1, 19)
	add	sp, 0Ch
	jmp	SHORT L09A8

N_mteled	LABEL	BYTE
	DB	'mteled',0
L09A8:
	push	13h
	push	-1
	push	-1
	push	OFFSET N_mteled
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mteled", -1, -1, 19)
	add	sp, 0Ch
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 0
	jne	L09E1
	jmp	SHORT L09CC

N_rteled	LABEL	BYTE
	DB	'rteled',0
L09CC:
	push	13h
	push	-1
	push	-1
	push	OFFSET N_rteled
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rteled", -1, -1, 19)
	add	sp, 0Ch
L09E1:
	retf

L09E2:
	retf

; Carrying on (anim msg 19): +2, on to room 4.
H_09E3:
	SCRIPT	MSG_ANIM_DONE, 13h, 0, 0, H_09FD
CarryOn:
	add	word ptr [si+score], 2
	mov	byte ptr [si+RS_BUSY], 1
	push	4
	push	4
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(4, 4)
	retf

; Tick 90: three Klingons beam in and open fire.
H_09FD:
	SCRIPT	MSG_TICK, 5Ah, 0, 0, H_0A5D
KlingonsBeamIn:
	and	byte ptr [si+klingons_down], 8
	jne	L0A5C
	cmp	word ptr [si+klingon1], 14h
	je	L0A5C
	mov	ax, 9
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(9)
	add	sp, 4
	mov	ax, -1
	push	ax
	mov	ax, 20h
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(32, -1)
	add	sp, 6
	jmp	SHORT L0A3C

N_t3ktel	LABEL	BYTE
	DB	't3ktel',0
L0A3C:
	push	1
	push	0B1h
	push	57h
	push	OFFSET N_t3ktel
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "t3ktel", 87, 177, 1)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	word ptr [si+klingon1], 15h
L0A5C:
	retf

; Region 3, the exit: a Klingon mine explodes (anim msg 14): game over.
H_0A5D:
	SCRIPT	MSG_REGION, 3, 0, 0, H_0AC1
IntoTheMine:
	mov	ax, 14h
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(20)
	add	sp, 4
	mov	ax, -1
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(2, -1)
	add	sp, 6
	jmp	SHORT L0A92

N_BITOKIRK	LABEL	BYTE
	DB	'BITOKIRK',0
L0A92:
	push	OFFSET N_BITOKIRK
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("BITOKIRK")
	add	sp, 4
	jmp	SHORT L0AAA

N_t3expl	LABEL	BYTE
	DB	't3expl',0
L0AAA:
	push	0Eh
	push	0C7h
	push	0
	push	OFFSET N_t3expl
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "t3expl", 0, 199, 14)
	add	sp, 0Ch
	retf

H_0AC1:
	SCRIPT	MSG_ANIM_DONE, 0Eh, 0, 0, H_0AF2
MineExploded:
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	mov	ax, 0
	mov	bx, OFFSET S_0ADC
	call	Say
	jmp	SHORT L0AF1

S_0ADC	LABEL	BYTE
	DB	'***Game over man!***',0
L0AF1:
	retf

H_0AF2:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_0B41
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_TRI3N000
	call	Say
	jmp	SHORT L0B40

T_TRI3N000	LABEL	BYTE
	DB	'#TRI3\TRI3N000#Captain James Tiberius Kirk, deep in thought.',0
L0B40:
	retf

H_0B41:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_0B9C
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_TRI3N004
	call	Say
	jmp	SHORT L0B9B

T_TRI3N004	LABEL	BYTE
	DB	'#TRI3\TRI3N004#Spock, one of the foremost science officers in St'
	DB	'arfleet.',0
L0B9B:
	retf

H_0B9C:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_0BF1
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_TRI3N001
	call	Say
	jmp	SHORT L0BF0

T_TRI3N001	LABEL	BYTE
	DB	'#TRI3\TRI3N001#Doctor Leonard McCoy, a rather disgruntled surgeo'
	DB	'n.',0
L0BF0:
	retf

H_0BF1:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_0C59
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_TRI3N002
	call	Say
	jmp	SHORT L0C58

T_TRI3N002	LABEL	BYTE
	DB	'#TRI3\TRI3N002#Ensign Bennie, who wishes that he was back at the'
	DB	' Academy right now...',0
L0C58:
	retf

; Looking and talking.
H_0C59:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_0CA9
LookAtExit:
	mov	ax, 0
	mov	bx, OFFSET T_TRI3N005
	call	Say
	jmp	SHORT L0CA8

T_TRI3N005	LABEL	BYTE
	DB	'#TRI3\TRI3N005#The exit to this particular complex. You hope.',0
L0CA8:
	retf

H_0CA9:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_0CE5
LookAtWall:
	mov	ax, 0
	mov	bx, OFFSET T_TRI3N007
	call	Say
	jmp	SHORT L0CE4

T_TRI3N007	LABEL	BYTE
	DB	'#TRI3\TRI3N007#The wall of this corridor.',0
L0CE4:
	retf

H_0CE5:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0D29
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI3_001
	call	Say
	jmp	SHORT L0D28

T_TRI3_001	LABEL	BYTE
	DB	'#TRI3\TRI3_001#This is too easy. I don''t like it.',0
L0D28:
	retf

H_0D29:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0D68
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI3_022
	call	Say
	jmp	SHORT L0D67

T_TRI3_022	LABEL	BYTE
	DB	'#TRI3\TRI3_022#I recommend caution, Captain.',0
L0D67:
	retf

H_0D68:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0DC0
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI3_018
	call	Say
	jmp	SHORT L0DBF

T_TRI3_018	LABEL	BYTE
	DB	'#TRI3\TRI3_018#Well, maybe I''ve been too hard on you, Jim. I''m s'
	DB	'orry.',0
L0DBF:
	retf

H_0DC0:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0E37
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI3_029
	call	Say
	jmp	SHORT L0E36

T_TRI3_029	LABEL	BYTE
	DB	'#TRI3\TRI3_029#When I get out of this, I am going to have the be'
	DB	'st shore leave in Starfleet history!',0
L0E36:
	retf

; Phasers on the Klingons (msgs 17, 18): stunned, or killed (-3 for the
; first).
H_0E37:
	SCRIPT	MSG_USE, IT_PHASERS, 21h, 0, H_0E3F
	jmp	SHORT PhaserWall

H_0E3F:
	SCRIPT	MSG_USE, IT_PHASERK, 21h, 0, H_0E86
PhaserWall:
	mov	ax, 0
	mov	bx, OFFSET T_TRI3N006
	call	Say
	jmp	SHORT L0E85

T_TRI3N006	LABEL	BYTE
	DB	'#TRI3\TRI3N006#The wall is resistant to phaser fire.',0
L0E85:
	retf

H_0E86:
	SCRIPT	MSG_USE, IT_PHASERS, 8, 0, H_0EB6
StunKlingon1:
	cmp	word ptr [si+klingon1], 16h
	jne	L0E93
	retf

L0E93:
	mov	byte ptr [si+RS_BUSY], 1
	jmp	SHORT L0EA0

N_kdraww	LABEL	BYTE
	DB	'kdraww',0
L0EA0:
	push	11h
	push	-1
	push	-1
	push	OFFSET N_kdraww
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kdraww", -1, -1, 17)
	add	sp, 0Ch
	retf

H_0EB6:
	SCRIPT	MSG_ANIM_DONE, 11h, 0, 0, H_0F23
KirkFiresStun:
	mov	si, word ptr cs:rdf_state
	cmp	word ptr [si+klingon1], 15h
	jne	L0F22
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0EE2

N_t3phas00	LABEL	BYTE
	DB	't3phas00',0
L0EE2:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t3phas00
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t3phas00", 5)
	add	sp, 6
	jmp	SHORT L0EFF

N_t3kstn	LABEL	BYTE
	DB	't3kstn',0
L0EFF:
	push	0Bh
	push	-1
	push	-1
	push	OFFSET N_t3kstn
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "t3kstn", -1, -1, 11)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 0
	mov	word ptr [si+klingon1], 16h
L0F22:
	retf

H_0F23:
	SCRIPT	MSG_USE, IT_PHASERS, 9, 0, H_0F60
StunKlingon2:
	mov	byte ptr [si+RS_BUSY], 1
	cmp	word ptr [si+klingon2], 15h
	jne	L0F5F
	jmp	SHORT L0F3C

N_t3kstn_2	LABEL	BYTE
	DB	't3kstn',0
L0F3C:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_t3kstn_2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "t3kstn", -1, -1, 12)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 0
	mov	word ptr [si+klingon2], 16h
L0F5F:
	retf

H_0F60:
	SCRIPT	MSG_USE, IT_PHASERS, 0Ah, 0, H_0F9D
StunKlingon3:
	mov	byte ptr [si+RS_BUSY], 1
	cmp	word ptr [si+klingon3], 15h
	jne	L0F9C
	jmp	SHORT L0F79

N_t3kstn_3	LABEL	BYTE
	DB	't3kstn',0
L0F79:
	push	0Dh
	push	-1
	push	-1
	push	OFFSET N_t3kstn_3
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "t3kstn", -1, -1, 13)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 0
	mov	word ptr [si+klingon3], 16h
L0F9C:
	retf

H_0F9D:
	SCRIPT	MSG_USE, IT_PHASERK, 8, 0, H_0FC6
KillKlingon1:
	mov	byte ptr [si+RS_BUSY], 1
	jmp	SHORT L0FB0

N_kdraww_2	LABEL	BYTE
	DB	'kdraww',0
L0FB0:
	push	12h
	push	-1
	push	-1
	push	OFFSET N_kdraww_2
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kdraww", -1, -1, 18)
	add	sp, 0Ch
	retf

H_0FC6:
	SCRIPT	MSG_ANIM_DONE, 12h, 0, 0, H_1032
KirkFiresKill:
	cmp	word ptr [si+klingon1], 15h
	jne	L1031
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0FED

N_t3phas02	LABEL	BYTE
	DB	't3phas02',0
L0FED:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t3phas02
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t3phas02", 5)
	add	sp, 6
	jmp	SHORT L100A

N_t3kdie	LABEL	BYTE
	DB	't3kdie',0
L100A:
	push	0Bh
	push	-1
	push	-1
	push	OFFSET N_t3kdie
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "t3kdie", -1, -1, 11)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 0
	mov	word ptr [si+klingon1], 17h
	add	word ptr [si+score], -3
L1031:
	retf

H_1032:
	SCRIPT	MSG_USE, IT_PHASERK, 9, 0, H_10A2
KillKlingon2:
	mov	byte ptr [si+RS_BUSY], 1
	cmp	word ptr [si+klingon2], 15h
	jne	L106F
	jmp	SHORT L104B

N_t3kdie_2	LABEL	BYTE
	DB	't3kdie',0
L104B:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_t3kdie_2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "t3kdie", -1, -1, 12)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 0
	mov	word ptr [si+klingon2], 17h
	retf

L106F:
	mov	si, word ptr cs:rdf_state
	cmp	word ptr [si+klingon2], 16h
	jne	L10A1
	jmp	SHORT L1083

N_t3kdie_3	LABEL	BYTE
	DB	't3kdie',0
L1083:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_t3kdie_3
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "t3kdie", -1, -1, 12)
	add	sp, 0Ch
	mov	byte ptr [si+RS_BUSY], 0
	mov	word ptr [si+klingon2], 17h
L10A1:
	retf

H_10A2:
	SCRIPT	MSG_USE, IT_PHASERK, 0Ah, 0, H_1112
KillKlingon3:
	mov	byte ptr [si+RS_BUSY], 1
	cmp	word ptr [si+klingon3], 15h
	jne	L10DF
	jmp	SHORT L10BB

N_t3kdie_4	LABEL	BYTE
	DB	't3kdie',0
L10BB:
	push	0Dh
	push	-1
	push	-1
	push	OFFSET N_t3kdie_4
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "t3kdie", -1, -1, 13)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 0
	mov	word ptr [si+klingon3], 17h
	retf

L10DF:
	cmp	word ptr [si+klingon3], 16h
	jne	L1111
	jmp	SHORT L10EE

N_t3kdie_5	LABEL	BYTE
	DB	't3kdie',0
L10EE:
	push	0Dh
	push	-1
	push	-1
	push	OFFSET N_t3kdie_5
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "t3kdie", -1, -1, 13)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 0
	mov	word ptr [si+klingon3], 17h
L1111:
	retf

H_1112:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_111A
	jmp	SHORT KillAnything

H_111A:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_1161
KillAnything:
	mov	ax, 0
	mov	bx, OFFSET T_TRI3N003
	call	Say
	jmp	SHORT L1160

T_TRI3N003	LABEL	BYTE
	DB	'#TRI3\TRI3N003#No gunslinging allowed, space cowboy.',0
L1160:
	retf

; Tricorders: McCoy reads Klingons outside, Spock a bomb in the exit.
H_1161:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_KIRK, 0, H_11D9
McCoyScansKirk:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L1174

N_sscans	LABEL	BYTE
	DB	'sscans',0
L1174:
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
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI3_015
	call	Say
	jmp	SHORT L11D8

T_TRI3_015	LABEL	BYTE
	DB	'#TRI3\TRI3_015#Male Human, good physical condition.',0
L11D8:
	retf

H_11D9:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_SPOCK, 0, H_1264
McCoyScansSpock:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L11EC

N_sscans_2	LABEL	BYTE
	DB	'sscans',0
L11EC:
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
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI3_016
	call	Say
	jmp	SHORT L1263

T_TRI3_016	LABEL	BYTE
	DB	'#TRI3\TRI3_016#Male Human-Vulcan hybrid. Excellent physical cond'
	DB	'ition.',0
L1263:
	retf

H_1264:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_MCCOY, 0, H_12E6
McCoyScansMcCoy:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L1277

N_sscans_3	LABEL	BYTE
	DB	'sscans',0
L1277:
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
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI3_013
	call	Say
	jmp	SHORT L12E5

T_TRI3_013	LABEL	BYTE
	DB	'#TRI3\TRI3_013#He''s a Male Human, average physical condition.',0
L12E5:
	retf

H_12E6:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_REDSHIRT, 0, H_1331
McCoyScansBennie:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI3_014
	call	Say
	jmp	SHORT L1330

T_TRI3_014	LABEL	BYTE
	DB	'#TRI3\TRI3_014#Male Human, excellent physical condition.',0
L1330:
	retf

H_1331:
	SCRIPT	MSG_USE, IT_MTRICOR, 20h, 0, H_13E0
McCoyScansExit:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L1344

N_sscans_4	LABEL	BYTE
	DB	'sscans',0
L1344:
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
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI3_009
	call	Say
	jmp	SHORT L13DF

T_TRI3_009	LABEL	BYTE
	DB	'#TRI3\TRI3_009#Approximately thirty Klingons, within 500 meters '
	DB	'of the opening, no closer than 200 meters.',0
L13DF:
	retf

H_13E0:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_146B
SpockScansWall:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L13F3

N_sscans_5	LABEL	BYTE
	DB	'sscans',0
L13F3:
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
	mov	bx, OFFSET T_TRI3_024
	call	Say
	jmp	SHORT L146A

T_TRI3_024	LABEL	BYTE
	DB	'#TRI3\TRI3_024#This wall was carved from the natural rock of a c'
	DB	'avern.',0
L146A:
	retf

H_146B:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_155C
SpockScansExit:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L147E

N_sscans_6	LABEL	BYTE
	DB	'sscans',0
L147E:
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
	mov	bx, OFFSET T_TRI3_023
	call	Say
	JMPN	L155B

T_TRI3_023	LABEL	BYTE
	DB	'#TRI3\TRI3_023#Reading a high energy build-up; there is a Klingo'
	DB	'n explosive device present five point three meters outside the c'
	DB	'avern! It could be detonated at any moment!',0
L155B:
	retf

H_155C:
	SCRIPT	MSG_USE, IT_MTRICOR, 8, 0, H_1688
McCoyScansKlingon:
	cmp	word ptr [si+klingon1], 16h
	je	L156B
	JMPN	L1687

L156B:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L1578

N_sscans_7	LABEL	BYTE
	DB	'sscans',0
L1578:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscans_7
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
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI3_011
	call	Say
	JMPN	L162E

T_TRI3_011	LABEL	BYTE
	DB	'#TRI3\TRI3_011#He''s out like a light, Jim. There are hibernating'
	DB	' Arcturian sloth-tigers that will get up more quickly than this '
	DB	'guy.',0
L162E:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI3_028
	call	Say
	jmp	SHORT L1686

T_TRI3_028	LABEL	BYTE
	DB	'#TRI3\TRI3_028#What are waiting for, sir? Shouldn''t we just get '
	DB	'out of here?',0
L1686:
	retf

L1687:
	retf

; The communicator: still working on it, or (can_leave) beam up now?
H_1688:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_183A
CallUhura:
	cmp	byte ptr [si+can_leave], 0
	je	L1697
	JMPN	L1725

L1697:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI3U067
	call	Say
	JMPN	L1724

T_TRI3U067	LABEL	BYTE
	DB	'#TRI3\TRI3U067#Captain, we''re still working on breaching the for'
	DB	'ce field. We will let you know when we''re ready to beam you out.',0
L1724:
	retf

L1725:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI3U089
	call	Say
	jmp	SHORT L1768

T_TRI3U089	LABEL	BYTE
	DB	'#TRI3\TRI3U089#Do you wish to be beamed up now Captain?',0
L1768:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L17AA

T_TRI3_103	LABEL	BYTE
	DB	'#TRI3\TRI3_103#Beam us back to the Enterprise. Kirk out.',0
L17AA:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI3_103
	mov	word ptr cs:choice_jumps, OFFSET L08FC
	jmp	SHORT L17E6

T_TRI3_104	LABEL	BYTE
	DB	'#TRI3\TRI3_104#Beam us to Vlict''s position.',0
L17E6:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI3_104
	mov	word ptr cs:choice_jumps+2, OFFSET L094A
	jmp	SHORT L180F

T_TRI3_107	LABEL	BYTE
	DB	'#TRI3\TRI3_107#Negative.',0
L180F:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI3_107
	mov	word ptr cs:choice_jumps+4, OFFSET L09E2
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

; The crew on the wall and the exit.
H_183A:
	SCRIPT	MSG_USE, OBJ_MCCOY, 21h, 0, H_1891
McCoyOnWall:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI3_010
	call	Say
	jmp	SHORT L1890

T_TRI3_010	LABEL	BYTE
	DB	'#TRI3\TRI3_010#Damn it Jim, I''m a Doctor, not a structural Engin'
	DB	'eer!',0
L1890:
	retf

H_1891:
	SCRIPT	MSG_USE, OBJ_MCCOY, 20h, 0, H_18DA
McCoyOnExit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI3_012
	call	Say
	jmp	SHORT L18D9

T_TRI3_012	LABEL	BYTE
	DB	'#TRI3\TRI3_012#I believe that you have seniority, Jim.',0
L18D9:
	retf

H_18DA:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_192D
SpockOnWall:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI3_021
	call	Say
	jmp	SHORT L192C

T_TRI3_021	LABEL	BYTE
	DB	'#TRI3\TRI3_021#I do not understand the desired course of action.',0
L192C:
	retf

H_192D:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_19AD
SpockOnExit:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI3_008
	call	Say
	jmp	SHORT L19AC

T_TRI3_008	LABEL	BYTE
	DB	'#TRI3\TRI3_008#Captain, Starfleet protocol requires that the com'
	DB	'manding officer lead in hazardous situations.',0
L19AC:
	retf

H_19AD:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 20h, 0, H_1A11
BennieOnExit:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI3_027
	call	Say
	jmp	SHORT L1A10

T_TRI3_027	LABEL	BYTE
	DB	'#TRI3\TRI3_027#No sir. I insist that you have the honor of leadi'
	DB	'ng us to victory.',0
L1A10:
	retf

H_1A11:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 21h, 0, H_1A5A
BennieOnWall:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI3_026
	call	Say
	jmp	SHORT L1A59

T_TRI3_026	LABEL	BYTE
	DB	'#TRI3\TRI3_026#How hard do you want me to hit it, sir.',0
L1A59:
	retf

H_1A5A:
	SCRIPT	MSG_WALK, 20h, 0, 0, H_1A7D
WalkToExit:
	mov	ax, 0
	push	ax
	mov	ax, 9Dh
	push	ax
	mov	ax, 26h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 38, 157, 0)
	add	sp, 0Ah
	retf

H_1A7D:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, rdf_scripts_end
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI3_017
	call	Say
	jmp	SHORT L1ADE

T_TRI3_017	LABEL	BYTE
	DB	'#TRI3\TRI3_017#Nobody needs healing, Jim, but you will if they h'
	DB	'arm my patient.',0
L1ADE:
	retf

rdf_scripts_end	LABEL	BYTE

RDF	ENDS
	END
