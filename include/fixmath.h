/* fixmath.h - fixed point trigonometry, vectors and matrices
 *
 * Fixed point values use 14 fraction bits (0x4000 = 1.0). Angles are
 * 0x400 units per full turn.
 */

#ifndef FIXMATH_H
#define FIXMATH_H

#define FIX_ONE 0x4000

typedef struct Vec {
    int e[3];
} Vec;

typedef struct Matrix {
    int e[3][3];
} Matrix;

extern int far sin_table[0x101];    /* sin over a quarter turn */
extern int far cos_table[0x101];
extern int far tan_table[0x81];     /* tan over an eighth of a turn */
extern int sin_small[33];
extern int cos_small[33];
extern long ang_small[33];

/* seg027 (assembly) */
void MatMul(Matrix *a, Matrix *b, Matrix *out);
int FixDiv(long a, long b);                 /* (a << 14) / b */
int FixMul(int a, int b);                   /* (a * b) >> 14 */
long FixMul2(long a, int b, long c, int d); /* (a * b + c * d) >> 14 */
int FixSqrt(long x);
int FixLength(int x, int y, int z);

void InitTrig(void);
int FixSin(int a);
int FixCos(int a);
int FixTan(int a);
int FixACos(int v);
int FixAtan2(long a, long b);
int FixASin(int v);
void MatIdentity(Matrix *m);
Matrix *MatRotX(int a, Matrix *out);
Matrix *MatRotY(int a, Matrix *out);
Matrix *MatRotZ(int a, Matrix *out);
Matrix *MatRotXPre(int a, Matrix *out);
Matrix *MatRotYPre(int a, Matrix *out);
Matrix *MatRotZPre(int a, Matrix *out);
void MatTranspose(Matrix *src, Matrix *dst);
int VecCross(int *a, int *b, int *out);
int VecLen32(long *v);
int VecNorm32(long *v, int *out);
int VecLen(int *v);
int VecNorm(int *v, int *out);
int MatFromVecs(long *dir, int *up, int *alt, Matrix *m);
void MatFromDir(int *v, Matrix *m);
Matrix *MatRotXSC(int s, int c, Matrix *out);
Matrix *MatRotYSC(int s, int c, Matrix *out);
Matrix *MatRotZSC(int s, int c, Matrix *out);
void MatOrtho(Matrix *m);
void VecSub(int *a, int *b);

#endif
