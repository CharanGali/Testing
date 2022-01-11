-- this sql script is used only for executing the UT cases

CREATE SCHEMA IF NOT EXISTS nicedpsdb;

USE nicedpsdb;

CREATE TABLE IF NOT EXISTS serial_no_table (
id int unsigned NOT NULL AUTO_INCREMENT,
mfr_id varchar(36) NOT NULL COMMENT 'mfr_id',   
serial_number varchar(255) NOT NULL COMMENT 'serial_number', 
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
CONSTRAINT uq_serial_no_table  UNIQUE(mfr_id, serial_number),
PRIMARY KEY (id));