create database if not exists app_simulation;
use app_simulation;
-- drop table users;
create table if not exists users(
		user_id INT primary key,
		install_date DATETIME,
		channel VARCHAR(30),
		device_os VARCHAR(10),
		inviter_id INT,
		activated INT,
		index idx_user_id (user_id)
);
create table if not exists orders(
		order_id INT primary key,
		user_id INT,
		order_time DATETIME,
		amount DECIMAL(10,2),
		index idx_user_id (user_id)		
);
create table if not exists login_log(
		user_id INT,
		login_date DATETIME
);