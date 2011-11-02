---=== June 31 2003 ===---

A new feature in mysql.dll Matlab-SQL interface.

Now you can write

	a = mysql('SELECT * FROM mytable','');

instead of writing

	[a,b,c,d,e,f ...] = mysql('SELECT * FROM mytable')

New sintax treats the sole output argument as a structure array with fields corresponding to query result fields.

Example:
           a = mysql('SELECT id,name FROM test','');
The result may be something like this:
                a(1).id = 1     a(1).name = 'Bob'
                a(2).id = 2     a(2).name = 'Marley'
                . . .           . . .

To invoke the new sitax instead of the old one you have to add an empty (actually any) string as the second input argument to a function. In future versions this second argument will probably have some sence, but now it's existense is just a sign for new overload method.

---=== ===---
Arseni Khakhalin
arsenic@1gb.ru