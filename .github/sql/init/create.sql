CREATE SCHEMA IF NOT EXISTS nicedpsdb;

USE nicedpsdb;

-- crl_table
CREATE TABLE IF NOT EXISTS crl_table(
  id int unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
  crl_url varchar(255) NOT NULL UNIQUE COMMENT 'crl_url',
	this_update TIMESTAMP NOT NULL  COMMENT 'this_update',
  next_update TIMESTAMP NOT NULL COMMENT 'next_update',
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ,
	updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT crl_table_PKC PRIMARY KEY (id)
) COMMENT 'crl_table';

-- revoked_list_table 

CREATE TABLE IF NOT EXISTS revoked_list_table (
	id int unsigned NOT NULL AUTO_INCREMENT  COMMENT 'id',
  serial_number varchar(255) NOT NULL UNIQUE  COMMENT 'serial_number',   
  revoked_date TIMESTAMP NOT NULL  COMMENT 'revoked_date', 
  crl_reasoncode varchar(10) NOT NULL COMMENT 'crl_reasoncode',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT revoked_list_table_PKC PRIMARY KEY (id)
  );