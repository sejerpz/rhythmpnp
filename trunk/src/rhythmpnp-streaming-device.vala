/* upnpstreamingdevice.vala
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

namespace RhythmPnP
{
	public class StreamingDevice : IDevice, RB.StreamingSource
	{
		private bool _active = false; // store if the source is currently active (selected among the rhythmbox sources list)
		private bool _deleted = false;
		private bool _activated = false;
		private ServiceProxy _service_proxy;
		private int _starting_index = 0;
		private EntryView _view;
		private RhythmDB.QueryModel _model;
	
		private GLib.List<GUPnP.DIDLLiteItem> _cache = new GLib.List<GUPnP.DIDLLiteItem>();

		public string id {
			get; set;
		}
	
		public bool is_loading {
			get; set;
		}
	
		public StreamingDevice (DeviceProxy device, ServiceProxy service_proxy, RB.Plugin plugin, RB.Shell shell)
		{
			var db = shell.db;
			var entry_type = db.entry_register_type (device.udn);
			entry_type.save_to_disk = false;
			entry_type.category = EntryCategory.STREAM;
			GLib.Object (plugin: plugin, shell: shell, entry_type: entry_type, source_group: SourceGroup.library);
		
			shell.append_source (this);
			shell.register_entry_type_for_source(this, entry_type);
			this.id = device.udn;
			_service_proxy = service_proxy;
		
			var pixbuf = Utils.get_device_icon (device, 
				DefaultOptions.ICON_PREFERRED_DEPTH, 
				DefaultOptions.ICON_PREFERRED_WIDTH, 
				DefaultOptions.ICON_PREFERRED_HEIGHT);
			if (pixbuf != null)
				this.icon = pixbuf;
			
			// setup the view
			_view = new RB.EntryView (db, shell.get_player (), "%s/%s".printf (DefaultOptions.CONF_PREFIX, DefaultOptions.SORTING));
			_view.append_column (EntryViewColumn.TITLE, true);
			_view.append_column (EntryViewColumn.RATING, false);
			_view.append_column (EntryViewColumn.LAST_PLAYED, false);
		
			_model = new QueryModel.empty (db);
			_view.set_model (_model);
		
			// adding the view to the source
			this.pack_start (_view, true, true);
			this.show_all ();
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
	
		public override RB.EntryView impl_get_entry_view ()
		{
			return _view;
		}

		public override bool impl_can_browse ()
		{
			return false;
		}
	
		private void start_music_search ()
		{
			debug ("start music search for %s", id);
			_cache = new GLib.List<GUPnP.DIDLLiteItem>();
			Utils.start_predefined_search (_service_proxy, this.complete_music_search, _starting_index, DefaultOptions.SEARCH_CHUNK_SIZE);
		}
	
		private void complete_music_search (GUPnP.ServiceProxy proxy, GUPnP.ServiceProxyAction action)
		{
			debug ("music search complete for %s", proxy.get_id ());
			string result;
			string result_number;
			string result_total_matches;
			string update_id = null;
			int number = 0;
			int total_matches = 0;
		
	 		try {
				if (!proxy.end_action (action, 
					"Result", typeof(string), out result,
					"NumberReturned", typeof(string), out result_number,
					"TotalMatches", typeof(string), out result_total_matches,
					"UpdateID", typeof(string), out update_id)) {
				    	critical ("end_action on proxy %s failed", proxy.get_id ());
					is_loading = false;
					warning ("proxy.end_action failed");
					return;
				}
			} catch (Error err) {
				debug ("error %s %d", err.message, err.code);
			}
		
			if (result_number != null && result_number != "")
				number = result_number.to_int ();
			
			if (result_total_matches != null && result_total_matches != "")
				total_matches = result_total_matches.to_int ();
		
			debug ("items returned: %d current count: %d total items: %d", number, number + _starting_index, total_matches);

			if (_deleted)  { // if the source was delete stop scanning the media library
				is_loading = false;
				return;
			}
			
			if (number > 0) {
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
		
			if ((_starting_index + number) >= total_matches) {
				is_loading = false;
				this.notify_status_changed ();
			} else {
				_starting_index	+= number;
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
			var res = Utils.get_best_resource (item);		
			if (res != null) {
				debug ("new gst-launch entry found with uri: %s", res.uri);
				unowned RhythmDB.Entry? entry = db.entry_new (this.entry_type, res.uri);
				if (entry != null) {
					db.entry_set (entry, EntryPropType.TITLE, item.title ?? "");
					_model.add_entry (entry);
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
}

