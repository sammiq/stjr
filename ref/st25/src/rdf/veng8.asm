; VENG8.RDF - "Vengeance", the Republic's transporter room, the only way
; into the torpedo bay. Powered by impulse power or the fusion pack, it
; sends Kije to unjam the torpedo loader.
;
; Actors: 3 Kije beaming, 9/0Ah (10) the fusion pack and its cable,
; 0Bh (11) the door, 0Ch (12) the console, 0Dh/0Eh (13/14) the sparks,
; 0Fh/10h (15/16) the pads. Objects: 8 the transporter chief, 9 the
; fusion pack, 0Bh/23h the door, 0Fh/21h the coordinate controls, 10h/20h
; the sliders, 22h the conduits, 24h the chamber. Exit 2: the corridor
; (room 7).
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - KijeOnPad also answers walk message 4, and counts arrivals in on_pad
;   as if two crewmen were to walk to the pad; only Kije's walk (msg 1)
;   is ever made, so the count is always 1.
; - The script chain runs on into code at 1D91: the engine reads its bytes
;   as key 50 B8 03 00 and next 2E50 (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
power_on	EQU	RS_VARS+0Bh	; impulse power is back (room 6)
enterprise_away	EQU	RS_VARS+0Dh	; the Enterprise has left to follow the distress call (room 0)
hypo_oiled	EQU	RS_VARS+11h	; the hypo holds oil (room 6)
power_to	EQU	RS_VARS+13h	; impulse power: 1 weapons, 2 shields, 3 transporter (room 2)
torpedo_loaded	EQU	RS_VARS+18h	; Kije has unjammed the torpedo loader
rescued	EQU	RS_VARS+19h	; the Enterprise is back: the Elasi threats are over
elasi_here	EQU	RS_VARS+1Ah	; the Elasi ship has arrived and jams the communicators
stalled	EQU	RS_VARS+1Bh	; Kirk has asked the Elasi for thirty minutes
complied	EQU	RS_VARS+1Ch	; Kirk has agreed to the Elasi's terms
board_timer	EQU	RS_VARS+20h	; word: until the Elasi board, unless the shields are up
stall_timer	EQU	RS_VARS+22h	; word: the thirty minutes
comply_timer	EQU	RS_VARS+24h	; word: until the Elasi lose patience after Kirk complies
torpedo_timer	EQU	RS_VARS+26h	; word: until their torpedoes
attack_timer	EQU	RS_VARS+28h	; word: after the Elasi lower their shields
coords_set	EQU	RS_VARS+3Ch	; Spock has set the coordinates to the torpedo bay
know_jam	EQU	RS_VARS+3Dh	; Spock has found the torpedo jam (room 2)
fusion_wired	EQU	RS_VARS+3Eh	; the fusion pack powers the transporter

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
	DW	12Ch
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, -1, 7, -1	; room for each exit
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
	DW	308,180, 191,189	; entrance 2, crew 0
	DW	308,180, 212,178	; entrance 2, crew 1
	DW	308,180, 231,191	; entrance 2, crew 2
	DW	308,180, 279,193	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0
; In the room file, so these start again each time the room loads
on_pad	LABEL	BYTE	; arrivals on the pad
	DB	0

rdf_scripts:
; The room starts: the fusion pack if wired in, the console, the door, and
; the sparks (timers 0, 1).
H_00CB:
	SCRIPT	MSG_TICK, 1, 0, 0, H_01BC
StartRoom:
	jmp	SHORT L00DC

N_VEN8LOOP	LABEL	BYTE
	DB	'VEN8LOOP',0
L00DC:
	push	OFFSET N_VEN8LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("VEN8LOOP")
	add	sp, 4
	cmp	byte ptr [si+fusion_wired], 1
	je	L00F4
	JMPN	L0191

L00F4:
	jmp	SHORT L00FD

N_s7r8pp	LABEL	BYTE
	DB	's7r8pp',0
L00FD:
	push	0
	push	0A2h
	push	10Dh
	push	OFFSET N_s7r8pp
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s7r8pp", 269, 162, 0)
	add	sp, 0Ch
	jmp	SHORT L011D

N_s7r8pl	LABEL	BYTE
	DB	's7r8pl',0
L011D:
	push	0
	push	97h
	push	101h
	push	OFFSET N_s7r8pl
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s7r8pl", 257, 151, 0)
	add	sp, 0Ch
	jmp	SHORT L013D

N_s7r8t2	LABEL	BYTE
	DB	's7r8t2',0
L013D:
	push	0
	push	9Fh
	push	3Ch
	push	OFFSET N_s7r8t2
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s7r8t2", 60, 159, 0)
	add	sp, 0Ch
	jmp	SHORT L015C

N_s7r8q1	LABEL	BYTE
	DB	's7r8q1',0
L015C:
	push	0
	push	0A0h
	push	35h
	push	OFFSET N_s7r8q1
	push	0Fh
	push	RC_ANIM2
	SERVICE		; Anim(15, "s7r8q1", 53, 160, 0)
	add	sp, 0Ch
	jmp	SHORT L017B

N_s7r8q2	LABEL	BYTE
	DB	's7r8q2',0
L017B:
	push	0
	push	0A0h
	push	44h
	push	OFFSET N_s7r8q2
	push	10h
	push	RC_ANIM2
	SERVICE		; Anim(16, "s7r8q2", 68, 160, 0)
	add	sp, 0Ch
L0191:
	jmp	SHORT L019B

N_s7r8d1c	LABEL	BYTE
	DB	's7r8d1c',0
L019B:
	push	0
	push	0ACh
	push	12Ch
	push	OFFSET N_s7r8d1c
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r8d1c", 300, 172, 0)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS], 2Fh
	mov	word ptr [si+RS_TIMERS+2], 0Eh
	retf

; Walking out to the corridor (msg 8, anim msg 7).
H_01BC:
	SCRIPT	MSG_WALK, 0Bh, 0, 0, H_01C4
	jmp	SHORT WalkToDoor

H_01C4:
	SCRIPT	MSG_WALK, 23h, 0, 0, H_01E7
WalkToDoor:
	mov	ax, 8
	push	ax
	mov	ax, 0B6h
	push	ax
	mov	ax, 117h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 279, 182, 8)
	add	sp, 0Ah
	retf

H_01E7:
	SCRIPT	MSG_WALK_DONE, 8, 0, 0, H_0222
AtDoor:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 5
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(5)
	add	sp, 4
	jmp	SHORT L020A

N_s7r8d1	LABEL	BYTE
	DB	's7r8d1',0
L020A:
	push	7
	push	0ACh
	push	12Ch
	push	OFFSET N_s7r8d1
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "s7r8d1", 300, 172, 7)
	add	sp, 0Ch
	retf

H_0222:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_0245
DoorOpened:
	mov	ax, 0
	push	ax
	mov	ax, 0B6h
	push	ax
	mov	ax, 134h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 308, 182, 0)
	add	sp, 0Ah
	retf

; The sparks loop: each animation restarts the other's timer.
H_0245:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_026A
Sparks1:
	jmp	SHORT L0254

N_s7r8s1	LABEL	BYTE
	DB	's7r8s1',0
L0254:
	push	0Bh
	push	0
	push	0
	push	OFFSET N_s7r8s1
	push	0Dh
	push	RC_ANIM2
	SERVICE		; Anim(13, "s7r8s1", 0, 0, 11)
	add	sp, 0Ch
	retf

H_026A:
	SCRIPT	MSG_ANIM_DONE, 0Bh, 0, 0, H_0275
Sparks1Done:
	mov	word ptr [si+RS_TIMERS], 80h
	retf

H_0275:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_029A
Sparks2:
	jmp	SHORT L0284

N_s7r8s2	LABEL	BYTE
	DB	's7r8s2',0
L0284:
	push	0Ch
	push	0
	push	0
	push	OFFSET N_s7r8s2
	push	0Eh
	push	RC_ANIM2
	SERVICE		; Anim(14, "s7r8s2", 0, 0, 12)
	add	sp, 0Ch
	retf

H_029A:
	SCRIPT	MSG_ANIM_DONE, 0Ch, 0, 0, H_02A6
Sparks2Done:
	mov	word ptr [si+RS_TIMERS+2], 20h
	retf

; Looking.
H_02A6:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_030C
LookAtFusion:
	mov	ax, 0
	mov	bx, OFFSET T_VEN8N004
	call	Say
	jmp	SHORT L030B

T_VEN8N004	LABEL	BYTE
	DB	'#VEN8\VEN8N004#The Fusion power pack is rigged into the transpor'
	DB	'ter power circuits.',0
L030B:
	retf

H_030C:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_0314
	jmp	SHORT LookAtDoor

H_0314:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_036B
LookAtDoor:
	mov	ax, 0
	mov	bx, OFFSET T_VEN8N009
	call	Say
	jmp	SHORT L036A

T_VEN8N009	LABEL	BYTE
	DB	'#VEN8\VEN8N009#This door leads back to the corridor and turbolif'
	DB	't 2.',0
L036A:
	retf

H_036B:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_03C5
LookAtConduits:
	mov	ax, 0
	mov	bx, OFFSET T_VEN8N006
	call	Say
	jmp	SHORT L03C4

T_VEN8N006	LABEL	BYTE
	DB	'#VEN8\VEN8N006#These are the power conduits for the transporter '
	DB	'system.',0
L03C4:
	retf

H_03C5:
	SCRIPT	MSG_LOOK, 0Fh, 0, 0, H_03CD
	jmp	SHORT LookAtControls

H_03CD:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_0426
LookAtControls:
	mov	ax, 0
	mov	bx, OFFSET T_VEN8N007
	call	Say
	jmp	SHORT L0425

T_VEN8N007	LABEL	BYTE
	DB	'#VEN8\VEN8N007#These controls set the coordinates for the transp'
	DB	'orter.',0
L0425:
	retf

H_0426:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_047C
LookAtChief:
	mov	ax, 0
	mov	bx, OFFSET T_VEN8N003
	call	Say
	jmp	SHORT L047B

T_VEN8N003	LABEL	BYTE
	DB	'#VEN8\VEN8N003#The former transporter chief of the U.S.S. Republ'
	DB	'ic.',0
L047B:
	retf

H_047C:
	SCRIPT	MSG_LOOK, 10h, 0, 0, H_0484
	jmp	SHORT LookAtSliders

H_0484:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_04D5
LookAtSliders:
	mov	ax, 0
	mov	bx, OFFSET T_VEN8N008
	call	Say
	jmp	SHORT L04D4

T_VEN8N008	LABEL	BYTE
	DB	'#VEN8\VEN8N008#These sliders activate the transporter systems.',0
L04D4:
	retf

H_04D5:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_0511
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_VEN8N001
	call	Say
	jmp	SHORT L0510

T_VEN8N001	LABEL	BYTE
	DB	'#VEN8\VEN8N001#Kirk is extremely worried.',0
L0510:
	retf

H_0511:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_0548
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_VEN5N002
	call	Say
	jmp	SHORT L0547

T_VEN5N002	LABEL	BYTE
	DB	'#VEN5\VEN5N002#A resolute Mr. Spock.',0
L0547:
	retf

H_0548:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_0598
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_VEN5N004
	call	Say
	jmp	SHORT L0597

T_VEN5N004	LABEL	BYTE
	DB	'#VEN5\VEN5N004#Dr. McCoy avoids the glances of his crewmates.',0
L0597:
	retf

H_0598:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_05DE
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_VEN8N000
	call	Say
	jmp	SHORT L05DD

T_VEN8N000	LABEL	BYTE
	DB	'#VEN8\VEN8N000#Kije is eager to perform his duties.',0
L05DD:
	retf

H_05DE:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_0644
LookAtPads:
	mov	ax, 0
	mov	bx, OFFSET T_VEN8N010
	call	Say
	jmp	SHORT L0643

T_VEN8N010	LABEL	BYTE
	DB	'#VEN8\VEN8N010#This is the transporter chamber. The pads do not '
	DB	'seem to be damaged.',0
L0643:
	retf

H_0644:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_06A2
LookAtTransporterRoom:
	mov	ax, 0
	mov	bx, OFFSET T_VEN8N005
	call	Say
	jmp	SHORT L06A1

T_VEN8N005	LABEL	BYTE
	DB	'#VEN8\VEN8N005#The transporter room appears to have escaped seri'
	DB	'ous damage.',0
L06A1:
	retf

; Talking: before the jam is known, after stalling, after the loading.
H_06A2:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_07AB
TalkToKirk:
	cmp	byte ptr [si+torpedo_loaded], 1
	jne	L0700
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN8_002
	call	Say
	jmp	SHORT L06FF

T_VEN8_002	LABEL	BYTE
	DB	'#VEN8\VEN8_002#Now, let''s give the Elasi something to remember u'
	DB	's by.',0
L06FF:
	retf

L0700:
	cmp	byte ptr [si+stalled], 1
	jne	L0749
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN8_005
	call	Say
	jmp	SHORT L0748

T_VEN8_005	LABEL	BYTE
	DB	'#VEN8\VEN8_005#This is it. We know what we have to do.',0
L0748:
	retf

L0749:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN8_006
	call	Say
	jmp	SHORT L07AA

T_VEN8_006	LABEL	BYTE
	DB	'#VEN8\VEN8_006#This room''s in pretty good condition compared to '
	DB	'the rest of the ship.',0
L07AA:
	retf

H_07AB:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_088D
TalkToSpock:
	cmp	byte ptr [si+torpedo_loaded], 1
	jne	L07F1
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN8_032
	call	Say
	jmp	SHORT L07F0

T_VEN8_032	LABEL	BYTE
	DB	'#VEN8\VEN8_032#A very efficient job, Captain.',0
L07F0:
	retf

L07F1:
	cmp	byte ptr [si+stalled], 1
	jne	L0847
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN8_029
	call	Say
	jmp	SHORT L0846

T_VEN8_029	LABEL	BYTE
	DB	'#VEN8\VEN8_029#This is the only access to the torpedo bay, Capta'
	DB	'in.',0
L0846:
	retf

L0847:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN8_028
	call	Say
	jmp	SHORT L088C

T_VEN8_028	LABEL	BYTE
	DB	'#VEN8\VEN8_028#The transporter pads seem intact, Captain.',0
L088C:
	retf

H_088D:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_09F6
TalkToMcCoy:
	cmp	byte ptr [si+torpedo_loaded], 1
	je	L089C
	JMPN	L0946

L089C:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN8_020
	call	Say
	jmp	SHORT L08E5

T_VEN8_020	LABEL	BYTE
	DB	'#VEN8\VEN8_020#Shall we give the Elasi our transmission, Jim?',0
L08E5:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN8_001
	call	Say
	jmp	SHORT L0945

T_VEN8_001	LABEL	BYTE
	DB	'#VEN8\VEN8_001#Let''s get back to auxiliary control and give them'
	DB	' our... information.',0
L0945:
	retf

L0946:
	cmp	byte ptr [si+stalled], 1
	jne	L0980
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN8_021
	call	Say
	jmp	SHORT L097F

T_VEN8_021	LABEL	BYTE
	DB	'#VEN8\VEN8_021#We don''t have much time!',0
L097F:
	retf

L0980:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN8_018
	call	Say
	jmp	SHORT L09F5

T_VEN8_018	LABEL	BYTE
	DB	'#VEN8\VEN8_018#Oh, great, my favorite place in the ship. Wouldn'''
	DB	't you know it would be in the best shape.',0
L09F5:
	retf

H_09F6:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0B33
TalkToRedshirt:
	cmp	byte ptr [si+torpedo_loaded], 1
	je	L0A05
	JMPN	L0AB4

L0A05:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN8_034
	call	Say
	jmp	SHORT L0A39

T_VEN8_034	LABEL	BYTE
	DB	'#VEN8\VEN8_034#I did good, didn''t I sir?',0
L0A39:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_VEN8_023
	call	Say
	jmp	SHORT L0A6F

T_VEN8_023	LABEL	BYTE
	DB	'#VEN8\VEN8_023#No, you did "well", ensign.',0
L0A6F:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN8_036
	call	Say
	jmp	SHORT L0AB3

T_VEN8_036	LABEL	BYTE
	DB	'#VEN8\VEN8_036#I''m a security officer, not a grammarian.',0
L0AB3:
	retf

L0AB4:
	cmp	byte ptr [si+stalled], 1
	jne	L0AF1
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN8_041
	call	Say
	jmp	SHORT L0AF0

T_VEN8_041	LABEL	BYTE
	DB	'#VEN8\VEN8_041#Ready for your orders, sir.',0
L0AF0:
	retf

L0AF1:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN8_040
	call	Say
	jmp	SHORT L0B32

T_VEN8_040	LABEL	BYTE
	DB	'#VEN8\VEN8_040#I have a bad feeling about this place.',0
L0B32:
	retf

; The coordinate controls (Spock, msgs 0Dh, 0Eh): with power from the
; fusion pack or to the transporter, and the jam known, Spock sets them for
; the torpedo bay.
H_0B33:
	SCRIPT	MSG_USE, OBJ_KIRK, 0Fh, 0, H_0B3B
	jmp	SHORT KirkOnControls

H_0B3B:
	SCRIPT	MSG_USE, OBJ_KIRK, 21h, 0, H_0B86
KirkOnControls:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN8_003
	call	Say
	jmp	SHORT L0B84

T_VEN8_003	LABEL	BYTE
	DB	'#VEN8\VEN8_003#Spock, please check out the transporter.',0
L0B84:
	jmp	SHORT SpockOnControls

H_0B86:
	SCRIPT	MSG_USE, OBJ_SPOCK, 0Fh, 0, H_0B8E
	jmp	SHORT SpockOnControls

H_0B8E:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_0BB5
SpockOnControls:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0Dh
	push	ax
	mov	ax, 0C4h
	push	ax
	mov	ax, 37h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 55, 196, 13)
	add	sp, 0Ah
	retf

H_0BB5:
	SCRIPT	MSG_WALK_DONE, 0Dh, 0, 0, H_0BDA
SpockAtControls:
	jmp	SHORT L0BC4

N_susemn	LABEL	BYTE
	DB	'susemn',0
L0BC4:
	push	0Eh
	push	-1
	push	-1
	push	OFFSET N_susemn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemn", -1, -1, 14)
	add	sp, 0Ch
	retf

H_0BDA:
	SCRIPT	MSG_ANIM_DONE, 0Eh, 0, 0, H_0DE4
SetCoordinates:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+fusion_wired], 1
	jne	L0BED
	JMPN	L0CAA

L0BED:
	cmp	byte ptr [si+power_on], 1
	je	L0C50
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN8_026
	call	Say
	jmp	SHORT L0C4F

T_VEN8_026	LABEL	BYTE
	DB	'#VEN8\VEN8_026#The impulse engines are not generating any power '
	DB	'for this system.',0
L0C4F:
	retf

L0C50:
	cmp	byte ptr [si+power_to], 3
	je	L0CAA
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN8_014
	call	Say
	jmp	SHORT L0CA9

T_VEN8_014	LABEL	BYTE
	DB	'#VEN8\VEN8_014#Captain, there is no power allocated to the trans'
	DB	'porter.',0
L0CA9:
	retf

L0CAA:
	cmp	byte ptr [si+know_jam], 1
	jne	L0CB3
	JMPN	L0D5A

L0CB3:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN8_030
	call	Say
	JMPN	L0D59

T_VEN8_030	LABEL	BYTE
	DB	'#VEN8\VEN8_030#This unit is fully functional. But I do not see t'
	DB	'he logic in using it at this time, Captain. The Enterprise is ou'
	DB	't of range for transport.',0
L0D59:
	retf

L0D5A:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN8_031
	call	Say
	jmp	SHORT L0DDF

T_VEN8_031	LABEL	BYTE
	DB	'#VEN8\VEN8_031#Transporter systems are operational, Captain. Coo'
	DB	'rdinates have been set to the Photon Torpedo Loading bay.',0
L0DDF:
	mov	byte ptr [si+coords_set], 1
	retf

; The fusion pack on the conduits (msgs 9, 0Ah, anim 0Fh): enough power
; for one person.
H_0DE4:
	SCRIPT	MSG_USE, IT_FUSION, 22h, 0, H_0F3F
FusionOnConduits:
	cmp	byte ptr [si+fusion_wired], 1
	jne	L0DF1
	retf

L0DF1:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN8_011
	call	Say
	jmp	SHORT L0E7A

T_VEN8_011	LABEL	BYTE
	DB	'#VEN8\VEN8_011#Spock, would it be possible to connect the fusion'
	DB	' power pack directly into the transporter power circuits?',0
L0E7A:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN8_033
	call	Say
	jmp	SHORT L0EFA

T_VEN8_033	LABEL	BYTE
	DB	'#VEN8\VEN8_033#Fascinating. It can be done. However, the transpo'
	DB	'rter will only be able to transport a single person.',0
L0EFA:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN8_009
	call	Say
	jmp	SHORT L0F22

T_VEN8_009	LABEL	BYTE
	DB	'#VEN8\VEN8_009#Do it, Spock.',0
L0F22:
	mov	ax, 9
	push	ax
	mov	ax, 0A4h
	push	ax
	mov	ax, 0FAh
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 250, 164, 9)
	add	sp, 0Ah
	retf

H_0F3F:
	SCRIPT	MSG_WALK_DONE, 9, 0, 0, H_0F64
SpockAtConduits:
	jmp	SHORT L0F4E

N_susemn_2	LABEL	BYTE
	DB	'susemn',0
L0F4E:
	push	0Ah
	push	-1
	push	-1
	push	OFFSET N_susemn_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susemn", -1, -1, 10)
	add	sp, 0Ch
	retf

H_0F64:
	SCRIPT	MSG_ANIM_DONE, 0Ah, 0, 0, H_1018
FusionWired:
	jmp	SHORT L0F75

N_MTHTRNSP	LABEL	BYTE
	DB	'MTHTRNSP',0
L0F75:
	push	OFFSET N_MTHTRNSP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MTHTRNSP")
	add	sp, 4
	jmp	SHORT L0F8D

N_s7r8pp_2	LABEL	BYTE
	DB	's7r8pp',0
L0F8D:
	push	0
	push	0A2h
	push	10Dh
	push	OFFSET N_s7r8pp_2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "s7r8pp", 269, 162, 0)
	add	sp, 0Ch
	jmp	SHORT L0FAD

N_s7r8pl_2	LABEL	BYTE
	DB	's7r8pl',0
L0FAD:
	push	0
	push	97h
	push	101h
	push	OFFSET N_s7r8pl_2
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "s7r8pl", 257, 151, 0)
	add	sp, 0Ch
	jmp	SHORT L0FCD

N_s7r8t1	LABEL	BYTE
	DB	's7r8t1',0
L0FCD:
	push	0Fh
	push	9Fh
	push	3Ch
	push	OFFSET N_s7r8t1
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "s7r8t1", 60, 159, 15)
	add	sp, 0Ch
	mov	ax, 0
	push	ax
	mov	ax, 0B2h
	push	ax
	mov	ax, 0D4h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 212, 178, 0)
	add	sp, 0Ah
	mov	byte ptr [si+fusion_wired], 1
	mov	ax, IT_FUSION
	push	ax
	mov	ax, RC_TAKEITEM
	push	ax
	SERVICE		; TakeItem(IT_FUSION)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_1018:
	SCRIPT	MSG_ANIM_DONE, 0Fh, 0, 0, H_105D
PadsLit:
	jmp	SHORT L1027

N_s7r8q1_2	LABEL	BYTE
	DB	's7r8q1',0
L1027:
	push	0
	push	0A0h
	push	35h
	push	OFFSET N_s7r8q1_2
	push	0Fh
	push	RC_ANIM2
	SERVICE		; Anim(15, "s7r8q1", 53, 160, 0)
	add	sp, 0Ch
	jmp	SHORT L1046

N_s7r8q2_2	LABEL	BYTE
	DB	's7r8q2',0
L1046:
	push	0
	push	0A0h
	push	44h
	push	OFFSET N_s7r8q2_2
	push	10h
	push	RC_ANIM2
	SERVICE		; Anim(16, "s7r8q2", 68, 160, 0)
	add	sp, 0Ch
	retf

; The sliders (Spock, msg 10h): with power and coordinates, Kije beams
; to the torpedo bay (msg 1, anims 5, 2), forces the loading door, and
; comes back (anims 6, 3): the torpedo is loaded.
H_105D:
	SCRIPT	MSG_USE, OBJ_KIRK, 10h, 0, H_1065
	jmp	SHORT KirkOnSliders

H_1065:
	SCRIPT	MSG_USE, OBJ_KIRK, 20h, 0, H_10B0
KirkOnSliders:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN8_004
	call	Say
	jmp	SHORT L10AE

T_VEN8_004	LABEL	BYTE
	DB	'#VEN8\VEN8_004#Spock, please check out the transporter.',0
L10AE:
	jmp	SHORT SpockOnSliders

H_10B0:
	SCRIPT	MSG_USE, OBJ_SPOCK, 10h, 0, H_10B8
	jmp	SHORT SpockOnSliders

H_10B8:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_10E3
SpockOnSliders:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 10h
	push	ax
	mov	ax, 0C4h
	push	ax
	mov	ax, 37h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 55, 196, 16)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+1], 0
	retf

H_10E3:
	SCRIPT	MSG_WALK_DONE, 10h, 0, 0, H_13BE
Energise:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+fusion_wired], 1
	jne	L10F6
	JMPN	L11B3

L10F6:
	cmp	byte ptr [si+power_on], 1
	je	L1159
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN8_027
	call	Say
	jmp	SHORT L1158

T_VEN8_027	LABEL	BYTE
	DB	'#VEN8\VEN8_027#The impulse engines are not generating any power '
	DB	'for this system.',0
L1158:
	retf

L1159:
	cmp	byte ptr [si+power_to], 3
	je	L11B3
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN8_015
	call	Say
	jmp	SHORT L11B2

T_VEN8_015	LABEL	BYTE
	DB	'#VEN8\VEN8_015#Captain, there is no power allocated to the trans'
	DB	'porter.',0
L11B2:
	retf

L11B3:
	cmp	byte ptr [si+coords_set], 1
	je	L122B
	mov	ax, 0
	push	ax
	mov	ax, 0B6h
	push	ax
	mov	ax, 98h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 152, 182, 0)
	add	sp, 0Ah
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN8_013
	call	Say
	jmp	SHORT L122A

T_VEN8_013	LABEL	BYTE
	DB	'#VEN8\VEN8_013#Captain, there are no coordinates set for the tra'
	DB	'nsporter.',0
L122A:
	retf

L122B:
	cmp	byte ptr [si+torpedo_loaded], 1
	jne	L12AB
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN8_042
	call	Say
	jmp	SHORT L12AA

T_VEN8_042	LABEL	BYTE
	DB	'#VEN8\VEN8_042#There is no need to go back to the torpedo bay, C'
	DB	'aptain. I can assure you that it is unjammed.',0
L12AA:
	retf

L12AB:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN8_010
	call	Say
	JMPN	L136D

T_VEN8_010	LABEL	BYTE
	DB	'#VEN8\VEN8_010#Ensign Kije, I want you to beam into the torpedo '
	DB	'bay and unjam the loading mechanism. If you don''t succeed, we''ll'
	DB	' all be on permanent shoreleave in an Elasi jail.',0
L136D:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN8_035
	call	Say
	jmp	SHORT L139D

T_VEN8_035	LABEL	BYTE
	DB	'#VEN8\VEN8_035#I''ll do my best, Sir.',0
L139D:
	mov	ax, 1
	push	ax
	mov	ax, 7Fh
	push	ax
	mov	ax, 0C8h
	push	ax
	mov	ax, 3
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(3, 200, 127, 1)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+3], 1
	retf

H_13BE:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_13C6
	jmp	SHORT KijeOnPad

H_13C6:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_1430
KijeOnPad:
	inc	byte ptr cs:on_pad
	cmp	byte ptr cs:on_pad, 1
	jne	L142F
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN8_009_2
	call	Say
	jmp	SHORT L1401

T_VEN8_009_2	LABEL	BYTE
	DB	'#VEN8\VEN8_009#Do it, Spock.',0
L1401:
	jmp	SHORT L140A

N_susehn	LABEL	BYTE
	DB	'susehn',0
L140A:
	push	5
	push	-1
	push	-1
	push	OFFSET N_susehn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susehn", -1, -1, 5)
	add	sp, 0Ch
	mov	ax, 0Ah
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(10)
	add	sp, 4
L142F:
	retf

H_1430:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_1469
KijeBeamed:
	jmp	SHORT L143F

N_rteled	LABEL	BYTE
	DB	'rteled',0
L143F:
	push	2
	push	-1
	push	-1
	push	OFFSET N_rteled
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rteled", -1, -1, 2)
	add	sp, 0Ch
	mov	ax, 8
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(8)
	add	sp, 4
	mov	byte ptr [si+RS_REDSHIRT_DEAD], 1
	retf

H_1469:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_172F
KijeInTorpedoBay:
	mov	ax, 3
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(3)
	add	sp, 4
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN8_037
	call	Say
	jmp	SHORT L14F0

T_VEN8_037	LABEL	BYTE
	DB	'#VEN8\VEN8_037#I''ve reached the torpedo loading bay, Captain. It'
	DB	's not too badly damaged, fortunately.',0
L14F0:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN8_012
	call	Say
	jmp	SHORT L1543

T_VEN8_012	LABEL	BYTE
	DB	'#VEN8\VEN8_012#What''s causing the malfunction in the loading mec'
	DB	'hanism?',0
L1543:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN8_039
	call	Say
	JMPN	L1618

T_VEN8_039	LABEL	BYTE
	DB	'#VEN8\VEN8_039#The inner loading door is stuck in the closed pos'
	DB	'ition. I can force it open, but when the loading cycle is begun,'
	DB	' the room will lose pressure.  We won''t be able to beam back her'
	DB	'e again.',0
L1618:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN8_008
	call	Say
	jmp	SHORT L167F

T_VEN8_008	LABEL	BYTE
	DB	'#VEN8\VEN8_008#Do it, Ensign.  We''ll just have to gamble that th'
	DB	'e system doesn''t jam again.',0
L167F:
	mov	ax, OFFSET N_Ensign_Kije
	mov	bx, OFFSET T_VEN8_038
	call	Say
	jmp	SHORT L16D0

T_VEN8_038	LABEL	BYTE
	DB	'#VEN8\VEN8_038#The door''s open, Captain. I''m ready to transport '
	DB	'back.',0
L16D0:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN8_007
	call	Say
	jmp	SHORT L1700

T_VEN8_007	LABEL	BYTE
	DB	'#VEN8\VEN8_007#Beam him back, Spock.',0
L1700:
	jmp	SHORT L1709

N_susehn_2	LABEL	BYTE
	DB	'susehn',0
L1709:
	push	6
	push	-1
	push	-1
	push	OFFSET N_susehn_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susehn", -1, -1, 6)
	add	sp, 0Ch
	mov	ax, 0Ah
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(10)
	add	sp, 4
	retf

H_172F:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_1769
KijeBeamedBack:
	mov	byte ptr [si+RS_REDSHIRT_DEAD], 0
	jmp	SHORT L1741

N_rtele	LABEL	BYTE
	DB	'rtele',0
L1741:
	push	3
	push	81h
	push	0C8h
	push	OFFSET N_rtele
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rtele", 200, 129, 3)
	add	sp, 0Ch
	mov	ax, 9
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(9)
	add	sp, 4
	retf

H_1769:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_1794
KijeBack:
	mov	ax, 0
	push	ax
	mov	ax, 0B2h
	push	ax
	mov	ax, 0BAh
	push	ax
	mov	ax, 3
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(3, 186, 178, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr [si+torpedo_loaded], 1
	retf

; Spock's tricorder on the transporter.
H_1794:
	SCRIPT	MSG_USE, IT_STRICOR, 0Fh, 0, H_179C
	jmp	SHORT SpockScansSliders

H_179C:
	SCRIPT	MSG_USE, IT_STRICOR, 10h, 0, H_17A4
SpockScansSliders:
	jmp	SHORT SpockScansControls

H_17A4:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_17AC
SpockScansControls:
	jmp	SHORT SpockScansSliders2

H_17AC:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_1837
SpockScansSliders2:
	jmp	SHORT L17BB

N_sscans	LABEL	BYTE
	DB	'sscans',0
L17BB:
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
	mov	bx, OFFSET T_VEN8_025
	call	Say
	jmp	SHORT L1836

T_VEN8_025	LABEL	BYTE
	DB	'#VEN8\VEN8_025#Surprisingly, the transporter controls have escap'
	DB	'ed damage.',0
L1836:
	retf

; Every tick, common to the mission's rooms: the Elasi deadlines set on
; the bridge (room 2). Until the Enterprise returns: boarding unless the
; shields are up, the thirty minutes, the wait after Kirk complies (then
; a warning and the torpedoes), the chance after they lower their
; shields. When one runs out, the game is over.
H_1837:
	SCRIPT	MSG_TICK, ANY, ANY, ANY, H_1A5B
ElasiDeadlines:
	cmp	word ptr [si+board_timer], 0
	je	L1851
	dec	word ptr [si+board_timer]
	jne	L1851
	cmp	byte ptr [si+power_to], 2
	je	L1851
	JMPN	L1951

L1851:
	cmp	word ptr [si+stall_timer], 0
	je	L1865
	dec	word ptr [si+stall_timer]
	jne	L1865
	cmp	byte ptr [si+complied], 1
	je	L1865
	JMPN	L1951

L1865:
	cmp	word ptr [si+comply_timer], 0
	je	L18C4
	dec	word ptr [si+comply_timer]
	jne	L18C4
	cmp	byte ptr [si+rescued], 1
	je	L18C4
	mov	ax, OFFSET N_Elasi_Captain
	mov	bx, OFFSET T_VEN2_098
	call	Say
	jmp	SHORT L18BF

T_VEN2_098	LABEL	BYTE
	DB	'#VEN2\VEN2_098#What are you stalling for? Lower your shields.',0
L18BF:
	mov	word ptr [si+torpedo_timer], 0A8Ch
L18C4:
	cmp	word ptr [si+torpedo_timer], 0
	je	L193D
	dec	word ptr [si+torpedo_timer]
	jne	L193D
	cmp	byte ptr [si+rescued], 1
	je	L193D
	mov	ax, 0
	mov	bx, OFFSET T_VENA_F40
	call	Say
	jmp	SHORT L1931

T_VENA_F40	LABEL	BYTE
	DB	'#VENA\VENA_F40#The Elasi fire photon torpedoes. The Republic has'
	DB	' been destroyed.',0
L1931:
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
L193D:
	cmp	word ptr [si+attack_timer], 0
	je	L1950
	dec	word ptr [si+attack_timer]
	jne	L1950
	cmp	byte ptr [si+rescued], 1
	je	L1950
	jmp	SHORT L1951

L1950:
	retf

L1951:
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

H_1A5B:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_1A63
	jmp	SHORT KillAnything

H_1A63:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_1AF8
KillAnything:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VENA_F34
	call	Say
	JMPN	L1AF7

T_VENA_F34	LABEL	BYTE
	DB	'#VENA\VENA_F34#Captain, it would be unwise to use your phaser co'
	DB	'nsidering the already extensive damage sustained by the Republic'
	DB	'.',0
L1AF7:
	retf

; The hypo, empty or full of oil.
H_1AF8:
	SCRIPT	MSG_LOOK, IT_HYPO, 0, 0, H_1B8E
LookAtHypo:
	cmp	byte ptr [si+hypo_oiled], 1
	je	L1B45
	mov	ax, 0
	mov	bx, OFFSET T_VEN4N010
	call	Say
	jmp	SHORT L1B44

T_VEN4N010	LABEL	BYTE
	DB	'#VEN4\VEN4N010#This is an empty hypodermic injector.',0
L1B44:
	retf

L1B45:
	mov	ax, 0
	mov	bx, OFFSET T_VEN6N007
	call	Say
	jmp	SHORT L1B8D

T_VEN6N007	LABEL	BYTE
	DB	'#VEN6\VEN6N007#The hypo is now filled with multipurpose oil.',0
L1B8D:
	retf

; The communicator: before the Enterprise leaves, Uhura; while the Elasi
; jam it, Spock; otherwise Uhura, tracking the distress call.
H_1B8E:
	SCRIPT	MSG_USE, IT_COMM, OBJ_KIRK, 0, Talk
CallEnterprise:
	cmp	byte ptr [si+enterprise_away], 1
	je	L1C16
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018
	call	Say
	jmp	SHORT L1BDF

T_MUD4_018	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise ... Kirk to Enterprise.',0
L1BDF:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_BRIDU146
	call	Say
	jmp	SHORT L1C15

T_BRIDU146	LABEL	BYTE
	DB	'#BRID\BRIDU146#Nothing to report, Captain.',0
L1C15:
	retf

L1C16:
	cmp	byte ptr [si+elasi_here], 1
	jne	L1C1F
	JMPN	L1D1C

L1C1F:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD4_018_2
	call	Say
	jmp	SHORT L1C63

T_MUD4_018_2	LABEL	BYTE
	DB	'#MUD4\MUD4_018#Kirk to Enterprise, Kirk to Enterprise...',0
L1C63:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_VEN2U093
	call	Say
	jmp	SHORT L1CCE

T_VEN2U093	LABEL	BYTE
	DB	'#VEN2\VEN2U093#Enterprise here. We''re still tracking the distres'
	DB	's call. Are you all right, Sir?',0
L1CCE:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_VEN2_028
	call	Say
	jmp	SHORT L1D1B

T_VEN2_028	LABEL	BYTE
	DB	'#VEN2\VEN2_028#Yes, Uhura. Just wanted a status report. Kirk out'
	DB	'.',0
L1D1B:
	retf

L1D1C:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_VEN2_066
	call	Say
	jmp	SHORT L1D90

T_VEN2_066	LABEL	BYTE
	DB	'#VEN2\VEN2_066#They are jamming all frequencies, Captain. We wil'
	DB	'l not be able to contact the Enterprise.',0
L1D90:
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
	DW	65,139, 80,139, 80,156, 65,156
	DW	21h, 4	; id, points
	DW	43,144, 59,144, 59,153, 43,153
	DW	21h, 4	; id, points
	DW	25,158, 34,158, 34,161, 25,161
	DW	22h, 4	; id, points
	DW	249,99, 264,99, 264,115, 249,115
	DW	23h, 4	; id, points
	DW	296,96, 319,96, 319,184, 296,168
	DW	24h, 4	; id, points
	DW	96,33, 228,33, 228,135, 96,135
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	2, 4	; id, points
	DW	284,169, 297,169, 319,184, 319,193
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	's7r8',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
	DB	'wes',0
N_Ensign_Kije	LABEL	BYTE
	DB	'Ensign Kije',0
N_Elasi_Captain	LABEL	BYTE
	DB	'Elasi Captain',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
	DB	'#VEN8\VEN8_016#Don''t look at me, Jim. You know how much I hate t'
	DB	'hat thing.',0
	DB	'#VEN8\VEN8_024#I recommend I stay behind, Captain. If there is a'
	DB	' problem with the transporter, I am the most qualified to repair'
	DB	' it.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
