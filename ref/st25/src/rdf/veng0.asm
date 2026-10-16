; VENG0.RDF - "Vengeance", the bridge of the U.S.S. Republic, found
; wrecked with all hands dead. Its records say the Enterprise attacked
; it. The Enterprise leaves to answer a distress call while Kirk's party
; searches the ship; the Elasi will soon arrive (room 2).
;
; Actors: 8 the beam, 9/10 (0Ah) the saw's sparks.
; Objects: 8 the beam, 20h a crewman, 21h the captain's chair, 22h a
; body, 23h the computer, 24h Captain Patterson, 25h navigation, 26h the
; helm, 27h the viewscreen. Exit 1: the turbolift.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 18A8: the engine reads its bytes
;   as key 50 6A 03 2E and next 1EFF (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
scott_left	EQU	RS_VARS+4	; the opening scene has played
saw_crewman	EQU	RS_VARS+7	; McCoy has examined the dying crewman
read_log	EQU	RS_VARS+8	; Spock has read the Republic's last log
read_records	EQU	RS_VARS+9	; Spock has read the computer's records
power_on	EQU	RS_VARS+0Bh	; the Republic has power again (room 6)
beam	EQU	RS_VARS+0Ch	; 0 fixed to the hull, 1 cut free, 2 taken
enterprise_away	EQU	RS_VARS+0Dh	; the Enterprise has left to follow the distress call (room 0)
hypo_oiled	EQU	RS_VARS+11h	; the hypo holds oil (room 6)
power_to	EQU	RS_VARS+13h	; impulse power: 1 weapons, 2 shields, 3 transporter (room 2)
rescued	EQU	RS_VARS+19h	; the Enterprise is back: the Elasi threats are over
elasi_here	EQU	RS_VARS+1Ah	; the Elasi ship has arrived and jams the communicators
complied	EQU	RS_VARS+1Ch	; Kirk has agreed to the Elasi's terms
board_timer	EQU	RS_VARS+20h	; word: until the Elasi board, unless the shields are up
stall_timer	EQU	RS_VARS+22h	; word: the thirty minutes
comply_timer	EQU	RS_VARS+24h	; word: until the Elasi lose patience after Kirk complies
torpedo_timer	EQU	RS_VARS+26h	; word: until their torpedoes
attack_timer	EQU	RS_VARS+28h	; word: after the Elasi lower their shields
clue_crewman	EQU	RS_VARS+3Fh	; evidence for the log: the crewman who just died
clue_log	EQU	RS_VARS+42h	; evidence: the last log entry
clue_records	EQU	RS_VARS+43h	; evidence: the records naming the Enterprise

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0C7h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	96h
rdf_scale_min	LABEL	BYTE
	DW	0B4h	; and scale range
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
	DW	63,196, 91,169	; entrance 1, crew 0
	DW	63,196, 113,169	; entrance 1, crew 1
	DW	63,196, 94,186	; entrance 1, crew 2
	DW	63,196, 125,179	; entrance 1, crew 3
	DW	0,0, 0,0	; entrance 2, crew 0
	DW	0,0, 0,0	; entrance 2, crew 1
	DW	0,0, 0,0	; entrance 2, crew 2
	DW	0,0, 0,0	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	199,181, 217,180, 184,172, 209,167	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	199,181, 217,180, 184,172, 209,167
	DB	'museme',0
	DB	'sscans',0
	DB	'mscans',0
	DB	'mscane',0

rdf_scripts:
; The room starts: the beam, fixed or fallen.
H_00E6:
	SCRIPT	MSG_TICK, 1, 0, 0, H_015D
StartRoom:
	jmp	SHORT L00F7

N_VEN0LOOP	LABEL	BYTE
	DB	'VEN0LOOP',0
L00F7:
	push	OFFSET N_VEN0LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("VEN0LOOP")
	add	sp, 4
	cmp	byte ptr [si+beam], 2
	je	L012D
	jmp	SHORT L0115

N_s7r0bo	LABEL	BYTE
	DB	's7r0bo',0
L0115:
	push	0
	push	0C6h
	push	28h
	push	OFFSET N_s7r0bo
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s7r0bo", 40, 198, 0)
	add	sp, 0Ch
	jmp	SHORT L014C

L012D:
	jmp	SHORT L0136

N_s7r0bf	LABEL	BYTE
	DB	's7r0bf',0
L0136:
	push	0
	push	9Ah
	push	0Eh
	push	OFFSET N_s7r0bf
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s7r0bf", 14, 154, 0)
	add	sp, 0Ch
L014C:
	mov	byte ptr [si+RS_FALL], 1
	mov	byte ptr [si+RS_FALL+1], 1
	mov	byte ptr [si+RS_FALL+2], 1
	mov	byte ptr [si+RS_FALL+3], 1
	retf

H_015D:
	SCRIPT	MSG_TICK, 0Ah, 0, 0, H_0164
Tick10:
	retf

; Tick 50, the first time: the Enterprise picks up a distress call, and
; Kirk sends it off, staying aboard (enterprise_away).
H_0164:
	SCRIPT	MSG_TICK, 32h, 0, 0, H_073E
ScottLeaves:
	cmp	byte ptr [si+scott_left], 0
	je	L0173
	JMPN	L073D

L0173:
	mov	byte ptr [si+scott_left], 1
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_018
	call	Say
	jmp	SHORT L01D1

T_VEN0_018	LABEL	BYTE
	DB	'#VEN0\VEN0_018#My God, Jim. What kind of butcher would do someth'
	DB	'ing like this?',0
L01D1:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN0_006
	call	Say
	jmp	SHORT L0254

T_VEN0_006	LABEL	BYTE
	DB	'#VEN0\VEN0_006#I don''t know, Bones. We''re too far from the Kling'
	DB	'on and Romulan borders for it to be one of their ships.',0
L0254:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_VEN0_S12
	call	Say
	jmp	SHORT L028A

T_VEN0_S12	LABEL	BYTE
	DB	'#VEN0\VEN0_S12#Enterprise to Captain Kirk.',0
L028A:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN0_008
	call	Say
	jmp	SHORT L02C3

T_VEN0_008	LABEL	BYTE
	DB	'#VEN0\VEN0_008#Kirk Here. What is it, Scotty?',0
L02C3:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_VEN0_S52
	call	Say
	JMPN	L0376

T_VEN0_S52	LABEL	BYTE
	DB	'#VEN0\VEN0_S52#We''ve picked up a distress signal. It appears a t'
	DB	'rading vessel is having a wee bit of trouble with their warp dri'
	DB	've. What condition is the Republic in?',0
L0376:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN0_007
	call	Say
	jmp	SHORT L03D6

T_VEN0_007	LABEL	BYTE
	DB	'#VEN0\VEN0_007#It''s a mess, Scotty. Life support''s functioning, '
	DB	'but that''s about it.',0
L03D6:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN0_030
	call	Say
	JMPN	L048C

T_VEN0_030	LABEL	BYTE
	DB	'#VEN0\VEN0_030#I''ve done a primary scan of the Republic''s system'
	DB	's. Main and auxiliary power is out. Life support is stable. I al'
	DB	'so read that communications are operable.',0
L048C:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_VEN0_S15
	call	Say
	jmp	SHORT L04C8

T_VEN0_S15	LABEL	BYTE
	DB	'#VEN0\VEN0_S15#Should we beam you back, Captain?',0
L04C8:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN0_005
	call	Say
	jmp	SHORT L0515

T_VEN0_005	LABEL	BYTE
	DB	'#VEN0\VEN0_005#Do the sensors read any other ships in the sector'
	DB	'?',0
L0515:
	mov	ax, OFFSET N_Mr_Chekov
	mov	bx, OFFSET T_VEN0_039
	call	Say
	jmp	SHORT L0564

T_VEN0_039	LABEL	BYTE
	DB	'#VEN0\VEN0_039#Besides the trade wessel, this sector is clear, S'
	DB	'ir.',0
L0564:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN0_009
	call	Say
	JMPN	L05F4

T_VEN0_009	LABEL	BYTE
	DB	'#VEN0\VEN0_009#Mr. Scott, we will continue here. Assist the trad'
	DB	'e ship and return here. If we need assistance, we will contact y'
	DB	'ou.',0
L05F4:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_VEN0_S54
	call	Say
	jmp	SHORT L0635

T_VEN0_S54	LABEL	BYTE
	DB	'#VEN0\VEN0_S54#You sure you''ll be all right, Captain?',0
L0635:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN0_011
	call	Say
	jmp	SHORT L0680

T_VEN0_011	LABEL	BYTE
	DB	'#VEN0\VEN0_011#Yes, Scotty. Just don''t take too long. Kirk out.',0
L0680:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN0_010
	call	Say
	jmp	SHORT L06D2

T_VEN0_010	LABEL	BYTE
	DB	'#VEN0\VEN0_010#Well, Gentlemen. Let''s see if we can reestablish '
	DB	'power.',0
L06D2:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_017
	call	Say
	jmp	SHORT L0739

T_VEN0_017	LABEL	BYTE
	DB	'#VEN0\VEN0_017#Jim, don''t forget, there''s another survivor on bo'
	DB	'ard. We''ve got to find him!',0
L0739:
	mov	byte ptr [si+enterprise_away], 1
L073D:
	retf

; Exit 1: the turbolift.
H_073E:
	SCRIPT	MSG_EXIT, 1, 0, 0, H_0763
ToTurbolift:
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	push	0
	push	0
	push	RC_TURBOLIFT
	SERVICE		; Turbolift(0, 0)
	add	sp, 6
	retf

; Spock scans the computer (the Enterprise's transponder in the attack
; records) and the captain's chair (Patterson's last log).
H_0763:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_082F
SpockScansComputer:
	cmp	byte ptr [si+read_records], 1
	je	L07D3
	mov	byte ptr [si+read_records], 1
	mov	byte ptr [si+clue_records], 1
	jmp	SHORT L0780

N_sscans	LABEL	BYTE
	DB	'sscans',0
L0780:
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
	mov	bx, OFFSET T_VEN0_028
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN0_002
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN0_029
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_020
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN0_031
	call	Say
	retf

L07D3:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN0_025
	call	Say
	jmp	SHORT L082E

T_VEN0_025	LABEL	BYTE
	DB	'#VEN0\VEN0_025#There are no more computer entries accessible fro'
	DB	'm this station.',0
L082E:
	retf

H_082F:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_08D0
SpockScansChair:
	cmp	byte ptr [si+read_log], 1
	je	L0896
	mov	byte ptr [si+read_log], 1
	mov	byte ptr [si+clue_log], 1
	jmp	SHORT L084C

N_sscans_2	LABEL	BYTE
	DB	'sscans',0
L084C:
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
	mov	bx, OFFSET T_VEN0_32
	call	Say
	mov	ax, OFFSET S_19F3
	mov	bx, OFFSET T_VEN0_035
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN0_033
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN0_004
	call	Say
	retf

L0896:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN0_026
	call	Say
	jmp	SHORT L08CF

T_VEN0_026	LABEL	BYTE
	DB	'#VEN0\VEN0_026#There are no more log entries.',0
L08CF:
	retf

H_08D0:
	SCRIPT	MSG_USE, IT_STRICOR, 27h, 0, H_08D8
	jmp	SHORT SpockScans

H_08D8:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_09BF
SpockScans:
	cmp	byte ptr [si+power_on], 1
	jne	L08E7
	JMPN	L09BE

L08E7:
	jmp	SHORT L08F0

N_sscans_3	LABEL	BYTE
	DB	'sscans',0
L08F0:
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
	mov	bx, OFFSET T_VEN0_027
	call	Say
	JMPN	L09BE

T_VEN0_027	LABEL	BYTE
	DB	'#VEN0\VEN0_027#Tricorder readings indicate that the ship is runn'
	DB	'ing on minimal battery power. Only life support and essential sy'
	DB	'stems are currently running.',0
L09BE:
	retf

; The crew on the beam and the controls.
H_09BF:
	SCRIPT	MSG_USE, OBJ_MCCOY, 8, 0, H_0A04
McCoyOnBeam:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_015
	call	Say
	jmp	SHORT L0A03

T_VEN0_015	LABEL	BYTE
	DB	'#VEN0\VEN0_015#I''m a doctor, not a civil engineer!',0
L0A03:
	retf

H_0A04:
	SCRIPT	MSG_USE, IT_STRICOR, 8, 0, H_0A0C
	jmp	SHORT SpockOnBeam

H_0A0C:
	SCRIPT	MSG_USE, OBJ_SPOCK, 8, 0, H_0A88
SpockOnBeam:
	jmp	SHORT L0A1B

N_sscanw	LABEL	BYTE
	DB	'sscanw',0
L0A1B:
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
	mov	bx, OFFSET T_VEN0_034
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_021
	call	Say
	jmp	SHORT L0A87

T_VEN0_021	LABEL	BYTE
	DB	'#VEN0\VEN0_021#Thanks for the dissertation, Spock.',0
L0A87:
	retf

H_0A88:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 8, 0, H_0AE2
KijeOnBeam:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN0_037
	call	Say
	jmp	SHORT L0AE1

T_VEN0_037	LABEL	BYTE
	DB	'#VEN0\VEN0_037#I think I remember seeing a ton of these at space'
	DB	'dock 4.',0
L0AE1:
	retf

H_0AE2:
	SCRIPT	MSG_USE, OBJ_SPOCK, 26h, 0, H_0AEA
	jmp	SHORT SpockOnNavigation

H_0AEA:
	SCRIPT	MSG_USE, OBJ_SPOCK, 25h, 0, H_0AF2
SpockOnNavigation:
	jmp	SHORT SpockScansHelm

H_0AF2:
	SCRIPT	MSG_USE, IT_STRICOR, 26h, 0, H_0AFA
SpockScansHelm:
	jmp	SHORT SpockScansNavigation

H_0AFA:
	SCRIPT	MSG_USE, IT_STRICOR, 25h, 0, H_0B80
SpockScansNavigation:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN0_024
	call	Say
	jmp	SHORT L0B7F

T_VEN0_024	LABEL	BYTE
	DB	'#VEN0\VEN0_024#The controls have been totally destroyed. Undoubt'
	DB	'edly due to circuit overloads caused by the battle.',0
L0B7F:
	retf

H_0B80:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 26h, 0, H_0B88
	jmp	SHORT KijeOnNavigation

H_0B88:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 25h, 0, H_0BEA
KijeOnNavigation:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN0_038
	call	Say
	jmp	SHORT L0BE9

T_VEN0_038	LABEL	BYTE
	DB	'#VEN0\VEN0_038#There is no response, Captain. The controls are c'
	DB	'ompletely dead.',0
L0BE9:
	retf

; Phasers on the beam.
H_0BEA:
	SCRIPT	MSG_USE, IT_PHASERS, 8, 0, H_0BF2
	jmp	SHORT PhaserBeam

H_0BF2:
	SCRIPT	MSG_USE, IT_PHASERK, 8, 0, H_0C70
PhaserBeam:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN0_013
	call	Say
	jmp	SHORT L0C6F

T_VEN0_013	LABEL	BYTE
	DB	'#VEN0\VEN0_013#Captain, these phasers are not configured for fin'
	DB	'e cutting. We could cause extensive damage.',0
L0C6F:
	retf

; McCoy and the bodies.
H_0C70:
	SCRIPT	MSG_USE, OBJ_MCCOY, 24h, 0, H_0C78
	jmp	SHORT McCoyScansPatterson

H_0C78:
	SCRIPT	MSG_USE, IT_MTRICOR, 24h, 0, H_0C80
McCoyScansPatterson:
	jmp	SHORT McCoyOnBody

H_0C80:
	SCRIPT	MSG_USE, OBJ_MCCOY, 22h, 0, H_0C88
McCoyOnBody:
	jmp	SHORT MedkitOnBody

H_0C88:
	SCRIPT	MSG_USE, IT_MEDKIT, 22h, 0, H_0C90
MedkitOnBody:
	jmp	SHORT MedkitOnPatterson

H_0C90:
	SCRIPT	MSG_USE, IT_MEDKIT, 24h, 0, H_0C98
MedkitOnPatterson:
	jmp	SHORT McCoyScansBody

H_0C98:
	SCRIPT	MSG_USE, IT_MTRICOR, 22h, 0, H_0CD6
McCoyScansBody:
	jmp	SHORT L0CA7

N_mscans	LABEL	BYTE
	DB	'mscans',0
L0CA7:
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
	mov	bx, OFFSET T_VEN0_016
	call	Say
	retf

; The molecular saw on the beam (msgs 1, 2, timer 0): it comes free.
H_0CD6:
	SCRIPT	MSG_USE, IT_LMD, 8, 0, H_0D5E
SawOnBeam:
	cmp	byte ptr [si+beam], 1
	je	L0D09
	cmp	byte ptr [si+beam], 2
	je	L0D09
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 1
	push	ax
	mov	ax, 0C2h
	push	ax
	mov	ax, 24h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 36, 194, 1)
	add	sp, 0Ah
	retf

L0D09:
	mov	ax, 0
	mov	bx, OFFSET T_VEN0N008
	call	Say
	jmp	SHORT L0D5D

T_VEN0N008	LABEL	BYTE
	DB	'#VEN0\VEN0N008#The support beam has already been detached from t'
	DB	'he hull.',0
L0D5D:
	retf

H_0D5E:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_0D86
KirkAtBeam:
	jmp	SHORT L0D6C

N_kcutw	LABEL	BYTE
	DB	'kcutw',0
L0D6C:
	push	2
	push	-1
	push	-1
	push	OFFSET N_kcutw
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kcutw", -1, -1, 2)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS], 8
	retf

H_0D86:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_0DF3
Sawing:
	jmp	SHORT L0D95

N_MUR3E2	LABEL	BYTE
	DB	'MUR3E2',0
L0D95:
	push	OFFSET N_MUR3E2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR3E2")
	add	sp, 4
	jmp	SHORT L0DAD

N_s7r0s1	LABEL	BYTE
	DB	's7r0s1',0
L0DAD:
	push	0
	push	0C7h
	push	0
	push	OFFSET N_s7r0s1
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s7r0s1", 0, 199, 0)
	add	sp, 0Ch
	jmp	SHORT L0DCC

N_s7r0b1	LABEL	BYTE
	DB	's7r0b1',0
L0DCC:
	push	0
	push	0C7h
	push	0
	push	OFFSET N_s7r0b1
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s7r0b1", 0, 199, 0)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	retf

H_0DF3:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_0E8A
BeamCut:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, 9
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(9)
	add	sp, 4
	mov	ax, 0Ah
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(10)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_VEN0N007
	call	Say
	jmp	SHORT L0E84

T_VEN0N007	LABEL	BYTE
	DB	'#VEN0\VEN0N007#The molecular saw easily cuts through the beam, s'
	DB	'eparating it from the hull.',0
L0E84:
	mov	byte ptr [si+beam], 1
	jmp	SHORT GetBeam

; Taking the beam, once cut.
H_0E8A:
	SCRIPT	MSG_GET, 8, 0, 0, H_0F70
GetBeam:
	cmp	byte ptr [si+beam], 1
	je	L0E99
	JMPN	L0F25

L0E99:
	mov	ax, 0
	mov	bx, OFFSET T_VEN0N019
	call	Say
	jmp	SHORT L0EF1

T_VEN0N019	LABEL	BYTE
	DB	'#VEN0\VEN0N019#You pick up the beam. It''s a little heavy, but yo'
	DB	'u manage it.',0
L0EF1:
	mov	byte ptr [si+beam], 2
	mov	ax, IT_BEAM
	push	ax
	mov	ax, RC_GIVEITEM
	push	ax
	SERVICE		; GiveItem(IT_BEAM)
	add	sp, 4
	jmp	SHORT L0F0E

N_s7r0bf_2	LABEL	BYTE
	DB	's7r0bf',0
L0F0E:
	push	0
	push	9Ah
	push	0Eh
	push	OFFSET N_s7r0bf_2
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s7r0bf", 14, 154, 0)
	add	sp, 0Ch
	retf

L0F25:
	mov	ax, 0
	mov	bx, OFFSET T_VEN0N009
	call	Say
	jmp	SHORT L0F6F

T_VEN0N009	LABEL	BYTE
	DB	'#VEN0\VEN0N009#The support beam is still attached to the hull.',0
L0F6F:
	retf

; Talking and looking.
H_0F70:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0F80
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN0_001
	call	Say
	retf

H_0F80:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0F90
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_014
	call	Say
	retf

H_0F90:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0FB6
TalkToSpock:
	cmp	byte ptr [si+read_records], 1
	jne	L0FAC
	cmp	byte ptr [si+read_log], 1
	jne	L0FAC
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN0_012
	call	Say
	retf

L0FAC:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN0_023
	call	Say
	retf

H_0FB6:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0FC6
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN0_036
	call	Say
	retf

H_0FC6:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_0FD5
LookAtPatterson:
	sub	ax, ax
	mov	bx, OFFSET T_VEN0N004
	call	Say
	retf

H_0FD5:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_0FE4
LookAtBody:
	sub	ax, ax
	mov	bx, OFFSET T_VEN0N017
	call	Say
	retf

H_0FE4:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_0FF3
LookAtComputer:
	sub	ax, ax
	mov	bx, OFFSET T_VEN0N005
	call	Say
	retf

H_0FF3:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_1002
LookAtChair:
	sub	ax, ax
	mov	bx, OFFSET T_VEN0N015
	call	Say
	retf

H_1002:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_1011
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_VEN0N001
	call	Say
	retf

H_1011:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_1020
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_VEN0N006
	call	Say
	retf

H_1020:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_102F
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_VEN0N002
	call	Say
	retf

H_102F:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_103E
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_VEN0N003
	call	Say
	retf

H_103E:
	SCRIPT	MSG_LOOK, 27h, 0, 0, H_1082
LookAtViewscreen:
	mov	ax, 0
	mov	bx, OFFSET T_VEN0N010
	call	Say
	jmp	SHORT L1081

T_VEN0N010	LABEL	BYTE
	DB	'#VEN0\VEN0N010#The viewscreen is not functioning.',0
L1081:
	retf

H_1082:
	SCRIPT	MSG_LOOK, 26h, 0, 0, H_10EE
LookAtHelm:
	mov	ax, 0
	mov	bx, OFFSET T_VEN0N011
	call	Say
	jmp	SHORT L10ED

T_VEN0N011	LABEL	BYTE
	DB	'#VEN0\VEN0N011#These are the helm controls for the Republic. The'
	DB	'y are currently inactive.',0
L10ED:
	retf

H_10EE:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_1160
LookAtNavigation:
	mov	ax, 0
	mov	bx, OFFSET T_VEN0N012
	call	Say
	jmp	SHORT L115F

T_VEN0N012	LABEL	BYTE
	DB	'#VEN0\VEN0N012#These are the navigation controls for the Republi'
	DB	'c. They are currently inactive.',0
L115F:
	retf

H_1160:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_121C
LookAtBeam:
	cmp	byte ptr [si+beam], 1
	je	L11D6
	mov	ax, 0
	mov	bx, OFFSET T_VEN0N000
	call	Say
	jmp	SHORT L11D5

T_VEN0N000	LABEL	BYTE
	DB	'#VEN0\VEN0N000#A common Tritanium/Duranium support beam which ha'
	DB	's snapped away from the hull.',0
L11D5:
	retf

L11D6:
	mov	ax, 0
	mov	bx, OFFSET T_VEN0N013
	call	Say
	jmp	SHORT L121B

T_VEN0N013	LABEL	BYTE
	DB	'#VEN0\VEN0N013#This beam has been detached from the hull.',0
L121B:
	retf

H_121C:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_127A
LookAtScene:
	mov	ax, 0
	mov	bx, OFFSET T_VEN0N018
	call	Say
	jmp	SHORT L1279

T_VEN0N018	LABEL	BYTE
	DB	'#VEN0\VEN0N018#You are in what''s left of the bridge of the U.S.S'
	DB	'. Republic.',0
L1279:
	retf

H_127A:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_128A
LookAtCrewman:
	mov	ax, OFFSET S_1A28
	mov	bx, OFFSET T_VEN0N016
	call	Say
	retf

; The crewman: McCoy (msg 3, anim msg 1) finds he died moments ago
; (evidence).
H_128A:
	SCRIPT	MSG_USE, IT_MEDKIT, 20h, 0, H_1292
	jmp	SHORT McCoyScansCrewman

H_1292:
	SCRIPT	MSG_USE, IT_MTRICOR, 20h, 0, H_129A
McCoyScansCrewman:
	jmp	SHORT McCoyOnCrewman

H_129A:
	SCRIPT	MSG_USE, OBJ_MCCOY, 20h, 0, H_12CD
McCoyOnCrewman:
	cmp	byte ptr [si+saw_crewman], 1
	je	L12C3
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL+2], 2
	push	3
	push	0A0h
	push	0DCh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 220, 160, 3)
	add	sp, 0Ah
	retf

L12C3:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_016
	call	Say
	retf

H_12CD:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_133A
McCoyAtCrewman:
	mov	byte ptr [si+saw_crewman], 1
	mov	byte ptr [si+clue_crewman], 1
	jmp	SHORT L12E4

N_mscane	LABEL	BYTE
	DB	'mscane',0
L12E4:
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
	mov	bx, OFFSET T_VEN0_022
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN0_003
	call	Say
	jmp	SHORT L1324

N_mscane_2	LABEL	BYTE
	DB	'mscane',0
L1324:
	push	1
	push	-1
	push	-1
	push	OFFSET N_mscane_2
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscane", -1, -1, 1)
	add	sp, 0Ch
	retf

H_133A:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_134E
CrewmanDied:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN0_019
	call	Say
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Every tick, common to the mission's rooms: the Elasi deadlines set on
; the bridge (room 2). Until the Enterprise returns: boarding unless the
; shields are up, the thirty minutes, the wait after Kirk complies (then
; a warning and the torpedoes), the chance after they lower their
; shields. When one runs out, the game is over.
H_134E:
	SCRIPT	MSG_TICK, ANY, ANY, ANY, H_1572
ElasiDeadlines:
	cmp	word ptr [si+board_timer], 0
	je	L1368
	dec	word ptr [si+board_timer]
	jne	L1368
	cmp	byte ptr [si+power_to], 2
	je	L1368
	JMPN	L1468

L1368:
	cmp	word ptr [si+stall_timer], 0
	je	L137C
	dec	word ptr [si+stall_timer]
	jne	L137C
	cmp	byte ptr [si+complied], 1
	je	L137C
	JMPN	L1468

L137C:
	cmp	word ptr [si+comply_timer], 0
	je	L13DB
	dec	word ptr [si+comply_timer]
	jne	L13DB
	cmp	byte ptr [si+rescued], 1
	je	L13DB
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_098
	call	Say
	jmp	SHORT L13D6

T_VEN2_098	LABEL	BYTE
	DB	'#VEN2\VEN2_098#What are you stalling for? Lower your shields.',0
L13D6:
	mov	word ptr [si+torpedo_timer], 0A8Ch
L13DB:
	cmp	word ptr [si+torpedo_timer], 0
	je	L1454
	dec	word ptr [si+torpedo_timer]
	jne	L1454
	cmp	byte ptr [si+rescued], 1
	je	L1454
	mov	ax, 0
	mov	bx, OFFSET T_VENA_F40
	call	Say
	jmp	SHORT L1448

T_VENA_F40	LABEL	BYTE
	DB	'#VENA\VENA_F40#The Elasi fire photon torpedoes. The Republic has'
	DB	' been destroyed.',0
L1448:
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
L1454:
	cmp	word ptr [si+attack_timer], 0
	je	L1467
	dec	word ptr [si+attack_timer]
	jne	L1467
	cmp	byte ptr [si+rescued], 1
	je	L1467
	jmp	SHORT L1468

L1467:
	retf

L1468:
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

H_1572:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_157A
	jmp	SHORT KillAnything

H_157A:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_160F
KillAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VENA_F34
	call	Say
	JMPN	L160E

T_VENA_F34	LABEL	BYTE
	DB	'#VENA\VENA_F34#Captain, it would be unwise to use your phaser co'
	DB	'nsidering the already extensive damage sustained by the Republic'
	DB	'.',0
L160E:
	retf

; The hypo, empty or full of oil.
H_160F:
	SCRIPT	MSG_LOOK, IT_HYPO, 0, 0, H_16A5
LookAtHypo:
	cmp	byte ptr [si+hypo_oiled], 1
	je	L165C
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N010
	call	Say
	jmp	SHORT L165B

T_VEN4N010	LABEL	BYTE
	DB	'#VEN4\VEN4N010#This is an empty hypodermic injector.',0
L165B:
	retf

L165C:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N007
	call	Say
	jmp	SHORT L16A4

T_VEN6N007	LABEL	BYTE
	DB	'#VEN6\VEN6N007#The hypo is now filled with multipurpose oil.',0
L16A4:
	retf

; The communicator: before the Enterprise leaves, Uhura; while the Elasi
; jam it, Spock; otherwise Uhura, tracking the distress call.
H_16A5:
	SCRIPT	MSG_USE, IT_COMM, OBJ_KIRK, 0, Talk
CallEnterprise:
	cmp	byte ptr [si+enterprise_away], 1
	je	L172D
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018
	call	Say
	jmp	SHORT L16F6

T_MUD4_018	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L16F6:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146
	call	Say
	jmp	SHORT L172C

T_BRIDU146	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L172C:
	retf

L172D:
	cmp	byte ptr [si+elasi_here], 1
	jne	L1736
	JMPN	L1833

L1736:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_2
	call	Say
	jmp	SHORT L177A

T_MUD4_018_2	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise, Kirk to Enterprise...',0
L177A:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_VEN2U093
	call	Say
	jmp	SHORT L17E5

T_VEN2U093	LABEL	BYTE
	DB	'#VEN2\VEN2U093#Enterprise here. We''re still tracking the distres'
	DB	's call. Are you all right, Sir?',0
L17E5:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_028
	call	Say
	jmp	SHORT L1832

T_VEN2_028	LABEL	BYTE
	DB	'#VEN2\VEN2_028#Yes, Uhura. Just wanted a status report. Kirk out'
	DB	'.',0
L1832:
	retf

L1833:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_066
	call	Say
	jmp	SHORT L18A7

T_VEN2_066	LABEL	BYTE
	DB	'#VEN2\VEN2_066#They are jamming all frequencies, Captain. We wil'
	DB	'l not be able to contact the Enterprise.',0
L18A7:
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
	DW	23h, 4	; id, points
	DW	0,127, 54,114, 75,124, 0,157
	DW	23h, 4	; id, points
	DW	268,103, 319,129, 319,157, 245,124
	DW	21h, 4	; id, points
	DW	136,177, 181,177, 181,199, 136,199
	DW	24h, 4	; id, points
	DW	184,187, 224,187, 224,199, 184,199
	DW	22h, 4	; id, points
	DW	4,177, 24,176, 41,199, 9,199
	DW	22h, 4	; id, points
	DW	106,125, 136,125, 139,164, 109,163
	DW	20h, 4	; id, points
	DW	231,128, 250,129, 256,156, 224,159
	DW	25h, 4	; id, points
	DW	174,128, 220,128, 220,150, 174,150
	DW	26h, 4	; id, points
	DW	99,128, 146,128, 146,150, 99,150
	DW	27h, 4	; id, points
	DW	71,27, 251,27, 251,113, 71,113
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	1, 4	; id, points
	DW	0,195, 319,195, 319,199, 0,199
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's9b1',0
	DB	's9b3',0
	DB	's9b4',0
	DB	's9b5',0
	DB	's9b6',0
	DB	's9b7',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Ensign_Kije	LABEL	BYTE
	DB	'Ensign Kije',0
N_Mr_Scott	LABEL	BYTE
	DB	'Mr. Scott',0
S_19F3	LABEL	BYTE
	DB	'*Capt. Patterson*',0
N_Mr_Chekov	LABEL	BYTE
	DB	'Mr. Chekov',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
N_Elasi_Captain	LABEL	BYTE
	DB	'Elasi Captain',0
S_1A28	LABEL	BYTE
	DB	0
T_VEN0N016	LABEL	BYTE
	DB	'#VEN0\VEN0N016#This man is dead.',0
T_VEN0_022	LABEL	BYTE
	DB	'#VEN0\VEN0_022#We''re too late. This man must have just died a fe'
	DB	'w moments ago.',0
T_VEN0_003	LABEL	BYTE
	DB	'#VEN0\VEN0_003#Can you bring him back?',0
T_VEN0_019	LABEL	BYTE
	DB	'#VEN0\VEN0_019#Punctured lung, nerve damage, brain damage, fract'
	DB	'ured arm and ribs; it''s a miracle he lasted as long as he did. H'
	DB	'e''s not coming back, Jim.',0
T_VEN0N004	LABEL	BYTE
	DB	'#VEN0\VEN0N004#Here is the body of Captain Patterson of the Repu'
	DB	'blic. He didn''t die without a fight.',0
T_VEN0N017	LABEL	BYTE
	DB	'#VEN0\VEN0N017#This person is dead.',0
T_VEN0N005	LABEL	BYTE
	DB	'#VEN0\VEN0N005#Main computer banks. They appear to have been dam'
	DB	'aged.',0
T_VEN0N015	LABEL	BYTE
	DB	'#VEN0\VEN0N015#This is is the Captain''s chair, where the Captain'
	DB	'''s log is stored.',0
T_VEN0N001	LABEL	BYTE
	DB	'#VEN0\VEN0N001#Captain James T. Kirk. This is not one of the bes'
	DB	't days of his life.',0
T_VEN0N006	LABEL	BYTE
	DB	'#VEN0\VEN0N006#Mr. Spock, awaiting orders.',0
T_VEN0N002	LABEL	BYTE
	DB	'#VEN0\VEN0N002#Dr. Leonard McCoy. You have rarely seen him as sh'
	DB	'aken as he is now.',0
T_VEN0N003	LABEL	BYTE
	DB	'#VEN0\VEN0N003#Ensign Kije, who wishes that Lieutenant Stackpole'
	DB	' had drawn this assignment.',0
T_VEN0_001	LABEL	BYTE
	DB	'#VEN0\VEN0_001#Dick Patterson and I weren''t exactly friends, but'
	DB	' this...',0
T_VEN0_023	LABEL	BYTE
	DB	'#VEN0\VEN0_023#I recommend checking as many of the logs and sens'
	DB	'or records as possible.',0
T_VEN0_014	LABEL	BYTE
	DB	'#VEN0\VEN0_014#What kind of a butcher would do this sort of thin'
	DB	'g?',0
T_VEN0_036	LABEL	BYTE
	DB	'#VEN0\VEN0_036#I feel sick.',0
T_VEN0_028	LABEL	BYTE
	DB	'#VEN0\VEN0_028#Captain, records indicate that this ship was atta'
	DB	'cked by a Constitution-class Starship.',0
T_VEN0_002	LABEL	BYTE
	DB	'#VEN0\VEN0_002#Any idea of which one it was?',0
T_VEN0_029	LABEL	BYTE
	DB	'#VEN0\VEN0_029#I am reading a record of the transponder signal. '
	DB	'NCC-1701. It''s the Enterprise, Captain.',0
T_VEN0_020	LABEL	BYTE
	DB	'#VEN0\VEN0_020#Someone must have tampered with the computer reco'
	DB	'rds!',0
T_VEN0_031	LABEL	BYTE
	DB	'#VEN0\VEN0_031#May I remind you, Doctor, that the main computer '
	DB	'of a Constitution class starship has safeguards against such an '
	DB	'intrusion. Furthermore, I do not see any discrepancies in any of'
	DB	' the files that I am able to access.',0
T_VEN0_32	LABEL	BYTE
	DB	'#VEN0\VEN0_32#My tricorder has picked up the final entry of the '
	DB	'Republic.',0
T_VEN0_035	LABEL	BYTE
	DB	'#VEN0\VEN0_035#We are under attack. Our sensors are inoperative.'
	DB	' We''re trying to get shields up. Our rear deflector''s down. It a'
	DB	'ppears our enemy is a Constitution class starship. We have tried'
	DB	' to defend ourselves. We''ve hailed them, but no response.',0
T_VEN0_033	LABEL	BYTE
	DB	'#VEN0\VEN0_033#That''s all there is, Captain.',0
T_VEN0_004	LABEL	BYTE
	DB	'#VEN0\VEN0_004#Dick Patterson was never one for making long spee'
	DB	'ches.',0
T_VEN0_016	LABEL	BYTE
	DB	'#VEN0\VEN0_016#They are dead, Jim. All of them.',0
T_VEN0_012	LABEL	BYTE
	DB	'#VEN0\VEN0_012#Captain, I believe we have exhausted all our opti'
	DB	'ons concerning data retrieval here on the bridge.',0
T_VEN0_034	LABEL	BYTE
	DB	'#VEN0\VEN0_034#This is a standard Tritanium/Duranium support bea'
	DB	'm. Tricorder readings indicate that although it has experienced '
	DB	'enough tensile stress to push it from one side of its mooring, i'
	DB	't has not elastically deformed beyond its ability to support a c'
	DB	'ompressive load.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
