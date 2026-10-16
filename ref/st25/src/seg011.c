/* seg011: doubly linked lists */

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

void ListRemove(List *l, Node *n)
{
    Node *a;
    Node *b;

    a = n->next;
    b = n->prev;
    a->prev = b;
    b->next = a;
    n->next = 0;
    n->prev = 0;
}

/* Not called anywhere in the game. */
int ListCount(List *l)
{
    Node *n;
    Node *tail;
    int count;

    tail = &l->tail;
    count = 0;
    for (n = l->head.prev; n != tail; ++count, n = n->prev)
        ;
    return count;
}
