; LOVE0.RDF - "Love's Labor Jeopardized", the bridge of the research
; station ARK7, abandoned, with a Romulan bird of prey on the viewscreen.
; The station's computer holds Dr. Marcus' log, and her research on the
; Oroborus virus, which is infecting Spock (timer 2). Common to all of the
; mission's rooms: the virus, the cure, the gas canisters and the
; communicator.
;
; Actors: 8 the left door, 9 the right door.
; Objects: 8 the left door, 9 the right door (secured), 20h the computer,
; 21h/22h by the doors, 23h the viewscreen.
; Exits: 0 room 2, 2 room 1. Regions 0, 1: the doorsteps.
; Timers: 0 crew laugh, 1 Spock laughs, 2 the virus.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The communicator's four cases (CallEnterprise) all play the same
;   placeholder lines, recorded for other missions.
; - Getting door 8 runs the next script's header as code (GetDoor), and
;   the doors' own answer is left unreachable after the jmp.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
visited	EQU	RS_VARS+0	; the mission has set up its state (room 0)
have_research	EQU	RS_VARS+1	; McCoy has Dr. Marcus' research on the virus (room 0)
n2o_released	EQU	RS_VARS+3	; laughing gas: the crew laugh (timer 0)
rlg_released	EQU	RS_VARS+4	; Romulan laughing gas: Spock laughs (timer 1)
tank1	EQU	RS_VARS+0Dh	; the synthesizer's first gas tank (room 2): 1 O2
tank2	EQU	RS_VARS+0Eh	; its second: 2 H2
virus_struck	EQU	RS_VARS+18h	; the virus has floored Spock, and the Romulans below
virus	EQU	RS_VARS+1Ch	; Spock's infection: 3Ch he collapses, 64h he dies
spock_cured	EQU	RS_VARS+1Dh
called_ship	EQU	RS_VARS+1Eh	; Kirk has called the Enterprise
called_ship_cured	EQU	RS_VARS+1Fh	; the same, after the cure
spock_read_log	EQU	RS_VARS+20h	; Spock's point for the computer
mccoy_read_log	EQU	RS_VARS+21h	; McCoy's points for the computer
made_cure	EQU	RS_VARS+26h	; the cure has been synthesized (room 2)
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
	DW	81h
rdf_scale_min	LABEL	BYTE
	DW	0A0h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	0ECh
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	2, -1, 1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	230,129, 236,153	; entrance 0, crew 0
	DW	230,129, 162,129	; entrance 0, crew 1
	DW	230,129, 202,133	; entrance 0, crew 2
	DW	230,129, 255,135	; entrance 0, crew 3
	DW	0,0, 0,0	; entrance 1, crew 0
	DW	0,0, 0,0	; entrance 1, crew 1
	DW	0,0, 0,0	; entrance 1, crew 2
	DW	0,0, 0,0	; entrance 1, crew 3
	DW	291,140, 236,163	; entrance 2, crew 0
	DW	291,140, 208,134	; entrance 2, crew 1
	DW	291,140, 298,176	; entrance 2, crew 2
	DW	291,140, 258,135	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	148,185, 138,175, 158,175, 144,165	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	49,133, 45,166, 49,133, 26,155
	DB	31h, 0, 85h, 0, 44h, 0, 8Dh, 0, 31h, 0, 85h, 0
	DB	7Ch, 0, 82h, 0
; In the room file, so these start again each time the room loads
heard_log	LABEL	BYTE	; the computer has played Dr. Marcus' log
	DB	0, 0
right_door_steps	LABEL	BYTE	; the walk and the door have both finished at 2
	DB	0
left_door_steps	LABEL	BYTE
	DB	0
going_door	LABEL	BYTE	; 1 the left door, 2 the right
	DB	0
laugher	LABEL	BYTE	; word: the name of who giggles
	DB	0, 0
roll	LABEL	BYTE	; word: a random number
	DB	0, 0
user	LABEL	BYTE	; word: the crew member at the computer
	DB	0, 0
user_anim	LABEL	BYTE	; word
	DB	0, 0
user_name	LABEL	BYTE	; word
	DB	0, 0
user_line	LABEL	BYTE	; word: what they say
	DB	0, 0
	DB	'r1shot',0
	DB	's3r0s2',0
N_s3r0d1	LABEL	BYTE
	DB	's3r0d1',0
N_s3r0d1a	LABEL	BYTE
	DB	's3r0d1a',0
N_s3r0d2	LABEL	BYTE
	DB	's3r0d2',0
N_s3r0d2a	LABEL	BYTE
	DB	's3r0d2a',0
	DB	'kkille',0
	DB	'skille',0
	DB	'mkille',0
	DB	'rkille',0
	DB	'kusemn',0
N_susemn	LABEL	BYTE
	DB	'susemn',0
N_musemw	LABEL	BYTE
	DB	'musemw',0
	DB	'rusemn',0
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_sscann	LABEL	BYTE
	DB	'sscann',0
N_mscans	LABEL	BYTE
	DB	'mscans',0

rdf_scripts:
; The room starts. The first time, the mission's state is set up. Gases
; already released keep working; the virus timer runs; the doors.
H_0164:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0207
StartRoom:
	cmp	byte ptr [si+visited], 0
	jne	L0196
	mov	byte ptr [si+tank1], 1
	mov	byte ptr [si+tank2], 2
	mov	byte ptr [si+visited], 1
	jmp	SHORT L0187

N_LOV0LOOP	LABEL	BYTE
	DB	'LOV0LOOP',0
L0187:
	push	OFFSET N_LOV0LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("LOV0LOOP")
	add	sp, 4
L0196:
	cmp	byte ptr [si+n2o_released], 1
	jne	L01AE
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS], ax
L01AE:
	cmp	byte ptr [si+rlg_released], 1
	jne	L01C7
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS+2], ax
L01C7:
	mov	word ptr [si+RS_TIMERS+4], 0C8h
	push	0
	push	80h
	push	0E6h
	push	OFFSET N_s3r0d2a
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s3r0d2a", 230, 128, 0)
	add	sp, 0Ch
	push	0
	push	8Dh
	push	123h
	push	OFFSET N_s3r0d1a
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s3r0d1a", 291, 141, 0)
	add	sp, 0Ch
	mov	byte ptr cs:cure_x, -0Ch
	mov	byte ptr cs:cure_y, -71h
	retf

H_0207:
	SCRIPT	MSG_TICK, 0Ah, 0, 0, H_020E
Tick10:
	retf

; The right door (to room 2): walk (msg 4), it opens at the step
; (anim msg 3), and when both are done, through.
H_020E:
	SCRIPT	MSG_WALK, 21h, 0, 0, H_0216
	jmp	SHORT WalkToRightDoor

H_0216:
	SCRIPT	MSG_WALK, 9, 0, 0, H_023F
WalkToRightDoor:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr cs:going_door, 2
	push	4
	push	81h
	push	0E6h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 230, 129, 4)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL], 0
	retf

H_023F:
	SCRIPT	MSG_REGION, 0, 0, 0, H_0271
ReachRightDoor:
	cmp	byte ptr cs:going_door, 2
	jne	L0270
	push	3
	push	80h
	push	0E6h
	push	OFFSET N_s3r0d2
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s3r0d2", 230, 128, 3)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
L0270:
	retf

H_0271:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_0279
	jmp	SHORT ThroughRightDoor

H_0279:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_029C
ThroughRightDoor:
	inc	byte ptr cs:right_door_steps
	cmp	byte ptr cs:right_door_steps, 2
	je	L028D
	retf

L028D:
	push	1
	push	2
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(2, 1)
	add	sp, 6
	retf

; The left door (to room 1), the same with msgs 5 and 4.
H_029C:
	SCRIPT	MSG_WALK, 22h, 0, 0, H_02A4
	jmp	SHORT WalkToLeftDoor

H_02A4:
	SCRIPT	MSG_WALK, 8, 0, 0, H_02C9
WalkToLeftDoor:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr cs:going_door, 1
	push	5
	push	8Dh
	push	125h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 293, 141, 5)
	add	sp, 0Ah
	retf

H_02C9:
	SCRIPT	MSG_REGION, 1, 0, 0, H_02FB
ReachLeftDoor:
	cmp	byte ptr cs:going_door, 1
	jne	L02FA
	push	4
	push	8Dh
	push	123h
	push	OFFSET N_s3r0d1
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s3r0d1", 291, 141, 4)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
L02FA:
	retf

H_02FB:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_0303
	jmp	SHORT ThroughLeftDoor

H_0303:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_0326
ThroughLeftDoor:
	inc	byte ptr cs:left_door_steps
	cmp	byte ptr cs:left_door_steps, 2
	je	L0317
	retf

L0317:
	push	3
	push	1
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(1, 3)
	add	sp, 6
	retf

; Looking and talking.
H_0326:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_0335
LookAtComputer:
	sub	ax, ax
	mov	bx, OFFSET T_LOV0N006
	call	Say
	retf

H_0335:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_0344
LookAtViewscreen:
	sub	ax, ax
	mov	bx, OFFSET T_LOV0N000
	call	Say
	retf

H_0344:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_0353
LookAtScene:
	sub	ax, ax
	mov	bx, OFFSET T_LOV0N009
	call	Say
	retf

H_0353:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_0362
LookAtLeftDoor:
	sub	ax, ax
	mov	bx, OFFSET T_LOV0N008
	call	Say
	retf

H_0362:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_0371
LookAtRightDoor:
	sub	ax, ax
	mov	bx, OFFSET T_LOV0N007
	call	Say
	retf

H_0371:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_0380
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_LOV0N002
	call	Say
	retf

H_0380:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_038F
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_LOV0N004
	call	Say
	retf

H_038F:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_039E
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_LOV0N005
	call	Say
	retf

H_039E:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_03AD
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_LOV0N003
	call	Say
	retf

H_03AD:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0440
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV0_003
	call	Say
	JMPN	L043F

T_LOV0_003	LABEL	BYTE
	DB	'#LOV0\LOV0_003#Strange that the bridge is empty. Stay sharp ever'
	DB	'yone. The station''s computer system might give us some answers.',0
L043F:
	retf

H_0440:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0490
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV0_007
	call	Say
	jmp	SHORT L048F

T_LOV0_007	LABEL	BYTE
	DB	'#LOV0\LOV0_007#Nice view of the Romulan ship. How comforting.',0
L048F:
	retf

H_0490:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_04A0
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV0_027
	call	Say
	retf

H_04A0:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_04B0
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV0_038
	call	Say
	retf

; Tricorders.
H_04B0:
	SCRIPT	MSG_USE, IT_MTRICOR, ANY, 0, H_055D
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
	cmp	byte ptr [si+have_research], 1
	je	L0553
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV0_006
	call	Say
	jmp	SHORT L0552

T_LOV0_006	LABEL	BYTE
	DB	'#LOV0\LOV0_006#I''m picking up some strange, airborne virus. I ca'
	DB	'n''t identify it without more information.',0
L0552:
	retf

L0553:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV0_008
	call	Say
	retf

H_055D:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_058E
SpockScansComputer:
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
	mov	bx, OFFSET T_LOV0_031
	call	Say
	retf

H_058E:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_05BF
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
	mov	bx, OFFSET T_LOV0_028
	call	Say
	retf

; The computer: Spock reads Dr. Marcus' log (+4, once); McCoy reads it
; and finds her research on the Oroborus virus (+2, once): have_research.
H_05BF:
	SCRIPT	MSG_USE, OBJ_KIRK, 20h, 0, H_0626
KirkUsesComputer:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV0_002
	call	Say
	jmp	SHORT L0624

T_LOV0_002	LABEL	BYTE
	DB	'#LOV0\LOV0_002#Spock, check out the station''s computer and see w'
	DB	'hat you can dig up.',0
L0624:
	jmp	SHORT SpockUsesComputer

H_0626:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 20h, 0, H_0696
FerrisUsesComputer:
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV0_036
	call	Say
	jmp	SHORT L0695

T_LOV0_036	LABEL	BYTE
	DB	'#LOV0\LOV0_036#I think Mr. Spock would be more qualified in exam'
	DB	'ining the station''s computer.',0
L0695:
	retf

H_0696:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_06DE
SpockUsesComputer:
	mov	word ptr cs:user, 1
	mov	word ptr cs:user_name, OFFSET N_Mr_Spock
	mov	word ptr cs:user_line, OFFSET T_LOV0_005
	mov	word ptr cs:user_anim, OFFSET N_susemn
	push	2
	push	9Ah
	push	9Ah
	push	word ptr cs:user
	push	RC_WALK
	SERVICE		; Walk(?, 154, 154, 2)
	add	sp, 0Ah
	cmp	byte ptr [si+spock_read_log], 1
	je	L06DD
	mov	byte ptr [si+spock_read_log], 1
	add	word ptr [si+score], 4
L06DD:
	retf

H_06DE:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_06FF
AtComputer:
	push	5
	push	-1
	push	-1
	push	word ptr cs:user_anim
	push	word ptr cs:user
	push	RC_ANIM2
	SERVICE		; Anim(?, ?, -1, -1, 5)
	add	sp, 0Ch
	retf

H_06FF:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_0744
ComputerLog:
	jmp	SHORT L0710

N_V6KIRKTY	LABEL	BYTE
	DB	'V6KIRKTY',0
L0710:
	push	OFFSET N_V6KIRKTY
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("V6KIRKTY")
	add	sp, 4
	cmp	byte ptr [si+have_research], 1
	jne	L0728
	JMPN	L07F9

L0728:
	mov	ax, OFFSET N_Computer
	mov	bx, OFFSET T_COMPU188
	call	Say
	mov	ax, word ptr cs:user_name
	mov	bx, word ptr cs:user_line
	call	Say
	mov	byte ptr cs:heard_log, 1
	retf

H_0744:
	SCRIPT	MSG_USE, OBJ_MCCOY, 20h, 0, H_075E
McCoyUsesComputer:
	push	3
	push	98h
	push	78h
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 120, 152, 3)
	add	sp, 0Ah
	retf

H_075E:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_077A
McCoyAtComputer:
	push	6
	push	-1
	push	-1
	push	OFFSET N_musemw
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musemw", -1, -1, 6)
	add	sp, 0Ch
	retf

H_077A:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_0874
McCoyReadsResearch:
	jmp	SHORT L078B

N_V6KIRKTY_2	LABEL	BYTE
	DB	'V6KIRKTY',0
L078B:
	push	OFFSET N_V6KIRKTY_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("V6KIRKTY")
	add	sp, 4
	cmp	byte ptr [si+mccoy_read_log], 1
	je	L07A8
	mov	byte ptr [si+mccoy_read_log], 1
	add	word ptr [si+score], 2
L07A8:
	cmp	byte ptr [si+have_research], 1
	jne	L07B0
	jmp	SHORT L07F9

L07B0:
	cmp	byte ptr cs:heard_log, 0
	jne	L07C7
	mov	ax, OFFSET N_Computer
	mov	bx, OFFSET T_COMPU188
	call	Say
	mov	byte ptr cs:heard_log, 1
L07C7:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV0_024
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV0_035
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV0_023
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV0_004
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV0_009
	call	Say
	mov	byte ptr [si+have_research], 1
	retf

L07F9:
	mov	ax, OFFSET N_Computer
	mov	bx, OFFSET T_COMPU192
	call	Say
	mov	ax, OFFSET C_310B
	call	Talk
	AX8	cmp, 0
	jne	L080F
	jmp	SHORT L0833

L080F:
	AX8	cmp, 1
	jne	L0816
	jmp	SHORT L083E

L0816:
	AX8	cmp, 2
	jne	L081D
	jmp	SHORT L0849

L081D:
	AX8	cmp, 3
	jne	L0824
	jmp	SHORT L0854

L0824:
	AX8	cmp, 4
	jne	L082B
	jmp	SHORT L085F

L082B:
	AX8	cmp, 5
	jne	L0831
	retf

L0831:
	jmp	SHORT L086A

L0833:
	mov	ax, OFFSET N_Computer
	mov	bx, OFFSET T_COMPU190
	call	Say
	jmp	SHORT L07F9

L083E:
	mov	ax, OFFSET N_Computer
	mov	bx, OFFSET T_COMPU193
	call	Say
	jmp	SHORT L07F9

L0849:
	mov	ax, OFFSET N_Computer
	mov	bx, OFFSET T_COMPU189
	call	Say
	jmp	SHORT L07F9

L0854:
	mov	ax, OFFSET N_Computer
	mov	bx, OFFSET T_COMPU186
	call	Say
	jmp	SHORT L07F9

L085F:
	mov	ax, OFFSET N_Computer
	mov	bx, OFFSET T_COMPU187
	call	Say
	jmp	SHORT L07F9

L086A:
	mov	ax, OFFSET N_wes
	mov	bx, OFFSET N_dialog_error
	call	Say
	retf

; Getting the doors: both end up at GetComputer's line.
H_0874:
	SCRIPT	MSG_GET, 8, 0, 0, H_087A

H_087A:
GetDoor:				; NOTE: the GET 8 script has no body: its entry is this header,
					; whose six bytes run as code before the jmp
	SCRIPT	MSG_GET, 9, 0, 0, H_088C
	jmp	SHORT GetComputer

					; NOTE: unreachable, probably the doors' answer once
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV0_030
	call	Say
	retf

H_088C:
	SCRIPT	MSG_GET, 20h, 0, 0, H_08AD
GetComputer:
	mov	ax, OFFSET S_1752
	mov	bx, OFFSET T_LOV0N001
	call	Say
	retf

N_musemn	LABEL	BYTE
	DB	'musemn',0
N_sgetdn	LABEL	BYTE
	DB	'sgetdn',0
cure_steps	LABEL	BYTE	; Spock and McCoy at the cure spot: 2
	DB	0
cure_x	LABEL	BYTE	; the cure spot
	DB	0
cure_y	LABEL	BYTE
	DB	0

; The gases, common to all of the mission's rooms. Timer 0 (after
; laughing gas): a random crew member giggles, and again in 200-400 ticks.
H_08AD:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_0ACA
CrewLaugh:
	push	2
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 2)
	add	sp, 6
	mov	word ptr cs:roll, ax
	cmp	word ptr cs:roll, 0
	jne	L08D6
	mov	word ptr cs:laugher, OFFSET N_Dr_McCoy
	jmp	SHORT L0913

L08D6:
	cmp	word ptr cs:roll, 1
	jne	L08F7
	mov	word ptr cs:laugher, OFFSET N_Lt_Ferris
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L08F5
	mov	word ptr cs:laugher, OFFSET N_Dr_McCoy
	JMPN	L09BE

L08F5:
	jmp	SHORT L0913

L08F7:
	mov	ax, 0
	mov	bx, OFFSET N_get_name_error
	call	Say
	jmp	SHORT L0912

N_get_name_error	LABEL	BYTE
	DB	'get name error.',0
L0912:
	retf

L0913:
	mov	word ptr cs:laugher, OFFSET N_Dr_McCoy
	push	0Ah
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 10)
	add	sp, 6
	mov	word ptr cs:roll, ax
	cmp	word ptr cs:roll, 0
	jne	L093A
	mov	bx, OFFSET T_LOV0_011
	JMPN	L0A65

L093A:
	cmp	word ptr cs:roll, 1
	jne	L0948
	mov	bx, OFFSET T_LOV0_020
	JMPN	L0A65

L0948:
	cmp	word ptr cs:roll, 2
	jne	L0956
	mov	bx, OFFSET T_LOV0_016
	JMPN	L0A65

L0956:
	cmp	word ptr cs:roll, 3
	jne	L0964
	mov	bx, OFFSET T_LOV0_012
	JMPN	L0A65

L0964:
	cmp	word ptr cs:roll, 4
	jne	L0972
	mov	bx, OFFSET T_LOV0_014
	JMPN	L0A65

L0972:
	cmp	word ptr cs:roll, 5
	jne	L0980
	mov	bx, OFFSET T_LOV0_022
	JMPN	L0A65

L0980:
	cmp	word ptr cs:roll, 6
	jne	L098E
	mov	bx, OFFSET T_LOV0_015
	JMPN	L0A65

L098E:
	cmp	word ptr cs:roll, 7
	jne	L099C
	mov	bx, OFFSET T_LOV0_021
	JMPN	L0A65

L099C:
	cmp	word ptr cs:roll, 8
	jne	L09AA
	mov	bx, OFFSET T_LOV0_013
	JMPN	L0A65

L09AA:
	cmp	word ptr cs:roll, 9
	jne	L09B8
	mov	bx, OFFSET T_LOV0_019
	JMPN	L0A65

L09B8:
	mov	bx, OFFSET T_LOV0_017
	JMPN	L0A65

L09BE:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L09C5
	retf

L09C5:
	mov	word ptr cs:laugher, OFFSET N_Lt_Ferris
	push	0Ah
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 10)
	add	sp, 6
	mov	word ptr cs:roll, ax
	cmp	word ptr cs:roll, 0
	jne	L09EB
	mov	bx, OFFSET T_LOV0_039
	jmp	SHORT L0A65

L09EB:
	cmp	word ptr cs:roll, 1
	jne	L09F8
	mov	bx, OFFSET T_LOV0_048
	jmp	SHORT L0A65

L09F8:
	cmp	word ptr cs:roll, 2
	jne	L0A05
	mov	bx, OFFSET T_LOV0_045
	jmp	SHORT L0A65

L0A05:
	cmp	word ptr cs:roll, 3
	jne	L0A12
	mov	bx, OFFSET T_LOV0_040
	jmp	SHORT L0A65

L0A12:
	cmp	word ptr cs:roll, 4
	jne	L0A1F
	mov	bx, OFFSET T_LOV0_042
	jmp	SHORT L0A65

L0A1F:
	cmp	word ptr cs:roll, 5
	jne	L0A2C
	mov	bx, OFFSET T_LOV0_050
	jmp	SHORT L0A65

L0A2C:
	cmp	word ptr cs:roll, 6
	jne	L0A39
	mov	bx, OFFSET T_LOV0_043
	jmp	SHORT L0A65

L0A39:
	cmp	word ptr cs:roll, 7
	jne	L0A46
	mov	bx, OFFSET T_LOV0_049
	jmp	SHORT L0A65

L0A46:
	cmp	word ptr cs:roll, 8
	jne	L0A53
	mov	bx, OFFSET T_LOV0_041
	jmp	SHORT L0A65

L0A53:
	cmp	word ptr cs:roll, 9
	jne	L0A60
	mov	bx, OFFSET T_LOV0_047
	jmp	SHORT L0A65

L0A60:
	mov	bx, OFFSET T_LOV0_046
	jmp	SHORT L0A65

L0A65:
	mov	ax, word ptr cs:laugher
	call	Say
	cmp	byte ptr [si+rlg_released], 1
	jne	L0A73
	retf

L0A73:
	push	3
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 3)
	add	sp, 6
	mov	word ptr cs:roll, ax
	mov	ax, OFFSET N_Mr_Spock
	cmp	word ptr cs:roll, 0
	jne	L0A95
	mov	bx, OFFSET T_LOV0_029
	jmp	SHORT L0AB4

L0A95:
	cmp	word ptr cs:roll, 1
	jne	L0AA2
	mov	bx, OFFSET T_LOV0_033
	jmp	SHORT L0AB4

L0AA2:
	cmp	word ptr cs:roll, 2
	jne	L0AAF
	mov	bx, OFFSET T_LOV0_026
	jmp	SHORT L0AB4

L0AAF:
	mov	bx, OFFSET T_LOV0_124
	jmp	SHORT L0AB4

L0AB4:
	call	Say
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS], ax
	retf

; Timer 1 (after Romulan laughing gas): Spock laughs.
H_0ACA:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_0B5C
SpockLaughs:
	push	7
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 7)
	add	sp, 6
	mov	word ptr cs:roll, ax
	mov	ax, OFFSET N_Mr_Spock
	cmp	word ptr cs:roll, 0
	jne	L0AF2
	mov	bx, OFFSET T_LOV0_025
	jmp	SHORT L0B45

L0AF2:
	cmp	word ptr cs:roll, 1
	jne	L0AFF
	mov	bx, OFFSET T_LOV0_101
	jmp	SHORT L0B45

L0AFF:
	cmp	word ptr cs:roll, 2
	jne	L0B0C
	mov	bx, OFFSET T_LOV0_102
	jmp	SHORT L0B45

L0B0C:
	cmp	word ptr cs:roll, 3
	jne	L0B19
	mov	bx, OFFSET T_LOV0_103
	jmp	SHORT L0B45

L0B19:
	cmp	word ptr cs:roll, 4
	jne	L0B26
	mov	bx, OFFSET T_LOV0_104
	jmp	SHORT L0B45

L0B26:
	cmp	word ptr cs:roll, 5
	jne	L0B33
	mov	bx, OFFSET T_LOV0_105
	jmp	SHORT L0B45

L0B33:
	cmp	word ptr cs:roll, 6
	jne	L0B40
	mov	bx, OFFSET T_LOV0_106
	jmp	SHORT L0B45

L0B40:
	mov	bx, OFFSET T_LOV0_107
	jmp	SHORT L0B45

L0B45:
	call	Say
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS+2], ax
	retf

; Curing Spock, common to all of the mission's rooms: with the cure,
; Spock and McCoy walk to the cure spot (msg 99), and McCoy injects him.
H_0B5C:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_SPOCK, 0, H_0BEA
MedkitOnSpock:
	cmp	byte ptr [si+spock_cured], 1
	je	L0BB6
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_019
	call	Say
	jmp	SHORT L0BB5

T_LOV5_019	LABEL	BYTE
	DB	'#LOV5\LOV5_019#I don''t have the proper medicine to cure him, Jim'
	DB	'.',0
L0BB5:
	retf

L0BB6:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_015
	call	Say
	jmp	SHORT L0BE9

T_LOV5_015	LABEL	BYTE
	DB	'#LOV5\LOV5_015#He''s already cured, Jim.',0
L0BE9:
	retf

H_0BEA:
	SCRIPT	MSG_USE, IT_SAMPLE, OBJ_SPOCK, 0, H_0C5D
SampleOnSpock:
	cmp	byte ptr [si+spock_cured], 1
	jne	L0BF9
	JMPN	L0C9D

L0BF9:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F55
	call	Say
	jmp	SHORT L0C5C

T_LOVA_F55	LABEL	BYTE
	DB	'#LOVA\LOVA_F55#Jim, we need to sysnthesize more to make the seru'
	DB	'm before we can use it.',0
L0C5C:
	retf

H_0C5D:
	SCRIPT	MSG_USE, IT_CURE, OBJ_SPOCK, 0, H_0CD9
CureSpock:
	cmp	byte ptr [si+spock_cured], 1
	jne	L0C9D
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_015_2
	call	Say
	jmp	SHORT L0C9C

T_LOV5_015_2	LABEL	BYTE
	DB	'#LOV5\LOV5_015#He''s already cured, Jim.',0
L0C9C:
	retf

L0C9D:
	push	63h
	xor	ah, ah
	mov	al, byte ptr cs:cure_y
	push	ax
	xor	ah, ah
	mov	al, byte ptr cs:cure_x
	push	ax
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, ?, ?, 99)
	add	sp, 0Ah
	push	63h
	xor	ah, ah
	mov	al, byte ptr cs:cure_y
	AX8	add, 0Ah
	push	ax
	xor	ah, ah
	mov	al, byte ptr cs:cure_x
	push	ax
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, ?, ?, 99)
	add	sp, 0Ah
	retf

H_0CD9:
	SCRIPT	MSG_WALK_DONE, 63h, 0, 0, H_0D03
AtSpock:
	inc	byte ptr cs:cure_steps
	cmp	byte ptr cs:cure_steps, 2
	je	L0CED
	retf

L0CED:
	push	63h
	push	-1
	push	-1
	push	OFFSET N_musemn
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musemn", -1, -1, 99)
	add	sp, 0Ch
	retf

H_0D03:
	SCRIPT	MSG_ANIM_DONE, 63h, 0, 0, H_0DC2
SpockCured:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_030
	call	Say
	jmp	SHORT L0D3C

T_LOV5_030	LABEL	BYTE
	DB	'#LOV5\LOV5_030#There. You''re now cured.',0
L0D3C:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV5_038
	call	Say
	jmp	SHORT L0D69

T_LOV5_038	LABEL	BYTE
	DB	'#LOV5\LOV5_038#Thank you, Doctor.',0
L0D69:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_027
	call	Say
	jmp	SHORT L0D9E

T_LOV5_027	LABEL	BYTE
	DB	'#LOV5\LOV5_027#Finally, a human response!',0
L0D9E:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_0DA9
	call	Say
	jmp	SHORT L0DBD

S_0DA9	LABEL	BYTE
	DB	'(raises an eyebrow)',0
L0DBD:
	mov	byte ptr [si+spock_cured], 1
	retf

; Timer 2, every 200 ticks until Spock is cured: the virus advances,
; with a line at 0Fh, 1Eh, 2Dh; at 3Ch Spock collapses, at 64h he dies.
H_0DC2:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_0F78
VirusProgresses:
	cmp	byte ptr [si+spock_cured], 1
	jne	L0DCF
	retf

L0DCF:
	inc	byte ptr [si+virus]
	cmp	byte ptr [si+virus], 64h
	jl	L0DDB
	JMPN	L0F28

L0DDB:
	cmp	byte ptr [si+virus], 0Fh
	jne	L0E12
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_spokcoff
	call	Say
	jmp	SHORT L0E0C

T_spokcoff	LABEL	BYTE
	DB	'#sfx\spokcoff#cough... cough...',0
L0E0C:
	inc	byte ptr [si+virus]
	JMPN	L0F22

L0E12:
	cmp	byte ptr [si+virus], 1Eh
	jne	L0E78
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F08
	call	Say
	jmp	SHORT L0E72

T_LOVA_F08	LABEL	BYTE
	DB	'#LOVA\LOVA_F08#It''s what I was afraid of, Jim. I think spock is '
	DB	'getting worse.',0
L0E72:
	inc	byte ptr [si+virus]
	JMPN	L0F22

L0E78:
	cmp	byte ptr [si+virus], 2Dh
	jne	L0EAE
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_spokcoff_2
	call	Say
	jmp	SHORT L0EA9

T_spokcoff_2	LABEL	BYTE
	DB	'#sfx\spokcoff#cough... cough...',0
L0EA9:
	inc	byte ptr [si+virus]
	jmp	SHORT L0F22

L0EAE:
	cmp	byte ptr [si+virus], 3Ch
	jne	L0F22
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOVA_F54
	call	Say
	jmp	SHORT L0F19

T_LOVA_F54	LABEL	BYTE
	DB	'#LOVA\LOVA_F54#The virus has spread to me, Captain.Isuggestyouco'
	DB	'ncentrateyoureffortsonthe',0
L0F19:
	mov	byte ptr [si+virus_struck], 1
	inc	byte ptr [si+virus]
	jmp	SHORT L0F22

L0F22:
	mov	word ptr [si+RS_TIMERS+4], 0C8h
	retf

L0F28:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sgetdn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sgetdn", -1, -1, 0)
	add	sp, 0Ch
	push	2
	push	RC_MUSIC
	SERVICE		; Music(2)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_GENER004
	call	Say
	jmp	SHORT L0F6D

T_GENER004	LABEL	BYTE
	DB	'#GENE\GENER004#Game Over',0
L0F6D:
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	retf

; McCoy's tricorder on Spock follows the virus; on the others, normal.
H_0F78:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_SPOCK, 0, H_11E9
McCoyScansSpock:
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	cmp	byte ptr [si+spock_cured], 1
	jne	L0FD2
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F01
	call	Say
	jmp	SHORT L0FD1

T_LOVA_F01	LABEL	BYTE
	DB	'#LOVA\LOVA_F01#He''s been cured of the Oroborus virus.',0
L0FD1:
	retf

L0FD2:
	cmp	byte ptr [si+have_research], 1
	je	L1044
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F02
	call	Say
	jmp	SHORT L1043

T_LOVA_F02	LABEL	BYTE
	DB	'#LOVA\LOVA_F02#I''m picking up some kind of virus. I can''t identi'
	DB	'fy it without more information.',0
L1043:
	retf

L1044:
	cmp	byte ptr [si+virus], 0Ah
	jge	L1099
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F04
	call	Say
	jmp	SHORT L1098

T_LOVA_F04	LABEL	BYTE
	DB	'#LOVA\LOVA_F04#The virus affects the Romulan-Vulcan genotype, Ji'
	DB	'm.',0
L1098:
	retf

L1099:
	cmp	byte ptr [si+virus], 1Eh
	jge	L10DD
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F03
	call	Say
	jmp	SHORT L10DC

T_LOVA_F03	LABEL	BYTE
	DB	'#LOVA\LOVA_F03#He''s infected with the virus, Jim.',0
L10DC:
	retf

L10DD:
	cmp	byte ptr [si+virus], 32h
	jge	L113E
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F08_2
	call	Say
	jmp	SHORT L113D

T_LOVA_F08_2	LABEL	BYTE
	DB	'#LOVA\LOVA_F08#It''s what I was afraid of, Jim. I think spock is '
	DB	'getting worse.',0
L113D:
	retf

L113E:
	cmp	byte ptr [si+virus], 46h
	jne	L1184
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG2_010
	call	Say
	jmp	SHORT L1183

T_TUG2_010	LABEL	BYTE
	DB	'#TUG2\TUG2_010#I don''t like the looks of this, Jim.',0
L1183:
	retf

L1184:
	cmp	byte ptr [si+virus], 64h
	jge	L11BE
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F10
	call	Say
	jmp	SHORT L11BD

T_LOVA_F10	LABEL	BYTE
	DB	'#LOVA\LOVA_F10#He has weak vital signs.',0
L11BD:
	retf

L11BE:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_100
	call	Say
	jmp	SHORT L11E8

T_LOVA_100	LABEL	BYTE
	DB	'#LOVA\LOVA_100#He''s dead, Jim.',0
L11E8:
	retf

H_11E9:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_KIRK, 0, H_11F1
	jmp	SHORT McCoyScansMcCoy

H_11F1:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_MCCOY, 0, H_11F9
McCoyScansMcCoy:
	jmp	SHORT McCoyScansCrew

H_11F9:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_REDSHIRT, 0, H_1240
McCoyScansCrew:
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F07
	call	Say
	jmp	SHORT L123F

T_LOVA_F07	LABEL	BYTE
	DB	'#LOVA\LOVA_F07#All lifesigns are normal.',0
L123F:
	retf

; Opening a gas canister: Romulan laughing gas sets Spock laughing,
; nitrous oxide the crew, ammonia nothing.
H_1240:
	SCRIPT	MSG_USE, IT_RLG, ANY, 0, H_1290
ReleaseRLG:
	mov	ax, OFFSET S_1752
	mov	bx, OFFSET T_LOV2N005
	call	Say
	jmp	SHORT L127F

T_LOV2N005	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L127F:
	mov	byte ptr [si+rlg_released], 1
	push	IT_RLG
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_RLG)
	add	sp, 4
	retf

H_1290:
	SCRIPT	MSG_USE, IT_N2O, ANY, 0, H_1322
ReleaseN2O:
	mov	ax, OFFSET S_1752
	mov	bx, OFFSET T_LOV2N005_2
	call	Say
	jmp	SHORT L12CF

T_LOV2N005_2	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L12CF:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD2_040
	call	Say
	jmp	SHORT L1305

T_MUD2_040	LABEL	BYTE
	DB	'#MUD2\MUD2_040#You look troubled, Captain.',0
L1305:
	mov	byte ptr [si+n2o_released], 1
	push	IT_N2O
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_N2O)
	add	sp, 4
	push	3
	push	RC_MUSIC
	SERVICE		; Music(3)
	add	sp, 4
	retf

H_1322:
	SCRIPT	MSG_USE, IT_NH3, ANY, 0, H_1388
ReleaseNH3:
	mov	ax, OFFSET S_1752
	mov	bx, OFFSET T_LOV2N005_3
	call	Say
	jmp	SHORT L1361

T_LOV2N005_3	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L1361:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L1367
L1367:
	push	IT_NH3
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_NH3)
	add	sp, 4
	retf

	DB	'Mr. Scott',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0

; The communicator: four cases (first call, later calls, the same after
; the cure), all with the same three lines borrowed from other missions'
; speech files.
H_1388:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, rdf_scripts_end
CallEnterprise:
	cmp	byte ptr [si+made_cure], 1
	jne	L1397
	JMPN	L14E4

L1397:
	cmp	byte ptr [si+called_ship], 1
	jne	L13A0
	JMPN	L1444

L13A0:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018
	call	Say
	jmp	SHORT L13E5

T_MUD4_018	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L13E5:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146
	call	Say
	jmp	SHORT L141B

T_BRIDU146	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L141B:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41
	call	Say
	jmp	SHORT L143F

T_VENA_F41	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L143F:
	mov	byte ptr [si+called_ship], 1
	retf

L1444:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_2
	call	Say
	jmp	SHORT L1489

T_MUD4_018_2	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L1489:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_2
	call	Say
	jmp	SHORT L14BF

T_BRIDU146_2	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L14BF:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_2
	call	Say
	jmp	SHORT L14E3

T_VENA_F41_2	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L14E3:
	retf

L14E4:
	cmp	byte ptr [si+called_ship_cured], 1
	jne	L14ED
	JMPN	L1591

L14ED:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_3
	call	Say
	jmp	SHORT L1532

T_MUD4_018_3	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L1532:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_3
	call	Say
	jmp	SHORT L1568

T_BRIDU146_3	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L1568:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_3
	call	Say
	jmp	SHORT L158C

T_VENA_F41_3	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L158C:
	mov	byte ptr [si+called_ship_cured], 1
	retf

L1591:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_4
	call	Say
	jmp	SHORT L15D6

T_MUD4_018_4	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L15D6:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_4
	call	Say
	jmp	SHORT L160C

T_BRIDU146_4	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L160C:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_4
	call	Say
	jmp	SHORT L1630

T_VENA_F41_4	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L1630:
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
	DW	23h, 4	; id, points
	DW	94,65, 190,65, 190,92, 94,92
	DW	23h, 4	; id, points
	DW	94,93, 190,93, 170,113, 115,113
	DW	20h, 4	; id, points
	DW	101,119, 188,119, 188,137, 101,137
	DW	20h, 4	; id, points
	DW	67,127, 100,119, 106,137, 83,147
	DW	20h, 4	; id, points
	DW	189,119, 219,126, 203,148, 180,138
	DW	21h, 4	; id, points
	DW	210,122, 246,122, 246,136, 210,136
	DW	22h, 4	; id, points
	DW	264,132, 306,132, 306,162, 264,162
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	210,122, 246,122, 246,136, 210,136
	DW	1, 4	; id, points
	DW	264,132, 306,132, 306,162, 264,162
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	'lite1',0
	DB	'lite2',0
	DB	'lite3',0
	DB	'lite4',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Ferris	LABEL	BYTE
	DB	'Lt. Ferris',0
N_Computer	LABEL	BYTE
	DB	'Computer',0
N_wes	LABEL	BYTE
	DB	'wes',0
S_1752	LABEL	BYTE
	DB	0
T_LOV0N008	LABEL	BYTE
	DB	'#LOV0\LOV0N008#This is a standard door, leading to another room '
	DB	'on this deck.',0
T_LOV0N006	LABEL	BYTE
	DB	'#LOV0\LOV0N006#This computer terminal is linked into the station'
	DB	'''s main computer. It is currently running an open file of log pr'
	DB	'ograms.',0
T_LOV0N004	LABEL	BYTE
	DB	'#LOV0\LOV0N004#McCoy is fidgeting around.',0
T_LOV0N002	LABEL	BYTE
	DB	'#LOV0\LOV0N002#James Kirk watches the Romulan ship with concern.',0
T_LOV0N005	LABEL	BYTE
	DB	'#LOV0\LOV0N005#Spock is analyzing the surroundings.',0
T_LOV0N003	LABEL	BYTE
	DB	'#LOV0\LOV0N003#Lt. Ferris watches the exits carefully.',0
T_LOV0N009	LABEL	BYTE
	DB	'#LOV0\LOV0N009#You are on the bridge of the ARK7.',0
T_LOV0N000	LABEL	BYTE
	DB	'#LOV0\LOV0N000#A Romulan bird of prey hovers menacingly on the v'
	DB	'iew screen.',0
T_LOV0N007	LABEL	BYTE
	DB	'#LOV0\LOV0N007#This is a heavily secured door, leading to anothe'
	DB	'r section of the station. Its access code has been breached.',0
T_LOV0_027	LABEL	BYTE
	DB	'#LOV0\LOV0_027#Nothing unusual here, Captain, though the station'
	DB	'''s computer may be able to tell us something.',0
T_LOV0_038	LABEL	BYTE
	DB	'#LOV0\LOV0_038#This is a very dangerous situation, sir. We shoul'
	DB	'd proceed with caution.',0
T_LOV0_008	LABEL	BYTE
	DB	'#LOV0\LOV0_008#Except for the Oroborus virus, I''m not picking up'
	DB	' anything unusual.',0
T_LOV0_031	LABEL	BYTE
	DB	'#LOV0\LOV0_031#The main computer banks of the Ark7. It looks lik'
	DB	'e someone has recently been rummaging through the main data bank'
	DB	's.',0
T_LOV0_028	LABEL	BYTE
	DB	'#LOV0\LOV0_028#Nothing unusual is detected.',0
T_COMPU188	LABEL	BYTE
	DB	'#COMP\COMPU188#Dr. Marcus'' Log, Supplemental: Continued testing '
	DB	'of the Oroborus Virus confirms its potential harmful effects on '
	DB	'Romulan/Vulcan humanoids. As soon as the spill has been cleaned '
	DB	'up, we will sterilize both labs and purge the circulation system'
	DB	' to make sure no traces of the virus will remain viable. Then al'
	DB	'l research files must be erased -- we must leave no chance that '
	DB	'this terrible accident will ever be repeated.',0
T_LOV0_024	LABEL	BYTE
	DB	'#LOV0\LOV0_024#Now that''s interesting -- there''s more here. All '
	DB	'of Dr. Marcus'' research data on the Oroborous virus.  Let me see'
	DB	'...virus growth patterns, pneumonococcal mimic affecting Romulo-'
	DB	'Vulcan genotype ... alveoli involvement in--  Boy, Jim, this bug'
	DB	' works fast!',0
T_LOV0_035	LABEL	BYTE
	DB	'#LOV0\LOV0_035#Is this really the time to catch up on your readi'
	DB	'ng, Doctor?',0
T_LOV0_023	LABEL	BYTE
	DB	'#LOV0\LOV0_023#Now listen here, you pointy-eared...',0
T_LOV0_004	LABEL	BYTE
	DB	'#LOV0\LOV0_004#Gentlemen, I think we have more pressing problems'
	DB	'.',0
T_LOV0_009	LABEL	BYTE
	DB	'#LOV0\LOV0_009#Jim, there is an appended medical database online'
	DB	'. Also, it would be useful for me to experiment on how the virus'
	DB	' grows in the presence of different gases. I''m sure the station '
	DB	'has the necessary equipment.',0
T_COMPU192	LABEL	BYTE
	DB	'#COMP\COMPU192#Please select subject file...',0
T_COMPA190	LABEL	BYTE
	DB	'#COMP\COMPA190#Oroborus Virus',0
T_COMPA193	LABEL	BYTE
	DB	'#COMP\COMPA193#TLTDH Gas',0
T_COMPA189	LABEL	BYTE
	DB	'#COMP\COMPA189#Nitrous Oxide',0
T_COMPA186	LABEL	BYTE
	DB	'#COMP\COMPA186#Ammonia',0
T_COMPA187	LABEL	BYTE
	DB	'#COMP\COMPA187#Di-hydrogen Oxide',0
T_COMPA191	LABEL	BYTE
	DB	'#COMP\COMPA191#Exit Database',0
T_COMPU190	LABEL	BYTE
	DB	'#COMP\COMPU190#Oroborus virus: Atypical growth patterns for L-Ty'
	DB	'pe virus. Opportunistic pneumococcal mimic affecting Romulo-Vulc'
	DB	'an genotype. Etiology: contact or airborne vector with alveoli m'
	DB	'icrocollapse involvement immediately upon exposure. Tissue dehyd'
	DB	'ration follows pneumal flooding. Mortality: 0.6 in 1.0 stardates'
	DB	', 1.0 within 2.0 stardates Treatment: none. Named for the mythic'
	DB	' worldsnake that swallows its own tail.',0
T_COMPU193	LABEL	BYTE
	DB	'#COMP\COMPU193#TLTDH gas: The chemical compound tantalum bi-lith'
	DB	'ium thalo-dihydroxide. Colorless, odorless, nonflammable gaseous'
	DB	' at 1 atm and temperatures within the human norm. Early anesthet'
	DB	'ic among Vulcans and Romulans, in whom it produces laughter, fee'
	DB	'lings of exhiliration, euphoria; sometimes leading to unconsciou'
	DB	'sness. In post-industrial/pre-spaceflight era, a social problem '
	DB	'evolved when crude TLTDH became popular to "cook up" from non-co'
	DB	'nductive tantalo-lithial compounds commonly used as electrical i'
	DB	'nsulation.',0
T_COMPU189	LABEL	BYTE
	DB	23h, 43h, 4Fh, 4Dh, 50h, 5Ch, 43h, 4Fh, 4Dh, 50h, 55h, 31h
	DB	38h, 39h, 23h, 4Eh, 69h, 74h, 72h, 6Fh, 75h, 73h, 20h, 4Fh
	DB	78h, 69h, 64h, 65h, 3Ah, 20h, 61h, 20h, 63h, 6Fh, 6Ch, 6Fh
	DB	72h, 6Ch, 65h, 73h, 73h, 20h, 6Eh, 6Fh, 6Eh, 66h, 6Ch, 61h
	DB	6Dh, 6Dh, 61h, 62h, 6Ch, 65h, 20h, 63h, 6Fh, 6Dh, 70h, 6Fh
	DB	75h, 6Eh, 64h, 20h, 4Eh, 1Dh
	DB	'O, gaseous at 1 atm and temperatures within the human norm. Earl'
	DB	'y anesthetic among humans, in whom it produces laughter, feeling'
	DB	's of exhiliration, euphoria; sometimes leading to unconsciousnes'
	DB	's.',0
T_COMPU186	LABEL	BYTE
	DB	'#COMP\COMPU186#Ammonia: a colorless pungent compound NH3, a comm'
	DB	'on byproduct of metabolism in carbon-based lifeforms. Liquid or '
	DB	'gaseous at 1 atm. Compounds widely used in agricultural, medical'
	DB	' and industrial applications.',0
T_COMPU187	LABEL	BYTE
	DB	23h, 43h, 4Fh, 4Dh, 50h, 5Ch, 43h, 4Fh, 4Dh, 50h, 55h, 31h
	DB	38h, 37h, 23h, 44h, 69h, 2Dh, 68h, 79h, 64h, 72h, 6Fh, 67h
	DB	65h, 6Eh, 20h, 4Fh, 78h, 69h, 64h, 65h, 3Ah, 20h, 61h, 20h
	DB	63h, 6Fh, 6Ch, 6Fh, 72h, 6Ch, 65h, 73h, 73h, 2Ch, 20h, 74h
	DB	61h, 73h, 74h, 65h, 6Ch, 65h, 73h, 73h, 2Ch, 20h, 6Eh, 6Fh
	DB	6Eh, 66h, 6Ch, 61h, 6Dh, 6Dh, 61h, 62h, 6Ch, 65h, 20h, 63h
	DB	6Fh, 6Dh, 70h, 6Fh, 75h, 6Eh, 64h, 20h, 48h, 1Dh
	DB	'O- water. Liquid, solid, or gaseous at 1 atm. Temperature scales'
	DB	' defined in most humanoid cultures by state-shift of pure water.',0
	DB	'#LOV0\LOV0_001#A medical data file is attached --  your bailiwic'
	DB	'k, Bones.',0
T_LOV0_005	LABEL	BYTE
	DB	'#LOV0\LOV0_005#Doctor, you may be interested in the medical data'
	DB	' file appended to the log.',0
	DB	'#LOV0\LOV0_037#A detailed data file is with the log.  Do you wan'
	DB	't to look at it, Doctor McCoy?',0
T_LOV0_030	LABEL	BYTE
	DB	'#LOV0\LOV0_030#That is not logical, Captain.',0
T_LOV0N001	LABEL	BYTE
	DB	'#LOV0\LOV0N001#It is bolted down and cannot be moved.',0
	DB	'Where? It''s welded to the bulkhead, dummy!',0
	DB	'#LOV0\LOV0_010#Ouch!',0
T_LOV0_011	LABEL	BYTE
	DB	'#LOV0\LOV0_011#Hee hee hee hee...',0
T_LOV0_020	LABEL	BYTE
	DB	'#LOV0\LOV0_020#The hills are alive... With the sounds of...',0
T_LOV0_016	LABEL	BYTE
	DB	'#LOV0\LOV0_016#Ooka! Ooka! Ooka!',0
T_LOV0_012	LABEL	BYTE
	DB	'#LOV0\LOV0_012#I think we''re all feeling just woooonderful!',0
T_LOV0_014	LABEL	BYTE
	DB	'#LOV0\LOV0_014#I''m floating up and up and up...',0
T_LOV0_022	LABEL	BYTE
	DB	'#LOV0\LOV0_022#This is how I want to feel all the time!',0
T_LOV0_015	LABEL	BYTE
	DB	'#LOV0\LOV0_015#I''m so happy, I want to hug the world!',0
T_LOV0_021	LABEL	BYTE
	DB	'#LOV0\LOV0_021#The moon in June''s a boon to tunes... er, somethi'
	DB	'ng like that.',0
T_LOV0_013	LABEL	BYTE
	DB	'#LOV0\LOV0_013#I''m a little teapot short and stout...',0
T_LOV0_019	LABEL	BYTE
	DB	'#LOV0\LOV0_019#Spock, ol'' buddy, ol'' friend, you look soo funny '
	DB	'standing there!',0
T_LOV0_017	LABEL	BYTE
	DB	'#LOV0\LOV0_017#Row, row, row, your boat. Aww, come on Spock.',0
T_LOV0_039	LABEL	BYTE
	DB	'#LOV0\LOV0_039#Hee hee hee hee...',0
T_LOV0_048	LABEL	BYTE
	DB	'#LOV0\LOV0_048#The hills are alive... With the sounds of...',0
T_LOV0_045	LABEL	BYTE
	DB	'#LOV0\LOV0_045#Ooka! Ooka! Ooka!',0
T_LOV0_040	LABEL	BYTE
	DB	'#LOV0\LOV0_040#I think we''re all feeling just woooonderful!',0
T_LOV0_042	LABEL	BYTE
	DB	'#LOV0\LOV0_042#I''m floating up and up and up...',0
T_LOV0_050	LABEL	BYTE
	DB	'#LOV0\LOV0_050#This is how I want to feel all the time!',0
T_LOV0_043	LABEL	BYTE
	DB	'#LOV0\LOV0_043#I''m so happy, I want to hug the world!',0
T_LOV0_049	LABEL	BYTE
	DB	'#LOV0\LOV0_049#The moon in June''s a boon to tunes... er, somethi'
	DB	'ng like that.',0
T_LOV0_041	LABEL	BYTE
	DB	'#LOV0\LOV0_041#I''m a little teapot short and stout...',0
T_LOV0_047	LABEL	BYTE
	DB	'#LOV0\LOV0_047#Spock, ol'' buddy, ol'' friend, you look soo funny '
	DB	'standing there!',0
T_LOV0_046	LABEL	BYTE
	DB	'#LOV0\LOV0_046#Row, row, row, your boat. Aww, come on Spock.',0
T_LOV0_029	LABEL	BYTE
	DB	'#LOV0\LOV0_029#Please, gentlemen, try to control yourselves',0
T_LOV0_033	LABEL	BYTE
	DB	'#LOV0\LOV0_033#Try taking deep breaths to clear your heads.',0
T_LOV0_026	LABEL	BYTE
	DB	'#LOV0\LOV0_026#I don''t believe you''d behave like this if you cou'
	DB	'ld avoid it.',0
T_LOV0_124	LABEL	BYTE
	DB	'#LOV0\LOV0_124#I''m trying to be patient, Captain.',0
T_LOV0_025	LABEL	BYTE
	DB	'#LOV0\LOV0_025#How many Admirals does it take to wire in a logic'
	DB	' transmogrifier?',0
T_LOV0_101	LABEL	BYTE
	DB	'#LOV0\LOV0_101#Fascinating. I am experiencing an urge to laugh.',0
T_LOV0_102	LABEL	BYTE
	DB	'#LOV0\LOV0_102#I am a Vulcan. I must resist these unchecked emot'
	DB	'ions.',0
T_LOV0_103	LABEL	BYTE
	DB	'#LOV0\LOV0_103#Logic...What happened to my logic?',0
T_LOV0_104	LABEL	BYTE
	DB	'#LOV0\LOV0_104#Jim, is this how you feel on shore leave?',0
T_LOV0_105	LABEL	BYTE
	DB	'#LOV0\LOV0_105#I remember my mother trying to tell me jokes when'
	DB	' I was a child. Now, I finally understand them.',0
T_LOV0_106	LABEL	BYTE
	DB	'#LOV0\LOV0_106#Romulan laughing gas. My father would never appro'
	DB	've.',0
T_LOV0_107	LABEL	BYTE
	DB	'#LOV0\LOV0_107#Why do they call you "Bones", doctor?',0
N_dialog_error	LABEL	BYTE
	DB	'dialog error',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0
C_310B	LABEL	BYTE
	DW	OFFSET N_Computer, OFFSET T_COMPA190, OFFSET T_COMPA193, OFFSET T_COMPA189, OFFSET T_COMPA186, OFFSET T_COMPA187, OFFSET T_COMPA191, 0	; speaker, choices, 0

RDF	ENDS
	END
