NULL = 

AM_CPPFLAGS = \
	$(RHYTHMPNP_CFLAGS) \
	-include $(CONFIG_HEADER) \
	-I $(top_srcdir)/rb-include/shell \
	-I $(top_srcdir)/rb-include/sources \
	-I $(top_srcdir)/rb-include/rhythmdb \
	-I $(top_srcdir)/rb-include/lib \
	-I $(top_srcdir)/rb-include/widgets \
	$(NULL)

plugindir = $(PLUGINDIR)/rhythmpnp

plugin_LTLIBRARIES = librhythmpnp.la

plugin_in_files = rhythmpnp.rb-plugin

librhythmpnp_la_VALAFLAGS = --vapidir ../vapi --thread --pkg libsoup-2.4 --pkg gupnp-1.0 --pkg gupnp-av-1.0 --pkg gstreamer-0.10 --pkg rb

librhythmpnp_la_SOURCES = \
	main.vala \
	$(NULL)

librhythmpnp_la_LDFLAGS = \
	-module \
	-avoid-version \
	$(NULL)

#not supported by vala integration?!?
#librhythmpnp_la_LIBTOOLFLAGS = --tag=disable-static

librhythmpnp_la_LIBADD = \
	$(RHYTHMPNP_LIBS) \
	$(NULL)

plugin_DATA = $(plugin_in_files:.rb-plugin.in=.rb-plugin)

EXTRA_DIST = \
	$(plugin_in_files) \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

