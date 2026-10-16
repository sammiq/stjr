; TRIAL9.RDF - "The Feathered Serpent", the end: back on the Enterprise,
; how the mission ended (ending, set in rooms 0-5) is told through
; messages from the K'lirta and the Captain's log.
;
; Unused: nothing enters room 9 (the trial rooms only go to rooms 1, 2, 4
; and 5, and StartAway always starts in room 0), there is no TRIAL9.BMP or
; .PRI for LoadRoom to load, and its strings have no voice tags. The game
; plays the ending on the bridge instead: the rooms pass the ending as
; RC_BEAMUP's outcome, and seg034 picks TrialKenka, TrialSpock, TrialSulu
; or TrialKallarax from it, with text from TRIAL.TXT. The rooms' writes to
; the ending variable are left over from this room. The floppy version
; has no TRIAL9.RDF at all.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The conversation at 00CA is built at run time.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
ending	EQU	RS_VARS+36h	; word: how it ended, for room 9: 0 Kirk let the trial run, 1 he beamed back mid-trial, 2 Quetzecoatl was lost, 3 the Klingons leave, 4 Vlict was executed

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	0
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
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
N_Sulu	LABEL	BYTE
	DB	'Sulu',0
N_Vlict	LABEL	BYTE
	DB	'Vlict',0
N_Kallarax	LABEL	BYTE
	DB	'Kallarax',0

rdf_scripts:
rdf_objects:
rdf_objects_end:
rdf_exits:
rdf_exits_end:
rdf_regions:
rdf_regions_end:
rdf_bans:
rdf_bans_end:
; Tick 30: the epilogue for each ending: 0 "Scenario completed" (Kirk was
; dismissed from the court); 1 Vlict's taunts after Kirk left mid-trial;
; 2 Quetzecoatl lost; 3 the Klingons leave orbit; 4 the Klingons demand
; Vlict, tried and executed by an alien computer.
H_015E:
	SCRIPT	MSG_TICK, 1Eh, 0, 0, rdf_scripts_end
Epilogue:
	cmp	word ptr [si+ending], 0
	jne	L016C
	jmp	SHORT L0190

L016C:
	cmp	word ptr [si+ending], 1
	jne	L0174
	jmp	SHORT L01B7

L0174:
	cmp	word ptr [si+ending], 2
	jne	L017D
	JMPN	L044C

L017D:
	cmp	word ptr [si+ending], 3
	jne	L0186
	JMPN	L0704

L0186:
	cmp	word ptr [si+ending], 4
	jne	L018F
	JMPN	L0829

L018F:
	retf

L0190:
	mov	ax, 0
	mov	bx, OFFSET S_019B
	call	Say
	jmp	SHORT L01B5

S_019B	LABEL	BYTE
	DB	'***Scenario completed.***',0
L01B5:
	retf

	DB	0CBh
L01B7:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET S_01C2
	call	Say
	jmp	SHORT L01EF

S_01C2	LABEL	BYTE
	DB	'Captain, message coming in from the K''lirta.',0
L01EF:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET N_Onscreen
	call	Say
	jmp	SHORT L0204

N_Onscreen	LABEL	BYTE
	DB	'Onscreen.',0
L0204:
	jmp	SHORT L020D

N_p1talk	LABEL	BYTE
	DB	'p1talk',0
L020D:
	push	0
	push	0
	push	0
	push	OFFSET N_p1talk
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p1talk", 0, 0, 0)
	add	sp, 0Ch
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET S_022E
	call	Say
	JMPN	L02CF

S_022E	LABEL	BYTE
	DB	'My dear Captain Kirk, you will be pleased to know that your act '
	DB	'of cowardice in returning to your ship in the middle of the tria'
	DB	'l has found a suitable reward...',0
L02CF:
	mov	ax, OFFSET N_Vlict
	mov	bx, OFFSET S_02DB
	call	Say
	JMPN	L0383

S_02DB	LABEL	BYTE
	DB	'The traitor has been executed, and this unfortunate business has'
	DB	' come to an end. I humbly invite you to leave Klingon space befo'
	DB	're I use your ship for target practise!',0
L0383:
	mov	ax, 8
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(8)
	add	sp, 4
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET S_039E
	call	Say
	jmp	SHORT L03BC

S_039E	LABEL	BYTE
	DB	'All channels closed, Captain.',0
L03BC:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET S_03C7
	call	Say
	jmp	SHORT L040E

S_03C7	LABEL	BYTE
	DB	'Let''s get out of here. Warp Three, Mr. Sulu, back to Federation '
	DB	'Space.',0
L040E:
	mov	ax, OFFSET N_Sulu
	mov	bx, OFFSET N_Aye_sir
	call	Say
	jmp	SHORT L0425

N_Aye_sir	LABEL	BYTE
	DB	'Aye sir....',0
L0425:
	mov	ax, 0
	mov	bx, OFFSET S_0430
	call	Say
	jmp	SHORT L044A

S_0430	LABEL	BYTE
	DB	'***Scenario completed.***',0
L044A:
	retf

	DB	0CBh
L044C:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET S_0457
	call	Say
	jmp	SHORT L04CC

S_0457	LABEL	BYTE
	DB	'Captain''s Log, Stardate ?????.?? We have returned to Federation '
	DB	'Space, having tried and failed to save a new friend.',0
L04CC:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_04D7
	call	Say
	jmp	SHORT L051A

S_04D7	LABEL	BYTE
	DB	'Quezecoatl was a remarkable creature, Captain. It is a great los'
	DB	's.',0
L051A:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET S_0525
	call	Say
	jmp	SHORT L0546

S_0525	LABEL	BYTE
	DB	'He died for what he believed in.',0
L0546:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_0551
	call	Say
	jmp	SHORT L05CC

S_0551	LABEL	BYTE
	DB	'Yet so did many men who were judged by history to be evil. Dicta'
	DB	'tors, assassins. Self-sacrifice in itself is not a virtue.',0
L05CC:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET S_05D7
	call	Say
	jmp	SHORT L05F8

S_05D7	LABEL	BYTE
	DB	'It''s just another form of dying.',0
L05F8:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET S_0604
	call	Say
	JMPN	L06DE

S_0604	LABEL	BYTE
	DB	'Still, I cannot find it in my heart to condemn him. He had a gre'
	DB	'at dream of peace, and it''s been left to others to fufill it. Le'
	DB	't''s get started. Ahead, Warp Factor Two to (Initial Destination '
	DB	'in Scenario #7) Mr. Sulu.',0
L06DE:
	mov	ax, 0
	mov	bx, OFFSET S_06E9
	call	Say
	jmp	SHORT L0703

S_06E9	LABEL	BYTE
	DB	'***Scenario completed.***',0
L0703:
	retf

L0704:
	mov	ax, OFFSET N_Sulu
	mov	bx, OFFSET S_070F
	call	Say
	jmp	SHORT L072B

S_070F	LABEL	BYTE
	DB	'Klingon ship leaving orbit.',0
L072B:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_0736
	call	Say
	jmp	SHORT L076A

S_0736	LABEL	BYTE
	DB	'It would appear everything worked out for the best.',0
L076A:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET S_0775
	call	Say
	jmp	SHORT L07B8

S_0775	LABEL	BYTE
	DB	'Except for the people of Hrakkour, Mr. Spock. Except for the dea'
	DB	'd.',0
L07B8:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET S_07C3
	call	Say
	jmp	SHORT L0803

S_07C3	LABEL	BYTE
	DB	'Set course for (NEXT DESTINATION), Mr. Sulu. Warp Factor Three.',0
L0803:
	mov	ax, 0
	mov	bx, OFFSET S_080E
	call	Say
	jmp	SHORT L0828

S_080E	LABEL	BYTE
	DB	'***Scenario completed.***',0
L0828:
	retf

L0829:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET S_0834
	call	Say
	jmp	SHORT L084D

S_0834	LABEL	BYTE
	DB	'Klingon ship hailing us!',0
L084D:
	mov	ax, OFFSET N_Kallarax
	mov	bx, OFFSET S_0858
	call	Say
	jmp	SHORT L088B

S_0858	LABEL	BYTE
	DB	'Where is Admiral Vlict! What have you done to him!',0
L088B:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L08FE

S_0894	LABEL	BYTE
	DB	'Vlict is dead. He was tried and executed by an alien computer. I'
	DB	' have a tricorder recording of the event.',0
L08FE:
	mov	word ptr cs:talk_buf+2, OFFSET S_0894
	mov	word ptr cs:choice_jumps, OFFSET L0A17
	jmp	SHORT L0978

S_090E	LABEL	BYTE
	DB	'Vlict is dead. He fell into his own trap and died in dishonor. I'
	DB	' have a tricorder recording of the event.',0
L0978:
	mov	word ptr cs:talk_buf+4, OFFSET S_090E
	mov	word ptr cs:choice_jumps+2, OFFSET L0A17
	jmp	SHORT L09EC

S_0988	LABEL	BYTE
	DB	'Vlict is dead. We''re having a party to celebrate on our recreati'
	DB	'on deck, you want to come Kallarax?',0
L09EC:
	mov	word ptr cs:talk_buf+6, OFFSET S_0988
	mov	word ptr cs:choice_jumps+4, OFFSET L0BA1
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L0A17:
	mov	ax, OFFSET N_Kallarax
	mov	bx, OFFSET S_0A23
	call	Say
	JMPN	L0AB8

S_0A23	LABEL	BYTE
	DB	'I will analyze this evidence. If it is false, then relations bet'
	DB	'ween the Federation and the Klingon Empire will get worse! Now l'
	DB	'eave Klingon space! ',0
L0AB8:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET S_0AC3
	call	Say
	jmp	SHORT L0B16

S_0AC3	LABEL	BYTE
	DB	'Quetzecoatl is safely aboard Captain, and wishes to be returned '
	DB	'to his home world.',0
L0B16:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET S_0B21
	call	Say
	jmp	SHORT L0B89

S_0B21	LABEL	BYTE
	DB	'I think we can squeeze this into our busy schedule. Set course f'
	DB	'or Zamphor, Mr. Sulu. Warp Factor Six. ',0
L0B89:
	mov	ax, OFFSET N_Sulu
	mov	bx, OFFSET N_Aye_Captain
	call	Say
	jmp	SHORT L0BA1

N_Aye_Captain	LABEL	BYTE
	DB	'Aye Captain.',0
L0BA1:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET S_0BAC
	call	Say
	jmp	SHORT L0BCE

S_0BAC	LABEL	BYTE
	DB	'***big space battle goes here.***',0
L0BCE:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET S_0BD9
	call	Say
	jmp	SHORT L0C24

S_0BD9	LABEL	BYTE
	DB	'Well, that''s over with. Set course for Zamphor, Mr. Sulu. Warp F'
	DB	'actor Six.',0
L0C24:
	mov	ax, 0
	mov	bx, OFFSET S_0C2F
	call	Say
	jmp	SHORT L0C49

S_0C2F	LABEL	BYTE
	DB	'***Scenario completed.***',0
L0C49:
	retf

rdf_scripts_end	LABEL	BYTE

RDF	ENDS
	END
