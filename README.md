#LRUCache


Your mobile-device’s RAM is limited; and when you hit the limit, you’ll get a memory warning.
Failing to release memory when you receive this warning <em>will crash your app</em>.

<b>Purpose:</b>
&nbsp;&nbsp;&nbsp;&nbsp; LRUCache enhances data-access by storing frequently-used data in memory (cache) and allowing
the cache to purge least-recently-used (LRU) data.

‘MyLRU’ is a proof-of-concept of using LRU (Least Recently Used) cache design pattern.
‘MyLRU’ serializes user-data (NSData) into a NSData object within the in-memory cache layer and  archive and unarchive some of the cache’s contents when memory is limiting.

<b>Modus Operandi:</b>
&nbsp;&nbsp;&nbsp;&nbsp; A dictionary is used to hold your cached data in memory.  There’s a size limit to the memory; so
when anything is added to the cache after it’s full, the least-recently used object (least recently used) should be saved to file (flash memory).

&nbsp;&nbsp;&nbsp;&nbsp; This code also handles memory warnings and write the in-memory cache to flash memory (as files).
All in-memory cache are written to flash memory (files) when the app is closed or
quit or when it enters the background.

<b>Variables:</b>
* A NSMutableDictionary for storing the cache data.
* A NSMutableArray is used to keep track of recently-used items, in chronological order, and an integer that limits the maximum size of this cache.

The ```@synchronized``` directives wrap <em>thread-sensitive</em> portions of the code to allow for thread safety.

A Unit-Testing target is provided.
