/* seg005: input events */

#include <dos.h>
#include <conio.h>
#include "mem.h"
#include "sprite.h"
#include "sound.h"
#include "event.h"

/* Globals this file owns (declared in the headers). */
int buttons;
unsigned long ticks;
int input_dev;

void Fatal(char *fmt, ...);     /* fatal error */
void MsgBox(char *title, char *msg, int a, int b, int c, int d);    /* seg008: message box */
void QuitMenu(int a, int b);       /* seg019: quit dialog */

/* seg027: joystick */
extern int joy_x;
extern int joy_y;
extern int joy_buttons;
extern int joy_present;
void JoyCalibrate(void);
void JoyUpdate(void);

extern Rect clip_rect;
extern int sound_closed;
Event *ev_write;
Event *ev_read;
Event ev_queue[EV_MAX];
unsigned char move_pending;      /* an EV_MOVE is queued */
unsigned char tick_pending;      /* an EV_TICK is queued */
unsigned char mouse_present;
unsigned long last_tick;
int old_buttons;
int key_code;
int key_shift;
int mouse_hires;                 /* the driver works in 640 wide coordinates */
int key_b1;                      /* keypad + held: left button */
int key_b2;                      /* keypad - held: right button */
extern int kbd_mouse;                   /* keypad arrows jump the pointer */
int arrow_key;                   /* keypad arrow held */
int arrow_changed;
int btn_key;
int btn_changed;
int shift_key;

int last_mx = 160;
int last_my = 100;
int joy_recal = 0;
int key_accel = 1;                      /* held keypad arrows speed up */
unsigned long key_tick0 = 0;
long key_unused = 0;
unsigned long last_key_tick = 0;
void (_interrupt _far *old_kbd)(void) = 0;

void EventInit(void)
{
    ev_read = ev_write = ev_queue;
    tick_pending = move_pending = 0;
    MouseInit();
    mouse_present = input_dev == INPUT_MOUSE;
}

Event *PeekEvent(void)
{
    PollInput();
    if (ev_read != ev_write)
        return ev_read;
    else
        return 0;
}

void PopEvent(void)
{
    if (ev_read == ev_write)
        return;
    move_pending -= ev_read->type == EV_MOVE;
    tick_pending -= ev_read->type == EV_TICK;
    ev_read = NextEvent(ev_read);
}

Event *GetEvent(Event *e)
{
    Event *p;

    if ((p = PeekEvent()) != 0) {
        MemCpy(e, p, sizeof(Event));
        PopEvent();
        return e;
    } else
        return 0;
}

/* Queue a copy of e. Moves and ticks are merged into one already queued. */
void PostEvent(Event *e)
{
    if (e->type == EV_MOVE && move_pending) {
        register Event *p;

        for (p = ev_read; p != ev_write; p = NextEvent(p)) {
            if (p->type == EV_MOVE) {
                *p = *e;
                return;
            }
        }
    } else if (e->type == EV_TICK && tick_pending)
        return;
    if (e->type == EV_MOVE)
        move_pending = 1;
    if (e->type == EV_TICK)
        tick_pending = 1;
    *ev_write = *e;
    ev_write = NextEvent(ev_write);
}

void FlushEvents(void)
{
    Event e;

    while (GetEvent(&e))
        ;
    ev_read = ev_write = ev_queue;
    tick_pending = move_pending = 0;
}

long GetTicks(void)
{
    ReadClock();
    return ticks;
}

Event *NextEvent(Event *p)
{
    if (++p == &ev_queue[EV_MAX])
        p = ev_queue;
    if (ev_read == p)
        Fatal("event overflow");
    return p;
}

/* Turn the timer, pointer and keyboard state into events. */
void PollInput(void)
{
    if (sound_closed) {
        sound_closed = 0;
        MsgBox("Warning",
                  "#GENE\\GENER027#Insufficient memory to continue playing music and sound effects.",
                  300, 199, 176, 0);
    }
    if (joy_recal == 1) {
        joy_recal = 0;
        JoyCalibrate();
        MsgBox("Joystick",
                  "Move the joystick from upper-left to lower-right and then press <ENTER>.",
                  300, 199, 176, 0);
    }
    PollTimer();
    PollMouse();
    PollKeys();
}

void PollTimer(void)
{
    Event e;

    ReadClock();
    if (ticks != last_tick) {
        e.type = EV_TICK;
        last_tick = e.time = ticks;
        PostEvent(&e);
    }
}

void PollMouse(void)
{
    Event e;

    if (ReadPointer()) {
        if (mouse_x != last_mx || mouse_y != last_my) {
            e.type = EV_MOVE;
            last_mx = e.x = mouse_x;
            last_my = e.y = mouse_y;
            PostEvent(&e);
        }
        if ((buttons & 1) != (old_buttons & 1)) {
            old_buttons ^= 1;
            e.type = (buttons & 1) ? EV_DOWN1 : EV_UP1;
            e.x = mouse_x;
            e.y = mouse_y;
            PostEvent(&e);
        }
        if ((buttons & 2) != (old_buttons & 2)) {
            old_buttons ^= 2;
            e.type = (buttons & 2) ? EV_DOWN2 : EV_UP2;
            e.x = mouse_x;
            e.y = mouse_y;
            PostEvent(&e);
        }
    }
}

/* Keys; Ctrl-S sound, Ctrl-M music, Ctrl-P pause, Ctrl-Q quit and Ctrl-J
 * joystick are handled here. */
void PollKeys(void)
{
    Event e;

    while (KeyReady()) {
        ReadKey();
        if (key_code == 0x1F13)
            SetSfxOn(!sfx_on);
        else if (key_code == 0x320D)
            SetMusicOn(!music_on);
        else if (key_code == 0x1910)
            getch();
        else if (key_code == 0x1011)
            QuitMenu(300, 199);
        else if (!mouse_present && key_code == 0x240A) {
            joy_present = 1;
            joy_recal = 1;
        } else if (key_code) {
            e.type = EV_KEY;
            e.key = key_code;
            e.shift = key_shift;
            PostEvent(&e);
        }
    }
}

void MouseInit(void)
{
    int ok;

    ok = 0;
    if (input_dev == INPUT_MOUSE) {
        _asm {
            sub ax, ax
            int 33h
            cmp ax, 0FFFFh
            jne l_none
            mov ax, 7
            mov cx, 0
            mov dx, 27Fh
            int 33h
            mov ax, 8
            mov cx, 0
            mov dx, 0C7h
            int 33h
            mov ax, 4
            mov cx, 27Fh
            mov dx, 64h
            int 33h
            mov mouse_hires, 1
            mov ax, 3
            int 33h
            cmp cx, 27Fh
            je l_hires
            cmp cx, 27Eh
            je l_hires
            dec mouse_hires
        l_hires:
            mov ax, 4
            mov cx, 140h
            mov dx, 64h
            int 33h
            mov ax, 1
            jmp short l_done
        l_none:
            sub ax, ax
        l_done:
            mov ok, ax
        }
        if (ok == 0)
            input_dev = INPUT_KEYS;
    } else if (input_dev == INPUT_JOY) {
        joy_present = 1;
        JoyCalibrate();
        joy_x = 160;
        joy_y = 100;
        if (joy_present == 0)
            input_dev = INPUT_KEYS;
    }
}

/* Read the pointer position and buttons from the keypad, mouse or
 * joystick. */
int ReadPointer(void)
{
    int keys;

    keys = (key_b1 ? 1 : 0) | (key_b2 ? 2 : 0);
    if (kbd_mouse) {
        /* the arrows jump to the middle or the edges of the view */
        if (arrow_key || TestAndClear(&arrow_changed)) {
            int dx;
            int dy;
            int cx;
            int cy;
            int hw;
            int hh;

            switch (arrow_key) {
            case 0x47:
                dx = -1, dy = -1;
                break;
            case 0x48:
                dx = 0, dy = -1;
                break;
            case 0x49:
                dx = 1, dy = -1;
                break;
            case 0x4B:
                dx = -1, dy = 0;
                break;
            case 0x4D:
                dx = 1, dy = 0;
                break;
            case 0x4F:
                dx = -1, dy = 1;
                break;
            case 0x50:
                dx = 0, dy = 1;
                break;
            case 0x51:
                dx = 1, dy = 1;
                break;
            case 0x4A:
            case 0x4C:
            case 0x4E:
            default:
                dx = 0, dy = 0;
                break;
            }
            dx <<= 1, dy <<= 1;
            cx = (clip_rect.x0 + clip_rect.x1) / 2;
            cy = (clip_rect.y0 + clip_rect.y1) / 2;
            hw = (clip_rect.x1 - clip_rect.x0) / 4;
            hh = (clip_rect.y1 - clip_rect.y0) / 4;
            mouse_x = dx * hw + cx;
            mouse_y = dy * hh + cy;
            SetPointer(mouse_x, mouse_y);
            buttons = keys;
            return 1;
        }
    } else {
        /* the arrows move the pointer, faster the longer they are held */
        if (arrow_key && key_accel) {
            if (ticks != last_key_tick) {
                unsigned step;
                unsigned long saved;

                if (TestAndClear(&arrow_changed)) {
                    key_tick0 = ticks;
                    step = 1;
                } else if (ticks <= key_tick0 + 64) {
                    step = (unsigned)(ticks - key_tick0) / 4;
                    step = (step + 1) / 2 * step;
                } else
                    step = 128;
                switch (arrow_key) {
                case 0x47:
                    mouse_x -= step, mouse_y -= step;
                    break;
                case 0x48:
                    mouse_y -= step;
                    break;
                case 0x49:
                    mouse_x += step, mouse_y -= step;
                    break;
                case 0x4B:
                    mouse_x -= step;
                    break;
                case 0x4D:
                    mouse_x += step;
                    break;
                case 0x4F:
                    mouse_x -= step, mouse_y += step;
                    break;
                case 0x50:
                    mouse_y += step;
                    break;
                case 0x51:
                    mouse_x += step, mouse_y += step;
                    break;
                }
                if ((int)mouse_x < 0)
                    mouse_x = 0;
                else if (mouse_x > 319)
                    mouse_x = 319;
                if ((int)mouse_y < 0)
                    mouse_y = 0;
                else if (mouse_y > 199)
                    mouse_y = 199;
                saved = key_tick0;
                SetPointer(mouse_x, mouse_y);
                key_tick0 = saved;
                buttons = keys;
            }
            last_key_tick = ticks;
            return 1;
        }
    }
    if (mouse_present) {
        _asm {
            mov ax, 3
            int 33h
            and bx, 3
            cmp mouse_hires, 0
            je l_lores
            shr cx, 1
        l_lores:
            or bx, keys
            mov buttons, bx
            mov mouse_x, cx
            mov mouse_y, dx
        }
        return 1;
    }
    if (joy_present) {
        JoyUpdate();
        buttons = joy_buttons | keys;
        mouse_x = joy_x;
        mouse_y = joy_y;
        return 1;
    }
}

void SetPointer(int x, int y)
{
    key_tick0 = ticks;
    if (mouse_present) {
        _asm {
            mov ax, 4
            mov cx, x
            cmp mouse_hires, 0
            je l_lores
            shl cx, 1
        l_lores:
            mov dx, y
            int 33h
        }
    } else if (joy_present) {
        joy_x = x;
        joy_y = y;
    }
}

void ReadClock(void)
{
    _asm {
        sub ax, ax
        int 1Ah
        mov word ptr ticks, dx
        mov word ptr ticks+2, cx
    }
}

/* INT 9: track the keypad keys used as a pointer, then chain to the BIOS. */
void _interrupt _far KbdISR(void)
{
    int code;
    int up;

    code = inp(0x60);
    up = code & 0x80;
    code &= 0x7F;
    switch (code) {
    case 0x47:
    case 0x48:
    case 0x49:
    case 0x4B:
    case 0x4D:
    case 0x4F:
    case 0x50:
    case 0x51:
        if (up) {
            if (arrow_key == code)
                arrow_key = 0, arrow_changed = 1;
        } else if (arrow_key != code)
            arrow_key = code, arrow_changed = 1;
        break;
    case 0x52:
    case 0x53:
        if (up) {
            if (btn_key == code)
                btn_key = 0, btn_changed = 1;
        } else if (arrow_key != code)
            btn_key = code, btn_changed = 1;
        break;
    case 0x2A:
    case 0x36:
        if (up) {
            if (shift_key == code)
                shift_key = 0;
        } else
            shift_key = code;
        break;
    case 0x4A:
        key_b2 = !up;
        break;
    case 0x4E:
        key_b1 = !up;
        break;
    }
    _chain_intr(old_kbd);
}

void HookKbd(void)
{
    if (old_kbd == 0) {
        old_kbd = _dos_getvect(9);
        _dos_setvect(9, KbdISR);
    }
}

void UnhookKbd(void)
{
    if (old_kbd) {
        _dos_setvect(9, old_kbd);
        old_kbd = 0;
    }
}

int TestAndClear(int *p)
{
    int v;

    _disable();
    v = *p;
    *p = 0;
    _enable();
    return v;
}

int KeyReady(void)
{
    _asm {
        mov ah, 1
        int 16h
        mov ax, 0
        je l_none
        inc ax
    l_none:
    }
}

void ReadKey(void)
{
    _asm {
        mov ah, 2
        int 16h
        sub ah, ah
        mov key_shift, ax
        mov key_code, 0
    l_next:
        call KeyReady
        je l_done
        sub ax, ax
        int 16h
        or ax, ax
        je l_next
        mov key_code, ax
    l_done:
    }
}

void MouseShow(void)
{
    _asm {
        mov ax, 1
        int 33h
    }
}

void MouseReset(void)
{
    _asm {
        mov ax, 0
        int 33h
    }
}
