table chr(
	id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
	phytozomeName 	varchar(255) not null	,
	marker_name	varchar(255) not null	,
	marker_type	varchar(255) 		,
	chr 		varchar(255) not null	,
	start		int not null		,
	stop		int not null	
)
