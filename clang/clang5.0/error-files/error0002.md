## Error 0002 ##
**File Location:** fs/exofs/ore_raid.c  
**Error Message:**
```
fs/exofs/ore_raid.c:77:27: error: fields must have a constant size: 'variable length array in structure' extension will never be supported
                        struct __1_page_stripe _1p_stripes[pages_in_unit];
                                               ^
fs/exofs/ore_raid.c:80:17: error: fields must have a constant size: 'variable length array in structure' extension will never be supported
                        struct page *pages[group_width];
                                     ^
fs/exofs/ore_raid.c:81:17: error: fields must have a constant size: 'variable length array in structure' extension will never be supported
                        struct page *scribble[group_width];
                                     ^
fs/exofs/ore_raid.c:82:9: error: fields must have a constant size: 'variable length array in structure' extension will never be supported
                        char page_is_read[data_devs];
                             ^
1 warning and 4 errors generated.
scripts/Makefile.build:316: recipe for target 'fs/exofs/ore_raid.o' failed
```
