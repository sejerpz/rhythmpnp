Rhythmbox Universal Plug and Play Digital Media Player plugin written in Vala and it's especially targeted to work in pair with [Rygel](http://live.gnome.org/Rygel) UPnP Media Server

![http://rhythmpnp.googlecode.com/svn/wiki/images/rhythmpnp.png](http://rhythmpnp.googlecode.com/svn/wiki/images/rhythmpnp.png)

_Note:_

RhythmPnP it isn't a replacement for the coherence plugin already included in Rhythmbox because it's just the player part and it will not publish your media library on the network.

## Why? ##

I wrote it because I don't need all the rhythmbox coherence plugin functions and worse that plugin never worked on my configuration despite all the tries I've done.

## Download ##

Releases: http://code.google.com/p/rhythmpnp/downloads/list

Source code repository: http://gitorious.org/rhythmpnp/rhythmpnp

## Compile ##

As always:

```
./configure --prefix=/usr
make
make install
```

### Future ###

This plugin does already all what I need, so its development it's **deliberately slow**, but fell free to file enhancement request or better patches ;)


### Contacts ###

You can reach me at _sejerpz at tin dot it_

### Releases ###
_Sun Jun 5 2011:_

> RhythmPnP 0.3.0 released:
    * Ported to RhythmBox 0.13 Plugin API

_Tue Jul 13 2010:_

> RhythmPnP 0.2.1 released:
    * Fixed duration and track number informations

_Tue Jun 29 2010:_

> RhythmPnP 0.2.0 released:
    * Added basic support for Rygel Gst-Launch plugin
    * Improved network interface management using GUPnP ContextManager class

_Sat Jun 26 2010:_

> RhythmPnP 0.1.0 released:
    * Initial release