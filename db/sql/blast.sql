create table phytozomeBlast{
	id int NOT NULL AUTO_INCREMENT,
	g_id varchar(255) NOT NULL,
	o_id varchar(255) NOT NULL,
	hit_g_id varchar(255) ,
	hit_o_id varchar(255) NOT NULL,
	hit_id varchar(255),
	hit_eval varchar(255),
	hit_iden varchar(255),
	hit_hit_id varchar(255),
	hit_hit_eval varchar(255),
	hit_hit_iden varchar(255),

	PRIMARY KEY(g_id,o_id)

}
