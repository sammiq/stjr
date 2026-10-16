; TRIAL0.RDF - "The Feathered Serpent", part two (the trial): the Klingon
; court on Hrakkour, a world destroyed in the war.
; Admiral Vlict tries Quetzecoatl. Kirk can let the trial run (he is
; dismissed as a coward, and the mission ends), or claim a warrior's
; trial for Quetzecoatl: the Test of Life, which starts in room 1.
;
; Actors: 8 Vlict, 9 the guard, 10 (0Ah) Quetzecoatl.
; Objects: 8 Vlict, 9 the guard, 0Ah Quetzecoatl, 23h the bench, 25h the
; city, 26h the seal (walk: step forward).
; Timer 0: background sounds.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The conversation at 00CE is built at run time.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
score	EQU	RS_VARS+0	; word: the mission's score
max_score	EQU	RS_VARS+2	; word: for the debriefing
ending	EQU	RS_VARS+36h	; word: how it ended, for room 9: 0 Kirk let the trial run, 1 he beamed back mid-trial, 2 Quetzecoatl was lost, 3 the Klingons leave, 4 Vlict was executed

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
	DW	270,182, 267,157, 293,186, 297,159	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	270,182, 267,157, 293,186, 297,159
	DB	0CEh, 0, 0CEh, 0
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
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
N_Vlict	LABEL	BYTE
	DB	'Vlict',0
N_Klingon_Guard	LABEL	BYTE
	DB	'Klingon Guard',0
N_Quetzecoatl	LABEL	BYTE
	DB	'Quetzecoatl',0
rdf_objects	LABEL	BYTE
	DW	23h, 4	; id, points
	DW	107,71, 210,71, 182,119, 136,118
	DW	24h, 4	; id, points
	DW	122,36, 198,36, 178,71, 140,71
	DW	25h, 4	; id, points
	DW	51,57, 269,57, 252,82, 68,82
	DW	26h, 4	; id, points
	DW	116,148, 205,148, 205,187, 116,187
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	116,148, 205,148, 205,187, 116,187
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	't0b1',0
	DB	't0b2',0
	DB	't0b3',0
	DB	't0b4',0

rdf_scripts:
rdf_bans_end:
; The room starts: the score's maximum, Vlict, the guard, Quetzecoatl.
H_01E6:
	SCRIPT	MSG_TICK, 1, 0, 0, H_027C
StartRoom:
	jmp	SHORT L01F7

N_TRI0LOOP	LABEL	BYTE
	DB	'TRI0LOOP',0
L01F7:
	push	OFFSET N_TRI0LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("TRI0LOOP")
	add	sp, 4
	push	258h
	push	0B4h
	push	RC_RANDOM
	SERVICE		; Random(180, 600)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS], ax
	mov	word ptr [si+max_score], 1Dh
	jmp	SHORT L0226

N_vlict1	LABEL	BYTE
	DB	'vlict1',0
L0226:
	push	0
	push	48h
	push	9Fh
	push	OFFSET N_vlict1
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "vlict1", 159, 72, 0)
	add	sp, 0Ch
	jmp	SHORT L0245

N_kgstnd	LABEL	BYTE
	DB	'kgstnd',0
L0245:
	push	0
	push	6Ah
	push	0DCh
	push	OFFSET N_kgstnd
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "kgstnd", 220, 106, 0)
	add	sp, 0Ch
	jmp	SHORT L0264

N_qteleg	LABEL	BYTE
	DB	'qteleg',0
L0264:
	push	0
	push	0AAh
	push	10Eh
	push	OFFSET N_qteleg
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "qteleg", 270, 170, 0)
	add	sp, 0Ch
	retf

; Tick 40: Vlict calls the trial to order.
H_027C:
	SCRIPT	MSG_TICK, 28h, 0, 0, H_02E6
VlictOpens:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_058
	call	Say
	jmp	SHORT L02E5

T_TRI0_058	LABEL	BYTE
	DB	'#TRI0\TRI0_058#The prisoner and his witnesses will stand forth, '
	DB	'so the trial may begin!',0
L02E5:
	retf

; Timer 0: a random sound, again in 180-600 ticks.
H_02E6:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_02FF
Ambience:
	push	258h
	push	0B4h
	push	RC_RANDOM
	SERVICE		; Random(180, 600)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS], ax
	retf

; Kirk steps forward (msg 1) and the trial is held: a run of
; conversations built at run time (talk_buf, choice_jumps). Claiming a
; warrior's rights for Quetzecoatl sends the party to the Test of Life
; (room 1); letting the trial run ends the mission (ending 0).
H_02FF:
	SCRIPT	MSG_WALK, 26h, 0, 0, H_032A
StandForth:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 1
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 0A0h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 160, 170, 1)
	add	sp, 0Ah
	retf

H_032A:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_18C9
TheTrial:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_053
	call	Say
	jmp	SHORT L03B4

T_TRI0_053	LABEL	BYTE
	DB	'#TRI0\TRI0_053#So Kirk, we finally meet. I had thought it would '
	DB	'be in battle, but the universe holds many surprises.',0
L03B4:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L042B

T_TRI0_019	LABEL	BYTE
	DB	'#TRI0\TRI0_019#There''s nothing less appealing than a gloating Kl'
	DB	'ingon, Vlict. Let''s get this trial under way.',0
L042B:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI0_019
	mov	word ptr cs:choice_jumps, OFFSET L0535
	jmp	SHORT L0486

T_TRI0_016	LABEL	BYTE
	DB	'#TRI0\TRI0_016#Stick around, Vlict. There are more surprises awa'
	DB	'iting you.',0
L0486:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI0_016
	mov	word ptr cs:choice_jumps+2, OFFSET L0535
	jmp	SHORT L050A

T_TRI0_021	LABEL	BYTE
	DB	'#TRI0\TRI0_021#Why does every Klingon tell me they expected to m'
	DB	'eet me in battle? You really have a one-track mind!',0
L050A:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI0_021
	mov	word ptr cs:choice_jumps+4, OFFSET L0535
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L0535:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_054
	call	Say
	JMPN	L0609

T_TRI0_054	LABEL	BYTE
	DB	'#TRI0\TRI0_054#So be it. This begins the trial of the entity K''e'
	DB	'tz''koatl, who is charged with impersonating a klingon, stirring '
	DB	'dissent, encouraging cowardice, and treason in the highest degre'
	DB	'e.',0
L0609:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI0_004
	call	Say
	jmp	SHORT L0675

T_TRI0_004	LABEL	BYTE
	DB	'#TRI0\TRI0_004#Those are serious charges, Vlict. Should he not b'
	DB	'e tried by a Klingon High Court?',0
L0675:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_047
	call	Say
	JMPN	L071E

T_TRI0_047	LABEL	BYTE
	DB	'#TRI0\TRI0_047#He has not demonstrated honor, Kirk! Only a prove'
	DB	'n warrior may be tried in High Court! Principles of honor are no'
	DB	't applicable to his defense!',0
L071E:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	JMPN	L07A9

T_TRI0_011	LABEL	BYTE
	DB	'#TRI0\TRI0_011#I''m a warrior, Vlict! I hereby intervene for him '
	DB	'and demand the honors and responsibilities of a warrior''s trial!',0
L07A9:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI0_011
	mov	word ptr cs:choice_jumps, OFFSET L0882
	jmp	SHORT L0803

T_TRI0_018	LABEL	BYTE
	DB	'#TRI0\TRI0_018#Then this trial is a mockery for the entire galax'
	DB	'y to see!',0
L0803:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI0_018
	mov	word ptr cs:choice_jumps+2, OFFSET L0B94
	jmp	SHORT L0857

T_TRI0_015	LABEL	BYTE
	DB	'#TRI0\TRI0_015#Oh well. I''m afraid you''re on your own, Quetzecoa'
	DB	'tl.',0
L0857:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI0_015
	mov	word ptr cs:choice_jumps+4, OFFSET L1782
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L0882:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_043
	call	Say
	jmp	SHORT L08FF

T_TRI0_043	LABEL	BYTE
	DB	'#TRI0\TRI0_043#A Federation officer, claiming the rights of a Kl'
	DB	'ingon warrior? How dare you insult me, Kirk!',0
L08FF:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI0_002
	call	Say
	JMPN	L09B9

T_TRI0_002	LABEL	BYTE
	DB	'#TRI0\TRI0_002#I''ve faced Klingons, both in personal and ship-to'
	DB	'-ship combat. Your own records will confirm this. If I''m not wor'
	DB	'thy of their honors, why didn''t they kill me?',0
L09B9:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_056
	call	Say
	jmp	SHORT L09FE

T_TRI0_056	LABEL	BYTE
	DB	'#TRI0\TRI0_056#That oversight, Kirk, is easily rectified.',0
L09FE:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_061
	call	Say
	JMPN	L0A9D

T_TRI0_061	LABEL	BYTE
	DB	'#TRI0\TRI0_061#You and your three companions may face the tests '
	DB	'that we set for the defender. Then we shall see if you are as wo'
	DB	'rthy as a Klingon!',0
L0A9D:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI0_001
	call	Say
	jmp	SHORT L0B18

T_TRI0_001	LABEL	BYTE
	DB	'#TRI0\TRI0_001#I want your word of honor, Vlict, that Quetzecoat'
	DB	'l will not be harmed while we take these tests.',0
L0B18:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_060
	call	Say
	jmp	SHORT ToTheTest

T_TRI0_060	LABEL	BYTE
	DB	'#TRI0\TRI0_060#Very well. You have my word. Captain Kallarax, tr'
	DB	'ansport them to the Test of Life.',0
ToTheTest:
	mov	byte ptr [si+RS_BUSY], 1
	push	4
	push	1
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(1, 4)
L0B94:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_048
	call	Say
	JMPN	L0C28

T_TRI0_048	LABEL	BYTE
	DB	'#TRI0\TRI0_048#How typical of the Federation, to judge every oth'
	DB	'er species as morally inferior. Your rhetoric is not welcome her'
	DB	'e!',0
L0C28:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI0_041
	call	Say
	JMPN	L0CB9

T_TRI0_041	LABEL	BYTE
	DB	'#TRI0\TRI0_041#I offered them insights into the philosophy of pe'
	DB	'ace and cooperation. They chose to follow it of their own free w'
	DB	'ill.',0
L0CB9:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_050
	call	Say
	JMPN	L0D6D

T_TRI0_050	LABEL	BYTE
	DB	'#TRI0\TRI0_050#K''etz''koatl, you encouraged the colony to destroy'
	DB	' its weapons. You even encouraged them to hold their children fr'
	DB	'om our traditional military ceremonies.',0
L0D6D:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI0_039
	call	Say
	jmp	SHORT L0DD2

T_TRI0_039	LABEL	BYTE
	DB	'#TRI0\TRI0_039#Children should not even play at war. To prepare '
	DB	'them to kill is barbaric.',0
L0DD2:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_059
	call	Say
	JMPN	L0EAA

T_TRI0_059	LABEL	BYTE
	DB	'#TRI0\TRI0_059#To counsel it is to counsel cowardice. To counsel'
	DB	' it is to abandon all honor! This is treason, for all to see! Th'
	DB	'e penalty for treason in this system is death! Do you accept you'
	DB	'r sentence?',0
L0EAA:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI0_040
	call	Say
	jmp	SHORT L0EEC

T_TRI0_040	LABEL	BYTE
	DB	'#TRI0\TRI0_040#I have failed. Death is what I deserve.',0
L0EEC:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_046
	call	Say
	jmp	SHORT L0F6F

T_TRI0_046	LABEL	BYTE
	DB	'#TRI0\TRI0_046#He has admitted guilt. You have surrendered him t'
	DB	'o Klingon law. Can you deny that this was a fair trial?',0
L0F6F:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L0FF0

T_TRI0_023	LABEL	BYTE
	DB	'#TRI0\TRI0_023#You''re going to kill this old man because he enco'
	DB	'uraged non-violence? The Federation cannot accept this.',0
L0FF0:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI0_023
	mov	word ptr cs:choice_jumps, OFFSET L1121
	JMPN	L109C

T_TRI0_006	LABEL	BYTE
	DB	'#TRI0\TRI0_006#By our standards, he would rank among the greates'
	DB	't heroes of the Federation: Gandhi, Surak, M''lelto-jhi, Shanarda'
	DB	'. We will not abandon him.',0
L109C:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI0_006
	mov	word ptr cs:choice_jumps+2, OFFSET L1121
	jmp	SHORT L10F6

T_TRI0_010	LABEL	BYTE
	DB	'#TRI0\TRI0_010#Guess I can''t argue with you. Pleasant conquests,'
	DB	' admiral.',0
L10F6:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI0_010
	mov	word ptr cs:choice_jumps+4, OFFSET L1782
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L1121:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_052
	call	Say
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	JMPN	L11C9

T_TRI0_017	LABEL	BYTE
	DB	'#TRI0\TRI0_017#Then a Klingon can thrive on the conflict between'
	DB	' his inner nature and his philosophy. Clearly, the people of Hra'
	DB	'kkour did that.',0
L11C9:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI0_017
	mov	word ptr cs:choice_jumps, OFFSET L12FE
	JMPN	L1261

T_TRI0_020	LABEL	BYTE
	DB	'#TRI0\TRI0_020#This is a matter for a philosophical debate, not '
	DB	'a trial! The state has no right to interfere in a person''s consc'
	DB	'ience.',0
L1261:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI0_020
	mov	word ptr cs:choice_jumps+2, OFFSET L12FE
	jmp	SHORT L12D3

T_TRI0_008	LABEL	BYTE
	DB	'#TRI0\TRI0_008#Fine. Can we get this over with? I''ve got shore l'
	DB	'eave scheduled on Ryza next week.',0
L12D3:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI0_008
	mov	word ptr cs:choice_jumps+4, OFFSET L1782
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L12FE:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_057
	call	Say
	jmp	SHORT L134B

T_TRI0_057	LABEL	BYTE
	DB	'#TRI0\TRI0_057#The Klingon Empire will not tolerate dissent.',0
L134B:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI0_003
	call	Say
	jmp	SHORT L1387

T_TRI0_003	LABEL	BYTE
	DB	'#TRI0\TRI0_003#Then the Klingon Empire is wrong.',0
L1387:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_051
	call	Say
	JMPN	L142F

T_TRI0_051	LABEL	BYTE
	DB	'#TRI0\TRI0_051#Only the greatest warriors of old could say such '
	DB	'a thing and expect to live! Do you think yourself worthy enough '
	DB	'to walk in their footsteps?',0
L142F:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L1484

T_TRI0_009	LABEL	BYTE
	DB	'#TRI0\TRI0_009#Give me an opportunity. If I succeed, Quetzecoatl'
	DB	' goes free.',0
L1484:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI0_009
	mov	word ptr cs:choice_jumps, OFFSET L15E2
	JMPN	L151E

T_TRI0_014	LABEL	BYTE
	DB	'#TRI0\TRI0_014#If it means that I can prevent you from murdering'
	DB	' an ancient and blameless creature, yes. And I''m prepared to bac'
	DB	'k it up.',0
L151E:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI0_014
	mov	word ptr cs:choice_jumps+2, OFFSET L15E2
	JMPN	L15B7

T_TRI0_013	LABEL	BYTE
	DB	'#TRI0\TRI0_013#I''m James T. Kirk. I''m more worthy than you''ll ev'
	DB	'er be, and I have girlfriends on fifty planets who will vouch fo'
	DB	'r that!',0
L15B7:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI0_013
	mov	word ptr cs:choice_jumps+4, OFFSET L168A
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L15E2:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_055
	call	Say
	JMPN	L167B

T_TRI0_055	LABEL	BYTE
	DB	'#TRI0\TRI0_055#Stories of your impudence are not exaggerated. Yo'
	DB	'u shall have your chance. It is a pity we will not meet again, C'
	DB	'aptain.',0
L167B:
	mov	byte ptr [si+RS_BUSY], 1
	push	4
	push	1
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(1, 4)
L168A:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_045
	call	Say
	JMPN	L1773

T_TRI0_045	LABEL	BYTE
	DB	'#TRI0\TRI0_045#Ha! Ha! You have never encountered Klingon women,'
	DB	' Captain. But that was the response of a true warrior. You have '
	DB	'earned my respect. I shall give you and your companions a chance'
	DB	' to defend the traitor.',0
L1773:
	mov	byte ptr [si+RS_BUSY], 1
	push	4
	push	1
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(1, 4)
L1782:
	mov	si, word ptr cs:rdf_state
	mov	ax, -1
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(2, -1)
	add	sp, 6
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_049
	call	Say
	jmp	SHORT L17E8

T_TRI0_049	LABEL	BYTE
	DB	'#TRI0\TRI0_049#I hereby sentence K''etz''coatl to a coward''s death'
	DB	'.',0
L17E8:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_044
	call	Say
	JMPN	Dismissed

T_TRI0_044	LABEL	BYTE
	DB	'#TRI0\TRI0_044#As for you Kirk, I expected a more forceful respo'
	DB	'nse. I had heard you were a worthy opponent. Instead, I see a cr'
	DB	'inging coward. Leave this place, Kirk. You dishonor it.',0
Dismissed:
	mov	si, word ptr cs:rdf_state
	mov	word ptr [si+ending], 0
	push	0
	push	word ptr [si+max_score]
	push	word ptr [si+score]
	push	RC_BEAMUP
	SERVICE		; BeamUp(?, ?, 0)
	add	sp, 8
	retf

; Looking and talking.
H_18C9:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_196F
LookAtCity:
	mov	ax, 0
	mov	bx, OFFSET T_TRI0N007
	call	Say
	JMPN	L196E

T_TRI0N007	LABEL	BYTE
	DB	'#TRI0\TRI0N007#This city was destroyed by heavy bombardment and '
	DB	'intense doses of neutrino rays that killed all known forms of li'
	DB	'fe on this planet.',0
L196E:
	retf

H_196F:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_19CA
LookAtVlict:
	mov	ax, 0
	mov	bx, OFFSET T_TRI0N001
	call	Say
	jmp	SHORT L19C9

T_TRI0N001	LABEL	BYTE
	DB	'#TRI0\TRI0N001#Admiral Vlict, commander of the Klingon flagship '
	DB	'K''lirta.',0
L19C9:
	retf

H_19CA:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_1A68
LookAtGuard:
	mov	ax, 0
	mov	bx, OFFSET T_TRI0N000
	call	Say
	JMPN	L1A67

T_TRI0N000	LABEL	BYTE
	DB	'#TRI0\TRI0N000#A Klingon guard. A big Klingon guard. A big Kling'
	DB	'on guard with his disruptor ready to fire on anyone who gives hi'
	DB	'm trouble.',0
L1A67:
	retf

H_1A68:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_1B0C
LookAtBench:
	mov	ax, 0
	mov	bx, OFFSET T_TRI0N006
	call	Say
	JMPN	L1B0B

T_TRI0N006	LABEL	BYTE
	DB	'#TRI0\TRI0N006#This bench is marked with the symbol of the Kling'
	DB	'on Court of High Justice, the two Triangles of Words and Blood, '
	DB	'linked together.',0
L1B0B:
	retf

H_1B0C:
	SCRIPT	MSG_LOOK, 26h, 0, 0, H_1B5C
LookAtSeal:
	mov	ax, 0
	mov	bx, OFFSET T_TRI0N008
	call	Say
	jmp	SHORT L1B5B

T_TRI0N008	LABEL	BYTE
	DB	'#TRI0\TRI0N008#This is the famous seal of the Klingon Empire.',0
L1B5B:
	retf

H_1B5C:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_1BE5
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_TRI0N004
	call	Say
	jmp	SHORT L1BE4

T_TRI0N004	LABEL	BYTE
	DB	'#TRI0\TRI0N004#James T. Kirk, trapped in a situation he cannot w'
	DB	'in, forced to watch a travesty of justice... or is he?',0
L1BE4:
	retf

H_1BE5:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_1C65
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_TRI0N005
	call	Say
	jmp	SHORT L1C64

T_TRI0N005	LABEL	BYTE
	DB	'#TRI0\TRI0N005#Mr. Spock looks stoically at the klingon bench. E'
	DB	'xpecting to win this case would be illogical.',0
L1C64:
	retf

H_1C65:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_1CF8
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_TRI0N002
	call	Say
	JMPN	L1CF7

T_TRI0N002	LABEL	BYTE
	DB	'#TRI0\TRI0N002#Dr. McCoy glares angrily at Kirk. It is obvious h'
	DB	'e does not like seeing his patient handed over to the Klingons.',0
L1CF7:
	retf

H_1CF8:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_1D68
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_TRI0N003
	call	Say
	jmp	SHORT L1D67

T_TRI0N003	LABEL	BYTE
	DB	'#TRI0\TRI0N003#Ensign Bennie stares around the Klingon court, di'
	DB	'strusting everything he sees.',0
L1D67:
	retf

H_1D68:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_1DDB
LookAtQuetzecoatl:
	mov	ax, 0
	mov	bx, OFFSET T_TRI0N009
	call	Say
	jmp	SHORT L1DDA

T_TRI0N009	LABEL	BYTE
	DB	'#TRI0\TRI0N009#Your new found friend looks rather frightened rig'
	DB	'ht now, and you don''t blame him.',0
L1DDA:
	retf

H_1DDB:
	SCRIPT	MSG_TALK, 8, 0, 0, H_1E33
TalkToVlict:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI0_062
	call	Say
	jmp	SHORT L1E32

T_TRI0_062	LABEL	BYTE
	DB	'#TRI0\TRI0_062#You will not speak unless the court requests it, '
	DB	'Kirk!',0
L1E32:
	retf

H_1E33:
	SCRIPT	MSG_TALK, 9, 0, 0, H_203C
TalkToGuard:
	mov	ax, OFFSET N_Klingon_Guard
	mov	bx, OFFSET T_TRI0_F24
	call	Say
	jmp	SHORT L1E76

T_TRI0_F24	LABEL	BYTE
	DB	'#TRI0\TRI0_F24#How amusing. Federation weaklings.',0
L1E76:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI0_065
	call	Say
	jmp	SHORT L1EDC

T_TRI0_065	LABEL	BYTE
	DB	'#TRI0\TRI0_065#Who are you calling a weakling? I''ve had tougher '
	DB	'girlfriends than you, pal!',0
L1EDC:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI0_007
	call	Say
	jmp	SHORT L1EFE

T_TRI0_007	LABEL	BYTE
	DB	'#TRI0\TRI0_007#Ensign!',0
L1EFE:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI0_064
	call	Say
	jmp	SHORT L1F7D

T_TRI0_064	LABEL	BYTE
	DB	'#TRI0\TRI0_064#But I did, sir. Lieutenant Hildebrandt is a third'
	DB	' dan in karate. Toughest fighter I''ve ever known...',0
L1F7D:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI0_022
	call	Say
	JMPN	L2018

T_TRI0_022	LABEL	BYTE
	DB	'#TRI0\TRI0_022#You will act with the discipline of a Federation '
	DB	'officer, Ensign, or you will return to the Enterprise. Do I make'
	DB	' myself clear?',0
L2018:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI0_066
	call	Say
	jmp	SHORT L203B

T_TRI0_066	LABEL	BYTE
	DB	'#TRI0\TRI0_066#Yes sir.',0
L203B:
	retf

H_203C:
	SCRIPT	MSG_TALK, 0Ah, 0, 0, H_20A1
TalkToQuetzecoatl:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI0_042
	call	Say
	jmp	SHORT L20A0

T_TRI0_042	LABEL	BYTE
	DB	'#TRI0\TRI0_042#I''m frightened, Captain, but if I am to die, then'
	DB	' I shall die well.',0
L20A0:
	retf

H_20A1:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_20E7
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI0_031
	call	Say
	jmp	SHORT L20E6

T_TRI0_031	LABEL	BYTE
	DB	'#TRI0\TRI0_031#I''ve got nothing to say to you, Jim.',0
L20E6:
	retf

H_20E7:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_215C
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI0_025
	call	Say
	jmp	SHORT L215B

T_TRI0_025	LABEL	BYTE
	DB	'#TRI0\TRI0_025#Captain, I estimate the odds of this court acquit'
	DB	'ting Quetzecoatl at 0.086 percent.',0
L215B:
	retf

H_215C:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_2198
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI0_063
	call	Say
	jmp	SHORT L2197

T_TRI0_063	LABEL	BYTE
	DB	'#TRI0\TRI0_063#Awaiting your orders, sir!',0
L2197:
	retf

H_2198:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_21A0
StunAnything:
	jmp	SHORT L21B0

H_21A0:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_21A8
KillAnything:
	jmp	SHORT L21B0

; Attacking anyone: Spock and McCoy object.
H_21A8:
	SCRIPT	MSG_USE, IT_ROCK, ANY, 0, H_22CE
RockAtAnyone:
	jmp	SHORT L21B0

L21B0:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI0_026
	call	Say
	JMPN	L224F

T_TRI0_026	LABEL	BYTE
	DB	'#TRI0\TRI0_026#Captain, may I remind you that we are deep in Kli'
	DB	'ngon space? If we attack them here, they may respond by destroyi'
	DB	'ng the Enterprise.',0
L224F:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI0_036
	call	Say
	jmp	SHORT L22CD

T_TRI0_036	LABEL	BYTE
	DB	'#TRI0\TRI0_036#Don''t be a fool, Jim! We can''t risk the Enterpris'
	DB	'e!We''ve already signed one person''s death warrant!',0
L22CD:
	retf

H_22CE:
	SCRIPT	MSG_USE, IT_SNAKE, 8, 0, H_2336
SnakeOnVlict:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_076
	call	Say
	jmp	SHORT L2335

T_TRI4_076	LABEL	BYTE
	DB	'#TRI4\TRI4_076#You humans have an excellent imagination, but a p'
	DB	'oor grasp of reality.',0
L2335:
	retf

H_2336:
	SCRIPT	MSG_USE, IT_SNAKE, 9, 0, H_237A
SnakeOnGuard:
	mov	ax, OFFSET N_Klingon_Guard
	mov	bx, OFFSET T_TRI0_F24_2
	call	Say
	jmp	SHORT L2379

T_TRI0_F24_2	LABEL	BYTE
	DB	'#TRI0\TRI0_F24#How amusing. Federation weaklings.',0
L2379:
	retf

; Tricorders, the communicator, and the crew on the Klingons.
H_237A:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Ah, 0, H_23F1
McCoyScansQuetzecoatl:
	mov	byte ptr [si+RS_FALL+2], 1
	jmp	SHORT L238D

N_mscans	LABEL	BYTE
	DB	'mscans',0
L238D:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscans
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscans", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI0_029
	call	Say
	jmp	SHORT L23F0

T_TRI0_029	LABEL	BYTE
	DB	'#TRI0\TRI0_029#He''s still weak from the operation.',0
L23F0:
	retf

H_23F1:
	SCRIPT	MSG_USE, IT_MTRICOR, 8, 0, H_2464
McCoyScansVlict:
	mov	byte ptr [si+RS_FALL+2], 1
	jmp	SHORT L2404

N_mscans_2	LABEL	BYTE
	DB	'mscans',0
L2404:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscans_2
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscans", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI0_030
	call	Say
	jmp	SHORT L2463

T_TRI0_030	LABEL	BYTE
	DB	'#TRI0\TRI0_030#One healthy adult klingon male.',0
L2463:
	retf

H_2464:
	SCRIPT	MSG_USE, IT_MTRICOR, ANY, 0, H_24CC
McCoyScans:
	mov	byte ptr [si+RS_FALL+2], 1
	jmp	SHORT L2477

N_mscans_3	LABEL	BYTE
	DB	'mscans',0
L2477:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscans_3
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscans", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI0_035
	call	Say
	jmp	SHORT L24CB

T_TRI0_035	LABEL	BYTE
	DB	'#TRI0\TRI0_035#Nothing of interest.',0
L24CB:
	retf

H_24CC:
	SCRIPT	MSG_USE, IT_STRICOR, 25h, 0, H_2584
SpockScansCity:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L24DF

N_sscans	LABEL	BYTE
	DB	'sscans',0
L24DF:
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
	mov	bx, OFFSET T_TRI0_037
	call	Say
	jmp	SHORT L2583

T_TRI0_037	LABEL	BYTE
	DB	'#TRI0\TRI0_037#Low level radiation, within safety limits. But yo'
	DB	'u wouldn''t want to spend more than a few days here.',0
L2583:
	retf

H_2584:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_25BA
SpockScans:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI0_038
	call	Say
	jmp	SHORT L25B9

T_TRI0_038	LABEL	BYTE
	DB	'#TRI0\TRI0_038#Nothing of interest.',0
L25B9:
	retf

H_25BA:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_263F
UseCommunicator:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI0U075
	call	Say
	jmp	SHORT L263E

T_TRI0U075	LABEL	BYTE
	DB	'#TRI0\TRI0U075#Uhura here. Captain, there''s a force field over t'
	DB	'he planet. We will not be able to beam you aboard.',0
L263E:
	retf

H_263F:
	SCRIPT	MSG_USE, OBJ_SPOCK, 9, 0, H_2647
SpockOnGuard:
	jmp	SHORT L266F

H_2647:
	SCRIPT	MSG_USE, OBJ_KIRK, 9, 0, H_264F
KirkOnGuard:
	jmp	SHORT L266F

H_264F:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 9, 0, H_2657
BennieOnGuard:
	jmp	SHORT L266F

H_2657:
	SCRIPT	MSG_USE, OBJ_SPOCK, 8, 0, H_265F
SpockOnVlict:
	jmp	SHORT L266F

H_265F:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 8, 0, H_2667
BennieOnVlict:
	jmp	SHORT L266F

H_2667:
	SCRIPT	MSG_USE, OBJ_KIRK, 8, 0, H_26D3
KirkOnVlict:
	jmp	SHORT L266F

L266F:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI0_024
	call	Say
	jmp	SHORT L26D2

T_TRI0_024	LABEL	BYTE
	DB	'#TRI0\TRI0_024#Any hostile action here may result in the destruc'
	DB	'tion of the Enterprise.',0
L26D2:
	retf

H_26D3:
	SCRIPT	MSG_USE, OBJ_MCCOY, 8, 0, H_2720
McCoyOnVlict:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI0_027
	call	Say
	jmp	SHORT L271F

T_TRI0_027	LABEL	BYTE
	DB	'#TRI0\TRI0_027#Damn it Jim, I''m a doctor not a arbitrator.',0
L271F:
	retf

H_2720:
	SCRIPT	MSG_USE, OBJ_MCCOY, 9, 0, H_277C
McCoyOnGuard:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI0_028
	call	Say
	jmp	SHORT L277B

T_TRI0_028	LABEL	BYTE
	DB	'#TRI0\TRI0_028#Damn it, Jim!  I use my hands to save lives not t'
	DB	'ake them.',0
L277B:
	retf

H_277C:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, T_TRI0_052
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI0_034
	call	Say
	jmp	SHORT L27DD

T_TRI0_034	LABEL	BYTE
	DB	'#TRI0\TRI0_034#Nobody needs healing, Jim, but you will if they h'
	DB	'arm my patient.',0
L27DD:
	retf

rdf_scripts_end	LABEL	BYTE
T_TRI0_052	LABEL	BYTE
	DB	'#TRI0\TRI0_052#Pacifism is utterly alien to our people. It would'
	DB	' be as though he preached a doctrine of suicide in direct contra'
	DB	'diction of the will to live. Honorable men thrive in war and con'
	DB	'flict -- cowards seek to avoid conflict.',0

RDF	ENDS
	END
