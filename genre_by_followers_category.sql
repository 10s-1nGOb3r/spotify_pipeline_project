CREATE VIEW genre_total_flwrs AS
WITH genre_flwrs AS (
    SELECT 
        genr.name AS genre,
        SUM(art.followers) AS followers
    FROM artists art
    JOIN artist_genres arge 
        ON arge.artist_id = art.spotify_id
    JOIN genres genr 
        ON genr.id_genre = arge.genre_id
    WHERE art.followers IS NOT NULL
    GROUP BY genr.name
),

genre_flwrs2 AS (
    SELECT 
        genre_flwrs.genre AS genre1,
        genre_flwrs.followers AS followers1,
        ROUND(
            (
                genre_flwrs.followers 
                / SUM(genre_flwrs.followers) OVER ()
            ) * 100,
            2
        ) AS flwrs_perc,
        (
            CASE 
                WHEN genre_flwrs.followers > 0 
                     AND genre_flwrs.followers <= 245000 
                    THEN 'The Niche'
                WHEN genre_flwrs.followers > 245000 
                     AND genre_flwrs.followers <= 8800000 
                    THEN 'The Established'
                WHEN genre_flwrs.followers > 8800000 
                     AND genre_flwrs.followers <= 27700000
                    THEN 'The Mainstream'
                WHEN genre_flwrs.followers > 27700000
                    THEN 'The Super Genres'
            END
        ) AS genre_category_by_followers
    FROM genre_flwrs
)

SELECT 
    genre_flwrs2.genre1 AS genre2,
    genre_flwrs2.followers1 AS followers2,
    genre_flwrs2.flwrs_perc AS flwrs_perc2,
    genre_flwrs2.genre_category_by_followers AS genre_category_by_followers2,
    ROUND(
        (
            genre_flwrs2.followers1 
            / SUM(genre_flwrs2.followers1) OVER (
                PARTITION BY genre_flwrs2.genre_category_by_followers
            )
        ) * 100,
        2
    ) AS perc_genre_category_by_followers
FROM genre_flwrs2
ORDER BY genre_flwrs2.followers1 DESC;
