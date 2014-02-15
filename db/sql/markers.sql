table markers(
	id INT NOT NULL AUTO_INCREMENT,
	m_id		varchar(255) NOT NULL
	marker_type	varchar(255) 		,
	c_id 		varchar(255) NOT null	,
	start		int not null NOT NULL	,
	stop		int not null NOT NULL	,
	o_id		varchar(255) NOT NULL,
	PRIMARY KEY (m_id)
)
