/* default-options.vala
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

namespace RhythmPnP.DefaultOptions
{
	internal const int SEARCH_CHUNK_SIZE = 500;
	internal const int ICON_PREFERRED_DEPTH = 32;
	internal const int ICON_PREFERRED_WIDTH = 22;
	internal const int ICON_PREFERRED_HEIGHT = 22;
	
	internal const string CONF_PREFIX = "/app/rhythmbox";
	internal const string SORTING = "state/rhythmpnp/sorting";
}

