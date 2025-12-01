CREATE VIEW `view_genre_pop` AS
    SELECT 
        `genr`.`name` AS `genre`,
        ROUND(AVG(`art`.`popularity`), 0) AS `popularity`
    FROM
        ((`artists` `art`
        JOIN `artist_genres` `arge` ON ((`arge`.`artist_id` = `art`.`spotify_id`)))
        JOIN `genres` `genr` ON ((`genr`.`id_genre` = `arge`.`genre_id`)))
    GROUP BY `genr`.`name`
