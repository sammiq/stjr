; LOVE5.RDF - "Love's Labor Jeopardized", Dr. Carol Marcus' quarters
; and lab, home of the Cradle. The Romulans hold Marcus and her assistant
; Cheever here, tied up; their commander, Preax, lies sick with the virus.
; Kirk frees the hostages, McCoy cures Preax (and Spock, if not yet), and
; Kirk and Preax part as worthy opponents: the end of the mission.
;
; Actors: 8 the Cradle's light, 9 Preax, 10 (0Ah) Marcus, 11 (0Bh)
; Cheever.
; Objects: 9 Preax, 0Ah Marcus, 0Bh Cheever, 20h the Cradle, 21h its
; equipment. Exit 1: the crew quarters (room 4). Timer 4: leaving.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The communicator's four cases (CallEnterprise) all play the same
;   placeholder lines, recorded for other missions.
; - Two scripts answer phasers on Preax; the second can never run.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
have_research	EQU	RS_VARS+1	; McCoy has Dr. Marcus' research on the virus (room 0)
romulans_out	EQU	RS_VARS+2	; the Romulan laughing gas has put the Romulans out (room 3)
n2o_released	EQU	RS_VARS+3	; laughing gas: the crew laugh (timer 0)
rlg_released	EQU	RS_VARS+4	; Romulan laughing gas: Spock laughs (timer 1)
virus_struck	EQU	RS_VARS+18h	; the virus has floored Spock, and the Romulans below
freed_hostages	EQU	RS_VARS+19h
preax_cured	EQU	RS_VARS+1Ah
preax_talked	EQU	RS_VARS+1Bh	; Kirk and Preax have parted as worthy opponents
virus	EQU	RS_VARS+1Ch	; Spock's infection: 3Ch he collapses, 64h he dies
spock_cured	EQU	RS_VARS+1Dh
called_ship	EQU	RS_VARS+1Eh	; Kirk has called the Enterprise
called_ship_cured	EQU	RS_VARS+1Fh	; the same, after the cure
made_cure	EQU	RS_VARS+26h	; the cure has been synthesized (room 2)
watered_preax	EQU	RS_VARS+27h	; the point for the water
score	EQU	RS_VARS+29h	; word: the mission's score

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0A9h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	8Eh
rdf_scale_min	LABEL	BYTE
	DW	0DCh	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, 4, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	0,0, 0,0	; entrance 0, crew 0
	DW	0,0, 0,0	; entrance 0, crew 1
	DW	0,0, 0,0	; entrance 0, crew 2
	DW	0,0, 0,0	; entrance 0, crew 3
	DW	139,199, 92,187	; entrance 1, crew 0
	DW	139,199, 137,185	; entrance 1, crew 1
	DW	139,199, 211,184	; entrance 1, crew 2
	DW	139,199, 233,190	; entrance 1, crew 3
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
watered	LABEL	BYTE	; Preax has had water this visit
	DB	0
gathered	LABEL	BYTE	; crew members in place to leave: 3 ends the mission
	DB	0
laugher	LABEL	BYTE	; word: the name of who giggles
	DB	0, 0
roll	LABEL	BYTE	; word: a random number
	DB	0, 0
N_s3r6c1	LABEL	BYTE
	DB	's3r6c1',0
N_s3r6r1	LABEL	BYTE
	DB	's3r6r1',0
N_s3r6r2	LABEL	BYTE
	DB	's3r6r2',0
N_s3r6r3	LABEL	BYTE
	DB	's3r6r3',0
N_marcus	LABEL	BYTE
	DB	'marcus',0
N_marcus2	LABEL	BYTE
	DB	'marcus2',0
N_marcusst	LABEL	BYTE
	DB	'marcusst',0
N_kuntie	LABEL	BYTE
	DB	'kuntie',0
N_s3gtup	LABEL	BYTE
	DB	's3gtup',0
N_s3gtup2	LABEL	BYTE
	DB	's3gtup2',0
N_s3gtupst	LABEL	BYTE
	DB	's3gtupst',0
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_sscann	LABEL	BYTE
	DB	'sscann',0
	DB	'mscans',0
N_mscanw	LABEL	BYTE
	DB	'mscanw',0
N_mscane	LABEL	BYTE
	DB	'mscane',0

rdf_scripts:
; The room starts: the Cradle, the hostages tied or free, Preax.
H_0146:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0220
StartRoom:
	jmp	SHORT L0157

N_LOV5LOOP	LABEL	BYTE
	DB	'LOV5LOOP',0
L0157:
	push	OFFSET N_LOV5LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("LOV5LOOP")
	add	sp, 4
	push	0
	push	0A9h
	push	27h
	push	OFFSET N_s3r6c1
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s3r6c1", 39, 169, 0)
	add	sp, 0Ch
	push	0
	push	0A6h
	push	28h
	push	OFFSET N_marcus2
	cmp	byte ptr [si+freed_hostages], 1
	jne	L0190
	pop	ax
	push	OFFSET N_marcusst
L0190:
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, ?, 40, 166, 0)
	add	sp, 0Ch
	push	0
	push	0ACh
	push	49h
	push	OFFSET N_s3gtup2
	cmp	byte ptr [si+freed_hostages], 1
	jne	L01B0
	pop	ax
	push	OFFSET N_s3gtupst
L01B0:
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, ?, 73, 172, 0)
	add	sp, 0Ch
	push	0
	push	0BAh
	push	116h
	push	OFFSET N_s3r6r2
	cmp	byte ptr [si+preax_cured], 1
	jne	L01D1
	pop	ax
	push	OFFSET N_s3r6r3
L01D1:
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, ?, 278, 186, 0)
	add	sp, 0Ch
	cmp	byte ptr [si+n2o_released], 1
	jne	L01F5
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS], ax
L01F5:
	cmp	byte ptr [si+rlg_released], 1
	jne	L020E
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS+2], ax
L020E:
	mov	word ptr [si+RS_TIMERS+4], 0C8h
	mov	byte ptr cs:cure_x, -77h
	mov	byte ptr cs:cure_y, -47h
	retf

; Exit 1 (timer 4): back to the crew quarters, room 4.
H_0220:
	SCRIPT	MSG_EXIT, 1, 0, 0, H_023C
ExitToQuarters:
	mov	byte ptr [si+RS_BUSY], 1
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	mov	word ptr [si+RS_TIMERS+8], 0Ah
	retf

H_023C:
	SCRIPT	MSG_TIMER, 4, 0, 0, H_0255
GoToQuarters:
	push	0
	push	4
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(4, 0)
	add	sp, 6
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Phasers on Preax. The second script has the same key, so it never runs
; (the first doesn't set RS_MORE); it was probably meant for kill.
H_0255:
	SCRIPT	MSG_USE, IT_PHASERS, 9, 0, H_02B1
PhaserPreax:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_011
	call	Say
	jmp	SHORT L02B0

T_LOV5_011	LABEL	BYTE
	DB	'#LOV5\LOV5_011#Are you crazy, Jim? That''s not going to help in t'
	DB	'he least!',0
L02B0:
	retf

H_02B1:
	SCRIPT	MSG_USE, IT_PHASERS, 9, 0, H_0312
PhaserPreaxAgain:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_FEA5_008
	call	Say
	jmp	SHORT L0311

T_FEA5_008	LABEL	BYTE
	DB	'#FEA5\FEA5_008#Captain, I''ll declare you unfit to command if you'
	DB	' keep this up>',0
L0311:
	retf

; Looking.
H_0312:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_0321
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_LOV5N004
	call	Say
	retf

H_0321:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_0330
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_LOV5N005
	call	Say
	retf

H_0330:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_033F
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_LOV5N002
	call	Say
	retf

H_033F:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_034E
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_LOV5N003
	call	Say
	retf

H_034E:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_039C
LookAtLab:
	mov	ax, 0
	mov	bx, OFFSET T_LOV5N008
	call	Say
	jmp	SHORT L039B

T_LOV5N008	LABEL	BYTE
	DB	'#LOV5\LOV5N008#This is a very advanced research laboratory.',0
L039B:
	retf

H_039C:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_03BE
LookAtCradle:
	mov	ax, OFFSET S_234F
	mov	bx, OFFSET T_LOV5N013
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_028
	call	Say
	mov	ax, OFFSET N_Dr_Marcus
	mov	bx, OFFSET T_LOV5_044
	call	Say
	retf

H_03BE:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_03E0
LookAtEquipment:
	mov	ax, OFFSET S_234F
	mov	bx, OFFSET T_LOV5N016
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_031
	call	Say
	mov	ax, OFFSET N_Dr_Marcus
	mov	bx, OFFSET T_LOV5_050
	call	Say
	retf

H_03E0:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_0409
LookAtMarcus:
	cmp	byte ptr [si+freed_hostages], 1
	jne	L03F6
	mov	ax, OFFSET S_234F
	mov	bx, OFFSET T_LOV5N001_2
	call	Say
	retf

L03F6:
	mov	ax, OFFSET S_234F
	mov	bx, OFFSET T_LOV5N001
	call	Say
	mov	ax, OFFSET N_Dr_Marcus
	mov	bx, OFFSET T_LOV5_046
	call	Say
	retf

H_0409:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_044A
LookAtCheever:
	cmp	byte ptr [si+freed_hostages], 1
	jne	L041F
	mov	ax, OFFSET S_234F
	mov	bx, OFFSET T_LOV5N000
	call	Say
	retf

L041F:
	mov	ax, OFFSET S_234F
	mov	bx, OFFSET T_LOV5N014
	call	Say
	mov	ax, OFFSET N_Dr_Cheever
	mov	bx, OFFSET T_LOV5_057
	call	Say
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L0449
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV5_054
	call	Say
	mov	ax, OFFSET N_Dr_Cheever
	mov	bx, OFFSET T_LOV5_058
	call	Say
L0449:
	retf

H_044A:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_04B8
LookAtScene:
	mov	ax, 0
	mov	bx, OFFSET T_LOV5N009
	call	Say
	jmp	SHORT L04B7

T_LOV5N009	LABEL	BYTE
	DB	'#LOV5\LOV5N009#This is Dr. Carol Marcus'' quarters. The hostages '
	DB	'and four Romulans are here.',0
L04B7:
	retf

H_04B8:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_04D8
LookAtPreax:
	cmp	byte ptr [si+preax_cured], 1
	je	L04CE
	mov	ax, OFFSET S_234F
	mov	bx, OFFSET T_LOV5N012
	call	Say
	retf

L04CE:
	mov	ax, OFFSET S_234F
	mov	bx, OFFSET T_LOV5N011
	call	Say
	retf

; Talking to Preax, once he is cured and the hostages free: a
; conversation; the right answer has them part as worthy opponents. Then
; McCoy cures Spock if he hasn't been (msgs 5, 6), and everyone gathers
; to leave (msg 6): +17 score and the mission's end.
H_04D8:
	SCRIPT	MSG_TALK, 9, 0, 0, H_0766
TalkToPreax:
	cmp	byte ptr [si+preax_cured], 0
	jne	L0537
	mov	ax, OFFSET N_Dr_Marcus
	mov	bx, OFFSET T_LOV5_018
	call	Say
	jmp	SHORT L0536

T_LOV5_018	LABEL	BYTE
	DB	'#LOV5\LOV5_018#He''s too weak to talk, Jim. He needs medical atte'
	DB	'ntion.',0
L0536:
	retf

L0537:
	cmp	byte ptr [si+freed_hostages], 0
	jne	L05A7
	mov	ax, 0
	mov	bx, OFFSET T_LOV5N006
	call	Say
	jmp	SHORT L05A6

T_LOV5N006	LABEL	BYTE
	DB	'#LOV5\LOV5N006#The Preax remains silent, but glances between you'
	DB	' and your tied up companions.',0
L05A6:
	retf

L05A7:
	mov	ax, OFFSET PreaxSpeaks
	call	Talk
	mov	ax, OFFSET KirkToPreax
	call	Talk
	AX8	cmp, 0
	jne	L05BA
	jmp	SHORT L05CD

L05BA:
	AX8	cmp, 1
	jne	L05C2
	JMPN	L0693

L05C2:
	AX8	cmp, 2
	jne	L05CA
	JMPN	L069C

L05CA:
	JMPN	L06FB

L05CD:
	mov	ax, OFFSET PreaxAnswers
	call	Talk
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV5_010
	call	Say
	jmp	SHORT L0633

T_LOV5_010	LABEL	BYTE
	DB	'#LOV5\LOV5_010#You are also a worthy opponent, Preax. May you li'
	DB	've long and prosper.',0
L0633:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_063E
	call	Say
	jmp	SHORT L0652

S_063E	LABEL	BYTE
	DB	'(Raises an eyebrow)',0
L0652:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_032
	call	Say
	jmp	SHORT L0691

T_LOV5_032	LABEL	BYTE
	DB	'#LOV5\LOV5_032#You''ll never cease to amaze me, Jim.',0
L0691:
	jmp	SHORT L06A8

L0693:
	mov	ax, OFFSET MarcusFarewell
	call	Talk
	JMPN	L05CD

L069C:
	mov	ax, OFFSET KirkFarewell
	call	Talk
	mov	byte ptr [si+preax_talked], 1
	jmp	SHORT L06A8

L06A8:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV5_002
	call	Say
	jmp	SHORT L06D1

T_LOV5_002	LABEL	BYTE
	DB	'#LOV5\LOV5_002#Goodbye Carol.',0
L06D1:
	mov	ax, OFFSET N_Dr_Marcus
	mov	bx, OFFSET T_LOV5_045
	call	Say
	jmp	SHORT L06F8

T_LOV5_045	LABEL	BYTE
	DB	'#LOV5\LOV5_045#Goodbye Jim.',0
L06F8:
	jmp	SHORT L0705

	DB	0CBh
L06FB:
	mov	ax, 0
	mov	bx, OFFSET N_dialog_error
	call	Say
	retf

L0705:
	mov	byte ptr [si+RS_BUSY], 1
	cmp	byte ptr [si+spock_cured], 1
	jne	L0712
	JMPN	L083C

L0712:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_021
	call	Say
	jmp	SHORT L0751

T_LOV5_021	LABEL	BYTE
	DB	'#LOV5\LOV5_021#Oops! Almost forgot about you Spock.',0
L0751:
	push	5
	push	0C3h
	push	87h
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 135, 195, 5)
	add	sp, 0Ah
	retf

H_0766:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_0782
McCoyAtSpock:
	push	6
	push	-1
	push	-1
	push	OFFSET N_musemn
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musemn", -1, -1, 6)
	add	sp, 0Ch
	retf

H_0782:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_08DD
SpockCuredAtLast:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_030
	call	Say
	jmp	SHORT L07BB

T_LOV5_030	LABEL	BYTE
	DB	'#LOV5\LOV5_030#There. You''re now cured.',0
L07BB:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV5_038
	call	Say
	jmp	SHORT L07E8

T_LOV5_038	LABEL	BYTE
	DB	'#LOV5\LOV5_038#Thank you, Doctor.',0
L07E8:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_027
	call	Say
	jmp	SHORT L081D

T_LOV5_027	LABEL	BYTE
	DB	'#LOV5\LOV5_027#Finally, a human response!',0
L081D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_0828
	call	Say
	jmp	SHORT L083C

S_0828	LABEL	BYTE
	DB	'(raises an eyebrow)',0
L083C:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV5_001
	call	Say
	jmp	SHORT L0875

T_LOV5_001	LABEL	BYTE
	DB	'#LOV5\LOV5_001#Well gentlemen, let''s go home.',0
L0875:
	mov	byte ptr [si+RS_FALL], 1
	push	6
	push	0C2h
	push	64h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 100, 194, 6)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+1], 1
	push	6
	push	0B8h
	push	5Ah
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 90, 184, 6)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+2], 1
	push	6
	push	0B8h
	push	6Eh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 110, 184, 6)
	add	sp, 0Ah
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L08DC
	mov	byte ptr [si+RS_FALL+3], 1
	push	6
	push	0AEh
	push	69h
	push	3
	push	RC_WALK
	SERVICE		; Walk(3, 105, 174, 6)
	add	sp, 0Ah
	dec	byte ptr cs:gathered
L08DC:
	retf

H_08DD:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_0907
CrewGathered:
	inc	byte ptr cs:gathered
	cmp	byte ptr cs:gathered, 3
	je	L08F1
	retf

L08F1:
	add	word ptr [si+score], 11h
	push	0
	push	2Ch
	push	word ptr [si+score]
	push	RC_BEAMUP
	SERVICE		; BeamUp(?, 44, 0)
	add	sp, 8
	retf

; Talking.
H_0907:
	SCRIPT	MSG_TALK, 0Ah, 0, 0, H_0A66
TalkToMarcus:
	cmp	byte ptr [si+freed_hostages], 1
	je	L094E
	mov	ax, OFFSET N_Dr_Marcus
	mov	bx, OFFSET T_LOV5_040
	call	Say
	jmp	SHORT L094D

T_LOV5_040	LABEL	BYTE
	DB	'#LOV5\LOV5_040#Jim, it''s you! Please untie us!',0
L094D:
	retf

L094E:
	push	IT_CURE
	push	RC_HAVEITEM
	SERVICE		; HaveItem(IT_CURE)
	add	sp, 4
	AX8	cmp, 0
	je	L0962
	JMPN	L0A24

L0962:
	mov	ax, OFFSET N_Dr_Marcus
	mov	bx, OFFSET T_LOV5_039
	call	Say
	JMPN	L0A23

T_LOV5_039	LABEL	BYTE
	DB	'#LOV5\LOV5_039#Anthony and I will look after these Romulans, Jim'
	DB	'. Dr. McCoy, we could use your expertise on discovering a cure f'
	DB	'or the virus. All our equipment is at your disposal.',0
L0A23:
	retf

L0A24:
	mov	ax, OFFSET N_Dr_Marcus
	mov	bx, OFFSET T_LOV5_042
	call	Say
	jmp	SHORT L0A65

T_LOV5_042	LABEL	BYTE
	DB	'#LOV5\LOV5_042#Thank you for saving our station, Jim.',0
L0A65:
	retf

H_0A66:
	SCRIPT	MSG_TALK, 0Bh, 0, 0, H_0AEA
TalkToCheever:
	cmp	byte ptr [si+freed_hostages], 1
	je	L0AAD
	mov	ax, OFFSET N_Dr_Cheever
	mov	bx, OFFSET T_LOV5_055
	call	Say
	jmp	SHORT L0AAC

T_LOV5_055	LABEL	BYTE
	DB	'#LOV5\LOV5_055#Hey! Would you please untie us?',0
L0AAC:
	retf

L0AAD:
	mov	ax, OFFSET N_Dr_Cheever
	mov	bx, OFFSET T_LOV5_056
	call	Say
	jmp	SHORT L0AE9

T_LOV5_056	LABEL	BYTE
	DB	'#LOV5\LOV5_056#It''s about time someone got here.',0
L0AE9:
	retf

H_0AEA:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0B15
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV5_003
	call	Say
	mov	ax, OFFSET N_Dr_Marcus
	mov	bx, OFFSET T_LOV5_048
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV5_009
	call	Say
	mov	ax, OFFSET N_Dr_Marcus
	mov	bx, OFFSET T_LOV5_047
	call	Say
	retf

H_0B15:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0B37
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV5_036
	call	Say
	mov	ax, OFFSET N_Dr_Marcus
	mov	bx, OFFSET T_LOV5_051
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_G_024
	call	Say
	retf

H_0B37:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0BCE
TalkToMcCoy:
	cmp	byte ptr [si+preax_cured], 1
	jne	L0B46
	JMPN	L0BCD

L0B46:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_014
	call	Say
	jmp	SHORT L0BCD

T_LOV5_014	LABEL	BYTE
	DB	'#LOV5\LOV5_014#Dammit, Jim, I''m a doctor, not a diplomat. These '
	DB	'people will be fine. I''ve got to try and save the Romulans.',0
L0BCD:
	retf

H_0BCE:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0C25
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV5_052
	call	Say
	jmp	SHORT L0C24

T_LOV5_052	LABEL	BYTE
	DB	'#LOV5\LOV5_052#These Romulans appear to be a negligible threat, '
	DB	'sir.',0
L0C24:
	retf

; Tricorders.
H_0C25:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_0C99
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
	mov	bx, OFFSET T_LOV5_033
	call	Say
	jmp	SHORT L0C98

T_LOV5_033	LABEL	BYTE
	DB	'#LOV5\LOV5_033#I detect no other lifeforms in the room, Captain.',0
L0C98:
	retf

H_0C99:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_0CD3
SpockScansCradle:
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
	mov	bx, OFFSET T_LOV5_034
	call	Say
	mov	ax, OFFSET N_Dr_Marcus
	mov	bx, OFFSET T_LOV5_049
	call	Say
	retf

H_0CD3:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Ah, 0, H_0CDB
	jmp	SHORT McCoyScansHostages

H_0CDB:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Bh, 0, H_0D0C
McCoyScansHostages:
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
	mov	bx, OFFSET T_LOV5_025
	call	Say
	retf

H_0D0C:
	SCRIPT	MSG_USE, IT_MTRICOR, 9, 0, H_0E2F
McCoyScansPreax:
	cmp	byte ptr [si+preax_cured], 1
	jne	L0D19
	retf

L0D19:
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
	cmp	byte ptr [si+romulans_out], 1
	je	L0D43
	JMPN	L0DED

L0D43:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_024
	call	Say
	JMPN	L0DEC

T_LOV5_024	LABEL	BYTE
	DB	'#LOV5\LOV5_024#The hostages are scared, but fine. The laughing g'
	DB	'as did the trick, Jim, but the Romulan is still very, very sick '
	DB	'-- he''s only got hours left.',0
L0DEC:
	retf

L0DED:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_016
	call	Say
	jmp	SHORT L0E2E

T_LOV5_016	LABEL	BYTE
	DB	'#LOV5\LOV5_016#He''s infected with the virus too, Jim.',0
L0E2E:
	retf

; Treating Preax: water (+1, once), and if the virus had struck he wakes
; and reaches for his weapon; the cure (msgs 4, 5).
H_0E2F:
	SCRIPT	MSG_USE, IT_MEDKIT, 9, 0, H_0EBD
MedkitOnPreax:
	cmp	byte ptr [si+preax_cured], 1
	je	L0E89
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_019
	call	Say
	jmp	SHORT L0E88

T_LOV5_019	LABEL	BYTE
	DB	'#LOV5\LOV5_019#I don''t have the proper medicine to cure him, Jim'
	DB	'.',0
L0E88:
	retf

L0E89:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_015
	call	Say
	jmp	SHORT L0EBC

T_LOV5_015	LABEL	BYTE
	DB	'#LOV5\LOV5_015#He''s already cured, Jim.',0
L0EBC:
	retf

H_0EBD:
	SCRIPT	MSG_USE, IT_H2O, 9, 0, H_120F
WaterPreax:
	mov	byte ptr cs:watered, 1
	cmp	byte ptr [si+preax_cured], 1
	je	L0ED2
	JMPN	L100D

L0ED2:
	mov	ax, 0
	mov	bx, OFFSET T_LOV5N018
	call	Say
	jmp	SHORT L0F2A

T_LOV5N018	LABEL	BYTE
	DB	'#LOV5\LOV5N018#The Romulan Preax drinks thirstily and empties th'
	DB	'e container.',0
L0F2A:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_029
	call	Say
	jmp	SHORT L0FA9

T_LOV5_029	LABEL	BYTE
	DB	'#LOV5\LOV5_029#Take it easy now... You''ll feel better in a few m'
	DB	'inutes. Good thing we had the water available, Jim.',0
L0FA9:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV5_007
	call	Say
	jmp	SHORT L0FFC

T_LOV5_007	LABEL	BYTE
	DB	'#LOV5\LOV5_007#We aren''t barbarians, in spite of what some might'
	DB	' think.',0
L0FFC:
	cmp	byte ptr [si+watered_preax], 1
	je	L100A
	mov	byte ptr [si+watered_preax], 1
	add	word ptr [si+score], 1
L100A:
	JMPN	L1202

L100D:
	cmp	byte ptr [si+virus_struck], 1
	je	L1016
	JMPN	L10D5

L1016:
	mov	ax, 0
	mov	bx, OFFSET T_LOV5_013
	call	Say
	JMPN	L10D2

T_LOV5_013	LABEL	BYTE
	DB	'#LOV5\LOV5_013#Careful there! He''s suffering from dehydration bu'
	DB	't it''s dangerous to give water to someone while they''re unconsci'
	DB	'ous. This man needs serum or he''s going to die!',0
L10D2:
	JMPN	L1202

L10D5:
	mov	ax, 0
	mov	bx, OFFSET T_LOV5N017
	call	Say
	jmp	SHORT L1139

T_LOV5N017	LABEL	BYTE
	DB	'#LOV5\LOV5N017#The Romulan Preax weakly regains conscienceness, '
	DB	'reaching for his weapon.',0
L1139:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L11B4
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV5_053
	call	Say
	jmp	SHORT L117A

T_LOV5_053	LABEL	BYTE
	DB	'#LOV5\LOV5_053#Freeze, Romulan! You''re covered!',0
L117A:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV5_005
	call	Say
	jmp	SHORT L11B4

T_LOV5_005	LABEL	BYTE
	DB	'#LOV5\LOV5_005#Lt. Ferris, collect his weapon.',0
L11B4:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_026
	call	Say
	jmp	SHORT L1202

T_LOV5_026	LABEL	BYTE
	DB	'#LOV5\LOV5_026#Dammit, Jim, these men are sick! They need my hel'
	DB	'p!',0
L1202:
	push	IT_H2O
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_H2O)
	add	sp, 4
	retf

H_120F:
	SCRIPT	MSG_USE, IT_SAMPLE, 9, 0, H_1266
SampleOnPreax:
	mov	ax, 0
	mov	bx, OFFSET T_LOV5_020
	call	Say
	jmp	SHORT L1265

T_LOV5_020	LABEL	BYTE
	DB	'#LOV5\LOV5_020#Jim, we need to synthesize more before we can use'
	DB	' it.',0
L1265:
	retf

H_1266:
	SCRIPT	MSG_USE, IT_CURE, 9, 0, H_1288
CurePreax:
	cmp	byte ptr [si+preax_cured], 1
	jne	L1273
	retf

L1273:
	push	4
	push	0BFh
	push	116h
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 278, 191, 4)
	add	sp, 0Ah
	retf

H_1288:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_12A4
McCoyAtPreax:
	push	5
	push	-1
	push	-1
	push	OFFSET N_musemn
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musemn", -1, -1, 5)
	add	sp, 0Ch
	retf

H_12A4:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_1388
PreaxCured:
	push	0
	push	0C3h
	push	0DCh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 220, 195, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+2], 2
	mov	ax, 0
	mov	bx, OFFSET T_LOV5N007
	call	Say
	jmp	SHORT L1328

T_LOV5N007	LABEL	BYTE
	DB	'#LOV5\LOV5N007#The Romulan Preax stirs weakly, then begins to ge'
	DB	't up... he has been cured!',0
L1328:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_017
	call	Say
	jmp	SHORT L136C

T_LOV5_017	LABEL	BYTE
	DB	'#LOV5\LOV5_017#He''s severely dehydrated, but he''ll live.',0
L136C:
	push	0
	push	0BAh
	push	116h
	push	OFFSET N_s3r6r1
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s3r6r1", 278, 186, 0)
	add	sp, 0Ch
	mov	byte ptr [si+preax_cured], 1
	retf

H_1388:
	SCRIPT	MSG_USE, ANY, 9, 0, H_13C2
UseOnPreax:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_023
	call	Say
	jmp	SHORT L13C1

T_LOV5_023	LABEL	BYTE
	DB	'#LOV5\LOV5_023#That''s not working, Jim.',0
L13C1:
	retf

; Untying Cheever and Marcus (msgs 1-4).
H_13C2:
	SCRIPT	MSG_USE, OBJ_KIRK, 0Ah, 0, H_13CA
	jmp	SHORT UntieHostages

H_13CA:
	SCRIPT	MSG_USE, OBJ_KIRK, 0Bh, 0, H_13F3
UntieHostages:
	cmp	byte ptr [si+freed_hostages], 1
	jne	L13D7
	retf

L13D7:
	mov	byte ptr [si+RS_BUSY], 1
	push	1
	push	0B1h
	push	49h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 73, 177, 1)
	add	sp, 0Ah
	mov	byte ptr [si+freed_hostages], 1
	retf

H_13F3:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_140F
KirkAtCheever:
	push	2
	push	-1
	push	-1
	push	OFFSET N_kuntie
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuntie", -1, -1, 2)
	add	sp, 0Ch
	retf

H_140F:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_143F
CheeverFree:
	push	0
	push	0ACh
	push	49h
	push	OFFSET N_s3gtup
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s3gtup", 73, 172, 0)
	add	sp, 0Ch
	push	2
	push	0B1h
	push	26h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 38, 177, 2)
	add	sp, 0Ah
	retf

H_143F:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_145B
KirkAtMarcus:
	push	3
	push	-1
	push	-1
	push	OFFSET N_kuntie
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuntie", -1, -1, 3)
	add	sp, 0Ch
	retf

H_145B:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_149B
MarcusFree:
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	push	4
	push	0A6h
	push	28h
	push	OFFSET N_marcus
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "marcus", 40, 166, 4)
	add	sp, 0Ch
	push	0
	push	0B9h
	push	35h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 53, 185, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL], 0
	retf

H_149B:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_1500
MarcusThanks:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Dr_Marcus
	mov	bx, OFFSET T_LOV5_041
	call	Say
	jmp	SHORT L14EE

T_LOV5_041	LABEL	BYTE
	DB	'#LOV5\LOV5_041#Thank God it''s you, Jim. I''m so glad you came.',0
L14EE:
	retf

N_musemn	LABEL	BYTE
	DB	'musemn',0
N_sgetdn	LABEL	BYTE
	DB	'sgetdn',0
cure_steps	LABEL	BYTE	; Spock and McCoy at the cure spot: 2
	DB	0
cure_x	LABEL	BYTE	; the cure spot
	DB	0
cure_y	LABEL	BYTE
	DB	0

; The gases, common to all of the mission's rooms. Timer 0 (after
; laughing gas): a random crew member giggles, and again in 200-400 ticks.
H_1500:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_171D
CrewLaugh:
	push	2
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 2)
	add	sp, 6
	mov	word ptr cs:roll, ax
	cmp	word ptr cs:roll, 0
	jne	L1529
	mov	word ptr cs:laugher, OFFSET N_Dr_McCoy
	jmp	SHORT L1566

L1529:
	cmp	word ptr cs:roll, 1
	jne	L154A
	mov	word ptr cs:laugher, OFFSET N_Lt_Ferris
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L1548
	mov	word ptr cs:laugher, OFFSET N_Dr_McCoy
	JMPN	L1611

L1548:
	jmp	SHORT L1566

L154A:
	mov	ax, 0
	mov	bx, OFFSET N_get_name_error
	call	Say
	jmp	SHORT L1565

N_get_name_error	LABEL	BYTE
	DB	'get name error.',0
L1565:
	retf

L1566:
	mov	word ptr cs:laugher, OFFSET N_Dr_McCoy
	push	0Ah
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 10)
	add	sp, 6
	mov	word ptr cs:roll, ax
	cmp	word ptr cs:roll, 0
	jne	L158D
	mov	bx, OFFSET T_LOV0_011
	JMPN	L16B8

L158D:
	cmp	word ptr cs:roll, 1
	jne	L159B
	mov	bx, OFFSET T_LOV0_020
	JMPN	L16B8

L159B:
	cmp	word ptr cs:roll, 2
	jne	L15A9
	mov	bx, OFFSET T_LOV0_016
	JMPN	L16B8

L15A9:
	cmp	word ptr cs:roll, 3
	jne	L15B7
	mov	bx, OFFSET T_LOV0_012
	JMPN	L16B8

L15B7:
	cmp	word ptr cs:roll, 4
	jne	L15C5
	mov	bx, OFFSET T_LOV0_014
	JMPN	L16B8

L15C5:
	cmp	word ptr cs:roll, 5
	jne	L15D3
	mov	bx, OFFSET T_LOV0_022
	JMPN	L16B8

L15D3:
	cmp	word ptr cs:roll, 6
	jne	L15E1
	mov	bx, OFFSET T_LOV0_015
	JMPN	L16B8

L15E1:
	cmp	word ptr cs:roll, 7
	jne	L15EF
	mov	bx, OFFSET T_LOV0_021
	JMPN	L16B8

L15EF:
	cmp	word ptr cs:roll, 8
	jne	L15FD
	mov	bx, OFFSET T_LOV0_013
	JMPN	L16B8

L15FD:
	cmp	word ptr cs:roll, 9
	jne	L160B
	mov	bx, OFFSET T_LOV0_019
	JMPN	L16B8

L160B:
	mov	bx, OFFSET T_LOV0_017
	JMPN	L16B8

L1611:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L1618
	retf

L1618:
	mov	word ptr cs:laugher, OFFSET N_Lt_Ferris
	push	0Ah
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 10)
	add	sp, 6
	mov	word ptr cs:roll, ax
	cmp	word ptr cs:roll, 0
	jne	L163E
	mov	bx, OFFSET T_LOV0_039
	jmp	SHORT L16B8

L163E:
	cmp	word ptr cs:roll, 1
	jne	L164B
	mov	bx, OFFSET T_LOV0_048
	jmp	SHORT L16B8

L164B:
	cmp	word ptr cs:roll, 2
	jne	L1658
	mov	bx, OFFSET T_LOV0_045
	jmp	SHORT L16B8

L1658:
	cmp	word ptr cs:roll, 3
	jne	L1665
	mov	bx, OFFSET T_LOV0_040
	jmp	SHORT L16B8

L1665:
	cmp	word ptr cs:roll, 4
	jne	L1672
	mov	bx, OFFSET T_LOV0_042
	jmp	SHORT L16B8

L1672:
	cmp	word ptr cs:roll, 5
	jne	L167F
	mov	bx, OFFSET T_LOV0_050
	jmp	SHORT L16B8

L167F:
	cmp	word ptr cs:roll, 6
	jne	L168C
	mov	bx, OFFSET T_LOV0_043
	jmp	SHORT L16B8

L168C:
	cmp	word ptr cs:roll, 7
	jne	L1699
	mov	bx, OFFSET T_LOV0_049
	jmp	SHORT L16B8

L1699:
	cmp	word ptr cs:roll, 8
	jne	L16A6
	mov	bx, OFFSET T_LOV0_041
	jmp	SHORT L16B8

L16A6:
	cmp	word ptr cs:roll, 9
	jne	L16B3
	mov	bx, OFFSET T_LOV0_047
	jmp	SHORT L16B8

L16B3:
	mov	bx, OFFSET T_LOV0_046
	jmp	SHORT L16B8

L16B8:
	mov	ax, word ptr cs:laugher
	call	Say
	cmp	byte ptr [si+rlg_released], 1
	jne	L16C6
	retf

L16C6:
	push	3
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 3)
	add	sp, 6
	mov	word ptr cs:roll, ax
	mov	ax, OFFSET N_Mr_Spock
	cmp	word ptr cs:roll, 0
	jne	L16E8
	mov	bx, OFFSET T_LOV0_029
	jmp	SHORT L1707

L16E8:
	cmp	word ptr cs:roll, 1
	jne	L16F5
	mov	bx, OFFSET T_LOV0_033
	jmp	SHORT L1707

L16F5:
	cmp	word ptr cs:roll, 2
	jne	L1702
	mov	bx, OFFSET T_LOV0_026
	jmp	SHORT L1707

L1702:
	mov	bx, OFFSET T_LOV0_124
	jmp	SHORT L1707

L1707:
	call	Say
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS], ax
	retf

; Timer 1 (after Romulan laughing gas): Spock laughs.
H_171D:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_17AF
SpockLaughs:
	push	7
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 7)
	add	sp, 6
	mov	word ptr cs:roll, ax
	mov	ax, OFFSET N_Mr_Spock
	cmp	word ptr cs:roll, 0
	jne	L1745
	mov	bx, OFFSET T_LOV0_025
	jmp	SHORT L1798

L1745:
	cmp	word ptr cs:roll, 1
	jne	L1752
	mov	bx, OFFSET T_LOV0_101
	jmp	SHORT L1798

L1752:
	cmp	word ptr cs:roll, 2
	jne	L175F
	mov	bx, OFFSET T_LOV0_102
	jmp	SHORT L1798

L175F:
	cmp	word ptr cs:roll, 3
	jne	L176C
	mov	bx, OFFSET T_LOV0_103
	jmp	SHORT L1798

L176C:
	cmp	word ptr cs:roll, 4
	jne	L1779
	mov	bx, OFFSET T_LOV0_104
	jmp	SHORT L1798

L1779:
	cmp	word ptr cs:roll, 5
	jne	L1786
	mov	bx, OFFSET T_LOV0_105
	jmp	SHORT L1798

L1786:
	cmp	word ptr cs:roll, 6
	jne	L1793
	mov	bx, OFFSET T_LOV0_106
	jmp	SHORT L1798

L1793:
	mov	bx, OFFSET T_LOV0_107
	jmp	SHORT L1798

L1798:
	call	Say
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS+2], ax
	retf

; Curing Spock, common to all of the mission's rooms: with the cure,
; Spock and McCoy walk to the cure spot (msg 99), and McCoy injects him.
H_17AF:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_SPOCK, 0, H_183D
MedkitOnSpock:
	cmp	byte ptr [si+spock_cured], 1
	je	L1809
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_019_2
	call	Say
	jmp	SHORT L1808

T_LOV5_019_2	LABEL	BYTE
	DB	'#LOV5\LOV5_019#I don''t have the proper medicine to cure him, Jim'
	DB	'.',0
L1808:
	retf

L1809:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_015_2
	call	Say
	jmp	SHORT L183C

T_LOV5_015_2	LABEL	BYTE
	DB	'#LOV5\LOV5_015#He''s already cured, Jim.',0
L183C:
	retf

H_183D:
	SCRIPT	MSG_USE, IT_SAMPLE, OBJ_SPOCK, 0, H_18B0
SampleOnSpock:
	cmp	byte ptr [si+spock_cured], 1
	jne	L184C
	JMPN	L18F0

L184C:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F55
	call	Say
	jmp	SHORT L18AF

T_LOVA_F55	LABEL	BYTE
	DB	'#LOVA\LOVA_F55#Jim, we need to sysnthesize more to make the seru'
	DB	'm before we can use it.',0
L18AF:
	retf

H_18B0:
	SCRIPT	MSG_USE, IT_CURE, OBJ_SPOCK, 0, H_192C
CureSpock:
	cmp	byte ptr [si+spock_cured], 1
	jne	L18F0
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_015_3
	call	Say
	jmp	SHORT L18EF

T_LOV5_015_3	LABEL	BYTE
	DB	'#LOV5\LOV5_015#He''s already cured, Jim.',0
L18EF:
	retf

L18F0:
	push	63h
	xor	ah, ah
	mov	al, byte ptr cs:cure_y
	push	ax
	xor	ah, ah
	mov	al, byte ptr cs:cure_x
	push	ax
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, ?, ?, 99)
	add	sp, 0Ah
	push	63h
	xor	ah, ah
	mov	al, byte ptr cs:cure_y
	AX8	add, 0Ah
	push	ax
	xor	ah, ah
	mov	al, byte ptr cs:cure_x
	push	ax
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, ?, ?, 99)
	add	sp, 0Ah
	retf

H_192C:
	SCRIPT	MSG_WALK_DONE, 63h, 0, 0, H_1956
AtSpock:
	inc	byte ptr cs:cure_steps
	cmp	byte ptr cs:cure_steps, 2
	je	L1940
	retf

L1940:
	push	63h
	push	-1
	push	-1
	push	OFFSET N_musemn
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musemn", -1, -1, 99)
	add	sp, 0Ch
	retf

H_1956:
	SCRIPT	MSG_ANIM_DONE, 63h, 0, 0, H_1A15
SpockCured:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_030_2
	call	Say
	jmp	SHORT L198F

T_LOV5_030_2	LABEL	BYTE
	DB	'#LOV5\LOV5_030#There. You''re now cured.',0
L198F:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV5_038_2
	call	Say
	jmp	SHORT L19BC

T_LOV5_038_2	LABEL	BYTE
	DB	'#LOV5\LOV5_038#Thank you, Doctor.',0
L19BC:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_027_2
	call	Say
	jmp	SHORT L19F1

T_LOV5_027_2	LABEL	BYTE
	DB	'#LOV5\LOV5_027#Finally, a human response!',0
L19F1:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_19FC
	call	Say
	jmp	SHORT L1A10

S_19FC	LABEL	BYTE
	DB	'(raises an eyebrow)',0
L1A10:
	mov	byte ptr [si+spock_cured], 1
	retf

; Timer 2, every 200 ticks until Spock is cured: the virus advances,
; with a line at 0Fh, 1Eh, 2Dh; at 3Ch Spock collapses, at 64h he dies.
H_1A15:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_1BCB
VirusProgresses:
	cmp	byte ptr [si+spock_cured], 1
	jne	L1A22
	retf

L1A22:
	inc	byte ptr [si+virus]
	cmp	byte ptr [si+virus], 64h
	jl	L1A2E
	JMPN	L1B7B

L1A2E:
	cmp	byte ptr [si+virus], 0Fh
	jne	L1A65
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_spokcoff
	call	Say
	jmp	SHORT L1A5F

T_spokcoff	LABEL	BYTE
	DB	'#sfx\spokcoff#cough... cough...',0
L1A5F:
	inc	byte ptr [si+virus]
	JMPN	L1B75

L1A65:
	cmp	byte ptr [si+virus], 1Eh
	jne	L1ACB
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F08
	call	Say
	jmp	SHORT L1AC5

T_LOVA_F08	LABEL	BYTE
	DB	'#LOVA\LOVA_F08#It''s what I was afraid of, Jim. I think spock is '
	DB	'getting worse.',0
L1AC5:
	inc	byte ptr [si+virus]
	JMPN	L1B75

L1ACB:
	cmp	byte ptr [si+virus], 2Dh
	jne	L1B01
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_spokcoff_2
	call	Say
	jmp	SHORT L1AFC

T_spokcoff_2	LABEL	BYTE
	DB	'#sfx\spokcoff#cough... cough...',0
L1AFC:
	inc	byte ptr [si+virus]
	jmp	SHORT L1B75

L1B01:
	cmp	byte ptr [si+virus], 3Ch
	jne	L1B75
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOVA_F54
	call	Say
	jmp	SHORT L1B6C

T_LOVA_F54	LABEL	BYTE
	DB	'#LOVA\LOVA_F54#The virus has spread to me, Captain.Isuggestyouco'
	DB	'ncentrateyoureffortsonthe',0
L1B6C:
	mov	byte ptr [si+virus_struck], 1
	inc	byte ptr [si+virus]
	jmp	SHORT L1B75

L1B75:
	mov	word ptr [si+RS_TIMERS+4], 0C8h
	retf

L1B7B:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sgetdn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sgetdn", -1, -1, 0)
	add	sp, 0Ch
	push	2
	push	RC_MUSIC
	SERVICE		; Music(2)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_GENER004
	call	Say
	jmp	SHORT L1BC0

T_GENER004	LABEL	BYTE
	DB	'#GENE\GENER004#Game Over',0
L1BC0:
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	retf

; McCoy's tricorder on Spock follows the virus; on the others, normal.
H_1BCB:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_SPOCK, 0, H_1E3C
McCoyScansSpock:
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	cmp	byte ptr [si+spock_cured], 1
	jne	L1C25
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F01
	call	Say
	jmp	SHORT L1C24

T_LOVA_F01	LABEL	BYTE
	DB	'#LOVA\LOVA_F01#He''s been cured of the Oroborus virus.',0
L1C24:
	retf

L1C25:
	cmp	byte ptr [si+have_research], 1
	je	L1C97
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F02
	call	Say
	jmp	SHORT L1C96

T_LOVA_F02	LABEL	BYTE
	DB	'#LOVA\LOVA_F02#I''m picking up some kind of virus. I can''t identi'
	DB	'fy it without more information.',0
L1C96:
	retf

L1C97:
	cmp	byte ptr [si+virus], 0Ah
	jge	L1CEC
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F04
	call	Say
	jmp	SHORT L1CEB

T_LOVA_F04	LABEL	BYTE
	DB	'#LOVA\LOVA_F04#The virus affects the Romulan-Vulcan genotype, Ji'
	DB	'm.',0
L1CEB:
	retf

L1CEC:
	cmp	byte ptr [si+virus], 1Eh
	jge	L1D30
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F03
	call	Say
	jmp	SHORT L1D2F

T_LOVA_F03	LABEL	BYTE
	DB	'#LOVA\LOVA_F03#He''s infected with the virus, Jim.',0
L1D2F:
	retf

L1D30:
	cmp	byte ptr [si+virus], 32h
	jge	L1D91
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F08_2
	call	Say
	jmp	SHORT L1D90

T_LOVA_F08_2	LABEL	BYTE
	DB	'#LOVA\LOVA_F08#It''s what I was afraid of, Jim. I think spock is '
	DB	'getting worse.',0
L1D90:
	retf

L1D91:
	cmp	byte ptr [si+virus], 46h
	jne	L1DD7
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG2_010
	call	Say
	jmp	SHORT L1DD6

T_TUG2_010	LABEL	BYTE
	DB	'#TUG2\TUG2_010#I don''t like the looks of this, Jim.',0
L1DD6:
	retf

L1DD7:
	cmp	byte ptr [si+virus], 64h
	jge	L1E11
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F10
	call	Say
	jmp	SHORT L1E10

T_LOVA_F10	LABEL	BYTE
	DB	'#LOVA\LOVA_F10#He has weak vital signs.',0
L1E10:
	retf

L1E11:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_100
	call	Say
	jmp	SHORT L1E3B

T_LOVA_100	LABEL	BYTE
	DB	'#LOVA\LOVA_100#He''s dead, Jim.',0
L1E3B:
	retf

H_1E3C:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_KIRK, 0, H_1E44
	jmp	SHORT McCoyScansMcCoy

H_1E44:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_MCCOY, 0, H_1E4C
McCoyScansMcCoy:
	jmp	SHORT McCoyScansCrew

H_1E4C:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_REDSHIRT, 0, H_1E93
McCoyScansCrew:
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F07
	call	Say
	jmp	SHORT L1E92

T_LOVA_F07	LABEL	BYTE
	DB	'#LOVA\LOVA_F07#All lifesigns are normal.',0
L1E92:
	retf

; Opening a gas canister: Romulan laughing gas sets Spock laughing,
; nitrous oxide the crew, ammonia nothing.
H_1E93:
	SCRIPT	MSG_USE, IT_RLG, ANY, 0, H_1EE3
ReleaseRLG:
	mov	ax, OFFSET S_234F
	mov	bx, OFFSET T_LOV2N005
	call	Say
	jmp	SHORT L1ED2

T_LOV2N005	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L1ED2:
	mov	byte ptr [si+rlg_released], 1
	push	IT_RLG
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_RLG)
	add	sp, 4
	retf

H_1EE3:
	SCRIPT	MSG_USE, IT_N2O, ANY, 0, H_1F75
ReleaseN2O:
	mov	ax, OFFSET S_234F
	mov	bx, OFFSET T_LOV2N005_2
	call	Say
	jmp	SHORT L1F22

T_LOV2N005_2	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L1F22:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD2_040
	call	Say
	jmp	SHORT L1F58

T_MUD2_040	LABEL	BYTE
	DB	'#MUD2\MUD2_040#You look troubled, Captain.',0
L1F58:
	mov	byte ptr [si+n2o_released], 1
	push	IT_N2O
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_N2O)
	add	sp, 4
	push	3
	push	RC_MUSIC
	SERVICE		; Music(3)
	add	sp, 4
	retf

H_1F75:
	SCRIPT	MSG_USE, IT_NH3, ANY, 0, H_1FDB
ReleaseNH3:
	mov	ax, OFFSET S_234F
	mov	bx, OFFSET T_LOV2N005_3
	call	Say
	jmp	SHORT L1FB4

T_LOV2N005_3	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L1FB4:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L1FBA
L1FBA:
	push	IT_NH3
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_NH3)
	add	sp, 4
	retf

	DB	'Mr. Scott',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0

; The communicator: four cases (first call, later calls, the same after
; the cure), all with the same three lines borrowed from other missions'
; speech files.
H_1FDB:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, rdf_scripts_end
CallEnterprise:
	cmp	byte ptr [si+made_cure], 1
	jne	L1FEA
	JMPN	L2137

L1FEA:
	cmp	byte ptr [si+called_ship], 1
	jne	L1FF3
	JMPN	L2097

L1FF3:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018
	call	Say
	jmp	SHORT L2038

T_MUD4_018	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L2038:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146
	call	Say
	jmp	SHORT L206E

T_BRIDU146	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L206E:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41
	call	Say
	jmp	SHORT L2092

T_VENA_F41	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L2092:
	mov	byte ptr [si+called_ship], 1
	retf

L2097:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_2
	call	Say
	jmp	SHORT L20DC

T_MUD4_018_2	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L20DC:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_2
	call	Say
	jmp	SHORT L2112

T_BRIDU146_2	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L2112:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_2
	call	Say
	jmp	SHORT L2136

T_VENA_F41_2	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L2136:
	retf

L2137:
	cmp	byte ptr [si+called_ship_cured], 1
	jne	L2140
	JMPN	L21E4

L2140:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_3
	call	Say
	jmp	SHORT L2185

T_MUD4_018_3	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L2185:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_3
	call	Say
	jmp	SHORT L21BB

T_BRIDU146_3	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L21BB:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_3
	call	Say
	jmp	SHORT L21DF

T_VENA_F41_3	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L21DF:
	mov	byte ptr [si+called_ship_cured], 1
	retf

L21E4:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_4
	call	Say
	jmp	SHORT L2229

T_MUD4_018_4	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L2229:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_4
	call	Say
	jmp	SHORT L225F

T_BRIDU146_4	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L225F:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_4
	call	Say
	jmp	SHORT L2283

T_VENA_F41_4	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L2283:
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
	DW	145,78, 164,78, 164,129, 145,129
	DW	21h, 4	; id, points
	DW	112,140, 201,140, 201,160, 112,160
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	1, 4	; id, points
	DW	42,197, 242,197, 242,199, 42,199
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's3r6l1',0
	DB	's3r6l2',0
	DB	's3r6l3',0
	DB	's3r6l4',0
	DB	's3r6l5',0
	DB	's3r6l6',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Ferris	LABEL	BYTE
	DB	'Lt. Ferris',0
N_Preax	LABEL	BYTE
	DB	'Preax',0
N_Dr_Marcus	LABEL	BYTE
	DB	'Dr. Marcus',0
N_Dr_Cheever	LABEL	BYTE
	DB	'Dr. Cheever',0
S_234F	LABEL	BYTE
	DB	0
T_LOV5N013	LABEL	BYTE
	DB	'#LOV5\LOV5N013#An odd looking device, almost like a 20th Century'
	DB	' torpedo, fitted with an experimental gear.',0
T_LOV5_028	LABEL	BYTE
	DB	'#LOV5\LOV5_028#My God, that''s some kind of weapon!',0
T_LOV5_044	LABEL	BYTE
	DB	'#LOV5\LOV5_044#Everyone on this project is an avowed pacifist, d'
	DB	'octor. Myself included. We do not make weapons.',0
T_LOV5N016	LABEL	BYTE
	DB	'#LOV5\LOV5N016#Some odd looking equipment, connected to the torp'
	DB	'edo.',0
T_LOV5_031	LABEL	BYTE
	DB	'#LOV5\LOV5_031#What does this stuff do? What''s going on here?',0
T_LOV5_050	LABEL	BYTE
	DB	'#LOV5\LOV5_050#We''re conducting research into the origins of lif'
	DB	'e in the universe. This is our equipment. We believe that... uh,'
	DB	' well, I guess you don''t have the time. You can get the backgrou'
	DB	'nd in my doctoral thesis.',0
	DB	'#LOV5\LOV5N010#This ladder leads back to the main level of the s'
	DB	'tation.',0
T_LOV5N001	LABEL	BYTE
	DB	'#LOV5\LOV5N001#Dr. Carol Marcus, head of this station''s research'
	DB	' team. She has been bound by the Romulans.',0
T_LOV5_046	LABEL	BYTE
	DB	'#LOV5\LOV5_046#How about someone giving us a hand?',0
T_LOV5N001_2	LABEL	BYTE
	DB	'#LOV5\LOV5N001#Dr. Carol Marcus, head of this station''s research'
	DB	' team.',0
T_LOV5N014	LABEL	BYTE
	DB	'#LOV5\LOV5N014#Dr. Anthony Cheever, Marcus''s assistant. He has b'
	DB	'een bound by the Romulans.',0
T_LOV5_057	LABEL	BYTE
	DB	'#LOV5\LOV5_057#Hey? Does anyone in Starfleet know how to untie a'
	DB	' knot?',0
T_LOV5_054	LABEL	BYTE
	DB	'#LOV5\LOV5_054#I do. You just pull on the ropes until they''re un'
	DB	'tied.',0
T_LOV5_058	LABEL	BYTE
	DB	'#LOV5\LOV5_058#I don''t care who does it, but could somebody get '
	DB	'around to doing it on this Stardate?',0
T_LOV5N000	LABEL	BYTE
	DB	'#LOV5\LOV5N000#Dr. Anthony Cheever, the assistant of Dr. Marcus.',0
T_LOV5N012	LABEL	BYTE
	DB	'#LOV5\LOV5N012#This Romulan commander is unconscious.',0
T_LOV5N011	LABEL	BYTE
	DB	'#LOV5\LOV5N011#This Romulan commander is cautiously looking at y'
	DB	'ou.',0
T_LOV5N004	LABEL	BYTE
	DB	'#LOV5\LOV5N004#James T. Kirk, glad to see Carol Marcus again, ye'
	DB	't slightly uncomfortable.',0
T_LOV5N002	LABEL	BYTE
	DB	'#LOV5\LOV5N002#Dr. McCoy is viewing this scene with interest.',0
T_LOV5N005	LABEL	BYTE
	DB	'#LOV5\LOV5N005#Mr. Spock is fascinated by these machines.',0
T_LOV5N003	LABEL	BYTE
	DB	'#LOV5\LOV5N003#Ensign Ferris is wondering when they''re going to '
	DB	'give him a tough assignment for a change.',0
T_LOV5_003	LABEL	BYTE
	DB	'#LOV5\LOV5_003#Hello, Carol. It''s good to see you again.',0
T_LOV5_048	LABEL	BYTE
	DB	'#LOV5\LOV5_048#There was a time when I wouldn''t have agreed with'
	DB	' that statement. But I guess some things do get better with age.',0
T_LOV5_009	LABEL	BYTE
	DB	'#LOV5\LOV5_009#You always could put me in my place, couldn''t you'
	DB	'?',0
T_LOV5_047	LABEL	BYTE
	DB	'#LOV5\LOV5_047#That''s the one thing I could never do. Your place'
	DB	' was wandering the galaxy, and that''s the one thing I could neve'
	DB	'r give you.',0
T_LOV5_036	LABEL	BYTE
	DB	'#LOV5\LOV5_036#Fascinating equipment. I believe I have seen this'
	DB	' sort of equipment someplace before.',0
T_LOV5_051	LABEL	BYTE
	DB	'#LOV5\LOV5_051#We''re testing the effect of radiation on combinat'
	DB	'ions of simple and complex molecules. We''re trying to see what n'
	DB	'ew forms of life are developed, and how they compare to our own '
	DB	'early development.',0
T_G_024	LABEL	BYTE
	DB	'#GENE\G_024#Fascinating.',0
T_LOV5_034	LABEL	BYTE
	DB	'#LOV5\LOV5_034#Fascinating. This device contains over ten millio'
	DB	'n forms of life. Patterns I have never seen before.',0
T_LOV5_049	LABEL	BYTE
	DB	'#LOV5\LOV5_049#We call this the Cradle, Mr. Spock. One day, I ho'
	DB	'pe, something wonderful will be produced here.',0
T_LOV5_025	LABEL	BYTE
	DB	'#LOV5\LOV5_025#They''ve been through a good deal of stress, but t'
	DB	'hey are already starting to recover. Their heart rate is droppin'
	DB	'g, and their blood pressure is also dropping.',0
N_dialog_error	LABEL	BYTE
	DB	'dialog error',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0
PreaxSpeaks	LABEL	BYTE
	DW	OFFSET N_Preax, OFFSET T_LOV5_059, 0	; speaker, choices, 0
KirkToPreax	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_LOV5_008, OFFSET T_LOV5_004, OFFSET T_LOV5_006, 0	; speaker, choices, 0
PreaxAnswers	LABEL	BYTE
	DW	OFFSET N_Preax, OFFSET T_LOV5_061, 0	; speaker, choices, 0
MarcusFarewell	LABEL	BYTE
	DW	OFFSET N_Dr_Marcus, OFFSET T_LOV5_043, 0	; speaker, choices, 0
KirkFarewell	LABEL	BYTE
	DW	OFFSET N_Preax, OFFSET T_LOV5_060, 0	; speaker, choices, 0
T_LOV5_059	LABEL	BYTE
	DB	'#LOV5\LOV5_059#I have called off the Romulan attack on this stat'
	DB	'ion, Kirk. I believed your virus was some kind of deliberate att'
	DB	'ack, but your great honor and compassion have convinced me other'
	DB	'wise.',0
T_LOV5_008	LABEL	BYTE
	DB	'#LOV5\LOV5_008#You also conducted yourself in the most honorable'
	DB	' fashion, Centurion Preax. You may return to Romulan space witho'
	DB	'ut Federation interference.',0
T_LOV5_004	LABEL	BYTE
	DB	'#LOV5\LOV5_004#I assure you, the Federation would never undertak'
	DB	'e such a foul program. It was all an accident, right, Dr. Marcus'
	DB	'?',0
T_LOV5_006	LABEL	BYTE
	DB	'#LOV5\LOV5_006#Save it for someone who''s buying, Preax. Leave Fe'
	DB	'deration space immediately or we''ll scatter your atoms across th'
	DB	'e quadrant.',0
T_LOV5_061	LABEL	BYTE
	DB	'#LOV5\LOV5_061#You are an honorable adversary, Kirk. Jolan-tru.',0
T_LOV5_043	LABEL	BYTE
	DB	'#LOV5\LOV5_043#Absolutely. We''ve already destroyed all cultures '
	DB	'and purged the data files. This will never happen again.',0
T_LOV5_060	LABEL	BYTE
	DB	'#LOV5\LOV5_060#Phah! And I thought you a man of honor... You nee'
	DB	'd not worry, Captain Kirk. Your lack of warrior spirit stinks ev'
	DB	'en across the vacuum of space, and I am eager to be free of it.',0
	DB	'Do wrapup and beam out here.',0
T_LOV0_011	LABEL	BYTE
	DB	'#LOV0\LOV0_011#Hee hee hee hee...',0
T_LOV0_020	LABEL	BYTE
	DB	'#LOV0\LOV0_020#The hills are alive... With the sounds of...',0
T_LOV0_016	LABEL	BYTE
	DB	'#LOV0\LOV0_016#Ooka! Ooka! Ooka!',0
T_LOV0_012	LABEL	BYTE
	DB	'#LOV0\LOV0_012#I think we''re all feeling just woooonderful!',0
T_LOV0_014	LABEL	BYTE
	DB	'#LOV0\LOV0_014#I''m floating up and up and up...',0
T_LOV0_022	LABEL	BYTE
	DB	'#LOV0\LOV0_022#This is how I want to feel all the time!',0
T_LOV0_015	LABEL	BYTE
	DB	'#LOV0\LOV0_015#I''m so happy, I want to hug the world!',0
T_LOV0_021	LABEL	BYTE
	DB	'#LOV0\LOV0_021#The moon in June''s a boon to tunes... er, somethi'
	DB	'ng like that.',0
T_LOV0_013	LABEL	BYTE
	DB	'#LOV0\LOV0_013#I''m a little teapot short and stout...',0
T_LOV0_019	LABEL	BYTE
	DB	'#LOV0\LOV0_019#Spock, ol'' buddy, ol'' friend, you look soo funny '
	DB	'standing there!',0
T_LOV0_017	LABEL	BYTE
	DB	'#LOV0\LOV0_017#Row, row, row, your boat. Aww, come on Spock.',0
T_LOV0_039	LABEL	BYTE
	DB	'#LOV0\LOV0_039#Hee hee hee hee...',0
T_LOV0_048	LABEL	BYTE
	DB	'#LOV0\LOV0_048#The hills are alive... With the sounds of...',0
T_LOV0_045	LABEL	BYTE
	DB	'#LOV0\LOV0_045#Ooka! Ooka! Ooka!',0
T_LOV0_040	LABEL	BYTE
	DB	'#LOV0\LOV0_040#I think we''re all feeling just woooonderful!',0
T_LOV0_042	LABEL	BYTE
	DB	'#LOV0\LOV0_042#I''m floating up and up and up...',0
T_LOV0_050	LABEL	BYTE
	DB	'#LOV0\LOV0_050#This is how I want to feel all the time!',0
T_LOV0_043	LABEL	BYTE
	DB	'#LOV0\LOV0_043#I''m so happy, I want to hug the world!',0
T_LOV0_049	LABEL	BYTE
	DB	'#LOV0\LOV0_049#The moon in June''s a boon to tunes... er, somethi'
	DB	'ng like that.',0
T_LOV0_041	LABEL	BYTE
	DB	'#LOV0\LOV0_041#I''m a little teapot short and stout...',0
T_LOV0_047	LABEL	BYTE
	DB	'#LOV0\LOV0_047#Spock, ol'' buddy, ol'' friend, you look soo funny '
	DB	'standing there!',0
T_LOV0_046	LABEL	BYTE
	DB	'#LOV0\LOV0_046#Row, row, row, your boat. Aww, come on Spock.',0
T_LOV0_029	LABEL	BYTE
	DB	'#LOV0\LOV0_029#Please, gentlemen, try to control yourselves',0
T_LOV0_033	LABEL	BYTE
	DB	'#LOV0\LOV0_033#Try taking deep breaths to clear your heads.',0
T_LOV0_026	LABEL	BYTE
	DB	'#LOV0\LOV0_026#I don''t believe you''d behave like this if you cou'
	DB	'ld avoid it.',0
T_LOV0_124	LABEL	BYTE
	DB	'#LOV0\LOV0_124#I''m trying to be patient, Captain.',0
T_LOV0_025	LABEL	BYTE
	DB	'#LOV0\LOV0_025#How many Admirals does it take to wire in a logic'
	DB	' transmogrifier?',0
T_LOV0_101	LABEL	BYTE
	DB	'#LOV0\LOV0_101#Fascinating. I am experiencing an urge to laugh.',0
T_LOV0_102	LABEL	BYTE
	DB	'#LOV0\LOV0_102#I am a Vulcan. I must resist these unchecked emot'
	DB	'ions.',0
T_LOV0_103	LABEL	BYTE
	DB	'#LOV0\LOV0_103#Logic...What happened to my logic?',0
T_LOV0_104	LABEL	BYTE
	DB	'#LOV0\LOV0_104#Jim, is this how you feel on shore leave?',0
T_LOV0_105	LABEL	BYTE
	DB	'#LOV0\LOV0_105#I remember my mother trying to tell me jokes when'
	DB	' I was a child. Now, I finally understand them.',0
T_LOV0_106	LABEL	BYTE
	DB	'#LOV0\LOV0_106#Romulan laughing gas. My father would never appro'
	DB	've.',0
T_LOV0_107	LABEL	BYTE
	DB	'#LOV0\LOV0_107#Why do they call you "Bones", doctor?',0

RDF	ENDS
	END
