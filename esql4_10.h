/*
@(#)File:            esql4_10.h
@(#)Version:         1.5
@(#)Last changed:    96/11/26
@(#)Purpose:         Function prototypes for ESQL/C Version 4.10
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1992,1993,1995,1996
@(#)Product:         :PRODUCT:
*/

/*TABSTOP=4*/

/*
** Function prototypes for functions found in:
** Informix ESQL/C application-engine interface library Version 4.10.
** Same as for Version 4.00 except: sqgetdbs() does not link in 4.10!
** List of names derived from output of "strings $INFORMIXDIR/lib/esqlc"
** iec_stop() is called by WHENEVER ERROR STOP.
*/

#ifndef ESQL4_10_H
#define ESQL4_10_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char esql4_10_h[] = "@(#)esql4_10.h	1.5 96/11/26";
#endif	/*lint */
#endif	/*MAIN_PROGRAM */

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include <sqlhdr.h>
#include <sqlda.h>

#ifdef __STDC__

extern int      _iqbeginwork(void);
extern int      _iqclose(_SQCURSOR *cursor);
extern int      _iqcommit(void);
extern int      _iqcopen(_SQCURSOR *cursor,
                         int icnt,
                         struct sqlvar_struct *ibind,
                         struct sqlda *idesc,
                         struct value *ivalues,
                         int useflag);
extern int      _iqdatabase(char *db_name,
                            int exclusive,
                            int icnt,
                            struct sqlvar_struct *ibind);
extern int      _iqdbclose(void);
extern int      _iqdclcur(_SQCURSOR *cursor,
                          char *curname,
                          char **cmdtxt,
                          int icnt,
                          struct sqlvar_struct *ibind,
                          int ocnt,
                          struct sqlvar_struct *obind,
                          int flags);
extern int      _iqddclcur(_SQCURSOR *cursor,
                           char *curname,
                           int flags);
extern int      _iqdscribe(_SQCURSOR *cursor, struct sqlda **descp);
extern int      _iqeximm(char *stmt);
extern int      _iqflush(_SQCURSOR *cursor);
extern int      _iqfree(_SQCURSOR *cursor);
extern int      _iqftch(_SQCURSOR *cursor,
                        int ocnt,
                        struct sqlvar_struct *obind,
                        struct sqlda *odescriptor,
                        int chkind);
extern int      _iqinsput(_SQCURSOR *cursor,
                          int icnt,
                          struct sqlvar_struct *ibind,
                          struct sqlda *idesc,
                          struct value *ivalues);
extern int      _iqnftch(_SQCURSOR *cursor,
                         int ocnt,
                         struct sqlvar_struct *obind,
                         struct sqlda *odescriptor,
                         int fetch_type,
                         long val,
                         int icnt,
                         struct sqlvar_struct *ibind,
                         struct sqlda *idescriptor,
                         int chkind);
extern int      _iqpclose(_SQCURSOR *cursor);
extern int      _iqpdclcur(_SQCURSOR *cursor,
                           char *cursor_name,
                           int statement_type,
                           char *table_name,
                           char **select_list,
                           char **orderby_list,
                           char **where_text,
                           int icnt,
                           struct sqlvar_struct *ibind,
                           int ocnt,
                           struct sqlvar_struct *obind,
                           int for_update);
extern int      _iqpdelete(_SQCURSOR *cursor);
extern int      _iqpopen(_SQCURSOR *cursor,
                         int icnt,
                         struct sqlvar_struct *ibind,
                         struct sqlda *idesc,
                         struct value *ivalues,
                         int useflag);
extern int      _iqpput(_SQCURSOR *cursor,
                        int icnt,
                        struct sqlvar_struct *ibind,
                        struct sqlda *idesc,
                        struct value *ivalues);
extern int      _iqprepare(_SQCURSOR *cursor, char *stmt);
extern int      _iqpupdate(_SQCURSOR *cursor,
                           char **ucolumn_list,
                           int icnt,
                           struct sqlvar_struct *ibind);
extern int      _iqrollback(void);
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
extern int      _iqxecute(_SQCURSOR *cursor,
                          int icnt,
                          struct sqlvar_struct *ibind,
                          struct sqlda *idesc,
                          struct value *ivalues);
extern int      iec_stop(void);
extern int      sqlbreak(void);
extern int      sqlexit(void);
extern int      sqlstart(void);

#else

extern int      _iqbeginwork();
extern int      _iqclose();
extern int      _iqcommit();
extern int      _iqcopen();
extern int      _iqdatabase();
extern int      _iqdbclose();
extern int      _iqdclcur();
extern int      _iqddclcur();
extern int      _iqdscribe();
extern int      _iqeximm();
extern int      _iqflush();
extern int      _iqfree();
extern int      _iqftch();
extern int      _iqinsput();
extern int      _iqnftch();
extern int      _iqpclose();
extern int      _iqpdclcur();
extern int      _iqpdelete();
extern int      _iqpopen();
extern int      _iqpput();
extern int      _iqprepare();
extern int      _iqpupdate();
extern int      _iqrollback();
extern int      _iqslct();
extern int      _iqstmnt();
extern int      _iqxecute();
extern int      iec_stop();
extern int      sqlbreak();
extern int      sqlexit();
extern int      sqlstart();

#endif	/* __STDC__ */

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif	/* ESQL4_10_H */
