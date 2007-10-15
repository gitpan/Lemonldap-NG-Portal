create table taccounts
(
        id_account int NOT NULL AUTO_INCREMENT,
        uid blob NOT NULL,
        identity_dump blob NULL,
        timestamp TIMESTAMP,
        divers blob NULL,
        unique index (id_account),
        primary key (id_account)
);

