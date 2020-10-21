CREATE DATABASE puppylove;

\c 

CREATE TABLE users(id SERIAL PRIMARY KEY, username VARCHAR(50), email TEXT, password_digest TEXT);

CREATE TABLE dogs(id SERIAL PRIMARY KEY, username VARCHAR(50), image_url TEXT, age INTEGER, gender VARCHAR(20), breed VARCHAR(50), loves TEXT, about TEXT, looking_for TEXT, loc_state VARCHAR(50), loc_suburb VARCHAR(50), loc_country VARCHA(50);)