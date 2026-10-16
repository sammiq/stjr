; DEMON3.RDF - "Demon World", the cave-in inside Mount Idyll. Brother
; Kandrey is trapped under the rubble in front of an alien door. Kirk clears
; it boulder by boulder with his phaser on kill, top first: the crew take
; cover, Kirk fires, and the boulder breaks up. Shooting a lower one while
; the top boulder is still up brings that down on Ensign Everts. Under the
; last boulder is the miner, whom McCoy can save. The door opens to the
; android's repaired hand on its panel; Everts, if he tries the panel,
; gets a shock, and the fifth time it kills him.
;
; Actors: 8 the light over the door, 9-12 (0Ch) the boulders, top to
; bottom, 13 (0Dh) the miner, 14 (0Eh) the door, 15 (0Fh) the panel,
; 17 (11h) the falling rubble.
; Objects: 9-0Ch the boulders, 0Dh the miner, 0Eh/21h the door, 0Fh/20h
; the hand panel, 22h the structure.
; Exits: 0 through the door (room 4), 1 back out (room 2).
; Timers: 0 the top boulder falls, 1 it hits Everts, 3 the panel takes the
; hand.
;
; Labels: H_ script headers, L branch targets, C_ conversations,
; T_/N_/S_ strings; talk_buf: the conversation buffer of Say.
;
; Quirks of the original:
; - The script chain runs on into code at 16F9: the engine reads its bytes
;   as key 50 B8 03 00 and next 2E50 (beyond rdf_scripts_end, so the search
;   stops).

	INCLUDE	rdf.inc

; RoomState.vars, shared by the mission's rooms (cleared by StartAway)
boulders_down	EQU	RS_VARS+10h	; how many of the four boulders have been cleared
hand_repaired	EQU	RS_VARS+12h	; set in room 6
healed_miner	EQU	RS_VARS+13h
miner_dead	EQU	RS_VARS+17h	; he died: the party left without treating him (room 4)
panel_tries	EQU	RS_VARS+18h	; word: Everts' tries at the panel
rubble_cleared	EQU	RS_VARS+1Ah	; word: the last boulder is down
everts_shocked	EQU	RS_VARS+1Ch	; word: the panel killed Everts
boulder1_down	EQU	RS_VARS+20h
boulder2_down	EQU	RS_VARS+21h
boulder3_down	EQU	RS_VARS+22h
boulder4_down	EQU	RS_VARS+23h
door_open	EQU	RS_VARS+24h
cave_music	EQU	RS_VARS+2Dh	; the cave music has started
score	EQU	RS_VARS+2Fh	; word: the mission's score

RDF	SEGMENT BYTE PUBLIC 'RDF'
	ASSUME	CS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING

rdf_service	LABEL	BYTE
	DD	0	; ScriptService, set by LoadRoom
rdf_state	LABEL	BYTE
	DW	0	; &room, set by LoadRoom
rdf_y_max	LABEL	BYTE
	DW	78h	; depth scaling: y range
rdf_y_min	LABEL	BYTE
	DW	32h
rdf_scale_min	LABEL	BYTE
	DW	46h	; and scale range
rdf_scale_max	LABEL	BYTE
	DW	100h
rdf_sections	LABEL	BYTE
	DW	OFFSET rdf_scripts, OFFSET rdf_scripts_end	; scripts, objects, exits, regions, bans: start, end
	DW	OFFSET rdf_objects, OFFSET rdf_objects_end
	DW	OFFSET rdf_exits, OFFSET rdf_exits_end
	DW	OFFSET rdf_regions, OFFSET rdf_regions_end
	DW	OFFSET rdf_bans, OFFSET rdf_bans_end
rdf_exit_room	LABEL	BYTE
	DW	4, 2, -1, -1	; room for each exit
rdf_walk_in	LABEL	BYTE
				; per entrance, for each crew member: from, to
	DW	175,58, 171,128	; entrance 0, crew 0
	DW	175,58, 133,118	; entrance 0, crew 1
	DW	175,58, 185,109	; entrance 0, crew 2
	DW	175,58, 155,96	; entrance 0, crew 3
	DW	175,199, 175,167	; entrance 1, crew 0
	DW	175,199, 205,173	; entrance 1, crew 1
	DW	175,199, 150,180	; entrance 1, crew 2
	DW	175,199, 178,185	; entrance 1, crew 3
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
	DW	160,170, 150,160, 170,160, 160,150
; In the room file, so these start again each time the room loads
crew_ready	LABEL	BYTE	; the crew have been sent to take cover
	DB	0
top_boulder_safe	LABEL	BYTE	; the top boulder can no longer fall
	DB	0
boulder	LABEL	BYTE	; the boulder being shot, 1-4
	DB	0
kirk_in_place	LABEL	BYTE	; in cover, ready to shoot
	DB	0
everts_in_place	LABEL	BYTE
	DB	0
spock_in_place	LABEL	BYTE
	DB	0
mccoy_in_place	LABEL	BYTE
	DB	0
in_cover	LABEL	BYTE	; the crew are already where they shelter
	DB	0, 0
kirk_fired	LABEL	BYTE
	DB	0
rubble_anim	LABEL	BYTE	; the breaking boulder's animation
	DB	0, 0
door_shots	LABEL	BYTE	; word: phaser shots at the door
	DB	0, 0
N_drbldr	LABEL	BYTE
	DB	'drbldr',0
N_redkil	LABEL	BYTE
	DB	'redkil',0
N_sbldr1	LABEL	BYTE
	DB	'sbldr1',0
N_sbldr2	LABEL	BYTE
	DB	'sbldr2',0
N_sbldr3	LABEL	BYTE
	DB	'sbldr3',0
N_sbldr4	LABEL	BYTE
	DB	'sbldr4',0
N_bldr1	LABEL	BYTE
	DB	'bldr1',0
N_bldr2	LABEL	BYTE
	DB	'bldr2',0
N_bldr3	LABEL	BYTE
	DB	'bldr3',0
N_bldr4	LABEL	BYTE
	DB	'bldr4',0
N_kstnds	LABEL	BYTE
	DB	'kstnds',0
	DB	'sstnds',0
N_kwaitn	LABEL	BYTE
	DB	'kwaitn',0
N_swaitn	LABEL	BYTE
	DB	'swaitn',0
N_mwaitn	LABEL	BYTE
	DB	'mwaitn',0
N_rwaitn	LABEL	BYTE
	DB	'rwaitn',0
N_deadre	LABEL	BYTE
	DB	'deadre',0
N_drmine	LABEL	BYTE
	DB	'drmine',0
N_miner	LABEL	BYTE
	DB	'miner',0
N_door	LABEL	BYTE
	DB	'door',0
N_door2	LABEL	BYTE
	DB	'door2',0
N_panel	LABEL	BYTE
	DB	'panel',0
N_demon3a	LABEL	BYTE
	DB	'demon3a',0
N_demon3	LABEL	BYTE
	DB	'demon3',0
N_light	LABEL	BYTE
	DB	'light',0
N_rkille	LABEL	BYTE
	DB	'rkille',0
	DB	'rstunn',0
N_kfiren	LABEL	BYTE
	DB	'kfiren',0
N_s0r3s1	LABEL	BYTE
	DB	's0r3s1',0
N_s0r3s2	LABEL	BYTE
	DB	's0r3s2',0
N_s0r3s3	LABEL	BYTE
	DB	's0r3s3',0
N_s0r3s4	LABEL	BYTE
	DB	's0r3s4',0
N_museln	LABEL	BYTE
	DB	'museln',0
N_kusehn	LABEL	BYTE
	DB	'kusehn',0
N_rusehn	LABEL	BYTE
	DB	'rusehn',0
N_mscann	LABEL	BYTE
	DB	'mscann',0
N_mscanw	LABEL	BYTE
	DB	'mscanw',0
N_sscann	LABEL	BYTE
	DB	'sscann',0

rdf_scripts:
; The room starts: the boulders still up, the door if it is open.
H_01D9:
	SCRIPT	MSG_TICK, 1, 0, 0, H_031C
StartRoom:
	jmp	SHORT L01EA

N_DEM3LOOP	LABEL	BYTE
	DB	'DEM3LOOP',0
L01EA:
	push	OFFSET N_DEM3LOOP
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("DEM3LOOP")
	add	sp, 4
	push	0
	push	3
	push	0ABh
	push	OFFSET N_light
	push	8
	push	RC_ANIM0
	SERVICE		; Anim0(8, "light", 171, 3, 0)
	add	sp, 0Ch
	mov	byte ptr cs:top_boulder_safe, 1
	cmp	byte ptr [si+boulder1_down], 1
	je	L0236
	push	0
	push	0
	push	26h
	push	OFFSET N_bldr1
	push	9
	push	RC_ANIM0
	SERVICE		; Anim0(9, "bldr1", 38, 0, 0)
	add	sp, 0Ch
	mov	byte ptr cs:top_boulder_safe, 0
L0236:
	cmp	byte ptr [si+boulder2_down], 1
	je	L0251
	push	0
	push	0
	push	22h
	push	OFFSET N_bldr2
	push	0Ah
	push	RC_ANIM0
	SERVICE		; Anim0(10, "bldr2", 34, 0, 0)
	add	sp, 0Ch
L0251:
	cmp	byte ptr [si+boulder3_down], 1
	je	L026C
	push	0
	push	0
	push	22h
	push	OFFSET N_bldr3
	push	0Bh
	push	RC_ANIM0
	SERVICE		; Anim0(11, "bldr3", 34, 0, 0)
	add	sp, 0Ch
L026C:
	cmp	byte ptr [si+boulder4_down], 1
	je	L0287
	push	0
	push	0
	push	22h
	push	OFFSET N_bldr4
	push	0Ch
	push	RC_ANIM0
	SERVICE		; Anim0(12, "bldr4", 34, 0, 0)
	add	sp, 0Ch
L0287:
	cmp	byte ptr [si+door_open], 1
	jne	L02A3
	push	0
	push	0Ch
	push	82h
	push	OFFSET N_door2
	push	0Eh
	push	RC_ANIM0
	SERVICE		; Anim0(14, "door2", 130, 12, 0)
	add	sp, 0Ch
L02A3:
	cmp	byte ptr [si+door_open], 1
	je	L02B6
	push	OFFSET N_demon3a
	push	RC_LOADMAP
	SERVICE		; LoadMap("demon3a")
	add	sp, 4
L02B6:
	cmp	byte ptr [si+healed_miner], 1
	je	L02D8
	cmp	byte ptr [si+boulder4_down], 1
	jne	L02D8
	push	0
	push	6Ch
	push	0DAh
	push	OFFSET N_miner
	push	0Dh
	push	RC_ANIM0
	SERVICE		; Anim0(13, "miner", 218, 108, 0)
	add	sp, 0Ch
L02D8:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L02FA
	cmp	word ptr [si+everts_shocked], 1
	je	L02FA
	push	0
	push	0A0h
	push	46h
	push	OFFSET N_deadre
	push	3
	push	RC_ANIM0
	SERVICE		; Anim0(3, "deadre", 70, 160, 0)
	add	sp, 0Ch
L02FA:
	cmp	word ptr [si+panel_tries], 0
	jne	L0303
	inc	word ptr [si+panel_tries]
L0303:
	cmp	byte ptr [si+cave_music], 1
	je	L031B
	mov	byte ptr [si+cave_music], 1
	push	-1
	push	0
	push	RC_MUSIC
	SERVICE		; Music(0, -1)
	add	sp, 6
L031B:
	retf

; Timer 0 (set when a lower boulder goes first): the top boulder
; comes down, and on timer 1...
H_031C:
	SCRIPT	MSG_TIMER, 0, 0, 0, H_0376
TopBoulderFalls:
	mov	byte ptr cs:top_boulder_safe, 1
	push	0
	push	0
	push	26h
	push	OFFSET N_drbldr
	push	9
	push	RC_ANIM2
	SERVICE		; Anim(9, "drbldr", 38, 0, 0)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+2], 0Dh
	mov	byte ptr [si+boulder1_down], 1
	inc	byte ptr [si+boulders_down]
	mov	byte ptr [si+RS_BUSY], 1
	push	-1
	push	2
	push	RC_MUSIC
	SERVICE		; Music(2, -1)
	add	sp, 6
	jmp	SHORT L0366

N_BOULDERK	LABEL	BYTE
	DB	'BOULDERK',0
L0366:
	push	OFFSET N_BOULDERK
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("BOULDERK")
	add	sp, 4
	retf

; ...Kirk and Everts are caught (anim msg 1).
H_0376:
	SCRIPT	MSG_TIMER, 1, 0, 0, H_03AF
BoulderHitsEverts:
	mov	byte ptr cs:kirk_fired, 0
	push	0
	push	0A0h
	push	46h
	push	OFFSET N_redkil
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "redkil", 70, 160, 0)
	add	sp, 0Ch
	push	1
	push	0A0h
	push	46h
	push	OFFSET N_redkil
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "redkil", 70, 160, 1)
	add	sp, 0Ch
	retf

H_03AF:
	SCRIPT	MSG_TIMER, 3, 0, 0, H_03FA
PanelTakesHand:
	cmp	byte ptr [si+hand_repaired], 1
	jne	L03F0
	mov	ax, OFFSET S_17BC
	mov	bx, OFFSET T_DEM3N008
	call	Say
	push	0
	push	0Ch
	push	82h
	push	OFFSET N_door
	push	0Eh
	push	RC_ANIM0
	SERVICE		; Anim0(14, "door", 130, 12, 0)
	add	sp, 0Ch
	push	OFFSET N_demon3
	push	RC_LOADMAP
	SERVICE		; LoadMap("demon3")
	add	sp, 4
	mov	byte ptr [si+door_open], 1
	add	word ptr [si+score], 2
	retf

L03F0:
	mov	ax, OFFSET S_17BC
	mov	bx, OFFSET T_DEM3N007
	call	Say
	retf

; Everts is dead; McCoy goes to him (msg 5).
H_03FA:
	SCRIPT	MSG_ANIM_DONE, 1, 0, 0, H_0458
EvertsCrushed:
	push	0
	push	0A9h
	push	0EEh
	push	OFFSET N_kstnds
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kstnds", 238, 169, 0)
	add	sp, 0Ch
	push	0
	push	0A0h
	push	46h
	push	OFFSET N_deadre
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "deadre", 70, 160, 0)
	add	sp, 0Ch
	push	1
	push	RC_STOPANIM
	SERVICE		; StopAnim(1)
	add	sp, 4
	push	5
	push	0B2h
	push	9Ch
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 156, 178, 5)
	add	sp, 0Ah
	mov	byte ptr cs:in_cover, 0
	mov	byte ptr [si+RS_REDSHIRT_DEAD], 1
	retf

; The last boulder has gone: the miner is uncovered, +3 score.
H_0458:
	SCRIPT	MSG_ANIM_DONE, 2, 0, 0, H_0479
MinerUncovered:
	push	0
	push	6Ch
	push	0DAh
	push	OFFSET N_miner
	push	0Dh
	push	RC_ANIM0
	SERVICE		; Anim0(13, "miner", 218, 108, 0)
	add	sp, 0Ch
	add	word ptr [si+score], 3
	retf

H_0479:
	SCRIPT	MSG_WALK_DONE, 5, 0, 0, H_04AE
McCoyAtEverts:
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
	mov	bx, OFFSET T_DEM3_019
	call	Say
	mov	byte ptr [si+RS_BUSY], 0
	retf

; The crew reach cover (walk msgs 1-4). When everyone is there, Kirk
; fires (anim msg 4).
H_04AE:
	SCRIPT	MSG_WALK_DONE, 3, 0, 0, H_04D3
McCoyInCover:
	push	0
	push	0B8h
	push	0D6h
	push	OFFSET N_mwaitn
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mwaitn", 214, 184, 0)
	add	sp, 0Ch
	mov	byte ptr cs:mccoy_in_place, 1
	jmp	SHORT L053E

H_04D3:
	SCRIPT	MSG_WALK_DONE, 2, 0, 0, H_04F8
SpockInCover:
	push	0
	push	0B4h
	push	0AEh
	push	OFFSET N_swaitn
	push	1
	push	RC_ANIM2
	SERVICE		; Anim(1, "swaitn", 174, 180, 0)
	add	sp, 0Ch
	mov	byte ptr cs:spock_in_place, 1
	jmp	SHORT L053E

H_04F8:
	SCRIPT	MSG_WALK_DONE, 4, 0, 0, H_051C
EvertsInCover:
	push	0
	push	0A0h
	push	46h
	push	OFFSET N_rwaitn
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rwaitn", 70, 160, 0)
	add	sp, 0Ch
	mov	byte ptr cs:everts_in_place, 1
	jmp	SHORT L053E

H_051C:
	SCRIPT	MSG_WALK_DONE, 1, 0, 0, H_058B
KirkInCover:
	push	0
	push	0A0h
	push	79h
	push	OFFSET N_kwaitn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kwaitn", 121, 160, 0)
	add	sp, 0Ch
	mov	byte ptr cs:kirk_in_place, 1
L053E:
	cmp	byte ptr cs:kirk_in_place, 1
	jne	L0566
	cmp	byte ptr cs:spock_in_place, 1
	jne	L0566
	cmp	byte ptr cs:mccoy_in_place, 1
	jne	L0566
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L0567
	cmp	byte ptr cs:everts_in_place, 1
	jne	L0566
	jmp	SHORT L0567

L0566:
	retf

L0567:
	cmp	byte ptr cs:kirk_fired, 1
	je	BoulderBreaks
	push	4
	push	-1
	push	-1
	push	OFFSET N_kfiren
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kfiren", -1, -1, 4)
	add	sp, 0Ch
	mov	byte ptr cs:kirk_fired, 1
	retf

; The shot has hit: the boulder breaks up (rubble_anim), msg 2 for the
; last one. If the top boulder is still up, timer 0 brings it down.
H_058B:
	SCRIPT	MSG_ANIM_DONE, 4, 0, 0, H_0643
BoulderBreaks:
	mov	byte ptr cs:kirk_in_place, 0
	mov	byte ptr cs:spock_in_place, 0
	mov	byte ptr cs:mccoy_in_place, 0
	mov	byte ptr cs:everts_in_place, 0
	mov	byte ptr cs:crew_ready, 0
	push	2
	cmp	byte ptr cs:boulder, 4
	je	L05BC
	pop	ax
	push	0
L05BC:
	push	0
	push	22h
	cmp	byte ptr cs:boulder, 1
	jne	L05CF
	push	OFFSET N_sbldr1
	push	9
	jmp	SHORT L0605

L05CF:
	cmp	byte ptr cs:boulder, 2
	jne	L05DE
	push	OFFSET N_sbldr2
	push	0Ah
	jmp	SHORT L0605

L05DE:
	cmp	byte ptr cs:boulder, 3
	jne	L05ED
	push	OFFSET N_sbldr3
	push	0Bh
	jmp	SHORT L0605

L05ED:
	cmp	byte ptr cs:boulder, 4
	jne	L05FC
	push	OFFSET N_sbldr4
	push	0Ch
	jmp	SHORT L0605

L05FC:
	mov	ax, OFFSET N_wes
	mov	bx, OFFSET S_2185
	call	Say
L0605:
	push	RC_ANIM2
	SERVICE		; Anim(?, ?, ?)
	add	sp, 0Ch
	push	0
	push	0
	push	0
	push	word ptr cs:rubble_anim
	push	11h
	push	RC_ANIM0
	SERVICE		; Anim0(17, ?, 0, 0, 0)
	add	sp, 0Ch
	push	6
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	cmp	byte ptr cs:top_boulder_safe, 1
	je	L063E
	mov	word ptr [si+RS_TIMERS], 1
L063E:
	mov	byte ptr [si+RS_BUSY], 0
	retf

; Phasers on Everts (dead: McCoy objects), and on the boulders: stun
; does nothing...
H_0643:
	SCRIPT	MSG_USE, IT_PHASERS, OBJ_REDSHIRT, 0, H_064B
	jmp	SHORT PhaserDeadEverts

H_064B:
	SCRIPT	MSG_USE, IT_PHASERK, OBJ_REDSHIRT, 0, H_06AA
PhaserDeadEverts:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L06A9
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_013
	call	Say
	jmp	SHORT L06A9

T_DEM3_013	LABEL	BYTE
	DB	'#DEM3\DEM3_013#He''s already dead, Jim. Isn''t that good enough fo'
	DB	'r you?',0
L06A9:
	retf

H_06AA:
	SCRIPT	MSG_USE, IT_PHASERS, 9, 0, H_06B2
	jmp	SHORT StunBoulder2

H_06B2:
	SCRIPT	MSG_USE, IT_PHASERS, 0Ah, 0, H_06BA
StunBoulder2:
	jmp	SHORT StunBoulder3

H_06BA:
	SCRIPT	MSG_USE, IT_PHASERS, 0Bh, 0, H_06C2
StunBoulder3:
	jmp	SHORT StunBoulder

H_06C2:
	SCRIPT	MSG_USE, IT_PHASERS, 0Ch, 0, H_072A
StunBoulder:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM3_007
	call	Say
	jmp	SHORT L0729

T_DEM3_007	LABEL	BYTE
	DB	'#DEM3\DEM3_007#Captain, the stun setting would be very ineffecti'
	DB	've on these boulders.',0
L0729:
	retf

; ...on kill, each boulder once, top first, after the crew take cover.
H_072A:
	SCRIPT	MSG_USE, IT_PHASERK, 9, 0, H_075D
ShootBoulder1:
	cmp	byte ptr cs:crew_ready, 1
	jne	L0739
	retf

L0739:
	cmp	byte ptr [si+boulder1_down], 1
	jne	L0740
	retf

L0740:
	mov	byte ptr [si+boulder1_down], 1
	inc	byte ptr [si+boulders_down]
	mov	byte ptr cs:boulder, 1
	mov	byte ptr cs:top_boulder_safe, 1
	mov	word ptr cs:rubble_anim, OFFSET N_s0r3s2
	JMPN	L093F

H_075D:
	SCRIPT	MSG_USE, IT_PHASERK, 0Ah, 0, H_078A
ShootBoulder2:
	cmp	byte ptr cs:crew_ready, 1
	jne	L076C
	retf

L076C:
	cmp	byte ptr [si+boulder2_down], 1
	jne	L0773
	retf

L0773:
	mov	byte ptr [si+boulder2_down], 1
	inc	byte ptr [si+boulders_down]
	mov	byte ptr cs:boulder, 2
	mov	word ptr cs:rubble_anim, OFFSET N_s0r3s3
	JMPN	L093F

H_078A:
	SCRIPT	MSG_USE, IT_PHASERK, 0Bh, 0, H_086A
ShootBoulder3:
	cmp	byte ptr [si+boulder1_down], 1
	jne	L0799
	JMPN	L0843

L0799:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM3_006
	call	Say
	JMPN	L0842

T_DEM3_006	LABEL	BYTE
	DB	'#DEM3\DEM3_006#Captain, the structure is extremely unstable. I w'
	DB	'ould not recommend disturbing the lower section before the upper'
	DB	' sections have been cleared.',0
L0842:
	retf

L0843:
	cmp	byte ptr cs:crew_ready, 1
	jne	L084C
	retf

L084C:
	cmp	byte ptr [si+boulder3_down], 1
	jne	L0853
	retf

L0853:
	mov	byte ptr [si+boulder3_down], 1
	inc	byte ptr [si+boulders_down]
	mov	byte ptr cs:boulder, 3
	mov	word ptr cs:rubble_anim, OFFSET N_s0r3s1
	JMPN	L093F

H_086A:
	SCRIPT	MSG_USE, IT_PHASERK, 0Ch, 0, H_09E7
ShootBoulder4:
	cmp	byte ptr [si+boulder2_down], 1
	jne	L0879
	JMPN	L0914

L0879:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET S_0885
	call	Say
	JMPN	L0913

S_0885	LABEL	BYTE
	DB	'Captain, the structure is extremely unstable. I would not recomm'
	DB	'end disturbing the lower section before the upper sections have '
	DB	'been cleared.',0
L0913:
	retf

L0914:
	cmp	byte ptr cs:crew_ready, 1
	jne	L091D
	retf

L091D:
	cmp	byte ptr [si+boulder4_down], 1
	jne	L0924
	retf

L0924:
	mov	byte ptr [si+boulder4_down], 1
	inc	byte ptr [si+boulders_down]
	mov	byte ptr cs:boulder, 4
	mov	word ptr cs:rubble_anim, OFFSET N_s0r3s4
	mov	word ptr [si+rubble_cleared], 1
	jmp	SHORT L093F

L093F:
	mov	byte ptr [si+RS_BUSY], 1
	push	0
	push	RC_ACTORPOS
	SERVICE		; ActorPos(0)
	add	sp, 4
	cmp	dx, 0A0h
	je	L0961
	mov	byte ptr cs:in_cover, 0
	mov	byte ptr cs:kirk_fired, 0
L0961:
	AX8	cmp, 79h
	je	L0972
	mov	byte ptr cs:in_cover, 0
	mov	byte ptr cs:kirk_fired, 0
L0972:
	cmp	byte ptr cs:in_cover, 1
	jne	L097D
	JMPN	L0567

L097D:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM3_001
	call	Say
	push	1
	push	0A0h
	push	79h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 121, 160, 1)
	add	sp, 0Ah
	push	2
	push	0B4h
	push	0AEh
	push	1
	push	RC_WALK
	SERVICE		; Walk(1, 174, 180, 2)
	add	sp, 0Ah
	push	3
	push	0B8h
	push	0D6h
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 214, 184, 3)
	add	sp, 0Ah
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L09DA
	push	4
	push	0A0h
	push	46h
	push	3
	push	RC_WALK
	SERVICE		; Walk(3, 70, 160, 4)
	add	sp, 0Ah
L09DA:
	mov	byte ptr cs:crew_ready, 1
	mov	byte ptr cs:in_cover, 1
	retf

; Tricorders.
H_09E7:
	SCRIPT	MSG_USE, IT_STRICOR, 0Dh, 0, H_0A68
SpockScansMiner:
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
	mov	bx, OFFSET T_DEM3_008
	call	Say
	jmp	SHORT L0A67

T_DEM3_008	LABEL	BYTE
	DB	'#DEM3\DEM3_008#I think Doctor McCoy would be better suited to de'
	DB	'al with this.',0
L0A67:
	retf

H_0A68:
	SCRIPT	MSG_USE, IT_STRICOR, 20h, 0, H_0B10
SpockScansPanel:
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
	mov	bx, OFFSET T_DEM3_009
	call	Say
	jmp	SHORT L0B0F

T_DEM3_009	LABEL	BYTE
	DB	'#DEM3\DEM3_009#It appears to be a security lock designed to open'
	DB	' the door when the correct hand print is registered.',0
L0B0F:
	retf

H_0B10:
	SCRIPT	MSG_USE, IT_STRICOR, 9, 0, H_0B18
	jmp	SHORT SpockScansBoulder2

H_0B18:
	SCRIPT	MSG_USE, IT_STRICOR, 0Ah, 0, H_0B20
SpockScansBoulder2:
	jmp	SHORT SpockScansBoulder3

H_0B20:
	SCRIPT	MSG_USE, IT_STRICOR, 0Bh, 0, H_0B28
SpockScansBoulder3:
	jmp	SHORT SpockScansBoulder

H_0B28:
	SCRIPT	MSG_USE, IT_STRICOR, 0Ch, 0, H_0B5F
SpockScansBoulder:
	cmp	word ptr [si+rubble_cleared], 1
	je	L0B5E
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
	mov	bx, OFFSET T_DEM3_010
	call	Say
L0B5E:
	retf

H_0B5F:
	SCRIPT	MSG_USE, IT_MTRICOR, 9, 0, H_0B67
	jmp	SHORT McCoyScansBoulder2

H_0B67:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Ah, 0, H_0B6F
McCoyScansBoulder2:
	jmp	SHORT McCoyScansBoulder3

H_0B6F:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Bh, 0, H_0B77
McCoyScansBoulder3:
	jmp	SHORT McCoyScansBoulder

H_0B77:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Ch, 0, H_0BA8
McCoyScansBoulder:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscann
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscann", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_020
	call	Say
	retf

; The crew at the panel: Everts insists on going himself.
H_0BA8:
	SCRIPT	MSG_USE, OBJ_KIRK, 20h, 0, H_0BB0
	jmp	SHORT SpockUsesPanel

H_0BB0:
	SCRIPT	MSG_USE, OBJ_SPOCK, 20h, 0, H_0BB8
SpockUsesPanel:
	jmp	SHORT McCoyUsesPanel

H_0BB8:
	SCRIPT	MSG_USE, OBJ_MCCOY, 20h, 0, H_0C12
McCoyUsesPanel:
	cmp	byte ptr [si+boulders_down], 4
	je	L0BC5
	retf

L0BC5:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L0BCC
	retf

L0BCC:
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM3_031
	call	Say
	jmp	SHORT L0C0F

T_DEM3_031	LABEL	BYTE
	DB	'#DEM3\DEM3_031#Sir, it may be dangerous. Let me try it.',0
L0C0F:
	JMPN	L0C93

H_0C12:
	SCRIPT	MSG_USE, OBJ_REDSHIRT, 20h, 0, H_0CA7
EvertsUsesPanel:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L0C1F
	retf

L0C1F:
	cmp	byte ptr [si+boulders_down], 4
	je	L0C93
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM3_030
	call	Say
	jmp	SHORT L0C92

T_DEM3_030	LABEL	BYTE
	DB	'#DEM3\DEM3_030#Sir, I think we should clear the rest of the rock'
	DB	's before we check out the device.',0
L0C92:
	retf

L0C93:
	push	8
	push	70h
	push	0D8h
	push	3
	push	RC_WALK
	SERVICE		; Walk(3, 216, 112, 8)
	add	sp, 0Ah
	retf

H_0CA7:
	SCRIPT	MSG_WALK_DONE, 8, 0, 0, H_0CC3
EvertsAtPanel:
	push	5
	push	-1
	push	-1
	push	OFFSET N_rusehn
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rusehn", -1, -1, 5)
	add	sp, 0Ch
	retf

; Everts' hand on the panel (anim msg 5), once the rubble is cleared:
; a line from everts_lines for each try, and the fifth kills him.
H_0CC3:
	SCRIPT	MSG_ANIM_DONE, 5, 0, 0, H_0D5F
EvertsTouchesPanel:
	cmp	word ptr [si+rubble_cleared], 1
	jne	L0D3F
	inc	word ptr [si+panel_tries]
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, word ptr [si+panel_tries]
	cmp	bx, 5
	jne	L0D40
	jmp	SHORT L0CE4

N_EFX3	LABEL	BYTE
	DB	'EFX3',0
L0CE4:
	push	OFFSET N_EFX3
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("EFX3")
	add	sp, 4
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM3_A32
	call	Say
	jmp	SHORT L0D15

T_DEM3_A32	LABEL	BYTE
	DB	'#DEM3\DEM3_A32#Aieeee!',0
L0D15:
	push	3
	push	-1
	push	-1
	push	OFFSET N_rkille
	push	3
	push	RC_ANIM2
	SERVICE		; Anim(3, "rkille", -1, -1, 3)
	add	sp, 0Ch
	push	6
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(6)
	add	sp, 4
	mov	byte ptr [si+RS_REDSHIRT_DEAD], 1
	mov	word ptr [si+everts_shocked], 1
L0D3F:
	retf

L0D40:
	shl	bx, 1
	mov	bx, word ptr cs:[bx+everts_lines]
	call	Say
	push	0
	push	9Bh
	push	0BEh
	push	3
	push	RC_WALK
	SERVICE		; Walk(3, 190, 155, 0)
	add	sp, 0Ah
	retf

H_0D5F:
	SCRIPT	MSG_ANIM_DONE, 3, 0, 0, H_0D6F
EvertsDead:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_018
	call	Say
	retf

H_0D6F:
	SCRIPT	MSG_USE, IT_STRICOR, 21h, 0, H_0DA0
SpockScansDoor:
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
	mov	bx, OFFSET T_DEM3_012
	call	Say
	retf

H_0DA0:
	SCRIPT	MSG_USE, IT_STRICOR, ANY, 0, H_0DD1
SpockScans:
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
	mov	bx, OFFSET T_DEM3_027
	call	Say
	retf

H_0DD1:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Eh, 0, H_0DD9
	jmp	SHORT McCoyScansDoor2

H_0DD9:
	SCRIPT	MSG_USE, IT_MTRICOR, 21h, 0, H_0DE1
McCoyScansDoor2:
	jmp	SHORT McCoyScansDoor

H_0DE1:
	SCRIPT	MSG_USE, IT_MTRICOR, 22h, 0, H_0E75
McCoyScansDoor:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscann
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscann", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_016
	call	Say
	jmp	SHORT L0E74

T_DEM3_016	LABEL	BYTE
	DB	'#DEM3\DEM3_016#This is incredible, Jim. I''m picking up faint lif'
	DB	'esign readings behind this door!',0
L0E74:
	retf

; Phasers on the door: no effect, then Spock objects.
H_0E75:
	SCRIPT	MSG_USE, IT_PHASERS, 0Eh, 0, H_0E7D
	jmp	SHORT PhaserDoor2

H_0E7D:
	SCRIPT	MSG_USE, IT_PHASERK, 0Eh, 0, H_0E85
PhaserDoor2:
	jmp	SHORT PhaserDoor3

H_0E85:
	SCRIPT	MSG_USE, IT_PHASERS, 21h, 0, H_0E8D
PhaserDoor3:
	jmp	SHORT PhaserDoor

H_0E8D:
	SCRIPT	MSG_USE, IT_PHASERK, 21h, 0, H_0EBB
PhaserDoor:
	inc	word ptr cs:door_shots
	cmp	word ptr cs:door_shots, 1
	jne	L0EA9
	mov	ax, 0
	mov	bx, OFFSET T_DEM3N009
	call	Say
L0EA9:
	cmp	word ptr cs:door_shots, 2
	jne	L0EBA
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM3_011
	call	Say
L0EBA:
	retf

; The android's hand on the panel, once the rubble is cleared: Kirk
; walks there (msg 7), reaches (anim msg 6), and on timer 3 the door
; opens if the hand has been repaired, +2 score.
H_0EBB:
	SCRIPT	MSG_USE, IT_HAND, 20h, 0, H_0F40
UseHandOnPanel:
	cmp	byte ptr [si+boulders_down], 4
	je	L0F25
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM3_005
	call	Say
	jmp	SHORT L0F24

T_DEM3_005	LABEL	BYTE
	DB	'#DEM3\DEM3_005#Captain, I would strongly recommend clearing all '
	DB	'the debris first.',0
L0F24:
	retf

L0F25:
	cmp	byte ptr [si+door_open], 1
	jne	L0F2C
	retf

L0F2C:
	push	7
	push	70h
	push	0D8h
	push	0
	push	RC_WALK
	SERVICE		; Walk(0, 216, 112, 7)
	add	sp, 0Ah
	retf

H_0F40:
	SCRIPT	MSG_WALK_DONE, 7, 0, 0, H_0F78
KirkAtPanel:
	push	6
	push	-1
	push	-1
	push	OFFSET N_kusehn
	push	0
	push	RC_ANIM2
	SERVICE		; Anim(0, "kusehn", -1, -1, 6)
	add	sp, 0Ch
	mov	byte ptr [si+RS_FALL], 3
	jmp	SHORT L0F68

N_MUR4E1	LABEL	BYTE
	DB	'MUR4E1',0
L0F68:
	push	OFFSET N_MUR4E1
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("MUR4E1")
	add	sp, 4
	retf

H_0F78:
	SCRIPT	MSG_ANIM_DONE, 6, 0, 0, H_0FB4
KirkPutsHand:
	push	0
	push	3Dh
	push	0D6h
	push	OFFSET N_panel
	push	0Fh
	push	RC_ANIM0
	SERVICE		; Anim0(15, "panel", 214, 61, 0)
	add	sp, 0Ch
	mov	word ptr [si+RS_TIMERS+6], 0Ah
	jmp	SHORT L0FA4

N_SE0FORCE	LABEL	BYTE
	DB	'SE0FORCE',0
L0FA4:
	push	OFFSET N_SE0FORCE
	mov	ax, RC_SFX
	push	ax
	SERVICE		; Sfx("SE0FORCE")
	add	sp, 4
	retf

H_0FB4:
	SCRIPT	MSG_USE, IT_STRICOR, 0Dh, 0, H_0FF5
SpockScansMiner2:
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
	cmp	byte ptr [si+miner_dead], 1
	jne	L0FEB
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM3_022
	call	Say
	retf

L0FEB:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM3_023
	call	Say
	retf

H_0FF5:
	SCRIPT	MSG_USE, IT_MTRICOR, 0Dh, 0, H_102F
McCoyScansMiner:
	push	0
	push	-1
	push	-1
	push	OFFSET N_mscann
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "mscann", -1, -1, 0)
	add	sp, 0Ch
	push	4
	push	RC_BRIDGESFX
	SERVICE		; BridgeSfx(4)
	add	sp, 4
	cmp	byte ptr [si+miner_dead], 1
	jne	L1025
	JMPN	L1115

L1025:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_023
	call	Say
	retf

; McCoy treats the miner (msgs 6, 7), +2 score.
H_102F:
	SCRIPT	MSG_USE, OBJ_MCCOY, 0Dh, 0, H_1037
	jmp	SHORT HealMiner

H_1037:
	SCRIPT	MSG_USE, IT_MEDKIT, 0Dh, 0, H_10AB
HealMiner:
	cmp	byte ptr [si+healed_miner], 1
	jne	L108B
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_015
	call	Say
	jmp	SHORT L108A

T_DEM3_015	LABEL	BYTE
	DB	'#DEM3\DEM3_015#I''ve done all I can. He just needs rest now.',0
L108A:
	retf

L108B:
	push	6
	push	7Bh
	push	0E6h
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 230, 123, 6)
	add	sp, 0Ah
	mov	byte ptr cs:in_cover, 0
	mov	byte ptr cs:kirk_fired, 0
	retf

H_10AB:
	SCRIPT	MSG_WALK_DONE, 6, 0, 0, H_10C7
McCoyAtMiner:
	push	7
	push	-1
	push	-1
	push	OFFSET N_museln
	push	2
	push	RC_ANIM2
	SERVICE		; Anim(2, "museln", -1, -1, 7)
	add	sp, 0Ch
	retf

H_10C7:
	SCRIPT	MSG_ANIM_DONE, 7, 0, 0, H_111F
MinerHealed:
	cmp	byte ptr [si+miner_dead], 1
	jne	L10D5
	jmp	SHORT L1115

L10D5:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_021
	call	Say
	mov	byte ptr [si+healed_miner], 1
	push	0
	push	6Ch
	push	0DAh
	push	OFFSET N_drmine
	push	0Dh
	push	RC_ANIM2
	SERVICE		; Anim(13, "drmine", 218, 108, 0)
	add	sp, 0Ch
	add	word ptr [si+score], 2
	push	0
	push	96h
	push	104h
	push	2
	push	RC_WALK
	SERVICE		; Walk(2, 260, 150, 0)
	add	sp, 0Ah
	mov	byte ptr [si+RS_FALL+2], 3
	retf

L1115:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_022
	call	Say
	retf

H_111F:
	SCRIPT	MSG_GET, 0Dh, 0, 0, H_112F
GetMiner:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_017
	call	Say
	retf

; Talking.
H_112F:
	SCRIPT	MSG_TALK, 0Dh, 0, 0, H_1145
TalkToMiner:
	cmp	byte ptr [si+healed_miner], 1
	jne	L1144
	mov	ax, OFFSET N_Brother_Kandrey
	mov	bx, OFFSET T_DEM3_F21
	call	Say
L1144:
	retf

H_1145:
	SCRIPT	MSG_TALK, OBJ_KIRK, 0, 0, H_1167
TalkToKirk:
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM3_002
	call	Say
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM3_029
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_026
	call	Say
	retf

H_1167:
	SCRIPT	MSG_TALK, OBJ_SPOCK, 0, 0, H_1177
TalkToSpock:
	mov	ax, OFFSET N_Mr_Spock
	mov	bx, OFFSET T_DEM3_028
	call	Say
	retf

H_1177:
	SCRIPT	MSG_TALK, OBJ_MCCOY, 0, 0, H_11EB
TalkToMcCoy:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L11CF
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_014
	call	Say
	jmp	SHORT L11CE

T_DEM3_014	LABEL	BYTE
	DB	'#DEM3\DEM3_014#I''m sorry, Jim. Ensign Everts is beyond my help.',0
L11CE:
	retf

L11CF:
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_025
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM3_003
	call	Say
	mov	ax, OFFSET N_Dr_McCoy
	mov	bx, OFFSET T_DEM3_024
	call	Say
	retf

H_11EB:
	SCRIPT	MSG_TALK, OBJ_REDSHIRT, 0, 0, H_1204
TalkToRedshirt:
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM3_036
	call	Say
	mov	ax, OFFSET N_Capt_Kirk
	mov	bx, OFFSET T_DEM3_004
	call	Say
	retf

; Looking at things.
H_1204:
	SCRIPT	MSG_LOOK, OBJ_KIRK, 0, 0, H_1213
LookAtKirk:
	sub	ax, ax
	mov	bx, OFFSET T_DEM3N004
	call	Say
	retf

H_1213:
	SCRIPT	MSG_LOOK, OBJ_SPOCK, 0, 0, H_1222
LookAtSpock:
	sub	ax, ax
	mov	bx, OFFSET T_DEM3N001
	call	Say
	retf

H_1222:
	SCRIPT	MSG_LOOK, OBJ_MCCOY, 0, 0, H_1231
LookAtMcCoy:
	sub	ax, ax
	mov	bx, OFFSET T_DEM3N002
	call	Say
	retf

H_1231:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_1293
LookAtDeadEverts:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	jne	L1289
	mov	ax, 0
	mov	bx, OFFSET T_DEM3N017
	call	Say
	jmp	SHORT L1288

T_DEM3N017	LABEL	BYTE
	DB	'#DEM3\DEM3N017#Ensign Everts lies dead, crushed by the boulder.',0
L1288:
	retf

L1289:
	mov	ax, OFFSET S_17BC
	mov	bx, OFFSET T_DEM3N003
	call	Say
	retf

H_1293:
	SCRIPT	MSG_LOOK, ANY, 0, 0, H_12D3
LookAtScene:
	mov	ax, 0
	mov	bx, OFFSET T_DEM3N010
	call	Say
	jmp	SHORT L12D2

T_DEM3N010	LABEL	BYTE
	DB	'#DEM3\DEM3N010#A cavern, deep in Mount Idyll.',0
L12D2:
	retf

H_12D3:
	SCRIPT	MSG_LOOK, OBJ_REDSHIRT, 0, 0, H_1352
LookAtRedshirt:
	cmp	byte ptr [si+RS_REDSHIRT_DEAD], 1
	je	L12E9
	mov	ax, OFFSET N_Ensign_Everts
	mov	bx, OFFSET T_DEM3N003
	call	Say
	retf

L12E9:
	mov	ax, 0
	mov	bx, OFFSET T_DEM3N018
	call	Say
	jmp	SHORT L1351

T_DEM3N018	LABEL	BYTE
	DB	'#DEM3\DEM3N018#The crushed body of Ensign Everts reminds you of '
	DB	'your poor command judgement.',0
L1351:
	retf

H_1352:
	SCRIPT	MSG_LOOK, 0Dh, 0, 0, H_1372
LookAtMiner:
	cmp	byte ptr [si+healed_miner], 1
	jne	L1368
	mov	ax, OFFSET S_17BC
	mov	bx, OFFSET T_DEM3N000
	call	Say
	retf

L1368:
	mov	ax, OFFSET S_17BC
	mov	bx, OFFSET T_DEM3N006
	call	Say
	retf

H_1372:
	SCRIPT	MSG_LOOK, 9, 0, 0, H_13C4
LookAtBoulder1:
	mov	ax, 0
	mov	bx, OFFSET T_DEM3N011
	call	Say
	jmp	SHORT L13C3

T_DEM3N011	LABEL	BYTE
	DB	'#DEM3\DEM3N011#A huge boulder sits upon a large pile of rubble.',0
L13C3:
	retf

H_13C4:
	SCRIPT	MSG_LOOK, 0Ah, 0, 0, H_1432
LookAtBoulder2:
	mov	ax, 0
	mov	bx, OFFSET T_DEM3N013
	call	Say
	jmp	SHORT L1431

T_DEM3N013	LABEL	BYTE
	DB	'#DEM3\DEM3N013#A large pile of rubble blocks what appears to be '
	DB	'a large metallic structure.',0
L1431:
	retf

H_1432:
	SCRIPT	MSG_LOOK, 0Bh, 0, 0, H_14A0
LookAtBoulder3:
	mov	ax, 0
	mov	bx, OFFSET T_DEM3N013_2
	call	Say
	jmp	SHORT L149F

T_DEM3N013_2	LABEL	BYTE
	DB	'#DEM3\DEM3N013#A large pile of rubble blocks what appears to be '
	DB	'a large metallic structure.',0
L149F:
	retf

H_14A0:
	SCRIPT	MSG_LOOK, 0Ch, 0, 0, H_1511
LookAtBoulder4:
	mov	ax, 0
	mov	bx, OFFSET T_DEM3N020
	call	Say
	jmp	SHORT L1510

T_DEM3N020	LABEL	BYTE
	DB	'#DEM3\DEM3N020#You notice what appears to be a man''s arm stickin'
	DB	'g out from beneath the rubble.',0
L1510:
	retf

H_1511:
	SCRIPT	MSG_LOOK, 22h, 0, 0, H_158C
LookAtStructure:
	mov	ax, 0
	mov	bx, OFFSET T_DEM3N016
	call	Say
	jmp	SHORT L158B

T_DEM3N016	LABEL	BYTE
	DB	'#DEM3\DEM3N016#A structure built into the surrounding rock. It m'
	DB	'ust have been buried here for millennia.',0
L158B:
	retf

H_158C:
	SCRIPT	MSG_LOOK, 0Eh, 0, 0, H_1594
	jmp	SHORT LookAtDoor

H_1594:
	SCRIPT	MSG_LOOK, 21h, 0, 0, H_162F
LookAtDoor:
	cmp	byte ptr [si+door_open], 1
	je	L15EA
	mov	ax, 0
	mov	bx, OFFSET T_DEM3N012
	call	Say
	jmp	SHORT L15E9

T_DEM3N012	LABEL	BYTE
	DB	'#DEM3\DEM3N012#A large metallic door is set in the structure.',0
L15E9:
	retf

L15EA:
	mov	ax, 0
	mov	bx, OFFSET T_DEM3N014
	call	Say
	jmp	SHORT L162E

T_DEM3N014	LABEL	BYTE
	DB	'#DEM3\DEM3N014#A long tunnel descends into the mountain.',0
L162E:
	retf

H_162F:
	SCRIPT	MSG_LOOK, 0Fh, 0, 0, H_1637
	jmp	SHORT LookAtPanel

H_1637:
	SCRIPT	MSG_LOOK, 20h, 0, 0, H_169C
LookAtPanel:
	mov	ax, 0
	mov	bx, OFFSET T_DEM3N019
	call	Say
	jmp	SHORT L169B

T_DEM3N019	LABEL	BYTE
	DB	'#DEM3\DEM3N019#This looks like some of the hand security panels '
	DB	'on the Enterprise.',0
L169B:
	retf

H_169C:
	SCRIPT	MSG_LOOK, 8, 0, 0, Talk
LookAtLight:
	mov	ax, 0
	mov	bx, OFFSET T_DEM3N015
	call	Say
	jmp	SHORT L16F8

T_DEM3N015	LABEL	BYTE
	DB	'#DEM3\DEM3N015#A pulsing red light is set in the structure above'
	DB	' the door.',0
L16F8:
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
	DW	214,61, 226,61, 226,72, 214,72
	DW	21h, 4	; id, points
	DW	131,13, 211,13, 211,100, 131,100
	DW	22h, 4	; id, points
	DW	65,0, 251,0, 251,95, 65,95
rdf_objects_end	LABEL	BYTE
rdf_exits	LABEL	BYTE
	DW	0, 4	; id, points
	DW	164,57, 180,57, 180,64, 164,64
	DW	1, 4	; id, points
	DW	40,195, 280,195, 280,199, 40,199
rdf_exits_end	LABEL	BYTE
rdf_regions	LABEL	BYTE
rdf_regions_end	LABEL	BYTE
rdf_bans	LABEL	BYTE
rdf_bans_end	LABEL	BYTE
N_Capt_Kirk	LABEL	BYTE
	DB	'Capt. Kirk',0
N_Dr_McCoy	LABEL	BYTE
	DB	'Dr. McCoy',0
N_Mr_Spock	LABEL	BYTE
	DB	'Mr. Spock',0
N_Ensign_Everts	LABEL	BYTE
	DB	'Ensign Everts',0
N_Brother_Kandrey	LABEL	BYTE
	DB	'Brother Kandrey',0
N_wes	LABEL	BYTE
	DB	'wes',0
S_17BC	LABEL	BYTE
	DB	0
T_DEM3N004	LABEL	BYTE
	DB	'#DEM3\DEM3N004#James T. Kirk. Captain of the Enterprise.',0
T_DEM3N001	LABEL	BYTE
	DB	'#DEM3\DEM3N001#Commander Spock; curious about what lies ahead.',0
T_DEM3N002	LABEL	BYTE
	DB	'#DEM3\DEM3N002#Doctor Leonard McCoy, glad that the cave provides'
	DB	' some shelter from the breeze.',0
T_DEM3N003	LABEL	BYTE
	DB	'#DEM3\DEM3N003#Ensign Everts, wary of more ambushes.',0
T_DEM3N006	LABEL	BYTE
	DB	'#DEM3\DEM3N006#One of the Acolytes, who was trapped by the the r'
	DB	'ockfall.',0
T_DEM3N000	LABEL	BYTE
	DB	'#DEM3\DEM3N000#Brother Kandrey is barely conscious, and is lying'
	DB	' still, trying to regain his strength.',0
T_DEM3_002	LABEL	BYTE
	DB	'#DEM3\DEM3_002#A gateway to an alien race. The wonders of the ga'
	DB	'laxy are endless, aren''t they, Mr. Spock?',0
T_DEM3_029	LABEL	BYTE
	DB	'#DEM3\DEM3_029#Indeed, Captain.',0
T_DEM3_026	LABEL	BYTE
	DB	'#DEM3\DEM3_026#They can also be damned cold.',0
T_DEM3_028	LABEL	BYTE
	DB	'#DEM3\DEM3_028#I recommend as thorough an analysis of this area '
	DB	'as possible.',0
T_DEM3_025	LABEL	BYTE
	DB	'#DEM3\DEM3_025#Jim, the next time you need medical help on a sno'
	DB	'wball...',0
T_DEM3_003	LABEL	BYTE
	DB	'#DEM3\DEM3_003#Bones..',0
T_DEM3_024	LABEL	BYTE
	DB	'#DEM3\DEM3_024#I''ll probably end up coming along.',0
T_DEM3_036	LABEL	BYTE
	DB	'#DEM3\DEM3_036#No sign of demons, Klingons, or other hostiles, C'
	DB	'aptain. I promise I''ll let you know the instant something appear'
	DB	's.',0
T_DEM3_004	LABEL	BYTE
	DB	'#DEM3\DEM3_004#Don''t be too anxious, Ensign. We may want to talk'
	DB	' with them.',0
T_DEM3_001	LABEL	BYTE
	DB	'#DEM3\DEM3_001#Assume firing positions.',0
T_DEM3_020	LABEL	BYTE
	DB	'#DEM3\DEM3_020#I''m picking up weak vital signs. If we don''t dig '
	DB	'him out soon, we''re going to lose him!',0
T_DEM3_010	LABEL	BYTE
	DB	'#DEM3\DEM3_010#Captain, there are several weak points in the cav'
	DB	'e-in''s structure. Careful use of our phasers, from the top down,'
	DB	' should be able to clear it.',0
T_DEM3_023	LABEL	BYTE
	DB	'#DEM3\DEM3_023#This man is badly hurt, and suffering from shock '
	DB	'and exposure as well.',0
T_DEM3_021	LABEL	BYTE
	DB	'#DEM3\DEM3_021#It was a near thing, but he''ll live.',0
T_DEM3_022	LABEL	BYTE
	DB	'#DEM3\DEM3_022#The miner is dead.',0
T_DEM3_017	LABEL	BYTE
	DB	'#DEM3\DEM3_017#Dammit, Jim, I''m a doctor, not a bellhop. This ma'
	DB	'n''s too hurt to be moved.',0
	DB	'#DEM3\DEM3N005#Nothing happens.',0
	DB	'#DEM3\DEM3_033#I think I was shocked, sir.',0
	DB	'#DEM3\DEM3_035#That was definitely a mild shock.',0
	DB	'#DEM3\DEM3_034#Ouch, that hurt.',0
	DB	'#DEM3\DEM3_B32#Aieeeee.',0
T_DEM3_018	LABEL	BYTE
	DB	'#DEM3\DEM3_018#He''s dead Jim.',0
everts_lines	LABEL	BYTE	; what Everts says on each try at the panel
	DB	0, 0, 10h, 1Eh, 30h, 1Eh, 5Bh, 1Eh, 8Ch, 1Eh, 0ACh, 1Eh
T_DEM3_012	LABEL	BYTE
	DB	'#DEM3\DEM3_012#Fascinating, Captain. This door is made of an unk'
	DB	'nown material. It is clearly built by an alien race we have no k'
	DB	'nowledge of.',0
T_DEM3_027	LABEL	BYTE
	DB	'#DEM3\DEM3_027#Fascinating...  I''m registering low-intensity shi'
	DB	'elding unlike anything we''ve encountered before.  That kept this'
	DB	' door -- and whatever is behind it -- hidden from the ship''s sen'
	DB	'sors and earlier tricorder readings.',0
T_DEM3N009	LABEL	BYTE
	DB	'#DEM3\DEM3N009#There is no apparent effect.',0
T_DEM3_011	LABEL	BYTE
	DB	'#DEM3\DEM3_011#Captain, this course of action is ineffectual.',0
T_DEM3N007	LABEL	BYTE
	DB	'#DEM3\DEM3N007#The fit is perfect, but something seems to be sho'
	DB	'rting out.',0
T_DEM3N008	LABEL	BYTE
	DB	'#DEM3\DEM3N008#The hand''s circuitry triggers a connection, and t'
	DB	'he door opens.',0
T_DEM3_019	LABEL	BYTE
	DB	'#DEM3\DEM3_019#He''s dead, Jim...',0
S_2185	LABEL	BYTE
	DB	'There is a boulder check error.',0
	DB	'The walk should be done now.',0
T_DEM3_F21	LABEL	BYTE
	DB	'#DEM3\DEM3_F21#Oh, thank you, kind souls, for saving my life. Le'
	DB	't me rest here for a little before returning to report this mira'
	DB	'cle to Prelate Angiven.',0
talk_buf	LABEL	BYTE
	DW	0, 0, 0	; speaker, line, 0

RDF	ENDS
	END
