/*
@(#)File:            esql5_00.h
@(#)Version:         1.9
@(#)Last changed:    96/11/27
@(#)Purpose:         Function prototypes for ESQL/C Versions 5.00..5.07
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1992,1993,1995,1996
@(#)Product:         :PRODUCT:
*/

/*
**	@(#)Informix ESQL/C Version 5.0x ANSI C Function Prototypes
*/

/*
**  Beware:
**  ESQL/C version 5.00 has a 4-argument version of _iqlocate_cursor(),
**  but ESQL/C versions 5.01 and upwards (to 5.07 at least) have a
**  3-argument version of _iqlocate_cursor().
**  You must set ESQLC_VERSION accurately.
*/

#ifndef ESQL5_00_H
#define ESQL5_00_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/* There is a unprototyped declaration of _iqlocate_cursor() in <sqlhdr.h> */
#undef _iqlocate_cursor
#define _iqlocate_cursor _iq_non_existent
#include <sqlhdr.h>
#undef _iqlocate_cursor

#include <sqlda.h>
#include <value.h>

#ifdef MAIN_PROGRAM
#ifndef lint
static const char esql5_00_h[] = "@(#)esql5_00.h	1.9 96/11/27";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#ifdef __STDC__

#ifdef ESQLC_STRICT_PROTOTYPES
/* A non-prototyped declaration for _iqnprep() is emitted by the compiler */
extern _SQCURSOR *_iqnprep(const char *name, char *stmt, short cs_sens);
#else
extern _SQCURSOR *_iqnprep();
#endif /* ESQLC_STRICT_PROTOTYPES */

#if ESQLC_VERSION == 500
extern _SQCURSOR *_iqlocate_cursor(const char *name, int type, int cs, int xx);
#else
extern _SQCURSOR *_iqlocate_cursor(const char *name, int type, int cs_sens);
#endif /* ESQLC_VERSION */

extern int      _iqalloc(char *descname, int occurrence);
extern int      _iqbeginwork(void);
extern int      _iqcdcl(_SQCURSOR *cursor,
                        char *curname,
                        char **cmdtxt,
                        struct sqlda *idesc,
                        struct sqlda *odesc,
                        int flags);
extern int      _iqcddcl(_SQCURSOR *cursor,
                         const char *curname,
                         _SQCURSOR *stmt,
                         int flags);
extern int      _iqcftch(_SQCURSOR *cursor,
                         struct sqlda *idesc,
                         struct sqlda *odesc,
                         char *odesc_name,
                         _FetchSpec *fetchspec);
extern int      _iqclose(_SQCURSOR *cursor);
extern int      _iqcommit(void);
extern int      _iqcopen(_SQCURSOR *cursor,
                         int icnt,
                         struct sqlvar_struct *ibind,
                         struct sqlda *idesc,
                         struct value *ivalues,
                         int useflag);
extern int      _iqcput(_SQCURSOR *cursor,
                        struct sqlda *idesc,
                        char *desc_name);
extern int      _iqcrproc(char *fname);
extern int      _iqdbase(char *db_name, int exclusive);
extern int      _iqdbclose(void);
extern int      _iqdcopen(_SQCURSOR *cursor,
                          struct sqlda *idesc,
                          char *desc_name,
                          char *ivalues,
                          int useflag);
extern int      _iqdealloc(char *desc_name);
extern int      _iqdescribe(_SQCURSOR *cursor,
                            struct sqlda **descp,
                            char *desc_name);
extern int      _iqexecute(_SQCURSOR *cursor,
                           struct sqlda *idesc,
                           char *desc_name,
                           struct value *ivalues);
extern int      _iqeximm(char *stmt);
extern int      _iqexproc(_SQCURSOR *cursor,
                          char **cmdtxt,
                          int icnt,
                          struct sqlvar_struct *ibind,
                          int ocnt,
                          struct sqlvar_struct *obind,
                          int chkind);
extern int      _iqflush(_SQCURSOR *cursor);
extern int      _iqfree(_SQCURSOR *cursor);
extern int      _iqgetdesc(char *desc_name,
                           int sqlvar_num,
                           struct hostvar_struct *hosttab,
                           int xopen_flg);
extern int      _iqprepare(_SQCURSOR *cursor, char *stmt);
extern int      _iqrollback(void);
extern int      _iqsetdesc(char *desc_name,
                           int sqlvar_num,
                           struct hostvar_struct *hosttab,
                           int xopen_flg);
extern int      _iqslct(_SQCURSOR *cursor,
                        char **cmdtxt,
                        int icnt,
                        struct sqlvar_struct *ibind,
                        int ocnt,
                        struct sqlvar_struct *obind,
                        int chkind);
extern int      _iqstmnt(_SQSTMT *scb,
                         char **cmdtxt,
                         int icnt,
                         struct sqlvar_struct *ibind,
                         struct value *ivalues);
extern void     iec_stop(void);
extern int      sqgetdbs(int *ret_fcnt,
                         char **fnames,
                         int fnsize,
                         char *farea,
                         int fasize);
extern int      sqlbreak(void);
extern void     sqldetach(void);
extern void     sqlexit(void);
extern int      sqlstart(void);

#else

extern _SQCURSOR *_iqnprep();
extern _SQCURSOR *_iqlocate_cursor();
extern int      _iqalloc();
extern int      _iqbeginwork();
extern int      _iqcdcl();
extern int      _iqcddcl();
extern int      _iqcftch();
extern int      _iqclose();
extern int      _iqcommit();
extern int      _iqcopen();
extern int      _iqcput();
extern int      _iqcrproc();
extern int      _iqdbase();
extern int      _iqdbclose();
extern int      _iqdcopen();
extern int      _iqdealloc();
extern int      _iqdescribe();
extern int      _iqexecute();
extern int      _iqeximm();
extern int      _iqexproc();
extern int      _iqflush();
extern int      _iqfree();
extern int      _iqgetdesc();
extern int      _iqprepare();
extern int      _iqrollback();
extern int      _iqsetdesc();
extern int      _iqslct();
extern int      _iqstmnt();
extern void     iec_stop();
extern int      sqgetdbs();
extern int      sqlbreak();
extern void     sqldetach();
extern void     sqlexit();
extern int      sqlstart();

#endif	/* __STDC__ */

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif	/* ESQL5_00_H */
