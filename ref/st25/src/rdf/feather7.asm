; FEATHER7.RDF - "The Feathered Serpent", Quetzecoatl's chamber, the end
; of the mission. Quetzecoatl reveals that the jungle was a test of the
; party, hears the truth about the Aztecs, and agrees to come to the
; Enterprise to answer to the Klingons.
;
; Actors: 8 Quetzecoatl.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 03E3: the engine reads its bytes
;   as key 50 6A 03 2E and next 1EFF (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
died_in_cave	EQU	RS_VARS+0	; Kirk was killed in the cave and revived (room 6)
knocked_out	EQU	RS_VARS+0Ah	; Tlaoxac was knocked out (room 3)
score	EQU	RS_VARS+0Dh	; word: the mission's score

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0A7h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	7Ah
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
	DW	217,123, 217,127	; entrance 2, crew 0
	DW	249,124, 249,128	; entrance 2, crew 1
	DW	234,133, 234,137	; entrance 2, crew 2
	DW	240,114, 240,118	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	217,127, 249,128, 234,137, 240,118
; In the room file, so these start again each time the room loads
harsh	LABEL	BYTE	; Kirk was harsh with Quetzecoatl
	DB	0
N_s5r7qn	LABEL	BYTE
	DB	's5r7qn',0
N_s5r7qw	LABEL	BYTE
	DB	's5r7qw',0
N_s5r7qt	LABEL	BYTE
	DB	's5r7qt',0
N_s5r7ks	LABEL	BYTE
	DB	's5r7ks',0
N_s5r7ss	LABEL	BYTE
	DB	's5r7ss',0
N_s5r7ms	LABEL	BYTE
	DB	's5r7ms',0
N_s5r7ku	LABEL	BYTE
	DB	's5r7ku',0
N_s5r7su	LABEL	BYTE
	DB	's5r7su',0
N_s5r7mu	LABEL	BYTE
	DB	's5r7mu',0

rdf_scripts:
; The room starts: Quetzecoatl, the party unable to move.
H_010A:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0152
StartRoom:
	jmp	SHORT L011B

N_FEA7LOOP	LABEL	BYTE
	DB	'FEA7LOOP',0
L011B:
	push	OFFSET N_FEA7LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("FEA7LOOP")
	add	sp, 4
	push	21h
	push	RC_MUSIC
	SERVICE		; Music(33)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 2
	push	0
	push	98h
	push	106h
	push	OFFSET N_s5r7qn
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s5r7qn", 262, 152, 0)
	add	sp, 0Ch
	retf

; Tick 40: Quetzecoatl apologises (if Kirk died), praises Stragey's
; sacrifice, regrets Tlaoxac (if knocked out), and has everyone sit
; (walk msgs 1-3, anim msg 4).
H_0152:
	SCRIPT	MSG_TICK, 28h, 0, 0, H_01E8
QuetzecoatlSpeaks:
	cmp	byte ptr [si+died_in_cave], 1
	jne	L0167
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA7_017
	call	Say
L0167:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA7_022
	call	Say
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L018E
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA7_021
	call	Say
	cmp	byte ptr [si+knocked_out], 1
	jne	L018E
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA7_023
	call	Say
L018E:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA7_027
	call	Say
	push	1
	push	93h
	push	6Ch
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 108, 147, 1)
	add	sp, 0Ah
	push	2
	push	8Ch
	push	0BBh
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 187, 140, 2)
	add	sp, 0Ah
	push	3
	push	8Ch
	push	8Dh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 141, 140, 3)
	add	sp, 0Ah
	push	4
	push	-1
	push	-1
	push	OFFSET N_s5r7qw
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s5r7qw", -1, -1, 4)
	add	sp, 0Ch
	retf

H_01E8:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_0204
KirkSits:
	push	1
	push	-1
	push	-1
	push	OFFSET N_s5r7ks
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r7ks", -1, -1, 1)
	add	sp, 0Ch
	retf

H_0204:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_0220
SpockSits:
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r7ss
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "s5r7ss", -1, -1, 0)
	add	sp, 0Ch
	retf

H_0220:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_023C
McCoySits:
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r7ms
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "s5r7ms", -1, -1, 0)
	add	sp, 0Ch
	retf

H_023C:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_025A
QuetzecoatlSits:
	push	0
	push	98h
	push	97h
	push	OFFSET N_s5r7qn
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s5r7qn", 151, 152, 0)
	add	sp, 0Ch
	retf

; Seated (anim msg 1): the conversation. Quetzecoatl decides to give up
; his power and stand trial among the Klingons (anim msg 2).
H_025A:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_0388
TalkWithQuetzecoatl:
	mov	ax, OFFSET KirkOnTests
	call	Talk
	AX8	cmp, 0
	jne	L0273
	mov	byte ptr cs:harsh, 1
	jmp	SHORT L027F

L0273:
	AX8	cmp, 1
	jne	L027A
	jmp	SHORT L028A

L027A:
	AX8	cmp, 2
	jmp	SHORT L0295

L027F:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA7_020
	call	Say
	jmp	SHORT L029E

L028A:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA7_019
	call	Say
	jmp	SHORT L029E

L0295:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA7_016
	call	Say
L029E:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA7_029
	call	Say
	mov	ax, OFFSET KirkOnAztecs
	call	Talk
	AX8	cmp, 0
	jne	L02BA
	mov	byte ptr cs:harsh, 1
	jmp	SHORT L02C9

L02BA:
	AX8	cmp, 1
	jne	L02C1
	jmp	SHORT L02D4

L02C1:
	mov	byte ptr cs:harsh, 1
	jmp	SHORT L02DF

L02C9:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA7_030
	call	Say
	jmp	SHORT L02E8

L02D4:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA7_018
	call	Say
	jmp	SHORT L02E8

L02DF:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA7_026
	call	Say
L02E8:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_FEA7_014
	call	Say
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA7_024
	call	Say
	mov	ax, OFFSET KirkOnProgress
	call	Talk
	AX8	cmp, 0
	jne	L030D
	mov	byte ptr cs:harsh, 1
	jmp	SHORT L0319

L030D:
	AX8	cmp, 1
	jne	L0314
	jmp	SHORT L0324

L0314:
	AX8	cmp, 2
	jmp	SHORT L032D

L0319:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA7_025
	call	Say
	jmp	SHORT L032D

L0324:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA7_028
	call	Say
L032D:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_FEA7_015
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA7_013
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_FEA7_003
	call	Say
	push	2
	push	-1
	push	-1
	push	OFFSET N_s5r7ku
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r7ku", -1, -1, 2)
	add	sp, 0Ch
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r7su
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "s5r7su", -1, -1, 0)
	add	sp, 0Ch
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r7mu
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "s5r7mu", -1, -1, 0)
	add	sp, 0Ch
	retf

; The end: four or five to beam up (+1 with Stragey alive), +2 unless
; Kirk was harsh, +4; BeamUp(score, 19, 0).
H_0388:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, Talk
BeamUp:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L039F
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_FEA7_002
	call	Say
	jmp	SHORT L03AC

L039F:
	add	word ptr [si+score], 1
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_FEA7_001
	call	Say
L03AC:
	cmp	byte ptr cs:harsh, 1
	je	L03B8
	add	word ptr [si+score], 2
L03B8:
	add	word ptr [si+score], 4
	push	0
	push	-1
	push	-1
	push	OFFSET N_s5r7qt
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s5r7qt", -1, -1, 0)
	add	sp, 0Ch
	push	0
	push	13h
	push	word ptr [si+score]
	push	RC_BEAMUP
	SERVICE		; BeamUp(?, 19, 0)
	add	sp, 8
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
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	2, 4	; id, points
	DW	219,112, 270,112, 270,121, 219,121
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's5r7h1',0
	DB	's5r7h2',0
	DB	's5r7h3',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
	DB	'Lt. Stragey',0
N_Quetzecoatl	LABEL	BYTE
	DB	'Quetzecoatl',0
	DB	0
T_FEA7_017	LABEL	BYTE
	DB	'#FEA7\FEA7_017#I am sorry you had to go through this ordeal. It '
	DB	'was not meant for you to die.',0
T_FEA7_022	LABEL	BYTE
	DB	'#FEA7\FEA7_022#I watched as you worked through the problems I se'
	DB	't in your path. you are a valiant, intelligent species.',0
T_FEA7_021	LABEL	BYTE
	DB	'#FEA7\FEA7_021#I was particularly impressed by the sacrifice mad'
	DB	'e by Lt. Stragey. Of course, I gave him back his life. He is now'
	DB	' safely aboard your vessel.',0
T_FEA7_027	LABEL	BYTE
	DB	'#FEA7\FEA7_027#Please sit down. We have much to discuss.',0
T_FEA7_023	LABEL	BYTE
	DB	'#FEA7\FEA7_023#I would have been more impressed had you found a '
	DB	'less violent solution. My children are dear to me. Even so, few '
	DB	'choices remain to me.',0
T_FEA7_005	LABEL	BYTE
	DB	'#FEA7\FEA7_005#I''ve had it up to here with so-called superior be'
	DB	'ings terrorizing my crew because we''re so ''primitive''. Maybe you'
	DB	' should see how primitive you are before you go around testing o'
	DB	'thers.',0
T_FEA7_006	LABEL	BYTE
	DB	'#FEA7\FEA7_006#One thing first. If you''re so peaceful, how come '
	DB	'the Aztecs were so violent and agressive?',0
T_FEA7_010	LABEL	BYTE
	DB	'#FEA7\FEA7_010#Yes, I guess we do. Go on.',0
T_FEA7_020	LABEL	BYTE
	DB	'#FEA7\FEA7_020#I was not aware you had been tested before. My ap'
	DB	'ologies.',0
T_FEA7_019	LABEL	BYTE
	DB	'#FEA7\FEA7_019#I tried to teach them the concept of self-sacrifi'
	DB	'ce. It would appear they did not completely understand my teachi'
	DB	'ngs.',0
T_FEA7_016	LABEL	BYTE
	DB	'#FEA7\FEA7_016#First, I have one question...',0
T_FEA7_029	LABEL	BYTE
	DB	'#FEA7\FEA7_029#You are clearly not the liars I thought you to be'
	DB	'. Were you telling me the truth about my disciples? That they be'
	DB	'came ruthless savages?',0
T_FEA7_007	LABEL	BYTE
	DB	'#FEA7\FEA7_007#The Federation is not in the business of lying, m'
	DB	'ister.',0
T_FEA7_004	LABEL	BYTE
	DB	'#FEA7\FEA7_004#Absolutely. Your best intentions were changed by '
	DB	'the imperfect humans that you left in charge after you departed.'
	DB	' Such is the way of our race, I''m afraid.',0
T_FEA7_012	LABEL	BYTE
	DB	'#FEA7\FEA7_012#You messed up in a big way. Perhaps you should tr'
	DB	'y following the Prime Directive. It changed our lives.',0
T_FEA7_030	LABEL	BYTE
	DB	'#FEA7\FEA7_030#Your harshness is unwarranted, but I sense truth '
	DB	'in this. Perhaps this is what happened to my children on the Kli'
	DB	'ngon world of Hrakkour, which would explain why they are searchi'
	DB	'ng for me. I have clearly abused the power that was given me lon'
	DB	'g ago.',0
T_FEA7_018	LABEL	BYTE
	DB	'#FEA7\FEA7_018#I sense truth in this. Perhaps this is what happe'
	DB	'ned to my children on the Klingon world of Hrakkour, which would'
	DB	' explain why they are searching for me. I have clearly abused th'
	DB	'e power that was given me long ago.',0
T_FEA7_026	LABEL	BYTE
	DB	'#FEA7\FEA7_026#Ours is an intensely curious race, Captain. My br'
	DB	'others and I have raised children on a thousand worlds, loved th'
	DB	'em, watched them grow, only to see them become separated from us'
	DB	' by the passage of time. It is sad and lonely process, one which'
	DB	' I shall not repeat again. I am no longer worthy of my gift.',0
T_FEA7_014	LABEL	BYTE
	DB	'#FEA7\FEA7_014#You show great wisdom, sir. But your statement im'
	DB	'plies that you wish to change your condition.',0
T_FEA7_024	LABEL	BYTE
	DB	'#FEA7\FEA7_024#Indeed. If my mission of peace was overthrown, th'
	DB	'en I am no longer worthy of my power. Tell me, has your species '
	DB	'made progress in the medical arts?',0
T_FEA7_008	LABEL	BYTE
	DB	'#FEA7\FEA7_008#We''re a technologically advanced starfaring race,'
	DB	' what do you think? That we wouldn''t have made progress in medic'
	DB	'ine?',0
T_FEA7_009	LABEL	BYTE
	DB	'#FEA7\FEA7_009#With Dr. McCoy, I sometimes wonder, but yes, I wo'
	DB	'uld say we have made considerable advances.',0
T_FEA7_011	LABEL	BYTE
	DB	'#FEA7\FEA7_011#Yes, why do you ask?',0
T_FEA7_025	LABEL	BYTE
	DB	'#FEA7\FEA7_025#Of course, how foolish of me. Still, there are cu'
	DB	'ltures where medical knowledge is considered a sign of weakness.'
	DB	' Warrior cultures, where nothing matters but physical strength. '
	DB	'Survival of the foolish.',0
T_FEA7_028	LABEL	BYTE
	DB	'#FEA7\FEA7_028#Then I shall ask to make use of your advances.',0
T_FEA7_015	LABEL	BYTE
	DB	'#FEA7\FEA7_015#At the top of my spine is a gland not found in yo'
	DB	'ur species. This is the seat of my power. I wish you to remove i'
	DB	't, thereby making me a mortal.',0
T_FEA7_013	LABEL	BYTE
	DB	'#FEA7\FEA7_013#Jim, I''ll try, but the physiology is completely a'
	DB	'lien...',0
T_FEA7_003	LABEL	BYTE
	DB	'#FEA7\FEA7_003#You''ve got to do it, Bones! If the Klingons reali'
	DB	'ze he''s no longer a threat to them, perhaps we can avoid a war!',0
T_FEA7_002	LABEL	BYTE
	DB	'#FEA7\FEA7_002#Scotty, four to beam up.',0
T_FEA7_001	LABEL	BYTE
	DB	'#FEA7\FEA7_001#Scotty, five to beam up.',0
	DB	'Party teleports back to the Enterprise.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0
KirkOnTests	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_FEA7_005, OFFSET T_FEA7_006, OFFSET T_FEA7_010, 0	; speaker, choices, 0
KirkOnAztecs	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_FEA7_007, OFFSET T_FEA7_004, OFFSET T_FEA7_012, 0	; speaker, choices, 0
KirkOnProgress	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_FEA7_008, OFFSET T_FEA7_009, OFFSET T_FEA7_011, 0	; speaker, choices, 0

RDF	ENDS
	END
