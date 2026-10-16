; MUDD3.RDF - "Another Fine Mess", the alien ship's library. The console
; on the pedestal works the ship's computer; with the clue that the
; aliens count in sixes (room 4), Spock and McCoy join their tricorders
; to decode it, which teaches McCoy the aliens' physiology (needed in
; room 2). Mudd then comes in, eager to download it all; allowed, he
; wipes the databanks. Otherwise the library can be saved onto the alien
; disks (room 0). A doover lies on the floor.
;
; Actors: 8 Mudd, 9 the pedestal, 12 (0Ch) the upper door, 13 (0Dh) the
; doover.
; Objects: 8 Mudd, 0Dh the doover, 20h the data screen, 21h the console,
; 22h/23h by the doors.
; Exits: 1 room 1, 2 room 4. Regions 0, 1: the doorsteps.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - KirkUsesScreenNever's key has its objects swapped, so it never runs.
; - The script chain runs on into code at 0DE4: the engine reads its bytes
;   as key 50 6A 03 2E and next 1EFF (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
six_clue	EQU	RS_VARS+0Ch	; Spock has noticed the aliens' fixation on six (room 4)
know_physiology	EQU	RS_VARS+0Dh	; the tricorders have decoded the library: McCoy knows the aliens
library_erased	EQU	RS_VARS+0Eh	; Mudd has wiped the databanks
mudd_here	EQU	RS_VARS+0Fh	; Mudd is in the room
mudd_asked	EQU	RS_VARS+11h	; Mudd has asked to use the library
mudd_allowed	EQU	RS_VARS+12h	; Kirk let him
used_device	EQU	RS_VARS+13h	; the alien device has been fired, anywhere (+5 once)
mudd_incident	EQU	RS_VARS+16h	; Mudd is causing trouble somewhere: no other scene with him starts
mudd_came	EQU	RS_VARS+17h	; Mudd's library scene has started
read_library	EQU	RS_VARS+18h	; Spock has retrieved the library's topics
took_doover	EQU	RS_VARS+19h
saved_library	EQU	RS_VARS+1Ah	; the library is on the disks (+3)
air_failing	EQU	RS_VARS+1Dh	; life support is failing: the countdown runs (room 5)
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
	DW	91h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	70h
rdf_scale_min	LABEL	BYTE
	DW	50h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	-1, 1, 4, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	0,0, 0,0	; entrance 0, crew 0
	DW	0,0, 0,0	; entrance 0, crew 1
	DW	0,0, 0,0	; entrance 0, crew 2
	DW	0,0, 0,0	; entrance 0, crew 3
	DW	248,143, 241,149	; entrance 1, crew 0
	DW	257,137, 205,135	; entrance 1, crew 1
	DW	273,131, 236,132	; entrance 1, crew 2
	DW	289,129, 272,166	; entrance 1, crew 3
	DW	192,124, 241,149	; entrance 2, crew 0
	DW	176,121, 205,135	; entrance 2, crew 1
	DW	185,118, 236,132	; entrance 2, crew 2
	DW	172,112, 272,166	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	241,149, 205,135, 236,132, 272,166	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	241,149, 205,135, 236,132, 272,166
; In the room file, so these start again each time the room loads
ready_to_join	LABEL	BYTE	; Spock has proposed joining the tricorders
	DB	0
tricorders_busy	LABEL	BYTE	; both tricorders are processing the data
	DB	0
going_door	LABEL	BYTE
	DB	0
collapsed	LABEL	BYTE	; crew members down when the air ran out
	DB	0
N_s4lbhs	LABEL	BYTE
	DB	's4lbhs',0
N_s4lbhb	LABEL	BYTE
	DB	's4lbhb',0
N_s4lbpb	LABEL	BYTE
	DB	's4lbpb',0
N_s4lbap	LABEL	BYTE
	DB	's4lbap',0
N_s4lbdo	LABEL	BYTE
	DB	's4lbdo',0
N_s4lbdv	LABEL	BYTE
	DB	's4lbdv',0
N_kusemn	LABEL	BYTE
	DB	'kusemn',0
N_kgetdn	LABEL	BYTE
	DB	'kgetdn',0
N_sgetde	LABEL	BYTE
	DB	'sgetde',0
N_mgetds	LABEL	BYTE
	DB	'mgetds',0
N_rgetds	LABEL	BYTE
	DB	'rgetds',0
N_sscans	LABEL	BYTE
	DB	'sscans',0
N_s4cbxp	LABEL	BYTE
	DB	's4cbxp',0

rdf_scripts:
; The room starts: the pedestal, the doover, and Mudd's scene: once the
; library is decoded (and no other trouble with Mudd), he comes in.
H_0129:
	SCRIPT	MSG_TICK, 1, 0, 0, H_01CE
StartRoom:
	jmp	SHORT L013A

N_MUD3LOOP	LABEL	BYTE
	DB	'MUD3LOOP',0
L013A:
	push	OFFSET N_MUD3LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUD3LOOP")
	add	sp, 4
	mov	byte ptr [si+RS_FALL+3], 3
	cmp	byte ptr [si+library_erased], 1
	jne	L0187
	push	0
	push	9Fh
	push	0A2h
	push	OFFSET N_s4lbpb
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "s4lbpb", 162, 159, 0)
	add	sp, 0Ch
	cmp	byte ptr [si+took_doover], 0
	jne	L0187
	push	0
	push	0A8h
	push	0B7h
	push	OFFSET N_s4lbdv
	push	0Dh
	push	RC_ANIM0
	SERVICE		; Anim0(13, "s4lbdv", 183, 168, 0)
	add	sp, 0Ch
L0187:
	mov	byte ptr [si+mudd_here], 0
	cmp	byte ptr [si+mudd_came], 0
	jne	L01CD
	cmp	byte ptr [si+know_physiology], 1
	jne	L01CD
	cmp	byte ptr [si+mudd_incident], 0
	jne	L01CD
	mov	byte ptr [si+mudd_came], 1
	push	0
	push	9Fh
	push	0A2h
	push	OFFSET N_s4lbhs
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s4lbhs", 162, 159, 0)
	add	sp, 0Ch
	push	3
	push	RC_MUSIC
	SERVICE		; Music(3)
	add	sp, 4
	mov	byte ptr [si+mudd_here], 1
	mov	word ptr [si+RS_TIMERS+4], 10h
L01CD:
	retf

H_01CE:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_023C
CallEnterprise:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD3_003
	call	Say
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_STATICU1
	call	Say
	retf

T_MUD3_003	LABEL	BYTE
	DB	'#MUD3\MUD3_003#Kirk to Enterprise...',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
T_STATICU1	LABEL	BYTE
	DB	'#SFX\STATICU1#Ent... neu ... trans...',0

; The data screen.
H_023C:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_025C
LookAtScreen:
	cmp	byte ptr [si+know_physiology], 0
	jne	L0252
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_038
	call	Say
	retf

L0252:
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N017
	call	Say
	retf

H_025C:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_029F
SpockScansScreen:
	cmp	byte ptr cs:tricorders_busy, 1
	jne	L0274
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3_039
	call	Say
	retf

L0274:
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
	mov	bx, OFFSET T_MUD3_017
	call	Say
	retf

; The key has its objects swapped (20h used on Kirk, not Kirk on 20h), so
; this never runs.
H_029F:
	SCRIPT	MSG_USE, 20h, OBJ_KIRK, 0, H_02BE
KirkUsesScreenNever:
	cmp	byte ptr [si+know_physiology], 0
	jne	L02BD
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N011
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_037
	call	Say
L02BD:
	retf

; The console. Spock, with the six clue, proposes joining the tricorders
; (McCoy's tricorder then, msg 2; timer 1 when done: know_physiology,
; +1). Afterwards Spock reads out the library's topics (timer 3).
H_02BE:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_03E7
SpockUsesConsole:
	mov	byte ptr [si+RS_FALL+1], 1
	push	1
	push	RC_STOPANIM
	SERVICE		; StopAnim(1)
	add	sp, 4
	cmp	byte ptr [si+mudd_asked], 0
	je	L02DD
	JMPN	L0438

L02DD:
	cmp	byte ptr [si+know_physiology], 0
	jne	L0320
	cmp	byte ptr [si+six_clue], 1
	je	L02EC
	JMPN	L0416

L02EC:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_043
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD3_022
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_056
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD3_015
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_047
	call	Say
	mov	byte ptr cs:ready_to_join, 1
	retf

L0320:
	cmp	byte ptr [si+read_library], 1
	jne	L0330
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_035
	call	Say
	retf

L0330:
	mov	byte ptr [si+read_library], 1
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_054
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD3_032
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_050
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_049
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_046
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD3_007
	call	Say
	add	word ptr [si+score], 1
	push	0
	push	64h
	push	32h
	push	OFFSET N_s4lbap
	push	0Ah
	push	RC_ANIM0
	jmp	SHORT L0386

N_LSHAIANS	LABEL	BYTE
	DB	'LSHAIANS',0
L0386:
	push	OFFSET N_LSHAIANS
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("LSHAIANS")
	add	sp, 4
	SERVICE		; Anim0(10, "s4lbap", 50, 100, 0)
	add	sp, 0Ch
	mov	byte ptr [si+RS_FALL], 3
	push	0
	push	RC_STOPANIM
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	byte ptr [si+RS_FALL+1], 3
	push	1
	push	RC_STOPANIM
	SERVICE		; StopAnim(1)
	add	sp, 4
	mov	byte ptr [si+RS_FALL+2], 3
	push	2
	push	RC_STOPANIM
	SERVICE		; StopAnim(2)
	add	sp, 4
	mov	byte ptr [si+RS_FALL+3], 3
	push	3
	push	RC_STOPANIM
	SERVICE		; StopAnim(3)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 1
	mov	word ptr [si+RS_TIMERS+6], 28h
	retf

H_03E7:
	SCRIPT	MSG_TIMER, 3, 0, 0, H_0487
LibraryTopics:
	mov	byte ptr [si+RS_BUSY], 0
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD3_027
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_053
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD3_028
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD3_026
	call	Say
	retf

L0416:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_044
	call	Say
	mov	byte ptr [si+RS_FALL+1], 3
	push	0
	push	87h
	push	0CDh
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 205, 135, 0)
	add	sp, 0Ah
	retf

L0438:
	cmp	byte ptr [si+library_erased], 0
	jne	L0462
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N000
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_052
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD3_012
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD3_024
	call	Say
L0462:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD3_006
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_048
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD3_008
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_051
	call	Say
	retf

H_0487:
	SCRIPT	MSG_USE, OBJ_MCCOY, 21h, 0, H_04AF
McCoyUsesConsole:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD3_021
	call	Say
	mov	byte ptr [si+RS_FALL+2], 3
	push	0
	push	84h
	push	0ECh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 236, 132, 0)
	add	sp, 0Ah
	retf

H_04AF:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 21h, 0, H_04D7
BuchertUsesConsole:
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD3_021
	call	Say
	mov	byte ptr [si+RS_FALL+3], 3
	push	0
	push	0A6h
	push	110h
	push	3
	push	RC_WALK
	SERVICE		; Walk(3, 272, 166, 0)
	add	sp, 0Ah
	retf

H_04D7:
	SCRIPT	MSG_USE, IT_MTRICOR, 21h, 0, H_056A
McCoyScansConsole:
	cmp	byte ptr cs:tricorders_busy, 1
	jne	L04EF
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3_039
	call	Say
	retf

L04EF:
	mov	byte ptr [si+RS_FALL+2], 1
	push	2
	push	RC_STOPANIM
	SERVICE		; StopAnim(2)
	add	sp, 4
	cmp	byte ptr [si+know_physiology], 0
	jne	L0548
	cmp	byte ptr cs:ready_to_join, 1
	jne	L0548
	cmp	byte ptr [si+six_clue], 1
	jne	L0548
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL+2], 1
	push	0
	push	88h
	push	0ACh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 172, 136, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+1], 1
	push	2
	push	8Ch
	push	0A5h
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 165, 140, 2)
	add	sp, 0Ah
	retf

L0548:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD3_021
	call	Say
	mov	byte ptr [si+RS_FALL+2], 3
	push	0
	push	84h
	push	0ECh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 236, 132, 0)
	add	sp, 0Ah
	retf

H_056A:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_05F1
SpockScansConsole:
	mov	byte ptr [si+RS_FALL+1], 1
	push	1
	push	RC_STOPANIM
	SERVICE		; StopAnim(1)
	add	sp, 4
	cmp	byte ptr cs:tricorders_busy, 1
	jne	L0592
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3_039
	call	Say
	retf

L0592:
	cmp	byte ptr [si+know_physiology], 0
	jne	L05AA
	cmp	byte ptr [si+six_clue], 0
	jne	L05CC
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_042
	call	Say
	jmp	SHORT L05B3

	DB	0CBh
L05AA:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_041
	call	Say
L05B3:
	mov	byte ptr [si+RS_FALL+1], 3
	push	0
	push	87h
	push	0CDh
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 205, 135, 0)
	add	sp, 0Ah
	retf

L05CC:
	cmp	byte ptr cs:ready_to_join, 1
	jne	L05AA
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL+2], 1
	push	2
	push	88h
	push	0ACh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 172, 136, 2)
	add	sp, 0Ah
	retf

H_05F1:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_062D
TricordersJoined:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_018
	call	Say
	mov	byte ptr cs:tricorders_busy, 1
	mov	word ptr [si+RS_TIMERS+2], 32h
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
	retf

H_062D:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_068E
DataProcessed:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_040
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_034
	call	Say
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr cs:tricorders_busy, 0
	mov	byte ptr cs:ready_to_join, 0
	mov	byte ptr [si+know_physiology], 1
	add	word ptr [si+score], 1
	mov	byte ptr [si+RS_FALL+1], 3
	push	0
	push	87h
	push	0CDh
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 205, 135, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+2], 3
	push	0
	push	84h
	push	0ECh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 236, 132, 0)
	add	sp, 0Ah
	retf

; Timer 2: Mudd wants the library; let him (mudd_allowed) and on timer 4
; he wipes it.
H_068E:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_06F0
MuddWantsLibrary:
	mov	byte ptr [si+mudd_asked], 1
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD3_065
	call	Say
	mov	ax, OFFSET KirkToMudd
	call	Talk
	AX8	cmp, 0
	jne	L06BA
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD3_066
	call	Say
	mov	byte ptr [si+mudd_allowed], 1
	retf

L06BA:
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD3_064
	call	Say
	mov	word ptr [si+RS_TIMERS+8], 62h
	mov	byte ptr [si+RS_BUSY], 2
	push	1Ah
	push	RC_MUSIC
	SERVICE		; Music(26)
	add	sp, 4
	push	0
	push	9Fh
	push	0A2h
	push	OFFSET N_s4lbhb
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "s4lbhb", 162, 159, 0)
	add	sp, 0Ch
	retf

H_06F0:
	SCRIPT	MSG_TIMER, 4, 0, 0, H_0711
MuddErasesLibrary:
	mov	byte ptr [si+library_erased], 1
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD3_063
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD3_031
	call	Say
	mov	byte ptr [si+RS_BUSY], 0
	retf

; The disks in the console: the library saved onto them (+3, once).
H_0711:
	SCRIPT	MSG_USE, IT_DISKS, 21h, 0, H_0755
DisksInConsole:
	cmp	byte ptr [si+library_erased], 1
	jne	L0727
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N014
	call	Say
	retf

L0727:
	cmp	byte ptr [si+know_physiology], 1
	jne	L074B
	cmp	byte ptr [si+mudd_allowed], 0
	jne	L074B
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N020
	call	Say
	cmp	byte ptr [si+saved_library], 1
	je	L074A
	add	word ptr [si+score], 3
	mov	byte ptr [si+saved_library], 1
L074A:
	retf

L074B:
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N019
	call	Say
	retf

H_0755:
	SCRIPT	MSG_USE, IT_DEGRIME, ANY, 0, H_0765
UseDegrimer:
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N001
	call	Say
	retf

; Common to all of the mission's rooms: the de-grimer on the lenses makes
; the alien device (+1); firing the device sets off an explosion at Kirk
; (anim msg 9), +5 the first time anywhere; the de-grimer on anything else
; just cleans it.
H_0765:
	SCRIPT	MSG_USE, IT_LENSES, IT_DEGRIME, 0, H_0793
CleanLenses:
	push	IT_LENSES
	push	RC_TAKEITEM
	push	IT_DEGRIME
	push	RC_TAKEITEM
	push	IT_ALIENDV
	push	RC_GIVEITEM
	mov	di, 3
L077A:
	SERVICE		; GiveItem(IT_ALIENDV); TakeItem(IT_DEGRIME); TakeItem(IT_LENSES)
	add	sp, 4
	dec	di
	jne	L077A
	add	word ptr [si+score], 1
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N016
	call	Say
	retf

H_0793:
	SCRIPT	MSG_USE, IT_ALIENDV, ANY, 0, H_07E6
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
	push	9
	push	0Ah
	push	ax
	push	OFFSET N_s4cbxp
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, "s4cbxp", ?, 10, 9)
	add	sp, 0Ch
	jmp	SHORT L07D6

N_EXPLO3	LABEL	BYTE
	DB	'EXPLO3',0
L07D6:
	push	OFFSET N_EXPLO3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EXPLO3")
	add	sp, 4
	retf

; The alien device has gone off here (anim msg 9).
H_07E6:
	SCRIPT	MSG_ANIM_DONE, 9, 0, 0, H_0808
DeviceFired:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+used_device], 0
	jne	L0807
	mov	byte ptr [si+used_device], 1
	add	word ptr [si+score], 5
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD2_002
	call	Say
L0807:
	retf

; The doover (msgs 3, 1): +1.
H_0808:
	SCRIPT	MSG_GET, 0Dh, 0, 0, H_083B
GetDoover:
	cmp	byte ptr [si+took_doover], 0
	jne	L0831
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 0
	push	3
	push	0C1h
	push	0BAh
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 186, 193, 3)
	add	sp, 0Ah
	retf

L0831:
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N018
	call	Say
	retf

H_083B:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_085B
KirkAtDoover:
	mov	byte ptr [si+RS_FALL], 0
	push	1
	push	-1
	push	-1
	push	OFFSET N_kusemn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusemn", -1, -1, 1)
	add	sp, 0Ch
	retf

H_085B:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_0886
TookDoover:
	mov	byte ptr [si+RS_BUSY], 0
	push	0Dh
	push	RC_STOPANIM
	SERVICE		; StopAnim(13)
	add	sp, 4
	mov	byte ptr [si+took_doover], 1
	add	word ptr [si+score], 1
	push	IT_DOOVER
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_DOOVER)
	add	sp, 4
	retf

; Every tick, common to all of the mission's rooms: while life support is
; failing, the air runs down from 6978h, with warnings at 4F1Ah, 34BCh
; and 1A5Eh; at 1 the crew collapse (walk msgs 9-12) and the game is
; over.
H_0886:
	SCRIPT	MSG_TICK, ANY, ANY, ANY, H_0A01
AirRunsOut:
	cmp	byte ptr [si+air_failing], 0
	jne	L0895
	JMPN	L0932

L0895:
	cmp	word ptr [si+air_countdown], 1
	je	L08A5
	mov	word ptr [si+air_countdown], 1
	mov	word ptr [si+air_left], 6978h
L08A5:
	dec	word ptr [si+air_left]
	cmp	word ptr [si+air_left], 1A5Eh
	jne	L08B2
	JMPN	L0947

L08B2:
	cmp	word ptr [si+air_left], 34BCh
	jne	L08BC
	JMPN	L093D

L08BC:
	cmp	word ptr [si+air_left], 4F1Ah
	je	L0933
	cmp	word ptr [si+air_left], 1
	jne	L0932
	mov	byte ptr [si+RS_BUSY], 1
	push	9
	push	95h
	push	0F1h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 241, 149, 9)
	add	sp, 0Ah
	push	0Ah
	push	87h
	push	0CDh
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 205, 135, 10)
	add	sp, 0Ah
	push	0Bh
	push	84h
	push	0ECh
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 236, 132, 11)
	add	sp, 0Ah
	push	0Ch
	push	0A6h
	push	110h
	push	3
	push	RC_WALK
	SERVICE		; Walk(3, 272, 166, 12)
	add	sp, 0Ah
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N008
	call	Say
	push	0
	push	RC_GAMEOVER
	SERVICE		; GameOver(0)
	add	sp, 4
L0932:
	retf

L0933:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_0951
	call	Say
	retf

L093D:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_0974
	call	Say
	retf

L0947:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_0997
	call	Say
	retf

S_0951	LABEL	BYTE
	DB	'Life support down to 75%, Captain.',0
S_0974	LABEL	BYTE
	DB	'Life support down to 50%, Captain.',0
S_0997	LABEL	BYTE
	DB	'Life support down to 25%, Captain.',0
T_MUD3N008	LABEL	BYTE
	DB	'#MUD3\MUD3N008#Life support fails completely and you fall uncons'
	DB	'cious.',0

H_0A01:
	SCRIPT	MSG_WALK_DONE, 9, 0, 0, H_0A1E
KirkCollapses:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kgetdn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kgetdn", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0A73

H_0A1E:
	SCRIPT	MSG_WALK_DONE, 0Ah, 0, 0, H_0A3B
SpockCollapses:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sgetde
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sgetde", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0A73

H_0A3B:
	SCRIPT	MSG_WALK_DONE, 0Bh, 0, 0, H_0A58
McCoyCollapses:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mgetds
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mgetds", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0A73

H_0A58:
	SCRIPT	MSG_WALK_DONE, 0Ch, 0, 0, H_0B14
RedshirtCollapses:
	push	0
	push	-1
	push	-1
	push	OFFSET N_rgetds
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rgetds", -1, -1, 0)
	add	sp, 0Ch
L0A73:
	inc	byte ptr cs:collapsed
	cmp	byte ptr cs:collapsed, 4
	jne	L0A89
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N013
	call	Say
L0A89:
	retf

T_MUD3N013	LABEL	BYTE
	DB	'#MUD3\MUD3N013#The atmosphere in the ship has dropped below the '
	DB	'level needed to sustain life. You drop to unconsciousness and sl'
	DB	'owly die.',0

; Looking.
H_0B14:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_0B23
LookAtConsole:
	sub	ax, ax
	mov	bx, OFFSET T_MUD3N015
	call	Say
	retf

; The doors: walk there; at the step the door slides (regions 0, 1).
H_0B23:
	SCRIPT	MSG_WALK, 22h, 0, 0, H_0B47
WalkToUpperDoor:
	mov	byte ptr cs:going_door, 1
	mov	byte ptr [si+RS_BUSY], 1
	push	0
	push	70h
	push	0B8h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 184, 112, 0)
	add	sp, 0Ah
	retf

H_0B47:
	SCRIPT	MSG_REGION, 0, 0, 0, H_0B86
ReachUpperDoor:
	cmp	byte ptr cs:going_door, 1
	jne	L0B85
	jmp	SHORT L0B60

N_SMADOOR3	LABEL	BYTE
	DB	'SMADOOR3',0
L0B60:
	push	OFFSET N_SMADOOR3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SMADOOR3")
	add	sp, 4
	push	0
	push	6Fh
	push	0BAh
	push	OFFSET N_s4lbdo
	push	0Ch
	push	RC_ANIM0
	SERVICE		; Anim0(12, "s4lbdo", 186, 111, 0)
	add	sp, 0Ch
L0B85:
	retf

H_0B86:
	SCRIPT	MSG_WALK, 23h, 0, 0, H_0BAB
WalkToRightDoor:
	mov	byte ptr cs:going_door, 1
	mov	byte ptr [si+RS_BUSY], 1
	push	0
	push	81h
	push	121h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 289, 129, 0)
	add	sp, 0Ah
	retf

H_0BAB:
	SCRIPT	MSG_REGION, 1, 0, 0, H_0BD4
ReachRightDoor:
	cmp	byte ptr cs:going_door, 1
	jne	L0BD3
	jmp	SHORT L0BC4

N_SMADOOR3_2	LABEL	BYTE
	DB	'SMADOOR3',0
L0BC4:
	push	OFFSET N_SMADOOR3_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SMADOOR3")
	add	sp, 4
L0BD3:
	retf

H_0BD4:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_0BF4
LookAtKirk:
	cmp	byte ptr [si+mudd_here], 1
	je	L0BEA
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N005
	call	Say
	retf

L0BEA:
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N004
	call	Say
	retf

H_0BF4:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_0C14
LookAtSpock:
	cmp	byte ptr [si+mudd_here], 1
	je	L0C0A
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N012
	call	Say
	retf

L0C0A:
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N002
	call	Say
	retf

H_0C14:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_0C34
LookAtMcCoy:
	cmp	byte ptr [si+mudd_here], 1
	je	L0C2A
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N010
	call	Say
	retf

L0C2A:
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N009
	call	Say
	retf

H_0C34:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_0C54
LookAtRedshirt:
	cmp	byte ptr [si+mudd_here], 1
	je	L0C4A
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N007
	call	Say
	retf

L0C4A:
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N006
	call	Say
	retf

; Mudd.
H_0C54:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_0C64
LookAtMudd:
	mov	ax, OFFSET S_0EF8
	mov	bx, OFFSET T_MUD3N003
	call	Say
	retf

H_0C64:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0C96
TalkToKirk:
	cmp	byte ptr [si+mudd_here], 1
	je	L0C8C
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD3_014
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_057
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD3_025
	call	Say
	retf

L0C8C:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD3_002
	call	Say
	retf

H_0C96:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0CC8
TalkToSpock:
	cmp	byte ptr [si+mudd_here], 1
	je	L0CBE
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_055
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD3_033
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD3_011
	call	Say
	retf

L0CBE:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_MUD3_019
	call	Say
	retf

H_0CC8:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0CF1
TalkToMcCoy:
	cmp	byte ptr [si+mudd_here], 1
	je	L0CDE
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD3_023
	call	Say
	retf

L0CDE:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD3_030
	call	Say
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD3_062
	call	Say
	retf

H_0CF1:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0D23
TalkToRedshirt:
	cmp	byte ptr [si+mudd_here], 1
	je	L0D19
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD3_070
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD3_016
	call	Say
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD3_071
	call	Say
	retf

L0D19:
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD3_067
	call	Say
	retf

H_0D23:
	SCRIPT	MSG_TALK, 8, 0, 0, H_0D81
TalkToMudd:
	cmp	byte ptr [si+library_erased], 0
	je	L0D80
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD3_060
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD3_029
	call	Say
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD3_061
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD3_013
	call	Say
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD3_058
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_3343
	call	Say
	mov	ax, OFFSET N_Lt_Buchert
	mov	bx, OFFSET T_MUD3_069
	call	Say
	mov	ax, OFFSET N_Harry_Mudd
	mov	bx, OFFSET T_MUD3_059
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_MUD3_005
	call	Say
L0D80:
	retf

H_0D81:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, Talk
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_MUD3_020
	call	Say
	retf

T_MUD3_020	LABEL	BYTE
	DB	'#MUD3\MUD3_020#Everyone is healthy, Jim, there''s no need for the'
	DB	' medical kit here.',0
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
	DW	80FFh, 165, 140	; actions (bit 15 set), walk to (x, y)
	DW	21h, 7	; id, points
	DW	170,119, 189,135, 177,159, 155,160, 141,145, 142,130
	DW	160,119
	DW	20h, 7	; id, points
	DW	59,68, 76,71, 90,82, 90,107, 67,122, 38,108
	DW	38,81
	DW	22h, 5	; id, points
	DW	184,84, 201,117, 195,125, 172,125, 168,117
	DW	23h, 5	; id, points
	DW	298,85, 291,132, 262,138, 254,134, 265,127
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	1, 3	; id, points
	DW	270,127, 292,127, 290,132
	DW	2, 4	; id, points
	DW	172,110, 197,110, 202,114, 168,114
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	168,117, 201,117, 195,125, 172,125
	DW	1, 4	; id, points
	DW	267,127, 287,132, 264,138, 254,134
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Buchert	LABEL	BYTE
	DB	'Lt. Buchert',0
N_Harry_Mudd	LABEL	BYTE
	DB	'Harry Mudd',0
S_0EF8	LABEL	BYTE
	DB	0
T_MUD3_035	LABEL	BYTE
	DB	'#MUD3\MUD3_035#I believe I have retrieved as much data as I can,'
	DB	' Captain.',0
T_MUD3_039	LABEL	BYTE
	DB	'#MUD3\MUD3_039#The tricorder''s entire sensor and data processing'
	DB	' capabilities are presently occupied with decipherment of the sh'
	DB	'ip''s library.',0
T_MUD3_040	LABEL	BYTE
	DB	'#MUD3\MUD3_040#The tricorders are again available for general us'
	DB	'e. The alien ship''s computer data is now accessible from the shi'
	DB	'p''s library.',0
T_MUD3_034	LABEL	BYTE
	DB	'#MUD3\MUD3_034#I believe I have downloaded enough information to'
	DB	' our tricorders to enable operation of most of the ship''s contro'
	DB	'ls, Captain.',0
T_MUD3N017	LABEL	BYTE
	DB	'#MUD3\MUD3N017#This might be a data screen of some kind.',0
T_MUD3_038	LABEL	BYTE
	DB	'#MUD3\MUD3_038#The data viewscreen is operational. The informati'
	DB	'on selectors are controlled from the console platform.',0
T_MUD3_017	LABEL	BYTE
	DB	'#MUD3\MUD3_017#Apparently an information data screen, something '
	DB	'like the display readers on the Enterprise.',0
T_MUD3N011	LABEL	BYTE
	DB	'#MUD3\MUD3N011#Nothing happens.',0
T_MUD3_037	LABEL	BYTE
	DB	'#MUD3\MUD3_037#I would suggest, Captain, that the controls to th'
	DB	'is screen are elsewhere in this room.',0
T_MUD3N015	LABEL	BYTE
	DB	'#MUD3\MUD3N015#The sphere in the middle of this console appears '
	DB	'to be some sort of control mechanism.',0
T_MUD3_044	LABEL	BYTE
	DB	'#MUD3\MUD3_044#This seems to activate the ship''s computer bank c'
	DB	'ontrol node. I lack sufficient information to commence data retr'
	DB	'ieval, however.  Simply put, without some understanding of the a'
	DB	'liens'' mindset, there''s no place to start.',0
T_MUD3_043	LABEL	BYTE
	DB	'#MUD3\MUD3_043#This seems to activate the ship''s computer bank c'
	DB	'ontrol node. Given the aliens'' predilection for multiples of 3, '
	DB	'it may be possible to use our tricorders to decipher the informa'
	DB	'tion carried in these data banks.',0
T_MUD3_022	LABEL	BYTE
	DB	'#MUD3\MUD3_022#That would be quite a find, Jim. This is an alien'
	DB	' race unknown to us, and they were certain to have knowledge new'
	DB	' to us.',0
T_MUD3_056	LABEL	BYTE
	DB	'#MUD3\MUD3_056#Were the Universal Translator available, this wou'
	DB	'ld be simple.',0
T_MUD3_015	LABEL	BYTE
	DB	'#MUD3\MUD3_015#With the Enterprise out of range, that''s not an o'
	DB	'ption, Mr. Spock.What else can you do?',0
T_MUD3_047	LABEL	BYTE
	DB	'#MUD3\MUD3_047#I believe if Dr. McCoy and I conjoin our two tric'
	DB	'orders, we may be able to process enough sample data to get a ba'
	DB	'sic understanding of the aliens'' computer system. This will comp'
	DB	'letely tie up both our tricorders for an extended amount of time'
	DB	', however.',0
T_MUD3_042	LABEL	BYTE
	DB	'#MUD3\MUD3_042#This platform contains the control console for wh'
	DB	'at appears to be the information center of the ship -- the compu'
	DB	'ter library, if you will. It appears functional, but incomprehen'
	DB	'sible without some better understanding of the aliens who built '
	DB	'it.',0
T_MUD3_041	LABEL	BYTE
	DB	'#MUD3\MUD3_041#This platform contains the control console for th'
	DB	'e ship''s computer library. Data may be accessed by using this co'
	DB	'nsole.',0
T_MUD3_021	LABEL	BYTE
	DB	'#MUD3\MUD3_021#Not my area of expertise, I''m afraid.',0
T_MUD3_018	LABEL	BYTE
	DB	'#MUD3\MUD3_018#Both our tricorders are now working on basic proc'
	DB	'essing of the aliens'' computer data system.  The tricorders are '
	DB	'not the equal of the Universal Translator, but we should be able'
	DB	' to retrieve basic information and get an insight into their cul'
	DB	'ture and lifesystems. I don''t believe we could have gotten even '
	DB	'this far, had we not deduced their fixation on base-6 mathematic'
	DB	's and esthetics.',0
T_MUD3_054	LABEL	BYTE
	DB	'#MUD3\MUD3_054#Not all topics will necessarily be available, Cap'
	DB	'tain. Nor do I believe we can get full details on all data -- th'
	DB	'e tricorders could only do so much processing. It would be worth'
	DB	' our effort to locate the central databanks for delivery to the '
	DB	'Kornephoros Life Sciences University, I believe.',0
T_MUD3_032	LABEL	BYTE
	DB	'#MUD3\MUD3_032#To say nothing of fulfilling our mandate to seek '
	DB	'out new life and new civilizations...',0
T_MUD3_050	LABEL	BYTE
	DB	'#MUD3\MUD3_050#I''m recieving data now, Captain. Most internal an'
	DB	'd external functions are controlled from the bridge. These inclu'
	DB	'de Engineering, Navigation, Communications, and Sensors. Weapons'
	DB	' functions are controlled from the weapons room.',0
T_MUD3_049	LABEL	BYTE
	DB	'#MUD3\MUD3_049#I have found an entry on an experimental long-ran'
	DB	'ge weapon booster, recently installed, named the Whyos weapon. I'
	DB	't does not alter the power of the primary weapons systems, but i'
	DB	't does increase the range at which those weapons are effective.',0
T_MUD3_046	LABEL	BYTE
	DB	'#MUD3\MUD3_046#I believe I can produce a picture of a member of '
	DB	'their race, Captain.',0
T_MUD3_007	LABEL	BYTE
	DB	'#MUD3\MUD3_007#By all means, Spock.',0
T_MUD3_027	LABEL	BYTE
	DB	'#MUD3\MUD3_027#Look at their physiology, Jim -- I think this exp'
	DB	'lains the L''Shaians'' fascination with threes and sixes.',0
T_MUD3_053	LABEL	BYTE
	DB	'#MUD3\MUD3_053#It should be no surprise that physiology affects '
	DB	'mind and behavior. I would say a six-fingered, six-eyed people w'
	DB	'ould naturally develop their sciences and arts around base-six n'
	DB	'umerical systems, just as I observed on the bridge.',0
T_MUD3_028	LABEL	BYTE
	DB	'#MUD3\MUD3_028#Medical knowledge is comprehensive, and lifespan '
	DB	'is extended considerably over archaic expectations, with mainten'
	DB	'ance of quality of life.',0
T_MUD3_026	LABEL	BYTE
	DB	'#MUD3\MUD3_026#Interesting data here about the six-eyed vision p'
	DB	'rocessing in the brain. Their eyesight must have been excellent,'
	DB	' and almost 300 degrees around.',0
T_MUD3_065	LABEL	BYTE
	DB	'#MUD3\MUD3_065#Why, Captain! I see you got this machine to work '
	DB	'-- I tried to get it up and running for the longest time.',0
T_MUD3_010	LABEL	BYTE
	DB	'#MUD3\MUD3_010#Help yourself, Harry. Knowledge is for everyone.',0
T_MUD3_066	LABEL	BYTE
	DB	'#MUD3\MUD3_066#Why, Kirk, I didn''t think you had it in you. Than'
	DB	'k you!',0
T_MUD3_009	LABEL	BYTE
	DB	'#MUD3\MUD3_009#Get away from that this instant, Harry, or I''ll s'
	DB	'hoot you where you stand.',0
T_MUD3_064	LABEL	BYTE
	DB	'#MUD3\MUD3_064#Whatever you say, Captain!',0
T_MUD3_063	LABEL	BYTE
	DB	'#MUD3\MUD3_063#Ooops!',0
T_MUD3_031	LABEL	BYTE
	DB	'#MUD3\MUD3_031#Mudd, do you know what you just did!? That knowle'
	DB	'dge was priceless -- and you''ve just destroyed it forever!!',0
T_MUD3N000	LABEL	BYTE
	DB	'#MUD3\MUD3N000#Databanks erased.',0
T_MUD3_052	LABEL	BYTE
	DB	'#MUD3\MUD3_052#It appears our good friend Harry Mudd has crashed'
	DB	' the main computers. I doubt if it was a very easy thing to mana'
	DB	'ge.',0
T_MUD3_012	LABEL	BYTE
	DB	'#MUD3\MUD3_012#Spock, we''re talking about Harry Mudd. He was pro'
	DB	'bably trying to download it so he could sell it to the highest b'
	DB	'idder.',0
T_MUD3_024	LABEL	BYTE
	DB	'#MUD3\MUD3_024#And instead, he wiped the memory. That knowledge '
	DB	'was priceless!',0
T_MUD3_006	LABEL	BYTE
	DB	'#MUD3\MUD3_006#At least our life support system isn''t dependent '
	DB	'on the alien computer.',0
T_MUD3_048	LABEL	BYTE
	DB	'#MUD3\MUD3_048#I believe, Captain, that the basic functions of t'
	DB	'he ship remain, even now.  This is the library module -- the art'
	DB	', history, and cultural memory of the aliens are gone, but the m'
	DB	'echanical necessities of sick bay, engineering, and sensors cont'
	DB	'inue to work.',0
T_MUD3_008	LABEL	BYTE
	DB	'#MUD3\MUD3_008#But their essence, their souls -- are gone, Spock'
	DB	'.',0
T_MUD3_051	LABEL	BYTE
	DB	'#MUD3\MUD3_051#Illogical, Captain.  This race has been extinct f'
	DB	'or millenia.',0
	DB	'#MUD3\MUD3_036#I believe I''ve extracted a copy of the main datab'
	DB	'ank, Captain.',0
T_MUD3N014	LABEL	BYTE
	DB	'#MUD3\MUD3N014#The computer has nothing to write to the spheroid'
	DB	'.',0
T_MUD3N020	LABEL	BYTE
	DB	'#MUD3\MUD3N020#You download major portions of the alien library '
	DB	'onto the yellow spheroid.',0
T_MUD3N019	LABEL	BYTE
	DB	'#MUD3\MUD3N019#You can''t seem to make this work.',0
T_MUD3N018	LABEL	BYTE
	DB	'#MUD3\MUD3N018#You already have a doover.',0
T_MUD2_002	LABEL	BYTE
	DB	'#MUD2\MUD2_002#Well, now! I think we know why the Elasi pirates '
	DB	'were so interested in finding out where Mudd was getting these!',0
T_MUD3N016	LABEL	BYTE
	DB	'#MUD3\MUD3N016#These two things fit together like they were made'
	DB	' for each other.',0
T_MUD3N001	LABEL	BYTE
	DB	'#MUD3\MUD3N001#Dust and grease lifts off the surface, leaving th'
	DB	'is item clean as new.',0
T_MUD3N005	LABEL	BYTE
	DB	'#MUD3\MUD3N005#Kirk is silently worried about what is happening '
	DB	'back on the Enterprise. ',0
T_MUD3N012	LABEL	BYTE
	DB	'#MUD3\MUD3N012#Sometimes you wonder if Spock will ever show emot'
	DB	'ion. ',0
T_MUD3N010	LABEL	BYTE
	DB	'#MUD3\MUD3N010#McCoy is his usual crusty old self. ',0
T_MUD3N007	LABEL	BYTE
	DB	'#MUD3\MUD3N007#Lieutenant Buchert seems to have limitless energy'
	DB	'. It makes you feel old just watching him. ',0
T_MUD3N004	LABEL	BYTE
	DB	'#MUD3\MUD3N004#Kirk is dismayed by the destruction he has seen. ',0
T_MUD3N002	LABEL	BYTE
	DB	'#MUD3\MUD3N002#Even Spock is visibly disturbed by Mudd''s careles'
	DB	'sness. ',0
T_MUD3N009	LABEL	BYTE
	DB	'#MUD3\MUD3N009#McCoy is aghast at this turn of events. ',0
T_MUD3N006	LABEL	BYTE
	DB	'#MUD3\MUD3N006#Lieutenant Buchert is not at all happy with Harco'
	DB	'urt Fenton Mudd. ',0
T_MUD3N003	LABEL	BYTE
	DB	'#MUD3\MUD3N003#Harry Mudd hopes he can make it back to his ship '
	DB	'and get away in one piece. ',0
T_MUD3_014	LABEL	BYTE
	DB	'#MUD3\MUD3_014#This technology is unbelievable, Mr. Spock. I''ve '
	DB	'never seen anything like it. ',0
T_MUD3_057	LABEL	BYTE
	DB	'#MUD3\MUD3_057#It is indeed impressive Captain. If I were capabl'
	DB	'e of emotion, I would be in awe of this place. ',0
T_MUD3_025	LABEL	BYTE
	DB	'#MUD3\MUD3_025#If you''re incapable of emotion, how do you know w'
	DB	'hat "awe" is, Spock? ',0
T_MUD3_055	LABEL	BYTE
	DB	'#MUD3\MUD3_055#This is a major archeological find, Captain. I be'
	DB	'lieve the galaxy may actually have cause to thank Harry Mudd. ',0
T_MUD3_033	LABEL	BYTE
	DB	'#MUD3\MUD3_033#You can''t be serious, Spock! ',0
T_MUD3_011	LABEL	BYTE
	DB	'#MUD3\MUD3_011#It would be nice to think after all the stunts th'
	DB	'at Harry has pulled that he would do something right for a chang'
	DB	'e. ',0
T_MUD3_023	LABEL	BYTE
	DB	'#MUD3\MUD3_023#This equipment''s way out of my league, Jim. ',0
T_MUD3_070	LABEL	BYTE
	DB	'#MUD3\MUD3_070#Captain, does this mean that I''m a part of a majo'
	DB	'r archeological discovery? ',0
T_MUD3_016	LABEL	BYTE
	DB	'#MUD3\MUD3_016#You better believe it, lieutenant. ',0
T_MUD3_071	LABEL	BYTE
	DB	'#MUD3\MUD3_071#I don''t see why you''re complaining about this Mud'
	DB	'd guy. Who knows what advances we could get from all this knowle'
	DB	'dge? ',0
T_MUD3_002	LABEL	BYTE
	DB	'#MUD3\MUD3_002#Harry! Look what you''ve done! ',0
T_MUD3_019	LABEL	BYTE
	DB	'#MUD3\MUD3_019#Captain, it was not logical to allow Harry Mudd t'
	DB	'o get within one hundred meters of this room. ',0
T_MUD3_030	LABEL	BYTE
	DB	'#MUD3\MUD3_030#Mudd! If I were to perform an autopsy on you righ'
	DB	't now, I might be able to find a cure for stupidity! ',0
T_MUD3_062	LABEL	BYTE
	DB	'#MUD3\MUD3_062#Now, you aren''t... I mean.... Kirk! ',0
T_MUD3_067	LABEL	BYTE
	DB	'#MUD3\MUD3_067#Captain, I think I understand why you dislike thi'
	DB	's Mudd guy so much. ',0
T_MUD3_060	LABEL	BYTE
	DB	'#MUD3\MUD3_060#Kirk, look what you made me do! You and your clum'
	DB	'sy Starfleet... ',0
T_MUD3_029	LABEL	BYTE
	DB	'#MUD3\MUD3_029#Mudd! Don''t you realize what you''ve done! That kn'
	DB	'owledge was irreplaceable! You just burned down the galactic equ'
	DB	'ivalent of the Library of Alexandria! Millions of lives might ha'
	DB	've been saved by the knowledge you destroyed! ',0
T_MUD3_061	LABEL	BYTE
	DB	'#MUD3\MUD3_061#Now see here, Dr. McCoy! Don''t blame me if Kirk''s'
	DB	' bellowing causes me to be a teeny bit clumsy... ',0
T_MUD3_013	LABEL	BYTE
	DB	'#MUD3\MUD3_013#Teeny bit clumsy? Mudd, you''re a disgrace to the '
	DB	'entire human race! ',0
T_MUD3_058	LABEL	BYTE
	DB	'#MUD3\MUD3_058#How dare you, Kirk! I have half a mind to sue for'
	DB	' defamation of character... ',0
S_3343	LABEL	BYTE
	DB	'(Raises eyebrow) ',0
T_MUD3_069	LABEL	BYTE
	DB	'#MUD3\MUD3_069#Captain, I think Mr. Mudd looks like he''s getting'
	DB	' out of control... ',0
T_MUD3_059	LABEL	BYTE
	DB	'#MUD3\MUD3_059#Kirk! Get this muscle-bound clod away from me. I'''
	DB	'm allergic to violence! ',0
T_MUD3_005	LABEL	BYTE
	DB	'#MUD3\MUD3_005#At ease, lieutenant. He''s not worth it. ',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0
KirkToMudd	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_MUD3_010, OFFSET T_MUD3_009, 0	; speaker, choices, 0

RDF	ENDS
	END
