; FEATHER4.RDF - "The Feathered Serpent", a dark forest path past
; Tlaoxac (room 3), towards the river. Nothing to do but look around:
; toxic mushrooms, a razor-edged fern, glowing insects.
;
; Objects: 20h eyes, 21h the mushrooms, 22h the fern, 23h-25h the lights.
; Exits: 2 room 3, 3 room 5.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 03E4: the engine reads its bytes
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
	DW	4Ah
rdf_scale_min	LABEL	BYTE
	DW	14h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, -1, 3, 5	; room for each exit
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
	DW	218,161, 147,167	; entrance 2, crew 0
	DW	241,168, 168,178	; entrance 2, crew 1
	DW	233,144, 159,148	; entrance 2, crew 2
	DW	255,157, 191,157	; entrance 2, crew 3
	DW	76,127, 147,167	; entrance 3, crew 0
	DW	71,112, 168,178	; entrance 3, crew 1
	DW	86,100, 159,148	; entrance 3, crew 2
	DW	64,92, 191,157	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0
N_sscanw	LABEL	BYTE
	DB	'sscanw',0
N_mscanw	LABEL	BYTE
	DB	'mscanw',0

rdf_scripts:
; The room starts: the music.
H_00D8:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0105
StartRoom:
	jmp	SHORT L00E9

N_FEA4LOOP	LABEL	BYTE
	DB	'FEA4LOOP',0
L00E9:
	push	OFFSET N_FEA4LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("FEA4LOOP")
	add	sp, 4
	push	1Bh
	push	RC_MUSIC
	SERVICE		; Music(27)
	add	sp, 4
	retf

; The communicator and phasers still don't work.
H_0105:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_0115
UseCommunicator:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA4N008_2
	call	Say
	retf

H_0115:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_0125
StunAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA4_011
	call	Say
	retf

H_0125:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_0135
KillAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA4_011
	call	Say
	retf

; Tricorders.
H_0135:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_013D
	jmp	SHORT SpockScansLights2

H_013D:
	SCRIPT	MSG_USE, IT_STRICOR, 24h, 0, H_0145
SpockScansLights2:
	jmp	SHORT SpockScansLights

H_0145:
	SCRIPT	MSG_USE, IT_STRICOR, 25h, 0, H_0176
SpockScansLights:
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
	mov	bx, OFFSET T_FEA4_010
	call	Say
	retf

H_0176:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_01A7
SpockScansMushrooms:
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
	mov	bx, OFFSET T_FEA4_012
	call	Say
	retf

H_01A7:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_01D8
SpockScansFern:
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
	mov	bx, OFFSET T_FEA4_009
	call	Say
	retf

H_01D8:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_0209
SpockScans:
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
	mov	bx, OFFSET T_FEA4_008
	call	Say
	retf

H_0209:
	SCRIPT	MSG_USE, IT_MTRICOR, 23h, 0, H_0211
	jmp	SHORT McCoyScansLights2

H_0211:
	SCRIPT	MSG_USE, IT_MTRICOR, 24h, 0, H_0219
McCoyScansLights2:
	jmp	SHORT McCoyScansLights

H_0219:
	SCRIPT	MSG_USE, IT_MTRICOR, 25h, 0, H_024A
McCoyScansLights:
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
	mov	bx, OFFSET T_FEA4_001
	call	Say
	retf

H_024A:
	SCRIPT	MSG_USE, IT_MTRICOR, 21h, 0, H_027B
McCoyScansMushrooms:
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
	mov	bx, OFFSET T_FEA4_003
	call	Say
	retf

H_027B:
	SCRIPT	MSG_USE, IT_MTRICOR, ANY, 0, H_02AC
McCoyScans:
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
	mov	bx, OFFSET T_FEA4_006
	call	Say
	retf

; The medkit, talking and looking.
H_02AC:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, H_030F
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA4_002
	call	Say
	retf

T_FEA4_002	LABEL	BYTE
	DB	'#FEA4\FEA4_002#Everyone is healthy, Jim, there''s no need for the'
	DB	' medical kit here.',0

H_030F:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_031F
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA4_004
	call	Say
	retf

H_031F:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_032F
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA4_007
	call	Say
	retf

H_032F:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_033F
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Stragey
	mov	bx, OFFSET T_FEA4_013
	call	Say
	retf

H_033F:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_034E
LookAtEyes:
	sub	ax, ax
	mov	bx, OFFSET T_FEA4N003
	call	Say
	retf

H_034E:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_035D
LookAtScene:
	sub	ax, ax
	mov	bx, OFFSET T_FEA4N008
	call	Say
	retf

H_035D:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_036C
LookAtMushrooms:
	sub	ax, ax
	mov	bx, OFFSET T_FEA4N001
	call	Say
	retf

H_036C:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_037B
LookAtFern:
	sub	ax, ax
	mov	bx, OFFSET T_FEA4N000
	call	Say
	retf

H_037B:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_038A
LookAtLight1:
	sub	ax, ax
	mov	bx, OFFSET T_FEA4N002
	call	Say
	retf

H_038A:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_0399
LookAtLight2:
	sub	ax, ax
	mov	bx, OFFSET T_FEA4N002
	call	Say
	retf

H_0399:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_03A8
LookAtLight3:
	sub	ax, ax
	mov	bx, OFFSET T_FEA4N002
	call	Say
	retf

H_03A8:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_03B7
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_FEA4N004
	call	Say
	retf

H_03B7:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_03C6
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_FEA4N007
	call	Say
	retf

H_03C6:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_03D5
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_FEA4N006
	call	Say
	retf

H_03D5:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, Talk
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_FEA4N005
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
	DW	70,54, 80,54, 80,61, 70,61
	DW	21h, 4	; id, points
	DW	95,133, 112,121, 127,140, 106,150
	DW	22h, 4	; id, points
	DW	123,150, 143,152, 142,165, 122,164
	DW	23h, 4	; id, points
	DW	173,70, 187,70, 187,83, 173,83
	DW	24h, 4	; id, points
	DW	50,72, 57,72, 57,78, 50,78
	DW	25h, 4	; id, points
	DW	78,76, 84,76, 84,80, 78,80
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	2, 4	; id, points
	DW	270,130, 290,130, 290,199, 270,199
	DW	3, 4	; id, points
	DW	50,80, 100,80, 100,100, 50,100
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's5r4l1',0
	DB	's5r4l2',0
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
	DB	0
T_FEA4N001	LABEL	BYTE
	DB	'#FEA4\FEA4N001#Below this rock is a large growth of mushrooms.',0
T_FEA4N000	LABEL	BYTE
	DB	'#FEA4\FEA4N000#A large fern fans the pathway.',0
T_FEA4N002	LABEL	BYTE
	DB	'#FEA4\FEA4N002#Familiar glowing spheres light the path.',0
T_FEA4N003	LABEL	BYTE
	DB	'#FEA4\FEA4N003#Feral red eyes glare out of the dark at you.',0
T_FEA4N008	LABEL	BYTE
	DB	'#FEA4\FEA4N008#You are in a dark forest. You can hear the flow o'
	DB	'f water to the northwest.',0
T_FEA4N008_2	LABEL	BYTE
	DB	'#FEA4\FEA4N008#Still out, Jim.',0
T_FEA4_011	LABEL	BYTE
	DB	'#FEA4\FEA4_011#They are not currently operational, Captain.',0
T_FEA4_008	LABEL	BYTE
	DB	'#FEA4\FEA4_008#I am reading a life form to the west, Captain.',0
T_FEA4_006	LABEL	BYTE
	DB	'#FEA4\FEA4_006#You''re looking a little pale, Jim.',0
T_FEA4_004	LABEL	BYTE
	DB	'#FEA4\FEA4_004#It''s getting a little cool out here. Keep warm. I'
	DB	' don''t want a bunch of sick crewmen when we get back to the ship'
	DB	'. If we ever do get back to the ship.',0
T_FEA4_007	LABEL	BYTE
	DB	'#FEA4\FEA4_007#Fascinating. The trees are able to grow very clos'
	DB	'e together in this forest, Captain.',0
T_FEA4N004	LABEL	BYTE
	DB	'#FEA4\FEA4N004#James T. Kirk realizes that every step increases '
	DB	'their danger.',0
T_FEA4N007	LABEL	BYTE
	DB	'#FEA4\FEA4N007#Mr. Spock analyzes the surroundings.',0
T_FEA4N006	LABEL	BYTE
	DB	'#FEA4\FEA4N006#McCoy doesn''t want to be bothered right now.',0
T_FEA4N005	LABEL	BYTE
	DB	'#FEA4\FEA4N005#Lt. Stragey smiles as he strolls down the path.',0
T_FEA4_013	LABEL	BYTE
	DB	'#FEA4\FEA4_013#Does every planetside mission have this much adve'
	DB	'nture, Captain? Mind you, I can''t say Mr. Quetzecoatl is making '
	DB	'a very good impression on me...',0
T_FEA4_010	LABEL	BYTE
	DB	'#FEA4\FEA4_010#Small colonies of bio-luminescent insects, Captai'
	DB	'n.',0
T_FEA4_001	LABEL	BYTE
	DB	'#FEA4\FEA4_001#A swarm of fireflies, Jim.',0
T_FEA4_012	LABEL	BYTE
	DB	'#FEA4\FEA4_012#Tralxacian mushrooms. Their spores are highly tox'
	DB	'ic and are released if they are disturbed.',0
T_FEA4_003	LABEL	BYTE
	DB	'#FEA4\FEA4_003#I would strongly recommend against touching these'
	DB	', Jim. They are highly toxic.',0
T_FEA4_009	LABEL	BYTE
	DB	'#FEA4\FEA4_009#It vaguely resembles the Terran Spanish Bayonette'
	DB	'. The edges of the leaf are razor sharp and secrete a poisonous '
	DB	'resin.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
