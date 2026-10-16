/* seg019: saving and loading games, and the game menus that go with them */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <io.h>
#include "mem.h"
#include "gfx.h"

#define SAVE_VERSION 0x24
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
void sub_1EE58(int a, char *msg);   /* seg008 (unidentified): show msg */
char *InputDescription(void);       /* seg002 */

SaveDir save_dir;
char save_path[80];
char save_desc[25];
FILE *save_fp;
int save_version;
extern int voc_wait;
extern char save_prefix[];          /* directory the saves go in */
int load_arg;

void LoadSaveDir(void);
void SaveSaveDir(void);
void SavePath(int n);
void SaveWrite(void *p, unsigned n);
void SaveRead(void *p, unsigned n);
int SaveGame(void);
void LoadGame(int verbose);
int SaveGame(void)
{
    if ((save_fp = fopen(save_path, "wb")) == NULL)
        return 0;
    SaveWrite(save_desc, 25);
    save_version = SAVE_VERSION;
    SaveWrite(&save_version, 2);
    SaveGameState();
    fclose(save_fp);
    return 1;
}

void LoadGame(int verbose)
{
    if ((save_fp = fopen(save_path, "rb")) == NULL) {
        if (verbose)
            sub_1EE58(-1, "Unable to load game.");
        return;
    }
    SaveRead(save_desc, 25);
    SaveRead(&save_version, 2);
    if (save_version != SAVE_VERSION) {
        if (verbose)
            MsgBox("Load Game", "Unable to load game.  Game was saved by an older version of this program.",
                   20, 20, 9, 0);
    } else
        LoadGameState();
    fclose(save_fp);
}

void SaveClose(void);
int SaveVersion(void);
void SaveNew(void);
void RestoreNew(void);
void SaveNamed(char *name);
void LoadNamed(char *name, int arg);
int GetLoadArg(void);
char *SlotName(int n, char *title, char *out);
char *MenuText(int n, char **list, char *out);
void SaveMenu(void);
void LoadGameMenu(void);
void QuitMenu(int x, int y);
void GameOverMenu(void);
void TextModeMenu(int ask);
int ReadTextMode(void);
int WriteTextMode(int mode);

void SaveWrite(void *p, unsigned n)
{
    fwrite(p, 1, n, save_fp);
}

void SaveRead(void *p, unsigned n)
{
    fread(p, 1, n, save_fp);
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
    sprintf(save_path, "%ssavegame.new", save_prefix);
    if (access(save_path, 0) == -1 || SaveVersion() != SAVE_VERSION)
        SaveGame();
}

/* LoadGame doesn't come back when it works. */
void RestoreNew(void)
{
    sprintf(save_path, "%ssavegame.new", save_prefix);
    LoadGame(0);
    Fatal("Unable to load savegame.new");
}

void SaveNamed(char *name)
{
    sprintf(save_path, "%s%s.sav", save_prefix, name);
    SaveGame();
    load_arg = 0;
}

void LoadNamed(char *name, int arg)
{
    load_arg = arg;
    sprintf(save_path, "%s%s.sav", save_prefix, name);
    LoadGame(0);
    Fatal("Can't open %s", save_path);
}

int GetLoadArg(void)
{
    return load_arg;
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

