# AntiRot
AntiRot is my personal take on a simple SHA256 file corruption checker. It scans a directory tree and builds a JSON blob of SHA256 hashes for each file. Although I think the risk of bit rot and unexpected corruption are unlikely, I scared myself enough into building this so that can check for it. ZFS and btrfs weren't good immediate options.

There are a few great solutions out there to solve this problem already, such as [shatag](https://bitbucket.org/maugier/shatag), [cshatag](https://github.com/rfjakob/cshatag), and [chkbit](https://github.com/laktak/chkbit)...but none of them does quite what I want. I needed a solution that satisfied the following criteria:

* Executable on Synology's DSM, my NAS platform of choice, with minimal effort (i.e. cross-compiling) required
* Does not link OpenSSL
* Does not pollute directory structure or extended attributes

I chose Ruby because I already have [a Ruby interpreter on my Synology box](https://www.synology.com/en-us/dsm/packages/Ruby). Ruby's standard libaries include directory traversal, digesting, and JSON parsing.

One notable difference between other tools and this one: AntiRot assumes that a file at a given path will never be changed. That solves the moving problem (a file moved is assumed not to be corrupt, instead simply a new file), as long as you run AntiRot frequently enough. If a file becomes corrupted, and is then moved, it won't be detected.