/*
 * @(#)$Id: link.h,v 61.2 1998/10/29 19:30:58 jleffler Exp $ 
 *
 * Copyright (c) 1998 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

#ifndef LINK_H
#define LINK_H

/* Doubly linked list for tracking connections and statements */
typedef struct Link Link;

struct Link
{
	Link	*next;
	Link	*prev;
	void	*data;
};

#define dbd_ix_link_add		dbd_ix_link_add
#define dbd_ix_link_delete		dbd_ix_link_delete
#define dbd_ix_link_newhead	dbd_ix_link_newhead
#define dbd_ix_link_delchain	dbd_ix_link_delchain

extern void dbd_ix_link_add(Link *link_1, Link *link_n);
extern void dbd_ix_link_delete(Link *link_d, void (*function)(void *));
extern void dbd_ix_link_delchain(Link *head, void (*function)(void *));
extern void dbd_ix_link_newhead(Link *link);

#endif	/* LINK_H */
