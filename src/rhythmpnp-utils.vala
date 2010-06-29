/* utils.vala
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
using GUPnP;
using RhythmDB;

namespace RhythmPnP.Utils
{
	internal static Gdk.Pixbuf? get_device_icon (DeviceProxy device, int preferred_depth, int preferred_width, int preferred_height)
	{
		Gdk.Pixbuf pixbuf = null;
		string mime_type;
		int width, height;
	
		//get the device icon
		try {
			var icon_url = device.get_icon_url (null,
				 preferred_depth,
				 preferred_width,
				 preferred_height,
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
								int final_height = (int) (preferred_width / aspect_ratio);
								pixbuf = pixbuf.scale_simple (preferred_height, final_height, Gdk.InterpType.HYPER);
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

	internal static GUPnP.DIDLLiteResource? get_best_resource (GUPnP.DIDLLiteItem item)
	{
		string[] mime_types = new string[] { "audio/ogg", "audio/mpeg", "audio/x-wav", "audio/" }; // in order of preference
		
		foreach (string mime_type in mime_types) {
			foreach (GUPnP.DIDLLiteResource res in item.get_resources ()) {
				if (res.protocol_info.mime_type.has_prefix (mime_type)) {
					return res;
				}
			}
		}
		
		return null;
	}
	
	internal static void start_predefined_search (ServiceProxy service_proxy, GUPnP.ServiceProxyActionCallback callback, int starting_index, int requested_count = 0)
	{
		service_proxy.begin_action (
			"Search", callback,
			"ContainerID", typeof(string), "0",
			"SearchCriteria", typeof(string), "upnp:class derivedFrom \"object.item.audioItem\"",
			"Filter", typeof(string), "dc:title,dc:creator,dc:date,upnp:album,upnp:originalTrackNumber,res@duration",
			"StartingIndex", typeof(string), starting_index.to_string (),
			"RequestedCount", typeof(string), requested_count.to_string (),
			"SortCriteria", typeof(string), "");

	}

}

