/*
 * @(#)dbdimp.h	25.14 96/12/09 14:48:25
 *
 * $Derived-From: dbdimp.h,v 1.5 1995/06/22 00:37:04 timbo Archaic $
 *
 * Copyright (c) 1994,1995  Tim Bunce
 *           (c) 1996       Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

#ifndef DBDIMP_H
#define DBDIMP_H

#define NAMESIZE 19				/* 18 character name plus '\0' */

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

/* Define drh implementor data structure */
struct imp_drh_st
{
	dbih_drc_t      com;		/* MUST be first element in structure   */
	int             max_connections;	/* Maximum concurrent connections */
	int             n_connections;		/* Number of active connections */
	const char     *current_connection;	/* Name of current connection */
};

/* Define dbh implementor data structure */
struct imp_dbh_st
{
	dbih_dbc_t      com;		/* MUST be first element in structure */
	char           *database;	/* Name of database */
	Name            nm_connection;	/* Name of connection */
	Boolean         is_onlinedb;/* Is OnLine Engine */
	Boolean         is_modeansi;/* Is MODE ANSI Database */
	Boolean         is_loggeddb;/* Has transaction log */
	Boolean         autocommit; /* Treat each statement as a transaction? */
	Boolean         autoreport; /* Report all errors when they happen? */
	BlobLocn        blob_bind;	/* Blob binding */
	Sqlca           sqlca;      /* Last SQLCA record for connection */
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
};

extern void dbd_ix_debug _((int n, char *fmt, const char *arg));
extern void dbd_ix_sqlcode _((imp_dbh_t *dbh));
extern void dbd_ix_seterror _((ErrNum rc));

extern void dbd_dr_init _((dbistate_t *dbistate));
extern int dbd_ix_driver _((SV *drh));

extern SV      *dbd_db_FETCH _((SV *dbh, SV *keysv));
extern int dbd_db_STORE _((SV *dbh, SV *keysv, SV *valuesv));
extern int dbd_db_commit _((SV *sth));
extern int dbd_db_disconnect _((SV *dbh));
extern int dbd_db_login _((SV *dbh, char *dbname, char *uid, char *pwd));
extern int dbd_db_rollback _((SV *sth));
extern void dbd_db_destroy _((SV *dbh));

extern AV      *dbd_st_fetch _((SV *sth));
extern SV      *dbd_st_FETCH _((SV *sth, SV *keysv));
extern int dbd_st_STORE _((SV *sth, SV *keysv, SV *valuesv));
extern int dbd_st_bind_ph _((SV *sth, SV *param, SV *value, SV *attribs, int boolean, int len));
extern int dbd_st_blob_read _((SV *sth, int field, long offset, long len, SV *destsv, int destoffset));
extern int dbd_st_execute _((imp_sth_t *sth));
extern int dbd_st_finish _((SV *sth));
extern int dbd_st_prepare _((SV *sth, char *statement, SV *attribs));
extern int dbd_st_rows _((SV *sth));
extern void dbd_st_destroy _((SV *sth));
extern int dbd_ix_immediate _((SV *dbh, char *stmt));

extern int dbd_ix_setbindnum _((imp_sth_t *sth, int items));
extern int dbd_ix_bindsv _((imp_sth_t *sth, int idx, SV *val));
extern int dbd_ix_setconnection _((imp_sth_t *imp_sth));

#if ESQLC_VERSION >= 600
extern void     dbd_ix_disconnect _((char *connection));
extern void     dbd_ix_connect _((char *conn, char *dbase, char *user, char *pass));
#else
extern void     dbd_ix_closedatabase _((void));
extern void     dbd_ix_opendatabase _((char *dbase));
#endif	/* ESQLC_VERSION >= 600 */

#endif	/* DBDIMP_H */
