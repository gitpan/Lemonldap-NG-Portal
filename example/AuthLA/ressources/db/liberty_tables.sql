create table taccounts
(
        id_account int NOT NULL AUTO_INCREMENT,
	uid blob NOT NULL,
        identity_dump blob NOT NULL,
        timestamp TIMESTAMP,
        divers blob NULL,
        unique index (id_account),
        primary key (id_account)
);

create table tnameid
(
        id_nameid int NOT NULL AUTO_INCREMENT,
	nameid varchar(100) NOT NULL, 
	id_account int NOT NULL,
        timestamp TIMESTAMP,
        divers blob NULL,
        unique index (id_nameid),
        primary key (id_nameid)
);

create table tsessions
(
	id_session int NOT NULL AUTO_INCREMENT,
        session_nb blob NOT NULL,
        id_account int NOT NULL,
	id_nameid int NOT NULL,
        session_dump blob NULL,
        timestamp TIMESTAMP,
        divers blob NULL,
        unique index (id_session),
        primary key (id_session)
);



