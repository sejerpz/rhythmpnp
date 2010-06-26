/* main.vala
 *
 * Copyright (C) 2010  Andrea Del Signore
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *  
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *  
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Author:
 * 	Andrea Del Signore <sejerpz@tin.it>
 */

using GLib;
using RB;
using Gtk;
using Gst;
using GUPnP;
using RhythmDB;

public class UPnpDevice : RB.BrowserSource
{
	private const int CHUNK_SIZE = 500;
	private const int PREFERRED_DEPTH = 32;
	private const int PREFERRED_WIDTH = 22;
	private const int PREFERRED_HEIGHT = 22;

	private bool _active = false; // store if the source is currently active (selected among the rhythmbox sources list)
	private bool _deleted = false;
	private bool _activated = false;
	private ServiceProxy _service_proxy;
	private int _starting_index = 0;
		
	private GLib.List<GUPnP.DIDLLiteItem> _cache = new GLib.List<GUPnP.DIDLLiteItem>();
	
	public string id {
		get; set;
	}

	public bool is_loading {
		get; private set;
	}
		
	public UPnpDevice (DeviceProxy device, ServiceProxy service_proxy, RB.Plugin plugin, RB.Shell shell)
	{
		var db = shell.db;
		var entry_type = db.entry_register_type (device.udn);
		entry_type.save_to_disk = false;
		entry_type.category = EntryCategory.NORMAL;
		GLib.Object (plugin: plugin, shell: shell, entry_type: entry_type);
		
		shell.append_source (this);
		shell.register_entry_type_for_source(this, entry_type);
		this.id = device.udn;
		_service_proxy = service_proxy;
		
		var pixbuf = get_device_icon (device);
		if (pixbuf != null)
			this.icon = pixbuf;
	}
	
	private Gdk.Pixbuf? get_device_icon (DeviceProxy device)
	{
		Gdk.Pixbuf pixbuf = null;
		string mime_type;
		int width, height;
	
		//get the device icon
		try {
			var icon_url = device.get_icon_url (null,
				 PREFERRED_DEPTH,
				 PREFERRED_WIDTH,
				 PREFERRED_HEIGHT,
				 true,
				 out mime_type,
				 null,
				 out width,
				 out height);
				 
			if (icon_url != null) {
				debug ("device icon url: %s", icon_url);
				var message = new Soup.Message ("GET", icon_url);
				var session = new Soup.SessionAsync ();
				session.send_message (message);
				if (message.status_code == 200) {
					// get icon from message
					var loader = new Gdk.PixbufLoader.with_mime_type (mime_type);
					if (loader != null) {
						try {
							loader.write (message.response_body.data, (size_t)message.response_body.length);
							pixbuf = loader.get_pixbuf ();
							if (pixbuf != null) {
								float aspect_ratio = (float) width / (float) height;
								int final_height = (int) (PREFERRED_WIDTH / aspect_ratio);
								pixbuf = pixbuf.scale_simple (PREFERRED_WIDTH, final_height, Gdk.InterpType.HYPER);
							}
							loader.close ();
						} catch (Error err) {
							warning ("error while loading the pixbuf: %s", err.message);
						}
					} else {
						warning ("error creating pixbuf loader for mime type %s", mime_type);
					}
				} else {
					warning ("error sending icon message: %u", message.status_code);
				}
			} else {
				debug ("no device icon found");
			}
		} catch (Error err) {
			warning ("error getting device icon: %s", err.message);
		}
		return pixbuf;
	}
	
	public override void impl_activate ()
	{
		debug ("source %s activated", id);
		_active = true;
		if (!_activated) {
			_activated = true;
			_starting_index = 0;
			is_loading = true;
			this.notify_status_changed ();
			start_music_search ();
		}
	}
	
	public override void impl_deactivate ()
	{
		debug ("source %s deactivate", id);
		_active = false;
	}
	
	public override void impl_get_status (out string text, out string progress_text, out float progress)
	{
		if (is_loading) {
			progress_text = null;
			text = _("loading %s music catalog").printf(this.name);
			progress = -1.0f;
		} else {
			base.impl_get_status (out text, out progress_text, out progress);
		}
	}
		
	private void start_music_search ()
	{
		debug ("start music search for %s", id);
		_cache = new GLib.List<GUPnP.DIDLLiteItem>();
		_service_proxy.begin_action (
			"Search", this.complete_music_search,
			"ContainerID", typeof(string), "0",
			"SearchCriteria", typeof(string), "upnp:class derivedFrom \"object.item.audioItem\"",
			"Filter", typeof(string), "dc:title,dc:creator,dc:date,upnp:album,upnp:originalTrackNumber,res@duration",
			"StartingIndex", typeof(string), _starting_index.to_string (),
			"RequestedCount", typeof(string), CHUNK_SIZE.to_string (),
			"SortCriteria", typeof(string), "");
	}
	
	private void complete_music_search (GUPnP.ServiceProxy proxy, GUPnP.ServiceProxyAction action)
	{
		debug ("music search complete for %s", proxy.get_id ());
		string result;
		string number = "0";
		string total_matches = "0";
		string update_id = null;
		
 		try {
			if (!proxy.end_action (action, 
				"Result", typeof(string), out result,
				"NumberReturned", typeof(string), out number,
				"TotalMatches", typeof(string), out total_matches,
				"UpdateID", typeof(string), out update_id)) {
			    	critical ("end_action on proxy %s failed", proxy.get_id ());
				is_loading = false;
				warning ("proxy.end_action failed");
				return;
			}
		} catch (Error err) {
			debug ("error %s %d", err.message, err.code);
		}
		debug ("number returned: %s\ntotal matches: %s\nupdateid: %s\n", number, total_matches, update_id);

		if (_deleted)  { // if the source was delete stop scanning the media library
			is_loading = false;
			return;
		}
			
		if (number != null && number != "0") {
			// parsing the result
			GUPnP.DIDLLiteParser parser = new GUPnP.DIDLLiteParser ();
			parser.item_available.connect (this.on_item_available);
			try {
				parser.parse_didl (result);
			} catch (Error err) {
				warning ("error parsing didl results: %s", err.message);
			}
			parser.item_available.disconnect (this.on_item_available);
		}

		if (_cache.length() > 0) {		
			var db = shell.db;
			foreach (GUPnP.DIDLLiteItem item in _cache) {
				add_entry (db, item);
			}
			db.commit ();
		}
		_cache = null;
		
		if (number.to_int () == 0) {
			is_loading = false;
			this.notify_status_changed ();
		} else {
			_starting_index	+= CHUNK_SIZE;
			start_music_search (); // continue searching
		}
	}
	
	private void on_item_available (GUPnP.DIDLLiteParser parser, GUPnP.DIDLLiteItem item)		
	{
		//debug ("ITEM available %s: %s", item.id, item.title);
		_cache.append (item);
	}
	
	private void add_entry (RhythmDB.DB db, GUPnP.DIDLLiteItem item)
	{
		foreach (GUPnP.DIDLLiteResource res in item.get_resources ()) {
			if (res.protocol_info.mime_type == "audio/mpeg" || res.protocol_info.mime_type == "audio/ogg") {
				unowned RhythmDB.Entry? entry = db.entry_new (this.entry_type, res.uri);
				if (entry != null) {
					db.entry_set (entry, EntryPropType.TITLE, item.title ?? "");
					db.entry_set (entry, EntryPropType.ALBUM, item.album ?? "");
					db.entry_set (entry, EntryPropType.ARTIST, item.creator ?? "");
					db.entry_set (entry, EntryPropType.TRACK_NUMBER, (ulong)item.track_number);
					db.entry_set (entry, EntryPropType.DURATION, (ulong)res.duration);
					db.entry_set (entry, EntryPropType.GENRE, item.genre ?? "");
				}
				break;
			}
		}
	}
	
	public void cleanup ()
	{
		debug ("source %s cleanup", id);
		this.shell.db.entry_delete_by_type (this.entry_type);
		_deleted = true;
		delete_thyself ();
	}
}

public class RhythmPnPPlugin : RB.Plugin 
{
	private unowned RB.Shell _shell = null;
	
	private Context _context;
	private ControlPoint _control_point;
	private GLib.List<UPnpDevice> _devices = new GLib.List<UPnpDevice> ();

	public RhythmPnPPlugin ()
	{
		GLib.Object ();
	}
	
	public override void activate (RB.Shell shell)
	{
		debug ("plugin activated");
		this._shell = shell;
		setup_upnp_discovery ();
	}

	public override void deactivate (RB.Shell shell)
	{
		debug ("plugin deactivated");
		cleanup_upnp ();
	}
		
	private void setup_upnp_discovery ()
	{
		debug ("setup upnp discovery");
		try {
			_context = new Context (null, null, 0);
			_control_point = new ControlPoint (_context, "urn:schemas-upnp-org:device:MediaServer:2");
			_control_point.device_proxy_available.connect (this.on_device_proxy_available);
			_control_point.device_proxy_unavailable.connect (this.on_device_proxy_unavailable);
			_control_point.active = true;
		} catch (Error err) {
			warning ("error while setting up upnp discovery: %s", err.message);
		}
	}

	private void cleanup_upnp ()	
	{
		_control_point.active = false;
		_control_point = null;
		_context = null;
	}
	
	public UPnpDevice? create_upnp_device (RB.Plugin plugin, RB.Shell shell, DeviceProxy proxy)
	{
		UPnpDevice device = null;
		
		//try to find a content directory service
		foreach (ServiceInfo service in proxy.list_services ()) {
			debug ("service of type %s exposed %s: %s", service.get_type ().name (), service.udn, service.service_type);
			if (service is ServiceProxy && service.service_type.contains (":ContentDirectory:")) {
				debug ("found a ContentDirectory service");
				device = new UPnpDevice (proxy, (ServiceProxy) service, plugin, shell);		
				device.name = proxy.get_friendly_name ();
			}
		}
		
		return device;
	}

	private void on_device_proxy_available (GUPnP.DeviceProxy proxy)
	{
		debug ("device available '%s': %s", proxy.get_friendly_name (), proxy.get_device_type ());
		if (find_device_for_udn (proxy.udn) != null) {
			warning ("duplicate proxy device object found: %s", proxy.udn);
			return;
		}
		
		
		var device = create_upnp_device (this, _shell, proxy);
		
		if (device != null) {
			_devices.append (device);
		} else {
			debug ("no ContentDirectory service exposed for %s", proxy.get_friendly_name ());
		}
	}
	
	private void on_device_proxy_unavailable (GUPnP.DeviceProxy proxy)
	{
		debug ("device unavailable '%s': %s", proxy.get_friendly_name (), proxy.get_device_type ());
		var device = find_device_for_udn (proxy.udn);
		if (device == null) {
			warning ("cannot find proxy device: %s", proxy.udn);
			return;				
		}
		device.cleanup ();
		_devices.remove (device);
	}

	private UPnpDevice? find_device_for_udn (string udn)
	{
		foreach (UPnpDevice device in _devices) {
			if (device.id == udn) {
				return device;
			}
		}
		
		return null;
	}
}

[ModuleInit]
public GLib.Type register_rb_plugin (GLib.TypeModule module)
{
	return typeof (RhythmPnPPlugin);
}
