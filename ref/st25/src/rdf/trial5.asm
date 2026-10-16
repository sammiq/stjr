; TRIAL5.RDF - "The Feathered Serpent", the heart of Hrakkour, reached by
; the Test of Life's other door (room 1). A machine of the planet's dead
; builders takes three gems, from nine (rubies, emeralds, sapphires) in
; three holes: their colours light the Light of War, Knowledge or
; Travel. The right combination primes the neural interlink, through which
; Bialbi, the last of Hrakkour, judges Vlict for destroying it.
;
; Actors: 9 the interface, 14-22 (0Eh-16h) the gems, 23 (17h) Vlict.
; Objects: 9 the platform, 0Eh-16h the gems, 21h-23h the holes, 24h the
; interface.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The conversation at 00CA is built at run time.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
score	EQU	RS_VARS+0	; word: the mission's score
interlink_primed	EQU	RS_VARS+1Ah	; the Light of Knowledge has primed the neural interlink
hole1	EQU	RS_VARS+1Bh	; word: the gem in the first hole, its object number (0Eh-16h); 0 none
hole2	EQU	RS_VARS+1Dh	; word: the second hole
hole3	EQU	RS_VARS+1Fh	; word: the third hole
ending	EQU	RS_VARS+36h	; word: how it ended, for room 9: 0 Kirk let the trial run, 1 he beamed back mid-trial, 2 Quetzecoatl was lost, 3 the Klingons leave, 4 Vlict was executed
primed_scored	EQU	RS_VARS+3Ah	; the point for priming the interlink

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
	DW	104,137, 132,137, 170,137, 201,137	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	160,140, 150,140, 170,150, 160,150
talk_buf	LABEL	BYTE
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0
choice_jumps	LABEL	BYTE
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0
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
N_Ensign_Bennie	LABEL	BYTE
	DB	'Ensign Bennie',0
	DB	'Lt. Uhura',0
N_Light_of_War	LABEL	BYTE
	DB	'Light of War',0
N_Light_of_Knowledge	LABEL	BYTE
	DB	'Light of Knowledge',0
N_Light_of_Travel	LABEL	BYTE
	DB	'Light of Travel',0
N_A_Voice_Speaks	LABEL	BYTE
	DB	'A Voice Speaks',0
N_Bialbi	LABEL	BYTE
	DB	'Bialbi',0
N_Vlict	LABEL	BYTE
	DB	'Vlict',0
rdf_objects	LABEL	BYTE
	DW	20h, 6	; id, points
	DW	120,120, 180,120, 188,139, 188,164, 113,164, 113,139
	DW	21h, 4	; id, points
	DW	39,109, 53,109, 53,115, 39,115
	DW	22h, 4	; id, points
	DW	27,116, 41,116, 41,122, 27,122
	DW	23h, 4	; id, points
	DW	53,116, 67,116, 67,122, 53,122
	DW	24h, 4	; id, points
	DW	250,63, 285,63, 285,144, 250,144
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	250,145, 285,145, 285,158, 250,158
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	'trl5',0

rdf_scripts:
rdf_bans_end:
; The room starts: the nine gems.
H_021B:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0370
StartRoom:
	jmp	SHORT L022C

N_TRI5LOOP	LABEL	BYTE
	DB	'TRI5LOOP',0
L022C:
	push	OFFSET N_TRI5LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("TRI5LOOP")
	add	sp, 4
	mov	ax, -1
	push	ax
	mov	ax, 1Fh
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(31, -1)
	add	sp, 6
	jmp	SHORT L0258

N_redgem	LABEL	BYTE
	DB	'redgem',0
L0258:
	push	0
	push	98h
	push	82h
	push	OFFSET N_redgem
	push	0Eh
	push	RC_ANIM2
	SERVICE		; Anim(14, "redgem", 130, 152, 0)
	add	sp, 0Ch
	jmp	SHORT L0278

N_redgem_2	LABEL	BYTE
	DB	'redgem',0
L0278:
	push	0
	push	9Eh
	push	81h
	push	OFFSET N_redgem_2
	push	0Fh
	push	RC_ANIM2
	SERVICE		; Anim(15, "redgem", 129, 158, 0)
	add	sp, 0Ch
	jmp	SHORT L0298

N_redgem_3	LABEL	BYTE
	DB	'redgem',0
L0298:
	push	0
	push	0A5h
	push	80h
	push	OFFSET N_redgem_3
	push	10h
	push	RC_ANIM2
	SERVICE		; Anim(16, "redgem", 128, 165, 0)
	add	sp, 0Ch
	jmp	SHORT L02B8

N_grngem	LABEL	BYTE
	DB	'grngem',0
L02B8:
	push	0
	push	98h
	push	97h
	push	OFFSET N_grngem
	push	11h
	push	RC_ANIM2
	SERVICE		; Anim(17, "grngem", 151, 152, 0)
	add	sp, 0Ch
	jmp	SHORT L02D8

N_grngem_2	LABEL	BYTE
	DB	'grngem',0
L02D8:
	push	0
	push	9Eh
	push	97h
	push	OFFSET N_grngem_2
	push	12h
	push	RC_ANIM2
	SERVICE		; Anim(18, "grngem", 151, 158, 0)
	add	sp, 0Ch
	jmp	SHORT L02F8

N_grngem_3	LABEL	BYTE
	DB	'grngem',0
L02F8:
	push	0
	push	0A5h
	push	97h
	push	OFFSET N_grngem_3
	push	13h
	push	RC_ANIM2
	SERVICE		; Anim(19, "grngem", 151, 165, 0)
	add	sp, 0Ch
	jmp	SHORT L0318

N_blugem	LABEL	BYTE
	DB	'blugem',0
L0318:
	push	0
	push	98h
	push	0ABh
	push	OFFSET N_blugem
	push	14h
	push	RC_ANIM2
	SERVICE		; Anim(20, "blugem", 171, 152, 0)
	add	sp, 0Ch
	jmp	SHORT L0338

N_blugem_2	LABEL	BYTE
	DB	'blugem',0
L0338:
	push	0
	push	9Eh
	push	0ACh
	push	OFFSET N_blugem_2
	push	15h
	push	RC_ANIM2
	SERVICE		; Anim(21, "blugem", 172, 158, 0)
	add	sp, 0Ch
	jmp	SHORT L0358

N_blugem_3	LABEL	BYTE
	DB	'blugem',0
L0358:
	push	0
	push	0A5h
	push	0ADh
	push	OFFSET N_blugem_3
	push	16h
	push	RC_ANIM2
	SERVICE		; Anim(22, "blugem", 173, 165, 0)
	add	sp, 0Ch
	retf

; Tick 60: the crew on the alien chamber.
H_0370:
	SCRIPT	MSG_TICK, 3Ch, 0, 0, H_04D1
FirstSight:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI5_052
	call	Say
	jmp	SHORT L03A4

T_TRI5_052	LABEL	BYTE
	DB	'#TRI5\TRI5_052#What is this place?',0
L03A4:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI5_017
	call	Say
	jmp	SHORT L03E7

T_TRI5_017	LABEL	BYTE
	DB	'#TRI5\TRI5_017#This is not Klingon technology, Captain.',0
L03E7:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI5_014
	call	Say
	jmp	SHORT L042E

T_TRI5_014	LABEL	BYTE
	DB	'#TRI5\TRI5_014#Even I can see that, you pointy-eared freak!',0
L042E:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI5_002
	call	Say
	JMPN	L04D0

T_TRI5_002	LABEL	BYTE
	DB	'#TRI5\TRI5_002#Gentlemen, I suggest we start trying to find out '
	DB	'what this is. I have a feeling we''ve come some place Vlict wasn'''
	DB	't expecting us to go.',0
L04D0:
	retf

; Bialbi brings Vlict before the interlink (anim msg 1) and tries him:
; Kirk's answers decide between mercy (the Klingons leave, ending 3) and
; Vlict's execution (ending 4).
H_04D1:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_101A
BialbiJudgesVlict:
	mov	ax, OFFSET N_Bialbi
	mov	bx, OFFSET T_TRI5_027
	call	Say
	JMPN	L059C

T_TRI5_027	LABEL	BYTE
	DB	'#TRI5\TRI5_027#Admiral Vlict, this is the defensive system of Hr'
	DB	'akkour. You have engaged in genocidal activities on this world. '
	DB	'Have you anything to say before your sentence is passed?',0
L059C:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI5_020
	call	Say
	jmp	SHORT L05D0

T_TRI5_020	LABEL	BYTE
	DB	'#TRI5\TRI5_020#Kirk! This is your doing!',0
L05D0:
	mov	ax, OFFSET N_Bialbi
	mov	bx, OFFSET T_TRI5_031
	call	Say
	JMPN	L0698

T_TRI5_031	LABEL	BYTE
	DB	'#TRI5\TRI5_031#No, Admiral, it is not, but that will suffice as '
	DB	'a final public statement. The sentence is banishment, to you and'
	DB	' all members of your crew who were involved in this action.',0
L0698:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI5_022
	call	Say
	jmp	SHORT L06CF

T_TRI5_022	LABEL	BYTE
	DB	'#TRI5\TRI5_022#You have no right to try me!',0
L06CF:
	mov	ax, OFFSET N_Bialbi
	mov	bx, OFFSET T_TRI5_029
	call	Say
	JMPN	L0772

T_TRI5_029	LABEL	BYTE
	DB	'#TRI5\TRI5_029#I have as much right as you to conduct trials on '
	DB	'this planet. You showed no justice to your victim. The penalty f'
	DB	'or injustice is death.',0
L0772:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI5_018
	call	Say
	jmp	SHORT L0792

T_TRI5_018	LABEL	BYTE
	DB	'#TRI5\TRI5_018#Kirk!',0
L0792:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L07EB

T_TRI5_003	LABEL	BYTE
	DB	'#TRI5\TRI5_003#Hoist on your own petard, eh, Vlict? Do you want '
	DB	'me to help you?',0
L07EB:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI5_003
	mov	word ptr cs:choice_jumps, OFFSET L08F9
	jmp	SHORT L0859

T_TRI5_008	LABEL	BYTE
	DB	'#TRI5\TRI5_008#You tried to send me to my death. Now you can rot'
	DB	' as you get what you deserve.',0
L0859:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI5_008
	mov	word ptr cs:choice_jumps+2, OFFSET L0AAF
	jmp	SHORT L08CE

T_TRI5_006	LABEL	BYTE
	DB	'#TRI5\TRI5_006#If I have your word that Quetzecoatl goes free, I'
	DB	'''m willing to intervene to save you.',0
L08CE:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI5_006
	mov	word ptr cs:choice_jumps+4, OFFSET L0B76
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L08F9:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI5_023
	call	Say
	jmp	SHORT L095E

T_TRI5_023	LABEL	BYTE
	DB	'#TRI5\TRI5_023#You want me to beg like a weakling child cowering'
	DB	' before his betters!',0
L095E:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI5_015
	call	Say
	jmp	SHORT L09AF

T_TRI5_015	LABEL	BYTE
	DB	'#TRI5\TRI5_015#He really doesn''t have a likable personality, doe'
	DB	's he?',0
L09AF:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L0A0F

T_TRI5_009	LABEL	BYTE
	DB	'#TRI5\TRI5_009#You tried to eliminate me. Now you can rot as you'
	DB	' get what you deserve.',0
L0A0F:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI5_009
	mov	word ptr cs:choice_jumps, OFFSET L0AAF
	jmp	SHORT L0A84

T_TRI5_007	LABEL	BYTE
	DB	'#TRI5\TRI5_007#If I have your word that Quetzecoatl goes free, I'
	DB	'''m willing to intervene to save you.',0
L0A84:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI5_007
	mov	word ptr cs:choice_jumps+2, OFFSET L0B76
	mov	word ptr cs:talk_buf+6, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L0AAF:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Bialbi
	mov	bx, OFFSET T_TRI5_034
	call	Say
	JMPN	L0B5A

T_TRI5_034	LABEL	BYTE
	DB	'#TRI5\TRI5_034#You will be returned to your ship, Captain. As wi'
	DB	'll the creature who was unfairly punished. You need not witness '
	DB	'the Klingon''s punishment.',0
L0B5A:
	mov	si, word ptr cs:rdf_state
	mov	word ptr [si+ending], 4
	push	4
	push	1
	push	word ptr [si+score]
	push	RC_BEAMUP
	SERVICE		; BeamUp(?, 1, 4)
	add	sp, 8
	retf

L0B76:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI5_019
	call	Say
	jmp	SHORT L0B9D

T_TRI5_019	LABEL	BYTE
	DB	'#TRI5\TRI5_019#Agreed!',0
L0B9D:
	mov	ax, -1
	push	ax
	mov	ax, 1Ch
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(28, -1)
	add	sp, 6
	mov	ax, OFFSET N_Bialbi
	mov	bx, OFFSET T_TRI5_025
	call	Say
	jmp	SHORT L0C11

T_TRI5_025	LABEL	BYTE
	DB	'#TRI5\TRI5_025#A life for a life is a just bargain. But his crim'
	DB	'es are beyond count.',0
L0C11:
	add	word ptr [si+score], 4
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI5_004
	call	Say
	jmp	SHORT L0C60

T_TRI5_004	LABEL	BYTE
	DB	'#TRI5\TRI5_004#I do not see what can be served by more killing.',0
L0C60:
	mov	ax, OFFSET N_Bialbi
	mov	bx, OFFSET T_TRI5_030
	call	Say
	jmp	SHORT L0CC9

T_TRI5_030	LABEL	BYTE
	DB	'#TRI5\TRI5_030#Idealism! An advanced concept! Naive, perhaps, bu'
	DB	't charming in its simplicity.',0
L0CC9:
	mov	ax, OFFSET N_Bialbi
	mov	bx, OFFSET T_TRI5_026
	call	Say
	JMPN	L0D94

T_TRI5_026	LABEL	BYTE
	DB	'#TRI5\TRI5_026#Admiral Vlict, the entity Quetzecoatl shall be se'
	DB	't free. If you ever return to this sector, the sentence shall be'
	DB	' carried out. No Klingon vessel may ever return to this world.',0
L0D94:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI5_021
	call	Say
	jmp	SHORT L0DD7

T_TRI5_021	LABEL	BYTE
	DB	'#TRI5\TRI5_021#Rrrrr. Very well. I agree to your terms.',0
L0DD7:
	mov	ax, OFFSET N_Bialbi
	mov	bx, OFFSET T_TRI5_028
	call	Say
	jmp	SHORT L0E44

T_TRI5_028	LABEL	BYTE
	DB	'#TRI5\TRI5_028#As for you, Captain, you may return. I find your '
	DB	'social development most pleasing.',0
L0E44:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI5_005
	call	Say
	JMPN	L0EEA

T_TRI5_005	LABEL	BYTE
	DB	'#TRI5\TRI5_005#I fear that politics will make it impossible. You'
	DB	'r planet is in Klingon space. But I don''t understand why the Kli'
	DB	'ngons never detected you.',0
L0EEA:
	mov	ax, OFFSET N_Bialbi
	mov	bx, OFFSET T_TRI5_033
	call	Say
	JMPN	L0F96

T_TRI5_033	LABEL	BYTE
	DB	'#TRI5\TRI5_033#Their archeological digs did come close, Captain,'
	DB	' but I am very elusive. I waited and monitored the situation and'
	DB	' chose to reveal myself to you.',0
L0F96:
	mov	ax, OFFSET N_Bialbi
	mov	bx, OFFSET T_TRI5_032
	call	Say
	jmp	SHORT L0FFF

T_TRI5_032	LABEL	BYTE
	DB	'#TRI5\TRI5_032#Now, you may go. Heed my warning Vlict. I shall n'
	DB	'ot be merciful a second time.',0
L0FFF:
	mov	si, word ptr cs:rdf_state
	mov	word ptr [si+ending], 3
	push	3
	push	1
	push	1
	push	RC_BEAMUP
	SERVICE		; BeamUp(1, 1, 3)
	add	sp, 8
	retf

; The interface (msg 2): unprimed, it refuses; primed, Bialbi speaks
; (+5) and calls Vlict in.
H_101A:
	SCRIPT	MSG_USE, OBJ_KIRK, 24h, 0, H_103D
KirkToInterface:
	mov	ax, 2
	push	ax
	mov	ax, 96h
	push	ax
	mov	ax, 106h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 262, 150, 2)
	add	sp, 0Ah
	retf

H_103D:
	SCRIPT	MSG_WALK, 24h, 0, 0, H_1060
WalkToInterface:
	mov	ax, 2
	push	ax
	mov	ax, 96h
	push	ax
	mov	ax, 106h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 262, 150, 2)
	add	sp, 0Ah
	retf

H_1060:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_138A
AtInterface:
	cmp	byte ptr [si+interlink_primed], 1
	je	L10A8
	mov	ax, OFFSET N_A_Voice_Speaks
	mov	bx, OFFSET T_TRI5_035
	call	Say
	jmp	SHORT L10A7

T_TRI5_035	LABEL	BYTE
	DB	'#TRI5\TRI5_035#Not primed for neural interlink.',0
L10A7:
	retf

L10A8:
	mov	ax, OFFSET N_Bialbi
	mov	bx, OFFSET T_TRI5_024
	call	Say
	JMPN	L1140

T_TRI5_024	LABEL	BYTE
	DB	'#TRI5\TRI5_024#This is Bialbi, the most advanced lifeform on thi'
	DB	's world. Thank you for informing us of the situation. It shall b'
	DB	'e resolved.',0
L1140:
	jmp	SHORT L1149

N_vlict1	LABEL	BYTE
	DB	'vlict1',0
L1149:
	push	1
	push	91h
	push	0BEh
	push	OFFSET N_vlict1
	push	17h
	push	RC_ANIM2
	SERVICE		; Anim(23, "vlict1", 190, 145, 1)
	add	sp, 0Ch
	add	word ptr [si+score], 5
	mov	ax, -1
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(1, -1)
	add	sp, 6
	retf

L1179:
	mov	byte ptr [si+RS_BUSY], 1
	mov	si, word ptr cs:rdf_state
	mov	ax, word ptr cs:take_object
	cmp	ax, word ptr [si+hole1]
	jne	L11C1
	mov	word ptr [si+hole1], 0
	mov	byte ptr [si+interlink_primed], 0
	mov	ax, 9
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(9)
	add	sp, 4
	mov	ax, 1Eh
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 2Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 44, 159, 30)
	add	sp, 0Ah
	retf

L11C1:
	mov	si, word ptr cs:rdf_state
	cmp	ax, word ptr [si+hole2]
	jne	L1201
	mov	word ptr [si+hole2], 0
	mov	byte ptr [si+interlink_primed], 0
	mov	ax, 9
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(9)
	add	sp, 4
	mov	ax, 1Eh
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 22h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 34, 159, 30)
	add	sp, 0Ah
	retf

L1201:
	mov	si, word ptr cs:rdf_state
	cmp	ax, word ptr [si+hole3]
	jne	L1241
	mov	word ptr [si+hole3], 0
	mov	byte ptr [si+interlink_primed], 0
	mov	ax, 9
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(9)
	add	sp, 4
	mov	ax, 1Eh
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 3Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 60, 159, 30)
	add	sp, 0Ah
	retf

L1241:
	cmp	word ptr cs:take_object, 0Eh
	jne	L1265
	mov	ax, 1Eh
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 80h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 128, 170, 30)
	add	sp, 0Ah
L1265:
	cmp	word ptr cs:take_object, 0Fh
	jne	L1289
	mov	ax, 1Eh
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 80h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 128, 170, 30)
	add	sp, 0Ah
L1289:
	cmp	word ptr cs:take_object, 10h
	jne	L12AD
	mov	ax, 1Eh
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 80h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 128, 170, 30)
	add	sp, 0Ah
L12AD:
	cmp	word ptr cs:take_object, 11h
	jne	L12D1
	mov	ax, 1Eh
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 95h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 149, 170, 30)
	add	sp, 0Ah
L12D1:
	cmp	word ptr cs:take_object, 12h
	jne	L12F5
	mov	ax, 1Eh
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 95h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 149, 170, 30)
	add	sp, 0Ah
L12F5:
	cmp	word ptr cs:take_object, 13h
	jne	L1319
	mov	ax, 1Eh
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 95h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 149, 170, 30)
	add	sp, 0Ah
L1319:
	cmp	word ptr cs:take_object, 14h
	jne	L133D
	mov	ax, 1Eh
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 0ADh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 173, 170, 30)
	add	sp, 0Ah
L133D:
	cmp	word ptr cs:take_object, 15h
	jne	L1361
	mov	ax, 1Eh
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 0ADh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 173, 170, 30)
	add	sp, 0Ah
L1361:
	cmp	word ptr cs:take_object, 16h
	jne	L1385
	mov	ax, 1Eh
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 0ADh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 173, 170, 30)
	add	sp, 0Ah
L1385:
	retf

; In the room file, so these start again each time the room loads
take_item	LABEL	BYTE	; word: the gem being taken back, as an item
	DB	0, 0
take_object	LABEL	BYTE	; word: and as an object
	DB	0, 0

H_138A:
	SCRIPT	MSG_WALK_DONE, 1Eh, 0, 0, H_13AF
KirkAtHoles:
	jmp	SHORT L1399

N_kusemn	LABEL	BYTE
	DB	'kusemn',0
L1399:
	push	1Fh
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 31)
	add	sp, 0Ch
	retf

H_13AF:
	SCRIPT	MSG_ANIM_DONE, 1Fh, 0, 0, H_13D8
GemTakenBack:
	mov	ax, word ptr cs:take_item
	push	ax
	push	RC_GIVEITEM
	SERVICE		; GiveItem(?)
	add	sp, 4
	mov	ax, word ptr cs:take_object
	push	ax
	push	RC_STOPANIM
	SERVICE		; StopAnim(?)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Taking a gem back out of a hole (msgs 30, 31).
H_13D8:
	SCRIPT	MSG_GET, 0Eh, 0, 0, H_13F0
GetRuby1:
	mov	word ptr cs:take_item, 6Ah
	mov	word ptr cs:take_object, 0Eh
	JMPN	L1179

	DB	0CBh

H_13F0:
	SCRIPT	MSG_GET, 0Fh, 0, 0, H_1408
GetRuby2:
	mov	word ptr cs:take_item, 6Bh
	mov	word ptr cs:take_object, 0Fh
	JMPN	L1179

	DB	0CBh

H_1408:
	SCRIPT	MSG_GET, 10h, 0, 0, H_1420
GetRuby3:
	mov	word ptr cs:take_item, 6Ch
	mov	word ptr cs:take_object, 10h
	JMPN	L1179

	DB	0CBh

H_1420:
	SCRIPT	MSG_GET, 11h, 0, 0, H_1438
GetEmerald1:
	mov	word ptr cs:take_item, 6Dh
	mov	word ptr cs:take_object, 11h
	JMPN	L1179

	DB	0CBh

H_1438:
	SCRIPT	MSG_GET, 12h, 0, 0, H_1450
GetEmerald2:
	mov	word ptr cs:take_item, 6Eh
	mov	word ptr cs:take_object, 12h
	JMPN	L1179

	DB	0CBh

H_1450:
	SCRIPT	MSG_GET, 13h, 0, 0, H_1468
GetEmerald3:
	mov	word ptr cs:take_item, 6Fh
	mov	word ptr cs:take_object, 13h
	JMPN	L1179

	DB	0CBh

H_1468:
	SCRIPT	MSG_GET, 14h, 0, 0, H_1480
GetSapphire1:
	mov	word ptr cs:take_item, 70h
	mov	word ptr cs:take_object, 14h
	JMPN	L1179

	DB	0CBh

H_1480:
	SCRIPT	MSG_GET, 15h, 0, 0, H_1498
GetSapphire2:
	mov	word ptr cs:take_item, 71h
	mov	word ptr cs:take_object, 15h
	JMPN	L1179

	DB	0CBh

H_1498:
	SCRIPT	MSG_GET, 16h, 0, 0, H_14B0
GetSapphire3:
	mov	word ptr cs:take_item, 72h
	mov	word ptr cs:take_object, 16h
	JMPN	L1179

	DB	0CBh

H_14B0:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_14F4
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N005
	call	Say
	jmp	SHORT L14F3

T_TRI5N005	LABEL	BYTE
	DB	'#TRI5\TRI5N005#James T. Kirk, hero of the galaxy!',0
L14F3:
	retf

H_14F4:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_1536
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N009
	call	Say
	jmp	SHORT L1535

T_TRI5N009	LABEL	BYTE
	DB	'#TRI5\TRI5N009#Your ever logical friend, Spock.',0
L1535:
	retf

H_1536:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_157E
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N008
	call	Say
	jmp	SHORT L157D

T_TRI5N008	LABEL	BYTE
	DB	'#TRI5\TRI5N008#Your ever emotional friend, Dr. McCoy.',0
L157D:
	retf

H_157E:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_15C9
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N010
	call	Say
	jmp	SHORT L15C8

T_TRI5N010	LABEL	BYTE
	DB	'#TRI5\TRI5N010#Your ever nervous crewman, Ensign Bennie.',0
L15C8:
	retf

; Looking, scanning and talking.
H_15C9:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_160C
LookAtPlatform:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N002
	call	Say
	jmp	SHORT L160B

T_TRI5N002	LABEL	BYTE
	DB	'#TRI5\TRI5N002#A platform emitting a beam light.',0
L160B:
	retf

H_160C:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_1645
LookAtInterface:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N004
	call	Say
	jmp	SHORT L1644

T_TRI5N004	LABEL	BYTE
	DB	'#TRI5\TRI5N004#A strange yellow light.',0
L1644:
	retf

H_1645:
	SCRIPT	MSG_USE, IT_STRICOR, 24h, 0, H_16F5
SpockScansInterface:
	mov	byte ptr [si+RS_FALL+1], 2
	jmp	SHORT L1658

N_sscane	LABEL	BYTE
	DB	'sscane',0
L1658:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscane
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscane", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI5_010
	call	Say
	jmp	SHORT L16F4

T_TRI5_010	LABEL	BYTE
	DB	'#TRI5\TRI5_010#Captain, it seems to be some sort of interface de'
	DB	'vice, but I do not know how to activate it.',0
L16F4:
	retf

H_16F5:
	SCRIPT	MSG_USE, IT_MTRICOR, 24h, 0, H_1788
McCoyScansInterface:
	mov	byte ptr [si+RS_FALL+2], 2
	jmp	SHORT L1708

N_mscane	LABEL	BYTE
	DB	'mscane',0
L1708:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscane
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscane", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI5_011
	call	Say
	jmp	SHORT L1787

T_TRI5_011	LABEL	BYTE
	DB	'#TRI5\TRI5_011#Jim, I have no idea what it is. Why don''t you try'
	DB	' asking Spock.',0
L1787:
	retf

H_1788:
	SCRIPT	MSG_LOOK, 0Eh, 0, 0, H_17FC
LookAtRuby1:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N013
	call	Say
	jmp	SHORT L17FB

T_TRI5N013	LABEL	BYTE
	DB	'#TRI5\TRI5N013#This large gem appears to be a ruby of unusual si'
	DB	'ze. This is obviously artificial.',0
L17FB:
	retf

H_17FC:
	SCRIPT	MSG_LOOK, 0Fh, 0, 0, H_1870
LookAtRuby2:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N014
	call	Say
	jmp	SHORT L186F

T_TRI5N014	LABEL	BYTE
	DB	'#TRI5\TRI5N014#This large gem appears to be a ruby of unusual si'
	DB	'ze. This is obviously artificial.',0
L186F:
	retf

H_1870:
	SCRIPT	MSG_LOOK, 10h, 0, 0, H_18E4
LookAtRuby3:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N015
	call	Say
	jmp	SHORT L18E3

T_TRI5N015	LABEL	BYTE
	DB	'#TRI5\TRI5N015#This large gem appears to be a ruby of unusual si'
	DB	'ze. This is obviously artificial.',0
L18E3:
	retf

H_18E4:
	SCRIPT	MSG_LOOK, 11h, 0, 0, H_195B
LookAtEmerald1:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N019
	call	Say
	jmp	SHORT L195A

T_TRI5N019	LABEL	BYTE
	DB	'#TRI5\TRI5N019#This large gem appears to be a emerald of unusual'
	DB	' size. This is obviously artificial.',0
L195A:
	retf

H_195B:
	SCRIPT	MSG_LOOK, 12h, 0, 0, H_19D2
LookAtEmerald2:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N020
	call	Say
	jmp	SHORT L19D1

T_TRI5N020	LABEL	BYTE
	DB	'#TRI5\TRI5N020#This large gem appears to be a emerald of unusual'
	DB	' size. This is obviously artificial.',0
L19D1:
	retf

H_19D2:
	SCRIPT	MSG_LOOK, 13h, 0, 0, H_1A49
LookAtEmerald3:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N021
	call	Say
	jmp	SHORT L1A48

T_TRI5N021	LABEL	BYTE
	DB	'#TRI5\TRI5N021#This large gem appears to be a emerald of unusual'
	DB	' size. This is obviously artificial.',0
L1A48:
	retf

H_1A49:
	SCRIPT	MSG_LOOK, 14h, 0, 0, H_1AC0
LookAtSapphire1:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N016
	call	Say
	jmp	SHORT L1ABF

T_TRI5N016	LABEL	BYTE
	DB	'#TRI5\TRI5N016#This large gem appears to be a saphire of unusual'
	DB	' size. This is obviously artificial.',0
L1ABF:
	retf

H_1AC0:
	SCRIPT	MSG_LOOK, 15h, 0, 0, H_1B37
LookAtSapphire2:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N017
	call	Say
	jmp	SHORT L1B36

T_TRI5N017	LABEL	BYTE
	DB	'#TRI5\TRI5N017#This large gem appears to be a saphire of unusual'
	DB	' size. This is obviously artificial.',0
L1B36:
	retf

H_1B37:
	SCRIPT	MSG_LOOK, 16h, 0, 0, H_1BAE
LookAtSapphire3:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N018
	call	Say
	jmp	SHORT L1BAD

T_TRI5N018	LABEL	BYTE
	DB	'#TRI5\TRI5N018#This large gem appears to be a saphire of unusual'
	DB	' size. This is obviously artificial.',0
L1BAD:
	retf

H_1BAE:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_1BB6
	jmp	SHORT LookAtHoles

H_1BB6:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_1BBE
	jmp	SHORT LookAtHoles

H_1BBE:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_1C19
LookAtHoles:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N006
	call	Say
	jmp	SHORT L1C18

T_TRI5N006	LABEL	BYTE
	DB	'#TRI5\TRI5N006#Openings on the platform. Place something in thes'
	DB	'e holes?',0
L1C18:
	retf

H_1C19:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_1C83
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI5_001
	call	Say
	jmp	SHORT L1C82

T_TRI5_001	LABEL	BYTE
	DB	'#TRI5\TRI5_001#Obviously, they want us to place the gems in the '
	DB	'holes, but which one...',0
L1C82:
	retf

H_1C83:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_1D28
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI5_016
	call	Say
	JMPN	L1D27

T_TRI5_016	LABEL	BYTE
	DB	'#TRI5\TRI5_016#I suspect Captain, that the machinery is activate'
	DB	'd by placing the gems in the proper slots. We should determine a'
	DB	' system for this.',0
L1D27:
	retf

H_1D28:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_1D6C
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI5_013
	call	Say
	jmp	SHORT L1D6B

T_TRI5_013	LABEL	BYTE
	DB	'#TRI5\TRI5_013#We''ve got to get out of here, Jim!',0
L1D6B:
	retf

H_1D6C:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_1DD2
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI5_051
	call	Say
	jmp	SHORT L1DD1

T_TRI5_051	LABEL	BYTE
	DB	'#TRI5\TRI5_051#I guess I should''ve taken a few more science cour'
	DB	'ses at the Academy.',0
L1DD1:
	retf

; The phasers, tricorders and communicator don't work here.
H_1DD2:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_1DDA
	jmp	SHORT KillAnything

H_1DDA:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_1E17
KillAnything:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N011
	call	Say
	jmp	SHORT L1E16

T_TRI5N011	LABEL	BYTE
	DB	'#TRI5\TRI5N011#Your phaser is not working.',0
L1E16:
	retf

H_1E17:
	SCRIPT	MSG_USE, IT_MTRICOR, ANY, 0, H_1E1F
	jmp	SHORT TricorderAnything

H_1E1F:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_1ED0
TricorderAnything:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L1E32

N_sscans	LABEL	BYTE
	DB	'sscans',0
L1E32:
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
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N012
	call	Say
	jmp	SHORT L1ECF

T_TRI5N012	LABEL	BYTE
	DB	'#TRI5\TRI5N012#Your tricorder''s recording functions are working,'
	DB	' but it does not seem to be able to analyze.',0
L1ECF:
	retf

H_1ED0:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_1F13
UseCommunicator:
	mov	ax, 0
	mov	bx, OFFSET T_TRI5N007
	call	Say
	jmp	SHORT L1F12

T_TRI5N007	LABEL	BYTE
	DB	'#TRI5\TRI5N007#Your communicator is not working.',0
L1F12:
	retf

; Gems in the holes (msgs 3-29): each hole takes one gem; with all three
; in, ReadGems works out their colours and lights a Light.
H_1F13:
	SCRIPT	MSG_USE, IT_REDGEM1, 21h, 0, H_1F3A
Ruby1InHole1:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 3
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 2Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 44, 159, 3)
	add	sp, 0Ah
	retf

H_1F3A:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_1F99
Ruby1Placed1:
	jmp	SHORT L1F49

N_kusehn	LABEL	BYTE
	DB	'kusehn',0
L1F49:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole1], 0
	jne	L1F98
	mov	word ptr [si+hole1], 0Eh
	jmp	SHORT L1F73

N_RedGem1	LABEL	BYTE
	DB	'RedGem1',0
L1F73:
	push	0
	push	8Eh
	push	2Eh
	push	OFFSET N_RedGem1
	push	0Eh
	push	RC_ANIM2
	SERVICE		; Anim(14, "RedGem1", 46, 142, 0)
	add	sp, 0Ch
	push	IT_REDGEM1
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_REDGEM1)
	add	sp, 4
	JMPN	ReadGems

L1F98:
	retf

H_1F99:
	SCRIPT	MSG_USE, IT_REDGEM2, 21h, 0, H_1FC0
Ruby2InHole1:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 6
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 2Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 44, 159, 6)
	add	sp, 0Ah
	retf

H_1FC0:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_201F
Ruby2Placed1:
	jmp	SHORT L1FCF

N_kusehn_2	LABEL	BYTE
	DB	'kusehn',0
L1FCF:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_2
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole1], 0
	jne	L201E
	mov	word ptr [si+hole1], 0Fh
	jmp	SHORT L1FF9

N_RedGem2	LABEL	BYTE
	DB	'RedGem2',0
L1FF9:
	push	0
	push	8Eh
	push	2Eh
	push	OFFSET N_RedGem2
	push	0Fh
	push	RC_ANIM2
	SERVICE		; Anim(15, "RedGem2", 46, 142, 0)
	add	sp, 0Ch
	push	IT_REDGEM2
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_REDGEM2)
	add	sp, 4
	JMPN	ReadGems

L201E:
	retf

H_201F:
	SCRIPT	MSG_USE, IT_REDGEM3, 21h, 0, H_2046
Ruby3InHole1:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 9
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 2Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 44, 159, 9)
	add	sp, 0Ah
	retf

H_2046:
	SCRIPT	MSG_WALK_DONE, 9, 0, 0, H_20A5
Ruby3Placed1:
	jmp	SHORT L2055

N_kusehn_3	LABEL	BYTE
	DB	'kusehn',0
L2055:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_3
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole1], 0
	jne	L20A4
	mov	word ptr [si+hole1], 10h
	jmp	SHORT L207F

N_RedGem3	LABEL	BYTE
	DB	'RedGem3',0
L207F:
	push	0
	push	8Eh
	push	2Eh
	push	OFFSET N_RedGem3
	push	10h
	push	RC_ANIM2
	SERVICE		; Anim(16, "RedGem3", 46, 142, 0)
	add	sp, 0Ch
	push	IT_REDGEM3
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_REDGEM3)
	add	sp, 4
	JMPN	ReadGems

L20A4:
	retf

H_20A5:
	SCRIPT	MSG_USE, IT_GRNGEM1, 21h, 0, H_20CC
Emerald1InHole1:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 0Ch
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 2Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 44, 159, 12)
	add	sp, 0Ah
	retf

H_20CC:
	SCRIPT	MSG_WALK_DONE, 0Ch, 0, 0, H_212B
Emerald1Placed1:
	jmp	SHORT L20DB

N_kusehn_4	LABEL	BYTE
	DB	'kusehn',0
L20DB:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_4
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole1], 0
	jne	L212A
	mov	word ptr [si+hole1], 11h
	jmp	SHORT L2105

N_GrnGem1	LABEL	BYTE
	DB	'GrnGem1',0
L2105:
	push	0
	push	8Eh
	push	2Eh
	push	OFFSET N_GrnGem1
	push	11h
	push	RC_ANIM2
	SERVICE		; Anim(17, "GrnGem1", 46, 142, 0)
	add	sp, 0Ch
	push	IT_GRNGEM1
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_GRNGEM1)
	add	sp, 4
	JMPN	ReadGems

L212A:
	retf

H_212B:
	SCRIPT	MSG_USE, IT_GRNGEM2, 21h, 0, H_2152
Emerald2InHole1:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 0Fh
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 2Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 44, 159, 15)
	add	sp, 0Ah
	retf

H_2152:
	SCRIPT	MSG_WALK_DONE, 0Fh, 0, 0, H_21B1
Emerald2Placed1:
	jmp	SHORT L2161

N_kusehn_5	LABEL	BYTE
	DB	'kusehn',0
L2161:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_5
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole1], 0
	jne	L21B0
	mov	word ptr [si+hole1], 12h
	jmp	SHORT L218B

N_GrnGem2	LABEL	BYTE
	DB	'GrnGem2',0
L218B:
	push	0
	push	8Eh
	push	2Eh
	push	OFFSET N_GrnGem2
	push	12h
	push	RC_ANIM2
	SERVICE		; Anim(18, "GrnGem2", 46, 142, 0)
	add	sp, 0Ch
	push	IT_GRNGEM2
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_GRNGEM2)
	add	sp, 4
	JMPN	ReadGems

L21B0:
	retf

H_21B1:
	SCRIPT	MSG_USE, IT_GRNGEM3, 21h, 0, H_21D8
Emerald3InHole1:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 12h
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 2Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 44, 159, 18)
	add	sp, 0Ah
	retf

H_21D8:
	SCRIPT	MSG_WALK_DONE, 12h, 0, 0, H_2237
Emerald3Placed1:
	jmp	SHORT L21E7

N_kusehn_6	LABEL	BYTE
	DB	'kusehn',0
L21E7:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_6
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole1], 0
	jne	L2236
	mov	word ptr [si+hole1], 13h
	jmp	SHORT L2211

N_GrnGem3	LABEL	BYTE
	DB	'GrnGem3',0
L2211:
	push	0
	push	8Eh
	push	2Eh
	push	OFFSET N_GrnGem3
	push	13h
	push	RC_ANIM2
	SERVICE		; Anim(19, "GrnGem3", 46, 142, 0)
	add	sp, 0Ch
	push	IT_GRNGEM3
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_GRNGEM3)
	add	sp, 4
	JMPN	ReadGems

L2236:
	retf

H_2237:
	SCRIPT	MSG_USE, IT_BLUGEM1, 21h, 0, H_225E
Sapphire1InHole1:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 15h
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 2Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 44, 159, 21)
	add	sp, 0Ah
	retf

H_225E:
	SCRIPT	MSG_WALK_DONE, 15h, 0, 0, H_22BD
Sapphire1Placed1:
	jmp	SHORT L226D

N_kusehn_7	LABEL	BYTE
	DB	'kusehn',0
L226D:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_7
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole1], 0
	jne	L22BC
	mov	word ptr [si+hole1], 14h
	jmp	SHORT L2297

N_BluGem1	LABEL	BYTE
	DB	'BluGem1',0
L2297:
	push	0
	push	8Eh
	push	2Eh
	push	OFFSET N_BluGem1
	push	14h
	push	RC_ANIM2
	SERVICE		; Anim(20, "BluGem1", 46, 142, 0)
	add	sp, 0Ch
	push	IT_BLUGEM1
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_BLUGEM1)
	add	sp, 4
	JMPN	ReadGems

L22BC:
	retf

H_22BD:
	SCRIPT	MSG_USE, IT_BLUGEM2, 21h, 0, H_22E4
Sapphire2InHole1:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 18h
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 2Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 44, 159, 24)
	add	sp, 0Ah
	retf

H_22E4:
	SCRIPT	MSG_WALK_DONE, 18h, 0, 0, H_2343
Sapphire2Placed1:
	jmp	SHORT L22F3

N_kusehn_8	LABEL	BYTE
	DB	'kusehn',0
L22F3:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_8
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole1], 0
	jne	L2342
	mov	word ptr [si+hole1], 15h
	jmp	SHORT L231D

N_BluGem2	LABEL	BYTE
	DB	'BluGem2',0
L231D:
	push	0
	push	8Eh
	push	2Eh
	push	OFFSET N_BluGem2
	push	15h
	push	RC_ANIM2
	SERVICE		; Anim(21, "BluGem2", 46, 142, 0)
	add	sp, 0Ch
	push	IT_BLUGEM2
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_BLUGEM2)
	add	sp, 4
	JMPN	ReadGems

L2342:
	retf

H_2343:
	SCRIPT	MSG_USE, IT_BLUGEM3, 21h, 0, H_236A
Sapphire3InHole1:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 1Bh
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 2Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 44, 159, 27)
	add	sp, 0Ah
	retf

H_236A:
	SCRIPT	MSG_WALK_DONE, 1Bh, 0, 0, H_23C9
Sapphire3Placed1:
	jmp	SHORT L2379

N_kusehn_9	LABEL	BYTE
	DB	'kusehn',0
L2379:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_9
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole1], 0
	jne	L23C8
	mov	word ptr [si+hole1], 16h
	jmp	SHORT L23A3

N_BluGem3	LABEL	BYTE
	DB	'BluGem3',0
L23A3:
	push	0
	push	8Eh
	push	2Eh
	push	OFFSET N_BluGem3
	push	16h
	push	RC_ANIM2
	SERVICE		; Anim(22, "BluGem3", 46, 142, 0)
	add	sp, 0Ch
	push	IT_BLUGEM3
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_BLUGEM3)
	add	sp, 4
	JMPN	ReadGems

L23C8:
	retf

H_23C9:
	SCRIPT	MSG_USE, IT_REDGEM1, 22h, 0, H_23F0
Ruby1InHole2:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 4
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 22h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 34, 159, 4)
	add	sp, 0Ah
	retf

H_23F0:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_244F
Ruby1Placed2:
	jmp	SHORT L23FF

N_kusehn_10	LABEL	BYTE
	DB	'kusehn',0
L23FF:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_10
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole2], 0
	jne	L244E
	mov	word ptr [si+hole2], 0Eh
	jmp	SHORT L2429

N_RedGem1_2	LABEL	BYTE
	DB	'RedGem1',0
L2429:
	push	0
	push	95h
	push	22h
	push	OFFSET N_RedGem1_2
	push	0Eh
	push	RC_ANIM2
	SERVICE		; Anim(14, "RedGem1", 34, 149, 0)
	add	sp, 0Ch
	push	IT_REDGEM1
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_REDGEM1)
	add	sp, 4
	JMPN	ReadGems

L244E:
	retf

H_244F:
	SCRIPT	MSG_USE, IT_REDGEM2, 22h, 0, H_2476
Ruby2InHole2:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 7
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 22h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 34, 159, 7)
	add	sp, 0Ah
	retf

H_2476:
	SCRIPT	MSG_WALK_DONE, 7, 0, 0, H_24D5
Ruby2Placed2:
	jmp	SHORT L2485

N_kusehn_11	LABEL	BYTE
	DB	'kusehn',0
L2485:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_11
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole2], 0
	jne	L24D4
	mov	word ptr [si+hole2], 0Fh
	jmp	SHORT L24AF

N_RedGem2_2	LABEL	BYTE
	DB	'RedGem2',0
L24AF:
	push	0
	push	95h
	push	22h
	push	OFFSET N_RedGem2_2
	push	0Fh
	push	RC_ANIM2
	SERVICE		; Anim(15, "RedGem2", 34, 149, 0)
	add	sp, 0Ch
	push	IT_REDGEM2
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_REDGEM2)
	add	sp, 4
	JMPN	ReadGems

L24D4:
	retf

H_24D5:
	SCRIPT	MSG_USE, IT_REDGEM3, 22h, 0, H_24FC
Ruby3InHole2:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 0Ah
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 22h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 34, 159, 10)
	add	sp, 0Ah
	retf

H_24FC:
	SCRIPT	MSG_WALK_DONE, 0Ah, 0, 0, H_255B
Ruby3Placed2:
	jmp	SHORT L250B

N_kusehn_12	LABEL	BYTE
	DB	'kusehn',0
L250B:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_12
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole2], 0
	jne	L255A
	mov	word ptr [si+hole2], 10h
	jmp	SHORT L2535

N_RedGem3_2	LABEL	BYTE
	DB	'RedGem3',0
L2535:
	push	0
	push	95h
	push	22h
	push	OFFSET N_RedGem3_2
	push	10h
	push	RC_ANIM2
	SERVICE		; Anim(16, "RedGem3", 34, 149, 0)
	add	sp, 0Ch
	push	IT_REDGEM3
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_REDGEM3)
	add	sp, 4
	JMPN	ReadGems

L255A:
	retf

H_255B:
	SCRIPT	MSG_USE, IT_GRNGEM1, 22h, 0, H_2582
Emerald1InHole2:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 0Dh
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 22h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 34, 159, 13)
	add	sp, 0Ah
	retf

H_2582:
	SCRIPT	MSG_WALK_DONE, 0Dh, 0, 0, H_25E1
Emerald1Placed2:
	jmp	SHORT L2591

N_kusehn_13	LABEL	BYTE
	DB	'kusehn',0
L2591:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_13
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole2], 0
	jne	L25E0
	mov	word ptr [si+hole2], 11h
	jmp	SHORT L25BB

N_GrnGem1_2	LABEL	BYTE
	DB	'GrnGem1',0
L25BB:
	push	0
	push	95h
	push	22h
	push	OFFSET N_GrnGem1_2
	push	11h
	push	RC_ANIM2
	SERVICE		; Anim(17, "GrnGem1", 34, 149, 0)
	add	sp, 0Ch
	push	IT_GRNGEM1
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_GRNGEM1)
	add	sp, 4
	JMPN	ReadGems

L25E0:
	retf

H_25E1:
	SCRIPT	MSG_USE, IT_GRNGEM2, 22h, 0, H_2608
Emerald2InHole2:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 10h
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 22h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 34, 159, 16)
	add	sp, 0Ah
	retf

H_2608:
	SCRIPT	MSG_WALK_DONE, 10h, 0, 0, H_2667
Emerald2Placed2:
	jmp	SHORT L2617

N_kusehn_14	LABEL	BYTE
	DB	'kusehn',0
L2617:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_14
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole2], 0
	jne	L2666
	mov	word ptr [si+hole2], 12h
	jmp	SHORT L2641

N_GrnGem2_2	LABEL	BYTE
	DB	'GrnGem2',0
L2641:
	push	0
	push	95h
	push	22h
	push	OFFSET N_GrnGem2_2
	push	12h
	push	RC_ANIM2
	SERVICE		; Anim(18, "GrnGem2", 34, 149, 0)
	add	sp, 0Ch
	push	IT_GRNGEM2
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_GRNGEM2)
	add	sp, 4
	JMPN	ReadGems

L2666:
	retf

H_2667:
	SCRIPT	MSG_USE, IT_GRNGEM3, 22h, 0, H_268E
Emerald3InHole2:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 13h
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 22h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 34, 159, 19)
	add	sp, 0Ah
	retf

H_268E:
	SCRIPT	MSG_WALK_DONE, 13h, 0, 0, H_26ED
Emerald3Placed2:
	jmp	SHORT L269D

N_kusehn_15	LABEL	BYTE
	DB	'kusehn',0
L269D:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_15
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole2], 0
	jne	L26EC
	mov	word ptr [si+hole2], 13h
	jmp	SHORT L26C7

N_GrnGem3_2	LABEL	BYTE
	DB	'GrnGem3',0
L26C7:
	push	0
	push	95h
	push	22h
	push	OFFSET N_GrnGem3_2
	push	13h
	push	RC_ANIM2
	SERVICE		; Anim(19, "GrnGem3", 34, 149, 0)
	add	sp, 0Ch
	push	IT_GRNGEM3
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_GRNGEM3)
	add	sp, 4
	JMPN	ReadGems

L26EC:
	retf

H_26ED:
	SCRIPT	MSG_USE, IT_BLUGEM1, 22h, 0, H_2714
Sapphire1InHole2:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 16h
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 22h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 34, 159, 22)
	add	sp, 0Ah
	retf

H_2714:
	SCRIPT	MSG_WALK_DONE, 16h, 0, 0, H_2773
Sapphire1Placed2:
	jmp	SHORT L2723

N_kusehn_16	LABEL	BYTE
	DB	'kusehn',0
L2723:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_16
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole2], 0
	jne	L2772
	mov	word ptr [si+hole2], 14h
	jmp	SHORT L274D

N_BluGem1_2	LABEL	BYTE
	DB	'BluGem1',0
L274D:
	push	0
	push	95h
	push	22h
	push	OFFSET N_BluGem1_2
	push	14h
	push	RC_ANIM2
	SERVICE		; Anim(20, "BluGem1", 34, 149, 0)
	add	sp, 0Ch
	push	IT_BLUGEM1
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_BLUGEM1)
	add	sp, 4
	JMPN	ReadGems

L2772:
	retf

H_2773:
	SCRIPT	MSG_USE, IT_BLUGEM2, 22h, 0, H_279A
Sapphire2InHole2:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 19h
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 22h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 34, 159, 25)
	add	sp, 0Ah
	retf

H_279A:
	SCRIPT	MSG_WALK_DONE, 19h, 0, 0, H_27F9
Sapphire2Placed2:
	jmp	SHORT L27A9

N_kusehn_17	LABEL	BYTE
	DB	'kusehn',0
L27A9:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_17
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole2], 0
	jne	L27F8
	mov	word ptr [si+hole2], 15h
	jmp	SHORT L27D3

N_BluGem2_2	LABEL	BYTE
	DB	'BluGem2',0
L27D3:
	push	0
	push	95h
	push	22h
	push	OFFSET N_BluGem2_2
	push	15h
	push	RC_ANIM2
	SERVICE		; Anim(21, "BluGem2", 34, 149, 0)
	add	sp, 0Ch
	push	IT_BLUGEM2
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_BLUGEM2)
	add	sp, 4
	JMPN	ReadGems

L27F8:
	retf

H_27F9:
	SCRIPT	MSG_USE, IT_BLUGEM3, 22h, 0, H_2820
Sapphire3InHole2:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 1Ch
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 22h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 34, 159, 28)
	add	sp, 0Ah
	retf

H_2820:
	SCRIPT	MSG_WALK_DONE, 1Ch, 0, 0, H_287F
Sapphire3Placed2:
	jmp	SHORT L282F

N_kusehn_18	LABEL	BYTE
	DB	'kusehn',0
L282F:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_18
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole2], 0
	jne	L287E
	mov	word ptr [si+hole2], 16h
	jmp	SHORT L2859

N_BluGem3_2	LABEL	BYTE
	DB	'BluGem3',0
L2859:
	push	0
	push	95h
	push	22h
	push	OFFSET N_BluGem3_2
	push	16h
	push	RC_ANIM2
	SERVICE		; Anim(22, "BluGem3", 34, 149, 0)
	add	sp, 0Ch
	push	IT_BLUGEM3
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_BLUGEM3)
	add	sp, 4
	JMPN	ReadGems

L287E:
	retf

H_287F:
	SCRIPT	MSG_USE, IT_REDGEM1, 23h, 0, H_28A6
Ruby1InHole3:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 5
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 3Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 60, 159, 5)
	add	sp, 0Ah
	retf

H_28A6:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_2905
Ruby1Placed3:
	jmp	SHORT L28B5

N_kusehn_19	LABEL	BYTE
	DB	'kusehn',0
L28B5:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_19
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole3], 0
	jne	L2904
	mov	word ptr [si+hole3], 0Eh
	jmp	SHORT L28DF

N_RedGem1_3	LABEL	BYTE
	DB	'RedGem1',0
L28DF:
	push	0
	push	95h
	push	3Ch
	push	OFFSET N_RedGem1_3
	push	0Eh
	push	RC_ANIM2
	SERVICE		; Anim(14, "RedGem1", 60, 149, 0)
	add	sp, 0Ch
	push	IT_REDGEM1
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_REDGEM1)
	add	sp, 4
	JMPN	ReadGems

L2904:
	retf

H_2905:
	SCRIPT	MSG_USE, IT_REDGEM2, 23h, 0, H_292C
Ruby2InHole3:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 8
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 3Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 60, 159, 8)
	add	sp, 0Ah
	retf

H_292C:
	SCRIPT	MSG_WALK_DONE, 8, 0, 0, H_298B
Ruby2Placed3:
	jmp	SHORT L293B

N_kusehn_20	LABEL	BYTE
	DB	'kusehn',0
L293B:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_20
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole3], 0
	jne	L298A
	mov	word ptr [si+hole3], 0Fh
	jmp	SHORT L2965

N_RedGem2_3	LABEL	BYTE
	DB	'RedGem2',0
L2965:
	push	0
	push	95h
	push	3Ch
	push	OFFSET N_RedGem2_3
	push	0Fh
	push	RC_ANIM2
	SERVICE		; Anim(15, "RedGem2", 60, 149, 0)
	add	sp, 0Ch
	push	IT_REDGEM2
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_REDGEM2)
	add	sp, 4
	JMPN	ReadGems

L298A:
	retf

H_298B:
	SCRIPT	MSG_USE, IT_REDGEM3, 23h, 0, H_29B2
Ruby3InHole3:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 0Bh
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 3Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 60, 159, 11)
	add	sp, 0Ah
	retf

H_29B2:
	SCRIPT	MSG_WALK_DONE, 0Bh, 0, 0, H_2A11
Ruby3Placed3:
	jmp	SHORT L29C1

N_kusehn_21	LABEL	BYTE
	DB	'kusehn',0
L29C1:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_21
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole3], 0
	jne	L2A10
	mov	word ptr [si+hole3], 10h
	jmp	SHORT L29EB

N_RedGem3_3	LABEL	BYTE
	DB	'RedGem3',0
L29EB:
	push	0
	push	95h
	push	3Ch
	push	OFFSET N_RedGem3_3
	push	10h
	push	RC_ANIM2
	SERVICE		; Anim(16, "RedGem3", 60, 149, 0)
	add	sp, 0Ch
	push	IT_REDGEM3
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_REDGEM3)
	add	sp, 4
	JMPN	ReadGems

L2A10:
	retf

H_2A11:
	SCRIPT	MSG_USE, IT_GRNGEM1, 23h, 0, H_2A38
Emerald1InHole3:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 0Eh
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 3Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 60, 159, 14)
	add	sp, 0Ah
	retf

H_2A38:
	SCRIPT	MSG_WALK_DONE, 0Eh, 0, 0, H_2A97
Emerald1Placed3:
	jmp	SHORT L2A47

N_kusehn_22	LABEL	BYTE
	DB	'kusehn',0
L2A47:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_22
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole3], 0
	jne	L2A96
	mov	word ptr [si+hole3], 11h
	jmp	SHORT L2A71

N_GrnGem1_3	LABEL	BYTE
	DB	'GrnGem1',0
L2A71:
	push	0
	push	95h
	push	3Ch
	push	OFFSET N_GrnGem1_3
	push	11h
	push	RC_ANIM2
	SERVICE		; Anim(17, "GrnGem1", 60, 149, 0)
	add	sp, 0Ch
	push	IT_GRNGEM1
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_GRNGEM1)
	add	sp, 4
	JMPN	ReadGems

L2A96:
	retf

H_2A97:
	SCRIPT	MSG_USE, IT_GRNGEM2, 23h, 0, H_2ABE
Emerald2InHole3:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 11h
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 3Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 60, 159, 17)
	add	sp, 0Ah
	retf

H_2ABE:
	SCRIPT	MSG_WALK_DONE, 11h, 0, 0, H_2B1D
Emerald2Placed3:
	jmp	SHORT L2ACD

N_kusehn_23	LABEL	BYTE
	DB	'kusehn',0
L2ACD:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_23
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole3], 0
	jne	L2B1C
	mov	word ptr [si+hole3], 12h
	jmp	SHORT L2AF7

N_GrnGem2_3	LABEL	BYTE
	DB	'GrnGem2',0
L2AF7:
	push	0
	push	95h
	push	3Ch
	push	OFFSET N_GrnGem2_3
	push	12h
	push	RC_ANIM2
	SERVICE		; Anim(18, "GrnGem2", 60, 149, 0)
	add	sp, 0Ch
	push	IT_GRNGEM2
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_GRNGEM2)
	add	sp, 4
	JMPN	ReadGems

L2B1C:
	retf

H_2B1D:
	SCRIPT	MSG_USE, IT_GRNGEM3, 23h, 0, H_2B44
Emerald3InHole3:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 14h
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 3Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 60, 159, 20)
	add	sp, 0Ah
	retf

H_2B44:
	SCRIPT	MSG_WALK_DONE, 14h, 0, 0, H_2BA3
Emerald3Placed3:
	jmp	SHORT L2B53

N_kusehn_24	LABEL	BYTE
	DB	'kusehn',0
L2B53:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_24
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole3], 0
	jne	L2BA2
	mov	word ptr [si+hole3], 13h
	jmp	SHORT L2B7D

N_GrnGem3_3	LABEL	BYTE
	DB	'GrnGem3',0
L2B7D:
	push	0
	push	95h
	push	3Ch
	push	OFFSET N_GrnGem3_3
	push	13h
	push	RC_ANIM2
	SERVICE		; Anim(19, "GrnGem3", 60, 149, 0)
	add	sp, 0Ch
	push	IT_GRNGEM3
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_GRNGEM3)
	add	sp, 4
	JMPN	ReadGems

L2BA2:
	retf

H_2BA3:
	SCRIPT	MSG_USE, IT_BLUGEM1, 23h, 0, H_2BCA
Sapphire1InHole3:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 17h
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 3Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 60, 159, 23)
	add	sp, 0Ah
	retf

H_2BCA:
	SCRIPT	MSG_WALK_DONE, 17h, 0, 0, H_2C29
Sapphire1Placed3:
	jmp	SHORT L2BD9

N_kusehn_25	LABEL	BYTE
	DB	'kusehn',0
L2BD9:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_25
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole3], 0
	jne	L2C28
	mov	word ptr [si+hole3], 14h
	jmp	SHORT L2C03

N_BluGem1_3	LABEL	BYTE
	DB	'BluGem1',0
L2C03:
	push	0
	push	95h
	push	3Ch
	push	OFFSET N_BluGem1_3
	push	14h
	push	RC_ANIM2
	SERVICE		; Anim(20, "BluGem1", 60, 149, 0)
	add	sp, 0Ch
	push	IT_BLUGEM1
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_BLUGEM1)
	add	sp, 4
	JMPN	ReadGems

L2C28:
	retf

H_2C29:
	SCRIPT	MSG_USE, IT_BLUGEM2, 23h, 0, H_2C50
Sapphire2InHole3:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 1Ah
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 3Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 60, 159, 26)
	add	sp, 0Ah
	retf

H_2C50:
	SCRIPT	MSG_WALK_DONE, 1Ah, 0, 0, H_2CAF
Sapphire2Placed3:
	jmp	SHORT L2C5F

N_kusehn_26	LABEL	BYTE
	DB	'kusehn',0
L2C5F:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_26
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole3], 0
	jne	L2CAE
	mov	word ptr [si+hole3], 15h
	jmp	SHORT L2C89

N_BluGem2_3	LABEL	BYTE
	DB	'BluGem2',0
L2C89:
	push	0
	push	95h
	push	3Ch
	push	OFFSET N_BluGem2_3
	push	15h
	push	RC_ANIM2
	SERVICE		; Anim(21, "BluGem2", 60, 149, 0)
	add	sp, 0Ch
	push	IT_BLUGEM2
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_BLUGEM2)
	add	sp, 4
	JMPN	ReadGems

L2CAE:
	retf

H_2CAF:
	SCRIPT	MSG_USE, IT_BLUGEM3, 23h, 0, H_2CD6
Sapphire3InHole3:
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 1Dh
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 3Ch
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 60, 159, 29)
	add	sp, 0Ah
	retf

H_2CD6:
	SCRIPT	MSG_WALK_DONE, 1Dh, 0, 0, H_38FE
Sapphire3Placed3:
	jmp	SHORT L2CE5

N_kusehn_27	LABEL	BYTE
	DB	'kusehn',0
L2CE5:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kusehn_27
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 0)
	add	sp, 0Ch
	cmp	word ptr [si+hole3], 0
	jne	L2D33
	mov	word ptr [si+hole3], 16h
	jmp	SHORT L2D0F

N_BluGem3_3	LABEL	BYTE
	DB	'BluGem3',0
L2D0F:
	push	0
	push	95h
	push	3Ch
	push	OFFSET N_BluGem3_3
	push	16h
	push	RC_ANIM2
	SERVICE		; Anim(22, "BluGem3", 60, 149, 0)
	add	sp, 0Ch
	push	IT_BLUGEM3
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_BLUGEM3)
	add	sp, 4
	jmp	SHORT ReadGems

L2D33:
	retf

colour1	LABEL	BYTE	; the first hole's gem: 1 red, 2 green, 3 blue
	DB	0
colour2	LABEL	BYTE
	DB	0
colour3	LABEL	BYTE
	DB	0
; The gems' colours (1 red, 2 green, 3 blue) in the three holes pick one of
; the 27 combinations: the first chooses the Light (War, Knowledge, Travel),
; the others what it does.
ReadGems:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr cs:colour1, 0
	mov	byte ptr cs:colour2, 0
	mov	byte ptr cs:colour3, 0
	mov	si, word ptr cs:rdf_state
	cmp	word ptr [si+hole1], 0Eh
	jne	L2D5F
	mov	byte ptr cs:colour1, 1
L2D5F:
	cmp	word ptr [si+hole1], 0Fh
	jne	L2D6B
	mov	byte ptr cs:colour1, 1
L2D6B:
	cmp	word ptr [si+hole1], 10h
	jne	L2D77
	mov	byte ptr cs:colour1, 1
L2D77:
	cmp	word ptr [si+hole2], 0Eh
	jne	L2D83
	mov	byte ptr cs:colour2, 1
L2D83:
	cmp	word ptr [si+hole2], 0Fh
	jne	L2D8F
	mov	byte ptr cs:colour2, 1
L2D8F:
	cmp	word ptr [si+hole2], 10h
	jne	L2D9B
	mov	byte ptr cs:colour2, 1
L2D9B:
	cmp	word ptr [si+hole3], 0Eh
	jne	L2DA7
	mov	byte ptr cs:colour3, 1
L2DA7:
	cmp	word ptr [si+hole3], 0Fh
	jne	L2DB3
	mov	byte ptr cs:colour3, 1
L2DB3:
	cmp	word ptr [si+hole3], 10h
	jne	L2DBF
	mov	byte ptr cs:colour3, 1
L2DBF:
	cmp	word ptr [si+hole1], 11h
	jne	L2DCB
	mov	byte ptr cs:colour1, 2
L2DCB:
	cmp	word ptr [si+hole1], 12h
	jne	L2DD7
	mov	byte ptr cs:colour1, 2
L2DD7:
	cmp	word ptr [si+hole1], 13h
	jne	L2DE3
	mov	byte ptr cs:colour1, 2
L2DE3:
	cmp	word ptr [si+hole2], 11h
	jne	L2DEF
	mov	byte ptr cs:colour2, 2
L2DEF:
	cmp	word ptr [si+hole2], 12h
	jne	L2DFB
	mov	byte ptr cs:colour2, 2
L2DFB:
	cmp	word ptr [si+hole2], 13h
	jne	L2E07
	mov	byte ptr cs:colour2, 2
L2E07:
	cmp	word ptr [si+hole3], 11h
	jne	L2E13
	mov	byte ptr cs:colour3, 2
L2E13:
	cmp	word ptr [si+hole3], 12h
	jne	L2E1F
	mov	byte ptr cs:colour3, 2
L2E1F:
	cmp	word ptr [si+hole3], 13h
	jne	L2E2B
	mov	byte ptr cs:colour3, 2
L2E2B:
	cmp	word ptr [si+hole1], 14h
	jne	L2E37
	mov	byte ptr cs:colour1, 3
L2E37:
	cmp	word ptr [si+hole1], 15h
	jne	L2E43
	mov	byte ptr cs:colour1, 3
L2E43:
	cmp	word ptr [si+hole1], 16h
	jne	L2E4F
	mov	byte ptr cs:colour1, 3
L2E4F:
	cmp	word ptr [si+hole2], 14h
	jne	L2E5B
	mov	byte ptr cs:colour2, 3
L2E5B:
	cmp	word ptr [si+hole2], 15h
	jne	L2E67
	mov	byte ptr cs:colour2, 3
L2E67:
	cmp	word ptr [si+hole2], 16h
	jne	L2E73
	mov	byte ptr cs:colour2, 3
L2E73:
	cmp	word ptr [si+hole3], 14h
	jne	L2E7F
	mov	byte ptr cs:colour3, 3
L2E7F:
	cmp	word ptr [si+hole3], 15h
	jne	L2E8B
	mov	byte ptr cs:colour3, 3
L2E8B:
	cmp	word ptr [si+hole3], 16h
	jne	L2E97
	mov	byte ptr cs:colour3, 3
L2E97:
	cmp	byte ptr cs:colour1, 1
	jne	L2EB2
	cmp	byte ptr cs:colour2, 1
	jne	L2EB2
	cmp	byte ptr cs:colour3, 1
	jne	L2EB2
	JMPN	L322E

L2EB2:
	cmp	byte ptr cs:colour1, 1
	jne	L2ECD
	cmp	byte ptr cs:colour2, 1
	jne	L2ECD
	cmp	byte ptr cs:colour3, 2
	jne	L2ECD
	JMPN	L317F

L2ECD:
	cmp	byte ptr cs:colour1, 1
	jne	L2EE8
	cmp	byte ptr cs:colour2, 1
	jne	L2EE8
	cmp	byte ptr cs:colour3, 3
	jne	L2EE8
	JMPN	L317F

L2EE8:
	cmp	byte ptr cs:colour1, 1
	jne	L2F03
	cmp	byte ptr cs:colour2, 2
	jne	L2F03
	cmp	byte ptr cs:colour3, 1
	jne	L2F03
	JMPN	L317F

L2F03:
	cmp	byte ptr cs:colour1, 1
	jne	L2F1E
	cmp	byte ptr cs:colour2, 2
	jne	L2F1E
	cmp	byte ptr cs:colour3, 2
	jne	L2F1E
	JMPN	L32CC

L2F1E:
	cmp	byte ptr cs:colour1, 1
	jne	L2F39
	cmp	byte ptr cs:colour2, 2
	jne	L2F39
	cmp	byte ptr cs:colour3, 3
	jne	L2F39
	JMPN	L3350

L2F39:
	cmp	byte ptr cs:colour1, 1
	jne	L2F54
	cmp	byte ptr cs:colour2, 3
	jne	L2F54
	cmp	byte ptr cs:colour3, 1
	jne	L2F54
	JMPN	L317F

L2F54:
	cmp	byte ptr cs:colour1, 1
	jne	L2F6F
	cmp	byte ptr cs:colour2, 3
	jne	L2F6F
	cmp	byte ptr cs:colour3, 2
	jne	L2F6F
	JMPN	L317F

L2F6F:
	cmp	byte ptr cs:colour1, 1
	jne	L2F8A
	cmp	byte ptr cs:colour2, 3
	jne	L2F8A
	cmp	byte ptr cs:colour3, 3
	jne	L2F8A
	JMPN	L3301

L2F8A:
	cmp	byte ptr cs:colour1, 2
	jne	L2FA5
	cmp	byte ptr cs:colour2, 1
	jne	L2FA5
	cmp	byte ptr cs:colour3, 1
	jne	L2FA5
	JMPN	L33E7

L2FA5:
	cmp	byte ptr cs:colour1, 2
	jne	L2FC0
	cmp	byte ptr cs:colour2, 1
	jne	L2FC0
	cmp	byte ptr cs:colour3, 2
	jne	L2FC0
	JMPN	L3683

L2FC0:
	cmp	byte ptr cs:colour1, 2
	jne	L2FDB
	cmp	byte ptr cs:colour2, 1
	jne	L2FDB
	cmp	byte ptr cs:colour3, 3
	jne	L2FDB
	JMPN	L3683

L2FDB:
	cmp	byte ptr cs:colour1, 2
	jne	L2FF6
	cmp	byte ptr cs:colour2, 2
	jne	L2FF6
	cmp	byte ptr cs:colour3, 1
	jne	L2FF6
	JMPN	L317F

L2FF6:
	cmp	byte ptr cs:colour1, 2
	jne	L3011
	cmp	byte ptr cs:colour2, 2
	jne	L3011
	cmp	byte ptr cs:colour3, 2
	jne	L3011
	JMPN	L341C

L3011:
	cmp	byte ptr cs:colour1, 2
	jne	L302C
	cmp	byte ptr cs:colour2, 2
	jne	L302C
	cmp	byte ptr cs:colour3, 3
	jne	L302C
	JMPN	L317F

L302C:
	cmp	byte ptr cs:colour1, 2
	jne	L3047
	cmp	byte ptr cs:colour2, 3
	jne	L3047
	cmp	byte ptr cs:colour3, 1
	jne	L3047
	JMPN	L3616

L3047:
	cmp	byte ptr cs:colour1, 2
	jne	L3062
	cmp	byte ptr cs:colour2, 3
	jne	L3062
	cmp	byte ptr cs:colour3, 2
	jne	L3062
	JMPN	L3683

L3062:
	cmp	byte ptr cs:colour1, 2
	jne	L307D
	cmp	byte ptr cs:colour2, 3
	jne	L307D
	cmp	byte ptr cs:colour3, 3
	jne	L307D
	JMPN	L3565

L307D:
	cmp	byte ptr cs:colour1, 3
	jne	L3098
	cmp	byte ptr cs:colour2, 1
	jne	L3098
	cmp	byte ptr cs:colour3, 1
	jne	L3098
	JMPN	L3725

L3098:
	cmp	byte ptr cs:colour1, 3
	jne	L30B3
	cmp	byte ptr cs:colour2, 1
	jne	L30B3
	cmp	byte ptr cs:colour3, 2
	jne	L30B3
	JMPN	L39A4

L30B3:
	cmp	byte ptr cs:colour1, 3
	jne	L30CE
	cmp	byte ptr cs:colour2, 1
	jne	L30CE
	cmp	byte ptr cs:colour3, 3
	jne	L30CE
	JMPN	L39A4

L30CE:
	cmp	byte ptr cs:colour1, 3
	jne	L30E9
	cmp	byte ptr cs:colour2, 2
	jne	L30E9
	cmp	byte ptr cs:colour3, 1
	jne	L30E9
	JMPN	L3918

L30E9:
	cmp	byte ptr cs:colour1, 3
	jne	L3104
	cmp	byte ptr cs:colour2, 2
	jne	L3104
	cmp	byte ptr cs:colour3, 2
	jne	L3104
	JMPN	L3781

L3104:
	cmp	byte ptr cs:colour1, 3
	jne	L311F
	cmp	byte ptr cs:colour2, 2
	jne	L311F
	cmp	byte ptr cs:colour3, 3
	jne	L311F
	JMPN	L39A4

L311F:
	cmp	byte ptr cs:colour1, 3
	jne	L3139
	cmp	byte ptr cs:colour2, 3
	jne	L3139
	cmp	byte ptr cs:colour3, 1
	jne	L3139
	jmp	SHORT L317F

L3139:
	cmp	byte ptr cs:colour1, 3
	jne	L3153
	cmp	byte ptr cs:colour2, 3
	jne	L3153
	cmp	byte ptr cs:colour3, 2
	jne	L3153
	jmp	SHORT L317F

L3153:
	cmp	byte ptr cs:colour1, 3
	jne	L316E
	cmp	byte ptr cs:colour2, 3
	jne	L316E
	cmp	byte ptr cs:colour3, 3
	jne	L316E
	JMPN	L37F9

L316E:
	mov	ax, 9
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(9)
	add	sp, 4
	retf

L317F:
	mov	ax, 0Ah
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(10)
	add	sp, 4
	mov	ax, OFFSET N_Light_of_Knowledge
	mov	bx, OFFSET T_TRI5_039
	call	Say
	jmp	SHORT L31FE

T_TRI5_039	LABEL	BYTE
	DB	'#TRI5\TRI5_039#That combination is restricted to higher order fu'
	DB	'nctions. Neural interlink required.',0
L31FE:
	retf

; The Light of War: the planet's defences.
LightOfWar:
	mov	ax, 0Ah
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(10)
	add	sp, 4
	jmp	SHORT L3218

N_redlit	LABEL	BYTE
	DB	'redlit',0
L3218:
	push	0
	push	0
	push	0
	push	OFFSET N_redlit
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "redlit", 0, 0, 0)
	add	sp, 0Ch
	ret

L322E:
	call	LightOfWar
	mov	ax, -1
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(1, -1)
	add	sp, 6
	mov	ax, OFFSET N_Light_of_War
	mov	bx, OFFSET T_TRI5_050
	call	Say
	jmp	SHORT L32A1

T_TRI5_050	LABEL	BYTE
	DB	'#TRI5\TRI5_050#Planetary defenses revived. All alien vessels in '
	DB	'orbit destroyed.',0
L32A1:
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	mov	ax, 0
	mov	bx, OFFSET S_32B6
	call	Say
	jmp	SHORT L32CB

S_32B6	LABEL	BYTE
	DB	'***Game over man!***',0
L32CB:
	retf

L32CC:
	call	LightOfWar
	mov	ax, OFFSET N_Light_of_War
	mov	bx, OFFSET T_TRI5_036
	call	Say
	jmp	SHORT L3300

T_TRI5_036	LABEL	BYTE
	DB	'#TRI5\TRI5_036#Alien vessels scanned.',0
L3300:
	retf

L3301:
	call	LightOfWar
	mov	ax, OFFSET N_Light_of_War
	mov	bx, OFFSET T_TRI5_049
	call	Say
	jmp	SHORT L334F

T_TRI5_049	LABEL	BYTE
	DB	'#TRI5\TRI5_049#Internal defenses off line. Failsafes cancelled.',0
L334F:
	retf

L3350:
	call	LightOfWar
	mov	ax, OFFSET N_Light_of_War
	mov	bx, OFFSET T_TRI5_048
	call	Say
	jmp	SHORT L33B7

T_TRI5_048	LABEL	BYTE
	DB	'#TRI5\TRI5_048#Breach of protocol. Alien invasion imminent. Inte'
	DB	'rnal security activated.',0
L33B7:
	retf

; The Light of Knowledge: Bialbi's archives; one combination primes the
; interlink (interlink_primed, +1 once).
LightOfKnowledge:
	mov	ax, 0Ah
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(10)
	add	sp, 4
	jmp	SHORT L33D1

N_grnlit	LABEL	BYTE
	DB	'grnlit',0
L33D1:
	push	0
	push	0
	push	0
	push	OFFSET N_grnlit
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "grnlit", 0, 0, 0)
	add	sp, 0Ch
	ret

L33E7:
	call	LightOfKnowledge
	mov	ax, OFFSET N_Light_of_Knowledge
	mov	bx, OFFSET T_TRI5_047
	call	Say
	jmp	SHORT L341B

T_TRI5_047	LABEL	BYTE
	DB	'#TRI5\TRI5_047#Alien vessels scanned.',0
L341B:
	retf

L341C:
	call	LightOfKnowledge
	jmp	SHORT L3428

N_EFX12B	LABEL	BYTE
	DB	'EFX12B',0
L3428:
	push	OFFSET N_EFX12B
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EFX12B")
	add	sp, 4
	mov	ax, OFFSET N_Light_of_Knowledge
	mov	bx, OFFSET T_TRI5_040
	call	Say
	JMPN	L351D

T_TRI5_040	LABEL	BYTE
	DB	'#TRI5\TRI5_040#This is Bialbi, High Mentalic of Hrakkour. For de'
	DB	'fense, use the light of war. For information, use my light. For '
	DB	'transportation, use the light of travel. Sequences are keyed by '
	DB	'combinations of crystals.',0
L351D:
	mov	ax, OFFSET N_Light_of_Knowledge
	mov	bx, OFFSET T_TRI5_037
	call	Say
	jmp	SHORT L354D

T_TRI5_037	LABEL	BYTE
	DB	'#TRI5\TRI5_037#Integrator now active',0
L354D:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+interlink_primed], 1
	cmp	byte ptr [si+primed_scored], 0
	jne	L3564
	mov	byte ptr [si+primed_scored], 1
	add	word ptr [si+score], 3
L3564:
	retf

L3565:
	call	LightOfKnowledge
	mov	ax, OFFSET N_Light_of_Knowledge
	mov	bx, OFFSET T_TRI5_038
	call	Say
	JMPN	L3615

T_TRI5_038	LABEL	BYTE
	DB	'#TRI5\TRI5_038#Telepathic entry codes required for greater than '
	DB	'level One functions. Neural interlink at the integrator, and use'
	DB	' the main index code of my light',0
L3615:
	retf

L3616:
	call	LightOfKnowledge
	mov	ax, OFFSET N_Light_of_Knowledge
	mov	bx, OFFSET T_TRI5_041
	call	Say
	jmp	SHORT L3682

T_TRI5_041	LABEL	BYTE
	DB	'#TRI5\TRI5_041#To use any light, the first crystal must correspo'
	DB	'nd to the color of the light.',0
L3682:
	retf

L3683:
	call	LightOfKnowledge
	mov	ax, OFFSET N_Light_of_Knowledge
	mov	bx, OFFSET T_TRI5_039_2
	call	Say
	jmp	SHORT L36F5

T_TRI5_039_2	LABEL	BYTE
	DB	'#TRI5\TRI5_039#That combination is restricted to higher order fu'
	DB	'nctions. Neural interlink required.',0
L36F5:
	retf

; The Light of Travel: transport, mostly refused.
LightOfTravel:
	mov	ax, 0Ah
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(10)
	add	sp, 4
	jmp	SHORT L370F

N_blulit	LABEL	BYTE
	DB	'blulit',0
L370F:
	push	0
	push	0
	push	0
	push	OFFSET N_blulit
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "blulit", 0, 0, 0)
	add	sp, 0Ch
	ret

L3725:
	call	LightOfTravel
	mov	ax, OFFSET N_Light_of_Travel
	mov	bx, OFFSET T_TRI5_045
	call	Say
	jmp	SHORT L3780

T_TRI5_045	LABEL	BYTE
	DB	'#TRI5\TRI5_045#There is no battle site at present at which to tr'
	DB	'ansport you.',0
L3780:
	retf

L3781:
	call	LightOfTravel
	mov	ax, OFFSET N_Light_of_Travel
	mov	bx, OFFSET T_TRI5_044
	call	Say
	jmp	SHORT L37F8

T_TRI5_044	LABEL	BYTE
	DB	'#TRI5\TRI5_044#There is damage in the archive section due to a r'
	DB	'ecent neutrino burst. Transport aborted.',0
L37F8:
	retf

L37F9:
	call	LightOfTravel
	mov	ax, OFFSET N_Light_of_Travel
	mov	bx, OFFSET T_TRI5_046
	call	Say
	jmp	SHORT L386B

T_TRI5_046	LABEL	BYTE
	DB	'#TRI5\TRI5_046#We can transport you only in proximity of nearest'
	DB	' humanoid life. Transport imminent.',0
L386B:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 8
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(8)
	add	sp, 4
	jmp	SHORT L3888

N_kteled	LABEL	BYTE
	DB	'kteled',0
L3888:
	push	20h
	push	-1
	push	-1
	push	OFFSET N_kteled
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kteled", -1, -1, 32)
	add	sp, 0Ch
	jmp	SHORT L38A6

N_steled	LABEL	BYTE
	DB	'steled',0
L38A6:
	push	20h
	push	-1
	push	-1
	push	OFFSET N_steled
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "steled", -1, -1, 32)
	add	sp, 0Ch
	jmp	SHORT L38C4

N_mteled	LABEL	BYTE
	DB	'mteled',0
L38C4:
	push	20h
	push	-1
	push	-1
	push	OFFSET N_mteled
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mteled", -1, -1, 32)
	add	sp, 0Ch
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 0
	jne	L38FD
	jmp	SHORT L38E8

N_rteled	LABEL	BYTE
	DB	'rteled',0
L38E8:
	push	20h
	push	-1
	push	-1
	push	OFFSET N_rteled
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rteled", -1, -1, 32)
	add	sp, 0Ch
L38FD:
	retf

; Transport done (anim msg 32): +1, back to the court (room 4).
H_38FE:
	SCRIPT	MSG_ANIM_DONE, 20h, 0, 0, H_39FA
Travelled:
	add	word ptr [si+score], 1
	mov	byte ptr [si+RS_BUSY], 1
	push	4
	push	4
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(4, 4)
	retf

L3918:
	call	LightOfTravel
	mov	ax, OFFSET N_Light_of_Travel
	mov	bx, OFFSET T_TRI5_042
	call	Say
	jmp	SHORT L39A3

T_TRI5_042	LABEL	BYTE
	DB	'#TRI5\TRI5_042#Force field blocks trans-system transport. Transp'
	DB	'ort aborted. Use defense systems to eliminate alien vessels.',0
L39A3:
	retf

L39A4:
	call	LightOfTravel
	mov	ax, OFFSET N_Light_of_Travel
	mov	bx, OFFSET T_TRI5_043
	call	Say
	jmp	SHORT L39F9

T_TRI5_043	LABEL	BYTE
	DB	'#TRI5\TRI5_043#That destination no longer exists. Transport aban'
	DB	'doned.',0
L39F9:
	retf

H_39FA:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, rdf_scripts_end
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI5_012
	call	Say
	jmp	SHORT L3A5B

T_TRI5_012	LABEL	BYTE
	DB	'#TRI5\TRI5_012#Nobody needs healing, Jim, but you will if they h'
	DB	'arm my patient.',0
L3A5B:
	retf

rdf_scripts_end	LABEL	BYTE

RDF	ENDS
	END
