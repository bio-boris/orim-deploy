table geneLocations(
	id INT NOT NULL AUTO_INCREMENT,
	g_id varchar(255) RIMARY KEY NOT NULL,
	o_id 		varchar(255) not null,
	c_id 		varchar(255) not null,
	start		varchar(255) not null,
	stop		varchar(255) not null,
	PRIMARY KEY (g_id)
)
