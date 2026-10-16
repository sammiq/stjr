/* list.h - doubly linked lists with head and tail sentinels */

#ifndef LIST_H
#define LIST_H

typedef struct Node {
    struct Node *next;      /* 00 */
    struct Node *prev;      /* 02 */
} Node;

typedef struct List {
    Node head;              /* 00 */
    Node tail;              /* 04 */
} List;

void ListInit(List *l);
void ListAdd(List *l, Node *n);
void ListRemove(List *l, Node *n);
int ListCount(List *l);

#endif
