SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema emoindiepunktracker
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `emoindiepunktracker` DEFAULT CHARACTER SET utf8 ;
USE `emoindiepunktracker` ;

-- -----------------------------------------------------album_artists
-- Table `artists`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `emoindiepunktracker`.`artists` (
  `spotify_id` VARCHAR(50) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `popularity` INT NULL,
  `followers` INT NULL,
  `fetched_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`spotify_id`))
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `albums`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `emoindiepunktracker`.`albums` (
  `spotify_id` VARCHAR(50) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `album_type` VARCHAR(20) NULL,
  `total_tracks` INT NULL,
  `release_date` VARCHAR(30) NULL,
  `fetched_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`spotify_id`))
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `tracks`
-- (This now has the 'album_id' foreign key)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `emoindiepunktracker`.`tracks` (
  `spotify_id` VARCHAR(50) NOT NULL,
  `album_id` VARCHAR(50) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `popularity` INT NULL,
  `duration_ms` INT NULL,
  `track_number` INT NULL,
  `explicit` TINYINT NULL,
  `fetched_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`spotify_id`),
  INDEX `fk_tracks_albums_idx` (`album_id` ASC) VISIBLE,
  CONSTRAINT `fk_tracks_albums`
    FOREIGN KEY (`album_id`)
    REFERENCES `emoindiepunktracker`.`albums` (`spotify_id`))
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `audio_features` (This was your 'vibe' table)
-- (This now has a clean 1-to-1 relationship)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `emoindiepunktracker`.`audio_features` (
  `track_id` VARCHAR(50) NOT NULL,
  `danceability` FLOAT NULL,
  `energy` FLOAT NULL,
  `loudness` FLOAT NULL,
  `speechiness` FLOAT NULL,
  `acousticness` FLOAT NULL,
  `instrumentalness` FLOAT NULL,
  `liveness` FLOAT NULL,
  `valence` FLOAT NULL,
  `tempo` FLOAT NULL,
  PRIMARY KEY (`track_id`),
  CONSTRAINT `fk_audio_features_tracks`
    FOREIGN KEY (`track_id`)
    REFERENCES `emoindiepunktracker`.`tracks` (`spotify_id`))
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `genres`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `emoindiepunktracker`.`genres` (
  `id_genre` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`id_genre`),
  UNIQUE INDEX `name_UNIQUE` (`name` ASC) VISIBLE)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `album_artists` (Cleaned Join Table)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `emoindiepunktracker`.`album_artists` (
  `album_id` VARCHAR(50) NOT NULL,
  `artist_id` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`album_id`, `artist_id`),
  INDEX `fk_album_artists_artists_idx` (`artist_id` ASC) VISIBLE,
  CONSTRAINT `fk_album_artists_albums`
    FOREIGN KEY (`album_id`)
    REFERENCES `emoindiepunktracker`.`albums` (`spotify_id`),
  CONSTRAINT `fk_album_artists_artists`
    FOREIGN KEY (`artist_id`)
    REFERENCES `emoindiepunktracker`.`artists` (`spotify_id`))
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `artist_genres` (Cleaned Join Table)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `emoindiepunktracker`.`artist_genres` (
  `artist_id` VARCHAR(50) NOT NULL,
  `genre_id` INT NOT NULL,
  PRIMARY KEY (`artist_id`, `genre_id`),
  INDEX `fk_artist_genres_genres_idx` (`genre_id` ASC) VISIBLE,
  CONSTRAINT `fk_artist_genres_artists`
    FOREIGN KEY (`artist_id`)
    REFERENCES `emoindiepunktracker`.`artists` (`spotify_id`),
  CONSTRAINT `fk_artist_genres_genres`
    FOREIGN KEY (`genre_id`)
    REFERENCES `emoindiepunktracker`.`genres` (`id_genre`))
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `track_artists` (Cleaned Join Table)
-- (This now correctly links tracks <-> artists)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `emoindiepunktracker`.`track_artists` (
  `track_id` VARCHAR(50) NOT NULL,
  `artist_id` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`track_id`, `artist_id`),
  INDEX `fk_track_artists_artists_idx` (`artist_id` ASC) VISIBLE,
  CONSTRAINT `fk_track_artists_tracks`
    FOREIGN KEY (`track_id`)
    REFERENCES `emoindiepunktracker`.`tracks` (`spotify_id`),
  CONSTRAINT `fk_track_artists_artists`
    FOREIGN KEY (`artist_id`)
    REFERENCES `emoindiepunktracker`.`artists` (`spotify_id`))
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
