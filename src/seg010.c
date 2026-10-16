/* seg010: fixed point trigonometry, vectors and 3x3 matrices */

#include <math.h>
#include "mem.h"
#include "fixmath.h"

#define PI 3.141592654

void MatIdentity(Matrix *m)
{
    int i;
    int j;

    MemSet(m, sizeof(Matrix), 0);
    for (i = 0; i != 3; i++)
        m->e[i][i] = FIX_ONE;
}

/* Near matches. In the sequel the first two element stores swapped places
 * (X and Z; that alone makes the *SC versions match). Still different: the
 * original has s and c in each other's stack slots (not declaration order
 * or names), and the Y rotations load c before s. */
Matrix *MatRotX(int a, Matrix *out)
{
    long s;
    long c;
    Matrix m;
    Matrix r;

    s = FixSin(a);
    c = FixCos(a);
    MatIdentity(&m);
    m.e[1][2] = s;
    m.e[1][1] = c;
    m.e[2][1] = -s;
    m.e[2][2] = c;
    MatMul(out, &m, &r);
    *out = r;
}

Matrix *MatRotY(int a, Matrix *out)
{
    long s;
    long c;
    Matrix m;
    Matrix r;

    s = FixSin(a);
    c = FixCos(a);
    MatIdentity(&m);
    m.e[0][0] = c;
    m.e[0][2] = -s;
    m.e[2][0] = s;
    m.e[2][2] = c;
    MatMul(out, &m, &r);
    *out = r;
}

Matrix *MatRotZ(int a, Matrix *out)
{
    long s;
    long c;
    Matrix m;
    Matrix r;

    s = FixSin(a);
    c = FixCos(a);
    MatIdentity(&m);
    m.e[0][1] = s;
    m.e[0][0] = c;
    m.e[1][0] = -s;
    m.e[1][1] = c;
    MatMul(out, &m, &r);
    *out = r;
}

Matrix *MatRotXPre(int a, Matrix *out)
{
    long s;
    long c;
    Matrix m;
    Matrix r;

    s = FixSin(a);
    c = FixCos(a);
    MatIdentity(&m);
    m.e[1][2] = s;
    m.e[1][1] = c;
    m.e[2][1] = -s;
    m.e[2][2] = c;
    MatMul(&m, out, &r);
    *out = r;
}

Matrix *MatRotYPre(int a, Matrix *out)
{
    long s;
    long c;
    Matrix m;
    Matrix r;

    s = FixSin(a);
    c = FixCos(a);
    MatIdentity(&m);
    m.e[0][0] = c;
    m.e[0][2] = -s;
    m.e[2][0] = s;
    m.e[2][2] = c;
    MatMul(&m, out, &r);
    *out = r;
}

Matrix *MatRotZPre(int a, Matrix *out)
{
    long s;
    long c;
    Matrix m;
    Matrix r;

    s = FixSin(a);
    c = FixCos(a);
    MatIdentity(&m);
    m.e[0][1] = s;
    m.e[0][0] = c;
    m.e[1][0] = -s;
    m.e[1][1] = c;
    MatMul(&m, out, &r);
    *out = r;
}

void MatTranspose(Matrix *src, Matrix *dst)
{
    int i;
    int j;
    int t;

    for (i = 0; i != 3; i++)
        for (j = 0; j != 3; j++) {
            t = src->e[j][i];
            dst->e[i][j] = t;
        }
}

/* out = a x b; returns 1 if the result is zero. */
int VecCross(register int *a, register int *b, int *out)
{
    out[0] = FixMul2(a[1], b[2], a[2], -b[1]);
    out[1] = FixMul2(a[2], b[0], a[0], -b[2]);
    out[2] = FixMul2(a[0], b[1], a[1], -b[0]);
    return out[0] == 0 && out[1] == 0 && out[2] == 0;
}

int VecLen32(register long *v)
{
    return FixLength(v[0], v[1], v[2]);
}

int VecNorm32(register long *v, register int *out)
{
    unsigned len;

    len = VecLen32(v);
    if (len != 0) {
        out[0] = FixDiv(v[0], len);
        out[1] = FixDiv(v[1], len);
        out[2] = FixDiv(v[2], len);
        return 0;
    } else {
        out[0] = 0;
        out[1] = 0;
        out[2] = 0;
        return 1;
    }
}

int VecLen(register int *v)
{
    return FixLength(v[0], v[1], v[2]);
}

int VecNorm(register int *v, register int *out)
{
    unsigned len;

    len = VecLen(v);
    if (len != 0) {
        out[0] = FixDiv(v[0], len);
        out[1] = FixDiv(v[1], len);
        out[2] = FixDiv(v[2], len);
        return 0;
    } else {
        out[0] = 0;
        out[1] = 0;
        out[2] = 0;
        return 1;
    }
}

/* Build an orthonormal basis looking along dir, with up (or alt if up is
 * parallel to dir). */
int MatFromVecs(long *dir, int *up, int *alt, Matrix *m)
{
    if (VecNorm32(dir, m->e[2]))
        return 0;
    if (VecCross(up, m->e[2], m->e[0])) {
        if (alt) {
            if (VecCross(alt, m->e[2], m->e[0]))
                return 0;
            else
                return 0;
        }
    }
    VecNorm(m->e[0], m->e[0]);
    VecCross(m->e[2], m->e[0], m->e[1]);
    return 1;
}

void MatFromDir(int *v, Matrix *m)
{
    int len;
    int x;
    int y;
    int z;
    int w;
    int xx;
    int xy;
    int yy;

    if (v[0] == 0 && v[1] == 0) {
        MatIdentity(m);
        return;
    }
    len = FixLength(v[0], v[1], 0);
    x = FixDiv(v[1], len);
    y = FixDiv(-v[0], len);
    z = v[2];
    w = FixSqrt(0x10000000L - (long)z * z);
    xx = FixMul(x, x);
    xy = FixMul(x, y);
    yy = FixMul(y, y);
    m->e[0][0] = FixMul(z, yy) + xx;
    m->e[0][1] = xy - FixMul(z, xy);
    m->e[0][2] = -FixMul(w, y);
    m->e[1][0] = m->e[0][1];
    m->e[1][1] = FixMul(z, xx) + yy;
    m->e[1][2] = FixMul(w, x);
    m->e[2][0] = -m->e[0][2];
    m->e[2][1] = -m->e[1][2];
    m->e[2][2] = z;
    return;
}

Matrix *MatRotXSC(int s, int c, Matrix *out)
{
    Matrix m;
    Matrix r;

    MatIdentity(&m);
    m.e[1][2] = s;
    m.e[1][1] = c;
    m.e[2][1] = -s;
    m.e[2][2] = c;
    MatMul(&m, out, &r);
    *out = r;
}

Matrix *MatRotYSC(int s, int c, Matrix *out)
{
    Matrix m;
    Matrix r;

    MatIdentity(&m);
    m.e[0][0] = c;
    m.e[0][2] = -s;
    m.e[2][0] = s;
    m.e[2][2] = c;
    MatMul(&m, out, &r);
    *out = r;
}

Matrix *MatRotZSC(int s, int c, Matrix *out)
{
    Matrix m;
    Matrix r;

    MatIdentity(&m);
    m.e[0][1] = s;
    m.e[0][0] = c;
    m.e[1][0] = -s;
    m.e[1][1] = c;
    MatMul(&m, out, &r);
    *out = r;
}

/* Re-orthonormalise a rotation matrix. */
void MatOrtho(Matrix *m)
{
    Vec v;

    VecCross(m->e[1], m->e[2], m->e[0]);
    VecCross(m->e[2], m->e[0], m->e[1]);
    VecNorm(m->e[0], v.e);
    *(Vec *)m->e[0] = v;
    VecNorm(m->e[1], v.e);
    *(Vec *)m->e[1] = v;
    VecNorm(m->e[2], v.e);
    *(Vec *)m->e[2] = v;
}

void VecSub(int *a, int *b)
{
    a[0] -= b[0];
    a[1] -= b[1];
    a[2] -= b[2];
}
