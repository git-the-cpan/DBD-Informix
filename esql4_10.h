/*
@(#)File:            $RCSfile: esql4_10.h,v $
@(#)Version:         $Revision: 1.8 $
@(#)Last changed:    $Date: 1997/06/02 16:24:26 $
@(#)Purpose:         Function prototypes for ESQL/C Version 4.10
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1992-93,1995-97
@(#)Product:         Informix Database Driver for Perl Version 0.97005 (2000-02-10)
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
static const char esql4_10_h[] = "@(#)$Id: esql4_10.h version /main/8 1997-06-02 16:24:26 $";
#endif	/*lint */
#endif	/*MAIN_PROGRAM */

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include <sqlhdr.h>
#include <sqlda.h>

/* Pre-declare struct value to keep compilers quiet */
struct value;

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

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif	/* ESQL4_10_H */
