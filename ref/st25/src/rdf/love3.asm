; LOVE3.RDF - "Love's Labor Jeopardized", the station's engineering
; center. The air vent here leads to the Romulan-held deck below: Romulan
; laughing gas poured down it puts the Romulans out. The nitrogen tank the
; synthesizer needs (room 2) is here, bolted to its feed lines; the access
; panel holds the insulation for polyberylcarbonate (room 1); the wrench
; lies on the floor.
;
; Actors: 8 the service panel, 9 the access panel, 10 (0Ah) the wrench,
; 11 (0Bh) the vent cover, 12 (0Ch) the nitrogen tank.
; Objects: 8 the service panel, 9/20h the access panel, 0Ah the wrench,
; 0Bh the vent cover, 0Ch the tank, 21h the readouts, 22h the vent, 23h
; the reactor. Exit 1: the lab (room 1).
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The communicator's four cases (CallEnterprise) all play the same
;   placeholder lines, recorded for other missions.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
have_research	EQU	RS_VARS+1	; McCoy has Dr. Marcus' research on the virus (room 0)
romulans_out	EQU	RS_VARS+2	; the Romulan laughing gas has put the Romulans below out
n2o_released	EQU	RS_VARS+3	; laughing gas: the crew laugh (timer 0)
rlg_released	EQU	RS_VARS+4	; Romulan laughing gas: Spock laughs (timer 1)
service_panel_open	EQU	RS_VARS+0Fh	; bit 0
tank_loose	EQU	RS_VARS+10h	; the nitrogen tank is off its feed lines
took_wrench	EQU	RS_VARS+11h
took_n2_tank	EQU	RS_VARS+12h	; the nitrogen tank is in the inventory
never_set	EQU	RS_VARS+13h	; nothing sets it: the insulation can always be taken
vent_open	EQU	RS_VARS+14h
access_panel_open	EQU	RS_VARS+15h
been_below	EQU	RS_VARS+16h	; the party has been to the deck below (room 4)
virus_struck	EQU	RS_VARS+18h	; the virus has floored Spock, and the Romulans below
virus	EQU	RS_VARS+1Ch	; Spock's infection: 3Ch he collapses, 64h he dies
spock_cured	EQU	RS_VARS+1Dh
called_ship	EQU	RS_VARS+1Eh	; Kirk has called the Enterprise
called_ship_cured	EQU	RS_VARS+1Fh	; the same, after the cure
opened_vent	EQU	RS_VARS+24h	; the point for the vent
gassed	EQU	RS_VARS+25h	; the points for the gas
made_cure	EQU	RS_VARS+26h	; the cure has been synthesized (room 2)
score	EQU	RS_VARS+29h	; word: the mission's score

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0C7h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	0ABh
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
	DW	-1, 1, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	0,0, 0,0	; entrance 0, crew 0
	DW	0,0, 0,0	; entrance 0, crew 1
	DW	0,0, 0,0	; entrance 0, crew 2
	DW	0,0, 0,0	; entrance 0, crew 3
	DW	147,199, 113,175	; entrance 1, crew 0
	DW	147,199, 188,179	; entrance 1, crew 1
	DW	147,199, 77,196	; entrance 1, crew 2
	DW	147,199, 153,189	; entrance 1, crew 3
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
laugher	LABEL	BYTE	; word: the name of who giggles
	DB	0, 0
roll	LABEL	BYTE	; word: a random number
	DB	0, 0
crew	LABEL	BYTE	; word: the crew member at the service panel
	DB	0, 0
crew_anim	LABEL	BYTE	; word
	DB	0, 0
N_wrench	LABEL	BYTE
	DB	'wrench',0
N_r4n2	LABEL	BYTE
	DB	'r4n2',0
N_s3r4p1	LABEL	BYTE
	DB	's3r4p1',0
N_s3r4p2	LABEL	BYTE
	DB	's3r4p2',0
N_s3r4d1	LABEL	BYTE
	DB	's3r4d1',0
N_s3r4d1a	LABEL	BYTE
	DB	's3r4d1a',0
N_s3r4d2	LABEL	BYTE
	DB	's3r4d2',0
N_s3r4d1b	LABEL	BYTE
	DB	's3r4d1b',0
N_s3r4g1	LABEL	BYTE
	DB	's3r4g1',0
N_s3r4g3	LABEL	BYTE
	DB	's3r4g3',0
N_s3r4g2	LABEL	BYTE
	DB	's3r4g2',0
N_s3r4g2a	LABEL	BYTE
	DB	's3r4g2a',0
N_s5r1kg	LABEL	BYTE
	DB	's5r1kg',0
	DB	'kusehn',0
N_kusehe	LABEL	BYTE
	DB	'kusehe',0
N_kuselw	LABEL	BYTE
	DB	'kuselw',0
N_kusemn	LABEL	BYTE
	DB	'kusemn',0
N_kuseme	LABEL	BYTE
	DB	'kuseme',0
N_susehe	LABEL	BYTE
	DB	'susehe',0
N_musehe	LABEL	BYTE
	DB	'musehe',0
N_rusehe	LABEL	BYTE
	DB	'rusehe',0
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_sscann	LABEL	BYTE
	DB	'sscann',0
N_sscanw	LABEL	BYTE
	DB	'sscanw',0
N_mscans	LABEL	BYTE
	DB	'mscans',0

rdf_scripts:
; The room starts: the wrench, the vent, the panels, the tank.
H_0182:
	SCRIPT	MSG_TICK, 1, 0, 0, H_027D
StartRoom:
	jmp	SHORT L0193

N_LOV3LOOP	LABEL	BYTE
	DB	'LOV3LOOP',0
L0193:
	push	OFFSET N_LOV3LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("LOV3LOOP")
	add	sp, 4
	cmp	byte ptr [si+took_wrench], 1
	je	L01BF
	push	0
	push	0B6h
	push	10Ah
	push	OFFSET N_wrench
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "wrench", 266, 182, 0)
	add	sp, 0Ch
L01BF:
	push	0
	cmp	byte ptr [si+vent_open], 1
	jne	L01D0
	push	0
	push	0
	push	OFFSET N_s3r4g3
	jmp	SHORT L01D9

L01D0:
	push	8Fh
	push	116h
	push	OFFSET N_s3r4g1
L01D9:
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, ?, ?, ?, 0)
	add	sp, 0Ch
	cmp	byte ptr [si+access_panel_open], 1
	jne	L0200
	push	0
	push	0
	push	0
	push	OFFSET N_s3r4p2
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s3r4p2", 0, 0, 0)
	add	sp, 0Ch
L0200:
	cmp	byte ptr [si+took_n2_tank], 1
	je	L021B
	push	0
	push	0
	push	0
	push	OFFSET N_r4n2
	push	0Ch
	push	RC_ANIM0
	SERVICE		; Anim0(12, "r4n2", 0, 0, 0)
	add	sp, 0Ch
L021B:
	push	0
	push	0
	push	1
	push	OFFSET N_s3r4d2
	cmp	byte ptr [si+service_panel_open], 1
	jne	L022E
	pop	ax
	push	OFFSET N_s3r4d1a
L022E:
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, ?, 1, 0, 0)
	add	sp, 0Ch
	cmp	byte ptr [si+n2o_released], 1
	jne	L0252
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS], ax
L0252:
	cmp	byte ptr [si+rlg_released], 1
	jne	L026B
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS+2], ax
L026B:
	mov	word ptr [si+RS_TIMERS+4], 0C8h
	mov	byte ptr cs:cure_x, -4Ch
	mov	byte ptr cs:cure_y, -49h
	retf

; Tick 80, with the Romulan laughing gas and not yet below: McCoy jokes.
H_027D:
	SCRIPT	MSG_TICK, 50h, 0, 0, H_0392
McCoyJokes:
	cmp	byte ptr [si+been_below], 1
	jne	L028C
	JMPN	L0391

L028C:
	push	IT_RLG
	push	RC_HAVEITEM
	SERVICE		; HaveItem(IT_RLG)
	add	sp, 4
	AX8	cmp, 0
	jne	L02A0
	JMPN	L0391

L02A0:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV3_010
	call	Say
	JMPN	L0348

T_LOV3_010	LABEL	BYTE
	DB	'#LOV3\LOV3_010#I don''t suppose you''d enjoy the psychological rel'
	DB	'ease of a few good belly laughs, Spock? We could open the canist'
	DB	'er right here, if you like.',0
L0348:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV3_020
	call	Say
	jmp	SHORT L0391

T_LOV3_020	LABEL	BYTE
	DB	'#LOV3\LOV3_020#I would strongly recommend against it, Doctor.',0
L0391:
	retf

; Exit 1 (timer 3): to the lab, room 1.
H_0392:
	SCRIPT	MSG_EXIT, 1, 0, 0, H_03AE
ExitToLab:
	mov	byte ptr [si+RS_BUSY], 1
	push	5
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	mov	word ptr [si+RS_TIMERS+6], 0Ah
	retf

H_03AE:
	SCRIPT	MSG_TIMER, 3, 0, 0, H_03C7
GoToLab:
	push	0
	push	1
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(1, 0)
	add	sp, 6
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Looking and talking.
H_03C7:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_03D6
LookAtServicePanel:
	sub	ax, ax
	mov	bx, OFFSET T_LOV3NA20
	call	Say
	retf

H_03D6:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_03E5
LookAtReadouts:
	sub	ax, ax
	mov	bx, OFFSET T_LOV3_
	call	Say
	retf

H_03E5:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_03F4
LookAtWrench:
	sub	ax, ax
	mov	bx, OFFSET T_LOV3N002
	call	Say
	retf

H_03F4:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_0403
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_LOV3N003
	call	Say
	retf

H_0403:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_0412
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_LOV3N005
	call	Say
	retf

H_0412:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_0421
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_LOV3N008
	call	Say
	retf

H_0421:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_0430
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_LOV3N004
	call	Say
	retf

H_0430:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_048C
LookAtScene:
	mov	ax, 0
	mov	bx, OFFSET T_LOV3NA23
	call	Say
	jmp	SHORT L048B

T_LOV3NA23	LABEL	BYTE
	DB	'#LOV3\LOV3NA23#This is the engineering center for the ARK7 space'
	DB	' station.',0
L048B:
	retf

H_048C:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_04E7
LookAtVent:
	cmp	byte ptr [si+vent_open], 1
	jne	L04E6
	mov	ax, 0
	mov	bx, OFFSET T_LOV3NA21
	call	Say
	jmp	SHORT L04E6

T_LOV3NA21	LABEL	BYTE
	DB	'#LOV3\LOV3NA21#This is a vent shaft that leads to the lower leve'
	DB	'l.',0
L04E6:
	retf

H_04E7:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_053F
LookAtVentCover:
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N019
	call	Say
	jmp	SHORT L053E

T_LOV3N019	LABEL	BYTE
	DB	'#LOV3\LOV3N019#This is a screen and filter for the ventilation s'
	DB	'haft.',0
L053E:
	retf

H_053F:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_0547
	jmp	SHORT LookAtAccessPanel

H_0547:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_05CE
LookAtAccessPanel:
	cmp	byte ptr [si+access_panel_open], 1
	jne	L05C4
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N017
	call	Say
	jmp	SHORT L05C3

T_LOV3N017	LABEL	BYTE
	DB	'#LOV3\LOV3N017#There is a pile of stripped insulation that fell '
	DB	'out of the Engineering access panel.',0
L05C3:
	retf

L05C4:
	mov	ax, OFFSET S_2711
	mov	bx, OFFSET T_LOV3NA22
	call	Say
	retf

H_05CE:
	SCRIPT	MSG_LOOK, 0Ch, 0, 0, H_05FC
LookAtTank:
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N006
	call	Say
	jmp	SHORT L05FB

T_LOV3N006	LABEL	BYTE
	DB	23h, 4Ch, 4Fh, 56h, 33h, 5Ch, 4Ch, 4Fh, 56h, 33h, 4Eh, 30h
	DB	30h, 36h, 23h, 4Eh, 1Dh
	DB	' gas tank.',0
L05FB:
	retf

H_05FC:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_062D
LookAtReactor:
	mov	ax, OFFSET S_2711
	mov	bx, OFFSET T_LOV3N026
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV3_009
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV3_019
	call	Say
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L062C
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV3_026
	call	Say
L062C:
	retf

H_062D:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0683
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_LOV3_001
	call	Say
	jmp	SHORT L0682

T_LOV3_001	LABEL	BYTE
	DB	'#LOV3\LOV3_001#At least all this equipment appears to be operati'
	DB	'ng.',0
L0682:
	retf

H_0683:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0711
TalkToSpock:
	cmp	byte ptr [si+been_below], 1
	je	L0707
	cmp	byte ptr [si+romulans_out], 1
	jne	L06EC
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV3_017
	call	Say
	jmp	SHORT L06EB

T_LOV3_017	LABEL	BYTE
	DB	'#LOV3\LOV3_017#We should now be able to proceed safely to the lo'
	DB	'wer level.',0
L06EB:
	retf

L06EC:
	push	IT_RLG
	push	RC_HAVEITEM
	SERVICE		; HaveItem(IT_RLG)
	add	sp, 4
	AX8	cmp, 1
	jne	L0707
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV3_004
	call	Say
	retf

L0707:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV3_003
	call	Say
	retf

H_0711:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0797
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV3_008
	call	Say
	jmp	SHORT L0796

T_LOV3_008	LABEL	BYTE
	DB	'#LOV3\LOV3_008#Ah. The station''s fusion reactor. Very nice. What'
	DB	' are we going to tour next, the ventilation system?',0
L0796:
	retf

H_0797:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_07EB
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV3_024
	call	Say
	jmp	SHORT L07EA

T_LOV3_024	LABEL	BYTE
	DB	'#LOV3\LOV3_024#Sir, I''ll watch the door so we don''t get cornered'
	DB	'.',0
L07EA:
	retf

; Tricorders.
H_07EB:
	SCRIPT	MSG_USE, IT_MTRICOR, ANY, 0, H_0898
McCoyScans:
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
	cmp	byte ptr [si+have_research], 1
	je	L088E
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV3_006
	call	Say
	jmp	SHORT L088D

T_LOV3_006	LABEL	BYTE
	DB	'#LOV3\LOV3_006#I''m picking up some strange, airborne virus. I ca'
	DB	'n''t identify it without more information.',0
L088D:
	retf

L088E:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV3_005
	call	Say
	retf

H_0898:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_08C9
SpockScansReactor:
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
	mov	bx, OFFSET T_LOV3_014
	call	Say
	retf

H_08C9:
	SCRIPT	MSG_USE, IT_STRICOR, 9, 0, H_0900
SpockScansInsulation:
	cmp	byte ptr [si+access_panel_open], 1
	jne	L08FF
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscanw
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscanw", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV3_002
	call	Say
L08FF:
	retf

H_0900:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_0931
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
	mov	bx, OFFSET T_LOV3_013
	call	Say
	retf

; The service panel, by anyone (msg 1): open or shut.
H_0931:
	SCRIPT	MSG_USE, OBJ_KIRK, 8, 0, H_0947
KirkOpensServicePanel:
	mov	word ptr cs:crew, 0
	mov	word ptr cs:crew_anim, OFFSET N_kusehe
	jmp	SHORT L0987

H_0947:
	SCRIPT	MSG_USE, OBJ_SPOCK, 8, 0, H_095D
SpockOpensServicePanel:
	mov	word ptr cs:crew, 1
	mov	word ptr cs:crew_anim, OFFSET N_susehe
	jmp	SHORT L0987

H_095D:
	SCRIPT	MSG_USE, OBJ_MCCOY, 8, 0, H_0973
McCoyOpensServicePanel:
	mov	word ptr cs:crew, 2
	mov	word ptr cs:crew_anim, OFFSET N_musehe
	jmp	SHORT L0987

H_0973:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 8, 0, H_099F
FerrisOpensServicePanel:
	mov	word ptr cs:crew, 3
	mov	word ptr cs:crew_anim, OFFSET N_rusehe
L0987:
	push	1
	push	0AEh
	push	104h
	push	word ptr cs:crew
	push	RC_WALK
	SERVICE		; Walk(?, 260, 174, 1)
	add	sp, 0Ah
	retf

H_099F:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_09C0
AtServicePanel:
	push	1
	push	-1
	push	-1
	push	word ptr cs:crew_anim
	push	word ptr cs:crew
	push	RC_ANIM2
	SERVICE		; Anim(?, ?, -1, -1, 1)
	add	sp, 0Ch
	retf

H_09C0:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_0AE5
ServicePanelToggled:
	push	0
	push	0
	push	1
	push	OFFSET N_s3r4d1
	cmp	byte ptr [si+service_panel_open], 1
	jne	L09D9
	pop	ax
	push	OFFSET N_s3r4d1b
L09D9:
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, ?, 1, 0, 0)
	add	sp, 0Ch
	jmp	SHORT L09F0

N_SMADOOR1	LABEL	BYTE
	DB	'SMADOOR1',0
L09F0:
	push	OFFSET N_SMADOOR1
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SMADOOR1")
	add	sp, 4
	xor	byte ptr [si+service_panel_open], 1
	cmp	byte ptr [si+service_panel_open], 1
	je	L0A36
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N020
	call	Say
	jmp	SHORT L0A35

T_LOV3N020	LABEL	BYTE
	DB	'#LOV3\LOV3N020#The panel closes.',0
L0A35:
	retf

L0A36:
	cmp	byte ptr [si+took_n2_tank], 1
	jne	L0A68
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N023
	call	Say
	jmp	SHORT L0A67

T_LOV3N023	LABEL	BYTE
	DB	'#LOV3\LOV3N023#The panel opens.',0
L0A67:
	retf

L0A68:
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N022
	call	Say
	jmp	SHORT L0AE4

T_LOV3N022	LABEL	BYTE
	DB	23h, 4Ch, 4Fh, 56h, 33h, 5Ch, 4Ch, 4Fh, 56h, 33h, 4Eh, 30h
	DB	32h, 32h, 23h, 54h, 68h, 65h, 20h, 70h, 61h, 6Eh, 65h, 6Ch
	DB	20h, 6Fh, 70h, 65h, 6Eh, 73h, 2Eh, 20h, 59h, 6Fh, 75h, 20h
	DB	73h, 65h, 65h, 20h, 61h, 20h, 67h, 61h, 73h, 20h, 74h, 61h
	DB	6Eh, 6Bh, 20h, 6Ch, 61h, 62h, 65h, 6Ch, 65h, 64h, 20h, 4Eh
	DB	1Dh
	DB	', with its feed lines running deeper into the wall.',0
L0AE4:
	retf

; The nitrogen tank: the wrench frees it from its feed lines or fixes it
; back (msgs 2), the antigrav unit then lifts it; another gas won't do.
H_0AE5:
	SCRIPT	MSG_USE, IT_WRENCH, 0Ch, 0, H_0B00
WrenchOnTank:
	push	2
	push	0AEh
	push	10Eh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 270, 174, 2)
	add	sp, 0Ah
	retf

H_0B00:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_0B35
KirkAtTank:
	push	2
	push	-1
	push	-1
	push	OFFSET N_kusehe
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehe", -1, -1, 2)
	add	sp, 0Ch
	jmp	SHORT L0B25

N_MUR3E1S	LABEL	BYTE
	DB	'MUR3E1S',0
L0B25:
	push	OFFSET N_MUR3E1S
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR3E1S")
	add	sp, 4
	retf

H_0B35:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_0C3B
TankWrenched:
	cmp	byte ptr [si+tank_loose], 1
	jne	L0B44
	JMPN	L0BE9

L0B44:
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N012
	call	Say
	jmp	SHORT L0B78

T_LOV3N012	LABEL	BYTE
	DB	'#LOV3\LOV3N012#The tank detaches easily.',0
L0B78:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L0BE4
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV3_022
	call	Say
	jmp	SHORT L0BE4

T_LOV3_022	LABEL	BYTE
	DB	'#LOV3\LOV3_022#I guess this made it easier to replace the tank e'
	DB	'very so often, eh Captain?',0
L0BE4:
	mov	byte ptr [si+tank_loose], 1
	retf

L0BE9:
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N015
	call	Say
	jmp	SHORT L0C36

T_LOV3N015	LABEL	BYTE
	DB	'#LOV3\LOV3N015#The tank is now firmly attached to its feed lines'
	DB	'.',0
L0C36:
	mov	byte ptr [si+tank_loose], 0
	retf

H_0C3B:
	SCRIPT	MSG_USE, IT_WRENCH, IT_O2GAS, 0, H_0C43
	jmp	SHORT WrenchOnOtherTank

H_0C43:
	SCRIPT	MSG_USE, IT_WRENCH, IT_H2GAS, 0, H_0CCA
WrenchOnOtherTank:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV3_016
	call	Say
	jmp	SHORT L0CC9

T_LOV3_016	LABEL	BYTE
	DB	'#LOV3\LOV3_016#This is not wise, Captain. I don''t believe we can'
	DB	' safely substitute a different gas in this location.',0
L0CC9:
	retf

H_0CCA:
	SCRIPT	MSG_USE, IT_WRENCH, IT_N2GAS, 0, H_0CE5
WrenchOnN2Tank:
	push	0Fh
	push	0AEh
	push	10Eh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 270, 174, 15)
	add	sp, 0Ah
	retf

H_0CE5:
	SCRIPT	MSG_WALK_DONE, 0Fh, 0, 0, H_0D1A
KirkAtTankSlot:
	push	3
	push	-1
	push	-1
	push	OFFSET N_kusehe
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehe", -1, -1, 3)
	add	sp, 0Ch
	jmp	SHORT L0D0A

N_MUR3E1S_2	LABEL	BYTE
	DB	'MUR3E1S',0
L0D0A:
	push	OFFSET N_MUR3E1S_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR3E1S")
	add	sp, 4
	retf

H_0D1A:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_0D92
N2TankBack:
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N013
	call	Say
	jmp	SHORT L0D6C

T_LOV3N013	LABEL	BYTE
	DB	'#LOV3\LOV3N013#The tank fits into place and is easy to reattach.',0
L0D6C:
	mov	byte ptr [si+took_n2_tank], 0
	push	IT_N2GAS
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_N2GAS)
	add	sp, 4
	push	0
	push	0
	push	0
	push	OFFSET N_r4n2
	push	0Ch
	push	RC_ANIM0
	SERVICE		; Anim0(12, "r4n2", 0, 0, 0)
	add	sp, 0Ch
	retf

; The access panel (msgs 3, 4): the insulation falls out.
H_0D92:
	SCRIPT	MSG_USE, IT_WRENCH, 20h, 0, H_0DAC
WrenchOnAccessPanel:
	push	3
	push	0B4h
	push	37h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 55, 180, 3)
	add	sp, 0Ah
	retf

H_0DAC:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_0DE1
KirkAtAccessPanel:
	push	4
	push	-1
	push	-1
	push	OFFSET N_kuselw
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuselw", -1, -1, 4)
	add	sp, 0Ch
	jmp	SHORT L0DD1

N_MUR3E1S_3	LABEL	BYTE
	DB	'MUR3E1S',0
L0DD1:
	push	OFFSET N_MUR3E1S_3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR3E1S")
	add	sp, 4
	retf

H_0DE1:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_0E2A
AccessPanelOpen:
	cmp	byte ptr [si+access_panel_open], 1
	je	L0E20
	jmp	SHORT L0DF8

N_MADR4E4A	LABEL	BYTE
	DB	'MADR4E4A',0
L0DF8:
	push	OFFSET N_MADR4E4A
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MADR4E4A")
	add	sp, 4
	push	0
	push	0
	push	0
	push	OFFSET N_s3r4p1
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s3r4p1", 0, 0, 0)
	add	sp, 0Ch
	mov	byte ptr [si+access_panel_open], 1
L0E20:
	mov	ax, OFFSET S_2711
	mov	bx, OFFSET T_LOV3N021
	call	Say
	retf

; Other things on the readouts.
H_0E2A:
	SCRIPT	MSG_USE, IT_WRENCH, 21h, 0, H_0E3A
WrenchOnReadouts:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV3_018
	call	Say
	retf

H_0E3A:
	SCRIPT	MSG_USE, IT_H2O, 21h, 0, H_0E55
WaterOnReadouts:
	push	0Eh
	push	0B2h
	push	0C8h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 200, 178, 14)
	add	sp, 0Ah
	retf

H_0E55:
	SCRIPT	MSG_WALK_DONE, 0Eh, 0, 0, H_0E71
KirkAtReadouts:
	push	6
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 6)
	add	sp, 0Ch
	retf

H_0E71:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_0F01
ReadoutsWet:
	mov	ax, 0
	mov	bx, OFFSET T_LOV3_021
	call	Say
	jmp	SHORT L0EF4

T_LOV3_021	LABEL	BYTE
	DB	'#LOV3\LOV3_021#Good thing the person who designed these stations'
	DB	' built in safeguards against an accidental spill!',0
L0EF4:
	push	IT_H2O
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_H2O)
	add	sp, 4
	retf

; The crew can't open the panels by hand.
H_0F01:
	SCRIPT	MSG_USE, OBJ_KIRK, 20h, 0, H_0F09
	jmp	SHORT SpockOnAccessPanel

H_0F09:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_0F11
SpockOnAccessPanel:
	jmp	SHORT McCoyOnAccessPanel

H_0F11:
	SCRIPT	MSG_USE, OBJ_MCCOY, 20h, 0, H_0F19
McCoyOnAccessPanel:
	jmp	SHORT FerrisOnAccessPanel

H_0F19:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 20h, 0, H_0F21
FerrisOnAccessPanel:
	jmp	SHORT KirkOnVentCover

H_0F21:
	SCRIPT	MSG_USE, OBJ_KIRK, 0Bh, 0, H_0F29
KirkOnVentCover:
	jmp	SHORT SpockOnVentCover

H_0F29:
	SCRIPT	MSG_USE, OBJ_SPOCK, 0Bh, 0, H_0F31
SpockOnVentCover:
	jmp	SHORT McCoyOnVentCover

H_0F31:
	SCRIPT	MSG_USE, OBJ_MCCOY, 0Bh, 0, H_0F39
McCoyOnVentCover:
	jmp	SHORT FerrisOnVentCover

H_0F39:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 0Bh, 0, H_0F7F
FerrisOnVentCover:
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N030
	call	Say
	jmp	SHORT L0F7E

T_LOV3N030	LABEL	BYTE
	DB	'#LOV3\LOV3N030#You need something to pry this open.',0
L0F7E:
	retf

; The vent cover: the wrench opens or closes it (msgs 4, 7), +1 once.
H_0F7F:
	SCRIPT	MSG_USE, IT_WRENCH, 0Bh, 0, H_0F9E
WrenchOnVentCover:
	push	4
	push	0AAh
	push	0F6h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 246, 170, 4)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 1
	retf

H_0F9E:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_0FE9
KirkAtVent:
	push	7
	push	-1
	push	-1
	push	OFFSET N_s3r4g2
	cmp	byte ptr [si+vent_open], 1
	jne	L0FB7
	pop	ax
	push	OFFSET N_s3r4g2a
L0FB7:
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, ?, -1, -1, 7)
	add	sp, 0Ch
	push	0Bh
	push	RC_STOPANIM
	SERVICE		; StopAnim(11)
	add	sp, 4
	jmp	SHORT L0FD9

N_MUR3E1S_4	LABEL	BYTE
	DB	'MUR3E1S',0
L0FD9:
	push	OFFSET N_MUR3E1S_4
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR3E1S")
	add	sp, 4
	retf

H_0FE9:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_108C
VentToggled:
	mov	byte ptr [si+RS_BUSY], 0
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	cmp	byte ptr [si+vent_open], 1
	je	L1036
	mov	byte ptr [si+vent_open], 1
	push	0
	push	0
	push	0
	push	OFFSET N_s3r4g3
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, "s3r4g3", 0, 0, 0)
	add	sp, 0Ch
	mov	ax, OFFSET S_2711
	mov	bx, OFFSET T_LOV3N016
	call	Say
	cmp	byte ptr [si+opened_vent], 1
	je	L1035
	mov	byte ptr [si+opened_vent], 1
	add	word ptr [si+score], 1
L1035:
	retf

L1036:
	push	0
	push	8Fh
	push	116h
	push	OFFSET N_s3r4g1
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, "s3r4g1", 278, 143, 0)
	add	sp, 0Ch
	mov	byte ptr [si+vent_open], 0
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N032
	call	Say
	jmp	SHORT L108B

T_LOV3N032	LABEL	BYTE
	DB	'#LOV3\LOV3N032#You replace the air vent cover.',0
L108B:
	retf

; Gases down the vent: water and laughing gas do nothing, ammonia
; angers the Romulans, Romulan laughing gas puts them out (+6, once)
; unless the virus already has.
H_108C:
	SCRIPT	MSG_USE, OBJ_KIRK, 22h, 0, H_1094
	jmp	SHORT SpockInVent

H_1094:
	SCRIPT	MSG_USE, OBJ_SPOCK, 22h, 0, H_109C
SpockInVent:
	jmp	SHORT McCoyInVent

H_109C:
	SCRIPT	MSG_USE, OBJ_MCCOY, 22h, 0, H_10A4
McCoyInVent:
	jmp	SHORT FerrisInVent

H_10A4:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 22h, 0, H_10EE
FerrisInVent:
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N011
	call	Say
	jmp	SHORT L10ED

T_LOV3N011	LABEL	BYTE
	DB	'#LOV3\LOV3N011#The shaft is too small to crawl through.',0
L10ED:
	retf

H_10EE:
	SCRIPT	MSG_USE, IT_H2O, 22h, 0, H_1109
WaterInVent:
	push	5
	push	0A6h
	push	100h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 256, 166, 5)
	add	sp, 0Ah
	retf

H_1109:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_1135
KirkAtVent2:
	cmp	byte ptr [si+vent_open], 1
	je	L111F
	mov	ax, OFFSET S_2711
	mov	bx, OFFSET T_LOV3N025
	call	Say
	retf

L111F:
	push	8
	push	-1
	push	-1
	push	OFFSET N_kuseme
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseme", -1, -1, 8)
	add	sp, 0Ch
	retf

H_1135:
	SCRIPT	MSG_ANIM_DONE, 8, 0, 0, H_117C
VentWet:
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N009
	call	Say
	jmp	SHORT L116F

T_LOV3N009	LABEL	BYTE
	DB	'#LOV3\LOV3N009#The air vent becomes wet.',0
L116F:
	push	IT_H2O
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_H2O)
	add	sp, 4
	retf

H_117C:
	SCRIPT	MSG_USE, IT_N2O, 22h, 0, H_1197
N2OInVent:
	push	6
	push	0A6h
	push	100h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 256, 166, 6)
	add	sp, 0Ah
	retf

H_1197:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_11C3
KirkAtVent3:
	cmp	byte ptr [si+vent_open], 1
	je	L11AD
	mov	ax, OFFSET S_2711
	mov	bx, OFFSET T_LOV3N025
	call	Say
	retf

L11AD:
	push	9
	push	-1
	push	-1
	push	OFFSET N_kuseme
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseme", -1, -1, 9)
	add	sp, 0Ch
	retf

H_11C3:
	SCRIPT	MSG_ANIM_DONE, 9, 0, 0, H_1293
N2OVented:
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N018
	call	Say
	jmp	SHORT L1200

T_LOV3N018	LABEL	BYTE
	DB	'#LOV3\LOV3N018#There seems to be no effect.',0
L1200:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV3_012
	call	Say
	jmp	SHORT L1286

T_LOV3_012	LABEL	BYTE
	DB	'#LOV3\LOV3_012#Nitrous oxide affects humans, but not Romulans. H'
	DB	'owever, a similar effect can be produced by the gas TLTDH.',0
L1286:
	push	IT_N2O
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_N2O)
	add	sp, 4
	retf

H_1293:
	SCRIPT	MSG_USE, IT_NH3, 22h, 0, H_12AE
NH3InVent:
	push	7
	push	0A6h
	push	100h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 256, 166, 7)
	add	sp, 0Ah
	retf

H_12AE:
	SCRIPT	MSG_WALK_DONE, 7, 0, 0, H_12DA
KirkAtVent4:
	cmp	byte ptr [si+vent_open], 1
	je	L12C4
	mov	ax, OFFSET S_2711
	mov	bx, OFFSET T_LOV3N025
	call	Say
	retf

L12C4:
	push	0Ah
	push	-1
	push	-1
	push	OFFSET N_kuseme
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseme", -1, -1, 10)
	add	sp, 0Ch
	retf

H_12DA:
	SCRIPT	MSG_ANIM_DONE, 0Ah, 0, 0, H_13B2
NH3Vented:
	cmp	byte ptr [si+virus_struck], 1
	jne	L12E9
	JMPN	L13A5

L12E9:
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N001
	call	Say
	jmp	SHORT L132F

T_LOV3N001	LABEL	BYTE
	DB	'#LOV3\LOV3N001#Cursing and coughing echo up the air shaft.',0
L132F:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L13A5
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV3_023
	call	Say
	jmp	SHORT L13A5

T_LOV3_023	LABEL	BYTE
	DB	'#LOV3\LOV3_023#It doesn''t sound like it subdued them, Captain. I'
	DB	'f anything, it just made them angry.',0
L13A5:
	push	IT_NH3
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_NH3)
	add	sp, 4
	retf

H_13B2:
	SCRIPT	MSG_USE, IT_RLG, 22h, 0, H_1433
RLGInVent:
	cmp	byte ptr [si+gassed], 1
	je	L13C6
	mov	byte ptr [si+gassed], 1
	add	word ptr [si+score], 6
L13C6:
	cmp	byte ptr [si+romulans_out], 1
	jne	L141E
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV3_011
	call	Say
	jmp	SHORT L141D

T_LOV3_011	LABEL	BYTE
	DB	'#LOV3\LOV3_011#I think one application of gas is sufficient, Cap'
	DB	'tain.',0
L141D:
	retf

L141E:
	push	8
	push	0A4h
	push	0F6h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 246, 164, 8)
	add	sp, 0Ah
	retf

H_1433:
	SCRIPT	MSG_WALK_DONE, 8, 0, 0, H_1476
KirkAtVent5:
	cmp	byte ptr [si+vent_open], 1
	je	L1449
	mov	ax, OFFSET S_2711
	mov	bx, OFFSET T_LOV3N025
	call	Say
	retf

L1449:
	push	0Bh
	push	-1
	push	-1
	push	OFFSET N_kuseme
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseme", -1, -1, 11)
	add	sp, 0Ch
	jmp	SHORT L1466

N_EFX24	LABEL	BYTE
	DB	'EFX24',0
L1466:
	push	OFFSET N_EFX24
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EFX24")
	add	sp, 4
	retf

H_1476:
	SCRIPT	MSG_ANIM_DONE, 0Bh, 0, 0, H_14C4
RLGVented:
	push	IT_RLG
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_RLG)
	add	sp, 4
	mov	byte ptr [si+romulans_out], 1
	cmp	byte ptr [si+virus_struck], 1
	je	L14B6
	mov	ax, OFFSET S_2711
	mov	bx, OFFSET T_LOV3NA09
	call	Say
	jmp	SHORT L14A6

N_ROMULANL	LABEL	BYTE
	DB	'ROMULANL',0
L14A6:
	push	OFFSET N_ROMULANL
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("ROMULANL")
	add	sp, 4
	retf

L14B6:
	mov	ax, OFFSET S_2711
	mov	bx, OFFSET T_LOV3NA08
	call	Say
	mov	byte ptr [si+romulans_out], 0
	retf

; Getting things.
H_14C4:
	SCRIPT	MSG_GET, 0Ah, 0, 0, H_14DF
GetWrench:
	push	9
	push	0B6h
	push	104h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 260, 182, 9)
	add	sp, 0Ah
	retf

H_14DF:
	SCRIPT	MSG_WALK_DONE, 9, 0, 0, H_14FB
KirkAtWrench:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_s5r1kg
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r1kg", -1, -1, 12)
	add	sp, 0Ch
	retf

H_14FB:
	SCRIPT	MSG_ANIM_DONE, 0Ch, 0, 0, H_1532
TookWrench:
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	push	IT_WRENCH
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_WRENCH)
	add	sp, 4
	push	0Ah
	push	RC_STOPANIM
	SERVICE		; StopAnim(10)
	add	sp, 4
	mov	byte ptr [si+took_wrench], 1
	mov	bx, OFFSET T_LOV3N031
	sub	ax, ax
	call	Say
	retf

H_1532:
	SCRIPT	MSG_GET, 0Ch, 0, 0, H_154D
GetTank:
	push	0Ah
	push	0B7h
	push	121h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 289, 183, 10)
	add	sp, 0Ah
	retf

H_154D:
	SCRIPT	MSG_WALK_DONE, 0Ah, 0, 0, H_1600
KirkAtTank2:
	cmp	byte ptr [si+tank_loose], 1
	jne	L15A3
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N007
	call	Say
	jmp	SHORT L15A2

T_LOV3N007	LABEL	BYTE
	DB	'#LOV3\LOV3N007#The tank is too heavy to move by muscle alone.',0
L15A2:
	retf

L15A3:
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N014
	call	Say
	jmp	SHORT L15FF

T_LOV3N014	LABEL	BYTE
	DB	'#LOV3\LOV3N014#The tank is large and heavy, with its feed lines '
	DB	'firmly attached.',0
L15FF:
	retf

H_1600:
	SCRIPT	MSG_USE, IT_ANTIGRA, 0Ch, 0, H_161B
AntigravOnTank:
	push	0Bh
	push	0AEh
	push	10Eh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 270, 174, 11)
	add	sp, 0Ah
	retf

H_161B:
	SCRIPT	MSG_WALK_DONE, 0Bh, 0, 0, H_165A
KirkAtTank3:
	cmp	byte ptr [si+tank_loose], 1
	je	L162A
	JMPN	L1730

L162A:
	push	0Dh
	push	-1
	push	-1
	push	OFFSET N_kusehe
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehe", -1, -1, 13)
	add	sp, 0Ch
	jmp	SHORT L164A

N_SE3PLBAT	LABEL	BYTE
	DB	'SE3PLBAT',0
L164A:
	push	OFFSET N_SE3PLBAT
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SE3PLBAT")
	add	sp, 4
	retf

H_165A:
	SCRIPT	MSG_ANIM_DONE, 0Dh, 0, 0, H_181C
TankLifted:
	push	IT_N2GAS
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_N2GAS)
	add	sp, 4
	push	0Ch
	push	RC_STOPANIM
	SERVICE		; StopAnim(12)
	add	sp, 4
	mov	byte ptr [si+took_n2_tank], 1
	mov	ax, 0
	mov	bx, OFFSET T_LOV3NJ32
	call	Say
	jmp	SHORT L16DC

T_LOV3NJ32	LABEL	BYTE
	DB	'#LOV3\LOV3NJ32#You attach the antigrav unit to the gas tank. It '
	DB	'can be moved freely.',0
L16DC:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L172F
	mov	ax, OFFSET N_Lt_Ferris
	mov	bx, OFFSET T_LOV3_025
	call	Say
	jmp	SHORT L172F

T_LOV3_025	LABEL	BYTE
	DB	'#LOV3\LOV3_025#It sure beats hauling it around on our backs, sir'
	DB	'.',0
L172F:
	retf

L1730:
	mov	ax, 0
	mov	bx, OFFSET T_LOV3N010
	call	Say
	jmp	SHORT L1793

T_LOV3N010	LABEL	BYTE
	DB	'#LOV3\LOV3N010#The antigrav unit hums and emits the stink of ozo'
	DB	'ne before it failsafes.',0
L1793:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV3_015
	call	Say
	jmp	SHORT L181B

T_LOV3_015	LABEL	BYTE
	DB	'#LOV3\LOV3_015#The unit cannot lift something fastened to the bo'
	DB	'dy of the station, Captain. The tank must be detached first.',0
L181B:
	retf

H_181C:
	SCRIPT	MSG_GET, 9, 0, 0, H_1836
GetInsulation:
	push	0Ch
	push	0BEh
	push	32h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 50, 190, 12)
	add	sp, 0Ah
	retf

H_1836:
	SCRIPT	MSG_WALK_DONE, 0Ch, 0, 0, H_1858
KirkAtInsulation:
	cmp	byte ptr [si+never_set], 1
	je	L187E
	push	0Eh
	push	-1
	push	-1
	push	OFFSET N_s5r1kg
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "s5r1kg", -1, -1, 14)
	add	sp, 0Ch
	retf

H_1858:
	SCRIPT	MSG_ANIM_DONE, 0Eh, 0, 0, H_1890
TookInsulation:
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	push	IT_INSULAT
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_INSULAT)
	add	sp, 4
	mov	bx, OFFSET T_LOV3N029
	sub	ax, ax
	call	Say
L187E:
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
H_1890:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_1AAD
CrewLaugh:
	push	2
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 2)
	add	sp, 6
	mov	word ptr cs:roll, ax
	cmp	word ptr cs:roll, 0
	jne	L18B9
	mov	word ptr cs:laugher, OFFSET N_Dr_McCoy
	jmp	SHORT L18F6

L18B9:
	cmp	word ptr cs:roll, 1
	jne	L18DA
	mov	word ptr cs:laugher, OFFSET N_Lt_Ferris
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L18D8
	mov	word ptr cs:laugher, OFFSET N_Dr_McCoy
	JMPN	L19A1

L18D8:
	jmp	SHORT L18F6

L18DA:
	mov	ax, 0
	mov	bx, OFFSET N_get_name_error
	call	Say
	jmp	SHORT L18F5

N_get_name_error	LABEL	BYTE
	DB	'get name error.',0
L18F5:
	retf

L18F6:
	mov	word ptr cs:laugher, OFFSET N_Dr_McCoy
	push	0Ah
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 10)
	add	sp, 6
	mov	word ptr cs:roll, ax
	cmp	word ptr cs:roll, 0
	jne	L191D
	mov	bx, OFFSET T_LOV0_011
	JMPN	L1A48

L191D:
	cmp	word ptr cs:roll, 1
	jne	L192B
	mov	bx, OFFSET T_LOV0_020
	JMPN	L1A48

L192B:
	cmp	word ptr cs:roll, 2
	jne	L1939
	mov	bx, OFFSET T_LOV0_016
	JMPN	L1A48

L1939:
	cmp	word ptr cs:roll, 3
	jne	L1947
	mov	bx, OFFSET T_LOV0_012
	JMPN	L1A48

L1947:
	cmp	word ptr cs:roll, 4
	jne	L1955
	mov	bx, OFFSET T_LOV0_014
	JMPN	L1A48

L1955:
	cmp	word ptr cs:roll, 5
	jne	L1963
	mov	bx, OFFSET T_LOV0_022
	JMPN	L1A48

L1963:
	cmp	word ptr cs:roll, 6
	jne	L1971
	mov	bx, OFFSET T_LOV0_015
	JMPN	L1A48

L1971:
	cmp	word ptr cs:roll, 7
	jne	L197F
	mov	bx, OFFSET T_LOV0_021
	JMPN	L1A48

L197F:
	cmp	word ptr cs:roll, 8
	jne	L198D
	mov	bx, OFFSET T_LOV0_013
	JMPN	L1A48

L198D:
	cmp	word ptr cs:roll, 9
	jne	L199B
	mov	bx, OFFSET T_LOV0_019
	JMPN	L1A48

L199B:
	mov	bx, OFFSET T_LOV0_017
	JMPN	L1A48

L19A1:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L19A8
	retf

L19A8:
	mov	word ptr cs:laugher, OFFSET N_Lt_Ferris
	push	0Ah
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 10)
	add	sp, 6
	mov	word ptr cs:roll, ax
	cmp	word ptr cs:roll, 0
	jne	L19CE
	mov	bx, OFFSET T_LOV0_039
	jmp	SHORT L1A48

L19CE:
	cmp	word ptr cs:roll, 1
	jne	L19DB
	mov	bx, OFFSET T_LOV0_048
	jmp	SHORT L1A48

L19DB:
	cmp	word ptr cs:roll, 2
	jne	L19E8
	mov	bx, OFFSET T_LOV0_045
	jmp	SHORT L1A48

L19E8:
	cmp	word ptr cs:roll, 3
	jne	L19F5
	mov	bx, OFFSET T_LOV0_040
	jmp	SHORT L1A48

L19F5:
	cmp	word ptr cs:roll, 4
	jne	L1A02
	mov	bx, OFFSET T_LOV0_042
	jmp	SHORT L1A48

L1A02:
	cmp	word ptr cs:roll, 5
	jne	L1A0F
	mov	bx, OFFSET T_LOV0_050
	jmp	SHORT L1A48

L1A0F:
	cmp	word ptr cs:roll, 6
	jne	L1A1C
	mov	bx, OFFSET T_LOV0_043
	jmp	SHORT L1A48

L1A1C:
	cmp	word ptr cs:roll, 7
	jne	L1A29
	mov	bx, OFFSET T_LOV0_049
	jmp	SHORT L1A48

L1A29:
	cmp	word ptr cs:roll, 8
	jne	L1A36
	mov	bx, OFFSET T_LOV0_041
	jmp	SHORT L1A48

L1A36:
	cmp	word ptr cs:roll, 9
	jne	L1A43
	mov	bx, OFFSET T_LOV0_047
	jmp	SHORT L1A48

L1A43:
	mov	bx, OFFSET T_LOV0_046
	jmp	SHORT L1A48

L1A48:
	mov	ax, word ptr cs:laugher
	call	Say
	cmp	byte ptr [si+rlg_released], 1
	jne	L1A56
	retf

L1A56:
	push	3
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 3)
	add	sp, 6
	mov	word ptr cs:roll, ax
	mov	ax, OFFSET N_Mr_Spock
	cmp	word ptr cs:roll, 0
	jne	L1A78
	mov	bx, OFFSET T_LOV0_029
	jmp	SHORT L1A97

L1A78:
	cmp	word ptr cs:roll, 1
	jne	L1A85
	mov	bx, OFFSET T_LOV0_033
	jmp	SHORT L1A97

L1A85:
	cmp	word ptr cs:roll, 2
	jne	L1A92
	mov	bx, OFFSET T_LOV0_026
	jmp	SHORT L1A97

L1A92:
	mov	bx, OFFSET T_LOV0_124
	jmp	SHORT L1A97

L1A97:
	call	Say
	push	190h
	push	0C8h
	push	RC_RANDOM
	SERVICE		; Random(200, 400)
	add	sp, 6
	mov	word ptr [si+RS_TIMERS], ax
	retf

; Timer 1 (after Romulan laughing gas): Spock laughs.
H_1AAD:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_1B3F
SpockLaughs:
	push	7
	push	0
	push	RC_RANDOM
	SERVICE		; Random(0, 7)
	add	sp, 6
	mov	word ptr cs:roll, ax
	mov	ax, OFFSET N_Mr_Spock
	cmp	word ptr cs:roll, 0
	jne	L1AD5
	mov	bx, OFFSET T_LOV0_025
	jmp	SHORT L1B28

L1AD5:
	cmp	word ptr cs:roll, 1
	jne	L1AE2
	mov	bx, OFFSET T_LOV0_101
	jmp	SHORT L1B28

L1AE2:
	cmp	word ptr cs:roll, 2
	jne	L1AEF
	mov	bx, OFFSET T_LOV0_102
	jmp	SHORT L1B28

L1AEF:
	cmp	word ptr cs:roll, 3
	jne	L1AFC
	mov	bx, OFFSET T_LOV0_103
	jmp	SHORT L1B28

L1AFC:
	cmp	word ptr cs:roll, 4
	jne	L1B09
	mov	bx, OFFSET T_LOV0_104
	jmp	SHORT L1B28

L1B09:
	cmp	word ptr cs:roll, 5
	jne	L1B16
	mov	bx, OFFSET T_LOV0_105
	jmp	SHORT L1B28

L1B16:
	cmp	word ptr cs:roll, 6
	jne	L1B23
	mov	bx, OFFSET T_LOV0_106
	jmp	SHORT L1B28

L1B23:
	mov	bx, OFFSET T_LOV0_107
	jmp	SHORT L1B28

L1B28:
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
H_1B3F:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_SPOCK, 0, H_1BCD
MedkitOnSpock:
	cmp	byte ptr [si+spock_cured], 1
	je	L1B99
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_019
	call	Say
	jmp	SHORT L1B98

T_LOV5_019	LABEL	BYTE
	DB	'#LOV5\LOV5_019#I don''t have the proper medicine to cure him, Jim'
	DB	'.',0
L1B98:
	retf

L1B99:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_015
	call	Say
	jmp	SHORT L1BCC

T_LOV5_015	LABEL	BYTE
	DB	'#LOV5\LOV5_015#He''s already cured, Jim.',0
L1BCC:
	retf

H_1BCD:
	SCRIPT	MSG_USE, IT_SAMPLE, OBJ_SPOCK, 0, H_1C40
SampleOnSpock:
	cmp	byte ptr [si+spock_cured], 1
	jne	L1BDC
	JMPN	L1C80

L1BDC:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F55
	call	Say
	jmp	SHORT L1C3F

T_LOVA_F55	LABEL	BYTE
	DB	'#LOVA\LOVA_F55#Jim, we need to sysnthesize more to make the seru'
	DB	'm before we can use it.',0
L1C3F:
	retf

H_1C40:
	SCRIPT	MSG_USE, IT_CURE, OBJ_SPOCK, 0, H_1CBC
CureSpock:
	cmp	byte ptr [si+spock_cured], 1
	jne	L1C80
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_015_2
	call	Say
	jmp	SHORT L1C7F

T_LOV5_015_2	LABEL	BYTE
	DB	'#LOV5\LOV5_015#He''s already cured, Jim.',0
L1C7F:
	retf

L1C80:
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

H_1CBC:
	SCRIPT	MSG_WALK_DONE, 63h, 0, 0, H_1CE6
AtSpock:
	inc	byte ptr cs:cure_steps
	cmp	byte ptr cs:cure_steps, 2
	je	L1CD0
	retf

L1CD0:
	push	63h
	push	-1
	push	-1
	push	OFFSET N_musemn
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musemn", -1, -1, 99)
	add	sp, 0Ch
	retf

H_1CE6:
	SCRIPT	MSG_ANIM_DONE, 63h, 0, 0, H_1DA5
SpockCured:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_030
	call	Say
	jmp	SHORT L1D1F

T_LOV5_030	LABEL	BYTE
	DB	'#LOV5\LOV5_030#There. You''re now cured.',0
L1D1F:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOV5_038
	call	Say
	jmp	SHORT L1D4C

T_LOV5_038	LABEL	BYTE
	DB	'#LOV5\LOV5_038#Thank you, Doctor.',0
L1D4C:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOV5_027
	call	Say
	jmp	SHORT L1D81

T_LOV5_027	LABEL	BYTE
	DB	'#LOV5\LOV5_027#Finally, a human response!',0
L1D81:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_1D8C
	call	Say
	jmp	SHORT L1DA0

S_1D8C	LABEL	BYTE
	DB	'(raises an eyebrow)',0
L1DA0:
	mov	byte ptr [si+spock_cured], 1
	retf

; Timer 2, every 200 ticks until Spock is cured: the virus advances,
; with a line at 0Fh, 1Eh, 2Dh; at 3Ch Spock collapses, at 64h he dies.
H_1DA5:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_1F5B
VirusProgresses:
	cmp	byte ptr [si+spock_cured], 1
	jne	L1DB2
	retf

L1DB2:
	inc	byte ptr [si+virus]
	cmp	byte ptr [si+virus], 64h
	jl	L1DBE
	JMPN	L1F0B

L1DBE:
	cmp	byte ptr [si+virus], 0Fh
	jne	L1DF5
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_spokcoff
	call	Say
	jmp	SHORT L1DEF

T_spokcoff	LABEL	BYTE
	DB	'#sfx\spokcoff#cough... cough...',0
L1DEF:
	inc	byte ptr [si+virus]
	JMPN	L1F05

L1DF5:
	cmp	byte ptr [si+virus], 1Eh
	jne	L1E5B
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F08
	call	Say
	jmp	SHORT L1E55

T_LOVA_F08	LABEL	BYTE
	DB	'#LOVA\LOVA_F08#It''s what I was afraid of, Jim. I think spock is '
	DB	'getting worse.',0
L1E55:
	inc	byte ptr [si+virus]
	JMPN	L1F05

L1E5B:
	cmp	byte ptr [si+virus], 2Dh
	jne	L1E91
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_spokcoff_2
	call	Say
	jmp	SHORT L1E8C

T_spokcoff_2	LABEL	BYTE
	DB	'#sfx\spokcoff#cough... cough...',0
L1E8C:
	inc	byte ptr [si+virus]
	jmp	SHORT L1F05

L1E91:
	cmp	byte ptr [si+virus], 3Ch
	jne	L1F05
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_LOVA_F54
	call	Say
	jmp	SHORT L1EFC

T_LOVA_F54	LABEL	BYTE
	DB	'#LOVA\LOVA_F54#The virus has spread to me, Captain.Isuggestyouco'
	DB	'ncentrateyoureffortsonthe',0
L1EFC:
	mov	byte ptr [si+virus_struck], 1
	inc	byte ptr [si+virus]
	jmp	SHORT L1F05

L1F05:
	mov	word ptr [si+RS_TIMERS+4], 0C8h
	retf

L1F0B:
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
	jmp	SHORT L1F50

T_GENER004	LABEL	BYTE
	DB	'#GENE\GENER004#Game Over',0
L1F50:
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	retf

; McCoy's tricorder on Spock follows the virus; on the others, normal.
H_1F5B:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_SPOCK, 0, H_21CC
McCoyScansSpock:
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	cmp	byte ptr [si+spock_cured], 1
	jne	L1FB5
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F01
	call	Say
	jmp	SHORT L1FB4

T_LOVA_F01	LABEL	BYTE
	DB	'#LOVA\LOVA_F01#He''s been cured of the Oroborus virus.',0
L1FB4:
	retf

L1FB5:
	cmp	byte ptr [si+have_research], 1
	je	L2027
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F02
	call	Say
	jmp	SHORT L2026

T_LOVA_F02	LABEL	BYTE
	DB	'#LOVA\LOVA_F02#I''m picking up some kind of virus. I can''t identi'
	DB	'fy it without more information.',0
L2026:
	retf

L2027:
	cmp	byte ptr [si+virus], 0Ah
	jge	L207C
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F04
	call	Say
	jmp	SHORT L207B

T_LOVA_F04	LABEL	BYTE
	DB	'#LOVA\LOVA_F04#The virus affects the Romulan-Vulcan genotype, Ji'
	DB	'm.',0
L207B:
	retf

L207C:
	cmp	byte ptr [si+virus], 1Eh
	jge	L20C0
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F03
	call	Say
	jmp	SHORT L20BF

T_LOVA_F03	LABEL	BYTE
	DB	'#LOVA\LOVA_F03#He''s infected with the virus, Jim.',0
L20BF:
	retf

L20C0:
	cmp	byte ptr [si+virus], 32h
	jge	L2121
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F08_2
	call	Say
	jmp	SHORT L2120

T_LOVA_F08_2	LABEL	BYTE
	DB	'#LOVA\LOVA_F08#It''s what I was afraid of, Jim. I think spock is '
	DB	'getting worse.',0
L2120:
	retf

L2121:
	cmp	byte ptr [si+virus], 46h
	jne	L2167
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG2_010
	call	Say
	jmp	SHORT L2166

T_TUG2_010	LABEL	BYTE
	DB	'#TUG2\TUG2_010#I don''t like the looks of this, Jim.',0
L2166:
	retf

L2167:
	cmp	byte ptr [si+virus], 64h
	jge	L21A1
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F10
	call	Say
	jmp	SHORT L21A0

T_LOVA_F10	LABEL	BYTE
	DB	'#LOVA\LOVA_F10#He has weak vital signs.',0
L21A0:
	retf

L21A1:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_100
	call	Say
	jmp	SHORT L21CB

T_LOVA_100	LABEL	BYTE
	DB	'#LOVA\LOVA_100#He''s dead, Jim.',0
L21CB:
	retf

H_21CC:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_KIRK, 0, H_21D4
	jmp	SHORT McCoyScansMcCoy

H_21D4:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_MCCOY, 0, H_21DC
McCoyScansMcCoy:
	jmp	SHORT McCoyScansCrew

H_21DC:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_REDSHIRT, 0, H_2223
McCoyScansCrew:
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_LOVA_F07
	call	Say
	jmp	SHORT L2222

T_LOVA_F07	LABEL	BYTE
	DB	'#LOVA\LOVA_F07#All lifesigns are normal.',0
L2222:
	retf

; Opening a gas canister: Romulan laughing gas sets Spock laughing,
; nitrous oxide the crew, ammonia nothing.
H_2223:
	SCRIPT	MSG_USE, IT_RLG, ANY, 0, H_2273
ReleaseRLG:
	mov	ax, OFFSET S_2711
	mov	bx, OFFSET T_LOV2N005
	call	Say
	jmp	SHORT L2262

T_LOV2N005	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L2262:
	mov	byte ptr [si+rlg_released], 1
	push	IT_RLG
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_RLG)
	add	sp, 4
	retf

H_2273:
	SCRIPT	MSG_USE, IT_N2O, ANY, 0, H_2305
ReleaseN2O:
	mov	ax, OFFSET S_2711
	mov	bx, OFFSET T_LOV2N005_2
	call	Say
	jmp	SHORT L22B2

T_LOV2N005_2	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L22B2:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD2_040
	call	Say
	jmp	SHORT L22E8

T_MUD2_040	LABEL	BYTE
	DB	'#MUD2\MUD2_040#You look troubled, Captain.',0
L22E8:
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

H_2305:
	SCRIPT	MSG_USE, IT_NH3, ANY, 0, H_236B
ReleaseNH3:
	mov	ax, OFFSET S_2711
	mov	bx, OFFSET T_LOV2N005_3
	call	Say
	jmp	SHORT L2344

T_LOV2N005_3	LABEL	BYTE
	DB	'#LOV2\LOV2N005#A loud hissing fills the room.',0
L2344:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L234A
L234A:
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
H_236B:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, rdf_scripts_end
CallEnterprise:
	cmp	byte ptr [si+made_cure], 1
	jne	L237A
	JMPN	L24C7

L237A:
	cmp	byte ptr [si+called_ship], 1
	jne	L2383
	JMPN	L2427

L2383:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018
	call	Say
	jmp	SHORT L23C8

T_MUD4_018	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L23C8:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146
	call	Say
	jmp	SHORT L23FE

T_BRIDU146	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L23FE:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41
	call	Say
	jmp	SHORT L2422

T_VENA_F41	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L2422:
	mov	byte ptr [si+called_ship], 1
	retf

L2427:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_2
	call	Say
	jmp	SHORT L246C

T_MUD4_018_2	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L246C:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_2
	call	Say
	jmp	SHORT L24A2

T_BRIDU146_2	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L24A2:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_2
	call	Say
	jmp	SHORT L24C6

T_VENA_F41_2	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L24C6:
	retf

L24C7:
	cmp	byte ptr [si+called_ship_cured], 1
	jne	L24D0
	JMPN	L2574

L24D0:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_3
	call	Say
	jmp	SHORT L2515

T_MUD4_018_3	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L2515:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_3
	call	Say
	jmp	SHORT L254B

T_BRIDU146_3	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L254B:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_3
	call	Say
	jmp	SHORT L256F

T_VENA_F41_3	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L256F:
	mov	byte ptr [si+called_ship_cured], 1
	retf

L2574:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_4
	call	Say
	jmp	SHORT L25B9

T_MUD4_018_4	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L25B9:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146_4
	call	Say
	jmp	SHORT L25EF

T_BRIDU146_4	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L25EF:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VENA_F41_4
	call	Say
	jmp	SHORT L2613

T_VENA_F41_4	LABEL	BYTE
	DB	'#VENA\VENA_F41#Kirk out.',0
L2613:
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
	DW	21,164, 46,154, 45,171, 21,188
	DW	21h, 4	; id, points
	DW	192,137, 229,137, 229,153, 192,153
	DW	22h, 4	; id, points
	DW	256,121, 278,123, 278,144, 256,140
	DW	23h, 4	; id, points
	DW	55,23, 243,23, 243,77, 55,77
	DW	23h, 4	; id, points
	DW	33,78, 264,78, 264,108, 33,108
	DW	23h, 4	; id, points
	DW	60,109, 236,109, 236,127, 60,109
	DW	23h, 4	; id, points
	DW	107,128, 189,128, 189,160, 107,160
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	1, 4	; id, points
	DW	0,198, 319,198, 319,199, 0,199
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's3r4l1',0
	DB	's3r4l2',0
	DB	's3r4l3',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Ferris	LABEL	BYTE
	DB	'Lt. Ferris',0
S_2711	LABEL	BYTE
	DB	0
T_LOV3NA22	LABEL	BYTE
	DB	'#LOV3\LOV3NA22#This is an engineering access panel, allowing rep'
	DB	'airs to be made to the interior wiring in the equipment.',0
T_LOV3NA20	LABEL	BYTE
	DB	'#LOV3\LOV3NA20#This is a service access panel, permitting used-u'
	DB	'p or worn materials to be replaced.',0
T_LOV3_	LABEL	BYTE
	DB	'#LOV3\LOV3_#All readings are normal.',0
T_LOV3N002	LABEL	BYTE
	DB	'#LOV3\LOV3N002#It''s a standard adjustable metric socket wrench.',0
T_LOV3N003	LABEL	BYTE
	DB	'#LOV3\LOV3N003#Kirk is looking closely at the equipment.',0
T_LOV3N005	LABEL	BYTE
	DB	'#LOV3\LOV3N005#McCoy is fidgeting around.',0
T_LOV3N008	LABEL	BYTE
	DB	'#LOV3\LOV3N008#Spock is analyzing the surroundings.',0
T_LOV3N004	LABEL	BYTE
	DB	'#LOV3\LOV3N004#Lt. Ferris is carefully watching the hallway',0
	DB	'#LOV3\LOV3N024#This is the engineering room. All appears normal.',0
T_LOV3N026	LABEL	BYTE
	DB	'#LOV3\LOV3N026#Turbines of a Cochrane-500 Class Fusion drive, ma'
	DB	'nufactured over a century ago on Alpha Centuri.',0
T_LOV3_009	LABEL	BYTE
	DB	'#LOV3\LOV3_009#I didn''t realize that they used these old fusion '
	DB	'reactors anymore.',0
T_LOV3_019	LABEL	BYTE
	DB	'#LOV3\LOV3_019#Actually, doctor, as Mr. Scott would tell you, th'
	DB	'e Cochrane-500 is renowned for its reliability and perfectly sui'
	DB	'ted for a station of this size.',0
T_LOV3_026	LABEL	BYTE
	DB	'#LOV3\LOV3_026#Hey, this thing''s real old, isn''t it?',0
T_LOV3_003	LABEL	BYTE
	DB	'#LOV3\LOV3_003#Captain, the fusion reactor doesn''t seem to have '
	DB	'been tampered with. I suggest we leave the controls as they are.',0
T_LOV3_004	LABEL	BYTE
	DB	'#LOV3\LOV3_004#Captain, we can introduce the Romulan Laughing Ga'
	DB	's into the station''s ventilation system from here.',0
T_LOV3_005	LABEL	BYTE
	DB	'#LOV3\LOV3_005#Except for the Oroborus virus, I''m not picking up'
	DB	' anything unusual.',0
T_LOV3_013	LABEL	BYTE
	DB	'#LOV3\LOV3_013#Nothing unusual is detected.',0
T_LOV3_014	LABEL	BYTE
	DB	'#LOV3\LOV3_014#The fusion reactor is functioning at peak efficie'
	DB	'ncy. There is no need to tamper with its current operation.',0
T_LOV3_002	LABEL	BYTE
	DB	'#LOV3\LOV3_002#A prime source of raw material for TLDTH gas.',0
T_LOV3N031	LABEL	BYTE
	DB	'#LOV3\LOV3N031#You pick up a large wrench.',0
	DB	'#LOV3\LOV3N028#You already have the wrench.',0
T_LOV3N029	LABEL	BYTE
	DB	'#LOV3\LOV3N029#You grab a handful of insulation.',0
	DB	'#LOV3\LOV3N027#You already have some insulation.',0
T_LOV3N021	LABEL	BYTE
	DB	'#LOV3\LOV3N021#The panel is open. You see vast quantities of dus'
	DB	't and stripped insulation from wiring repairs made to the consol'
	DB	'e in the past.',0
T_LOV3_018	LABEL	BYTE
	DB	'#LOV3\LOV3_018#Captain, the instruments are far too delicate for'
	DB	' such abuse. We may set off a chain reaction that would destroy '
	DB	'the entire space station.',0
T_LOV3N016	LABEL	BYTE
	DB	'#LOV3\LOV3N016#The vent is now open. It leads to the lower deck.',0
T_LOV3N025	LABEL	BYTE
	DB	'#LOV3\LOV3N025#This vent is currently closed.',0
T_LOV3NA09	LABEL	BYTE
	DB	'#LOV3\LOV3NA09#With a hiss, the Romulan Laughing Gas billows dow'
	DB	'n the vent. You hear the muffled sounds through the vent of hear'
	DB	'ty Romulan laughter, followed by the dull thud of bodies hitting'
	DB	' the deck.',0
T_LOV3NA08	LABEL	BYTE
	DB	'#LOV3\LOV3NA08#With a hiss, the Romulan Laughing Gas billows dow'
	DB	'n the vent. Things are strangely quiet below.',0
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
	DB	'#LOV3\LOV3_007#Ouch!',0
	DB	'dialog error',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
