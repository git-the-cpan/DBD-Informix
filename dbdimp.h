/*
 * @(#)dbdimp.h	52.2 97/03/02 12:57:04
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

enum Boolean
{
	False, True
};

typedef enum State State;		/* Cursor/Statement states */
typedef enum Boolean Boolean;
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
	Boolean         autocommit; 	/* Treat each statement as a transaction? */
	Boolean         autoreport; 	/* Report all errors when they happen? */
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
	imp_dbh_t	   *dbh;		/* Database handle for statement */
	Link            chain;      /* Link in list of statements */
};

extern void dbd_ix_debug _((int n, char *fmt, const char *arg));
extern void dbd_ix_seterror _((ErrNum rc));

extern void dbd_dr_init _((dbistate_t *dbistate));
extern int dbd_ix_driver _((SV *drh));
extern int dbd_dr_disconnectall _((imp_drh_t *));

extern SV *dbd_db_FETCH_attrib _((imp_dbh_t *dbh, SV *keysv));
extern int dbd_db_STORE_attrib _((imp_dbh_t *dbh, SV *keysv, SV *valuesv));
extern int dbd_db_begin _((imp_dbh_t *sth));
extern int dbd_db_commit _((imp_dbh_t *sth));
extern int dbd_db_connect _((imp_dbh_t *dbh, char *dbs, char *uid, char *pwd));
extern int dbd_db_disconnect _((imp_dbh_t *dbh));
extern int dbd_db_rollback _((imp_dbh_t *sth));
extern void dbd_db_destroy _((imp_dbh_t *dbh));

extern AV *dbd_st_fetch _((imp_sth_t *sth));
extern SV *dbd_st_FETCH_attrib _((imp_sth_t *sth, SV *keysv));
extern int dbd_ix_immediate _((imp_dbh_t *dbh, char *stmt));
extern int dbd_st_STORE_attrib _((imp_sth_t *sth, SV *keysv, SV *valuesv));
extern int dbd_st_bind_ph _((SV *sth, SV *param, SV *value, SV *attribs, int boolean, int len));
extern int dbd_st_blob_read _((SV *sth, int field, long offset, long len, SV *destsv, int destoffset));
extern int dbd_st_execute _((imp_sth_t *sth));
extern int dbd_st_finish _((imp_sth_t *sth));
extern int dbd_st_prepare _((imp_sth_t *sth, char *statement, SV *attribs));
extern int dbd_st_rows _((SV *sth));
extern void dbd_st_destroy _((imp_sth_t *sth));

extern int dbd_ix_setbindnum _((imp_sth_t *sth, int items));
extern int dbd_ix_bindsv _((imp_sth_t *sth, int idx, SV *val));
extern int dbd_ix_setconnection _((imp_dbh_t *imp_dbh));

extern const char *dbd_ix_module(void);

#if ESQLC_VERSION >= 600
extern void dbd_ix_disconnect _((char *connection));
extern Boolean dbd_ix_connect _((char *conn, char *dbase, char *user, char *pass));
#else
extern void dbd_ix_closedatabase _((void));
extern Boolean dbd_ix_opendatabase _((char *dbase));
#endif	/* ESQLC_VERSION >= 600 */

#endif	/* DBDIMP_H */
