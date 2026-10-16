; DEMON1.RDF - "Demon World", the path up Mount Idyll, where three
; "Klingons" ambush the landing party. They are androids: when shot,
; Klingon 1 loses a hand with circuitry in its palm, which Kirk can take.
; Any of the crew they stun get up again after the fight.
;
; Actors: 8, 9, 10 (0Ah) the Klingons; 11 (0Bh) a Klingon's shot;
; 12 (0Ch) Kirk's phaser shot; 13 (0Dh) the hand on the ground.
; Objects: 0Dh the hand, 20h cattails, 21h tulips, 22h Brandzite pods,
; 23h a fern, 24h the stream, 25h the mine entrance, 26h Mount Idyll.
; Exits: 0 up to the mine (room 2), 1 back to the colony (room 0).
; Timers: 2 the ambush starts, 0 and 3 the other Klingons stand up,
; 1 a Klingon fires, 4 Kirk has the hand, 5 Uhura calls, 6 the crew
; come round.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 15C5: the engine reads its bytes
;   as key 2E A3 E7 16 and next 892E (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
ambushed	EQU	RS_VARS+6	; word: 0 until the ambush, then -1
took_hand	EQU	RS_VARS+8	; word
saw_klingons	EQU	RS_VARS+0Eh	; the Klingons have appeared
came_from	EQU	RS_VARS+11h	; 1: from the colony, 2: from the mine; which way the crew face
under_fire	EQU	RS_VARS+1Fh	; the Klingons are shooting: no leaving
score	EQU	RS_VARS+2Fh	; word: the mission's score

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0C7h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	60h
rdf_scale_min	LABEL	BYTE
	DW	0A2h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	2, 0, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	219,100, 260,122	; entrance 0, crew 0
	DW	219,100, 206,110	; entrance 0, crew 1
	DW	219,100, 261,113	; entrance 0, crew 2
	DW	219,100, 237,103	; entrance 0, crew 3
	DW	210,184, 232,161	; entrance 1, crew 0
	DW	210,184, 289,166	; entrance 1, crew 1
	DW	210,184, 162,166	; entrance 1, crew 2
	DW	210,184, 191,177	; entrance 1, crew 3
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
	DW	272,153, 253,158, 276,163, 260,169
; In the room file, so these start again each time the room loads
klingon1_hit	LABEL	BYTE	; Kirk has shot Klingon 1 (actor 8)
	DB	0
klingon2_hit	LABEL	BYTE
	DB	0
klingon3_hit	LABEL	BYTE
	DB	0
klingons_down	LABEL	BYTE	; 3: the fight is over
	DB	0, 0
scanned_klingon	LABEL	BYTE	; Spock has explained the Klingon
	DB	0
crew_shot	LABEL	BYTE	; how many of the crew the Klingons have stunned
	DB	0
kirk_firing	LABEL	BYTE
	DB	0
shooter	LABEL	BYTE	; the Klingon firing
	DB	0, 0
shooter_anim	LABEL	BYTE	; its firing animation
	DB	0, 0
shot_anim	LABEL	BYTE	; the shot, aimed at the next crew member
	DB	0, 0
N_klg1u	LABEL	BYTE
	DB	'klg1u',0
N_klg1f	LABEL	BYTE
	DB	'klg1f',0
N_klg1d	LABEL	BYTE
	DB	'klg1d',0
N_klg1d2	LABEL	BYTE
	DB	'klg1d2',0
N_klghnd	LABEL	BYTE
	DB	'klghnd',0
N_klg2u	LABEL	BYTE
	DB	'klg2u',0
N_klg2f	LABEL	BYTE
	DB	'klg2f',0
N_klg2d	LABEL	BYTE
	DB	'klg2d',0
N_klg2d2	LABEL	BYTE
	DB	'klg2d2',0
N_klg3u	LABEL	BYTE
	DB	'klg3u',0
N_klg3f	LABEL	BYTE
	DB	'klg3f',0
N_klg3d	LABEL	BYTE
	DB	'klg3d',0
N_klg3d2	LABEL	BYTE
	DB	'klg3d2',0
N_klg1fr	LABEL	BYTE
	DB	'klg1fr',0
N_klg1fs	LABEL	BYTE
	DB	'klg1fs',0
N_klg1fm	LABEL	BYTE
	DB	'klg1fm',0
N_klg1fk	LABEL	BYTE
	DB	'klg1fk',0
N_klg2fr	LABEL	BYTE
	DB	'klg2fr',0
N_klg2fs	LABEL	BYTE
	DB	'klg2fs',0
N_klg2fm	LABEL	BYTE
	DB	'klg2fm',0
N_klg2fk	LABEL	BYTE
	DB	'klg2fk',0
N_klg3fr	LABEL	BYTE
	DB	'klg3fr',0
N_klg3fs	LABEL	BYTE
	DB	'klg3fs',0
N_klg3fm	LABEL	BYTE
	DB	'klg3fm',0
N_klg3fk	LABEL	BYTE
	DB	'klg3fk',0
N_s0ks1	LABEL	BYTE
	DB	's0ks1',0
N_s0ks2	LABEL	BYTE
	DB	's0ks2',0
N_s0ks3	LABEL	BYTE
	DB	's0ks3',0
N_rstunn	LABEL	BYTE
	DB	'rstunn',0
N_sstunn	LABEL	BYTE
	DB	'sstunn',0
N_mstune	LABEL	BYTE
	DB	'mstune',0
N_kstunn	LABEL	BYTE
	DB	'kstunn',0
N_mscann	LABEL	BYTE
	DB	'mscann',0
N_sscann	LABEL	BYTE
	DB	'sscann',0
N_kfiren	LABEL	BYTE
	DB	'kfiren',0
N_s5r1kg	LABEL	BYTE
	DB	's5r1kg',0

rdf_scripts:
; The room starts. The first time, the ambush is set for timer 2 and the
; crew can't walk; afterwards the Klingons lie where they fell (and the hand,
; until Kirk takes it).
H_01C8:
	SCRIPT	MSG_TICK, 1, 0, 0, H_02B2
StartRoom:
	jmp	SHORT L01D9

N_DEM1LOOP	LABEL	BYTE
	DB	'DEM1LOOP',0
L01D9:
	push	OFFSET N_DEM1LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("DEM1LOOP")
	add	sp, 4
	cmp	word ptr [si+ambushed], 0
	jne	L01FC
	push	-1
	push	1
	push	RC_MUSIC
	SERVICE		; Music(1, -1)
	add	sp, 6
L01FC:
	cmp	byte ptr [si+came_from], 1
	jne	L0214
	mov	byte ptr [si+RS_FALL], 0
	mov	byte ptr [si+RS_FALL+1], 0
	mov	byte ptr [si+RS_FALL+2], 0
	mov	byte ptr [si+RS_FALL+3], 0
	jmp	SHORT L022A

L0214:
	cmp	byte ptr [si+came_from], 2
	jne	L022A
	mov	byte ptr [si+RS_FALL], 1
	mov	byte ptr [si+RS_FALL+1], 1
	mov	byte ptr [si+RS_FALL+2], 1
	mov	byte ptr [si+RS_FALL+3], 1
L022A:
	cmp	word ptr [si+ambushed], 0
	jne	L023A
	mov	byte ptr [si+RS_NO_WALK], 1
	mov	word ptr [si+RS_TIMERS+4], 32h
	retf

L023A:
	push	0
	push	82h
	push	120h
	push	OFFSET N_klg1d2
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "klg1d2", 288, 130, 0)
	add	sp, 0Ch
	cmp	word ptr [si+took_hand], 1
	je	L026E
	push	0
	push	8Eh
	push	10Bh
	push	OFFSET N_klghnd
	push	0Dh
	push	RC_ANIM0
	SERVICE		; Anim0(13, "klghnd", 267, 142, 0)
	add	sp, 0Ch
L026E:
	push	0
	push	7Ch
	push	0AAh
	push	OFFSET N_klg2d2
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "klg2d2", 170, 124, 0)
	add	sp, 0Ch
	push	0
	push	0
	push	0
	push	OFFSET N_klg3d2
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "klg3d2", 0, 0, 0)
	add	sp, 0Ch
	mov	byte ptr cs:klingon1_hit, 1
	mov	byte ptr cs:klingon2_hit, 1
	mov	byte ptr cs:klingon3_hit, 1
	mov	byte ptr cs:klingons_down, 3
	retf

; Clicking the mine entrance after the fight: walk there (msg 2), then
; leave as by exit 0.
H_02B2:
	SCRIPT	MSG_WALK, 25h, 0, 0, H_02D5
WalkToMine:
	cmp	byte ptr cs:klingons_down, 3
	je	L02C1
	retf

L02C1:
	push	2
	push	56h
	push	0A3h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 163, 86, 2)
	add	sp, 0Ah
	retf

H_02D5:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_02DD
	jmp	SHORT ExitToMine

H_02DD:
	SCRIPT	MSG_EXIT, 0, 0, 0, H_02F8
ExitToMine:
	cmp	byte ptr [si+under_fire], 1
	je	L02F7
	push	1
	push	2
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(2, 1)
	add	sp, 6
L02F7:
	retf

H_02F8:
	SCRIPT	MSG_EXIT, 1, 0, 0, H_0313
ExitToColony:
	cmp	byte ptr [si+under_fire], 1
	je	L0312
	push	0
	push	0
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(0, 0)
	add	sp, 6
L0312:
	retf

; Timer 2: Klingon 1 stands up; the others follow on timers 0 and 3,
; and timer 1 starts the shooting.
H_0313:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_0350
Ambush:
	cmp	word ptr [si+ambushed], 0
	jne	L034F
	mov	byte ptr [si+saw_klingons], 1
	dec	word ptr [si+ambushed]
	mov	byte ptr [si+under_fire], 1
	mov	word ptr [si+RS_TIMERS], 5
	mov	word ptr [si+RS_TIMERS+6], 2
	mov	word ptr [si+RS_TIMERS+2], 64h
	push	0
	push	82h
	push	120h
	push	OFFSET N_klg1u
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "klg1u", 288, 130, 0)
	add	sp, 0Ch
L034F:
	retf

H_0350:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_036D
Klingon2StandsUp:
	push	0
	push	7Ch
	push	0AAh
	push	OFFSET N_klg2u
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "klg2u", 170, 124, 0)
	add	sp, 0Ch
	retf

H_036D:
	SCRIPT	MSG_TIMER, 3, 0, 0, H_038A
Klingon3StandsUp:
	push	0
	push	6Dh
	push	0DBh
	push	OFFSET N_klg3u
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "klg3u", 219, 109, 0)
	add	sp, 0Ch
	retf

; Timer 1: the first Klingon still standing fires at the next crew
; member (redshirt, McCoy, Spock, then Kirk). The jumps into the next
; Klingon's tests when crew_shot doesn't match are in the original.
H_038A:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_04B9
KlingonFires:
	cmp	byte ptr cs:klingon1_hit, 1
	je	L03EE
	mov	word ptr cs:shooter_anim, OFFSET N_klg1f
	mov	word ptr cs:shooter, 8
	cmp	byte ptr cs:crew_shot, 0
	jne	L03B8
	mov	word ptr cs:shot_anim, OFFSET N_klg1fr
	JMPN	L049E

L03B8:
	cmp	byte ptr cs:crew_shot, 1
	jne	L03CA
	mov	word ptr cs:shot_anim, OFFSET N_klg1fm
	JMPN	L049E

L03CA:
	cmp	byte ptr cs:crew_shot, 2
	jne	L03DC
	mov	word ptr cs:shot_anim, OFFSET N_klg1fs
	JMPN	L049E

L03DC:
	cmp	byte ptr cs:crew_shot, 3
	jne	L0416
	mov	word ptr cs:shot_anim, OFFSET N_klg1fk
	JMPN	L049E

L03EE:
	cmp	byte ptr cs:klingon2_hit, 1
	je	L0449
	mov	word ptr cs:shooter_anim, OFFSET N_klg2f
	mov	word ptr cs:shooter, 9
	cmp	byte ptr cs:crew_shot, 0
	jne	L0416
	mov	word ptr cs:shot_anim, OFFSET N_klg2fr
	JMPN	L049E

L0416:
	cmp	byte ptr cs:crew_shot, 1
	jne	L0427
	mov	word ptr cs:shot_anim, OFFSET N_klg2fm
	jmp	SHORT L049E

L0427:
	cmp	byte ptr cs:crew_shot, 2
	jne	L0438
	mov	word ptr cs:shot_anim, OFFSET N_klg2fs
	jmp	SHORT L049E

L0438:
	cmp	byte ptr cs:crew_shot, 3
	jne	L0468
	mov	word ptr cs:shot_anim, OFFSET N_klg2fk
	jmp	SHORT L049E

L0449:
	mov	word ptr cs:shooter_anim, OFFSET N_klg3f
	mov	word ptr cs:shooter, 0Ah
	cmp	byte ptr cs:crew_shot, 0
	jne	L0468
	mov	word ptr cs:shot_anim, OFFSET N_klg3fr
	jmp	SHORT L049E

L0468:
	cmp	byte ptr cs:crew_shot, 1
	jne	L0479
	mov	word ptr cs:shot_anim, OFFSET N_klg3fm
	jmp	SHORT L049E

L0479:
	cmp	byte ptr cs:crew_shot, 2
	jne	L048A
	mov	word ptr cs:shot_anim, OFFSET N_klg3fs
	jmp	SHORT L049E

L048A:
	cmp	byte ptr cs:crew_shot, 3
	je	L0495
	JMPN	L0517

L0495:
	mov	word ptr cs:shot_anim, OFFSET N_klg3fk
	jmp	SHORT L049E

L049E:
	push	2
	push	-1
	push	-1
	push	word ptr cs:shooter_anim
	push	word ptr cs:shooter
	push	RC_ANIM2
	SERVICE		; Anim(?, ?, -1, -1, 2)
	add	sp, 0Ch
	retf

; The shot has hit (anim msg 2): that crew member falls, stunned for
; 28Ah ticks (RS_STUN, RS_FLAGS), and timer 1 is set for the next shot.
; When it's Kirk's turn (msg 1 when done), the game is over. The three
; shared pushes are made before the test; the last case pops them again.
H_04B9:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_0599
CrewMemberStunned:
	push	0
	push	0
	push	0
	push	word ptr cs:shot_anim
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, ?, 0, 0, 0)
	add	sp, 0Ch
	push	6
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	push	0
	push	-1
	push	-1
	inc	byte ptr cs:crew_shot
	cmp	byte ptr cs:crew_shot, 1
	jne	L0517
	push	OFFSET N_rstunn
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rstunn", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_FALL+3], 0
	mov	word ptr [si+RS_TIMERS+2], 64h
	mov	word ptr [si+RS_STUN+6], 28Ah
	or	byte ptr [si+RS_FLAGS], 8
	retf

L0517:
	cmp	byte ptr cs:crew_shot, 2
	jne	L0541
	push	OFFSET N_sstunn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sstunn")
	add	sp, 0Ch
	mov	byte ptr [si+RS_FALL+1], 0
	mov	word ptr [si+RS_TIMERS+2], 64h
	mov	word ptr [si+RS_STUN+2], 28Ah
	or	byte ptr [si+RS_FLAGS], 2
	retf

L0541:
	cmp	byte ptr cs:crew_shot, 3
	jne	L056B
	push	OFFSET N_mstune
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mstune")
	add	sp, 0Ch
	mov	byte ptr [si+RS_FALL+2], 3
	mov	word ptr [si+RS_TIMERS+2], 64h
	mov	word ptr [si+RS_STUN+4], 28Ah
	or	byte ptr [si+RS_FLAGS], 4
	retf

L056B:
	cmp	byte ptr cs:crew_shot, 4
	jne	L0598
	pop	ax
	pop	ax
	pop	ax
	push	1
	push	-1
	push	-1
	push	OFFSET N_kstunn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kstunn", -1, -1, 1)
	add	sp, 0Ch
	mov	byte ptr [si+RS_FALL], 0
	mov	word ptr [si+RS_STUN], 28Ah
	or	byte ptr [si+RS_FLAGS], 1
L0598:
	retf

; Kirk has been shot: game over.
H_0599:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_05B3
KirkShot:
	mov	ax, OFFSET S_172C
	mov	bx, OFFSET T_DEM1N000
	call	Say
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	retf

H_05B3:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_05BB
	jmp	SHORT PhaserAfterFight

H_05BB:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_0624
PhaserAfterFight:
	cmp	byte ptr cs:klingons_down, 3
	jne	L0623
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM1_011
	call	Say
	jmp	SHORT L0623

T_DEM1_011	LABEL	BYTE
	DB	'#DEM1\DEM1_011#The fire fight is over, Jim. I think you can put '
	DB	'that away now.',0
L0623:
	retf

; Kirk phasers Klingon 1 (anim msg 3), once.
H_0624:
	SCRIPT	MSG_USE, IT_PHASERK, 8, 0, H_062C
	jmp	SHORT ShootKlingon1

H_062C:
	SCRIPT	MSG_USE, IT_PHASERS, 8, 0, H_066B
ShootKlingon1:
	cmp	byte ptr cs:klingon1_hit, 0
	je	L063B
	retf

L063B:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr cs:klingon1_hit, 1
	cmp	byte ptr cs:kirk_firing, 1
	jne	L064F
	jmp	SHORT Klingon1Hit

L064F:
	push	3
	push	-1
	push	-1
	push	OFFSET N_kfiren
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kfiren", -1, -1, 3)
	add	sp, 0Ch
	mov	byte ptr cs:kirk_firing, 1
	retf

; Klingon 1 falls (anim msg 7); the fight is over when all three are down.
H_066B:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_06E5
Klingon1Hit:
	inc	byte ptr cs:klingons_down
	cmp	byte ptr cs:klingons_down, 3
	jne	L0695
	mov	word ptr [si+RS_TIMERS+2], 0
	mov	word ptr [si+RS_TIMERS+10], 0B4h
	mov	word ptr [si+RS_TIMERS+12], 1
	mov	byte ptr [si+under_fire], 0
	mov	byte ptr [si+RS_NO_WALK], 0
L0695:
	push	0
	push	0
	push	0
	push	OFFSET N_s0ks1
	push	0Ch
	push	RC_ANIM0
	SERVICE		; Anim0(12, "s0ks1", 0, 0, 0)
	add	sp, 0Ch
	push	6
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L06BE

N_EFX19	LABEL	BYTE
	DB	'EFX19',0
L06BE:
	push	OFFSET N_EFX19
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EFX19")
	add	sp, 4
	push	7
	push	82h
	push	120h
	push	OFFSET N_klg1d
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "klg1d", 288, 130, 7)
	add	sp, 0Ch
	retf

; ...and loses his hand.
H_06E5:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_0812
Klingon1Falls:
	push	0
	push	8Eh
	push	10Bh
	push	OFFSET N_klghnd
	push	0Dh
	push	RC_ANIM0
	SERVICE		; Anim0(13, "klghnd", 267, 142, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_BUSY], 0
	mov	word ptr [si+RS_TIMERS+2], 0
	mov	ax, 0
	mov	bx, OFFSET T_DEM1N020
	call	Say
	jmp	SHORT L077D

T_DEM1N020	LABEL	BYTE
	DB	'#DEM1\DEM1N020#You see a small explosion, and the Klingon''s hand'
	DB	' falls to the ground with a dull thud.',0
L077D:
	test	byte ptr [si+RS_FLAGS], 8
	je	L0786
	JMPN	L0811

L0786:
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM1_025
	call	Say
	jmp	SHORT L07D9

T_DEM1_025	LABEL	BYTE
	DB	'#DEM1\DEM1_025#I guess they don''t make Klingons like they used t'
	DB	'o, Sir.',0
L07D9:
	cmp	byte ptr cs:klingons_down, 3
	je	L0811
	mov	ax, OFFSET N_Klingon
	mov	bx, OFFSET T_DEM1_F23
	call	Say
	jmp	SHORT L080C

T_DEM1_F23	LABEL	BYTE
	DB	'#DEM1\DEM1_F23#Federation Scum!',0
L080C:
	mov	word ptr [si+RS_TIMERS+2], 1
L0811:
	retf

; The same for Klingons 2 and 3 (msgs 4 and 5).
H_0812:
	SCRIPT	MSG_USE, IT_PHASERK, 9, 0, H_081A
	jmp	SHORT ShootKlingon2

H_081A:
	SCRIPT	MSG_USE, IT_PHASERS, 9, 0, H_0859
ShootKlingon2:
	cmp	byte ptr cs:klingon2_hit, 0
	je	L0829
	retf

L0829:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr cs:klingon2_hit, 1
	cmp	byte ptr cs:kirk_firing, 1
	jne	L083D
	jmp	SHORT Klingon2Hit

L083D:
	push	4
	push	-1
	push	-1
	push	OFFSET N_kfiren
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kfiren", -1, -1, 4)
	add	sp, 0Ch
	mov	byte ptr cs:kirk_firing, 1
	retf

H_0859:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_08BF
Klingon2Hit:
	inc	byte ptr cs:klingons_down
	cmp	byte ptr cs:klingons_down, 3
	jne	L0883
	mov	word ptr [si+RS_TIMERS+2], 0
	mov	word ptr [si+RS_TIMERS+10], 0B4h
	mov	word ptr [si+RS_TIMERS+12], 1
	mov	byte ptr [si+under_fire], 0
	mov	byte ptr [si+RS_NO_WALK], 0
L0883:
	push	0
	push	0
	push	0
	push	OFFSET N_s0ks2
	push	0Ch
	push	RC_ANIM0
	SERVICE		; Anim0(12, "s0ks2", 0, 0, 0)
	add	sp, 0Ch
	push	6
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	push	0
	push	7Ch
	push	0AAh
	push	OFFSET N_klg2d
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "klg2d", 170, 124, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_08BF:
	SCRIPT	MSG_USE, IT_PHASERK, 0Ah, 0, H_08C7
	jmp	SHORT ShootKlingon3

H_08C7:
	SCRIPT	MSG_USE, IT_PHASERS, 0Ah, 0, H_0906
ShootKlingon3:
	cmp	byte ptr cs:klingon3_hit, 0
	je	L08D6
	retf

L08D6:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr cs:klingon3_hit, 1
	cmp	byte ptr cs:kirk_firing, 1
	jne	L08EA
	jmp	SHORT Klingon3Hit

L08EA:
	push	5
	push	-1
	push	-1
	push	OFFSET N_kfiren
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kfiren", -1, -1, 5)
	add	sp, 0Ch
	mov	byte ptr cs:kirk_firing, 1
	retf

H_0906:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_096B
Klingon3Hit:
	inc	byte ptr cs:klingons_down
	cmp	byte ptr cs:klingons_down, 3
	jne	L0930
	mov	word ptr [si+RS_TIMERS+2], 0
	mov	word ptr [si+RS_TIMERS+10], 0B4h
	mov	word ptr [si+RS_TIMERS+12], 1
	mov	byte ptr [si+under_fire], 0
	mov	byte ptr [si+RS_NO_WALK], 0
L0930:
	push	0
	push	0
	push	0
	push	OFFSET N_s0ks3
	push	0Ch
	push	RC_ANIM0
	SERVICE		; Anim0(12, "s0ks3", 0, 0, 0)
	add	sp, 0Ch
	push	6
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	push	0
	push	0
	push	0
	push	OFFSET N_klg3d
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "klg3d", 0, 0, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Timer 6: everyone stunned gets up in 45 ticks.
H_096B:
	SCRIPT	MSG_TIMER, 6, 0, 0, H_0986
CrewComeRound:
	mov	word ptr [si+RS_STUN], 2Dh
	mov	word ptr [si+RS_STUN+2], 2Dh
	mov	word ptr [si+RS_STUN+4], 2Dh
	mov	word ptr [si+RS_STUN+6], 2Dh
	retf

; Timer 5: Uhura asks what the shooting was.
H_0986:
	SCRIPT	MSG_TIMER, 5, 0, 0, H_0BE3
UhuraCalls:
	cmp	byte ptr [si+RS_FLAGS], 0
	je	L0993
	retf

L0993:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_DEM1U077
	call	Say
	jmp	SHORT L09FB

T_DEM1U077	LABEL	BYTE
	DB	'#DEM1\DEM1U077#Captain we registered Phaser fire and an unknown '
	DB	'energy beam. Is everyone OK?',0
L09FB:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM1_003
	call	Say
	jmp	SHORT L0A46

T_DEM1_003	LABEL	BYTE
	DB	'#DEM1\DEM1_003#We''re fine. Did you register any Disruptor fire?',0
L0A46:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_DEM1U078
	call	Say
	jmp	SHORT L0A8B

T_DEM1U078	LABEL	BYTE
	DB	'#DEM1\DEM1U078#No, Captain. Why, are Klingons down there?',0
L0A8B:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM1_002
	call	Say
	jmp	SHORT L0AC0

T_DEM1_002	LABEL	BYTE
	DB	'#DEM1\DEM1_002#No just an idea, Kirk out.',0
L0AC0:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM1_020
	call	Say
	JMPN	L0B4F

T_DEM1_020	LABEL	BYTE
	DB	'#DEM1\DEM1_020#Fascinating. I begin to suspect that we have stum'
	DB	'bled upon something that the colonists would never have uncovere'
	DB	'd.',0
L0B4F:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM1_004
	call	Say
	jmp	SHORT L0B7C

T_DEM1_004	LABEL	BYTE
	DB	'#DEM1\DEM1_004#What is it, Spock?',0
L0B7C:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM1_021
	call	Say
	jmp	SHORT L0BE2

T_DEM1_021	LABEL	BYTE
	DB	'#DEM1\DEM1_021#I wish to gather further data before making a def'
	DB	'inite conclusion, Captain.',0
L0BE2:
	retf

; Tricorders on the plants, the hand and the Klingons.
H_0BE3:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Dh, 0, H_0C14
McCoyScansHand:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscann
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscann", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM1_012
	call	Say
	retf

H_0C14:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_0CA3
SpockScansTulips:
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
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM1_007
	call	Say
	jmp	SHORT L0CA2

T_DEM1_007	LABEL	BYTE
	DB	'#DEM1\DEM1_007#Khytellian tulips are a perennial flower that sur'
	DB	'vive in almost any climate.',0
L0CA2:
	retf

H_0CA3:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_0D4F
SpockScansPods:
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
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM1_008
	call	Say
	jmp	SHORT L0D4E

T_DEM1_008	LABEL	BYTE
	DB	'#DEM1\DEM1_008#The Brandzite pod is similar to terran milkweed e'
	DB	'xcept that the silk pods are in bright iridecent colors.',0
L0D4E:
	retf

H_0D4F:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_0E23
SpockScansCattails:
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
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM1_005
	call	Say
	JMPN	L0E22

T_DEM1_005	LABEL	BYTE
	DB	'#DEM1\DEM1_005#Doctis Cattails are similar to their terran name '
	DB	'sake except that they are known to cause hives if in contact wit'
	DB	'h flesh for any amount of time.',0
L0E22:
	retf

H_0E23:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_0EA5
SpockScansFern:
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
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM1_006
	call	Say
	jmp	SHORT L0EA4

T_DEM1_006	LABEL	BYTE
	DB	'#DEM1\DEM1_006#Gindorian ferns are regarded as an intergalactic '
	DB	'weed, Captain.',0
L0EA4:
	retf

H_0EA5:
	SCRIPT	MSG_USE, IT_STRICOR, 0Dh, 0, H_0ED6
SpockScansHand:
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
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM1_017
	call	Say
	retf

; Spock's first scan of Klingon 1 after the fight explains the androids,
; once. Its scanning animation was taken out (the pushes are dropped).
H_0ED6:
	SCRIPT	MSG_USE, IT_STRICOR, 8, 0, H_0F2F
SpockScansKlingon1:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscann
	push	1
	push	2
	add	sp, 0Ch		; NOTE: drops the arguments of Anim(1, "sscann", -1, -1, 0): the call was taken out
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, 16F8h
	cmp	byte ptr cs:klingons_down, 3
	jne	L0F25
	cmp	word ptr [si+took_hand], 1
	je	L0F25
	cmp	byte ptr cs:scanned_klingon, 1
	je	L0F25
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM1_018
	mov	byte ptr cs:scanned_klingon, 1
	call	Say
	retf

L0F25:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM1_019
	call	Say
	retf

H_0F2F:
	SCRIPT	MSG_USE, IT_STRICOR, 0Ah, 0, H_0F37
	jmp	SHORT SpockScansKlingon

H_0F37:
	SCRIPT	MSG_USE, IT_STRICOR, 9, 0, H_0F6C
SpockScansKlingon:
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
	mov	bx, OFFSET T_DEM1_019
	call	Say
	retf

H_0F6C:
	SCRIPT	MSG_USE, IT_MEDKIT, 8, 0, H_0F74
	jmp	SHORT McCoyScansKlingon1

H_0F74:
	SCRIPT	MSG_USE, IT_MTRICOR, 8, 0, H_0FA9
McCoyScansKlingon1:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscann
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscann", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM1_012
	call	Say
	retf

H_0FA9:
	SCRIPT	MSG_USE, IT_MEDKIT, 0Ah, 0, H_0FB1
	jmp	SHORT McCoyScansKlingon3

H_0FB1:
	SCRIPT	MSG_USE, IT_MEDKIT, 9, 0, H_0FB9
McCoyScansKlingon3:
	jmp	SHORT McCoyScansKlingon3b

H_0FB9:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Ah, 0, H_0FC1
McCoyScansKlingon3b:
	jmp	SHORT McCoyScansKlingon

H_0FC1:
	SCRIPT	MSG_USE, IT_MTRICOR, 9, 0, H_0FF6
McCoyScansKlingon:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscann
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscann", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM1_012
	call	Say
	retf

H_0FF6:
	SCRIPT	MSG_USE, IT_STRICOR, 8, 0, H_102B
SpockScansKlingon1Again:
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
	mov	bx, OFFSET T_DEM1_016
	call	Say
	retf

; McCoy on a stunned crew member.
H_102B:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_KIRK, 0, H_1038
McCoyScansKirk:
	test	byte ptr [si+RS_FLAGS], 1
	jne	L1052
	retf

H_1038:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_SPOCK, 0, H_1045
McCoyScansSpock:
	test	byte ptr [si+RS_FLAGS], 2
	jne	L1052
	retf

H_1045:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_REDSHIRT, 0, H_10C4
McCoyScansRedshirt:
	test	byte ptr [si+RS_FLAGS], 8
	jne	L1052
	retf

L1052:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscann
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscann", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM1_009
	call	Say
	jmp	SHORT L10C3

T_DEM1_009	LABEL	BYTE
	DB	'#DEM1\DEM1_009#He''s only stunned. He''ll be back up in a few seco'
	DB	'nds.',0
L10C3:
	retf

; Getting the hand: walk to it (msg 1), crouch (anim msg 6), +3 score,
; and on timer 4 it is in the inventory.
H_10C4:
	SCRIPT	MSG_GET, 0Dh, 0, 0, H_10E8
GetHand:
	cmp	byte ptr cs:klingons_down, 3
	je	L10D3
	retf

L10D3:
	push	1
	push	8Eh
	push	104h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 260, 142, 1)
	add	sp, 0Ah
	retf

H_10E8:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_1104
ReachHand:
	push	6
	push	-1
	push	-1
	push	OFFSET N_s5r1kg
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r1kg", -1, -1, 6)
	add	sp, 0Ch
	retf

H_1104:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_112C
PickUpHand:
	push	0Dh
	push	RC_STOPANIM
	SERVICE		; StopAnim(13)
	add	sp, 4
	add	word ptr [si+score], 3
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	word ptr [si+RS_TIMERS+8], 2
	retf

H_112C:
	SCRIPT	MSG_TIMER, 4, 0, 0, H_1155
GiveHand:
	mov	bx, OFFSET T_DEM1N005
	cmp	word ptr [si+took_hand], 0
	jne	L114F
	mov	word ptr [si+took_hand], 1
	push	IT_HAND
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_HAND)
	add	sp, 4
	mov	bx, OFFSET T_DEM1N007
L114F:
	sub	ax, ax
	call	Say
	retf

; Looking at things.
H_1155:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_115D
	jmp	SHORT LookAtKlingon2

H_115D:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_1165
LookAtKlingon2:
	jmp	SHORT LookAtKlingon

H_1165:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_1175
LookAtKlingon:
	mov	ax, OFFSET S_172C
	mov	bx, OFFSET T_DEM1N004
	call	Say
	retf

H_1175:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_11C0
LookAtCattails:
	mov	ax, 0
	mov	bx, OFFSET T_DEM1N018
	call	Say
	jmp	SHORT L11BF

T_DEM1N018	LABEL	BYTE
	DB	'#DEM1\DEM1N018#These are very beautiful Doctis Cattails.',0
L11BF:
	retf

H_11C0:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_1205
LookAtTulips:
	mov	ax, 0
	mov	bx, OFFSET T_DEM1N010
	call	Say
	jmp	SHORT L1204

T_DEM1N010	LABEL	BYTE
	DB	'#DEM1\DEM1N010#A large patch of Khytellian Tulips.',0
L1204:
	retf

H_1205:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_1260
LookAtPods:
	mov	ax, 0
	mov	bx, OFFSET T_DEM1N019
	call	Say
	jmp	SHORT L125F

T_DEM1N019	LABEL	BYTE
	DB	'#DEM1\DEM1N019#These Brandzite Pods add a nice touch to the loca'
	DB	'l flora.',0
L125F:
	retf

H_1260:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_1293
LookAtFern:
	mov	ax, 0
	mov	bx, OFFSET T_DEM1N009
	call	Say
	jmp	SHORT L1292

T_DEM1N009	LABEL	BYTE
	DB	'#DEM1\DEM1N009#A Gindorian Fern.',0
L1292:
	retf

H_1293:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_12E2
LookAtStream:
	mov	ax, 0
	mov	bx, OFFSET T_DEM1N011
	call	Say
	jmp	SHORT L12E1

T_DEM1N011	LABEL	BYTE
	DB	'#DEM1\DEM1N011#A small stream flows down towards the forest.',0
L12E1:
	retf

H_12E2:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_1324
LookAtMine:
	mov	ax, 0
	mov	bx, OFFSET T_DEM1N021
	call	Say
	jmp	SHORT L1323

T_DEM1N021	LABEL	BYTE
	DB	'#DEM1\DEM1N021#You see the mine entrance ahead.',0
L1323:
	retf

H_1324:
	SCRIPT	MSG_LOOK, 26h, 0, 0, H_1360
LookAtMountain:
	mov	ax, 0
	mov	bx, OFFSET T_DEM1N016
	call	Say
	jmp	SHORT L135F

T_DEM1N016	LABEL	BYTE
	DB	'#DEM1\DEM1N016#Mt. Idyll rises above you.',0
L135F:
	retf

H_1360:
	SCRIPT	MSG_LOOK, 0Dh, 0, 0, H_13A3
LookAtHand:
	mov	ax, 0
	mov	bx, OFFSET T_DEM1N023
	call	Say
	jmp	SHORT L13A2

T_DEM1N023	LABEL	BYTE
	DB	'#DEM1\DEM1N023#It''s the Klingon''s detached hand!',0
L13A2:
	retf

H_13A3:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_13F8
LookAtScene:
	mov	ax, 0
	mov	bx, OFFSET T_DEM1N017
	call	Say
	jmp	SHORT L13F7

T_DEM1N017	LABEL	BYTE
	DB	'#DEM1\DEM1N017#The path is surrounded by some beautiful shrubber'
	DB	'y.',0
L13F7:
	retf

H_13F8:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_1446
LookAtKirk:
	test	byte ptr [si+RS_FLAGS], 1
	jne	L140E
	mov	ax, OFFSET S_172C
	mov	bx, OFFSET T_DEM1N003
	call	Say
	retf

L140E:
	mov	ax, 0
	mov	bx, OFFSET T_DEM1N012
	call	Say
	jmp	SHORT L1445

T_DEM1N012	LABEL	BYTE
	DB	'#DEM1\DEM1N012#Captain Kirk is unconscious.',0
L1445:
	retf

H_1446:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_1491
LookAtSpock:
	test	byte ptr [si+RS_FLAGS], 2
	jne	L145C
	mov	ax, OFFSET S_172C
	mov	bx, OFFSET T_DEM1N008
	call	Say
	retf

L145C:
	mov	ax, 0
	mov	bx, OFFSET T_DEM1N015
	call	Say
	jmp	SHORT L1490

T_DEM1N015	LABEL	BYTE
	DB	'#DEM1\DEM1N015#Mr. Spock is unconscious.',0
L1490:
	retf

H_1491:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_14DC
LookAtMcCoy:
	test	byte ptr [si+RS_FLAGS], 4
	jne	L14A7
	mov	ax, OFFSET S_172C
	mov	bx, OFFSET T_DEM1N001
	call	Say
	retf

L14A7:
	mov	ax, 0
	mov	bx, OFFSET T_DEM1N013
	call	Say
	jmp	SHORT L14DB

T_DEM1N013	LABEL	BYTE
	DB	'#DEM1\DEM1N013#Dr. McCoy is unconscious.',0
L14DB:
	retf

H_14DC:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_152B
LookAtRedshirt:
	test	byte ptr [si+RS_FLAGS], 8
	jne	L14F2
	mov	ax, OFFSET S_172C
	mov	bx, OFFSET T_DEM1N002
	call	Say
	retf

L14F2:
	mov	ax, 0
	mov	bx, OFFSET T_DEM1N014
	call	Say
	jmp	SHORT L152A

T_DEM1N014	LABEL	BYTE
	DB	'#DEM1\DEM1N014#Ensign Everts is unconscious.',0
L152A:
	retf

; Talking to the crew.
H_152B:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_1549
TalkToKirk:
	test	byte ptr [si+RS_FLAGS], 1
	jne	L15AF
	cmp	byte ptr cs:klingons_down, 3
	jne	L1548
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM1_001
	call	Say
L1548:
	retf

H_1549:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_157A
TalkToSpock:
	test	byte ptr [si+RS_FLAGS], 2
	jne	L15AF
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM1_022
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM1_013
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM1_024
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM1_014
	call	Say
	retf

H_157A:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_1599
TalkToMcCoy:
	test	byte ptr [si+RS_FLAGS], 4
	jne	L15AF
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM1_015
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM1_023
	call	Say
	retf

H_1599:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, Say
TalkToRedshirt:
	test	byte ptr [si+RS_FLAGS], 8
	jne	L15AF
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM1_026
	call	Say
	retf

L15AF:
	mov	ax, OFFSET S_172C
	mov	bx, OFFSET N_Zzzzz
	call	Say
	jmp	SHORT L15C4

N_Zzzzz	LABEL	BYTE
	DB	'Zzzzz....',0
L15C4:
	retf

; Say: one line, BX, said by AX (0: narration).
Say:
	mov	word ptr cs:talk_buf, ax
	mov	word ptr cs:talk_buf+2, bx
	mov	ax, OFFSET talk_buf
	call	Talk
	ret

; Talk: conversation AX (speaker, choices, 0); returns the choice.
Talk:
	push	ax
	mov	ax, RC_TALK
	push	ax
	SERVICE		; Talk(?)
	add	sp, 4
	ret

rdf_scripts_end	LABEL	BYTE
rdf_objects	LABEL	BYTE
	DW	20h, 4	; id, points
	DW	168,146, 203,146, 203,173, 168,173
	DW	21h, 4	; id, points
	DW	210,102, 234,102, 234,157, 210,157
	DW	22h, 4	; id, points
	DW	83,157, 167,157, 167,173, 83,173
	DW	22h, 4	; id, points
	DW	140,141, 167,141, 167,156, 140,156
	DW	23h, 4	; id, points
	DW	133,122, 168,122, 168,140, 133,140
	DW	23h, 4	; id, points
	DW	67,141, 139,141, 139,156, 67,156
	DW	24h, 4	; id, points
	DW	50,173, 50,155, 66,143, 66,162
	DW	24h, 4	; id, points
	DW	65,129, 81,117, 87,117, 73,140
	DW	25h, 4	; id, points
	DW	157,21, 203,21, 203,96, 157,96
	DW	26h, 4	; id, points
	DW	50,9, 303,9, 303,93, 50,93
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	0, 4	; id, points
	DW	169,93, 210,93, 210,104, 169,104
	DW	1, 4	; id, points
	DW	33,167, 310,167, 310,173, 33,173
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	150,110, 294,110, 294,133, 150,133
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
rdf_bans_end	LABEL	BYTE
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Ensign_Everts	LABEL	BYTE
	DB	'Ensign Everts',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
N_Klingon	LABEL	BYTE
	DB	'Klingon',0
S_172C	LABEL	BYTE
	DB	0
T_DEM1N003	LABEL	BYTE
	DB	'#DEM1\DEM1N003#James Kirk, filled with a premonition of more dan'
	DB	'gers yet to come.',0
T_DEM1N001	LABEL	BYTE
	DB	'#DEM1\DEM1N001#Dr. McCoy, still hoping the cold winds that whip '
	DB	'around Mount Idyll will soon die down.',0
T_DEM1N008	LABEL	BYTE
	DB	'#DEM1\DEM1N008#Your Vulcan science officer seems to be lost in t'
	DB	'hought, but remains alert.',0
T_DEM1N002	LABEL	BYTE
	DB	'#DEM1\DEM1N002#Ensign Everts seems to be rattled by the attack o'
	DB	'f the Klingons.',0
T_DEM1N000	LABEL	BYTE
	DB	'#DEM1\DEM1N000#Captain Kirk is fatally shot by a Klingon, game o'
	DB	'ver.',0
T_DEM1_018	LABEL	BYTE
	DB	'#DEM1\DEM1_018#This is not a Klingon, Captain, not a real one. I'
	DB	't is an organic construct -- an android-like robot. It looks lik'
	DB	'e a Klingon, but the appearance is entirely superficial. There i'
	DB	's something different about this particular construct. Come here'
	DB	', Captain, look at the hand.It seems to have been separated from'
	DB	' the body. There is a wiring circuit in the middle of the palm.',0
	DB	'#DEM1\DEM1N006#You find nothing new.',0
T_DEM1_012	LABEL	BYTE
	DB	'#DEM1\DEM1_012#This is definitely not a real klingon Jim.',0
T_DEM1_017	LABEL	BYTE
	DB	'#DEM1\DEM1_017#This is a detached hand with some kind of circuit'
	DB	'ry in the palm, Captain.',0
T_DEM1_019	LABEL	BYTE
	DB	'#DEM1\DEM1_019#This is not a Klingon, Captain, not a real one. I'
	DB	't is an organic construct -- an android-like robot. It looks lik'
	DB	'e a Klingon, but the appearance is entirely superficial.',0
T_DEM1_016	LABEL	BYTE
	DB	'#DEM1\DEM1_016#The circuit was damaged. It appears reparable, bu'
	DB	't some specialized equipment will be required.',0
T_DEM1N005	LABEL	BYTE
	DB	'#DEM1\DEM1N005#You already took the hand from the Klingon.',0
T_DEM1N007	LABEL	BYTE
	DB	'#DEM1\DEM1N007#You take the Klingon''s detached hand.',0
T_DEM1N004	LABEL	BYTE
	DB	'#DEM1\DEM1N004#They look like Klingons.',0
T_DEM1_001	LABEL	BYTE
	DB	'#DEM1\DEM1_001#We were caught flat footed there. I don''t want an'
	DB	'y more surprises to catch us off guard.',0
T_DEM1_022	LABEL	BYTE
	DB	'#DEM1\DEM1_022#Captain, I detect a recent avalanche, approximate'
	DB	'ly 6.2 kilometers away, that occurred within the last three days'
	DB	'. The mountain may be quite dangerous.',0
T_DEM1_013	LABEL	BYTE
	DB	'#DEM1\DEM1_013#Demons, Klingons, avalanches... What''s next, the '
	DB	'Wicked Witch of the West?',0
T_DEM1_024	LABEL	BYTE
	DB	'#DEM1\DEM1_024#That is not logical, doctor.',0
T_DEM1_014	LABEL	BYTE
	DB	'#DEM1\DEM1_014#It wasn''t supposed to be logical, you green blood'
	DB	'ed Vulcan! Why does everything have to be so damned logical?',0
T_DEM1_015	LABEL	BYTE
	DB	'#DEM1\DEM1_015#Well, we''ve seen Klingons. Now all we need is a f'
	DB	'ew Romulans...',0
T_DEM1_023	LABEL	BYTE
	DB	'#DEM1\DEM1_023#Control your thoughts, Doctor. There is a high pr'
	DB	'obability that something here is using our own memories against '
	DB	'us.',0
T_DEM1_026	LABEL	BYTE
	DB	'#DEM1\DEM1_026#I guess this isn''t such a great planet after all.',0

RDF	ENDS
	END
