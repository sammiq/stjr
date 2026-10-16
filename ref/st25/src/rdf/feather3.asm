; FEATHER3.RDF - "The Feathered Serpent", the path to Quetzecoatl's grove,
; guarded by Tlaoxac, his priest. Only a man of courage who has shed his
; own blood may pass: the snake from the pit (room 1) shown to him, then
; biting Kirk or Stragey, opens the way. Two rocks knock him out instead
; (at a cost); a threat makes him kill Stragey. He drops a knife.
;
; Actors: 8 Tlaoxac, 9 the knife, 10 (0Ah) the thrown rock.
; Objects: 8 Tlaoxac, 9 the knife, 20h the path, 21h/22h the lamps.
; Exits: 2 room 2, 3 room 4. Region 0: the way past Tlaoxac.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 09D7: the engine reads its bytes
;   as key 50 6A 03 2E and next 1EFF (beyond rdf_scripts_end, so the search
;   stops).
; - Code at 0699 runs on into the script header at 069C.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
took_knife	EQU	RS_VARS+4
shed_blood	EQU	RS_VARS+5	; blood has been shed for Tlaoxac
rocks_thrown	EQU	RS_VARS+6	; rocks thrown at Tlaoxac: the second knocks him out
may_pass	EQU	RS_VARS+9	; Tlaoxac lets the party by
knocked_out	EQU	RS_VARS+0Ah	; Tlaoxac is unconscious
showed_snake	EQU	RS_VARS+0Ch	; the point for showing the snake
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
	DW	5Bh
rdf_scale_min	LABEL	BYTE
	DW	0A0h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, -1, 2, 4	; room for each exit
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
	DW	270,170, 162,190	; entrance 2, crew 0
	DW	280,170, 166,160	; entrance 2, crew 1
	DW	290,170, 182,182	; entrance 2, crew 2
	DW	307,170, 124,178	; entrance 2, crew 3
	DW	42,185, 162,190	; entrance 3, crew 0
	DW	26,178, 166,160	; entrance 3, crew 1
	DW	27,195, 182,182	; entrance 3, crew 2
	DW	10,188, 124,178	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	162,190, 166,160, 202,182, 124,178
; In the room file, so these start again each time the room loads
snake_shown	LABEL	BYTE	; Tlaoxac has seen the snake this visit
	DB	0
tlaoxac_down	LABEL	BYTE
	DB	0
N_s5r1kg	LABEL	BYTE
	DB	's5r1kg',0
N_s5r3kt	LABEL	BYTE
	DB	's5r3kt',0
N_s5r3rd	LABEL	BYTE
	DB	's5r3rd',0
N_s5r3as	LABEL	BYTE
	DB	's5r3as',0
N_s5r3aj	LABEL	BYTE
	DB	's5r3aj',0
N_s5r3ah	LABEL	BYTE
	DB	's5r3ah',0
N_s5r3ad	LABEL	BYTE
	DB	's5r3ad',0
N_s5r3nf	LABEL	BYTE
	DB	's5r3nf',0
N_s5r3rt	LABEL	BYTE
	DB	's5r3rt',0
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_sscanw	LABEL	BYTE
	DB	'sscanw',0
N_mscann	LABEL	BYTE
	DB	'mscann',0
N_mscanw	LABEL	BYTE
	DB	'mscanw',0
N_feather3	LABEL	BYTE
	DB	'feather3',0
N_feath3b	LABEL	BYTE
	DB	'feath3b',0

rdf_scripts:
; The room starts: Tlaoxac blocking the path, the knife if dropped.
H_0138:
	SCRIPT	MSG_TICK, 1, 0, 0, H_01AB
StartRoom:
	jmp	SHORT L0149

N_FEA3LOOP	LABEL	BYTE
	DB	'FEA3LOOP',0
L0149:
	push	OFFSET N_FEA3LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("FEA3LOOP")
	add	sp, 4
	push	1Dh
	push	RC_MUSIC
	SERVICE		; Music(29)
	add	sp, 4
	cmp	byte ptr [si+may_pass], 0
	jne	L018E
	push	0
	push	0ABh
	push	2Eh
	push	OFFSET N_s5r3as
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s5r3as", 46, 171, 0)
	add	sp, 0Ch
	push	OFFSET N_feath3b
	push	RC_LOADMAP
	SERVICE		; LoadMap("feath3b")
	add	sp, 4
	retf

L018E:
	cmp	byte ptr [si+took_knife], 0
	jne	L01AA
	push	0
	push	0B4h
	push	64h
	push	OFFSET N_s5r3nf
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s5r3nf", 100, 180, 0)
	add	sp, 0Ch
L01AA:
	retf

; Tick 40, region 0: Tlaoxac challenges the party and blocks the way.
H_01AB:
	SCRIPT	MSG_TICK, 28h, 0, 0, H_01C1
TlaoxacSpeaks:
	cmp	byte ptr [si+may_pass], 0
	jne	L01C0
	mov	ax, OFFSET N_Tlaoxac
	mov	bx, OFFSET T_FEA3_036
	call	Say
L01C0:
	retf

H_01C1:
	SCRIPT	MSG_REGION, 0, 0, 0, H_01D7
TlaoxacBlocks:
	cmp	byte ptr [si+may_pass], 0
	jne	L01D6
	mov	ax, OFFSET N_Tlaoxac
	mov	bx, OFFSET T_FEA3_035
	call	Say
L01D6:
	retf

; The crew on Tlaoxac and on the path: none will fight him.
H_01D7:
	SCRIPT	MSG_USE, OBJ_SPOCK, 8, 0, H_0202
SpockFightsTlaoxac:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA3_026
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA3_018
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA3_028
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA3_015
	call	Say
	retf

H_0202:
	SCRIPT	MSG_USE, OBJ_MCCOY, 8, 0, H_0224
McCoyFightsTlaoxac:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA3_016
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA3_027
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA3_017
	call	Say
	retf

H_0224:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 8, 0, H_023A
StrageyFightsTlaoxac:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L0239
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA3_029
	call	Say
L0239:
	retf

H_023A:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_0242
SpockOnPath:
	jmp	SHORT L0256

H_0242:
	SCRIPT	MSG_USE, OBJ_MCCOY, 20h, 0, H_024A
McCoyOnPath:
	jmp	SHORT L0256

H_024A:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 20h, 0, H_0266
StrageyOnPath:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L0256
L0256:
	cmp	byte ptr [si+may_pass], 0
	jne	L0265
	mov	ax, OFFSET N_Tlaoxac
	mov	bx, OFFSET T_FEA3_041
	call	Say
L0265:
	retf

; The communicator.
H_0266:
	SCRIPT	MSG_USE, IT_COMM, OBJ_KIRK, 0, H_0276
CommOnKirk:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA3_024
	call	Say
	retf

; The snake: shown to Tlaoxac (+1 once), then bitten by it Kirk (+2) or
; Stragey (+1, msg 2) has shed blood and the way is open.
H_0276:
	SCRIPT	MSG_USE, IT_SNAKE, OBJ_KIRK, 0, H_02D9
SnakeBitesKirk:
	cmp	byte ptr [si+may_pass], 0
	jne	L02CE
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 0
	jne	L02CE
	cmp	byte ptr cs:snake_shown, 1
	jne	L02CF
	cmp	byte ptr [si+rocks_thrown], 0
	jne	L02CF
	mov	ax, OFFSET N_Tlaoxac
	mov	bx, OFFSET T_FEA3_043
	call	Say
	mov	byte ptr [si+may_pass], 1
	add	word ptr [si+score], 2
	push	OFFSET N_feather3
	push	RC_LOADMAP
	SERVICE		; LoadMap("feather3")
	add	sp, 4
	push	0
	push	0B4h
	push	64h
	push	OFFSET N_s5r3nf
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s5r3nf", 100, 180, 0)
	add	sp, 0Ch
	mov	byte ptr [si+shed_blood], 1
L02CE:
	retf

L02CF:
	mov	ax, OFFSET S_0AAC
	mov	bx, OFFSET T_FEA3N004
	call	Say
	retf

H_02D9:
	SCRIPT	MSG_USE, IT_SNAKE, OBJ_SPOCK, 0, H_02FB
SnakeOnSpock:
	cmp	byte ptr cs:snake_shown, 1
	jne	L02F1
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA3_004
	call	Say
	retf

L02F1:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA3_020
	call	Say
	retf

H_02FB:
	SCRIPT	MSG_USE, IT_SNAKE, OBJ_REDSHIRT, 0, H_033D
SnakeBitesStragey:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L0332
	cmp	byte ptr [si+may_pass], 0
	jne	L0332
	cmp	byte ptr cs:snake_shown, 1
	jne	L0333
	cmp	byte ptr [si+rocks_thrown], 0
	jne	L0333
	push	2
	push	0BCh
	push	7Ch
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 124, 188, 2)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
L0332:
	retf

L0333:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA3_031
	call	Say
	retf

H_033D:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_0389
StrageyBitten:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA3_034
	call	Say
	mov	ax, OFFSET N_Tlaoxac
	mov	bx, OFFSET T_FEA3_044
	call	Say
	mov	byte ptr [si+may_pass], 1
	add	word ptr [si+score], 1
	push	OFFSET N_feather3
	push	RC_LOADMAP
	SERVICE		; LoadMap("feather3")
	add	sp, 4
	push	0
	push	0B4h
	push	64h
	push	OFFSET N_s5r3nf
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s5r3nf", 100, 180, 0)
	add	sp, 0Ch
	mov	byte ptr [si+shed_blood], 1
	retf

H_0389:
	SCRIPT	MSG_USE, IT_SNAKE, OBJ_MCCOY, 0, H_0399
SnakeOnMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA3_007
	call	Say
	retf

H_0399:
	SCRIPT	MSG_USE, IT_SNAKE, 8, 0, H_03D3
ShowSnake:
	cmp	byte ptr [si+may_pass], 0
	jne	L03C8
	cmp	byte ptr [si+rocks_thrown], 0
	jne	L03C8
	mov	ax, OFFSET N_Tlaoxac
	mov	bx, OFFSET T_FEA3_039
	call	Say
	mov	byte ptr cs:snake_shown, 1
	cmp	byte ptr [si+showed_snake], 1
	je	L03C8
	mov	byte ptr [si+showed_snake], 1
	add	word ptr [si+score], 1
L03C8:
	retf

	DB	0B8h, 0A4h, 0Ah, 0BBh, 1Ch, 17h, 0E8h, 11h, 6, 0CBh

; The knife on the crew.
H_03D3:
	SCRIPT	MSG_USE, IT_KNIFE, OBJ_SPOCK, 0, H_03E3
KnifeOnSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA3_025
	call	Say
	retf

H_03E3:
	SCRIPT	MSG_USE, IT_KNIFE, OBJ_MCCOY, 0, H_03F3
KnifeOnMcCoy:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA3_011
	call	Say
	retf

H_03F3:
	SCRIPT	MSG_USE, IT_KNIFE, OBJ_REDSHIRT, 0, H_0409
KnifeOnStragey:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L0408
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA3_033
	call	Say
L0408:
	retf

; Rocks at Tlaoxac (msgs 3, timers 2-4): the second knocks him out (-2)
; and he drops his knife (anim msg 4).
H_0409:
	SCRIPT	MSG_USE, IT_ROCK, 8, 0, H_043D
RockAtTlaoxac:
	cmp	byte ptr cs:tlaoxac_down, 0
	jne	L0433
	inc	byte ptr [si+rocks_thrown]
	mov	byte ptr [si+RS_BUSY], 1
	push	3
	push	0B4h
	push	0ACh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 172, 180, 3)
	add	sp, 0Ah
	retf

L0433:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA3_009
	call	Say
	retf

H_043D:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_04EF
KirkThrows:
	mov	byte ptr [si+RS_FALL], 3
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r3kt
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r3kt", -1, -1, 0)
	add	sp, 0Ch
	push	0
	push	7Eh
	push	80h
	push	OFFSET N_s5r3rt
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "s5r3rt", 128, 126, 0)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+8], 15h
	cmp	byte ptr [si+rocks_thrown], 2
	jne	L04BA
	mov	byte ptr [si+knocked_out], 1
	add	word ptr [si+score], -2
	push	4
	push	-1
	push	-1
	push	OFFSET N_s5r3ad
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s5r3ad", -1, -1, 4)
	add	sp, 0Ch
	jmp	SHORT L04A5

N_ROCKFACE	LABEL	BYTE
	DB	'ROCKFACE',0
L04A5:
	push	OFFSET N_ROCKFACE
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("ROCKFACE")
	add	sp, 4
	mov	word ptr [si+RS_TIMERS+4], 18h
	retf

L04BA:
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r3ah
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s5r3ah", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L04DA

N_ROCKFACE_2	LABEL	BYTE
	DB	'ROCKFACE',0
L04DA:
	push	OFFSET N_ROCKFACE_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("ROCKFACE")
	add	sp, 4
	mov	word ptr [si+RS_TIMERS+6], 61h
	retf

H_04EF:
	SCRIPT	MSG_TIMER, 4, 0, 0, H_0502
Timer4Sound:
	push	0Bh
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(11)
	add	sp, 4
	retf

H_0502:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_0525
KnifeShows:
	cmp	byte ptr [si+took_knife], 0
	jne	L0524
	push	0
	push	0B4h
	push	64h
	push	OFFSET N_s5r3nf
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s5r3nf", 100, 180, 0)
	add	sp, 0Ch
L0524:
	retf

H_0525:
	SCRIPT	MSG_TIMER, 3, 0, 0, H_053C
ThrowDone:
	mov	byte ptr [si+RS_BUSY], 0
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	retf

H_053C:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_0588
TlaoxacFalls:
	mov	byte ptr [si+RS_BUSY], 0
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	ax, OFFSET S_0AAC
	mov	bx, OFFSET T_FEA3N006
	call	Say
	cmp	byte ptr [si+took_knife], 0
	jne	L0570
	cmp	byte ptr [si+shed_blood], 0
	jne	L0570
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA3_008
	call	Say
L0570:
	mov	byte ptr [si+may_pass], 1
	mov	byte ptr cs:tlaoxac_down, 1
	push	OFFSET N_feather3
	push	RC_LOADMAP
	SERVICE		; LoadMap("feather3")
	add	sp, 4
	retf

H_0588:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_0598
StunAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA3_023
	call	Say
	retf

H_0598:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_05A8
KillAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA3_023
	call	Say
	retf

H_05A8:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_05B8
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA3_005
	call	Say
	retf

H_05B8:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_05C8
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA3_022
	call	Say
	retf

H_05C8:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_05DE
TalkToRedshirt:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L05DD
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA3_032
	call	Say
L05DD:
	retf

; Talking to Tlaoxac: a threat makes him strike Stragey down (anim msg
; 2).
H_05DE:
	SCRIPT	MSG_TALK, 8, 0, 0, H_069C
TalkToTlaoxac:
	cmp	byte ptr [si+may_pass], 0
	jne	L0609
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 0
	jne	L0609
	cmp	byte ptr cs:tlaoxac_down, 0
	jne	L0609
	cmp	byte ptr cs:snake_shown, 0
	jne	L060A
	mov	ax, OFFSET N_Tlaoxac
	mov	bx, OFFSET T_FEA3_038
	call	Say
L0609:
	retf

L060A:
	cmp	byte ptr [si+rocks_thrown], 0
	je	L061A
	mov	ax, OFFSET N_Tlaoxac
	mov	bx, OFFSET T_FEA3_038
	call	Say
	retf

L061A:
	mov	ax, OFFSET KirkToTlaoxac
	call	Talk
	AX8	cmp, 0
	jne	L0627
	jmp	SHORT L0637

L0627:
	AX8	cmp, 1
	jne	L062E
	jmp	SHORT L0641

L062E:
	AX8	cmp, 2
	jne	L0635
	jmp	SHORT L064B

L0635:
	jmp	SHORT L0693

L0637:
	mov	ax, OFFSET N_Tlaoxac
	mov	bx, OFFSET T_FEA3_037
	call	Say
	retf

L0641:
	mov	ax, OFFSET N_Tlaoxac
	mov	bx, OFFSET T_FEA3_042
	call	Say
	retf

L064B:
	mov	ax, OFFSET N_Tlaoxac
	mov	bx, OFFSET T_FEA3_040
	call	Say
	mov	byte ptr [si+RS_BUSY], 1
	push	2
	push	-1
	push	-1
	push	OFFSET N_s5r3aj
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s5r3aj", -1, -1, 2)
	add	sp, 0Ch
	push	2
	push	RC_MUSIC
	SERVICE		; Music(2)
	add	sp, 4
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r3rd
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "s5r3rd", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_REDSHIRT_DEAD], 1
	retf

L0693:
	mov	ax, OFFSET S_0AAC
	mov	bx, OFFSET N_dialogue_error
	call	Say
				; NOTE: runs on into the next script's header, executing its six bytes as code

H_069C:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_06A7
TlaoxacStrikes:
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Tricorders and the medkit.
H_06A7:
	SCRIPT	MSG_USE, IT_MTRICOR, 8, 0, H_06EA
McCoyScansTlaoxac:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscanw
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscanw", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	cmp	byte ptr cs:tlaoxac_down, 1
	jne	L06E0
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA3_010
	call	Say
	retf

L06E0:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA3_014
	call	Say
	retf

H_06EA:
	SCRIPT	MSG_USE, IT_MEDKIT, 8, 0, H_077C
MedkitOnTlaoxac:
	cmp	byte ptr [si+knocked_out], 0
	je	L06FF
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA3_012
	call	Say
L06FF:
	retf

T_FEA3_012	LABEL	BYTE
	DB	'#FEA3\FEA3_012#Jim, he''ll be up in about an hour. If I wake him '
	DB	'now he''s liable to retalliate for your thoughtless actions.',0

H_077C:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_REDSHIRT, 0, H_07B3
MedkitOnStragey:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L07B2
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
	mov	bx, OFFSET T_FEA3_030
	call	Say
L07B2:
	retf

H_07B3:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, H_0816
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA3_006
	call	Say
	retf

T_FEA3_006	LABEL	BYTE
	DB	'#FEA3\FEA3_006#Everyone is healthy, Jim, there''s no need for the'
	DB	' medical kit here.',0

H_0816:
	SCRIPT	MSG_USE, IT_MTRICOR, 21h, 0, H_081E
	jmp	SHORT McCoyScansLamps

H_081E:
	SCRIPT	MSG_USE, IT_MTRICOR, 22h, 0, H_084F
McCoyScansLamps:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscanw
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscanw", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA3_013
	call	Say
	retf

H_084F:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_0857
	jmp	SHORT SpockScansLamps

H_0857:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_0888
SpockScansLamps:
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
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA3_019
	call	Say
	retf

H_0888:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_08B9
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
	mov	bx, OFFSET T_FEA3_021
	call	Say
	retf

; The knife (+1, msg 1, timer 1).
H_08B9:
	SCRIPT	MSG_GET, 9, 0, 0, H_08DB
GetKnife:
	add	word ptr [si+score], 1
	push	1
	push	0B4h
	push	57h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 87, 180, 1)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

H_08DB:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_08FC
KirkAtKnife:
	push	1
	push	-1
	push	-1
	push	OFFSET N_s5r1kg
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r1kg", -1, -1, 1)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+2], 14h
	retf

H_08FC:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_091F
TookKnife:
	mov	byte ptr [si+took_knife], 1
	push	IT_KNIFE
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_KNIFE)
	add	sp, 4
	push	9
	push	RC_STOPANIM
	SERVICE		; StopAnim(9)
	add	sp, 4
	retf

H_091F:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_093F
KnifeTaken:
	mov	byte ptr [si+RS_BUSY], 0
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	ax, OFFSET S_0AAC
	mov	bx, OFFSET T_FEA3N010
	call	Say
	retf

H_093F:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_095B
LookAtSpock:
	cmp	byte ptr [si+knocked_out], 0
	jne	L095A
	cmp	byte ptr [si+may_pass], 0
	jne	L095A
	mov	ax, OFFSET S_0AAC
	mov	bx, OFFSET T_FEA3N002
	call	Say
L095A:
	retf

H_095B:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_097B
LookAtRedshirt:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 0
	jne	L0971
	mov	ax, OFFSET S_0AAC
	mov	bx, OFFSET T_FEA3N012
	call	Say
	retf

L0971:
	mov	ax, OFFSET S_0AAC
	mov	bx, OFFSET T_FEA3N005
	call	Say
	retf

; Looking.
H_097B:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_099B
LookAtTlaoxac:
	cmp	byte ptr [si+knocked_out], 1
	jne	L0991
	mov	ax, OFFSET S_0AAC
	mov	bx, OFFSET T_FEA3N003
	call	Say
	retf

L0991:
	mov	ax, OFFSET S_0AAC
	mov	bx, OFFSET T_FEA3N007
	call	Say
	retf

H_099B:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_09AA
LookAtLamp1:
	sub	ax, ax
	mov	bx, OFFSET T_FEA3N001
	call	Say
	retf

H_09AA:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_09B9
LookAtLamp2:
	sub	ax, ax
	mov	bx, OFFSET T_FEA3N001
	call	Say
	retf

H_09B9:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_09C8
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_FEA3N000
	call	Say
	retf

H_09C8:
	SCRIPT	MSG_LOOK, 9, 0, 0, Talk
LookAtKnife:
	sub	ax, ax
	mov	bx, OFFSET T_FEA3N011
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
	DW	20h, 4	; id, points
	DW	0,172, 64,172, 64,199, 0,199
	DW	21h, 4	; id, points
	DW	202,102, 252,102, 252,146, 202,146
	DW	22h, 4	; id, points
	DW	132,46, 150,46, 150,62, 132,62
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	2, 4	; id, points
	DW	300,110, 319,110, 319,199, 300,199
	DW	3, 4	; id, points
	DW	0,150, 24,150, 24,199, 0,199
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	65,171, 105,171, 105,199, 65,199
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's5r3l1',0
	DB	's5r3l2',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Stragey	LABEL	BYTE
	DB	'Lt. Stragey',0
N_Tlaoxac	LABEL	BYTE
	DB	'Tlaoxac',0
S_0AAC	LABEL	BYTE
	DB	0
T_FEA3_036	LABEL	BYTE
	DB	'#FEA3\FEA3_036#I am Tlaoxac, priest of Quetzecoatl. Only one who'
	DB	' knows his ways may approach his holy ground.',0
T_FEA3_008	LABEL	BYTE
	DB	'#FEA3\FEA3_008#He dropped a knife, Jim!',0
T_FEA3N012	LABEL	BYTE
	DB	'#FEA3\FEA3N012#Your security officer looks at you for orders and'
	DB	', perhaps, inspiration.',0
T_FEA3N005	LABEL	BYTE
	DB	'#FEA3\FEA3N005#This was once a living member of your crew.',0
T_FEA3N001	LABEL	BYTE
	DB	'#FEA3\FEA3N001#Primitive lights illuminate this savage scene.',0
T_FEA3N000	LABEL	BYTE
	DB	'#FEA3\FEA3N000#McCoy seems rather nervous.',0
T_FEA3N002	LABEL	BYTE
	DB	'#FEA3\FEA3N002#Spock looks small compared to the great warrior.',0
T_FEA3N007	LABEL	BYTE
	DB	'#FEA3\FEA3N007#Towering over your security officer, holding a gr'
	DB	'eat spear in his huge hands, the great warrior Tlaoxac will let '
	DB	'no one pass him.',0
T_FEA3N003	LABEL	BYTE
	DB	'#FEA3\FEA3N003#The aztec warrior lies on the ground unconcious.',0
T_FEA3N011	LABEL	BYTE
	DB	'#FEA3\FEA3N011#You see a jewel encrusted, gold colored knife.',0
T_FEA3_026	LABEL	BYTE
	DB	'#FEA3\FEA3_026#Captain, I do not think that I can defeat him in '
	DB	'personal combat.',0
T_FEA3_018	LABEL	BYTE
	DB	'#FEA3\FEA3_018#What about your famous nerve pinch?',0
T_FEA3_028	LABEL	BYTE
	DB	'#FEA3\FEA3_028#It is unlikely to work on a man of that size, doc'
	DB	'tor.',0
T_FEA3_015	LABEL	BYTE
	DB	'#FEA3\FEA3_015#Damn. He noticed.',0
T_FEA3_016	LABEL	BYTE
	DB	'#FEA3\FEA3_016#Isn''t that what they said to David before he foug'
	DB	'ht Goliath?',0
T_FEA3_027	LABEL	BYTE
	DB	'#FEA3\FEA3_027#Doctor, may I remind you that David defeated Goli'
	DB	'ath?',0
T_FEA3_017	LABEL	BYTE
	DB	'#FEA3\FEA3_017#Well, then send in David!',0
T_FEA3_029	LABEL	BYTE
	DB	'#FEA3\FEA3_029#All right! Time for some action. Let me show you '
	DB	'how we did it at the Acad... uh, Captain, do you realize how BIG'
	DB	' this guy is?',0
T_FEA3_035	LABEL	BYTE
	DB	'#FEA3\FEA3_035#Get back! You may not pass until you prove your w'
	DB	'orthiness.',0
T_FEA3_041	LABEL	BYTE
	DB	'#FEA3\FEA3_041#None shall pass until blood is shed',0
T_FEA3N004	LABEL	BYTE
	DB	'#FEA3\FEA3N004#The snake enjoys snacking on you.',0
T_FEA3_043	LABEL	BYTE
	DB	'#FEA3\FEA3_043#Self-sacrifice is the noblest quality of humanity'
	DB	'. You may go. Beware the monster in the water. You may have my k'
	DB	'nife to defend yourself.',0
T_FEA3_020	LABEL	BYTE
	DB	'#FEA3\FEA3_020#Interesting. From the angle of its fangs and the '
	DB	'shape of its mouth, it might have had  the ability to inject its'
	DB	' prey with venom at one time.',0
T_FEA3_004	LABEL	BYTE
	DB	'#FEA3\FEA3_004#An intriguing solution Captain, but it is unlikel'
	DB	'y that he will accept green blood as a proper sacrifice.',0
T_FEA3_007	LABEL	BYTE
	DB	'#FEA3\FEA3_007#Get that thing away from me!',0
T_FEA3_031	LABEL	BYTE
	DB	'#FEA3\FEA3_031#I''m really not that anxious to get a good look at'
	DB	' it, sir.',0
T_FEA3_034	LABEL	BYTE
	DB	'#FEA3\FEA3_034#Well, there is a doctor here, so I guess it''s all'
	DB	' right. They never told me I''d be doing this at the Academy.',0
T_FEA3_044	LABEL	BYTE
	DB	'#FEA3\FEA3_044#You are truly a noble man, unlike the coward who '
	DB	'was not capable of shedding his own blood. You may pass, but bew'
	DB	'are the man in the golden robe. He may lead you to your death. U'
	DB	'se this knife to defend yourself.',0
T_FEA3_039	LABEL	BYTE
	DB	'#FEA3\FEA3_039#Indeed you know the ways of Quetzecoatl But only '
	DB	'a man of courage, one who will shed blood will pass.',0
T_FEA3N006	LABEL	BYTE
	DB	'#FEA3\FEA3N006#Tloaxac falls to the ground unconscious.',0
T_FEA3_009	LABEL	BYTE
	DB	'#FEA3\FEA3_009#He''s out cold, Jim.I don''t think we''ll have any m'
	DB	'ore trouble from him.',0
T_FEA3_025	LABEL	BYTE
	DB	'#FEA3\FEA3_025#That is not a logical act, Captain.',0
T_FEA3_011	LABEL	BYTE
	DB	'#FEA3\FEA3_011#Hey! What do you think you''re doing?',0
T_FEA3_033	LABEL	BYTE
	DB	'#FEA3\FEA3_033#Ouch, sir.',0
T_FEA3_019	LABEL	BYTE
	DB	'#FEA3\FEA3_019#Fascinating. These lights are actually swarms of '
	DB	'bio-luminescent insects. I wonder how they are controlled.',0
T_FEA3_013	LABEL	BYTE
	DB	'#FEA3\FEA3_013#These lamps are made up of insects much like fire'
	DB	'flies, Jim.',0
T_FEA3_022	LABEL	BYTE
	DB	'#FEA3\FEA3_022#Perhaps our host will be more reasonable now. I r'
	DB	'ecommend trying to locate him, Captain.',0
T_FEA3_005	LABEL	BYTE
	DB	'#FEA3\FEA3_005#Did you ever get the feeling that people don''t li'
	DB	'ke you?',0
T_FEA3_032	LABEL	BYTE
	DB	'#FEA3\FEA3_032#Nice planet. I kinda like it.',0
T_FEA3_038	LABEL	BYTE
	DB	'#FEA3\FEA3_038#I will not listen to your deceitful ways.',0
T_FEA3_001	LABEL	BYTE
	DB	'#FEA3\FEA3_001#Well, does anyone have any suggestions?',0
T_FEA3_002	LABEL	BYTE
	DB	'#FEA3\FEA3_002#Great Tlaoxac, I do not understand. Quetzecoatl s'
	DB	'ays that his is the way of peace, yet you wish blood to be shed?',0
T_FEA3_003	LABEL	BYTE
	DB	'#FEA3\FEA3_003#It is urgent that we speak to Quetzecoatl. His li'
	DB	'fe may depend on it. Please stand aside and let us pass?',0
T_FEA3_037	LABEL	BYTE
	DB	'#FEA3\FEA3_037#I do not understand your words, but it does not m'
	DB	'atter. You may not pass until blood is shed.',0
T_FEA3_042	LABEL	BYTE
	DB	'#FEA3\FEA3_042#Nonetheless, that is what must be done. Only men '
	DB	'of courage are allowed into his presence.',0
T_FEA3_040	LABEL	BYTE
	DB	'#FEA3\FEA3_040#None can threaten the great Quetzecoatl! You lie!'
	DB	' Truly you do not serve the serpent-god. You may not pass!',0
T_FEA3_014	LABEL	BYTE
	DB	'#FEA3\FEA3_014#Well, either this Aztec is a real flesh and blood'
	DB	' human being, or I''m going to be retired as soon as I get back t'
	DB	'o the Enterprise.',0
T_FEA3_010	LABEL	BYTE
	DB	'#FEA3\FEA3_010#He''s unconscious, Jim.',0
T_FEA3_030	LABEL	BYTE
	DB	'#FEA3\FEA3_030#sHe''s dead, Jim!',0
T_FEA3_021	LABEL	BYTE
	DB	'#FEA3\FEA3_021#Nothing unusual here, Captain.',0
T_FEA3N010	LABEL	BYTE
	DB	'#FEA3\FEA3N010#You pick up the beautifully crafted knife.',0
T_FEA3_023	LABEL	BYTE
	DB	'#FEA3\FEA3_023#Still inoperative, Captain.',0
T_FEA3_024	LABEL	BYTE
	DB	'#FEA3\FEA3_024#Still inoperative, Captain.',0
N_dialogue_error	LABEL	BYTE
	DB	'dialogue error',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0
KirkToTlaoxac	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_FEA3_001, OFFSET T_FEA3_002, OFFSET T_FEA3_003, 0	; speaker, choices, 0

RDF	ENDS
	END
