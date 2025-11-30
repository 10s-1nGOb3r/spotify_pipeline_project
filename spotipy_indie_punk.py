import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
import mysql.connector
import schedule
import time
import os
import sys
from dotenv import load_dotenv

# --- NEW LOGGING SETUP ---
# We are redirecting all 'print' and 'error' messages
# to a file named 'pipeline.log' in the same folder.
# 'a' means 'append', so it keeps a running history.
# 'utf-8' handles special characters in song names.
log_file_path = os.path.join(os.path.dirname(__file__), 'pipeline.log')
err_file_path = os.path.join(os.path.dirname(__file__), 'pipeline_error.log')

# --- This setup will log to files when run by scheduler, but print to console when run by you ---


def setup_logging():
    # Only redirect if NOT in an interactive terminal (like Windows Scheduler)
    if not sys.stdout.isatty():
        try:
            sys.stdout = open(log_file_path, 'a', encoding='utf-8')
            sys.stderr = open(err_file_path, 'a', encoding='utf-8')
        except Exception as e:
            # This will print to console if it fails
            print(f"Failed to open log files: {e}")


setup_logging()
# -------------------------

load_dotenv()

# --- NEW, BULLETPROOF CONFIGURATION ---

# 1. Spotify Credentials
SPOTIPY_CLIENT_ID = os.getenv('SPOTIPY_CLIENT_ID')
SPOTIPY_CLIENT_SECRET = os.getenv('SPOTIPY_CLIENT_SECRET')

# 2. MySQL Credentials
DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_HOST = os.getenv('DB_HOST')
DB_NAME = os.getenv('DB_NAME')

# 3. Validation (This is the new part)
print(f"\n--- Validating Credentials from .env file at {time.ctime()} ---")
if not SPOTIPY_CLIENT_ID:
    print("❌ ERROR: 'SPOTIPY_CLIENT_ID' not found in .env file.", file=sys.stderr)
    sys.exit(1)  # <-- Exit with an error code

if not SPOTIPY_CLIENT_SECRET:
    print("❌ ERROR: 'SPOTIPY_CLIENT_SECRET' not found in .env file.", file=sys.stderr)
    sys.exit(1)  # <-- Exit with an error code

if not DB_USER:
    print("❌ ERROR: 'DB_USER' not found in .env file.", file=sys.stderr)
    sys.exit(1)  # <-- Exit with an error code

if not DB_PASSWORD:
    print("❌ ERROR: 'DB_PASSWORD' not found in .env file.", file=sys.stderr)
    sys.exit(1)  # <-- Exit with an error code

print("✅ All credentials found.")
print("---------------------------------------------")


# 4. MySQL Config Dictionary
DB_CONFIG = {
    'user': DB_USER,
    'password': DB_PASSWORD,
    'host': DB_HOST,
    'database': DB_NAME,
    'raise_on_warnings': False  # <--- Fix for 1062 error
}

# --- FUNCTIONS ---


def get_spotify_client():
    """Authenticates with Spotify and returns the client object."""
    print("Authenticating with Spotify...")
    auth_manager = SpotifyClientCredentials(
        client_id=SPOTIPY_CLIENT_ID,
        client_secret=SPOTIPY_CLIENT_SECRET
    )
    # Increased timeout to 30 seconds
    return spotipy.Spotify(auth_manager=auth_manager, requests_timeout=30)

# --- DATABASE PROCESSOR FUNCTIONS ---
# (These are all correct, no changes needed)


def process_artist(cursor, artist_data):
    """Saves a single artist to the 'artists' table."""
    sql = """
    INSERT INTO artists (spotify_id, name, popularity, followers)
    VALUES (%s, %s, %s, %s)
    AS new_values
    ON DUPLICATE KEY UPDATE
        name = new_values.name,
        popularity = new_values.popularity,
        followers = new_values.followers,
        fetched_at = NOW()
    """
    data = (
        artist_data['id'],
        artist_data['name'],
        artist_data['popularity'],
        artist_data['followers']['total']
    )
    cursor.execute(sql, data)


def process_simplified_artist(cursor, simple_artist_data):
    """
    Ensures a simplified artist (from album/track) exists in the artists table.
    Returns the artist's ID for later hydration.
    """
    sql = """
    INSERT INTO artists (spotify_id, name, popularity, followers)
    VALUES (%s, %s, NULL, NULL)
    AS new_values
    ON DUPLICATE KEY UPDATE
        name = new_values.name
    """
    data = (
        simple_artist_data['id'],
        simple_artist_data['name']
    )
    cursor.execute(sql, data)

    return simple_artist_data['id']


def process_genres(cursor, artist_id, genres_list):
    """Saves genres and links them to an artist."""
    for genre_name in genres_list:
        cursor.execute(
            "INSERT IGNORE INTO genres (name) VALUES (%s)", (genre_name,))

        cursor.execute(
            "SELECT id_genre FROM genres WHERE name = %s", (genre_name,))
        genre_result = cursor.fetchone()
        if genre_result:
            genre_id = genre_result[0]

            sql_link = """
            INSERT INTO artist_genres (artist_id, genre_id)
            VALUES (%s, %s)
            ON DUPLICATE KEY UPDATE artist_id = artist_id
            """
            cursor.execute(sql_link, (artist_id, genre_id))


def process_album(cursor, album_data):
    """Saves a single album to the 'albums' table."""
    sql = """
    INSERT INTO albums (spotify_id, name, album_type, total_tracks, release_date)
    VALUES (%s, %s, %s, %s, %s)
    AS new_values
    ON DUPLICATE KEY UPDATE
        name = new_values.name,
        album_type = new_values.album_type,
        total_tracks = new_values.total_tracks,
        release_date = new_values.release_date,
        fetched_at = NOW()
    """
    data = (
        album_data['id'],
        album_data['name'],
        album_data['album_type'],
        album_data['total_tracks'],
        album_data['release_date']
    )
    cursor.execute(sql, data)


def process_album_artists(cursor, album_id, artists_list, artists_to_hydrate):
    """Links an album to its artists in 'album_artists'."""
    for artist in artists_list:
        # Get the ID and add it to our to-do list
        artist_id = process_simplified_artist(cursor, artist)
        artists_to_hydrate.add(artist_id)

        sql = """
        INSERT INTO album_artists (album_id, artist_id)
        VALUES (%s, %s)
        ON DUPLICATE KEY UPDATE album_id = album_id
        """
        cursor.execute(sql, (album_id, artist['id']))


def process_track(cursor, track_data, album_id):
    """Saves a single track to the 'tracks' table."""

    # --- NEW SAFETY SHIELD ---
    if track_data is None:
        print(f"⚠️ Skipping 'None' track data for album {album_id}")
        return
    # -------------------------

    sql = """
    INSERT INTO tracks (spotify_id, album_id, name, popularity, duration_ms, track_number, explicit)
    VALUES (%s, %s, %s, %s, %s, %s, %s)
    AS new_values
    ON DUPLICATE KEY UPDATE
        name = new_values.name,
        popularity = new_values.popularity,
        duration_ms = new_values.duration_ms,
        track_number = new_values.track_number,
        explicit = new_values.explicit,
        fetched_at = NOW()
    """

    data = (
        track_data['id'],
        album_id,
        track_data['name'],
        track_data.get('popularity', 0),  # Will be filled by track hydration
        track_data['duration_ms'],
        track_data['track_number'],
        track_data['explicit']
    )
    cursor.execute(sql, data)


def process_track_artists(cursor, track_id, artists_list, artists_to_hydrate):
    """Links a track to its artists (for features) in 'track_artists'."""
    for artist in artists_list:
        # Get the ID and add it to our to-do list
        artist_id = process_simplified_artist(cursor, artist)
        artists_to_hydrate.add(artist_id)

        sql = """
        INSERT INTO track_artists (track_id, artist_id)
        VALUES (%s, %s)
        ON DUPLICATE KEY UPDATE track_id = track_id
        """
        cursor.execute(sql, (track_id, artist['id']))

# --- MAIN JOB FUNCTION (Complete v3.0) ---


def job(genre_list):
    """
    The main job that runs the whole pipeline.
    This is a "deep" crawl: Artists -> Albums -> Tracks
    """
    print(f"\n--- 🚀 Starting Scheduled Job at {time.ctime()} ---")

    # --- Variable initializations ---
    sp = get_spotify_client()
    cnx = None
    cursor = None

    genres_to_search = genre_list  # Use the genre list passed to the function
    ARTIST_LIMIT_PER_GENRE = 20

    artists_to_hydrate = set()

    try:
        cnx = mysql.connector.connect(**DB_CONFIG)
        cursor = cnx.cursor()
        print("✅ Database connection successful.")

        all_artist_results = []
        for genre in genres_to_search:
            print(
                f"🎸 Searching for {genre} artists (limit {ARTIST_LIMIT_PER_GENRE})...")
            results = sp.search(
                q=f'genre:"{genre}"', type='artist', limit=ARTIST_LIMIT_PER_GENRE)
            all_artist_results.extend(results['artists']['items'])

        print(f"\n📊 Found {len(all_artist_results)} total artists to process.")

        # --- The Main Pipeline Loop ---
        for artist in all_artist_results:
            # Our polite 2-second wait PER ARTIST
            time.sleep(2)

            print(f"\nProcessing Artist: {artist['name']} ({artist['id']})")

            # 1. Process the Artist and their Genres
            process_artist(cursor, artist)
            process_genres(cursor, artist['id'], artist['genres'])
            artists_to_hydrate.discard(artist['id'])

            # 2. Get Artist's Albums
            albums = sp.artist_albums(
                artist['id'], album_type='album,single', limit=50)

            for album in albums['items']:
                # Wait 1 full second PER ALBUM
                time.sleep(1)

                # 3. Process the Album and its Artists
                process_album(cursor, album)
                process_album_artists(
                    cursor, album['id'], album['artists'], artists_to_hydrate)

                # 4. Get Album's Tracks (Simplified)
                simplified_tracks = sp.album_tracks(album['id'], limit=50)

                # 5. "TRACK HYDRATION" STEP
                track_ids = [t['id'] for t in simplified_tracks['items']]
                if not track_ids:
                    continue

                full_track_objects = sp.tracks(track_ids)

                for track in full_track_objects['tracks']:
                    if not track:
                        continue

                    process_track(cursor, track, album['id'])
                    process_track_artists(
                        cursor, track['id'], track['artists'], artists_to_hydrate)

        # 6. "ARTIST HYDRATION" STEP
        if artists_to_hydrate:
            print(
                f"\n💧 Hydrating {len(artists_to_hydrate)} collaborating artists...")

            artist_id_list = list(artists_to_hydrate)
            for i in range(0, len(artist_id_list), 50):
                # Add a sleep to the hydration loop too
                time.sleep(2)
                batch_ids = artist_id_list[i:i+50]
                full_artists_data = sp.artists(batch_ids)

                for artist_data in full_artists_data['artists']:
                    if artist_data:
                        process_artist(cursor, artist_data)

            print("💧 Artist Hydration complete.")

        # --- All done, commit changes to DB ---
        print("\nCommitting all changes to the database...")
        cnx.commit()
        print("✅ Database commit successful!")

    except spotipy.SpotifyException as e:
        # <-- Write error to stderr
        print(f"❌ Spotify API Error: {e}", file=sys.stderr)
        if cnx:
            print("Rolling back database changes...", file=sys.stderr)
            cnx.rollback()
        sys.exit(1)  # <-- NEW: Exit with an error code
    except mysql.connector.Error as err:
        # <-- Write error to stderr
        print(f"❌ Database Error: {err}", file=sys.stderr)
        if cnx:
            print("Rolling back database changes...", file=sys.stderr)
            cnx.rollback()
        sys.exit(1)  # <-- NEW: Exit with an error code
    except Exception as e:
        # <-- Write error to stderr
        print(f"❌ An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)  # <-- NEW: Exit with an error code
    finally:
        # This block runs no matter what,
        # ensuring your database connection always closes.
        if cursor:
            cursor.close()
        if cnx and cnx.is_connected():
            cnx.close()
            print("Database connection closed.")

    print(f"--- 😴 Job finished at {time.ctime()} ---")


# ----------------------------------------------------
# --- NEW SCHEDULER BLOCK FOR WINDOWS TASK SCHEDULER ---
# ----------------------------------------------------
# This new block will run job() once and then exit,
# which is exactly what Task Scheduler needs.

if __name__ == "__main__":
    # --- NEW: Get script name to determine genre ---
    # This gets the filename (e.g., "spotipy_pop_punk.py")
    script_name = os.path.basename(__file__)

    print(f"🚀 Windows Task Scheduler started this job at {time.ctime()}.")
    print(f"Script name detected: {script_name}")

    genres = []  # Start with an empty list

    # --- NEW, SAFER LOGIC ---
    # We check for the MOST specific names FIRST.
    if "pop_punk" in script_name:
        genres = ["pop punk"]
    elif "indie_punk" in script_name:
        genres = ["indie punk"]
    elif "indorock" in script_name:
        genres = ["indie rock"]  # <-- YOUR NEW GENRE, FIXED
    elif "indie" in script_name:
        # This will now ONLY match "spotipy_indie.py"
        print("⚠️ WARNING: Running for 'indie'. This is a massive genre and may get rate-limited.")
        genres = ["indie"]
    elif "metal" in script_name:
        genres = ["nu metal", "metalcore"]  # Safe sub-genres
    elif "punk" in script_name:
        # This will now ONLY match "spotipy_punk.py"
        genres = ["punk", "hardcore punk"]
    else:
        print(
            f"⚠️ WARNING: Could not determine genre from filename '{script_name}'. Defaulting to 'pop punk'.")
        genres = ["pop punk"]  # A default just in case

    print(f"Running for genres: {genres}")

    if genres:
        job(genres)  # <-- Pass the genre list to the job
    else:
        print("❌ ERROR: No genres were selected. Exiting.", file=sys.stderr)
        sys.exit(1)

    print(f"✅ Job complete. Exiting script at {time.ctime()}.")
