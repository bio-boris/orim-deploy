CREATE TABLE organisms(
	id INT  NOT NULL AUTO_INCREMENT,
	o_id varchar(255) PRIMARY KEY NOT NULL
      	class varchar(255) NOT NULL,
        latin varchar(255) NOT NULL,
	common varchar(255) NOT NULL,
	PRIMARY KEY(o_id)
)
