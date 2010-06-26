[CCode (cprefix = "RB", lower_case_cprefix = "rb_")]
namespace RB {
	[CCode (cheader_filename = "rb-shell.h", ref_function = "g_object_ref", unref_function = "g_object_unref")]
	public class Shell 
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

	public class Source : GLib.Object
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
		
		[HasEmitter]
		public virtual signal void notify_status_changed ();
		
		//[CCode(cname="impl_activate")]
		public virtual void impl_activate ();
		
		//[CCode(cname="impl_deactivate")]
		public virtual void impl_deactivate ();
		
		public virtual void impl_get_status (out string text, out string progress_text, out float progress);
		
		public virtual void delete_thyself ();
		
/*		
		public SearchType search_type {
			get; construct set;
		}
*/
	}
	
	[CCode(cheader_filename="rb-browser-source.h")]
	public class BrowserSource : RB.Source
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
}
