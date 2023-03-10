CREATE SCHEMA "master";

CREATE SCHEMA "netflix";

CREATE TYPE "master"."mpa_rating" AS ENUM (
  'G',
  'PG',
  'PG_13',
  'R',
  'NC_17',
  'TV_MA',
  'TV_14',
  'TV_PG',
  'TV_Y',
  'TV_G',
  'TV_Y7',
  'NOT_RATED'
);

CREATE TYPE "master"."credit_type" AS ENUM (
  'ACTOR',
  'DIRECTOR'
);

CREATE TYPE "master"."reaction" AS ENUM (
  'LIKE',
  'DISLIKE'
);

CREATE TYPE "master"."title_type" AS ENUM (
  'MOVIE',
  'SHOW'
);

CREATE TABLE "master"."countries" (
  "id" INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  "country_code" varchar(2) UNIQUE NOT NULL,
  "country_name" varchar(100) UNIQUE,
  "region" varchar(100),
  "sub_region" varchar(100),
  "created_by" int DEFAULT 1,
  "created_at" timestamp DEFAULT (now()),
  "updated_by" int DEFAULT 1,
  "updated_at" timestamp DEFAULT (now())
);

CREATE TABLE "master"."genre" (
  "id" INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  "genre" varchar(20) NOT NULL,
  "created_by" int DEFAULT 1,
  "created_at" timestamp DEFAULT (now()),
  "updated_by" int DEFAULT 1,
  "updated_at" timestamp DEFAULT (now())
);

CREATE TABLE "master"."users" (
  "id" INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  "username" varchar(25),
  "password" varchar(255),
  "active" boolean DEFAULT true,
  "is_admin" boolean DEFAULT false,
  "last_logged_in" timestamp DEFAULT (now())
);

CREATE TABLE "netflix"."titles_countries" (
  "title_id" int NOT NULL,
  "country_id" int NOT NULL,
  PRIMARY KEY ("country_id", "title_id")
);

CREATE TABLE "netflix"."titles_genre" (
  "title_id" int NOT NULL,
  "genre_id" int NOT NULL,
  PRIMARY KEY ("genre_id", "title_id")
);

CREATE TABLE "netflix"."titles" (
  "id" INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  "title" varchar(255) NOT NULL,
  "type" master.title_type NOT NULL,
  "release_year" int NOT NULL,
  "mpa_rating" master.mpa_rating NOT NULL,
  "runtime" int NOT NULL,
  "seasons" float8,
  "imdb_id" varchar(10) UNIQUE,
  "imdb_score" float8,
  "imdb_votes" int
);

CREATE TABLE "netflix"."people" (
  "id" INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  "name" varchar(255) NOT NULL
);

CREATE TABLE "netflix"."credits" (
  "id" INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  "title_id" int NOT NULL,
  "person_id" int NOT NULL,
  "character" text,
  "role" master.credit_type NOT NULL
);

CREATE TABLE "netflix"."titles_likes" (
  "user_id" int NOT NULL,
  "title_id" int NOT NULL,
  "reaction" master.reaction NOT NULL,
  PRIMARY KEY ("user_id", "title_id")
);

CREATE TABLE "netflix"."people_likes" (
  "user_id" int NOT NULL,
  "person_id" int NOT NULL,
  "reaction" master.reaction NOT NULL,
  PRIMARY KEY ("user_id", "person_id")
);

COMMENT ON COLUMN "master"."countries"."country_code" IS 'alpha-2';

COMMENT ON COLUMN "netflix"."titles"."runtime" IS 'in minutes';

ALTER TABLE "netflix"."titles_countries" ADD FOREIGN KEY ("title_id") REFERENCES "netflix"."titles" ("id") ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "netflix"."titles_countries" ADD FOREIGN KEY ("country_id") REFERENCES "master"."countries" ("id") ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "netflix"."titles_genre" ADD FOREIGN KEY ("title_id") REFERENCES "netflix"."titles" ("id") ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "netflix"."titles_genre" ADD FOREIGN KEY ("genre_id") REFERENCES "master"."genre" ("id") ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "netflix"."credits" ADD FOREIGN KEY ("person_id") REFERENCES "netflix"."people" ("id") ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "netflix"."credits" ADD FOREIGN KEY ("title_id") REFERENCES "netflix"."titles" ("id") ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "netflix"."titles_likes" ADD FOREIGN KEY ("user_id") REFERENCES "master"."users" ("id") ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "netflix"."titles_likes" ADD FOREIGN KEY ("title_id") REFERENCES "netflix"."titles" ("id") ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "netflix"."people_likes" ADD FOREIGN KEY ("user_id") REFERENCES "master"."users" ("id") ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "netflix"."people_likes" ADD FOREIGN KEY ("person_id") REFERENCES "netflix"."people" ("id") ON DELETE CASCADE ON UPDATE NO ACTION;


-- Copy from CSV
BEGIN;
COPY master.genre(genre)
FROM '/etc/processed_data/genres.csv'
DELIMITER ','
CSV HEADER;


COPY master.countries(country_name,country_code,region,sub_region)
FROM '/etc/processed_data/countries.csv'
DELIMITER ','
CSV HEADER;

COPY master.users(username, password, active, is_admin)
FROM '/etc/processed_data/users.csv'
DELIMITER ','
CSV HEADER;


COPY netflix.people(name)
FROM '/etc/processed_data/people.csv'
DELIMITER ','
CSV HEADER;

COPY netflix.titles(title,type,release_year,mpa_rating,runtime,seasons,imdb_id,imdb_score,imdb_votes)
FROM '/etc/processed_data/titles.csv'
DELIMITER ','
CSV HEADER;

COPY netflix.credits(title_id,person_id,character,role)
FROM '/etc/processed_data/credits.csv'
DELIMITER ','
CSV HEADER;

COPY netflix.people_likes(person_id,user_id,reaction)
FROM '/etc/processed_data/people_likes.csv'
DELIMITER ','
CSV HEADER;

COPY netflix.titles_genre(title_id,genre_id)
FROM '/etc/processed_data/titles_genres.csv'
DELIMITER ','
CSV HEADER;

COPY netflix.titles_likes(title_id,user_id,reaction)
FROM '/etc/processed_data/titles_likes.csv'
DELIMITER ','
CSV HEADER;

COMMIT;

