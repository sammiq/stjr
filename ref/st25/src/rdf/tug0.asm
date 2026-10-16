; TUG0.RDF - "Hijacked", the transporter room of the Masada, taken by
; Elasi pirates. The Elasi bombed the transporter controls; Crewman
; Simpson lies stunned by the pad. McCoy revives him, which opens the
; cabinet with the Runcinate Transmogrifier. Spock repairs the controls
; with the transmogrifier fitted with a comb bit (welded from junk metal)
; and a length of wiring, setting them for just inside the bridge door.
; Then the pad beams the party onto the bridge (room 3). Beaming the bomb
; there instead destroys the ship, hostages and all: the mission's
; failure ending.
;
; Actors: 8 Simpson, 9 the cabinet, 10 (0Ah) the bomb, 11 (0Bh) the
; controls.
; Objects: 8 Simpson, 9 the cabinet, 0Bh/21h the controls, 22h the pad,
; 23h the door.
; Exit 0: the door (room 1). Timer 0: after the bomb.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 2675: the engine reads its bytes
;   as key 50 B8 03 00 and next 2E50 (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
score	EQU	RS_VARS+0	; word: the mission's score
max_score	EQU	RS_VARS+2	; word: for the debriefing
outcome	EQU	RS_VARS+4	; word: 1 the ship was blown up (BeamUp)
revived_simpson	EQU	RS_VARS+7
took_transmogrifier	EQU	RS_VARS+1Ah
transporter_fixed	EQU	RS_VARS+1Bh
spock_assessed	EQU	RS_VARS+1Ch	; Spock has looked at the controls
transmogrifier_fitted	EQU	RS_VARS+1Dh	; the transmogrifier is in the controls; the wiring is next
found_bomb	EQU	RS_VARS+20h	; room 2

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0C7h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	83h
rdf_scale_min	LABEL	BYTE
	DW	0F6h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	14Ah
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	1, -1, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	274,173, 147,188	; entrance 0, crew 0
	DW	287,170, 252,166	; entrance 0, crew 1
	DW	291,173, 288,173	; entrance 0, crew 2
	DW	311,181, 210,162	; entrance 0, crew 3
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
	DW	98,127, 154,126, 123,122, 74,125	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	98,127, 154,126, 123,122, 74,125
	DB	0A8h, 26h, 0A8h, 26h
rdf_objects	LABEL	BYTE
	DW	20h, 4	; id, points
	DW	6,155, 15,151, 15,161, 6,166
	DW	21h, 4	; id, points
	DW	220,134, 272,130, 290,148, 240,157
	DW	22h, 6	; id, points
	DW	67,120, 173,121, 207,126, 206,130, 152,136, 67,134
	DW	23h, 4	; id, points
	DW	292,93, 319,93, 319,173, 294,165

rdf_scripts:
rdf_objects_end:
; The room starts: the controls (lit once repaired), Simpson lying or
; sitting up, the cabinet closed or open (empty once Kirk has the tool).
H_0126:
	SCRIPT	MSG_TICK, 1, 0, 0, H_022E
StartRoom:
	jmp	SHORT L0137

N_TUG0LOOP	LABEL	BYTE
	DB	'TUG0LOOP',0
L0137:
	push	OFFSET N_TUG0LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("TUG0LOOP")
	add	sp, 4
	mov	ax, -1
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(0, -1)
	add	sp, 6
	mov	word ptr [si+max_score], 23h
	cmp	byte ptr [si+transporter_fixed], 1
	jne	L0185
	jmp	SHORT L016E

N_t0con2	LABEL	BYTE
	DB	't0con2',0
L016E:
	push	0
	push	0C2h
	push	105h
	push	OFFSET N_t0con2
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "t0con2", 261, 194, 0)
	add	sp, 0Ch
L0185:
	cmp	byte ptr [si+revived_simpson], 0
	jne	L01AB
	jmp	SHORT L0194

N_tcdown	LABEL	BYTE
	DB	'tcdown',0
L0194:
	push	0
	push	0A8h
	push	27h
	push	OFFSET N_tcdown
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "tcdown", 39, 168, 0)
	add	sp, 0Ch
	retf

L01AB:
	jmp	SHORT L01B3

N_tcupd	LABEL	BYTE
	DB	'tcupd',0
L01B3:
	push	0
	push	0A8h
	push	27h
	push	OFFSET N_tcupd
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "tcupd", 39, 168, 0)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+took_transmogrifier], 1
	jne	L01F4
	jmp	SHORT L01DD

N_pempty	LABEL	BYTE
	DB	'pempty',0
L01DD:
	push	0
	push	0A9h
	push	27h
	push	OFFSET N_pempty
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "pempty", 39, 169, 0)
	add	sp, 0Ch
	retf

L01F4:
	jmp	SHORT L01FD

N_popend	LABEL	BYTE
	DB	'popend',0
L01FD:
	push	0
	push	0A9h
	push	27h
	push	OFFSET N_popend
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "popend", 39, 169, 0)
	add	sp, 0Ch
	jmp	SHORT L021D

N_MUR4E6S	LABEL	BYTE
	DB	'MUR4E6S',0
L021D:
	push	OFFSET N_MUR4E6S
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR4E6S")
	add	sp, 4
	retf

	DB	0CBh

; Simpson.
H_022E:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_02D0
LookAtSimpson:
	cmp	byte ptr [si+revived_simpson], 1
	jne	L0266
	mov	ax, 0
	mov	bx, OFFSET T_TUG0N002
	call	Say
	jmp	SHORT L0265

T_TUG0N002	LABEL	BYTE
	DB	'#TUG0\TUG0N002#Crewman Simpson.',0
L0265:
	retf

L0266:
	mov	ax, 0
	mov	bx, OFFSET T_TUG0N014
	call	Say
	jmp	SHORT L02CF

T_TUG0N014	LABEL	BYTE
	DB	'#TUG0\TUG0N014#This man was obviously the transporter engineer. '
	DB	'He is unconscious, but alive.',0
L02CF:
	retf

H_02D0:
	SCRIPT	MSG_GET, 8, 0, 0, H_0318
GetSimpson:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG0_019
	call	Say
	jmp	SHORT L0317

T_TUG0_019	LABEL	BYTE
	DB	'#TUG0\TUG0_019#I don''t think he should be moved, Jim.',0
L0317:
	retf

; The controls.
H_0318:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_0320
	jmp	SHORT LookAtControls

H_0320:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_03FF
LookAtControls:
	cmp	byte ptr [si+transporter_fixed], 1
	jne	L03A5
	mov	ax, 0
	mov	bx, OFFSET T_TUG0N012
	call	Say
	jmp	SHORT L03A4

T_TUG0N012	LABEL	BYTE
	DB	'#TUG0\TUG0N012#These transporter controls are now operational. T'
	DB	'hey are set for just inside the bridge door.',0
L03A4:
	retf

L03A5:
	mov	ax, 0
	mov	bx, OFFSET T_TUG0N001
	call	Say
	jmp	SHORT L03FE

T_TUG0N001	LABEL	BYTE
	DB	'#TUG0\TUG0N001#A small bomb appears to have damaged the transpor'
	DB	'ter controls.',0
L03FE:
	retf

; Spock looks at the controls (msgs 16, 17): only a jury-rig will do.
H_03FF:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_042A
SpockUsesControls:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL+1], 2
	mov	ax, 10h
	push	ax
	mov	ax, 0C5h
	push	ax
	mov	ax, 0DBh
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 219, 197, 16)
	add	sp, 0Ah
	retf

H_042A:
	SCRIPT	MSG_WALK_DONE, 10h, 0, 0, H_045F
SpockAtControls:
	jmp	SHORT L0439

N_sscane	LABEL	BYTE
	DB	'sscane',0
L0439:
	push	11h
	push	-1
	push	-1
	push	OFFSET N_sscane
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscane", -1, -1, 17)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	retf

H_045F:
	SCRIPT	MSG_ANIM_DONE, 11h, 0, 0, H_070A
SpockAssesses:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG0_040
	call	Say
	jmp	SHORT L04B4

T_TUG0_040	LABEL	BYTE
	DB	'#TUG0\TUG0_040#The controls have been virtually destroyed, Capta'
	DB	'in.',0
L04B4:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG0_005
	call	Say
	jmp	SHORT L04EB

T_TUG0_005	LABEL	BYTE
	DB	'#TUG0\TUG0_005#Can they be repaired, Spock?',0
L04EB:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG0_043
	call	Say
	jmp	SHORT L056F

T_TUG0_043	LABEL	BYTE
	DB	'#TUG0\TUG0_043#With chief Engineer Scott''s assistance, I believe'
	DB	' we could get them in perfect working order in two days.',0
L056F:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG0_013
	call	Say
	JMPN	L0610

T_TUG0_013	LABEL	BYTE
	DB	'#TUG0\TUG0_013#Spock, we don''t have two days. If we can repair t'
	DB	'he transporter, we might be able to transport onto the bridge an'
	DB	'd capture the Elasi.',0
L0610:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG0_038
	call	Say
	JMPN	L06A2

T_TUG0_038	LABEL	BYTE
	DB	'#TUG0\TUG0_038#I can attempt to jury-rig repairs if I can find p'
	DB	'arts. However, there is only a 67.357 percent probability of suc'
	DB	'cess.',0
L06A2:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG0_008
	call	Say
	jmp	SHORT L06FC

T_TUG0_008	LABEL	BYTE
	DB	'#TUG0\TUG0_008#I''ve always been a gambler, Spock. Figure out wha'
	DB	't you''ll need.',0
L06FC:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+spock_assessed], 1
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Repairing the controls: the transmogrifier needs its comb bit first;
; with it, Spock fits it (msgs 6, 7), then needs wiring (the scraps are
; too short), and wires them up (msgs 8, 9). +1 score each step. Then
; Christensen sums up the plan of attack.
H_070A:
	SCRIPT	MSG_USE, IT_RT, 21h, 0, H_0792
UseTransmogrifierOnControls:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG0_014
	call	Say
	jmp	SHORT L0791

T_TUG0_014	LABEL	BYTE
	DB	'#TUG0\TUG0_014#Captain, I need to find a bit that will fit into '
	DB	'the transmogrifier before I can go further with this.',0
L0791:
	retf

H_0792:
	SCRIPT	MSG_USE, IT_RTWB, 21h, 0, H_07BD
UseFittedTransmogrifier:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL+1], 2
	mov	ax, 6
	push	ax
	mov	ax, 0C5h
	push	ax
	mov	ax, 0DBh
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 219, 197, 6)
	add	sp, 0Ah
	retf

H_07BD:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_084F
SpockFitsIt:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG0_029
	call	Say
	jmp	SHORT L0820

T_TUG0_029	LABEL	BYTE
	DB	'#TUG0\TUG0_029#I attach these here... Now all I need is a spare '
	DB	'length of wiring.',0
L0820:
	jmp	SHORT L0829

N_susehn	LABEL	BYTE
	DB	'susehn',0
L0829:
	push	7
	push	-1
	push	-1
	push	OFFSET N_susehn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susehn", -1, -1, 7)
	add	sp, 0Ch
	mov	ax, 0Bh
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(11)
	add	sp, 4
	retf

H_084F:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_0873
TransmogrifierFitted:
	push	IT_RTWB
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_RTWB)
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+transmogrifier_fitted], 1
	mov	byte ptr [si+RS_BUSY], 0
	add	word ptr [si+score], 1
	retf

H_0873:
	SCRIPT	MSG_ANIM_DONE, 16h, 0, 0, H_089A
ControlsLit:
	jmp	SHORT L0882

N_t0con2_2	LABEL	BYTE
	DB	't0con2',0
L0882:
	push	0
	push	0C2h
	push	105h
	push	OFFSET N_t0con2_2
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "t0con2", 261, 194, 0)
	add	sp, 0Ch
	retf

H_089A:
	SCRIPT	MSG_USE, IT_WIRSCRP, 21h, 0, H_0901
UseWireScrapsOnControls:
	cmp	byte ptr [si+transmogrifier_fitted], 1
	je	L08A9
	JMPN	L0931

L08A9:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG0_034
	call	Say
	jmp	SHORT L0900

T_TUG0_034	LABEL	BYTE
	DB	'#TUG0\TUG0_034#The bits are not long enough, I need a longer pie'
	DB	'ce of wire.',0
L0900:
	retf

H_0901:
	SCRIPT	MSG_USE, IT_WIRING, 21h, 0, H_0932
UseWiringOnControls:
	cmp	byte ptr [si+transmogrifier_fitted], 1
	jne	L0931
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL+1], 2
	mov	ax, 8
	push	ax
	mov	ax, 0C5h
	push	ax
	mov	ax, 0DBh
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 219, 197, 8)
	add	sp, 0Ah
L0931:
	retf

H_0932:
	SCRIPT	MSG_WALK_DONE, 8, 0, 0, H_0957
SpockWires:
	jmp	SHORT L0941

N_susehn_2	LABEL	BYTE
	DB	'susehn',0
L0941:
	push	9
	push	-1
	push	-1
	push	OFFSET N_susehn_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susehn", -1, -1, 9)
	add	sp, 0Ch
	retf

H_0957:
	SCRIPT	MSG_ANIM_DONE, 9, 0, 0, H_0E6E
ControlsRepaired:
	mov	byte ptr [si+RS_BUSY], 0
	push	IT_WIRING
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_WIRING)
	add	sp, 4
	add	word ptr [si+score], 1
	jmp	SHORT L097A

N_t0con1	LABEL	BYTE
	DB	't0con1',0
L097A:
	push	16h
	push	0C2h
	push	105h
	push	OFFSET N_t0con1
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "t0con1", 261, 194, 22)
	add	sp, 0Ch
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG0_039
	call	Say
	jmp	SHORT L09E9

T_TUG0_039	LABEL	BYTE
	DB	'#TUG0\TUG0_039#The controls are set for just inside the bridge d'
	DB	'oor Captain.',0
L09E9:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+transporter_fixed], 1
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG0_010
	call	Say
	jmp	SHORT L0A28

T_TUG0_010	LABEL	BYTE
	DB	'#TUG0\TUG0_010#Mr. Spock, you''re a genius!',0
L0A28:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG0_022
	call	Say
	JMPN	L0AEC

T_TUG0_022	LABEL	BYTE
	DB	'#TUG0\TUG0_022#I wouldn''t go that far, Jim. But I do have to con'
	DB	'gratulate you, Mr. Spock. Now we can really risk shooting our at'
	DB	'oms around the universe. Is this really necessary, Jim?',0
L0AEC:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG0_002
	call	Say
	jmp	SHORT L0B20

T_TUG0_002	LABEL	BYTE
	DB	'#TUG0\TUG0_002#Analysis, Lt. Christensen',0
L0B20:
	mov	ax, OFFSET N_Lt_Christensen
	mov	bx, OFFSET T_TUG0L009
	call	Say
	JMPN	L0BCC

T_TUG0L009	LABEL	BYTE
	DB	'#TUG0\TUG0L009#Security analysis, sir: if we transport onto the '
	DB	'bridge, we''ll have the drop on them -- assuming Mr. Spock has th'
	DB	'e transporter working porperly.',0
L0BCC:
	mov	ax, OFFSET N_Lt_Christensen
	mov	bx, OFFSET T_TUG0L008
	call	Say
	jmp	SHORT L0C52

T_TUG0L008	LABEL	BYTE
	DB	'#TUG0\TUG0L008#If we could get past the forcefield on the door o'
	DB	'f the bridge, we should be able to surprise them for sure.',0
L0C52:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+found_bomb], 1
	je	L0C60
	JMPN	L0DEA

L0C60:
	mov	ax, OFFSET N_Lt_Christensen
	mov	bx, OFFSET T_TUG0L010
	call	Say
	JMPN	L0D19

T_TUG0L010	LABEL	BYTE
	DB	'#TUG0\TUG0L010#Since we have a bomb, Captain, we could rearm it,'
	DB	' transport it onto the bridge, and perhaps the Elasi will flee i'
	DB	'nto the hallway. Then we could capture them.',0
L0D19:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG0_021
	call	Say
	jmp	SHORT L0D92

T_TUG0_021	LABEL	BYTE
	DB	'#TUG0\TUG0_021#And any hostages on the bridge will be killed whe'
	DB	'n the bomb goes off! No, Jim, that''s inhuman!',0
L0D92:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG0_041
	call	Say
	jmp	SHORT L0DEA

T_TUG0_041	LABEL	BYTE
	DB	'#TUG0\TUG0_041#To say nothing of the possible damage to the brid'
	DB	'ge controls.',0
L0DEA:
	retf

	DB	0B8h, 0BDh, 26h, 0BBh, 0F6h, 0Dh, 0E8h, 8Fh, 18h, 0EBh
	DB	'w#TUG0\TUG0_033#I''ll be able to use this later, so I want to kee'
	DB	'p it -- but I need to get some equipment in here first.',0
	DB	0CBh

; McCoy revives Simpson (msgs 2, 13, 1), +1 score: he tells them about
; the cabinet, which opens.
H_0E6E:
	SCRIPT	MSG_USE, IT_MEDKIT, 8, 0, H_0E9F
HealSimpson:
	cmp	byte ptr [si+revived_simpson], 1
	je	L0E9E
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL+2], 0
	mov	ax, 2
	push	ax
	mov	ax, 0AFh
	push	ax
	mov	ax, 2Dh
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 45, 175, 2)
	add	sp, 0Ah
L0E9E:
	retf

H_0E9F:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_0EC4
McCoyAtSimpson:
	jmp	SHORT L0EAE

N_museln	LABEL	BYTE
	DB	'museln',0
L0EAE:
	push	0Dh
	push	-1
	push	-1
	push	OFFSET N_museln
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "museln", -1, -1, 13)
	add	sp, 0Ch
	retf

H_0EC4:
	SCRIPT	MSG_ANIM_DONE, 0Dh, 0, 0, H_0F10
SimpsonWakes:
	jmp	SHORT L0ED1

N_tcup	LABEL	BYTE
	DB	'tcup',0
L0ED1:
	push	1
	push	0A8h
	push	27h
	push	OFFSET N_tcup
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "tcup", 39, 168, 1)
	add	sp, 0Ch
	mov	byte ptr [si+RS_FALL+2], 2
	mov	ax, 0
	push	ax
	mov	ax, 0AFh
	push	ax
	mov	ax, 41h
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 65, 175, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 0
	add	word ptr [si+score], 1
	retf

H_0F10:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_1040
SimpsonSitsUp:
	mov	ax, OFFSET N_Crewman_Simpson
	mov	bx, OFFSET T_TUG0_F31
	call	Say
	JMPN	L0FBA

T_TUG0_F31	LABEL	BYTE
	DB	'#TUG0\TUG0_F31#Thank you, Doctor. Be careful, Captain, the Elasi'
	DB	' like to set boobytraps. if you need any equipment I''ve got my t'
	DB	'ools in this workspace.',0
L0FBA:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+revived_simpson], 1
	jmp	SHORT L0FCC

N_tcshow	LABEL	BYTE
	DB	'tcshow',0
L0FCC:
	push	0
	push	0A8h
	push	27h
	push	OFFSET N_tcshow
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "tcshow", 39, 168, 0)
	add	sp, 0Ch
	jmp	SHORT L0FEA

N_popen	LABEL	BYTE
	DB	'popen',0
L0FEA:
	push	0
	push	0A9h
	push	27h
	push	OFFSET N_popen
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "popen", 39, 169, 0)
	add	sp, 0Ch
	jmp	SHORT L100A

N_MUR4E6S_2	LABEL	BYTE
	DB	'MUR4E6S',0
L100A:
	push	OFFSET N_MUR4E6S_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR4E6S")
	add	sp, 4
	retf

	DB	'tcup',0
	DB	'tcupd',0
	DB	'tcshow',0
	DB	'popen',0
	DB	'popend',0
	DB	'pempty',0

; Taking the transmogrifier from the cabinet (msgs 3, 4), +1 score.
H_1040:
	SCRIPT	MSG_GET, 9, 0, 0, H_1073
GetTransmogrifier:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+took_transmogrifier], 0
	jne	L1072
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 3
	push	ax
	mov	ax, 0B1h
	push	ax
	mov	ax, 1Eh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 30, 177, 3)
	add	sp, 0Ah
	retf

L1072:
	retf

H_1073:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_1098
KirkAtCabinet:
	jmp	SHORT L1082

N_kuselw	LABEL	BYTE
	DB	'kuselw',0
L1082:
	push	4
	push	-1
	push	-1
	push	OFFSET N_kuselw
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuselw", -1, -1, 4)
	add	sp, 0Ch
	retf

H_1098:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_10EB
TookTransmogrifier:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+took_transmogrifier], 1
	push	IT_RT
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_RT)
	add	sp, 4
	jmp	SHORT L10BC

N_pempty_2	LABEL	BYTE
	DB	'pempty',0
L10BC:
	push	0
	push	0A9h
	push	27h
	push	OFFSET N_pempty_2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "pempty", 39, 169, 0)
	add	sp, 0Ch
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	add	word ptr [si+score], 1
	retf

H_10EB:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_11F2
LookAtCabinet:
	cmp	byte ptr [si+took_transmogrifier], 0
	je	L10FA
	JMPN	L11C1

L10FA:
	mov	ax, 0
	mov	bx, OFFSET T_TUG0N000
	call	Say
	JMPN	L11C0

T_TUG0N000	LABEL	BYTE
	DB	'#TUG0\TUG0N000#A Runcinate Transmogrifier: An engineering tool u'
	DB	'sed in the maintainance of transporters, which can be fitted wit'
	DB	'h bits having a variety of irregularly serrated surfaces.',0
L11C0:
	retf

L11C1:
	mov	ax, 0
	mov	bx, OFFSET T_TUG0N008
	call	Say
	jmp	SHORT L11F1

T_TUG0N008	LABEL	BYTE
	DB	'#TUG0\TUG0N008#The cabinet is empty.',0
L11F1:
	retf

; Inventory: phaser + empty welder = charged welder; welder + junk metal
; = comb bit (wire scraps just melt); comb bit + transmogrifier.
H_11F2:
	SCRIPT	MSG_USE, IT_PHASERS, IT_PWE, 0, H_11FA
	jmp	SHORT ChargeWelder

H_11FA:
	SCRIPT	MSG_USE, IT_PHASERK, IT_PWE, 0, H_1251
ChargeWelder:
	push	IT_PWE
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_PWE)
	add	sp, 4
	push	IT_PWF
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_PWF)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_TUG0N006
	call	Say
	jmp	SHORT L1250

T_TUG0N006	LABEL	BYTE
	DB	'#TUG0\TUG0N006#Phaser Welder is now charged.',0
L1250:
	retf

H_1251:
	SCRIPT	MSG_USE, IT_PWF, IT_WIRSCRP, 0, H_12E2
WeldWireScraps:
	mov	ax, 0
	mov	bx, OFFSET T_TUG0N010
	call	Say
	jmp	SHORT L12D5

T_TUG0N010	LABEL	BYTE
	DB	'#TUG0\TUG0N010#The wire scraps are too small, they melt instead '
	DB	'of fusing together, and you''re left with nothing. ',0
L12D5:
	push	IT_WIRSCRP
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_WIRSCRP)
	add	sp, 4
	retf

H_12E2:
	SCRIPT	MSG_USE, IT_PWF, IT_JNKMETL, 0, H_1390
WeldJunkMetal:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG0_032
	call	Say
	JMPN	L1377

T_TUG0_032	LABEL	BYTE
	DB	'#TUG0\TUG0_032#I think that does it -- a Comb Bit for the transm'
	DB	'ogrifier. Now I can continue repairs on the transporter controls'
	DB	'. ',0
L1377:
	push	IT_JNKMETL
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_JNKMETL)
	add	sp, 4
	push	IT_COMBBIT
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_COMBBIT)
	add	sp, 4
	retf

H_1390:
	SCRIPT	MSG_USE, IT_COMBBIT, IT_RT, 0, H_13FC
FitCombBit:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG0_035
	call	Say
	jmp	SHORT L13D7

T_TUG0_035	LABEL	BYTE
	DB	'#TUG0\TUG0_035#The parts fit together satisfactorily.',0
L13D7:
	push	IT_COMBBIT
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_COMBBIT)
	add	sp, 4
	push	IT_RT
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_RT)
	add	sp, 4
	push	IT_RTWB
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_RTWB)
	add	sp, 4
	retf

; The pad, once the controls are fixed: everyone onto it, Spock energizes
; (msgs 14, 18, 20, 21), +3 score, and they appear on the bridge.
H_13FC:
	SCRIPT	MSG_USE, OBJ_SPOCK, 0Bh, 0, H_1404
	jmp	SHORT UsePad

H_1404:
	SCRIPT	MSG_USE, OBJ_KIRK, 22h, 0, H_1498
UsePad:
	cmp	byte ptr [si+transporter_fixed], 1
	je	L1413
	JMPN	L1497

L1413:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 1
	mov	ax, 0
	push	ax
	mov	ax, 7Fh
	push	ax
	mov	ax, 62h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 98, 127, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+1], 3
	mov	ax, 0Eh
	push	ax
	mov	ax, 0C7h
	push	ax
	mov	ax, 11Eh
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 286, 199, 14)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+2], 1
	mov	ax, 0
	push	ax
	mov	ax, 7Ah
	push	ax
	mov	ax, 7Bh
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 123, 122, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+3], 1
	mov	ax, 0
	push	ax
	mov	ax, 7Dh
	push	ax
	mov	ax, 4Ah
	push	ax
	mov	ax, 3
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(3, 74, 125, 0)
	add	sp, 0Ah
L1497:
	retf

H_1498:
	SCRIPT	MSG_WALK_DONE, 0Eh, 0, 0, H_14DD
SpockAtControls2:
	jmp	SHORT L14A7

N_susehw	LABEL	BYTE
	DB	'susehw',0
L14A7:
	push	12h
	push	-1
	push	-1
	push	OFFSET N_susehw
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susehw", -1, -1, 18)
	add	sp, 0Ch
	mov	ax, 7
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(7)
	add	sp, 4
	mov	ax, 0Ah
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(10)
	add	sp, 4
	retf

H_14DD:
	SCRIPT	MSG_ANIM_DONE, 12h, 0, 0, H_1565
SpockEnergizes:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG0_001
	call	Say
	jmp	SHORT L1544

T_TUG0_001	LABEL	BYTE
	DB	'#TUG0\TUG0_001#I''m going to have a word for you, Spock, if we ap'
	DB	'pear inside the door!',0
L1544:
	mov	byte ptr [si+RS_FALL+1], 1
	mov	ax, 14h
	push	ax
	mov	ax, 7Eh
	push	ax
	mov	ax, 9Ah
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 154, 126, 20)
	add	sp, 0Ah
	retf

H_1565:
	SCRIPT	MSG_WALK_DONE, 14h, 0, 0, H_15FA
EveryoneOnPad:
	mov	ax, 8
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(8)
	add	sp, 4
	jmp	SHORT L1584

N_kteled	LABEL	BYTE
	DB	'kteled',0
L1584:
	push	15h
	push	-1
	push	-1
	push	OFFSET N_kteled
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kteled", -1, -1, 21)
	add	sp, 0Ch
	jmp	SHORT L15A2

N_steled	LABEL	BYTE
	DB	'steled',0
L15A2:
	push	15h
	push	-1
	push	-1
	push	OFFSET N_steled
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "steled", -1, -1, 21)
	add	sp, 0Ch
	jmp	SHORT L15C0

N_mteled	LABEL	BYTE
	DB	'mteled',0
L15C0:
	push	15h
	push	-1
	push	-1
	push	OFFSET N_mteled
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mteled", -1, -1, 21)
	add	sp, 0Ch
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 0
	jne	L15F9
	jmp	SHORT L15E4

N_rteled	LABEL	BYTE
	DB	'rteled',0
L15E4:
	push	15h
	push	-1
	push	-1
	push	OFFSET N_rteled
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rteled", -1, -1, 21)
	add	sp, 0Ch
L15F9:
	retf

H_15FA:
	SCRIPT	MSG_ANIM_DONE, 15h, 0, 0, H_1614
BeamedToBridge:
	add	word ptr [si+score], 3
	mov	byte ptr [si+RS_BUSY], 1
	push	4
	push	3
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(3, 4)
	retf

; The bomb on the pad, once the controls are fixed: Kirk puts it there,
; Spock beams it to the bridge (msgs 5, 10, 11, 15, 19, 12). Timer 0:
; the Masada is destroyed; score 0, outcome 1.
H_1614:
	SCRIPT	MSG_USE, IT_BOMB, 22h, 0, H_1681
UseBombOnPad:
	cmp	byte ptr [si+transporter_fixed], 1
	jne	L1680
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 5
	push	ax
	mov	ax, 7Fh
	push	ax
	mov	ax, 62h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 98, 127, 5)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+2], 0
	mov	ax, 0
	push	ax
	mov	ax, 0BEh
	push	ax
	mov	ax, 46h
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 70, 190, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+3], 0
	mov	ax, 0
	push	ax
	mov	ax, 0BEh
	push	ax
	mov	ax, 78h
	push	ax
	mov	ax, 3
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(3, 120, 190, 0)
	add	sp, 0Ah
L1680:
	retf

H_1681:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_16A6
KirkAtPad:
	jmp	SHORT L1690

N_kpickw	LABEL	BYTE
	DB	'kpickw',0
L1690:
	push	0Ah
	push	-1
	push	-1
	push	OFFSET N_kpickw
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kpickw", -1, -1, 10)
	add	sp, 0Ch
	retf

H_16A6:
	SCRIPT	MSG_ANIM_DONE, 0Ah, 0, 0, H_1716
BombOnPad:
	push	IT_BOMB
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_BOMB)
	add	sp, 4
	jmp	SHORT L16C0

N_bomb1	LABEL	BYTE
	DB	'bomb1',0
L16C0:
	push	0
	push	7Fh
	push	5Ah
	push	OFFSET N_bomb1
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "bomb1", 90, 127, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 0Bh
	push	ax
	mov	ax, 0BEh
	push	ax
	mov	ax, 0C8h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 200, 190, 11)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+1], 3
	mov	ax, 0Fh
	push	ax
	mov	ax, 0C7h
	push	ax
	mov	ax, 11Eh
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 286, 199, 15)
	add	sp, 0Ah
	retf

H_1716:
	SCRIPT	MSG_WALK_DONE, 0Fh, 0, 0, H_175B
SpockAtControls3:
	jmp	SHORT L1725

N_susehw_2	LABEL	BYTE
	DB	'susehw',0
L1725:
	push	13h
	push	-1
	push	-1
	push	OFFSET N_susehw_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susehw", -1, -1, 19)
	add	sp, 0Ch
	mov	ax, 7
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(7)
	add	sp, 4
	mov	ax, 0Ah
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(10)
	add	sp, 4
	retf

H_175B:
	SCRIPT	MSG_ANIM_DONE, 13h, 0, 0, H_178F
BombBeamed:
	mov	ax, 8
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(8)
	add	sp, 4
	jmp	SHORT L1779

N_bomb2	LABEL	BYTE
	DB	'bomb2',0
L1779:
	push	0Ch
	push	7Fh
	push	5Ah
	push	OFFSET N_bomb2
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "bomb2", 90, 127, 12)
	add	sp, 0Ch
	retf

H_178F:
	SCRIPT	MSG_ANIM_DONE, 0Ch, 0, 0, H_17B3
BombExplodes:
	mov	ax, 14h
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(20)
	add	sp, 4
	add	word ptr [si+score], 0
	mov	word ptr [si+score], 0
	mov	word ptr [si+RS_TIMERS], 40h
	retf

H_17B3:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_1A00
ShipDestroyed:
	mov	ax, -1
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(2, -1)
	add	sp, 6
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG0_023
	call	Say
	jmp	SHORT L1848

T_TUG0_023	LABEL	BYTE
	DB	'#TUG0\TUG0_023#My God Jim, what have you done! You killed them a'
	DB	'll. You probably blew up the whole damn bridge.',0
L1848:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG0_037
	call	Say
	jmp	SHORT L18D2

T_TUG0_037	LABEL	BYTE
	DB	'#TUG0\TUG0_037#Captain, the ship will crash into the planet in 1'
	DB	'8.32 seconds, I would recommend, leaving the ship immediately.',0
L18D2:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG0_027
	call	Say
	jmp	SHORT L190C

T_TUG0_027	LABEL	BYTE
	DB	'#TUG0\TUG0_027#You cold blooded emotionless...',0
L190C:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG0_004
	call	Say
	jmp	SHORT L1948

T_TUG0_004	LABEL	BYTE
	DB	'#TUG0\TUG0_004#Bones, later. Kirk to Enterprise.',0
L1948:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_TUG0_S11
	call	Say
	jmp	SHORT L1979

T_TUG0_S11	LABEL	BYTE
	DB	'#TUG0\TUG0_S11#Captain, you''re alive!',0
L1979:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG0_003
	call	Say
	jmp	SHORT L19A8

T_TUG0_003	LABEL	BYTE
	DB	'#TUG0\TUG0_003#Beam us out of here.',0
L19A8:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_TUG0_S06
	call	Say
	jmp	SHORT L19CF

T_TUG0_S06	LABEL	BYTE
	DB	'#TUG0\TUG0_S06#Aye Captain.',0
L19CF:
	mov	byte ptr [si+RS_BUSY], 0
	mov	word ptr [si+outcome], 1
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, word ptr [si+score]
	and	ax, -8000h
	AX8	cmp, 0
	je	L19EC
	mov	word ptr [si+score], 0
L19EC:
	push	word ptr [si+outcome]
	push	word ptr [si+max_score]
	push	word ptr [si+score]
	push	RC_BEAMUP
	SERVICE		; BeamUp(?, ?, ?)
	add	sp, 8
	retf

; Tricorders.
H_1A00:
	SCRIPT	MSG_USE, OBJ_MCCOY, 21h, 0, H_1A08
	jmp	SHORT McCoyScansControls

H_1A08:
	SCRIPT	MSG_USE, IT_MTRICOR, 21h, 0, H_1A8F
McCoyScansControls:
	mov	byte ptr [si+RS_FALL+2], 1
	jmp	SHORT L1A1B

N_mscans	LABEL	BYTE
	DB	'mscans',0
L1A1B:
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
	mov	bx, OFFSET T_TUG0_016
	call	Say
	jmp	SHORT L1A8E

T_TUG0_016	LABEL	BYTE
	DB	'#TUG0\TUG0_016#Damn it, Jim. I''m a doctor, not a rocket scientis'
	DB	't.',0
L1A8E:
	retf

H_1A8F:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_1B4B
SpockScansControls:
	jmp	SHORT L1A9E

N_sscans	LABEL	BYTE
	DB	'sscans',0
L1A9E:
	push	17h
	push	-1
	push	-1
	push	OFFSET N_sscans
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscans", -1, -1, 23)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG0_015
	call	Say
	jmp	SHORT L1B4A

T_TUG0_015	LABEL	BYTE
	DB	'#TUG0\TUG0_015#Even our most efficient Chief Engineer Scott woul'
	DB	'd have trouble repairing this damage in less than two days.',0
L1B4A:
	retf

H_1B4B:
	SCRIPT	MSG_USE, IT_MTRICOR, 8, 0, H_1B76
McCoyScansSimpson:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL+2], 0
	mov	ax, 18h
	push	ax
	mov	ax, 0AFh
	push	ax
	mov	ax, 2Dh
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 45, 175, 24)
	add	sp, 0Ah
	retf

H_1B76:
	SCRIPT	MSG_WALK_DONE, 18h, 0, 0, H_1BAB
McCoyAtSimpson2:
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	jmp	SHORT L1B95

N_mscann	LABEL	BYTE
	DB	'mscann',0
L1B95:
	push	19h
	push	-1
	push	-1
	push	OFFSET N_mscann
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscann", -1, -1, 25)
	add	sp, 0Ch
	retf

H_1BAB:
	SCRIPT	MSG_ANIM_DONE, 19h, 0, 0, H_1C8D
SimpsonScanned:
	cmp	byte ptr [si+revived_simpson], 1
	jne	L1C27
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG0_017
	call	Say
	jmp	SHORT L1C02

T_TUG0_017	LABEL	BYTE
	DB	'#TUG0\TUG0_017#He will be all right, but we shouldn''t move him.',0
L1C02:
	mov	byte ptr [si+RS_FALL+2], 3
	mov	ax, 1Ah
	push	ax
	mov	ax, 0AFh
	push	ax
	mov	ax, 41h
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 65, 175, 26)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 0
	retf

L1C27:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG0_018
	call	Say
	jmp	SHORT L1C68

T_TUG0_018	LABEL	BYTE
	DB	'#TUG0\TUG0_018#He''s not hurt badly. I can revive him.',0
L1C68:
	mov	byte ptr [si+RS_FALL+2], 3
	mov	ax, 1Ah
	push	ax
	mov	ax, 0AFh
	push	ax
	mov	ax, 41h
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 65, 175, 26)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_1C8D:
	SCRIPT	MSG_WALK_DONE, 1Ah, 0, 0, H_1C94
McCoyBack:
	retf

H_1C94:
	SCRIPT	MSG_USE, OBJ_SPOCK, 8, 0, H_1C9C
	jmp	SHORT SpockScansSimpson

H_1C9C:
	SCRIPT	MSG_USE, IT_STRICOR, 8, 0, H_1D2A
SpockScansSimpson:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L1CAF

N_sscans_2	LABEL	BYTE
	DB	'sscans',0
L1CAF:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscans_2
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
	mov	bx, OFFSET T_TUG0_030
	call	Say
	jmp	SHORT L1D29

T_TUG0_030	LABEL	BYTE
	DB	'#TUG0\TUG0_030#I believe this would be in Dr. McCoy''s field of e'
	DB	'xpertise.',0
L1D29:
	retf

; Walking to the door.
H_1D2A:
	SCRIPT	MSG_WALK, 23h, 0, 0, H_1D4D
WalkToDoor:
	mov	ax, 0
	push	ax
	mov	ax, 0AAh
	push	ax
	mov	ax, 138h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 312, 170, 0)
	add	sp, 0Ah
	retf

; Looking at things.
H_1D4D:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_1D99
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_TUG0N003
	call	Say
	jmp	SHORT L1D98

T_TUG0N003	LABEL	BYTE
	DB	'#TUG0\TUG0N003#James T. Kirk cautiously watches the area.',0
L1D98:
	retf

H_1D99:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_1DFD
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_TUG0N007
	call	Say
	jmp	SHORT L1DFC

T_TUG0N007	LABEL	BYTE
	DB	'#TUG0\TUG0N007#Spock quietly analyzes the damaged areas of this '
	DB	'transporter room.',0
L1DFC:
	retf

H_1DFD:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_1E5A
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_TUG0N005
	call	Say
	jmp	SHORT L1E59

T_TUG0N005	LABEL	BYTE
	DB	'#TUG0\TUG0N005#McCoy wonders how many patients he''ll have on thi'
	DB	's mission.',0
L1E59:
	retf

H_1E5A:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_1EA0
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_TUG0N004
	call	Say
	jmp	SHORT L1E9F

T_TUG0N004	LABEL	BYTE
	DB	'#TUG0\TUG0N004#Lieutenant Christensen stands ready.',0
L1E9F:
	retf

H_1EA0:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_1EF1
LookAtPad:
	mov	ax, 0
	mov	bx, OFFSET T_TUG0N013
	call	Say
	jmp	SHORT L1EF0

T_TUG0N013	LABEL	BYTE
	DB	'#TUG0\TUG0N013#This is the main transporter pad of the Masada.',0
L1EF0:
	retf

H_1EF1:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_1F59
LookAtDoor:
	mov	ax, 0
	mov	bx, OFFSET T_TUG0N011
	call	Say
	jmp	SHORT L1F58

T_TUG0N011	LABEL	BYTE
	DB	'#TUG0\TUG0N011#These doors have been scarred by phaser fire. The'
	DB	're was a battle here.',0
L1F58:
	retf

; Talking.
H_1F59:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_203D
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG0_006
	call	Say
	jmp	SHORT L1FAE

T_TUG0_006	LABEL	BYTE
	DB	'#TUG0\TUG0_006#Get what you can from this area -- let''s get movi'
	DB	'ng.',0
L1FAE:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG0_036
	call	Say
	jmp	SHORT L1FF2

T_TUG0_036	LABEL	BYTE
	DB	'#TUG0\TUG0_036#Captain, a thorough analysis is required.',0
L1FF2:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG0_011
	call	Say
	jmp	SHORT L203C

T_TUG0_011	LABEL	BYTE
	DB	'#TUG0\TUG0_011#Okay, but let''s not stay too long in one place.',0
L203C:
	retf

H_203D:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_212C
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG0_025
	call	Say
	jmp	SHORT L209F

T_TUG0_025	LABEL	BYTE
	DB	'#TUG0\TUG0_025#Well Jim, there''s one thing I can tell you -- I d'
	DB	'on''t like Elasi.',0
L209F:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG0_007
	call	Say
	jmp	SHORT L20F2

T_TUG0_007	LABEL	BYTE
	DB	'#TUG0\TUG0_007#I can''t see them winning any popularity contests,'
	DB	' Bones.',0
L20F2:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG0_024
	call	Say
	jmp	SHORT L212B

T_TUG0_024	LABEL	BYTE
	DB	'#TUG0\TUG0_024#They can forget about my vote.',0
L212B:
	retf

H_212C:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_2214
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG0_042
	call	Say
	JMPN	L21D0

T_TUG0_042	LABEL	BYTE
	DB	'#TUG0\TUG0_042#When this operation is complete, Captain, we shou'
	DB	'ld have Mr. Scott or Transporter Chief Kyle come here to assist '
	DB	'with the repairs.',0
L21D0:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG0_009
	call	Say
	jmp	SHORT L2213

T_TUG0_009	LABEL	BYTE
	DB	'#TUG0\TUG0_009#Let''s not look too far ahead, Mr. Spock.',0
L2213:
	retf

H_2214:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_227E
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Christensen
	mov	bx, OFFSET T_TUG0L006
	call	Say
	jmp	SHORT L227D

T_TUG0L006	LABEL	BYTE
	DB	'#TUG0\TUG0L006#This is just like their raid on Damocles Station,'
	DB	' hard, fast, and dirty.',0
L227D:
	retf

H_227E:
	SCRIPT	MSG_TALK, 8, 0, 0, H_23B0
TalkToSimpson:
	cmp	byte ptr [si+revived_simpson], 1
	je	L228D
	JMPN	L23AF

L228D:
	mov	ax, OFFSET N_Crewman_Simpson
	mov	bx, OFFSET T_TUG0_F30
	call	Say
	jmp	SHORT L22F6

T_TUG0_F30	LABEL	BYTE
	DB	'#TUG0\TUG0_F30#I suppose I should be grateful to see anyone afte'
	DB	'r that. I thought I was dead.',0
L22F6:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG0_026
	call	Say
	jmp	SHORT L235D

T_TUG0_026	LABEL	BYTE
	DB	'#TUG0\TUG0_026#Well, with any luck, you won''t have to worry abou'
	DB	't that for quite some time.',0
L235D:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG0_012
	call	Say
	jmp	SHORT L23AF

T_TUG0_012	LABEL	BYTE
	DB	'#TUG0\TUG0_012#Provided the Elasi don''t have anything to say abo'
	DB	'ut it.',0
L23AF:
	retf

; The communicator: Spock advises silence.
H_23B0:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_245C
UseCommunicator:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG0_031
	call	Say
	JMPN	L245B

T_TUG0_031	LABEL	BYTE
	DB	'#TUG0\TUG0_031#I strongly recommend that we keep our silence, Ca'
	DB	'ptain. The Elasi are quite capable of tracing any communication '
	DB	'from within this vessel.',0
L245B:
	retf

H_245C:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_24BA
LookAtScene:
	mov	ax, 0
	mov	bx, OFFSET T_TUG0N009
	call	Say
	jmp	SHORT L24B9

T_TUG0N009	LABEL	BYTE
	DB	'#TUG0\TUG0N009#The transporter bay has been damaged in a recent '
	DB	'fire fight.',0
L24B9:
	retf

H_24BA:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_25A5
SpockScans:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L24CD

N_sscans_3	LABEL	BYTE
	DB	'sscans',0
L24CD:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscans_3
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
	mov	bx, OFFSET T_TUG0_028
	call	Say
	JMPN	L25A4

T_TUG0_028	LABEL	BYTE
	DB	'#TUG0\TUG0_028#I am registering energy residue from phaser fire '
	DB	'and phaser grenade detonations. There are readings of another en'
	DB	'ergy weapon, but the type is unknown.',0
L25A4:
	retf

H_25A5:
	SCRIPT	MSG_USE, IT_MTRICOR, ANY, 0, Talk
McCoyScans:
	mov	byte ptr [si+RS_FALL+2], 1
	jmp	SHORT L25B8

N_mscans_2	LABEL	BYTE
	DB	'mscans',0
L25B8:
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
	mov	bx, OFFSET T_TUG0_020
	call	Say
	JMPN	L2674

T_TUG0_020	LABEL	BYTE
	DB	'#TUG0\TUG0_020#Well, at least I''m not picking up residue of any '
	DB	'biologicalweapons.  The Elasi used some restraint if you can cal'
	DB	'l it that.',0
L2674:
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
rdf_exits	LABEL	BYTE
	DW	0, 4	; id, points
	DW	291,170, 308,167, 319,168, 319,176
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
rdf_bans_end	LABEL	BYTE
	DB	0
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Christensen	LABEL	BYTE
	DB	'Lt. Christensen',0
N_Crewman_Simpson	LABEL	BYTE
	DB	'Crewman Simpson',0
	DB	'Starfleet',0
N_Mr_Scott	LABEL	BYTE
	DB	'Mr. Scott',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
