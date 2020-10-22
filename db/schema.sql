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

insert into dogs(username, image_url, age, gender, breed, hobbies, about, looking_for, loc_suburb, loc_state, loc_country, user_id) VALUES ('Fluffy','https://www.purina.com.au/-/media/project/purina/main/breeds/dog/mobile/dog_samoyed_mobile.jpg?h=300&la=en&w=375&hash=EE6529E6036EFD00F71DA4045ED88F0D', 5, 'Male', 'Samoyed', 'Schmackos, Nanna naps, Walks', $$Hi! My name is Fluffy and I'm a gentle and cheeky big ball of white fluff. I am very sociable and love long walks with my human.$$, $$I am looking for a friend to play frisbee in the parks with, or just to hang out for fun!$$, 'Thornbury','Victoria','Australia', 1 );

insert into dogs(username, image_url, age, gender, breed, hobbies, about, looking_for, loc_suburb, loc_state, loc_country, user_id) VALUES ('Max the Golden Retriever','https://unsplash.com/photos/2s6ORaJY6gI', 6, 'Male', $$Golden Retriever$$, $$Ice cream, Walks, my family's baby humans$$, $$I am Max, a loving Golden Retriever. I am a goofy and silly family dog who loves to play with my 2 human siblings$$, $$I am looking for a friend to share ice creams with.$$, 'Sydney','New South Wales','Australia', 2);

ALTER TABLE dogs DROP COLUMN email;