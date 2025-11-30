CREATE VIEW song_with_genre AS
	SELECT tra.name AS song_name,
		art.name AS musician,
		tra.popularity AS popularity_rate,
		genr.name AS genre,
		CASE WHEN tra.popularity >= 0  AND tra.popularity <= 30 THEN "The Underground / Nische"
			WHEN tra.popularity >= 30  AND tra.popularity <= 60 THEN "The Established Track"
			WHEN tra.popularity >= 60  AND tra.popularity <= 80 THEN "The Certified Hit"
			WHEN tra.popularity >= 80  AND tra.popularity <= 100 THEN "The Global Smash"
		END AS popularity_class,
		ROUND(tra.duration_ms/60000, 2) AS song_length
	FROM tracks tra
	JOIN track_artists trar ON trar.track_id = tra.spotify_id
	JOIN artists art ON art.spotify_id = trar.artist_id
	JOIN artist_genres arge ON arge.artist_id = art.spotify_id
	JOIN genres genr ON genr.id_genre = arge.genre_id
	WHERE DATE(tra.fetched_at) <> '2025-11-11';
