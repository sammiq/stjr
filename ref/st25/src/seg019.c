/* seg019: saving and loading games, and the game menus that go with them */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <io.h>
#include "mem.h"
#include "gfx.h"

#define SAVE_VERSION 17
#define MAX_SAVES    16

/* savegame.dir: the saved games, newest first. */
typedef struct SaveDir {
    int count;
    long used;                      /* savegame.N files in use */
    unsigned char slot[MAX_SAVES];  /* N for each game */
} SaveDir;

void MsgBox(char *title, char *msg, int a, int b, int c, int d);    /* seg008: message box */
int TextBox(char *(far *get)(int, void *, char *), void *data, int a, int b, int c, int d,
              int e, int f);                                        /* seg008: list box */
void CentreLine(char *out, char *title);                             /* seg008 */
void SaveGameState(void);               /* seg008: write the game state */
void LoadGameState(void);               /* seg008: read the game state */
void Fatal(char *fmt, ...);     /* fatal error */
char *InputDescription(void);       /* seg002 */

SaveDir save_dir;
char save_path[80];
char save_desc[25];
FILE *save_fp;
int save_version;
extern int voc_wait;

/* The bitmap in a ship's .r3s for each yaw and pitch step (seg006
 * SelectView); 0x8000 means draw it mirrored. */
int view_tab[24][13] = {
    { 0x0000, 0x0001, 0x0002, 0x0003, 0x0004, 0x0005, 0x0006, 0x0007, 0x0008, 0x0009, 0x000A, 0x000B, 0x000C },
    { 0x0000, 0x0011, 0x0012, 0x0013, 0x0014, 0x0015, 0x0016, 0x0017, 0x0018, 0x0019, 0x001A, 0x001B, 0x000C },
    { 0x0000, 0x0021, 0x0022, 0x0023, 0x0024, 0x0025, 0x0026, 0x0027, 0x0028, 0x0029, 0x002A, 0x002B, 0x000C },
    { 0x0000, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037, 0x0038, 0x0039, 0x003A, 0x003B, 0x000C },
    { 0x0000, 0x0041, 0x0042, 0x0043, 0x0044, 0x0045, 0x0046, 0x0047, 0x0048, 0x0049, 0x004A, 0x004B, 0x000C },
    { 0x0000, 0x0051, 0x0052, 0x0053, 0x0054, 0x0055, 0x0056, 0x0057, 0x0058, 0x0059, 0x005A, 0x005B, 0x000C },
    { 0x0000, 0x0061, 0x0062, 0x0063, 0x0064, 0x0065, 0x0066, 0x0067, 0x0068, 0x0069, 0x006A, 0x006B, 0x000C },
    { 0x0000, 0x0071, 0x0072, 0x0073, 0x0074, 0x0075, 0x0076, 0x0077, 0x0078, 0x0079, 0x007A, 0x007B, 0x000C },
    { 0x0000, 0x0081, 0x0082, 0x0083, 0x0084, 0x0085, 0x0086, 0x0087, 0x0088, 0x0089, 0x008A, 0x008B, 0x000C },
    { 0x0000, 0x0091, 0x0092, 0x0093, 0x0094, 0x0095, 0x0096, 0x0097, 0x0098, 0x0099, 0x009A, 0x009B, 0x000C },
    { 0x0000, 0x00A1, 0x00A2, 0x00A3, 0x00A4, 0x00A5, 0x00A6, 0x00A7, 0x00A8, 0x00A9, 0x00AA, 0x00AB, 0x000C },
    { 0x0000, 0x00B1, 0x00B2, 0x00B3, 0x00B4, 0x00B5, 0x00B6, 0x00B7, 0x00B8, 0x00B9, 0x00BA, 0x00BB, 0x000C },
    { 0x0000, 0x00C1, 0x00C2, 0x00C3, 0x00C4, 0x00C5, 0x00C6, 0x00C7, 0x00C8, 0x00C9, 0x00CA, 0x00CB, 0x000C },
    { 0x0000, 0x80B1, 0x80B2, 0x80B3, 0x80B4, 0x80B5, 0x80B6, 0x80B7, 0x80B8, 0x80B9, 0x80BA, 0x80BB, 0x000C },
    { 0x0000, 0x80A1, 0x80A2, 0x80A3, 0x80A4, 0x80A5, 0x80A6, 0x80A7, 0x80A8, 0x80A9, 0x80AA, 0x80AB, 0x000C },
    { 0x0000, 0x8091, 0x8092, 0x8093, 0x8094, 0x8095, 0x8096, 0x8097, 0x8098, 0x8099, 0x809A, 0x809B, 0x000C },
    { 0x0000, 0x8081, 0x8082, 0x8083, 0x8084, 0x8085, 0x8086, 0x8087, 0x8088, 0x8089, 0x808A, 0x808B, 0x000C },
    { 0x0000, 0x8071, 0x8072, 0x8073, 0x8074, 0x8075, 0x8076, 0x8077, 0x8078, 0x8079, 0x807A, 0x807B, 0x000C },
    { 0x0000, 0x8061, 0x8062, 0x8063, 0x8064, 0x8065, 0x8066, 0x8067, 0x8068, 0x8069, 0x806A, 0x806B, 0x000C },
    { 0x0000, 0x8051, 0x8052, 0x8053, 0x8054, 0x8055, 0x8056, 0x8057, 0x8058, 0x8059, 0x805A, 0x805B, 0x000C },
    { 0x0000, 0x8041, 0x8042, 0x8043, 0x8044, 0x8045, 0x8046, 0x8047, 0x8048, 0x8049, 0x804A, 0x804B, 0x000C },
    { 0x0000, 0x8031, 0x8032, 0x8033, 0x8034, 0x8035, 0x8036, 0x8037, 0x8038, 0x8039, 0x803A, 0x803B, 0x000C },
    { 0x0000, 0x8021, 0x8022, 0x8023, 0x8024, 0x8025, 0x8026, 0x8027, 0x8028, 0x8029, 0x802A, 0x802B, 0x000C },
    { 0x0000, 0x8011, 0x8012, 0x8013, 0x8014, 0x8015, 0x8016, 0x8017, 0x8018, 0x8019, 0x801A, 0x801B, 0x000C },
};

int save_dir_loaded = 0;

void LoadSaveDir(void);
void SaveSaveDir(void);
void SavePath(int n);
void SaveWrite(void *p, unsigned n);
void SaveRead(void *p, unsigned n);
void SaveGame(void);
void LoadGame(void);
void SaveClose(void);
int SaveVersion(void);
void SaveNew(void);
void RestoreNew(void);
char *SlotName(int n, char *title, char *out);
char *MenuText(int n, char **list, char *out);
void SaveMenu(void);
void LoadGameMenu(void);
void QuitMenu(int x, int y);
void GameOverMenu(void);
void TextModeMenu(int ask);
int ReadTextMode(void);
int WriteTextMode(int mode);

void LoadSaveDir(void)
{
    FILE *f;

    if (save_dir_loaded)
        return;
    save_dir_loaded = 1;
    if (access("savegame.dir", 0) == -1) {
        save_dir.count = 0;
        save_dir.used = 0;
    } else {
        f = fopen("savegame.dir", "rb");
        fread(&save_dir, 1, sizeof(save_dir), f);
        fclose(f);
    }
}

void SaveSaveDir(void)
{
    FILE *f;

    f = fopen("savegame.dir", "wb");
    fwrite(&save_dir, 1, sizeof(save_dir), f);
    fclose(f);
}

void SavePath(int n)
{
    sprintf(save_path, "savegame.%d", save_dir.slot[n]);
}

void SaveWrite(void *p, unsigned n)
{
    fwrite(p, 1, n, save_fp);
}

void SaveRead(void *p, unsigned n)
{
    fread(p, 1, n, save_fp);
}

void SaveGame(void)
{
    save_fp = fopen(save_path, "wb");
    SaveWrite(save_desc, 25);
    save_version = SAVE_VERSION;
    SaveWrite(&save_version, 2);
    SaveGameState();
    fclose(save_fp);
}

void LoadGame(void)
{
    save_fp = fopen(save_path, "rb");
    SaveRead(save_desc, 25);
    SaveRead(&save_version, 2);
    if (save_version != SAVE_VERSION)
        MsgBox("Load Game", "#GENE\\GENER025#Unable to load game.  Game was saved by an older version of this program.", 20, 20, 0xB0, 0);
    else
        LoadGameState();
    fclose(save_fp);
}

void SaveClose(void)
{
    fclose(save_fp);
}

int SaveVersion(void)
{
    save_fp = fopen(save_path, "rb");
    SaveRead(save_desc, 25);
    SaveRead(&save_version, 2);
    fclose(save_fp);
    return save_version;
}

/* Save the game to savegame.new for restarting, unless it is there. */
void SaveNew(void)
{
    strcpy(save_path, "savegame.new");
    if (access(save_path, 0) == -1 || SaveVersion() != SAVE_VERSION)
        SaveGame();
}

void RestoreNew(void)
{
    strcpy(save_path, "savegame.new");
    LoadGame();
}

/* List box entry n of the saved games: its description, then Cancel. */
char *SlotName(int n, char *title, char *out)
{
    char *s;
    char *cancel;
    char *label;

    cancel = save_dir.count ? "Cancel." : "#GENE\\GENERJ01#No games saved.";
    label = "Description:\n";
    if (n > save_dir.count)
        return 0;
    CentreLine(out, title);
    if (n == save_dir.count) {
        s = AllocMemPtr(strlen(cancel) + 1);
        strcpy(s, cancel);
    } else {
        SavePath(n);
        save_fp = fopen(save_path, "rb");
        SaveRead(save_desc, 25);
        fclose(save_fp);
        s = AllocMemPtr(strlen(label) + strlen(save_desc) + 1);
        strcpy(s, label);
        strcat(s, save_desc);
    }
    return s;
}

/* List box entry n of a menu: list[0] is the title, then the entries,
 * ending with an empty one. */
char *MenuText(int n, char **list, char *out)
{
    char *s;
    char *e;

    e = list[n + 1];
    if (e == 0 || *e == 0)
        return 0;
    CentreLine(out, list[0]);
    s = AllocMemPtr(strlen(e) + 1);
    strcpy(s, e);
    return s;
}

char *save_menu[] = {
    "Save Game",
    "#GENE\\GENER023#Save new game.",
    "#GENE\\GENER019#Replace previous game.",
    "#GENE\\GENER002#Delete previous game.",
    "#GENE\\GENER000#Cancel.",
    ""
};

void SaveMenu(void)
{
    int choice;
    int i;

    LoadSaveDir();
    for (;;) {
        choice = TextBox(MenuText, save_menu, 20, 20, 0xB0, 1, 0, 1);
        switch (choice) {
        case 0:
            if (save_dir.count == MAX_SAVES) {
                MsgBox("", "#GENE\\GENER024#Too many games saved.  Replace or delete a previous game.", 20, 20, 0xB0, 0);
                continue;
            } else {
                unsigned long bit;
                char *p;

                p = InputDescription();
                while (*p && *p == ' ')
                    ++p;
                if (*p == 0)
                    return;
                strcpy(save_desc, p);
                for (i = save_dir.count; i != 0; --i)
                    save_dir.slot[i] = save_dir.slot[i - 1];
                save_dir.count++;
                for (i = 0, bit = 1; i < MAX_SAVES; ++i, bit <<= 1)
                    if ((save_dir.used & bit) == 0)
                        break;
                save_dir.slot[0] = i;
                save_dir.used |= bit;
                SavePath(0);
                SaveGame();
                SaveSaveDir();
                return;
            }
        case 1:
            i = TextBox(SlotName, "Save Game", 20, 20, 0xB0, 1, 0, 1);
            if (i != -1 && i != save_dir.count) {
                SavePath(i);
                SaveGame();
            }
            return;
        case 2:
            i = TextBox(SlotName, "Delete Game", 20, 20, 0xB0, 1, 0, 1);
            if (i != -1 && i != save_dir.count) {
                int j;

                SavePath(i);
                unlink(save_path);
                save_dir.used &= ~(1L << save_dir.slot[i]);
                for (j = i + 1; j < save_dir.count; ++j)
                    save_dir.slot[j - 1] = save_dir.slot[j];
                save_dir.count--;
                SaveSaveDir();
            }
            continue;
        case -1:
        case 3:
            return;
        }
    }
}

void LoadGameMenu(void)
{
    int i;

    LoadSaveDir();
    i = TextBox(SlotName, "Load Game", 20, 20, 0xB0, 1, 0, 1);
    if (i != -1 && i != save_dir.count) {
        SavePath(i);
        LoadGame();
    }
}

int menu_busy = 0;

char *quit_menu[] = {
    "Quit Game",
    "#GENE\\GENER028#Yes, quit the game.",
    "#GENE\\GENER008#No, do not quit the game.",
    ""
};

void QuitMenu(int x, int y)
{
    int r;

    if (menu_busy)
        return;
    menu_busy = 1;
    r = TextBox(MenuText, quit_menu, x, y, 0xB0, 1, 0, 1);
    menu_busy = 0;
    switch (r) {
    case 0:
        FadeOut();
        exit(0);
    case -1:
    case 1:
        break;
    }
}

char *gameover_menu[] = {
    "Game Over",
    "#GENE\\GENER006#Load a previously saved game.",
    "#GENE\\GENER020#Restart the game.",
    "#GENE\\GENER018#Quit the game.",
    ""
};

void GameOverMenu(void)
{
    int r;

    for (;;) {
        menu_busy = 1;
        r = TextBox(MenuText, gameover_menu, 20, 20, 0xB0, 1, 0, 1);
        menu_busy = 0;
        switch (r) {
        case 1:
            FadeOut();
            RestoreNew();
            Fatal("#GENE\\GENER021#Restore new game failed.");
        case 0:
            FadeOut();
            LoadGameMenu();
        case -1:
            continue;
        case 2:
            FadeOut();
            exit(0);
        }
    }
}

char *text_menu[] = {
    "Text display",
    "Text subtitles.",
    "Display text until you press enter.",
    "No text displayed.",
    ""
};

/* Ask how to show speech text, or use the choice in intrplay.cfg. */
void TextModeMenu(int ask)
{
    int r;

    if (ask || (r = ReadTextMode()) == -1) {
        r = TextBox(MenuText, text_menu, 20, 30, 0xB0, 1, 0, 1);
        WriteTextMode(r);
    }
    switch (r) {
    case 0:
        voc_wait = 1;
        break;
    case 1:
        voc_wait = 0;
        break;
    case 2:
        voc_wait = 2;
        break;
    }
}

int ReadTextMode(void)
{
    int mode;
    FILE *f;

    f = fopen("intrplay.cfg", "rb");
    if (f == 0)
        return -1;
    if (filelength(fileno(f)) <= 16) {
        fclose(f);
        return -1;
    }
    fseek(f, 16L, SEEK_SET);
    fread(&mode, 2, 1, f);
    fclose(f);
    return mode;
}

int WriteTextMode(int mode)
{
    FILE *f;

    f = fopen("intrplay.cfg", "r+b");
    if (f == 0)
        return -1;
    if (filelength(fileno(f)) < 16) {
        fclose(f);
        return -1;
    }
    fseek(f, 16L, SEEK_SET);
    fwrite(&mode, 2, 1, f);
    fclose(f);
    return 0;
}
