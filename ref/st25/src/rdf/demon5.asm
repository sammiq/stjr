; DEMON5.RDF - "Demon World", the chapel, where the colonists who met the
; demons wait: Brother Roberts, Brother Chub (injured by them), Brother
; Grisnash the Tellarite, and Brother Stephen. McCoy examines them all;
; Chub needs a Hypo-Dytoxin made from Laraxian berries (room 2, made in
; room 6), and giving it to him cures him.
;
; Actors: 8 Brother Roberts, 9 Brother Chub, 10 (0Ah) Brother Grisnash,
; 11 (0Bh) Brother Stephen, 12 (0Ch) the door.
; Objects: 8-0Bh the brothers, 0Ch/22h the door, 20h the skylight,
; 21h the supplies.
; Region 0: the doorstep. The door leads back to the colony (room 0).
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 0CF8: the engine reads its bytes
;   as key 50 B8 03 00 and next 2E50 (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
saw_klingons	EQU	RS_VARS+0Eh	; the Klingons have appeared (room 1)
hand_repaired	EQU	RS_VARS+12h	; set in room 6
cured_chub	EQU	RS_VARS+14h	; Brother Chub has had the Hypo-Dytoxin
examined_chub	EQU	RS_VARS+15h
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
	DW	0C7h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	93h
rdf_scale_min	LABEL	BYTE
	DW	0D2h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	0, -1, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	160,148, 179,175	; entrance 0, crew 0
	DW	160,148, 131,164	; entrance 0, crew 1
	DW	160,148, 200,186	; entrance 0, crew 2
	DW	160,148, 228,153	; entrance 0, crew 3
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
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0
; In the room file, so these start again each time the room loads
scanned_roberts	LABEL	BYTE	; McCoy has examined each brother
	DB	0
scanned_chub	LABEL	BYTE
	DB	0
scanned_grisnash	LABEL	BYTE
	DB	0
scanned_stephen	LABEL	BYTE
	DB	0
scans	LABEL	BYTE	; how many brothers McCoy has examined
	DB	0
talks	LABEL	BYTE	; how many brothers Kirk has talked to; 5: McCoy has given his verdict
	DB	0
talked_roberts	LABEL	BYTE
	DB	0
talked_chub	LABEL	BYTE
	DB	0
talked_grisnash	LABEL	BYTE
	DB	0
talked_stephen	LABEL	BYTE
	DB	0
door_steps	LABEL	BYTE	; the walk and the door have both finished at 2
	DB	0
going_out	LABEL	BYTE	; Kirk is on his way to the door
	DB	0
N_oldman	LABEL	BYTE
	DB	'oldman',0
N_brorob	LABEL	BYTE
	DB	'brorob',0
N_crip	LABEL	BYTE
	DB	'crip',0
N_brotel	LABEL	BYTE
	DB	'brotel',0
N_s0r6d1	LABEL	BYTE
	DB	's0r6d1',0
N_s0r6d2	LABEL	BYTE
	DB	's0r6d2',0
N_musemn	LABEL	BYTE
	DB	'musemn',0
N_sscans	LABEL	BYTE
	DB	'sscans',0
	DB	'mscann',0
N_mscane	LABEL	BYTE
	DB	'mscane',0
N_mscanw	LABEL	BYTE
	DB	'mscanw',0

rdf_scripts:
; The room starts: the brothers (Stephen only until Chub is cured and
; the Klingons have been met) and the door.
H_0121:
	SCRIPT	MSG_TICK, 1, 0, 0, H_01C0
StartRoom:
	jmp	SHORT L0132

N_DEM5LOOP	LABEL	BYTE
	DB	'DEM5LOOP',0
L0132:
	push	OFFSET N_DEM5LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("DEM5LOOP")
	add	sp, 4
	cmp	byte ptr [si+cured_chub], 0
	je	L014D
	cmp	byte ptr [si+saw_klingons], 1
	je	L0163
L014D:
	push	0
	push	0B0h
	push	7Ah
	push	OFFSET N_oldman
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, "oldman", 122, 176, 0)
	add	sp, 0Ch
L0163:
	push	0
	push	0A8h
	push	0C9h
	push	OFFSET N_brorob
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "brorob", 201, 168, 0)
	add	sp, 0Ch
	push	0
	push	0A8h
	push	0E3h
	push	OFFSET N_crip
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "crip", 227, 168, 0)
	add	sp, 0Ch
	push	0
	push	0BCh
	push	0F9h
	push	OFFSET N_brotel
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "brotel", 249, 188, 0)
	add	sp, 0Ch
	push	0
	push	92h
	push	0A0h
	push	OFFSET N_s0r6d2
	push	0Ch
	push	RC_ANIM0
	SERVICE		; Anim0(12, "s0r6d2", 160, 146, 0)
	add	sp, 0Ch
	retf

; Leaving: walk to the door (msg 1); at the doorstep it opens (anim
; msg 1), and when both are done, back to the colony.
H_01C0:
	SCRIPT	MSG_WALK, 22h, 0, 0, H_01C8
	jmp	SHORT WalkToDoor

H_01C8:
	SCRIPT	MSG_WALK, 0Ch, 0, 0, H_01ED
WalkToDoor:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr cs:going_out, 1
	push	1
	push	94h
	push	0A0h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 160, 148, 1)
	add	sp, 0Ah
	retf

H_01ED:
	SCRIPT	MSG_REGION, 0, 0, 0, H_021F
ReachDoor:
	cmp	byte ptr cs:going_out, 1
	jne	L021E
	push	1
	push	92h
	push	0A0h
	push	OFFSET N_s0r6d1
	push	0Ch
	push	RC_ANIM0
	SERVICE		; Anim0(12, "s0r6d1", 160, 146, 1)
	add	sp, 0Ch
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
L021E:
	retf

H_021F:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_0227
	jmp	SHORT GoOut

H_0227:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_024A
GoOut:
	inc	byte ptr cs:door_steps
	cmp	byte ptr cs:door_steps, 2
	je	L023B
	retf

L023B:
	push	1
	push	0
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(0, 1)
	add	sp, 6
	retf

; Spock's tricorder, and phasers.
H_024A:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_02CD
SpockScansSupplies:
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
	mov	bx, OFFSET T_DEM5_006
	call	Say
	jmp	SHORT L02CC

T_DEM5_006	LABEL	BYTE
	DB	'#DEM5\DEM5_006#I detect various pieces of mining equipment but n'
	DB	'othing of note.',0
L02CC:
	retf

H_02CD:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_02D5
	jmp	SHORT PhaserColonist

H_02D5:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_036C
PhaserColonist:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM5_007
	call	Say
	JMPN	L036B

T_DEM5_007	LABEL	BYTE
	DB	'#DEM5\DEM5_007#May I suggest using a more diplomatic approach to'
	DB	' questioning the colonists. Force will gain us little, if anythi'
	DB	'ng.',0
L036B:
	retf

; Showing Brother Stephen the hand and the berries.
H_036C:
	SCRIPT	MSG_USE, IT_HAND, 0Bh, 0, H_046C
ShowHandToStephen:
	cmp	byte ptr [si+hand_repaired], 1
	jne	L037B
	JMPN	L042D

L037B:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM5_039
	call	Say
	JMPN	L042C

T_DEM5_039	LABEL	BYTE
	DB	'#DEM5\DEM5_039#What an interesting artifact. Hmmm... It appears '
	DB	'to have been damaged. When you have a chance, take it to my lab '
	DB	'and we''ll see if it can be repaired.',0
L042C:
	retf

L042D:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM5_036
	call	Say
	jmp	SHORT L046B

T_DEM5_036	LABEL	BYTE
	DB	'#DEM5\DEM5_036#That''s very nice, but I''m busy now.',0
L046B:
	retf

H_046C:
	SCRIPT	MSG_USE, IT_BERRY, 0Bh, 0, H_052F
ShowBerriesToStephen:
	cmp	byte ptr [si+need_berries], 1
	jne	L04D3
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM5_033
	call	Say
	jmp	SHORT L04D2

T_DEM5_033	LABEL	BYTE
	DB	'#DEM5\DEM5_033#Good, you have found the berries. Bring them to m'
	DB	'y lab quickly.',0
L04D2:
	retf

L04D3:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM5_037
	call	Say
	jmp	SHORT L052E

T_DEM5_037	LABEL	BYTE
	DB	'#DEM5\DEM5_037#Those are Laraxian berries. They grow wild by the'
	DB	' mine entrance.',0
L052E:
	retf

; McCoy gives Chub the Hypo-Dytoxin (msgs 2): +2 score.
H_052F:
	SCRIPT	MSG_USE, IT_DETOXIN, 9, 0, H_054A
GiveHypoToChub:
	push	2
	push	0B0h
	push	0E1h
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 225, 176, 2)
	add	sp, 0Ah
	retf

H_054A:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_0566
McCoyAtChub:
	push	2
	push	-1
	push	-1
	push	OFFSET N_musemn
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musemn", -1, -1, 2)
	add	sp, 0Ch
	retf

H_0566:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_05D1
ChubCured:
	push	0
	push	0BAh
	push	0C8h
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 200, 186, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+2], 3
	mov	ax, OFFSET N_Brother_Chub
	mov	bx, OFFSET T_DEM5L027
	call	Say
	jmp	SHORT L05BC

T_DEM5L027	LABEL	BYTE
	DB	'#DEM5\DEM5L027#Thank you. You are most kind.',0
L05BC:
	push	IT_DETOXIN
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_DETOXIN)
	add	sp, 4
	mov	byte ptr [si+cured_chub], 1
	add	word ptr [si+score], 2
	retf

; The Hypo-Dytoxin or the raw berries elsewhere.
H_05D1:
	SCRIPT	MSG_USE, IT_DETOXIN, ANY, 0, H_060E
GiveHypo:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM5_008
	call	Say
	jmp	SHORT L060D

T_DEM5_008	LABEL	BYTE
	DB	'#DEM5\DEM5_008#Jim, that wouldn''t be wise.',0
L060D:
	retf

H_060E:
	SCRIPT	MSG_USE, IT_BERRY, 9, 0, H_0656
GiveBerriesToChub:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM5_009
	call	Say
	jmp	SHORT L0655

T_DEM5_009	LABEL	BYTE
	DB	'#DEM5\DEM5_009#Jim, these need to be processed first!',0
L0655:
	retf

; Looking at things.
H_0656:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_0665
LookAtRoberts:
	sub	ax, ax
	mov	bx, OFFSET T_DEM5N001
	call	Say
	retf

H_0665:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_0674
LookAtGrisnash:
	sub	ax, ax
	mov	bx, OFFSET T_DEM5N009
	call	Say
	retf

H_0674:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_0683
LookAtStephen:
	sub	ax, ax
	mov	bx, OFFSET T_DEM5N003
	call	Say
	retf

H_0683:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_0692
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_DEM5N006
	call	Say
	retf

H_0692:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_06A1
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_DEM5N008
	call	Say
	retf

H_06A1:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_06B0
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_DEM5N007
	call	Say
	retf

H_06B0:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_06BF
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_DEM5N005
	call	Say
	retf

H_06BF:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_06CE
LookAtSkylight:
	sub	ax, ax
	mov	bx, OFFSET T_DEM5N002
	call	Say
	retf

H_06CE:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_06DD
LookAtSupplies:
	sub	ax, ax
	mov	bx, OFFSET T_DEM5N004
	call	Say
	retf

H_06DD:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_06EC
LookAtScene:
	sub	ax, ax
	mov	bx, OFFSET T_DEM5N000
	call	Say
	retf

H_06EC:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_06FC
LookAtChub:
	mov	ax, OFFSET N_Brother_Chub
	mov	bx, OFFSET T_DEM5L028
	call	Say
	retf

; Talking to the brothers: each counts once towards McCoy's verdict.
H_06FC:
	SCRIPT	MSG_TALK, 8, 0, 0, H_076C
TalkToRoberts:
	cmp	byte ptr [si+cured_chub], 1
	je	L074D
	mov	ax, 0
	mov	bx, OFFSET T_DEM5N010
	call	Say
	jmp	SHORT L074C

T_DEM5N010	LABEL	BYTE
	DB	'#DEM5\DEM5N010#He is too busy consoling the wounded man.',0
L074C:
	retf

L074D:
	mov	ax, OFFSET N_Brother_Roberts
	mov	bx, OFFSET T_DEM5_030
	call	Say
	cmp	byte ptr cs:talked_roberts, 1
	je	L0769
	mov	byte ptr cs:talked_roberts, 1
	inc	byte ptr cs:talks
L0769:
	JMPN	L0C9B

H_076C:
	SCRIPT	MSG_TALK, 9, 0, 0, H_07FB
TalkToChub:
	cmp	byte ptr [si+cured_chub], 1
	je	L07B8
	mov	ax, 0
	mov	bx, OFFSET T_DEM5N013
	call	Say
	jmp	SHORT L07B7

T_DEM5N013	LABEL	BYTE
	DB	'#DEM5\DEM5N013#This man is in no condition to talk.',0
L07B7:
	retf

L07B8:
	mov	ax, OFFSET N_Brother_Chub
	mov	bx, OFFSET T_DEM5L029
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM5_002
	call	Say
	mov	ax, OFFSET N_Brother_Chub
	mov	bx, OFFSET T_DEM5L030
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM5_005
	call	Say
	mov	ax, OFFSET N_Brother_Chub
	mov	bx, OFFSET T_DEM5L031
	call	Say
	cmp	byte ptr cs:talked_chub, 1
	je	L07F8
	mov	byte ptr cs:talked_chub, 1
	inc	byte ptr cs:talks
L07F8:
	JMPN	L0C9B

H_07FB:
	SCRIPT	MSG_TALK, 0Ah, 0, 0, H_0886
TalkToGrisnash:
	cmp	byte ptr [si+cured_chub], 1
	je	L084C
	mov	ax, 0
	mov	bx, OFFSET T_DEM5N011
	call	Say
	jmp	SHORT L084B

T_DEM5N011	LABEL	BYTE
	DB	'#DEM5\DEM5N011#He is too busy consoling the wounded man.',0
L084B:
	retf

L084C:
	mov	ax, OFFSET N_Brother_Grisnash
	mov	bx, OFFSET T_DEM5_028
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM5_024
	call	Say
	mov	ax, OFFSET N_Brother_Grisnash
	mov	bx, OFFSET T_DEM5_029
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM5_025
	call	Say
	cmp	byte ptr cs:talked_grisnash, 1
	je	L0883
	mov	byte ptr cs:talked_grisnash, 1
	inc	byte ptr cs:talks
L0883:
	JMPN	L0C9B

H_0886:
	SCRIPT	MSG_TALK, 0Bh, 0, 0, H_0A49
TalkToStephen:
	cmp	byte ptr [si+cured_chub], 1
	jne	L0895
	JMPN	L0A06

L0895:
	cmp	byte ptr [si+need_berries], 1
	je	L089E
	JMPN	L09AD

L089E:
	cmp	byte ptr [si+made_hypo], 1
	jne	L08F3
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM5_035
	call	Say
	jmp	SHORT L08F2

T_DEM5_035	LABEL	BYTE
	DB	'#DEM5\DEM5_035#Please hurry Doctor. Brother Chub is looking wors'
	DB	'e.',0
L08F2:
	retf

L08F3:
	cmp	byte ptr [si+got_berries], 1
	jne	L094D
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM5_032
	call	Say
	jmp	SHORT L0948

T_DEM5_032	LABEL	BYTE
	DB	'#DEM5\DEM5_032#Ahh, I see you found the berries. Meet me in my l'
	DB	'ab.',0
L0948:
	mov	byte ptr [si+examined_chub], 0
	retf

L094D:
	cmp	byte ptr [si+examined_chub], 1
	jne	L09AD
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM5_038
	call	Say
	jmp	SHORT L09AC

T_DEM5_038	LABEL	BYTE
	DB	'#DEM5\DEM5_038#Time is of the essence, you must hurry and retrie'
	DB	've the berry.',0
L09AC:
	retf

L09AD:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM5_034
	call	Say
	jmp	SHORT L0A05

T_DEM5_034	LABEL	BYTE
	DB	'#DEM5\DEM5_034#I am worried about Brother Chub. Can you examine '
	DB	'him, Doctor?',0
L0A05:
	retf

L0A06:
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM5_041
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM5_022
	call	Say
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM5_043
	call	Say
	mov	ax, OFFSET N_Brother_Roberts
	mov	bx, OFFSET T_DEM5_031
	call	Say
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM5_042
	call	Say
	cmp	byte ptr cs:talked_stephen, 1
	je	L0A46
	mov	byte ptr cs:talked_stephen, 1
	inc	byte ptr cs:talks
L0A46:
	JMPN	L0C9B

; Talking to the crew.
H_0A49:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0A59
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM5_001
	call	Say
	retf

H_0A59:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0A72
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM5_027
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM5_018
	call	Say
	retf

H_0A72:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0A94
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM5_045
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM5_021
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM5_003
	call	Say
	retf

H_0A94:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0AE7
TalkToMcCoy:
	cmp	byte ptr [si+cured_chub], 1
	je	L0AAA
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM5_017
	call	Say
	retf

L0AAA:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM5_023
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM5_004
	call	Say
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L0AE6
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM5_044
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM5_020
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM5_026
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM5_019
	call	Say
L0AE6:
	retf

; McCoy examines the brothers, each once. Chub's examination finds the
; need for the berries. When all four have been examined and talked to,
; McCoy finds nothing wrong with any of them.
H_0AE7:
	SCRIPT	MSG_USE, IT_MTRICOR, 8, 0, H_0B2D
McCoyScansRoberts:
	cmp	byte ptr cs:scanned_roberts, 1
	je	L0B2A
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
	mov	bx, OFFSET T_DEM5_015
	call	Say
	mov	byte ptr cs:scanned_roberts, 1
	inc	byte ptr cs:scans
L0B2A:
	JMPN	L0C9B

H_0B2D:
	SCRIPT	MSG_USE, IT_MEDKIT, 9, 0, H_0B35
	jmp	SHORT McCoyHelpsChub

H_0B35:
	SCRIPT	MSG_USE, OBJ_MCCOY, 9, 0, H_0B3D
McCoyHelpsChub:
	jmp	SHORT McCoyScansChub

H_0B3D:
	SCRIPT	MSG_USE, IT_MTRICOR, 9, 0, H_0C13
McCoyScansChub:
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
	jne	L0B6D
	JMPN	L0BF4

L0B6D:
	cmp	byte ptr [si+examined_chub], 1
	jne	L0BD9
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM5_010
	call	Say
	jmp	SHORT L0BD8

T_DEM5_010	LABEL	BYTE
	DB	'#DEM5\DEM5_010#This man is getting worse. We''ve got to find thos'
	DB	'e berries before he dies.',0
L0BD8:
	retf

L0BD9:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM5_012
	call	Say
	mov	ax, OFFSET N_Brother_Stephen
	mov	bx, OFFSET T_DEM5_040
	call	Say
	mov	byte ptr [si+need_berries], 1
	mov	byte ptr [si+examined_chub], 1
	retf

L0BF4:
	cmp	byte ptr cs:scanned_chub, 1
	je	L0C10
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM5_016
	call	Say
	mov	byte ptr cs:scanned_chub, 1
	inc	byte ptr cs:scans
L0C10:
	JMPN	L0C9B

H_0C13:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Ah, 0, H_0C58
McCoyScansGrisnash:
	cmp	byte ptr cs:scanned_grisnash, 1
	je	L0C56
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
	mov	bx, OFFSET T_DEM5_013
	call	Say
	mov	byte ptr cs:scanned_grisnash, 1
	inc	byte ptr cs:scans
L0C56:
	jmp	SHORT L0C9B

H_0C58:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Bh, 0, H_0CBB
McCoyScansStephen:
	cmp	byte ptr cs:scanned_stephen, 1
	je	L0C9B
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
	mov	bx, OFFSET T_DEM5_014
	call	Say
	mov	byte ptr cs:scanned_stephen, 1
	inc	byte ptr cs:scans
L0C9B:
	cmp	byte ptr cs:scans, 4
	jne	L0CBA
	cmp	byte ptr cs:talks, 4
	jne	L0CBA
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM5_011
	call	Say
	mov	byte ptr cs:talks, 5
L0CBA:
	retf

; Getting the supplies.
H_0CBB:
	SCRIPT	MSG_GET, 21h, 0, 0, Talk
GetSupplies:
	mov	ax, 0
	mov	bx, OFFSET T_DEM5N012
	call	Say
	jmp	SHORT L0CF7

T_DEM5N012	LABEL	BYTE
	DB	'#DEM5\DEM5N012#They are too heavy to move.',0
L0CF7:
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
	DW	80,18, 239,18, 238,75, 80,75
	DW	21h, 4	; id, points
	DW	247,139, 261,139, 261,153, 247,139
	DW	21h, 4	; id, points
	DW	262,126, 304,126, 304,153, 262,153
	DW	21h, 4	; id, points
	DW	79,133, 99,133, 99,161, 79,161
	DW	21h, 4	; id, points
	DW	7,98, 78,98, 78,161, 7,161
	DW	21h, 4	; id, points
	DW	0,123, 6,123, 6,161, 0,161
	DW	21h, 4	; id, points
	DW	0,162, 47,162, 47,199, 0,199
	DW	22h, 4	; id, points
	DW	132,145, 185,145, 185,159, 132,159
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	132,145, 185,145, 185,159, 132,159
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Ensign_Everts	LABEL	BYTE
	DB	'Ensign Everts',0
N_Brother_Roberts	LABEL	BYTE
	DB	'Brother Roberts',0
N_Brother_Chub	LABEL	BYTE
	DB	'Brother Chub',0
N_Brother_Grisnash	LABEL	BYTE
	DB	'Brother Grisnash',0
N_Brother_Stephen	LABEL	BYTE
	DB	'Brother Stephen',0
T_DEM5N001	LABEL	BYTE
	DB	'#DEM5\DEM5N001#A grim-faced miner-colonist nods curtly at you.',0
T_DEM5L028	LABEL	BYTE
	DB	'#DEM5\DEM5L028#You''ll understand if I don''t stand up, I hope. I '
	DB	'am not well.',0
T_DEM5N009	LABEL	BYTE
	DB	'#DEM5\DEM5N009#The Tellarite appears completely at home surround'
	DB	'ed by humans, but the wrinkling on his brow indicates a great de'
	DB	'al of worry.',0
T_DEM5N003	LABEL	BYTE
	DB	'#DEM5\DEM5N003#A sturdy man of advanced years, whose blue eyes m'
	DB	'eet yours with clarity, curiosity, and directness.',0
T_DEM5N002	LABEL	BYTE
	DB	'#DEM5\DEM5N002#A majestic view of Mt. Idyll can be seen through '
	DB	'the skylight.',0
T_DEM5N004	LABEL	BYTE
	DB	'#DEM5\DEM5N004#Boxes of supplies and mining equipment litter the'
	DB	' floor.',0
T_DEM5N000	LABEL	BYTE
	DB	'#DEM5\DEM5N000#A chapel typical of the Acolytes of the Stars.',0
T_DEM5N007	LABEL	BYTE
	DB	'#DEM5\DEM5N007#McCoy looks anxiously about the room.',0
T_DEM5N005	LABEL	BYTE
	DB	'#DEM5\DEM5N005#Ensign Everts cannot take his eyes off the sight '
	DB	'of Mount Idyll.',0
T_DEM5N008	LABEL	BYTE
	DB	'#DEM5\DEM5N008#Spock waits for your command, patient as ever.',0
T_DEM5N006	LABEL	BYTE
	DB	'#DEM5\DEM5N006#James Kirk takes time to rest and ponder the rema'
	DB	'inder of the mission.',0
T_DEM5_030	LABEL	BYTE
	DB	'#DEM5\DEM5_030#Brother Kandrey was -- is -- my partner. I was on'
	DB	' the communications link when the demons caused the rockfall and'
	DB	' silenced him.  He said he''d found a strange door with devilish '
	DB	'writing.  Truly he came upon the Gate of Hell itself.',0
T_DEM5L029	LABEL	BYTE
	DB	'#DEM5\DEM5L029#I headed up the party that sought to rescue Broth'
	DB	'er Kandrey. Without warning, the demons appeared and attacked us'
	DB	' as we approached the mine!',0
T_DEM5_002	LABEL	BYTE
	DB	'#DEM5\DEM5_002#Can you tell us what they looked like?',0
T_DEM5L030	LABEL	BYTE
	DB	'#DEM5\DEM5L030#Like the demons that have plagued devout folk sin'
	DB	'ce before our people left the Earth. Huge muscular demons, with '
	DB	'ruddy skin. Truly the manifestation of Evil, with batwings, horn'
	DB	's and talons, and a pointed tail. God preserve us all. One tore '
	DB	'open my arm and I surely would have perished -- but for my compa'
	DB	'nions who bore me back down the mountain.',0
T_DEM5_005	LABEL	BYTE
	DB	'#DEM5\DEM5_005#The demons didn''t follow you?',0
T_DEM5L031	LABEL	BYTE
	DB	'#DEM5\DEM5L031#No.',0
T_DEM5_028	LABEL	BYTE
	DB	'#DEM5\DEM5_028#I am Brother Grisnash. I went up the mountainside'
	DB	' in solitary prayer, seeking to face my fears. Indeed I found th'
	DB	'em.  A bellowing Krognik-demon with sharp teeth and a long snout'
	DB	' descended upon me in a rush of wind.',0
T_DEM5_024	LABEL	BYTE
	DB	'#DEM5\DEM5_024#Captain, a Krognik-demon has a decidedly wolfish '
	DB	'appearance. Brother Grisnash, is this not the traditional shape '
	DB	'of the Evil One and his minions among Tellarites?',0
T_DEM5_029	LABEL	BYTE
	DB	'#DEM5\DEM5_029#It is.',0
T_DEM5_025	LABEL	BYTE
	DB	'#DEM5\DEM5_025#I believe this may be significant, Captain.',0
T_DEM5_041	LABEL	BYTE
	DB	'#DEM5\DEM5_041#I am Brother Stephen, an Ignaciate, following the'
	DB	' holy teachings with mind and soul alike. I believe the anomalou'
	DB	's mineral readings, in combination with evidence of ancient dist'
	DB	'urbances in this otherwise highly stable geologic location indic'
	DB	'ates previous habitation of the region, eons ago.',0
T_DEM5_022	LABEL	BYTE
	DB	'#DEM5\DEM5_022#Why, Spock, you two should get along fine, he sou'
	DB	'nds just like you.',0
T_DEM5_043	LABEL	BYTE
	DB	'#DEM5\DEM5_043#I would be equally honored to discuss medicine wi'
	DB	'th you, Doctor, as science with your Vulcan associate.  Let me c'
	DB	'ontinue. I believe our God made humans, aliens -- and demons all'
	DB	'.  If I could get a real demon into my study, I would bless our '
	DB	'God for the opportunity, as I thank Him for everything in this l'
	DB	'ife.',0
T_DEM5_031	LABEL	BYTE
	DB	'#DEM5\DEM5_031#You tread close to unholy knowledge, Brother Step'
	DB	'hen!',0
T_DEM5_042	LABEL	BYTE
	DB	'#DEM5\DEM5_042#I appreciate your prayers, Brother Roberts. Capta'
	DB	'in, if you and your people go up the mountain, I hope afterward '
	DB	'you will visit me in my study, which is next door. I am too old '
	DB	'to make the trek myself, but I am eager for knowledge. In return'
	DB	', I will offer you what insights our God grants these old eyes.',0
T_DEM5_001	LABEL	BYTE
	DB	'#DEM5\DEM5_001#Just thinking to myself. Don''t mind me.',0
T_DEM5_027	LABEL	BYTE
	DB	'#DEM5\DEM5_027#The medical methods of these people seem primitiv'
	DB	'e to me, doctor.',0
T_DEM5_018	LABEL	BYTE
	DB	'#DEM5\DEM5_018#By our standards yes. Here the Acolytes prefer a '
	DB	'simpler life style; unfortunately, this is one of the consequenc'
	DB	'es.',0
T_DEM5_045	LABEL	BYTE
	DB	'#DEM5\DEM5_045#My uncle John lived with the Acolytes a long time'
	DB	' ago. He died in their service, helping plague victims on New On'
	DB	'tario VI twenty years ago.',0
T_DEM5_021	LABEL	BYTE
	DB	'#DEM5\DEM5_021#The Acolytes did a lot of good work for the needy'
	DB	' in this quadrant.',0
T_DEM5_003	LABEL	BYTE
	DB	'#DEM5\DEM5_003#It will be good to help them for a change.',0
T_DEM5_017	LABEL	BYTE
	DB	'#DEM5\DEM5_017#This man needs help, Jim, and I wouldn''t want to '
	DB	'put it off for too long.',0
T_DEM5_023	LABEL	BYTE
	DB	'#DEM5\DEM5_023#You know Jim, they can take a captain out of a st'
	DB	'arship, and a science officer out of his lab, but you can never '
	DB	'retire a doctor.',0
T_DEM5_004	LABEL	BYTE
	DB	'#DEM5\DEM5_004#Not the good ones, that''s for sure.',0
T_DEM5_044	LABEL	BYTE
	DB	'#DEM5\DEM5_044#My mom wanted me to become a doctor. Honest. But '
	DB	'I hated my biology classes.',0
T_DEM5_020	LABEL	BYTE
	DB	'#DEM5\DEM5_020#So did I, but I became one anyway.',0
T_DEM5_026	LABEL	BYTE
	DB	'#DEM5\DEM5_026#That is not logical, doctor.',0
T_DEM5_019	LABEL	BYTE
	DB	'#DEM5\DEM5_019#Neither were some of my professors.',0
T_DEM5_012	LABEL	BYTE
	DB	'#DEM5\DEM5_012#Jim, this man has suffered severe physical injuri'
	DB	'es to his head and arm. The wounds have been adequately cared fo'
	DB	'r; however, he has developed the Nugaireyn infection. If not tre'
	DB	'ated swiftly, the effects can be fatal. The infection can normal'
	DB	'ly be treated with Hypo-Dytoxin, but there''s none on the Enterpr'
	DB	'ise.',0
T_DEM5_040	LABEL	BYTE
	DB	'#DEM5\DEM5_040#I may be of some assistance. The Laraxian Berry g'
	DB	'rows near the mouth of the cave. If I could acquire it, I would '
	DB	'be able to synthesize the Hypo-Dytoxin from the berry. Unfortuna'
	DB	'tely, the demons prevent us from approaching the cave entrance. '
	DB	'perhaps you could retrieve it for me.',0
T_DEM5_015	LABEL	BYTE
	DB	'#DEM5\DEM5_015#The man seems worried and stressed, but all body '
	DB	'functions appear within normal limits.',0
T_DEM5_016	LABEL	BYTE
	DB	'#DEM5\DEM5_016#This man has recently suffered a nasty but non-li'
	DB	'fe-threatening wound. The damage has been adequately cared for. '
	DB	'The man''s vital effects are attributable to shock and stress.',0
T_DEM5_013	LABEL	BYTE
	DB	'#DEM5\DEM5_013#The alien''s lifesigns seem stress-elevated. Other'
	DB	'wise he appears fundamentally healthy.',0
T_DEM5_014	LABEL	BYTE
	DB	'#DEM5\DEM5_014#The man is suffering moderately from the effects '
	DB	'of his age, but seems healthy, alert, and in fine spirits.',0
T_DEM5_011	LABEL	BYTE
	DB	'#DEM5\DEM5_011#Jim, I''ve completed my study. I find no evidence '
	DB	'for physical or mental disturbances among the colonists, causing'
	DB	' them to see hallucinations. There must be other reasons for wha'
	DB	't these people are seeing.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
