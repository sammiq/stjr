/* seg002: the computer: text input box and topic lookup */

#include <stdlib.h>
#include <string.h>
#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "sprite.h"
#include "gfx.h"
#include "event.h"

int isprint(int c);
void MsgBox(char *title, char *msg, int a, int b, int c, int d);   /* seg008: message box */
void TextBox(char *(far *get)(int, void *, char *), void *data, int a, int b, int c, int d,
               int e, int f);                                        /* seg008: list box */
void TrackMouse(Event *e);                                            /* seg012 */

/* Topics found for a search: 8 character file names. */
typedef struct DBList {
    int count;
    char names[16][8];
} DBList;

extern int key_accel;
unsigned char cursor_on;
MemHandle input_bg;          /* the empty box */
MemHandle input_bmp;         /* the box with the text */
int input_size;
Sprite input_sprite;
extern long blink_count;
char *dialog_title;

char input_buf[134] = "some input";
int cursor = 0;

char *GetDBEntry(int idx, DBList *db, char *out);
void DrawInput(void);
void InsertChar(int pos, int unused, char c);
void DeleteChar(int pos, int unused);
void DelAtCursor(void);
void TypeChar(char c);
int InputBox(int x, int y, char *prompt);
void OpenInputBox(int x, int y, char *prompt);
void CloseInputBox(void);

/* List box callback: put the title of topic idx in out ("R: title") and
 * return its text, from <name>.db. */
char *GetDBEntry(int idx, DBList *db, char *out)
{
    MemHandle h;
    char far *p;
    char *text;
    char far *q;
    char name[10];
    int n;

    if (idx >= db->count)
        return 0;
    MemCpy(name, db->names[idx], 8);
    name[8] = 0;
    h = CacheLoad(name, "db");
    p = LockMem(h);
    MemCpy(out, "R: ", 3);
    MemSet(out + 3, 21, ' ');
    for (n = 3; *p != '\n'; p++)
        if (n < 24 && *p != '\r')
            out[n++] = *p;
    p++;
    n = 0;
    for (q = p; *q != '$'; ++n, ++q)
        ;
    text = AllocMemPtr(n + 1);
    MemCpy(text, p, n);
    text[n] = 0;
    for (q = text; *q; q++)
        if (*q == '\r' && q[1] == '\n' && q[2] != '\r')
            q[1] = '\r';
    UnlockMem(h);
    CacheRelease(h);
    return text;
}

/* Ask for a word and list the topics whose keywords contain it. */
void Computer(void)
{
    DBList list;
    MemHandle h;
    char far *p;

    for (;;) {
        list.count = 0;
        memset(input_buf, 0, 133);
        if (InputBox(160, 100, "Computer:\n                    ") == 0 || input_buf[0] == 0)
            return;
        strupr(input_buf);
        if (strlen(input_buf) > 2) {
            h = CacheLoad("db", "key");
            p = LockMem(h);
            {
                int i;

                for (i = 131; i != 0; i--)
                    input_buf[i] = input_buf[i - 1];
            }
            input_buf[0] = ' ';
            while (*p != '$') {
                char name[9];
                char far *s;

                s = _fstrchr(p, '\n');
                if (s == 0)
                    break;
                *s = 0;
                _fstrncpy(name, p, 8);
                name[8] = 0;
                s = strchr(name, ' ');
                if (s)
                    *s = 0;
                s = _fstrchr(p, ' ');
                if (s) {
                    _fstrupr(s);
                    if (_fstrstr(s, input_buf) && list.count < 16)
                        MemCpy(list.names[list.count++], name, 8);
                }
                p += _fstrlen(p);
                *p++ = '\n';
            }
            UnlockMem(h);
            CacheRelease(h);
        }
        if (list.count)
            TextBox(GetDBEntry, &list, 20, 20, 176, 0, 0, 0);
        else
            MsgBox("Spock", "#COMP\\COMPUNOT#Topic not available, Captain.", 294, 106, 44, 0);
    }
}

char *InputDescription(void)
{
    memset(input_buf, 0, 133);
    if (InputBox(160, 100, "Description:\n                    ") == 0)
        input_buf[0] = 0;
    return input_buf;
}

char *InputCode(void)
{
    memset(input_buf, 0, 133);
    if (InputBox(160, 100, "Code:\n                    ") == 0)
        input_buf[0] = 0;
    return input_buf;
}

void DrawInput(void)
{
    int unused;
    char text[40];
    Bitmap far *bg;
    Bitmap far *bmp;

    memset(text, 0, 40);
    strcpy(text, input_buf);
    if (cursor_on)
        text[cursor] = cursor_on;
    bg = LockMem(input_bg);
    bmp = LockMem(input_bmp);
    _fmemcpy(bmp, bg, input_size);
    DrawText(text, 20, 4, 12, bmp);
    UnlockMem(input_bg);
    UnlockMem(input_bmp);
    input_sprite.dirty = 1;
    UpdateSprites();
}

void InsertChar(int pos, int unused, char c)
{
    int i;

    for (i = 18; i >= pos; i--)
        input_buf[i + 1] = input_buf[i];
    input_buf[pos] = c;
}

void DeleteChar(int pos, int unused)
{
    for (pos = pos; pos < 20; pos++)
        input_buf[pos] = input_buf[pos + 1];
}

void DelAtCursor(void)
{
    DeleteChar(cursor, 0);
}

void TypeChar(char c)
{
    int unused1;
    int unused2;
    int unused3;
    int unused4;
    int len;
    int n;

    len = strlen(input_buf);
    if (len < cursor) {
        for (n = cursor - len; n != 0; n--)
            InsertChar(len, 0, ' ');
    }
    InsertChar(cursor, 0, c);
}

/* Edit input_buf in a box at (x, y) under prompt. Returns 1 when entered
 * (Enter, F1 or click), 0 when cancelled (Esc, F2 or right click). */
int InputBox(int x, int y, char *prompt)
{
    int unused1;
    int unused2;
    int unused3;
    int unused4;
    int unused5;
    int unused6;
    int running;
    Event e;
    int unused7;
    int unused8;
    int key;
    int ok;

    unused7 = -1;
    ok = 0;
    key_accel = 0;
    LoadFont();
    cursor = 0;
    OpenInputBox(x, y, prompt);
    running = 1;
    while (running) {
        if (GetEvent(&e)) {
            TrackMouse(&e);
            switch (e.type) {
            case EV_TICK:
                FadeUp();
                blink_count++;
                if (blink_count & 2)
                    cursor_on = 1;
                else
                    cursor_on = 0;
                DrawInput();
                break;
            case EV_KEY:
                key = e.key & 0xFF;
                if (key == 0)
                    key = e.key;
                switch (key) {
                case 0x1B:
                case 0x3C00:
                    running = 0;
                    break;
                case 0x0D:
                case 0x3B00:
                    DrawInput();
                    running = 0;
                    ok = 1;
                    break;
                case 0x4700:
                    cursor = 0;
                    break;
                case 0x4F00:
                    cursor = strlen(input_buf);
                    break;
                case 0x4D00:
                    if (cursor < 19)
                        cursor++;
                    DrawInput();
                    break;
                case 0x4B00:
                    if (cursor > 0)
                        cursor--;
                    DrawInput();
                    break;
                case 0x08:
                case 0x0E00:
                    if (cursor > 0) {
                        cursor--;
                        DelAtCursor();
                    }
                    DrawInput();
                    break;
                default:
                    if (isprint(key)) {
                        TypeChar((char)key);
                        if (cursor < 19)
                            cursor++;
                        DrawInput();
                        break;
                    }
                }
                break;
            case EV_DOWN1:
                DrawInput();
                ok = 1;
                running = 0;
                break;
            case EV_DOWN2:
                running = 0;
                break;
            }
        }
    }
    CloseInputBox();
    FreeFont();
    key_accel = 1;
    return ok;
}

/* Build the box bitmap: the prompt word wrapped under the dialog title,
 * with a dotted border. */
void OpenInputBox(int x, int y, char *prompt)
{
    int i;
    long pad;
    int unused1;
    int unused2;
    int unused3;
    char lines[11][26];
    char *text;
    int w;
    int h;
    int cols;
    int nlines;
    long unused4;
    Bitmap far *bmp;
    Bitmap far *bmp2;

    cols = strlen(prompt);
    if (cols > 25)
        cols = 25;
    text = prompt;
    nlines = 0;
    if (dialog_title) {
        lines[nlines][0] = 0;
        pad = (cols - strlen(dialog_title)) / 2;
        for (i = 0; i < pad; i++)
            strcat(lines[nlines], " ");
        strcat(lines[nlines++], dialog_title);
    }
    do
        text = WrapLine(text, lines[nlines++], cols);
    while (text && nlines < 11);
    w = cols * 8 + 8;
    h = nlines * 8 + 8;
    input_size = w * h + 8;
    input_bg = AllocMemAbort(w * h + 8, 0);
    input_bmp = AllocMemAbort(w * h + 8, 0);
    bmp = LockMem(input_bg);
    bmp->x = 0;
    bmp->y = 0;
    bmp->w = w;
    bmp->h = h;
    bmp->x = w / 2;
    if (w / 2 + x > 319)
        bmp->x += w / 2 + x - 319;
    if (x - w / 2 < 0)
        bmp->x -= 0 - (x - w / 2);
    bmp->y = h + 20;
    MemSet(bmp->data, w * h, 0);
    {
        int px;
        int py;

        for (px = 1, py = 1; px < w - 1; px++)
            bmp->data[py * w + px] = 'x';
        for (px = 1, py = h - 2; px < w - 1; px++)
            bmp->data[py * w + px] = 'x';
        for (px = 1, py = 1; py < h - 1; py++)
            bmp->data[py * w + px] = 'x';
        for (px = w - 2, py = 1; py < h - 1; py++)
            bmp->data[py * w + px] = 'x';
    }
    for (i = 0; i < nlines; i++)
        DrawString(lines[i], 4, i * 8 + 4, bmp);
    bmp2 = LockMem(input_bmp);
    _fmemcpy(bmp2, bmp, w * h + 8);
    UnlockMem(input_bg);
    UnlockMem(input_bmp);
    AddSprite(&input_sprite);
    input_sprite.type = SPRITE_SHADOW;
    input_sprite.name = "System";
    input_sprite.handle = input_bmp;
    SpriteSetPos(&input_sprite, x, y, 15);
    input_sprite.layer = 8;
    UpdateSprites();
}

void CloseInputBox(void)
{
    SpriteErase(&input_sprite);
    UpdateSprites();
    DelSprite(&input_sprite);
    FreeMem(input_bg);
    FreeMem(input_bmp);
}
