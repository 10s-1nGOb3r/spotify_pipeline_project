CREATE VIEW view_track_popularity_per_genre AS
	WITH track_popularity AS(
		SELECT tra.name AS song_name,
			tra.popularity AS popularity,
			CASE WHEN tra.popularity >= 0 AND tra.popularity <= 30 THEN "The Underground"
				WHEN tra.popularity > 30 AND tra.popularity <= 60 THEN "The Established Track"
				WHEN tra.popularity > 60 AND tra.popularity <= 80 THEN "The Certified Hit"
				WHEN tra.popularity > 80 AND tra.popularity <= 100 THEN "The Global Smash"
			END AS popularity_level,
			genr.name AS genre
		FROM tracks tra
		JOIN track_artists trar ON trar.track_id = tra.spotify_id
		JOIN artists art ON art.spotify_id = trar.artist_id
		JOIN artist_genres arge ON arge.artist_id = art.spotify_id
		JOIN genres genr ON genr.id_genre = arge.genre_id
		WHERE tra.popularity IS NOT NULL),
	track_popularity2 AS(
		SELECT genre AS genre1,
			popularity_level AS popularity_level1,
			COUNT(popularity_level) AS count_popularity_level
		FROM track_popularity
		GROUP BY genre, popularity_level),
	track_popularity3 AS(
		SELECT genre AS genre2,
			COUNT(genre) AS count_genre
		FROM track_popularity
		GROUP BY genre)
	SELECT trap3.genre2 AS genre,
		trap3.count_genre AS total_count_genre,
		trap2.popularity_level1 AS popularity_level,
		trap2.count_popularity_level AS total_popularity_level_per_genre,
		ROUND((trap2.count_popularity_level / trap3.count_genre) * 100,2) AS popularity_level_perc
	FROM track_popularity3 trap3
	JOIN track_popularity2 trap2 ON trap2.genre1 = trap3.genre2;