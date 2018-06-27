# Analysis Report 0005 #

## General ##
**Warning Type:** UNINITIALIZED_VALUE  
**Warning Explanation:** The value read from length[_] was never initialized.   
```C 
}
  /* Find largest and smallest lengths in this group */
  minLen = maxLen = length[0];
  for (i = 1; i < symCount; i++) {
```
**File Location:** lib/decompress_bunzip2.c:271  
## History ##
**Introduced By:** TODO  
**Reported Since:** TODO  
**Resolved By:** --  

## Manuel Assesment ##
**Classification:** POSITIVE  
### Rationale ###
```C
static int INIT get_next_block(struct bunzip_data *bd)
{
	struct group_data *hufGroup = NULL;
	int *base = NULL;
	int *limit = NULL;
	int dbufCount, nextSym, dbufSize, groupCount, selector,
		i, j, k, t, runPos, symCount, symTotal, nSelectors, *byteCount;
	unsigned char uc, *symToByte, *mtfSymbol, *selectors;
	unsigned int *dbuf, origPtr;

	dbuf = bd->dbuf;
	dbufSize = bd->dbufSize;
	selectors = bd->selectors;
	byteCount = bd->byteCount;
	symToByte = bd->symToByte;
	mtfSymbol = bd->mtfSymbol;

	/* Read in header signature and CRC, then validate signature.
	   (last block signature means CRC is for whole file, return now) */
	i = get_bits(bd, 24);
	j = get_bits(bd, 24);
	bd->headerCRC = get_bits(bd, 32);
	if ((i == 0x177245) && (j == 0x385090))
		return RETVAL_LAST_BLOCK;
	if ((i != 0x314159) || (j != 0x265359))
		return RETVAL_NOT_BZIP_DATA;
	/* We can add support for blockRandomised if anybody complains.
	   There was some code for this in busybox 1.0.0-pre3, but nobody ever
	   noticed that it didn't actually work. */
	if (get_bits(bd, 1))
		return RETVAL_OBSOLETE_INPUT;
	origPtr = get_bits(bd, 24);
	if (origPtr >= dbufSize)
		return RETVAL_DATA_ERROR;
	/* mapping table: if some byte values are never used (encoding things
	   like ascii text), the compression code removes the gaps to have fewer
	   symbols to deal with, and writes a sparse bitfield indicating which
	   values were present.  We make a translation table to convert the
	   symbols back to the corresponding bytes. */
	t = get_bits(bd, 16);
	symTotal = 0;
	for (i = 0; i < 16; i++) {
		if (t&(1 << (15-i))) {
			k = get_bits(bd, 16);
			for (j = 0; j < 16; j++)
				if (k&(1 << (15-j)))
					symToByte[symTotal++] = (16*i)+j;
		}
	}
	/* How many different Huffman coding groups does this block use? */
	groupCount = get_bits(bd, 3);
	if (groupCount < 2 || groupCount > MAX_GROUPS)
		return RETVAL_DATA_ERROR;
	/* nSelectors: Every GROUP_SIZE many symbols we select a new
	   Huffman coding group.  Read in the group selector list,
	   which is stored as MTF encoded bit runs.  (MTF = Move To
	   Front, as each value is used it's moved to the start of the
	   list.) */
	nSelectors = get_bits(bd, 15);
	if (!nSelectors)
		return RETVAL_DATA_ERROR;
	for (i = 0; i < groupCount; i++)
		mtfSymbol[i] = i;
	for (i = 0; i < nSelectors; i++) {
		/* Get next value */
		for (j = 0; get_bits(bd, 1); j++)
			if (j >= groupCount)
				return RETVAL_DATA_ERROR;
		/* Decode MTF to get the next selector */
		uc = mtfSymbol[j];
		for (; j; j--)
			mtfSymbol[j] = mtfSymbol[j-1];
		mtfSymbol[0] = selectors[i] = uc;
	}
	/* Read the Huffman coding tables for each group, which code
	   for symTotal literal symbols, plus two run symbols (RUNA,
	   RUNB) */
	symCount = symTotal+2;
	for (j = 0; j < groupCount; j++) {
		unsigned char length[MAX_SYMBOLS], temp[MAX_HUFCODE_BITS+1];
		int	minLen,	maxLen, pp;
		/* Read Huffman code lengths for each symbol.  They're
		   stored in a way similar to mtf; record a starting
		   value for the first symbol, and an offset from the
		   previous value for everys symbol after that.
		   (Subtracting 1 before the loop and then adding it
		   back at the end is an optimization that makes the
		   test inside the loop simpler: symbol length 0
		   becomes negative, so an unsigned inequality catches
		   it.) */
		t = get_bits(bd, 5)-1;
		for (i = 0; i < symCount; i++) {
			for (;;) {
				if (((unsigned)t) > (MAX_HUFCODE_BITS-1))
					return RETVAL_DATA_ERROR;

				/* If first bit is 0, stop.  Else
				   second bit indicates whether to
				   increment or decrement the value.
				   Optimization: grab 2 bits and unget
				   the second if the first was 0. */

				k = get_bits(bd, 2);
				if (k < 2) {
					bd->inbufBitCount++;
					break;
				}
				/* Add one if second bit 1, else
				 * subtract 1.  Avoids if/else */
				t += (((k+1)&2)-1);
			}
			/* Correct for the initial -1, to get the
			 * final symbol length */
			length[i] = t+1;
		}
		/* Find largest and smallest lengths in this group */
		minLen = maxLen = length[0];
```
