/*
@(#)Purpose:         Specialized doubly-linked list management routines
@(#)Author:          J Leffler
@(#)Copyright:       1996-98 Jonathan Leffler
@(#)Copyright:       2002    IBM
@(#)Product:         Informix Database Driver for Perl Version 1.03.PC1 (2002-11-21)
*/

/*TABSTOP=4*/

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "Informix.h"

#ifdef DBD_IX_DEBUG_LINK
#define PRINT_LIST(s, x)	print_list(s, x)
#define PRINT_LINK(s, x)	print_link(s, x)
#else
#define PRINT_LIST(s, x)	/* As nothing */
#define PRINT_LINK(s, x)	/* As nothing */
#endif /* DBD_IX_DEBUG_LINK */

#ifndef lint
static const char rcs[] = "@(#)$Id: link.c,v 100.1 2002/02/08 22:49:30 jleffler Exp $";
#endif

#ifdef DBD_IX_DEBUG_LINK
typedef unsigned long Ulong;
static void	print_link(const char *s, Link *x)
{
	fprintf(stderr, "%s: link 0x%08X, data 0x%08X, next 0x%08X, prev 0x%08X\n",
			s, (Ulong)x, (Ulong)x->data, (Ulong)x->next, (Ulong)x->prev);
}

static void	print_list(const char *s, Link *x)
{
	Link *y;
	fprintf(stderr, "-BEGIN- %s:\n", s);
	print_link("Start link", x);
	y = x;
	while ((y = y->next) != x)
	{
		print_link("Chain link", y);
	}
	fprintf(stderr, "--END-- %s:\n", s);
}
#endif /* DBD_IX_DEBUG_LINK */

/* Initialize the head link of a list */
void dbd_ix_link_newhead(Link *link)
{
	link->next = link;
	link->prev = link;
	link->data = 0;
	PRINT_LIST("dbd_ix_link_newhead", link);
}

/* Delete the link from the list and cleanup the data */
void dbd_ix_link_delete(Link *link_d, void (*function)(void *))
{
	Link	*link_1;
	Link	*link_2;

	link_1 = link_d->prev;
	link_2 = link_d->next;
	PRINT_LINK("dbd_ix_link_delete:delete", link_d);
	PRINT_LIST("dbd_ix_link_delete:before", link_d);
	link_1->next = link_2;
	link_2->prev = link_1;
	PRINT_LIST("dbd_ix_link_delete:after", link_2);
	link_d->next = link_d->prev = link_d;
	(*function)(link_d->data);
}

void dbd_ix_link_delchain(Link *head, void (*function)(void *))
{
	/* Delete all links */
	dbd_ix_debug(1, "-->> %s::dbd_ix_link_delchain()\n", "DBD::Informix");
	PRINT_LIST("dbd_ix_link_delchain:before", head);
	while (head->next->data != 0)
		dbd_ix_link_delete(head->next, function);
	PRINT_LIST("dbd_ix_link_delchain:after", head);
	dbd_ix_debug(1, "<<-- %s::dbd_ix_link_delchain()\n", "DBD::Informix");
}

/* Add the link (link_n) after a pre-existing link in a list (link_1) */
void dbd_ix_link_add(Link *link_1, Link *link_n)
{
	Link	*link_2 = link_1->next;

	PRINT_LINK("dbd_ix_link_add:insert", link_n);
	PRINT_LIST("dbd_ix_link_add:before", link_1);
	assert(link_2->prev == link_1);
	link_n->next = link_2;
	link_n->prev = link_1;
	link_1->next = link_n;
	link_2->prev = link_n;
	PRINT_LIST("dbd_ix_link_add:after", link_1);
}

