; SINS1.RDF - "Sins of Omission", inside the security door: a huge inner
; door with a keypad and display, and a lens above it. The right code
; opens it; a wrong but meaningful one fires an anti-intruder laser.
; Scott reports a virus that has taken the Enterprise's phasers and
; tractor beams.
;
; Actors: 8 the door, 9 the laser.
; Objects: 8 the lock, 20h the door, 21h the keypad, 22h the display,
; 23h the lens. Exits: 0 room 2, 1 room 0.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - Two scripts answer talking to Spock; the second never runs.
; - The conversation at 00D8 is built at run time.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
unused08	EQU	RS_VARS+8	; set each visit, never read
unused09	EQU	RS_VARS+9	; set each visit, never read
laser_fired	EQU	RS_VARS+0Ah	; the wrong code has fired the laser
know_lens	EQU	RS_VARS+0Bh	; Spock knows the lens is an anti-intruder laser
door_open1	EQU	RS_VARS+14h	; the security door is open
door_open2	EQU	RS_VARS+15h	; the second door has opened (room 2)
scott_virus	EQU	RS_VARS+1Ah	; Scott has reported the virus in the ship's computer
virus_found	EQU	RS_VARS+1Bh	; set in room 2
music_started	EQU	RS_VARS+27h

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
	DW	2, 0, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	160,175, 160,180	; entrance 0, crew 0
	DW	140,170, 140,175	; entrance 0, crew 1
	DW	180,170, 180,175	; entrance 0, crew 2
	DW	160,165, 160,170	; entrance 0, crew 3
	DW	160,181, 160,180	; entrance 1, crew 0
	DW	140,186, 140,185	; entrance 1, crew 1
	DW	180,186, 180,185	; entrance 1, crew 2
	DW	160,191, 160,190	; entrance 1, crew 3
	DW	0,0, 0,0	; entrance 2, crew 0
	DW	0,0, 0,0	; entrance 2, crew 1
	DW	0,0, 0,0	; entrance 2, crew 2
	DW	0,0, 0,0	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	160,180, 150,185, 170,185, 160,190	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	160,180, 150,185, 170,185, 160,190
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_mscans	LABEL	BYTE
	DB	'mscans',0
talk_buf	LABEL	BYTE
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
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
N_Mr_Scott	LABEL	BYTE
	DB	'Mr. Scott',0
rdf_objects	LABEL	BYTE
	DW	20h, 4	; id, points
	DW	69,165, 70,18, 238,18, 238,165
	DW	21h, 4	; id, points
	DW	248,124, 260,124, 260,136, 248,136
	DW	22h, 4	; id, points
	DW	248,107, 260,107, 260,118, 248,118
	DW	23h, 4	; id, points
	DW	145,8, 156,8, 156,13, 145,13
	DW	24h, 4	; id, points
	DW	234,80, 241,77, 244,133, 233,124
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	0, 4	; id, points
	DW	105,145, 203,145, 192,159, 118,160
	DW	1, 4	; id, points
	DW	0,194, 319,194, 319,199, 0,199
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's1b1',0

rdf_scripts:
rdf_bans_end:
; The room starts: the door, open or shut. Until Scott's call (tick 40)
; the party can't move.
H_01FF:
	SCRIPT	MSG_TICK, 1, 0, 0, H_02D1
StartRoom:
	jmp	SHORT L0210

N_SIN1LOOP	LABEL	BYTE
	DB	'SIN1LOOP',0
L0210:
	push	OFFSET N_SIN1LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SIN1LOOP")
	add	sp, 4
	cmp	byte ptr [si+scott_virus], 0
	jne	L0229
	mov	byte ptr [si+RS_BUSY], 1
L0229:
	cmp	byte ptr [si+door_open1], 1
	jne	L0264
	jmp	SHORT L0237

N_s1dro	LABEL	BYTE
	DB	's1dro',0
L0237:
	push	0
	push	0
	push	0
	push	OFFSET N_s1dro
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s1dro", 0, 0, 0)
	add	sp, 0Ch
	jmp	SHORT L0255

N_sins12	LABEL	BYTE
	DB	'sins12',0
L0255:
	push	OFFSET N_sins12
	push	RC_LOADMAP
	SERVICE		; LoadMap("sins12")
	add	sp, 4
	jmp	SHORT L0279

L0264:
	jmp	SHORT L026C

N_sins1	LABEL	BYTE
	DB	'sins1',0
L026C:
	push	OFFSET N_sins1
	push	RC_LOADMAP
	SERVICE		; LoadMap("sins1")
	add	sp, 4
L0279:
	cmp	byte ptr [si+door_open2], 1
	jne	L029D
	jmp	SHORT L0288

N_s1ndro	LABEL	BYTE
	DB	's1ndro',0
L0288:
	push	0
	push	0
	push	0
	push	OFFSET N_s1ndro
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s1ndro", 0, 0, 0)
	add	sp, 0Ch
L029D:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+unused09], 1
	mov	byte ptr [si+unused08], 1
	push	-3
	push	1Bh
	push	RC_MUSIC
	SERVICE		; Music(27, -3)
	add	sp, 6
	cmp	byte ptr [si+music_started], 1
	je	L02D0
	push	-2
	push	1
	push	RC_MUSIC
	SERVICE		; Music(1, -2)
	add	sp, 6
	mov	byte ptr [si+music_started], 1
L02D0:
	retf

; Looking and talking.
H_02D1:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_031C
LookAtScene:
	mov	ax, 0
	mov	bx, OFFSET T_SIN1N001
	call	Say
	jmp	SHORT L031B

T_SIN1N001	LABEL	BYTE
	DB	'#SIN1\SIN1N001#Built into the rock is a very large door.',0
L031B:
	retf

H_031C:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_036C
LookAtLock:
	mov	ax, 0
	mov	bx, OFFSET T_SIN1N009
	call	Say
	jmp	SHORT L036B

T_SIN1N009	LABEL	BYTE
	DB	'#SIN1\SIN1N009#This appears to be some sort of security lock.',0
L036B:
	retf

H_036C:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_03E5
LookAtDoor:
	mov	ax, 0
	mov	bx, OFFSET T_SIN1N010
	call	Say
	jmp	SHORT L03E4

T_SIN1N010	LABEL	BYTE
	DB	'#SIN1\SIN1N010#This heavy-duty door has taken numerous micromete'
	DB	'orite strikes but still appears solid.',0
L03E4:
	retf

H_03E5:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_0430
LookAtDisplay:
	mov	ax, 0
	mov	bx, OFFSET T_SIN1N003
	call	Say
	jmp	SHORT L042F

T_SIN1N003	LABEL	BYTE
	DB	'#SIN1\SIN1N003#It looks like some sort of display panel.',0
L042F:
	retf

H_0430:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_0479
LookAtKeypad:
	mov	ax, 0
	mov	bx, OFFSET T_SIN1N011
	call	Say
	jmp	SHORT L0478

T_SIN1N011	LABEL	BYTE
	DB	'#SIN1\SIN1N011#This is a keypad that looks functional.',0
L0478:
	retf

H_0479:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_04FE
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN1_020
	call	Say
	jmp	SHORT L04FD

T_SIN1_020	LABEL	BYTE
	DB	'#SIN1\SIN1_020#The origin point for the broadcast Uhura monitore'
	DB	'd was approximately fifty meters beyond this door.',0
L04FD:
	retf

; Tricorders.
H_04FE:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_056F
SpockScansDisplay:
	jmp	SHORT L050D

N_sscann	LABEL	BYTE
	DB	'sscann',0
L050D:
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
	mov	bx, OFFSET T_SIN1_010
	call	Say
	jmp	SHORT L056E

T_SIN1_010	LABEL	BYTE
	DB	'#SIN1\SIN1_010#A working display panel, Captain.',0
L056E:
	retf

H_056F:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_05E4
SpockScansKeypad:
	jmp	SHORT L057E

N_sscann_2	LABEL	BYTE
	DB	'sscann',0
L057E:
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
	mov	bx, OFFSET T_SIN1_021
	call	Say
	jmp	SHORT L05E3

T_SIN1_021	LABEL	BYTE
	DB	'#SIN1\SIN1_021#There is power running to the keypad.',0
L05E3:
	retf

H_05E4:
	SCRIPT	MSG_USE, IT_STRICOR, 8, 0, H_064D
SpockScansLock:
	jmp	SHORT L05F3

N_sscann_3	LABEL	BYTE
	DB	'sscann',0
L05F3:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscann_3
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
	mov	bx, OFFSET T_SIN1_009
	call	Say
	jmp	SHORT L064C

T_SIN1_009	LABEL	BYTE
	DB	'#SIN1\SIN1_009#A security lock, Captain.',0
L064C:
	retf

H_064D:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_06D7
SpockScansDoor:
	cmp	byte ptr [si+door_open1], 0
	jne	L06D6
	jmp	SHORT L0662

N_sscann_4	LABEL	BYTE
	DB	'sscann',0
L0662:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscann_4
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
	mov	bx, OFFSET T_SIN1_019
	call	Say
	jmp	SHORT L06D6

T_SIN1_019	LABEL	BYTE
	DB	'#SIN1\SIN1_019#The door still appears to be in operating conditi'
	DB	'on.',0
L06D6:
	retf

H_06D7:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_0727
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
	mov	bx, OFFSET T_SIN1_024
	call	Say
	jmp	SHORT L0726

T_SIN1_024	LABEL	BYTE
	DB	'#SIN1\SIN1_024#Unremarkable.',0
L0726:
	retf

H_0727:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_0800
SpockScansLens:
	cmp	byte ptr [si+know_lens], 0
	jne	L07B1
	jmp	SHORT L073C

N_sscann_5	LABEL	BYTE
	DB	'sscann',0
L073C:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscann_5
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
	mov	bx, OFFSET T_SIN1_022
	call	Say
	jmp	SHORT L07B0

T_SIN1_022	LABEL	BYTE
	DB	'#SIN1\SIN1_022#This appears to be a dust-covered lens of some so'
	DB	'rt.',0
L07B0:
	retf

L07B1:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN1_023
	call	Say
	jmp	SHORT L07FF

T_SIN1_023	LABEL	BYTE
	DB	'#SIN1\SIN1_023#This is the focal lense for an anti-intruder lase'
	DB	'r.',0
L07FF:
	retf

; A rock on the door.
H_0800:
	SCRIPT	MSG_USE, IT_S8ROCKS, 20h, 0, H_087C
RockOnDoor:
	mov	ax, 0
	mov	bx, OFFSET T_SIN1N007
	call	Say
	jmp	SHORT L087B

T_SIN1N007	LABEL	BYTE
	DB	'#SIN1\SIN1N007#Meteorites have hit this door and left it undamag'
	DB	'ed. What are you going to do with a rock?',0
L087B:
	retf

; The keypad: only Spock (msg 6). He enters the code typed (InputCode):
; "10200" (99 in the Lucrs' base three) opens the door (anim msgs 8, 1);
; "01210" or "1210" (100 in the Sofs' base four) fires the laser over the
; door (msgs 9, 2); anything else does nothing (msg 7).
H_087C:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 21h, 0, H_08C5
MosherOnKeypad:
	cmp	byte ptr [si+door_open1], 0
	jne	L08C4
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN1_028
	call	Say
	jmp	SHORT L08C4

T_SIN1_028	LABEL	BYTE
	DB	'#SIN1\SIN1_028#I''m just a security officer, Sir.',0
L08C4:
	retf

H_08C5:
	SCRIPT	MSG_USE, OBJ_MCCOY, 21h, 0, H_0919
McCoyOnKeypad:
	cmp	byte ptr [si+door_open1], 0
	jne	L0918
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN1_012
	call	Say
	jmp	SHORT L0918

T_SIN1_012	LABEL	BYTE
	DB	'#SIN1\SIN1_012#Damn it, Jim. I''m a doctor, not a locksmith!',0
L0918:
	retf

H_0919:
	SCRIPT	MSG_USE, OBJ_KIRK, 21h, 0, H_096D
KirkOnKeypad:
	cmp	byte ptr [si+door_open1], 0
	jne	L096C
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN1_001
	call	Say
	jmp	SHORT L096A

T_SIN1_001	LABEL	BYTE
	DB	'#SIN1\SIN1_001#Spock, see what you can do with that lock.',0
L096A:
	jmp	SHORT SpockOnKeypad

L096C:
	retf

H_096D:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_09AC
SpockOnKeypad:
	cmp	byte ptr [si+door_open1], 0
	jne	L0999
	mov	byte ptr [si+RS_FALL+1], 0
	mov	ax, 6
	push	ax
	mov	ax, 0ADh
	push	ax
	mov	ax, 0FDh
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 253, 173, 6)
	add	sp, 0Ah
L0999:
	retf

N_01210	LABEL	BYTE
	DB	'01210',0
	DB	'1210',0
	DB	'10200',0
	DB	0

H_09AC:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_0A9D
EnterCode:
	mov	ax, OFFSET N_01210
	push	ax
	mov	ax, RC_INPUTCODE
	push	ax
	SERVICE		; InputCode("01210")
	add	sp, 4
	AX8	cmp, 1
	je	L0A2F
	AX8	cmp, 2
	je	L0A2F
	AX8	cmp, 3
	jne	L09D4
	JMPN	L0A66

L09D4:
	jmp	SHORT L09D7

	DB	0CBh
L09D7:
	jmp	SHORT L09E0

N_EFX14S	LABEL	BYTE
	DB	'EFX14S',0
L09E0:
	push	OFFSET N_EFX14S
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EFX14S")
	add	sp, 4
	jmp	SHORT L09F8

N_susehn	LABEL	BYTE
	DB	'susehn',0
L09F8:
	push	7
	push	-1
	push	-1
	push	OFFSET N_susehn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susehn", -1, -1, 7)
	add	sp, 0Ch
	retf

				; NOTE: unreachable (code=0A0E in config/rdf.txt)
L0A0E:
	mov	byte ptr [si+RS_FALL+1], 3
	mov	ax, 0
	push	ax
	mov	ax, 0ADh
	push	ax
	mov	ax, 0F3h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 243, 173, 0)
	add	sp, 0Ah
	retf

L0A2F:
	jmp	SHORT L0A38

N_EFX14S_2	LABEL	BYTE
	DB	'EFX14S',0
L0A38:
	push	OFFSET N_EFX14S_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EFX14S")
	add	sp, 4
	jmp	SHORT L0A50

N_susehn_2	LABEL	BYTE
	DB	'susehn',0
L0A50:
	push	9
	push	-1
	push	-1
	push	OFFSET N_susehn_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susehn", -1, -1, 9)
	add	sp, 0Ch
	retf

L0A66:
	jmp	SHORT L0A6F

N_EFX14S_3	LABEL	BYTE
	DB	'EFX14S',0
L0A6F:
	push	OFFSET N_EFX14S_3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EFX14S")
	add	sp, 4
	jmp	SHORT L0A87

N_susehn_3	LABEL	BYTE
	DB	'susehn',0
L0A87:
	push	8
	push	-1
	push	-1
	push	OFFSET N_susehn_3
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susehn", -1, -1, 8)
	add	sp, 0Ch
	retf

H_0A9D:
	SCRIPT	MSG_ANIM_DONE, 8, 0, 0, H_0B1B
DoorOpens:
	mov	byte ptr [si+RS_FALL+1], 3
	mov	ax, 0
	push	ax
	mov	ax, 0ADh
	push	ax
	mov	ax, 0F3h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 243, 173, 0)
	add	sp, 0Ah
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+door_open1], 1
	jmp	SHORT L0AD5

N_sins12_2	LABEL	BYTE
	DB	'sins12',0
L0AD5:
	push	OFFSET N_sins12_2
	push	RC_LOADMAP
	SERVICE		; LoadMap("sins12")
	add	sp, 4
	jmp	SHORT L0AEB

N_s1door	LABEL	BYTE
	DB	's1door',0
L0AEB:
	push	1
	push	0
	push	0
	push	OFFSET N_s1door
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s1door", 0, 0, 1)
	add	sp, 0Ch
	jmp	SHORT L0B0B

N_HUGEDOO2	LABEL	BYTE
	DB	'HUGEDOO2',0
L0B0B:
	push	OFFSET N_HUGEDOO2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("HUGEDOO2")
	add	sp, 4
	retf

H_0B1B:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_0BA8
DoorOpened:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN1_011
	call	Say
	jmp	SHORT L0BA7

T_SIN1_011	LABEL	BYTE
	DB	'#SIN1\SIN1_011#Ah, that worked. I see you deduced that 10200, in'
	DB	' the Lucrs base three was equal to their sacred number 99.',0
L0BA7:
	retf

H_0BA8:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_0C78
WrongCode:
	mov	byte ptr [si+RS_FALL+1], 3
	mov	ax, 0
	push	ax
	mov	ax, 0ADh
	push	ax
	mov	ax, 0F3h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 243, 173, 0)
	add	sp, 0Ah
	mov	ax, 0
	mov	bx, OFFSET T_SIN1_017
	call	Say
	JMPN	L0C77

T_SIN1_017	LABEL	BYTE
	DB	'#SIN1\SIN1_017#That did not seem to work, Captain. Perhaps we sh'
	DB	'ould try a number that had some significance to them. Remember t'
	DB	'hey were very superstitious.',0
L0C77:
	retf

H_0C78:
	SCRIPT	MSG_ANIM_DONE, 9, 0, 0, H_0CCC
LaserFires:
	mov	byte ptr [si+RS_FALL+1], 3
	mov	ax, 0
	push	ax
	mov	ax, 0ADh
	push	ax
	mov	ax, 0F3h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 243, 173, 0)
	add	sp, 0Ah
	jmp	SHORT L0CA6

N_s1ph1	LABEL	BYTE
	DB	's1ph1',0
L0CA6:
	push	2
	push	0
	push	0
	push	OFFSET N_s1ph1
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s1ph1", 0, 0, 2)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	retf

; Phasers on the door: useless.
H_0CCC:
	SCRIPT	MSG_USE, IT_PHASERS, 20h, 0, H_0CD4
	jmp	SHORT PhaserDoor

H_0CD4:
	SCRIPT	MSG_USE, IT_PHASERK, 20h, 0, H_0D43
PhaserDoor:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN1_016
	call	Say
	jmp	SHORT L0D42

T_SIN1_016	LABEL	BYTE
	DB	'#SIN1\SIN1_016#It would be useless Captain. The door could easil'
	DB	'y withstand our phaser fire.',0
L0D42:
	retf

H_0D43:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_0DE5
LaserFired:
	mov	ax, 9
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(9)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN1_018
	call	Say
	jmp	SHORT L0DD7

T_SIN1_018	LABEL	BYTE
	DB	'#SIN1\SIN1_018#That prompted a response, Captain. 01210 is 100 i'
	DB	'n base four, a number the Sofs regarded as sacred.',0
L0DD7:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+laser_fired], 1
	mov	byte ptr [si+know_lens], 1
	retf

; Tick 40, once: Scott reports a virus in the computer; no phasers.
H_0DE5:
	SCRIPT	MSG_TICK, 28h, 0, 0, H_10AA
ScottOnVirus:
	cmp	byte ptr [si+scott_virus], 0
	je	L0DF4
	JMPN	L10A9

L0DF4:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_SIN1_S10
	call	Say
	jmp	SHORT L0E40

T_SIN1_S10	LABEL	BYTE
	DB	'#SIN1\SIN1_S10#Captain, I''m afraid we''ve got a wee problem here.',0
L0E40:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN1_007
	call	Say
	jmp	SHORT L0E6E

T_SIN1_007	LABEL	BYTE
	DB	'#SIN1\SIN1_007#What is it, Scotty?',0
L0E6E:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_SIN1_S18
	call	Say
	JMPN	L0F28

T_SIN1_S18	LABEL	BYTE
	DB	'#SIN1\SIN1_S18#There is some sort of virus in the main computer.'
	DB	' Our phasers and tractor beams have been disabled, and there''s n'
	DB	'o way we''re getting them back in three hours.',0
L0F28:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN1_005
	call	Say
	jmp	SHORT L0F7B

T_SIN1_005	LABEL	BYTE
	DB	'#SIN1\SIN1_005#There goes our back-up plan. Do what you can, Mr.'
	DB	' Scott.',0
L0F7B:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_SIN1_S85
	call	Say
	jmp	SHORT L0FFA

T_SIN1_S85	LABEL	BYTE
	DB	'#SIN1\SIN1_S85#Aye, I will Captain. I may yet have a trick or tw'
	DB	'o that I can pull, but don''t count on any miracles.',0
L0FFA:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN1_003
	call	Say
	jmp	SHORT L1049

T_SIN1_003	LABEL	BYTE
	DB	'#SIN1\SIN1_003#Isolate that virus. That''s your number one priori'
	DB	'ty.',0
L1049:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_SIN1_S17
	call	Say
	jmp	SHORT L109C

T_SIN1_S17	LABEL	BYTE
	DB	'#SIN1\SIN1_S17#That it is, Captain. We''ll keep you informed. Sco'
	DB	'tt out.',0
L109C:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+scott_virus], 1
	mov	byte ptr [si+RS_BUSY], 0
L10A9:
	retf

H_10AA:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_1156
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN1_006
	call	Say
	jmp	SHORT L1102

T_SIN1_006	LABEL	BYTE
	DB	'#SIN1\SIN1_006#Well, we won''t be able to phaser any outbound mis'
	DB	'siles.',0
L1102:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN1_027
	call	Say
	jmp	SHORT L1155

T_SIN1_027	LABEL	BYTE
	DB	'#SIN1\SIN1_027#It appears that our mission has increased in impo'
	DB	'rtance.',0
L1155:
	retf

H_1156:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_11D0
TalkToSpockNever:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN1_025
	call	Say
	jmp	SHORT L11CF

T_SIN1_025	LABEL	BYTE
	DB	'#SIN1\SIN1_025#We should carefully consider everything we know a'
	DB	'bout this culture before taking action.',0
L11CF:
	retf

H_11D0:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_1258
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN1_015
	call	Say
	jmp	SHORT L1257

T_SIN1_015	LABEL	BYTE
	DB	'#SIN1\SIN1_015#We should stay inside as much as possible. We mus'
	DB	't try to protect ourselves from the cosmic radiation.',0
L1257:
	retf

H_1258:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_138E
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN1_030
	call	Say
	jmp	SHORT L12C1

T_SIN1_030	LABEL	BYTE
	DB	'#SIN1\SIN1_030#This door is huge. If they were humanoid, they co'
	DB	'uld have been giants...',0
L12C1:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN1_026
	call	Say
	JMPN	L135F

T_SIN1_026	LABEL	BYTE
	DB	'#SIN1\SIN1_026#From what we know about the Lucrs, they had an af'
	DB	'finity for size. Their machines weren''t just equipment; they wer'
	DB	'e also monuments.',0
L135F:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN1_029
	call	Say
	jmp	SHORT L138D

T_SIN1_029	LABEL	BYTE
	DB	'#SIN1\SIN1_029#I can believe that.',0
L138D:
	retf

H_138E:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_13FA
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_SIN1N005
	call	Say
	jmp	SHORT L13F9

T_SIN1N005	LABEL	BYTE
	DB	'#SIN1\SIN1N005#James T. Kirk, A man with a problem. A big proble'
	DB	'm that is getting bigger.',0
L13F9:
	retf

H_13FA:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_1481
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_SIN1N004
	call	Say
	jmp	SHORT L1480

T_SIN1N004	LABEL	BYTE
	DB	'#SIN1\SIN1N004#It never ceases to amaze you how passive Spock ca'
	DB	'n be, even in the presence of extraordinary wonders.',0
L1480:
	retf

H_1481:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_14E5
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_SIN1N006
	call	Say
	jmp	SHORT L14E4

T_SIN1N006	LABEL	BYTE
	DB	'#SIN1\SIN1N006#McCoy is examining himself for cosmic radiation s'
	DB	'ickness symptoms.',0
L14E4:
	retf

H_14E5:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_1554
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_SIN1N002
	call	Say
	jmp	SHORT L1553

T_SIN1N002	LABEL	BYTE
	DB	'#SIN1\SIN1N002#Ensign Mosher is glad to be a member of this land'
	DB	'ing party, at least for now.',0
L1553:
	retf

H_1554:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_159B
LookAtDoorway:
	mov	ax, 0
	mov	bx, OFFSET T_SIN1N008
	call	Say
	jmp	SHORT L159A

T_SIN1N008	LABEL	BYTE
	DB	'#SIN1\SIN1N008#The doorway into the complex is huge.',0
L159A:
	retf

H_159B:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_15F6
LookAtLens:
	mov	ax, 0
	mov	bx, OFFSET T_SIN1N000
	call	Say
	jmp	SHORT L15F5

T_SIN1N000	LABEL	BYTE
	DB	'#SIN1\SIN1N000#A lens sits above the doorway, but is it mere dec'
	DB	'oration?',0
L15F5:
	retf

H_15F6:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_1848
UseCommunicator:
	cmp	byte ptr [si+virus_found], 0
	je	L1605
	JMPN	L1808

L1605:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN1_008
	call	Say
	jmp	SHORT L163A

T_SIN1_008	LABEL	BYTE
	DB	'#SIN1\SIN1_008#Your situation, Mr. Scott?',0
L163A:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_SIN1_S51
	call	Say
	JMPN	L16F4

T_SIN1_S51	LABEL	BYTE
	DB	'#SIN1\SIN1_S51#We''re still looking for the virus, Captain. I eve'
	DB	'n have Lieutenant Uhura looking through the computer system. I n'
	DB	'ever realized the lass was so good with them.',0
L16F4:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN1_002
	call	Say
	jmp	SHORT L1775

T_SIN1_002	LABEL	BYTE
	DB	'#SIN1\SIN1_002#Check her record, Mr. Scott. She was in the top t'
	DB	'en percent of her class in computer systems analysis.',0
L1775:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_SIN1_S20
	call	Say
	jmp	SHORT L17C9

T_SIN1_S20	LABEL	BYTE
	DB	'#SIN1\SIN1_S20#We''ll find that virus soon Captain, or I''m an Eng'
	DB	'lishman.',0
L17C9:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN1_004
	call	Say
	jmp	SHORT L1808

T_SIN1_004	LABEL	BYTE
	DB	'#SIN1\SIN1_004#Just do your best, Scotty. Kirk out.',0
L1808:
	cmp	byte ptr [si+virus_found], 1
	jne	L1847
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_SIN1U070
	call	Say
	jmp	SHORT L1847

T_SIN1U070	LABEL	BYTE
	DB	'#SIN1\SIN1U070#Nothing new to report Captain.',0
L1847:
	retf

H_1848:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_KIRK, 0, H_1850
	jmp	SHORT MedkitOnSpock

H_1850:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_SPOCK, 0, H_1858
MedkitOnSpock:
	jmp	SHORT MedkitOnMcCoy

H_1858:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_MCCOY, 0, H_1860
MedkitOnMcCoy:
	jmp	SHORT MedkitOnRedshirt

H_1860:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_REDSHIRT, 0, H_18DA
MedkitOnRedshirt:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN1_014
	call	Say
	jmp	SHORT L18D9

T_SIN1_014	LABEL	BYTE
	DB	'#SIN1\SIN1_014#There''s not much I can do for cosmic radiation. I'
	DB	't''s best if we find some cover indoors.',0
L18D9:
	retf

H_18DA:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_KIRK, 0, H_18E2
	jmp	SHORT McCoyScansRedshirt

H_18E2:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_SPOCK, 0, H_18EA
	jmp	SHORT McCoyScansRedshirt

H_18EA:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_MCCOY, 0, H_18F2
	jmp	SHORT McCoyScansRedshirt

H_18F2:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_REDSHIRT, 0, H_1961
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
	mov	bx, OFFSET T_SIN1_013
	call	Say
	jmp	SHORT L1960

T_SIN1_013	LABEL	BYTE
	DB	'#SIN1\SIN1_013#No appreciable cosmic radiation damage. Yet.',0
L1960:
	retf

; Walking through the open door (room 2).
H_1961:
	SCRIPT	MSG_WALK, 20h, 0, 0, H_198A
WalkInside:
	cmp	byte ptr [si+door_open1], 1
	jne	L1989
	mov	ax, 5
	push	ax
	mov	ax, 9Eh
	push	ax
	mov	ax, 98h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 152, 158, 5)
	add	sp, 0Ah
L1989:
	retf

H_198A:
	SCRIPT	MSG_WALK, 8, 0, 0, rdf_scripts_end
WalkInside2:
	cmp	byte ptr [si+door_open1], 1
	jne	L19B2
	mov	ax, 5
	push	ax
	mov	ax, 9Eh
	push	ax
	mov	ax, 98h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 152, 158, 5)
	add	sp, 0Ah
L19B2:
	retf

rdf_scripts_end	LABEL	BYTE

RDF	ENDS
	END
