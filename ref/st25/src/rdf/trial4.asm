; TRIAL4.RDF - "The Feathered Serpent", back in the court after the Test
; of Life (from rooms 1-3). Vlict, furious, admits the trial was a sham;
; Quetzecoatl gives himself up to spare the party, and the mission ends
; with ending 2 (Quetzecoatl lost).
;
; Actors: 8 Vlict, 9 the guard, 10 (0Ah) Quetzecoatl.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The conversation at 00CA is built at run time.

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
	DW	160,140, 150,140, 170,150, 160,150	; beaming in
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
	DB	'Ensign Bennie',0
	DB	'Lt. Uhura',0
N_Vlict	LABEL	BYTE
	DB	'Vlict',0
N_Quetzecoatl	LABEL	BYTE
	DB	'Quetzecoatl',0
rdf_objects	LABEL	BYTE
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	't0b1',0
	DB	't0b2',0
	DB	't0b3',0
	DB	't0b4',0

rdf_scripts:
rdf_bans_end:
; The room starts: Vlict, the guard, Quetzecoatl.
H_0170:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0208
StartRoom:
	jmp	SHORT L0181

N_TRI4LOOP	LABEL	BYTE
	DB	'TRI4LOOP',0
L0181:
	push	OFFSET N_TRI4LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("TRI4LOOP")
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	jmp	SHORT L019E

N_vlict1	LABEL	BYTE
	DB	'vlict1',0
L019E:
	push	0
	push	48h
	push	9Fh
	push	OFFSET N_vlict1
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "vlict1", 159, 72, 0)
	add	sp, 0Ch
	jmp	SHORT L01BD

N_kgstnd	LABEL	BYTE
	DB	'kgstnd',0
L01BD:
	push	0
	push	6Ah
	push	0DCh
	push	OFFSET N_kgstnd
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "kgstnd", 220, 106, 0)
	add	sp, 0Ch
	jmp	SHORT L01DC

N_qstand	LABEL	BYTE
	DB	'qstand',0
L01DC:
	push	0
	push	0AAh
	push	10Eh
	push	OFFSET N_qstand
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "qstand", 270, 170, 0)
	add	sp, 0Ch
	mov	ax, -1
	push	ax
	mov	ax, 20h
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(32, -1)
	add	sp, 6
	retf

; Tick 60: the confrontation, a series of conversations built at run
; time; it ends with Quetzecoatl's sacrifice and BeamUp (ending 2).
H_0208:
	SCRIPT	MSG_TICK, 3Ch, 0, 0, rdf_scripts_end
VlictRages:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_061
	call	Say
	JMPN	L02A2

T_TRI4_061	LABEL	BYTE
	DB	'#TRI4\TRI4_061#How dare you! The test was supposed to take place'
	DB	' without interference from your ship. You have shown all lack of'
	DB	' honor.',0
L02A2:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L02F5

T_TRI4_022	LABEL	BYTE
	DB	'#TRI4\TRI4_022#Honor? Give me a break, Vlict! You were trying to'
	DB	' kill us!',0
L02F5:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI4_022
	mov	word ptr cs:choice_jumps, OFFSET L044D
	JMPN	L0389

T_TRI4_039	LABEL	BYTE
	DB	'#TRI4\TRI4_039#I believe that the use of guile, to do what an en'
	DB	'emy does not expect, is considered very honorable by the Klingon'
	DB	's.',0
L0389:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI4_039
	mov	word ptr cs:choice_jumps+2, OFFSET L0A84
	JMPN	L0422

T_TRI4_032	LABEL	BYTE
	DB	'#TRI4\TRI4_032#You didn''t say I wasn''t allowed to use my ship''s '
	DB	'computer. If you didn''t explain the rules clearly, whose fault i'
	DB	's that?',0
L0422:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI4_032
	mov	word ptr cs:choice_jumps+4, OFFSET L1327
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L044D:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_064
	call	Say
	jmp	SHORT L04B2

T_TRI4_064	LABEL	BYTE
	DB	'#TRI4\TRI4_064#If I had been trying to murder you, Kirk, you wou'
	DB	'ld have surely died.',0
L04B2:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L04EB

T_TRI4_033	LABEL	BYTE
	DB	'#TRI4\TRI4_033#You don''t lie very well, do you?',0
L04EB:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI4_033
	mov	word ptr cs:choice_jumps, OFFSET L05A2
	jmp	SHORT L0539

T_TRI4_009	LABEL	BYTE
	DB	'#TRI4\TRI4_009#Maybe you aren''t as good as you think you are.',0
L0539:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI4_009
	mov	word ptr cs:choice_jumps+2, OFFSET L05A2
	jmp	SHORT L0577

T_TRI4_002	LABEL	BYTE
	DB	'#TRI4\TRI4_002#Do Klingons believe in ghosts?',0
L0577:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI4_002
	mov	word ptr cs:choice_jumps+4, OFFSET L05A2
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L05A2:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_062
	call	Say
	jmp	SHORT L0619

T_TRI4_062	LABEL	BYTE
	DB	'#TRI4\TRI4_062#I am tired of this posturing, Kirk. You know what'
	DB	' the verdict is. Go back to your ship.',0
L0619:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI4_014
	call	Say
	jmp	SHORT L0663

T_TRI4_014	LABEL	BYTE
	DB	'#TRI4\TRI4_014#Then you admit this trial is a sham! A charade!',0
L0663:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_066
	call	Say
	JMPN	L072B

T_TRI4_066	LABEL	BYTE
	DB	'#TRI4\TRI4_066#Of course it was, you fool! Did you honestly expe'
	DB	'ct us to act with kindness to traitors? You fought a battle that'
	DB	' you could not win, and fought it very well. Go home, Kirk.',0
L072B:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI4_043
	call	Say
	JMPN	L07BF

T_TRI4_043	LABEL	BYTE
	DB	'#TRI4\TRI4_043#Captain, I taught others self-sacrifice. Now I mu'
	DB	'st practice what I preached. It is the only way to atone for my '
	DB	'crimes.',0
L07BF:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L081E

T_TRI4_029	LABEL	BYTE
	DB	'#TRI4\TRI4_029#Then you have my deepest respect. I am sorry I ca'
	DB	'nnot do more for you.',0
L081E:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI4_029
	mov	word ptr cs:choice_jumps, OFFSET L21AF
	jmp	SHORT L0898

T_TRI4_020	LABEL	BYTE
	DB	'#TRI4\TRI4_020#Farewell my friend. Vlict, if you respect honor, '
	DB	'you will make it a quick, painless death.',0
L0898:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI4_020
	mov	word ptr cs:choice_jumps+2, OFFSET L0959
	JMPN	L092E

T_TRI4_030	LABEL	BYTE
	DB	'#TRI4\TRI4_030#There''s a time to fight for what you believe, and'
	DB	' a time to die for it. I hope you chose the right time, Quetzeco'
	DB	'atl.',0
L092E:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI4_030
	mov	word ptr cs:choice_jumps+4, OFFSET L09AE
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L0959:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_063
	call	Say
	jmp	SHORT L09AB

T_TRI4_063	LABEL	BYTE
	DB	'#TRI4\TRI4_063#I shall agree to it, Captain. Until we meet again'
	DB	'.',0
L09AB:
	JMPN	L21AF

L09AE:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI4_040
	call	Say
	JMPN	L0A81

T_TRI4_040	LABEL	BYTE
	DB	'#TRI4\TRI4_040#As do I. My only regret is that I did not get to '
	DB	'know you better. If only a part of what you are is because you l'
	DB	'earned from the mistakes of my acolytes, my work was not in vain'
	DB	'.',0
L0A81:
	JMPN	L21AF

L0A84:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_060
	call	Say
	JMPN	L0B5C

T_TRI4_060	LABEL	BYTE
	DB	'#TRI4\TRI4_060#How dare you lecture me on points of honor! I, th'
	DB	'e most decorated warrior in the entire empire! I, who took the d'
	DB	'ishonored trash of my homeworld and destroyed it with a fist of '
	DB	'steel!',0
L0B5C:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI4_013
	call	Say
	jmp	SHORT L0BD9

T_TRI4_013	LABEL	BYTE
	DB	'#TRI4\TRI4_013#Then you admit that it was you, and not Quetzecoa'
	DB	'tl who was responsible for the death of Hrakkour.',0
L0BD9:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_072
	call	Say
	jmp	SHORT L0C30

T_TRI4_072	LABEL	BYTE
	DB	'#TRI4\TRI4_072#Those who lose honor lose life, Kirk! It is the K'
	DB	'lingon way!',0
L0C30:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI4_015
	call	Say
	jmp	SHORT L0CBA

T_TRI4_015	LABEL	BYTE
	DB	'#TRI4\TRI4_015#Then you will not object to presenting the orders'
	DB	' from the Klingon Council authorizing mass murder on Hrakkour.',0
L0CBA:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_071
	call	Say
	jmp	SHORT L0D13

T_TRI4_071	LABEL	BYTE
	DB	'#TRI4\TRI4_071#The trial is over! He is guilty. Durn, carry out '
	DB	'the sentence!',0
L0D13:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI4_005
	call	Say
	jmp	SHORT L0D48

T_TRI4_005	LABEL	BYTE
	DB	'#TRI4\TRI4_005#I won''t let you. I chal...',0
L0D48:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI4_052
	call	Say
	JMPN	L0E0E

T_TRI4_052	LABEL	BYTE
	DB	'#TRI4\TRI4_052#No captain. Let there be an end to this violence.'
	DB	' I will not allow any more blood to be shed, save my own. I taug'
	DB	'ht the doctrine of self-sacrifice, and I shall die of it.',0
L0E0E:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI4_041
	call	Say
	jmp	SHORT L0E7B

T_TRI4_041	LABEL	BYTE
	DB	'#TRI4\TRI4_041#But before I die, I believe that Klingon law allo'
	DB	'ws me to make a public statement.',0
L0E7B:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI4_051
	call	Say
	JMPN	L0F0F

T_TRI4_051	LABEL	BYTE
	DB	'#TRI4\TRI4_051#Intelligent beings are not meant to be caged, eit'
	DB	'her by tyranny, or barbarism. Those who try doom themselves to f'
	DB	'ailure.',0
L0F0F:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI4_053
	call	Say
	JMPN	L0FE1

T_TRI4_053	LABEL	BYTE
	DB	'#TRI4\TRI4_053#Once a culture has tasted peace, it will not desi'
	DB	're anything else, because peace is better than war, love is bett'
	DB	'er than hate, and creation is better than destruction. This is T'
	DB	'ruth.',0
L0FE1:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI4_050
	call	Say
	JMPN	L108E

T_TRI4_050	LABEL	BYTE
	DB	'#TRI4\TRI4_050#I, who was once immortal, know that truth is the '
	DB	'only true immortal. You can kill people, cultures, even gods, bu'
	DB	't the truth will always survive.',0
L108E:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_070
	call	Say
	jmp	SHORT L1116

T_TRI4_070	LABEL	BYTE
	DB	'#TRI4\TRI4_070#The death ceremony shall take place aboard the K'''
	DB	'lirta. I trust you are satisfied that justice has been done.',0
L1116:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	JMPN	L11B6

T_TRI4_019	LABEL	BYTE
	DB	'#TRI4\TRI4_019#Did you listen to anything he said? One day, in s'
	DB	'pite of people like you, the Klingons will know peace. I hope I '
	DB	'live to see that day.',0
L11B6:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI4_019
	mov	word ptr cs:choice_jumps, OFFSET L21AF
	jmp	SHORT L1236

T_TRI4_025	LABEL	BYTE
	DB	'#TRI4\TRI4_025#I do not know if you are a praying man, Vlict. If'
	DB	' I were you, I would not want to meet me again.',0
L1236:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI4_025
	mov	word ptr cs:choice_jumps+2, OFFSET L1289
	jmp	SHORT L125E

T_TRI4_008	LABEL	BYTE
	DB	'#TRI4\TRI4_008#Justice?',0
L125E:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI4_008
	mov	word ptr cs:choice_jumps+4, OFFSET L21AF
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L1289:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_069
	call	Say
	jmp	SHORT L12EE

T_TRI4_069	LABEL	BYTE
	DB	'#TRI4\TRI4_069#Such threats, Kirk, will only increase my longing'
	DB	' for the experience.',0
L12EE:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI4_004
	call	Say
	jmp	SHORT L1324

T_TRI4_004	LABEL	BYTE
	DB	'#TRI4\TRI4_004#I don''t really give a damn.',0
L1324:
	JMPN	L21AF

L1327:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_058
	call	Say
	jmp	SHORT L1379

T_TRI4_058	LABEL	BYTE
	DB	'#TRI4\TRI4_058#Do you think that you can make a fool of me, Kirk'
	DB	'!',0
L1379:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L13C5

T_TRI4_027	LABEL	BYTE
	DB	'#TRI4\TRI4_027#Isn''t it time that we stopped playing games, Vlic'
	DB	't?',0
L13C5:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI4_027
	mov	word ptr cs:choice_jumps, OFFSET L14A5
	jmp	SHORT L142A

T_TRI4_034	LABEL	BYTE
	DB	'#TRI4\TRI4_034#You lost, Vlict. I beat your test. Release Quetze'
	DB	'coatl and let us go!',0
L142A:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI4_034
	mov	word ptr cs:choice_jumps+2, OFFSET L189B
	jmp	SHORT L147A

T_TRI4_018	LABEL	BYTE
	DB	'#TRI4\TRI4_018#As we say on Earth, Vlict, nature beat me to it.',0
L147A:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI4_018
	mov	word ptr cs:choice_jumps+4, OFFSET L1ABA
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L14A5:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_075
	call	Say
	jmp	SHORT L1505

T_TRI4_075	LABEL	BYTE
	DB	'#TRI4\TRI4_075#Very well. The trial is over. K''etz''koatl is sent'
	DB	'enced to death.',0
L1505:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI4_017
	call	Say
	jmp	SHORT L1525

T_TRI4_017	LABEL	BYTE
	DB	'#TRI4\TRI4_017#What!',0
L1525:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI4_042
	call	Say
	JMPN	L15C0

T_TRI4_042	LABEL	BYTE
	DB	'#TRI4\TRI4_042#Captain, I do not see any successful resolution t'
	DB	'o this, except with my death. Dying to prevent conflict would gi'
	DB	've it meaning.',0
L15C0:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_054
	call	Say
	jmp	SHORT L1604

T_TRI4_054	LABEL	BYTE
	DB	'#TRI4\TRI4_054#A coward''s attitude. He shames this soil.',0
L1604:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L162B

T_TRI4_028	LABEL	BYTE
	DB	'#TRI4\TRI4_028#Shut up Vlict.',0
L162B:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI4_028
	mov	word ptr cs:choice_jumps, OFFSET L171F
	jmp	SHORT L168E

T_TRI4_021	LABEL	BYTE
	DB	'#TRI4\TRI4_021#He knows more about courage than you or your Empi'
	DB	're will ever know.',0
L168E:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI4_021
	mov	word ptr cs:choice_jumps+2, OFFSET L171F
	jmp	SHORT L16F4

T_TRI4_031	LABEL	BYTE
	DB	'#TRI4\TRI4_031#Vlict is right, Quetzecoatl. This is suicide. It '
	DB	'is a cowardly action.',0
L16F4:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI4_031
	mov	word ptr cs:choice_jumps+4, OFFSET L17A9
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L171F:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_068
	call	Say
	jmp	SHORT L176C

T_TRI4_068	LABEL	BYTE
	DB	'#TRI4\TRI4_068#Return to your ship, Kirk. The trial is over.',0
L176C:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI4_036
	call	Say
	jmp	SHORT L17A6

T_TRI4_036	LABEL	BYTE
	DB	'#TRI4\TRI4_036#Jim! You can''t let him do this!',0
L17A6:
	JMPN	L21AF

L17A9:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_056
	call	Say
	jmp	SHORT L1834

T_TRI4_056	LABEL	BYTE
	DB	'#TRI4\TRI4_056#As long as the Federation continues to foster suc'
	DB	'h weaklings, the triumph of the Klingon Empire is assured.',0
L1834:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI4_001
	call	Say
	jmp	SHORT L1898

T_TRI4_001	LABEL	BYTE
	DB	'#TRI4\TRI4_001#Admiral, one day the weaklings are going to surpr'
	DB	'ise the Hell out of you.',0
L1898:
	JMPN	L21AF

L189B:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_076
	call	Say
	jmp	SHORT L1901

T_TRI4_076	LABEL	BYTE
	DB	'#TRI4\TRI4_076#You humans have an excellent imagination, but a p'
	DB	'oor grasp of reality.',0
L1901:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI4_037
	call	Say
	jmp	SHORT L1954

T_TRI4_037	LABEL	BYTE
	DB	'#TRI4\TRI4_037#You never had any intention of letting Quetzecoat'
	DB	'l live!',0
L1954:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_073
	call	Say
	jmp	SHORT L19CB

T_TRI4_073	LABEL	BYTE
	DB	'#TRI4\TRI4_073#To allow a traitor to live would dishonor me. I w'
	DB	'ill not live with such a stain on my honor.',0
L19CB:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI4_011
	call	Say
	JMPN	L1A7B

T_TRI4_011	LABEL	BYTE
	DB	'#TRI4\TRI4_011#Nothing you have done has been honorable, Vlict! '
	DB	'One day, everyone in the Klingon empire will know it too. Perhap'
	DB	's one day even you will realize it.',0
L1A7B:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_059
	call	Say
	jmp	SHORT L1AB7

T_TRI4_059	LABEL	BYTE
	DB	'#TRI4\TRI4_059#Go back to your Federation, Kirk!',0
L1AB7:
	JMPN	L21AF

L1ABA:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_065
	call	Say
	JMPN	L1B55

T_TRI4_065	LABEL	BYTE
	DB	'#TRI4\TRI4_065#If I was not bound by the Organian treaty, you wo'
	DB	'uld be a dead man now, Kirk! Perhaps one day, I shall not be bou'
	DB	'nd by it.',0
L1B55:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI4_016
	call	Say
	jmp	SHORT L1BBA

T_TRI4_016	LABEL	BYTE
	DB	'#TRI4\TRI4_016#We beat you, Vlict. Unless you free Quetzecoatl, '
	DB	'you will lose your honor!',0
L1BBA:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_074
	call	Say
	jmp	SHORT L1C1A

T_TRI4_074	LABEL	BYTE
	DB	'#TRI4\TRI4_074#To free a traitor is to lose all honor, Kirk! He '
	DB	'is sentenced to die!',0
L1C1A:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L1C88

T_TRI4_026	LABEL	BYTE
	DB	'#TRI4\TRI4_026#If you kill him, the Empire will learn that you b'
	DB	'etrayed them by destroying Hrakkour.',0
L1C88:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI4_026
	mov	word ptr cs:choice_jumps, OFFSET L1D75
	jmp	SHORT L1CE7

T_TRI4_024	LABEL	BYTE
	DB	'#TRI4\TRI4_024#How can you call him a traitor without giving him'
	DB	' a fair trail!',0
L1CE7:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI4_024
	mov	word ptr cs:choice_jumps+2, OFFSET L1EF7
	jmp	SHORT L1D4A

T_TRI4_023	LABEL	BYTE
	DB	'#TRI4\TRI4_023#How can a liar like you even say the word "honor"'
	DB	' without blushing?',0
L1D4A:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI4_023
	mov	word ptr cs:choice_jumps+4, OFFSET L208B
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L1D75:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_057
	call	Say
	jmp	SHORT L1E01

T_TRI4_057	LABEL	BYTE
	DB	'#TRI4\TRI4_057#Do not threaten me, Kirk! If you expect the Empir'
	DB	'e will believe you instead of me, you are greatly mistaken.',0
L1E01:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI4_038
	call	Say
	jmp	SHORT L1E33

T_TRI4_038	LABEL	BYTE
	DB	'#TRI4\TRI4_038#He is correct, Captain.',0
L1E33:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI4_044
	call	Say
	jmp	SHORT L1E91

T_TRI4_044	LABEL	BYTE
	DB	'#TRI4\TRI4_044#Captain, I thank you for your efforts on my behal'
	DB	'f, but it is over.',0
L1E91:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI4_006
	call	Say
	jmp	SHORT L1ECA

T_TRI4_006	LABEL	BYTE
	DB	'#TRI4\TRI4_006#I''m sorry we couldn''t do more.',0
L1ECA:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI4_048
	call	Say
	jmp	SHORT L1EF4

T_TRI4_048	LABEL	BYTE
	DB	'#TRI4\TRI4_048#I know Captain.',0
L1EF4:
	JMPN	L21AF

L1EF7:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_055
	call	Say
	jmp	SHORT L1F82

T_TRI4_055	LABEL	BYTE
	DB	'#TRI4\TRI4_055#As judge, I determine what is fair and what is un'
	DB	'fair, Kirk! The trial is at an end. The verdict is guilty.',0
L1F82:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI4_045
	call	Say
	jmp	SHORT L1FE0

T_TRI4_045	LABEL	BYTE
	DB	'#TRI4\TRI4_045#Captain, I thank you for your efforts on my behal'
	DB	'f, but it is over.',0
L1FE0:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI4_003
	call	Say
	jmp	SHORT L201D

T_TRI4_003	LABEL	BYTE
	DB	'#TRI4\TRI4_003#I didn''t want it to end like this.',0
L201D:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI4_047
	call	Say
	jmp	SHORT L2061

T_TRI4_047	LABEL	BYTE
	DB	'#TRI4\TRI4_047#I know Captain. But it''s better this way.',0
L2061:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI4_010
	call	Say
	jmp	SHORT L2088

T_TRI4_010	LABEL	BYTE
	DB	'#TRI4\TRI4_010#No it isn''t.',0
L2088:
	JMPN	L21AF

L208B:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET T_TRI4_067
	call	Say
	jmp	SHORT L20ED

T_TRI4_067	LABEL	BYTE
	DB	'#TRI4\TRI4_067#Perhaps because Klingons do not blush. You''ve los'
	DB	't, Kirk. Go home.',0
L20ED:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI4_046
	call	Say
	jmp	SHORT L214B

T_TRI4_046	LABEL	BYTE
	DB	'#TRI4\TRI4_046#Captain, I thank you for your efforts on my behal'
	DB	'f, but it is over.',0
L214B:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI4_007
	call	Say
	jmp	SHORT L2184

T_TRI4_007	LABEL	BYTE
	DB	'#TRI4\TRI4_007#I''m sorry we couldn''t do more.',0
L2184:
	mov	ax, OFFSET N_Quetzecoatl
	mov	bx, OFFSET T_TRI4_049
	call	Say
	jmp	SHORT L21AF

T_TRI4_049	LABEL	BYTE
	DB	'#TRI4\TRI4_049#I know, Captain.',0
L21AF:
	mov	si, word ptr cs:rdf_state
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI4_012
	call	Say
	jmp	SHORT L21E2

T_TRI4_012	LABEL	BYTE
	DB	'#TRI4\TRI4_012#Scotty, beam us up.',0
L21E2:
	mov	word ptr [si+ending], 2
	push	2
	push	word ptr [si+max_score]
	push	word ptr [si+score]
	push	RC_BEAMUP
	SERVICE		; BeamUp(?, ?, 2)
	add	sp, 8
	retf

rdf_scripts_end	LABEL	BYTE

RDF	ENDS
	END
