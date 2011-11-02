#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#ifdef WIN32
#include <windows.h>
#include <winsock.h>
#pragma warning(disable: 4514 4786)
#pragma warning(push, 3)
/* #define VERSION "4.1" */
#endif

#include "mysql.h"	//  Definitions for MySQL client API
#include <mex.h>	//  Definitions for Matlab API

/**********************************************************************
 **********************************************************************
 *
 * Matlab interface to MySQL server
 * Documentation on how to use is in "mysql.m"
 *  Robert Almgren, March 2000
 *
 * Here is a list of the routines in this file:
 *
 *  mexFunction()      Entry point from Matlab, presumably as "mysql"
 *   |
 *   +- getstring()    Extract string from Matlab array
 *   +- hostport()     Get host and port number from combined string
 *   |
 *   +- fix_types()    Some datatype fudges for MySQL C API
 *   +- can_convert()  Whether we can convert a MySQL data type to numeric
 *   +- field2num()    Convert a MySQL data string to a Matlab number
 *   |   |
 *   |   +- daynum()   Convert year,month,day to Matlab date number
 *   |   +- typestr()  Translate MySQL data type into a word, for errors
 *   |
 *   +- fancyprint()   Display query result in nice form
 *
 **********************************************************************

 July 31 2003 - Arseni Khakhalin (arsenic@1gb.ru)
 New syntax added. If user adds an empty string inut argument after the
 main query string ( a = mysql('SELECT ...',''); ) - he get a structure
 array with fields corresponding with query result fields.
 
 Compile Instructions
 
 Windows:
 mex -Ic:/mysql/include mysql.cpp c:/mysql/lib/opt/libmySQL.lib 
 tried adding:
 'c:\Program Files\Microsoft Visual Studio .NET\Vc7\PlatformSDK\lib\wsock32.lib' 'c:\Program Files\Microsoft Visual Studio .NET\Vc7\PlatformSDK\lib\wincsv32.lib'
 to remove dependency on .net dlls, but it didn't work.
 
 Linux:
 mex -O COPTIMFLAGS='-O2 -march=i586 -DNDEBUG' -I/usr/include/mysql \
 /usr/lib/mysql/libmysqlclient.so mysql.cpp 

to build a statically-linked version (more portable):

mex -O COPTIMFLAGS='-O2 -march=i586 -DNDEBUG' -I/usr/include/mysql mysql.cpp /usr/lib/mysql/libmysqlclient.a /usr/lib/libz.a


 **********************************************************************/

/**********************************************************************
 *
 * hostport(s):  Given a host name s, possibly containing a port number
 *    separated by the port separation character (normally ':').
 * Modify the input string by putting a null at the end of
 * the host string, and return the integer of the port number.
 * Check for errors and die with message if can't interpret.
 * Examples:  s="myhost:2515" modifies s to "myhost" and returns 2515.
 *            s="myhost"      leaves s unchanged and returns 0.
 *
 **********************************************************************/

const char portsep = ':';   //  separates host name from port number

static int hostport(char *s)
{
   //  Check whether we got a null string
   if (!s) return 0;

   //   Look for portsep in s
   while ( (*s) && (*s)!=portsep ) s++;

   //  If we are at end of string, then there was no portsep
   if (!(*s))  return 0;

   //  If s points to portsep, then truncate and convert tail
   *s++=0;
   return atoi(s);   // Returns zero in most special cases
}

/**********************************************************************
 *
 * typestr(s):  Readable translation of MySQL field type specifier
 *              as listed in   mysql_com.h
 *
 **********************************************************************/

static const char *typestr( enum_field_types t )
{
   switch(t)
      {
      //  These are considered numeric by IS_NUM() macro
      case FIELD_TYPE_DECIMAL:      return "decimal";
      case FIELD_TYPE_TINY:         return "tiny";
      case FIELD_TYPE_SHORT:        return "short";
      case FIELD_TYPE_LONG:         return "long";
      case FIELD_TYPE_FLOAT:        return "float";
      case FIELD_TYPE_DOUBLE:       return "double";
      case FIELD_TYPE_NULL:         return "null";
      case FIELD_TYPE_LONGLONG:     return "longlong";
      case FIELD_TYPE_INT24:        return "int24";
      case FIELD_TYPE_YEAR:         return "year";
      case FIELD_TYPE_TIMESTAMP:    return "timestamp";

      //  These are not considered numeric by IS_NUM()
      case FIELD_TYPE_DATE:         return "date";
      case FIELD_TYPE_TIME:         return "time";
      case FIELD_TYPE_DATETIME:     return "datetime";
      case FIELD_TYPE_NEWDATE:      return "newdate";     // not in manual
      case FIELD_TYPE_ENUM:         return "enum";
      case FIELD_TYPE_SET:          return "set";
      case FIELD_TYPE_TINY_BLOB:    return "tiny_blob";
      case FIELD_TYPE_MEDIUM_BLOB:  return "medium_blob";
      case FIELD_TYPE_LONG_BLOB:    return "long_blob";
      case FIELD_TYPE_BLOB:         return "blob";
      case FIELD_TYPE_VAR_STRING:   return "var_string";
      case FIELD_TYPE_STRING:       return "string";

      default:                      return "unknown";
      }
}

/**********************************************************************
 *
 * fancyprint():  Print a nice display of a query result
 *     We assume the whole output set is already stored in memory,
 *     as from mysql_store_result(), just so that we can get the
 *     number of rows in case we need to clip the printing.
 *     In any case, we make only one pass through the data.
 *
 *     If the number of rows in the result is greater than NROWMAX,
 *     then we print only the first NHEAD and the last NTAIL.
 *     NROWMAX must be greater than NHEAD+NTAIL, normally at least
 *     2 greater to allow the the extra information
 *     lines printed when we clip (ellipses and total lines).
 *
 *     Display null elements as empty
 *
 **********************************************************************/

const char *contstr = "...";  //  representation of missing rows
const int contstrlen = 3;     //  length of above string
const int NROWMAX = 40;       //  max number of rows to print w/o clipping
const int NHEAD = 10;         //  number of rows to print at top if we clip
const int NTAIL = 10;         //  number of rows to print at end if we clip

static void fancyprint( MYSQL_RES *res )
{
   unsigned long nrow = (unsigned long)mysql_num_rows(res);
   unsigned long nfield = mysql_num_fields(res);

   bool clip = ( nrow > NROWMAX );

   MYSQL_FIELD *f = mysql_fetch_fields(res);

   /************************************************************************/
   //  Determine column widths, and format strings for printing

   //  Find the longest entry in each column header,
   //    and over the rows, using MySQL's max_length
   unsigned long *len = (unsigned long *) mxMalloc( nfield * sizeof(unsigned long) );
   { for ( unsigned long j=0 ; j<nfield ; j++ )
      { len[j] = strlen(f[j].name);
        if ( f[j].max_length > len[j] ) len[j] = f[j].max_length; }}

   //  Compare to the continuation string length if we will clip
   if (clip)
      { for ( unsigned long j=0 ; j<nfield ; j++ )
         { if ( contstrlen > len[j] )  len[j] = contstrlen; }}

   //  Construct the format specification for printing the strings
   char **fmt = (char **) mxMalloc( nfield * sizeof(char *) );
   { for ( unsigned long j=0 ; j<nfield ; j++ )
      { fmt[j] = (char *) mxCalloc( 10, sizeof(char) );
        sprintf(fmt[j],"  %%-%ds ",len[j]); }}

   /************************************************************************/
   //  Now print the actual data

   mexPrintf("\n");

   //  Column headers
   { for ( unsigned long j=0 ; j<nfield ; j++ )  mexPrintf( fmt[j], f[j].name ); }
   mexPrintf("\n");

   //  Fancy underlines
   { for ( unsigned long j=0 ; j<nfield ; j++ )
      { mexPrintf(" +");
        for ( unsigned long k=0 ; k<len[j] ; k++ )  mexPrintf("-");
        mexPrintf("+"); }}
   mexPrintf("\n");

   //  Print the table entries
   if (nrow<=0) mexPrintf("(zero rows in result set)\n");
   else
   {
   if (!clip)    //  print the entire table
      {
      mysql_data_seek(res,0);
      for ( unsigned long i=0 ; i<nrow ; i++ )
        { MYSQL_ROW row = mysql_fetch_row(res);
          if (!row)
            { mexPrintf("Printing full table data from row %d\n",i+1);
              mexErrMsgTxt("Internal error:  Failed to get a row"); }
          for ( unsigned long j=0 ; j<nfield ; j++ )
               mexPrintf( fmt[j], ( row[j] ? row[j] : "" ) );
          mexPrintf("\n"); }
      }
   else          //  print half at beginning, half at end
      {
      mysql_data_seek(res,0);
      { for ( int i=0 ; i<NHEAD ; i++ )
         { MYSQL_ROW row = mysql_fetch_row(res);
           if (!row)
             { mexPrintf("Printing head table data from row %d\n",i+1);
               mexErrMsgTxt("Internal error:  Failed to get a row"); }
           for ( unsigned long j=0 ; j<nfield ; j++ )
               mexPrintf( fmt[j], ( row[j] ? row[j] : "" ) );
           mexPrintf("\n"); }}
      { for ( unsigned long j=0 ; j<nfield ; j++ ) mexPrintf(fmt[j],contstr); }
      mexPrintf("\n");
      mysql_data_seek( res, nrow - NTAIL );
      { for ( int i=0 ; i<NTAIL ; i++ )
         { MYSQL_ROW row = mysql_fetch_row(res);
           if (!row)
             { mexPrintf("Printing tail table data from row %d",nrow-NTAIL+i+1);
               mexErrMsgTxt("Internal error:  Failed to get a row"); }
           for ( unsigned long j=0 ; j<nfield ; j++ )
               mexPrintf( fmt[j], ( row[j] ? row[j] : "" ) );
           mexPrintf("\n"); }}
      mexPrintf("(%d rows total)\n",nrow);
      }
   }
   mexPrintf("\n");

   // These should be automatically freed when we return to Matlab,
   //  but just in case ...
   mxFree(len);  mxFree(fmt);
}

/**********************************************************************
 *
 * field2num():  Convert field in string format to double number
 *
 **********************************************************************/

const double NaN = mxGetNaN();         //  Matlab NaN for null values
const double secinday = 24.*60.*60.;   //  seconds in one day

//==============================================
//  year,month,day --> serial date number, based on Matlab's own algorithm

const int cummonday[2][12] =
            { {  0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 },
              {  0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335 } };

inline int cl( int y, int n )  { return ((y-1)/n)+1; }  // ceil(y/n)

static int daynum( int yr, int mon, int day )
{
   //  This is exactly Matlab's formula
   int leap = ( !(yr%4) && (yr%100) ) | !(yr%400);
   return 365*yr + cl(yr,4) - cl(yr,100) + cl(yr,400)
         + cummonday[leap][mon-1] + day;
}

//================================================

static bool can_convert( enum_field_types t )
{
   return ( IS_NUM(t)
      || ( t == FIELD_TYPE_DATE )
      || ( t == FIELD_TYPE_TIME )
      || ( t == FIELD_TYPE_DATETIME ) );
}

static double field2num( const char *s, enum_field_types t )
{
   if (!s) return NaN;  // MySQL null -- nothing there

   if ( IS_NUM(t) )
      {
      double val=NaN;
      if ( sscanf(s,"%lf",&val) != 1 )
         { mexPrintf("Unreadable value \"%s\" of type %s\n",s,typestr(t));
           return NaN; }
      return val;
      }
   else if ( t == FIELD_TYPE_DATE )
      {
      int yr, mon, day;
      if ( sscanf(s,"%4d-%2d-%2d",&yr,&mon,&day) != 3
            || yr<1000 || yr>=3000 || mon<1 || mon>12 || day<1 || day>31 )
         { mexPrintf("Unreadable value \"%s\" of type %s\n",s,typestr(t));
           return NaN; }
      return (double) daynum(yr,mon,day);
      }
   else if ( t == FIELD_TYPE_TIME )
      {
      int hr, min, sec;
      if ( sscanf(s,"%2d:%2d:%2d",&hr,&min,&sec) != 3
               || min>60 || sec>60 )
         { mexPrintf("Unreadable value \"%s\" of type %s\n",s,typestr(t));
           return NaN; }
      return (sec+60*(min+60*hr))/secinday;
      }
   else if ( t == FIELD_TYPE_DATETIME )
      {
      int yr, mon, day, hr, min, sec;
      if ( sscanf(s,"%4d-%2d-%2d %2d:%2d:%2d",&yr,&mon,&day,&hr,&min,&sec) != 6
            || yr<1000 || yr>=3000 || mon<1 || mon>12 || day<1 || day>31
            || min>60 || sec>60 )
         { mexPrintf("Unreadable value \"%s\" of type %s\n",s,typestr(t));
           return NaN; }
      return ((double) daynum(yr,mon,day))
                    + ((sec+60*(min+60*hr))/secinday );
      }
   else
      {
      mexPrintf("Tried to convert \"%s\" of type %s to numeric\n",s,typestr(t));
      mexErrMsgTxt("Internal inconsistency");
      }
}

/**********************************************************************
 *
 * fix_types():   I have seen problems with the MySQL C API reporting
 *   types inconsistently. Returned data value from fields of type
 *   "date" or "time" has type set appropriately to DATE, TIME, etc.
 *   However, if any operation is performed on such data, even something
 *   simple like max(), then the result can sometimes be reported as the
 *   generic type STRING. The developers say this is forced by the SQL
 *   standard but to me it seems strange.
 *
 *   This function looks at the actual result data returned. For each
 *   column that is reported as type STRING, we see if we can make a
 *   more precise classification as DATE, TIME, or DATETIME.
 *
 *   For fields of type STRING, we look at the length, then content
 *    length = 8, 9, or 10:  can be time as HH:MM:SS, HHH:MM:SS, or HHHH:MM:SS
 *    length = 10:           can be date in form YYYY:MM:DD
 *    length = 19:           can be datetime in form YYYY:MM:DD HH:MM:SS
 *
 **********************************************************************/

static void fix_types( MYSQL_FIELD *f, MYSQL_RES *res )
{
   if (!res)    //  This should never happen
      mexErrMsgTxt("Internal error:  fix_types called with res=NULL");

   unsigned long nrow = (unsigned long)mysql_num_rows(res), nfield=mysql_num_fields(res);
   if (nrow<1) return;  // nothing to look at, nothing to fix

   bool *is_unknown = (bool *) mxMalloc( nfield * sizeof(bool) );
   int n_unknown=0;   //  count number of fields of unknown type
   { for ( unsigned long j=0 ; j<nfield ; j++ )
      { is_unknown[j] = ( f[j].type==FIELD_TYPE_STRING
               && ( f[j].length==8 || f[j].length==9 || f[j].length==10
                     || f[j].length==19 ) );
        if (is_unknown[j])  n_unknown++; }}

//mexPrintf("Starting types:");
//{ for ( int j=0 ; j<nfield ; j++ )
//      mexPrintf("  %s(%d)%s", typestr(f[j].type), f[j].length,
//                  ( is_unknown[j] ? "?" : "" ) ); }
//mexPrintf("\n");

   //  Look at successive rows as long as some columns are still unknown
   //  We go through columns only to find the first non-null data value.
   mysql_data_seek(res,0);
   { for ( unsigned long i=0 ; n_unknown>0 && i<nrow ; i++ )
      {
      MYSQL_ROW row = mysql_fetch_row(res);
      if (!row)
        { mexPrintf("Scanning row %d for type identification\n",i+1);
          mexErrMsgTxt("Internal error in fix_types():  Failed to get a row"); }

//mexPrintf("  row[%d]:",i+1);
//{ for ( int j=0 ; j<nfield ; j++ )
//      mexPrintf("  \"%s\"%s", ( row[j] ? row[j] : "NULL" ),
//               ( is_unknown[j] ? "?" : "" ) ); }
//mexPrintf("\n");

      //  Look at each field to see if we can extract information
      for ( unsigned long j=0 ; j<nfield ; j++ )
         {
         //  If this column is still a mystery, and if there is data here,
         //    then try extracting a date and/or time out of it
         if ( is_unknown[j] && row[j] )
         {
         int yr, mon, day, hr, min, sec;

         if ( f[j].length==19
                 && sscanf(row[j],"%4d-%2d-%2d %2d:%2d:%2d",
                                       &yr,&mon,&day,&hr,&min,&sec) == 6
            && yr>=1000 && yr<3000 && mon>=1 && mon<=12 && day>=1 && day<=31
               && min<=60 && sec<=60 )
            f[j].type = FIELD_TYPE_DATETIME;

         else if ( f[j].length==10
                 && sscanf(row[j],"%4d-%2d-%2d",&yr,&mon,&day) == 3
            && yr>=1000 && yr<3000 && mon>=1 && mon<=12 && day>=1 && day<=31 )
            f[j].type = FIELD_TYPE_DATE;

         else if ( ( f[j].length==8 || f[j].length==9 || f[j].length==10 )
            && sscanf(row[j],"%d:%2d:%2d",&hr,&min,&sec) == 3
               && min<=60 && sec<=60 )
            f[j].type = FIELD_TYPE_TIME;

         //  If the tests above failed, then the type is not date or time;
         //  it really is a string of unknown type.
         //  Whether the tests suceeded or failed, it is no longer a mystery.
         is_unknown[j]=false;  n_unknown--;
         }}
      }}

//mexPrintf("  Ending types:");
//{ for ( int j=0 ; j<nfield ; j++ )
//      mexPrintf("  %s(%d)%s", typestr(f[j].type), f[j].length,
//               ( is_unknown[j] ? "?" : "" ) ); }
//mexPrintf("\n");

   mxFree(is_unknown);  // should be automatically freed, but still...
}

/**********************************************************************
 *
 * getstring():   Extract string from a Matlab array
 *    (Space allocated by mxCalloc() should be freed by Matlab
 *     when control returns out of the MEX-function.)
 *   This is based on an original by Kimmo Uutela
 *
 **********************************************************************/

static char *getstring(const mxArray *a)
{
   int llen = mxGetM(a)*mxGetN(a)*sizeof(mxChar) + 1;
   char *c = (char *) mxCalloc(llen,sizeof(char));
   if (mxGetString(a,c,llen))
      mexErrMsgTxt("Can\'t copy string in getstring()");
   return c;
}

/**********************************************************************
 *
 * mysql():  Execute the actual action
 *
 *  Which action we perform is based on the first input argument,
 *  which must be present and must be a character string:
 *    'open', 'close', 'use', 'status', or a legitimate MySQL query.
 *
 *  This version does not permit binary characters in query string,
 *  since the query is converted to a C null-terminated string.
 *
 *  If no output argument is given, then information is displayed.
 *  If an output argument is given, then we operate silently, and
 *     return status information.
 *
 **********************************************************************/

extern "C" void mexFunction(int nlhs, mxArray *plhs[],
		 int nrhs, const mxArray *prhs[]);

void mexFunction(int nlhs, mxArray *plhs[],
		 int nrhs, const mxArray *prhs[])
{
   /*********************************************************************/
   //  Check that the arguments are all character strings
   bool all_are_char=true;
   { for ( int j=0 ; j<nrhs ; j++ )
      { if (!mxIsChar(prhs[j]))  {  all_are_char=false; break; }}}
   if ( nrhs<1 || !all_are_char )
      { mexPrintf("Usage:  %s( command, [ host, user, password ] )\n",
               mexFunctionName());
        mexErrMsgTxt("No numeric values"); }

   /*********************************************************************/
   //  Set up the variables for maintaining the connection
   static MYSQL *conn=NULL;     //  let MySQL alloc space for connection info
   static bool isopen=false;    //  whether we believe connection is open
      /*
       *  isopen gets set to true when we execute an "open"
       *  isopen gets set to false when either we execute a "close"
       *                        or when a ping or status fails
       *   We do not set it to false when a normal query fails;
       *   this might be due to the server having died, but is much
       *   more likely to be caused by an incorrect query.
       */

   /*********************************************************************/
   //  Parse the result based on the first argument

   char *query=getstring(prhs[0]);
   if (!strcmp(query,"open"))
      {
      //  Close connection if it is open
      if (isopen)  { mysql_close(conn);   isopen=false;  conn=NULL; }

      //  Extract information from input arguments
      char *host=NULL;   if (nrhs>=2)  host = getstring(prhs[1]);
      char *user=NULL;   if (nrhs>=3)  user = getstring(prhs[2]);
      char *pass=NULL;   if (nrhs>=4)  pass = getstring(prhs[3]);
      int port = hostport(host);  // returns zero if there is no port

      if (nlhs<1)
         { mexPrintf("Connecting to  host=%s", (host) ? host : "localhost" );
           if (port) mexPrintf("  port=%d",port);
           if (user) mexPrintf("  user=%s",user);
           if (pass) mexPrintf("  password=%s",pass);
           mexPrintf("\n"); }

      //  Establish and test the connection
      //  If this fails, then conn is still set, but isopen stays false
      if (!(conn=mysql_init(conn)))
           mexErrMsgTxt("Couldn\'t initialize MySQL connection object");
      if (!mysql_real_connect( conn, host, user, pass, NULL,port,NULL,0 ))
         mexErrMsgTxt(mysql_error(conn));
      const char *c = mysql_stat(conn);
      if (c)  { if (nlhs<1) mexPrintf("%s\n",c); }
      else    mexErrMsgTxt(mysql_error(conn));
      isopen=true;

      //  Now we are OK -- if he wants output, give him a 1
      if (nlhs>=1)
         { if (!( plhs[0] = mxCreateDoubleMatrix( 1, 1, mxREAL ) ))
               mexErrMsgTxt("Unable to create matrix for output");
           double *pr=mxGetPr(plhs[0]);
           *pr=1.; }
      }

   else if (!strcmp(query,"close"))
      { if (isopen) { mysql_close(conn);  isopen=false;  conn=NULL; } }

   else if ( !strcmp(query,"use") || !strncmp(query,"use ",4) )
      { if (!isopen)  { mexPrintf("Not connected\n");  return; }
        char *db=NULL;
        if (!strcmp(query,"use"))
            { if (nrhs>=2) db=getstring(prhs[1]);
              else         mexErrMsgTxt("Must specify a database to use"); }
        else if (!strncmp(query,"use ",4))
            { db = query + 4;
              while ( *db==' ' || *db=='\t' ) db++; }
        else
            mexErrMsgTxt("How did we get here?  Internal logic error!");
        if (mysql_select_db(conn,db))  mexErrMsgTxt(mysql_error(conn));
        if (nlhs<1) mexPrintf("Current database is \"%s\"\n",db); }

   else if (!strcmp(query,"status"))
      {
      if (nlhs<1)
         {
         if (!isopen)  { mexPrintf("Not connected\n");  return; }
         if (mysql_ping(conn))
            { isopen=false;   mexErrMsgTxt(mysql_error(conn)); }
         mexPrintf("Connected to %s   Server version: %s   Client version: %s\n",
            mysql_get_host_info(conn),
            mysql_get_server_info(conn), mysql_get_client_info() );
         const char *c=mysql_stat(conn);
         if (c)  mexPrintf("%s\n",c);
         else    { isopen=false;  mexErrMsgTxt(mysql_error(conn)); }
         }
      else
         {
         if (!( plhs[0] = mxCreateDoubleMatrix( 1, 1, mxREAL ) ))
           mexErrMsgTxt("Unable to create matrix for output");
         double *pr=mxGetPr(plhs[0]);   *pr=0.;
         if (!isopen)             {                *pr=1.; return; }
         if (mysql_ping(conn))    { isopen=false;  *pr=2.; return; }
         if (!mysql_stat(conn))   { isopen=false;  *pr=3.; return; }
         }
      }
   else
      {
      //  Check that we have a valid connection
      if (!isopen) mexErrMsgTxt("No connection open");
      if (mysql_ping(conn))
         { isopen=false; mexErrMsgTxt(mysql_error(conn)); }

      //  Execute the query (data stays on server)
      if (mysql_query(conn,query))
         { mexErrMsgTxt(mysql_error(conn)); }

      //  Download the data from server into our memory
      //     We need to be careful to deallocate res before returning.
      //  Matlab's allocation routines return instantly if there is not
      //  enough free space, without giving us time to dealloc res.
      //  This is a potential memory leak but I don't see how to fix it.
      MYSQL_RES *res = mysql_store_result(conn);

      //  As recommended in Paul DuBois' MySQL book (New Riders, 1999):
      //  A NULL result set after the query can indicate either
      //    (1) the query was an INSERT, DELETE, REPLACE, or UPDATE, that
      //        affect rows in the table but do not return a result set; or
      //    (2) an error, if the query was a SELECT, SHOW, or EXPLAIN
      //        that should return a result set but didn't.
      //  Distinguish between the two by checking mysql_field_count()
      //  We return in either case, either correctly or with an error
      if (!res)
         {
         if (!mysql_field_count(conn))
            { unsigned long nrows = (unsigned long)mysql_affected_rows(conn);
              if (nlhs<1)
               { mexPrintf("%u rows affected\n",nrows);
                 return; }
              else
               { if (!( plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL) ))
                   mexErrMsgTxt("Unable to create numeric matrix for output");
                 *(mxGetPr(plhs[0])) = (double) nrows;
                 return; }}
         else
            mexErrMsgTxt(mysql_error(conn));
         }

      unsigned long nrow = (unsigned long)mysql_num_rows(res), nfield=mysql_num_fields(res);

      //  If he didn't ask for any output (nlhs=0),
      //       then display the output and return
      if ( nlhs<1 )
         { fancyprint(res);
           mysql_free_result(res);
           return; }

      //  If we are here, he wants output
      //  He must give exactly the right number of output arguments
      // ars: or use another syntax (see below)
      if( nrhs==1 ) {
				// If there're no additional parameters it works like it worked for years
				if ( nlhs != nfield ){
					mysql_free_result(res);
					mexPrintf("You specified %d output arguments, "
										"and got %d columns of data\n",nlhs,nfield);
					mexPrintf("You have 2 choices:\n1) You may use %d output arguments\n",nfield);
					mexPrintf("2) Or you may use 1 output argument and invoke a struct-output mode\n"
										"by adding a second empty-string input argument (see help)\n");
					mexErrMsgTxt("Syntax error"); }
				
				//  Fix the column types to fix MySQL C API sloppiness
				MYSQL_FIELD *f = mysql_fetch_fields(res);
				fix_types( f, res );
				
				//  Create the Matlab arrays for output
				double **pr = (double **) mxMalloc( nfield * sizeof(double *) );
				for ( unsigned long j=0 ; j<nfield ; j++ ){
					if ( can_convert(f[j].type) ){
						if (!( plhs[j] = mxCreateDoubleMatrix( nrow, 1, mxREAL ) )){
							mysql_free_result(res);
							mexErrMsgTxt("Unable to create numeric matrix for output"); }
						pr[j] = mxGetPr(plhs[j]); 
					}else{ 
						if (!( plhs[j] = mxCreateCellMatrix( nrow, 1 ) )){
							mysql_free_result(res);
							mexErrMsgTxt("Unable to create cell matrix for output"); 
						}
						pr[j] = NULL;
					}
				}
				
				//  Load the data into the cells
				mysql_data_seek(res,0);
				for ( unsigned long i=0 ; i<nrow ; i++ ){
					MYSQL_ROW row = mysql_fetch_row(res);
					if (!row)
						{ mexPrintf("Scanning row %d for data extraction\n",i+1);
						mexErrMsgTxt("Internal error:  Failed to get a row"); }
					for ( unsigned long j=0 ; j<nfield ; j++ ){
						if (can_convert(f[j].type)){
							pr[j][i] = field2num(row[j],f[j].type);
						}else{
							mxArray *c = mxCreateString(row[j]);
							mxSetCell(plhs[j],i,c);
						}
					}
				}
			}else{
				/* mexPrintf("Test zone. Be careful!\n"); */
				/* If there are any additional parameters - user needs structured output */
				
				if ( nlhs > 1 )	{
					mysql_free_result(res);
					mexPrintf("You used %d output arguments.\n",nlhs);
					mexErrMsgTxt("In this syntax you must use only one output argument.");
				}
				
				MYSQL_FIELD *fields = mysql_fetch_fields(res);
				fix_types( fields, res );
				int ndims[2]; // Size of  the output structure array
				ndims[0] = nrow;
				ndims[1] = 1;
				
				double **pr = new double *[ nfield*nrow ]; // Numerical values storage
				
				// Prepare fields list
				char** fieldlist = new char*[ nfield ];
				for ( unsigned long j=0; j<nfield ; j++) {
					fieldlist[j] = new char[strlen(fields[j].name) + 1];
					fieldlist[j] = fields[j].name;
					/* pr[j] = new double *[ nrow ]; */
				}
				
				// Create the Matlab array for output
				if (!( plhs[0] = mxCreateStructArray (2, ndims, nfield, (const char**)fieldlist ))) {
					mysql_free_result(res);
					mexErrMsgTxt("Unable to create structure matrix for output");
				}
				
				// Load the data into the cells
				// 2003.09.09 RFD: added following line to fix missing row bug.
				mysql_data_seek(res,0);
				for ( unsigned long i=0 ; i<nrow ; i++ ) {
					MYSQL_ROW row = mysql_fetch_row(res);
					if (!row) {
						mexPrintf("Scanning row %d for data extraction: FAILED TO GET ROW!\n",i+1);
						//mexErrMsgTxt("Error: Failed to get a row");	
					} else { 
						for ( unsigned long j=0; j<nfield ; j++) {
							/* mexPrintf(":: I= %d :: J= %d \n",i,j); */
							if ( can_convert(fields[j].type) ) {
								mxArray* out_double = mxCreateDoubleMatrix(1,1,mxREAL);
								pr[j*nrow+i] = mxGetPr(out_double);
								*pr[j*nrow+i] = field2num(row[j],fields[j].type);
								/* mexPrintf("Value [ %g ] ==> [ %d ]\n",*pr[j*nrow+i],pr[j*nrow+i]); */
								mxSetField(plhs[0],i,fields[j].name,out_double);
							} else {
								//*pr[j*nrow+i] = NULL;
								mxArray *c = mxCreateString(row[j]);
								/* mexPrintf(fields[j].name); mexPrintf(" - ");
									 mexPrintf(row[j]); mexPrintf("\n"); */
 mxSetField(plhs[0],i,fields[j].name,c);
							}
						}
					}
				}

				delete fieldlist;
				delete pr;
			}
			
			mysql_free_result(res);
			}
}
