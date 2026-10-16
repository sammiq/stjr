; TRIAL2.RDF - "The Feathered Serpent", the Test of Life, second chamber.
; A sphere of energy, an automaton with a force field, blocks the way. It
; absorbs phaser fire: at a charge of exactly 3 it splits in two, at 4 it
; overloads and explodes, so the spheres must be charged past 3 with
; the right mix of stun and kill shots.
;
; Actors: 8-11 (0Bh) the spheres.
; Objects: 8-0Ah the spheres, 20h the insignia, 21h the wall, 22h the
; way back. Exits: 2 room 1, 3 room 3. Region 0: the sphere's field.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The conversation at 00CA is built at run time.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
score	EQU	RS_VARS+0	; word: the mission's score
split	EQU	RS_VARS+0Ch	; the first sphere has split in two
spheres_gone	EQU	RS_VARS+0Dh	; the spheres have destroyed themselves
sphere1	EQU	RS_VARS+0Eh	; charge of the first sphere: 3 it splits, 4 it explodes
sphere2	EQU	RS_VARS+0Fh	; charge of the second
sphere3	EQU	RS_VARS+10h	; charge of the third
seen_sphere	EQU	RS_VARS+33h
can_leave	EQU	RS_VARS+34h	; room 3 is done: Uhura offers to beam the party up
ending	EQU	RS_VARS+36h	; word: how it ended, for room 9: 0 Kirk let the trial run, 1 he beamed back mid-trial, 2 Quetzecoatl was lost, 3 the Klingons leave, 4 Vlict was executed
scanned_sphere	EQU	RS_VARS+3Bh	; the point for scanning it

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
	DW	-1, -1, 1, 3	; room for each exit
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
	DW	270,181, 225,191	; entrance 2, crew 0
	DW	254,183, 235,181	; entrance 2, crew 1
	DW	259,188, 235,199	; entrance 2, crew 2
	DW	272,186, 245,191	; entrance 2, crew 3
	DW	34,163, 44,163	; entrance 3, crew 0
	DW	52,167, 62,167	; entrance 3, crew 1
	DW	57,179, 67,179	; entrance 3, crew 2
	DW	27,173, 37,173	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	225,191, 235,181, 235,199, 245,191	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	225,191, 235,181, 235,199, 245,191
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
N_Ensign_Bennie	LABEL	BYTE
	DB	'Ensign Bennie',0
N_Lt_Uhura	LABEL	BYTE
	DB	'Lt. Uhura',0
rdf_objects	LABEL	BYTE
	DW	20h, 4	; id, points
	DW	0,0, 1,0, 1,1, 0,1
	DW	21h, 4	; id, points
	DW	0,0, 1,0, 1,1, 0,1
	DW	22h, 6	; id, points
	DW	263,179, 256,138, 267,111, 282,110, 301,153, 282,189
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	2, 4	; id, points
	DW	243,178, 273,176, 300,192, 262,194
	DW	3, 4	; id, points
	DW	0,150, 20,153, 16,181, 0,172
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	0,0, 1,0, 1,1, 0,1

rdf_scripts:
rdf_regions_end:
rdf_bans:
rdf_bans_end:
; The room starts: the sphere, or the two after the split, or none.
H_01CA:
	SCRIPT	MSG_TICK, 1, 0, 0, H_02E0
StartRoom:
	jmp	SHORT L01DB

N_NOOOLOOP	LABEL	BYTE
	DB	'NOOOLOOP',0
L01DB:
	push	OFFSET N_NOOOLOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("NOOOLOOP")
	add	sp, 4
	cmp	byte ptr [si+seen_sphere], 0
	jne	L01F4
	mov	byte ptr [si+RS_BUSY], 2
L01F4:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+spheres_gone], 1
	jne	L0200
	retf

L0200:
	mov	ax, -1
	push	ax
	mov	ax, 18h
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(24, -1)
	add	sp, 6
	jmp	SHORT L021E

N_trial22	LABEL	BYTE
	DB	'trial22',0
L021E:
	push	OFFSET N_trial22
	push	RC_LOADMAP
	SERVICE		; LoadMap("trial22")
	add	sp, 4
	cmp	byte ptr [si+split], 0
	jne	L0274
	jmp	SHORT L023C

N_TRI2LOOP	LABEL	BYTE
	DB	'TRI2LOOP',0
L023C:
	push	OFFSET N_TRI2LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("TRI2LOOP")
	add	sp, 4
	jmp	SHORT L0253

N_sglob	LABEL	BYTE
	DB	'sglob',0
L0253:
	push	0
	push	0AFh
	push	46h
	push	OFFSET N_sglob
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "sglob", 70, 175, 0)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+sphere1], 1
	jmp	SHORT L0274

L0274:
	cmp	byte ptr [si+split], 1
	jne	L02DF
	jmp	SHORT L0285

N_TRI2LOOP_2	LABEL	BYTE
	DB	'TRI2LOOP',0
L0285:
	push	OFFSET N_TRI2LOOP_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("TRI2LOOP")
	add	sp, 4
	jmp	SHORT L029C

N_sglob_2	LABEL	BYTE
	DB	'sglob',0
L029C:
	push	0
	push	0AFh
	push	20h
	push	OFFSET N_sglob_2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "sglob", 32, 175, 0)
	add	sp, 0Ch
	jmp	SHORT L02BA

N_sglob_3	LABEL	BYTE
	DB	'sglob',0
L02BA:
	push	0
	push	0AFh
	push	69h
	push	OFFSET N_sglob_3
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "sglob", 105, 175, 0)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+sphere2], 1
	mov	byte ptr [si+sphere3], 1
	jmp	SHORT L02DF

L02DF:
	retf

; Tick 60, the first time: the crew on the sphere.
H_02E0:
	SCRIPT	MSG_TICK, 3Ch, 0, 0, H_043F
FirstSight:
	cmp	byte ptr [si+seen_sphere], 0
	jne	L02F0
	mov	byte ptr [si+RS_BUSY], 0
L02F0:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+seen_sphere], 0
	je	L02FE
	JMPN	L043E

L02FE:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI2_034
	call	Say
	jmp	SHORT L0335

T_TRI2_034	LABEL	BYTE
	DB	'#TRI2\TRI2_034#Captain, what is that thing?',0
L0335:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI2_005
	call	Say
	jmp	SHORT L0365

T_TRI2_005	LABEL	BYTE
	DB	'#TRI2\TRI2_005#I don''t know, Ensign.',0
L0365:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI2_030
	call	Say
	jmp	SHORT L03E7

T_TRI2_030	LABEL	BYTE
	DB	'#TRI2\TRI2_030#I believe Ensign, that this energy sphere is some'
	DB	' sort of automaton, programmed to block our movements.',0
L03E7:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI2_008
	call	Say
	jmp	SHORT L0435

T_TRI2_008	LABEL	BYTE
	DB	'#TRI2\TRI2_008#Whatever it is, we have to find a way to get by i'
	DB	't.',0
L0435:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+seen_sphere], 1
L043E:
	retf

; Region 0: the sphere's force field stops the party.
H_043F:
	SCRIPT	MSG_REGION, 0, 0, 0, H_04EC
Blocked:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+sphere2], 0
	jne	L0457
	cmp	byte ptr [si+sphere3], 0
	jne	L0457
	retf

L0457:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI2_024
	call	Say
	JMPN	L04EB

T_TRI2_024	LABEL	BYTE
	DB	'#TRI2\TRI2_024#The automaton is emitting a protective force fiel'
	DB	'd, Captain. We cannot proceed further without rendering it inope'
	DB	'rative.',0
L04EB:
	retf

H_04EC:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_054C
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_TRI2N003
	call	Say
	jmp	SHORT L054B

T_TRI2N003	LABEL	BYTE
	DB	'#TRI2\TRI2N003#James T. Kirk, a rather frustated Federation star'
	DB	'ship captain.',0
L054B:
	retf

H_054C:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_05B1
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_TRI2N001
	call	Say
	jmp	SHORT L05B0

T_TRI2N001	LABEL	BYTE
	DB	'#TRI2\TRI2N001#Commander Spock, a patient and thoughtful Federat'
	DB	'ion first officer.',0
L05B0:
	retf

H_05B1:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_061A
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_TRI2N006
	call	Say
	jmp	SHORT L0619

T_TRI2N006	LABEL	BYTE
	DB	'#TRI2\TRI2N006#Leonard McCoy, a crusty country doctor, and Starf'
	DB	'leet''s finest surgeon.',0
L0619:
	retf

H_061A:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_066E
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_TRI2N002
	call	Say
	jmp	SHORT L066D

T_TRI2N002	LABEL	BYTE
	DB	'#TRI2\TRI2N002#Ensign Bennie, faithful and true security officer'
	DB	'.',0
L066D:
	retf

; Looking and talking.
H_066E:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_06A1
LookAtInsignia:
	mov	ax, 0
	mov	bx, OFFSET T_TRI2N004
	call	Say
	jmp	SHORT L06A0

T_TRI2N004	LABEL	BYTE
	DB	'#TRI2\TRI2N004#Klingon insignia.',0
L06A0:
	retf

H_06A1:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_06A9
	jmp	SHORT LookAtSphere

H_06A9:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_06B1
	jmp	SHORT LookAtSphere

H_06B1:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_06ED
LookAtSphere:
	mov	ax, 0
	mov	bx, OFFSET T_TRI2N000
	call	Say
	jmp	SHORT L06EC

T_TRI2N000	LABEL	BYTE
	DB	'#TRI2\TRI2N000#A pulsing globe of energy.',0
L06EC:
	retf

H_06ED:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_0760
LookAtWall:
	mov	ax, 0
	mov	bx, OFFSET T_TRI2N007
	call	Say
	jmp	SHORT L075F

T_TRI2N007	LABEL	BYTE
	DB	'#TRI2\TRI2N007#Rock wall. Looks like it was carved from stone by'
	DB	' Klingon heavy mining equipment.',0
L075F:
	retf

H_0760:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_07BB
LookAtWayBack:
	mov	ax, 0
	mov	bx, OFFSET T_TRI2N005
	call	Say
	jmp	SHORT L07BA

T_TRI2N005	LABEL	BYTE
	DB	'#TRI2\TRI2N005#Leads back to the room where the Electrical creat'
	DB	'ure was.',0
L07BA:
	retf

H_07BB:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_0835
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI2_001
	call	Say
	jmp	SHORT L0834

T_TRI2_001	LABEL	BYTE
	DB	'#TRI2\TRI2_001#This reminds me of an old practical joke that Fin'
	DB	'negan played on me back at the Academy.',0
L0834:
	retf

H_0835:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_08BB
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI2_019
	call	Say
	jmp	SHORT L08BA

T_TRI2_019	LABEL	BYTE
	DB	'#TRI2\TRI2_019#Fascinating. It would appear that Vlict sent us i'
	DB	'nto this place in the hope that we would be killed.',0
L08BA:
	retf

H_08BB:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0942
TalkToMcCoy:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI2_013
	call	Say
	jmp	SHORT L0941

T_TRI2_013	LABEL	BYTE
	DB	'#TRI2\TRI2_013#If you hadn''t been so damned anxious to give my p'
	DB	'atient to the Klingons, we wouldn''t be in this mess.',0
L0941:
	retf

H_0942:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_099D
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI2_033
	call	Say
	jmp	SHORT L099C

T_TRI2_033	LABEL	BYTE
	DB	'#TRI2\TRI2_033#We''re not going to get out of this alive, are we '
	DB	'Captain?',0
L099C:
	retf

H_099D:
	SCRIPT	MSG_TALK, 8, 0, 0, H_09CB
TalkToSphere1:
	mov	ax, 0
	mov	bx, OFFSET T_QUIET
	call	Say
	jmp	SHORT L09CA

T_QUIET	LABEL	BYTE
	DB	'#SFX\QUIET#Zzzzzzzzzzzmmmm.',0
L09CA:
	retf

H_09CB:
	SCRIPT	MSG_TALK, 9, 0, 0, H_09F9
TalkToSphere2:
	mov	ax, 0
	mov	bx, OFFSET T_QUIET_2
	call	Say
	jmp	SHORT L09F8

T_QUIET_2	LABEL	BYTE
	DB	'#SFX\QUIET#Zzzzzzzzzzzmmmm.',0
L09F8:
	retf

H_09F9:
	SCRIPT	MSG_TALK, 0Ah, 0, 0, H_0A27
TalkToSphere3:
	mov	ax, 0
	mov	bx, OFFSET T_QUIET_3
	call	Say
	jmp	SHORT L0A26

T_QUIET_3	LABEL	BYTE
	DB	'#SFX\QUIET#Zzzzzzzzzzzmmmm.',0
L0A26:
	retf

; Phasers on the spheres (msgs 7-18): stun charges one by 1, kill by 2.
; At exactly 3 it splits, at 4 it overloads and explodes.
H_0A27:
	SCRIPT	MSG_USE, IT_PHASERS, 21h, 0, H_0A2F
	jmp	SHORT PhaserWall

H_0A2F:
	SCRIPT	MSG_USE, IT_PHASERK, 21h, 0, H_0A78
PhaserWall:
	mov	ax, 0
	mov	bx, OFFSET T_TRI2N008
	call	Say
	jmp	SHORT L0A77

T_TRI2N008	LABEL	BYTE
	DB	'#TRI2\TRI2N008#The walls are resistant to phaser fire.',0
L0A77:
	retf

H_0A78:
	SCRIPT	MSG_USE, IT_PHASERS, 8, 0, H_0A9F
StunSphere1:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 7
	push	ax
	mov	ax, 0C5h
	push	ax
	mov	ax, 0CDh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 205, 197, 7)
	add	sp, 0Ah
	retf

H_0A9F:
	SCRIPT	MSG_WALK_DONE, 7, 0, 0, H_0AC4
KirkFires1:
	jmp	SHORT L0AAE

N_kdraww	LABEL	BYTE
	DB	'kdraww',0
L0AAE:
	push	0Ah
	push	-1
	push	-1
	push	OFFSET N_kdraww
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kdraww", -1, -1, 10)
	add	sp, 0Ch
	retf

H_0AC4:
	SCRIPT	MSG_ANIM_DONE, 0Ah, 0, 0, H_0BA9
Sphere1Charged:
	mov	byte ptr [si+RS_FALL], 3
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0AE7

N_t2kp00	LABEL	BYTE
	DB	't2kp00',0
L0AE7:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2kp00
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2kp00", 5)
	add	sp, 6
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 0
	add	byte ptr [si+sphere1], 1
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI2_025
	call	Say
	JMPN	L0BA6

T_TRI2_025	LABEL	BYTE
	DB	'#TRI2\TRI2_025#The automaton''s energy level has increased slight'
	DB	'ly. It absorbed the phaser fire. No appreciable increase in mass'
	DB	'.',0
L0BA6:
	JMPN	L0C4B

H_0BA9:
	SCRIPT	MSG_USE, IT_PHASERK, 8, 0, H_0BD0
KillSphere1:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0Dh
	push	ax
	mov	ax, 0C5h
	push	ax
	mov	ax, 0CDh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 205, 197, 13)
	add	sp, 0Ah
	retf

H_0BD0:
	SCRIPT	MSG_WALK_DONE, 0Dh, 0, 0, H_0BF5
KirkFires1Kill:
	jmp	SHORT L0BDF

N_kdraww_2	LABEL	BYTE
	DB	'kdraww',0
L0BDF:
	push	10h
	push	-1
	push	-1
	push	OFFSET N_kdraww_2
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kdraww", -1, -1, 16)
	add	sp, 0Ch
	retf

H_0BF5:
	SCRIPT	MSG_ANIM_DONE, 10h, 0, 0, H_0CE5
Sphere1Overcharged:
	mov	byte ptr [si+RS_FALL], 3
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0C18

N_t2kp03	LABEL	BYTE
	DB	't2kp03',0
L0C18:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2kp03
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2kp03", 5)
	add	sp, 6
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 0
	add	byte ptr [si+sphere1], 2
	jmp	SHORT L0C4B

L0C4B:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+sphere1], 3
	jne	L0C90
	jmp	SHORT L0C61

N_GLOBEDIV	LABEL	BYTE
	DB	'GLOBEDIV',0
L0C61:
	push	OFFSET N_GLOBEDIV
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("GLOBEDIV")
	add	sp, 4
	jmp	SHORT L0C79

N_globsp	LABEL	BYTE
	DB	'globsp',0
L0C79:
	push	1
	push	0AFh
	push	46h
	push	OFFSET N_globsp
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "globsp", 70, 175, 1)
	add	sp, 0Ch
	retf

L0C90:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+sphere1], 4
	jl	L0CE4
	mov	ax, 14h
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(20)
	add	sp, 4
	jmp	SHORT L0CB5

N_REDBALL	LABEL	BYTE
	DB	'REDBALL',0
L0CB5:
	push	OFFSET N_REDBALL
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("REDBALL")
	add	sp, 4
	jmp	SHORT L0CCD

N_globex	LABEL	BYTE
	DB	'globex',0
L0CCD:
	push	4
	push	0AFh
	push	46h
	push	OFFSET N_globex
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "globex", 70, 175, 4)
	add	sp, 0Ch
	retf

L0CE4:
	retf

H_0CE5:
	SCRIPT	MSG_USE, IT_PHASERS, 9, 0, H_0D0C
StunSphere2:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 8
	push	ax
	mov	ax, 0C5h
	push	ax
	mov	ax, 0CDh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 205, 197, 8)
	add	sp, 0Ah
	retf

H_0D0C:
	SCRIPT	MSG_WALK_DONE, 8, 0, 0, H_0D31
KirkFires2:
	jmp	SHORT L0D1B

N_kdraww_3	LABEL	BYTE
	DB	'kdraww',0
L0D1B:
	push	0Bh
	push	-1
	push	-1
	push	OFFSET N_kdraww_3
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kdraww", -1, -1, 11)
	add	sp, 0Ch
	retf

H_0D31:
	SCRIPT	MSG_ANIM_DONE, 0Bh, 0, 0, H_0E16
Sphere2Charged:
	mov	byte ptr [si+RS_FALL], 3
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0D54

N_t2kp01	LABEL	BYTE
	DB	't2kp01',0
L0D54:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2kp01
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2kp01", 5)
	add	sp, 6
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 0
	add	byte ptr [si+sphere2], 1
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI2_025_2
	call	Say
	JMPN	L0E13

T_TRI2_025_2	LABEL	BYTE
	DB	'#TRI2\TRI2_025#The automaton''s energy level has increased slight'
	DB	'ly. It absorbed the phaser fire. No appreciable increase in mass'
	DB	'.',0
L0E13:
	JMPN	L0C4B

H_0E16:
	SCRIPT	MSG_USE, IT_PHASERK, 9, 0, H_0E3D
KillSphere2:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0Eh
	push	ax
	mov	ax, 0C5h
	push	ax
	mov	ax, 0CDh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 205, 197, 14)
	add	sp, 0Ah
	retf

H_0E3D:
	SCRIPT	MSG_WALK_DONE, 0Eh, 0, 0, H_0E62
KirkFires2Kill:
	jmp	SHORT L0E4C

N_kdraww_4	LABEL	BYTE
	DB	'kdraww',0
L0E4C:
	push	11h
	push	-1
	push	-1
	push	OFFSET N_kdraww_4
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kdraww", -1, -1, 17)
	add	sp, 0Ch
	retf

H_0E62:
	SCRIPT	MSG_ANIM_DONE, 11h, 0, 0, H_0FA1
Sphere2Overcharged:
	mov	byte ptr [si+RS_FALL], 3
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0E85

N_t2kp04	LABEL	BYTE
	DB	't2kp04',0
L0E85:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2kp04
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2kp04", 5)
	add	sp, 6
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 0
	add	byte ptr [si+sphere2], 2
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI2_023
	call	Say
	jmp	SHORT L0F38

T_TRI2_023	LABEL	BYTE
	DB	'#TRI2\TRI2_023#Marked increase in energy level, Captain. It abso'
	DB	'rbed the phaser fire. No appreciable increase in mass.',0
L0F38:
	jmp	SHORT L0F3A

L0F3A:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+sphere2], 3
	jne	L0F65
	jmp	SHORT L0F4E

N_globsp_2	LABEL	BYTE
	DB	'globsp',0
L0F4E:
	push	2
	push	0AFh
	push	20h
	push	OFFSET N_globsp_2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "globsp", 32, 175, 2)
	add	sp, 0Ch
	retf

L0F65:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+sphere2], 4
	jl	L0FA0
	mov	ax, 14h
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(20)
	add	sp, 4
	jmp	SHORT L0F89

N_globex_2	LABEL	BYTE
	DB	'globex',0
L0F89:
	push	5
	push	0AFh
	push	20h
	push	OFFSET N_globex_2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "globex", 32, 175, 5)
	add	sp, 0Ch
	retf

L0FA0:
	retf

H_0FA1:
	SCRIPT	MSG_USE, IT_PHASERS, 0Ah, 0, H_0FC8
StunSphere3:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 9
	push	ax
	mov	ax, 0C5h
	push	ax
	mov	ax, 0CDh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 205, 197, 9)
	add	sp, 0Ah
	retf

H_0FC8:
	SCRIPT	MSG_WALK_DONE, 9, 0, 0, H_0FED
KirkFires3:
	jmp	SHORT L0FD7

N_kdraww_5	LABEL	BYTE
	DB	'kdraww',0
L0FD7:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_kdraww_5
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kdraww", -1, -1, 12)
	add	sp, 0Ch
	retf

H_0FED:
	SCRIPT	MSG_ANIM_DONE, 0Ch, 0, 0, H_10D2
Sphere3Charged:
	mov	byte ptr [si+RS_FALL], 3
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L1010

N_t2kp02	LABEL	BYTE
	DB	't2kp02',0
L1010:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2kp02
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2kp02", 5)
	add	sp, 6
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 0
	add	byte ptr [si+sphere3], 1
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI2_025_3
	call	Say
	JMPN	L10CF

T_TRI2_025_3	LABEL	BYTE
	DB	'#TRI2\TRI2_025#The automaton''s energy level has increased slight'
	DB	'ly. It absorbed the phaser fire. No appreciable increase in mass'
	DB	'.',0
L10CF:
	JMPN	L11FA

H_10D2:
	SCRIPT	MSG_USE, IT_PHASERK, 0Ah, 0, H_10F9
KillSphere3:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 0Fh
	push	ax
	mov	ax, 0C5h
	push	ax
	mov	ax, 0CDh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 205, 197, 15)
	add	sp, 0Ah
	retf

H_10F9:
	SCRIPT	MSG_WALK_DONE, 0Fh, 0, 0, H_111E
KirkFires3Kill:
	jmp	SHORT L1108

N_kdraww_6	LABEL	BYTE
	DB	'kdraww',0
L1108:
	push	12h
	push	-1
	push	-1
	push	OFFSET N_kdraww_6
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kdraww", -1, -1, 18)
	add	sp, 0Ch
	retf

H_111E:
	SCRIPT	MSG_ANIM_DONE, 12h, 0, 0, H_1261
Sphere3Overcharged:
	mov	byte ptr [si+RS_FALL], 3
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L1141

N_t2kp05	LABEL	BYTE
	DB	't2kp05',0
L1141:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2kp05
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2kp05", 5)
	add	sp, 6
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
	mov	byte ptr [si+RS_BUSY], 0
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 0
	add	byte ptr [si+sphere3], 2
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI2_023_2
	call	Say
	jmp	SHORT L11F8

T_TRI2_023_2	LABEL	BYTE
	DB	'#TRI2\TRI2_023#Marked increase in energy level, Captain. It abso'
	DB	'rbed the phaser fire. No appreciable increase in mass.',0
L11F8:
	jmp	SHORT L11FA

L11FA:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+sphere3], 3
	jne	L1225
	jmp	SHORT L120E

N_globsp_3	LABEL	BYTE
	DB	'globsp',0
L120E:
	push	3
	push	0AFh
	push	69h
	push	OFFSET N_globsp_3
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "globsp", 105, 175, 3)
	add	sp, 0Ch
	retf

L1225:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+sphere3], 4
	jl	L1260
	mov	ax, 14h
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(20)
	add	sp, 4
	jmp	SHORT L1249

N_globex_3	LABEL	BYTE
	DB	'globex',0
L1249:
	push	6
	push	0AFh
	push	69h
	push	OFFSET N_globex_3
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "globex", 105, 175, 6)
	add	sp, 0Ch
	retf

L1260:
	retf

; A sphere has overloaded (anim msgs 4-6): its explosion clears the way,
; +1.
H_1261:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_1269
Sphere1Explodes:
	jmp	SHORT L1279

H_1269:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_1271
Sphere2Explodes:
	jmp	SHORT L1279

H_1271:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_131F
SpheresGone:
	jmp	SHORT L1279

L1279:
	mov	ax, RC_DIGIOFF
	push	ax
	SERVICE		; DigiOff()
	add	sp, 2
	jmp	SHORT L1290

N_Noooloop_2	LABEL	BYTE
	DB	'Noooloop',0
L1290:
	push	OFFSET N_Noooloop_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("Noooloop")
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI2_020
	call	Say
	jmp	SHORT L12E7

T_TRI2_020	LABEL	BYTE
	DB	'#TRI2\TRI2_020#Fascinating. These automatons are not stable.',0
L12E7:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+spheres_gone], 1
	mov	ax, -1
	push	ax
	mov	ax, 1Ch
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(28, -1)
	add	sp, 6
	add	word ptr [si+score], 1
	jmp	SHORT L1311

N_trial2	LABEL	BYTE
	DB	'trial2',0
L1311:
	push	OFFSET N_trial2
	push	RC_LOADMAP
	SERVICE		; LoadMap("trial2")
	add	sp, 4
	retf

; The first sphere splits in two (anim msg 1); a second split (anim msgs 2,
; 3) multiplies them until they kill the party (anim msg 19).
H_131F:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_1488
Sphere1Splits:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI2_009
	call	Say
	JMPN	L13E0

T_TRI2_009	LABEL	BYTE
	DB	'#TRI2\TRI2_009#Extreme increase in energy level, Captain. It abs'
	DB	'orbed the phaser fire. An unexpected reaction is occuring, high '
	DB	'levels of lethal radiation are being produced.',0
L13E0:
	JMPN	L1511

				; NOTE: unreachable (code=13E3 in config/rdf.txt)
L13E3:
	mov	byte ptr [si+sphere1], 0
	mov	byte ptr [si+sphere2], 1
	mov	byte ptr [si+sphere3], 1
	mov	byte ptr [si+split], 1
	jmp	SHORT L13FB

N_sglob_4	LABEL	BYTE
	DB	'sglob',0
L13FB:
	push	0
	push	0AFh
	push	20h
	push	OFFSET N_sglob_4
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "sglob", 32, 175, 0)
	add	sp, 0Ch
	jmp	SHORT L1419

N_sglob_5	LABEL	BYTE
	DB	'sglob',0
L1419:
	push	0
	push	0AFh
	push	69h
	push	OFFSET N_sglob_5
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "sglob", 105, 175, 0)
	add	sp, 0Ch
	mov	ax, 8
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(8)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI2_021
	call	Say
	jmp	SHORT L1487

T_TRI2_021	LABEL	BYTE
	DB	'#TRI2\TRI2_021#Fascinating. These automatons are not stable.',0
L1487:
	retf

H_1488:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_14CC
Sphere2Splits:
	jmp	SHORT L1496

N_sglob_6	LABEL	BYTE
	DB	'sglob',0
L1496:
	push	0
	push	0AFh
	push	43h
	push	OFFSET N_sglob_6
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "sglob", 67, 175, 0)
	add	sp, 0Ch
	jmp	SHORT L14B4

N_sglob_7	LABEL	BYTE
	DB	'sglob',0
L14B4:
	push	0
	push	0AFh
	push	0
	push	OFFSET N_sglob_7
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "sglob", 0, 175, 0)
	add	sp, 0Ch
	jmp	SHORT L1511

H_14CC:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_15C1
Sphere3Splits:
	jmp	SHORT L14DA

N_sglob_8	LABEL	BYTE
	DB	'sglob',0
L14DA:
	push	0
	push	0AFh
	push	8Ch
	push	OFFSET N_sglob_8
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "sglob", 140, 175, 0)
	add	sp, 0Ch
	jmp	SHORT L14F9

N_sglob_9	LABEL	BYTE
	DB	'sglob',0
L14F9:
	push	0
	push	0AFh
	push	46h
	push	OFFSET N_sglob_9
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "sglob", 70, 175, 0)
	add	sp, 0Ch
	jmp	SHORT L1511

L1511:
	jmp	SHORT L151C

N_V7ALLGET	LABEL	BYTE
	DB	'V7ALLGET',0
L151C:
	push	OFFSET N_V7ALLGET
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("V7ALLGET")
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, -1
	push	ax
	mov	ax, 1Ah
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(26, -1)
	add	sp, 6
	jmp	SHORT L1551

N_kkills	LABEL	BYTE
	DB	'kkills',0
L1551:
	push	13h
	push	-1
	push	-1
	push	OFFSET N_kkills
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kkills", -1, -1, 19)
	add	sp, 0Ch
	jmp	SHORT L156F

N_skills	LABEL	BYTE
	DB	'skills',0
L156F:
	push	0
	push	-1
	push	-1
	push	OFFSET N_skills
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "skills", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L158D

N_mkills	LABEL	BYTE
	DB	'mkills',0
L158D:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mkills
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mkills", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L15AB

N_rkills	LABEL	BYTE
	DB	'rkills',0
L15AB:
	push	0
	push	-1
	push	-1
	push	OFFSET N_rkills
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rkills", -1, -1, 0)
	add	sp, 0Ch
	retf

H_15C1:
	SCRIPT	MSG_ANIM_DONE, 13h, 0, 0, H_15F7
PartyKilled:
	mov	byte ptr [si+RS_BUSY], 0
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	mov	ax, 0
	mov	bx, OFFSET S_15E0
	call	Say
	jmp	SHORT L15F5

S_15E0	LABEL	BYTE
	DB	'***Game over man!***',0
L15F5:
	retf

	DB	0CBh

; Tricorders (+1 for the sphere, once).
H_15F7:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_KIRK, 0, H_166F
McCoyScansKirk:
	mov	byte ptr [si+RS_FALL+2], 1
	jmp	SHORT L160A

N_mscans	LABEL	BYTE
	DB	'mscans',0
L160A:
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
	mov	bx, OFFSET T_TRI2_016
	call	Say
	jmp	SHORT L166E

T_TRI2_016	LABEL	BYTE
	DB	'#TRI2\TRI2_016#Male Human, good physical condition.',0
L166E:
	retf

H_166F:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_SPOCK, 0, H_16FA
McCoyScansSpock:
	mov	byte ptr [si+RS_FALL+2], 1
	jmp	SHORT L1682

N_mscans_2	LABEL	BYTE
	DB	'mscans',0
L1682:
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
	mov	bx, OFFSET T_TRI2_017
	call	Say
	jmp	SHORT L16F9

T_TRI2_017	LABEL	BYTE
	DB	'#TRI2\TRI2_017#Male Human-Vulcan hybrid. Excellent physical cond'
	DB	'ition.',0
L16F9:
	retf

H_16FA:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_MCCOY, 0, H_1779
McCoyScansMcCoy:
	mov	byte ptr [si+RS_FALL+2], 1
	jmp	SHORT L170D

N_mscans_3	LABEL	BYTE
	DB	'mscans',0
L170D:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscans_3
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
	mov	bx, OFFSET T_TRI2_014
	call	Say
	jmp	SHORT L1778

T_TRI2_014	LABEL	BYTE
	DB	'#TRI2\TRI2_014#One Male Human, average physical condition.',0
L1778:
	retf

H_1779:
	SCRIPT	MSG_USE, IT_MTRICOR, OBJ_REDSHIRT, 0, H_17F6
McCoyScansBennie:
	mov	byte ptr [si+RS_FALL+2], 1
	jmp	SHORT L178C

N_mscans_4	LABEL	BYTE
	DB	'mscans',0
L178C:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscans_4
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
	mov	bx, OFFSET T_TRI2_015
	call	Say
	jmp	SHORT L17F5

T_TRI2_015	LABEL	BYTE
	DB	'#TRI2\TRI2_015#Male Human, excellent physical condition.',0
L17F5:
	retf

H_17F6:
	SCRIPT	MSG_USE, IT_MTRICOR, 8, 0, H_17FE
	jmp	SHORT McCoyScansSphere

H_17FE:
	SCRIPT	MSG_USE, IT_MTRICOR, 9, 0, H_1806
	jmp	SHORT McCoyScansSphere

H_1806:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Ah, 0, H_188C
McCoyScansSphere:
	mov	byte ptr [si+RS_FALL+2], 1
	jmp	SHORT L1819

N_mscans_5	LABEL	BYTE
	DB	'mscans',0
L1819:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscans_5
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
	mov	bx, OFFSET T_TRI2_011
	call	Say
	jmp	SHORT L187D

T_TRI2_011	LABEL	BYTE
	DB	'#TRI2\TRI2_011#It does not register as a life form.',0
L187D:
	cmp	byte ptr [si+scanned_sphere], 0
	jne	L188B
	mov	byte ptr [si+scanned_sphere], 1
	add	word ptr [si+score], 1
L188B:
	retf

H_188C:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_1917
SpockScansWall:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L189F

N_sscans	LABEL	BYTE
	DB	'sscans',0
L189F:
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
	mov	bx, OFFSET T_TRI2_029
	call	Say
	jmp	SHORT L1916

T_TRI2_029	LABEL	BYTE
	DB	'#TRI2\TRI2_029#This wall was carved from the natural rock of a c'
	DB	'avern.',0
L1916:
	retf

H_1917:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_19A7
SpockScans:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L192A

N_sscans_2	LABEL	BYTE
	DB	'sscans',0
L192A:
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
	mov	bx, OFFSET T_TRI2_027
	call	Say
	jmp	SHORT L19A6

T_TRI2_027	LABEL	BYTE
	DB	'#TRI2\TRI2_027#These walls were carved from the natural rock of '
	DB	'the cavern.',0
L19A6:
	retf

H_19A7:
	SCRIPT	MSG_USE, IT_STRICOR, 8, 0, H_19AF
	jmp	SHORT SpockScansSphere

H_19AF:
	SCRIPT	MSG_USE, IT_STRICOR, 9, 0, H_19B7
	jmp	SHORT SpockScansSphere

H_19B7:
	SCRIPT	MSG_USE, IT_STRICOR, 0Ah, 0, H_1B16
SpockScansSphere:
	mov	byte ptr [si+RS_FALL+1], 1
	jmp	SHORT L19CA

N_sscans_3	LABEL	BYTE
	DB	'sscans',0
L19CA:
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
	mov	bx, OFFSET T_TRI2_026
	call	Say
	JMPN	L1AA9

T_TRI2_026	LABEL	BYTE
	DB	'#TRI2\TRI2_026#The ball of energy is an automaton, Captain. It i'
	DB	's an artificial construct, programmed to block any movements; I '
	DB	'can detect no other function or intelligence.',0
L1AA9:
	cmp	byte ptr [si+scanned_sphere], 0
	jne	L1AB7
	mov	byte ptr [si+scanned_sphere], 1
	add	word ptr [si+score], 1
L1AB7:
	retf

L1AB8:
	mov	si, word ptr cs:rdf_state
	mov	si, word ptr cs:rdf_state
	mov	word ptr [si+ending], 1
	push	1
	push	1
	mov	ax, word ptr [si+score]
	push	ax
	push	RC_BEAMUP
	SERVICE		; BeamUp(?, 1, 1)
	add	sp, 8
	retf

	DB	2Eh, 8Bh, 36h, 4, 0, 0B8h, 40h, 1, 0BBh, 0EAh, 1Ah, 0E8h
	DB	14h, 0E6h, 0EBh, 12h
	DB	'Affirmative, sir.',0
L1AFC:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+RS_BUSY], 1
	push	4
	push	4
	push	RC_GOTOROOM
	SERVICE		; GotoRoom(4, 4)
L1B10:
	mov	si, word ptr cs:rdf_state
	retf

; The communicator: Uhura can't get through yet (or, room 3 done, beams up).
H_1B16:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_1EBD
CallUhura:
	cmp	byte ptr [si+can_leave], 1
	je	L1B25
	JMPN	L1C3A

L1B25:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI2U091
	call	Say
	jmp	SHORT L1B68

T_TRI2U091	LABEL	BYTE
	DB	'#TRI2\TRI2U091#Do you wish to be beamed up now Captain?',0
L1B68:
	mov	word ptr cs:talk_buf, OFFSET N_Capt_Kirk
	jmp	SHORT L1BAA

T_TRI2_003	LABEL	BYTE
	DB	'#TRI2\TRI2_003#Beam us back to the Enterprise. Kirk out.',0
L1BAA:
	mov	word ptr cs:talk_buf+2, OFFSET T_TRI2_003
	mov	word ptr cs:choice_jumps, OFFSET L1AB8
	jmp	SHORT L1BE6

T_TRI2_004	LABEL	BYTE
	DB	'#TRI2\TRI2_004#Beam us to Vlict''s position.',0
L1BE6:
	mov	word ptr cs:talk_buf+4, OFFSET T_TRI2_004
	mov	word ptr cs:choice_jumps+2, OFFSET L1AFC
	jmp	SHORT L1C0F

T_TRI2_007	LABEL	BYTE
	DB	'#TRI2\TRI2_007#Negative.',0
L1C0F:
	mov	word ptr cs:talk_buf+6, OFFSET T_TRI2_007
	mov	word ptr cs:choice_jumps+4, OFFSET L1B10
	mov	word ptr cs:talk_buf+8, 0
	push	OFFSET talk_buf
	push	RC_TALK
	SERVICE		; Talk(talk_buf)
	add	sp, 4
	shl	ax, 1
	mov	si, ax
	jmp	word ptr cs:[si+choice_jumps]

L1C3A:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI2U087
	call	Say
	JMPN	L1D09

T_TRI2U087	LABEL	BYTE
	DB	'#TRI2\TRI2U087#Captain, there is still a barrier between us and '
	DB	'the planet. Mr. Scott thinks there might be a way to break throu'
	DB	'gh it, and he''s working on it now, but the Klingons won''t like i'
	DB	't.',0
L1D09:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI2_006
	call	Say
	jmp	SHORT L1D6D

T_TRI2_006	LABEL	BYTE
	DB	'#TRI2\TRI2_006#Keep working on it, but don''t try to beam us up u'
	DB	'nless I give the signal.',0
L1D6D:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI2U104
	call	Say
	jmp	SHORT L1D9C

T_TRI2U104	LABEL	BYTE
	DB	'#TRI2\TRI2U104#Understood, Captain.',0
L1D9C:
	cmp	byte ptr [si+spheres_gone], 0
	je	L1DA5
	JMPN	L1E40

L1DA5:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI2U081
	call	Say
	jmp	SHORT L1DDF

T_TRI2U081	LABEL	BYTE
	DB	'#TRI2\TRI2U081#By the way, sensors indicate...',0
L1DDF:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TRI2_002
	call	Say
	jmp	SHORT L1E40

T_TRI2_002	LABEL	BYTE
	DB	'#TRI2\TRI2_002#...some kind of energy source a few meters from o'
	DB	'ur position. We know.',0
L1E40:
	mov	ax, OFFSET N_Lt_Uhura
	mov	bx, OFFSET T_TRI2U074
	call	Say
	jmp	SHORT L1EBC

T_TRI2U074	LABEL	BYTE
	DB	'#TRI2\TRI2U074#Please keep in contact with us. We''ll keep you in'
	DB	'formed if further developments occur. Uhura out.',0
L1EBC:
	retf

; The crew on the spheres and the wall.
H_1EBD:
	SCRIPT	MSG_USE, OBJ_MCCOY, 9, 0, H_1F0B
McCoyOnSphere2:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI2_012
	call	Say
	jmp	SHORT L1F0A

T_TRI2_012	LABEL	BYTE
	DB	'#TRI2\TRI2_012#I''m not touching some damned ball of energy!',0
L1F0A:
	retf

H_1F0B:
	SCRIPT	MSG_USE, OBJ_MCCOY, 0Ah, 0, H_1F59
McCoyOnSphere3:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI2_012_2
	call	Say
	jmp	SHORT L1F58

T_TRI2_012_2	LABEL	BYTE
	DB	'#TRI2\TRI2_012#I''m not touching some damned ball of energy!',0
L1F58:
	retf

H_1F59:
	SCRIPT	MSG_USE, OBJ_MCCOY, 21h, 0, H_1FA4
McCoyOnWall:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI2_010
	call	Say
	jmp	SHORT L1FA3

T_TRI2_010	LABEL	BYTE
	DB	'#TRI2\TRI2_010#Do you want me to hit my head against it?',0
L1FA3:
	retf

H_1FA4:
	SCRIPT	MSG_USE, OBJ_SPOCK, 9, 0, H_2024
SpockOnSphere2:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI2_028
	call	Say
	jmp	SHORT L2023

T_TRI2_028	LABEL	BYTE
	DB	'#TRI2\TRI2_028#This automaton is generating a force field, Capta'
	DB	'in. I am physically incapable of touching it.',0
L2023:
	retf

H_2024:
	SCRIPT	MSG_USE, OBJ_SPOCK, 0Ah, 0, H_20A4
SpockOnSphere3:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI2_F11
	call	Say
	jmp	SHORT L20A3

T_TRI2_F11	LABEL	BYTE
	DB	'#TRI2\TRI2_F11#This automaton is generating a force field, Capta'
	DB	'in. I am physically incapable of touching it.',0
L20A3:
	retf

H_20A4:
	SCRIPT	MSG_USE, OBJ_SPOCK, 21h, 0, H_20F7
SpockOnWall:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TRI2_022
	call	Say
	jmp	SHORT L20F6

T_TRI2_022	LABEL	BYTE
	DB	'#TRI2\TRI2_022#I do not understand the desired course of action.',0
L20F6:
	retf

H_20F7:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 9, 0, H_2157
BennieOnSphere2:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI2_031
	call	Say
	jmp	SHORT L2156

T_TRI2_031	LABEL	BYTE
	DB	'#TRI2\TRI2_031#I refuse, Captain, on the grounds that it might i'
	DB	'ncinerate me.',0
L2156:
	retf

H_2157:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 0Ah, 0, H_21B7
BennieOnSphere3:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI2_031_2
	call	Say
	jmp	SHORT L21B6

T_TRI2_031_2	LABEL	BYTE
	DB	'#TRI2\TRI2_031#I refuse, Captain, on the grounds that it might i'
	DB	'ncinerate me.',0
L21B6:
	retf

H_21B7:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 21h, 0, H_21E8
BennieOnWall:
	mov	ax, OFFSET N_Ensign_Bennie
	mov	bx, OFFSET T_TRI2_032
	call	Say
	jmp	SHORT L21E7

T_TRI2_032	LABEL	BYTE
	DB	'#TRI2\TRI2_032#Uh, pardon sir?',0
L21E7:
	retf

; Walking back to the entity's chamber.
H_21E8:
	SCRIPT	MSG_WALK, 22h, 0, 0, H_220B
WalkBack:
	mov	ax, 0
	push	ax
	mov	ax, 0B5h
	push	ax
	mov	ax, 117h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 279, 181, 0)
	add	sp, 0Ah
	retf

H_220B:
	SCRIPT	MSG_USE, IT_MEDKIT, ANY, 0, rdf_scripts_end
UseMedkit:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TRI2_018
	call	Say
	jmp	SHORT L226C

T_TRI2_018	LABEL	BYTE
	DB	'#TRI2\TRI2_018#Nobody needs healing, Jim, but you will if they h'
	DB	'arm my patient.',0
L226C:
	retf

rdf_scripts_end	LABEL	BYTE

RDF	ENDS
	END
