[CCode (cheader_filename = "rhythmdb.h", lower_case_cprefix="rhythmdb_")]
namespace RhythmDB
{
	[CCode(cprefix="RHYTHMDB_ENTRY_")]
	public enum EntryCategory 
	{
		NORMAL,		/* anything that doesn't match the other categories */
		STREAM,		/* endless streams (eg shoutcast, last.fm) */
		CONTAINER,	/* things that point to other entries (eg podcast feeds) */
		VIRTUAL		/* import errors, ignored files */
	}
	
	[CCode(cprefix="RHYTHMDB_PROP_")]
	public enum EntryPropType
	{
		TYPE = 0,
		ENTRY_ID,
		TITLE,
		GENRE,
		ARTIST,
		ALBUM,
		TRACK_NUMBER,
		DISC_NUMBER,
		DURATION,
		FILE_SIZE,
		LOCATION,
		MOUNTPOINT,
		MTIME,
		FIRST_SEEN,
		LAST_SEEN,
		RATING,
		PLAY_COUNT,
		LAST_PLAYED,
		BITRATE,
		DATE,
		TRACK_GAIN,			/* obsolete */
		TRACK_PEAK,			/* obsolete */
		ALBUM_GAIN,			/* obsolete */
		ALBUM_PEAK,			/* obsolete */
		MIMETYPE,
		TITLE_SORT_KEY,
		GENRE_SORT_KEY,
		ARTIST_SORT_KEY,
		ALBUM_SORT_KEY,
		TITLE_FOLDED,
		GENRE_FOLDED,
		ARTIST_FOLDED,
		ALBUM_FOLDED,
		LAST_PLAYED_STR,
		HIDDEN,
		PLAYBACK_ERROR,
		FIRST_SEEN_STR,
		LAST_SEEN_STR,

		/* synthetic properties */
		SEARCH_MATCH,
		YEAR,
		KEYWORD, /**/

		/* Podcast properties */
		STATUS,
		DESCRIPTION,
		SUBTITLE,
		SUMMARY,
		LANG,
		COPYRIGHT,
		IMAGE,
		POST_TIME,

		MUSICBRAINZ_TRACKID,
		MUSICBRAINZ_ARTISTID,
		MUSICBRAINZ_ALBUMID,
		MUSICBRAINZ_ALBUMARTISTID,
		ARTIST_SORTNAME,
		ALBUM_SORTNAME,

		ARTIST_SORTNAME_SORT_KEY,
		ARTIST_SORTNAME_FOLDED,
		ALBUM_SORTNAME_SORT_KEY,
		ALBUM_SORTNAME_FOLDED,

		RHYTHMDB_NUM_PROPERTIES
	}

	[CCode(cname="RhythmDBEntryType_", free_function="g_boxed_free", ref_function = "", unref_function = "")]
	[Compact]
	public class EntryType
	{
		public bool save_to_disk;
		public bool has_playlist;
		public EntryCategory category;
	}
	
	[Compact]
	public class Entry
	{
		
	}
	
	[CCode(cname="RhythmDB")]
	public class DB : GLib.Object
	{
		[CCode(cname="rhythmdb_entry_register_type")]
		public unowned EntryType entry_register_type (owned string name);

		[CCode(cname="rhythmdb_entry_new")]
		public unowned Entry entry_new (EntryType type, string url);
		
		[CCode(cname="rhythmdb_entry_get")]
		public void entry_get (Entry entry, EntryPropType propid, out GLib.Value @value);
		
		[CCode(cname="rhythmdb_entry_set")]
		public void entry_set (Entry entry, EntryPropType propid, GLib.Value @value);
		
		[CCode(cname="rhythmdb_entry_delete")]
		public void entry_delete (Entry entry);
		
		[CCode(cname="rhythmdb_entry_delete_by_type")]
		public void entry_delete_by_type (EntryType entry_type);

		[CCode(cname="rhythmdb_commit")]
		public void commit ();
	}
	
	[CCode (cheader_filename = "rhythmdb-query-model.h")]
	public class QueryModel : GLib.Object
	{
		public QueryModel.empty (RhythmDB.DB db);
		public void add_entry (Entry entry, int index = -1);
	}
}
