/*
 * @(#)$Id: dbdimp.h,v 56.5 1997/07/09 17:41:44 johnl Exp $ 
 *
 * $Derived-From: dbdimp.h,v 1.5 1995/06/22 00:37:04 timbo Archaic $
 *
 * Copyright (c) 1994,1995 Tim Bunce
 *           (c) 1996,1997 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

#ifndef DBDIMP_H
#define DBDIMP_H

#define NAMESIZE 19				/* 18 character name plus '\0' */
#define DEFAULT_DATABASE	".DEFAULT."

/* Different states for a statement */
enum State
{
	Unused, Prepared, Allocated, Described, Declared, Opened, Finished
};

typedef enum State State;		/* Cursor/Statement states */
typedef long ErrNum;			/* Informix Error Number */
typedef char Name[NAMESIZE];

/* Doubly linked list for tracking connections and statements */
typedef struct Link Link;

struct Link
{
	Link	*next;
	Link	*prev;
	void	*data;
};

/* Define drh implementor data structure */
struct imp_drh_st
{
	dbih_drc_t      com;		/* MUST be first element in structure   */
	Boolean         multipleconnections;/* Supports multiple connections */
	int             n_connections;		/* Number of active connections */
	const char     *current_connection;	/* Name of current connection */
	Link            head;               /* Head of list of connections */
};

/* Define dbh implementor data structure */
struct imp_dbh_st
{
	dbih_dbc_t      com;		/* MUST be first element in structure */
	char           *database;	/* Name of database */
	Name            nm_connection;	/* Name of connection */
	Boolean         is_connected;   /* Is connection open */
	Boolean         is_onlinedb;	/* Is OnLine Engine */
	Boolean         is_modeansi;	/* Is MODE ANSI Database */
	Boolean         is_loggeddb;	/* Has transaction log */
	Boolean         is_txactive;	/* Is inside transaction */
	BlobLocn        blob_bind;	/* Blob binding */
	Sqlca           sqlca;      /* Last SQLCA record for connection */
	Link            chain;      /* Link in list of connections */
	Link            head;       /* Head of list of statements */
};

/* Define sth implementor data structure */
struct imp_sth_st
{
	dbih_stc_t      com;		/* MUST be first element in structure   */
	Name            nm_stmnt;	/* Name of prepared statement */
	Name            nm_obind;	/* Name of allocated descriptor */
	Name            nm_cursor;	/* Name of declared cursor */
	Name            nm_ibind;	/* Name of input (bind) descriptor */
	State           st_state;	/* State of statement */
	int             st_type;	/* Type of statement */
	BlobLocn        blob_bind;	/* Blob Binding */
	int             n_blobs;	/* Number of blobs for statement */
	int             n_columns;	/* Number of output fields */
	int             n_bound;	/* Number of input fields */
	int             n_rows;		/* Number of rows processed */
	imp_dbh_t	   *dbh;		/* Database handle for statement */
	Link            chain;      /* Link in list of statements */
};

#define DBI_AutoCommit(dbh)	(DBIc_is(dbh, DBIcf_AutoCommit) ? True : False)

extern void dbd_ix_seterror(ErrNum rc);

extern SV *dbd_dr_FETCH_attrib(imp_drh_t *drh, SV *keysv);
extern int dbd_dr_disconnectall(imp_drh_t *);
extern int dbd_dr_driver(SV *drh);
extern void dbd_dr_init(dbistate_t *dbistate);

extern SV *dbd_db_FETCH_attrib(imp_dbh_t *dbh, SV *keysv);
extern int dbd_db_STORE_attrib(imp_dbh_t *dbh, SV *keysv, SV *valuesv);
extern int dbd_db_begin(imp_dbh_t *sth);
extern int dbd_db_commit(imp_dbh_t *sth);
extern int dbd_db_connect(imp_dbh_t *dbh, char *dbs, char *uid, char *pwd);
extern int dbd_db_createprocfrom(imp_dbh_t *imp_dbh, char *file);
extern int dbd_db_disconnect(imp_dbh_t *dbh);
extern int dbd_db_immediate(imp_dbh_t *dbh, char *stmt);
extern int dbd_db_rollback(imp_dbh_t *sth);
extern void dbd_db_destroy(imp_dbh_t *dbh);

extern AV *dbd_st_fetch(imp_sth_t *sth);
extern SV *dbd_st_FETCH_attrib(imp_sth_t *sth, SV *keysv);
extern int dbd_st_STORE_attrib(imp_sth_t *sth, SV *keysv, SV *valuesv);
extern int dbd_st_bind_ph(SV *sth, SV *param, SV *value, SV *attribs, int boolean, int len);
extern int dbd_st_blob_read(SV *sth, int field, long offset, long len, SV *destsv, int destoffset);
extern int dbd_st_execute(imp_sth_t *sth);
extern int dbd_st_finish(imp_sth_t *sth);
extern int dbd_st_prepare(imp_sth_t *sth, char *statement, SV *attribs);
extern void dbd_st_destroy(imp_sth_t *sth);

extern int dbd_ix_setbindnum(imp_sth_t *sth, int items);
extern int dbd_ix_bindsv(imp_sth_t *sth, int idx, SV *val);
extern const char *dbd_ix_module(void);

extern void add_link(Link *link_1, Link *link_n);
extern void delete_link(Link *link_d, void (*function)(void *));
extern void destroy_chain(Link *head, void (*function)(void *));
extern void new_headlink(Link *link);

#endif	/* DBDIMP_H */
