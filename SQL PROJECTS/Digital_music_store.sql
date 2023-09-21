--###Create Tables###

CREATE TABLE Album
(
    AlbumId INT NOT NULL,
    Title VARCHAR(160) NOT NULL,
    ArtistId INT NOT NULL,
    CONSTRAINT PK_Album PRIMARY KEY  (AlbumId)
);

CREATE TABLE Artist
(
    ArtistId INT NOT NULL,
    Name VARCHAR(120),
    CONSTRAINT PK_Artist PRIMARY KEY  (ArtistId)
);

CREATE TABLE Customer
(
    CustomerId INT NOT NULL,
    FirstName VARCHAR(40) NOT NULL,
    LastName VARCHAR(20) NOT NULL,
    Company VARCHAR(80),
    Address VARCHAR(70),
    City VARCHAR(40),
    State VARCHAR(40),
    Country VARCHAR(40),
    PostalCode VARCHAR(10),
    Phone VARCHAR(24),
    Fax VARCHAR(24),
    Email VARCHAR(60) NOT NULL,
    SupportRepId INT,
    CONSTRAINT PK_Customer PRIMARY KEY  (CustomerId)
);

CREATE TABLE Employee
(
    EmployeeId INT NOT NULL,
    LastName VARCHAR(20) NOT NULL,
    FirstName VARCHAR(20) NOT NULL,
    Title VARCHAR(30),
    ReportsTo INT,
    BirthDate DATE,
    HireDate DATE,
    Address VARCHAR(70),
    City VARCHAR(40),
    State VARCHAR(40),
    Country VARCHAR(40),
    PostalCode VARCHAR(10),
    Phone VARCHAR(24),
    Fax VARCHAR(24),
    Email VARCHAR(60),
    CONSTRAINT PK_Employee PRIMARY KEY  (EmployeeId)
);

CREATE TABLE Genre
(
    GenreId INT NOT NULL,
    Name VARCHAR(120),
    CONSTRAINT "PK_Genre" PRIMARY KEY  (GenreId)
);

CREATE TABLE Invoice
(
    InvoiceId INT NOT NULL,
    CustomerId INT NOT NULL,
    InvoiceDate DATE NOT NULL,
    BillingAddress VARCHAR(70),
    BillingCity VARCHAR(40),
    BillingState VARCHAR(40),
    BillingCountry VARCHAR(40),
    BillingPostalCode VARCHAR(10),
    Total NUMERIC(10,2) NOT NULL,
    CONSTRAINT PK_Invoice PRIMARY KEY  (InvoiceId)
);

CREATE TABLE InvoiceLine
(
    InvoiceLineId INT NOT NULL,
    InvoiceId INT NOT NULL,
    TrackId INT NOT NULL,
    UnitPrice NUMERIC(10,2) NOT NULL,
    Quantity INT NOT NULL,
    CONSTRAINT PK_InvoiceLine PRIMARY KEY  (InvoiceLineId)
);

CREATE TABLE MediaType
(
    MediaTypeId INT NOT NULL,
    Name VARCHAR(120),
    CONSTRAINT PK_MediaType PRIMARY KEY  (MediaTypeId)
);

CREATE TABLE Playlist
(
    PlaylistId INT NOT NULL,
    Name VARCHAR(120),
    CONSTRAINT PK_Playlist PRIMARY KEY  (PlaylistId)
);

CREATE TABLE PlaylistTrack
(
    PlaylistId INT NOT NULL,
    TrackId INT NOT NULL,
    CONSTRAINT PK_PlaylistTrack PRIMARY KEY  (PlaylistId, TrackId)
);

CREATE TABLE Track
(
    TrackId INT NOT NULL,
    Name VARCHAR(200) NOT NULL,
    AlbumId INT,
    MediaTypeId INT NOT NULL,
    GenreId INT,
    Composer VARCHAR(220),
    Milliseconds INT NOT NULL,
    Bytes INT,
    UnitPrice NUMERIC(10,2) NOT NULL,
    CONSTRAINT PK_Track PRIMARY KEY  (TrackId)
);

--####Create Primary Key Unique Indexes###

--Create Foreign Keys

--ALTER TABLE Album ADD CONSTRAINT FK_AlbumArtistId
  -- FOREIGN KEY (ArtistId) REFERENCES Artist (ArtistId) ON DELETE NO ACTION ON UPDATE NO ACTION;

--CREATE INDEX IFK_AlbumArtistId ON Album (ArtistId);

-- #####Populate Tables###

--INSERT INTO Genre (GenreId, Name) VALUES (1, N'Rock');

--I populate tables via import/export data

--SQL QUESTIONS (SET 1)

/* Question 1: Which countries have the most Invoices?*/

SELECT billingcountry,COUNT(billingcountry) AS country_invoice
FROM invoice
GROUP BY billingcountry
ORDER BY country_invoice DESC;

/* Question 2: Which city has the best customers?*/

SELECT billingcity,SUM(total) AS InvoiceTotal
FROM invoice
GROUP BY billingcity
ORDER BY InvoiceTotal DESC
LIMIT 1;

/*Question 3: Who is the best customer?*/

SELECT customer.customerid, firstname, lastname, SUM(total) AS total_spending
FROM customer
JOIN invoice ON customer.customerid = invoice.customerid
GROUP BY (customer.customerid)
ORDER BY total_spending DESC
LIMIT 1;

--SQL QUESTIONS (SET 2)

/*return the email, first name, last name, and Genre of all Rock Music listeners.
Return your list ordered alphabetically by email address starting with A.*/

/*Sol 1:*/
SELECT DISTINCT email,first_name, last_name
FROM customer
JOIN invoice ON customer.customerid = invoice.customerid
JOIN invoiceline ON invoice.invoiceid = invoiceline.invoiceid
WHERE trackid IN(
	SELECT trackid FROM track
	JOIN genre ON track.genreid = genre.genreid
	WHERE genre.name LIKE 'Rock'
);


/*Sol2:*/
SELECT DISTINCT email,firstname, lastname, genre.name AS G_Name
FROM customer
JOIN invoice ON invoice.customerid = customer.customerid
JOIN invoiceline ON invoiceline.invoiceid = invoice.invoiceid
JOIN track ON track.trackid = invoiceline.trackid
JOIN genre ON genre.genreid = track.genreid
WHERE genre.name LIKE 'Rock';

/*Question 2: Who is writing the rock music?
returns the Artist name and total track count of the top 10 rock bands.*/

SELECT artist.artistid, artist.name,COUNT(artist.artistid) AS number_of_songs
FROM track
JOIN album ON album.albumid = track.albumid
JOIN artist ON artist.artistid = album.artistid
JOIN genre ON genre.genreid = track.genreid
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artistid
ORDER BY number_of_songs DESC
LIMIT 10;

/*Question 3
First, find which artist has earned the most according to the InvoiceLines?
Now use this artist to find which customer spent the most on this artist.
For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, Album, and Artist tables.
Notice, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, 
and then multiply this by the price for each artist.*/

;WITH tbl_best_selling_artist AS(
	SELECT artist.artistid AS artistid,artist.name AS artistname,SUM(invoiceline.unitprice*invoiceline.quantity) AS total_sales
	FROM invoiceline
	JOIN track ON track.trackid = invoiceline.trackid
	JOIN album ON album.albumid = track.albumid
	JOIN artist ON artist.artistid = album.artistid
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)

SELECT bsa.artistname,SUM(il.unitprice*il.quantity) AS amount_spent,c.customerid,c.firstname,c.lastname
FROM invoice i
JOIN customer c ON c.customerid = i.customerid
JOIN invoiceline il ON il.invoiceid = i.invoiceid
JOIN track t ON t.trackid = il.trackid
JOIN album alb ON alb.albumid = t.albumid
JOIN tbl_best_selling_artist bsa ON bsa.artistid = alb.artistid
GROUP BY 1,3,4,5
ORDER BY 2 DESC;

--SQL QUESTIONS (SET 3)

/*Question 1:
We want to find out the most popular music Genre for each country. 
We determine the most popular genre as the genre with the highest amount of purchases. 
Write a query that returns each country along with the top Genre. 
For countries where the maximum number of purchases is shared return all Genres.*/

/*sales for each country*/
SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genreid
FROM invoiceline
JOIN invoice ON invoice.invoiceid = invoiceline.invoiceid
JOIN customer ON customer.customerid = invoice.customerid
JOIN track ON track.trackid = invoiceline.trackid
JOIN genre ON genre.genreid = track.genreid
GROUP BY 2,3,4
ORDER BY 2;

;WITH RECURSIVE
	tbl_sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genreid
		FROM invoiceline
		JOIN invoice ON invoice.invoiceid = invoiceline.invoiceid
		JOIN customer ON customer.customerid = invoice.customerid
		JOIN track ON track.trackid = invoiceline.trackid
		JOIN genre ON genre.genreid = track.genreid
		GROUP BY 2,3,4
		ORDER BY 2
	)
	,tbl_max_genre_per_country AS(SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM tbl_sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT tbl_sales_per_country.* 
FROM tbl_sales_per_country
JOIN tbl_max_genre_per_country ON tbl_sales_per_country.country = tbl_max_genre_per_country.country
WHERE tbl_sales_per_country.purchases_per_genre = tbl_max_genre_per_country.max_genre_number;


/*max genre for each country */

;WITH RECURSIVE
	tbl_sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genreid
		FROM invoiceline
		JOIN invoice ON invoice.invoiceid = invoiceline.invoiceid
		JOIN customer ON customer.customerid = invoice.customerid
		JOIN track ON track.trackid = invoiceline.trackid
		JOIN genre ON genre.genreid = track.genreid
		GROUP BY 2,3,4
		ORDER BY 2
)
SELECT MAX(purchases_per_genre) AS max_genre_number, country
FROM tbl_sales_per_country
GROUP BY 2
ORDER BY 2 desc;

/*Question 2:
Return all the track names that have a song length longer than the average song length. 
Though you could perform this with two queries. 
Imagine you wanted your query to update based on when new data is put in the database. 
Therefore, you do not want to hard code the average into your query. You only need the Track table to complete this query.
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.*/

SELECT name,milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track)
ORDER BY milliseconds DESC;


/*Question 3:
Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount.
You should only need to use the Customer and Invoice tables.*/

;WITH RECURSIVE 
	tbl_customter_with_country AS (
		SELECT customer.customerid,firstname,lastname,billingcountry,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customerid = invoice.customerid
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	tbl_country_max_spending AS(
		SELECT billingcountry,MAX(total_spending) AS max_spending
		FROM tbl_customter_with_country
		GROUP BY billingcountry)

SELECT tbl_cc.billingcountry, tbl_cc.total_spending,tbl_cc.firstname,tbl_cc.lastname,tbl_cc.customerid
FROM tbl_customter_with_country tbl_cc
JOIN tbl_country_max_spending tbl_ms
ON tbl_cc.billingcountry = tbl_ms.billingcountry
WHERE tbl_cc.total_spending = tbl_ms.max_spending
ORDER BY 1;