# FLCAD Engineering Language 1.0

FEL is the universal declarative engineering layer. UI, AI, Mobile, Desktop, Cloud and plugins describe intent as FEL; only the runtime executes registered effects.

The Alpha grammar supports commands, `->` pipelines, `LET`/`CONST`/`VAR`, numeric/string/boolean expressions, function calls, `IF/ELSE`, `WHILE`, `RETURN`, `BREAK` and `CONTINUE`. Keywords are case-insensitive. Comments begin with `#` or `//`.

Example:

```fel
SELECT REGION "FLANGE"
-> SHRINK REGION 1
-> SMOOTH REGION 1
-> SAVE PROJECT
```

Physical millimeter border offsets require a scaled-mesh adapter. The Alpha commands use topological rings and make this explicit in their command names/arguments.
