/*
@(#)File:            link.c
@(#)Version:         53.1
@(#)Last changed:    97/03/06
@(#)Purpose:         Specialized doubly-linked list management routines
@(#)Author:          J Leffler
@(#)Copyright:       (C) Jonathan Leffler 1996,1997
@(#)Product:         :PRODUCT:
*/

/*TABSTOP=4*/

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "Informix.h"

#ifndef lint
static const char sccs[] = "@(#)link.c	53.1 97/03/06";
#endif

/* Initialize the head link of a list */
void new_headlink(Link *link)
{
	link->next = link;
	link->prev = link;
	link->data = 0;
}

/* Delete the link from the list and cleanup the data */
void delete_link(Link *link_d, void (*function)(void *))
{
	Link	*link_1;
	Link	*link_2;

	link_1 = link_d->prev;
	link_2 = link_d->next;
	link_1->next = link_2;
	link_2->prev = link_1;
	(*function)(link_d->data);
}

void destroy_chain(Link *head, void (*function)(void *))
{
	/* Delete all links */
	dbd_ix_debug(1, "%s::destroy_chain()\n", "DBD::Informix");
	while (head->next->data != 0)
		delete_link(head->next, function);
}

/* Add the link (link_n) after a pre-existing link in a list (link_1) */
void add_link(Link *link_1, Link *link_n)
{
	Link	*link_2 = link_1->next;

	assert(link_2->prev == link_1);
	link_n->next = link_2;
	link_n->prev = link_1;
	link_1->next = link_n;
	link_2->prev = link_n;
}
