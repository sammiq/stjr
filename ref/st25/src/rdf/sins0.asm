; SINS0.RDF - "Sins of Omission", the moon of Proxtrey, before a security
; door built into a hill: the way into the old installation that the
; party has come to search. Meanwhile, Scott reports a fault in the
; transporter.
;
; Actors: 8 the door.
; Objects: 8/20h the door, 21h rocks, 22h stone faces, 23h the planet,
; 24h the stars. Exit 0: room 1.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - Two scripts answer talking to Mosher; the second never runs.
; - The conversation at 00D8 is built at run time.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
rocks_known	EQU	RS_VARS+10h	; bits: the rocks' silver has been found (rooms 0, 3, 4)
door_open1	EQU	RS_VARS+14h	; the security door has opened from inside (room 1)
door_open2	EQU	RS_VARS+15h	; the second door has opened (room 2)
scott_called	EQU	RS_VARS+19h	; Scott has reported the transporter fault
transporter_fixed	EQU	RS_VARS+1Ah	; set in room 1
scanned_stones	EQU	RS_VARS+1Fh	; the point for the stones
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
	DW	64h
rdf_scale_min	LABEL	BYTE
	DW	40h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	0C8h
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
	DW	100,155, 115,170	; entrance 0, crew 0
	DW	90,155, 85,165	; entrance 0, crew 1
	DW	100,150, 100,160	; entrance 0, crew 2
	DW	90,150, 90,155	; entrance 0, crew 3
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
	DW	237,143, 247,143, 237,133, 247,133	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	237,143, 247,143, 237,133, 247,133
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_mscans	LABEL	BYTE
	DB	'mscans',0
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
N_Ensign_Mosher	LABEL	BYTE
	DB	'Ensign Mosher',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
N_Mr_Scott	LABEL	BYTE
	DB	'Mr. Scott',0
rdf_objects	LABEL	BYTE
	DW	20h, 4	; id, points
	DW	63,80, 128,82, 128,131, 61,132
	DW	21h, 5	; id, points
	DW	0,162, 65,136, 204,136, 220,199, 0,199
	DW	22h, 5	; id, points
	DW	224,199, 262,157, 298,134, 308,145, 272,199
	DW	23h, 8	; id, points
	DW	167,47, 172,43, 180,43, 186,48, 186,54, 180,159
	DW	170,59, 167,54
	DW	24h, 5	; id, points
	DW	112,0, 140,66, 196,93, 319,91, 319,0
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	0, 4	; id, points
	DW	46,144, 63,136, 130,133, 146,145

rdf_scripts:
rdf_exits_end:
rdf_regions:
rdf_regions_end:
rdf_bans:
rdf_bans_end:
; The room starts: the door, open or not. The first time, the party can't
; move until Scott's call (tick 40).
H_01F6:
	SCRIPT	MSG_TICK, 1, 0, 0, H_0277
StartRoom:
	jmp	SHORT L0207

N_SIN0LOOP	LABEL	BYTE
	DB	'SIN0LOOP',0
L0207:
	push	OFFSET N_SIN0LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SIN0LOOP")
	add	sp, 4
	cmp	byte ptr [si+scott_called], 0
	jne	L0220
	mov	byte ptr [si+RS_BUSY], 2
L0220:
	cmp	byte ptr [si+door_open2], 1
	jne	L0245
	jmp	SHORT L022E

N_s0dr2	LABEL	BYTE
	DB	's0dr2',0
L022E:
	push	0
	push	0
	push	0
	push	OFFSET N_s0dr2
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s0dr2", 0, 0, 0)
	add	sp, 0Ch
	jmp	SHORT L0268

L0245:
	cmp	byte ptr [si+door_open1], 1
	jne	L0268
	jmp	SHORT L0253

N_s0dr1	LABEL	BYTE
	DB	's0dr1',0
L0253:
	push	0
	push	0
	push	0
	push	OFFSET N_s0dr1
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "s0dr1", 0, 0, 0)
	add	sp, 0Ch
L0268:
	push	-3
	push	1Bh
	push	RC_MUSIC
	SERVICE		; Music(27, -3)
	add	sp, 6
	retf

; Looking and talking.
H_0277:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_02C8
LookAtScene:
	mov	ax, 0
	mov	bx, OFFSET T_SIN0N009
	call	Say
	jmp	SHORT L02C7

T_SIN0N009	LABEL	BYTE
	DB	'#SIN0\SIN0N009#This moon has a thin but breathable atmosphere.',0
L02C7:
	retf

H_02C8:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_0313
LookAtOpenDoor:
	mov	ax, 0
	mov	bx, OFFSET T_SIN0N005
	call	Say
	jmp	SHORT L0312

T_SIN0N005	LABEL	BYTE
	DB	'#SIN0\SIN0N005#The heavy-duty security door is now open.',0
L0312:
	retf

H_0313:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_038B
LookAtDoor:
	mov	ax, 0
	mov	bx, OFFSET T_SIN0N008
	call	Say
	jmp	SHORT L038A

T_SIN0N008	LABEL	BYTE
	DB	'#SIN0\SIN0N008#This looks like a heavy-duty security door built '
	DB	'into the side of a hill on this moon.',0
L038A:
	retf

H_038B:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_040D
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN0_009
	call	Say
	jmp	SHORT L040C

T_SIN0_009	LABEL	BYTE
	DB	'#SIN0\SIN0_009#Aside from the security door on what should be a '
	DB	'lifeless planetoid, this place is unremarkable.',0
L040C:
	retf

H_040D:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_049C
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN0_011
	call	Say
	jmp	SHORT L049B

T_SIN0_011	LABEL	BYTE
	DB	'#SIN0\SIN0_011#The atmosphere is breathable, Jim, but hardly nou'
	DB	'rishing. We should either get inside or go back to the ship.',0
L049B:
	retf

; Mosher. TalkToMosherNever has the same key and the first doesn't set
; RS_MORE, so it never runs.
H_049C:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_04D3
TalkToMosher:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN0_024
	call	Say
	jmp	SHORT L04D2

T_SIN0_024	LABEL	BYTE
	DB	'#SIN0\SIN0_024#Area secure, Captain.',0
L04D2:
	retf

H_04D3:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_050F
LookAtRocks:
	mov	ax, 0
	mov	bx, OFFSET T_SIN0N006
	call	Say
	jmp	SHORT L050E

T_SIN0N006	LABEL	BYTE
	DB	'#SIN0\SIN0N006#There are many rocks here.',0
L050E:
	retf

; Rocks (anim msg 1): tri-phosphorate silver, by Spock's tricorder.
H_050F:
	SCRIPT	MSG_GET, 21h, 0, 0, H_053C
GetRock:
	mov	byte ptr [si+RS_BUSY], 1
	jmp	SHORT L0522

N_kpickw	LABEL	BYTE
	DB	'kpickw',0
L0522:
	push	1
	push	-1
	push	-1
	push	OFFSET N_kpickw
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kpickw", -1, -1, 1)
	add	sp, 0Ch
	or	byte ptr [si+rocks_known], 1
	retf

H_053C:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_0592
TookRock:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	ax, 0
	mov	bx, OFFSET T_SIN0N010
	call	Say
	jmp	SHORT L0585

T_SIN0N010	LABEL	BYTE
	DB	'#SIN0\SIN0N010#You retrieve a rock.',0
L0585:
	push	IT_S8ROCKS
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_S8ROCKS)
	add	sp, 4
	retf

H_0592:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_061B
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
	mov	bx, OFFSET T_SIN0_018
	call	Say
	jmp	SHORT L061A

T_SIN0_018	LABEL	BYTE
	DB	'#SIN0\SIN0_018#Unremarkable except for low grade power emanation'
	DB	's from the door area.',0
L061A:
	retf

H_061B:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_06A3
SpockScansRocks:
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
	mov	bx, OFFSET T_SIN0_017
	call	Say
	jmp	SHORT L069E

T_SIN0_017	LABEL	BYTE
	DB	'#SIN0\SIN0_017#The rocks have a high quantity of Tri-Phosphorate'
	DB	' Silver in them.',0
L069E:
	or	byte ptr [si+rocks_known], 1
	retf

H_06A3:
	SCRIPT	MSG_USE, IT_STRICOR, 23h, 0, H_075D
SpockScansPlanet:
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
	mov	bx, OFFSET T_SIN0_016
	call	Say
	JMPN	L075C

T_SIN0_016	LABEL	BYTE
	DB	'#SIN0\SIN0_016#I cannot get readings from this range, Captain. B'
	DB	'ut if we do not hurry there will be nothing left to get a readin'
	DB	'g on.',0
L075C:
	retf

; Tick 40, once: Scott reports a fault in the transporters.
H_075D:
	SCRIPT	MSG_TICK, 28h, 0, 0, H_0A39
ScottCalls:
	cmp	byte ptr [si+scott_called], 0
	je	L076C
	JMPN	L0A38

L076C:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_SIN0U082
	call	Say
	jmp	SHORT L07B7

T_SIN0U082	LABEL	BYTE
	DB	'#SIN0\SIN0U082#Captain, Mr. Scott wishes to speak with you.',0
L07B7:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN0_003
	call	Say
	jmp	SHORT L07DC

T_SIN0_003	LABEL	BYTE
	DB	'#SIN0\SIN0_003#Mr. Scott?',0
L07DC:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_SIN0_S48
	call	Say
	jmp	SHORT L0831

T_SIN0_S48	LABEL	BYTE
	DB	'#SIN0\SIN0_S48#Aye. We''ve had some slight problems with the tran'
	DB	'sporters.',0
L0831:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN0_007
	call	Say
	jmp	SHORT L0873

T_SIN0_007	LABEL	BYTE
	DB	'#SIN0\SIN0_007#We didn''t notice anything beaming down.',0
L0873:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_SIN0_S50
	call	Say
	JMPN	L0929

T_SIN0_S50	LABEL	BYTE
	DB	'#SIN0\SIN0_S50#Just a glitch in the main transporter program. Mr'
	DB	'. Kyle is loading a back-up, and we''re performing tests. The tra'
	DB	'nsporters will be down for about an hour.',0
L0929:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN0_005
	call	Say
	jmp	SHORT L0973

T_SIN0_005	LABEL	BYTE
	DB	'#SIN0\SIN0_005#That will still give us plenty of time, Scotty.',0
L0973:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_SIN0_S49
	call	Say
	jmp	SHORT L09E5

T_SIN0_S49	LABEL	BYTE
	DB	'#SIN0\SIN0_S49#I know. I have the lads in Engineering doing a co'
	DB	'mplete overhaul of the ship''s systems.',0
L09E5:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN0_001
	call	Say
	jmp	SHORT L0A2F

T_SIN0_001	LABEL	BYTE
	DB	'#SIN0\SIN0_001#Good Mr. Scott. I''ll keep you posted. Kirk out.',0
L0A2F:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+scott_called], 1
L0A38:
	retf

H_0A39:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0B07
TalkToMosherNever:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN0_026
	call	Say
	jmp	SHORT L0A90

T_SIN0_026	LABEL	BYTE
	DB	'#SIN0\SIN0_026#How can there be an atmosphere on a moon of this '
	DB	'size?',0
L0A90:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN0_022
	call	Say
	jmp	SHORT L0ABB

T_SIN0_022	LABEL	BYTE
	DB	'#SIN0\SIN0_022#Unknown, ensign.',0
L0ABB:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN0_006
	call	Say
	jmp	SHORT L0B06

T_SIN0_006	LABEL	BYTE
	DB	'#SIN0\SIN0_006#That''s what we''re here to find out. The unknown.',0
L0B06:
	retf

H_0B07:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_0CFC
LookAtStones:
	mov	ax, 0
	mov	bx, OFFSET T_SIN0N011
	call	Say
	jmp	SHORT L0B45

T_SIN0N011	LABEL	BYTE
	DB	'#SIN0\SIN0N011#These stones look like faces.',0
L0B45:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN0_015
	call	Say
	jmp	SHORT L0B97

T_SIN0_015	LABEL	BYTE
	DB	'#SIN0\SIN0_015#These stones resemble those on Earth, on Easter I'
	DB	'sland.',0
L0B97:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN0_021
	call	Say
	jmp	SHORT L0C03

T_SIN0_021	LABEL	BYTE
	DB	'#SIN0\SIN0_021#Stone monoliths of faces are a common artistic ex'
	DB	'pression in evolving cultures...',0
L0C03:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN0_027
	call	Say
	jmp	SHORT L0C83

T_SIN0_027	LABEL	BYTE
	DB	'#SIN0\SIN0_027#Like the faces on Vandu II. Even the animal face '
	DB	'art of the Orion Post-Decadence Movement is similar.',0
L0C83:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN0_014
	call	Say
	jmp	SHORT L0CFB

T_SIN0_014	LABEL	BYTE
	DB	'#SIN0\SIN0_014#I never realized the Orions ever got past decaden'
	DB	'ce... They hadn''t the last time I was there.',0
L0CFB:
	retf

H_0CFC:
	SCRIPT	MSG_LOOK, 23h, 0, 0, H_0D74
LookAtPlanet:
	mov	ax, 0
	mov	bx, OFFSET T_SIN0N007
	call	Say
	jmp	SHORT L0D73

T_SIN0N007	LABEL	BYTE
	DB	'#SIN0\SIN0N007#This is the planet Proxtrey, currently six hundre'
	DB	'd thousand kilometers from this moon.',0
L0D73:
	retf

H_0D74:
	SCRIPT	MSG_LOOK, 24h, 0, 0, H_0DF9
LookAtStars:
	mov	ax, 0
	mov	bx, OFFSET T_SIN0N004
	call	Say
	jmp	SHORT L0DF8

T_SIN0N004	LABEL	BYTE
	DB	'#SIN0\SIN0N004#Ten thousand points of light are visible to the n'
	DB	'aked eye through the thin atmosphere of this moon.',0
L0DF8:
	retf

H_0DF9:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_0E5D
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_SIN0N002
	call	Say
	jmp	SHORT L0E5C

T_SIN0N002	LABEL	BYTE
	DB	'#SIN0\SIN0N002#James T. Kirk, worried about the safety of the pe'
	DB	'ople of Proxtrey.',0
L0E5C:
	retf

H_0E5D:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_0ECB
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_SIN0N003
	call	Say
	jmp	SHORT L0ECA

T_SIN0N003	LABEL	BYTE
	DB	'#SIN0\SIN0N003#Mr. Spock looks forward to examining the technolo'
	DB	'gy of this ancient culture.',0
L0ECA:
	retf

H_0ECB:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_0F89
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_SIN0N000
	call	Say
	JMPN	L0F88

T_SIN0N000	LABEL	BYTE
	DB	'#SIN0\SIN0N000#Dr. Leonard McCoy, knowing that they aren''t likel'
	DB	'y to encounter any medical problems, is rather annoyed about bei'
	DB	'ng dragged yet again into the transporter.',0
L0F88:
	retf

H_0F89:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_0FF2
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_SIN0N001
	call	Say
	jmp	SHORT L0FF1

T_SIN0N001	LABEL	BYTE
	DB	'#SIN0\SIN0N001#Ensign Mosher seems to be rather curious about th'
	DB	'e planet''s technology.',0
L0FF1:
	retf

; Tricorders and the medkit.
H_0FF2:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_115E
SpockScansDoor:
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
	mov	bx, OFFSET T_SIN0_019
	call	Say
	jmp	SHORT L107E

T_SIN0_019	LABEL	BYTE
	DB	'#SIN0\SIN0_019#As expected Captain. The source of power emanatio'
	DB	'ns lies beyond that door.',0
L107E:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN0_025
	call	Say
	jmp	SHORT L10FF

T_SIN0_025	LABEL	BYTE
	DB	'#SIN0\SIN0_025#A power source that has lasted millenia and endur'
	DB	'ed major catastrophes. That''s fascinating, Mr. Spock.',0
L10FF:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN0_013
	call	Say
	jmp	SHORT L113A

T_SIN0_013	LABEL	BYTE
	DB	'#SIN0\SIN0_013#Do you have Vulcan blood ensign?',0
L113A:
	mov	ax, OFFSET N_Ensign_Mosher
	mov	bx, OFFSET T_SIN0_028
	call	Say
	jmp	SHORT L115D

T_SIN0_028	LABEL	BYTE
	DB	'#SIN0\SIN0_028#No, sir.',0
L115D:
	retf

H_115E:
	SCRIPT	MSG_USE, IT_STRICOR, 22h, 0, H_125D
SpockScansStones:
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
	mov	bx, OFFSET T_SIN0_020
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN0_008
	call	Say
	jmp	SHORT L11E8

T_SIN0_008	LABEL	BYTE
	DB	'#SIN0\SIN0_008#Which means that this moon might still be inhabit'
	DB	'ed, Mr. Spock.',0
L11E8:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_SIN0_023
	call	Say
	jmp	SHORT L124E

T_SIN0_023	LABEL	BYTE
	DB	'#SIN0\SIN0_023#We have detected no signs of life, Captain, but t'
	DB	'he possibility does exist.',0
L124E:
	cmp	byte ptr [si+scanned_stones], 1
	je	L125C
	mov	byte ptr [si+scanned_stones], 1
	add	word ptr [si+score], 1
L125C:
	retf

H_125D:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_KIRK, 0, H_1265
	jmp	SHORT MedkitOnSpock

H_1265:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_SPOCK, 0, H_126D
MedkitOnSpock:
	jmp	SHORT MedkitOnMcCoy

H_126D:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_MCCOY, 0, H_1275
MedkitOnMcCoy:
	jmp	SHORT MedkitOnRedshirt

H_1275:
	SCRIPT	MSG_USE, IT_MEDKIT, OBJ_REDSHIRT, 0, H_12EF
MedkitOnRedshirt:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN0_012
	call	Say
	jmp	SHORT L12EE

T_SIN0_012	LABEL	BYTE
	DB	'#SIN0\SIN0_012#There''s not much I can do for cosmic radiation. I'
	DB	't''s best if we find some cover indoors.',0
L12EE:
	retf

H_12EF:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_KIRK, 0, H_12F7
	jmp	SHORT McCoyScansRedshirt

H_12F7:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_SPOCK, 0, H_12FF
	jmp	SHORT McCoyScansRedshirt

H_12FF:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_MCCOY, 0, H_1307
	jmp	SHORT McCoyScansRedshirt

H_1307:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_REDSHIRT, 0, H_13F1
McCoyScansRedshirt:
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
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_SIN0_010
	call	Say
	JMPN	L13F0

T_SIN0_010	LABEL	BYTE
	DB	'#SIN0\SIN0_010#It''s what I was afraid of, Jim. The thin atmosphe'
	DB	're of this moon doesn''t provide enough protection from cosmic ra'
	DB	'ys. We shouldn''t stay here any more than a few hours.',0
L13F0:
	retf

; The communicator.
H_13F1:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_153C
UseCommunicator:
	cmp	byte ptr [si+transporter_fixed], 0
	je	L1400
	JMPN	L14FC

L1400:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN0_004
	call	Say
	jmp	SHORT L1445

T_SIN0_004	LABEL	BYTE
	DB	'#SIN0\SIN0_004#Scotty, report on the transporter problem.',0
L1445:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_SIN0_S01
	call	Say
	jmp	SHORT L14BA

T_SIN0_S01	LABEL	BYTE
	DB	'#SIN0\SIN0_S01#No change Captain. Although why it happened is ab'
	DB	'out as clear as a foggy night in Glasgow.',0
L14BA:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_SIN0_002
	call	Say
	jmp	SHORT L14FC

T_SIN0_002	LABEL	BYTE
	DB	'#SIN0\SIN0_002#Let me know if things change. Kirk out.',0
L14FC:
	cmp	byte ptr [si+transporter_fixed], 1
	jne	L153B
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_SIN0U069
	call	Say
	jmp	SHORT L153B

T_SIN0U069	LABEL	BYTE
	DB	'#SIN0\SIN0U069#Nothing new to report Captain.',0
L153B:
	retf

; The door (room 1).
H_153C:
	SCRIPT	MSG_WALK, 20h, 0, 0, H_155F
WalkToDoor:
	mov	ax, 0
	push	ax
	mov	ax, 8Ch
	push	ax
	mov	ax, 5Fh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 95, 140, 0)
	add	sp, 0Ah
	retf

H_155F:
	SCRIPT	MSG_WALK, 8, 0, 0, T_SIN0_020
WalkToOpenDoor:
	mov	ax, 0
	push	ax
	mov	ax, 8Ch
	push	ax
	mov	ax, 5Fh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 95, 140, 0)
	add	sp, 0Ah
	retf

rdf_scripts_end	LABEL	BYTE
T_SIN0_020	LABEL	BYTE
	DB	'#SIN0\SIN0_020#Large quantities of atmosphere are being circulat'
	DB	'ed through these rocks. I would guess there are storage units wi'
	DB	'thin this satellite which are constantly replacing the atmospher'
	DB	'e that is lost because of this moon''s weak gravity.',0

RDF	ENDS
	END
