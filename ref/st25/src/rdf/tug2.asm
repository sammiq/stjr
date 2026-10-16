; TUG2.RDF - "Hijacked", the Masada's brig. Two Elasi guards hold nine of
; the crew behind a forcefield. When the party arrives the guards draw;
; Kirk must stun (or kill) both before they fire. The guards shoot in
; rounds (timer 0), stunning the crew, or killing them if the party has
; used a phaser on kill. A stunned guard is tied up once the crew is free,
; but wakes up if the party leaves before then.
;
; The forcefield switch is booby-trapped: wires lead to a bomb inside the
; field. Pressing the switch, or pulling the wires, before the bomb is
; defused (Spock or Christensen) kills the prisoners. Defused, the wires
; are the wiring the transporter repair needs (room 0), and the bomb can
; be taken. The freed crew tell Kirk how to open the bridge door (room 1).
;
; Actors: 8 and 9 the guards, 10 (0Ah) the forcefield and prisoners, 11
; (0Bh) the bomb, 12 (0Ch) the wires, 13 (0Dh) the scorch on the wall.
; Objects: 8, 9 the guards, 0Ah the prisoners, 0Bh the bomb, 0Ch the
; wires, 20h the switch, 21h the door (to room 1), 22h the cell.
; Timers: 0 the guards fire, 2 Kirk is dead.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
score	EQU	RS_VARS+0	; word: the mission's score
bomb	EQU	RS_VARS+0Ch	; 0 armed, 4 defused, 6 went off (the prisoners are dead)
took_wiring	EQU	RS_VARS+0Eh
spock_assessed	EQU	RS_VARS+1Ch	; Spock has looked at the transporter controls (room 0)
heard_about_door	EQU	RS_VARS+1Fh	; the freed crew have told Kirk how to open the bridge door
found_bomb	EQU	RS_VARS+20h
used_kill	EQU	RS_VARS+21h	; a phaser on kill has been used: the guards shoot to kill
guard_round	EQU	RS_VARS+22h	; how many times the guards have fired
guard1	EQU	RS_VARS+23h	; 0 up, 1 stunned, 2 killed, 8 tied up
guard2	EQU	RS_VARS+24h	; as guard1
wall_scorched	EQU	RS_VARS+25h	; a kill shot hit the wall
kirk_killed	EQU	RS_VARS+26h	; 1 by a guard here, 2 on the bridge (room 3)
spock_killed	EQU	RS_VARS+27h
mccoy_killed	EQU	RS_VARS+28h
redshirt_killed	EQU	RS_VARS+29h
crew_freed	EQU	RS_VARS+2Fh	; the brig forcefield is off
guard1_drew	EQU	RS_VARS+30h	; guard 1 has drawn his weapon
been_here	EQU	RS_VARS+32h	; the party came in since the guards were last up
kirk_drew	EQU	RS_VARS+34h	; Kirk has drawn his phaser
talked_to_crew	EQU	RS_VARS+36h

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
	DW	-1, -1, -1, 1	; room for each exit
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
	DW	52,179, 102,184	; entrance 3, crew 0
	DW	11,173, 90,173	; entrance 3, crew 1
	DW	0,173, 46,188	; entrance 3, crew 2
	DW	15,183, 68,194	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	102,184, 86,169, 46,188, 68,194	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0
rdf_objects	LABEL	BYTE
	DW	20h, 4	; id, points
	DW	211,102, 222,103, 222,119, 211,119
	DW	21h, 4	; id, points
	DW	0,90, 27,91, 25,162, 0,172
	DW	22h, 4	; id, points
	DW	138,140, 155,71, 193,71, 215,144

rdf_scripts:
rdf_objects_end:
; The room starts: the bomb, the wires, the forcefield (on, off, or the
; explosion's aftermath), and the guards. A stunned guard is tied up if
; the crew is free, else he wakes and the party's injuries are forgotten.
; The first time (been_here), the guards are ready: no walking, music 32.
H_0106:
	SCRIPT	MSG_TICK, 1, 0, 0, H_03BA
StartRoom:
	jmp	SHORT L0117

N_TUG2LOOP	LABEL	BYTE
	DB	'TUG2LOOP',0
L0117:
	push	OFFSET N_TUG2LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("TUG2LOOP")
	add	sp, 4
	cmp	byte ptr [si+found_bomb], 1
	je	L014A
	jmp	SHORT L0135

N_t2bomb	LABEL	BYTE
	DB	't2bomb',0
L0135:
	push	0
	push	1
	push	-3
	push	OFFSET N_t2bomb
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "t2bomb", -3, 1, 0)
	add	sp, 0Ch
L014A:
	cmp	byte ptr [si+took_wiring], 1
	je	L016E
	jmp	SHORT L0159

N_t2wire	LABEL	BYTE
	DB	't2wire',0
L0159:
	push	0
	push	1
	push	0
	push	OFFSET N_t2wire
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "t2wire", 0, 1, 0)
	add	sp, 0Ch
L016E:
	cmp	byte ptr [si+crew_freed], 0
	jne	L0191
	jmp	SHORT L017C

N_fld01	LABEL	BYTE
	DB	'fld01',0
L017C:
	push	0
	push	0
	push	0
	push	OFFSET N_fld01
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "fld01", 0, 0, 0)
	add	sp, 0Ch
L0191:
	cmp	byte ptr [si+crew_freed], 1
	jne	L01B5
	jmp	SHORT L01A0

N_fld10d	LABEL	BYTE
	DB	'fld10d',0
L01A0:
	push	0
	push	0
	push	0
	push	OFFSET N_fld10d
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "fld10d", 0, 0, 0)
	add	sp, 0Ch
L01B5:
	cmp	byte ptr [si+bomb], 6
	jne	L01D9
	jmp	SHORT L01C4

N_zapdon	LABEL	BYTE
	DB	'zapdon',0
L01C4:
	push	0
	push	0
	push	0
	push	OFFSET N_zapdon
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "zapdon", 0, 0, 0)
	add	sp, 0Ch
L01D9:
	cmp	byte ptr [si+guard1], 8
	jne	L01FF
	jmp	SHORT L01E8

N_p5tied	LABEL	BYTE
	DB	'p5tied',0
L01E8:
	push	0
	push	0B1h
	push	0E0h
	push	OFFSET N_p5tied
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p5tied", 224, 177, 0)
	add	sp, 0Ch
L01FF:
	cmp	byte ptr [si+guard1], 1
	jne	L022F
	cmp	byte ptr [si+crew_freed], 1
	jne	L022F
	jmp	SHORT L0214

N_p5tied_2	LABEL	BYTE
	DB	'p5tied',0
L0214:
	push	0
	push	0B1h
	push	0E0h
	push	OFFSET N_p5tied_2
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p5tied", 224, 177, 0)
	add	sp, 0Ch
	mov	byte ptr [si+guard1], 8
L022F:
	cmp	byte ptr [si+guard1], 1
	jne	L0259
	cmp	byte ptr [si+crew_freed], 0
	jne	L0259
	mov	byte ptr [si+guard1], 0
	mov	byte ptr [si+kirk_killed], 0
	mov	byte ptr [si+spock_killed], 0
	mov	byte ptr [si+mccoy_killed], 0
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 0
	jne	L0255
	mov	byte ptr [si+redshirt_killed], 0
L0255:
	mov	byte ptr [si+been_here], 0
L0259:
	cmp	byte ptr [si+guard1], 0
	jne	L027F
	jmp	SHORT L0268

N_p5redy	LABEL	BYTE
	DB	'p5redy',0
L0268:
	push	0
	push	0B1h
	push	0E0h
	push	OFFSET N_p5redy
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p5redy", 224, 177, 0)
	add	sp, 0Ch
L027F:
	cmp	byte ptr [si+guard1], 2
	jne	L02A4
	jmp	SHORT L028D

N_p5hat	LABEL	BYTE
	DB	'p5hat',0
L028D:
	push	0
	push	0B1h
	push	0E0h
	push	OFFSET N_p5hat
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p5hat", 224, 177, 0)
	add	sp, 0Ch
L02A4:
	cmp	byte ptr [si+guard2], 8
	jne	L02CA
	jmp	SHORT L02B3

N_p6tied	LABEL	BYTE
	DB	'p6tied',0
L02B3:
	push	0
	push	0C5h
	push	0FBh
	push	OFFSET N_p6tied
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p6tied", 251, 197, 0)
	add	sp, 0Ch
L02CA:
	cmp	byte ptr [si+guard2], 1
	jne	L02FA
	cmp	byte ptr [si+crew_freed], 1
	jne	L02FA
	jmp	SHORT L02DF

N_p6tied_2	LABEL	BYTE
	DB	'p6tied',0
L02DF:
	push	0
	push	0C5h
	push	0FBh
	push	OFFSET N_p6tied_2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p6tied", 251, 197, 0)
	add	sp, 0Ch
	mov	byte ptr [si+guard2], 8
L02FA:
	cmp	byte ptr [si+guard2], 1
	jne	L0324
	cmp	byte ptr [si+crew_freed], 0
	jne	L0324
	mov	byte ptr [si+guard2], 0
	mov	byte ptr [si+kirk_killed], 0
	mov	byte ptr [si+spock_killed], 0
	mov	byte ptr [si+mccoy_killed], 0
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 0
	jne	L0320
	mov	byte ptr [si+redshirt_killed], 0
L0320:
	mov	byte ptr [si+been_here], 0
L0324:
	cmp	byte ptr [si+guard2], 0
	jne	L034A
	jmp	SHORT L0333

N_p6draw	LABEL	BYTE
	DB	'p6draw',0
L0333:
	push	0
	push	0C5h
	push	0FBh
	push	OFFSET N_p6draw
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p6draw", 251, 197, 0)
	add	sp, 0Ch
L034A:
	cmp	byte ptr [si+guard2], 2
	jne	L036F
	jmp	SHORT L0358

N_p5hat_2	LABEL	BYTE
	DB	'p5hat',0
L0358:
	push	0
	push	0C5h
	push	0FBh
	push	OFFSET N_p5hat_2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p5hat", 251, 197, 0)
	add	sp, 0Ch
L036F:
	cmp	byte ptr [si+wall_scorched], 0
	je	L0393
	jmp	SHORT L037E

N_wallht	LABEL	BYTE
	DB	'wallht',0
L037E:
	push	0
	push	0
	push	0
	push	OFFSET N_wallht
	push	0Dh
	push	RC_ANIM2
	SERVICE		; Anim(13, "wallht", 0, 0, 0)
	add	sp, 0Ch
L0393:
	cmp	byte ptr [si+been_here], 0
	jne	L03B1
	mov	byte ptr [si+RS_NO_WALK], 1
	mov	ax, -1
	push	ax
	mov	ax, 20h
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(32, -1)
	add	sp, 6
L03B1:
	mov	byte ptr [si+been_here], 1
	mov	byte ptr [si+kirk_drew], 0
	retf

; Tick 60, with a guard up: he challenges the party and timer 0 starts
; the shooting.
H_03BA:
	SCRIPT	MSG_TICK, 3Ch, 0, 0, H_0412
GuardsChallenge:
	cmp	byte ptr [si+guard1], 0
	je	L03CD
	cmp	byte ptr [si+guard2], 0
	je	L03CD
	retf

L03CD:
	mov	si, word ptr cs:rdf_state
	mov	word ptr [si+RS_TIMERS], 3Ch
	mov	ax, OFFSET N_Elasi_Guard
	mov	bx, OFFSET T_TUG2L085
	call	Say
	jmp	SHORT L040E

T_TUG2L085	LABEL	BYTE
	DB	'#TUG2\TUG2L085#Hey, what are you doing here?',0
L040E:
	call	Guard1Draws
	retf

; Looking at things.
H_0412:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_047C
LookAtSwitch:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N011
	call	Say
	jmp	SHORT L047B

T_TUG2N011	LABEL	BYTE
	DB	'#TUG2\TUG2N011#This appears to be the button that turns the brig'
	DB	' forcefield on and off.',0
L047B:
	retf

H_047C:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_04BD
LookAtMcCoy:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N005
	call	Say
	jmp	SHORT L04BC

T_TUG2N005	LABEL	BYTE
	DB	'#TUG2\TUG2N005#McCoy is looking at the guards.',0
L04BC:
	retf

H_04BD:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_04F7
LookAtSpock:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N007
	call	Say
	jmp	SHORT L04F6

T_TUG2N007	LABEL	BYTE
	DB	'#TUG2\TUG2N007#Spock raises an eyebrow.',0
L04F6:
	retf

H_04F7:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_0543
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N004
	call	Say
	jmp	SHORT L0542

T_TUG2N004	LABEL	BYTE
	DB	'#TUG2\TUG2N004#Lt. Christensen is fumbling for his phaser',0
L0542:
	retf

; Taking the bomb, once the field is off (msgs 12, 13).
H_0543:
	SCRIPT	MSG_GET, 0Bh, 0, 0, H_05C5
GetBomb:
	cmp	byte ptr [si+crew_freed], 1
	je	L05A0
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N024
	call	Say
	jmp	SHORT L059F

T_TUG2N024	LABEL	BYTE
	DB	'#TUG2\TUG2N024#You can''t.  it is located just inside the forcefi'
	DB	'eld.',0
L059F:
	retf

L05A0:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 0
	mov	ax, 0Ch
	push	ax
	mov	ax, 0A0h
	push	ax
	mov	ax, 0C9h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 201, 160, 12)
	add	sp, 0Ah
	retf

H_05C5:
	SCRIPT	MSG_WALK_DONE, 0Ch, 0, 0, H_05EA
KirkAtBomb:
	jmp	SHORT L05D4

N_kusehn	LABEL	BYTE
	DB	'kusehn',0
L05D4:
	push	0Dh
	push	-1
	push	-1
	push	OFFSET N_kusehn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 13)
	add	sp, 0Ch
	retf

H_05EA:
	SCRIPT	MSG_ANIM_DONE, 0Dh, 0, 0, H_061A
TookBomb:
	mov	ax, 0Bh
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(11)
	add	sp, 4
	push	IT_BOMB
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_BOMB)
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+found_bomb], 1
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_061A:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_0666
LookAtBomb:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N000
	call	Say
	jmp	SHORT L0665

T_TUG2N000	LABEL	BYTE
	DB	'#TUG2\TUG2N000#A bomb located just inside the forcefield.',0
L0665:
	retf

H_0666:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_076B
LookAtGuard1:
	cmp	byte ptr [si+guard1], 0
	jne	L06AA
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N001
	call	Say
	jmp	SHORT L06A9

T_TUG2N001	LABEL	BYTE
	DB	'#TUG2\TUG2N001#He doesn''t look to friendly.',0
L06A9:
	retf

L06AA:
	cmp	byte ptr [si+guard1], 1
	jne	L06E2
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N013
	call	Say
	jmp	SHORT L06E1

T_TUG2N013	LABEL	BYTE
	DB	'#TUG2\TUG2N013#This guard is stunned.',0
L06E1:
	retf

L06E2:
	cmp	byte ptr [si+guard1], 8
	jne	L071A
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N015
	call	Say
	jmp	SHORT L0719

T_TUG2N015	LABEL	BYTE
	DB	'#TUG2\TUG2N015#This guard is tied up.',0
L0719:
	retf

L071A:
	cmp	byte ptr [si+guard1], 2
	jne	L076A
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N106
	call	Say
	jmp	SHORT L0769

T_TUG2N106	LABEL	BYTE
	DB	'#TUG2\TUG2N106#Only the red beret of the elasi guard remains.',0
L0769:
	retf

L076A:
	retf

H_076B:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_0870
LookAtGuard2:
	cmp	byte ptr [si+guard2], 0
	jne	L07AF
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N037
	call	Say
	jmp	SHORT L07AE

T_TUG2N037	LABEL	BYTE
	DB	'#TUG2\TUG2N037#He doesn''t look to friendly.',0
L07AE:
	retf

L07AF:
	cmp	byte ptr [si+guard2], 1
	jne	L07E7
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N014
	call	Say
	jmp	SHORT L07E6

T_TUG2N014	LABEL	BYTE
	DB	'#TUG2\TUG2N014#This guard is stunned.',0
L07E6:
	retf

L07E7:
	cmp	byte ptr [si+guard2], 8
	jne	L081F
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N016
	call	Say
	jmp	SHORT L081E

T_TUG2N016	LABEL	BYTE
	DB	'#TUG2\TUG2N016#This guard is tied up.',0
L081E:
	retf

L081F:
	cmp	byte ptr [si+guard2], 2
	jne	L086F
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N106_2
	call	Say
	jmp	SHORT L086E

T_TUG2N106_2	LABEL	BYTE
	DB	'#TUG2\TUG2N106#Only the red beret of the elasi guard remains.',0
L086E:
	retf

L086F:
	retf

; Christensen.
H_0870:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_08B3
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Christensen
	mov	bx, OFFSET T_TUG2L002
	call	Say
	jmp	SHORT L08B2

T_TUG2L002	LABEL	BYTE
	DB	'#TUG2\TUG2L002#I''m just a security officer, sir.',0
L08B2:
	retf

H_08B3:
	SCRIPT	MSG_LOOK, 0Ch, 0, 0, H_0907
LookAtWires:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N010
	call	Say
	jmp	SHORT L0906

T_TUG2N010	LABEL	BYTE
	DB	'#TUG2\TUG2N010#These wires look like a modification of some sort'
	DB	'.',0
L0906:
	retf

; The wires: Spock finds the booby trap. Spock or Christensen defuse it
; (+2 score); McCoy won't, and Kirk asks Spock.
H_0907:
	SCRIPT	MSG_USE, IT_STRICOR, 0Ch, 0, H_090F
	jmp	SHORT SpockScansSwitch

H_090F:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_09D0
SpockScansSwitch:
	cmp	byte ptr [si+bomb], 0
	je	L091E
	JMPN	L09CF

L091E:
	mov	byte ptr [si+RS_FALL+1], 2
	jmp	SHORT L092B

N_sscane	LABEL	BYTE
	DB	'sscane',0
L092B:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscane
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscane", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG2_007
	call	Say
	jmp	SHORT L09CF

T_TUG2_007	LABEL	BYTE
	DB	'#TUG2\TUG2_007#Captain, the switch has been booby-trapped to det'
	DB	'onate a bomb, presumably inside the brig somewhere.',0
L09CF:
	retf

H_09D0:
	SCRIPT	MSG_USE, OBJ_MCCOY, 0Ch, 0, H_0A4D
McCoyOnWires:
	cmp	byte ptr [si+bomb], 0
	jne	L0A4C
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG2_009
	call	Say
	jmp	SHORT L0A4C

T_TUG2_009	LABEL	BYTE
	DB	'#TUG2\TUG2_009#Damn it, Jim, I''m a doctor, not an electrical eng'
	DB	'ineer! I''m likely to blow us all up.',0
L0A4C:
	retf

H_0A4D:
	SCRIPT	MSG_USE, OBJ_MCCOY, 0Bh, 0, H_0AAD
McCoyOnBomb:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG2_011
	call	Say
	jmp	SHORT L0AAC

T_TUG2_011	LABEL	BYTE
	DB	'#TUG2\TUG2_011#I don''t operate on bombs, Jim, unless you like bi'
	DB	'g explosions.',0
L0AAC:
	retf

H_0AAD:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 0Ch, 0, H_0B24
ChristensenOnWires:
	cmp	byte ptr [si+RS_NO_WALK], 0
	jne	L0B23
	cmp	byte ptr [si+bomb], 0
	jne	L0B23
	mov	ax, OFFSET N_Lt_Christensen
	mov	bx, OFFSET T_TUG2L007
	call	Say
	jmp	SHORT L0AFF

T_TUG2L007	LABEL	BYTE
	DB	'#TUG2\TUG2L007#I believe I can disarm this, Captain.',0
L0AFF:
	mov	byte ptr [si+RS_FALL+3], 0
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 6
	push	ax
	mov	ax, 0A0h
	push	ax
	mov	ax, 0C9h
	push	ax
	mov	ax, 3
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(3, 201, 160, 6)
	add	sp, 0Ah
L0B23:
	retf

H_0B24:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_0B49
ChristensenAtWires:
	jmp	SHORT L0B33

N_rusemn	LABEL	BYTE
	DB	'rusemn',0
L0B33:
	push	7
	push	-1
	push	-1
	push	OFFSET N_rusemn
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rusemn", -1, -1, 7)
	add	sp, 0Ch
	retf

H_0B49:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_0BC7
ChristensenDefuses:
	mov	ax, 0
	mov	bx, OFFSET N_Snip_snip_snip
	call	Say
	jmp	SHORT L0B6E

N_Snip_snip_snip	LABEL	BYTE
	DB	'Snip...snip...snip.',0
L0B6E:
	mov	ax, OFFSET N_Lt_Christensen
	mov	bx, OFFSET T_TUG2L011
	call	Say
	jmp	SHORT L0B9D

T_TUG2L011	LABEL	BYTE
	DB	'#TUG2\TUG2L011#There, It''s defused.',0
L0B9D:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+bomb], 4
	mov	byte ptr [si+RS_FALL+3], 2
	mov	ax, 8
	push	ax
	mov	ax, 0C2h
	push	ax
	mov	ax, 44h
	push	ax
	mov	ax, 3
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(3, 68, 194, 8)
	add	sp, 0Ah
	retf

H_0BC7:
	SCRIPT	MSG_WALK_DONE, 8, 0, 0, H_0BD6
ChristensenBack:
	mov	byte ptr [si+RS_BUSY], 0
	add	word ptr [si+score], 2
	retf

H_0BD6:
	SCRIPT	MSG_USE, OBJ_KIRK, 0Ch, 0, H_0C0D
KirkOnWires:
	cmp	byte ptr [si+RS_NO_WALK], 0
	jne	L0C0C
	cmp	byte ptr [si+bomb], 0
	jne	L0C0C
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 2
	mov	ax, 5
	push	ax
	mov	ax, 0A0h
	push	ax
	mov	ax, 0C9h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 201, 160, 5)
	add	sp, 0Ah
L0C0C:
	retf

H_0C0D:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_0CAA
KirkAtWires:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG2_003
	call	Say
	jmp	SHORT L0C4F

T_TUG2_003	LABEL	BYTE
	DB	'#TUG2\TUG2_003#Spock see if you can disarm this.',0
L0C4F:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG2_023
	call	Say
	jmp	SHORT L0C83

T_TUG2_023	LABEL	BYTE
	DB	'#TUG2\TUG2_023#I''ll do my best, Captain.',0
L0C83:
	mov	byte ptr [si+RS_FALL], 2
	mov	ax, 0
	push	ax
	mov	ax, 0B8h
	push	ax
	mov	ax, 66h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 102, 184, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_BUSY], 0
	jmp	SHORT SpockOnWires

	DB	0CBh

H_0CAA:
	SCRIPT	MSG_USE, OBJ_SPOCK, 0Ch, 0, H_0CE1
SpockOnWires:
	cmp	byte ptr [si+RS_NO_WALK], 0
	jne	L0CE0
	cmp	byte ptr [si+bomb], 0
	jne	L0CE0
	mov	byte ptr [si+RS_FALL+1], 2
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, 9
	push	ax
	mov	ax, 0A0h
	push	ax
	mov	ax, 0C9h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 201, 160, 9)
	add	sp, 0Ah
L0CE0:
	retf

H_0CE1:
	SCRIPT	MSG_WALK_DONE, 9, 0, 0, H_0DFA
SpockDefuses:
	jmp	SHORT L0CF0

N_suseme	LABEL	BYTE
	DB	'suseme',0
L0CF0:
	push	0
	push	-1
	push	-1
	push	OFFSET N_suseme
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "suseme", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L0D10

N_WIRESNIP	LABEL	BYTE
	DB	'WIRESNIP',0
L0D10:
	push	OFFSET N_WIRESNIP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("WIRESNIP")
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG2_024
	call	Say
	jmp	SHORT L0D6C

T_TUG2_024	LABEL	BYTE
	DB	'#TUG2\TUG2_024#There. I believe the bomb is now defused, Captain'
	DB	'.',0
L0D6C:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+bomb], 4
	cmp	byte ptr [si+spock_assessed], 1
	jne	L0DD9
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG2_008
	call	Say
	jmp	SHORT L0DD9

T_TUG2_008	LABEL	BYTE
	DB	'#TUG2\TUG2_008#Captain, this wiring may prove useful in repairin'
	DB	'g the transporter.',0
L0DD9:
	mov	byte ptr [si+RS_FALL+1], 2
	mov	ax, 0Bh
	push	ax
	mov	ax, 0A9h
	push	ax
	mov	ax, 56h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 86, 169, 11)
	add	sp, 0Ah
	retf

H_0DFA:
	SCRIPT	MSG_WALK_DONE, 0Bh, 0, 0, H_0E09
SpockBack:
	mov	byte ptr [si+RS_BUSY], 0
	add	word ptr [si+score], 2
	retf

; Pulling the wires (msgs 28, 29): if armed, the bomb goes off; if
; defused, Kirk has the wiring, +3 score.
H_0E09:
	SCRIPT	MSG_GET, 0Ch, 0, 0, H_0E3A
GetWires:
	cmp	byte ptr [si+RS_NO_WALK], 0
	jne	L0E39
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 2
	mov	ax, 1Ch
	push	ax
	mov	ax, 0A0h
	push	ax
	mov	ax, 0C9h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 201, 160, 28)
	add	sp, 0Ah
L0E39:
	retf

H_0E3A:
	SCRIPT	MSG_WALK_DONE, 1Ch, 0, 0, H_0E5F
KirkAtWires2:
	jmp	SHORT L0E49

N_kuseme	LABEL	BYTE
	DB	'kuseme',0
L0E49:
	push	1Dh
	push	-1
	push	-1
	push	OFFSET N_kuseme
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kuseme", -1, -1, 29)
	add	sp, 0Ch
	retf

H_0E5F:
	SCRIPT	MSG_ANIM_DONE, 1Dh, 0, 0, H_0F4F
PulledWires:
	cmp	byte ptr [si+bomb], 0
	je	L0E6E
	JMPN	L0F26

L0E6E:
	mov	ax, -1
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(2, -1)
	add	sp, 6
	jmp	SHORT L0E88

N_zap	LABEL	BYTE
	DB	'zap',0
L0E88:
	push	1
	push	0
	push	0
	push	OFFSET N_zap
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "zap", 0, 0, 1)
	add	sp, 0Ch
	jmp	SHORT L0EA8

N_NM8EXPLO	LABEL	BYTE
	DB	'NM8EXPLO',0
L0EA8:
	push	OFFSET N_NM8EXPLO
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("NM8EXPLO")
	add	sp, 4
	jmp	SHORT L0EBF

N_t2bbo	LABEL	BYTE
	DB	't2bbo',0
L0EBF:
	push	0
	push	1
	push	-3
	push	OFFSET N_t2bbo
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "t2bbo", -3, 1, 0)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	mov	ax, 16h
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(22)
	add	sp, 4
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+bomb], 6
	mov	ax, 0Ch
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(12)
	add	sp, 4
	push	IT_WIRING
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_WIRING)
	add	sp, 4
	mov	byte ptr [si+took_wiring], 1
	mov	byte ptr [si+RS_BUSY], 0
	add	word ptr [si+score], 3
	retf

L0F26:
	mov	ax, 0Ch
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(12)
	add	sp, 4
	push	IT_WIRING
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_WIRING)
	add	sp, 4
	mov	byte ptr [si+took_wiring], 1
	mov	byte ptr [si+RS_BUSY], 0
	add	word ptr [si+score], 3
	retf

; The switch (msgs 14-21): if armed, the bomb goes off; if defused, the
; field goes down and the crew are free, +6 score.
H_0F4F:
	SCRIPT	MSG_USE, OBJ_KIRK, 20h, 0, H_0F80
KirkPressesSwitch:
	cmp	byte ptr [si+RS_NO_WALK], 0
	jne	L0F7F
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL], 2
	mov	ax, 0Eh
	push	ax
	mov	ax, 0A0h
	push	ax
	mov	ax, 0C9h
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 201, 160, 14)
	add	sp, 0Ah
L0F7F:
	retf

H_0F80:
	SCRIPT	MSG_WALK_DONE, 0Eh, 0, 0, H_0FB5
KirkAtSwitch:
	jmp	SHORT L0F8F

N_kusehe	LABEL	BYTE
	DB	'kusehe',0
L0F8F:
	push	0Fh
	push	-1
	push	-1
	push	OFFSET N_kusehe
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehe", -1, -1, 15)
	add	sp, 0Ch
	mov	ax, 7
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(7)
	add	sp, 4
	retf

H_0FB5:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_0FE6
SpockPressesSwitch:
	cmp	byte ptr [si+RS_NO_WALK], 0
	jne	L0FE5
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL+1], 2
	mov	ax, 10h
	push	ax
	mov	ax, 0A0h
	push	ax
	mov	ax, 0C9h
	push	ax
	mov	ax, 1
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(1, 201, 160, 16)
	add	sp, 0Ah
L0FE5:
	retf

H_0FE6:
	SCRIPT	MSG_WALK_DONE, 10h, 0, 0, H_101B
SpockAtSwitch:
	jmp	SHORT L0FF5

N_susehe	LABEL	BYTE
	DB	'susehe',0
L0FF5:
	push	11h
	push	-1
	push	-1
	push	OFFSET N_susehe
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "susehe", -1, -1, 17)
	add	sp, 0Ch
	mov	ax, 7
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(7)
	add	sp, 4
	retf

H_101B:
	SCRIPT	MSG_USE, OBJ_MCCOY, 20h, 0, H_1046
McCoyPressesSwitch:
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL+2], 2
	mov	ax, 12h
	push	ax
	mov	ax, 0A0h
	push	ax
	mov	ax, 0C9h
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(2, 201, 160, 18)
	add	sp, 0Ah
	retf

H_1046:
	SCRIPT	MSG_WALK_DONE, 12h, 0, 0, H_107B
McCoyAtSwitch:
	mov	ax, 7
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(7)
	add	sp, 4
	jmp	SHORT L1065

N_musehe	LABEL	BYTE
	DB	'musehe',0
L1065:
	push	13h
	push	-1
	push	-1
	push	OFFSET N_musehe
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "musehe", -1, -1, 19)
	add	sp, 0Ch
	retf

H_107B:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 20h, 0, H_10AC
ChristensenPressesSwitch:
	cmp	byte ptr [si+RS_NO_WALK], 0
	jne	L10AB
	mov	byte ptr [si+RS_BUSY], 1
	mov	byte ptr [si+RS_FALL+3], 2
	mov	ax, 14h
	push	ax
	mov	ax, 0A0h
	push	ax
	mov	ax, 0C9h
	push	ax
	mov	ax, 3
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(3, 201, 160, 20)
	add	sp, 0Ah
L10AB:
	retf

H_10AC:
	SCRIPT	MSG_WALK_DONE, 14h, 0, 0, H_10E1
ChristensenAtSwitch:
	mov	ax, 7
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(7)
	add	sp, 4
	jmp	SHORT L10CB

N_rusehe	LABEL	BYTE
	DB	'rusehe',0
L10CB:
	push	15h
	push	-1
	push	-1
	push	OFFSET N_rusehe
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rusehe", -1, -1, 21)
	add	sp, 0Ch
	retf

H_10E1:
	SCRIPT	MSG_ANIM_DONE, 0Fh, 0, 0, H_10E9
	jmp	SHORT SwitchPressed

H_10E9:
	SCRIPT	MSG_ANIM_DONE, 11h, 0, 0, H_10F1
	jmp	SHORT SwitchPressed

H_10F1:
	SCRIPT	MSG_ANIM_DONE, 13h, 0, 0, H_10F9
	jmp	SHORT SwitchPressed

H_10F9:
	SCRIPT	MSG_ANIM_DONE, 15h, 0, 0, H_11CC
SwitchPressed:
	mov	byte ptr [si+RS_BUSY], 0
	cmp	byte ptr [si+bomb], 0
	jne	L1179
	mov	ax, -1
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(2, -1)
	add	sp, 6
	jmp	SHORT L1123

N_zap_2	LABEL	BYTE
	DB	'zap',0
L1123:
	push	1
	push	0
	push	0
	push	OFFSET N_zap_2
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "zap", 0, 0, 1)
	add	sp, 0Ch
	jmp	SHORT L1143

N_NM8EXPLO_2	LABEL	BYTE
	DB	'NM8EXPLO',0
L1143:
	push	OFFSET N_NM8EXPLO_2
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("NM8EXPLO")
	add	sp, 4
	jmp	SHORT L115A

N_t2bbo_2	LABEL	BYTE
	DB	't2bbo',0
L115A:
	push	0
	push	1
	push	-3
	push	OFFSET N_t2bbo_2
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "t2bbo", -3, 1, 0)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+bomb], 6
	retf

L1179:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+bomb], 4
	jne	L11CB
	cmp	byte ptr [si+crew_freed], 0
	jne	L11CB
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+crew_freed], 1
	jmp	SHORT L119B

N_fld10	LABEL	BYTE
	DB	'fld10',0
L119B:
	push	2
	push	0
	push	0
	push	OFFSET N_fld10
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "fld10", 0, 0, 2)
	add	sp, 0Ch
	add	word ptr [si+score], 6
	jmp	SHORT L11BC

N_EFX15	LABEL	BYTE
	DB	'EFX15',0
L11BC:
	push	OFFSET N_EFX15
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EFX15")
	add	sp, 4
L11CB:
	retf

; The bomb has gone off (anim msg 1): the field held, the prisoners died.
H_11CC:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_1288
BombWentOff:
	jmp	SHORT L11DB

N_zapdon_2	LABEL	BYTE
	DB	'zapdon',0
L11DB:
	push	0
	push	0
	push	0
	push	OFFSET N_zapdon_2
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "zapdon", 0, 0, 0)
	add	sp, 0Ch
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N026
	call	Say
	JMPN	L1287

T_TUG2N026	LABEL	BYTE
	DB	'#TUG2\TUG2N026#You''ve set off some type of booby trap. The force'
	DB	' field protected you from the blast, but everyone inside the bri'
	DB	'g is dead.',0
L1287:
	retf

; The field is down (anim msg 2): the crew tell of the bridge door.
H_1288:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_14B4
CrewFreed:
	jmp	SHORT L1297

N_fld10d_2	LABEL	BYTE
	DB	'fld10d',0
L1297:
	push	0
	push	0
	push	0
	push	OFFSET N_fld10d_2
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "fld10d", 0, 0, 0)
	add	sp, 0Ch
	mov	ax, OFFSET N_Masada_Crewman
	mov	bx, OFFSET T_TUG2_029
	call	Say
	jmp	SHORT L1321

T_TUG2_029	LABEL	BYTE
	DB	'#TUG2\TUG2_029#Thank you for freeing us, Captain! We''ll secure t'
	DB	'he area so they don''t come up behind you.',0
L1321:
	mov	ax, OFFSET N_Masada_Crewman
	mov	bx, OFFSET T_TUG2_030
	call	Say
	JMPN	L13DD

T_TUG2_030	LABEL	BYTE
	DB	'#TUG2\TUG2_030#We''ve had electrical problems with our door to ou'
	DB	'r bridge, Captain. The Elasi don''t know we put in an electric sh'
	DB	'utdown device -- you''d never find it by chance.',0
L13DD:
	mov	ax, OFFSET N_Masada_Crewman
	mov	bx, OFFSET T_TUG2_028
	call	Say
	JMPN	L14AA

T_TUG2_028	LABEL	BYTE
	DB	'#TUG2\TUG2_028#But if you used a charged Phaser Welder two feet '
	DB	'to the left of the door and one foot off the ground, you might b'
	DB	'e able to shut down the forcefield, and get a jump on the Elasi.',0
L14AA:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+heard_about_door], 1
	retf

; Phasers on the field.
H_14B4:
	SCRIPT	MSG_USE, IT_PHASERS, 0Ah, 0, H_14BC
	jmp	SHORT PhaserField

H_14BC:
	SCRIPT	MSG_USE, IT_PHASERK, 0Ah, 0, H_15BD
PhaserField:
	cmp	byte ptr [si+bomb], 0
	je	L14CB
	JMPN	L1566

L14CB:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG2_006
	call	Say
	JMPN	L1566

T_TUG2_006	LABEL	BYTE
	DB	'#TUG2\TUG2_006#Captain, if we could manage to overload the force'
	DB	'field, it would probably detonate the bomb before we could rescu'
	DB	'e the crewmen.',0
L1566:
	retf

; Guard 1 draws his weapon, once (near call).
Guard1Draws:
	cmp	byte ptr [si+guard1], 0
	jne	L1595
	cmp	byte ptr [si+guard1_drew], 0
	jne	L1595
	jmp	SHORT L157C

N_p5draw	LABEL	BYTE
	DB	'p5draw',0
L157C:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p5draw
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p5draw", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+guard1_drew], 1
L1595:
	ret

; Both guards down: walking again, and Kirk puts his phaser away.
GuardsDown:
	cmp	byte ptr [si+guard1], 0
	je	L15BC
	cmp	byte ptr [si+guard2], 0
	je	L15BC
	mov	byte ptr [si+RS_NO_WALK], 0
	cmp	byte ptr [si+kirk_drew], 1
	jne	L15BC
	mov	ax, 0
	push	ax
	mov	ax, RC_STOPANIM
	push	ax
	SERVICE		; StopAnim(0)
	add	sp, 4
L15BC:
	ret

; Phasers on the guards: Kirk draws (once) and fires (msgs 22-25). When
; both guards are down the party can walk again.
H_15BD:
	SCRIPT	MSG_USE, IT_PHASERS, 8, 0, H_15F9
StunGuard1:
	cmp	byte ptr [si+guard1], 0
	jne	Guard1Stunned
	call	Guard1Draws
	mov	byte ptr [si+RS_BUSY], 1
	cmp	byte ptr [si+kirk_drew], 0
	jne	Guard1Stunned
	jmp	SHORT L15DF

N_kdrawe	LABEL	BYTE
	DB	'kdrawe',0
L15DF:
	push	16h
	push	-1
	push	-1
	push	OFFSET N_kdrawe
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kdrawe", -1, -1, 22)
	add	sp, 0Ch
	mov	byte ptr [si+kirk_drew], 1
	retf

H_15F9:
	SCRIPT	MSG_ANIM_DONE, 16h, 0, 0, H_165E
Guard1Stunned:
	cmp	byte ptr [si+guard1], 0
	jne	L1659
	jmp	SHORT L160E

N_p5stun	LABEL	BYTE
	DB	'p5stun',0
L160E:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p5stun
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p5stun", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+guard1], 1
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L1642

N_t2beem03	LABEL	BYTE
	DB	't2beem03',0
L1642:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem03
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem03", 5)
	add	sp, 6
	call	GuardsDown
L1659:
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_165E:
	SCRIPT	MSG_USE, IT_PHASERS, 9, 0, H_169A
StunGuard2:
	cmp	byte ptr [si+guard2], 0
	jne	Guard2Stunned
	call	Guard1Draws
	mov	byte ptr [si+RS_BUSY], 1
	cmp	byte ptr [si+kirk_drew], 0
	jne	Guard2Stunned
	jmp	SHORT L1680

N_kdrawe_2	LABEL	BYTE
	DB	'kdrawe',0
L1680:
	push	17h
	push	-1
	push	-1
	push	OFFSET N_kdrawe_2
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kdrawe", -1, -1, 23)
	add	sp, 0Ch
	mov	byte ptr [si+kirk_drew], 1
	retf

H_169A:
	SCRIPT	MSG_ANIM_DONE, 17h, 0, 0, H_16FF
Guard2Stunned:
	cmp	byte ptr [si+guard2], 0
	jne	L16FA
	jmp	SHORT L16AF

N_p6stun	LABEL	BYTE
	DB	'p6stun',0
L16AF:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p6stun
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p6stun", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+guard2], 1
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L16E3

N_t2beem02	LABEL	BYTE
	DB	't2beem02',0
L16E3:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem02
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem02", 5)
	add	sp, 6
	call	GuardsDown
L16FA:
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_16FF:
	SCRIPT	MSG_USE, IT_PHASERK, 8, 0, H_173F
KillGuard1:
	cmp	byte ptr [si+guard1], 0
	jne	Guard1Killed
	call	Guard1Draws
	mov	byte ptr [si+RS_BUSY], 1
	cmp	byte ptr [si+kirk_drew], 0
	jne	Guard1Killed
	jmp	SHORT L1721

N_kdrawe_3	LABEL	BYTE
	DB	'kdrawe',0
L1721:
	push	18h
	push	-1
	push	-1
	push	OFFSET N_kdrawe_3
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kdrawe", -1, -1, 24)
	add	sp, 0Ch
	mov	byte ptr [si+kirk_drew], 1
	mov	byte ptr [si+used_kill], 1
	retf

H_173F:
	SCRIPT	MSG_ANIM_DONE, 18h, 0, 0, H_17A4
Guard1Killed:
	cmp	byte ptr [si+guard1], 0
	jne	L179F
	jmp	SHORT L1754

N_p5kill	LABEL	BYTE
	DB	'p5kill',0
L1754:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p5kill
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p5kill", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+guard1], 2
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L1788

N_t2beem05	LABEL	BYTE
	DB	't2beem05',0
L1788:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem05
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem05", 5)
	add	sp, 6
	call	GuardsDown
L179F:
	mov	byte ptr [si+RS_BUSY], 0
	retf

H_17A4:
	SCRIPT	MSG_USE, IT_PHASERK, 9, 0, H_17E4
KillGuard2:
	cmp	byte ptr [si+guard2], 0
	jne	Guard2Killed
	call	Guard1Draws
	mov	byte ptr [si+RS_BUSY], 1
	cmp	byte ptr [si+kirk_drew], 0
	jne	Guard2Killed
	jmp	SHORT L17C6

N_kdrawe_4	LABEL	BYTE
	DB	'kdrawe',0
L17C6:
	push	19h
	push	-1
	push	-1
	push	OFFSET N_kdrawe_4
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kdrawe", -1, -1, 25)
	add	sp, 0Ch
	mov	byte ptr [si+kirk_drew], 1
	mov	byte ptr [si+used_kill], 1
	retf

H_17E4:
	SCRIPT	MSG_ANIM_DONE, 19h, 0, 0, H_1849
Guard2Killed:
	cmp	byte ptr [si+guard2], 0
	jne	L1844
	jmp	SHORT L17F9

N_p6kill	LABEL	BYTE
	DB	'p6kill',0
L17F9:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p6kill
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p6kill", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+guard2], 2
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L182D

N_t2beem04	LABEL	BYTE
	DB	't2beem04',0
L182D:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem04
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem04", 5)
	add	sp, 6
	call	GuardsDown
L1844:
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Inventory, as in rooms 0 and 1.
H_1849:
	SCRIPT	MSG_USE, IT_PHASERS, IT_PWE, 0, H_1851
	jmp	SHORT ChargeWelder

H_1851:
	SCRIPT	MSG_USE, IT_PHASERK, IT_PWE, 0, H_18A8
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
	mov	bx, OFFSET T_TUG2N006
	call	Say
	jmp	SHORT L18A7

T_TUG2N006	LABEL	BYTE
	DB	'#TUG2\TUG2N006#Phaser Welder is now charged.',0
L18A7:
	retf

H_18A8:
	SCRIPT	MSG_USE, IT_PWF, IT_WIRSCRP, 0, H_1939
WeldWireScraps:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N009
	call	Say
	jmp	SHORT L192C

T_TUG2N009	LABEL	BYTE
	DB	'#TUG2\TUG2N009#The wire scraps are too small, they melt instead '
	DB	'of fusing together, and you''re left with nothing. ',0
L192C:
	push	IT_WIRSCRP
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_WIRSCRP)
	add	sp, 4
	retf

H_1939:
	SCRIPT	MSG_USE, IT_PWF, IT_JNKMETL, 0, H_19E7
WeldJunkMetal:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG2_112
	call	Say
	JMPN	L19CE

T_TUG2_112	LABEL	BYTE
	DB	'#TUG2\TUG2_112#I think that does it -- a Comb Bit for the transm'
	DB	'ogrifier. Now I can continue repairs on the transporter controls'
	DB	'. ',0
L19CE:
	push	IT_JNKMETL
	push	RC_TAKEITEM
	SERVICE		; TakeItem(IT_JNKMETL)
	add	sp, 4
	push	IT_COMBBIT
	push	RC_GIVEITEM
	SERVICE		; GiveItem(IT_COMBBIT)
	add	sp, 4
	retf

H_19E7:
	SCRIPT	MSG_USE, IT_COMBBIT, IT_RT, 0, H_1A53
FitCombBit:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG2_021
	call	Say
	jmp	SHORT L1A2E

T_TUG2_021	LABEL	BYTE
	DB	'#TUG2\TUG2_021#The parts fit together satisfactorily.',0
L1A2E:
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

; Kirk has been killed (anim msgs 26, 27): game over.
H_1A53:
	SCRIPT	MSG_ANIM_DONE, 1Ah, 0, 0, H_1A5B
	jmp	SHORT KirkKilled

H_1A5B:
	SCRIPT	MSG_ANIM_DONE, 1Bh, 0, 0, H_1A96
KirkKilled:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N025
	call	Say
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	mov	ax, 0
	mov	bx, OFFSET S_1A7F
	call	Say
	jmp	SHORT L1A94

S_1A7F	LABEL	BYTE
	DB	'***Game over man!***',0
L1A94:
	retf

	DB	0CBh

; The door, and looking and talking.
H_1A96:
	SCRIPT	MSG_WALK, 21h, 0, 0, H_1AB9
WalkToDoor:
	mov	ax, 0
	push	ax
	mov	ax, 0ABh
	push	ax
	mov	ax, 0Bh
	push	ax
	mov	ax, 0
	push	ax
	mov	ax, RC_WALK
	push	ax
	SERVICE		; Walk(0, 11, 171, 0)
	add	sp, 0Ah
	retf

H_1AB9:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_1B05
LookAtDoor:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N012
	call	Say
	jmp	SHORT L1B04

T_TUG2N012	LABEL	BYTE
	DB	'#TUG2\TUG2N012#This door leads back to the main corridor.',0
L1B04:
	retf

H_1B05:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_1B59
LookAtKirk:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N003
	call	Say
	jmp	SHORT L1B58

T_TUG2N003	LABEL	BYTE
	DB	'#TUG2\TUG2N003#Kirk seems concerned by what he sees in this room'
	DB	'.',0
L1B58:
	retf

H_1B59:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_1BE9
TalkToKirk:
	cmp	byte ptr [si+bomb], 6
	jne	L1B9B
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG2_001
	call	Say
	jmp	SHORT L1B9A

T_TUG2_001	LABEL	BYTE
	DB	'#TUG2\TUG2_001#My God, what have we done?',0
L1B9A:
	retf

L1B9B:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG2_002
	call	Say
	jmp	SHORT L1BE8

T_TUG2_002	LABEL	BYTE
	DB	'#TUG2\TUG2_002#They''ve turned this freighter into a prison barge'
	DB	'.',0
L1BE8:
	retf

H_1BE9:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_1C8D
TalkToMcCoy:
	cmp	byte ptr [si+bomb], 6
	jne	L1C4D
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG2_018
	call	Say
	jmp	SHORT L1C4C

T_TUG2_018	LABEL	BYTE
	DB	'#TUG2\TUG2_018#We came here to save these people, now look what '
	DB	'we''ve done!',0
L1C4C:
	retf

L1C4D:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG2_010
	call	Say
	jmp	SHORT L1C8C

T_TUG2_010	LABEL	BYTE
	DB	'#TUG2\TUG2_010#I don''t like the looks of this, Jim.',0
L1C8C:
	retf

H_1C8D:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_1D59
TalkToChristensen:
	cmp	byte ptr [si+bomb], 6
	jne	L1CF3
	mov	ax, OFFSET N_Lt_Christensen
	mov	bx, OFFSET T_TUG2L004
	call	Say
	jmp	SHORT L1CF2

T_TUG2L004	LABEL	BYTE
	DB	'#TUG2\TUG2L004#It''s my fault. They did the same thing on Damocle'
	DB	's Station... ',0
L1CF2:
	retf

L1CF3:
	mov	ax, OFFSET N_Lt_Christensen
	mov	bx, OFFSET T_TUG2J003
	call	Say
	jmp	SHORT L1D58

T_TUG2J003	LABEL	BYTE
	DB	'#TUG2\TUG2J003#I recommend extreme caution, Captain. We must be '
	DB	'ready to expect anything.',0
L1D58:
	retf

H_1D59:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_1DFC
TalkToSpock:
	cmp	byte ptr [si+bomb], 6
	jne	L1DA6
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG2_005
	call	Say
	jmp	SHORT L1DA5

T_TUG2_005	LABEL	BYTE
	DB	'#TUG2\TUG2_005#All of the crewmen are dead, Captain.',0
L1DA5:
	retf

L1DA6:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG2_020
	call	Say
	jmp	SHORT L1DFB

T_TUG2_020	LABEL	BYTE
	DB	'#TUG2\TUG2_020#I see that the Elasi live up to their reputation,'
	DB	' Captain.',0
L1DFB:
	retf

H_1DFC:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_1EC5
UseCommunicator:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG1_011
	call	Say
	JMPN	L1EA7

T_TUG1_011	LABEL	BYTE
	DB	'#TUG1\TUG1_011#I strongly recommend that we keep our silence, Ca'
	DB	'ptain. The Elasi are quite capable of tracing any communication '
	DB	'from within this vessel.',0
L1EA7:
	retf

; The guard still standing fires: guard 1 if both are.
PickShooter:
	cmp	byte ptr [si+guard2], 0
	jne	L1EB4
	mov	byte ptr cs:shooter, 9
L1EB4:
	cmp	byte ptr [si+guard1], 0
	jne	L1EC0
	mov	byte ptr cs:shooter, 8
L1EC0:
	ret

; In the room file, so these start again each time the room loads
shooter	LABEL	BYTE	; the guard firing, 8 or 9
	DB	0
target	LABEL	BYTE	; the crew member fired at, 0-3
	DB	0
killing	LABEL	BYTE	; the shot kills
	DB	0
killing2	LABEL	BYTE	; the same for the third round
	DB	0

; Timer 0, while a guard is up: the guards fire in rounds (guard_round)
; at Kirk, Christensen, McCoy, then Kirk or Spock again: stunning them,
; or killing them if `killing'. A dead Kirk (timer 2) ends the game.
H_1EC5:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_2046
GuardsFire:
	cmp	byte ptr [si+guard1], 0
	je	L1ED8
	cmp	byte ptr [si+guard2], 0
	je	L1ED8
	retf

L1ED8:
	mov	byte ptr cs:killing, 0
	cmp	byte ptr [si+used_kill], 1
	jne	L1EEA
	mov	byte ptr cs:killing, 1
L1EEA:
	cmp	byte ptr [si+guard_round], 0
	je	L1EF3
	JMPN	L1F7C

L1EF3:
	add	byte ptr [si+guard_round], 1
	cmp	byte ptr [si+guard2], 0
	je	L1EFE
	retf

L1EFE:
	cmp	byte ptr [si+guard2], 0
	jne	L1F7B
	jmp	SHORT L1F0D

N_wallht_2	LABEL	BYTE
	DB	'wallht',0
L1F0D:
	push	0
	push	0
	push	0
	push	OFFSET N_wallht_2
	push	0Dh
	push	RC_ANIM2
	SERVICE		; Anim(13, "wallht", 0, 0, 0)
	add	sp, 0Ch
	jmp	SHORT L1F2D

N_t2beem00	LABEL	BYTE
	DB	't2beem00',0
L1F2D:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem00
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem00", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L1F5A

N_p6fire	LABEL	BYTE
	DB	'p6fire',0
L1F5A:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p6fire
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p6fire", -1, -1, 0)
	add	sp, 0Ch
	mov	al, byte ptr cs:killing
	mov	byte ptr [si+wall_scorched], al
	mov	word ptr [si+RS_TIMERS], 3Ch
	retf

L1F7B:
	retf

L1F7C:
	cmp	byte ptr [si+guard_round], 1
	jne	L1F9D
	add	byte ptr [si+guard_round], 1
	cmp	byte ptr [si+redshirt_killed], 0
	jne	L1F9C
	call	PickShooter
	mov	byte ptr cs:target, 3
	mov	word ptr [si+RS_TIMERS], 3Ch
	JMPN	L2078

L1F9C:
	retf

L1F9D:
	cmp	byte ptr [si+guard_round], 2
	jne	L1FEA
	add	byte ptr [si+guard_round], 1
	mov	byte ptr cs:killing2, 0
	cmp	byte ptr [si+used_kill], 1
	jne	L1FB9
	mov	byte ptr cs:killing2, 1
L1FB9:
	cmp	byte ptr cs:killing2, 0
	jne	L1FD1
	call	PickShooter
	mov	byte ptr cs:target, 1
	mov	word ptr [si+RS_TIMERS], 3Ch
	JMPN	L2078

L1FD1:
	cmp	byte ptr cs:killing2, 1
	jne	L1FE9
	call	PickShooter
	mov	byte ptr cs:target, 0
	mov	word ptr [si+RS_TIMERS], 3Ch
	JMPN	L2078

L1FE9:
	retf

L1FEA:
	cmp	byte ptr [si+guard_round], 3
	jne	L200A
	add	byte ptr [si+guard_round], 1
	cmp	byte ptr [si+mccoy_killed], 0
	jne	L2009
	call	PickShooter
	mov	byte ptr cs:target, 2
	mov	word ptr [si+RS_TIMERS], 50h
	jmp	SHORT L2078

L2009:
	retf

L200A:
	cmp	byte ptr [si+guard_round], 4
	jne	L2045
	add	byte ptr [si+guard_round], 1
	cmp	byte ptr cs:killing2, 0
	jne	L202C
	call	PickShooter
	mov	byte ptr cs:target, 0
	mov	word ptr [si+RS_TIMERS+4], 28h
	jmp	SHORT L2078

L202C:
	cmp	byte ptr cs:killing2, 1
	jne	L2044
	call	PickShooter
	mov	byte ptr cs:target, 1
	mov	word ptr [si+RS_TIMERS+4], 28h
	jmp	SHORT L2078

L2044:
	retf

L2045:
	retf

H_2046:
	SCRIPT	MSG_TIMER, 2, 0, 0, H_29C7
GameOver:
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	mov	ax, 0
	mov	bx, OFFSET S_2061
	call	Say
	jmp	SHORT L2076

S_2061	LABEL	BYTE
	DB	'***Game over man!***',0
L2076:
	retf

	DB	0CBh
L2078:
	cmp	byte ptr cs:shooter, 8
	je	L2083
	JMPN	L2119

L2083:
	cmp	byte ptr cs:target, 0
	je	L208E
	JMPN	L2119

L208E:
	cmp	byte ptr cs:killing, 0
	je	L2099
	JMPN	L2119

L2099:
	mov	byte ptr [si+RS_FALL], 3
	jmp	SHORT L20A6

N_kstune	LABEL	BYTE
	DB	'kstune',0
L20A6:
	push	1Ah
	push	-1
	push	-1
	push	OFFSET N_kstune
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kstune", -1, -1, 26)
	add	sp, 0Ch
	jmp	SHORT L20C6

N_t2beem15	LABEL	BYTE
	DB	't2beem15',0
L20C6:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem15
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem15", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L20F3

N_p5fire	LABEL	BYTE
	DB	'p5fire',0
L20F3:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p5fire
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p5fire", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+kirk_killed], 0
	mov	byte ptr [si+RS_FALL], 3
	mov	word ptr [si+RS_STUN], 78h
	or	byte ptr [si+RS_FLAGS], 1
L2119:
	cmp	byte ptr cs:shooter, 9
	je	L2124
	JMPN	L21BA

L2124:
	cmp	byte ptr cs:target, 0
	je	L212F
	JMPN	L21BA

L212F:
	cmp	byte ptr cs:killing, 0
	je	L213A
	JMPN	L21BA

L213A:
	mov	byte ptr [si+RS_FALL], 3
	jmp	SHORT L2147

N_kstune_2	LABEL	BYTE
	DB	'kstune',0
L2147:
	push	1Ah
	push	-1
	push	-1
	push	OFFSET N_kstune_2
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kstune", -1, -1, 26)
	add	sp, 0Ch
	jmp	SHORT L2167

N_t2beem07	LABEL	BYTE
	DB	't2beem07',0
L2167:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem07
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem07", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L2194

N_p6fire_2	LABEL	BYTE
	DB	'p6fire',0
L2194:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p6fire_2
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p6fire", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+kirk_killed], 0
	mov	byte ptr [si+RS_FALL], 3
	mov	word ptr [si+RS_STUN], 78h
	or	byte ptr [si+RS_FLAGS], 1
L21BA:
	cmp	byte ptr cs:shooter, 8
	je	L21C5
	JMPN	L225B

L21C5:
	cmp	byte ptr cs:target, 1
	je	L21D0
	JMPN	L225B

L21D0:
	cmp	byte ptr cs:killing, 0
	je	L21DB
	JMPN	L225B

L21DB:
	mov	byte ptr [si+RS_FALL+1], 3
	jmp	SHORT L21E8

N_sstune	LABEL	BYTE
	DB	'sstune',0
L21E8:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sstune
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sstune", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L2208

N_t2beem14	LABEL	BYTE
	DB	't2beem14',0
L2208:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem14
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem14", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L2235

N_p5fire_2	LABEL	BYTE
	DB	'p5fire',0
L2235:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p5fire_2
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p5fire", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+spock_killed], 0
	mov	byte ptr [si+RS_FALL+1], 3
	mov	word ptr [si+RS_STUN+2], 78h
	or	byte ptr [si+RS_FLAGS], 2
L225B:
	cmp	byte ptr cs:shooter, 9
	je	L2266
	JMPN	L22FC

L2266:
	cmp	byte ptr cs:target, 1
	je	L2271
	JMPN	L22FC

L2271:
	cmp	byte ptr cs:killing, 0
	je	L227C
	JMPN	L22FC

L227C:
	mov	byte ptr [si+RS_FALL+1], 3
	jmp	SHORT L2289

N_sstune_2	LABEL	BYTE
	DB	'sstune',0
L2289:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sstune_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sstune", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L22A9

N_t2beem08	LABEL	BYTE
	DB	't2beem08',0
L22A9:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem08
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem08", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L22D6

N_p6fire_3	LABEL	BYTE
	DB	'p6fire',0
L22D6:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p6fire_3
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p6fire", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+spock_killed], 0
	mov	byte ptr [si+RS_FALL+1], 3
	mov	word ptr [si+RS_STUN+2], 78h
	or	byte ptr [si+RS_FLAGS], 2
L22FC:
	cmp	byte ptr cs:shooter, 8
	je	L2307
	JMPN	L239D

L2307:
	cmp	byte ptr cs:target, 2
	je	L2312
	JMPN	L239D

L2312:
	cmp	byte ptr cs:killing, 0
	je	L231D
	JMPN	L239D

L231D:
	mov	byte ptr [si+RS_FALL+2], 3
	jmp	SHORT L232A

N_mstune	LABEL	BYTE
	DB	'mstune',0
L232A:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mstune
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mstune", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L234A

N_t2beem17	LABEL	BYTE
	DB	't2beem17',0
L234A:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem17
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem17", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L2377

N_p5fire_3	LABEL	BYTE
	DB	'p5fire',0
L2377:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p5fire_3
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p5fire", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+mccoy_killed], 0
	mov	byte ptr [si+RS_FALL+2], 3
	mov	word ptr [si+RS_STUN+4], 78h
	or	byte ptr [si+RS_FLAGS], 4
L239D:
	cmp	byte ptr cs:shooter, 9
	je	L23A8
	JMPN	L243E

L23A8:
	cmp	byte ptr cs:target, 2
	je	L23B3
	JMPN	L243E

L23B3:
	cmp	byte ptr cs:killing, 0
	je	L23BE
	JMPN	L243E

L23BE:
	mov	byte ptr [si+RS_FALL+2], 3
	jmp	SHORT L23CB

N_mstune_2	LABEL	BYTE
	DB	'mstune',0
L23CB:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mstune_2
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mstune", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L23EB

N_t2beem09	LABEL	BYTE
	DB	't2beem09',0
L23EB:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem09
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem09", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L2418

N_p6fire_4	LABEL	BYTE
	DB	'p6fire',0
L2418:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p6fire_4
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p6fire", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+mccoy_killed], 0
	mov	byte ptr [si+RS_FALL+2], 3
	mov	word ptr [si+RS_STUN+4], 78h
	or	byte ptr [si+RS_FLAGS], 4
L243E:
	cmp	byte ptr cs:shooter, 8
	je	L2449
	JMPN	L24DF

L2449:
	cmp	byte ptr cs:target, 3
	je	L2454
	JMPN	L24DF

L2454:
	cmp	byte ptr cs:killing, 0
	je	L245F
	JMPN	L24DF

L245F:
	mov	byte ptr [si+RS_FALL+3], 3
	jmp	SHORT L246C

N_rstune	LABEL	BYTE
	DB	'rstune',0
L246C:
	push	0
	push	-1
	push	-1
	push	OFFSET N_rstune
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rstune", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L248C

N_t2beem16	LABEL	BYTE
	DB	't2beem16',0
L248C:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem16
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem16", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L24B9

N_p5fire_4	LABEL	BYTE
	DB	'p5fire',0
L24B9:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p5fire_4
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p5fire", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+redshirt_killed], 0
	mov	byte ptr [si+RS_FALL+3], 3
	mov	word ptr [si+RS_STUN+6], 78h
	or	byte ptr [si+RS_FLAGS], 8
L24DF:
	cmp	byte ptr cs:shooter, 9
	je	L24EA
	JMPN	L2580

L24EA:
	cmp	byte ptr cs:target, 3
	je	L24F5
	JMPN	L2580

L24F5:
	cmp	byte ptr cs:killing, 0
	je	L2500
	JMPN	L2580

L2500:
	mov	byte ptr [si+RS_FALL+3], 3
	jmp	SHORT L250D

N_rstune_2	LABEL	BYTE
	DB	'rstune',0
L250D:
	push	0
	push	-1
	push	-1
	push	OFFSET N_rstune_2
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rstune", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L252D

N_t2beem06	LABEL	BYTE
	DB	't2beem06',0
L252D:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem06
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem06", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L255A

N_p6fire_5	LABEL	BYTE
	DB	'p6fire',0
L255A:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p6fire_5
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p6fire", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+redshirt_killed], 0
	mov	byte ptr [si+RS_FALL+3], 3
	mov	word ptr [si+RS_STUN+6], 78h
	or	byte ptr [si+RS_FLAGS], 8
L2580:
	cmp	byte ptr cs:shooter, 8
	jne	L2607
	cmp	byte ptr cs:target, 0
	jne	L2607
	cmp	byte ptr cs:killing, 1
	jne	L2607
	jmp	SHORT L25A1

N_kKille	LABEL	BYTE
	DB	'kKille',0
L25A1:
	push	1Bh
	push	-1
	push	-1
	push	OFFSET N_kKille
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kKille", -1, -1, 27)
	add	sp, 0Ch
	jmp	SHORT L25C1

N_t2beem19	LABEL	BYTE
	DB	't2beem19',0
L25C1:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem19
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem19", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L25EE

N_p5fire_5	LABEL	BYTE
	DB	'p5fire',0
L25EE:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p5fire_5
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p5fire", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+kirk_killed], 1
L2607:
	cmp	byte ptr cs:shooter, 9
	jne	L268E
	cmp	byte ptr cs:target, 0
	jne	L268E
	cmp	byte ptr cs:killing, 1
	jne	L268E
	jmp	SHORT L2628

N_kKille_2	LABEL	BYTE
	DB	'kKille',0
L2628:
	push	1Bh
	push	-1
	push	-1
	push	OFFSET N_kKille_2
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kKille", -1, -1, 27)
	add	sp, 0Ch
	jmp	SHORT L2648

N_t2beem11	LABEL	BYTE
	DB	't2beem11',0
L2648:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem11
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem11", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L2675

N_p6fire_6	LABEL	BYTE
	DB	'p6fire',0
L2675:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p6fire_6
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p6fire", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+kirk_killed], 1
L268E:
	cmp	byte ptr cs:shooter, 8
	jne	L2715
	cmp	byte ptr cs:target, 1
	jne	L2715
	cmp	byte ptr cs:killing, 1
	jne	L2715
	jmp	SHORT L26AF

N_sKille	LABEL	BYTE
	DB	'sKille',0
L26AF:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sKille
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sKille", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L26CF

N_t2beem20	LABEL	BYTE
	DB	't2beem20',0
L26CF:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem20
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem20", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L26FC

N_p5fire_6	LABEL	BYTE
	DB	'p5fire',0
L26FC:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p5fire_6
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p5fire", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+spock_killed], 1
L2715:
	cmp	byte ptr cs:shooter, 9
	jne	L279C
	cmp	byte ptr cs:target, 1
	jne	L279C
	cmp	byte ptr cs:killing, 1
	jne	L279C
	jmp	SHORT L2736

N_sKille_2	LABEL	BYTE
	DB	'sKille',0
L2736:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sKille_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sKille", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L2756

N_t2beem12	LABEL	BYTE
	DB	't2beem12',0
L2756:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem12
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem12", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L2783

N_p6fire_7	LABEL	BYTE
	DB	'p6fire',0
L2783:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p6fire_7
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p6fire", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+spock_killed], 1
L279C:
	cmp	byte ptr cs:shooter, 8
	jne	L2823
	cmp	byte ptr cs:target, 2
	jne	L2823
	cmp	byte ptr cs:killing, 1
	jne	L2823
	jmp	SHORT L27BD

N_mKille	LABEL	BYTE
	DB	'mKille',0
L27BD:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mKille
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mKille", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L27DD

N_t2beem21	LABEL	BYTE
	DB	't2beem21',0
L27DD:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem21
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem21", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L280A

N_p5fire_7	LABEL	BYTE
	DB	'p5fire',0
L280A:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p5fire_7
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p5fire", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+mccoy_killed], 1
L2823:
	cmp	byte ptr cs:shooter, 9
	jne	L28AA
	cmp	byte ptr cs:target, 2
	jne	L28AA
	cmp	byte ptr cs:killing, 1
	jne	L28AA
	jmp	SHORT L2844

N_mKille_2	LABEL	BYTE
	DB	'mKille',0
L2844:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mKille_2
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mKille", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L2864

N_t2beem13	LABEL	BYTE
	DB	't2beem13',0
L2864:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem13
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem13", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L2891

N_p6fire_8	LABEL	BYTE
	DB	'p6fire',0
L2891:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p6fire_8
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p6fire", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+mccoy_killed], 1
L28AA:
	cmp	byte ptr cs:shooter, 8
	je	L28B5
	JMPN	L2938

L28B5:
	cmp	byte ptr cs:target, 3
	jne	L2938
	cmp	byte ptr cs:killing, 1
	jne	L2938
	jmp	SHORT L28CE

N_rKille	LABEL	BYTE
	DB	'rKille',0
L28CE:
	push	0
	push	-1
	push	-1
	push	OFFSET N_rKille
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rKille", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L28EE

N_t2beem18	LABEL	BYTE
	DB	't2beem18',0
L28EE:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem18
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem18", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L291B

N_p5fire_8	LABEL	BYTE
	DB	'p5fire',0
L291B:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p5fire_8
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p5fire", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+redshirt_killed], 1
	mov	byte ptr [si+RS_REDSHIRT_DEAD], 1
L2938:
	cmp	byte ptr cs:shooter, 9
	je	L2943
	JMPN	L29C6

L2943:
	cmp	byte ptr cs:target, 3
	jne	L29C6
	cmp	byte ptr cs:killing, 1
	jne	L29C6
	jmp	SHORT L295C

N_rKille_2	LABEL	BYTE
	DB	'rKille',0
L295C:
	push	0
	push	-1
	push	-1
	push	OFFSET N_rKille_2
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rKille", -1, -1, 0)
	add	sp, 0Ch
	jmp	SHORT L297C

N_t2beem10	LABEL	BYTE
	DB	't2beem10',0
L297C:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t2beem10
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t2beem10", 5)
	add	sp, 6
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L29A9

N_p6fire_9	LABEL	BYTE
	DB	'p6fire',0
L29A9:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p6fire_9
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p6fire", -1, -1, 0)
	add	sp, 0Ch
	mov	byte ptr [si+redshirt_killed], 1
	mov	byte ptr [si+RS_REDSHIRT_DEAD], 1
L29C6:
	retf

; Tricorders, talking to the guards, the medkit.
H_29C7:
	SCRIPT	MSG_USE, IT_STRICOR, 0Bh, 0, H_2AD8
SpockScansBomb:
	mov	byte ptr [si+RS_FALL+1], 2
	jmp	SHORT L29DA

N_sscane_2	LABEL	BYTE
	DB	'sscane',0
L29DA:
	push	0
	push	-1
	push	-1
	push	OFFSET N_sscane_2
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "sscane", -1, -1, 0)
	add	sp, 0Ch
	mov	ax, 4
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG2_004
	call	Say
	JMPN	L2AD7

T_TUG2_004	LABEL	BYTE
	DB	'#TUG2\TUG2_004#A medium strength phaser bomb. The brig force fie'
	DB	'ld would contain the explosion but it would kill the crew member'
	DB	's within the cell. I recommend that we find a way of disarming i'
	DB	't, Captain.',0
L2AD7:
	retf

H_2AD8:
	SCRIPT	MSG_USE, IT_MTRICOR, 8, 0, H_2BBF
McCoyScansGuard1:
	cmp	byte ptr [si+guard1], 1
	je	L2AE7
	JMPN	L2BBE

L2AE7:
	mov	byte ptr [si+RS_FALL+2], 2
	jmp	SHORT L2AF4

N_mscane	LABEL	BYTE
	DB	'mscane',0
L2AF4:
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
	mov	bx, OFFSET T_TUG2_016
	call	Say
	JMPN	L2BBE

T_TUG2_016	LABEL	BYTE
	DB	'#TUG2\TUG2_016#The pirates won''t wake for a while, but they are '
	DB	'going to be quite unhappy when they do. I recommend that we not '
	DB	'be here when they awake.',0
L2BBE:
	retf

H_2BBF:
	SCRIPT	MSG_USE, IT_MTRICOR, 9, 0, H_2C95
McCoyScansGuard2:
	cmp	byte ptr [si+guard2], 1
	je	L2BCE
	JMPN	L2C94

L2BCE:
	mov	byte ptr [si+RS_FALL+2], 2
	jmp	SHORT L2BDB

N_mscane_2	LABEL	BYTE
	DB	'mscane',0
L2BDB:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscane_2
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
	mov	bx, OFFSET S_2C0C
	call	Say
	JMPN	L2C94

S_2C0C	LABEL	BYTE
	DB	'The pirates won''t wake for awhile but they are going to be quite'
	DB	' unhappy when they do. I recommend that we aren''t here when they'
	DB	'. wake.',0
L2C94:
	retf

H_2C95:
	SCRIPT	MSG_TALK, 8, 0, 0, H_2D85
TalkToGuard1:
	cmp	byte ptr [si+guard1], 8
	je	L2CA4
	JMPN	L2D37

L2CA4:
	mov	ax, OFFSET N_Elasi_Guard
	mov	bx, OFFSET T_TUG2L086
	call	Say
	JMPN	L2D37

T_TUG2L086	LABEL	BYTE
	DB	'#TUG2\TUG2L086#You imperialist Federation scum!  We will never s'
	DB	'urrender! Cereth is a great man with a great vision.  I spit upo'
	DB	'n you.',0
L2D37:
	cmp	byte ptr [si+guard1], 1
	jne	L2D84
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG2_012
	call	Say
	jmp	SHORT L2D84

T_TUG2_012	LABEL	BYTE
	DB	'#TUG2\TUG2_012#I don''t think he is in any shape to respond.',0
L2D84:
	retf

H_2D85:
	SCRIPT	MSG_TALK, 9, 0, 0, H_2E75
TalkToGuard2:
	cmp	byte ptr [si+guard2], 8
	je	L2D94
	JMPN	L2E27

L2D94:
	mov	ax, OFFSET N_Elasi_Guard
	mov	bx, OFFSET T_TUG2L086_2
	call	Say
	JMPN	L2E27

T_TUG2L086_2	LABEL	BYTE
	DB	'#TUG2\TUG2L086#You imperialist Federation scum!  We will never s'
	DB	'urrender! Cereth is a great man with a great vision.  I spit upo'
	DB	'n you.',0
L2E27:
	cmp	byte ptr [si+guard2], 1
	jne	L2E74
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG2_013
	call	Say
	jmp	SHORT L2E74

T_TUG2_013	LABEL	BYTE
	DB	'#TUG2\TUG2_013#I don''t think he is in any shape to respond.',0
L2E74:
	retf

H_2E75:
	SCRIPT	MSG_USE, IT_MEDKIT, 0Bh, 0, H_2E7D
	jmp	SHORT MedkitOnWires

H_2E7D:
	SCRIPT	MSG_USE, IT_MEDKIT, 0Ch, 0, H_2ED3
MedkitOnWires:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG2_017
	call	Say
	jmp	SHORT L2ED2

T_TUG2_017	LABEL	BYTE
	DB	'#TUG2\TUG2_017#These aren''t the right tools for the right job, J'
	DB	'im.',0
L2ED2:
	retf

H_2ED3:
	SCRIPT	MSG_USE, IT_MEDKIT, 8, 0, H_2F36
MedkitOnGuard1:
	cmp	byte ptr [si+guard1], 1
	jne	L2F35
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG2_014
	call	Say
	jmp	SHORT L2F35

T_TUG2_014	LABEL	BYTE
	DB	'#TUG2\TUG2_014#I don''t think it would be a good idea to wake the'
	DB	'm up, Jim.',0
L2F35:
	retf

H_2F36:
	SCRIPT	MSG_USE, IT_MEDKIT, 9, 0, H_2F99
MedkitOnGuard2:
	cmp	byte ptr [si+guard2], 1
	jne	L2F98
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG2_014_2
	call	Say
	jmp	SHORT L2F98

T_TUG2_014_2	LABEL	BYTE
	DB	'#TUG2\TUG2_014#I don''t think it would be a good idea to wake the'
	DB	'm up, Jim.',0
L2F98:
	retf

; The room, depending on the guards, the bomb and the prisoners.
H_2F99:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_2FA1
	jmp	SHORT LookAtScene

H_2FA1:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_2FA9
	jmp	SHORT LookAtScene

H_2FA9:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_344E
LookAtScene:
	cmp	byte ptr [si+guard1], 2
	je	L2FB8
	JMPN	L307E

L2FB8:
	cmp	byte ptr [si+guard2], 2
	je	L2FC1
	JMPN	L307E

L2FC1:
	cmp	byte ptr [si+bomb], 6
	je	L2FCA
	JMPN	L307E

L2FCA:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N019
	call	Say
	JMPN	L307D

T_TUG2N019	LABEL	BYTE
	DB	'#TUG2\TUG2N019#You are in the brig of the Masada. The cell conta'
	DB	'ins the smoldering remains of nine crew members. The berets of t'
	DB	'wo dead Elasi guards litter the floor.',0
L307D:
	retf

L307E:
	cmp	byte ptr [si+guard1], 2
	je	L3087
	JMPN	L313D

L3087:
	cmp	byte ptr [si+guard2], 2
	je	L3090
	JMPN	L313D

L3090:
	cmp	byte ptr [si+crew_freed], 0
	je	L3099
	JMPN	L313D

L3099:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N017
	call	Say
	JMPN	L313C

T_TUG2N017	LABEL	BYTE
	DB	'#TUG2\TUG2N017#You are in the brig of the Masada. Nine of the cr'
	DB	'ew members are held in the cell. The berets of two dead Elasi gu'
	DB	'ards litter the floor.',0
L313C:
	retf

L313D:
	cmp	byte ptr [si+guard1], 1
	je	L3146
	JMPN	L31F9

L3146:
	cmp	byte ptr [si+guard2], 1
	je	L314F
	JMPN	L31F9

L314F:
	cmp	byte ptr [si+bomb], 6
	je	L3158
	JMPN	L31F9

L3158:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N020
	call	Say
	JMPN	L31F8

T_TUG2N020	LABEL	BYTE
	DB	'#TUG2\TUG2N020#You are in the brig of the Masada. The cell conta'
	DB	'ins the smoldering remains of nine crew members. Two Elasi guard'
	DB	's lie on the floor.',0
L31F8:
	retf

L31F9:
	cmp	byte ptr [si+guard1], 1
	je	L3202
	JMPN	L32A5

L3202:
	cmp	byte ptr [si+guard2], 1
	je	L320B
	JMPN	L32A5

L320B:
	cmp	byte ptr [si+crew_freed], 0
	je	L3214
	JMPN	L32A5

L3214:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N018
	call	Say
	JMPN	L32A4

T_TUG2N018	LABEL	BYTE
	DB	'#TUG2\TUG2N018#You are in the brig of the Masada. Nine of the cr'
	DB	'ew members are held in the cell. Two Elasi guards lie on the flo'
	DB	'or.',0
L32A4:
	retf

L32A5:
	cmp	byte ptr [si+guard1], 1
	je	L32AE
	JMPN	L3352

L32AE:
	cmp	byte ptr [si+guard2], 1
	je	L32B7
	JMPN	L3352

L32B7:
	cmp	byte ptr [si+crew_freed], 1
	je	L32C0
	JMPN	L3352

L32C0:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N021
	call	Say
	JMPN	L3351

T_TUG2N021	LABEL	BYTE
	DB	'#TUG2\TUG2N021#You are in the brig of the Masada. The cell is op'
	DB	'en freeing the nine crew members. Two Elasi guards lie on the fl'
	DB	'oor.',0
L3351:
	retf

L3352:
	cmp	byte ptr [si+guard1], 2
	je	L335B
	JMPN	L3410

L335B:
	cmp	byte ptr [si+guard2], 2
	je	L3364
	JMPN	L3410

L3364:
	cmp	byte ptr [si+crew_freed], 1
	je	L336D
	JMPN	L3410

L336D:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N022
	call	Say
	JMPN	L340F

T_TUG2N022	LABEL	BYTE
	DB	'#TUG2\TUG2N022#You are in the brig of the Masada. The cell is op'
	DB	'en freeing the nine crew members. The hats of two dead Elasi gua'
	DB	'rds litter the floor.',0
L340F:
	retf

L3410:
	mov	ax, 0
	mov	bx, OFFSET T_TUG2N023
	call	Say
	jmp	SHORT L344D

T_TUG2N023	LABEL	BYTE
	DB	'#TUG2\TUG2N023#You are in the brig of the Masada.',0
L344D:
	retf

; The prisoners.
H_344E:
	SCRIPT	MSG_TALK, 0Ah, 0, 0, H_355A
TalkToPrisoners:
	cmp	byte ptr [si+crew_freed], 1
	je	L345D
	JMPN	L34FD

L345D:
	cmp	byte ptr [si+talked_to_crew], 0
	je	L3466
	JMPN	L34FD

L3466:
	jmp	SHORT L346F

N_fld10d_3	LABEL	BYTE
	DB	'fld10d',0
L346F:
	push	0
	push	0
	push	0
	push	OFFSET N_fld10d_3
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "fld10d", 0, 0, 0)
	add	sp, 0Ch
	mov	ax, OFFSET N_Masada_Crewman
	mov	bx, OFFSET T_TUG2_026
	call	Say
	jmp	SHORT L34F9

T_TUG2_026	LABEL	BYTE
	DB	'#TUG2\TUG2_026#Thank you for freeing us. You''d better take the b'
	DB	'ridge before they suspect anything is up.',0
L34F9:
	mov	byte ptr [si+talked_to_crew], 1
L34FD:
	cmp	byte ptr [si+crew_freed], 1
	je	L3506
	JMPN	L36A4

L3506:
	cmp	byte ptr [si+talked_to_crew], 1
	je	L350F
	JMPN	L36A4

L350F:
	mov	ax, OFFSET N_Masada_Crewman
	mov	bx, OFFSET T_TUG2_027
	call	Say
	jmp	SHORT L3559

T_TUG2_027	LABEL	BYTE
	DB	'#TUG2\TUG2_027#You''d better hurry up or they''ll catch on, Sir!',0
L3559:
	retf

H_355A:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Ah, 0, H_374F
McCoyScansPrisoners:
	cmp	byte ptr [si+bomb], 6
	je	L3569
	JMPN	L36A4

L3569:
	mov	byte ptr [si+RS_FALL+2], 2
	jmp	SHORT L3576

N_mscane_3	LABEL	BYTE
	DB	'mscane',0
L3576:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscane_3
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
	mov	bx, OFFSET T_TUG2_019
	call	Say
	jmp	SHORT L35F2

T_TUG2_019	LABEL	BYTE
	DB	'#TUG2\TUG2_019#They''re all dead, Jim. What in God''s name were yo'
	DB	'u thinking?',0
L35F2:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG2_022
	call	Say
	JMPN	L36A3

T_TUG2_022	LABEL	BYTE
	DB	'#TUG2\TUG2_022#I believe that no diety had any bearing on this d'
	DB	'octor, but the Captain should have been more careful. Starfleet '
	DB	'will not be pleased by their deaths.',0
L36A3:
	retf

L36A4:
	cmp	byte ptr [si+crew_freed], 0
	je	L36AD
	JMPN	L374E

L36AD:
	mov	byte ptr [si+RS_FALL+2], 2
	jmp	SHORT L36BA

N_mscane_4	LABEL	BYTE
	DB	'mscane',0
L36BA:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscane_4
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
	mov	bx, OFFSET T_TUG2_015
	call	Say
	jmp	SHORT L374E

T_TUG2_015	LABEL	BYTE
	DB	'#TUG2\TUG2_015#The crew is tired and has elevated signs from ext'
	DB	'reme stress, but they will survive.',0
L374E:
	retf

H_374F:
	SCRIPT	MSG_USE, IT_MTRICOR, 22h, 0, H_3800
McCoyScansCell:
	cmp	byte ptr [si+crew_freed], 1
	je	L375E
	JMPN	L37FF

L375E:
	mov	byte ptr [si+RS_FALL+2], 2
	jmp	SHORT L376B

N_mscane_5	LABEL	BYTE
	DB	'mscane',0
L376B:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscane_5
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
	mov	bx, OFFSET T_TUG2_015_2
	call	Say
	jmp	SHORT L37FF

T_TUG2_015_2	LABEL	BYTE
	DB	'#TUG2\TUG2_015#The crew is tired and has elevated signs from ext'
	DB	'reme stress, but they will survive.',0
L37FF:
	retf

H_3800:
	SCRIPT	MSG_USE, IT_PHASERK, 0Ah, 0, H_385E
KillPrisoners:
	cmp	byte ptr [si+crew_freed], 1
	jne	L385D
	mov	ax, OFFSET N_Masada_Crewman
	mov	bx, OFFSET T_TUG2_025
	call	Say
	jmp	SHORT L385D

T_TUG2_025	LABEL	BYTE
	DB	'#TUG2\TUG2_025#I''m on your side, Sir!  There''s no need to fire a'
	DB	't me.',0
L385D:
	retf

H_385E:
	SCRIPT	MSG_USE, IT_PHASERS, 0Ah, 0, H_38B6
StunPrisoners:
	mov	ax, OFFSET N_Masada_Crewman
	mov	bx, OFFSET T_TUG2_025_2
	call	Say
	jmp	SHORT L38B5

T_TUG2_025_2	LABEL	BYTE
	DB	'#TUG2\TUG2_025#I''m on your side, Sir!  There''s no need to fire a'
	DB	't me.',0
L38B5:
	retf

; Phasers on anything else: nothing.
H_38B6:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_38BD
StunAnything:
	retf

H_38BD:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, rdf_scripts_end
KillAnything:
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
	DW	3, 4	; id, points
	DW	13,163, 35,165, 0,180, 0,167
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
	DW	0, 4	; id, points
	DW	71,149, 201,139, 201,150, 71,160
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	'brig',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Lt_Christensen	LABEL	BYTE
	DB	'Lt. Christensen',0
N_Elasi_Guard	LABEL	BYTE
	DB	'Elasi Guard',0
N_Masada_Crewman	LABEL	BYTE
	DB	'Masada Crewman',0
	DB	'#TUG2\TUG2N002#Kirk falls to the floor stunned.',0
	DB	'#TUG2\TUG2J000#Ouch! That hurt!',0
	DB	'#TUG2\TUG2J001#Don''t you know any better?',0
	DB	'#TUG2\TUG2J002#What kind of idiot are you?',0
T_TUG2N025	LABEL	BYTE
	DB	23h, 54h, 55h, 47h, 32h, 5Ch, 54h, 55h, 47h, 32h, 4Eh, 30h
	DB	32h, 35h, 23h, 59h, 6Fh, 75h, 20h, 68h, 61h, 76h, 65h, 20h
	DB	62h, 65h, 65h, 6Eh, 20h, 74h, 61h, 6Bh, 65h, 6Eh, 20h, 63h
	DB	61h, 70h, 74h, 69h, 76h, 65h, 20h, 62h, 79h, 20h, 45h, 6Ch
	DB	61h, 73h, 69h, 20h, 43h, 65h, 72h, 65h, 74h, 68h, 2Ch, 20h
	DB	61h, 6Eh, 64h, 20h, 79h, 6Fh, 75h, 20h, 6Bh, 6Eh, 6Fh, 77h
	DB	20h, 53h, 74h, 61h, 72h, 66h, 6Ch, 65h, 65h, 74h, 20h, 64h
	DB	6Fh, 65h, 73h, 20h, 6Eh, 6Fh, 74h, 20h, 6Eh, 65h, 67h, 6Fh
	DB	74h, 69h, 61h, 74h, 65h, 20h, 77h, 69h, 74h, 68h, 20h, 74h
	DB	65h, 72h, 72h, 6Fh, 72h, 69h, 73h, 74h, 73h, 2Eh, 20h, 41h
	DB	73h, 20h, 79h, 6Fh, 75h, 20h, 6Ch, 6Fh, 6Fh, 6Bh, 20h, 66h
	DB	6Fh, 72h, 77h, 61h, 72h, 64h, 20h, 74h, 6Fh, 20h, 61h, 20h
	DB	6Ch, 6Fh, 6Eh, 67h, 20h, 63h, 61h, 70h, 74h, 69h, 76h, 69h
	DB	74h, 79h, 2Ch, 20h, 79h, 6Fh, 75h, 20h, 77h, 6Fh, 6Eh, 64h
	DB	65h, 72h, 20h, 77h, 68h, 6Fh, 20h, 77h, 69h, 6Ch, 6Ch, 20h
	DB	74h, 61h, 6Bh, 65h, 20h, 6Fh, 76h, 65h, 72h, 20h, 63h, 6Fh
	DB	6Dh, 6Dh, 61h, 6Eh, 64h, 20h, 6Fh, 66h, 20h, 74h, 68h, 65h
	DB	20h, 45h, 6Eh, 74h, 65h, 72h, 70h, 72h, 69h, 73h, 65h, 2Eh
	DB	20h, 42h, 65h, 74h, 74h, 65h, 72h, 20h, 6Ch, 75h, 63h, 6Bh
	DB	20h, 6Eh, 65h, 78h, 74h, 20h, 74h, 69h, 6Dh, 65h, 2Eh
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
