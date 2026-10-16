/* menu.h - menus of bitmap buttons loaded from .mnu files */

#ifndef MENU_H
#define MENU_H

#include "mem.h"
#include "sprite.h"

/* An entry of a .mnu file. */
typedef struct MenuEntry {
    char name[10];          /* 00 button bitmap */
    int x;                  /* 0A */
    int y;                  /* 0C */
    int id;                 /* 0E returned when chosen */
} MenuEntry;

/* The state of a menu replaced by one opened over it. */
typedef struct MenuSave {
    Sprite *sprites;        /* 00 */
    int *ids;               /* 02 */
    long disabled;          /* 04 */
    MemHandle handle;       /* 08 */
    int count;              /* 0A */
    int sel;                /* 0C */
    struct MenuSave *next;  /* 0E */
} MenuSave;

/* Menu directions for MenuMove */
#define MENU_NEXT   0       /* right arrow: the next button in reading order */
#define MENU_PREV   1
#define MENU_UP     2
#define MENU_DOWN   3
#define MENU_FIRST  4
#define MENU_LAST   5

/* MenuLoop results besides the button ids */
#define MENU_NONE   (-1)    /* clicked outside the buttons */
#define MENU_ESCAPE (-2)
#define MENU_TIMEOUT (-3)
#define MENU_CANCEL (-4)

extern Sprite *menu_sprites;
extern int *menu_ids;
extern long menu_disabled;
extern int menu_sel;
extern int menu_count;

int MenuHit(Sprite *s, int n, int x, int y);
void MenuMove(Sprite *s, int n, int cur, int dir);
void DrawButtonFrame(MemHandle h, int c);
void OptionsMenu(int x, int y);
int ActionPanel(void);
void LoadMenu(char *name, int x, int y);
void MenuShow(long mask);
void MenuDisable(long mask);
void MenuEnable(long mask);
void MenuHome(void);
int MenuLoop(unsigned long timeout, int keys);
int MenuWait(unsigned long timeout);
void MenuClose(void);

#endif
