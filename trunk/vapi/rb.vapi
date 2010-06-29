[CCode (cprefix = "RB", lower_case_cprefix = "rb_")]
namespace RB {
	[CCode (cheader_filename = "rb-shell.h", ref_function = "g_object_ref", unref_function = "g_object_unref")]
	public class Shell : GLib.Object
	{
		[CCode (cname = "rb_shell_get_type")]
		public static GLib.Type get_type ();

		[CCode (cname = "rb_shell_get_player")]
		public unowned ShellPlayer get_player ();

		[CCode (cname = "rb_shell_get_ui_manager")]
		public unowned GLib.Object get_ui_manager();
		
		[NoAccessorMethod]
		public RhythmDB.DB db { owned get; }
		
		public void append_source (RB.Source source, RB.Source? parent = null);
		
		public void register_entry_type_for_source(RB.Source source, RhythmDB.EntryType entry_type);
	}

	[CCode (cheader_filename = "rb-plugin.h")]
	public abstract class Plugin : GLib.Object {
		[CCode (cname = "rb_plugin_get_type")]
		public static GLib.Type get_type ();

		[CCode (cname = "rb_plugin_activate")]
		public abstract void activate (RB.Shell shell);
		
		[CCode (cname = "rb_plugin_deactivate")]
		public abstract void deactivate (RB.Shell shell);

		[CCode (cname = "rb_plugin_is_configurable")]
		public virtual bool is_configurable ();
		
		[CCode (cname = "rb_plugin_create_configure_dialog")]
		public virtual Gtk.Widget create_configure_dialog ();
		
		[CCode (cname = "rb_plugin_find_file")]
		public virtual unowned string find_file (string file);
	}

	[CCode (cheader_filename = "rb-player-gst-filter.h")]
	public interface PlayerGstFilter : GLib.Object {
		[CCode (cname = "rb_player_gst_filter_add_filter")]
		public virtual bool add_filter(Gst.Element e);

		[CCode (cname = "rb_player_gst_filter_remove_filter")]
		public virtual bool remove_filter(Gst.Element e);
	}

	public class Source : Gtk.HBox
	{
		[NoAccessorMethod]
		public string name {
			owned get; set;
		}
		
		[NoAccessorMethod]
		public Gdk.Pixbuf icon {
			get; set;
		}
		
		[NoAccessorMethod]
		public RB.Shell shell {
			owned get; construct set;
		}
		
		[NoAccessorMethod]
		public bool visibility {
			get; set;
		}
		
		[NoAccessorMethod]
		public RhythmDB.EntryType entry_type {
			get; construct set;
		}
		
		[NoAccessorMethod]
		public RB.Plugin plugin {
			get; construct set;
		}
		
		[NoAccessorMethod]
		public RB.SourceGroup source_group {
			get; construct set;
		}
		
		[HasEmitter]
		public virtual signal void notify_status_changed ();
		
		//[CCode(cname="impl_activate")]
		public virtual void impl_activate ();
		
		//[CCode(cname="impl_deactivate")]
		public virtual void impl_deactivate ();
		
		public virtual void impl_get_status (out string text, out string progress_text, out float progress);
		
		public virtual void delete_thyself ();
		
		public virtual RB.EntryView impl_get_entry_view ();
		
		public virtual bool impl_can_browse ();
		
/*		
		public SearchType search_type {
			get; construct set;
		}
*/
	}

	[CCode(cheader_filename="rb-source-group.h")]	
	public class SourceGroup
	{
		[CCode (cname = "RB_SOURCE_GROUP_LIBRARY")]
		public static SourceGroup library;
		
		[CCode (cname = "RB_SOURCE_GROUP_PLAYLISTS")]
		public static SourceGroup playlists;
		
		[CCode (cname = "RB_SOURCE_GROUP_DEVICES")]
		public static SourceGroup devices;
		
		[CCode (cname = "RB_SOURCE_GROUP_SHARED")]
		public static SourceGroup shared;
		          
		[CCode (cname = "RB_SOURCE_GROUP_STORES")]
		public static SourceGroup stores;
	}
	
	[CCode(cheader_filename="rb-browser-source.h")]
	public class BrowserSource : RB.Source
	{
		
	}

	[CCode(cheader_filename="rb-streaming-source.h")]
	public class StreamingSource : RB.Source
	{
		
	}

	[NoCompact, CCode (cheader_filename = "rb-shell-player.h")]
	public class ShellPlayer : Gtk.HBox {

		[CCode (cname = "rb_shell_player_pause")]
		public bool pause(ref GLib.Error? err = null);

		[CCode (cname = "rb_shell_player_play")]
		public bool play(ref GLib.Error? err = null);

		[CCode (cname = "rb_shell_player_stop")]
		public bool stop();

		[CCode (cname = "rb_shell_player_get_playing")]
		public bool get_playing(ref bool playing, ref GLib.Error? err = null);        

		[CCode (cname = "rb_shell_player_do_next")]
		public bool do_next(ref GLib.Error? err = null);

		[CCode (cname = "rb_shell_player_do_previous")]
		public bool do_previous(ref GLib.Error? err = null);        

		public virtual signal void playing_changed(bool playing);
	}

	[CCode (cheader_filename = "rb-player.h")]
	public interface Player : GLib.Object {
		[CCode (cname = "rb_player_opened")]
		public bool opened();
	}
	
	[CCode (cprefix="RB_ENTRY_VIEW_COL_")]
	public enum EntryViewColumn {
		TRACK_NUMBER,
		TITLE,
		ARTIST,
		ALBUM,
		GENRE,
		DURATION,
		QUALITY,
		RATING,
		PLAY_COUNT,
		YEAR,
		LAST_PLAYED,
		FIRST_SEEN,
		LAST_SEEN,
		LOCATION,
		ERROR
	}

	[CCode (cheader_filename="rb-entry-view.h")]	
	public class EntryView : Gtk.ScrolledWindow
	{
		public EntryView (RhythmDB.DB db, GLib.Object shell_player, string sort_key, bool is_drag_source = false, bool is_drag_dest = false);
		public void append_column (EntryViewColumn column_type, bool always_visible);
		public void set_model (RhythmDB.QueryModel model);
	}
	
	[CCode (cheader_filename="rb-debug.h")]
	public static void debug (string format, ...);
}
