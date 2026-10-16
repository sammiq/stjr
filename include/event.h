/* event.h - input events: timer ticks, mouse/joystick/keypad pointer, keys */

#ifndef EVENT_H
#define EVENT_H

/* Event types */
#define EV_TICK     0       /* the BIOS tick count changed */
#define EV_DOWN1    1       /* left button pressed */
#define EV_MOVE     2       /* pointer moved */
#define EV_UP1      3
#define EV_DOWN2    4       /* right button pressed */
#define EV_UP2      5
#define EV_KEY      6

typedef struct Event {
    int type;               /* 00 */
    int key;                /* 02 BIOS scan code and character */
    int shift;              /* 04 BIOS shift state */
    int x;                  /* 06 */
    int y;                  /* 08 */
    long time;              /* 0A */
} Event;

#define EV_MAX      64

/* input_dev */
#define INPUT_KEYS  0
#define INPUT_MOUSE 1
#define INPUT_JOY   2

extern int input_dev;
extern unsigned long ticks;     /* BIOS ticks, updated by ReadClock */
extern unsigned mouse_x;
extern unsigned mouse_y;
extern int buttons;

void EventInit(void);
Event *PeekEvent(void);
void PopEvent(void);
Event *GetEvent(Event *e);
void PostEvent(Event *e);
void FlushEvents(void);
long GetTicks(void);
Event *NextEvent(Event *p);
void PollInput(void);
void PollTimer(void);
void PollMouse(void);
void PollKeys(void);
void MouseInit(void);
int ReadPointer(void);
void SetPointer(int x, int y);
void ReadClock(void);
void HookKbd(void);
void UnhookKbd(void);
int TestAndClear(int *p);
int KeyReady(void);
void ReadKey(void);
void MouseShow(void);
void MouseReset(void);

#endif
