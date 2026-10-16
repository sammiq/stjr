/* seg015: music and digitised sound */

#include <dos.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mem.h"
#include "list.h"
#include "ems.h"
#include "cache.h"
#include "resource.h"
#include "sound.h"

int toupper(int c);
int isalnum(int c);

/* seg 2505: the digital sound driver interface (asm/t35052) */
int sub_35345(int a, int b);
void sub_35373(int a, int b);
void sub_35388(char far *msg);
void sub_3571B(DmaReq far *req);
unsigned sub_3577A(void);
void sub_357C0(void);
void sub_357EB(DmaReq far *req);
int sub_357FE(void);
int far *sub_35828(void);
void sub_3585E(int on);
int sub_3586D(void);
void sub_35873(char far *buf, unsigned len);
int sub_3588D(char far *buf, unsigned len);
int sub_358B3(void);

/* seg019: save game I/O */
void SaveWrite(void *p, int n);
void SaveRead(void *p, int n);

int midi_handle;
extern int sb_port;
extern int sb_irq;
void far *seq_state[NUM_SEQ];
int seq_handles[NUM_SEQ];
int seq_ids[NUM_SEQ];
extern char sfx_name[];
extern int stream_done;

char far *music_data = 0;

void PlaySeq(unsigned slot, int seq)
{
    StopSeq(slot);
    if (seq == -1)
        return;
    seq_handles[slot] = AIL_register_sequence(midi_handle, music_data, seq, seq_state[slot], 0);
    seq_ids[slot] = seq;
    AIL_start_sequence(midi_handle, seq_handles[slot]);
}

