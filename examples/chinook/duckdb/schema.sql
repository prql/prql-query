


CREATE TABLE playlists(playlist_id INTEGER, "name" VARCHAR);
CREATE TABLE playlist_track(playlist_id INTEGER, track_id INTEGER);
CREATE TABLE genres(genre_id INTEGER, "name" VARCHAR);
CREATE TABLE albums(album_id INTEGER, title VARCHAR, artist_id INTEGER);
CREATE TABLE tracks(track_id INTEGER, "name" VARCHAR, album_id INTEGER, media_type_id INTEGER, genre_id INTEGER, composer VARCHAR, "milliseconds" INTEGER, bytes INTEGER, unit_price DOUBLE);
CREATE TABLE invoice_items(invoice_line_id INTEGER, invoice_id INTEGER, track_id INTEGER, unit_price DOUBLE, quantity INTEGER);
CREATE TABLE artists(artist_id INTEGER, "name" VARCHAR);
CREATE TABLE employees(employee_id INTEGER, last_name VARCHAR, first_name VARCHAR, title VARCHAR, reports_to INTEGER, birth_date TIMESTAMP, hire_date TIMESTAMP, address VARCHAR, city VARCHAR, state VARCHAR, country VARCHAR, postal_code VARCHAR, phone VARCHAR, fax VARCHAR, email VARCHAR);
CREATE TABLE customers(customer_id INTEGER, first_name VARCHAR, last_name VARCHAR, company VARCHAR, address VARCHAR, city VARCHAR, state VARCHAR, country VARCHAR, postal_code VARCHAR, phone VARCHAR, fax VARCHAR, email VARCHAR, support_rep_id INTEGER);
CREATE TABLE invoices(invoice_id INTEGER, customer_id INTEGER, invoice_date TIMESTAMP, billing_address VARCHAR, billing_city VARCHAR, billing_state VARCHAR, billing_country VARCHAR, billing_postal_code VARCHAR, total DOUBLE);
CREATE TABLE media_types(media_type_id INTEGER, "name" VARCHAR);




