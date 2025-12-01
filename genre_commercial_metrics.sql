CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `view_genre_commercial_metric` AS
    SELECT 
        `genr`.`name` AS `genre`,
        ROUND(AVG(`art`.`popularity`), 0) AS `popularity`,
        ROUND(AVG(`art`.`followers`), 0) AS `followers`
    FROM
        ((`artists` `art`
        JOIN `artist_genres` `arge` ON ((`arge`.`artist_id` = `art`.`spotify_id`)))
        JOIN `genres` `genr` ON ((`genr`.`id_genre` = `arge`.`genre_id`)))
    WHERE
        (`art`.`popularity` IS NOT NULL)
    GROUP BY `genr`.`name`
