/* seg018: planets */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "resource.h"
#include "fixmath.h"
#include "obj3d.h"

void Fatal(char *fmt, ...);     /* fatal error */

extern long proj_dist;
extern float star_near;
extern long blink_count;
extern Bitmap far *backbuf;
MemHandle fractal_handle;        /* result of MakeFractal */
unsigned long planet_start;
int far *frac_pal;
int frac_size2;
int frac_bytes;
int far *frac_map;               /* heights, in the back buffer */
Bitmap far *frac_bmp;
int frac_size;
extern Obj3D dummy_planet;

/* Colours for the fractal heights of each planet palette (kept in a far
 * data segment). */
int far planet_pals[22][25] = {
    { 0x73, 0x6E, 0x69, 0x64, 0xA2, 0xA3, 0xA4, 0xA5, 0x98, 0x99, 0x9A, 0x9B, 0x9C, 0x9D, 0x9E,
      0x9F, 0xCB, 0xCA, 0xC9, 0xC8, 0xC7, 0xC6, 0xC5, 0xC4, 0xC3 },
    { 0x63, 0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xC8, 0x96, 0x97,
      0x98, 0x99, 0x9A, 0x9B, 0xA7, 0x9D, 0x9E, 0xAF, 0xAE, 0xAD },
    { 0x8C, 0x8B, 0x8A, 0x89, 0x88, 0x87, 0x86, 0x85, 0x84, 0x83, 0x82, 0x81, 0x80, 0x7F, 0x80,
      0x81, 0x82, 0x1D, 0xA8, 0xA9, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE },
    { 0x78, 0xD8, 0xD9, 0xDA, 0xDB, 0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0x95, 0x96, 0x97, 0x98, 0x99,
      0x9A, 0x9C, 0x9D, 0x9E, 0x9F, 0x22, 0xA9, 0xAB, 0xAC, 0xAD },
    { 0x8B, 0x89, 0x87, 0x86, 0x85, 0x84, 0x83, 0x07, 0x23, 0x0A, 0x0B, 0x28, 0x2E, 0x5F, 0x5A,
      0xB0, 0xB1, 0x55, 0xB4, 0x38, 0x25, 0x22, 0xA9, 0xAB, 0xAC },
    { 0x8A, 0x88, 0x86, 0x4A, 0x48, 0x49, 0x46, 0x45, 0x41, 0x3F, 0x05, 0x24, 0x0B, 0x28, 0x2E,
      0x5F, 0x5A, 0x42, 0xC6, 0x25, 0x22, 0xA9, 0xAB, 0xAC, 0xAD },
    { 0x8C, 0x8B, 0x8A, 0x89, 0x88, 0x87, 0x86, 0x85, 0x84, 0x83, 0x82, 0x81, 0x80, 0x81, 0x82,
      0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x88, 0x89, 0x8A, 0x8B },
    { 0xA5, 0x98, 0x99, 0x9A, 0x9B, 0x9C, 0x9D, 0x9E, 0x9F, 0xBF, 0xBE, 0xBD, 0xBC, 0xBB, 0xBA,
      0xB9, 0xB8, 0xA9, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF, 0xAF },
    { 0xA4, 0xA3, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA6, 0xA5, 0xA4, 0xA3, 0xA2, 0xA3, 0xA4,
      0xA3, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA6, 0xA5, 0xA4 },
    { 0x89, 0x8A, 0x8B, 0x8C, 0x63, 0x31, 0x98, 0x99, 0x9A, 0x9B, 0x9C, 0xBF, 0xBE, 0xBD, 0xBC,
      0xBB, 0xBA, 0xB9, 0xB8, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAE },
    { 0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0x9B, 0x9C, 0x9D, 0x9E,
      0x9F, 0x9E, 0x9D, 0x9C, 0x9B, 0x9A, 0x99, 0x98, 0x97, 0x96 },
    { 0xAF, 0x01, 0x01, 0x80, 0x80, 0x01, 0x01, 0xA7, 0x01, 0x01, 0x80, 0x80, 0x01, 0x01, 0xAF,
      0x01, 0x01, 0x80, 0x80, 0x01, 0x01, 0xB7, 0x01, 0x01, 0x80 },
    { 0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xCB, 0xCC, 0xCD, 0xCE,
      0xCF, 0xCE, 0xCD, 0xCC, 0xCB, 0xCA, 0xC9, 0xC8, 0xC7, 0xC6 },
    { 0xAC, 0xAB, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF, 0xAE, 0xAD, 0xAC, 0xAB, 0xAA, 0xAB, 0xAC,
      0xAB, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF, 0xAE, 0xAD, 0xAC },
    { 0xB4, 0xB3, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB6, 0xB5, 0xB4, 0xB3, 0xB2, 0xB3, 0xB4,
      0xB3, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB6, 0xB5, 0xB4 },
    { 0x79, 0x78, 0xD8, 0xD9, 0xDA, 0xDB, 0xB0, 0xDB, 0xDA, 0xD9, 0xD8, 0x78, 0x79, 0x78, 0xD8,
      0xD9, 0xDA, 0xDB, 0xB0, 0xDB, 0xDA, 0xD9, 0xD8, 0x78, 0x79 },
    { 0x8C, 0x8C, 0x8C, 0x8C, 0x63, 0x63, 0x63, 0x31, 0x31, 0x63, 0x63, 0x63, 0x8C, 0x8C, 0x8C,
      0x8C, 0x63, 0x63, 0x63, 0x31, 0x31, 0x63, 0x63, 0x63, 0x8C },
    { 0x6E, 0x69, 0x69, 0xA1, 0xA1, 0xA1, 0xA2, 0xA1, 0xA1, 0xA1, 0x69, 0x69, 0x6E, 0x69, 0x69,
      0xA1, 0xA1, 0xA1, 0xA2, 0xA1, 0xA1, 0xA1, 0x69, 0x69, 0x6E },
    { 0xBC, 0xBB, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF, 0xBE, 0xBD, 0xBC, 0xBB, 0xBA, 0xBB, 0xBC,
      0xBB, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF, 0xBE, 0xBD, 0xBC },
    { 0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6,
      0xD7, 0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD0 },
    { 0xE0, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE0, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6,
      0xE7, 0xE0, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE0 },
    { 0xE8, 0xE9, 0xEA, 0xEB, 0xEC, 0xED, 0xEE, 0xEF, 0xE8, 0xE9, 0xEA, 0xEB, 0xEC, 0xED, 0xEE,
      0xEF, 0xE8, 0xE9, 0xEA, 0xEB, 0xEC, 0xED, 0xEE, 0xEF, 0xE8 }
};

int small_planets = 0;                  /* generating textures is too slow */
int planet_unused[6] = { 0, 1, 0, 0, 0, -1 };
unsigned long planet_frame = 0;
int planet_n = 0;

int DrawPlanetLarge(Obj3D *o);
int DrawPlanetSmall(Obj3D *o);
void CreatePlanet(Obj3D *o, char *name, int radius, int small, unsigned seed, int pal);
void InitPlanet(Obj3D *o, char *name, int radius, int small, int gen, unsigned seed, int pal);
int DrawPlanet(Obj3D *o);
void FreePlanet(Obj3D *o);
void MakeFractal(int size, unsigned seed, unsigned pal);
void FracSquare(int x0, int y0, int x1, int y1);
void FracEdge(int x0, int y0, int x1, int y1);
void FracColour(void);

/* Draw the planet's texture wrapped round a sphere into its bitmap, at one
 * of five sizes by distance. planet.dat holds the sphere's texture
 * coordinates for each size. */
int DrawPlanetLarge(Obj3D *o)
{
    Vec32 rel;
    Vec32 v;
    Matrix m;
    int pitch;
    int yaw;
    int tu;
    int tv;
    char far *src;
    int n;
    int nn;
    char far *work0;
    char far *table;
    char far *pix;
    long dist;
    MemHandle wh;
    MemHandle bh;
    Bitmap far *bmp;
    char far *work;
    int created;
    int len;

    created = 0;
    if (o->generated == 0)
        bh = CacheGet(o->name, o->small ? "spl" : "lpl", 1, 1, 1);
    else {
        bh = CacheGet(o->name, o->small ? "%sf" : "%lf", 0, 0, 1);
        if (bh == 0) {
            len = 128;
            if (o->small)
                len >>= 2;
            MakeFractal(len, o->seed, o->palette);
            if (fractal_handle == 0)
                return 0;
            bh = fractal_handle;
            CacheStore(o->name, o->small ? "%sf" : "%lf", bh);
            created = 1;
        }
    }
    wh = CacheGet("planet", "%lw", 0, 0, 1);
    if (wh == 0) {
        wh = AllocMem(0x84AC, 0);
        if (wh == 0) {
            ReleaseCache(bh);
            return 0;
        }
        work = LockMem(wh);
        LoadFilePacked("planet", "dat", work);
        UnlockMem(wh);
        CacheStore("planet", "%lw", wh);
        created = 1;
    }
    o->r3s = wh;
    o->r3s_type = 0x761A;
    planet_frame++;
    if (created) {
        if (planet_n == 0)
            planet_start = planet_frame;
        planet_n++;
        if (planet_n == 4) {
            planet_n = 0;
            if (planet_frame <= planet_start + 6)
                small_planets = 1;
        }
    }
    bmp = LockMem(bh);
    work = LockMem(wh);
    if (o->small) {
        if (bmp->w != 32 || bmp->h != 32)
            Fatal("Planet image not %d x %d", 32, 32);
    } else if (bmp->w != 128 || bmp->h != 128)
        Fatal("Planet image not %d x %d", 128, 128);
    work0 = work;
    table = work + 0x7622;
    pix = bmp->data;
    dist = proj_dist * o->radius;
    if (o->view.z < star_near)
        Fatal("object too close.");
    if (o->view.z >= dist) {
        src = work + 0x4000;
        o->size = o->radius;
        n = 11;
    } else if (o->view.z >= dist / 2) {
        src = work + 0x40F2;
        o->size = o->radius / 2;
        n = 21;
    } else if (o->small || o->view.z >= dist / 3) {
        src = work + 0x4464;
        o->size = o->radius / 3;
        n = 31;
    } else if (o->view.z >= dist / 4) {
        src = work + 0x4BE6;
        o->size = o->radius / 4;
        n = 41;
    } else {
        src = work + 0x5908;
        o->size = o->radius / 6;
        n = 61;
    }
    ((BitmapHdr far *)(work + 0x761A))->x = (n - 1) / 2;
    ((BitmapHdr far *)(work + 0x761A))->y = (n - 1) / 2;
    ((BitmapHdr far *)(work + 0x761A))->w = n;
    ((BitmapHdr far *)(work + 0x761A))->h = n;
    nn = n * n;
    MemSet(&rel, 12, 0);
    Vec32Sub(&rel, &o->view);
    MatTranspose(&o->view_m, &m);
    MatTVecMul32(&rel, &m, &v);
    rel = v;
    yaw = FixAtan2(rel.x, rel.z) - 0x200;
    pitch = FixASin(FixDiv(rel.y, o->scale));
    if (pitch < -128 || pitch > 128) {
        len = FixLength(rel.x, rel.z, 0);
        pitch = FixACos(FixDiv((unsigned)len, o->scale));
        if (rel.y < 0)
            pitch = -pitch;
    }
    MatIdentity(&o->rot);
    MatRotY(-yaw, &o->rot);
    MatRotX(pitch, &o->rot);
    tu = (((long)pitch << 7) + 0x200) / 0x400;
    tv = (((long)-yaw << 7) + 0x200) / 0x400;
    tu &= 0x7F;
    tv &= 0x7F;
    tu = tu << 7;
    tv = tv << 7;
    /* Look each pixel of the sphere up in the texture. The texture's
     * address is patched into the loop. */
    if (o->small) {
        _asm {
            push si
            push di
            push bp
            lds si, src
            mov ax, word ptr pix
            mov word ptr cs:l_spatch+3, ax
            mov es, word ptr pix+2
            mov di, word ptr table
            mov dx, tv
            mov cx, nn
            mov al, 0BFh
            mov ah, 0BFh
            mov bp, tu
            jmp l_snext
        l_sblank:
            mov bx, 8000h
            jmp l_sclear
        l_sskip:
            add si, 2
        l_sclear:
            mov byte ptr [di], 0
            inc di
            and bx, [si]
            loopne l_sskip
            jcxz l_sdone
        l_snext:
            mov bx, [si]
            add si, 2
            add bx, bp
            js l_sblank
            and bh, al
            mov bx, [bx]
            add bx, dx
            and bh, ah
            shl bx, 1
            shr bh, 2
            shr bx, 3
        l_spatch:
            mov bl, es:[bx+1234h]
            mov [di], bl
            inc di
            loop l_snext
        l_sdone:
            mov ax, ss
            mov ds, ax
            pop bp
            pop di
            pop si
        }
    } else {
        _asm {
            push si
            push di
            push bp
            lds si, src
            mov ax, word ptr pix
            mov word ptr cs:l_lpatch+3, ax
            mov es, word ptr pix+2
            mov di, word ptr table
            mov dx, tv
            mov cx, nn
            mov al, 0BFh
            mov ah, 0BFh
            mov bp, tu
            jmp l_lnext
        l_lblank:
            mov bx, 8000h
            jmp l_lclear
        l_lskip:
            add si, 2
        l_lclear:
            mov byte ptr [di], 0
            inc di
            and bx, [si]
            loopne l_lskip
            jcxz l_ldone
        l_lnext:
            mov bx, [si]
            add si, 2
            add bx, bp
            js l_lblank
            and bh, al
            mov bx, [bx]
            add bx, dx
            and bh, ah
        l_lpatch:
            mov bl, es:[bx+1234h]
            mov [di], bl
            inc di
            loop l_lnext
        l_ldone:
            mov ax, ss
            mov ds, ax
            pop bp
            pop di
            pop si
        }
    }
    UnlockMem(wh);
    UnlockMem(bh);
    ReleaseCache(bh);
    return 1;
}

/* DrawPlanetLarge for slow machines: a 32x32 texture and two sizes. */
int DrawPlanetSmall(Obj3D *o)
{
    Vec32 rel;
    Vec32 v;
    Matrix m;
    int pitch;
    int yaw;
    int tu;
    int tv;
    char far *src;
    int n;
    int nn;
    char far *work0;
    char far *table;
    char far *pix;
    long dist;
    MemHandle wh;
    MemHandle bh;
    Bitmap far *bmp;
    char far *work;
    int len;

    if (o->generated == 0)
        bh = CacheGet(o->name, "spl", 1, 1, 1);
    else {
        bh = CacheGet(o->name, "%sf", 0, 0, 1);
        if (bh == 0) {
            len = 32;
            if (o->small)
                len >>= 2;
            MakeFractal(len, o->seed, o->palette);
            if (fractal_handle == 0)
                Fatal("Can't create small fractal planet!");
            bh = fractal_handle;
            CacheStore(o->name, "%sf", bh);
        }
    }
    wh = CacheGet("planet", "%sw", 0, 0, 1);
    if (wh == 0) {
        wh = AllocMem(0x143E, 0);
        if (wh == 0)
            Fatal("Can't alloc small work segment!");
        work = LockMem(wh);
        LoadFilePacked("planet", "sdt", work);
        UnlockMem(wh);
        CacheStore("planet", "%sw", wh);
    }
    o->r3s = wh;
    o->r3s_type = 0x1074;
    bmp = LockMem(bh);
    work = LockMem(wh);
    if (bmp->w != 32 || bmp->h != 32)
        Fatal("Planet image not %d x %d", 32, 32);
    work0 = work;
    table = work + 0x107C;
    pix = bmp->data;
    dist = proj_dist * o->radius;
    if (o->view.z < star_near)
        Fatal("object too close.");
    if (o->view.z >= dist) {
        src = work + 0x800;
        o->size = o->radius;
        n = 11;
    } else {
        src = work + 0x8F2;
        o->size = o->radius / 3;
        n = 31;
    }
    ((BitmapHdr far *)(work + 0x1074))->x = (n - 1) / 2;
    ((BitmapHdr far *)(work + 0x1074))->y = (n - 1) / 2;
    ((BitmapHdr far *)(work + 0x1074))->w = n;
    ((BitmapHdr far *)(work + 0x1074))->h = n;
    nn = n * n;
    MemSet(&rel, 12, 0);
    Vec32Sub(&rel, &o->view);
    MatTranspose(&o->view_m, &m);
    MatTVecMul32(&rel, &m, &v);
    rel = v;
    yaw = FixAtan2(rel.x, rel.z) - 0x200;
    pitch = FixASin(FixDiv(rel.y, o->scale));
    if (pitch < -128 || pitch > 128) {
        len = FixLength(rel.x, rel.z, 0);
        pitch = FixACos(FixDiv((unsigned)len, o->scale));
        if (rel.y < 0)
            pitch = -pitch;
    }
    MatIdentity(&o->rot);
    MatRotY(-yaw, &o->rot);
    MatRotX(pitch, &o->rot);
    tu = (((long)pitch << 5) + 0x200) / 0x400;
    tv = (((long)-yaw << 5) + 0x200) / 0x400;
    tu &= 0x1F;
    tv &= 0x1F;
    tu = tu << 6;
    tv = tv << 5;
    _asm {
        push si
        push di
        push bp
        lds si, src
        mov ax, word ptr pix
        mov word ptr cs:l_patch+3, ax
        mov es, word ptr pix+2
        mov di, word ptr table
        mov dx, tv
        mov cx, nn
        mov al, 0F7h
        mov ah, 0FBh
        mov bp, tu
        jmp l_next
    l_blank:
        mov bx, 8000h
        jmp l_clear
    l_skip:
        add si, 2
    l_clear:
        mov byte ptr [di], 0
        inc di
        and bx, [si]
        loopne l_skip
        jcxz l_done
    l_next:
        mov bx, [si]
        add si, 2
        add bx, bp
        js l_blank
        and bh, al
        mov bx, [bx]
        add bx, dx
        and bh, ah
    l_patch:
        mov bl, es:[bx+1234h]
        mov [di], bl
        inc di
        loop l_next
    l_done:
        mov ax, ss
        mov ds, ax
        pop bp
        pop di
        pop si
    }
    UnlockMem(wh);
    UnlockMem(bh);
    ReleaseCache(bh);
    return 1;
}

void InitDummyPlanet(void)
{
    int unused[6];

    MemSet(&dummy_planet, 0x1CE, 0);
    MatIdentity(&dummy_planet.orient);
    dummy_planet.pos.x = 0;
    dummy_planet.pos.y = 0;
    dummy_planet.pos.z = 15300;
    CreatePlanet(&dummy_planet, "noname", 500, 0, 714, 10);
}

/* A planet with a fractal texture. */
void CreatePlanet(Obj3D *o, char *name, int radius, int small, unsigned seed, int pal)
{
    InitPlanet(o, name, radius, small, 1, seed, pal);
}

/* A planet textured with name.spl / name.lpl. */
void CreatePlanetBmp(Obj3D *o, char *name, int radius, int small)
{
    InitPlanet(o, name, radius, small, 0, 0, 0);
}

void RandomPlanet(Obj3D *o)
{
    char name[10];
    unsigned seed;
    int pal;

    srand(blink_count);
    seed = rand() % 1000;
    pal = rand() % 16 + 6;
    sprintf(name, "r%dc%d", seed, pal);
    CreatePlanet(o, name, 500, 0, seed, pal);
}

void InitPlanet(Obj3D *o, char *name, int radius, int small, int gen, unsigned seed, int pal)
{
    o->visible = 1;
    o->draw = DrawPlanet;
    o->free = FreePlanet;
    o->radius = radius;
    o->small = small;
    strcpy(o->name, name);
    if (gen) {
        o->generated = 1;
        o->seed = seed;
        o->palette = pal;
    } else
        o->generated = 0;
    o->reach = o->radius * 11;
}

int DrawPlanet(Obj3D *o)
{
    if (small_planets)
        DrawPlanetSmall(o);
    else if (DrawPlanetLarge(o) == 0) {
        small_planets = 1;
        DrawPlanetSmall(o);
    }
}

void FreePlanet(Obj3D *o)
{
    ReleaseCache(o->r3s);
}

/* Make a size x size texture: a diamond-square fractal heightmap coloured
 * with palette pal. */
void MakeFractal(int size, unsigned seed, unsigned pal)
{
    srand(seed);
    if (pal >= 22)
        pal = 21;
    frac_pal = planet_pals[pal];
    frac_size2 = size * size;
    frac_bytes = frac_size2 * 2;
    frac_map = (int far *)backbuf->data;
    fractal_handle = AllocMem(frac_size2 + 8, 1);
    if (fractal_handle == 0)
        return;
    frac_bmp = LockMem(fractal_handle);
    MemSet(frac_map, frac_bytes, 0);
    frac_size = size;
    FracEdge(0, 0, frac_size, 0);
    FracEdge(0, 0, 0, frac_size);
    FracSquare(0, 0, frac_size, frac_size);
    FracColour();
    frac_bmp->x = frac_bmp->y = frac_size / 2;
    frac_bmp->w = frac_bmp->h = frac_size;
    UnlockMem(fractal_handle);
}

void FracSquare(int x0, int y0, int x1, int y1)
{
    register int hx;
    register int hy;

    hx = (x1 - x0) >> 1;
    hy = (y1 - y0) >> 1;
    FracEdge(x0, y0 + hy, x1, y0 + hy);
    if (hx + hy > 2) {
        FracEdge(x0 + hx, y0, x0 + hx, y0 + hy);
        FracEdge(x0 + hx, y0 + hy, x0 + hx, y1);
    }
    if (hx + hy >= 4) {
        FracSquare(x0, y0, x0 + hx, y0 + hy);
        FracSquare(x0 + hx, y0, x1, y0 + hy);
        FracSquare(x0, y0 + hy, x0 + hx, y1);
        FracSquare(x0 + hx, y0 + hy, x1, y1);
    }
}

/* Set the midpoint of (x0, y0)-(x1, y1) to the average of its ends plus a
 * random offset, and recurse on the halves. */
void FracEdge(int x0, int y0, int x1, int y1)
{
    register int hx;
    register int hy;
    int h;
    int wx;
    int wy;

    hx = (x1 - x0) >> 1;
    hy = (y1 - y0) >> 1;
    wx = frac_size - 1 & x1;
    wy = frac_size - 1 & y1;
    h = frac_map[x0 * frac_size + y0] + frac_map[wx * frac_size + wy];
    h = h / 2;
    h += (rand() - 0x4000) % (hx + hy);
    frac_map[(x0 + hx) * frac_size + (y0 + hy)] = h;
    if (hx + hy >= 2) {
        FracEdge(x0, y0, x0 + hx, y0 + hy);
        FracEdge(x0 + hx, y0 + hy, x1, y1);
    }
}

/* Scale the heights to the 25 colours of the palette. */
void FracColour(void)
{
    int n;
    int v;
    int far *p;
    int max;
    int min;
    int range;
    unsigned char far *out;

    max = -32768;
    min = 32767;
    for (p = frac_map, n = frac_size2; n--; p++) {
        if (*p > max)
            max = *p;
        if (*p < min)
            min = *p;
    }
    range = max - min + 1;
    out = frac_bmp->data;
    p = frac_map;
    n = frac_size2;
    while (n--) {
        v = *p++;
        v -= min;
        v = frac_pal[v * 25 / range];
        *out++ = v;
    }
}
