/* rhythmpnpplugin.vala
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

[CCode (lower_case_cprefix="rhythmpnp_")]
namespace RhythmPnP
{
	public class Plugin : RB.Plugin 
	{
		private unowned RB.Shell _shell = null;
	
		private ContextManager _context_manager;
		private GLib.List<IDevice> _devices = new GLib.List<IDevice> ();
	
		public Plugin ()
		{
			GLib.Object ();
		}
	
		private void on_context_available (ContextManager sender, Context context)
		{
			RB.debug ("context available");
			sender.manage_control_point (create_control_point (context));
		}
	
		public override void activate (RB.Shell shell)
		{
			RB.debug ("plugin activated");
			this._shell = shell;
		
			/* create context manager */
			_context_manager = new ContextManager(null, 0);
			_context_manager.context_available.connect (this.on_context_available);
		}

		public override void deactivate (RB.Shell shell)
		{
			RB.debug ("plugin deactivated");
			_context_manager.context_available.disconnect (this.on_context_available);
			_context_manager = null;
		}
		
		private ControlPoint create_control_point (Context context)
		{
			RB.debug ("create control point");
		
			var control_point = new ControlPoint (context, "urn:schemas-upnp-org:device:MediaServer:2");
			control_point.device_proxy_available.connect (this.on_device_proxy_available);
			control_point.device_proxy_unavailable.connect (this.on_device_proxy_unavailable);
			control_point.active = true;
		
			return control_point;
		}
	
		public IDevice? create_upnp_device (RB.Plugin plugin, RB.Shell shell, DeviceProxy proxy)
		{
			IDevice device = null;
		
			//try to find a content directory service
			foreach (ServiceInfo service in proxy.list_services ()) {
				RB.debug ("service of type %s exposed %s: %s", service.get_type ().name (), service.udn, service.service_type);
				if (service is ServiceProxy && service.service_type.contains (":ContentDirectory:")) {
					RB.debug ("found a ContentDirectory service");
					if (service.get_control_url ().contains("/GstLaunch/")) {
						var streaming_device = new StreamingDevice (proxy, (ServiceProxy) service, plugin, shell);		
						streaming_device.name = proxy.get_friendly_name ();
						device = streaming_device;		
					} else {
						var media_device = new MediaLibraryDevice (proxy, (ServiceProxy) service, plugin, shell);		
						media_device.name = proxy.get_friendly_name ();
						device = media_device;
					}
				}
			}
		
			return device;
		}

		private void on_device_proxy_available (GUPnP.DeviceProxy proxy)
		{
			RB.debug ("device available '%s': %s", proxy.get_friendly_name (), proxy.get_device_type ());
			if (find_device_for_udn (proxy.udn) != null) {
				warning ("duplicate proxy device object found: %s", proxy.udn);
				return;
			}
		
		
			var device = create_upnp_device (this, _shell, proxy);
		
			if (device != null) {
				_devices.append (device);
			} else {
				RB.debug ("no ContentDirectory service exposed for %s", proxy.get_friendly_name ());
			}
		}
	
		private void on_device_proxy_unavailable (GUPnP.DeviceProxy proxy)
		{
			RB.debug ("device unavailable '%s': %s", proxy.get_friendly_name (), proxy.get_device_type ());
			var device = find_device_for_udn (proxy.udn);
			if (device == null) {
				warning ("cannot find proxy device: %s", proxy.udn);
				return;				
			}
			device.cleanup ();
			_devices.remove (device);
		}

		private IDevice? find_device_for_udn (string udn)
		{
			foreach (IDevice device in _devices) {
				if (device.id == udn) {
					return device;
				}
			}
		
			return null;
		}
	}
}

[ModuleInit]
public GLib.Type register_rb_plugin (GLib.TypeModule module)
{
	return typeof (RhythmPnP.Plugin);
}
