urlview
=======

"urlview.pl" clone written in Shell

Usage
-----

$ urlview.sh < foo/links.txt

$ lynx -source http://localhost:631 |urlview.sh


Mutt integration
----------------

I'm using this script for handling links in e-mails while using Mutt.

.muttrc:
```
macro index,pager,attach,compose \Cb \
 "<enter-command>set my_pipe_decode=\$pipe_decode; set pipe_decode=yes<Enter>\
<pipe-message>~/bin/urlview.sh<Enter>\
<enter-command>set pipe_decode=\$my_pipe_decode; unset my_pipe_decode<Enter>" \
 "Extract URLs out of a message"
```

Then in Mutt, press CTRL+b in the index, page, attach, or compose menu.
