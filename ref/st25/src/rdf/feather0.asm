; FEATHER0.RDF - "The Feathered Serpent", a jungle clearing on Digifal.
; Quetzecoatl, who raised the Aztecs and has now come to the Klingon world
; of Digifal, greets the landing party. He refuses to believe what became
; of his people on Earth, and whatever Kirk says, he sends the party into
; the jungle (room 1).
;
; Actors: 8 Quetzecoatl.
; Objects: 8 Quetzecoatl, 20h the moon, 21h the log, 22h the hut, 23h-2Bh
; eyes in the dark, 2Ch insects.
; Timers: 0 the party is sent away, 1 room 1.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 0574: the engine reads its bytes
;   as key 50 6A 03 2E and next 1EFF (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0BFh	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	41h
rdf_scale_min	LABEL	BYTE
	DW	78h	; and scale range
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
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	172,146, 158,139, 188,139, 172,130	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0
N_s5r0qb	LABEL	BYTE
	DB	's5r0qb',0
N_s5r0qt	LABEL	BYTE
	DB	's5r0qt',0
N_ktele	LABEL	BYTE
	DB	'ktele',0
N_stele	LABEL	BYTE
	DB	'stele',0
N_mtele	LABEL	BYTE
	DB	'mtele',0
N_rtele	LABEL	BYTE
	DB	'rtele',0
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_mscans	LABEL	BYTE
	DB	'mscans',0

rdf_scripts:
; The room starts: Quetzecoatl; tick 60, music.
H_00FE:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0136
StartRoom:
	jmp	SHORT L010F

N_FEA0LOOP	LABEL	BYTE
	DB	'FEA0LOOP',0
L010F:
	push	OFFSET N_FEA0LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("FEA0LOOP")
	add	sp, 4
	push	0
	push	0A6h
	push	0BEh
	push	OFFSET N_s5r0qb
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s5r0qb", 190, 166, 0)
	add	sp, 0Ch
	retf

H_0136:
	SCRIPT	MSG_TICK, 3Ch, 0, 0, H_0149
MusicStarts:
	push	21h
	push	RC_MUSIC
	SERVICE		; Music(33)
	add	sp, 4
	retf

; Talking to Quetzecoatl: a conversation tree; whatever Kirk says, it
; ends with Quetzecoatl sending the party away (timer 0).
H_0149:
	SCRIPT	MSG_TALK, 8, 0, 0, H_0256
TalkToQuetzecoatl:
	mov	ax, OFFSET QGreets
	call	Talk
	mov	ax, OFFSET KirkIntroduces
	call	Talk
	AX8	cmp, 0
	jne	L0162
	jmp	SHORT L0173

L0162:
	AX8	cmp, 1
	jne	L0169
	jmp	SHORT L017B

L0169:
	AX8	cmp, 2
	jne	L0170
	jmp	SHORT L0183

L0170:
	JMPN	L02E4

L0173:
	mov	ax, OFFSET QOnKlingons
	call	Talk
	jmp	SHORT L018B

L017B:
	mov	ax, OFFSET QOnAnger
	call	Talk
	jmp	SHORT L01F1

L0183:
	mov	ax, OFFSET QWhoAreYou
	call	Talk
	jmp	SHORT L0208

L018B:
	mov	ax, OFFSET KirkAccuses
	call	Talk
	AX8	cmp, 0
	jne	L0198
	jmp	SHORT L01A2

L0198:
	AX8	cmp, 1
	jne	L019F
	jmp	SHORT L01B2

L019F:
	JMPN	L02E4

L01A2:
	mov	ax, OFFSET QOnPeace
	call	Talk
	jmp	SHORT L01AA

L01AA:
	mov	ax, OFFSET KirkOnName
	call	Talk
	jmp	SHORT L01BA

L01B2:
	mov	ax, OFFSET QDisbelieves
	call	Talk
	jmp	SHORT L01AA

L01BA:
	mov	ax, OFFSET QOnBloodshed
	call	Talk
	jmp	SHORT L01C2

L01C2:
	mov	ax, OFFSET KirkOnSacrifice
	call	Talk
	AX8	cmp, 0
	jne	L01CF
	jmp	SHORT L01D9

L01CF:
	AX8	cmp, 1
	jne	L01D6
	jmp	SHORT L01E1

L01D6:
	JMPN	L02E4

L01D9:
	mov	ax, OFFSET QImpossible
	call	Talk
	jmp	SHORT L01E9

L01E1:
	mov	ax, OFFSET QBegone
	call	Talk
	jmp	SHORT L0227

L01E9:
	mov	ax, OFFSET KirkOnConquest
	call	Talk
	jmp	SHORT L01E1

L01F1:
	mov	ax, OFFSET KirkOnPlans
	call	Talk
	AX8	cmp, 0
	jne	L01FE
	jmp	SHORT L01A2

L01FE:
	AX8	cmp, 1
	jne	L0205
	jmp	SHORT L01B2

L0205:
	JMPN	L02E4

L0208:
	mov	ax, OFFSET KirkOnPeople
	call	Talk
	AX8	cmp, 0
	jne	L0215
	jmp	SHORT L021F

L0215:
	AX8	cmp, 1
	jne	L021C
	jmp	SHORT L01B2

L021C:
	JMPN	L02E4

L021F:
	mov	ax, OFFSET QIntroduces
	call	Talk
	jmp	SHORT L0227

L0227:
	mov	byte ptr [si+RS_BUSY], 1
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r0qt
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s5r0qt", -1, -1, 0)
	add	sp, 0Ch
	push	1
	push	RC_MUSIC
	SERVICE		; Music(1)
	add	sp, 4
	mov	word ptr [si+RS_TIMERS], 32h
	mov	word ptr [si+RS_TIMERS+2], 40h
	retf

; Timer 0: the crew vanish, and timer 1 puts them in room 1.
H_0256:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_02CB
Teleported:
	jmp	SHORT L0267

N_SE2BIGEN	LABEL	BYTE
	DB	'SE2BIGEN',0
L0267:
	push	OFFSET N_SE2BIGEN
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SE2BIGEN")
	add	sp, 4
	push	0
	push	-1
	push	-1
	push	OFFSET N_ktele
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "ktele", -1, -1, 0)
	add	sp, 0Ch
	push	0
	push	-1
	push	-1
	push	OFFSET N_stele
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "stele", -1, -1, 0)
	add	sp, 0Ch
	push	0
	push	-1
	push	-1
	push	OFFSET N_mtele
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mtele", -1, -1, 0)
	add	sp, 0Ch
	push	0
	push	-1
	push	-1
	push	OFFSET N_rtele
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rtele", -1, -1, 0)
	add	sp, 0Ch
	retf

H_02CB:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_02EE
ToTheJungle:
	mov	byte ptr [si+RS_BUSY], 0
	push	5
	push	1
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(1)
	add	sp, 4
	retf

L02E4:
	mov	ax, 0
	mov	bx, OFFSET N_dialog_error
	call	Say
	retf

; Phasers.
H_02EE:
	SCRIPT	MSG_USE, IT_PHASERS, 8, 0, H_02FE
StunQuetzecoatl:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA0_025
	call	Say
	retf

H_02FE:
	SCRIPT	MSG_USE, IT_PHASERK, 8, 0, H_030E
KillQuetzecoatl:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA0_025
	call	Say
	retf

H_030E:
	SCRIPT	MSG_USE, IT_PHASERS, OBJ_MCCOY, 0, H_031E
StunMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA0_016
	call	Say
	retf

H_031E:
	SCRIPT	MSG_USE, IT_PHASERK, OBJ_MCCOY, 0, H_032E
KillMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA0_016
	call	Say
	retf

H_032E:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, H_0391
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA0_108
	call	Say
	retf

T_FEA0_108	LABEL	BYTE
	DB	'#FEA0\FEA0_108#Everyone is healthy, Jim, there''s no need for the'
	DB	' medical kit here.',0

; Looking and talking.
H_0391:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_03A0
LookAtQuetzecoatl:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N008
	call	Say
	retf

H_03A0:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_03AF
LookAtMoon:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N007
	call	Say
	retf

H_03AF:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_03BE
LookAtLog:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N006
	call	Say
	retf

H_03BE:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_03CD
LookAtHut:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N001
	call	Say
	retf

H_03CD:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_03DC
LookAtScene:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N009
	call	Say
	retf

H_03DC:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_03EB
LookAtEyes1:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N000
	call	Say
	retf

H_03EB:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_03FA
LookAtEyes2:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N000
	call	Say
	retf

H_03FA:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_0409
LookAtEyes3:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N000
	call	Say
	retf

H_0409:
	SCRIPT	MSG_LOOK, 26h, 0, 0, H_0418
LookAtEyes4:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N000
	call	Say
	retf

H_0418:
	SCRIPT	MSG_LOOK, 27h, 0, 0, H_0427
LookAtEyes5:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N000
	call	Say
	retf

H_0427:
	SCRIPT	MSG_LOOK, 28h, 0, 0, H_0436
LookAtEyes6:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N000
	call	Say
	retf

H_0436:
	SCRIPT	MSG_LOOK, 29h, 0, 0, H_0445
LookAtEyes7:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N000
	call	Say
	retf

H_0445:
	SCRIPT	MSG_LOOK, 2Ah, 0, 0, H_0454
LookAtEyes8:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N000
	call	Say
	retf

H_0454:
	SCRIPT	MSG_LOOK, 2Bh, 0, 0, H_0463
LookAtEyes9:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N000
	call	Say
	retf

H_0463:
	SCRIPT	MSG_LOOK, 2Ch, 0, 0, H_0472
LookAtInsects:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N003
	call	Say
	retf

H_0472:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_0481
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N004
	call	Say
	retf

H_0481:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_0490
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N005
	call	Say
	retf

H_0490:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_049F
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_FEA0N002
	call	Say
	retf

H_049F:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_04B8
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA0_017
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA0_021
	call	Say
	retf

H_04B8:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_04D1
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA0_022
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA0_018
	call	Say
	retf

H_04D1:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_04E1
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA0_023
	call	Say
	retf

; Tricorders.
H_04E1:
	SCRIPT	MSG_USE, IT_STRICOR, 8, 0, H_0512
SpockScansQuetzecoatl:
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
	mov	bx, OFFSET T_FEA0_020
	call	Say
	retf

H_0512:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_0543
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
	mov	bx, OFFSET T_FEA0_019
	call	Say
	retf

H_0543:
	SCRIPT	MSG_USE, IT_MTRICOR, 8, 0, Talk
McCoyScansQuetzecoatl:
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
	mov	bx, OFFSET T_FEA0_015
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
	DW	81,0, 150,0, 150,27, 81,27
	DW	21h, 4	; id, points
	DW	98,69, 123,64, 199,87, 175,102
	DW	22h, 4	; id, points
	DW	142,41, 202,44, 203,76, 146,65
	DW	23h, 4	; id, points
	DW	127,105, 140,105, 140,116, 127,116
	DW	24h, 4	; id, points
	DW	274,161, 286,161, 286,171, 274,171
	DW	25h, 4	; id, points
	DW	62,192, 72,192, 72,199, 62,199
	DW	26h, 4	; id, points
	DW	70,54, 80,54, 80,61, 70,61
	DW	27h, 4	; id, points
	DW	20,117, 30,117, 30,126, 20,126
	DW	28h, 4	; id, points
	DW	170,84, 185,84, 185,94, 170,94
	DW	29h, 4	; id, points
	DW	215,47, 227,47, 227,58, 215,58
	DW	2Ah, 4	; id, points
	DW	219,128, 245,128, 245,142, 219,142
	DW	2Bh, 4	; id, points
	DW	310,129, 319,130, 319,140, 310,140
	DW	2Ch, 4	; id, points
	DW	246,0, 309,0, 309,154, 246,154
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's5r0h1',0
	DB	's5r0h2',0
	DB	's5r0wt',0
	DB	's5r0e0',0
	DB	's5r0e1',0
	DB	's5r0e2',0
	DB	's5r0e3',0
	DB	's5r0e5',0
	DB	's5r0e6',0
	DB	's5r0f1',0
	DB	's5r0f2',0
	DB	's5r0f3',0
	DB	's5r0rl',0
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
T_FEA0N000	LABEL	BYTE
	DB	'#FEA0\FEA0N000#Feral red eyes glare out of the dark at you.',0
T_FEA0N003	LABEL	BYTE
	DB	'#FEA0\FEA0N003#Luminescent insects swarm near a large tree.',0
T_FEA0N001	LABEL	BYTE
	DB	'#FEA0\FEA0N001#It looks like the jungle has grown up into a smal'
	DB	'l hut.',0
T_FEA0N006	LABEL	BYTE
	DB	'#FEA0\FEA0N006#The log appears sturdy enough to cross.',0
T_FEA0N008	LABEL	BYTE
	DB	'#FEA0\FEA0N008#There is a tall, slender, dark haired man looking'
	DB	' intently at you.',0
T_FEA0N007	LABEL	BYTE
	DB	'#FEA0\FEA0N007#The moon of Digifal. Legend says that the gods of'
	DB	' good and evil fortune live there and will glance back at those '
	DB	'who look at them, and either a miracle or a catastrophe will soo'
	DB	'n befall those who gaze upon it.',0
T_FEA0N004	LABEL	BYTE
	DB	'#FEA0\FEA0N004#McCoy is fidgeting around.',0
T_FEA0N005	LABEL	BYTE
	DB	'#FEA0\FEA0N005#Spock is analyzing the surroundings.',0
T_FEA0N002	LABEL	BYTE
	DB	'#FEA0\FEA0N002#Lt. Stragey is carefully eyeing the humanoid.',0
T_FEA0N009	LABEL	BYTE
	DB	'#FEA0\FEA0N009#You see dense vegetation in all directions.',0
T_FEA0_017	LABEL	BYTE
	DB	'#FEA0\FEA0_017#Jim, that man is dressed in ancient Aztec clothin'
	DB	'g.',0
T_FEA0_021	LABEL	BYTE
	DB	'#FEA0\FEA0_021#I believe you are mistaken, doctor. His clothing '
	DB	'bears a distinct resemblance to fashions of a much later period.',0
T_FEA0_022	LABEL	BYTE
	DB	'#FEA0\FEA0_022#The humanoid''s adornments appear similar to those'
	DB	' worn by leaders of Earth''s early 20th century inhabitants of th'
	DB	'e South American continent.',0
T_FEA0_018	LABEL	BYTE
	DB	'#FEA0\FEA0_018#What do you know about Earth culture? He looks li'
	DB	'ke an ancient Aztec!',0
T_FEA0_023	LABEL	BYTE
	DB	'#FEA0\FEA0_023#I''m just a security officer, sir.',0
T_FEA0_020	LABEL	BYTE
	DB	'#FEA0\FEA0_020#I am picking up strange energy readings from the '
	DB	'alien.  Perhaps Doctor McCoy could provide better data.',0
T_FEA0_015	LABEL	BYTE
	DB	'#FEA0\FEA0_015#He appears human... All life signs are normal, bu'
	DB	't I''m getting strange energy readings near the base of his pitui'
	DB	'tary gland.',0
T_FEA0_025	LABEL	BYTE
	DB	'#FEA0\FEA0_025#You dare fire at a god?',0
T_FEA0_016	LABEL	BYTE
	DB	'#FEA0\FEA0_016#Ouch!',0
	DB	'At this point, the crew should beam back up to the Enterprise.',0
T_FEA0_028	LABEL	BYTE
	DB	'#FEA0\FEA0_028#Greetings, my children. I can barely imagine that'
	DB	' you have come so far.',0
T_FEA0_006	LABEL	BYTE
	DB	'#FEA0\FEA0_006#I am Captain James T. Kirk of the Starship Enterp'
	DB	'rise. Did you know the Klingons are looking for you?',0
T_FEA0_007	LABEL	BYTE
	DB	'#FEA0\FEA0_007#I am Captain James T. Kirk of the Starship Enterp'
	DB	'rise. What did you do to get the Klingons so upset?',0
T_FEA0_011	LABEL	BYTE
	DB	'#FEA0\FEA0_011#We''re not your children and we don''t appreciate t'
	DB	'his wild goose chase you''ve forced us into.',0
T_FEA0_032	LABEL	BYTE
	DB	'#FEA0\FEA0_032#The Klingons? Amazing! This is the first time one'
	DB	' of my missions has produced results so swiftly.',0
T_FEA0_031	LABEL	BYTE
	DB	'#FEA0\FEA0_031#Quaint expression. I have done nothing to anger t'
	DB	'hem. I did with them what I have done with everyone.',0
T_FEA0_033	LABEL	BYTE
	DB	'#FEA0\FEA0_033#Who are you? I know you come from Terrasol, but y'
	DB	'ou are not of my people. What goes on here?',0
T_FEA0_009	LABEL	BYTE
	DB	'#FEA0\FEA0_009#Listen, Mister, any missions conducted within Kli'
	DB	'ngon space fully jeopardize the peace.',0
T_FEA0_004	LABEL	BYTE
	DB	'#FEA0\FEA0_004#Damned right the results were swift. The Klingons'
	DB	' have been raiding colonies looking for you.',0
T_FEA0_030	LABEL	BYTE
	DB	'#FEA0\FEA0_030#Jeopardize the peace? Hardly. Peace is what I pre'
	DB	'ach. I am Quetzecoatl, as you well know from the proud history o'
	DB	'f your world.',0
T_FEA0_010	LABEL	BYTE
	DB	'#FEA0\FEA0_010#Quetzecoatl? How fitting you would name yourself '
	DB	'after one of the most bloody-handed gods in Earth''s history.',0
T_FEA0_101	LABEL	BYTE
	DB	'#FEA0\FEA0_101#No, you must be lying. They could not be raiding '
	DB	'if they are looking for me. Violence was not the message of any '
	DB	'of my missions. I, Quetzecoatl, preach universal brotherhood and'
	DB	' peace.',0
T_FEA0_026	LABEL	BYTE
	DB	'#FEA0\FEA0_026#Bloody-handed? My people love peace!',0
T_FEA0_013	LABEL	BYTE
	DB	'#FEA0\FEA0_013#Your followers regularly sacrificed other believe'
	DB	'rs to you after you left, offering you their still-beating heart'
	DB	's.',0
T_FEA0_005	LABEL	BYTE
	DB	'#FEA0\FEA0_005#Ha! You mean your followers love pieces! They sla'
	DB	'ughtered other believers hoping you''d return.',0
T_FEA0_029	LABEL	BYTE
	DB	'#FEA0\FEA0_029#Impossible! You must be lying!',0
T_FEA0_027	LABEL	BYTE
	DB	'#FEA0\FEA0_027#Foul lying creatures, my gift was wasted upon you'
	DB	'! Begone.',0
T_FEA0_003	LABEL	BYTE
	DB	'#FEA0\FEA0_003#And then your followers were destroyed because wh'
	DB	'en white men arrived on that continent, they were believed to be'
	DB	' you in your promised return. Your people perverted your teachin'
	DB	'gs, then were destroyed by it.',0
T_FEA0_002	LABEL	BYTE
	DB	'#FEA0\FEA0_002#And exactly what would you have done with them? E'
	DB	'ntering Klingon space for anything puts the peace in peril.',0
T_FEA0_012	LABEL	BYTE
	DB	'#FEA0\FEA0_012#Whatever you did has them very upset. They''re rai'
	DB	'ding worlds looking for you.',0
T_FEA0_014	LABEL	BYTE
	DB	'#FEA0\FEA0_014#Your people? We represent all of the Earth''s peop'
	DB	'le and we certainly do not recognize you.',0
T_FEA0_008	LABEL	BYTE
	DB	'#FEA0\FEA0_008#Listen, the Klingons are ripping colonies apart t'
	DB	'o find you, so stop this nonsense. This is serious.',0
T_FEA0_024	LABEL	BYTE
	DB	'#FEA0\FEA0_024#I am Quetzecoatl. I elevated a civilization on yo'
	DB	'ur world from barbarism to sentience. You are a perversion of th'
	DB	'at process. Be gone!',0
T_FEA0_019	LABEL	BYTE
	DB	'#FEA0\FEA0_019#I am picking up multiple life forms in the surrou'
	DB	'nding region, Captain.',0
N_dialog_error	LABEL	BYTE
	DB	'dialog error',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0
QGreets	LABEL	BYTE
	DW	OFFSET N_Quetzecoatl, OFFSET T_FEA0_028, 0	; speaker, choices, 0
KirkIntroduces	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_FEA0_006, OFFSET T_FEA0_007, OFFSET T_FEA0_011, 0	; speaker, choices, 0
QOnKlingons	LABEL	BYTE
	DW	OFFSET N_Quetzecoatl, OFFSET T_FEA0_032, 0	; speaker, choices, 0
QOnAnger	LABEL	BYTE
	DW	OFFSET N_Quetzecoatl, OFFSET T_FEA0_031, 0	; speaker, choices, 0
QWhoAreYou	LABEL	BYTE
	DW	OFFSET N_Quetzecoatl, OFFSET T_FEA0_033, 0	; speaker, choices, 0
KirkAccuses	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_FEA0_009, OFFSET T_FEA0_004, 0	; speaker, choices, 0
QOnPeace	LABEL	BYTE
	DW	OFFSET N_Quetzecoatl, OFFSET T_FEA0_030, 0	; speaker, choices, 0
KirkOnName	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_FEA0_010, 0	; speaker, choices, 0
QDisbelieves	LABEL	BYTE
	DW	OFFSET N_Quetzecoatl, OFFSET T_FEA0_101, 0	; speaker, choices, 0
QOnBloodshed	LABEL	BYTE
	DW	OFFSET N_Quetzecoatl, OFFSET T_FEA0_026, 0	; speaker, choices, 0
KirkOnSacrifice	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_FEA0_013, OFFSET T_FEA0_005, 0	; speaker, choices, 0
QImpossible	LABEL	BYTE
	DW	OFFSET N_Quetzecoatl, OFFSET T_FEA0_029, 0	; speaker, choices, 0
QBegone	LABEL	BYTE
	DW	OFFSET N_Quetzecoatl, OFFSET T_FEA0_027, 0	; speaker, choices, 0
KirkOnConquest	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_FEA0_003, 0	; speaker, choices, 0
KirkOnPlans	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_FEA0_002, OFFSET T_FEA0_012, 0	; speaker, choices, 0
KirkOnPeople	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_FEA0_014, OFFSET T_FEA0_008, 0	; speaker, choices, 0
QIntroduces	LABEL	BYTE
	DW	OFFSET N_Quetzecoatl, OFFSET T_FEA0_024, 0	; speaker, choices, 0

RDF	ENDS
	END
