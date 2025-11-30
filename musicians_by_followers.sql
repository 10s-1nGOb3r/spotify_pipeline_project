CREATE VIEW musician_by_followers AS
	SELECT art.name AS musician,
		art.followers AS followers,
		genr.name AS genre,
		ROUND((art.followers / SUM(art.followers) OVER(PARTITION BY genr.name)) * 100,2) AS perc
	FROM artists art
	JOIN artist_genres arge ON arge.artist_id = art.spotify_id
	JOIN genres genr ON genr.id_genre = arge.genre_id
	GROUP BY art.name, art.followers, genr.name
	ORDER BY genr.name, art.followers DESC;
