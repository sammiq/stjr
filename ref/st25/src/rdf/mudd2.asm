; MUDD2.RDF - "Another Fine Mess", the alien ship's sickbay. On the
; party's second visit Mudd staggers in, raving: he has tried an alien
; drug. Spock can hold him with a nerve pinch, and once McCoy has learned
; the aliens' physiology (room 3) and loaded the alien capsules into the
; dispenser, McCoy treats him on one of the beds.
;
; Actors: 8 Mudd, 9 the vial he dropped, 10 (0Ah) the upper door.
; Objects: 8 Mudd, 20h the capsules, 23h the monitoring station and
; dispenser, 24h/25h the beds.
; Exits: 2 room 1, 3 room 4. Regions 0, 1: the doorsteps.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - McCoyScansMuddNever's key is 45h, 8, 0, 0, not MSG_USE, IT_MTRICOR, 8,
;   0, so it never runs; and using a bed once McCoy is ready walks Kirk
;   with message 7, which nothing handles.
; - The conversation at 0104 is built at run time.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
know_physiology	EQU	RS_VARS+0Dh	; McCoy understands the aliens' physiology (room 3)
mudd_here	EQU	RS_VARS+10h	; Mudd is in the room
used_device	EQU	RS_VARS+13h	; the alien device has been fired, anywhere (+5 once)
mudd_incident	EQU	RS_VARS+16h	; Mudd is causing trouble somewhere: no other scene with him starts
air_failing	EQU	RS_VARS+1Dh	; life support is failing: the countdown runs (room 5)
capsules_loaded	EQU	RS_VARS+23h	; the capsules are in the beds' dispenser
mudd_held	EQU	RS_VARS+24h	; Spock has Mudd in a hold
sickbay	EQU	RS_VARS+25h	; 0 not yet visited, 1 visited, 2 Mudd raving here, 3 cured
mudd_raving	EQU	RS_VARS+26h
air_left	EQU	RS_VARS+27h	; word: ticks of air left, from 6978h
air_countdown	EQU	RS_VARS+29h	; word: the countdown has started
score	EQU	RS_VARS+31h	; word: the mission's score

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0C7h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	69h
rdf_scale_min	LABEL	BYTE
	DW	6Eh	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, -1, 1, 4	; room for each exit
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
	DW	102,121, 264,187	; entrance 2, crew 0
	DW	78,119, 280,196	; entrance 2, crew 1
	DW	90,118, 254,178	; entrance 2, crew 2
	DW	70,112, 279,174	; entrance 2, crew 3
	DW	193,123, 264,187	; entrance 3, crew 0
	DW	200,114, 280,196	; entrance 3, crew 1
	DW	180,114, 254,178	; entrance 3, crew 2
	DW	190,107, 279,174	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	264,187, 280,196, 254,178, 279,174	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	264,187, 280,196, 254,178, 279,174
; In the room file, so these start again each time the room loads
going_door	LABEL	BYTE
	DB	0
collapsed	LABEL	BYTE	; crew members down when the air ran out
	DB	0
N_s4sbdo	LABEL	BYTE
	DB	's4sbdo',0
N_s4cbxp	LABEL	BYTE
	DB	's4cbxp',0
N_kgetds	LABEL	BYTE
	DB	'kgetds',0
N_sgetdw	LABEL	BYTE
	DB	'sgetdw',0
N_mgetde	LABEL	BYTE
	DB	'mgetde',0
N_rgetde	LABEL	BYTE
	DB	'rgetde',0
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_mscanw	LABEL	BYTE
	DB	'mscanw',0
talk_buf	LABEL	BYTE
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
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
N_Lt_Buchert	LABEL	BYTE
	DB	'Lt. Buchert',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
N_Harry_Mudd	LABEL	BYTE
	DB	'Harry Mudd',0
S_018D	LABEL	BYTE
	DB	0
rdf_objects	LABEL	BYTE
	DW	20h, 4	; id, points
	DW	150,100, 170,100, 170,144, 150,144
	DW	21h, 3	; id, points
	DW	189,71, 205,120, 174,120
	DW	22h, 3	; id, points
	DW	52,70, 86,109, 61,114
	DW	23h, 4	; id, points
	DW	147,148, 174,148, 174,162, 147,162
	DW	24h, 7	; id, points
	DW	69,183, 69,174, 80,160, 111,146, 139,146, 139,179
	DW	75,189
	DW	25h, 7	; id, points
	DW	246,187, 182,182, 182,144, 213,145, 242,160, 257,174
	DW	252,182
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	3, 4	; id, points
	DW	174,104, 205,104, 205,108, 174,108
	DW	2, 3	; id, points
	DW	59,107, 84,109, 60,114
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	174,109, 205,109, 205,120, 205,120
	DW	1, 4	; id, points
	DW	85,109, 90,112, 73,116, 67,114
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	'm2',0
	DB	6Dh, 33h, 0

rdf_scripts:
rdf_bans_end:
; The doors: walk there; at the step the door slides (regions 0, 1).
H_0268:
	SCRIPT	MSG_WALK, 21h, 0, 0, H_0295
WalkToUpperDoor:
	mov	byte ptr cs:going_door, 1
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0
	push	ax
	mov	ax, 6Ah
	push	ax
	mov	ax, 0BCh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 188, 106, 0)
	add	sp, 0Ah
	retf

H_0295:
	SCRIPT	MSG_REGION, 0, 0, 0, H_02D4
ReachUpperDoor:
	cmp	byte ptr cs:going_door, 1
	jne	L02D3
	jmp	SHORT L02AE

N_SMADOOR3	LABEL	BYTE
	DB	'SMADOOR3',0
L02AE:
	push	OFFSET N_SMADOOR3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SMADOOR3")
	add	sp, 4
	push	0
	push	6Bh
	push	0BEh
	push	OFFSET N_s4sbdo
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "s4sbdo", 190, 107, 0)
	add	sp, 0Ch
L02D3:
	retf

H_02D4:
	SCRIPT	MSG_WALK, 22h, 0, 0, H_0301
WalkToLeftDoor:
	mov	byte ptr cs:going_door, 1
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0
	push	ax
	mov	ax, 6Fh
	push	ax
	mov	ax, 46h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 70, 111, 0)
	add	sp, 0Ah
	retf

H_0301:
	SCRIPT	MSG_REGION, 1, 0, 0, H_032A
ReachLeftDoor:
	cmp	byte ptr cs:going_door, 1
	jne	L0329
	jmp	SHORT L031A

N_SMADOOR3_2	LABEL	BYTE
	DB	'SMADOOR3',0
L031A:
	push	OFFSET N_SMADOOR3_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SMADOOR3")
	add	sp, 4
L0329:
	retf

; The room starts. On the second visit (and no other trouble with Mudd
; under way) Mudd is here, having taken an alien drug: timer 1 brings
; him on, raving. Later visits: Mudd raving, held, or gone once cured.
H_032A:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0434
StartRoom:
	jmp	SHORT L033B

N_MUD2LOOP	LABEL	BYTE
	DB	'MUD2LOOP',0
L033B:
	push	OFFSET N_MUD2LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUD2LOOP")
	add	sp, 4
	mov	byte ptr [si+RS_FALL], 3
	mov	byte ptr [si+RS_FALL+1], 3
	mov	byte ptr [si+RS_FALL+2], 3
	mov	byte ptr [si+RS_FALL+3], 3
	mov	byte ptr [si+mudd_here], 0
	cmp	byte ptr [si+sickbay], 0
	jne	L0367
	JMPN	L040E

L0367:
	cmp	byte ptr [si+sickbay], 2
	je	L03BF
	cmp	byte ptr [si+mudd_incident], 1
	jne	L0376
	JMPN	L040E

L0376:
	cmp	byte ptr [si+sickbay], 1
	je	L037D
	retf

L037D:
	push	3
	push	RC_MUSIC
	SERVICE		; Music(3)
	add	sp, 4
	jmp	SHORT L0392

N_s4sbhw	LABEL	BYTE
	DB	's4sbhw',0
L0392:
	push	0
	push	0BFh
	push	99h
	push	OFFSET N_s4sbhw
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s4sbhw", 153, 191, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_BUSY], 2
	mov	byte ptr [si+mudd_raving], 1
	mov	word ptr [si+RS_TIMERS+2], 46h
	mov	byte ptr [si+sickbay], 2
	mov	byte ptr [si+mudd_incident], 1
	retf

L03BF:
	mov	byte ptr [si+mudd_here], 1
	cmp	byte ptr [si+mudd_held], 1
	je	L0413
	mov	byte ptr [si+mudd_held], 0
	jmp	SHORT L03D6

N_s4sbhn	LABEL	BYTE
	DB	's4sbhn',0
L03D6:
	push	0
	push	0BFh
	push	9Fh
	push	OFFSET N_s4sbhn
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s4sbhn", 159, 191, 0)
	add	sp, 0Ch
	jmp	SHORT L03F6

N_s4sbvp	LABEL	BYTE
	DB	's4sbvp',0
L03F6:
	push	0
	push	0C3h
	push	93h
	push	OFFSET N_s4sbvp
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s4sbvp", 147, 195, 0)
	add	sp, 0Ch
	retf

L040E:
	mov	byte ptr [si+sickbay], 1
	retf

L0413:
	jmp	SHORT L041C

N_s4sbob	LABEL	BYTE
	DB	's4sbob',0
L041C:
	push	0
	push	0BAh
	push	9Fh
	push	OFFSET N_s4sbob
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s4sbob", 159, 186, 0)
	add	sp, 0Ch
	retf

; Timer 1: Mudd comes in (anim msg 1).
H_0434:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_045B
MuddArrives:
	jmp	SHORT L0443

N_s4sbmt	LABEL	BYTE
	DB	's4sbmt',0
L0443:
	push	1
	push	0BFh
	push	0A0h
	push	OFFSET N_s4sbmt
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s4sbmt", 160, 191, 1)
	add	sp, 0Ch
	retf

H_045B:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_0509
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
	mov	bx, OFFSET T_MUD2_037
	call	Say
	jmp	SHORT L0508

T_MUD2_037	LABEL	BYTE
	DB	'#MUD2\MUD2_037#This room closely resembles the Enterprise sickba'
	DB	'y.  The beds are powered, as is the central post console. ',0
L0508:
	retf

; The capsules: McCoy takes them once he knows the aliens (msgs 12, 13).
H_0509:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_05FD
SpockOnCapsules:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_018
	call	Say
	JMPN	L05FC

T_MUD2_018	LABEL	BYTE
	DB	'#MUD2\MUD2_018#Jim, these look like the capsules we might use in'
	DB	' a hypo.  I wouldn''t recommend experimenting with them, though. '
	DB	'Alien physiology or not, you can never be sure what unusual chem'
	DB	'icals will do to the human body.',0
L05FC:
	retf

H_05FD:
	SCRIPT	MSG_GET, 20h, 0, 0, H_0646
GetCapsules:
	cmp	byte ptr [si+mudd_raving], 0
	je	L0619
	cmp	byte ptr [si+mudd_held], 1
	je	L0619
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_023
	call	Say
	retf

L0619:
	cmp	byte ptr [si+know_physiology], 1
	je	L0629
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_024
	call	Say
	retf

L0629:
	mov	ax, 0Ch
	push	ax
	mov	ax, 0BFh
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 159, 191, 12)
	add	sp, 0Ah
	retf

H_0646:
	SCRIPT	MSG_WALK_DONE, 0Ch, 0, 0, H_0677
McCoyAtCapsules:
	jmp	SHORT L0655

N_musehn	LABEL	BYTE
	DB	'musehn',0
L0655:
	push	0Dh
	push	-1
	push	-1
	push	OFFSET N_musehn
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musehn", -1, -1, 13)
	add	sp, 0Ch
	push	IT_CAPSULE
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_CAPSULE)
	add	sp, 4
	retf

H_0677:
	SCRIPT	MSG_ANIM_DONE, 0Dh, 0, 0, H_069E
McCoyBack:
	mov	byte ptr [si+RS_FALL+2], 3
	mov	ax, 0
	push	ax
	mov	ax, 0B2h
	push	ax
	mov	ax, 0FEh
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 254, 178, 0)
	add	sp, 0Ah
	retf

H_069E:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_0702
CallEnterprise:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD2_009
	call	Say
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_STATICU1
	call	Say
	retf

T_MUD2_009	LABEL	BYTE
	DB	'#MUD2\MUD2_009#Kirk to Enterprise...',0
T_STATICU1	LABEL	BYTE
	DB	'#SFX\STATICU1#Ent... neu ... trans...',0

H_0702:
	SCRIPT	MSG_USE, IT_DEGRIME, ANY, 0, H_0712
UseDegrimer:
	mov	ax, OFFSET S_018D
	mov	bx, OFFSET T_MUD2N001
	call	Say
	retf

; Common to all of the mission's rooms: the de-grimer on the lenses makes
; the alien device (+1); firing the device sets off an explosion at Kirk
; (anim msg 9), +5 the first time anywhere; the de-grimer on anything else
; just cleans it.
H_0712:
	SCRIPT	MSG_USE, IT_LENSES, IT_DEGRIME, 0, H_0740
CleanLenses:
	push	IT_LENSES
	push	RC_TAKEITEM
	push	IT_DEGRIME
	push	RC_TAKEITEM
	push	IT_ALIENDV
	push	RC_GIVEITEM
	mov	di, 3
L0727:
	SERVICE		; GiveItem(IT_ALIENDV); TakeItem(IT_DEGRIME); TakeItem(IT_LENSES)
	add	sp, 4
	dec	di
	jne	L0727
	add	word ptr [si+score], 1
	mov	ax, OFFSET S_018D
	mov	bx, OFFSET T_MUD2N010
	call	Say
	retf

H_0740:
	SCRIPT	MSG_USE, IT_ALIENDV, ANY, 0, H_0793
FireDevice:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 1
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	push	0
	push	RC_ACTORPOS
	SERVICE		; ActorPos(0)
	add	sp, 4
	push	12h
	push	0Ah
	push	ax
	push	OFFSET N_s4cbxp
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, "s4cbxp", ?, 10, 18)
	add	sp, 0Ch
	jmp	SHORT L0783

N_EXPLO3	LABEL	BYTE
	DB	'EXPLO3',0
L0783:
	push	OFFSET N_EXPLO3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EXPLO3")
	add	sp, 4
	retf

; The alien device has gone off here (anim msg 18).
H_0793:
	SCRIPT	MSG_ANIM_DONE, 12h, 0, 0, H_0839
DeviceFired:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+used_device], 0
	je	L07A6
	JMPN	L0838

L07A6:
	mov	byte ptr [si+used_device], 1
	add	word ptr [si+score], 5
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD2_002
	call	Say
	jmp	SHORT L0838

T_MUD2_002	LABEL	BYTE
	DB	'#MUD2\MUD2_002#Well, now I think we know why the Elasi pirates w'
	DB	'ere so interested in finding out where Mudd was getting these>',0
L0838:
	retf

; Looking at and scanning the capsules.
H_0839:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_0885
LookAtCapsules:
	mov	ax, 0
	mov	bx, OFFSET T_MUD2N008
	call	Say
	jmp	SHORT L0884

T_MUD2N008	LABEL	BYTE
	DB	'#MUD2\MUD2N008#Small containers of oddly-colored liquids.',0
L0884:
	retf

H_0885:
	SCRIPT	MSG_USE, IT_MTRICOR, 20h, 0, H_0A55
McCoyScansCapsules:
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
	mov	bx, OFFSET T_MUD2_030
	call	Say
	JMPN	L094D

T_MUD2_030	LABEL	BYTE
	DB	'#MUD2\MUD2_030#It would be interesting to analyze them back aboa'
	DB	'rd the Enterprise, but these are probably vaccines, medicines, a'
	DB	'nd research viruses.',0
L094D:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD2_004
	call	Say
	jmp	SHORT L098E

T_MUD2_004	LABEL	BYTE
	DB	'#MUD2\MUD2_004#Do they pose any threat to us, Doctor?',0
L098E:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_019
	call	Say
	JMPN	L0A54

T_MUD2_019	LABEL	BYTE
	DB	'#MUD2\MUD2_019#None seems likely to have any effect on human -- '
	DB	'or Vulcan -- physiology. To be on the safe side, though, I would'
	DB	'n''t recommend taking a snootful from one of the capsules!',0
L0A54:
	retf

; The capsules into the beds' dispenser, once McCoy knows the aliens
; (msgs 15).
H_0A55:
	SCRIPT	MSG_USE, IT_CAPSULE, 23h, 0, H_0A8E
CapsulesInDispenser:
	cmp	byte ptr [si+mudd_raving], 0
	je	L0A71
	cmp	byte ptr [si+mudd_held], 1
	je	L0A71
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_023
	call	Say
	retf

L0A71:
	mov	ax, 0Fh
	push	ax
	mov	ax, 0BFh
	push	ax
	mov	ax, 9Fh
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 159, 191, 15)
	add	sp, 0Ah
	retf

H_0A8E:
	SCRIPT	MSG_WALK_DONE, 0Fh, 0, 0, H_0B54
McCoyAtDispenser:
	cmp	byte ptr [si+know_physiology], 0
	je	L0A9D
	JMPN	L0B35

L0A9D:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_014
	call	Say
	JMPN	L0B34

T_MUD2_014	LABEL	BYTE
	DB	'#MUD2\MUD2_014#I feel sure that these would have been used here,'
	DB	' but I don''t understand enough of how the aliens thought, to mak'
	DB	'e it work.',0
L0B34:
	retf

L0B35:
	jmp	SHORT L0B3E

N_musehn_2	LABEL	BYTE
	DB	'musehn',0
L0B3E:
	push	0Fh
	push	-1
	push	-1
	push	OFFSET N_musehn_2
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musehn", -1, -1, 15)
	add	sp, 0Ch
	retf

H_0B54:
	SCRIPT	MSG_ANIM_DONE, 0Fh, 0, 0, H_0D50
CapsulesLoaded:
	mov	byte ptr [si+RS_FALL+2], 0
	mov	ax, 2
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(2)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_020
	call	Say
	jmp	SHORT L0BD9

T_MUD2_020	LABEL	BYTE
	DB	'#MUD2\MUD2_020#The capsules slide into the machinery on the bed '
	DB	'exactly as they''re designed to.',0
L0BD9:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_029
	call	Say
	JMPN	L0C77

T_MUD2_029	LABEL	BYTE
	DB	'#MUD2\MUD2_029#I''m telling the program our physiology is not the'
	DB	' same as the aliens'' physiology.  Don''t want it to try to cure u'
	DB	's of being human!',0
L0C77:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD2_039
	call	Say
	jmp	SHORT L0CCB

T_MUD2_039	LABEL	BYTE
	DB	'#MUD2\MUD2_039#That would be too much to hope for, would it not,'
	DB	' Doctor?',0
L0CCB:
	cmp	byte ptr [si+mudd_held], 1
	jne	L0D1F
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_034
	call	Say
	jmp	SHORT L0D1F

T_MUD2_034	LABEL	BYTE
	DB	'#MUD2\MUD2_034#Particularly when we''re talking about Harry Mudd.'
	DB	'..',0
L0D1F:
	mov	byte ptr [si+capsules_loaded], 1
	push	IT_CAPSULE
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_CAPSULE)
	add	sp, 4
	mov	byte ptr [si+RS_FALL+2], 3
	mov	ax, 0
	push	ax
	mov	ax, 0B2h
	push	ax
	mov	ax, 0FEh
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 254, 178, 0)
	add	sp, 0Ah
	retf

; The beds: before the capsules, "no time for a nap" (msg 6). With McCoy
; knowing the aliens Kirk walks with msg 7, which nothing handles.
H_0D50:
	SCRIPT	MSG_USE, OBJ_KIRK, 24h, 0, H_0D58
	jmp	SHORT UseBed

H_0D58:
	SCRIPT	MSG_USE, OBJ_KIRK, 25h, 0, H_0DAA
UseBed:
	cmp	byte ptr [si+capsules_loaded], 0
	jne	L0D87
	cmp	byte ptr [si+know_physiology], 0
	jne	L0D87
	mov	ax, 6
	push	ax
	mov	ax, 0BDh
	push	ax
	mov	ax, 0D7h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 215, 189, 6)
	add	sp, 0Ah
	retf

L0D87:
	cmp	byte ptr [si+know_physiology], 1
	jne	L0DA9
	mov	ax, 7
	push	ax
	mov	ax, 0BDh
	push	ax
	mov	ax, 0D7h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 215, 189, 7)
	add	sp, 0Ah
L0DA9:
	retf

H_0DAA:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_0DE6
NoNap:
	mov	ax, 0
	mov	bx, OFFSET T_MUD2_022
	call	Say
	jmp	SHORT L0DE5

T_MUD2_022	LABEL	BYTE
	DB	'#MUD2\MUD2_022#This is no time for a nap>',0
L0DE5:
	retf

; Mudd, drugged, sees space aliens everywhere (anim msgs 1, 2).
H_0DE6:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_0E5E
MuddFeelsIt:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD2_044
	call	Say
	jmp	SHORT L0E17

T_MUD2_044	LABEL	BYTE
	DB	'#MUD2\MUD2_044#Why C-c-Captain!',0
L0E17:
	jmp	SHORT L0E22

N_BATTYGAS	LABEL	BYTE
	DB	'BATTYGAS',0
L0E22:
	push	OFFSET N_BATTYGAS
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("BATTYGAS")
	add	sp, 4
	jmp	SHORT L0E3A

N_s4sbhb	LABEL	BYTE
	DB	's4sbhb',0
L0E3A:
	push	2
	push	0BFh
	push	9Fh
	push	OFFSET N_s4sbhb
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s4sbhb", 159, 191, 2)
	add	sp, 0Ch
	push	0
	push	RC_MUSIC
	SERVICE		; Music(0)
	add	sp, 4
	retf

H_0E5E:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_1182
MuddRaves:
	jmp	SHORT L0E6D

N_s4sbhn_2	LABEL	BYTE
	DB	's4sbhn',0
L0E6D:
	push	3
	push	0BFh
	push	9Fh
	push	OFFSET N_s4sbhn_2
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s4sbhn", 159, 191, 3)
	add	sp, 0Ch
	jmp	SHORT L0E8D

N_s4sbvp_2	LABEL	BYTE
	DB	's4sbvp',0
L0E8D:
	push	0
	push	0C3h
	push	93h
	push	OFFSET N_s4sbvp_2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s4sbvp", 147, 195, 0)
	add	sp, 0Ch
	mov	byte ptr [si+mudd_here], 1
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_032
	call	Say
	JMPN	L0F41

T_MUD2_032	LABEL	BYTE
	DB	'#MUD2\MUD2_032#Jim, that doesn''t look good at all...  Harry, let'
	DB	' me take a look at you and check whether that had some deleterio'
	DB	'us effect...',0
L0F41:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD2_049
	call	Say
	JMPN	L0FEE

T_MUD2_049	LABEL	BYTE
	DB	'#MUD2\MUD2_049#No!  You''re all space aliens!  You''re little grey'
	DB	' men from inside the hollow earth!  You want to experiment on my'
	DB	' body parts!  Stay away from me!',0
L0FEE:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_026
	call	Say
	jmp	SHORT L1053

T_MUD2_026	LABEL	BYTE
	DB	'#MUD2\MUD2_026#Deleterious effects.  I guess I don''t even need m'
	DB	'y tricorder to know that.',0
L1053:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD2_051
	call	Say
	jmp	SHORT L10AA

T_MUD2_051	LABEL	BYTE
	DB	'#MUD2\MUD2_051#You''ll mind control me, kidnap my children!  Diss'
	DB	'ect my dog!',0
L10AA:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_031
	call	Say
	JMPN	L114F

T_MUD2_031	LABEL	BYTE
	DB	'#MUD2\MUD2_031#If we can get him on one of the beds, and get it '
	DB	'active, I think he can be cured.  Otherwise, he''s likely to beco'
	DB	'me increasingly violent.',0
L114F:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD2_050
	call	Say
	jmp	SHORT L117D

T_MUD2_050	LABEL	BYTE
	DB	'#MUD2\MUD2_050#Stay away from me!>',0
L117D:
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Phasers on Mudd: no use while he is raving.
H_1182:
	SCRIPT	MSG_USE, IT_PHASERS, 8, 0, H_118A
	jmp	SHORT PhaserMudd

H_118A:
	SCRIPT	MSG_USE, IT_PHASERK, 8, 0, H_134B
PhaserMudd:
	cmp	byte ptr [si+mudd_raving], 0
	jne	L1199
	JMPN	L134A

L1199:
	cmp	byte ptr [si+mudd_held], 1
	jne	L11A2
	JMPN	L134A

L11A2:
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD2_053
	call	Say
	jmp	SHORT L1224

T_MUD2_053	LABEL	BYTE
	DB	'#MUD2\MUD2_053#I don''t think the phaser will have the usual effe'
	DB	'ct, Captain.... we''ll have to think of something else!',0
L1224:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD2_042
	call	Say
	JMPN	L12D4

T_MUD2_042	LABEL	BYTE
	DB	'#MUD2\MUD2_042#Ahh, I feel faster -- smarter -- strong enough to'
	DB	' take you all on! You''re really lizard men wearing human masks -'
	DB	'- his is coming off -- Hahahahahah!',0
L12D4:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD2_043
	call	Say
	jmp	SHORT L134A

T_MUD2_043	LABEL	BYTE
	DB	'#MUD2\MUD2_043#I know you for what you really are!  I''ll tell th'
	DB	'e whole world, and then where will you be!',0
L134A:
	retf

; Restraining Mudd: Spock's nerve pinch holds him (msgs 4, 5); Kirk asks
; Spock; Buchert is thrown off (msgs 16, 17, timer 2).
H_134B:
	SCRIPT	MSG_USE, OBJ_SPOCK, 8, 0, H_137E
SpockGrabsMudd:
	cmp	byte ptr [si+mudd_raving], 1
	jne	L137D
	cmp	byte ptr [si+mudd_held], 0
	jne	L137D
L135D:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 4
	push	ax
	mov	ax, 0BFh
	push	ax
	mov	ax, 8Ah
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 138, 191, 4)
	add	sp, 0Ah
L137D:
	retf

H_137E:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_13B5
SpockAtMudd:
	jmp	SHORT L138D

N_s4sbsp	LABEL	BYTE
	DB	's4sbsp',0
L138D:
	push	5
	push	0BFh
	push	9Fh
	push	OFFSET N_s4sbsp
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "s4sbsp", 159, 191, 5)
	add	sp, 0Ch
	mov	ax, 8
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(8)
	add	sp, 4
	retf

H_13B5:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_145B
MuddHeld:
	jmp	SHORT L13C4

N_s4sbob_2	LABEL	BYTE
	DB	's4sbob',0
L13C4:
	push	0
	push	0BAh
	push	9Fh
	push	OFFSET N_s4sbob_2
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s4sbob", 159, 186, 0)
	add	sp, 0Ch
	jmp	SHORT L13E4

N_sstnde	LABEL	BYTE
	DB	'sstnde',0
L13E4:
	push	0
	push	0BDh
	push	0D0h
	push	OFFSET N_sstnde
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sstnde", 208, 189, 0)
	add	sp, 0Ch
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD2_012
	call	Say
	jmp	SHORT L1432

T_MUD2_012	LABEL	BYTE
	DB	'#MUD2\MUD2_012#All yours now, Doctor McCoy.',0
L1432:
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr [si+mudd_held], 1
	mov	byte ptr [si+RS_FALL+1], 3
	mov	ax, 0
	push	ax
	mov	ax, 0C4h
	push	ax
	mov	ax, 118h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 280, 196, 0)
	add	sp, 0Ah
	retf

H_145B:
	SCRIPT	MSG_USE, OBJ_KIRK, 8, 0, H_14B1
KirkGrabsMudd:
	cmp	byte ptr [si+mudd_raving], 1
	jne	L14B0
	cmp	byte ptr [si+mudd_held], 0
	jne	L14B0
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD2_001
	call	Say
	jmp	SHORT L14AD

T_MUD2_001	LABEL	BYTE
	DB	'#MUD2\MUD2_001#Spock, see if you can outflank him...',0
L14AD:
	JMPN	L135D

L14B0:
	retf

H_14B1:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 8, 0, H_14E4
BuchertGrabsMudd:
	cmp	byte ptr [si+mudd_raving], 0
	je	L14E3
	cmp	byte ptr [si+mudd_held], 1
	je	L14E3
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 10h
	push	ax
	mov	ax, 0BEh
	push	ax
	mov	ax, 0C3h
	push	ax
	mov	ax, 3
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(3, 195, 190, 16)
	add	sp, 0Ah
L14E3:
	retf

H_14E4:
	SCRIPT	MSG_WALK_DONE, 10h, 0, 0, H_1548
BuchertAtMudd:
	mov	word ptr [si+RS_TIMERS+4], 8
	jmp	SHORT L14F8

N_s4sbrh	LABEL	BYTE
	DB	's4sbrh',0
L14F8:
	push	10h
	push	-1
	push	-1
	push	OFFSET N_s4sbrh
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "s4sbrh", -1, -1, 16)
	add	sp, 0Ch
	jmp	SHORT L1518

N_ROCKFACE	LABEL	BYTE
	DB	'ROCKFACE',0
L1518:
	push	OFFSET N_ROCKFACE
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("ROCKFACE")
	add	sp, 4
	jmp	SHORT L1530

N_s4sbhh	LABEL	BYTE
	DB	's4sbhh',0
L1530:
	push	11h
	push	0BFh
	push	9Fh
	push	OFFSET N_s4sbhh
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s4sbhh", 159, 191, 17)
	add	sp, 0Ch
	retf

H_1548:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_155B
Timer2Sound:
	push	0Bh
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(11)
	add	sp, 4
	retf

H_155B:
	SCRIPT	MSG_ANIM_DONE, 11h, 0, 0, H_1580
MuddShakesOff:
	jmp	SHORT L156A

N_s4sbhn_3	LABEL	BYTE
	DB	's4sbhn',0
L156A:
	push	0
	push	-1
	push	-1
	push	OFFSET N_s4sbhn_3
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s4sbhn", -1, -1, 0)
	add	sp, 0Ch
	retf

H_1580:
	SCRIPT	MSG_ANIM_DONE, 10h, 0, 0, H_161F
BuchertThrown:
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD2_052
	call	Say
	jmp	SHORT L15DA

T_MUD2_052	LABEL	BYTE
	DB	'#MUD2\MUD2_052#He''s unnaturally strong, Captain!  I can''t take h'
	DB	'im down!',0
L15DA:
	jmp	SHORT L15E3

N_rstnds	LABEL	BYTE
	DB	'rstnds',0
L15E3:
	push	0
	push	0C3h
	push	0D8h
	push	OFFSET N_rstnds
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rstnds", 216, 195, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr [si+RS_FALL+3], 3
	mov	ax, 0
	push	ax
	mov	ax, 0AEh
	push	ax
	mov	ax, 117h
	push	ax
	mov	ax, 3
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(3, 279, 174, 0)
	add	sp, 0Ah
	retf

; McCoy's tricorder on Mudd: the key is written 45h, 8, 0, 0 instead of
; MSG_USE, IT_MTRICOR, 8, 0, so this never runs.
H_161F:
	SCRIPT	45h, 8, 0, 0, H_16CE
McCoyScansMuddNever:
	cmp	byte ptr [si+mudd_raving], 1
	jne	L162E
	JMPN	L16CD

L162E:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_013
	call	Say
	JMPN	L16CD

T_MUD2_013	LABEL	BYTE
	DB	'#MUD2\MUD2_013#He''s showing definite signs of hallucination and '
	DB	'a marked increase in adrenalin. I would recommend extreme cautio'
	DB	'n in handling him.',0
L16CD:
	retf

; McCoy treats Mudd on a bed, once he is held, McCoy knows the aliens and
; the capsules are in (msgs 10, 11): +2 score.
H_16CE:
	SCRIPT	MSG_USE, IT_MEDKIT, 8, 0, H_16D6
	jmp	SHORT McCoyTreatsMudd

H_16D6:
	SCRIPT	MSG_USE, OBJ_MCCOY, 8, 0, H_18CC
McCoyTreatsMudd:
	cmp	byte ptr [si+mudd_raving], 0
	je	L1740
	cmp	byte ptr [si+mudd_held], 1
	je	L1741
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_016
	call	Say
	jmp	SHORT L1740

T_MUD2_016	LABEL	BYTE
	DB	'#MUD2\MUD2_016#I''m not fast enough to get him with a tranquilize'
	DB	'r hypo, Jim!',0
L1740:
	retf

L1741:
	cmp	byte ptr [si+know_physiology], 0
	je	L174A
	JMPN	L17CD

L174A:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_015
	call	Say
	jmp	SHORT L17CC

T_MUD2_015	LABEL	BYTE
	DB	'#MUD2\MUD2_015#I need to understand more about the aliens before'
	DB	' I can make this bed and its instrumentation function.',0
L17CC:
	retf

L17CD:
	cmp	byte ptr [si+capsules_loaded], 0
	je	L17D6
	JMPN	L18AF

L17D6:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_021
	call	Say
	JMPN	L18AE

T_MUD2_021	LABEL	BYTE
	DB	'#MUD2\MUD2_021#The volatile chemicals have evaporated over the t'
	DB	'ime the derelict hung in space. I need to refill the capsule-dis'
	DB	'penser for the bed to activate and effect a cure on our friend H'
	DB	'arry, here.',0
L18AE:
	retf

L18AF:
	mov	ax, 0Ah
	push	ax
	mov	ax, 0AFh
	push	ax
	mov	ax, 0DEh
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 222, 175, 10)
	add	sp, 0Ah
	retf

H_18CC:
	SCRIPT	MSG_WALK_DONE, 0Ah, 0, 0, H_18F5
McCoyAtBed:
	add	word ptr [si+score], 2
	jmp	SHORT L18DF

N_s4sbms	LABEL	BYTE
	DB	's4sbms',0
L18DF:
	push	0Bh
	push	-1
	push	-1
	push	OFFSET N_s4sbms
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "s4sbms", -1, -1, 11)
	add	sp, 0Ch
	retf

H_18F5:
	SCRIPT	MSG_ANIM_DONE, 0Bh, 0, 0, H_1A40
MuddCured:
	mov	byte ptr [si+mudd_incident], 0
	mov	byte ptr [si+sickbay], 3
	mov	byte ptr [si+mudd_here], 0
	mov	byte ptr [si+mudd_raving], 0
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_033
	call	Say
	JMPN	L1998

T_MUD2_033	LABEL	BYTE
	DB	'#MUD2\MUD2_033#Okay, Harry, you should start to feel better in a'
	DB	' few minutes. Just lie there quietly until you feel like moving.',0
L1998:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD2_045
	call	Say
	JMPN	L1A3B

T_MUD2_045	LABEL	BYTE
	DB	'#MUD2\MUD2_045#*Groan.*  Give me something for this headache, Do'
	DB	'c. A herd of Hamali tree-elephants landed behind my eyeballs and'
	DB	' did a mating dance...',0
L1A3B:
	mov	byte ptr [si+mudd_held], 0
	retf

H_1A40:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_1A4F
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_MUD2N003
	call	Say
	retf

H_1A4F:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_1A5E
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_MUD2N006
	call	Say
	retf

H_1A5E:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_1A6D
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_MUD2N000
	call	Say
	retf

H_1A6D:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_1A7C
LookAtRedshirt:
	sub	ax, ax
	mov	bx, OFFSET T_MUD2N004
	call	Say
	retf

; Looking and talking.
H_1A7C:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_1A8B
LookAtMudd:
	sub	ax, ax
	mov	bx, OFFSET T_MUD2N002
	call	Say
	retf

H_1A8B:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_1A9A
LookAtMonitor:
	sub	ax, ax
	mov	bx, OFFSET T_MUD2N011
	call	Say
	retf

H_1A9A:
	SCRIPT	MSG_LOOK, 25h, 0, 0, H_1AA9
LookAtBed:
	sub	ax, ax
	mov	bx, OFFSET T_MUD2N007
	call	Say
	retf

H_1AA9:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_1AB8
LookAtBed2:
	sub	ax, ax
	mov	bx, OFFSET T_MUD2N007
	call	Say
	retf

H_1AB8:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_1AF6
TalkToKirk:
	cmp	byte ptr [si+mudd_here], 1
	jne	L1AEC
	cmp	byte ptr [si+mudd_raving], 1
	je	L1AEC
	cmp	byte ptr [si+mudd_held], 1
	je	L1AEC
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD2_005
	call	Say
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD2_046
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_035
	call	Say
	retf

L1AEC:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD2_010
	call	Say
	retf

H_1AF6:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_1B2B
TalkToSpock:
	cmp	byte ptr [si+mudd_here], 1
	jne	L1B18
	cmp	byte ptr [si+mudd_raving], 1
	je	L1B18
	cmp	byte ptr [si+mudd_held], 1
	je	L1B18
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD2_038
	call	Say
	retf

L1B18:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD2_040
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD2_011
	call	Say
	retf

H_1B2B:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_1B60
TalkToMcCoy:
	cmp	byte ptr [si+mudd_here], 1
	jne	L1B4D
	cmp	byte ptr [si+mudd_raving], 1
	je	L1B4D
	cmp	byte ptr [si+mudd_held], 1
	je	L1B4D
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_027
	call	Say
	retf

L1B4D:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_025
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD2_007
	call	Say
	retf

H_1B60:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_1BA7
TalkToRedshirt:
	cmp	byte ptr [si+mudd_here], 1
	jne	L1B94
	cmp	byte ptr [si+mudd_raving], 1
	je	L1B94
	cmp	byte ptr [si+mudd_held], 1
	je	L1B94
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD2_055
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD2_003
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_036
	call	Say
	retf

L1B94:
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD2_054
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD2_008
	call	Say
	retf

H_1BA7:
	SCRIPT	MSG_TALK, 8, 0, 0, H_1BE5
TalkToMudd:
	cmp	byte ptr [si+mudd_here], 0
	je	L1BD1
	cmp	byte ptr [si+mudd_held], 1
	je	L1BD1
	cmp	byte ptr [si+mudd_raving], 1
	je	L1BD2
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD2_047
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD2_006
	call	Say
L1BD1:
	retf

L1BD2:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD2_048
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD2_028
	call	Say
	retf

; Every tick, common to all of the mission's rooms: while life support is
; failing, the air runs down from 6978h, with warnings at 4F1Ah, 34BCh
; and 1A5Eh; at 1 the crew collapse (walk msgs 9-12) and the game is
; over.
H_1BE5:
	SCRIPT	MSG_TICK, ANY, ANY, ANY, H_1D60
AirRunsOut:
	cmp	byte ptr [si+air_failing], 0
	jne	L1BF4
	JMPN	L1C91

L1BF4:
	cmp	word ptr [si+air_countdown], 1
	je	L1C04
	mov	word ptr [si+air_countdown], 1
	mov	word ptr [si+air_left], 6978h
L1C04:
	dec	word ptr [si+air_left]
	cmp	word ptr [si+air_left], 1A5Eh
	jne	L1C11
	JMPN	L1CA6

L1C11:
	cmp	word ptr [si+air_left], 34BCh
	jne	L1C1B
	JMPN	L1C9C

L1C1B:
	cmp	word ptr [si+air_left], 4F1Ah
	je	L1C92
	cmp	word ptr [si+air_left], 1
	jne	L1C91
	mov	byte ptr [si+RS_BUSY], 1
	push	14h
	push	0BBh
	push	108h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 264, 187, 20)
	add	sp, 0Ah
	push	15h
	push	0C4h
	push	118h
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 280, 196, 21)
	add	sp, 0Ah
	push	16h
	push	0B2h
	push	0FEh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 254, 178, 22)
	add	sp, 0Ah
	push	17h
	push	0AEh
	push	117h
	push	3
	push	RC_WALK
	SERVICE		; Walk(3, 279, 174, 23)
	add	sp, 0Ah
	mov	ax, OFFSET S_018D
	mov	bx, OFFSET T_MUD2N005
	call	Say
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
L1C91:
	retf

L1C92:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_1CB0
	call	Say
	retf

L1C9C:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_1CD3
	call	Say
	retf

L1CA6:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_1CF6
	call	Say
	retf

S_1CB0	LABEL	BYTE
	DB	'Life support down to 75%, Captain.',0
S_1CD3	LABEL	BYTE
	DB	'Life support down to 50%, Captain.',0
S_1CF6	LABEL	BYTE
	DB	'Life support down to 25%, Captain.',0
T_MUD2N005	LABEL	BYTE
	DB	'#MUD2\MUD2N005#Life support fails completely and you fall uncons'
	DB	'cious.',0

; The air has run out (walk msgs 14h-17h).
H_1D60:
	SCRIPT	MSG_WALK_DONE, 14h, 0, 0, H_1D7D
KirkCollapses:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kgetds
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kgetds", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L1DD2

H_1D7D:
	SCRIPT	MSG_WALK_DONE, 15h, 0, 0, H_1D9A
SpockCollapses:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sgetdw
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sgetdw", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L1DD2

H_1D9A:
	SCRIPT	MSG_WALK_DONE, 16h, 0, 0, H_1DB7
McCoyCollapses:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mgetde
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mgetde", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L1DD2

H_1DB7:
	SCRIPT	MSG_WALK_DONE, 17h, 0, 0, rdf_scripts_end
RedshirtCollapses:
	push	0
	push	-1
	push	-1
	push	OFFSET N_rgetde
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rgetde", -1, -1, 0)
	add	sp, 0Ch
L1DD2:
	inc	byte ptr cs:collapsed
	cmp	byte ptr cs:collapsed, 4
	jne	L1DE8
	mov	ax, OFFSET S_018D
	mov	bx, OFFSET T_MUD2N009
	call	Say
L1DE8:
	retf

T_MUD2N009	LABEL	BYTE
	DB	'#MUD2\MUD2N009#The atmosphere in the ship has dropped below the '
	DB	'level needed to sustain life. You drop to unconsciousness and sl'
	DB	'owly die.',0
T_MUD2N003	LABEL	BYTE
	DB	'#MUD2\MUD2N003#James Kirk, the paragon of a Starfleet captain, f'
	DB	'eels nothing like a paragon right now. ',0
T_MUD2N006	LABEL	BYTE
	DB	'#MUD2\MUD2N006#Mr. Spock, your loyal science officer. ',0
T_MUD2N000	LABEL	BYTE
	DB	'#MUD2\MUD2N000#Dr. McCoy, who isn''t arguing as much with Spock a'
	DB	's usual. ',0
T_MUD2N004	LABEL	BYTE
	DB	'#MUD2\MUD2N004#Lieutenant Buchert. His is not to reason why. His'
	DB	' is to obey orders and stay alert. ',0
T_MUD2N002	LABEL	BYTE
	DB	'#MUD2\MUD2N002#Harcourt Fenton Mudd. Three of the most prominent'
	DB	' psychologists in the galaxy became famous by publishing case st'
	DB	'udies in sociopathy about him. ',0
T_MUD2_005	LABEL	BYTE
	DB	'#MUD2\MUD2_005#Harry! Calm down Harry, it''s only us! ',0
T_MUD2_046	LABEL	BYTE
	DB	'#MUD2\MUD2_046#Argh! My most dire enemies have found me! ',0
T_MUD2_035	LABEL	BYTE
	DB	'#MUD2\MUD2_035#Well, he got one thing right. ',0
T_MUD2_038	LABEL	BYTE
	DB	'#MUD2\MUD2_038#It would appear that the accident has made Harry '
	DB	'Mudd even less logical than before. ',0
T_MUD2_027	LABEL	BYTE
	DB	'#MUD2\MUD2_027#He''s delirious Jim. Actually, it''s kinda funny. ',0
T_MUD2_055	LABEL	BYTE
	DB	'#MUD2\MUD2_055#Sir, I can phaser him. A stun setting would just '
	DB	'leave him queasy. ',0
T_MUD2_003	LABEL	BYTE
	DB	'#MUD2\MUD2_003#Almost worth a try. Bones? ',0
T_MUD2_036	LABEL	BYTE
	DB	'#MUD2\MUD2_036#Who knows what effect a phaser might have on him '
	DB	'with all those chemicals in his system? We must find another way'
	DB	' to handle this. ',0
T_MUD2_048	LABEL	BYTE
	DB	'#MUD2\MUD2_048#No! You''re going to sell me to space aliens! Use '
	DB	'my brain as a weapon to destroy the human race! And here I am, w'
	DB	'illing to help out in a good cause... ',0
T_MUD2_028	LABEL	BYTE
	DB	'#MUD2\MUD2_028#I think I liked him better when he was less delir'
	DB	'ious. ',0
T_MUD2_010	LABEL	BYTE
	DB	'#MUD2\MUD2_010#Sometimes I wish I had become an archeology profe'
	DB	'ssor instead of a Starfleet Captain. ',0
T_MUD2_040	LABEL	BYTE
	DB	'#MUD2\MUD2_040#You look troubled, Captain.',0
T_MUD2_011	LABEL	BYTE
	DB	'#MUD2\MUD2_011#Sorry if I was bothering you. I was just silently'
	DB	' cursing the day I met Harry Mudd. ',0
T_MUD2_025	LABEL	BYTE
	DB	'#MUD2\MUD2_025#Are you religious, Jim? Is Harry Mudd a divine pu'
	DB	'nishment for anything we did wrong? ',0
T_MUD2_007	LABEL	BYTE
	DB	'#MUD2\MUD2_007#I can''t think of anything we did that was THAT ba'
	DB	'd. ',0
T_MUD2_054	LABEL	BYTE
	DB	'#MUD2\MUD2_054#Captain, count your blessings! We haven''t met any'
	DB	' salt vampires, deranged computers, blood-draining clouds, cell '
	DB	'imploding sirens, Greek gods, or any of the other things people '
	DB	'keep telling me about in security. ',0
T_MUD2_008	LABEL	BYTE
	DB	'#MUD2\MUD2_008#There''s not much I wouldn''t do to not have to dea'
	DB	'l with Mudd. ',0
T_MUD2_047	LABEL	BYTE
	DB	'#MUD2\MUD2_047#Kirk, you sound as though you aren''t happy to see'
	DB	' me! After all we''ve been through together, I thought we had bui'
	DB	'lt a genuine bond of camraderie, two men fighting side by side a'
	DB	'gainst impossible odds! ',0
T_MUD2_006	LABEL	BYTE
	DB	'#MUD2\MUD2_006#Harry, when did you become a comedian? ',0
T_MUD2_024	LABEL	BYTE
	DB	'#MUD2\MUD2_024#We won''t be able to operate any of this equipment'
	DB	' unless we can learn more about the aliens, Jim.',0
T_MUD2_023	LABEL	BYTE
	DB	'#MUD2\MUD2_023#We can''t get near that equipment with mudd going '
	DB	'nuts over there, Jim.',0
T_MUD2N010	LABEL	BYTE
	DB	'#MUD2\MUD2N010#These two things fit together like they were made'
	DB	' for each other.',0
T_MUD2N001	LABEL	BYTE
	DB	'#MUD2\MUD2N001#Dust and grease lifts off the surface, leaving th'
	DB	'is item clean as new.',0
T_MUD2N011	LABEL	BYTE
	DB	'#MUD2\MUD2N011#This seems to be the main monitoring station for '
	DB	'the beds. Above it is some sort of dispensary.',0
T_MUD2N007	LABEL	BYTE
	DB	'#MUD2\MUD2N007#Padded inclines resembling a bed.',0
rdf_scripts_end	LABEL	BYTE

RDF	ENDS
	END
