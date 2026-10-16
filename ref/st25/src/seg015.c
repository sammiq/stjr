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

/* Globals this file owns (declared in the headers). */
int digi_driver;
int midi_driver;
SndChan snd_chan[4];

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

int timer_busy;
void (_interrupt _far *old_timer)(void);
int far *digi_status;
long rom_sum1;
long rom_sum2;
int rom_errors;
int ems_save_err;
int ems_restore_err;
int digi_handle;
int midi_handle;
extern int sb_port;
extern int sb_irq;
char far *dma_buf;
int dma_buf_moved;
void far *seq_state[NUM_SEQ];
int seq_handles[NUM_SEQ];
int seq_ids[NUM_SEQ];
char midi_suffix[4];
unsigned timbre_cache_size;
char music_name[10];
List seq_list;
SeqNode seq_nodes[NUM_SEQ];
drvr_desc blaster_desc;
int blaster_type;
int music_next;
int music_cur;
int stream_mixed;
int voc_abort;
unsigned long voc_left;
char voc_name[80];
int voc_rate;
int voc_pack;
extern char sfx_name[];
int dma_auto;
DmaReq dma_req;
int dma_half_pos;
char dma_half;
char mix_half;
int digi_running;
int digi_ticks;
int mix_first;
int dma_state;
int dma_count;
extern int stream_done;
int stream_filling;

int music_on = 1;
int sfx_on = 1;
int no_midi = 0;
int midi_ok = 0;
int digi_ok = 0;
int voc_fd = -1;
char far *music_data = 0;
char *midi_drivers[13] = {
    0, "PCSPKR", "ADLIB", 0, "SBFM", "SBPFM", "SBPFM", "PASFM", "PASFM",
    "MT32MPU", "MT32MPU", 0, 0
};
char *digi_drivers[13] = {
    0, 0, 0, 0, "SBLASTER", "SBPRO", "SBPRO", "PAUDIO", "PAS16", 0, 0, 0, "SBCLONE"
};
/* BLASTER=A220 I5 D1 T4: the fields read and where they go */
char blaster_keys[] = "AIDT";
int blaster_radix[4] = { 16, 10, 10, 10 };
int *blaster_vals[4] = {
    &blaster_desc.default_IO, &blaster_desc.default_IRQ, &blaster_desc.default_DMA,
    &blaster_type
};
int sound_closed = 0;

/* Timer interrupt: run the sound driver tick. The ROM checksums before and
 * after count the times the tick left the EMS page frame at E000 changed. */
void _interrupt _far TimerISR(void)
{
    int err;
    long i;
    char far *rom;

    rom = (char far *)0xE0000000L;
    (*old_timer)();
    _asm cld
    timer_busy++;
    if (timer_busy == 1) {
        _enable();
        if (*digi_status == 0) {
            rom_sum1 = rom_sum2 = 0;
            for (i = 0; i < 0x10000L; i += 256)
                rom_sum1 += rom[i];
            err = EMSSaveMap();
            if (err)
                ems_save_err = err;
            DigiTick();
            err = EMSRestoreMap();
            if (err)
                ems_restore_err = err;
            for (i = 0; i < 0x10000L; i += 256)
                rom_sum2 += rom[i];
            if (rom_sum1 != rom_sum2)
                rom_errors++;
        }
        _disable();
    }
    timer_busy--;
}

void HookTimer(void)
{
    int unused;

    old_timer = _dos_getvect(8);
    _dos_setvect(8, TimerISR);
}

void UnhookTimer(void)
{
    _dos_setvect(8, old_timer);
}

/* Load and start the music and digital sound drivers chosen in the setup. */
void SoundInit(void)
{
    char far *midi_drv;
    char far *digi_drv;
    drvr_desc far *mdesc;
    drvr_desc desc;
    unsigned size;
    int i;

    if (midi_drivers[midi_driver]) {
        midi_ok = 1;
        midi_drv = PushMem(GetFileSize(midi_drivers[midi_driver], "ADV"));
        LoadFilePacked(midi_drivers[midi_driver], "ADV", midi_drv);
    } else
        no_midi = 1;
    if (digi_drivers[digi_driver]) {
        digi_ok = 1;
        digi_drv = PushMem(GetFileSize(digi_drivers[digi_driver], "ADV"));
        LoadFilePacked(digi_drivers[digi_driver], "ADV", digi_drv);
    }
    if (midi_ok == 0 && digi_ok == 0)
        return;
    AIL_startup();
    if (digi_ok) {
        char buf1[16];
        char buf2[16];

        digi_handle = AIL_register_driver(digi_drv);
        if (digi_handle == -1) {
            AIL_shutdown(0);
            digi_ok = 0;
            return;
        }
        desc = *AIL_describe_driver(digi_handle);
        if (digi_driver == 4 || digi_driver == 5 || digi_driver == 12) {
            if (sb_port) {
                *(int far *)(digi_drv + 0x106) = sb_port;
                *(int far *)(digi_drv + 0x108) = sb_irq;
                desc.default_IO = sb_port;
                desc.default_IRQ = sb_irq;
            } else if (ParseBlaster(&desc, buf2, buf1) == 0) {
                AIL_shutdown(0);
                digi_ok = 0;
                return;
            }
        }
        if (desc.drvr_type != DSP_DRVR) {
            AIL_shutdown(0);
            digi_ok = 0;
            return;
        }
        if (AIL_detect_device(digi_handle, desc.default_IO, desc.default_IRQ,
                              desc.default_DMA, desc.default_DRQ) == 0) {
            AIL_shutdown(0);
            digi_ok = 0;
            return;
        }
        AIL_init_driver(digi_handle, desc.default_IO, desc.default_IRQ,
                        desc.default_DMA, desc.default_DRQ);
        dma_buf = PushMem(0x2000);
        if (sub_3588D(dma_buf, 0x2000) == 0) {
            dma_buf = PushMem(0x2000);
            dma_buf_moved = 1;
        }
        HookTimer();
        StreamInit();
    }
    if (midi_ok) {
        midi_handle = AIL_register_driver(midi_drv);
        if (midi_handle == -1) {
            AIL_shutdown(0);
            no_midi = 1;
            midi_ok = 0;
            return;
        }
        mdesc = AIL_describe_driver(midi_handle);
        if (mdesc->drvr_type != XMIDI_DRVR
                || AIL_detect_device(midi_handle, mdesc->default_IO, mdesc->default_IRQ,
                                     mdesc->default_DMA, mdesc->default_DRQ) == 0) {
            AIL_shutdown(0);
            midi_ok = 0;
            no_midi = 1;
            return;
        }
        AIL_init_driver(midi_handle, mdesc->default_IO, mdesc->default_IRQ,
                        mdesc->default_DMA, mdesc->default_DRQ);
        size = AIL_state_table_size(midi_handle);
        for (i = 0; i < NUM_SEQ; i++) {
            seq_state[i] = PushMem(size);
            seq_handles[i] = -1;
        }
        if (mdesc->data_suffix[0])
            MemCpy(midi_suffix, mdesc->data_suffix, 4);
        else if (midi_driver == 1)
            MemCpy(midi_suffix, "pc", 4);
        else
            MemCpy(midi_suffix, "td", 4);
        timbre_cache_size = AIL_default_timbre_cache_size(midi_handle);
        if (timbre_cache_size) {
            GTLEntry far *e;
            MemHandle h;
            char far *gtl;
            char far *cache;

            cache = PushMem(timbre_cache_size);
            AIL_define_timbre_cache(midi_handle, cache, timbre_cache_size);
            h = getanyfile("gtl", midi_suffix);
            gtl = LockMem(h);
            for (e = (GTLEntry far *)gtl; e->bank != -1; e++)
                AIL_install_timbre(midi_handle, e->bank, e->patch, gtl + e->offset);
            UnlockMem(h);
            FreeAnyFile(h);
        }
        strcpy(music_name, "");
        music_data = 0;
        ListInit(&seq_list);
        for (i = 1; i < NUM_SEQ; i++) {
            int slot;

            slot = i;
            seq_nodes[i].slot = slot;
            ListAdd(&seq_list, &seq_nodes[i].node);
            seq_ids[i] = -1;
        }
        sub_3B584(midi_handle, "Star Trek");
        music_on = 1;
        sfx_on = 1;
        if (strcmpi(midi_suffix, "mt") == 0)
            ;
    }
}

/* Read the BLASTER environment variable into desc (A port, I irq, D dma,
 * T card type). Returns the card type, 0 if not set. */
int ParseBlaster(drvr_desc *desc, char *a, char *b)
{
    int k;
    int j;
    int key;
    int i;
    int c;
    int val;
    int pos;
    char *env;
    char buf[128];

    env = getenv("BLASTER");
    if (env == 0)
        return 0;
    strncpy(buf, env, 127);
    if (strlen(buf) == 0)
        return 0;
    strupr(buf);
    blaster_desc = *desc;
    for (i = 0; i < strlen(buf); i++) {
        if (i != 0 && buf[i] != ' ')
            continue;
        i += buf[i] == ' ';
        key = buf[i];
        for (k = 0; k < 4; k++) {
            if (key == blaster_keys[k]) {
                pos = i + 1;
                val = 0;
                do {
                    c = buf[pos++];
                    for (j = 0; j < blaster_radix[k]; j++)
                        if (toupper(c) == "0123456789ABCDEF"[j])
                            val = val * blaster_radix[k] + j;
                } while (isalnum(c));
                *blaster_vals[k] = val;
                break;
            }
        }
    }
    *desc = blaster_desc;
    if (blaster_type == 0)
        return 0;
    if (blaster_type > 4)
        blaster_type = 4;
    return blaster_type;
}

void SoundStop(void)
{
    if (digi_ok)
        UnhookTimer();
    if (midi_ok || digi_ok)
        AIL_shutdown(0);
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

int MusicPlaying(void)
{
    int i;

    if (midi_ok == 0)
        return 0;
    for (i = 0; i < NUM_SEQ; i++)
        if (seq_handles[i] != -1 && AIL_sequence_status(midi_handle, seq_handles[i]) == 1)
            return 1;
    return 0;
}

void StopVoc(void)
{
    if (digi_ok) {
        stream_play_pos = stream_fill_pos;
        if (voc_fd != -1) {
            _dos_close(voc_fd);
            voc_fd = -1;
        }
        stream_mixed = 0;
        stream_active = 0;
    }
}

void StopAllSound(void)
{
    int i;

    for (i = 0; i < NUM_SEQ; i++)
        StopSeq(i);
    StopVoc();
}

void LoadMusic(char *name)
{
    int unused;
    unsigned size;

    if (midi_ok == 0)
        return;
    StopAllSound();
    PlayMusic(-1, -1);
    if (strcmpi(name, music_name) == 0)
        return;
    strcpy(music_name, name);
    if (music_data)
        PopMem();
    size = GetFileSize(name, midi_suffix);
    music_data = PushMem(size);
    LoadFilePacked(name, midi_suffix, music_data);
}

/* Free everything SoundInit allocated, in reverse. */
int SoundShutdown(void)
{
    int i;

    if (midi_ok == 0)
        return 0;
    SoundStop();
    if (music_data)
        PopMem();
    no_midi = 1;
    midi_ok = 0;
    if (timbre_cache_size)
        PopMem();
    for (i = 0; i < NUM_SEQ; i++)
        PopMem();
    if (digi_ok) {
        PopMem();
        if (dma_buf_moved)
            PopMem();
        PopMem();
    }
    PopMem();
    sound_closed = 1;
    return 1;
}

/* Play sequence seq; next (-2 keep, -3 same as seq) plays when it ends. */
void PlayMusic(int seq, int next)
{
    if (midi_ok == 0 || music_on == 0)
        return;
    if (next == -2)
        ;
    else if (next == -3)
        music_next = seq;
    else
        music_next = next;
    if (seq == -2)
        return;
    music_cur = seq;
    if (music_on)
        PlaySeq(0, seq);
}

/* Read up to len bytes of sample data from the speech files listed in
 * voc_name ("file,file,..."), following the VOC blocks. Returns the number
 * of bytes read. */
int ReadVoc(char far *buf, int len)
{
    unsigned got;
    int start;
    char path[128];
    int i;

    voc_abort = 0;
    start = len;
    while (voc_abort == 0 && len != 0) {
        if (voc_fd == -1 && voc_name[0] != 0) {
            char hdr[26];
            unsigned n;

            for (i = 0; voc_name[i] != 0 && voc_name[i] != ','; i++)
                ;
            strcpy(path, voc_path);
            strncat(path, voc_name, i);
            strcat(path, ".voc");
            if (_dos_open(path, 0x8000, &voc_fd) != 0) {
                voc_fd = -1;
                return 0;
            }
            if (voc_name[i] == ',')
                strcpy(voc_name, &voc_name[i + 1]);
            else
                voc_name[0] = 0;
            ReadChunk(voc_fd, hdr, 26, &n);
            voc_abort = 0;
            voc_left = 0;
        }
        if (voc_fd == -1)
            return start - len;
        if (voc_left) {
            unsigned n;

            n = len;
            if (n > voc_left)
                n = voc_left;
            ReadChunk(voc_fd, buf, n, &got);
            n = got;
            if (n == 0) {
                _dos_close(voc_fd);
                voc_fd = -1;
            }
            buf += n;
            len -= n;
            voc_left -= n;
        } else {
            unsigned char hdr[4];

            ReadChunk(voc_fd, hdr, 4, &got);
            if (got < 4 && got != 1 && hdr[0] != 0) {
                _dos_close(voc_fd);
                voc_fd = -1;
                break;
            }
            voc_left = ((long)hdr[3] << 16) | ((long)hdr[2] << 8) | hdr[1];
            switch (hdr[0]) {
            case 0:
                _dos_close(voc_fd);
                voc_fd = -1;
                break;
            case 1:
                ReadChunk(voc_fd, hdr, 2, &got);
                voc_rate = hdr[0];
                voc_pack = hdr[1];
                voc_left -= 2;
                break;
            case 2:
                break;
            case 3:
            case 4:
            case 5:
            case 6:
            case 7:
            default:
                while (voc_left >= 4)
                    ReadChunk(voc_fd, hdr, 4, &got), voc_left -= 4;
                if (voc_left)
                    ReadChunk(voc_fd, hdr, voc_left, &got);
                voc_left = 0;
                break;
            }
        }
    }
    return start - len;
}

void MusicTick(void)
{
    int unused;

    if (midi_ok == 0 || music_on == 0)
        return;
    if (seq_handles[0] != -1 && AIL_sequence_status(midi_handle, seq_handles[0]) == 2) {
        if (music_cur == music_next && music_cur != -1)
            AIL_start_sequence(midi_handle, seq_handles[0]);
        else
            PlayMusic(music_next, music_next);
    }
    StreamTick();
}

void SetMusicOn(int on)
{
    if (midi_ok == 0 || music_on == on)
        return;
    music_on = on;
    if (music_on)
        PlayMusic(music_next, music_next);
    else
        StopSeq(0);
}

/* Play seq in slots 1-7, reusing a slot already holding it or else the
 * least recently used one. */
void PlaySfxSeq(int seq)
{
    int i;

    if (midi_ok == 0 || music_on == 0)
        return;
    for (i = 1; i < NUM_SEQ; i++) {
        if (seq_ids[i] == seq) {
            AIL_start_sequence(midi_handle, seq_handles[i]);
            ListRemove(&seq_list, &seq_nodes[i].node);
            ListAdd(&seq_list, &seq_nodes[i].node);
            return;
        }
    }
    i = ((SeqNode far *)seq_list.head.prev)->slot;
    ListRemove(&seq_list, &seq_nodes[i].node);
    ListAdd(&seq_list, &seq_nodes[i].node);
    PlaySeq(i, seq);
}

void SetSfxOn(int on)
{
    int i;

    if (digi_ok == 0 || sfx_on == on)
        return;
    sfx_on = on;
    if (sfx_on == 0)
        for (i = 1; i < NUM_SEQ; i++)
            StopSeq(i);
    if (sfx_on == 0)
        FreeAllEMSFiles();
    if (sfx_on == 1 && sfx_name[0])
        PlaySfx(sfx_name);
}

int GetMusicSeq(void)
{
    return seq_ids[0];
}

void SaveMusicState(void)
{
    char name[10];
    int seq;

    seq = music_next;
    strcpy(name, music_name);
    SaveWrite(name, 9);
    SaveWrite(&seq, 2);
}

void LoadMusicState(void)
{
    char name[10];
    int seq;

    SaveRead(name, 9);
    SaveRead(&seq, 2);
    if (name[0]) {
        LoadMusic(name);
        PlayMusic(seq, seq);
    } else
        StopAllSound();
}

int sub_2A776(int a, int b)
{
    return sub_35345(a, b);
}

void sub_2A791(int a, int b)
{
    sub_35373(a, b);
}

/* Start digital output: auto-init DMA over the whole buffer when the
 * driver supports it, else one half at a time. */
void DigiInit(void)
{
    digi_status = sub_35828();
    if (sub_358B3() == 0) {
        sub_35388("No sound driver resident.\n");
        exit(1);
    }
    dma_auto = 0;
    dma_req.len = HALF;
    dma_req.rate = 22050;
    if (sub_3577A() & 0x200) {
        if (sub_3588D(dma_buf, 0x2000)) {
            dma_auto = 1;
            dma_half_pos = HALF;
            sub_35873(dma_buf, 0x2000);
            sub_3585E(1);
            dma_req.buf = dma_buf;
            dma_req.len = 0x2000;
            dma_req.rate = 22050;
            sub_3571B(&dma_req);
        } else {
            printf("DMA buffer crosses segment boundary\n");
            exit(1);
        }
    } else {
        sub_35873(dma_buf, 0x2000);
        dma_req.buf = dma_buf + (dma_half << 12);
        dma_req.len = HALF;
        dma_req.rate = 22050;
        sub_3571B(&dma_req);
        dma_req.buf = dma_buf + (mix_half << 12);
        DigiPlay(&dma_req);
    }
}

/* Timer tick: when a half of the buffer has played, mix the next. */
void DigiTick(void)
{
    if (digi_ok && digi_running) {
        digi_ticks++;
        if (DigiStatus() != 2) {
            if (dma_half == 0) {
                dma_half = 1;
                mix_half = 0;
            } else {
                dma_half = 0;
                mix_half = 1;
            }
            if (stream_active == 1 && snd_chan[0].busy == 0 && snd_chan[1].busy == 0
                    && snd_chan[2].busy == 0 && snd_chan[3].busy == 0)
                ;
            sub_35873(dma_buf + (mix_half << 12), HALF);
            mix_first = 0;
            MixFrame();
            dma_req.len = HALF;
            dma_req.buf = dma_buf + (mix_half << 12);
            DigiPlay(&dma_req);
        }
    }
}

void DigiStop(void)
{
    if (dma_auto)
        sub_3585E(0);
}

void DigiPlay(DmaReq far *req)
{
    if (dma_auto == 0)
        sub_357EB(req);
}

int DigiStatus(void)
{
    int st;
    int n;

    if (dma_auto) {
        dma_state = st = 2;
        dma_count = n = sub_3586D();
        if (dma_half_pos && n < dma_half_pos) {
            dma_state = st = 1;
            dma_half_pos = 0;
        } else if (dma_half_pos == 0 && n >= HALF) {
            dma_state = st = 1;
            dma_half_pos = HALF;
        }
    } else
        st = sub_357FE();
    return st;
}

void DigiStart(void)
{
    digi_running = 1;
    dma_half = 0;
    mix_half = 1;
    mix_first = 1;
    DigiInit();
}

void DigiShutdown(void)
{
    int i;

    if (digi_ok) {
        sub_357C0();
        sub_35873(dma_buf + (mix_half << 12), HALF);
        digi_running = 0;
        for (i = 0; i < NUM_CHAN; i++)
            snd_chan[i].busy = 0;
        if (voc_fd != -1) {
            _dos_close(voc_fd);
            voc_fd = -1;
        }
        stream_active = 0;
    }
}

/* Stream the speech files in name ("file,file,..."). */
void PlayVoc(char *name)
{
    if (sfx_on == 0 || digi_ok == 0)
        return;
    StopVoc();
    stream_active = 1;
    strcpy(voc_name, name);
    stream_done = 0;
    stream_filling = 1;
    StreamFill();
    stream_filling = 0;
    if (digi_running == 0)
        DigiStart();
}

/* Start sound effect name.voc on a free channel, mixing straight into the
 * part of the buffer not yet played. */
int PlaySfx(char *name)
{
    int n;
    unsigned pos;
    int unused1;
    int unused2;
    int i;
    unsigned half;
    MemHandle h;

    if (strcmpi(name + 4, "loop") == 0)
        strcpy(sfx_name, name);
    if (sfx_on == 0 || digi_ok == 0)
        return;
    if (digi_running == 0)
        DigiStart();
    for (i = 0; i < NUM_CHAN; i++) {
        if (snd_chan[i].busy == 0) {
            h = LoadEMSFile(name, "voc");
            snd_chan[i].handle = h;
            if (snd_chan[i].handle == 0)
                return 0;
            snd_chan[i].pos = 0;
            snd_chan[i].len = 0;
            pos = 0x2000 - sub_3586D();
            half = pos / HALF;
            if (half == dma_half) {
                if (pos >= HALF)
                    pos -= HALF;
                n = HALF - pos;
                MixVoc(dma_buf + ((dma_half << 12) + pos), &snd_chan[i], n);
                if (snd_chan[i].pos == 0) {
                    SfxNop(snd_chan[i].handle);
                    snd_chan[i].busy = 0;
                    return;
                }
            }
            if (mix_first == 1) {
                n = HALF;
                MixVoc(dma_buf + (mix_half << 12), &snd_chan[i], n);
                if (snd_chan[i].pos == 0) {
                    SfxNop(snd_chan[i].handle);
                    snd_chan[i].busy = 0;
                    return;
                }
            }
            snd_chan[i].busy = 1;
            return;
        }
    }
}

void StreamTick(void)
{
    StreamFill();
}

/* Mix the speech stream and the sound effects into the half being filled. */
void MixFrame(void)
{
    int i;
    int n;
    long unused;

    mix_first = 1;
    n = HALF;
    if (stream_fill_pos != stream_play_pos && stream_filling == 0) {
        stream_mixed = 1;
        MixSamples(dma_buf + (mix_half << 12), MapStream(), n);
        stream_play_pos += n;
        if (stream_play_pos >= 0x10000L)
            stream_play_pos = 0;
    } else {
        if (stream_mixed == 1)
            stream_done = 1;
        stream_mixed = 0;
    }
    for (i = 0; i < NUM_CHAN; i++) {
        if (snd_chan[i].busy) {
            n = HALF;
            MixVoc(dma_buf + (mix_half << 12), &snd_chan[i], n);
            if (snd_chan[i].pos == 0) {
                snd_chan[i].busy = 0;
                SfxNop(snd_chan[i].handle);
            }
        }
    }
}

/* Add n signed samples from src to the unsigned samples in dst, clamped. */
void MixSamples(char far *dst, char far *src, int n)
{
    _asm {
        push ds
        push si
        push di
        cld
        mov cx, n
        les di, dst
        lds si, src
    l_next:
        lodsb
        add al, 80h
        cbw
        mov bl, es:[di]
        xor bh, bh
        add ax, bx
        cmp ax, 0
        jge l_pos
        xor ax, ax
        jmp l_store
    l_pos:
        cmp ax, 0FFh
        jle l_store
        mov ax, 0FFh
    l_store:
        stosb
        dec cx
        jne l_next
        pop di
        pop si
        pop ds
    }
}

/* Mix up to n bytes of the VOC file playing on ch into dst, following its
 * blocks. Returns the bytes mixed; ch->pos is 0 at the end of the file. */
int MixVoc(char far *dst, SndChan *ch, unsigned n)
{
    int unused;
    int total;

    total = 0;
    while (n) {
        if (ch->len) {
            char far *src;
            unsigned cnt;

            cnt = n;
            if (cnt > (unsigned long)ch->len)
                cnt = ch->len;
            src = MapMemRef((MemRef *)ch);
            MixSamples(dst, src, cnt);
            CacheNop();
            dst += cnt;
            ch->pos += cnt;
            n -= cnt;
            ch->len -= cnt;
            total += cnt;
        } else {
            long unused2;
            unsigned char far *p;
            char hdr[26];

            if (ch->pos == 0) {
                p = MapMemRef((MemRef *)ch);
                ch->pos += 26;
            }
            p = MapMemRef((MemRef *)ch);
            ch->len = ((long)p[3] << 16) | ((unsigned)p[2] << 8) | p[1];
            ch->pos += 4;
            switch (p[0]) {
            case 0:
                ch->len = 0;
                n = 0;
                ch->pos = 0;
                break;
            case 1:
                ch->pos += 2;
                ch->len -= 2;
                break;
            case 2:
                break;
            case 6:
                p += 4;
                ch->loops = ((long)p[1] << 8) | p[0];
                ch->pos += 2;
                ch->loop_pos = ch->pos;
                ch->len = 0;
                break;
            case 7:
                ch->loops--;
                if (ch->loops)
                    ch->pos = ch->loop_pos;
                break;
            case 3:
            case 4:
            case 5:
            default:
                ch->pos += ch->len;
                ch->len = 0;
                break;
            }
            CacheNop();
        }
    }
    return total;
}
