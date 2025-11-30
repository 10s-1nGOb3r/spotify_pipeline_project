CREATE VIEW album_pop AS
	WITH album_pop AS(
		SELECT alb.name AS album_name,
			art.name AS musician,
			genr.name AS genre,
			SUM(tra.popularity) AS popularity
		FROM albums alb
		JOIN tracks tra ON tra.album_id = alb.spotify_id
		JOIN album_artists alar ON alar.album_id = alb.spotify_id
		JOIN artists art ON art.spotify_id = alar.artist_id
		JOIN artist_genres arge ON arge.artist_id = art.spotify_id
		JOIN genres genr ON genr.id_genre = arge.genre_id
		WHERE tra.popularity > 0
		GROUP BY alb.name, art.name, genr.name)
	SELECT ROW_NUMBER() OVER(PARTITION BY genre ORDER BY popularity DESC) AS ranking, 
		album_name AS album_name1,
		musician AS musician1,
		genre AS genre1,
		popularity AS popularity1
	FROM album_pop;
