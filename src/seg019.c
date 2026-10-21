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
long TextBox(char *(far *get)(int, void *, char *), void *data, int a, int b, int c, int d,
              int e, int f);                                        /* seg008: list box */
void StartTalk(int a, char *s, int b, int c, int d, int e);         /* seg000 */
void ClearScreen(void);                 /* seg001 */
int CfgOpen(char *name);                /* (c2D688): trek2.cfg settings */
int CfgGet(char *key, char *out);
void CfgSet(char *key, char *value);
void CfgSave(char *name);
void CfgClose(void);
void CentreLine(char *out, char *title);                             /* seg008 */
void SaveGameState(void);               /* seg008: write the game state */
void LoadGameState(void);               /* seg008: read the game state */
void Fatal(char *fmt, ...);     /* fatal error */
void CrewSay(int a, char *msg);   /* seg008 (unidentified): show msg */
char *InputDescription(void);       /* seg002 */

static FILE *save_fp;
static SaveDir save_dir;
static char save_path[80];
static char save_desc[25];
static int save_version;
static int load_arg;
static char cd_prompt[64];
extern int voc_wait;
extern char save_prefix[];          /* directory the saves go in */
extern int combat_level;            /* seg001 */
extern char byte_47A91;             /* (room state) */

void LoadSaveDir(void);
void SaveSaveDir(void);
void SavePath(int n);
void SaveWrite(void *p, unsigned n);
void SaveRead(void *p, unsigned n);
int SaveGame(void);
void LoadGame(int verbose);
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
void StartMenu(void);
void CombatMenu(void);
int SoundCardMenu(void);
int InsertCDMenu(char *name);
void PushVoiceMode(int mode);
void PopVoiceMode(void);
int VoiceMode(void);
void TextModeMenu(int ask);
int ReadTextMode(void);
void WriteTextMode(int mode);

int save_dir_loaded = 0;

void LoadSaveDir(void)
{
    char path[128];
    FILE *f;

    if (save_dir_loaded)
        return;
    save_dir_loaded = 1;
    sprintf(path, "%ssavegame.dir", save_prefix);
    if (access(path, 0) == -1) {
        save_dir.count = 0;
        save_dir.used = 0;
    } else {
        f = fopen(path, "rb");
        fread(&save_dir, 1, sizeof(save_dir), f);
        fclose(f);
    }
}

void SaveSaveDir(void)
{
    char path[128];
    FILE *f;

    sprintf(path, "%ssavegame.dir", save_prefix);
    f = fopen(path, "wb");
    fwrite(&save_dir, 1, sizeof(save_dir), f);
    fclose(f);
}

void SavePath(int n)
{
    sprintf(save_path, "%ssavegame.%d", save_prefix, save_dir.slot[n]);
}

void SaveWrite(void *p, unsigned n)
{
    fwrite(p, 1, n, save_fp);
}

void SaveRead(void *p, unsigned n)
{
    fread(p, 1, n, save_fp);
}

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
            CrewSay(-1, "Unable to load game.");
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

    cancel = save_dir.count ? "Cancel." : "There are no saved games.";
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
    "#GENER023#Save new game.",
    "#GENER019#Replace previous game.",
    "#GENER002#Delete previous game.",
    "#GENER000#Cancel.",
    ""
};

void SaveMenu(void)
{
    int choice;
    int i;

    LoadSaveDir();
    StartTalk(-2, "", 0, 0, 0, 0);
    for (;;) {
        choice = TextBox(MenuText, save_menu, 20, 20, 9, 1, 0, 1);
        switch (choice) {
        case 0:
            if (save_dir.count == MAX_SAVES) {
                CrewSay(-1, "Too many games saved. Replace or delete a previous game.");
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
                if (!SaveGame())
                    CrewSay(-1, "Unable to save game. Disk may be full or read only.");
                else
                    SaveSaveDir();
                return;
            }
        case 1:
            i = TextBox(SlotName, "Save Game", 20, 20, 9, 1, 0, 1);
            if (i != -1 && i != save_dir.count) {
                SavePath(i);
                if (!SaveGame())
                    CrewSay(-1, "Unable to replace game. Disk may be full or read only.");
            }
            return;
        case 2:
            i = TextBox(SlotName, "Delete Game", 20, 20, 9, 1, 0, 1);
            if (i != -1 && i != save_dir.count) {
                int j;

                SavePath(i);
                remove(save_path);
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
    StartTalk(-2, "", 0, 0, 0, 0);
    if (save_dir.count == 0) {
        MsgBox("Load Game", "No games have been saved.", 20, 20, 9, 0);
        return;
    }
    i = TextBox(SlotName, "Load Game", 20, 20, 9, 1, 0, 1);
    if (i != -1 && i != save_dir.count) {
        SavePath(i);
        FadeOut();
        LoadGame(1);
    }
}

int menu_busy = 0;

char *quit_menu[] = {
    "Quit Game",
    "#GENER028#Yes, quit the game.",
    "#GENER008#No, do not quit the game.",
    ""
};

void QuitMenu(int x, int y)
{
    int r;

    StartTalk(-2, "", 0, 0, 0, 0);
    if (menu_busy)
        return;
    menu_busy = 1;
    StartTalk(-2, "", 0, 0, 0, 0);
    r = TextBox(MenuText, quit_menu, x, y, 9, 1, 0, 1);
    menu_busy = 0;
    switch (r) {
    case 0:
        FadeOut();
        exit(0);
    }
}

/* With no saved games there's nothing to load. */
char *gameover_new_menu[] = {
    "Game Over",
    "#GENER020#Restart the game.",
    "#GENER018#Quit the game.",
    ""
};

char *gameover_menu[] = {
    "Game Over",
    "#GENER006#Load a previously saved game.",
    "#GENER020#Restart the game.",
    "#GENER018#Quit the game.",
    ""
};

void GameOverMenu(void)
{
    char **menu;
    int r;

    StartTalk(-2, "", 0, 0, 0, 0);
    LoadSaveDir();
    menu = save_dir.count ? gameover_menu : gameover_new_menu;
    for (;;) {
        menu_busy = 1;
        r = TextBox(MenuText, menu, 20, 20, 9, 1, 0, 1);
        menu_busy = 0;
        if (save_dir.count == 0)
            r++;
        switch (r) {
        case 1:
            CombatMenu();
            combat_level |= 0x8000;
            FadeOut();
            RestoreNew();
            Fatal("Restore new game failed.");
        case 0:
            LoadGameMenu();
            continue;
        case 2:
            FadeOut();
            exit(0);
        }
    }
}

char *start_menu[] = {
    "Start Game",
    "#GENER006#Load a previously saved game.",
    "#GENER020#Restart the game.",
    ""
};

void StartMenu(void)
{
    ClearScreen();
    FadeIn();
    StartTalk(-2, "", 0, 0, 0, 0);
    LoadSaveDir();
    if (!save_dir.count) {
        CombatMenu();
        FadeOut();
        return;
    }
    for (;;) {
        switch ((int)TextBox(MenuText, start_menu, 20, 20, 9, 1, 0, 1)) {
        case 0:
            LoadGameMenu();
        case 1:
            goto done;
        }
    }
done:
    CombatMenu();
    FadeOut();
}

char *combat_menu[] = {
    "Space Combat Level",
    "Federation Cadet (None).",
    "Academy Graduate (Easy).",
    "Commissioned Officer (Hard).",
    ""
};

void CombatMenu(void)
{
    int r;

    StartTalk(-2, "", 0, 0, 0, 0);
    r = TextBox(MenuText, combat_menu, 20, 30, 9, 1, 0, 1);
    if (r == -1)
        combat_level = 2;
    else
        combat_level = r;
    byte_47A91 = combat_level;
}

char *sound_menu[] = {
    "Speech/Music card",
    "Soundblaster @ 220, IRQ 7, DMA 1.",
    "Don't use a sound card.",
    ""
};

/* Returns 1 to use the sound card. */
int SoundCardMenu(void)
{
    StartTalk(-2, "", 0, 0, 0, 0);
    return TextBox(MenuText, sound_menu, 20, 30, 9, 1, 0, 1) == 0;
}

char *cd_menu[] = {
    "Please insert CD",
    "OK",
    "Quit",
    ""
};

/* Returns 1 for OK. */
int InsertCDMenu(char *name)
{
    StartTalk(-2, "", 0, 0, 0, 0);
    LoadPalette("bridge");
    FadeIn();
    sprintf(cd_prompt, "Please insert %s CD", name);
    return TextBox(MenuText, cd_menu, 20, 30, 9, 1, 0, 1) == 0;
}

/* The speech/text setting, kept on a stack so a scene can change it
 * for a while: 0 speech only, 1 with subtitles, 2 text until Enter. */
int voice_depth = 0;
int voice_modes[20] = { 1 };

void PushVoiceMode(int mode)
{
    if (voice_depth < 19)
        voice_modes[++voice_depth] = mode;
}

void PopVoiceMode(void)
{
    if (voice_depth != 0)
        voice_depth--;
}

int VoiceMode(void)
{
    return voice_modes[voice_depth];
}

char *text_menu[] = {
    "Text/Speech Options",
    "Speech only.",
    "Speech with text subtitles.",
    "Display text subtitles until you press <ENTER>.",
    ""
};

/* Ask how to show speech text, or use the choice in trek2.cfg. */
void TextModeMenu(int ask)
{
    int r;

    StartTalk(-2, "", 0, 0, 0, 0);
    r = ReadTextMode();
    if (ask || r == -1) {
        switch (TextBox(MenuText, text_menu, 20, 30, 9, 1, 0, 1)) {
        default:
            r = 1;
            break;
        case 0:
            r = 2;
            break;
        case 2:
            r = 0;
            break;
        }
        WriteTextMode(r);
    }
    voice_depth = 0;
    voice_modes[0] = r;
}

int ReadTextMode(void)
{
    int mode;
    char buf[10];

    mode = -1;
    if (CfgOpen("trek2.cfg")) {
        if (CfgGet("talktype", buf))
            mode = atoi(buf);
        CfgClose();
    }
    return mode;
}

void WriteTextMode(int mode)
{
    char buf[10];

    if (CfgOpen("trek2.cfg")) {
        sprintf(buf, "%d", mode);
        CfgSet("talktype", buf);
        CfgSave("trek2.cfg");
        CfgClose();
    }
}
