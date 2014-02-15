create table annotations{
	id int NOT NULL AUTO_INCREMENT,
	g_id varchar(255) NOT NULL,
	g_acession varchar(255) NOT NULL,
	o_id varchar(255) NOT NULL,
	annotation varchar(255) NOT NULL,
	annotation_value varchar(255) NOT NULL,
	PRIMARY KEY(gid,oid)
}
