/* seg015: music and digitised sound
 *
 * The sequel's sound system is new: both music and speech/effects go
 * through Miles AIL drivers (.ADV), voices are read from .vcc archives
 * (Creative Voice or Interplay ACMP compressed) and mixed in software. */

#include <dos.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <io.h>
#include "mem.h"
#include "list.h"
#include "ems.h"
#include "cache.h"
#include "resource.h"
#include "sound.h"

/* seg019: save game I/O */
void SaveWrite(void *p, int n);
void SaveRead(void *p, int n);
int tolower(int c);

void Fatal(char *fmt, ...);             /* fatal error */
void Nop(char *fmt, ...);               /* (debug message, compiled out) */
void StartTalk(int a, char *s, int b, int c, int d, int e);   /* seg000 */

/* A sound stream (far data): a voice file on disk or in EMS. */
typedef struct Stream {
    unsigned mode;                      /* 00 1 file, 2 EMS; 0x4000 ACMP */
    int buf_state[2];                   /* 02 per AIL buffer: 1 the last */
    long start;                         /* 06 */
    long pos;                           /* 0A */
    unsigned long size;                 /* 0E left in the block (EMS: all) */
    int rate;                           /* 12 */
    union {
        int fd;                         /* 14 */
        MemHandle ems[8];               /* 14 32K pages */
    };
    struct Acmp { char state[0x220]; } acmp;    /* 24 ACMP decoder state */
} Stream;

/* A .vcc voice archive. */
typedef struct Vcc {
    int fd;                             /* 00 -1 / 0: free */
    char name[14];                      /* 02 */
    int count;                          /* 10 entries */
    MemHandle dir;                      /* 12 */
    int acmp;                           /* 14 compressed (CMPFILES) */
} Vcc;

typedef struct VccEntry {
    char name[8];                       /* 00 */
    long offset;                        /* 08 */
    long size;                          /* 0C */
} VccEntry;

/* AIL's sound buffer. */
typedef struct SndBuf {
    unsigned pack_type;                 /* 00 */
    unsigned sample_rate;               /* 02 */
    char far *data;                     /* 04 */
    unsigned long len;                  /* 08 */
} SndBuf;

/* A music suite (.sui): its raw samples and its effects. */
typedef struct SuiteSfx {
    char name[9];                       /* 00 voice file, or "" */
    unsigned char keep;                 /* 09 */
    int raw;                            /* 0A raw sample, or -1 */
} SuiteSfx;

typedef struct Suite {
    char raws[8][10];                   /* 00 */
    int unknown;                        /* 50 */
    SuiteSfx sfx[1];                    /* 52 */
} Suite;

typedef struct Raw {
    MemHandle h;
    unsigned size;
} Raw;

typedef struct Mix {
    MemHandle h;
    unsigned pos;
    unsigned left;
} Mix;

/* AIL digital sound */
void AIL_register_sound_buffer(int h, int n, SndBuf far *b);
void AIL_format_sound_buffer(int h, SndBuf far *b);
int AIL_sound_buffer_status(int h, int n);
void AIL_start_digital_playback(int h);
void AIL_stop_digital_playback(int h);
/* seg028 (MASM 5.0) keeps 31 characters of a name */
#define AIL_set_digital_playback_volume AIL_set_digital_playback_volum
#define AIL_set_digital_playback_panpot AIL_set_digital_playback_panpo
void AIL_set_digital_playback_volume(int h, int v);
void AIL_set_digital_playback_panpot(int h, int p);

/* the ACMP decoder (seg002) */
void AcmpOpen(struct Acmp far *st, Stream far *s, unsigned (far *read)(Stream far *, char *, unsigned));
unsigned AcmpRead(struct Acmp far *st, char far *buf, unsigned n);
void AcmpClose(struct Acmp far *st);
void MixVoice(char far *dst, char far *src, unsigned n);

void ResumeMusic(void);
void EndMusic(void);
void PlayMusicSeq(int seq);
int PlayDigiSfx(char *name, int vol, int pan, int loop);
unsigned VocRead(Stream far *s, char far *buf, unsigned n);
int Quiet(unsigned char far *p, unsigned n);
int FindVCC(char *path, long *size);
void SaveVCCs(int load);
void CloseVCC(char *name);
int OpenVCC(char *name);
void AddSamples(int far *dst, unsigned char far *src, unsigned n);
void ClampSamples(char far *dst, int far *src, unsigned n, int k);
void LoadSuite(void);
void FreeSuite(void);
void LoadMixTables(void);
void FreeMixTables(void);
void StopAllSound(void);

extern char voc_path[];                 /* where the voice files are */
extern long dword_42A9E;
extern MemHandle mix_tabs[4];
static int far mix_buf[4096];         /* the mixer's 16-bit sums */

extern unsigned music_card;             /* sound card for music (the config) */
extern int digi_card;                   /* and for speech */
extern int cfg_io;                      /* digital card overrides (0: the driver's) */
extern int cfg_irq;
extern int cfg_dma;
extern int cfg_mio;                     /* music card port override */
extern int digi_handle;
extern char far *digi_buf;
static char sfx_name[64];                      /* the looping effect */
static char voice_name[10];
static int sfx_vol;
static int sfx_pan;
static int sfx_loop;
static int voice_on;
static int midi_handle;
static char midi_suffix[4];                    /* timbre file extension */
static void far *seq_state[NUM_SEQ];
static int seq_handles[NUM_SEQ];
static unsigned seq_ids[NUM_SEQ];
static char music_name[9];
static char music_var;                         /* variant letter of the music file */
static char music_file[9];
static SeqNode seq_nodes[NUM_SEQ];
static List seq_list;
static int suite_vol;
static int suite_pan;
static Raw raws[8];
static Mix mixes[4];
static unsigned timbre_cache_size;
static MemHandle suite_handle;                 /* the music's effects */
static int word_410C6;                         /* never used */
static unsigned long sound_ticks;


int back_sound = 1;
int music_on = 1;
int sfx_on = 1;
int sound_purged = 0;                   /* no sound (no driver, or purged) */
int digi_loaded = 0;
int word_3D2C4 = 0;
char far *music_data = 0;
int word_3D2CA = 0;
int mix_count = 0;                      /* raw samples playing */
int cur_seq = -1;                       /* playing in slot 0 */
int next_seq = -1;                      /* to play after it */
unsigned char sfx_vol_next = 0x7F;      /* for the next BridgeSfx */
unsigned char sfx_pan_next = 0x40;

void SoundTick(void)
{
    sound_ticks++;
}

void SoundStartup(void)
{
    AIL_startup();
}

void SoundShutdownAIL(void)
{
    AIL_shutdown("");
}

/* Load the music and speech drivers for the configured cards. */
/* (99.97%: in the timbre loop the target copies the directory pointer
 * from di where this copies it from ax.) */
void SoundInit(void)
{
    char *drivers[12][2] = {
        { 0, 0 }, { "PCSPKR4", 0 }, { "ADLIB", 0 }, { "ADLIBG", "ALGDIG" },
        { "SBFM", "SBDIG" }, { "SBP1FM", "SBPDIG" }, { "SBP2FM", "SBPDIG" },
        { "PASFM", "PASDIG" }, { "PASOPL", "PASDIG" }, { "MT32MPU", 0 },
        { "MT32MPU", 0 }, { 0, 0 }
    };
    MemHandle h;
    char far *midi_drv;
    char far *digi_drv;
    drvr_desc far *desc;
    int io;
    int irq;
    int dma;
    int i;
    int *id;

    SoundStartup();
    strcpy(music_name, "");
    music_data = 0;
    ListInit(&seq_list);
    for (i = 1, id = &seq_ids[1]; i < NUM_SEQ; i++) {
        seq_nodes[i].slot = i;
        seq_nodes[i].kind = 0;
        seq_nodes[i].seq = -1;
        ListAdd(&seq_list, &seq_nodes[i].node);
        *id++ = -1;
    }
    if (sound_purged)
        return;
    if (music_card >= 12 || drivers[music_card][0] == 0)
        goto none;
    midi_drv = PushMem(GetFileSize(drivers[music_card][0], "ADV"));
    LoadFilePacked(drivers[music_card][0], "ADV", midi_drv);
    if (drivers[digi_card][1]) {
        digi_loaded = 1;
        digi_drv = PushMem(GetFileSize(drivers[digi_card][1], "ADV"));
        LoadFilePacked(drivers[digi_card][1], "ADV", digi_drv);
        digi_buf = PushMem(0x5624);
    }
    if (digi_loaded) {
        if ((digi_handle = AIL_register_driver(digi_drv)) == -1) {
            PopMem();
            PopMem();
            digi_loaded = 0;
        } else {
            desc = AIL_describe_driver(digi_handle);
            i = cfg_io ? cfg_io : desc->default_IO;
            irq = cfg_irq ? cfg_irq : desc->default_IRQ;
            dma = cfg_dma ? cfg_dma : desc->default_DMA;
            if (desc->drvr_type == DSP_DRVR && AIL_detect_device(digi_handle, i, irq, dma, dma))
                AIL_init_driver(digi_handle, i, irq, dma, dma);
            else {
                PopMem();
                PopMem();
                digi_loaded = 0;
            }
        }
    }
    if ((midi_handle = AIL_register_driver(midi_drv)) == -1) {
        SoundShutdownAIL();
        SoundStartup();
        sound_purged = 1;
        return;
    }
    desc = AIL_describe_driver(midi_handle);
    io = cfg_mio ? cfg_mio : desc->default_IO;
    if (desc->drvr_type != XMIDI_DRVR)
        goto fail;
    if (AIL_detect_device(midi_handle, io, desc->default_IRQ, desc->default_DMA, desc->default_DRQ) == 0)
        goto fail;
    AIL_init_driver(midi_handle, io, desc->default_IRQ, desc->default_DMA, desc->default_DRQ);
    i = AIL_state_table_size(midi_handle);
    {
        void far **s;
        int *sh;

        for (sh = seq_handles, s = seq_state; s < &seq_state[NUM_SEQ]; s++) {
            *s = PushMem(i);
            *sh++ = -1;
        }
    }
    if (desc->data_suffix[0])
        MemCpy(midi_suffix, desc->data_suffix, 4);
    if (music_card == 1)
        MemCpy(midi_suffix, "pc", 4);
    else if (music_card == 9)
        MemCpy(midi_suffix, "gm", 4);
    if ((timbre_cache_size = AIL_default_timbre_cache_size(midi_handle)) != 0) {
        char far *cache;
        GTLEntry far *e;
        char far *gtl;

        cache = PushMem(timbre_cache_size);
        AIL_define_timbre_cache(midi_handle, cache, timbre_cache_size);
        h = getanyfile("trek2", midi_suffix);
        gtl = LockMem(h);
        for (e = (GTLEntry far *)gtl; e->bank != -1; e++)
            AIL_install_timbre(midi_handle, e->bank, e->patch, gtl + (unsigned)e->offset);
        UnlockMem(h);
        FreeAnyFile(h);
    }
    sfx_on = music_on = 1;
    return;
fail:
    SoundShutdownAIL();
    SoundStartup();
none:
    sound_purged = 1;
}

void SoundClose(void)
{
    SoundShutdownAIL();
}

void StopSeq(unsigned slot)
{
    if (seq_handles[slot] != -1) {
        AIL_stop_sequence(midi_handle, seq_handles[slot]);
        AIL_release_sequence_handle(midi_handle, seq_handles[slot]);
        seq_handles[slot] = -1;
        seq_ids[slot] = -1;
    }
}

void PlaySeq(unsigned slot, int seq)
{
    StopSeq(slot);
    if (seq == -1)
        return;
    seq_handles[slot] = AIL_register_sequence(midi_handle, music_data, seq, seq_state[slot], 0);
    seq_ids[slot] = seq;
    AIL_start_sequence(midi_handle, seq_handles[slot]);
}

void SaveMusicState(void)
{
    SaveWrite(music_name, 9);
    SaveWrite(&music_var, 1);
}

void LoadMusicState(void)
{
    char name[9];
    char var;

    SaveRead(name, 9);
    SaveRead(&var, 1);
    LoadMusic(name, var);
}

/* Load name's music (var: the variant letter, 0 for none). */
void LoadMusicData(char *name, char var)
{
    StopAllSound();
    if (_stricmp(name, music_name) == 0 && tolower(var) == music_var)
        return;
    strcpy(music_name, name);
    _strlwr(music_name);
    music_var = tolower(var);
    if (var)
        sprintf(music_file, "%.7s%c", music_name, var);
    else
        sprintf(music_file, "%.8s", music_name);
    if (sound_purged || name[0] == 0)
        return;
    if (music_data)
        PopMem();
    music_data = PushMem(GetFileSize(music_file, midi_suffix));
    LoadFilePacked(music_file, midi_suffix, music_data);
    if (suite_handle)
        FreeSuite();
    LoadSuite();
}

/* A new piece of music plays its intro ('i' variant) to the end first. */
void LoadMusic(char *name, char var)
{
    int on;

    if (_stricmp(name, music_name) && sound_purged == 0) {
        on = music_on;
        LoadMusicData(name, 'i');
        music_on = 1;
        PlayMusic(0, -1);
        while (cur_seq != -1)
            MusicTick();
        music_on = on;
    }
    LoadMusicData(name, var);
}

int sound_closed = 0;

int PurgeSound(void)
{
    int i;

    if (sound_purged)
        return 0;
    SoundClose();
    SoundStartup();
    if (music_data)
        PopMem();
    FreeSuite();
    sound_purged = 1;
    if (timbre_cache_size)
        PopMem();
    for (i = 0; i != NUM_SEQ; i++)
        PopMem();
    if (digi_loaded) {
        PopMem();
        PopMem();
    }
    PopMem();
    return sound_closed = 1;
}

/* (89%: the target loads seq into cx and copies it to ax for the push.) */
void PlayMusicSeq(int seq)
{
    cur_seq = seq;
    next_seq = seq;
    PlaySeq(0, seq);
}

void StopMusic(void)
{
    StopSeq(0);
    next_seq = cur_seq = -1;
}

void EndMusic(void)
{
    StopSeq(0);
    cur_seq = -1;
}

void ResumeMusic(void)
{
    PlayMusicSeq(next_seq);
}

void SaveMusicSeq(void)
{
    SaveWrite(&next_seq, 2);
}

void LoadMusicSeq(void)
{
    SaveRead(&next_seq, 2);
    cur_seq = -1;
    if (sound_purged == 0 && music_on)
        ResumeMusic();
}

/* Play seq (-1: next_seq, 0xFE: none), then next (-1: as before, 0xFE:
 * none). */
void PlayMusic(int seq, int next)
{
    int queued;

    queued = cur_seq != next_seq;
    if (next == seq)
        queued = 0;
    if (next == 0xFE)
        next_seq = -1;
    else if (next != -1)
        next_seq = next;
    if (seq == -1)
        seq = next_seq;
    else if (seq == 0xFE)
        seq = -1;
    if (cur_seq != seq && !(queued && next_seq == seq)) {
        cur_seq = seq;
        if (music_on && sound_purged == 0)
            PlaySeq(0, seq);
    }
}

void SetMusicOn(int on)
{
    if (sound_purged == 0 && music_on != on) {
        if ((music_on = on) != 0)
            ResumeMusic();
        else
            EndMusic();
    }
}

/* ---- digitised sound: a voice stream and an effects stream ---- */

Stream far voice_stream;                /* far data 0000 */
Stream far sfx_stream;                  /* far data 0244 */

extern SndBuf snd_buf;                  /* AIL sound buffer being filled */
extern int stream_acmp;                 /* the file being opened is ACMP */
extern Vcc vccs[4];

int StreamActive(Stream far *s);
void StreamClose(Stream far *s);
int StreamOpen(char *name, Stream far *s, int mode);
int PlaySfxFile(char *name);
void PlayVoice(char *name);
int PlayDigi(char *name, int vol, int pan, int loop);
void StopSfxKind(int mask);
void StopMix(void);
void CloseVocFd(int fd);

void StopDigi(void)
{
    if (digi_loaded && (StreamActive(&sfx_stream) || StreamActive(&voice_stream))) {
        AIL_stop_digital_playback(digi_handle);
        StreamClose(&sfx_stream);
    }
}

void ResumeSfxLoop(void)
{
    if (digi_loaded && sfx_loop)
        PlayDigiSfx(sfx_name, sfx_vol, sfx_pan, 1);
}

void StopSfxLoop(void)
{
    StopDigi();
    sfx_loop = 0;
}

void SaveSfxState(void)
{
    SaveWrite(&sfx_loop, 2);
    SaveWrite(sfx_name, 64);
    SaveWrite(&sfx_vol, 2);
    SaveWrite(&sfx_pan, 2);
    SaveWrite(&voice_on, 2);
    SaveWrite(voice_name, 10);
}

void LoadSfxState(void)
{
    SaveRead(&sfx_loop, 2);
    SaveRead(sfx_name, 64);
    SaveRead(&sfx_vol, 2);
    SaveRead(&sfx_pan, 2);
    SaveRead(&voice_on, 2);
    SaveRead(voice_name, 10);
    if (sound_purged == 0) {
        if (sfx_on)
            ResumeSfxLoop();
        if (voice_on)
            PlayVoice(voice_name);
    }
}

/* (92%: the target has an unused 2-byte frame slot.) */
int PlayDigi(char *name, int vol, int pan, int loop)
{
    if (sound_purged || digi_loaded == 0)
        return 0;
    StopMix();
    StopSfxLoop();
    sfx_vol = vol;
    sfx_pan = pan;
    sfx_loop = loop;
    if (sfx_on == 0)
        return 0;
    if (PlaySfxFile(name) == 0)
        return 0;
    strcpy(sfx_name, name);
    AIL_set_digital_playback_volume(digi_handle, vol);
    AIL_set_digital_playback_panpot(digi_handle, pan);
}

int PlayDigiSfx(char *name, int vol, int pan, int loop)
{
    StopSfxKind(2);
    return PlayDigi(name, vol, pan, loop);
}

/* Close fd unless it's an open .vcc archive. */
void CloseVocFd(int fd)
{
    int i;
    Vcc *v;

    if (fd != -1) {
        for (i = 0, v = vccs; v < &vccs[4]; i++, v++)
            if (v->fd == fd)
                break;
        if (i == 4)
            _dos_close(fd);
    }
}

void CloseVocFile(int fd)
{
    CloseVocFd(fd);
    sfx_loop = word_3D2C4 = (int)(dword_42A9E = 0);
}

/* 0: nothing playing, 1: playing, 2: the last buffer is playing. */
int DigiStatus(void)
{
    int r;
    int b;

    r = 0;
    if (sfx_stream.mode || sfx_stream.buf_state[0] || sfx_stream.buf_state[1]) {
        if (AIL_sound_buffer_status(digi_handle, 0) == 2)
            b = 0;
        else
            b = 1;
        r = sfx_stream.buf_state[b] ? 1 : 2;
    }
    return r;
}

/* Open name, here or in one of dirs (";"-separated); -1 if not found. */
int OpenSearch(char *name, char *dirs)
{
    char list[0x208];
    char path[0x104];
    char dir[0xA0];
    char fname[10];
    char drive[6];
    char ext[6];
    char *d;
    char *p;
    int fd;

    fd = 0;
    _splitpath(name, drive, dir, fname, ext);
    strcpy(list, dirs);
    p = list;
    strcpy(path, name);
    if (_dos_open(path, O_RDONLY | O_BINARY, &fd)) {
        while ((d = strtok(p, ";")) != 0) {
            p = 0;
            _makepath(path, "", d, fname, ext);
            fd = -1;
            if (_dos_open(path, O_RDONLY | O_BINARY, &fd) == 0)
                break;
        }
    }
    return fd;
}

/* Find path's file in the open .vcc archives: its handle, positioned at
 * it, and *size; -1 if it isn't in any. */
int FindVCC(char *path, long *size)
{
    char drive[6];
    char dir[0xA0];
    char fname[10];
    char ext[6];
    VccEntry far *e;
    int n;
    int i;
    int len;
    int fd;

    fd = -1;
    _splitpath(path, drive, dir, fname, ext);
    _strupr(fname);
    len = strlen(fname);
    for (i = 0; fd == -1 && i < 4; i++) {
        if (vccs[i].fd <= 0)
            continue;
        e = LockMem(vccs[i].dir);
        n = vccs[i].count;
        while (n--) {
            if ((len < 8 && _fstrcmp(fname, e->name) == 0)
                    || (len == 8 && _fstrncmp(fname, e->name, 8) == 0)) {
                _lseek(vccs[i].fd, e->offset, SEEK_SET);
                *size = e->size;
                fd = vccs[i].fd;
                if (vccs[i].acmp == 1)
                    stream_acmp = 1;
                break;
            }
            e++;
        }
        UnlockMem(vccs[i].dir);
    }
    return fd;
}

/* The stream's read function: n bytes into buf (the ACMP decoder calls it
 * too). */
unsigned StreamRead(Stream far *s, char *buf, unsigned n)
{
    int page;
    char far *p;
    EMSBlock *saved;
    unsigned got;
    Stream far *t;

    t = s;
    switch ((unsigned char)t->mode) {
    case 1:
        _lseek(t->fd, t->pos, SEEK_SET);
        _dos_read(t->fd, buf, n, &got);
        t->pos += got;
        break;
    case 2:
        saved = EMSSave();
        if (t->pos % 0x8000 + n <= 0x8000)
            got = n;
        else {
            got = 0x8000 - (unsigned)t->pos;
            n -= got;
        }
        for (;;) {
            page = t->pos >> 15;
            p = LockMem(t->ems[page]);
            MemCpy(buf, p + t->pos % 0x8000, got);
            UnlockMem(t->ems[page]);
            t->pos += got;
            if (got == n)
                break;
            got = n;
            if (n == 0)
                break;
        }
        EMSRestore(saved);
        break;
    }
    return got;
}

void StreamRewind(Stream far *s)
{
    if (s->mode & 0x4000)
        AcmpClose(&s->acmp);
    if (s->mode & 1) {
        _lseek(s->fd, s->start, SEEK_SET);
        s->pos = s->start;
    } else
        s->pos = s->start;
    if (s->mode & 0x4000)
        AcmpOpen(&s->acmp, s, StreamRead);
}

/* Set the stream up (mode 2: read the whole file into EMS). */
/* (97%: the target shares one segment load between AcmpOpen's first two
 * arguments.) */
void StreamInit(Stream far *s, unsigned mode, int fd, long size)
{
    unsigned got;
    int i;
    int j;
    unsigned len;

    s->mode = mode;
    if (mode & 2) {
        if (size > 0x40000L)
            Fatal("StreamInit: EMS stream too large: %lu", size);
        s->size = size;
        for (j = 0; j != 8; j++)
            s->ems[j] = 0;
        for (i = 0; i < (size + 0x7FFF) >> 15; i++)
            s->ems[i] = AllocMemAbort(0x8000, 1);
        for (i = 0; i < 8; i++) {
            len = size > 0x8000 ? 0x8000 : size;
            if (len) {
                _dos_read(fd, LockMem(s->ems[i]), len, &got);
                UnlockMem(s->ems[i]);
                size -= len;
            }
        }
        s->start = s->pos = 0;
        CloseVocFd(fd);
    } else {
        s->fd = fd;
        s->pos = _tell(s->fd);
        s->start = s->pos;
    }
    if (mode & 0x4000)
        AcmpOpen(&s->acmp, s, StreamRead);
    s->buf_state[1] = s->buf_state[0] = 0;
}

/* Fill buf with n bytes of sound. */
unsigned StreamFill(Stream far *s, char far *buf, unsigned n)
{
    if (s->mode & 0x4000)
        n = AcmpRead(&s->acmp, buf, n);
    else {
        _lseek(s->fd, s->pos, SEEK_SET);
        n = VocRead(s, buf, n);
        s->pos = _tell(s->fd);
    }
    return n;
}

void StreamClose(Stream far *s)
{
    EMSBlock *saved;
    int i;

    if (s->mode & 0x4000)
        AcmpClose(&s->acmp);
    switch ((unsigned char)s->mode) {
    case 1:
        if (s->mode)
            CloseVocFile(s->fd);
        s->mode = 0;
        break;
    case 2:
        saved = EMSSave();
        for (i = 0; i < 8; i++)
            if (s->ems[i])
                FreeMem(s->ems[i]);
        s->mode = 0;
        EMSRestore(saved);
        break;
    }
}

int StreamActive(Stream far *s)
{
    return s->mode != 0;
}

/* Open name's voice file (in a .vcc archive or on disk) on stream s. */
int StreamOpen(char *name, Stream far *s, int mode)
{
    char path[0x104];
    char dir[0xA0];
    char hdr[26];
    char fname[10];
    char drive[6];
    char ext[6];
    long size;
    unsigned got;

    got = 0;
    StreamClose(s);
    _splitpath(name, drive, dir, fname, ext);
    _makepath(path, "", "", fname, ".VOC");
    stream_acmp = 0;
    size = 0;
    if ((s->fd = FindVCC(path, &size)) != -1 || (s->fd = OpenSearch(path, voc_path)) != -1) {
        if (size == 0)
            size = _filelength(s->fd);
        if (stream_acmp) {
            StreamInit(s, mode | 0x4000, s->fd, size);
            s->rate = 0xD3;
            snd_buf.pack_type = 0;
        } else {
            _dos_read(s->fd, hdr, sizeof(hdr), &got);
            if (strncmp(hdr, "Creative Voice File", 0x13) == 0)
                StreamInit(s, mode, s->fd, size);
            else if (strncmp(hdr, "Interplay ACMP Data", 0x13) == 0) {
                s->rate = 256 - 1000000L / *(int *)(hdr + 0x14);
                snd_buf.pack_type = 0;
                StreamInit(s, mode | 0x4000, s->fd, size);
            } else
                Fatal("VOC file, %s : Invalid format\n", path);
        }
        return 1;
    }
    Nop("VOC file, %s : not found", path);
    return 0;
}

int PlaySfxFile(char *name)
{
    return StreamOpen(name, &sfx_stream, 1);
}

void StopVoice(void);

void PlayVoice(char *name)
{
    char buf[14];

    if (back_sound) {
        StopVoice();
        strcpy(buf, name);
        strcat(buf, "");
        strcpy(voice_name, name);
        StreamOpen(buf, &voice_stream, 2);
        voice_on = 1;
    }
}

void StopVoice(void)
{
    if (voice_stream.mode)
        StreamClose(&voice_stream);
    voice_on = 0;
}

/* Save (load == 0) or restore which .vcc archives are open. */
void SaveVCCs(int load)
{
    char name[14];
    int n;
    int i;
    int j;

    if (load) {
        CloseVCC("all");
        SaveRead(&n, 2);
        for (i = 0; i < n; i++) {
            SaveRead(name, 14);
            OpenVCC(name);
        }
        return;
    }
    n = 0;
    for (j = 0; j < 4; j++)
        if (vccs[j].fd > 0)
            n++;
    SaveWrite(&n, 2);
    for (i = 0; i < n; i++)
        SaveWrite(vccs[i].name, 14);
}

/* Close the archive name ("all": every one). */
void CloseVCC(char *name)
{
    int i;

    for (i = 0; i < 4; i++)
        if (vccs[i].fd > 0 && (_stricmp(name, vccs[i].name) == 0 || _stricmp(name, "all") == 0)) {
            _dos_close(vccs[i].fd);
            FreeMem(vccs[i].dir);
            vccs[i].fd = -1;
        }
}

/* Open the archive name (its directory read into memory). */
int OpenVCC(char *name)
{
    MemHandle h;
    char far *p;
    long len;
    unsigned got;
    char hdr[16];
    int i;

    for (i = 0; i < 4; i++)
        if (vccs[i].fd <= 0) {
            if ((vccs[i].fd = OpenSearch(name, voc_path)) != -1) {
                _read(vccs[i].fd, hdr, 16);
                if (strncmp(hdr, "CMPFILES", 8) == 0)
                    vccs[i].acmp = 1;
                else if (strncmp(hdr, "VOCFILES", 8) == 0)
                    vccs[i].acmp = 0;
                else {
                    Fatal("VCC file, %s : Invalid format\n", name);
                    _close(vccs[i].fd);
                    return 0;
                }
                len = *(long *)(hdr + 0xC) << 4;
                if ((h = AllocMemAbort((unsigned)len, 1)) == 0) {
                    Fatal("VCCOpen: Insufficient memory\n", "");
                    _close(vccs[i].fd);
                    return 0;
                }
                p = LockMem(h);
                _lseek(vccs[i].fd, *(long *)(hdr + 8), SEEK_SET);
                _dos_read(vccs[i].fd, p, (unsigned)len, &got);
                vccs[i].dir = h;
                vccs[i].count = *(int *)(hdr + 0xC);
                strcpy(vccs[i].name, name);
                UnlockMem(h);
                return 1;
            }
            Fatal("VCCOpen : VCC file not found : %s", name);
        }
    Fatal("VCCOpen : No free VCC directory slots", "");
    return 0;
}

/* Read up to n bytes of sound data from a Creative Voice file. */
unsigned VocRead(Stream far *s, char far *buf, unsigned n)
{
    unsigned char info[12];
    unsigned char blk[4];
    unsigned got;
    unsigned long len;
    int more;

    if (s->start == s->pos) {
        more = 0;
        s->size = 0;
    } else
        more = 1;
    while (more == 0) {
        _dos_read(s->fd, blk, 4, &got);
        len = ((((unsigned long)blk[3] << 8) + blk[2]) << 8) + blk[1];
        switch (blk[0]) {
        case 0:
        case 7:
            more = 1;
            break;
        case 1:
            _dos_read(s->fd, blk, 2, &got);
            s->rate = blk[0];
            snd_buf.pack_type = blk[1];
            s->size = len - 2;
            more = 1;
            break;
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 8:
            _lseek(s->fd, len, SEEK_CUR);
            break;
        case 9:
            _dos_read(s->fd, info, 12, &got);
            len -= got;
            s->rate = 256 - 1000000L / *(long *)info;
            snd_buf.pack_type = 0;
            s->size = len;
            more = 1;
            break;
        default:
            Fatal("VocRead: Invalid blocktype %d", blk[0]);
            break;
        }
        if (more && s->size == 0)
            return 0;
    }
    got = 0;
    if (s->size) {
        len = s->size > n ? n : s->size;
        _dos_read(s->fd, buf, (unsigned)len, &got);
        if (got != len)
            Fatal("VocRead: error reading");
        s->size -= len;
    }
    return got;
}

/* Whether more than a seventh of n bytes of 8-bit sound are loud (more
 * than 8 from the 0x80 centre). */
int Quiet(unsigned char far *p, unsigned n)
{
    int k;
    int r;
    unsigned char c;
    unsigned i;

    k = 0;
    r = 0;
    for (i = n; i--; ) {
        c = *p++;
        if (c < 0x80 && c < 0x78)
            k++;
        if (c >= 0x80 && c > 0x88)
            k++;
    }
    if (n / 7 < k)
        r = 1;
    return r;
}

void StopAllSfx(void);
void ResumeSfx(void);
unsigned MixRaw(char far *buf, unsigned n);

void MusicTick(void)
{
    int b;
    unsigned n;
    char far *tmp;

    if (sound_purged)
        return;
    if (music_on && seq_handles[0] != -1 && AIL_sequence_status(midi_handle, seq_handles[0]) == 2) {
        if (next_seq == cur_seq && cur_seq != -1)
            AIL_start_sequence(midi_handle, seq_handles[0]);
        else
            PlayMusicSeq(next_seq);
    }
    if (digi_loaded == 0)
        return;
    for (b = 0; b < 2; b++) {
        snd_buf.len = 0;
        if (AIL_sound_buffer_status(digi_handle, b) != 3)
            continue;
        sfx_stream.buf_state[b] = 0;
        snd_buf.data = digi_buf + (b ? 0x2B12 : 0);
        if (mix_count) {
            snd_buf.len = MixRaw(snd_buf.data, 0x800);
            snd_buf.sample_rate = 0xA6;
        } else if (sfx_stream.mode) {
            snd_buf.len = StreamFill(&sfx_stream, snd_buf.data, 0x2B12);
            if (snd_buf.len == 0) {
                StreamClose(&sfx_stream);
                goto voice;
            }
            snd_buf.sample_rate = sfx_stream.rate;
            sfx_stream.buf_state[b] = Quiet(snd_buf.data, (unsigned)snd_buf.len);
            if (snd_buf.len < 0x2B12)
                sfx_stream.buf_state[b] = 1;
            if (voice_stream.mode) {
                tmp = PushMem((unsigned)snd_buf.len);
                n = StreamFill(&voice_stream, tmp, (unsigned)snd_buf.len);
                while (n < snd_buf.len) {
                    StreamRewind(&voice_stream);
                    n += StreamFill(&voice_stream, tmp + n, (unsigned)snd_buf.len - n);
                }
                MixVoice(snd_buf.data, tmp, n);
                PopMem();
            }
        } else {
        voice:
            if (voice_stream.mode) {
                n = StreamFill(&voice_stream, snd_buf.data, 0x2B12);
                if (n < 0x2B12) {
                    StreamRewind(&voice_stream);
                    n += StreamFill(&voice_stream, snd_buf.data + n, 0x2B12 - n);
                }
                snd_buf.sample_rate = voice_stream.rate;
                snd_buf.len = n;
            }
        }
        if (snd_buf.len) {
            snd_buf.pack_type = 0;
            AIL_format_sound_buffer(digi_handle, &snd_buf);
            AIL_register_sound_buffer(digi_handle, b, &snd_buf);
            AIL_start_digital_playback(digi_handle);
        }
    }
}

/* ---- sound effects: XMIDI sequences or suite voices, in slots 1-7 ---- */


void StopAllSfx(void)
{
    int i;

    for (i = 1; i < NUM_SEQ; i++)
        if (seq_nodes[i].kind) {
            if (digi_loaded && seq_nodes[i].kind == 2)
                StopSfxLoop();
            else
                StopSeq(i);
        }
}

void ResumeSfx(void)
{
    char name[10];
    char far *p;
    int i;

    if (sound_purged)
        return;
    for (i = 1; i < NUM_SEQ; i++)
        if (seq_nodes[i].kind && seq_nodes[i].seq != -1) {
            if (digi_loaded && seq_nodes[i].kind == 2) {
                p = LockMem(suite_handle);
                MemCpy(name, p + seq_nodes[i].seq * 12 + 0x52, 9);
                UnlockMem(suite_handle);
                PlayDigi(name, suite_vol, suite_pan, 0);
            } else
                PlaySeq(i, seq_nodes[i].seq);
        }
}

/* Stop the effects whose kind is in mask (1 XMIDI, 2 voice, 4 raw). */
void StopSfxKind(int mask)
{
    int i;

    for (i = 1; i < NUM_SEQ; i++)
        if (mask & seq_nodes[i].kind) {
            if (sfx_on) {
                if (digi_loaded && seq_nodes[i].kind == 2)
                    StopSfxLoop();
                else
                    StopSeq(i);
            }
            seq_nodes[i].kind = 0;
            seq_nodes[i].seq = -1;
            ListRemove(&seq_list, &seq_nodes[i].node);
            ListInsert(&seq_list.head, &seq_nodes[i].node);
        }
}

void SaveSfxSlots(void)
{
    SeqNode *n;
    int i;

    SaveWrite(&suite_vol, 2);
    SaveWrite(&suite_pan, 2);
    for (n = (SeqNode *)seq_list.head.prev, i = 7; i; i--, n = (SeqNode *)n->node.prev) {
        SaveWrite(&n->slot, 2);
        SaveWrite(&n->seq, 2);
        SaveWrite(&n->kind, 2);
    }
}

void LoadSfxSlots(void)
{
    int slot;
    int i;

    SaveRead(&suite_vol, 2);
    SaveRead(&suite_pan, 2);
    for (i = 1; i < NUM_SEQ; i++)
        ListRemove(&seq_list, &seq_nodes[i].node);
    for (i = 7; i; i--) {
        SaveRead(&slot, 2);
        SaveRead(&seq_nodes[slot].seq, 2);
        SaveRead(&seq_nodes[slot].kind, 2);
        ListAdd(&seq_list, &seq_nodes[slot].node);
    }
    if (sfx_on)
        ResumeSfx();
}

/* Give effect seq a slot (the one it has, or a free one) and play it. */
void SfxSlot(int seq, int kind, int keep)
{
    int play;
    int i;
    int j;
    SeqNode *n;

    if (sfx_on && (digi_loaded == 0 || kind != 2))
        play = 1;
    else
        play = 0;
    for (i = 1; i < NUM_SEQ; i++)
        if (seq_ids[i] == seq) {
            if (play)
                AIL_start_sequence(midi_handle, seq_handles[i]);
            break;
        }
    if (i == NUM_SEQ) {
        for (j = 1, n = (SeqNode *)seq_list.head.prev; j < NUM_SEQ; j++, n = (SeqNode *)n->node.prev)
            if (n->kind != 2 && n->seq == -1)
                break;
        if (j == NUM_SEQ)
            return;
        i = n->slot;
        if (play)
            PlaySeq(i, seq);
    }
    ListRemove(&seq_list, &seq_nodes[i].node);
    ListAdd(&seq_list, &seq_nodes[i].node);
    seq_nodes[i].seq = keep ? seq : -1;
    seq_nodes[i].kind = kind;
}

void PlayRaw(int i);

/* Effect n of the music's suite (0xFE: stop them all). */
void BridgeSfx(int n)
{
    Suite far *p;
    int kind;
    int keep;
    char name[10];
    unsigned char vol;
    unsigned char pan;

    if (sound_purged)
        return;
    vol = sfx_vol_next;
    pan = sfx_pan_next;
    sfx_vol_next = 0x7F;
    sfx_pan_next = 0x40;
    if (n == 0xFE) {
        StopSfxKind(7);
        StopMix();
        StopSfxLoop();
        return;
    }
    p = LockMem(suite_handle);
    keep = p->sfx[n].keep;
    if (p->sfx[n].raw != -1) {
        kind = 4;
        keep = 0;
        StopSfxKind(2);
    } else if (p->sfx[n].name[0]) {
        kind = 2;
        suite_vol = vol;
        suite_pan = pan;
        StopSfxKind(6);
    } else
        kind = 1;
    if (digi_loaded) {
        if (kind == 4) {
            PlayRaw(p->sfx[n].raw);
            UnlockMem(suite_handle);
            return;
        }
        if (kind == 2) {
            MemCpy(name, p->sfx[n].name, 9);
            UnlockMem(suite_handle);
            SfxSlot(n, kind, keep);
            PlayDigi(name, vol, pan, 0);
            StartTalk(-2, "", 0, 0, 0, 0);
            return;
        }
    }
    UnlockMem(suite_handle);
    SfxSlot(n, kind, keep);
}

void SetSfxOn(int on)
{
    if (sound_purged == 0 && sfx_on != on) {
        if ((sfx_on = on) != 0) {
            ResumeSfxLoop();
            ResumeSfx();
        } else {
            StopDigi();
            StopAllSfx();
        }
    }
}

void SaveSound(void)
{
    SaveMusicState();
    SaveMusicSeq();
    SaveSfxState();
    SaveSfxSlots();
    SaveVCCs(0);
}

void LoadSound(void)
{
    LoadMusicState();
    LoadMusicSeq();
    LoadSfxState();
    LoadSfxSlots();
    SaveVCCs(1);
}

void StopAllSound(void)
{
    if (sound_purged == 0) {
        StopMusic();
        StopSfxLoop();
        StopSfxKind(7);
        StopMix();
    }
}

/* ---- the raw samples of the suite, mixed in software ---- */


void LoadRaw(char *name, int i)
{
    raws[i].h = getanyfileems(name, "raw");
    raws[i].size = GetFileSize(name, "raw");
}

void FreeRaw(int i)
{
    FreeAnyFile(raws[i].h);
}

void StopMix(void)
{
    if (digi_loaded && mix_count) {
        AIL_stop_digital_playback(digi_handle);
        mix_count = 0;
    }
}

void PlayRaw(int i)
{
    Raw *r;

    r = &raws[i];
    if (sound_purged == 0 && sfx_on) {
        StopSfxLoop();
        AIL_set_digital_playback_volume(digi_handle, 0x7F);
        AIL_set_digital_playback_panpot(digi_handle, 0x40);
        if (mix_count < 4) {
            mixes[mix_count].h = r->h;
            mixes[mix_count].pos = 0;
            mixes[mix_count].left = r->size;
            mix_count++;
        }
    }
}

/* Mix the playing raw samples into n bytes of buf. */
unsigned MixRaw(char far *buf, unsigned n)
{
    unsigned len[4];
    int i;
    char far *p;
    Mix *m;
    unsigned max;
    int j;
    unsigned pos;
    unsigned k;

    max = 0;
    for (i = 0, m = mixes; i != mix_count; i++, m++)
        max = m->left >= max ? m->left : max;
    max = n < max ? n : max;
    MemSet(mix_buf, max * 2, 0);
    MemSet(buf + max, n - max, 0x80);
    for (i = 0, m = mixes; i != mix_count; i++, m++) {
        p = LockMem(m->h);
        p += m->pos;
        len[i] = k = m->left < n ? m->left : n;
        AddSamples(mix_buf, p, k);
        m->pos += k;
        m->left -= k;
        UnlockMem(m->h);
    }
    for (i = 0; i != mix_count - 1; i++)
        for (j = i + 1; j != mix_count; j++)
            if (len[j] < len[i]) {
                len[j] ^= len[i];
                len[i] ^= len[j];
                len[j] ^= len[i];
            }
    for (i = pos = 0; i != mix_count; i++) {
        ClampSamples(buf + pos, mix_buf + pos, len[i] - pos, mix_count - i - 1);
        pos = len[i];
    }
    for (i = 0, m = mixes; i != mix_count; i++, m++)
        if (m->left == 0) {
            *m = m[mix_count - i - 1];
            i--;
            m--;
            mix_count--;
        }
    return n;
}

/* dst[i] += src[i], for n samples. */
void AddSamples(int far *dst, unsigned char far *src, unsigned n)
{
    _asm {
        push ds
        push es
        push si
        push di
        mov cx, n
        or cx, cx
        je done
        lds si, src
        les di, dst
        sub ax, ax
    next:
        mov al, [si]
        inc si
        add es:[di], ax
        add di, 2
        dec cx
        je done
        mov al, [si]
        inc si
        add es:[di], ax
        add di, 2
        dec cx
        jne next
    done:
        pop di
        pop si
        pop es
        pop ds
    }
}

/* dst[i] = mix_tabs[k][src[i]]: the mixed sum of k + 1 samples, scaled
 * back to 8 bits. (386 code) */
void ClampSamples(char far *dst, int far *src, unsigned n, int k)
{
    char far *tab;

    tab = LockMem(mix_tabs[k]);
    /* 386 code (the inline assembler is 286 only):
     *   push es / push fs / push si / push di; sub eax,eax; sub ebx,ebx
     *   mov cx,n; or cx,cx; je done; lea bx,tab; lfs bx,[bx]; lds si,src; les di,dst
     * next: mov ax,[si]; add si,2; mov dl,fs:[ebx+eax*2]; mov es:[di],dl; inc di;
     *   dec cx; je done; (again); dec cx; jne next
     * done: pop di / pop si / pop es / pop fs; mov ax,ss; mov ds,ax */
    _asm {
        push es
        _emit 0x0F
        _emit 0xA0
        push si
        push di
        _emit 0x66
        _emit 0x2B
        _emit 0xC0
        _emit 0x66
        _emit 0x2B
        _emit 0xDB
        _emit 0x8B
        _emit 0x4E
        _emit 0x0E
        _emit 0x0B
        _emit 0xC9
        _emit 0x74
        _emit 0x2E
        _emit 0x8D
        _emit 0x5E
        _emit 0xFC
        _emit 0x0F
        _emit 0xB4
        _emit 0x1F
        _emit 0xC5
        _emit 0x76
        _emit 0x0A
        _emit 0xC4
        _emit 0x7E
        _emit 0x06
        _emit 0x8B
        _emit 0x04
        _emit 0x83
        _emit 0xC6
        _emit 0x02
        _emit 0x64
        _emit 0x67
        _emit 0x8A
        _emit 0x14
        _emit 0x43
        _emit 0x26
        _emit 0x88
        _emit 0x15
        _emit 0x47
        _emit 0x49
        _emit 0x74
        _emit 0x11
        _emit 0x8B
        _emit 0x04
        _emit 0x83
        _emit 0xC6
        _emit 0x02
        _emit 0x64
        _emit 0x67
        _emit 0x8A
        _emit 0x14
        _emit 0x43
        _emit 0x26
        _emit 0x88
        _emit 0x15
        _emit 0x47
        _emit 0x49
        _emit 0x75
        _emit 0xDE
        _emit 0x5F
        _emit 0x5E
        _emit 0x07
        _emit 0x0F
        _emit 0xA1
        _emit 0x8C
        _emit 0xD0
        _emit 0x8E
        _emit 0xD8
    }
    UnlockMem(mix_tabs[k]);
}

void LoadMixTables(void)
{
    char name[16];
    int i;
    MemHandle *h;

    for (i = 1, h = mix_tabs; i <= 4; i++) {
        sprintf(name, "sinmix%d", i);
        *h++ = getanyfileems(name, "mix");
    }
}

void FreeMixTables(void)
{
    MemHandle *h;

    for (h = mix_tabs; h != &mix_tabs[4]; h++)
        FreeAnyFile(*h);
}

/* The suite: the music's effects (8 raw samples, then 12 byte entries). */
void LoadSuite(void)
{
    char name[10];
    char far *p;
    int i;

    if (suite_handle)
        Fatal("Suite info still in mem.\n");
    LoadMixTables();
    suite_handle = getanyfileems(music_file, "sui");
    for (i = 0; i != 8; i++) {
        p = LockMem(suite_handle);
        if (p[i * 10]) {
            MemCpy(name, p + i * 10, 10);
            UnlockMem(suite_handle);
            LoadRaw(name, i);
        } else
            UnlockMem(suite_handle);
    }
}

void FreeSuite(void)
{
    char far *p;
    int i;

    if (suite_handle) {
        for (i = 0; i != 8; i++) {
            p = LockMem(suite_handle);
            if (p[i * 10]) {
                UnlockMem(suite_handle);
                FreeRaw(i);
            } else
                UnlockMem(suite_handle);
        }
        FreeAnyFile(suite_handle);
        FreeMixTables();
        suite_handle = 0;
    }
}
