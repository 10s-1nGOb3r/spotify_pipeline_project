CREATE ALGORITHM=UNDEFINED 
DEFINER=`root`@`localhost` 
SQL SECURITY DEFINER 
VIEW `musician_commercial_metric` AS

WITH `musician_gen` AS (
    SELECT 
        `art`.`name` AS `musician`,
        `art`.`popularity` AS `popularity`,
        `art`.`followers` AS `followers`,

        -- Popularity rate
        (
            CASE
                WHEN `art`.`popularity` >= 0 
                     AND `art`.`popularity` < 20 
                    THEN 'The Underground'
                WHEN `art`.`popularity` >= 20 
                     AND `art`.`popularity` < 40 
                    THEN 'The Established Track'
                WHEN `art`.`popularity` >= 40 
                     AND `art`.`popularity` < 60 
                    THEN 'The Certified Hit'
                WHEN `art`.`popularity` >= 60 
                     AND `art`.`popularity` < 80 
                    THEN 'The Global Smash'
                WHEN `art`.`popularity` >= 80 
                     AND `art`.`popularity` <= 100 
                    THEN 'The Global Superstar'
            END
        ) AS `popularity_rate`,

        -- Followers rate
        (
            CASE
                WHEN `art`.`followers` >= 0 
                     AND `art`.`followers` < 10000 
                    THEN 'Emerging Artist'
                WHEN `art`.`followers` >= 10000 
                     AND `art`.`followers` < 100000 
                    THEN 'Niche Star'
                WHEN `art`.`followers` >= 100000 
                     AND `art`.`followers` < 1000000 
                    THEN 'Established Act'
                WHEN `art`.`followers` >= 1000000 
                     AND `art`.`followers` <= 1000000000 
                    THEN 'Mainstream Star'
            END
        ) AS `followers_rate`

    FROM 
        `artists` `art`
    WHERE 
        `art`.`popularity` IS NOT NULL
)

SELECT 
    `musician_gen`.`musician` AS `musician1`,
    `musician_gen`.`popularity` AS `popularity1`,
    `musician_gen`.`followers` AS `followers1`,
    `musician_gen`.`popularity_rate` AS `popularity_rate1`,
    `musician_gen`.`followers_rate` AS `followers_rate1`,

    -- Commercial metric label
    (
        CASE
            WHEN `musician_gen`.`popularity_rate` = 'The Underground'
                 AND `musician_gen`.`followers_rate` = 'Emerging Artist'
                THEN 'Underground'

            WHEN `musician_gen`.`popularity_rate` = 'The Underground'
                 AND `musician_gen`.`followers_rate` = 'Niche Star'
                THEN 'Regular Artist'

            WHEN `musician_gen`.`popularity_rate` = 'The Global Superstar'
                 AND `musician_gen`.`followers_rate` = 'Mainstream Star'
                THEN 'Superstar'

            WHEN `musician_gen`.`popularity_rate` = 'The Global Superstar'
                 AND `musician_gen`.`followers_rate` = 'Established Act'
                THEN 'Regular Artist'

            WHEN `musician_gen`.`popularity_rate` = 'The Global Smash'
                 AND `musician_gen`.`followers_rate` = 'Mainstream Star'
                THEN 'Superstar'

            WHEN `musician_gen`.`popularity_rate` = 'The Global Smash'
                 AND `musician_gen`.`followers_rate` = 'Established Act'
                THEN 'Regular Artist'

            WHEN `musician_gen`.`popularity_rate` = 'The Global Smash'
                 AND `musician_gen`.`followers_rate` = 'Niche Star'
                THEN 'Regular Artist'

            WHEN `musician_gen`.`popularity_rate` = 'The Established Track'
                 AND `musician_gen`.`followers_rate` = 'Established Act'
                THEN 'Regular Artist'

            WHEN `musician_gen`.`popularity_rate` = 'The Established Track'
                 AND `musician_gen`.`followers_rate` = 'Emerging Artist'
                THEN 'Regular Artist'

            WHEN `musician_gen`.`popularity_rate` = 'The Established Track'
                 AND `musician_gen`.`followers_rate` = 'Niche Star'
                THEN 'Regular Artist'

            WHEN `musician_gen`.`popularity_rate` = 'The Certified Hit'
                 AND `musician_gen`.`followers_rate` = 'Mainstream Star'
                THEN 'Regular Artist'

            WHEN `musician_gen`.`popularity_rate` = 'The Certified Hit'
                 AND `musician_gen`.`followers_rate` = 'Established Act'
                THEN 'Regular Artist'

            WHEN `musician_gen`.`popularity_rate` = 'The Certified Hit'
                 AND `musician_gen`.`followers_rate` = 'Emerging Artist'
                THEN 'Regular Artist'

            WHEN `musician_gen`.`popularity_rate` = 'The Certified Hit'
                 AND `musician_gen`.`followers_rate` = 'Niche Star'
                THEN 'Regular Artist'
        END
    ) AS `commercial_metrics`

FROM 
    `musician_gen`;
