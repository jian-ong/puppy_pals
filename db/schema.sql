CREATE DATABASE puppylove;

\c 

CREATE TABLE users(id SERIAL PRIMARY KEY, email TEXT, password_digest TEXT);

CREATE TABLE dogs(
    id SERIAL PRIMARY KEY, 
    username VARCHAR(50), 
    image_url TEXT, 
    age TEXT, 
    gender VARCHAR(20), 
    breed VARCHAR(50), 
    bio TEXT,
    loc_suburb VARCHAR(50), 
    loc_state VARCHAR(50), 
    loc_country VARCHAR(50), 
    likes INTEGER,
    user_id INTEGER
);

ALTER TABLE dogs DROP COLUMN email;

SELECT * FROM dogs
    WHERE username ILIKE '%%'
    AND age ILIKE '%%'
AND breed ILIKE '%%'
AND bio ILIKE '%%'
AND (loc_suburb ILIKE '%new south wales%'
OR loc_state ILIKE '%new south wales%'
OR loc_country ILIKE '%new south wales%')
;