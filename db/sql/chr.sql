create table chr(
	id INT NOT NULL AUTO_INCREMENT,
	o_id		varchar(255) not null,
	c_id	varchar(255) not null,
	mrna_start   int not null,
	mrna_stop	int not null,
	PRIMARY KEY (o_id,c_id)
);

