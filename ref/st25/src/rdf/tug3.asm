; TUG3.RDF - "Hijacked", the Masada's bridge: Elasi Cereth and three
; clansmen. The party arrives by transporter (room 0) or the door (room
; 1). The first shot starts the fight: the clansmen draw and fire (timer
; 0), killing a crew member each time, Christensen first. Stunning or
; killing them (killing costs points) ends it, and the rest surrender.
; Talking to Cereth first can win his surrender (+8), or he plays a
; "gambit": he shoots the helm, and the Masada's orbit decays (timer 1).
; Calling Sulu in time stabilizes it; too late, the party can only beam
; out. With every Elasi down, Kirk calls for a security team and the
; mission ends. If a brig guard (room 2) is still up when the fight
; starts, the alarm has gone out and the score is lost.
;
; Actors: 8 Cereth, 9-11 (0Bh) the clansmen, 12 (0Ch) sparks, 13-15
; (0Fh) the security team.
; Timers: 0 the clansmen fire, 1 the orbit decays.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
score	EQU	RS_VARS+0	; word: the mission's score
max_score	EQU	RS_VARS+2	; word: for the debriefing
outcome	EQU	RS_VARS+4	; word: BeamUp's outcome
orbit_decay	EQU	RS_VARS+12h	; ticks of timer 1: 0Ah a warning, 10h too late
fight_started	EQU	RS_VARS+14h
talked_to_cereth	EQU	RS_VARS+15h
guard1	EQU	RS_VARS+23h	; brig guard 1 (room 2): 0 up
guard2	EQU	RS_VARS+24h	; brig guard 2 (room 2): 0 up
kirk_killed	EQU	RS_VARS+26h	; 1 in the brig (room 2), 2 here
spock_killed	EQU	RS_VARS+27h
mccoy_killed	EQU	RS_VARS+28h
redshirt_killed	EQU	RS_VARS+29h
cereth	EQU	RS_VARS+2Ah	; 0 up, 1 stunned, 2 killed, 4 surrendered
elasi2	EQU	RS_VARS+2Bh	; as cereth
elasi3	EQU	RS_VARS+2Ch
elasi4	EQU	RS_VARS+2Dh
surrendered	EQU	RS_VARS+33h	; the Elasi have surrendered
cereth_talk	EQU	RS_VARS+35h	; 1 security called, 2 Cereth gave in, 3 after his gambit

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	0BEh	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	60h
rdf_scale_min	LABEL	BYTE
	DW	0B4h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	0F0h
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
	DW	164,118, 164,119	; entrance 1, crew 0
	DW	192,107, 192,108	; entrance 1, crew 1
	DW	175,99, 175,100	; entrance 1, crew 2
	DW	140,117, 140,119	; entrance 1, crew 3
	DW	0,0, 0,0	; entrance 2, crew 0
	DW	0,0, 0,0	; entrance 2, crew 1
	DW	0,0, 0,0	; entrance 2, crew 2
	DW	0,0, 0,0	; entrance 2, crew 3
	DW	0,0, 0,0	; entrance 3, crew 0
	DW	0,0, 0,0	; entrance 3, crew 1
	DW	0,0, 0,0	; entrance 3, crew 2
	DW	0,0, 0,0	; entrance 3, crew 3
rdf_beam_pos	LABEL	BYTE
	DW	164,119, 192,108, 175,100, 140,119	; beaming in
rdf_stand_pos	LABEL	BYTE
	DW	0,0, 0,0, 0,0, 0,0

rdf_scripts:
; The room starts: the Elasi turn to face the party, who can't walk.
H_00CA:
	SCRIPT	MSG_TICK, 1, 0, 0, H_016E
StartRoom:
	jmp	SHORT L00DB

N_TUG3LOOP	LABEL	BYTE
	DB	'TUG3LOOP',0
L00DB:
	push	OFFSET N_TUG3LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("TUG3LOOP")
	add	sp, 4
	mov	byte ptr [si+RS_NO_WALK], 1
	jmp	SHORT L00F7

N_p1turn	LABEL	BYTE
	DB	'p1turn',0
L00F7:
	push	0
	push	98h
	push	0A4h
	push	OFFSET N_p1turn
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p1turn", 164, 152, 0)
	add	sp, 0Ch
	jmp	SHORT L0117

N_p2turn	LABEL	BYTE
	DB	'p2turn',0
L0117:
	push	0
	push	88h
	push	0D1h
	push	OFFSET N_p2turn
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p2turn", 209, 136, 0)
	add	sp, 0Ch
	jmp	SHORT L0137

N_p3turn	LABEL	BYTE
	DB	'p3turn',0
L0137:
	push	0
	push	0C4h
	push	0FBh
	push	OFFSET N_p3turn
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "p3turn", 251, 196, 0)
	add	sp, 0Ch
	jmp	SHORT L0157

N_p4turn	LABEL	BYTE
	DB	'p4turn',0
L0157:
	push	0
	push	9Eh
	push	5Ah
	push	OFFSET N_p4turn
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "p4turn", 90, 158, 0)
	add	sp, 0Ch
	retf

; Tick 40: Kirk draws.
H_016E:
	SCRIPT	MSG_TICK, 28h, 0, 0, H_0193
KirkDraws:
	jmp	SHORT L017D

N_kdraws	LABEL	BYTE
	DB	'kdraws',0
L017D:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kdraws
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kdraws", -1, -1, 0)
	add	sp, 0Ch
	retf

H_0193:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_0406
LookAtScene:
	mov	ax, 0
	mov	bx, OFFSET T_TUG3N007
	call	Say
	JMPN	L0235

T_TUG3N007	LABEL	BYTE
	DB	'#TUG3\TUG3N007#This is a standard Starfleet bridge, perhaps not '
	DB	'as impressive as the one on the Enterprise. There are quite a fe'
	DB	'w pirates here.',0
L0235:
	retf

; The Elasi still standing surrender, +4 score (near call).
ElasiSurrender:
	cmp	byte ptr [si+fight_started], 1
	jne	L023D
	ret

L023D:
	mov	byte ptr [si+surrendered], 1
	jmp	SHORT L024A

N_p1surr	LABEL	BYTE
	DB	'p1surr',0
L024A:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p1surr
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p1surr", -1, -1, 0)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+cereth], 4
	cmp	byte ptr [si+elasi2], 0
	jne	L0295
	jmp	SHORT L0277

N_p2surr	LABEL	BYTE
	DB	'p2surr',0
L0277:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p2surr
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p2surr", -1, -1, 0)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+elasi2], 4
L0295:
	cmp	byte ptr [si+elasi3], 0
	jne	L02C2
	jmp	SHORT L02A4

N_p3surr	LABEL	BYTE
	DB	'p3surr',0
L02A4:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p3surr
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "p3surr", -1, -1, 0)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+elasi3], 4
L02C2:
	cmp	byte ptr [si+elasi4], 0
	jne	L02EF
	jmp	SHORT L02D1

N_p4surr	LABEL	BYTE
	DB	'p4surr',0
L02D1:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p4surr
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "p4surr", -1, -1, 0)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+elasi4], 4
L02EF:
	add	word ptr [si+score], 4
	ret

; The fight starts, once: if a brig guard is still up he has raised the
; alarm, score 0. Timer 0, and the Elasi still up draw.
FightStarts:
	cmp	byte ptr [si+fight_started], 1
	jne	L02FB
	ret

L02FB:
	mov	byte ptr [si+fight_started], 1
	cmp	byte ptr [si+guard1], 0
	je	L030D
	cmp	byte ptr [si+guard2], 0
	je	L030D
	jmp	SHORT L0353

L030D:
	mov	ax, OFFSET N_Elasi_Clansman
	mov	bx, OFFSET T_TUG3L081
	call	Say
	jmp	SHORT L034A

T_TUG3L081	LABEL	BYTE
	DB	'#TUG3\TUG3L081#Bridge to brig, kill the hostages!',0
L034A:
	add	word ptr [si+score], 0
	mov	word ptr [si+score], 0
L0353:
	mov	si, word ptr cs:rdf_state
	cmp	word ptr [si+RS_TIMERS], 0
	jne	L0361
	mov	word ptr [si+RS_TIMERS], 0Ah
L0361:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+cereth], 0
	jne	L038A
	jmp	SHORT L0375

N_p1draw	LABEL	BYTE
	DB	'p1draw',0
L0375:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p1draw
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p1draw", -1, -1, 0)
	add	sp, 0Ch
L038A:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+elasi2], 0
	jne	L03B3
	jmp	SHORT L039E

N_p2draw	LABEL	BYTE
	DB	'p2draw',0
L039E:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p2draw
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p2draw", -1, -1, 0)
	add	sp, 0Ch
L03B3:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+elasi3], 0
	jne	L03DC
	jmp	SHORT L03C7

N_p3draw	LABEL	BYTE
	DB	'p3draw',0
L03C7:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p3draw
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "p3draw", -1, -1, 0)
	add	sp, 0Ch
L03DC:
	mov	si, word ptr cs:rdf_state
	cmp	byte ptr [si+elasi4], 0
	jne	L0405
	jmp	SHORT L03F0

N_p4draw	LABEL	BYTE
	DB	'p4draw',0
L03F0:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p4draw
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "p4draw", -1, -1, 0)
	add	sp, 0Ch
L0405:
	ret

; Phasers on anything else: nothing.
H_0406:
	SCRIPT	MSG_USE, IT_PHASERS, ANY, 0, H_040D
StunAnything:
	retf

H_040D:
	SCRIPT	MSG_USE, IT_PHASERK, ANY, 0, H_0414
KillAnything:
	retf

; Phasers on the Elasi, while Kirk is alive: stun, or kill (-2 score
; each). The first shot starts the fight (msg 12 when done).
H_0414:
	SCRIPT	MSG_USE, IT_PHASERS, 8, 0, H_0486
StunCereth:
	cmp	byte ptr [si+kirk_killed], 0
	je	L0423
	JMPN	L064B

L0423:
	cmp	byte ptr [si+cereth], 0
	je	L042C
	JMPN	L064B

L042C:
	jmp	SHORT L0435

N_p1stun	LABEL	BYTE
	DB	'p1stun',0
L0435:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_p1stun
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p1stun", -1, -1, 12)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0465

N_t3beem05	LABEL	BYTE
	DB	't3beem05',0
L0465:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t3beem05
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t3beem05", 5)
	add	sp, 6
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+cereth], 1
	call	FightStarts
	retf

H_0486:
	SCRIPT	MSG_USE, IT_PHASERS, 9, 0, H_04F8
StunElasi2:
	cmp	byte ptr [si+kirk_killed], 0
	je	L0495
	JMPN	L064B

L0495:
	cmp	byte ptr [si+elasi2], 0
	je	L049E
	JMPN	L064B

L049E:
	jmp	SHORT L04A7

N_p2stun	LABEL	BYTE
	DB	'p2stun',0
L04A7:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_p2stun
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p2stun", -1, -1, 12)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L04D7

N_t3beem06	LABEL	BYTE
	DB	't3beem06',0
L04D7:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t3beem06
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t3beem06", 5)
	add	sp, 6
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+elasi2], 1
	call	FightStarts
	retf

H_04F8:
	SCRIPT	MSG_USE, IT_PHASERS, 0Ah, 0, H_056A
StunElasi3:
	cmp	byte ptr [si+kirk_killed], 0
	je	L0507
	JMPN	L064B

L0507:
	cmp	byte ptr [si+elasi3], 0
	je	L0510
	JMPN	L064B

L0510:
	jmp	SHORT L0519

N_p3stun	LABEL	BYTE
	DB	'p3stun',0
L0519:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_p3stun
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "p3stun", -1, -1, 12)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0549

N_t3beem07	LABEL	BYTE
	DB	't3beem07',0
L0549:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t3beem07
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t3beem07", 5)
	add	sp, 6
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+elasi3], 1
	call	FightStarts
	retf

H_056A:
	SCRIPT	MSG_USE, IT_PHASERS, 0Bh, 0, H_05DC
StunElasi4:
	cmp	byte ptr [si+kirk_killed], 0
	je	L0579
	JMPN	L064B

L0579:
	cmp	byte ptr [si+elasi4], 0
	je	L0582
	JMPN	L064B

L0582:
	jmp	SHORT L058B

N_p4stun	LABEL	BYTE
	DB	'p4stun',0
L058B:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_p4stun
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "p4stun", -1, -1, 12)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L05BB

N_t3beem04	LABEL	BYTE
	DB	't3beem04',0
L05BB:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t3beem04
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t3beem04", 5)
	add	sp, 6
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+elasi4], 1
	call	FightStarts
	retf

H_05DC:
	SCRIPT	MSG_USE, IT_PHASERK, 8, 0, H_064C
KillCereth:
	cmp	byte ptr [si+kirk_killed], 0
	jne	L064B
	cmp	byte ptr [si+cereth], 0
	jne	L064B
	jmp	SHORT L05F7

N_p1Kill	LABEL	BYTE
	DB	'p1Kill',0
L05F7:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_p1Kill
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p1Kill", -1, -1, 12)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0627

N_t3beem25	LABEL	BYTE
	DB	't3beem25',0
L0627:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t3beem25
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t3beem25", 5)
	add	sp, 6
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+cereth], 2
	add	word ptr [si+score], -2
	call	FightStarts
L064B:
	retf

H_064C:
	SCRIPT	MSG_USE, IT_PHASERK, 9, 0, H_06BC
KillElasi2:
	cmp	byte ptr [si+kirk_killed], 0
	jne	L06BB
	cmp	byte ptr [si+elasi2], 0
	jne	L06BB
	jmp	SHORT L0667

N_p2Kill	LABEL	BYTE
	DB	'p2Kill',0
L0667:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_p2Kill
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "p2Kill", -1, -1, 12)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0697

N_t3beem27	LABEL	BYTE
	DB	't3beem27',0
L0697:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t3beem27
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t3beem27", 5)
	add	sp, 6
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+elasi2], 2
	add	word ptr [si+score], -2
	call	FightStarts
L06BB:
	retf

H_06BC:
	SCRIPT	MSG_USE, IT_PHASERK, 0Ah, 0, H_072C
KillElasi3:
	cmp	byte ptr [si+kirk_killed], 0
	jne	L072B
	cmp	byte ptr [si+elasi3], 0
	jne	L072B
	jmp	SHORT L06D7

N_p3Kill	LABEL	BYTE
	DB	'p3Kill',0
L06D7:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_p3Kill
	push	0Ah
	push	RC_ANIM2
	SERVICE		; Anim(10, "p3Kill", -1, -1, 12)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0707

N_t3beem26	LABEL	BYTE
	DB	't3beem26',0
L0707:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t3beem26
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t3beem26", 5)
	add	sp, 6
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+elasi3], 2
	add	word ptr [si+score], -2
	call	FightStarts
L072B:
	retf

H_072C:
	SCRIPT	MSG_USE, IT_PHASERK, 0Bh, 0, H_079C
KillElasi4:
	cmp	byte ptr [si+kirk_killed], 0
	jne	L079B
	cmp	byte ptr [si+elasi4], 0
	jne	L079B
	jmp	SHORT L0747

N_p4Kill	LABEL	BYTE
	DB	'p4Kill',0
L0747:
	push	0Ch
	push	-1
	push	-1
	push	OFFSET N_p4Kill
	push	0Bh
	push	RC_ANIM2
	SERVICE		; Anim(11, "p4Kill", -1, -1, 12)
	add	sp, 0Ch
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0777

N_t3beem24	LABEL	BYTE
	DB	't3beem24',0
L0777:
	mov	ax, 5
	push	ax
	mov	ax, OFFSET N_t3beem24
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t3beem24", 5)
	add	sp, 6
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+elasi4], 2
	add	word ptr [si+score], -2
	call	FightStarts
L079B:
	retf

; An Elasi is down: once none is standing, call security.
H_079C:
	SCRIPT	MSG_ANIM_DONE, 0Ch, 0, 0, H_07C8
ElasiHit:
	cmp	byte ptr [si+cereth_talk], 1
	je	L07C7
	cmp	byte ptr [si+cereth], 0
	je	L07C7
	cmp	byte ptr [si+elasi2], 0
	je	L07C7
	cmp	byte ptr [si+elasi3], 0
	je	L07C7
	cmp	byte ptr [si+elasi4], 0
	je	L07C7
	mov	byte ptr [si+cereth_talk], 1
	JMPN	CallSecurity

L07C7:
	retf

; Talking to Cereth, once, before the fight: a choice (+8 and surrender),
; or his gambit: he shoots the helm (msgs 3-6) and the orbit decays.
H_07C8:
	SCRIPT	MSG_TALK, 8, 0, 0, H_091F
TalkToCereth:
	cmp	byte ptr [si+cereth], 0
	je	L07D5
	retf

L07D5:
	cmp	byte ptr [si+talked_to_cereth], 1
	jne	L07DC
	retf

L07DC:
	mov	byte ptr [si+talked_to_cereth], 1
	mov	ax, OFFSET KirkToCereth
	call	Talk
	AX8	cmp, 0
	jne	L07ED
	jmp	SHORT L07FE

L07ED:
	AX8	cmp, 1
	jne	L07F5
	JMPN	L08A1

L07F5:
	AX8	cmp, 2
	jne	L07FD
	JMPN	L09A1

L07FD:
	retf

L07FE:
	mov	ax, OFFSET N_Elasi_Cereth
	mov	bx, OFFSET T_TUG3L084
	call	Say
	jmp	SHORT L085D

T_TUG3L084	LABEL	BYTE
	DB	'#TUG3\TUG3L084#You are an honorable and worthy opponent, Kirk. I'
	DB	' accept your offer.',0
L085D:
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+cereth], 4
	mov	si, word ptr cs:rdf_state
	jmp	SHORT L0874

N_p1surr_2	LABEL	BYTE
	DB	'p1surr',0
L0874:
	push	0
	push	-1
	push	-1
	push	OFFSET N_p1surr_2
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p1surr", -1, -1, 0)
	add	sp, 0Ch
	mov	si, word ptr cs:rdf_state
	mov	byte ptr [si+cereth], 4
	call	ElasiSurrender
	mov	byte ptr [si+cereth_talk], 2
	add	word ptr [si+score], 8
	JMPN	CallSecurity

	DB	0CBh
L08A1:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, OFFSET N_Elasi_Cereth
	mov	bx, OFFSET T_TUG3_F27
	call	Say
	jmp	SHORT L0900

T_TUG3_F27	LABEL	BYTE
	DB	'#TUG3\TUG3_F27#Foolhardy words, Kirk. You have underestimated me'
	DB	' at every turn.',0
L0900:
	jmp	SHORT L0909

N_p1draw_2	LABEL	BYTE
	DB	'p1draw',0
L0909:
	push	3
	push	-1
	push	-1
	push	OFFSET N_p1draw_2
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p1draw", -1, -1, 3)
	add	sp, 0Ch
	retf

H_091F:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_0985
GambitShot:
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0940

N_t3beem41	LABEL	BYTE
	DB	't3beem41',0
L0940:
	mov	ax, 0Dh
	push	ax
	mov	ax, OFFSET N_t3beem41
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t3beem41", 13)
	add	sp, 6
	mov	ax, 16h
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(22)
	add	sp, 4
	jmp	SHORT L096D

N_sparks	LABEL	BYTE
	DB	'sparks',0
L096D:
	push	4
	push	0ADh
	push	0A0h
	push	OFFSET N_sparks
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "sparks", 160, 173, 4)
	add	sp, 0Ch
	retf

H_0985:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_0A0C
HelmHit:
	call	FightStarts
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr [si+cereth_talk], 3
	mov	si, word ptr cs:rdf_state
	mov	word ptr [si+RS_TIMERS+2], 0Ah
	retf

L09A1:
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, OFFSET N_Elasi_Cereth
	mov	bx, OFFSET T_TUG3L083
	call	Say
	jmp	SHORT L09ED

T_TUG3L083	LABEL	BYTE
	DB	'#TUG3\TUG3L083#I still have a gambit or two left, my friend.',0
L09ED:
	jmp	SHORT L09F6

N_p1draw_3	LABEL	BYTE
	DB	'p1draw',0
L09F6:
	push	5
	push	-1
	push	-1
	push	OFFSET N_p1draw_3
	push	8
	push	RC_ANIM2
	SERVICE		; Anim(8, "p1draw", -1, -1, 5)
	add	sp, 0Ch
	retf

H_0A0C:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_0A7C
GambitShot2:
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	jmp	SHORT L0A2D

N_t3beem41_2	LABEL	BYTE
	DB	't3beem41',0
L0A2D:
	mov	ax, 0Dh
	push	ax
	mov	ax, OFFSET N_t3beem41_2
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap("t3beem41", 13)
	add	sp, 6
	jmp	SHORT L0A4A

N_sparks_2	LABEL	BYTE
	DB	'sparks',0
L0A4A:
	push	6
	push	0ADh
	push	0A0h
	push	OFFSET N_sparks_2
	push	0Ch
	push	RC_ANIM2
	SERVICE		; Anim(12, "sparks", 160, 173, 6)
	add	sp, 0Ch
	jmp	SHORT L0A6C

N_SHOOTCON	LABEL	BYTE
	DB	'SHOOTCON',0
L0A6C:
	push	OFFSET N_SHOOTCON
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SHOOTCON")
	add	sp, 4
	retf

H_0A7C:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_0AE7
HelmHit2:
	mov	ax, OFFSET N_Elasi_Cereth
	mov	bx, OFFSET T_TUG3L080
	call	Say
	jmp	SHORT L0AD1

T_TUG3L080	LABEL	BYTE
	DB	'#TUG3\TUG3L080#A blow struck for freedom, Captain. Now I surrend'
	DB	'er.',0
L0AD1:
	call	ElasiSurrender
	mov	byte ptr [si+RS_BUSY], 0
	mov	byte ptr [si+cereth_talk], 3
	mov	si, word ptr cs:rdf_state
	mov	word ptr [si+RS_TIMERS+2], 0Ah
	retf

; Nothing.
H_0AE7:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_0AEE
AnimDone1:
	retf

; Looking. A dead Elasi first, else (RS_MORE) the next script.
H_0AEE:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_0AFD
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_TUG3N000
	call	Say
	retf

H_0AFD:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_0B0C
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_TUG3N002
	call	Say
	retf

H_0B0C:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_0B5B
LookAtRedshirt:
	mov	ax, 0
	mov	bx, OFFSET T_TUG3N001
	call	Say
	jmp	SHORT L0B5A

T_TUG3N001	LABEL	BYTE
	DB	'#TUG3\TUG3N001#Lt. Christensen is carefully observing Elasi.',0
L0B5A:
	retf

H_0B5B:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_0B69
LookAtCerethDead:
	cmp	byte ptr [si+cereth], 2
	je	L0B9B
	jmp	SHORT L0B91

H_0B69:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_0B77
LookAtElasi2:
	cmp	byte ptr [si+elasi2], 2
	je	L0B9B
	jmp	SHORT L0B91

H_0B77:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_0B85
LookAtElasi3:
	cmp	byte ptr [si+elasi3], 2
	je	L0B9B
	jmp	SHORT L0B91

H_0B85:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_0BA5
LookAtElasi4:
	cmp	byte ptr [si+elasi4], 2
	je	L0B9B
L0B91:
	mov	ax, OFFSET S_15AA
	mov	bx, OFFSET T_TUG3N005
	call	Say
	retf

L0B9B:
	mov	ax, OFFSET S_15AA
	mov	bx, OFFSET T_TUG3N004
	call	Say
	retf

H_0BA5:
	SCRIPT	MSG_LOOK, 8, 0, 0, H_0BC5
LookAtCereth:
	cmp	byte ptr [si+cereth], 1
	je	L0BBB
	mov	ax, OFFSET S_15AA
	mov	bx, OFFSET T_TUG3N008
	call	Say
	retf

L0BBB:
	mov	ax, OFFSET S_15AA
	mov	bx, OFFSET T_TUG3N003
	call	Say
	retf

; Talking, depending on the orbit.
H_0BC5:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_0C81
TalkToMcCoy:
	cmp	byte ptr [si+orbit_decay], 0
	jne	L0C08
	cmp	byte ptr [si+cereth], 0
	jne	L0C08
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG3_013
	call	Say
	jmp	SHORT L0C07

T_TUG3_013	LABEL	BYTE
	DB	'#TUG3\TUG3_013#Jim, that man is mad.',0
L0C07:
	retf

L0C08:
	cmp	byte ptr [si+orbit_decay], 0Ah
	jge	L0C1C
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET S_0C19
	call	Say
	jmp	SHORT L0C1B

S_0C19	LABEL	BYTE
	DB	'#',0
L0C1B:
	retf

L0C1C:
	cmp	byte ptr [si+orbit_decay], 10h
	jge	L0C80
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_TUG3_011
	call	Say
	jmp	SHORT L0C7F

T_TUG3_011	LABEL	BYTE
	DB	'#TUG3\TUG3_011#I think we should return to the Enterprise before'
	DB	' we burn up, Jim.',0
L0C7F:
	retf

L0C80:
	retf

H_0C81:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_0D7D
TalkToSpock:
	cmp	byte ptr [si+orbit_decay], 0
	jne	L0C8E
	retf

L0C8E:
	cmp	byte ptr [si+orbit_decay], 0Ah
	jge	L0D04
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG3_009
	call	Say
	jmp	SHORT L0D03

T_TUG3_009	LABEL	BYTE
	DB	'#TUG3\TUG3_009#Captain, I recommend that Mr. Sulu stabilize the '
	DB	'Masada''s orbit from the Enterprise.',0
L0D03:
	retf

L0D04:
	cmp	byte ptr [si+orbit_decay], 10h
	jge	L0D7C
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_TUG3_008
	call	Say
	jmp	SHORT L0D7B

T_TUG3_008	LABEL	BYTE
	DB	'#TUG3\TUG3_008#Captain, I highly recommend returning to the Ente'
	DB	'rprise within the next 57.32 seconds.',0
L0D7B:
	retf

L0D7C:
	retf

H_0D7D:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_0DC0
TalkToRedshirt:
	mov	ax, OFFSET N_Lt_Christensen
	mov	bx, OFFSET T_TUG3L003
	call	Say
	jmp	SHORT L0DBF

T_TUG3L003	LABEL	BYTE
	DB	'#TUG3\TUG3L003#I''m just a security officer, sir.',0
L0DBF:
	retf

; The communicator while the orbit decays: Sulu stabilizes it; once it
; is too late, Scott beams the party out (score 0).
H_0DC0:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_0FF8
CallForHelp:
	cmp	byte ptr [si+orbit_decay], 0
	jne	L0DCD
	retf

L0DCD:
	cmp	byte ptr [si+orbit_decay], 0Ah
	jl	L0DD6
	JMPN	L0ECE

L0DD6:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG3_007
	call	Say
	jmp	SHORT L0E17

T_TUG3_007	LABEL	BYTE
	DB	'#TUG3\TUG3_007#Mr. Sulu, we need some help over here.',0
L0E17:
	mov	ax, OFFSET N_Mr_Sulu
	mov	bx, OFFSET T_TUG3_015
	call	Say
	jmp	SHORT L0E81

T_TUG3_015	LABEL	BYTE
	DB	'#TUG3\TUG3_015#Aye, Captain, using prefix code override to stabi'
	DB	'lize Masada''s orbit. Sulu out.',0
L0E81:
	mov	ax, OFFSET N_Ship_s_Computer
	mov	bx, OFFSET T_COMPA180
	call	Say
	jmp	SHORT L0EC0

T_COMPA180	LABEL	BYTE
	DB	'#COMP\COMPA180#Orbit Stabilized. Warning Cancelled.',0
L0EC0:
	mov	si, word ptr cs:rdf_state
	mov	word ptr [si+RS_TIMERS+2], 0
	JMPN	CallSecurity

	DB	0CBh
L0ECE:
	cmp	byte ptr [si+orbit_decay], 10h
	jl	L0ED7
	JMPN	L1054

L0ED7:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG3_006
	call	Say
	jmp	SHORT L0F10

T_TUG3_006	LABEL	BYTE
	DB	'#TUG3\TUG3_006#Mr. Scott, get us out of here.',0
L0F10:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_TUG3_S07
	call	Say
	jmp	SHORT L0F38

T_TUG3_S07	LABEL	BYTE
	DB	'#TUG3\TUG3_S07#Aye, Captain.',0
L0F38:
	mov	ax, -1
	push	ax
	mov	ax, -1
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(-1, -1)
	add	sp, 6
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, word ptr [si+score]
	and	ax, -8000h
	AX8	cmp, 0
	je	L0F60
	mov	word ptr [si+score], 0
L0F60:
	push	word ptr [si+outcome]
	push	word ptr [si+max_score]
	push	word ptr [si+score]
	push	RC_BEAMUP
	SERVICE		; BeamUp(?, ?, ?)
	add	sp, 8
	retf

; In the room file, so these start again each time the room loads
shot_flashes	LABEL	BYTE	; the flash bitmap for each clansman (rows) and target
	DB	8Ch, 0Fh, 95h, 0Fh, 9Eh, 0Fh, 0A7h, 0Fh, 0B0h, 0Fh, 0B9h, 0Fh
	DB	0C2h, 0Fh, 0CBh, 0Fh, 0D4h, 0Fh, 0DDh, 0Fh, 0E6h, 0Fh, 0EFh, 0Fh
	DB	't3beem33',0
	DB	't3beem35',0
	DB	't3beem34',0
	DB	't3beem32',0
	DB	't3beem37',0
	DB	't3beem39',0
	DB	't3beem38',0
	DB	't3beem36',0
	DB	't3beem29',0
	DB	't3beem31',0
	DB	't3beem30',0
	DB	't3beem28',0

; Timer 0: the next clansman standing fires at the next crew member
; still alive; McCoy's death (msg 13) ends the game.
H_0FF8:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_115B
ElasiFire:
	call	PickShooter
	cmp	word ptr cs:shooter, -1
	je	L1054
	call	PickTarget
	cmp	word ptr cs:target, -1
	je	L1054
	mov	ax, 6
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	mov	ax, word ptr cs:shooter
	shl	ax, 1
	shl	ax, 1
	add	ax, word ptr cs:target
	shl	ax, 1
	mov	si, ax
	mov	ax, 5
	push	ax
	mov	ax, word ptr cs:[si+shot_flashes]
	push	ax
	mov	ax, RC_FLASHBMP
	push	ax
	SERVICE		; FlashBitmap(?, 5)
	add	sp, 6
	mov	si, word ptr cs:rdf_state
	mov	word ptr [si+RS_TIMERS], 32h
L1054:
	retf

shooter	LABEL	BYTE	; word: the clansman firing, 0-2; -1 none
	DB	0, 0
target	LABEL	BYTE	; word: the crew member hit; -1 none
	DB	0, 0
; The first clansman still up (Cereth never fires).
PickShooter:
	cmp	byte ptr [si+elasi2], 0
	jne	L1067
	mov	word ptr cs:shooter, 0
	ret

L1067:
	cmp	byte ptr [si+elasi3], 0
	jne	L1075
	mov	word ptr cs:shooter, 1
	ret

L1075:
	cmp	byte ptr [si+elasi4], 0
	jne	L1083
	mov	word ptr cs:shooter, 2
	ret

L1083:
	mov	word ptr cs:shooter, -1
	ret

; The first of Christensen, Kirk, Spock, McCoy still alive is killed.
PickTarget:
	cmp	byte ptr [si+redshirt_killed], 0
	jne	L10BF
	mov	byte ptr [si+redshirt_killed], 2
	mov	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jmp	SHORT L10A2

N_rkills	LABEL	BYTE
	DB	'rkills',0
L10A2:
	push	0
	push	-1
	push	-1
	push	OFFSET N_rkills
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rkills", -1, -1, 0)
	add	sp, 0Ch
	mov	word ptr cs:target, 3
	ret

L10BF:
	cmp	byte ptr [si+kirk_killed], 0
	jne	L10F3
	mov	byte ptr [si+kirk_killed], 2
	mov	byte ptr [si+RS_BUSY], 1
	jmp	SHORT L10D6

N_kkills	LABEL	BYTE
	DB	'kkills',0
L10D6:
	push	0
	push	-1
	push	-1
	push	OFFSET N_kkills
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kkills", -1, -1, 0)
	add	sp, 0Ch
	mov	word ptr cs:target, 0
	ret

L10F3:
	cmp	byte ptr [si+spock_killed], 0
	jne	L1123
	mov	byte ptr [si+spock_killed], 2
	jmp	SHORT L1106

N_skills	LABEL	BYTE
	DB	'skills',0
L1106:
	push	0
	push	-1
	push	-1
	push	OFFSET N_skills
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "skills", -1, -1, 0)
	add	sp, 0Ch
	mov	word ptr cs:target, 1
	ret

L1123:
	cmp	byte ptr [si+mccoy_killed], 0
	jne	L1153
	mov	byte ptr [si+mccoy_killed], 2
	jmp	SHORT L1136

N_mkills	LABEL	BYTE
	DB	'mkills',0
L1136:
	push	0Dh
	push	-1
	push	-1
	push	OFFSET N_mkills
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mkills", -1, -1, 13)
	add	sp, 0Ch
	mov	word ptr cs:target, 2
	ret

L1153:
	mov	word ptr cs:target, -1
	ret

H_115B:
	SCRIPT	MSG_ANIM_DONE, 0Dh, 0, 0, H_11A0
McCoyKilled:
	mov	ax, -1
	push	ax
	mov	ax, 2
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(2, -1)
	add	sp, 6
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	mov	ax, 0
	mov	bx, OFFSET S_118A
	call	Say
	jmp	SHORT L119F

S_118A	LABEL	BYTE
	DB	'***Game over man!***',0
L119F:
	retf

; Timer 1: the orbit decays; at 10h the Masada is lost, game over.
H_11A0:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_130D
OrbitDecays:
	cmp	byte ptr [si+orbit_decay], 0Ah
	jge	L11F9
	mov	ax, OFFSET N_Ship_s_Computer
	mov	bx, OFFSET T_COMPU182
	call	Say
	jmp	SHORT L11F0

T_COMPU182	LABEL	BYTE
	DB	'#COMP\COMPU182#Warning. Orbital decay detected. Warning.',0
L11F0:
	mov	word ptr [si+RS_TIMERS+2], 64h
	inc	byte ptr [si+orbit_decay]
	retf

L11F9:
	cmp	byte ptr [si+orbit_decay], 10h
	jge	L126A
	mov	ax, OFFSET N_Ship_s_Computer
	mov	bx, OFFSET T_COMPU181
	call	Say
	jmp	SHORT L1261

T_COMPU181	LABEL	BYTE
	DB	'#COMP\COMPU181#Warning. Orbital Decay is now irreversible. Aband'
	DB	'on Ship. Abandon Ship.',0
L1261:
	mov	word ptr [si+RS_TIMERS+2], 64h
	inc	byte ptr [si+orbit_decay]
	retf

L126A:
	mov	ax, 0
	mov	bx, OFFSET T_TUG3N006
	call	Say
	jmp	SHORT L12E2

T_TUG3N006	LABEL	BYTE
	DB	'#TUG3\TUG3N006#The Masada goes down in a fireball over Beta Myam'
	DB	'id, with you on it. Better luck next season.',0
L12E2:
	push	RC_GAMEOVER
	SERVICE		; GameOver()
	add	sp, 2
	mov	ax, 0
	mov	bx, OFFSET S_12F7
	call	Say
	jmp	SHORT L130C

S_12F7	LABEL	BYTE
	DB	'***Game over man!***',0
L130C:
	retf

; The Elasi are all down (or the communicator): Scott beams a security
; team over (msgs 7-10), then the party out. The mission's end.
H_130D:
	SCRIPT	MSG_USE, IT_COMM, ANY, 0, H_13FD
CallSecurity:
	mov	ax, -1
	push	ax
	mov	ax, 1Ch
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(28, -1)
	add	sp, 6
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG3_001
	call	Say
	jmp	SHORT L138D

T_TUG3_001	LABEL	BYTE
	DB	'#TUG3\TUG3_001#Scotty, beam down a security team to the bridge. '
	DB	' We have regained control.',0
L138D:
	mov	ax, 9
	push	ax
	mov	ax, RC_BRIDGESFX
	push	ax
	SERVICE		; BridgeSfx(9)
	add	sp, 4
	jmp	SHORT L13A6

N_rteleb	LABEL	BYTE
	DB	'rteleb',0
L13A6:
	push	7
	push	0A0h
	push	14h
	push	OFFSET N_rteleb
	push	0Dh
	push	RC_ANIM2
	SERVICE		; Anim(13, "rteleb", 20, 160, 7)
	add	sp, 0Ch
	jmp	SHORT L13C5

N_rteleb_2	LABEL	BYTE
	DB	'rteleb',0
L13C5:
	push	0
	push	0A0h
	push	118h
	push	OFFSET N_rteleb_2
	push	0Eh
	push	RC_ANIM2
	SERVICE		; Anim(14, "rteleb", 280, 160, 0)
	add	sp, 0Ch
	jmp	SHORT L13E5

N_rteleb_3	LABEL	BYTE
	DB	'rteleb',0
L13E5:
	push	0
	push	0BEh
	push	96h
	push	OFFSET N_rteleb_3
	push	0Fh
	push	RC_ANIM2
	SERVICE		; Anim(15, "rteleb", 150, 190, 0)
	add	sp, 0Ch
	retf

H_13FD:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, Talk
SecurityArrives:
	jmp	SHORT L140C

N_rdrawe	LABEL	BYTE
	DB	'rdrawe',0
L140C:
	push	8
	push	-1
	push	-1
	push	OFFSET N_rdrawe
	push	0Dh
	push	RC_ANIM2
	SERVICE		; Anim(13, "rdrawe", -1, -1, 8)
	add	sp, 0Ch
	jmp	SHORT L142A

N_rdraws	LABEL	BYTE
	DB	'rdraws',0
L142A:
	push	9
	push	-1
	push	-1
	push	OFFSET N_rdraws
	push	0Eh
	push	RC_ANIM2
	SERVICE		; Anim(14, "rdraws", -1, -1, 9)
	add	sp, 0Ch
	jmp	SHORT L1448

N_rfiren	LABEL	BYTE
	DB	'rfiren',0
L1448:
	push	0Ah
	push	-1
	push	-1
	push	OFFSET N_rfiren
	push	0Fh
	push	RC_ANIM2
	SERVICE		; Anim(15, "rfiren", -1, -1, 10)
	add	sp, 0Ch
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_TUG3_005
	call	Say
	jmp	SHORT L1497

T_TUG3_005	LABEL	BYTE
	DB	'#TUG3\TUG3_005#Mr. Scott, beam us out of here.',0
L1497:
	mov	ax, OFFSET N_Mr_Scott
	mov	bx, OFFSET T_TUG3_S08
	call	Say
	jmp	SHORT L14BF

T_TUG3_S08	LABEL	BYTE
	DB	'#TUG3\TUG3_S08#Aye, Captain.',0
L14BF:
	mov	ax, -1
	push	ax
	mov	ax, -1
	push	ax
	mov	ax, RC_MUSIC
	push	ax
	SERVICE		; Music(-1, -1)
	add	sp, 6
	mov	byte ptr [si+RS_BUSY], 1
	mov	ax, word ptr [si+score]
	and	ax, -8000h
	AX8	cmp, 0
	je	L14E7
	mov	word ptr [si+score], 0
L14E7:
	push	word ptr [si+outcome]
	push	word ptr [si+max_score]
	push	word ptr [si+score]
	push	RC_BEAMUP
	SERVICE		; BeamUp(?, ?, ?)
	add	sp, 8
	retf

rdf_scripts_end:
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

rdf_objects	LABEL	BYTE
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	1, 4	; id, points
	DW	166,96, 202,96, 202,97, 166,97
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
	DB	'brdg',0
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Mr_Sulu	LABEL	BYTE
	DB	'Mr. Sulu',0
N_Ship_s_Computer	LABEL	BYTE
	DB	'Ship''s Computer',0
N_Lt_Christensen	LABEL	BYTE
	DB	'Lt. Christensen',0
N_Elasi_Cereth	LABEL	BYTE
	DB	'Elasi Cereth',0
N_Elasi_Clansman	LABEL	BYTE
	DB	'Elasi Clansman',0
	DB	'Starfleet',0
N_Mr_Scott	LABEL	BYTE
	DB	'Mr. Scott',0
S_15AA	LABEL	BYTE
	DB	0
T_TUG3N008	LABEL	BYTE
	DB	'#TUG3\TUG3N008#You carefully eye the chief lieutenant of the Ela'
	DB	'si Clan, Elasi Cereth.',0
T_TUG3N003	LABEL	BYTE
	DB	'#TUG3\TUG3N003#The body of Elasi Cereth lies on the ground.',0
T_TUG3N005	LABEL	BYTE
	DB	'#TUG3\TUG3N005#The Elasi clanmember glares at the party.',0
T_TUG3N004	LABEL	BYTE
	DB	'#TUG3\TUG3N004#The body of the Elasi clanmember lies on the grou'
	DB	'nd here.',0
T_TUG3N000	LABEL	BYTE
	DB	'#TUG3\TUG3N000#Dr. McCoy appears a bit restless.',0
T_TUG3N002	LABEL	BYTE
	DB	'#TUG3\TUG3N002#Spock is analyzing the surroundings.',0
	DB	'put anim of pirates beaming out here.',0
	DB	'At this point, the crew should beam back up to the Enterprise.',0
T_TUG3_004	LABEL	BYTE
	DB	'#TUG3\TUG3_004#It''s over, Cereth. Surrender and I''ll guarantee t'
	DB	'he lives of you and your crew.',0
T_TUG3_003	LABEL	BYTE
	DB	'#TUG3\TUG3_003#Freeze, don''t even think about it.',0
T_TUG3_002	LABEL	BYTE
	DB	'#TUG3\TUG3_002#Check and mate, Elasi. Don''t do anything foolish.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0
KirkToCereth	LABEL	BYTE
	DW	OFFSET N_Capt_Kirk, OFFSET T_TUG3_004, OFFSET T_TUG3_003, OFFSET T_TUG3_002, 0	; speaker, choices, 0

RDF	ENDS
	END
