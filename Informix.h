/*
	$Id: Oracle.h,v 1.3 1995/05/25 21:18:56 timbo Rel $
*/

#include <DBIXS.h>		/* installed by the DBI module	*/

/* try uncommenting this line if you get a syntax error on
 *	typedef signed long  sbig_ora;
 * in oratypes.h for Oracle 7.1.3. Don't you just love Oracle!
 */
/* #define signed */

/*#include <oratypes.h> */

/*#include <ocidfn.h>*/

/* #include <msql.h> */

/*
#ifdef CAN_PROTOTYPE
# include <ociapr.h>
#else
# include <ocikpr.h>
#endif
*/


/* Perl5.00[01] should include this if I_MEMORY set but doesn't	*/
/* #ifdef I_MEMORY
#include <memory.h>
#endif */

/* read in our implementation details */

#include "dbdimp.h"


/* end of Oracle.h */
