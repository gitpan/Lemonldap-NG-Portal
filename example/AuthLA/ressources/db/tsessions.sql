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


