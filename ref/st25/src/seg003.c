/* seg003: CD-ROM detection, resource files (DATA.DIR/RUN/001) and patches */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <io.h>
#include <dos.h>
#include "ems.h"
#include "mem.h"
#include "resource.h"

/* Globals this file owns (declared in the headers). */
char voc_path[32];
MemHandle dir_handle;
int data_fd;
unsigned dir_size;
MemHandle run_handle;
struct find_t patch_find;
unsigned dir_count;

void Fatal(char *fmt, ...);     /* fatal error */

char far file_buf[0x800];       /* ReadChunk reads through this (in FAR_BSS) */
int voc_on_cd = 0;
int word_45D18 = 0;             /* never used */
char *exit_msg = 0;
int data_not_open = -1;
int dir_last = 0;

/* Locate the speech directory: ./voc if installed, else on the CD. */
void FindCD(void)
{
    int unused;
    int inst;
    int i;
    int first;
    int count;
    char letters[256];
    char far *lpletters;
    int fd;

    lpletters = letters;
    _asm {
        mov ax, 1500h
        mov bx, 0
        int 2Fh
        mov inst, ax
        mov count, bx
        mov first, cx
        mov ax, 150Dh
        les bx, lpletters
        int 2Fh
        mov ax, 150Ch
        int 2Fh
    }
    strcpy(voc_path, ".\\voc\\speech.mrk");
    if ((fd = open(voc_path, O_RDONLY)) != -1) {
        strcpy(voc_path, ".\\voc\\");
        close(fd);
        voc_on_cd = 0;
        return;
    }
    if (count == 0) {
        SetExitMsg("No CD-ROM drive detected.\nMake sure that you have run MSCDEX.EXE and that the correct CD-ROM device\ndriver is present in your CONFIG.SYS file.");
        exit(0);
    }
    for (i = first; i < first + count; i++) {
        voc_path[0] = i + 'A';
        voc_path[1] = ':';
        voc_path[2] = 0;
        strcat(voc_path, "\\trekcd\\voc\\speech.mrk");
        if ((fd = open(voc_path, O_RDONLY)) != -1) {
            close(fd);
            voc_path[0] = i + 'A';
            voc_path[1] = ':';
            voc_path[2] = 0;
            strcat(voc_path, "\\trekcd\\voc\\");
            voc_on_cd = 1;
            return;
        }
    }
    SetExitMsg("Couldn't find the Star Trek: 25th Anniversary Enhanced CD-ROM disc.\nMake sure you've inserted the disc into your CD-ROM drive.");
    exit(1);
}

void PrintExitMsg(void)
{
    if (exit_msg)
        printf(exit_msg);
}

void SetExitMsg(char *msg)
{
    exit_msg = msg;
}

/* Unpack from src while at least 16 bytes of input remain; returns the
 * number of bytes consumed and advances *pdst. */
int UnpackChunk(unsigned char far *src, unsigned char far **pdst, unsigned len)
{
    unsigned char far *dst;
    unsigned char far *end;

    dst = *pdst;
    end = src + len - 16;
    if (len <= 16)
        return 0;
    len -= 16;
    end = src + len;
    _asm {
        push si
        push di
        lds si, src
        les di, dst
    l_next:
        lodsb
        cmp al, 0FFh
        jne l_bits
        test di, 1
        je l_even8
        movsb
        mov cx, 3
        rep movsw
        movsb
        cmp si, word ptr end
        jb l_next
        jmp l_done
    l_even8:
        mov cx, 4
        rep movsw
        cmp si, word ptr end
        jb l_next
        jmp l_done
    l_bits:
        mov dl, al
        mov dh, 1
        shr dx, 1
        jae l_match
        movsb
        shr dx, 1
        jae l_match
        movsb
        shr dx, 1
        jae l_match
        movsb
        shr dx, 1
        jae l_match
        movsb
        shr dx, 1
        jae l_match
        movsb
        shr dx, 1
        jae l_match
        movsb
        shr dx, 1
        jae l_match
        movsb
        shr dx, 1
        jae l_match
        movsb
        cmp si, word ptr end
        jb l_next
        jmp l_done
    l_cont:
        shr dx, 1
        je l_check
        jae l_match
        movsb
        shr dx, 1
        je l_check
        jae l_match
        movsb
        shr dx, 1
        je l_check
        jae l_match
        movsb
        shr dx, 1
        je l_check
        jae l_match
        movsb
        shr dx, 1
        je l_check
        jae l_match
        movsb
        shr dx, 1
        je l_check
        jae l_match
        movsb
        shr dx, 1
        je l_check
        jae l_match
        movsb
    l_check:
        cmp si, word ptr end
        jae l_done
        jmp l_next
    l_match:
        lodsw
        mov cx, ax
        and cx, 0Fh
        add cx, 3
        cmp ax, 20h
        jb l_fill
        shr ax, 4
        mov bx, si
        mov si, di
        sub si, ax
        mov ax, es
        mov ds, ax
        test di, 1
        je l_copyw
        movsb
        dec cx
    l_copyw:
        shr cx, 1
        rep movsw
        jae l_copied
        movsb
    l_copied:
        mov si, bx
        mov ds, word ptr src+2
        jmp l_cont
    l_fill:
        mov al, es:[di-1]
        mov ah, al
        test di, 1
        je l_fillw
        stosb
        dec cx
    l_fillw:
        shr cx, 1
        rep stosw
        jae l_cont
        stosb
        jmp l_cont
    l_done:
        mov word ptr src, si
        mov word ptr dst, di
        mov ax, ss
        mov ds, ax
        pop di
        pop si
    }
    *pdst = dst;
    return src + len - end;
}

/* Unpack the rest of the input. Each flag byte covers eight items: a set
 * bit is a literal byte, a clear bit a 12:4 bit (distance, length - 3)
 * back reference. */
void Unpack(unsigned char far *src, unsigned char far *dst, unsigned len)
{
    unsigned char far *end;
    unsigned flags;
    unsigned code;
    unsigned count;

    for (end = src + len; src < end; ) {
        flags = *src++;
        if (flags & 0x01)
            *dst++ = *src++;
        else {
            code = *(unsigned far *)src;
            count = (code & 0x0F) + 3;
            src += 2;
            _asm {
                push si
                push di
                push ds
                les di, dst
                lds si, dst
                mov ax, code
                shr ax, 4
                sub si, ax
                mov cx, count
                rep movsb
                pop ds
                pop di
                pop si
            }
            dst += count;
        }
        if (src >= end)
            break;
        if (flags & 0x02)
            *dst++ = *src++;
        else {
            code = *(unsigned far *)src;
            count = (code & 0x0F) + 3;
            src += 2;
            _asm {
                push si
                push di
                push ds
                les di, dst
                lds si, dst
                mov ax, code
                shr ax, 4
                sub si, ax
                mov cx, count
                rep movsb
                pop ds
                pop di
                pop si
            }
            dst += count;
        }
        if (src >= end)
            break;
        if (flags & 0x04)
            *dst++ = *src++;
        else {
            code = *(unsigned far *)src;
            count = (code & 0x0F) + 3;
            src += 2;
            _asm {
                push si
                push di
                push ds
                les di, dst
                lds si, dst
                mov ax, code
                shr ax, 4
                sub si, ax
                mov cx, count
                rep movsb
                pop ds
                pop di
                pop si
            }
            dst += count;
        }
        if (src >= end)
            break;
        if (flags & 0x08)
            *dst++ = *src++;
        else {
            code = *(unsigned far *)src;
            count = (code & 0x0F) + 3;
            src += 2;
            _asm {
                push si
                push di
                push ds
                les di, dst
                lds si, dst
                mov ax, code
                shr ax, 4
                sub si, ax
                mov cx, count
                rep movsb
                pop ds
                pop di
                pop si
            }
            dst += count;
        }
        if (src >= end)
            break;
        if (flags & 0x10)
            *dst++ = *src++;
        else {
            code = *(unsigned far *)src;
            count = (code & 0x0F) + 3;
            src += 2;
            _asm {
                push si
                push di
                push ds
                les di, dst
                lds si, dst
                mov ax, code
                shr ax, 4
                sub si, ax
                mov cx, count
                rep movsb
                pop ds
                pop di
                pop si
            }
            dst += count;
        }
        if (src >= end)
            break;
        if (flags & 0x20)
            *dst++ = *src++;
        else {
            code = *(unsigned far *)src;
            count = (code & 0x0F) + 3;
            src += 2;
            _asm {
                push si
                push di
                push ds
                les di, dst
                lds si, dst
                mov ax, code
                shr ax, 4
                sub si, ax
                mov cx, count
                rep movsb
                pop ds
                pop di
                pop si
            }
            dst += count;
        }
        if (src >= end)
            break;
        if (flags & 0x40)
            *dst++ = *src++;
        else {
            code = *(unsigned far *)src;
            count = (code & 0x0F) + 3;
            src += 2;
            _asm {
                push si
                push di
                push ds
                les di, dst
                lds si, dst
                mov ax, code
                shr ax, 4
                sub si, ax
                mov cx, count
                rep movsb
                pop ds
                pop di
                pop si
            }
            dst += count;
        }
        if (src >= end)
            break;
        if (flags & 0x80)
            *dst++ = *src++;
        else {
            code = *(unsigned far *)src;
            count = (code & 0x0F) + 3;
            src += 2;
            _asm {
                push si
                push di
                push ds
                les di, dst
                lds si, dst
                mov ax, code
                shr ax, 4
                sub si, ax
                mov cx, count
                rep movsb
                pop ds
                pop di
                pop si
            }
            dst += count;
        }
    }
}

void UnpackAll(unsigned char far *src, unsigned char far *dst, unsigned len)
{
    unsigned n;

    n = UnpackChunk(src, &dst, len);
    Unpack(src + n, dst, len - n);
}

void ReadFile(int fd, void far *buf, unsigned len)
{
    unsigned got;

    if (ReadChunk(fd, buf, len, &got))
        Fatal("error reading in _lread");
}

/* Read through the far buffer in 2K pieces. */
unsigned ReadChunk(int fd, char far *buf, unsigned len, unsigned *pread)
{
    unsigned err;
    unsigned chunk;
    unsigned got;

    *pread = 0;
    while (len != 0) {
        chunk = min(len, 0x800);
        if ((err = _dos_read(fd, file_buf, chunk, &got)) != 0)
            Fatal("error reading in _lread");
        _fmemcpy(buf, file_buf, got);
        len -= chunk;
        buf += chunk;
        *pread += got;
    }
    return err;
}

void OpenDataFiles(void)
{
    int fd;
    char far *dir;
    char far *run;
    unsigned len;

    if (data_not_open == -1) {
        if ((fd = open("data.dir", O_RDONLY | O_BINARY)) == -1)
            Fatal("Can't open data.dir.");
        dir_size = filelength(fd);
        dir_count = dir_size / sizeof(DirEntry);
        dir_handle = AllocMemAbort(dir_size, 1);
        dir = LockMem(dir_handle);
        ReadFile(fd, dir, dir_size);
        UnlockMem(dir_handle);
        close(fd);
        if ((fd = open("data.run", O_RDONLY | O_BINARY)) == -1)
            Fatal("Can't open data.run.");
        len = filelength(fd);
        run_handle = AllocMemAbort(len, 1);
        run = LockMem(run_handle);
        ReadFile(fd, run, len);
        UnlockMem(run_handle);
        close(fd);
        if ((data_fd = open("data.001", O_RDONLY | O_BINARY)) == -1)
            Fatal("Can't open data.001.");
        data_not_open = 0;
        ScanPatches();
    }
}

/* Binary search DATA.DIR. Numbered files (NAME0, NAME1, ...) share one
 * entry that points into DATA.RUN. With mark == 0 the file is flagged as
 * replaced by a patch instead. */
FileInfo FindFile(char *name, char *ext, int mark)
{
    char fname[10];
    int mid;
    int r;
    int lo;
    int hi;
    int len;
    DirEntry far *dir;
    FileInfo fi;
    unsigned char far *run;
    void far *saved;
    int i;

    saved = EMSUnlock();
    dir = LockMem(dir_handle);
    CopyName(fname, name);
    strupr(fname);
    strupr(ext);
    len = strlen(fname);
    len = min(len, 8);
    lo = 0;
    hi = dir_count - 1;
    mid = dir_last;
    while (lo <= hi) {
        if ((r = _fstrncmp(ext, dir[mid].ext, 3)) == 0) {
            int n;
            int idx;

            n = _fstrlen(dir[mid].name);
            n = min(n, 8);
            idx = fname[n - 1] - dir[mid].name[n - 1];
            if (n == len && _fstrncmp(fname, dir[mid].name, n - 1) == 0
                    && (dir[mid].hi & 0x80) && idx < (dir[mid].hi & 0x7F) && idx >= 0) {
                unsigned long pos;
                unsigned long far *p;
                unsigned far *q;
                int flag;

                dir_last = mid;
                MemCpy(&fi, &dir[mid], 11);
                fi.offset = dir[mid].offset;
                fi.name[n - 1] = fname[n - 1];
                UnlockMem(dir_handle);
                run = LockMem(run_handle);
                run = run + (fi.offset & 0xFFFF);
                p = (unsigned long far *)run;
                pos = *p & 0x7FFFFE;
                flag = *p & 1;
                q = (unsigned far *)(run + 3);
                for (i = 0; i < idx; i++) {
                    flag = *q & 1;
                    pos += *q++ & 0xFFFE;
                }
                if (!mark) {
                    if (i == 0)
                        *p |= 1;
                    else
                        q[-1] |= 1;
                    flag = 1;
                }
                if (flag)
                    break;
                fi.offset = pos + 4;
                lseek(data_fd, pos, SEEK_SET);
                ReadChunk(data_fd, (char far *)&fi.size, 4, &i);
                UnlockMem(run_handle);
                EMSRestore(saved);
                return fi;
            }
            r = _fstrncmp(fname, dir[mid].name, 8);
        }
        if (r == 0) {
            long b;

            dir_last = mid;
            if (!mark)
                dir[mid].offset |= 1;
            if (dir[mid].offset & 1)
                break;
            MemCpy(&fi, &dir[mid], 11);
            b = fi.offset = ((unsigned long)dir[mid].hi << 16) + dir[mid].offset + 4;
            b = (b - 4) & 0x7FFFFFFEL;
            lseek(data_fd, b, SEEK_SET);
            ReadChunk(data_fd, (char far *)&fi.size, 4, &i);
            UnlockMem(dir_handle);
            EMSRestore(saved);
            return fi;
        } else if (r < 0)
            hi = mid - 1;
        else
            lo = mid + 1;
        mid = (lo + hi) >> 1;
    }
    UnlockMem(dir_handle);
    EMSRestore(saved);
    fi.offset = -1L;
    return fi;
}

int LoadPatch(char *name, char *ext, char far *buf)
{
    char fname[10];
    char path[64];
    int fd;
    unsigned size;
    unsigned got;
    int unused;

    CopyName(fname, name);
    sprintf(path, "patches/%s.%s", fname, ext);
    if ((fd = open(path, O_RDONLY | O_BINARY)) == -1)
        Fatal("Not found patches/%s.%s", fname, ext);
    if (ReadChunk(fd, (char far *)&size, 2, &got))
        Fatal("error reading patches/%s.%s", fname, ext);
    if (ReadChunk(fd, buf, (unsigned)filelength(fd) - 2, &got))
        Fatal("error reading patches/%s.%s", fname, ext);
    close(fd);
    return 1;
}

int LoadPatchPacked(char *name, char *ext, unsigned char far *dst)
{
    char fname[10];
    char path[64];
    int fd;
    unsigned size;
    unsigned left;
    unsigned have;
    unsigned got;
    unsigned char buf[512];
    unsigned n;

    CopyName(fname, name);
    sprintf(path, "patches/%s.%s", fname, ext);
    if ((fd = open(path, O_RDONLY | O_BINARY)) == -1)
        Fatal("Not found patches/%s.%s", fname, ext);
    if (ReadChunk(fd, (char far *)&size, 2, &got))
        Fatal("error reading patches/%s.%s", fname, ext);
    left = filelength(fd) - 2;
    have = 0;
    while (left != 0) {
        if (ReadChunk(fd, buf + have, min(sizeof(buf) - have, left), &got))
            Fatal("error reading %s.%s", fname, ext);
        n = UnpackChunk(buf, &dst, have + got);
        left -= got;
        have += got - n;
        MemCpy(buf, buf + n, have);
    }
    Unpack(buf, dst, have);
    close(fd);
    return 1;
}

long GetPatchSize(char *name, char *ext)
{
    char fname[10];
    char path[64];
    int fd;
    unsigned size;
    unsigned got;

    CopyName(fname, name);
    sprintf(path, "patches/%s.%s", fname, ext);
    if ((fd = open(path, O_RDONLY | O_BINARY)) == -1)
        Fatal("Not found patches/%s.%s", fname, ext);
    ReadChunk(fd, (char far *)&size, 2, &got);
    close(fd);
    return size;
}

int GetPatchSizes(char *name, char *ext, unsigned *psize, unsigned *ppacked)
{
    char fname[10];
    char path[64];
    int fd;
    unsigned got;

    CopyName(fname, name);
    sprintf(path, "patches/%s.%s", fname, ext);
    if ((fd = open(path, O_RDONLY | O_BINARY)) == -1)
        Fatal("Not found patches/%s.%s", fname, ext);
    ReadChunk(fd, psize, 2, &got);
    *ppacked = filelength(fd) - 2;
    close(fd);
    return 1;
}

void LoadFile(char *name, char *ext, char far *buf)
{
    char fname[10];
    FileInfo fi;
    unsigned got;
    int unused;

    CopyName(fname, name);
    fi = FindFile(fname, ext, 1);
    if (fi.offset & 1) {
        if (LoadPatch(name, ext, buf))
            return;
        else
            Fatal("File not found: %s %s\n", name, ext);
    }
    lseek(data_fd, fi.offset, SEEK_SET);
    if (ReadChunk(data_fd, buf, fi.packed, &got))
        Fatal("error reading %s.%s", fname, ext);
}

void LoadFilePacked(char *name, char *ext, unsigned char far *dst)
{
    char fname[10];
    FileInfo fi;
    unsigned left;
    unsigned have;
    unsigned got;
    unsigned char buf[512];
    unsigned n;

    CopyName(fname, name);
    fi = FindFile(fname, ext, 1);
    if (fi.offset & 1) {
        if (LoadPatchPacked(name, ext, dst))
            return;
        else
            Fatal("File not found: %s %s\n", name, ext);
    }
    lseek(data_fd, fi.offset, SEEK_SET);
    left = fi.packed;
    have = 0;
    while (left != 0) {
        if (ReadChunk(data_fd, buf + have, min(sizeof(buf) - have, left), &got))
            Fatal("error reading %s.%s", fname, ext);
        n = UnpackChunk(buf, &dst, have + got);
        left -= got;
        have += got - n;
        MemCpy(buf, buf + n, have);
    }
    Unpack(buf, dst, have);
}

long GetFileSize(char *name, char *ext)
{
    long size;
    FileInfo fi;
    char fname[10];

    CopyName(fname, name);
    fi = FindFile(fname, ext, 1);
    if (fi.offset & 1)
        return GetPatchSize(name, ext);
    return fi.size;
}

void GetFileSizes(char *name, char *ext, unsigned *psize, unsigned *ppacked)
{
    char fname[10];
    FileInfo fi;

    CopyName(fname, name);
    fi = FindFile(fname, ext, 1);
    if (fi.offset & 1) {
        GetPatchSizes(name, ext, psize, ppacked);
        return;
    }
    *psize = fi.size;
    *ppacked = fi.packed;
}

/* Copy a name up to the first space. */
void CopyName(char *dst, char *src)
{
    while ((*dst = *src) != 0 && *src != ' ') {
        dst++;
        src++;
    }
    *dst = 0;
}

/* Flag every file in patches/ as replaced. */
void ScanPatches(void)
{
    char *p;
    char name[10];
    char ext[4];
    int unused;
    char *q;

    if ((p = FindFirstPatch()) != 0) {
        do {
            q = name;
            while (*p != 0 && *p != '.')
                *q++ = *p++;
            *q = 0;
            q = ext;
            if (*p != 0) {
                p++;
                while (*p != 0)
                    *q++ = *p++;
            }
            *q = 0;
            FindFile(name, ext, 0);
        } while ((p = FindNextPatch()) != 0);
    }
}

char *FindFirstPatch(void)
{
    if (_dos_findfirst("patches/*.*", _A_RDONLY, &patch_find) == 0)
        return patch_find.name;
    else
        return 0;
}

char *FindNextPatch(void)
{
    if (_dos_findnext(&patch_find) == 0)
        return patch_find.name;
    else
        return 0;
}
