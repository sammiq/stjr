/* sound.h - music (Miles AIL 2.0 XMIDI drivers) and digitised sound */

#ifndef SOUND_H
#define SOUND_H

#include "list.h"
#include "mem.h"
#include "cache.h"

/* AIL driver description (AIL_describe_driver). */
typedef struct drvr_desc {
    unsigned min_API_version;   /* 00 */
    unsigned drvr_type;         /* 02 2 = digital, 3 = XMIDI */
    char data_suffix[4];        /* 04 timbre file suffix */
    char far *dev_name_table;   /* 08 */
    int default_IO;             /* 0C */
    int default_IRQ;            /* 0E */
    int default_DMA;            /* 10 */
    int default_DRQ;            /* 12 */
    int service_rate;           /* 14 */
    unsigned display_size;      /* 16 */
} drvr_desc;

#define DSP_DRVR    2
#define XMIDI_DRVR  3

/* A timbre in the global timbre library (.gtl) directory. */
typedef struct GTLEntry {
    char patch;                 /* 00 */
    char bank;                  /* 01 -1 ends the directory */
    long offset;                /* 02 */
} GTLEntry;

/* Music sequence slot, kept in least recently used order (slots 1-7). */
typedef struct SeqNode {
    Node node;                  /* 00 */
    int slot;                   /* 04 */
} SeqNode;

/* Digital output request (seg 2505 driver). */
typedef struct DmaReq {
    char far *buf;              /* 00 */
    unsigned len;               /* 04 */
    int unk6;                   /* 06 */
    int unk8;                   /* 08 */
    unsigned rate;              /* 0A */
} DmaReq;

#define NUM_SEQ     8
#define NUM_CHAN    4
#define HALF        0x1000      /* half of the DMA buffer */

/* seg028: AIL */
void AIL_startup(void);
void AIL_shutdown(char far *msg);
int AIL_register_driver(void far *driver);
drvr_desc far *AIL_describe_driver(int h);
int AIL_detect_device(int h, unsigned IO, unsigned IRQ, unsigned DMA, unsigned DRQ);
void AIL_init_driver(int h, unsigned IO, unsigned IRQ, unsigned DMA, unsigned DRQ);
unsigned AIL_state_table_size(int h);
int AIL_register_sequence(int h, void far *data, int seq, void far *state, void far *ctrl);
void AIL_release_sequence_handle(int h, int seq);
unsigned AIL_default_timbre_cache_size(int h);
void AIL_define_timbre_cache(int h, void far *cache, unsigned size);
void AIL_install_timbre(int h, int bank, int patch, void far *data);
void AIL_start_sequence(int h, int seq);
void AIL_stop_sequence(int h, int seq);
int AIL_sequence_status(int h, int seq);
void sub_3B584(int h, char far *s);

extern int music_on;
extern int sfx_on;
extern int midi_ok;
extern int digi_ok;
extern int midi_driver;
extern int digi_driver;

void HookTimer(void);
void UnhookTimer(void);
void SoundInit(void);
int ParseBlaster(drvr_desc *desc, char *a, char *b);
void SoundStop(void);
void StopSeq(unsigned slot);
void PlaySeq(unsigned slot, int seq);
int MusicPlaying(void);
void StopVoc(void);
void StopAllSound(void);
void LoadMusic(char *name);
int SoundShutdown(void);
void PlayMusic(int seq, int next);
int ReadVoc(char far *buf, int len);
void MusicTick(void);
void SetMusicOn(int on);
void PlaySfxSeq(int seq);
void SetSfxOn(int on);
int GetMusicSeq(void);
void SaveMusicState(void);
void LoadMusicState(void);
void DigiInit(void);
void DigiTick(void);
void DigiStop(void);
void DigiPlay(DmaReq far *req);
int DigiStatus(void);
void DigiStart(void);
void DigiShutdown(void);
void PlayVoc(char *name);
int PlaySfx(char *name);
void StreamTick(void);
void MixFrame(void);
void MixSamples(char far *dst, char far *src, int n);
int MixVoc(char far *dst, SndChan *ch, unsigned n);

#endif
