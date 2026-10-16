; FEATHER1.RDF - "The Feathered Serpent", the pit Quetzecoatl drops the
; party into. Throwing rocks from the pile brings one of the vines low
; enough to climb out; a snake lives in a hole in the wall, and with the
; hole blocked by a rock Kirk can catch it. The communicators and
; phasers don't work.
;
; Actors: 8 Quetzecoatl, 9 the vine, 10 (0Ah) the snake, 11 (0Bh) the
; thrown rock, 12 (0Ch) the rock in the hole.
; Objects: 9/23h the vine, 0Ah the snake, 20h the rocks, 21h the hole,
; 22h the moss, 24h the light, 25h-27h eyes, 28h the way out at the top.
; Exit 3: room 2.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 103F: the engine reads its bytes
;   as key 50 6A 03 2E and next 1EFF (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
vine	EQU	RS_VARS+1	; 0 out of reach, 1 lower, 2 low enough to climb
took_rocks	EQU	RS_VARS+2
caught_snake	EQU	RS_VARS+3
hole_blocked	EQU	RS_VARS+8	; a rock blocks the snake's hole
score	EQU	RS_VARS+0Dh	; word: the mission's score

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0C7h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	0AFh
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
	DW	-1, -1, -1, 2	; room for each exit
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
	DW	62,48, 105,48	; entrance 3, crew 0
	DW	30,48, 85,48	; entrance 3, crew 1
	DW	20,48, 70,48	; entrance 3, crew 2
	DW	10,48, 55,48	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	135,186, 104,190, 85,180, 220,198
; In the room file, so these start again each time the room loads
snake_hidden	LABEL	BYTE	; the snake is in its hole
	DB	0
mccoy_joked	LABEL	BYTE
	DB	0
kirk_up	LABEL	BYTE	; at the top of the vine
	DB	0
spock_up	LABEL	BYTE
	DB	0
mccoy_up	LABEL	BYTE
	DB	0
stragey_up	LABEL	BYTE
	DB	0
N_s5r1qa	LABEL	BYTE
	DB	's5r1qa',0
N_s5r1qd	LABEL	BYTE
	DB	's5r1qd',0
N_s5r1v0	LABEL	BYTE
	DB	's5r1v0',0
N_s5r1v2	LABEL	BYTE
	DB	's5r1v2',0
N_s5r1v3	LABEL	BYTE
	DB	's5r1v3',0
N_s5r1v4	LABEL	BYTE
	DB	's5r1v4',0
N_s5r1si	LABEL	BYTE
	DB	's5r1si',0
N_s5r1so	LABEL	BYTE
	DB	's5r1so',0
N_s5r1kt	LABEL	BYTE
	DB	's5r1kt',0
N_s5r1kg	LABEL	BYTE
	DB	's5r1kg',0
N_s5r1ru	LABEL	BYTE
	DB	's5r1ru',0
N_s5r1rk	LABEL	BYTE
	DB	's5r1rk',0
N_s5r1kc	LABEL	BYTE
	DB	's5r1kc',0
N_s5r1sc	LABEL	BYTE
	DB	's5r1sc',0
N_s5r1mc	LABEL	BYTE
	DB	's5r1mc',0
N_s5r1rc	LABEL	BYTE
	DB	's5r1rc',0
N_s5r1kd	LABEL	BYTE
	DB	's5r1kd',0
N_s5r1sd	LABEL	BYTE
	DB	's5r1sd',0
N_s5r1md	LABEL	BYTE
	DB	's5r1md',0
N_s5r1rd	LABEL	BYTE
	DB	's5r1rd',0
N_kstndw	LABEL	BYTE
	DB	'kstndw',0
N_sstndw	LABEL	BYTE
	DB	'sstndw',0
N_mstndw	LABEL	BYTE
	DB	'mstndw',0
N_rstndw	LABEL	BYTE
	DB	'rstndw',0
N_sscann	LABEL	BYTE
	DB	'sscann',0
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_sscane	LABEL	BYTE
	DB	'sscane',0
N_mscane	LABEL	BYTE
	DB	'mscane',0
N_mscans	LABEL	BYTE
	DB	'mscans',0

rdf_scripts:
; The room starts. The first time, Quetzecoatl appears above the pit
; (ticks 45-95) to scold the party, and vanishes (anim msg 18).
H_019B:
	SCRIPT	MSG_TICK, 1, 0, 0, H_023B
StartRoom:
	jmp	SHORT L01AC

N_FEA1LOOP	LABEL	BYTE
	DB	'FEA1LOOP',0
L01AC:
	push	OFFSET N_FEA1LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("FEA1LOOP")
	add	sp, 4
	push	1Bh
	push	RC_MUSIC
	SERVICE		; Music(27)
	add	sp, 4
	cmp	byte ptr [si+vine], 0
	jne	L01D1
	mov	byte ptr [si+RS_BUSY], 1
L01D1:
	cmp	byte ptr [si+caught_snake], 0
	jne	L01EE
	push	0
	push	0C1h
	push	9Ch
	push	OFFSET N_s5r1so
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "s5r1so", 156, 193, 0)
	add	sp, 0Ch
L01EE:
	cmp	byte ptr [si+vine], 0
	jne	L020C
	push	0
	push	23h
	push	0A0h
	push	OFFSET N_s5r1v0
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s5r1v0", 160, 35, 0)
	add	sp, 0Ch
	jmp	SHORT L023A

L020C:
	mov	byte ptr cs:kirk_up, 1
	mov	byte ptr cs:spock_up, 1
	mov	byte ptr cs:mccoy_up, 1
	mov	byte ptr cs:stragey_up, 1
	push	0
	push	23h
	push	0A0h
	push	OFFSET N_s5r1v4
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s5r1v4", 160, 35, 0)
	add	sp, 0Ch
L023A:
	retf

H_023B:
	SCRIPT	MSG_TICK, 2Dh, 0, 0, H_0278
QuetzecoatlAppears:
	cmp	byte ptr [si+vine], 0
	jne	L0277
	jmp	SHORT L0252

N_LD3MAGAP	LABEL	BYTE
	DB	'LD3MAGAP',0
L0252:
	push	OFFSET N_LD3MAGAP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("LD3MAGAP")
	add	sp, 4
	push	0
	push	32h
	push	0B4h
	push	OFFSET N_s5r1qa
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s5r1qa", 180, 50, 0)
	add	sp, 0Ch
L0277:
	retf

H_0278:
	SCRIPT	MSG_TICK, 55h, 0, 0, H_028E
QuetzecoatlScolds:
	cmp	byte ptr [si+vine], 0
	jne	L028D
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA1_057
	call	Say
L028D:
	retf

H_028E:
	SCRIPT	MSG_TICK, 5Fh, 0, 0, H_02CA
QuetzecoatlVanishes:
	cmp	byte ptr [si+vine], 0
	jne	L02C9
	jmp	SHORT L02A5

N_LD3MAGDI	LABEL	BYTE
	DB	'LD3MAGDI',0
L02A5:
	push	OFFSET N_LD3MAGDI
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("LD3MAGDI")
	add	sp, 4
	push	12h
	push	-1
	push	-1
	push	OFFSET N_s5r1qd
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s5r1qd", -1, -1, 18)
	add	sp, 0Ch
L02C9:
	retf

H_02CA:
	SCRIPT	MSG_ANIM_DONE, 12h, 0, 0, H_02D5
QuetzecoatlGone:
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Getting the vine: out of reach until the rocks bring it down.
H_02D5:
	SCRIPT	MSG_GET, 23h, 0, 0, H_02E5
GetVine:
	mov	ax, OFFSET S_1173
	mov	bx, OFFSET T_FEA1N008
	call	Say
	retf

H_02E5:
	SCRIPT	MSG_GET, 9, 0, 0, H_0305
GetVine2:
	cmp	byte ptr [si+vine], 0
	jne	L02FB
	mov	ax, OFFSET S_1173
	mov	bx, OFFSET T_FEA1N009
	call	Say
	retf

L02FB:
	mov	ax, OFFSET S_1173
	mov	bx, OFFSET T_FEA1N008
	call	Say
	retf

; Getting rocks (msgs 6): from the pile.
H_0305:
	SCRIPT	MSG_GET, 20h, 0, 0, H_0346
GetRocks:
	cmp	byte ptr cs:kirk_up, 0
	jne	L033C
	cmp	byte ptr [si+took_rocks], 1
	jne	L0323
	mov	ax, OFFSET S_1173
	mov	bx, OFFSET T_FEA1N019
	call	Say
	retf

L0323:
	push	6
	push	0B6h
	push	90h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 144, 182, 6)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

L033C:
	mov	ax, OFFSET S_1173
	mov	bx, OFFSET T_FEA1N021
	call	Say
	retf

H_0346:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_0362
KirkAtRocks:
	push	6
	push	-1
	push	-1
	push	OFFSET N_s5r1kg
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r1kg", -1, -1, 6)
	add	sp, 0Ch
	retf

H_0362:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_0392
TookRocks:
	mov	byte ptr [si+RS_BUSY], 0
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	push	IT_ROCK
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_ROCK)
	add	sp, 4
	mov	ax, OFFSET S_1173
	mov	bx, OFFSET T_FEA1N022
	call	Say
	mov	byte ptr [si+took_rocks], 1
	retf

; Grabbing the snake (+1, msgs 8): if its hole is blocked Kirk catches it
; (timer 1), else it hides (timer 2) and comes out again (timer 0).
H_0392:
	SCRIPT	MSG_GET, 0Ah, 0, 0, H_03C7
GetSnake:
	add	word ptr [si+score], 1
	cmp	byte ptr cs:kirk_up, 0
	jne	L03BD
	push	8
	push	0BEh
	push	90h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 144, 190, 8)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

L03BD:
	mov	ax, OFFSET S_1173
	mov	bx, OFFSET T_FEA1N021
	call	Say
	retf

H_03C7:
	SCRIPT	MSG_WALK_DONE, 8, 0, 0, H_03F4
KirkGrabs:
	push	8
	push	-1
	push	-1
	push	OFFSET N_s5r1kg
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r1kg", -1, -1, 8)
	add	sp, 0Ch
	cmp	byte ptr [si+hole_blocked], 0
	jne	L03EE
	mov	word ptr [si+RS_TIMERS+4], 6
	retf

L03EE:
	mov	word ptr [si+RS_TIMERS+2], 14h
	retf

H_03F4:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_0417
SnakeCaught:
	push	IT_SNAKE
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_SNAKE)
	add	sp, 4
	push	0Ah
	push	RC_STOPANIM
	SERVICE		; StopAnim(10)
	add	sp, 4
	mov	byte ptr [si+caught_snake], 1
	retf

H_0417:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_043D
SnakeHides:
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r1si
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s5r1si", -1, -1, 0)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS], 50h
	mov	byte ptr cs:snake_hidden, 1
	retf

H_043D:
	SCRIPT	MSG_ANIM_DONE, 8, 0, 0, H_0454
GrabDone:
	mov	byte ptr [si+RS_BUSY], 0
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	retf

H_0454:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_0476
SnakeComesOut:
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r1so
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s5r1so", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr cs:snake_hidden, 0
	retf

H_0476:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_0486
UseCommunicator:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_023
	call	Say
	retf

; A rock in the hole while the snake is out (+1, msgs 9, timer 3).
H_0486:
	SCRIPT	MSG_USE, IT_ROCK, 21h, 0, H_04D7
RockInHole:
	cmp	byte ptr cs:kirk_up, 0
	jne	L04CD
	cmp	byte ptr [si+hole_blocked], 0
	jne	L04C3
	add	word ptr [si+score], 1
	push	9
	push	0B6h
	push	0A3h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 163, 182, 9)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	cmp	byte ptr cs:snake_hidden, 1
	jne	L04C2
	mov	word ptr [si+RS_TIMERS], 0Ch
L04C2:
	retf

L04C3:
	mov	ax, OFFSET S_1173
	mov	bx, OFFSET T_FEA1N005
	call	Say
	retf

L04CD:
	mov	ax, OFFSET S_1173
	mov	bx, OFFSET T_FEA1N021
	call	Say
	retf

H_04D7:
	SCRIPT	MSG_WALK_DONE, 9, 0, 0, H_04F8
KirkAtHole:
	push	9
	push	-1
	push	-1
	push	OFFSET N_s5r1kg
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r1kg", -1, -1, 9)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+6], 12h
	retf

H_04F8:
	SCRIPT	MSG_TIMER, 3, 0, 0, H_051A
HoleBlocked:
	push	0
	push	0BAh
	push	0ADh
	push	OFFSET N_s5r1rk
	push	0Ch
	push	RC_ANIM0
	SERVICE		; Anim0(12, "s5r1rk", 173, 186, 0)
	add	sp, 0Ch
	mov	byte ptr [si+hole_blocked], 1
	retf

H_051A:
	SCRIPT	MSG_ANIM_DONE, 9, 0, 0, H_0531
RockPlaced:
	mov	byte ptr [si+RS_BUSY], 0
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	retf

; The snake on things and people.
H_0531:
	SCRIPT	MSG_USE, IT_SNAKE, 9, 0, H_0541
SnakeOnVine:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_037
	call	Say
	retf

H_0541:
	SCRIPT	MSG_USE, IT_SNAKE, OBJ_SPOCK, 0, H_0563
SnakeOnSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_041
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_FEA1_001
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA1_018
	call	Say
	retf

H_0563:
	SCRIPT	MSG_USE, IT_SNAKE, OBJ_KIRK, 0, H_0573
SnakeOnKirk:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_026
	call	Say
	retf

H_0573:
	SCRIPT	MSG_USE, IT_SNAKE, OBJ_MCCOY, 0, H_0583
SnakeOnMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA1_F25
	call	Say
	retf

H_0583:
	SCRIPT	MSG_USE, IT_SNAKE, OBJ_REDSHIRT, 0, H_0593
SnakeOnStragey:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA1_050
	call	Say
	retf

; Rocks at the snake, and the crew on the snake and its hole.
H_0593:
	SCRIPT	MSG_USE, IT_ROCK, 0Ah, 0, H_05C8
RockAtSnake:
	cmp	byte ptr [si+hole_blocked], 0
	jne	L05C7
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r1si
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s5r1si", -1, -1, 0)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS], 50h
	mov	byte ptr cs:snake_hidden, 1
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA1_034
	call	Say
L05C7:
	retf

H_05C8:
	SCRIPT	MSG_USE, OBJ_SPOCK, 0Ah, 0, H_05D8
SpockGrabsSnake:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_035
	call	Say
	retf

H_05D8:
	SCRIPT	MSG_USE, OBJ_MCCOY, 0Ah, 0, H_05E8
McCoyGrabsSnake:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA1_005
	call	Say
	retf

H_05E8:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 0Ah, 0, H_05F8
StrageyGrabsSnake:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA1_046
	call	Say
	retf

H_05F8:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_061A
SpockInHole:
	cmp	byte ptr cs:snake_hidden, 0
	jne	L0610
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_027
	call	Say
	retf

L0610:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_025
	call	Say
	retf

H_061A:
	SCRIPT	MSG_USE, OBJ_MCCOY, 21h, 0, H_063C
McCoyInHole:
	cmp	byte ptr cs:snake_hidden, 0
	jne	L0632
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA1_010
	call	Say
	retf

L0632:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA1_004
	call	Say
	retf

H_063C:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 21h, 0, H_065E
StrageyInHole:
	cmp	byte ptr cs:snake_hidden, 0
	jne	L0654
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA1_051
	call	Say
	retf

L0654:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA1_047
	call	Say
	retf

; Rocks and the crew on the moss.
H_065E:
	SCRIPT	MSG_USE, IT_ROCK, 22h, 0, H_066E
RockOnMoss:
	mov	ax, OFFSET S_1173
	mov	bx, OFFSET T_FEA1N006
	call	Say
	retf

H_066E:
	SCRIPT	MSG_USE, IT_ROCK, OBJ_SPOCK, 0, H_067E
RockAtSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_032
	call	Say
	retf

H_067E:
	SCRIPT	MSG_USE, IT_ROCK, OBJ_MCCOY, 0, H_068E
RockAtMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA1_009
	call	Say
	retf

H_068E:
	SCRIPT	MSG_USE, IT_ROCK, OBJ_REDSHIRT, 0, H_069E
RockAtStragey:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA1_045
	call	Say
	retf

H_069E:
	SCRIPT	MSG_USE, OBJ_SPOCK, 22h, 0, H_06AE
SpockOnMoss:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_033
	call	Say
	retf

H_06AE:
	SCRIPT	MSG_USE, OBJ_MCCOY, 22h, 0, H_06BE
McCoyOnMoss:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA1_015
	call	Say
	retf

H_06BE:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 22h, 0, H_06CE
StrageyOnMoss:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA1_049
	call	Say
	retf

; Rocks at the vine: the first throw (msgs 1) brings it lower, the second
; (msgs 2) within reach, +6.
H_06CE:
	SCRIPT	MSG_USE, IT_ROCK, 9, 0, H_0717
RockAtVine:
	cmp	byte ptr [si+vine], 0
	jne	L06F5
	inc	byte ptr [si+vine]
	mov	byte ptr [si+RS_BUSY], 1
	push	1
	push	0B6h
	push	7Ah
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 122, 182, 1)
	add	sp, 0Ah
	retf

L06F5:
	cmp	byte ptr [si+vine], 1
	jne	L0716
	inc	byte ptr [si+vine]
	mov	byte ptr [si+RS_BUSY], 1
	push	2
	push	0B9h
	push	0A2h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 162, 185, 2)
	add	sp, 0Ah
L0716:
	retf

H_0717:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_0778
KirkThrows:
	push	1
	push	-1
	push	-1
	push	OFFSET N_s5r1kt
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r1kt", -1, -1, 1)
	add	sp, 0Ch
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r1v2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s5r1v2", -1, -1, 0)
	add	sp, 0Ch
	push	0
	push	6Dh
	push	81h
	push	OFFSET N_s5r1ru
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, "s5r1ru", 129, 109, 0)
	add	sp, 0Ch
	jmp	SHORT L0768

N_THROWROC	LABEL	BYTE
	DB	'THROWROC',0
L0768:
	push	OFFSET N_THROWROC
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("THROWROC")
	add	sp, 4
	retf

H_0778:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_07AA
VineLower:
	mov	byte ptr [si+RS_BUSY], 0
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_042
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA1_017
	call	Say
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA1_054
	call	Say
	retf

H_07AA:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_080B
KirkThrowsAgain:
	push	2
	push	-1
	push	-1
	push	OFFSET N_s5r1kt
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r1kt", -1, -1, 2)
	add	sp, 0Ch
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r1v3
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s5r1v3", -1, -1, 0)
	add	sp, 0Ch
	push	0
	push	70h
	push	0A3h
	push	OFFSET N_s5r1ru
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, "s5r1ru", 163, 112, 0)
	add	sp, 0Ch
	jmp	SHORT L07FB

N_THROWROC_2	LABEL	BYTE
	DB	'THROWROC',0
L07FB:
	push	OFFSET N_THROWROC_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("THROWROC")
	add	sp, 4
	retf

H_080B:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_0841
VineInReach:
	add	word ptr [si+score], 6
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_043
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA1_021
	call	Say
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA1_053
	call	Say
	retf

; Climbing the vine, once it is low enough (msgs 3-13): up, and down
; again for whoever is at the top.
H_0841:
	SCRIPT	MSG_USE, OBJ_SPOCK, 9, 0, H_0849
	jmp	SHORT SpockClimbs

H_0849:
	SCRIPT	MSG_USE, OBJ_SPOCK, 23h, 0, H_0898
SpockClimbs:
	cmp	byte ptr [si+vine], 2
	jne	L088E
	cmp	byte ptr cs:spock_up, 0
	jne	L0876
	push	3
	push	0C7h
	push	0C3h
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 195, 199, 3)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

L0876:
	push	0Ah
	push	30h
	push	0CCh
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 204, 48, 10)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

L088E:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_A46
	call	Say
	retf

H_0898:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_08B4
SpockAtVine:
	push	3
	push	-1
	push	-1
	push	OFFSET N_s5r1sc
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "s5r1sc", -1, -1, 3)
	add	sp, 0Ch
	retf

H_08B4:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_08EE
SpockUp:
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr cs:spock_up, 1
	push	0
	push	30h
	push	0CCh
	push	OFFSET N_sstndw
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sstndw", 204, 48, 0)
	add	sp, 0Ch
	push	0
	push	30h
	push	0AFh
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 175, 48, 0)
	add	sp, 0Ah
	retf

H_08EE:
	SCRIPT	MSG_WALK_DONE, 0Ah, 0, 0, H_090C
SpockClimbsDown:
	push	0Ah
	push	0C7h
	push	0C3h
	push	OFFSET N_s5r1sd
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "s5r1sd", 195, 199, 10)
	add	sp, 0Ch
	retf

H_090C:
	SCRIPT	MSG_ANIM_DONE, 0Ah, 0, 0, H_0947
SpockDown:
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr cs:spock_up, 0
	push	0
	push	0C7h
	push	0C3h
	push	OFFSET N_sstndw
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sstndw", 195, 199, 0)
	add	sp, 0Ch
	push	0
	push	0BEh
	push	68h
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 104, 190, 0)
	add	sp, 0Ah
	retf

H_0947:
	SCRIPT	MSG_USE, OBJ_MCCOY, 9, 0, H_094F
	jmp	SHORT McCoyClimbs

H_094F:
	SCRIPT	MSG_USE, OBJ_MCCOY, 23h, 0, H_099E
McCoyClimbs:
	cmp	byte ptr [si+vine], 2
	jne	L0994
	cmp	byte ptr cs:mccoy_up, 0
	jne	L097C
	push	4
	push	0C7h
	push	0C3h
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 195, 199, 4)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

L097C:
	push	0Bh
	push	30h
	push	0CCh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 204, 48, 11)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

L0994:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA1_013
	call	Say
	retf

H_099E:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_09BA
McCoyAtVine:
	push	4
	push	-1
	push	-1
	push	OFFSET N_s5r1mc
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "s5r1mc", -1, -1, 4)
	add	sp, 0Ch
	retf

H_09BA:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_09F4
McCoyUp:
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr cs:mccoy_up, 1
	push	0
	push	30h
	push	0CCh
	push	OFFSET N_mstndw
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mstndw", 204, 48, 0)
	add	sp, 0Ch
	push	0
	push	30h
	push	0BEh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 190, 48, 0)
	add	sp, 0Ah
	retf

H_09F4:
	SCRIPT	MSG_WALK_DONE, 0Bh, 0, 0, H_0A12
McCoyClimbsDown:
	push	0Bh
	push	0C7h
	push	0C3h
	push	OFFSET N_s5r1md
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "s5r1md", 195, 199, 11)
	add	sp, 0Ch
	retf

H_0A12:
	SCRIPT	MSG_ANIM_DONE, 0Bh, 0, 0, H_0A4D
McCoyDown:
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr cs:mccoy_up, 0
	push	0
	push	0C7h
	push	0C3h
	push	OFFSET N_mstndw
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mstndw", 195, 199, 0)
	add	sp, 0Ch
	push	0
	push	0B4h
	push	55h
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 85, 180, 0)
	add	sp, 0Ah
	retf

H_0A4D:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 9, 0, H_0A55
	jmp	SHORT StrageyClimbs

H_0A55:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 23h, 0, H_0AA4
StrageyClimbs:
	cmp	byte ptr [si+vine], 2
	jne	L0A9A
	cmp	byte ptr cs:stragey_up, 0
	jne	L0A82
	push	5
	push	0C7h
	push	0C3h
	push	3
	push	RC_WALK
	SERVICE		; Walk(3, 195, 199, 5)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

L0A82:
	push	0Ch
	push	30h
	push	0CCh
	push	3
	push	RC_WALK
	SERVICE		; Walk(3, 204, 48, 12)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

L0A9A:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA1_052
	call	Say
	retf

H_0AA4:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_0AC0
StrageyAtVine:
	push	5
	push	-1
	push	-1
	push	OFFSET N_s5r1rc
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "s5r1rc", -1, -1, 5)
	add	sp, 0Ch
	retf

H_0AC0:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_0AFA
StrageyUp:
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr cs:stragey_up, 1
	push	0
	push	30h
	push	0D2h
	push	OFFSET N_rstndw
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rstndw", 210, 48, 0)
	add	sp, 0Ch
	push	0
	push	30h
	push	0CAh
	push	3
	push	RC_WALK
	SERVICE		; Walk(3, 202, 48, 0)
	add	sp, 0Ah
	retf

H_0AFA:
	SCRIPT	MSG_WALK_DONE, 0Ch, 0, 0, H_0B18
StrageyClimbsDown:
	push	0Ch
	push	0C7h
	push	0C3h
	push	OFFSET N_s5r1rd
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "s5r1rd", 195, 199, 12)
	add	sp, 0Ch
	retf

H_0B18:
	SCRIPT	MSG_ANIM_DONE, 0Ch, 0, 0, H_0B54
StrageyDown:
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr cs:stragey_up, 0
	push	0
	push	0C7h
	push	0C3h
	push	OFFSET N_rstndw
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rstndw", 195, 199, 0)
	add	sp, 0Ch
	push	0
	push	0C6h
	push	0DCh
	push	3
	push	RC_WALK
	SERVICE		; Walk(3, 220, 198, 0)
	add	sp, 0Ah
	retf

H_0B54:
	SCRIPT	MSG_USE, OBJ_KIRK, 9, 0, H_0B5C
	jmp	SHORT KirkClimbs

H_0B5C:
	SCRIPT	MSG_USE, OBJ_KIRK, 23h, 0, H_0BAB
KirkClimbs:
	cmp	byte ptr [si+vine], 2
	jne	L0BA1
	cmp	byte ptr cs:kirk_up, 0
	jne	L0B89
	push	7
	push	0C7h
	push	0C3h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 195, 199, 7)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

L0B89:
	push	0Dh
	push	30h
	push	0CCh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 204, 48, 13)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

L0BA1:
	mov	ax, OFFSET S_1173
	mov	bx, OFFSET T_FEA1N010
	call	Say
	retf

H_0BAB:
	SCRIPT	MSG_WALK_DONE, 7, 0, 0, H_0BC7
KirkAtVine:
	push	7
	push	-1
	push	-1
	push	OFFSET N_s5r1kc
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r1kc", -1, -1, 7)
	add	sp, 0Ch
	retf

H_0BC7:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_0C01
KirkUp:
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr cs:kirk_up, 1
	push	0
	push	30h
	push	0CCh
	push	OFFSET N_kstndw
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kstndw", 204, 48, 0)
	add	sp, 0Ch
	push	0
	push	30h
	push	0A0h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 160, 48, 0)
	add	sp, 0Ah
	retf

H_0C01:
	SCRIPT	MSG_WALK_DONE, 0Dh, 0, 0, H_0C1F
KirkClimbsDown:
	push	0Dh
	push	0C7h
	push	0C3h
	push	OFFSET N_s5r1kd
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r1kd", 195, 199, 13)
	add	sp, 0Ch
	retf

H_0C1F:
	SCRIPT	MSG_ANIM_DONE, 0Dh, 0, 0, H_0C5B
KirkDown:
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr cs:kirk_up, 0
	push	0
	push	0C7h
	push	0C3h
	push	OFFSET N_kstndw
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kstndw", 195, 199, 0)
	add	sp, 0Ch
	push	0
	push	0BAh
	push	87h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 135, 186, 0)
	add	sp, 0Ah
	retf

; Phasers don't work here.
H_0C5B:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_0C6B
StunAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_028
	call	Say
	retf

H_0C6B:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_0C7B
KillAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_028
	call	Say
	retf

; Tricorders.
H_0C7B:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_0CAC
SpockScansVine:
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
	mov	bx, OFFSET T_FEA1_039
	call	Say
	retf

H_0CAC:
	SCRIPT	MSG_USE, IT_STRICOR, 0Ah, 0, H_0CDD
SpockScansSnake:
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
	mov	bx, OFFSET T_FEA1_029
	call	Say
	retf

H_0CDD:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_0D0E
SpockScansMoss:
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
	mov	bx, OFFSET T_FEA1_038
	call	Say
	retf

H_0D0E:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_0D51
SpockScansHole:
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
	cmp	byte ptr cs:snake_hidden, 1
	jne	L0D47
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_030
	call	Say
	retf

L0D47:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_031
	call	Say
	retf

H_0D51:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_0D82
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
	mov	bx, OFFSET T_FEA1_024
	call	Say
	retf

H_0D82:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_0DB3
SpockScansRocks:
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
	mov	bx, OFFSET T_FEA1_003
	call	Say
	retf

H_0DB3:
	SCRIPT	MSG_USE, IT_MTRICOR, 9, 0, H_0DC3
McCoyScansVine:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA1_007
	call	Say
	retf

H_0DC3:
	SCRIPT	MSG_USE, IT_MTRICOR, 23h, 0, H_0DD3
McCoyScansVine2:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA1_007
	call	Say
	retf

H_0DD3:
	SCRIPT	MSG_USE, IT_MTRICOR, 22h, 0, H_0E04
McCoyScansMoss:
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
	mov	bx, OFFSET T_FEA1_014
	call	Say
	retf

H_0E04:
	SCRIPT	MSG_USE, IT_MTRICOR, 21h, 0, H_0E47
McCoyScansHole:
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
	cmp	byte ptr cs:snake_hidden, 1
	jne	L0E3D
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA1_011
	call	Say
	retf

L0E3D:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA1_012
	call	Say
	retf

H_0E47:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Ah, 0, H_0EA1
McCoyScansSnake:
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
	mov	bx, OFFSET T_FEA1_019
	call	Say
	cmp	byte ptr cs:mccoy_joked, 0
	jne	L0EA0
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_044
	call	Say
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA1_055
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_FEA1_002
	call	Say
	mov	byte ptr cs:mccoy_joked, 1
L0EA0:
	retf

H_0EA1:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, H_0F04
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA1_008
	call	Say
	retf

T_FEA1_008	LABEL	BYTE
	DB	'#FEA1\FEA1_008#Everyone is healthy, Jim, there''s no need for the'
	DB	' medical kit here.',0

H_0F04:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0F14
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA1_006
	call	Say
	retf

H_0F14:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0F24
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA1_040
	call	Say
	retf

H_0F24:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0F34
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA1_048
	call	Say
	retf

; Walking off at the top (exit 3, room 2).
H_0F34:
	SCRIPT	MSG_WALK, 28h, 0, 0, H_0F4D
WalkOut:
	push	0
	push	30h
	push	0Ah
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 10, 48, 0)
	add	sp, 0Ah
	retf

; Looking.
H_0F4D:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_0F5C
LookAtScene:
	sub	ax, ax
	mov	bx, OFFSET T_FEA1N020
	call	Say
	retf

H_0F5C:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_0F6B
LookAtSnake:
	sub	ax, ax
	mov	bx, OFFSET T_FEA1N017
	call	Say
	retf

H_0F6B:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_0F7A
LookAtVine:
	sub	ax, ax
	mov	bx, OFFSET T_FEA1N015
	call	Say
	retf

H_0F7A:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_0F89
LookAtHole:
	sub	ax, ax
	mov	bx, OFFSET T_FEA1N014
	call	Say
	retf

H_0F89:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_0F98
LookAtMoss:
	sub	ax, ax
	mov	bx, OFFSET T_FEA1N016
	call	Say
	retf

H_0F98:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_0FA7
LookAtRocks:
	sub	ax, ax
	mov	bx, OFFSET T_FEA1N011
	call	Say
	retf

H_0FA7:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_0FB6
LookAtLight:
	sub	ax, ax
	mov	bx, OFFSET T_FEA1N013
	call	Say
	retf

H_0FB6:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_0FC5
LookAtEyes1:
	sub	ax, ax
	mov	bx, OFFSET T_FEA1N000
	call	Say
	retf

H_0FC5:
	SCRIPT	MSG_LOOK, 26h, 0, 0, H_0FD4
LookAtEyes2:
	sub	ax, ax
	mov	bx, OFFSET T_FEA1N000
	call	Say
	retf

H_0FD4:
	SCRIPT	MSG_LOOK, 27h, 0, 0, H_0FE3
LookAtEyes3:
	sub	ax, ax
	mov	bx, OFFSET T_FEA1N000
	call	Say
	retf

H_0FE3:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_0FF2
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_FEA1N001
	call	Say
	retf

H_0FF2:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_1001
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_FEA1N004
	call	Say
	retf

H_1001:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_1010
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_FEA1N003
	call	Say
	retf

H_1010:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_101F
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_FEA1N002
	call	Say
	retf

H_101F:
	SCRIPT	MSG_LOOK, 9, 0, 0, Talk
LookAtVines:
	cmp	byte ptr [si+vine], 0
	jne	L1035
	mov	ax, OFFSET S_1173
	mov	bx, OFFSET T_FEA1N012
	call	Say
	retf

L1035:
	mov	ax, OFFSET S_1173
	mov	bx, OFFSET T_FEA1N015
	call	Say
	retf

; Talk: conversation AX (speaker, choices, 0); returns the choice.
Talk:
	push	ax
	push	RC_TALK
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
	DW	20h, 5	; id, points
	DW	146,163, 161,172, 161,182, 137,182, 131,173
	DW	21h, 4	; id, points
	DW	166,173, 184,173, 184,183, 166,183
	DW	22h, 4	; id, points
	DW	172,154, 225,154, 225,168, 172,168
	DW	23h, 4	; id, points
	DW	188,0, 199,0, 199,148, 188,148
	DW	24h, 4	; id, points
	DW	141,65, 155,65, 155,78, 141,78
	DW	25h, 4	; id, points
	DW	47,10, 57,10, 57,20, 47,20
	DW	26h, 4	; id, points
	DW	225,20, 235,20, 235,30, 225,30
	DW	27h, 4	; id, points
	DW	162,45, 172,45, 172,55, 162,55
	DW	28h, 4	; id, points
	DW	0,0, 55,0, 55,55, 0,55
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	3, 4	; id, points
	DW	0,30, 60,30, 60,66, 0,66
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's5r1ff',0
	DB	's5r1e5',0
	DB	's5r1e6',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Quetzecoatl	LABEL	BYTE
	DB	'Quetzecoatl',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Stragey	LABEL	BYTE
	DB	'Lt. Stragey',0
S_1173	LABEL	BYTE
	DB	0
T_FEA1_057	LABEL	BYTE
	DB	'#FEA1\FEA1_057#You clearly are not the inheritors of the noble A'
	DB	'ztec world.  What you have said has greatly disturbed me. You sh'
	DB	'ould not lie so. You shall remain here until you have learned th'
	DB	'e error of angering Quetzecoatl!',0
T_FEA1_023	LABEL	BYTE
	DB	'#FEA1\FEA1_023#Fascinating. Our communicators have apparently be'
	DB	'en rendered ineffective.',0
T_FEA1N000	LABEL	BYTE
	DB	'#FEA1\FEA1N000#Feral red eyes glare out of the dark at you.',0
T_FEA1_032	LABEL	BYTE
	DB	'#FEA1\FEA1_032#Thank you, Captain, but I assure you that I was g'
	DB	'iving this situation my fullest attention.',0
T_FEA1_009	LABEL	BYTE
	DB	'#FEA1\FEA1_009#Hey! What was that for?',0
T_FEA1_045	LABEL	BYTE
	DB	'#FEA1\FEA1_045#I''m glad I was taught pain-nullification techniqu'
	DB	'es.',0
T_FEA1N005	LABEL	BYTE
	DB	'#FEA1\FEA1N005#The hole is already blocked.',0
T_FEA1N010	LABEL	BYTE
	DB	'#FEA1\FEA1N010#The vine will not support you.',0
T_FEA1_037	LABEL	BYTE
	DB	'#FEA1\FEA1_037#This isn''t very logical, but as you are human, it'
	DB	'''s quite understandable.',0
T_FEA1_A46	LABEL	BYTE
	DB	'#FEA1\FEA1_A46#There is not enough support, Captain.',0
T_FEA1_013	LABEL	BYTE
	DB	'#FEA1\FEA1_013#It''s bad enough that you put me in the damn trans'
	DB	'porter, now you want me to break my neck climbing that?!',0
T_FEA1_052	LABEL	BYTE
	DB	'#FEA1\FEA1_052#There''s no way that we''re getting up that way, Ca'
	DB	'ptain.  The vine is too weak.',0
T_FEA1_042	LABEL	BYTE
	DB	'#FEA1\FEA1_042#Fascinating. It did appear to knock the vine down'
	DB	' near to the point where one of us can reach it.',0
T_FEA1_017	LABEL	BYTE
	DB	'#FEA1\FEA1_017#Didn''t they have baseball on Vulcan? Show us your'
	DB	' fastball, Jim.',0
T_FEA1_054	LABEL	BYTE
	DB	'#FEA1\FEA1_054#Baseball? No one plays that anymore. Good try tho'
	DB	'ugh, sir.',0
T_FEA1_043	LABEL	BYTE
	DB	'#FEA1\FEA1_043#The probability of getting the vine on the second'
	DB	' try was only 36.53%. Well done, Captain.',0
T_FEA1_021	LABEL	BYTE
	DB	'#FEA1\FEA1_021#Probability? That was a perfect pitch if I ever s'
	DB	'aw one.',0
T_FEA1_053	LABEL	BYTE
	DB	'#FEA1\FEA1_053#All Right! We''re on our way!',0
T_FEA1_034	LABEL	BYTE
	DB	'#FEA1\FEA1_034#The snake has gone back into the hole, Captain.',0
T_FEA1_035	LABEL	BYTE
	DB	'#FEA1\FEA1_035#The snake is too quick to be easily grabbed, befo'
	DB	're it retreats Captain.',0
T_FEA1_005	LABEL	BYTE
	DB	'#FEA1\FEA1_005#Are you nuts? There''s no way I''m touching any dam'
	DB	'ned snake!',0
T_FEA1_046	LABEL	BYTE
	DB	'#FEA1\FEA1_046#It doesn''t seem to want to be grabbed, sir. It ju'
	DB	'st slithers back to its hole.',0
T_FEA1_027	LABEL	BYTE
	DB	'#FEA1\FEA1_027#I see no logic in searching an empty hole, Captai'
	DB	'n.',0
T_FEA1_025	LABEL	BYTE
	DB	'#FEA1\FEA1_025#I can not reach the snake, Captain.',0
T_FEA1_010	LABEL	BYTE
	DB	'#FEA1\FEA1_010#I''m not putting my fingers in there, Jim.',0
T_FEA1_004	LABEL	BYTE
	DB	'#FEA1\FEA1_004#And get my fingers taken off by some alien reptil'
	DB	'e? You''ve got to be joking.',0
T_FEA1_051	LABEL	BYTE
	DB	'#FEA1\FEA1_051#The hole is empty, sir.',0
T_FEA1_047	LABEL	BYTE
	DB	'#FEA1\FEA1_047#It''s coming out again, sir.',0
T_FEA1N006	LABEL	BYTE
	DB	'#FEA1\FEA1N006#The rock is a bit stickier.',0
T_FEA1_033	LABEL	BYTE
	DB	'#FEA1\FEA1_033#The resin does not seem to have any unusual prope'
	DB	'rties.',0
T_FEA1_015	LABEL	BYTE
	DB	'#FEA1\FEA1_015#No toxic reaction. It appears to be ordinary, exc'
	DB	'ept for this resin.',0
T_FEA1_049	LABEL	BYTE
	DB	'#FEA1\FEA1_049#Sure is sticky sir. I can''t see much use in it.',0
	DB	'#GENE\G_043#Ouch! Watch it with that thing!',0
T_FEA1_F25	LABEL	BYTE
	DB	'#FEA1\FEA1_F25#What on Earth are you doing with that slithering '
	DB	'thing!',0
T_FEA1_026	LABEL	BYTE
	DB	'#FEA1\FEA1_026#I realize that humans form emotional bonds with p'
	DB	'ets, but I recommend tribbles.',0
T_FEA1_050	LABEL	BYTE
	DB	'#FEA1\FEA1_050#That''s something of a runt, Captain. You should''v'
	DB	'e seen this Rigilian python that Cadet Tyrli put in the shower a'
	DB	't the Academy. Twenty meters long!',0
T_FEA1N012	LABEL	BYTE
	DB	'#FEA1\FEA1N012#There are several loose vines hanging over the si'
	DB	'de of the pit, out of reach. This is one of them.',0
T_FEA1N015	LABEL	BYTE
	DB	'#FEA1\FEA1N015#There is a vine hanging down into the pit.',0
T_FEA1N020	LABEL	BYTE
	DB	'#FEA1\FEA1N020#You are in a deep pit. It is a long, hard climb t'
	DB	'o the top.',0
T_FEA1N017	LABEL	BYTE
	DB	'#FEA1\FEA1N017#This particular snake doesn''t seem to like your c'
	DB	'ompany, and moves whenever you get near it.',0
T_FEA1N014	LABEL	BYTE
	DB	'#FEA1\FEA1N014#There is a tiny hole in the wall at this point. C'
	DB	'ertainly no human could crawl through here.',0
T_FEA1N016	LABEL	BYTE
	DB	'#FEA1\FEA1N016#This moss is covered with a very sticky substance'
	DB	'.',0
T_FEA1N011	LABEL	BYTE
	DB	'#FEA1\FEA1N011#There are rocks here, quite suitable for picking '
	DB	'up and throwing.',0
T_FEA1N013	LABEL	BYTE
	DB	'#FEA1\FEA1N013#There is a light suspended from above by a chain.',0
T_FEA1_006	LABEL	BYTE
	DB	'#FEA1\FEA1_006#Do I look like Houdini to you? I''m afraid you''re '
	DB	'going to have to pull the rabbit out of the hat on this one.',0
T_FEA1_040	LABEL	BYTE
	DB	'#FEA1\FEA1_040#Those vines would be useful to escape, if we coul'
	DB	'd reach them.',0
T_FEA1_048	LABEL	BYTE
	DB	'#FEA1\FEA1_048#No enemies in sight, but supplies could be a prob'
	DB	'lem if we don''t get out.',0
T_FEA1N021	LABEL	BYTE
	DB	'#FEA1\FEA1N021#You cannot reach it from where you are.',0
T_FEA1N022	LABEL	BYTE
	DB	'#FEA1\FEA1N022#You pick up some rocks from the pile.',0
T_FEA1N019	LABEL	BYTE
	DB	'#FEA1\FEA1N019#You already have rocks.',0
T_FEA1N009	LABEL	BYTE
	DB	'#FEA1\FEA1N009#The vine is not within reach.',0
T_FEA1N008	LABEL	BYTE
	DB	'#FEA1\FEA1N008#The vine is attached to a tree above you.',0
	DB	'#FEA1\FEA1N007#The snake darts back into its hole before you can'
	DB	' catch it.',0
	DB	'#FEA1\FEA1N018#With no where for the snake to go, you easliy cap'
	DB	'ture it.',0
T_FEA1_028	LABEL	BYTE
	DB	'#FEA1\FEA1_028#It is logical that an entity that professes to te'
	DB	'ach peace would render our phasers inoperative.',0
T_FEA1_039	LABEL	BYTE
	DB	'#FEA1\FEA1_039#This vine is not likely to support our weight by '
	DB	'itself, Captain. You would have to find some way to reinforce it'
	DB	'.',0
T_FEA1_029	LABEL	BYTE
	DB	'#FEA1\FEA1_029#It looks like a Zamphorian pit snake. A rather co'
	DB	'mmon species in this region, noted by galactic herpatologists fo'
	DB	'r their quickness. It is not venomous or dangerous to humans. ',0
T_FEA1_031	LABEL	BYTE
	DB	'#FEA1\FEA1_031#It would appear that this is where the snake live'
	DB	's, Captain.',0
T_FEA1_030	LABEL	BYTE
	DB	'#FEA1\FEA1_030#It would appear that this is where the snake live'
	DB	's, Captain. It is currently inside.',0
T_FEA1_038	LABEL	BYTE
	DB	'#FEA1\FEA1_038#This variety of moss seems to leave a very sticky'
	DB	' resin behind. Perhaps to trap the large amounts of pollen from '
	DB	'the plants on the surface, and use it as a secondary food source'
	DB	'.',0
T_FEA1_014	LABEL	BYTE
	DB	'#FEA1\FEA1_014#It''s moss. Anyone got any rolling stones?',0
T_FEA1_012	LABEL	BYTE
	DB	'#FEA1\FEA1_012#It''s a damned hole.',0
T_FEA1_011	LABEL	BYTE
	DB	'#FEA1\FEA1_011#It''s a damned hole with a snake in it.',0
T_FEA1_019	LABEL	BYTE
	DB	'#FEA1\FEA1_019#It''s a damned snake! Do you know what snakebite d'
	DB	'oes? It can ruin your whole day.',0
T_FEA1_044	LABEL	BYTE
	DB	'#FEA1\FEA1_044#We are not likely to find a way out of this pit w'
	DB	'ith humor, doctor. I suggest you concentrate your efforts to the'
	DB	' problem at hand.',0
T_FEA1_055	LABEL	BYTE
	DB	'#FEA1\FEA1_055#Do they always argue like this, Captain?',0
T_FEA1_002	LABEL	BYTE
	DB	'#FEA1\FEA1_002#Well, yes.',0
T_FEA1_007	LABEL	BYTE
	DB	'#FEA1\FEA1_007#Does it look sick to you, Captain?',0
	DB	'#FEA1\FEA1_022#The bite wasn''t serious Captain. He''ll be fine, b'
	DB	'ut I would like to get him to sickbay in case there''s some alien'
	DB	' infection.',0
	DB	'#FEA1\FEA1_056#Doctors! It''ll take more than a couple of scratch'
	DB	'es to put me out action, sir.',0
	DB	'#FEA1\FEA1_020#It''s bad enough being around pointy-eared Vulcans'
	DB	', now I have to listen to ensigns who think they can do my job!',0
T_FEA1N001	LABEL	BYTE
	DB	'#FEA1\FEA1N001#James T. Kirk does not seem very happy with his c'
	DB	'urrent predicament.',0
T_FEA1N004	LABEL	BYTE
	DB	'#FEA1\FEA1N004#Spock is carefully examining the pit.',0
T_FEA1N003	LABEL	BYTE
	DB	'#FEA1\FEA1N003#McCoy is examining the floor of the pit.',0
T_FEA1N002	LABEL	BYTE
	DB	'#FEA1\FEA1N002#Lt. Stragey is carefully examining the pit.',0
T_FEA1_041	LABEL	BYTE
	DB	'#FEA1\FEA1_041#A fascinating specimen, Captain, but I would be c'
	DB	'areful handling it. From the looks of it, it must have a nasty b'
	DB	'ite.',0
T_FEA1_001	LABEL	BYTE
	DB	'#FEA1\FEA1_001#We wouldn''t want to bleed all over Dr. McCoy now,'
	DB	' would we?',0
T_FEA1_018	LABEL	BYTE
	DB	'#FEA1\FEA1_018#Especially that green Vulcan blood. The last thin'
	DB	'g I need is a pint of T-Negative blood all over my uniform.',0
T_FEA1_003	LABEL	BYTE
	DB	'#FEA1\FEA1_003#A pile of small igneous rocks, Captain.',0
T_FEA1_024	LABEL	BYTE
	DB	'#FEA1\FEA1_024#I am picking up residual energy readings from the'
	DB	' area where the alien''s projection was.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
