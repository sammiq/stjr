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
unsigned long key_tick0 = 0;
void (_interrupt _far *old_kbd)(void) = 0;

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
