; FEATHER2.RDF - "The Feathered Serpent", a stretch of overgrown jungle
; between the pit (room 1) and the river (room 3). Nothing to do but look
; around; Spock reads a humanoid to the west.
;
; Objects: 20h-22h eyes, 23h the great tree, 24h trees, 25h a vine, 26h
; the way west. Exits: 2 room 1, 3 room 3.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 02D4: the engine reads its bytes
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
	DW	0C7h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	73h
rdf_scale_min	LABEL	BYTE
	DW	0F0h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, -1, 1, 3	; room for each exit
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
	DW	234,170, 152,178	; entrance 2, crew 0
	DW	256,160, 159,169	; entrance 2, crew 1
	DW	246,178, 165,187	; entrance 2, crew 2
	DW	275,170, 176,170	; entrance 2, crew 3
	DW	100,157, 152,178	; entrance 3, crew 0
	DW	80,156, 136,169	; entrance 3, crew 1
	DW	60,156, 165,187	; entrance 3, crew 2
	DW	40,154, 176,170	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	152,178, 136,169, 165,187, 176,170
N_sscans	LABEL	BYTE
	DB	'sscans',0

rdf_scripts:
; The room starts: the music.
H_00D1:
	SCRIPT	MSG_TICK, 1, 0, 0, H_00FE
StartRoom:
	jmp	SHORT L00E2

N_FEA2LOOP	LABEL	BYTE
	DB	'FEA2LOOP',0
L00E2:
	push	OFFSET N_FEA2LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("FEA2LOOP")
	add	sp, 4
	push	1Bh
	push	RC_MUSIC
	SERVICE		; Music(27)
	add	sp, 4
	retf

; The communicator and phasers don't work ("They're dead, Jim").
H_00FE:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_010E
UseCommunicator:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA2_006
	call	Say
	retf

H_010E:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_011E
StunAnything:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA2_003
	call	Say
	retf

H_011E:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_012E
KillAnything:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA2_003
	call	Say
	retf

; Tricorders and talking.
H_012E:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_015F
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
	mov	bx, OFFSET T_FEA2_007
	call	Say
	retf

H_015F:
	SCRIPT	MSG_USE, IT_MTRICOR, ANY, 0, H_016F
McCoyScans:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA2_002
	call	Say
	retf

H_016F:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_017F
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA2_004
	call	Say
	retf

H_017F:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_018F
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA2_008
	call	Say
	retf

H_018F:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_019F
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA2_009
	call	Say
	retf

; Looking.
H_019F:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_01C1
LookAtVine:
	mov	ax, OFFSET S_03FC
	mov	bx, OFFSET T_FEA2N000
	call	Say
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA2_010
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA2_005
	call	Say
	retf

H_01C1:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, H_0224
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA2_001
	call	Say
	retf

T_FEA2_001	LABEL	BYTE
	DB	'#FEA2\FEA2_001#Everyone is healthy, Jim, there''s no need for the'
	DB	' medical kit here.',0

; Walking off to the west (exit 2, room 1; exit 3, room 3).
H_0224:
	SCRIPT	MSG_WALK, 26h, 0, 0, H_023E
WalkWest:
	push	0
	push	96h
	push	14h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 20, 150, 0)
	add	sp, 0Ah
	retf

H_023E:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_024D
LookAtEyes1:
	sub	ax, ax
	mov	bx, OFFSET T_FEA2N001
	call	Say
	retf

H_024D:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_025C
LookAtEyes2:
	sub	ax, ax
	mov	bx, OFFSET T_FEA2N001
	call	Say
	retf

H_025C:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_026B
LookAtEyes3:
	sub	ax, ax
	mov	bx, OFFSET T_FEA2N001
	call	Say
	retf

H_026B:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_027A
LookAtTree:
	sub	ax, ax
	mov	bx, OFFSET T_FEA2N006
	call	Say
	retf

H_027A:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_0289
LookAtTrees:
	sub	ax, ax
	mov	bx, OFFSET T_FEA2N007
	call	Say
	retf

H_0289:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_0298
LookAtScene:
	sub	ax, ax
	mov	bx, OFFSET T_FEA2N008
	call	Say
	retf

H_0298:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_02A7
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_FEA2N002
	call	Say
	retf

H_02A7:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_02B6
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_FEA2N005
	call	Say
	retf

H_02B6:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_02C5
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_FEA2N004
	call	Say
	retf

H_02C5:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, Talk
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_FEA2N003
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
	DW	127,105, 140,105, 140,116, 127,116
	DW	21h, 4	; id, points
	DW	274,161, 286,161, 286,171, 274,171
	DW	22h, 4	; id, points
	DW	70,54, 80,54, 80,61, 70,61
	DW	23h, 4	; id, points
	DW	41,0, 106,86, 96,168, 33,167
	DW	24h, 5	; id, points
	DW	151,85, 188,0, 293,0, 290,123, 137,136
	DW	25h, 6	; id, points
	DW	68,10, 112,60, 138,57, 165,11, 148,78, 97,77
	DW	26h, 4	; id, points
	DW	0,103, 44,103, 44,199, 0,199
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	2, 4	; id, points
	DW	270,145, 290,145, 290,190, 270,190
	DW	3, 4	; id, points
	DW	0,135, 38,135, 38,165, 0,165
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's5r0e0',0
	DB	's5r0e1',0
	DB	's5r0e3',0
rdf_bans_end	LABEL	BYTE
	DB	'Capt. Kirk',0
	DB	'Quetzecoatl',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Stragey	LABEL	BYTE
	DB	'Lt. Stragey',0
S_03FC	LABEL	BYTE
	DB	0
T_FEA2N006	LABEL	BYTE
	DB	'#FEA2\FEA2N006#This great tree has been in this jungle for centu'
	DB	'ries.',0
T_FEA2N007	LABEL	BYTE
	DB	'#FEA2\FEA2N007#Trees to the left of you! Trees to the right of y'
	DB	'ou! Into the valley of trees raced the landing party!',0
T_FEA2N000	LABEL	BYTE
	DB	'#FEA2\FEA2N000#A vine hangs from the trees.',0
T_FEA2_010	LABEL	BYTE
	DB	'#FEA2\FEA2_010#You know, I always wanted to go swinging on a vin'
	DB	'e through a jungle. Just like in some old books I read when I wa'
	DB	's a kid.',0
T_FEA2_005	LABEL	BYTE
	DB	'#FEA2\FEA2_005#Really? Tell me more about your childhood Lieuten'
	DB	'ant...',0
T_FEA2N001	LABEL	BYTE
	DB	'#FEA2\FEA2N001#Feral red eyes glare out of the dark at you.',0
T_FEA2N008	LABEL	BYTE
	DB	'#FEA2\FEA2N008#You are in a densely vegetated area. The overgrow'
	DB	'th blocks your view in all directions.',0
T_FEA2_006	LABEL	BYTE
	DB	'#FEA2\FEA2_006#Fascinating. Our communicators have apparently be'
	DB	'en rendered ineffective.',0
T_FEA2_003	LABEL	BYTE
	DB	'#FEA2\FEA2_003#They''re dead, Jim.',0
T_FEA2_007	LABEL	BYTE
	DB	'#FEA2\FEA2_007#I am reading a life form to the west. It appears '
	DB	'to be humanoid.',0
T_FEA2_002	LABEL	BYTE
	DB	'#FEA2\FEA2_002#Nothing interesting in this neck of the woods, Ji'
	DB	'm.',0
T_FEA2_004	LABEL	BYTE
	DB	'#FEA2\FEA2_004#This jungle is sure lush, Jim. Speaking of lush, '
	DB	'I could use a nice saurian brandy about now.',0
T_FEA2_008	LABEL	BYTE
	DB	'#FEA2\FEA2_008#Staying in this overgrown region could prove quit'
	DB	'e dangerous. I suggest we continue, Captain.',0
T_FEA2_009	LABEL	BYTE
	DB	'#FEA2\FEA2_009#I feel like someone is watching us, Captain.',0
T_FEA2N002	LABEL	BYTE
	DB	'#FEA2\FEA2N002#Kirk is wondering what he said that made Quetzeco'
	DB	'atl so angry...',0
T_FEA2N005	LABEL	BYTE
	DB	'#FEA2\FEA2N005#Spock is examining the surrounding terrain for si'
	DB	'gns of danger. Anything else would be illogical.',0
T_FEA2N004	LABEL	BYTE
	DB	'#FEA2\FEA2N004#McCoy is filled with premonitions of injury and d'
	DB	'eath. Why else would they have brought him along?',0
T_FEA2N003	LABEL	BYTE
	DB	'#FEA2\FEA2N003#Lt. Stragey appears fascinated by the vines hangi'
	DB	'ng from the trees.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
