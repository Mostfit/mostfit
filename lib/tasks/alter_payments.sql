-- Added desktop_id and origin field in payments table -------

alter table payments add (desktop_id int(11), origin varchar(50) default 'server');
alter table clients add (fingerprint_file_name varchar(50), fingerprint_content_type varchar(50), fingerprint_file_size int(11), fingerprint_updated_at datetime);
alter table attendances add (desktop_id int(11), origin varchar(50) default 'server');