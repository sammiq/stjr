/* list: doubly linked lists (ST25's seg011, plus three new functions) */

#include "list.h"

void ListInit(List *l)
{
    l->head.next = &l->tail;
    l->head.prev = &l->tail;
    l->tail.next = &l->head;
    l->tail.prev = &l->head;
}

/* Link n in next to the tail sentinel. */
void ListAdd(List *l, Node *n)
{
    Node *last;
    Node *tail;

    last = l->tail.next;
    tail = &l->tail;
    n->prev = tail;
    n->next = last;
    last->prev = n;
    tail->next = n;
}
