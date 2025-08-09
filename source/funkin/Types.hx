package funkin;

@:dox(hide)
typedef SingleOrFloat = #if (java || hl || cpp) Single #else Float #end;