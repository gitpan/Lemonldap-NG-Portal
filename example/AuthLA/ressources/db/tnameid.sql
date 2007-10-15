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


