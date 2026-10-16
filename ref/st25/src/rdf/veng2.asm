; VENG2.RDF - "Vengeance", the Republic's auxiliary control room. With
; impulse power (room 6) and Spock's linked tricorders as a computer, the
; power can go to weapons, shields or the transporter. The Elasi uncloak
; and demand data; Kirk stalls, clears and loads a torpedo (room 8), lures
; them into lowering their shields and fires. The Enterprise returns.
;
; Actors: 8 the record decks, 9/0Ah (10) the science/medical tricorders
; wired in, 0Bh (11) the viewscreen, 0Ch (12) the shields, 0Dh (13) both
; tricorders, 0Eh (14) the torpedo light, 0Fh-15h (15-21) the dead
; consoles. Objects: those and 8 the decks, 0Bh/27h the viewscreen,
; 0Ch/15h/28h the damage display, 0Dh/24h the computer, 0Eh/20h the
; torpedo control, 0Fh/23h the power control, 10h/26h the helm, 12h/22h/25h
; the deck slots, 21h the fire control. Exit 1: the corridor.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - Both conversation menus end in a debug line from a speaker "wes",
;   "kirk dialog error." and "power allocation error.", for a choice that
;   cannot happen.
; - The script chain runs on into code at 4F85: the engine reads its bytes
;   as key 50 B8 03 00 and next 2E50, which is before rdf_scripts_end, so
;   the search carries on from there: 2E50 (key 54 2E EB 06), 020C (key FF
;   1E 00 00), then next C483 ends it.
; - The conversation at 00CB (comm_talk) is built at run time.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
score	EQU	RS_VARS+5	; word: the mission's score
power_on	EQU	RS_VARS+0Bh	; impulse power is back (room 6)
hypo_oiled	EQU	RS_VARS+11h	; the hypo holds oil (room 6)
power_to	EQU	RS_VARS+13h	; impulse power: 1 weapons, 2 shields, 3 transporter (room 2)
tricorders	EQU	RS_VARS+14h	; wired into the computer: 1 medical, 2 science, 3 both
logs_played	EQU	RS_VARS+15h	; how many of the log decks Kirk has played
elasi_open	EQU	RS_VARS+17h	; the Elasi have lowered their shields to beam over
torpedo_loaded	EQU	RS_VARS+18h	; the torpedo jam is cleared and one loaded (room 8)
rescued	EQU	RS_VARS+19h	; the Enterprise is back: the Elasi threats are over
elasi_here	EQU	RS_VARS+1Ah	; the Elasi ship has arrived and jams the communicators
stalled	EQU	RS_VARS+1Bh	; Kirk has asked the Elasi for thirty minutes
complied	EQU	RS_VARS+1Ch	; Kirk has agreed to the Elasi's terms
need_tricorders	EQU	RS_VARS+1Dh	; Spock has proposed linking the tricorders as a computer
hailed	EQU	RS_VARS+1Eh	; the Elasi captain has made his demands
decks_taken	EQU	RS_VARS+1Fh	; Kirk has taken the record decks
board_timer	EQU	RS_VARS+20h	; word: until the Elasi board, unless the shields are up
stall_timer	EQU	RS_VARS+22h	; word: the thirty minutes
comply_timer	EQU	RS_VARS+24h	; word: until the Elasi lose patience after Kirk complies
torpedo_timer	EQU	RS_VARS+26h	; word: until their torpedoes
attack_timer	EQU	RS_VARS+28h	; word: after the Elasi lower their shields
found_fusion	EQU	RS_VARS+31h	; the fusion power pack has been found (room 5)
read_journals	EQU	RS_VARS+38h	; Spock has read the engineering journals
know_jam	EQU	RS_VARS+3Dh	; Spock has found the torpedo jam
clue_crewman	EQU	RS_VARS+3Fh	; evidence: the crewman who just died (room 0)
clue_marata	EQU	RS_VARS+40h	; evidence: Marata's account (room 4)
clue_andrade	EQU	RS_VARS+41h	; evidence: Andrade's log deck, naming the Enterprise
clue_log	EQU	RS_VARS+42h	; evidence: the last log entry (room 0)
clue_records	EQU	RS_VARS+43h	; evidence: the records naming the Enterprise (room 0)

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0C7h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	78h
rdf_scale_min	LABEL	BYTE
	DW	0FAh	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, 1, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	0,0, 0,0	; entrance 0, crew 0
	DW	0,0, 0,0	; entrance 0, crew 1
	DW	0,0, 0,0	; entrance 0, crew 2
	DW	0,0, 0,0	; entrance 0, crew 3
	DW	155,199, 176,162	; entrance 1, crew 0
	DW	155,199, 160,170	; entrance 1, crew 1
	DW	155,199, 205,170	; entrance 1, crew 2
	DW	155,199, 186,178	; entrance 1, crew 3
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
beamed	LABEL	BYTE	; crewmen who have reached the beam-out spot
	DB	0
comm_talk	LABEL	BYTE	; the comm conversation, built at run time
	DB	0, 0
talk_choice0	LABEL	BYTE	; its first choice
	DB	0, 0
talk_choice1	LABEL	BYTE	; its second choice
	DB	0, 0
talk_choice2	LABEL	BYTE	; its third choice
	DB	0, 0
talk_end	LABEL	BYTE	; the end of the list
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0
choice_jumps	LABEL	BYTE
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0

rdf_scripts:
; The room starts: the decks, the wired tricorders, the Elasi on the
; viewscreen, the shields, the torpedo light, and the dead consoles unless
; there is power.
H_00FB:
	SCRIPT	MSG_TICK, 1, 0, 0, H_034F
StartRoom:
	cmp	byte ptr [si+decks_taken], 1
	je	L0127
	jmp	SHORT L0110

N_s7r2d1	LABEL	BYTE
	DB	's7r2d1',0
L0110:
	push	0
	push	8Ch
	push	0EEh
	push	OFFSET N_s7r2d1
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s7r2d1", 238, 140, 0)
	add	sp, 0Ch
L0127:
	push	IT_STRICOR
	push	RC_HAVEITEM
	SERVICE		; HaveItem(IT_STRICOR)
	add	sp, 4
	AX8	cmp, 1
	je	L0156
	jmp	SHORT L0141

N_s7r2t1	LABEL	BYTE
	DB	's7r2t1',0
L0141:
	push	0
	push	71h
	push	45h
	push	OFFSET N_s7r2t1
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s7r2t1", 69, 113, 0)
	add	sp, 0Ch
L0156:
	push	IT_MTRICOR
	push	RC_HAVEITEM
	SERVICE		; HaveItem(IT_MTRICOR)
	add	sp, 4
	AX8	cmp, 1
	je	L0185
	jmp	SHORT L0170

N_s7r2t2	LABEL	BYTE
	DB	's7r2t2',0
L0170:
	push	0
	push	67h
	push	55h
	push	OFFSET N_s7r2t2
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s7r2t2", 85, 103, 0)
	add	sp, 0Ch
L0185:
	cmp	byte ptr [si+tricorders], 3
	jne	L01A9
	jmp	SHORT L0194

N_s7r2t3	LABEL	BYTE
	DB	's7r2t3',0
L0194:
	push	0
	push	71h
	push	4Fh
	push	OFFSET N_s7r2t3
	push	0Dh
	push	RC_ANIM2
	SERVICE		; Anim(13, "s7r2t3", 79, 113, 0)
	add	sp, 0Ch
L01A9:
	cmp	byte ptr [si+elasi_here], 1
	jne	L01CE
	jmp	SHORT L01B8

N_s7r2u2	LABEL	BYTE
	DB	's7r2u2',0
L01B8:
	push	0
	push	63h
	push	9Eh
	push	OFFSET N_s7r2u2
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r2u2", 158, 99, 0)
	add	sp, 0Ch
L01CE:
	cmp	byte ptr [si+power_to], 2
	jne	L01F4
	jmp	SHORT L01DE

N_s7r2sh2	LABEL	BYTE
	DB	's7r2sh2',0
L01DE:
	push	0
	push	64h
	push	0FAh
	push	OFFSET N_s7r2sh2
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s7r2sh2", 250, 100, 0)
	add	sp, 0Ch
L01F4:
	jmp	SHORT L01FD

N_s7r2pl	LABEL	BYTE
	DB	's7r2pl',0
L01FD:
	push	0
	push	74h
	push	97h
	push	OFFSET N_s7r2pl
	push	0Eh
	push	RC_ANIM2
	SERVICE		; Anim(14, "s7r2pl", 151, 116, 0)
	add	sp, 0Ch
	cmp	byte ptr [si+torpedo_loaded], 1
	jne	L0238
	jmp	SHORT L0222

N_s7r2pm	LABEL	BYTE
	DB	's7r2pm',0
L0222:
	push	0
	push	74h
	push	97h
	push	OFFSET N_s7r2pm
	push	0Eh
	push	RC_ANIM2
	SERVICE		; Anim(14, "s7r2pm", 151, 116, 0)
	add	sp, 0Ch
L0238:
	cmp	byte ptr [si+power_on], 0
	je	L0241
	JMPN	L0335

L0241:
	jmp	SHORT L024A

N_s7r2o1	LABEL	BYTE
	DB	's7r2o1',0
L024A:
	push	0
	push	87h
	push	0Bh
	push	OFFSET N_s7r2o1
	push	0Fh
	push	RC_ANIM2
	SERVICE		; Anim(15, "s7r2o1", 11, 135, 0)
	add	sp, 0Ch
	jmp	SHORT L0269

N_s7r2o2	LABEL	BYTE
	DB	's7r2o2',0
L0269:
	push	0
	push	63h
	push	36h
	push	OFFSET N_s7r2o2
	push	14h
	push	RC_ANIM2
	SERVICE		; Anim(20, "s7r2o2", 54, 99, 0)
	add	sp, 0Ch
	jmp	SHORT L0287

N_s7r2o3	LABEL	BYTE
	DB	's7r2o3',0
L0287:
	push	0
	push	5Fh
	push	58h
	push	OFFSET N_s7r2o3
	push	11h
	push	RC_ANIM2
	SERVICE		; Anim(17, "s7r2o3", 88, 95, 0)
	add	sp, 0Ch
	jmp	SHORT L02A5

N_s7r2o4	LABEL	BYTE
	DB	's7r2o4',0
L02A5:
	push	0
	push	7Bh
	push	9Eh
	push	OFFSET N_s7r2o4
	push	10h
	push	RC_ANIM2
	SERVICE		; Anim(16, "s7r2o4", 158, 123, 0)
	add	sp, 0Ch
	jmp	SHORT L02C4

N_s7r2o5	LABEL	BYTE
	DB	's7r2o5',0
L02C4:
	push	0
	push	66h
	push	112h
	push	OFFSET N_s7r2o5
	push	15h
	push	RC_ANIM2
	SERVICE		; Anim(21, "s7r2o5", 274, 102, 0)
	add	sp, 0Ch
	jmp	SHORT L02E3

N_s7r2o6	LABEL	BYTE
	DB	's7r2o6',0
L02E3:
	push	0
	push	86h
	push	131h
	push	OFFSET N_s7r2o6
	push	12h
	push	RC_ANIM2
	SERVICE		; Anim(18, "s7r2o6", 305, 134, 0)
	add	sp, 0Ch
	jmp	SHORT L0303

N_s7r2o7	LABEL	BYTE
	DB	's7r2o7',0
L0303:
	push	0
	push	14h
	push	9Bh
	push	OFFSET N_s7r2o7
	push	13h
	push	RC_ANIM2
	SERVICE		; Anim(19, "s7r2o7", 155, 20, 0)
	add	sp, 0Ch
	jmp	SHORT L0324

N_VEN2LOFF	LABEL	BYTE
	DB	'VEN2LOFF',0
L0324:
	push	OFFSET N_VEN2LOFF
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("VEN2LOFF")
	add	sp, 4
	jmp	SHORT L034E

L0335:
	jmp	SHORT L033F

N_VEN2LON	LABEL	BYTE
	DB	'VEN2LON',0
L033F:
	push	OFFSET N_VEN2LON
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("VEN2LON")
	add	sp, 4
L034E:
	retf

; Timers 0 and 28h, once there is power and the tricorders run the
; computer: the Elasi uncloak (msg 5). Once they are here, raising the
; shields starts timer 2: they hail.
H_034F:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_0357
	jmp	SHORT ElasiUncloak

H_0357:
	SCRIPT	MSG_TICK, 28h, 0, 0, H_03CE
ElasiUncloak:
	cmp	byte ptr [si+tricorders], 3
	je	L0364
	retf

L0364:
	cmp	byte ptr [si+power_on], 1
	je	L036B
	retf

L036B:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+elasi_here], 1
	jne	L0388
	cmp	byte ptr [si+hailed], 1
	je	L0387
	cmp	byte ptr [si+power_to], 2
	jne	L0387
	mov	word ptr [si+RS_TIMERS+4], 2Dh
L0387:
	retf

L0388:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+elasi_here], 1
	jmp	SHORT L039B

N_UNCLOAK	LABEL	BYTE
	DB	'UNCLOAK',0
L039B:
	push	OFFSET N_UNCLOAK
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("UNCLOAK")
	add	sp, 4
	jmp	SHORT L03B3

N_s7r2u1	LABEL	BYTE
	DB	's7r2u1',0
L03B3:
	push	5
	push	63h
	push	9Eh
	push	OFFSET N_s7r2u1
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r2u1", 158, 99, 5)
	add	sp, 0Ch
	mov	byte ptr [si+RS_BUSY], 1
	retf

H_03CE:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_04F3
ElasiSeen:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN2_093
	call	Say
	jmp	SHORT L0410

T_VEN2_093	LABEL	BYTE
	DB	'#VEN2\VEN2_093#Captain, Look! An Elasi ship!',0
L0410:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_019
	call	Say
	jmp	SHORT L0441

T_VEN2_019	LABEL	BYTE
	DB	'#VEN2\VEN2_019#That ship was cloaked!',0
L0441:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_076
	call	Say
	jmp	SHORT L0468

T_VEN2_076	LABEL	BYTE
	DB	'#VEN2\VEN2_076#Fascinating.',0
L0468:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN2_042
	call	Say
	jmp	SHORT L049B

T_VEN2_042	LABEL	BYTE
	DB	'#VEN2\VEN2_042#Is that all you can say?',0
L049B:
	cmp	byte ptr [si+power_to], 2
	jne	L04A3
	jmp	SHORT ElasiHail

L04A3:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_032
	call	Say
	jmp	SHORT L04ED

T_VEN2_032	LABEL	BYTE
	DB	'#VEN2\VEN2_032#Captain, I suggest we try to raise the shields.',0
L04ED:
	mov	word ptr [si+board_timer], 708h
	retf

; Timer 2: the Elasi demand the locations of their imprisoned comrades
; from the Republic's records. Kirk gets thirty minutes (stalled).
H_04F3:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_0C37
ElasiHail:
	mov	byte ptr [si+hailed], 1
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_073
	call	Say
	jmp	SHORT L054A

T_VEN2_073	LABEL	BYTE
	DB	'#VEN2\VEN2_073#Captain, we are being hailed by the Elasi Captain'
	DB	'.',0
L054A:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_016
	call	Say
	jmp	SHORT L057D

T_VEN2_016	LABEL	BYTE
	DB	'#VEN2\VEN2_016#Put it on Screen, Spock.',0
L057D:
	jmp	SHORT L0586

N_s7r2p1	LABEL	BYTE
	DB	's7r2p1',0
L0586:
	push	0
	push	63h
	push	9Eh
	push	OFFSET N_s7r2p1
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r2p1", 158, 99, 0)
	add	sp, 0Ch
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_109
	call	Say
	jmp	SHORT L0616

T_VEN2_109	LABEL	BYTE
	DB	'#VEN2\VEN2_109#Well, if it isn''t Captain Kirk. Fancy meeting you'
	DB	' out here all alone in such a shabby starship.',0
L0616:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_027
	call	Say
	jmp	SHORT L0642

T_VEN2_027	LABEL	BYTE
	DB	'#VEN2\VEN2_027#What do you want?',0
L0642:
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_113
	call	Say
	jmp	SHORT L06CA

T_VEN2_113	LABEL	BYTE
	DB	'#VEN2\VEN2_113#You should be more civil considering your Enterpr'
	DB	'ise is far away on a mercy mission helping that poor trader.',0
L06CA:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_010
	call	Say
	jmp	SHORT L06F5

T_VEN2_010	LABEL	BYTE
	DB	'#VEN2\VEN2_010#It was a setup?!',0
L06F5:
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_103
	call	Say
	jmp	SHORT L0734

T_VEN2_103	LABEL	BYTE
	DB	'#VEN2\VEN2_103#I can see why they made you Captain!',0
L0734:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_006
	call	Say
	jmp	SHORT L0792

T_VEN2_006	LABEL	BYTE
	DB	'#VEN2\VEN2_006#I assume, since you haven''t blasted us to bits, y'
	DB	'ou want something.',0
L0792:
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_111
	call	Say
	jmp	SHORT L080F

T_VEN2_111	LABEL	BYTE
	DB	'#VEN2\VEN2_111#Why, yes I do. It seems you failed to give one of'
	DB	' my associates some rather important information.',0
L080F:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_020
	call	Say
	jmp	SHORT L0878

T_VEN2_020	LABEL	BYTE
	DB	'#VEN2\VEN2_020#The Masada, I presume. You want the locations of '
	DB	'all your imprisoned comrades?',0
L0878:
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_112
	call	Say
	JMPN	L090A

T_VEN2_112	LABEL	BYTE
	DB	'#VEN2\VEN2_112#Yes, Kirk. The Republic''s computers will have the'
	DB	' data just as your Enterprise would. I give you one minute to co'
	DB	'mply.',0
L090A:
	mov	ax, OFFSET DefyElasi
	call	Talk
	AX8	cmp, 0
	jne	L0917
	jmp	SHORT L093E

L0917:
	AX8	cmp, 1
	jne	L091F
	JMPN	L09BE

L091F:
	mov	ax, OFFSET N_wes
	mov	bx, OFFSET N_kirk_dialog_error
	call	Say
	jmp	SHORT L093D

N_kirk_dialog_error	LABEL	BYTE
	DB	'kirk dialog error.',0
L093D:
	retf

L093E:
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_099
	call	Say
	jmp	SHORT L0992

T_VEN2_099	LABEL	BYTE
	DB	'#VEN2\VEN2_099#Can''t threaten you?! As you said, I can blow you '
	DB	'to bits!',0
L0992:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_008
	call	Say
	jmp	SHORT L09BE

T_VEN2_008	LABEL	BYTE
	DB	'#VEN2\VEN2_008#I see your point.',0
L09BE:
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_105
	call	Say
	jmp	SHORT L0A30

T_VEN2_105	LABEL	BYTE
	DB	'#VEN2\VEN2_105#Maybe I should just pump a few torpedoes into you'
	DB	'r shields and check it out for myself.',0
L0A30:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_021
	call	Say
	jmp	SHORT L0A9A

T_VEN2_021	LABEL	BYTE
	DB	'#VEN2\VEN2_021#The Republic will fall apart if you fire on us. T'
	DB	'hen you''ll never get the data.',0
L0A9A:
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_102
	call	Say
	JMPN	L0B64

T_VEN2_102	LABEL	BYTE
	DB	'#VEN2\VEN2_102#All right, Kirk. We''ll do it your way. I would ra'
	DB	'ther not kill you. Besides, there''s an old friend that wants to '
	DB	'meet you. I give you thirty minutes. And remember, no tricks.',0
L0B64:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_072
	call	Say
	jmp	SHORT L0BAA

T_VEN2_072	LABEL	BYTE
	DB	'#VEN2\VEN2_072#Captain, the main computer is far beyond...',0
L0BAA:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN2_044
	call	Say
	jmp	SHORT L0BD4

T_VEN2_044	LABEL	BYTE
	DB	'#VEN2\VEN2_044#Shut up, Spock!',0
L0BD4:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_022
	call	Say
	jmp	SHORT L0C0E

T_VEN2_022	LABEL	BYTE
	DB	'#VEN2\VEN2_022#Thirty minutes, then. Kirk out.',0
L0C0E:
	jmp	SHORT L0C17

N_s7r2u2_2	LABEL	BYTE
	DB	's7r2u2',0
L0C17:
	push	0
	push	63h
	push	9Eh
	push	OFFSET N_s7r2u2_2
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r2u2", 158, 99, 0)
	add	sp, 0Ch
	mov	word ptr [si+stall_timer], 6978h
	mov	byte ptr [si+stalled], 1
	retf

; Exit 1: to the corridor (room 1).
H_0C37:
	SCRIPT	MSG_EXIT, 1, 0, 0, H_0C52
ToCorridor:
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	mov	byte ptr [si+RS_MORE], 1
	retf

; Looking.
H_0C52:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_0C5A
	jmp	SHORT LookAtViewscreen

H_0C5A:
	SCRIPT	MSG_LOOK, 27h, 0, 0, H_0D76
LookAtViewscreen:
	cmp	byte ptr [si+elasi_here], 1
	je	L0CE3
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N022
	call	Say
	jmp	SHORT L0CE2

T_VEN2N022	LABEL	BYTE
	DB	'#VEN2\VEN2N022#The auxiliary control room viewscreen is still op'
	DB	'erating. It is displaying a view of empty space.',0
L0CE2:
	retf

L0CE3:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N002
	call	Say
	JMPN	L0D75

T_VEN2N002	LABEL	BYTE
	DB	'#VEN2\VEN2N002#An Elasi frigate is visible on the viewscreen. Th'
	DB	'ough silent now, you know it is ready to attack at a moment''s no'
	DB	'tice.',0
L0D75:
	retf

H_0D76:
	SCRIPT	MSG_LOOK, 10h, 0, 0, H_0D7E
	jmp	SHORT LookAtHelm

H_0D7E:
	SCRIPT	MSG_LOOK, 26h, 0, 0, H_0E38
LookAtHelm:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N030
	call	Say
	JMPN	L0E37

T_VEN2N030	LABEL	BYTE
	DB	'#VEN2\VEN2N030#These are the auxiliary helm and navigation contr'
	DB	'ols for the Republic. Though they are intact, the ship is in no '
	DB	'condition to move under her own power.',0
L0E37:
	retf

H_0E38:
	SCRIPT	MSG_LOOK, 0Ch, 0, 0, H_0E40
	jmp	SHORT LookAtDamage

H_0E40:
	SCRIPT	MSG_LOOK, 15h, 0, 0, H_0E48
LookAtDamage:
	jmp	SHORT LookAtDamage2

H_0E48:
	SCRIPT	MSG_LOOK, 28h, 0, 0, H_0F63
LookAtDamage2:
	cmp	byte ptr [si+power_on], 1
	jne	L0E57
	JMPN	L0ED8

L0E57:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N035
	call	Say
	jmp	SHORT L0ED7

T_VEN2N035	LABEL	BYTE
	DB	'#VEN2\VEN2N035#This is the Republic''s Auxiliary Control Room. It'
	DB	' appears to be in better shape than the main bridge.',0
L0ED7:
	retf

L0ED8:
	cmp	byte ptr [si+power_to], 2
	je	L0F59
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N032
	call	Say
	jmp	SHORT L0F58

T_VEN2N032	LABEL	BYTE
	DB	'#VEN2\VEN2N032#This is the auxiliary ship damage display. Red fl'
	DB	'ashing damage indicators dominate its surface.',0
L0F58:
	retf

L0F59:
	mov	ax, OFFSET S_5125
	mov	bx, OFFSET T_VEN2N032_2
	call	Say
	retf

H_0F63:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_0FC8
LookAtSciTricorder:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N027
	call	Say
	jmp	SHORT L0FC7

T_VEN2N027	LABEL	BYTE
	DB	'#VEN2\VEN2N027#The science tricorder is currently wired into the'
	DB	' computer console.',0
L0FC7:
	retf

H_0FC8:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_102D
LookAtMedTricorder:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N024
	call	Say
	jmp	SHORT L102C

T_VEN2N024	LABEL	BYTE
	DB	'#VEN2\VEN2N024#The medical tricorder is currently wired into the'
	DB	' computer console.',0
L102C:
	retf

H_102D:
	SCRIPT	MSG_LOOK, 0Eh, 0, 0, H_1035
	jmp	SHORT LookAtTorpedoes

H_1035:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_1089
LookAtTorpedoes:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N033
	call	Say
	jmp	SHORT L1088

T_VEN2N033	LABEL	BYTE
	DB	'#VEN2\VEN2N033#This is the fire control for the photon torpedoes'
	DB	'.',0
L1088:
	retf

H_1089:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_128A
LookAtFireControl:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N033_2
	call	Say
	jmp	SHORT L10DD

T_VEN2N033_2	LABEL	BYTE
	DB	'#VEN2\VEN2N033#This is the fire control for the photon torpedoes'
	DB	'. ',0
L10DD:
	cmp	byte ptr [si+power_on], 0
	jne	L1117
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N001
	call	Say
	jmp	SHORT L1116

T_VEN2N001	LABEL	BYTE
	DB	'#VEN2\VEN2N001#All indicators are dead.',0
L1116:
	retf

L1117:
	cmp	byte ptr [si+torpedo_loaded], 0
	je	L1120
	JMPN	L11B1

L1120:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N000
	call	Say
	jmp	SHORT L118F

T_VEN2N000	LABEL	BYTE
	DB	'#VEN2\VEN2N000#A red flashing light is currently indicating a ja'
	DB	'm in the torpedo loading mechanism.',0
L118F:
	cmp	byte ptr [si+elasi_here], 1
	je	L11A3
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_036
	call	Say
	mov	byte ptr [si+know_jam], 1
	retf

L11A3:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_037
	call	Say
	mov	byte ptr [si+know_jam], 1
	retf

L11B1:
	cmp	byte ptr [si+rescued], 1
	je	L122D
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N021
	call	Say
	jmp	SHORT L122C

T_VEN2N021	LABEL	BYTE
	DB	'#VEN2\VEN2N021#Status indicators show that photon torpedo number'
	DB	' one and is loaded and ready to be fired.',0
L122C:
	retf

L122D:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N020
	call	Say
	jmp	SHORT L1289

T_VEN2N020	LABEL	BYTE
	DB	'#VEN2\VEN2N020#Status indicator show that the torpedo tubes are '
	DB	'currently empty.',0
L1289:
	retf

H_128A:
	SCRIPT	MSG_LOOK, 0Fh, 0, 0, H_1292
	jmp	SHORT LookAtPowerControl

H_1292:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_1541
LookAtPowerControl:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N034
	call	Say
	jmp	SHORT L12E0

T_VEN2N034	LABEL	BYTE
	DB	'#VEN2\VEN2N034#This is the impulse power allocation control.',0
L12E0:
	cmp	byte ptr [si+power_on], 1
	je	L1345
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N008
	call	Say
	jmp	SHORT L1344

T_VEN2N008	LABEL	BYTE
	DB	'#VEN2\VEN2N008#Indicators currently show no power output from th'
	DB	'e impulse engines.',0
L1344:
	retf

L1345:
	cmp	byte ptr [si+tricorders], 3
	je	L13B3
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N009
	call	Say
	jmp	SHORT L13B2

T_VEN2N009	LABEL	BYTE
	DB	'#VEN2\VEN2N009#Indicators show impulse power online, but no powe'
	DB	'r allocated to any systems.',0
L13B2:
	retf

L13B3:
	cmp	byte ptr [si+power_to], 0
	jne	L1421
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N009_2
	call	Say
	jmp	SHORT L1420

T_VEN2N009_2	LABEL	BYTE
	DB	'#VEN2\VEN2N009#Indicators show impulse power online, but no powe'
	DB	'r allocated to any systems.',0
L1420:
	retf

L1421:
	cmp	byte ptr [si+power_to], 1
	jne	L1483
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N007
	call	Say
	jmp	SHORT L1482

T_VEN2N007	LABEL	BYTE
	DB	'#VEN2\VEN2N007#Indicators currently show all power diverted to w'
	DB	'eapons control.',0
L1482:
	retf

L1483:
	cmp	byte ptr [si+power_to], 2
	jne	L14E1
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N005
	call	Say
	jmp	SHORT L14E0

T_VEN2N005	LABEL	BYTE
	DB	'#VEN2\VEN2N005#Indicators currently show all power diverted to t'
	DB	'he shields.',0
L14E0:
	retf

L14E1:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N006
	call	Say
	jmp	SHORT L1540

T_VEN2N006	LABEL	BYTE
	DB	'#VEN2\VEN2N006#Indicators currently show all power diverted to t'
	DB	'ransporter systems.',0
L1540:
	retf

H_1541:
	SCRIPT	MSG_LOOK, 0Dh, 0, 0, H_1549
	jmp	SHORT LookAtComputer

H_1549:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_16F2
LookAtComputer:
	cmp	byte ptr [si+tricorders], 0
	jne	L15AE
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N003
	call	Say
	jmp	SHORT L15AD

T_VEN2N003	LABEL	BYTE
	DB	'#VEN2\VEN2N003#Damage from the battle has disabled the ship''s ma'
	DB	'in computer.',0
L15AD:
	retf

L15AE:
	cmp	byte ptr [si+tricorders], 1
	jne	L1611
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N023
	call	Say
	jmp	SHORT L1610

T_VEN2N023	LABEL	BYTE
	DB	'#VEN2\VEN2N023#The medical tricorder is crudely wired into the c'
	DB	'omputer console.',0
L1610:
	retf

L1611:
	cmp	byte ptr [si+tricorders], 2
	jne	L1674
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N027_2
	call	Say
	jmp	SHORT L1673

T_VEN2N027_2	LABEL	BYTE
	DB	'#VEN2\VEN2N027#The science tricorder is crudely wired into the c'
	DB	'omputer console.',0
L1673:
	retf

L1674:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N025
	call	Say
	jmp	SHORT L16F1

T_VEN2N025	LABEL	BYTE
	DB	'#VEN2\VEN2N025#The science and medical tricorders are jury-rigge'
	DB	'd to the remains of the Republic computer system.',0
L16F1:
	retf

H_16F2:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_173F
LookAtDecks:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N029
	call	Say
	jmp	SHORT L173E

T_VEN2N029	LABEL	BYTE
	DB	'#VEN2\VEN2N029#These are Federation standard record decks.',0
L173E:
	retf

H_173F:
	SCRIPT	MSG_LOOK, 12h, 0, 0, H_1747
	jmp	SHORT LookAtDeckSlot

H_1747:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_179F
LookAtDeckSlot:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N031
	call	Say
	jmp	SHORT L179E

T_VEN2N031	LABEL	BYTE
	DB	'#VEN2\VEN2N031#This is a standard input/output slot for record d'
	DB	'ecks.',0
L179E:
	retf

H_179F:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_17F7
LookAtDeckSlot2:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N031_2
	call	Say
	jmp	SHORT L17F6

T_VEN2N031_2	LABEL	BYTE
	DB	'#VEN2\VEN2N031#This is a standard input/output slot for record d'
	DB	'ecks.',0
L17F6:
	retf

H_17F7:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_185B
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N010
	call	Say
	jmp	SHORT L185A

T_VEN2N010	LABEL	BYTE
	DB	'#VEN2\VEN2N010#Kirk is dismayed by the damage that was done to A'
	DB	'uxiliary Control.',0
L185A:
	retf

H_185B:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_18A3
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N019
	call	Say
	jmp	SHORT L18A2

T_VEN2N019	LABEL	BYTE
	DB	'#VEN2\VEN2N019#Spock wishes that Mr. Scott were here.',0
L18A2:
	retf

H_18A3:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_18EB
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N012
	call	Say
	jmp	SHORT L18EA

T_VEN2N012	LABEL	BYTE
	DB	'#VEN2\VEN2N012#McCoy wishes that Mr. Scott were here.',0
L18EA:
	retf

H_18EB:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_1944
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N004
	call	Say
	jmp	SHORT L1943

T_VEN2N004	LABEL	BYTE
	DB	'#VEN2\VEN2N004#Ensign Kije doesn''t see the need for a security e'
	DB	'scort.',0
L1943:
	retf

H_1944:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_19CB
LookAtRoom:
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N035_2
	call	Say
	jmp	SHORT L19CA

T_VEN2N035_2	LABEL	BYTE
	DB	'#VEN2\VEN2N035#This is the Republic''s Auxiliary Control Room. It'
	DB	' appears to be in better shape than the main bridge.',0
L19CA:
	retf

H_19CB:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_1A8C
TalkToKirk:
	cmp	byte ptr [si+stalled], 1
	je	L1A24
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_005
	call	Say
	jmp	SHORT L1A23

T_VEN2_005	LABEL	BYTE
	DB	'#VEN2\VEN2_005#What a mess. I wonder what we can do to fix this.',0
L1A23:
	retf

L1A24:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_004
	call	Say
	jmp	SHORT L1A8B

T_VEN2_004	LABEL	BYTE
	DB	'#VEN2\VEN2_004#We don''t have much time for talk. The Elasi are k'
	DB	'nown for their punctuality.',0
L1A8B:
	retf

H_1A8C:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_1B95
TalkToSpock:
	cmp	byte ptr [si+stalled], 1
	je	L1AE0
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN4_017
	call	Say
	jmp	SHORT L1ADF

T_VEN4_017	LABEL	BYTE
	DB	'#VEN4\VEN4_017#I believe nothing needs to be said, Captain.',0
L1ADF:
	retf

L1AE0:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_075
	call	Say
	jmp	SHORT L1B18

T_VEN2_075	LABEL	BYTE
	DB	'#VEN2\VEN2_075#Fascinating. A cloaked Elasi.',0
L1B18:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_009
	call	Say
	jmp	SHORT L1B94

T_VEN2_009	LABEL	BYTE
	DB	'#VEN2\VEN2_009#I''m not one to overlook strategic implications, M'
	DB	'r. Spock, but we can save that for another time.',0
L1B94:
	retf

H_1B95:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_1C68
TalkToMcCoy:
	cmp	byte ptr [si+stalled], 1
	je	L1BE0
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN2_039
	call	Say
	jmp	SHORT L1BDF

T_VEN2_039	LABEL	BYTE
	DB	'#VEN2\VEN2_039#I''m glad this isn''t the Enterprise.',0
L1BDF:
	retf

L1BE0:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN2_041
	call	Say
	jmp	SHORT L1C38

T_VEN2_041	LABEL	BYTE
	DB	'#VEN2\VEN2_041#Cloaked Elasi. I wonder who the old friend they m'
	DB	'entioned is?',0
L1C38:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_007
	call	Say
	jmp	SHORT L1C67

T_VEN2_007	LABEL	BYTE
	DB	'#VEN2\VEN2_007#I don''t know, Bones.',0
L1C67:
	retf

H_1C68:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_1DA7
TalkToRedshirt:
	cmp	byte ptr [si+stalled], 1
	je	L1CBC
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN2_086
	call	Say
	jmp	SHORT L1CBB

T_VEN2_086	LABEL	BYTE
	DB	'#VEN2\VEN2_086#If there''s anything I can do, sir, just ask.',0
L1CBB:
	retf

L1CBC:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN2_094
	call	Say
	JMPN	L1D5B

T_VEN2_094	LABEL	BYTE
	DB	'#VEN2\VEN2_094#Captain, do you suppose the Elasi might have used'
	DB	' cloaking technology to project a false image, of a ship the Rep'
	DB	'ublic would trust?',0
L1D5B:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_078
	call	Say
	jmp	SHORT L1DA6

T_VEN2_078	LABEL	BYTE
	DB	'#VEN2\VEN2_078#That is beyond the Elasi''s capabilities, Ensign.',0
L1DA6:
	retf

; The engineering journals in the deck slot (msgs 16h, 17h): Spock
; learns to power the systems through linked tricorders.
H_1DA7:
	SCRIPT	MSG_USE, IT_TECH, 12h, 0, H_1DAF
	jmp	SHORT JournalsInSlot

H_1DAF:
	SCRIPT	MSG_USE, IT_TECH, 25h, 0, H_1DB7
JournalsInSlot:
	jmp	SHORT JournalsInSlot2

H_1DB7:
	SCRIPT	MSG_USE, IT_TECH, 22h, 0, H_1E59
JournalsInSlot2:
	cmp	byte ptr [si+read_journals], 1
	jne	L1E38
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_046
	call	Say
	jmp	SHORT L1E37

T_VEN2_046	LABEL	BYTE
	DB	'#VEN2\VEN2_046#I have memorized all pertinent data, Captain. the'
	DB	're is no need to reexamine the journals.',0
L1E37:
	retf

L1E38:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 16h
	push	ax
	mov	ax, 98h
	push	ax
	mov	ax, 112h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 274, 152, 22)
	add	sp, 0Ah
	retf

H_1E59:
	SCRIPT	MSG_WALK_DONE, 16h, 0, 0, H_1E7E
SpockAtSlot:
	jmp	SHORT L1E68

N_susemn	LABEL	BYTE
	DB	'susemn',0
L1E68:
	push	17h
	push	-1
	push	-1
	push	OFFSET N_susemn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemn", -1, -1, 23)
	add	sp, 0Ch
	retf

H_1E7E:
	SCRIPT	MSG_ANIM_DONE, 17h, 0, 0, H_1FC8
ReadJournals:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_070
	call	Say
	jmp	SHORT L1F02

T_VEN2_070	LABEL	BYTE
	DB	'#VEN2\VEN2_070#Captain, I have examined the Engineering Journals'
	DB	'. According to chapter eighteen, we can run...',0
L1F02:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN2_043
	call	Say
	jmp	SHORT L1F55

T_VEN2_043	LABEL	BYTE
	DB	'#VEN2\VEN2_043#Jim, do we really need a lesson in starship engin'
	DB	'eering?',0
L1F55:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_017
	call	Say
	jmp	SHORT L1F96

T_VEN2_017	LABEL	BYTE
	DB	'#VEN2\VEN2_017#Spock, just tell me if they will help.',0
L1F96:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_081
	call	Say
	jmp	SHORT L1FC3

T_VEN2_081	LABEL	BYTE
	DB	'#VEN2\VEN2_081#Why, yes, Captain.',0
L1FC3:
	mov	byte ptr [si+read_journals], 1
	retf

; The log decks in the slot (msgs 18h, 19h): each play is the next
; entry; the fourth, Andrade's, says the Enterprise attacked (evidence).
H_1FC8:
	SCRIPT	MSG_USE, IT_DECK, 12h, 0, H_1FD0
	jmp	SHORT DeckInSlot

H_1FD0:
	SCRIPT	MSG_USE, IT_DECK, 25h, 0, H_1FD8
DeckInSlot:
	jmp	SHORT DeckInSlot2

H_1FD8:
	SCRIPT	MSG_USE, IT_DECK, 22h, 0, H_1FFF
DeckInSlot2:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 18h
	push	ax
	mov	ax, 98h
	push	ax
	mov	ax, 112h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 274, 152, 24)
	add	sp, 0Ah
	retf

H_1FFF:
	SCRIPT	MSG_WALK_DONE, 18h, 0, 0, H_2024
KirkAtSlot:
	jmp	SHORT L200E

N_kusemn	LABEL	BYTE
	DB	'kusemn',0
L200E:
	push	19h
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 25)
	add	sp, 0Ch
	retf

H_2024:
	SCRIPT	MSG_ANIM_DONE, 19h, 0, 0, H_21BC
PlayLog:
	jmp	SHORT L2035

N_COMPUTER	LABEL	BYTE
	DB	'COMPUTER',0
L2035:
	push	OFFSET N_COMPUTER
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("COMPUTER")
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	inc	byte ptr [si+logs_played]
	cmp	byte ptr [si+logs_played], 1
	je	L2054
	JMPN	L2148

L2054:
	mov	ax, OFFSET S_50BE
	mov	bx, OFFSET T_VEN2_082
	call	Say
	JMPN	L2147

T_VEN2_082	LABEL	BYTE
	DB	'#VEN2\VEN2_082#Captain''s log, stardate 6087.6. The Republic is c'
	DB	'urrently approaching the Vardaine system. Sensors have detected '
	DB	'unusual energy fluctuations near one of the Vardainian moons. St'
	DB	'arfleet has ordered us to investigate.',0
L2147:
	retf

L2148:
	cmp	byte ptr [si+logs_played], 2
	jne	L2158
	mov	ax, OFFSET S_50BE
	mov	bx, OFFSET T_VEN2_083
	call	Say
	retf

L2158:
	cmp	byte ptr [si+logs_played], 3
	jne	L2168
	mov	ax, OFFSET S_50BE
	mov	bx, OFFSET T_VEN2_084
	call	Say
	retf

L2168:
	cmp	byte ptr [si+logs_played], 4
	jne	L217B
	mov	ax, OFFSET S_50D0
	mov	bx, OFFSET T_VEN2_097
	call	Say
	mov	byte ptr [si+clue_andrade], 1
L217B:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_061
	call	Say
	jmp	SHORT L21BB

T_VEN2_061	LABEL	BYTE
	DB	'#VEN2\VEN2_061#There are no more log decks, Captain.',0
L21BB:
	retf

; The communicator: jammed once the Elasi are here. After stalling,
; Kirk can hail them: if the torpedo is loaded he tells them to beam over
; for the data, and they must lower their shields to do it (complied).
H_21BC:
	SCRIPT	MSG_USE, IT_COMM, OBJ_KIRK, 0, H_27C2
CallEnterprise:
	cmp	byte ptr [si+complied], 1
	jne	L2212
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_098
	call	Say
	jmp	SHORT L2211

T_VEN2_098	LABEL	BYTE
	DB	'#VEN2\VEN2_098#What are you stalling for? Lower your shields.',0
L2211:
	retf

L2212:
	cmp	byte ptr [si+stalled], 1
	jne	L221B
	JMPN	L231C

L221B:
	cmp	byte ptr [si+elasi_here], 1
	jne	L2224
	JMPN	L2392

L2224:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET S_222F
	call	Say
	jmp	SHORT L2263

S_222F	LABEL	BYTE
	DB	'#MUD4_018#Kirk to Enterprise, Kirk to Enterprise...',0
L2263:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_VEN2U093
	call	Say
	jmp	SHORT L22CE

T_VEN2U093	LABEL	BYTE
	DB	'#VEN2\VEN2U093#Enterprise here. We''re still tracking the distres'
	DB	's call. Are you all right, Sir?',0
L22CE:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_028
	call	Say
	jmp	SHORT L231B

T_VEN2_028	LABEL	BYTE
	DB	'#VEN2\VEN2_028#Yes, Uhura, Just wanted a status report. Kirk out'
	DB	'.',0
L231B:
	retf

L231C:
	mov	word ptr cs:comm_talk, OFFSET N_Capt_Kirk
	jmp	SHORT L2330

N_Hail_Elasi	LABEL	BYTE
	DB	'Hail Elasi',0
L2330:
	mov	word ptr cs:talk_choice0, OFFSET N_Hail_Elasi
	mov	word ptr cs:choice_jumps, OFFSET L240C
	jmp	SHORT L2350

N_Hail_Enterprise	LABEL	BYTE
	DB	'Hail Enterprise',0
L2350:
	mov	word ptr cs:talk_choice1, OFFSET N_Hail_Enterprise
	mov	word ptr cs:choice_jumps+2, OFFSET L2392
	jmp	SHORT L2367

N_cancel	LABEL	BYTE
	DB	'cancel',0
L2367:
	mov	word ptr cs:talk_choice2, OFFSET N_cancel
	mov	word ptr cs:choice_jumps+4, OFFSET L2406
	mov	word ptr cs:talk_end, 0
	push	OFFSET comm_talk
	push	RC_TALK
	SERVICE		; Talk(comm_talk)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L2392:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_066
	call	Say
	jmp	SHORT L2406

T_VEN2_066	LABEL	BYTE
	DB	'#VEN2\VEN2_066#They are jamming all frequencies, Captain. We wil'
	DB	'l not be able to contact the Enterprise.',0
L2406:
	mov	si, word ptr cs:rdf_state
	retf

L240C:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+torpedo_loaded], 1
	jne	L241A
	JMPN	L24B7

L241A:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN2_040
	call	Say
	JMPN	L24B6

T_VEN2_040	LABEL	BYTE
	DB	'#VEN2\VEN2_040#Jim, since we do not have what they want, I don''t'
	DB	' think it is a good idea to contact them until we are able to de'
	DB	'fend ourselves.',0
L24B6:
	retf

L24B7:
	jmp	SHORT L24C0

N_s7r2p1_2	LABEL	BYTE
	DB	's7r2p1',0
L24C0:
	push	0
	push	63h
	push	9Eh
	push	OFFSET N_s7r2p1_2
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r2p1", 158, 99, 0)
	add	sp, 0Ch
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_108
	call	Say
	jmp	SHORT L254B

T_VEN2_108	LABEL	BYTE
	DB	'#VEN2\VEN2_108#Well, Captain Kirk, I trust you and your valiant '
	DB	'crew have retrieved the data I requested?',0
L254B:
	mov	word ptr cs:comm_talk, OFFSET N_Capt_Kirk
	jmp	SHORT L259F

T_VEN2_015	LABEL	BYTE
	DB	'#VEN2\VEN2_015#Not yet. We''re having trouble accessing all the d'
	DB	'ata files.',0
L259F:
	mov	word ptr cs:talk_choice0, OFFSET T_VEN2_015
	mov	word ptr cs:choice_jumps, OFFSET L2650
	jmp	SHORT L2625

T_VEN2_029	LABEL	BYTE
	DB	'#VEN2\VEN2_029#Yes, we have. You''ll have to beam over and get it'
	DB	', though. The computer''s subspace transmitter is out.',0
L2625:
	mov	word ptr cs:talk_choice1, OFFSET T_VEN2_029
	mov	word ptr cs:choice_jumps+2, OFFSET L26CE
	mov	word ptr cs:talk_choice2, 0
	push	OFFSET comm_talk
	push	RC_TALK
	SERVICE		; Talk(comm_talk)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L2650:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_100
	call	Say
	jmp	SHORT L26AE

T_VEN2_100	LABEL	BYTE
	DB	'#VEN2\VEN2_100#You better step on it, Kirk! You only have a few '
	DB	'minutes left!',0
L26AE:
	jmp	SHORT L26B7

N_s7r2u2_3	LABEL	BYTE
	DB	's7r2u2',0
L26B7:
	push	0
	push	63h
	push	9Eh
	push	OFFSET N_s7r2u2_3
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r2u2", 158, 99, 0)
	add	sp, 0Ch
	retf

L26CE:
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_114
	call	Say
	JMPN	L2762

T_VEN2_114	LABEL	BYTE
	DB	'#VEN2\VEN2_114#How convenient, Kirk. We''ll beam over, but no tri'
	DB	'cks. My sensors read that only your shields have power. Lower th'
	DB	'em now!',0
L2762:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_025
	call	Say
	jmp	SHORT L2794

T_VEN2_025	LABEL	BYTE
	DB	'#VEN2\VEN2_025#We''ll comply. Kirk out.',0
L2794:
	mov	si, word ptr cs:rdf_state
	jmp	SHORT L27A2

N_s7r2u2_4	LABEL	BYTE
	DB	's7r2u2',0
L27A2:
	push	0
	push	63h
	push	9Eh
	push	OFFSET N_s7r2u2_4
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r2u2", 158, 99, 0)
	add	sp, 0Ch
	mov	word ptr [si+comply_timer], 708h
	mov	byte ptr [si+complied], 1
	retf

; The fire control (msgs 12h, 13h, anims 7, 6): with power to weapons,
; the torpedo loaded and the Elasi shields down, Kirk cripples their ship;
; the Enterprise returns (rescued) and beams the party up (msgs 1-4).
H_27C2:
	SCRIPT	MSG_USE, OBJ_KIRK, 0Eh, 0, H_27CA
	jmp	SHORT FireTorpedo

H_27CA:
	SCRIPT	MSG_USE, OBJ_KIRK, 20h, 0, H_2936
FireTorpedo:
	cmp	byte ptr [si+power_to], 1
	je	L2807
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N028
	call	Say
	jmp	SHORT L2806

T_VEN2N028	LABEL	BYTE
	DB	'#VEN2\VEN2N028#There is no response.',0
L2806:
	retf

L2807:
	cmp	byte ptr [si+torpedo_loaded], 1
	je	L287A
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_058
	call	Say
	jmp	SHORT L2879

T_VEN2_058	LABEL	BYTE
	DB	'#VEN2\VEN2_058#The torpedo warning systems are showing a malfunc'
	DB	'tion in the torpedo loading bay.',0
L2879:
	retf

L287A:
	cmp	byte ptr [si+elasi_open], 1
	jne	L2883
	JMPN	L2911

L2883:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_054
	call	Say
	JMPN	L2910

T_VEN2_054	LABEL	BYTE
	DB	'#VEN2\VEN2_054#The elasi ship''s shield are still raised, captain'
	DB	'. A single photon hit will have a negligible effect on the ship.',0
L2910:
	retf

L2911:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 12h
	push	ax
	mov	ax, 95h
	push	ax
	mov	ax, 90h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 144, 149, 18)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL], 0
	retf

H_2936:
	SCRIPT	MSG_WALK_DONE, 12h, 0, 0, H_295B
KirkAtFireControl:
	jmp	SHORT L2945

N_kusemn_2	LABEL	BYTE
	DB	'kusemn',0
L2945:
	push	13h
	push	-1
	push	-1
	push	OFFSET N_kusemn_2
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 19)
	add	sp, 0Ch
	retf

H_295B:
	SCRIPT	MSG_ANIM_DONE, 13h, 0, 0, H_299A
Fired:
	jmp	SHORT L296C

N_DBLWHAM2	LABEL	BYTE
	DB	'DBLWHAM2',0
L296C:
	push	OFFSET N_DBLWHAM2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("DBLWHAM2")
	add	sp, 4
	jmp	SHORT L2984

N_s7r2ph	LABEL	BYTE
	DB	's7r2ph',0
L2984:
	push	7
	push	0
	push	0
	push	OFFSET N_s7r2ph
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r2ph", 0, 0, 7)
	add	sp, 0Ch
	retf

H_299A:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_2BE3
ElasiHit:
	jmp	SHORT L29A9

N_s7r2p1_3	LABEL	BYTE
	DB	's7r2p1',0
L29A9:
	push	0
	push	63h
	push	9Eh
	push	OFFSET N_s7r2p1_3
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r2p1", 158, 99, 0)
	add	sp, 0Ch
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_104
	call	Say
	JMPN	L2A50

T_VEN2_104	LABEL	BYTE
	DB	'#VEN2\VEN2_104#Kirk! I should have known you''d try something und'
	DB	'erhanded like this. Weaponsmaster, fire all weapons on the Repub'
	DB	'lic!',0
L2A50:
	mov	ax, OFFSET N_Elasi_Weapons_Master
	mov	bx, OFFSET T_VEN2_F29
	call	Say
	jmp	SHORT L2A9B

T_VEN2_F29	LABEL	BYTE
	DB	'#VEN2\VEN2_F29#We can''t, Captain. All weapons systems off-line!',0
L2A9B:
	mov	ax, OFFSET N_Elasi_Crewman
	mov	bx, OFFSET T_VEN2_F28
	call	Say
	jmp	SHORT L2AEF

T_VEN2_F28	LABEL	BYTE
	DB	'#VEN2\VEN2_F28#Captain, the Enterprise is coming on high speed a'
	DB	'pproach!',0
L2AEF:
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_101
	call	Say
	jmp	SHORT L2B3E

T_VEN2_101	LABEL	BYTE
	DB	'#VEN2\VEN2_101#Activate cloaking device! Kirk, until we meet aga'
	DB	'in.',0
L2B3E:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_014
	call	Say
	jmp	SHORT L2B6E

T_VEN2_014	LABEL	BYTE
	DB	'#VEN2\VEN2_014#Not too soon, I hope.',0
L2B6E:
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_106
	call	Say
	jmp	SHORT L2BC4

T_VEN2_106	LABEL	BYTE
	DB	'#VEN2\VEN2_106#Watch yourself, Captain. It may be sooner than yo'
	DB	'u realize.',0
L2BC4:
	jmp	SHORT L2BCD

N_s7r2rc	LABEL	BYTE
	DB	's7r2rc',0
L2BCD:
	push	6
	push	0
	push	0
	push	OFFSET N_s7r2rc
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r2rc", 0, 0, 6)
	add	sp, 0Ch
	retf

H_2BE3:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_2E4C
ElasiGone:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_VEN2U094
	call	Say
	jmp	SHORT L2C32

T_VEN2U094	LABEL	BYTE
	DB	'#VEN2\VEN2U094#Enterprise to Captain Kirk. Are you safe, sir?',0
L2C32:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_026
	call	Say
	jmp	SHORT L2C64

T_VEN2_026	LABEL	BYTE
	DB	'#VEN2\VEN2_026#We''re fine, lieutenant.',0
L2C64:
	mov	ax, OFFSET N_Ensign_Chekov
	mov	bx, OFFSET T_VEN2_115
	call	Say
	JMPN	L2CFB

T_VEN2_115	LABEL	BYTE
	DB	'#VEN2\VEN2_115#Sir, we picked up another ship nearby and we came'
	DB	' as fast as we could. It appeared to cloak. Were you attacked by'
	DB	' Romulans?',0
L2CFB:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_013
	call	Say
	JMPN	L2DAF

T_VEN2_013	LABEL	BYTE
	DB	'#VEN2\VEN2_013#No, Ensign. It looks like the Elasi have been doi'
	DB	'ng some business with them. Scotty, beam us back. We need to fin'
	DB	'd that ship that attacked the Republic.',0
L2DAF:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_VEN2_S09
	call	Say
	jmp	SHORT L2DD7

T_VEN2_S09	LABEL	BYTE
	DB	'#VEN2\VEN2_S09#Aye, Captain.',0
L2DD7:
	mov	byte ptr [si+rescued], 1
	mov	ax, 1
	push	ax
	mov	ax, 9Dh
	push	ax
	mov	ax, 0ECh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 236, 157, 1)
	add	sp, 0Ah
	mov	ax, 2
	push	ax
	mov	ax, 96h
	push	ax
	mov	ax, 0D5h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 213, 150, 2)
	add	sp, 0Ah
	mov	ax, 3
	push	ax
	mov	ax, 95h
	push	ax
	mov	ax, 101h
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 257, 149, 3)
	add	sp, 0Ah
	mov	ax, 4
	push	ax
	mov	ax, 8Ch
	push	ax
	mov	ax, 0ECh
	push	ax
	mov	ax, 3
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(3, 236, 140, 4)
	add	sp, 0Ah
	retf

H_2E4C:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_2E54
	jmp	SHORT BeamOut2

H_2E54:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_2E5C
BeamOut2:
	jmp	SHORT BeamOut3

H_2E5C:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_2E64
BeamOut3:
	jmp	SHORT BeamOut

; Once all four have walked to the spot: the score is 16 plus one per
; piece of evidence.
H_2E64:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_2EC5
BeamOut:
	inc	byte ptr cs:beamed
	cmp	byte ptr cs:beamed, 4
	je	L2E78
	retf

L2E78:
	mov	word ptr [si+score], 10h
	cmp	byte ptr [si+clue_crewman], 1
	jne	L2E87
	add	word ptr [si+score], 1
L2E87:
	cmp	byte ptr [si+clue_marata], 1
	jne	L2E91
	add	word ptr [si+score], 1
L2E91:
	cmp	byte ptr [si+clue_andrade], 1
	jne	L2E9B
	add	word ptr [si+score], 1
L2E9B:
	cmp	byte ptr [si+clue_log], 1
	jne	L2EA5
	add	word ptr [si+score], 1
L2EA5:
	cmp	byte ptr [si+clue_records], 1
	jne	L2EAF
	add	word ptr [si+score], 1
L2EAF:
	push	0
	push	15h
	push	word ptr [si+score]
	push	RC_BEAMUP
	SERVICE		; BeamUp(?, 21, 0)
	add	sp, 8
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Spock's tricorder and the fire control.
H_2EC5:
	SCRIPT	MSG_USE, IT_STRICOR, 0Eh, 0, H_2F14
SpockScansTorpedoes:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_F35
	call	Say
	jmp	SHORT L2F13

T_VEN2_F35	LABEL	BYTE
	DB	'#VEN2\VEN2_F35#This is the photon torpedo launching control.',0
L2F13:
	retf

H_2F14:
	SCRIPT	MSG_USE, IT_STRICOR, 10h, 0, H_2F1C
	jmp	SHORT SpockScansHelm

H_2F1C:
	SCRIPT	MSG_USE, IT_STRICOR, 26h, 0, H_3004
SpockScansHelm:
	jmp	SHORT L2F2B

N_sscann	LABEL	BYTE
	DB	'sscann',0
L2F2B:
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
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N030_2
	call	Say
	JMPN	L3003

T_VEN2N030_2	LABEL	BYTE
	DB	'#VEN2\VEN2N030#These are the auxiliary helm and navigation contr'
	DB	'ols for the Republic. Though they are intact, the ship is in no '
	DB	'condition to move under her own power.',0
L3003:
	retf

H_3004:
	SCRIPT	MSG_USE, OBJ_KIRK, 21h, 0, H_300C
	jmp	SHORT ScanFireControl

H_300C:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_3014
ScanFireControl:
	jmp	SHORT SpockOnFireControl

H_3014:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_33B6
SpockOnFireControl:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_001
	call	Say
	jmp	SHORT L3071

T_VEN2_001	LABEL	BYTE
	DB	'#VEN2\VEN2_001#Mr. Spock, what is the condition of the fire cont'
	DB	'rol system?',0
L3071:
	jmp	SHORT L307A

N_sscann_2	LABEL	BYTE
	DB	'sscann',0
L307A:
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
	cmp	byte ptr [si+power_to], 1
	jne	L30A8
	JMPN	L31E0

L30A8:
	cmp	byte ptr [si+need_tricorders], 1
	jne	L30B1
	JMPN	L3189

L30B1:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_062
	call	Say
	JMPN	L3188

T_VEN2_062	LABEL	BYTE
	DB	'#VEN2\VEN2_062#There currently is no power being allocated to th'
	DB	'e weapons system. Even if there were a power source, the damage '
	DB	'to the main computer is enough to prevent power allocation to th'
	DB	'at system.',0
L3188:
	retf

L3189:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_064
	call	Say
	jmp	SHORT L31DF

T_VEN2_064	LABEL	BYTE
	DB	'#VEN2\VEN2_064#There is no power allocated to the weapons system'
	DB	', Captain.',0
L31DF:
	retf

L31E0:
	cmp	byte ptr [si+tricorders], 3
	je	L3264
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_055
	call	Say
	jmp	SHORT L3263

T_VEN2_055	LABEL	BYTE
	DB	'#VEN2\VEN2_055#The impulse engines are back on-line, but we have'
	DB	' no way of directing power to the weapons system.',0
L3263:
	retf

L3264:
	cmp	byte ptr [si+power_to], 1
	je	L32B8
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_065
	call	Say
	jmp	SHORT L32B7

T_VEN2_065	LABEL	BYTE
	DB	'#VEN2\VEN2_065#There is no power allocated to the weapons system'
	DB	'.',0
L32B7:
	retf

L32B8:
	cmp	byte ptr [si+torpedo_loaded], 0
	je	L32C1
	JMPN	L336B

L32C1:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_068
	call	Say
	jmp	SHORT L3349

T_VEN2_068	LABEL	BYTE
	DB	'#VEN2\VEN2_068#Weapons control is functioning properly, however,'
	DB	' there appears to be a jam in the primary loading mechanism.',0
L3349:
	cmp	byte ptr [si+elasi_here], 1
	je	L335D
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_036
	call	Say
	mov	byte ptr [si+know_jam], 1
	retf

L335D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_037
	call	Say
	mov	byte ptr [si+know_jam], 1
	retf

L336B:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_050
	call	Say
	jmp	SHORT L33B5

T_VEN2_050	LABEL	BYTE
	DB	'#VEN2\VEN2_050#Photon torpedo is loaded and ready to be fired.',0
L33B5:
	retf

; The power control (msgs 14h, 15h): once impulse power and the
; tricorders are in, Spock allocates it to weapons, shields or the
; transporter, which the Elasi watch.
H_33B6:
	SCRIPT	MSG_USE, OBJ_KIRK, 0Fh, 0, H_33BE
	jmp	SHORT SpockOnPower

H_33BE:
	SCRIPT	MSG_USE, OBJ_SPOCK, 0Fh, 0, H_33C6
SpockOnPower:
	jmp	SHORT KirkOnPower2

H_33C6:
	SCRIPT	MSG_USE, OBJ_KIRK, 23h, 0, H_33CE
KirkOnPower2:
	jmp	SHORT AllocatePower

H_33CE:
	SCRIPT	MSG_USE, OBJ_SPOCK, 23h, 0, H_356B
AllocatePower:
	cmp	byte ptr [si+power_on], 0
	je	L33DD
	JMPN	L3487

L33DD:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_003
	call	Say
	jmp	SHORT L342E

T_VEN2_003	LABEL	BYTE
	DB	'#VEN2\VEN2_003#Spock, what is the situation with the impulse eng'
	DB	'ines?',0
L342E:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_063
	call	Say
	jmp	SHORT L3486

T_VEN2_063	LABEL	BYTE
	DB	'#VEN2\VEN2_063#There is currently no power to be allocated from '
	DB	'the engines.',0
L3486:
	retf

L3487:
	cmp	byte ptr [si+tricorders], 3
	jne	L3490
	JMPN	L354A

L3490:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_003_2
	call	Say
	jmp	SHORT L34E0

T_VEN2_003_2	LABEL	BYTE
	DB	'#VEN2\VEN2_003#Spock, how is the situation with the impulse engi'
	DB	'nes?',0
L34E0:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_057
	call	Say
	jmp	SHORT L3549

T_VEN2_057	LABEL	BYTE
	DB	'#VEN2\VEN2_057#The main computer is too badly damaged to activel'
	DB	'y control the power circuits.',0
L3549:
	retf

L354A:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 14h
	push	ax
	mov	ax, 9Bh
	push	ax
	mov	ax, 22h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 34, 155, 20)
	add	sp, 0Ah
	retf

H_356B:
	SCRIPT	MSG_WALK_DONE, 14h, 0, 0, H_3590
SpockAtPower:
	jmp	SHORT L357A

N_susemn_2	LABEL	BYTE
	DB	'susemn',0
L357A:
	push	15h
	push	-1
	push	-1
	push	OFFSET N_susemn_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemn", -1, -1, 21)
	add	sp, 0Ch
	retf

H_3590:
	SCRIPT	MSG_ANIM_DONE, 15h, 0, 0, H_3CEB
PowerTo:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_069
	call	Say
	jmp	SHORT L3617

T_VEN2_069	LABEL	BYTE
	DB	'#VEN2\VEN2_069#With impulse power online and the tricorders perf'
	DB	'orming computer control, I can divert power to...',0
L3617:
	mov	ax, OFFSET PowerChoices
	call	Talk
	AX8	cmp, 0
	jne	L3624
	jmp	SHORT L363D

L3624:
	AX8	cmp, 1
	jne	L362C
	JMPN	L38E0

L362C:
	AX8	cmp, 2
	jne	L3634
	JMPN	L39FB

L3634:
	AX8	cmp, 3
	jne	L363A
	retf

L363A:
	JMPN	L3CC7

L363D:
	cmp	byte ptr [si+complied], 1
	jne	L3646
	JMPN	L373C

L3646:
	cmp	byte ptr [si+stalled], 1
	je	L364F
	JMPN	L36E5

L364F:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_035
	call	Say
	JMPN	L36E4

T_VEN2_035	LABEL	BYTE
	DB	'#VEN2\VEN2_035#Captain, the elasi can surely detect the lowering'
	DB	' of our shields. They will undoubtedly try to board us if we low'
	DB	'er them.',0
L36E4:
	retf

L36E5:
	cmp	byte ptr [si+power_to], 1
	jne	L373C
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN2_091
	call	Say
	jmp	SHORT L373B

T_VEN2_091	LABEL	BYTE
	DB	'#VEN2\VEN2_091#Power has already been allocated to the weapons, '
	DB	'Sir.',0
L373B:
	retf

L373C:
	cmp	byte ptr [si+power_to], 2
	jne	L377C
	jmp	SHORT L374D

N_LD6BMOFF	LABEL	BYTE
	DB	'LD6BMOFF',0
L374D:
	push	OFFSET N_LD6BMOFF
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("LD6BMOFF")
	add	sp, 4
	jmp	SHORT L3766

N_s7r2sh3	LABEL	BYTE
	DB	's7r2sh3',0
L3766:
	push	0
	push	64h
	push	0FAh
	push	OFFSET N_s7r2sh3
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s7r2sh3", 250, 100, 0)
	add	sp, 0Ch
L377C:
	mov	byte ptr [si+power_to], 1
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN2_088
	call	Say
	jmp	SHORT L37C7

T_VEN2_088	LABEL	BYTE
	DB	'#VEN2\VEN2_088#Power allocated to weapons systems, Captain.',0
L37C7:
	cmp	byte ptr [si+complied], 1
	je	L37D0
	JMPN	L3884

L37D0:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_052
	call	Say
	JMPN	L387B

T_VEN2_052	LABEL	BYTE
	DB	'#VEN2\VEN2_052#Sensors indicate that the Elasi Ship has lowered '
	DB	'its shields. I suggest we prepare your surprise soon, Captain. T'
	DB	'hey will beam over any moment.',0
L387B:
	mov	byte ptr [si+elasi_open], 1
	mov	word ptr [si+attack_timer], 384h
L3884:
	cmp	byte ptr [si+elasi_here], 1
	jne	L38DF
	cmp	byte ptr [si+hailed], 1
	je	L38DF
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_033
	call	Say
	jmp	SHORT L38DA

T_VEN2_033	LABEL	BYTE
	DB	'#VEN2\VEN2_033#Captain, I suggest we try to raise the shields.',0
L38DA:
	mov	word ptr [si+board_timer], 708h
L38DF:
	retf

L38E0:
	cmp	byte ptr [si+power_to], 2
	jne	L3937
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN2_089
	call	Say
	jmp	SHORT L3936

T_VEN2_089	LABEL	BYTE
	DB	'#VEN2\VEN2_089#Power has already been allocated to the shields, '
	DB	'sir.',0
L3936:
	retf

L3937:
	cmp	byte ptr [si+complied], 1
	jne	L399D
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN2_085
	call	Say
	jmp	SHORT L399C

T_VEN2_085	LABEL	BYTE
	DB	'#VEN2\VEN2_085#Captain, the Elasi will surely fire upon us if we'
	DB	' raise our shields.',0
L399C:
	retf

L399D:
	jmp	SHORT L39A6

N_s7r2sh	LABEL	BYTE
	DB	's7r2sh',0
L39A6:
	push	0
	push	64h
	push	0FAh
	push	OFFSET N_s7r2sh
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s7r2sh", 250, 100, 0)
	add	sp, 0Ch
	mov	byte ptr [si+power_to], 2
	cmp	byte ptr [si+elasi_here], 1
	jne	L39CB
	mov	word ptr [si+RS_TIMERS+4], 2Dh
L39CB:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN2_092
	call	Say
	jmp	SHORT L39FA

T_VEN2_092	LABEL	BYTE
	DB	'#VEN2\VEN2_092#Shields are up, sir.',0
L39FA:
	retf

L39FB:
	cmp	byte ptr [si+stalled], 1
	je	L3A04
	JMPN	L3B98

L3A04:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_034
	call	Say
	JMPN	L3A99

T_VEN2_034	LABEL	BYTE
	DB	'#VEN2\VEN2_034#Captain, the elasi can surely detect the lowering'
	DB	' of our shields. They will undoubtedly try to board us if we low'
	DB	'er them.',0
L3A99:
	cmp	byte ptr [si+found_fusion], 1
	je	L3AA2
	JMPN	L3B97

L3AA2:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_018
	call	Say
	jmp	SHORT L3B0F

T_VEN2_018	LABEL	BYTE
	DB	'#VEN2\VEN2_018#Spock, what about the Fusion Power Pack? Could we'
	DB	' use it to power the transporter?',0
L3B0F:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_077
	call	Say
	jmp	SHORT L3B97

T_VEN2_077	LABEL	BYTE
	DB	'#VEN2\VEN2_077#I believe so, Captain. It would require a connect'
	DB	'ion to the transporter circuits in the main control console.',0
L3B97:
	retf

L3B98:
	cmp	byte ptr [si+power_to], 3
	jne	L3BFA
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET S_3BA9
	call	Say
	jmp	SHORT L3BF9

S_3BA9	LABEL	BYTE
	DB	'#VEN6_090#Power has already been allocated to the transporter sy'
	DB	'stems, Captain.',0
L3BF9:
	retf

L3BFA:
	cmp	byte ptr [si+power_to], 2
	jne	L3C20
	jmp	SHORT L3C0A

N_s7r2sh3_2	LABEL	BYTE
	DB	's7r2sh3',0
L3C0A:
	push	0
	push	64h
	push	0FAh
	push	OFFSET N_s7r2sh3_2
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s7r2sh3", 250, 100, 0)
	add	sp, 0Ch
L3C20:
	mov	byte ptr [si+power_to], 3
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN2_087
	call	Say
	jmp	SHORT L3C6B

T_VEN2_087	LABEL	BYTE
	DB	'#VEN2\VEN2_087#Power allocated to transporter systems, sir.',0
L3C6B:
	cmp	byte ptr [si+elasi_here], 1
	jne	L3CC6
	cmp	byte ptr [si+hailed], 1
	je	L3CC6
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_071
	call	Say
	jmp	SHORT L3CC1

T_VEN2_071	LABEL	BYTE
	DB	'#VEN2\VEN2_071#Captain, I suggest we try to raise the shields.',0
L3CC1:
	mov	word ptr [si+board_timer], 708h
L3CC6:
	retf

L3CC7:
	mov	ax, OFFSET N_wes
	mov	bx, OFFSET S_3CD2
	call	Say
	jmp	SHORT L3CEA

S_3CD2	LABEL	BYTE
	DB	'power allocation error.',0
L3CEA:
	retf

; The computer: too damaged, so Spock proposes the linked tricorders
; (need_tricorders).
H_3CEB:
	SCRIPT	MSG_USE, OBJ_KIRK, 0Dh, 0, H_3CF3
	jmp	SHORT SpockOnComputer

H_3CF3:
	SCRIPT	MSG_USE, OBJ_SPOCK, 0Dh, 0, H_3CFB
SpockOnComputer:
	jmp	SHORT KirkOnComputer2

H_3CFB:
	SCRIPT	MSG_USE, OBJ_KIRK, 24h, 0, H_3D03
KirkOnComputer2:
	jmp	SHORT AskAboutComputer

H_3D03:
	SCRIPT	MSG_USE, OBJ_SPOCK, 24h, 0, H_4139
AskAboutComputer:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_002
	call	Say
	jmp	SHORT L3D59

T_VEN2_002	LABEL	BYTE
	DB	'#VEN2\VEN2_002#Mr. Spock, what is the status of the ship''s compu'
	DB	'ter?',0
L3D59:
	cmp	byte ptr [si+tricorders], 3
	jne	L3D62
	JMPN	L40BF

L3D62:
	jmp	SHORT L3D6B

N_sscanw	LABEL	BYTE
	DB	'sscanw',0
L3D6B:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscanw
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscanw", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_079
	call	Say
	JMPN	L3E2C

T_VEN2_079	LABEL	BYTE
	DB	'#VEN2\VEN2_079#There is extensive damage to the main processing '
	DB	'unit of the ship''s computer. It will take several days at a star'
	DB	'base to repair.',0
L3E2C:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_024
	call	Say
	jmp	SHORT L3E6D

T_VEN2_024	LABEL	BYTE
	DB	'#VEN2\VEN2_024#We don''t have several days, Mr. Spock.',0
L3E6D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_080
	call	Say
	jmp	SHORT L3EF4

T_VEN2_080	LABEL	BYTE
	DB	'#VEN2\VEN2_080#Unless we can find a suitable computational alter'
	DB	'native, there will be no way to control the ship''s systems.',0
L3EF4:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN2_045
	call	Say
	jmp	SHORT L3F61

T_VEN2_045	LABEL	BYTE
	DB	'#VEN2\VEN2_045#That''s just great, Spock. We don''t exactly carry '
	DB	'an M-5 computer in our inventory.',0
L3F61:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_074
	call	Say
	JMPN	L4047

T_VEN2_074	LABEL	BYTE
	DB	'#VEN2\VEN2_074#Correct, Doctor. However, there may be another al'
	DB	'ternative. Linked tricorders, along with the circuits in the dat'
	DB	'a reader, should have the processing power necessary to control '
	DB	'a single starship system.',0
L4047:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN2_096
	call	Say
	jmp	SHORT L40BA

T_VEN2_096	LABEL	BYTE
	DB	'#VEN2\VEN2_096#Thank goodness for parallel processing. I don''t k'
	DB	'now what computers could do without it.',0
L40BA:
	mov	byte ptr [si+need_tricorders], 1
	retf

L40BF:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_059
	call	Say
	jmp	SHORT L4138

T_VEN2_059	LABEL	BYTE
	DB	'#VEN2\VEN2_059#The tricorders are currently operating at 12.69 p'
	DB	'ercent less than normal computing efficiency.',0
L4138:
	retf

; Wiring in the tricorders (msgs 0Ah-0Dh); with both and power, timer 0
; counts to the Elasi's arrival.
H_4139:
	SCRIPT	MSG_USE, IT_STRICOR, 0Dh, 0, H_4141
	jmp	SHORT SciTricorderOnComputer

H_4141:
	SCRIPT	MSG_USE, IT_STRICOR, 24h, 0, H_422D
SciTricorderOnComputer:
	cmp	byte ptr [si+need_tricorders], 1
	je	L4150
	JMPN	AskAboutComputer

L4150:
	cmp	byte ptr [si+power_on], 1
	jne	L4159
	JMPN	L420C

L4159:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_031
	call	Say
	JMPN	L420B

T_VEN2_031	LABEL	BYTE
	DB	'#VEN2\VEN2_031#Captain, I recommend we wait until we have restor'
	DB	'ed power before I hook up the tricorders to the main computer. W'
	DB	'e may need them in engineering first.',0
L420B:
	retf

L420C:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0Ah
	push	ax
	mov	ax, 84h
	push	ax
	mov	ax, 52h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 82, 132, 10)
	add	sp, 0Ah
	retf

H_422D:
	SCRIPT	MSG_WALK_DONE, 0Ah, 0, 0, H_4252
SpockAtComputer:
	jmp	SHORT L423C

N_susemn_3	LABEL	BYTE
	DB	'susemn',0
L423C:
	push	0Bh
	push	-1
	push	-1
	push	OFFSET N_susemn_3
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemn", -1, -1, 11)
	add	sp, 0Ch
	retf

H_4252:
	SCRIPT	MSG_ANIM_DONE, 0Bh, 0, 0, H_433C
WiredSciTricorder:
	jmp	SHORT L4261

N_MUR4E1	LABEL	BYTE
	DB	'MUR4E1',0
L4261:
	push	OFFSET N_MUR4E1
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR4E1")
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+tricorders], 1
	je	L4280
	mov	byte ptr [si+tricorders], 2
	jmp	SHORT L4288

L4280:
	mov	byte ptr [si+tricorders], 3
	mov	word ptr [si+RS_TIMERS], 28h
L4288:
	mov	ax, IT_STRICOR
	push	ax
	mov	ax, RC_TAKEITEM
	push	ax
	SERVICE		; TakeItem(IT_STRICOR)
	add	sp, 4
	jmp	SHORT L42A1

N_s7r2t1_2	LABEL	BYTE
	DB	's7r2t1',0
L42A1:
	push	0
	push	71h
	push	45h
	push	OFFSET N_s7r2t1_2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s7r2t1", 69, 113, 0)
	add	sp, 0Ch
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N017
	call	Say
	jmp	SHORT L4316

T_VEN2N017	LABEL	BYTE
	DB	'#VEN2\VEN2N017#Spock crudely attaches the science tricorder to t'
	DB	'he computer console.',0
L4316:
	mov	ax, 0
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 5Fh
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 95, 170, 0)
	add	sp, 0Ah
	cmp	byte ptr [si+tricorders], 3
	jne	L433B
	JMPN	L44C0

L433B:
	retf

H_433C:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Dh, 0, H_4344
	jmp	SHORT MedTricorderOnComputer

H_4344:
	SCRIPT	MSG_USE, IT_MTRICOR, 24h, 0, H_43B4
MedTricorderOnComputer:
	cmp	byte ptr [si+power_on], 1
	je	L4393
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN2_038
	call	Say
	jmp	SHORT L4392

T_VEN2_038	LABEL	BYTE
	DB	'#VEN2\VEN2_038#I''m a doctor, not a computer scientist!',0
L4392:
	retf

L4393:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0Ch
	push	ax
	mov	ax, 84h
	push	ax
	mov	ax, 52h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 82, 132, 12)
	add	sp, 0Ah
	retf

H_43B4:
	SCRIPT	MSG_WALK_DONE, 0Ch, 0, 0, H_43D9
SpockAtComputer2:
	jmp	SHORT L43C3

N_susemn_4	LABEL	BYTE
	DB	'susemn',0
L43C3:
	push	0Dh
	push	-1
	push	-1
	push	OFFSET N_susemn_4
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemn", -1, -1, 13)
	add	sp, 0Ch
	retf

H_43D9:
	SCRIPT	MSG_ANIM_DONE, 0Dh, 0, 0, H_4591
WiredMedTricorder:
	jmp	SHORT L43E8

N_MUR4E1_2	LABEL	BYTE
	DB	'MUR4E1',0
L43E8:
	push	OFFSET N_MUR4E1_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR4E1")
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+tricorders], 2
	je	L4407
	mov	byte ptr [si+tricorders], 1
	jmp	SHORT L440F

L4407:
	mov	byte ptr [si+tricorders], 3
	mov	word ptr [si+RS_TIMERS], 28h
L440F:
	mov	ax, IT_MTRICOR
	push	ax
	mov	ax, RC_TAKEITEM
	push	ax
	SERVICE		; TakeItem(IT_MTRICOR)
	add	sp, 4
	jmp	SHORT L4428

N_s7r2t2_2	LABEL	BYTE
	DB	's7r2t2',0
L4428:
	push	0
	push	67h
	push	55h
	push	OFFSET N_s7r2t2_2
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s7r2t2", 85, 103, 0)
	add	sp, 0Ch
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N016
	call	Say
	jmp	SHORT L449D

T_VEN2N016	LABEL	BYTE
	DB	'#VEN2\VEN2N016#Spock crudely attaches the medical tricorder to t'
	DB	'he computer console.',0
L449D:
	mov	ax, 0
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 5Fh
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 95, 170, 0)
	add	sp, 0Ah
	cmp	byte ptr [si+tricorders], 3
	je	L44C0
	retf

L44C0:
	jmp	SHORT L44C9

N_s7r2t3_2	LABEL	BYTE
	DB	's7r2t3',0
L44C9:
	push	0
	push	71h
	push	4Fh
	push	OFFSET N_s7r2t3_2
	push	0Dh
	push	RC_ANIM2
	SERVICE		; Anim(13, "s7r2t3", 79, 113, 0)
	add	sp, 0Ch
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_030
	call	Say
	JMPN	L4590

T_VEN2_030	LABEL	BYTE
	DB	'#VEN2\VEN2_030#Both Tricorders are rigged into the main computer'
	DB	'''s central processing unit. We now have enough computational pow'
	DB	'er to control a single ship''s system.',0
L4590:
	retf

; Spock's tricorder and the fusion pack.
H_4591:
	SCRIPT	MSG_USE, IT_STRICOR, 12h, 0, H_4599
	jmp	SHORT SpockScansDeckSlot

H_4599:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_4632
SpockScansDeckSlot:
	jmp	SHORT L45A8

N_sscane	LABEL	BYTE
	DB	'sscane',0
L45A8:
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
	mov	bx, OFFSET T_VEN2_067
	call	Say
	jmp	SHORT L4631

T_VEN2_067	LABEL	BYTE
	DB	'#VEN2\VEN2_067#This input/output slot for the record decks is st'
	DB	'ill functional, Captain.',0
L4631:
	retf

H_4632:
	SCRIPT	MSG_USE, IT_STRICOR, 0Fh, 0, H_463A
	jmp	SHORT SpockScansPower

H_463A:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_4771
SpockScansPower:
	jmp	SHORT L4649

N_sscanw_2	LABEL	BYTE
	DB	'sscanw',0
L4649:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscanw_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscanw", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	cmp	byte ptr [si+power_on], 1
	je	L46EF
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_056
	call	Say
	jmp	SHORT L46EE

T_VEN2_056	LABEL	BYTE
	DB	'#VEN2\VEN2_056#The impulse power allocation controls are functio'
	DB	'nal, but there is no power available, Captain.',0
L46EE:
	retf

L46EF:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_051
	call	Say
	jmp	SHORT L4770

T_VEN2_051	LABEL	BYTE
	DB	'#VEN2\VEN2_051#Power is available, but the main computer is too '
	DB	'badly damaged to actively control the power circuits.',0
L4770:
	retf

H_4771:
	SCRIPT	MSG_USE, IT_FUSION, 0Dh, 0, H_4779
	jmp	SHORT FusionOnComputer

H_4779:
	SCRIPT	MSG_USE, IT_FUSION, 24h, 0, H_481A
FusionOnComputer:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_060
	call	Say
	JMPN	L4819

T_VEN2_060	LABEL	BYTE
	DB	'#VEN2\VEN2_060#The unit doesn''t generate enough power to run any'
	DB	' of the major systems. Main or Auxiliary power is required for t'
	DB	'hat, Captain.',0
L4819:
	retf

; Taking the decks (msgs 8, 9).
H_481A:
	SCRIPT	MSG_GET, 8, 0, 0, H_4841
GetDecks:
	mov	ax, 8
	push	ax
	mov	ax, 93h
	push	ax
	mov	ax, 0E7h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 231, 147, 8)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

H_4841:
	SCRIPT	MSG_WALK_DONE, 8, 0, 0, H_4866
KirkAtDecks:
	jmp	SHORT L4850

N_kuseln	LABEL	BYTE
	DB	'kuseln',0
L4850:
	push	9
	push	-1
	push	-1
	push	OFFSET N_kuseln
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseln", -1, -1, 9)
	add	sp, 0Ch
	retf

H_4866:
	SCRIPT	MSG_ANIM_DONE, 9, 0, 0, H_48CA
TookDecks:
	mov	ax, 8
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(8)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr [si+decks_taken], 1
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N039
	call	Say
	jmp	SHORT L48B9

T_VEN2N039	LABEL	BYTE
	DB	'#VEN2\VEN2N039#You take the record decks.',0
L48B9:
	mov	ax, IT_DECK
	push	ax
	mov	ax, RC_GIVEITEM
	push	ax
	SERVICE		; GiveItem(IT_DECK)
	add	sp, 4
	retf

; Taking the tricorders back out (msgs 0Eh-11h), not once the Elasi
; have hailed.
H_48CA:
	SCRIPT	MSG_GET, 9, 0, 0, H_49BD
GetSciTricorder:
	cmp	byte ptr [si+stalled], 1
	je	L48D9
	JMPN	L499C

L48D9:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_047
	call	Say
	JMPN	L499B

T_VEN2_047	LABEL	BYTE
	DB	'#VEN2\VEN2_047#It would not be prudent to remove the tricorder a'
	DB	't this time, Captain. Doing so will cause the shields to shut do'
	DB	'wn and allow the elasi to beam a boarding party over.',0
L499B:
	retf

L499C:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0Eh
	push	ax
	mov	ax, 84h
	push	ax
	mov	ax, 52h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 82, 132, 14)
	add	sp, 0Ah
	retf

H_49BD:
	SCRIPT	MSG_WALK_DONE, 0Eh, 0, 0, H_49E2
SpockAtComputer3:
	jmp	SHORT L49CC

N_susemn_5	LABEL	BYTE
	DB	'susemn',0
L49CC:
	push	0Fh
	push	-1
	push	-1
	push	OFFSET N_susemn_5
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemn", -1, -1, 15)
	add	sp, 0Ch
	retf

H_49E2:
	SCRIPT	MSG_ANIM_DONE, 0Fh, 0, 0, H_4A7C
UnwiredSciTricorder:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+tricorders], 3
	je	L49F8
	mov	byte ptr [si+tricorders], 0
	jmp	SHORT L49FC

L49F8:
	mov	byte ptr [si+tricorders], 1
L49FC:
	mov	ax, IT_STRICOR
	push	ax
	mov	ax, RC_GIVEITEM
	push	ax
	SERVICE		; GiveItem(IT_STRICOR)
	add	sp, 4
	mov	ax, 9
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(9)
	add	sp, 4
	mov	ax, 0Dh
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(13)
	add	sp, 4
	mov	ax, 0
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 5Fh
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 95, 170, 0)
	add	sp, 0Ah
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N015
	call	Say
	jmp	SHORT L4A7B

T_VEN2N015	LABEL	BYTE
	DB	'#VEN2\VEN2N015#Science Tricorder taken.',0
L4A7B:
	retf

H_4A7C:
	SCRIPT	MSG_GET, 0Ah, 0, 0, H_4B6F
GetMedTricorder:
	cmp	byte ptr [si+stalled], 1
	je	L4A8B
	JMPN	L4B4E

L4A8B:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_047_2
	call	Say
	JMPN	L4B4D

T_VEN2_047_2	LABEL	BYTE
	DB	'#VEN2\VEN2_047#It would not be prudent to remove the tricorder a'
	DB	't this time, Captain. Doing so will cause the shields to shut do'
	DB	'wn and allow the elasi to beam a boarding party over.',0
L4B4D:
	retf

L4B4E:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 10h
	push	ax
	mov	ax, 84h
	push	ax
	mov	ax, 52h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 82, 132, 16)
	add	sp, 0Ah
	retf

H_4B6F:
	SCRIPT	MSG_WALK_DONE, 10h, 0, 0, H_4B94
SpockAtComputer4:
	jmp	SHORT L4B7E

N_susemn_6	LABEL	BYTE
	DB	'susemn',0
L4B7E:
	push	11h
	push	-1
	push	-1
	push	OFFSET N_susemn_6
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemn", -1, -1, 17)
	add	sp, 0Ch
	retf

H_4B94:
	SCRIPT	MSG_ANIM_DONE, 11h, 0, 0, H_4C2E
UnwiredMedTricorder:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+tricorders], 3
	je	L4BAA
	mov	byte ptr [si+tricorders], 0
	jmp	SHORT L4BAE

L4BAA:
	mov	byte ptr [si+tricorders], 2
L4BAE:
	mov	ax, IT_MTRICOR
	push	ax
	mov	ax, RC_GIVEITEM
	push	ax
	SERVICE		; GiveItem(IT_MTRICOR)
	add	sp, 4
	mov	ax, 0Ah
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(10)
	add	sp, 4
	mov	ax, 0Dh
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(13)
	add	sp, 4
	mov	ax, 0
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 5Fh
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 95, 170, 0)
	add	sp, 0Ah
	mov	ax, 0
	mov	bx, OFFSET T_VEN2N013
	call	Say
	jmp	SHORT L4C2D

T_VEN2N013	LABEL	BYTE
	DB	'#VEN2\VEN2N013#Medical Tricorder taken.',0
L4C2D:
	retf

; Every tick, common to the mission's rooms: the Elasi deadlines set on
; the bridge (room 2). Until the Enterprise returns: boarding unless the
; shields are up, the thirty minutes, the wait after Kirk complies (then
; a warning and the torpedoes), the chance after they lower their
; shields. When one runs out, the game is over.
H_4C2E:
	SCRIPT	MSG_TICK, ANY, ANY, ANY, H_4E52
ElasiDeadlines:
	cmp	word ptr [si+board_timer], 0
	je	L4C48
	dec	word ptr [si+board_timer]
	jne	L4C48
	cmp	byte ptr [si+power_to], 2
	je	L4C48
	JMPN	L4D48

L4C48:
	cmp	word ptr [si+stall_timer], 0
	je	L4C5C
	dec	word ptr [si+stall_timer]
	jne	L4C5C
	cmp	byte ptr [si+complied], 1
	je	L4C5C
	JMPN	L4D48

L4C5C:
	cmp	word ptr [si+comply_timer], 0
	je	L4CBB
	dec	word ptr [si+comply_timer]
	jne	L4CBB
	cmp	byte ptr [si+rescued], 1
	je	L4CBB
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_098_2
	call	Say
	jmp	SHORT L4CB6

T_VEN2_098_2	LABEL	BYTE
	DB	'#VEN2\VEN2_098#What are you stalling for? Lower your shields.',0
L4CB6:
	mov	word ptr [si+torpedo_timer], 0A8Ch
L4CBB:
	cmp	word ptr [si+torpedo_timer], 0
	je	L4D34
	dec	word ptr [si+torpedo_timer]
	jne	L4D34
	cmp	byte ptr [si+rescued], 1
	je	L4D34
	mov	ax, 0
	mov	bx, OFFSET T_VENA_F40
	call	Say
	jmp	SHORT L4D28

T_VENA_F40	LABEL	BYTE
	DB	'#VENA\VENA_F40#The Elasi fire photon torpedoes. The Republic has'
	DB	' been destroyed.',0
L4D28:
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
L4D34:
	cmp	word ptr [si+attack_timer], 0
	je	L4D47
	dec	word ptr [si+attack_timer]
	jne	L4D47
	cmp	byte ptr [si+rescued], 1
	je	L4D47
	jmp	SHORT L4D48

L4D47:
	retf

L4D48:
	mov	ax, 0
	mov	bx, OFFSET T_VENA_F32
	call	Say
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
	retf

T_VENA_F32	LABEL	BYTE
	DB	'#VENA\VENA_F32#The landing party has been taken captive by the E'
	DB	'lasi, and you know Starfleet does not negotiate with terrorists.'
	DB	' As you look forward to a long captivity you wonder who will tak'
	DB	'e command of the Enterprise. Better luck next time.',0

H_4E52:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_4E5A
	jmp	SHORT KillAnything

H_4E5A:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_4EEF
KillAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VENA_F34
	call	Say
	JMPN	L4EEE

T_VENA_F34	LABEL	BYTE
	DB	'#VENA\VENA_F34#Captain, it would be unwise to use your phaser co'
	DB	'nsidering the already extensive damage sustained by the Republic'
	DB	'.',0
L4EEE:
	retf

; The hypo, empty or full of oil.
H_4EEF:
	SCRIPT	MSG_LOOK, IT_HYPO, 0, 0, Talk
LookAtHypo:
	cmp	byte ptr [si+hypo_oiled], 1
	je	L4F3C
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N010
	call	Say
	jmp	SHORT L4F3B

T_VEN4N010	LABEL	BYTE
	DB	'#VEN4\VEN4N010#This is an empty hypodermic injector.',0
L4F3B:
	retf

L4F3C:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N007
	call	Say
	jmp	SHORT L4F84

T_VEN6N007	LABEL	BYTE
	DB	'#VEN6\VEN6N007#The hypo is now filled with multipurpose oil.',0
L4F84:
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
	DW	149,110, 153,110, 153,113, 149,113
	DW	21h, 4	; id, points
	DW	140,107, 156,107, 156,119, 140,119
	DW	22h, 4	; id, points
	DW	270,108, 277,108, 277,113, 270,113
	DW	23h, 4	; id, points
	DW	0,115, 36,101, 63,113, 0,143
	DW	24h, 4	; id, points
	DW	43,68, 96,68, 96,103, 43,103
	DW	25h, 5	; id, points
	DW	256,112, 283,102, 319,113, 319,137, 308,137
	DW	26h, 4	; id, points
	DW	114,104, 201,104, 201,123, 114,123
	DW	27h, 4	; id, points
	DW	120,62, 195,62, 195,102, 120,102
	DW	28h, 4	; id, points
	DW	223,55, 273,55, 273,104, 223,104
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	1, 4	; id, points
	DW	0,183, 319,183, 319,199, 0,199
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's7r2',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Mr_Scott	LABEL	BYTE
	DB	'Mr. Scott',0
N_Ensign_Chekov	LABEL	BYTE
	DB	'Ensign Chekov',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
	DB	'Computer',0
S_50BE	LABEL	BYTE
	DB	'*Capt. Patterson*',0
S_50D0	LABEL	BYTE
	DB	'*Commander Andrade*',0
N_wes	LABEL	BYTE
	DB	'wes',0
N_Ensign_Kije	LABEL	BYTE
	DB	'Ensign Kije',0
N_Elasi_Captain	LABEL	BYTE
	DB	'Elasi Captain',0
N_Elasi_Weapons_Master	LABEL	BYTE
	DB	'Elasi Weapons Master',0
N_Elasi_Crewman	LABEL	BYTE
	DB	'Elasi Crewman',0
S_5125	LABEL	BYTE
	DB	0
	DB	'#VEN2\VEN2N011#McCoy is fidgeting around.',0
	DB	'#VEN2\VEN2N018#Spock is analyzing the surroundings.',0
	DB	'#VEN2\VEN2N038#You are in a typical starship corridor.',0
	DB	'#DEM6\DEM6_015#Do I look like a pointy eared, green blooded, kno'
	DB	'w-it-all alien?',0
T_VEN2_083	LABEL	BYTE
	DB	'#VEN2\VEN2_083#Captain''s log, stardate 6087.8. We are under atta'
	DB	'ck by two unidentified ships. I don''t know how they could have a'
	DB	'pproached undetected. They must have some kind of cloaking devic'
	DB	'e, although there are no reports of Romulans in this sector.',0
T_VEN2_084	LABEL	BYTE
	DB	'#VEN2\VEN2_084#Captain''s log, stardate 6088.1. We have successfu'
	DB	'lly driven off our assailants. Major damage has been sustained b'
	DB	'y our warp engines. Communications has reported that U.S.S. Ente'
	DB	'rprise is in sector. I requested Mr. Scott''s assistance in repai'
	DB	'ring damage to the Republic. With luck, we will be fully operati'
	DB	'onal in a couple of days.',0
T_VEN2_097	LABEL	BYTE
	DB	'#VEN2\VEN2_097#Captain''s log, stardate 6088.5. First Officer And'
	DB	'rade commanding. The Enterprise has unexplicably opened fire upo'
	DB	'n us. Captain Patterson has been mortally wounded. We have susta'
	DB	'ined major damage to all systems. Impulse power is out. We canno'
	DB	't understand why...',0
T_VEN2_WEA	LABEL	BYTE
	DB	'#VEN2\VEN2_WEA#Weapons',0
T_VEN2_SHI	LABEL	BYTE
	DB	'#VEN2\VEN2_SHI#Shields',0
T_VEN2_TRA	LABEL	BYTE
	DB	'#VEN2\VEN2_TRA#Transporter Circuits',0
T_VEN2_012	LABEL	BYTE
	DB	'#VEN2\VEN2_012#Just try and get it. You can''t threaten me!',0
T_VEN2_011	LABEL	BYTE
	DB	'#VEN2\VEN2_011#It will take time. The controls are smashed, and '
	DB	'the main computer''s badly damaged. It will take hours to get pow'
	DB	'er to the computer banks.',0
	DB	'#VEN2\VEN2_ELA#Contact Elasi Ship.',0
	DB	'#VEN2\VEN2_ENT#Contact Enterprise.',0
	DB	'#VEN2\VEN2_015#Not yet. We''re having trouble accessing all the d'
	DB	'ata files.',0
	DB	'#VEN2\VEN2_029#Yes, we have. You''ll have to beam over and get it'
	DB	', though. The computer''s subspace transmitter is out.',0
	DB	'#VEN2\VEN2_107#We finally meet in person, Captain Kirk. So where'
	DB	' is the data I requested?',0
	DB	'#VEN2\VEN2_023#Umm, well...',0
	DB	'#VEN2\VEN2_110#What? You mean you were deliberately wasting my t'
	DB	'ime? Guards, take them back to the ship! I''ll think of a suitabl'
	DB	'e punishment for them later.',0
	DB	'#VEN2\VEN2_048#Lowering shields and allocating power to photon t'
	DB	'orpedo systems. Torpedo is loaded and ready.',0
	DB	'#VEN2\VEN2_053#That would be unwise, Captain. I thought our plan'
	DB	' was to surprise the Elasi.',0
T_VEN2_036	LABEL	BYTE
	DB	'#VEN2\VEN2_036#Captain, the torpedo loading system is malfunctio'
	DB	'ning. To clear it, we will have to physically examine the mechan'
	DB	'ism. Currently, all turbolift access to the torpedo bay is block'
	DB	'ed by a hull breach. Fortunately, it is highly unlikely that we '
	DB	'will need this ship''s weapons systems.',0
T_VEN2_037	LABEL	BYTE
	DB	'#VEN2\VEN2_037#Captain, the torpedo loading system is malfunctio'
	DB	'ning. To clear it, we will have to physically examine the mechan'
	DB	'ism. Currently, all turbolift access to the torpedo bay is block'
	DB	'ed by a hull breach. It is imperative that we get the weapons on'
	DB	'-line.',0
T_VEN2N032_2	LABEL	BYTE
	DB	'#VEN2\VEN2N032#This is the Auxiliary Ship Damage Display. The re'
	DB	'adouts indicate extensive damage.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0
DefyElasi	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_VEN2_012, OFFSET T_VEN2_011, 0	; speaker, choices, 0
PowerChoices	LABEL	BYTE
	DW	OFFSET S_5125, OFFSET T_VEN2_WEA, OFFSET T_VEN2_SHI, OFFSET T_VEN2_TRA, 0	; speaker, choices, 0
	DB	25h, 51h, 9Dh, 56h, 0C0h, 56h, 0, 0, 74h, 50h, 0E3h
	DB	'V.W',0
	DB	0

RDF	ENDS
	END
