/* cfg: trek2.cfg, a file of key=value settings (new in the sequel) */

#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>

#define CFG_MAX 24

void Fatal(char *fmt, ...);     /* fatal error */

typedef struct CfgEntry {
    char *key;
    char *value;
} CfgEntry;

CfgEntry *cfg_env;

int CfgFind(char *key);
void CfgTrim(char *s, int how);

/* Copy key's value to out: out, or 0 if there's none. */
char *CfgGet(char *key, char *out)
{
    int i;
    char *r;

    r = (char *)(i = 0);
    if ((i = CfgFind(key)) != CFG_MAX) {
        strcpy(out, cfg_env[i].value);
        r = out;
    }
    return r;
}

void CfgSet(char *key, char *value)
{
    int i;

    if ((i = CfgFind(key)) != CFG_MAX) {
        if (cfg_env[i].value)
            _nfree(cfg_env[i].value);
    } else {
        for (i = 0; cfg_env[i].key; i++)
            if (i == CFG_MAX)
                Fatal("Exceeded max environment entries: %d", CFG_MAX);
        cfg_env[i].key = _strdup(key);
    }
    cfg_env[i].value = _strdup(value);
}

/* key's entry, or CFG_MAX. */
int CfgFind(char *key)
{
    int i;

    for (i = 0; i < CFG_MAX; i++) {
        if (cfg_env[i].key == 0) {
            i = CFG_MAX;
            break;
        }
        if (stricmp(key, cfg_env[i].key) == 0)
            break;
    }
    return i;
}

/* Remove leading spaces (how & 1) and trailing ones (how & 2). */
void CfgTrim(char *s, int how)
{
    char *start;
    char *dst;
    int seen;
    int n;

    dst = start = s;
    seen = 0;
    if (how & 1) {
        while (*s) {
            if (*s == ' ' && !seen)
                s++;
            else {
                *dst++ = *s++;
                seen = 1;
            }
        }
        *dst = 0;
    }
    n = strlen(start);
    while ((how & 2) && n-- && start[n] == ' ')
        start[n] = 0;
}

/* Read the settings in name: 0 if it can't be opened. */
/* (97.55%: the target keeps the dead store to k, which this drops.) */
int CfgOpen(char *name)
{
    static char delims[7] = "\t\n\r=,";
    char line[138];
    FILE *f;
    int ok;
    int n;
    int k;
    char *tok;
    int i;

    ok = 0;
    if ((f = fopen(name, "rt")) != 0) {
        if (cfg_env == 0) {
            cfg_env = _nmalloc(CFG_MAX * sizeof(CfgEntry));
            memset(cfg_env, 0, CFG_MAX * sizeof(CfgEntry));
        }
        ok = 1;
        n = 0;
        for (tok = 0, k = 0, i = 0; fgets(line, sizeof(line), f); ) {
            tok = strtok(line, delims);
            CfgTrim(tok, 3);
            if (strlen(tok) > 2) {
                if (i == CFG_MAX)
                    Fatal("Exceeded max environment entries: %d", CFG_MAX);
                cfg_env[i].key = _strdup(tok);
                if ((tok = strtok(0, delims)) != 0) {
                    CfgTrim(tok, 3);
                    cfg_env[i].value = _strdup(tok);
                } else
                    cfg_env[i].value = _strdup("");
                i++;
            }
        }
        fclose(f);
    }
    return ok;
}

void CfgClose(void)
{
    int i;

    if (cfg_env[0].key)
        for (i = 0; cfg_env[i].key; i++) {
            _nfree(cfg_env[i].key);
            _nfree(cfg_env[i].value);
        }
    _nfree(cfg_env);
    cfg_env = 0;
}

/* Write the settings to name. */
void CfgSave(char *name)
{
    char line[128];
    FILE *f;
    int n;
    int i;

    if ((f = fopen(name, "wt")) != 0) {
        for (n = 0, i = 0; cfg_env[i].key; i++) {
            sprintf(line, "%s=%s\n", cfg_env[i].key, cfg_env[i].value);
            fputs(line, f);
        }
        fclose(f);
        return;
    }
    Fatal("Couldn't save configuration file: %s", name);
}
