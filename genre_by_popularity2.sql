CREATE ALGORITHM=UNDEFINED 
DEFINER=`root`@`localhost` 
SQL SECURITY DEFINER 
VIEW `view_genre_pop2` AS

WITH `genre_pop2` AS (
    SELECT 
        `genr`.`name` AS `genre`,
        ROUND(AVG(`art`.`popularity`), 0) AS `popularity`,
        (
            CASE 
                WHEN AVG(`art`.`popularity`) >= 0 
                  AND AVG(`art`.`popularity`) <= 30 
                    THEN 'The Underground'
                WHEN AVG(`art`.`popularity`) > 30 
                  AND AVG(`art`.`popularity`) <= 60 
                    THEN 'The Established Track'
                WHEN AVG(`art`.`popularity`) > 60 
                  AND AVG(`art`.`popularity`) <= 80 
                    THEN 'The Certified Hit'
                WHEN AVG(`art`.`popularity`) > 80 
                  AND AVG(`art`.`popularity`) <= 100 
                    THEN 'The Global Smash'
            END
        ) AS `popularity_level`
    FROM 
        `artists` `art`
        JOIN `artist_genres` `arge`
            ON `arge`.`artist_id` = `art`.`spotify_id`
        JOIN `genres` `genr`
            ON `genr`.`id_genre` = `arge`.`genre_id`
    WHERE 
        `art`.`followers` IS NOT NULL
    GROUP BY 
        `genr`.`name`
)

SELECT 
    `genre_pop2`.`genre` AS `genre1`,
    `genre_pop2`.`popularity` AS `popularity1`,
    `genre_pop2`.`popularity_level` AS `popularity_level1`,
    ROUND(
        (
            `genre_pop2`.`popularity` 
            / SUM(`genre_pop2`.`popularity`) 
                OVER (PARTITION BY `genre_pop2`.`popularity_level`)
        ) * 100
    , 2) AS `popularity_level_perc`
FROM 
    `genre_pop2`
ORDER BY 
    `genre_pop2`.`popularity` DESC;
