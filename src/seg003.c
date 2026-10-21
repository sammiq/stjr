/* seg003: resource files: unpacking, archives (.dir/.run/.001) and loose files */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <io.h>
#include <dos.h>
#include "ems.h"
#include "mem.h"
#include "resource.h"

static Archive data_archive;           /* the game's own data files */
static Archive mission_archive;        /* the current mission's */
static struct find_t patch_find;

void Fatal(char *fmt, ...);     /* fatal error */


char *data_dir = "data/";
char *uncomp_dir = "uncomp/";

extern char mission_name[];
extern char cd_path[];          /* where the game was installed from */

void CachePurgeAll(void);           /* (seg016) */
int OpenSearch(char *name, char *dirs);     /* open name in one of dirs (";"-separated) */

/* Unpack from src while at least 16 bytes of input remain; returns the
 * number of bytes consumed and advances *pdst. */
int UnpackChunk(unsigned char far *src, unsigned char far **pdst, unsigned len)
{
    unsigned char far *dst;
    unsigned char far *end;

    dst = *pdst;
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

    for (end = src + len; src < end; ) {
        flags = *src++;
        if (flags & 0x01)
            *dst++ = *src++;
        else {
            unsigned code;
            unsigned count;

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
            unsigned code;
            unsigned count;

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
            unsigned code;
            unsigned count;

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
            unsigned code;
            unsigned count;

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
            unsigned code;
            unsigned count;

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
            unsigned code;
            unsigned count;

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
            unsigned code;
            unsigned count;

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
            unsigned code;
            unsigned count;

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

/* fatal error */

void UnpackAll(unsigned char far *src, unsigned char far *dst, unsigned len)
{
    unsigned n;

    n = UnpackChunk(src, &dst, len);
    Unpack(src + n, dst, len - n);
}

/* New in the sequel. */
int OpenFile(char *name)
{
    int fd;

    if ((fd = _open(name, O_RDONLY | O_BINARY)) == -1)
        Fatal("Can't open %s", name);
    return fd;
}

void ReadFile(int fd, void far *buf, unsigned len)
{
    unsigned got;

    if (len != 0 && _dos_read(fd, buf, len, &got))
        Fatal("error reading in _lread");
}

/* New in the sequel. */
int ReadByte(int fd)
{
    char c;

    if (_read(fd, &c, 1) == 1)
        return c;
    return -1;
}

/* The game's own data files, and those of the mission being played
 * (new in the sequel: each mission has its own archive). */
void OpenDataArchive(void)
{
    OpenArchive(&data_archive, "data");
    mission_archive.fd = -1;
}

void OpenMissionArchive(void)
{
    CachePurgeAll();
    CloseArchive(&mission_archive);
    OpenArchive(&mission_archive, mission_name);
}

/* Read name.dir and name.run, open name.001 and flag the files that have
 * loose copies in name/ (here or on the CD) as replaced. */
void OpenArchive(Archive *a, char *name)
{
    char dirs[128];
    char path[14];
    char far *dir;
    unsigned size;
    int fd;

    sprintf(dirs, "./;%s", cd_path);
    strcpy(path, name);
    strcat(path, ".dir");
    if ((fd = OpenSearch(path, dirs)) == -1)
        Fatal("Not found %s", path);
    size = filelength(fd);
    a->count = size / sizeof(DirEntry);
    a->dir = AllocMemAbort(size, 1);
    dir = LockMem(a->dir);
    ReadFile(fd, dir, size);
    UnlockMem(a->dir);
    _close(fd);
    strcpy(path, name);
    strcat(path, ".run");
    if ((fd = OpenSearch(path, dirs)) == -1)
        Fatal("Not found %s", path);
    {
        unsigned len;
        char far *run;

        a->run = AllocMemAbort(len = filelength(fd), 1);
        run = LockMem(a->run);
        ReadFile(fd, run, len);
        UnlockMem(a->run);
    }
    _close(fd);
    strcpy(path, name);
    strcat(path, ".001");
    if ((fd = OpenSearch(path, dirs)) == -1)
        Fatal("Not found %s", path);
    a->fd = fd;
    a->last = (a->count - 1) >> 1;
    sprintf(dirs, "%s%s/*.*", "./", name);
    ScanPatches(a, dirs);
    sprintf(dirs, "%s%s/*.*", cd_path, name);
    ScanPatches(a, dirs);
}

void CloseArchive(Archive *a)
{
    if (a->fd != -1) {
        _close(a->fd);
        FreeMem(a->dir);
        FreeMem(a->run);
        a->fd = -1;
    }
}

/* Find a file: in the mission's archive, the game's, or loose. */
FileInfo LocateFile(char *name, char *ext)
{
    FileInfo fi;

    fi = FindFile(&mission_archive, name, ext, 1);
    if (fi.offset & 1)
        fi = FindFile(&data_archive, name, ext, 1);
    if (fi.offset & 1)
        fi = OpenLooseFile(name, ext);
    return fi;
}

/* A file outside the archives: a 2-byte unpacked size, then the data. */
FileInfo OpenLooseFile(char *name, char *ext)
{
    char dirs[128];
    char path[14];
    FileInfo fi;
    unsigned got;
    int fd;

    CopyName(path, name);
    strcat(path, ".");
    strcat(path, ext);
    sprintf(dirs, "./data;./%s;%sdata;%s%s", mission_name, cd_path, cd_path, mission_name);
    if ((fd = OpenSearch(path, dirs)) == -1)
        Fatal("Not found %s", path);
    _dos_read(fd, &fi.size, 2, &got);
    fi.packed = filelength(fd) - 2;
    fi.offset = 2;
    fi.fd = fd;
    return fi;
}

/* Close a loose file (archive files share the archive's handle). */
void CloseFile(FileInfo *fi)
{
    if (fi->offset == 2)
        _close(fi->fd);
}

/* Binary search a .dir. Numbered files (NAME0, NAME1, ...) share one
 * entry that points into the .run. With mark == 0 the file is flagged as
 * replaced by a loose copy instead.
 *
 * 99.1%: in the numbered-file branch the original keeps a in si and run in
 * di (reloading mid from the stack); this keeps a in di. Not declaration
 * order, the scope of run, or how a->last = mid is written. */
FileInfo FindFile(Archive *a, char *name, char *ext, int mark)
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
    EMSBlock *saved;
    int i;

    if (a->fd != -1) {
        saved = EMSSave();
        dir = LockMem(a->dir);
        CopyName(fname, name);
        _strupr(fname);
        _strupr(ext);
        len = strlen(fname);
        len = min(len, 8);
        lo = 0;
        hi = a->count - 1;
        mid = a->last;
        while (lo <= hi) {
            if ((r = _fstrncmp(ext, dir[mid].ext, 3)) == 0) {
                int n;
                int idx;
                char c;

                c = dir[mid].name[7];
                dir[mid].name[7] = 0;
                n = _fstrlen(dir[mid].name);
                dir[mid].name[7] = c;
                if (n == 7 && c != 0)
                    n = 8;
                idx = fname[n - 1] - dir[mid].name[n - 1];
                if (n == len && _fstrncmp(fname, dir[mid].name, n - 1) == 0
                        && (dir[mid].hi & 0x80) && idx < (dir[mid].hi & 0x7F) && idx >= 0) {
                    unsigned long pos;
                    unsigned long far *p;
                    unsigned far *q;
                    int flag;

                    a->last = mid;
                    fi.offset = dir[mid].offset;
                    UnlockMem(a->dir);
                    run = LockMem(a->run);
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
                    if (flag) {
                        UnlockMem(a->run);
                        EMSRestore(saved);
                        fi.offset = -1L;
                        return fi;
                    }
                    fi.offset = pos + 4;
                    _lseek(a->fd, pos, SEEK_SET);
                    _dos_read(a->fd, &fi.size, 4, &i);
                    fi.fd = a->fd;
                    UnlockMem(a->run);
                    EMSRestore(saved);
                    return fi;
                }
                r = _fstrncmp(fname, dir[mid].name, 8);
            }
            if (r == 0) {
                a->last = mid;
                if (!mark)
                    dir[mid].offset |= 1;
                if (dir[mid].offset & 1)
                    break;
                fi.offset = ((unsigned long)dir[mid].hi << 16) + dir[mid].offset + 4;
                _lseek(a->fd, (fi.offset - 4) & 0x7FFFFFFEL, SEEK_SET);
                _dos_read(a->fd, &fi.size, 4, &i);
                fi.fd = a->fd;
                UnlockMem(a->dir);
                EMSRestore(saved);
                return fi;
            } else if (r < 0)
                hi = mid - 1;
            else
                lo = mid + 1;
            mid = (lo + hi) >> 1;
        }
        UnlockMem(a->dir);
        EMSRestore(saved);
    }
    fi.offset = -1L;
    return fi;
}

void LoadFile(char *name, char *ext, char far *buf)
{
    char fname[10];
    FileInfo fi;
    unsigned got;

    CopyName(fname, name);
    fi = LocateFile(fname, ext);
    lseek(fi.fd, fi.offset, SEEK_SET);
    if (_dos_read(fi.fd, buf, fi.packed, &got))
        Fatal("error reading %s.%s", fname, ext);
    CloseFile(&fi);
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
    fi = LocateFile(fname, ext);
    lseek(fi.fd, fi.offset, SEEK_SET);
    have = 0;
    left = fi.packed;
    while (left != 0) {
        if (_dos_read(fi.fd, buf + have, min(sizeof(buf) - have, left), &got))
            Fatal("error reading %s.%s", fname, ext);
        n = UnpackChunk(buf, &dst, have + got);
        left -= got;
        have += got - n;
        MemCpy(buf, buf + n, have);
    }
    Unpack(buf, dst, have);
    CloseFile(&fi);
}

long GetFileSize(char *name, char *ext)
{
    char fname[10];
    FileInfo fi;

    CopyName(fname, name);
    fi = LocateFile(fname, ext);
    CloseFile(&fi);
    return fi.size;
}

void GetFileSizes(char *name, char *ext, unsigned *psize, unsigned *ppacked)
{
    char fname[10];
    FileInfo fi;

    CopyName(fname, name);
    fi = LocateFile(fname, ext);
    *psize = fi.size;
    *ppacked = fi.packed;
    CloseFile(&fi);
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

/* Flag every file matching pattern as replaced in a. */
void ScanPatches(Archive *a, char *pattern)
{
    char *p;
    char name[10];
    char ext[4];
    char *q;

    if ((p = FindFirstPatch(pattern)) != 0) {
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
            FindFile(a, name, ext, 0);
        } while ((p = FindNextPatch()) != 0);
    }
}

char *FindFirstPatch(char *pattern)
{
    if (_dos_findfirst(pattern, _A_RDONLY, &patch_find) == 0)
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
