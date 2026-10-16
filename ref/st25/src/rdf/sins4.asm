; SINS4.RDF - "Sins of Omission", a corridor joining three chambers of the
; Scythe base. One door has a card lock: its slot shows traces of the
; moon's silver, and its pattern lets the drill (room 3) make a keycard.
; Uhura cures the virus, but the Enterprise's phasers stay down.
;
; Actors: 8 the door.
; Objects: 8/20h the door, 21h the lock, 22h a beam, 23h lights, 24h the
; way back, 25h the way on. Exits: 0 room 5, 1 room 2, 2 room 3.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - Two scripts answer Spock on the lock; the second never runs.
; - The conversation at 00D8 is built at run time.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
scanned_lock	EQU	RS_VARS+0Dh	; Spock has scanned the card lock
rocks_known	EQU	RS_VARS+10h	; bits: the rocks' silver (rooms 0, 3, 4): 7 all, 8 Spock's idea
door_open3	EQU	RS_VARS+16h	; the keycard has opened the door
seen_mine	EQU	RS_VARS+1Ch	; the party has been in the mining room (room 3)
virus_cured	EQU	RS_VARS+1Dh	; Uhura has destroyed the virus
scanned_walls	EQU	RS_VARS+20h	; the point for scanning the walls
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
	DW	32h
rdf_scale_min	LABEL	BYTE
	DW	5Ah	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	5, 2, 3, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	145,132, 134,144	; entrance 0, crew 0
	DW	157,132, 154,150	; entrance 0, crew 1
	DW	156,123, 174,147	; entrance 0, crew 2
	DW	146,126, 146,140	; entrance 0, crew 3
	DW	69,150, 151,154	; entrance 1, crew 0
	DW	69,154, 127,161	; entrance 1, crew 1
	DW	59,150, 135,147	; entrance 1, crew 2
	DW	21,150, 111,152	; entrance 1, crew 3
	DW	279,158, 259,158	; entrance 2, crew 0
	DW	279,168, 269,168	; entrance 2, crew 1
	DW	295,158, 279,158	; entrance 2, crew 2
	DW	319,168, 299,173	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	160,150, 160,150, 160,150, 160,150	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	160,150, 160,150, 160,150, 160,150
	DB	'sscans',0
N_mscans	LABEL	BYTE
	DB	'mscans',0
talk_buf	LABEL	BYTE
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
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
N_Ensign_Mosher	LABEL	BYTE
	DB	'Ensign Mosher',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
	DB	'Mr. Scott',0
rdf_objects	LABEL	BYTE
	DW	20h, 8	; id, points
	DW	138,129, 123,115, 126,89, 135,80, 166,80, 175,90
	DW	175,117, 163,129
	DW	21h, 4	; id, points
	DW	179,100, 189,100, 189,109, 179,109
	DW	22h, 4	; id, points
	DW	59,9, 73,9, 73,178, 59,171
	DW	23h, 4	; id, points
	DW	103,31, 253,31, 252,42, 101,41
	DW	24h, 6	; id, points
	DW	25,78, 40,78, 48,93, 48,127, 39,146, 25,152
	DW	25h, 6	; id, points
	DW	319,152, 312,149, 302,132, 302,83, 312,66, 319,65
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	0, 4	; id, points
	DW	138,121, 162,121, 162,126, 138,126
	DW	1, 4	; id, points
	DW	24,145, 58,146, 34,159, 4,157
	DW	2, 3	; id, points
	DW	293,147, 319,143, 319,163
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's4b1',0
	DB	's4b2',0
	DB	's4b3',0
	DB	's4b4',0
	DB	's4b5',0
	DB	's4b6',0

rdf_scripts:
rdf_bans_end:
; The room starts: the door, if opened. Until Uhura's call (tick 40)
; the party can't move.
H_0250:
	SCRIPT	MSG_TICK, 1, 0, 0, H_02B1
StartRoom:
	jmp	SHORT L0261

N_SIN4LOOP	LABEL	BYTE
	DB	'SIN4LOOP',0
L0261:
	push	OFFSET N_SIN4LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SIN4LOOP")
	add	sp, 4
	cmp	byte ptr [si+virus_cured], 0
	jne	L027A
	mov	byte ptr [si+RS_BUSY], 2
L027A:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+door_open3], 1
	jne	L02A2
	jmp	SHORT L028D

N_s4dro	LABEL	BYTE
	DB	's4dro',0
L028D:
	push	0
	push	0
	push	0
	push	OFFSET N_s4dro
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s4dro", 0, 0, 0)
	add	sp, 0Ch
L02A2:
	push	-3
	push	1Bh
	push	RC_MUSIC
	SERVICE		; Music(27, -3)
	add	sp, 6
	retf

; The lock: Spock's scan finds traces of tri-phosphorate silver in its
; slot (scanned_lock).
H_02B1:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_03D5
SpockScansLock:
	jmp	SHORT L02C0

N_sscann	LABEL	BYTE
	DB	'sscann',0
L02C0:
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
	mov	bx, OFFSET T_SIN4_020
	call	Say
	JMPN	L03C4

T_SIN4_020	LABEL	BYTE
	DB	'#SIN4\SIN4_020#This panel has a slot in it rather than a keypad.'
	DB	' The slot bears traces of Tri-Phosphorate Silver, and power is c'
	DB	'urrently running to it. I am recording the pattern of this lock '
	DB	'into my tricorder.',0
L03C4:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+scanned_lock], 1
	or	byte ptr [si+rocks_known], 4
	JMPN	L08EC

	DB	0CBh

; Spock on the lock. SpockOnLockNever has the same key, so it never runs
; (and with it Spock's suggestion of a keycard here).
H_03D5:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_0425
SpockOnLock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN4_018
	call	Say
	jmp	SHORT L0424

T_SIN4_018	LABEL	BYTE
	DB	'#SIN4\SIN4_018#My fingers are too large to fit into the slot.',0
L0424:
	retf

; Phasers.
H_0425:
	SCRIPT	MSG_USE, IT_PHASERK, 20h, 0, H_042D
	jmp	SHORT PhaserDoor

H_042D:
	SCRIPT	MSG_USE, IT_PHASERS, 20h, 0, H_04A0
PhaserDoor:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN4_009
	call	Say
	jmp	SHORT L049F

T_SIN4_009	LABEL	BYTE
	DB	'#SIN4\SIN4_009#Captain, the door is heavily shielded. Our phaser'
	DB	's will have a negligible effect.',0
L049F:
	retf

H_04A0:
	SCRIPT	MSG_USE, IT_PHASERK, 21h, 0, H_04A8
	jmp	SHORT PhaserLock

H_04A8:
	SCRIPT	MSG_USE, IT_PHASERS, 21h, 0, H_0512
PhaserLock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN4_008
	call	Say
	jmp	SHORT L0511

T_SIN4_008	LABEL	BYTE
	DB	'#SIN4\SIN4_008#Captain, if you destroy the lock, there will be n'
	DB	'o way to open the door.',0
L0511:
	retf

; The keycard in the lock (msgs 2, 5): the door opens (anim msg 1).
H_0512:
	SCRIPT	MSG_USE, IT_IDCARD, 21h, 0, H_057F
CardInLock:
	cmp	byte ptr [si+door_open3], 0
	jne	L053F
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 2
	push	ax
	mov	ax, 86h
	push	ax
	mov	ax, 0B8h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 184, 134, 2)
	add	sp, 0Ah
	retf

L053F:
	mov	ax, 0
	mov	bx, OFFSET T_SIN4N006
	call	Say
	jmp	SHORT L057E

T_SIN4N006	LABEL	BYTE
	DB	'#SIN4\SIN4N006#There is already a card in the lock.',0
L057E:
	retf

H_057F:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_05B9
KirkAtLock:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+door_open3], 1
	push	IT_IDCARD
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_IDCARD)
	add	sp, 4
	jmp	SHORT L05A3

N_kusemn	LABEL	BYTE
	DB	'kusemn',0
L05A3:
	push	5
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 5)
	add	sp, 0Ch
	retf

H_05B9:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_05F6
DoorOpens:
	jmp	SHORT L05C8

N_s4door	LABEL	BYTE
	DB	's4door',0
L05C8:
	push	1
	push	0
	push	0
	push	OFFSET N_s4door
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s4door", 0, 0, 1)
	add	sp, 0Ch
	jmp	SHORT L05E6

N_MUR4E1	LABEL	BYTE
	DB	'MUR4E1',0
L05E6:
	push	OFFSET N_MUR4E1
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR4E1")
	add	sp, 4
	retf

; A rock in the slot (msgs 3, 4): a power surge, nothing more.
H_05F6:
	SCRIPT	MSG_USE, IT_S8ROCKS, 21h, 0, H_061D
RockOnLock:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 3
	push	ax
	mov	ax, 86h
	push	ax
	mov	ax, 0B8h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 184, 134, 3)
	add	sp, 0Ah
	retf

H_061D:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_0642
KirkAtLock2:
	jmp	SHORT L062C

N_kusemn_2	LABEL	BYTE
	DB	'kusemn',0
L062C:
	push	4
	push	-1
	push	-1
	push	OFFSET N_kusemn_2
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 4)
	add	sp, 0Ch
	retf

H_0642:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_071B
RockHitsLock:
	mov	ax, 0
	mov	bx, OFFSET T_SIN4N012
	call	Say
	jmp	SHORT L067A

T_SIN4N012	LABEL	BYTE
	DB	'#SIN4\SIN4N012#The Panel is undamaged.',0
L067A:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN4_022
	call	Say
	JMPN	L0717

T_SIN4_022	LABEL	BYTE
	DB	'#SIN4\SIN4_022#Very odd, Captain. There was a power surge to the'
	DB	' panel just after the rock struck it. Probably 3KAg dust getting'
	DB	' into the slot. ',0
L0717:
	JMPN	L08EC

	DB	0CBh

; Looking and talking.
H_071B:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_0776
LookAtWayBack:
	mov	ax, 0
	mov	bx, OFFSET T_SIN4N009
	call	Say
	jmp	SHORT L0775

T_SIN4N009	LABEL	BYTE
	DB	'#SIN4\SIN4N009#This doorway leads back to the security lock and '
	DB	'outside.',0
L0775:
	retf

H_0776:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_07CA
LookAtWayOn:
	mov	ax, 0
	mov	bx, OFFSET T_SIN4N010
	call	Say
	jmp	SHORT L07C9

T_SIN4N010	LABEL	BYTE
	DB	'#SIN4\SIN4N010#This doorway leads to another area of the complex'
	DB	'.',0
L07C9:
	retf

H_07CA:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_0828
LookAtScene:
	mov	ax, 0
	mov	bx, OFFSET T_SIN4N013
	call	Say
	jmp	SHORT L0827

T_SIN4N013	LABEL	BYTE
	DB	'#SIN4\SIN4N013#You are in a corridor that connects to three othe'
	DB	'r chambers.',0
L0827:
	retf

H_0828:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_088D
LookAtLock:
	mov	ax, 0
	mov	bx, OFFSET T_SIN4N011
	call	Say
	jmp	SHORT L088C

T_SIN4N011	LABEL	BYTE
	DB	'#SIN4\SIN4N011#This panel is designed to receive an ID card to m'
	DB	'ake the door open.',0
L088C:
	retf

H_088D:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_09DC
SpockOnLockNever:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN4_021
	call	Say
	jmp	SHORT L08EC

T_SIN4_021	LABEL	BYTE
	DB	'#SIN4\SIN4_021#This panel requires a coded identification key to'
	DB	' get it open.',0
L08EC:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+rocks_known], 7
	je	L08FA
	JMPN	L09DB

L08FA:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN4_010
	call	Say
	JMPN	L09D7

T_SIN4_010	LABEL	BYTE
	DB	'#SIN4\SIN4_010#Captain, with the 3KAg content of the surface roc'
	DB	'ks and the Tricorder scan of the pattern inside the lock, I beli'
	DB	'eve the laser drill can be used to fashion the ID card needed to'
	DB	' open this door.',0
L09D7:
	or	byte ptr [si+rocks_known], 8
L09DB:
	retf

; Tick 40, once: Uhura has destroyed the virus, but the phasers are still
; out: the party must stop the missiles from here.
H_09DC:
	SCRIPT	MSG_TICK, 28h, 0, 0, H_0D2C
UhuraCuresVirus:
	cmp	byte ptr [si+virus_cured], 0
	je	L09EB
	JMPN	L0D2B

L09EB:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_SIN4U088
	call	Say
	jmp	SHORT L0A39

T_SIN4U088	LABEL	BYTE
	DB	'#SIN4\SIN4U088#Captain, we have a cure for the computer virus!',0
L0A39:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN4_007
	call	Say
	jmp	SHORT L0A65

T_SIN4_007	LABEL	BYTE
	DB	'#SIN4\SIN4_007#Well done, Uhura!',0
L0A65:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_SIN4U103
	call	Say
	jmp	SHORT L0AE0

T_SIN4U103	LABEL	BYTE
	DB	'#SIN4\SIN4U103#I modified K''trhra-C to exclusively attack the Lu'
	DB	'cr virus. They annihilated each other, Captain.',0
L0AE0:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN4_025
	call	Say
	jmp	SHORT L0B13

T_SIN4_025	LABEL	BYTE
	DB	'#SIN4\SIN4_025#Fascinating, lieutenant.',0
L0B13:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN4_003
	call	Say
	jmp	SHORT L0B9A

T_SIN4_003	LABEL	BYTE
	DB	'#SIN4\SIN4_003#The Klingons aren''t going to be happy to learn th'
	DB	'at they helped us. How about the phasers and tractor beams?',0
L0B9A:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_SIN4U107
	call	Say
	JMPN	L0C32

T_SIN4U107	LABEL	BYTE
	DB	'#SIN4\SIN4U107#We may get the tractor beams on-line in time, Cap'
	DB	'tain. I''m afraid even the back-up phaser transmission codes were'
	DB	' affected. ',0
L0C32:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_SIN4U105
	call	Say
	JMPN	L0CC0

T_SIN4U105	LABEL	BYTE
	DB	'#SIN4\SIN4U105#We could destroy some missiles manually, but if t'
	DB	'his complex decides to launch more than ten missiles at a time..'
	DB	'.',0
L0CC0:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN4_005
	call	Say
	jmp	SHORT L0D27

T_SIN4_005	LABEL	BYTE
	DB	'#SIN4\SIN4_005#Understood. The ball is in our court. We''ll give '
	DB	'it our best shot. Kirk out.',0
L0D27:
	mov	byte ptr [si+virus_cured], 1
L0D2B:
	retf

H_0D2C:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_0D87
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_SIN4N002
	call	Say
	jmp	SHORT L0D86

T_SIN4N002	LABEL	BYTE
	DB	'#SIN4\SIN4N002#James Kirk seems relieved by the good news from h'
	DB	'is ship.',0
L0D86:
	retf

H_0D87:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_0DDD
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_SIN4N004
	call	Say
	jmp	SHORT L0DDC

T_SIN4N004	LABEL	BYTE
	DB	'#SIN4\SIN4N004#Spock, deep in thought, analyzes the Lucr compute'
	DB	'rs.',0
L0DDC:
	retf

H_0DDD:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_0E3F
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_SIN4N003
	call	Say
	jmp	SHORT L0E3E

T_SIN4N003	LABEL	BYTE
	DB	'#SIN4\SIN4N003#So far, this mission has been boring, from a medi'
	DB	'cal standpoint.',0
L0E3E:
	retf

H_0E3F:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_0F00
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_SIN4N001
	call	Say
	JMPN	L0EFF

T_SIN4N001	LABEL	BYTE
	DB	'#SIN4\SIN4N001#As soon as this mission is over, Ensign Mosher is'
	DB	' going to write his sister, who serves onboard Pegasus Science S'
	DB	'tation, and gloat about everything he''s seen.',0
L0EFF:
	retf

H_0F00:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_0F73
LookAtLights:
	mov	ax, 0
	mov	bx, OFFSET T_SIN4N000
	call	Say
	jmp	SHORT L0F72

T_SIN4N000	LABEL	BYTE
	DB	'#SIN4\SIN4N000#Although centuries old, these lights still provid'
	DB	'e illumination for this complex.',0
L0F72:
	retf

H_0F73:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_0FEA
LookAtBeam:
	mov	ax, 0
	mov	bx, OFFSET T_SIN4N005
	call	Say
	jmp	SHORT L0FE9

T_SIN4N005	LABEL	BYTE
	DB	'#SIN4\SIN4N005#There are a few stress fractures on this beam, bu'
	DB	't it still looks to be quite sturdy.',0
L0FE9:
	retf

H_0FEA:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_102F
LookAtOpenDoor:
	mov	ax, 0
	mov	bx, OFFSET T_SIN4N008
	call	Say
	jmp	SHORT L102E

T_SIN4N008	LABEL	BYTE
	DB	'#SIN4\SIN4N008#This door leads to another chamber.',0
L102E:
	retf

H_102F:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_1074
LookAtDoor:
	mov	ax, 0
	mov	bx, OFFSET T_SIN4N007
	call	Say
	jmp	SHORT L1073

T_SIN4N007	LABEL	BYTE
	DB	'#SIN4\SIN4N007#This door appears to be very solid.',0
L1073:
	retf

H_1074:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_1166
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN4_001
	call	Say
	jmp	SHORT L10B5

T_SIN4_001	LABEL	BYTE
	DB	'#SIN4\SIN4_001#At least the Enterprise is safe.',0
L10B5:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN4_028
	call	Say
	jmp	SHORT L111C

T_SIN4_028	LABEL	BYTE
	DB	'#SIN4\SIN4_028#Unless the computers decide to send more powerful'
	DB	' viruses to the Enterprise.',0
L111C:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN4_004
	call	Say
	jmp	SHORT L1165

T_SIN4_004	LABEL	BYTE
	DB	'#SIN4\SIN4_004#Then we''re just going to have to prevent that.',0
L1165:
	retf

H_1166:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_11B0
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN4_019
	call	Say
	jmp	SHORT L11AF

T_SIN4_019	LABEL	BYTE
	DB	'#SIN4\SIN4_019#Please allow me to concentrate, Captain.',0
L11AF:
	retf

H_11B0:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_12BB
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN4_015
	call	Say
	jmp	SHORT L121F

T_SIN4_015	LABEL	BYTE
	DB	'#SIN4\SIN4_015#When I retire from Starfleet, I''m going to write '
	DB	'one heck of an autobiography.',0
L121F:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN4_024
	call	Say
	jmp	SHORT L126C

T_SIN4_024	LABEL	BYTE
	DB	'#SIN4\SIN4_024#Fascinating, doctor. I look forward to reading it'
	DB	'.',0
L126C:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN4_017
	call	Say
	jmp	SHORT L12BA

T_SIN4_017	LABEL	BYTE
	DB	'#SIN4\SIN4_017#That way I can finally get someone to listen to m'
	DB	'e!',0
L12BA:
	retf

H_12BB:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_1347
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN4_031
	call	Say
	jmp	SHORT L1346

T_SIN4_031	LABEL	BYTE
	DB	'#SIN4\SIN4_031#This machinery is incredible. Are all your landin'
	DB	'g missions this much fun? I might never leave this place!',0
L1346:
	retf

; Tricorders and the communicator.
H_1347:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_14E3
SpockScansDoor:
	jmp	SHORT L1356

N_sscann_2	LABEL	BYTE
	DB	'sscann',0
L1356:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscann_2
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
	mov	bx, OFFSET T_SIN4_027
	call	Say
	JMPN	L1417

T_SIN4_027	LABEL	BYTE
	DB	'#SIN4\SIN4_027#This door is made from remarkably dense alloys. E'
	DB	'ven our most powerful phaser rifle or welder would not be able t'
	DB	'o penetrate it.',0
L1417:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN4_032
	call	Say
	jmp	SHORT L1467

T_SIN4_032	LABEL	BYTE
	DB	'#SIN4\SIN4_032#The thing must be almost as tough as a starship h'
	DB	'ull!',0
L1467:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN4_026
	call	Say
	jmp	SHORT L14E2

T_SIN4_026	LABEL	BYTE
	DB	'#SIN4\SIN4_026#Indeed, Ensign. And considerably thinner. A remar'
	DB	'kable achievement in metallurgical engineering.',0
L14E2:
	retf

H_14E3:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_1577
SpockScansWalls:
	jmp	SHORT L14F2

N_sscans	LABEL	BYTE
	DB	'sscans',0
L14F2:
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
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN4_011
	call	Say
	jmp	SHORT L1568

T_SIN4_011	LABEL	BYTE
	DB	'#SIN4\SIN4_011#Circuits and atmosphere pumps are hidden in the w'
	DB	'alls.',0
L1568:
	cmp	byte ptr [si+scanned_walls], 1
	je	L1576
	add	word ptr [si+score], 1
	mov	byte ptr [si+scanned_walls], 1
L1576:
	retf

H_1577:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_16FB
UseCommunicator:
	cmp	byte ptr [si+seen_mine], 0
	je	L1586
	JMPN	L16BB

L1586:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_SIN4U100
	call	Say
	jmp	SHORT L15D0

T_SIN4U100	LABEL	BYTE
	DB	'#SIN4\SIN4U100#No change, Captain. Any progress on the planet?',0
L15D0:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN4_006
	call	Say
	jmp	SHORT L162F

T_SIN4_006	LABEL	BYTE
	DB	'#SIN4\SIN4_006#We''re making our way through. Keep your fingers c'
	DB	'rossed, lieutenant.',0
L162F:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_SIN4U83B
	call	Say
	jmp	SHORT L166D

T_SIN4U83B	LABEL	BYTE
	DB	'#SIN4\SIN4U83B#Captain, we''ll help you all we can.',0
L166D:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN4_002
	call	Say
	jmp	SHORT L16BB

T_SIN4_002	LABEL	BYTE
	DB	'#SIN4\SIN4_002#Right now, I''ll take anything that works. Kirk ou'
	DB	't.',0
L16BB:
	cmp	byte ptr [si+seen_mine], 1
	jne	L16FA
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_SIN4U073
	call	Say
	jmp	SHORT L16FA

T_SIN4U073	LABEL	BYTE
	DB	'#SIN4\SIN4U073#Nothing new to report Captain.',0
L16FA:
	retf

; The crew on the door and the lock.
H_16FB:
	SCRIPT	MSG_USE, OBJ_MCCOY, 20h, 0, H_1745
McCoyOnDoor:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN4_016
	call	Say
	jmp	SHORT L1744

T_SIN4_016	LABEL	BYTE
	DB	'#SIN4\SIN4_016#What do you want me to do, kick it down?',0
L1744:
	retf

H_1745:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 20h, 0, H_17A5
MosherOnDoor:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN4_029
	call	Say
	jmp	SHORT L17A4

T_SIN4_029	LABEL	BYTE
	DB	'#SIN4\SIN4_029#I don''t think a hand phaser is going to cut throu'
	DB	'gh that, Sir.',0
L17A4:
	retf

H_17A5:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_17F5
SpockOnDoor:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN4_023
	call	Say
	jmp	SHORT L17F4

T_SIN4_023	LABEL	BYTE
	DB	'#SIN4\SIN4_023#We must find a way to bypass it''s lock system.',0
L17F4:
	retf

H_17F5:
	SCRIPT	MSG_USE, OBJ_MCCOY, 21h, 0, H_1830
McCoyOnLock:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN4_013
	call	Say
	jmp	SHORT L182F

T_SIN4_013	LABEL	BYTE
	DB	'#SIN4\SIN4_013#My fingers don''t fit Jim.',0
L182F:
	retf

H_1830:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 21h, 0, H_1884
MosherOnLock:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN4_030
	call	Say
	jmp	SHORT L1883

T_SIN4_030	LABEL	BYTE
	DB	'#SIN4\SIN4_030#I don''t think my phaser will do a lot of good Sir'
	DB	'.',0
L1883:
	retf

; Walking: through the door (room 5), back (room 2), on (room 3).
H_1884:
	SCRIPT	MSG_WALK, 20h, 0, 0, H_18AD
WalkThroughDoor:
	cmp	byte ptr [si+door_open3], 1
	jne	L18AC
	mov	ax, 0
	push	ax
	mov	ax, 7Dh
	push	ax
	mov	ax, 96h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 150, 125, 0)
	add	sp, 0Ah
L18AC:
	retf

H_18AD:
	SCRIPT	MSG_WALK, 8, 0, 0, H_18D6
WalkThroughDoor2:
	cmp	byte ptr [si+door_open3], 1
	jne	L18D5
	mov	ax, 0
	push	ax
	mov	ax, 7Dh
	push	ax
	mov	ax, 96h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 150, 125, 0)
	add	sp, 0Ah
L18D5:
	retf

H_18D6:
	SCRIPT	MSG_WALK, 24h, 0, 0, H_18F9
WalkBack:
	mov	ax, 0
	push	ax
	mov	ax, 95h
	push	ax
	mov	ax, 1Bh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 27, 149, 0)
	add	sp, 0Ah
	retf

H_18F9:
	SCRIPT	MSG_WALK, 25h, 0, 0, H_191C
WalkOn:
	mov	ax, 0
	push	ax
	mov	ax, 9Bh
	push	ax
	mov	ax, 13Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 316, 155, 0)
	add	sp, 0Ah
	retf

H_191C:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_KIRK, 0, H_1924
	jmp	SHORT MedkitOnSpock

H_1924:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_SPOCK, 0, H_192C
MedkitOnSpock:
	jmp	SHORT MedkitOnMcCoy

H_192C:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_MCCOY, 0, H_1934
MedkitOnMcCoy:
	jmp	SHORT MedkitOnRedshirt

H_1934:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_REDSHIRT, 0, H_1980
MedkitOnRedshirt:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN4_014
	call	Say
	jmp	SHORT L197F

T_SIN4_014	LABEL	BYTE
	DB	'#SIN4\SIN4_014#We''re safe from the cosmic radiation, Jim.',0
L197F:
	retf

H_1980:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_KIRK, 0, H_1988
	jmp	SHORT McCoyScansRedshirt

H_1988:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_SPOCK, 0, H_1990
	jmp	SHORT McCoyScansRedshirt

H_1990:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_MCCOY, 0, H_1998
	jmp	SHORT McCoyScansRedshirt

H_1998:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_REDSHIRT, 0, rdf_scripts_end
McCoyScansRedshirt:
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
	mov	bx, OFFSET T_SIN4_012
	call	Say
	jmp	SHORT L1A30

T_SIN4_012	LABEL	BYTE
	DB	'#SIN4\SIN4_012#All readings are normal. The structure seems to b'
	DB	'e protecting us from the cosmic rays.',0
L1A30:
	retf

rdf_scripts_end	LABEL	BYTE

RDF	ENDS
	END
