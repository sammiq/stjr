; DEMON2.RDF - "Demon World", the mine entrance on Mount Idyll. Laraxian
; berries grow here: the cure for Brother Chub (room 5) is made from them.
;
; Objects: 20h, 27h the mine entrance, 21h/22h the mountain, 23h the berry
; bushes, 24h a fern, 25h the moss, 26h the tunnel lights.
; Exits: 0 into the mine (room 3), 1 back down the path (room 1).
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
came_from	EQU	RS_VARS+11h	; 1: from the colony, 2: from the mine; which way the crew face
cured_chub	EQU	RS_VARS+14h	; Brother Chub has had the Hypo-Dytoxin
need_berries	EQU	RS_VARS+16h	; McCoy knows the cure needs the berries
got_berries	EQU	RS_VARS+27h
made_hypo	EQU	RS_VARS+28h	; McCoy has made the Hypo-Dytoxin
score	EQU	RS_VARS+2Fh	; word: the mission's score

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0A0h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	57h
rdf_scale_min	LABEL	BYTE
	DW	46h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	3, 1, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	135,89, 160,145	; entrance 0, crew 0
	DW	135,89, 125,133	; entrance 0, crew 1
	DW	135,89, 159,131	; entrance 0, crew 2
	DW	135,89, 137,126	; entrance 0, crew 3
	DW	180,185, 168,143	; entrance 1, crew 0
	DW	180,185, 161,154	; entrance 1, crew 1
	DW	180,185, 197,155	; entrance 1, crew 2
	DW	180,185, 184,160	; entrance 1, crew 3
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
	DW	0,0, 0,0, 0,0, 0,0
N_kusehe	LABEL	BYTE
	DB	'kusehe',0
	DB	'mscann',0
N_mscane	LABEL	BYTE
	DB	'mscane',0
N_sscann	LABEL	BYTE
	DB	'sscann',0
N_sscane	LABEL	BYTE
	DB	'sscane',0

rdf_scripts:
; The room starts: the ambient sound.
H_00ED:
	SCRIPT	MSG_TICK, 1, 0, 0, H_010E
StartRoom:
	jmp	SHORT L00FE

N_DEM2LOOP	LABEL	BYTE
	DB	'DEM2LOOP',0
L00FE:
	push	OFFSET N_DEM2LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("DEM2LOOP")
	add	sp, 4
	retf

; Clicking the mine entrance: walk in (msg 2), then on to room 3.
H_010E:
	SCRIPT	MSG_WALK, 27h, 0, 0, H_0128
WalkIntoMine:
	push	2
	push	5Ch
	push	83h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 131, 92, 2)
	add	sp, 0Ah
	retf

H_0128:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_013D
EnterMine:
	push	1
	push	3
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(3, 1)
	add	sp, 6
	retf

; Leaving down the path: the engine does the rest (RS_MORE).
H_013D:
	SCRIPT	MSG_EXIT, 1, 0, 0, H_014C
ExitDownPath:
	mov	byte ptr [si+came_from], 2
	mov	byte ptr [si+RS_MORE], 1
	retf

; Looking at things.
H_014C:
	SCRIPT	MSG_LOOK, 27h, 0, 0, H_0154
	jmp	SHORT LookAtEntrance

H_0154:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_0184
LookAtEntrance:
	mov	ax, 0
	mov	bx, OFFSET T_DEM2N009
	call	Say
	jmp	SHORT L0183

T_DEM2N009	LABEL	BYTE
	DB	'#DEM2\DEM2N009#Mine entrance.',0
L0183:
	retf

H_0184:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_01B5
LookAtMountain:
	mov	ax, 0
	mov	bx, OFFSET T_DEM2N007
	call	Say
	jmp	SHORT L01B4

T_DEM2N007	LABEL	BYTE
	DB	'#DEM2\DEM2N007#Idyll Mountain.',0
L01B4:
	retf

H_01B5:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_01E6
LookAtMountain2:
	mov	ax, 0
	mov	bx, OFFSET T_DEM2N008
	call	Say
	jmp	SHORT L01E5

T_DEM2N008	LABEL	BYTE
	DB	'#DEM2\DEM2N008#Idyll Mountain.',0
L01E5:
	retf

H_01E6:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_0239
LookAtBerries:
	mov	ax, 0
	mov	bx, OFFSET T_DEM2N012
	call	Say
	jmp	SHORT L0238

T_DEM2N012	LABEL	BYTE
	DB	'#DEM2\DEM2N012#Various types of berries grow amongst the bushes.',0
L0238:
	retf

H_0239:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_026C
LookAtFern:
	mov	ax, 0
	mov	bx, OFFSET T_DEM2N005
	call	Say
	jmp	SHORT L026B

T_DEM2N005	LABEL	BYTE
	DB	'#DEM2\DEM2N005#A Gindorian fern.',0
L026B:
	retf

H_026C:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_02B5
LookAtMoss:
	mov	ax, 0
	mov	bx, OFFSET T_DEM2N010
	call	Say
	jmp	SHORT L02B4

T_DEM2N010	LABEL	BYTE
	DB	'#DEM2\DEM2N010#Phequedian moss grows on the cave wall.',0
L02B4:
	retf

H_02B5:
	SCRIPT	MSG_LOOK, 26h, 0, 0, H_0300
LookAtLights:
	mov	ax, 0
	mov	bx, OFFSET T_DEM2N006
	call	Say
	jmp	SHORT L02FF

T_DEM2N006	LABEL	BYTE
	DB	'#DEM2\DEM2N006#Feeble lights illuminate the mine tunnel.',0
L02FF:
	retf

H_0300:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_034F
LookAtScene:
	mov	ax, 0
	mov	bx, OFFSET T_DEM2N011
	call	Say
	jmp	SHORT L034E

T_DEM2N011	LABEL	BYTE
	DB	'#DEM2\DEM2N011#The mine entrance goes deep into Mount Idyll.',0
L034E:
	retf

H_034F:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_035E
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_DEM2N002
	call	Say
	retf

H_035E:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_036D
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_DEM2N004
	call	Say
	retf

H_036D:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_037C
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_DEM2N003
	call	Say
	retf

H_037C:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_038B
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_DEM2N000
	call	Say
	retf

; Talking to the crew.
H_038B:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_039B
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM2_001
	call	Say
	retf

H_039B:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_03B4
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM2_018
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM2_003
	call	Say
	retf

H_03B4:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_03D6
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM2_015
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM2_017
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM2_016
	call	Say
	retf

H_03D6:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0401
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM2_019
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM2_002
	call	Say
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM2_020
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM2_004
	call	Say
	retf

; Phasers and tricorders. What McCoy says about the berries depends on
; how far the cure has got.
H_0401:
	SCRIPT	MSG_USE, IT_PHASERK, 23h, 0, H_0409
	jmp	SHORT PhaserBerries

H_0409:
	SCRIPT	MSG_USE, IT_PHASERS, 23h, 0, H_0457
PhaserBerries:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM2_011
	call	Say
	jmp	SHORT L0456

T_DEM2_011	LABEL	BYTE
	DB	'#DEM2\DEM2_011#Jim, you usually pick food and then cook it.',0
L0456:
	retf

H_0457:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_0506
SpockScansBerries:
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
	mov	bx, OFFSET T_DEM2_008
	call	Say
	jmp	SHORT L0505

T_DEM2_008	LABEL	BYTE
	DB	'#DEM2\DEM2_008#These seem to be Laraxian berries, Captain. They '
	DB	'have several medicinal uses, but Dr. McCoy would know more.',0
L0505:
	retf

H_0506:
	SCRIPT	MSG_USE, IT_STRICOR, 25h, 0, H_0588
SpockScansMoss:
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
	mov	bx, OFFSET T_DEM2_007
	call	Say
	jmp	SHORT L0587

T_DEM2_007	LABEL	BYTE
	DB	'#DEM2\DEM2_007#The Phequedine moss extracts nourishment from haf'
	DB	'nium, Captain.',0
L0587:
	retf

H_0588:
	SCRIPT	MSG_USE, IT_STRICOR, 24h, 0, H_060A
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
	mov	bx, OFFSET T_DEM2_006
	call	Say
	jmp	SHORT L0609

T_DEM2_006	LABEL	BYTE
	DB	'#DEM2\DEM2_006#Gindorian ferns are regarded as an intergalactic '
	DB	'weed, Captain.',0
L0609:
	retf

H_060A:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_0612
	jmp	SHORT SpockScansMountain

H_0612:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_061A
SpockScansMountain:
	jmp	SHORT SpockScansMountain2

H_061A:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_070D
SpockScansMountain2:
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
	mov	bx, OFFSET T_DEM2_005
	call	Say
	JMPN	L070C

T_DEM2_005	LABEL	BYTE
	DB	'#DEM2\DEM2_005#Captain, I''m having trouble getting reliable read'
	DB	'ings from inside the mountain. Unusual crystalline structures wi'
	DB	'thin the ore may be at fault, though I cannot say for certain.',0
L070C:
	retf

H_070D:
	SCRIPT	MSG_USE, OBJ_MCCOY, 23h, 0, H_0715
	jmp	SHORT McCoyScansBerries

H_0715:
	SCRIPT	MSG_USE, IT_MTRICOR, 23h, 0, H_0939
McCoyScansBerries:
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
	cmp	byte ptr [si+cured_chub], 1
	jne	L079A
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM2_013
	call	Say
	jmp	SHORT L0799

T_DEM2_013	LABEL	BYTE
	DB	'#DEM2\DEM2_013#These are the Laraxian Berries we used to cure Br'
	DB	'other Chub.',0
L0799:
	retf

L079A:
	cmp	byte ptr [si+made_hypo], 1
	jne	L0802
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM2_009
	call	Say
	jmp	SHORT L0801

T_DEM2_009	LABEL	BYTE
	DB	'#DEM2\DEM2_009#Jim, these are Laraxian Berries that we used to m'
	DB	'ake the Hypo-Dytoxin.',0
L0801:
	retf

L0802:
	cmp	byte ptr [si+need_berries], 1
	je	L080B
	JMPN	L0898

L080B:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM2_010
	call	Say
	JMPN	L0897

T_DEM2_010	LABEL	BYTE
	DB	'#DEM2\DEM2_010#Jim, these are the berries we need to synthesize '
	DB	'the Hypo-Dytoxin. We must get these to Brother Stephen quickly.',0
L0897:
	retf

L0898:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM2_012
	call	Say
	JMPN	L0938

T_DEM2_012	LABEL	BYTE
	DB	'#DEM2\DEM2_012#These are Laraxian Berries. From what I remember,'
	DB	' certain chemical compounds in the berry can be used to treat Nu'
	DB	'gaireyn infections.',0
L0938:
	retf

; Getting the berries, once: walk there (msg 1), reach (anim msg 1),
; +1 score.
H_0939:
	SCRIPT	MSG_GET, 23h, 0, 0, H_099A
GetBerries:
	cmp	byte ptr [si+got_berries], 1
	jne	L0985
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM2_014
	call	Say
	jmp	SHORT L0984

T_DEM2_014	LABEL	BYTE
	DB	'#DEM2\DEM2_014#We don''t need any more berries, Jim.',0
L0984:
	retf

L0985:
	push	1
	push	97h
	push	0E8h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 232, 151, 1)
	add	sp, 0Ah
	retf

H_099A:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_09D0
ReachBerries:
	push	1
	push	-1
	push	-1
	push	OFFSET N_kusehe
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehe", -1, -1, 1)
	add	sp, 0Ch
	jmp	SHORT L09C0

N_PIKBERRY	LABEL	BYTE
	DB	'PIKBERRY',0
L09C0:
	push	OFFSET N_PIKBERRY
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("PIKBERRY")
	add	sp, 4
	retf

H_09D0:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, rdf_scripts_end
PickBerries:
	mov	ax, 0
	mov	bx, OFFSET T_DEM2N013
	call	Say
	jmp	SHORT L0A18

T_DEM2N013	LABEL	BYTE
	DB	'#DEM2\DEM2N013#You have retrieved a sample of berries.',0
L0A18:
	push	IT_BERRY
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_BERRY)
	add	sp, 4
	mov	byte ptr [si+got_berries], 1
	add	word ptr [si+score], 1
	retf

rdf_scripts_end	LABEL	BYTE
rdf_objects	LABEL	BYTE
	DW	27h, 4	; id, points
	DW	124,67, 150,67, 150,90, 124,90
	DW	23h, 4	; id, points
	DW	211,71, 281,71, 281,110, 211,110
	DW	24h, 4	; id, points
	DW	196,111, 285,111, 285,161, 196,161
	DW	24h, 4	; id, points
	DW	20,91, 123,91, 123,161, 20,161
	DW	25h, 4	; id, points
	DW	38,27, 76,27, 76,90, 38,90
	DW	26h, 4	; id, points
	DW	116,43, 134,43, 134,60, 16,60
	DW	26h, 4	; id, points
	DW	127,61, 139,61, 139,75, 127,75
	DW	20h, 6	; id, points
	DW	100,144, 103,46, 134,16, 167,16, 187,54, 180,144
	DW	21h, 4	; id, points
	DW	20,14, 100,15, 94,93, 20,95
	DW	22h, 4	; id, points
	DW	184,14, 285,14, 285,70, 217,67
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	0, 4	; id, points
	DW	123,93, 136,93, 136,97, 123,97
	DW	1, 4	; id, points
	DW	85,162, 285,162, 285,182, 85,182
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's0r2l1',0
rdf_bans_end:
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

N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Ensign_Everts	LABEL	BYTE
	DB	'Ensign Everts',0
T_DEM2N002	LABEL	BYTE
	DB	'#DEM2\DEM2N002#James T. Kirk. Always wondering what the next sur'
	DB	'prise will be.',0
T_DEM2N004	LABEL	BYTE
	DB	'#DEM2\DEM2N004#Spock. Perhaps the most brilliant mind in Starfle'
	DB	'et, pondering a most peculiar mystery.',0
T_DEM2N003	LABEL	BYTE
	DB	'#DEM2\DEM2N003#Leonard McCoy. Hoping that the cave will be warme'
	DB	'r than outside.',0
T_DEM2N000	LABEL	BYTE
	DB	'#DEM2\DEM2N000#Ensign Everts. Keeping a sharp eye out for anythi'
	DB	'ng dangerous.',0
T_DEM2_001	LABEL	BYTE
	DB	'#DEM2\DEM2_001#The answer to this mystery lies ahead of us, gent'
	DB	'lemen.',0
T_DEM2_015	LABEL	BYTE
	DB	'#DEM2\DEM2_015#Does your tricorder say the cave is warmer, Spock'
	DB	'...',0
T_DEM2_017	LABEL	BYTE
	DB	'#DEM2\DEM2_017#It is not logical for me to use my tricorder to d'
	DB	'etermine the cave''s temperature, doctor. I do not see what purpo'
	DB	'se it would serve.',0
T_DEM2_016	LABEL	BYTE
	DB	'#DEM2\DEM2_016#Spock, everybody talks about the weather!',0
T_DEM2_019	LABEL	BYTE
	DB	'#DEM2\DEM2_019#I''m sorry I let you down with those Klingons back'
	DB	' there. I should have been paying more attention.',0
T_DEM2_002	LABEL	BYTE
	DB	'#DEM2\DEM2_002#Just don''t make that mistake again, Ensign.',0
T_DEM2_020	LABEL	BYTE
	DB	'#DEM2\DEM2_020#Those Klingons give me the willies. They always h'
	DB	'ave. My sister was wounded by them in the Chozon ambush.',0
T_DEM2_004	LABEL	BYTE
	DB	'#DEM2\DEM2_004#We''ve all had our share of conflict with Klingons'
	DB	', Ensign. The Organians told me that one day Humans and Klingons'
	DB	' will become good friends. I wonder if I''ll ever live to see tha'
	DB	't day.',0
T_DEM2_018	LABEL	BYTE
	DB	'#DEM2\DEM2_018#Whoever was trying to stop us may not stop with t'
	DB	'hose Klingons, Captain. I recommend extreme caution.',0
T_DEM2_003	LABEL	BYTE
	DB	'#DEM2\DEM2_003#The thought had occurred to me, Mr. Spock, but th'
	DB	'ank you for mentioning it.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
