/* seg002: the computer: topic lookup
 *
 * The sequel moved the text input box out of this file (InputBox, in
 * seg008's neighbourhood, now takes the buffer), and plays the topics'
 * voice tags from computer.vcc. */

#include <stdlib.h>
#include <string.h>
#include "mem.h"
#include "cache.h"

void MsgBox(char *title, char *msg, int a, int b, int c, unsigned d);   /* seg008: message box */
void TextBox(char *(far *get)(int, void *, char *), void *data, int a, int b, int c, int d,
             int e, int f);                                         /* seg008: list box */
int InputBox(char *prompt, char *buf, int x, int y, int color);    /* seg008 */
char *PlayVoiceTag(char *p);                                        /* seg008 */
void OpenVCC(char *name);                                           /* seg015: voice archive */
void CloseVCC(char *name);

/* Topics found for a search: 8 character file names. */
typedef struct DBList {
    int count;
    char names[32][8];
} DBList;

static char input_buf[26];

/* List box callback: put the title of topic idx in out ("R: title") and
 * return its text, from <name>.db, after playing its voice tag. */
char *GetDBEntry(int idx, DBList *db, char *out)
{
    MemHandle h;
    char far *p;
    char *text;
    char far *q;
    char name[10];
    char head[12];
    int n;

    if (idx >= db->count)
        return 0;
    MemCpy(name, db->names[idx], 8);
    name[8] = 0;
    h = CacheLoadEMS(name, "db");
    p = LockMem(h);
    MemCpy(head, p, 12);
    UnlockMem(h);
    text = PlayVoiceTag(head);
    p = LockMem(h);
    p += text - head;
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
        else if (*q == '\t')
            *q = ' ';
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

    OpenVCC("computer.vcc");
    for (;;) {
        list.count = 0;
        strcpy(input_buf, "");
        if (InputBox("Computer (Select Topic):", input_buf, 160, 100, 9) == 0 || input_buf[0] == 0) {
            CloseVCC("computer.vcc");
            return;
        }
        strupr(input_buf);
        if (strlen(input_buf) > 2) {
            h = CacheLoadEMS("db", "key");
            p = LockMem(h);
            {
                int i;

                for (i = 23; i != 0; i--)
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
                    if (_fstrstr(s, input_buf) && list.count < 32)
                        MemCpy(list.names[list.count++], name, 8);
                }
                p += _fstrlen(p);
                *p++ = '\n';
            }
            UnlockMem(h);
            CacheRelease(h);
        }
        if (list.count)
            TextBox(GetDBEntry, &list, 20, 20, 9, 0, 0, 0);
        else
            MsgBox("Computer", "No references for specified topic.", 20, 20, 9, 0);
    }
}

char *InputDescription(void)
{
    memset(input_buf, 0, 25);
    if (InputBox("Description:", input_buf, 160, 100, 9) == 0)
        input_buf[0] = 0;
    return input_buf;
}

char *InputCode(void)
{
    memset(input_buf, 0, 25);
    if (InputBox("Enter Code:", input_buf, 160, 100, 9) == 0)
        input_buf[0] = 0;
    return input_buf;
}
