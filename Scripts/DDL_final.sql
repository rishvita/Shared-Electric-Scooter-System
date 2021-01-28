---- creating Scooter table
create table Scooter
(
Scooter_id bigint  IDENTITY(10000,1),
ModelNumber Varchar(50),
Make_Model_Year Integer ,
Status_in_Use Varchar(1),
Constraint  Scooter_pk Primary key  (Scooter_id),
constraint ModelNumber_chk check (substring(ModelNumber,1,1)='B' and isnumeric(substring(ModelNumber,2,len(ModelNumber)))!=0 and len(ModelNumber)>=5) ,
constraint status_chk check (Status_in_Use in ('Y','N'))
);

--- creating service table 
create table Service(
Service_id Varchar(25)  ,
Service_Type Varchar(50),
Constraint  Service_pk Primary key  (Service_id),
constraint ServiceId_chk check (substring(Service_id,1,1)='S' and isnumeric(substring(Service_id,2,len(Service_id)))!=0 and len(Service_id)>=5) 
);

---- create table docking station 
create table Docking_Station(
Station_ID Varchar(25),
Station_Name Varchar(255),
Station_Address Varchar(255),
Coordinates geography,
Docking_Capacity int ,
Station_Status Varchar(1)
Constraint  Station_pk Primary key  (Station_ID),
Constraint  Station_Status_pk check (Station_Status in ('Y','N')),
constraint StationId_chk check (substring(Station_ID,1,2)='DS' and isnumeric(substring(Station_ID,3,len(Station_ID)))!=0 and len(Station_ID)>=5));


--- creating fares table 
CREATE TABLE Fares(
Fare_ID VARCHAR(25)	NOT NULL,
[Time] int	not null,
Amount MONEY NOT NULL
CONSTRAINT Fares_PK PRIMARY KEY (Fare_ID),
constraint chk_fareid CHECK (SUBSTRING(Fare_ID,1,1)='F' and ISNUMERIC(SUBSTRING(Fare_ID,2,LEN(Fare_ID)))!=0 and LEN(Fare_ID)>=5));

--- creating a function to calculate the duration 
create function dbo.duration_calculation(@Start_Time Datetime2,@End_Time Datetime2)
returns int
as
begin
return datediff(hour,@Start_Time,@End_Time)
end

--- creating function to derive fareid for the time 
create function dbo.fare_calculation(@Duration  datetime)
returns varchar(25)
as
begin
Declare @fareid varchar(25)
select @fareid=Fare_ID 
from Fares 
where @Duration=[Time]
return @fareid
end

--- creating rides table 

create table Ride(
Ride_id int IDENTITY(1,1),
Start_Station_Id Varchar(25),
End_Station_Id Varchar(25),
Start_Time Datetime  ,
End_Time Datetime  ,
Scooter_Id bigint Not Null,
Account_Id varchar(25) not null,
Fare_id as dbo.fare_calculation(dbo.duration_calculation(Start_Time,End_Time)),
Duration AS dbo.duration_calculation(Start_Time,End_Time),
Constraint  Ride_pk Primary key  (Ride_id),
Constraint Scooter_fk foreign key (Scooter_Id) references Scooter(Scooter_Id),
Constraint Start_station_fk foreign key (Start_Station_ID) references Docking_Station(Station_Id),
Constraint End_station_fk foreign key (End_Station_ID) references Docking_Station(Station_Id),
constraint account_id_fk foreign key (Account_id) references Account(Account_Id)
);




--- creating scooter_docking_history table 
create table Scooter_Docking_History(
Scooter_Id bigint not null,
Station_Id Varchar(25) not null,
Start_Date_Time Datetime  ,
End_Date_Time Datetime  ,
Duration AS dbo.duration_calculation(Start_Date_Time,End_Date_Time),
Constraint Scooter_Docking_Histoy_pk primary key (Scooter_Id,Station_Id, start_date_time),
Constraint Station_Id_fk foreign key (Station_ID) references Docking_Station(Station_Id),
Constraint Scooter_Id_fk foreign key (Scooter_Id) references Scooter(Scooter_Id), 
);

--- creating employee table
create table Employee
(employee_id varchar(25) not null ,
employee_name varchar(50) ,
employee_address varchar(255),
employee_email varchar(50),
employee_phone bigint,
constraint chk_emp_id check(substring(employee_id,1,1)='E' and substring(employee_id, 2, len(employee_id)) like '%[0-9]%' 
and len(employee_id) >=5),
constraint chk_phn_no check(len(employee_phone) = 10 ),
constraint chk_email check( employee_email like '%@%.%'),
constraint pk_emp_id primary key (employee_id));

---- creating service_location table
create table Service_Location(
location_id varchar(25) not null,
location_name varchar(50),
location_address varchar(255)
constraint id_pk primary key (location_id),
constraint chk_loc_id check(substring(location_id,1,2)='SL' and substring(location_id, 3, len(location_id)) like '%[0-9]%' 
and len(location_id) >=5));

-- create useres table
CREATE TABLE Users(
User_ID		VARCHAR(25)	NOT NULL,
Username	VARCHAR(50)			,
First_Name	VARCHAR(50)			,
Last_Name	VARCHAR(50)			,
Phone_Number	BIGINT unique			,
Email		VARCHAR(50)			,
CONSTRAINT Users_PK PRIMARY KEY(User_ID),
constraint chk_userid CHECK (SUBSTRING(User_ID,1,1)='U' and ISNUMERIC(SUBSTRING(User_ID,2,LEN(User_ID)))!=0 and LEN(User_ID)>=5),
CONSTRAINT Users_Email  CHECK(Email LIKE '%___@___%'),
constraint phone_chk check(len(phone_number) =10));

--- create account table 

create table Account(
account_id varchar(25) not null, 
account_balance money
constraint account_pk primary key (account_id)
constraint account_fk foreign key (account_id) references users(user_id)
);



--- creating triggers so that the value is deleted into the account table when value is deleted in users table
create trigger Account_delete on dbo.users
for delete
as
begin
delete from dbo.Account where Account_ID=(select i.User_ID  from deleted i)
end

--- creating triggers so that the value is inserted into the account table when value is inserted in users table
create trigger Account_insert on users
for insert
as
begin
insert into dbo.Account(Account_ID,Account_Balance)
select i.User_ID,0  from inserted i
end

--- creating trigger to update the amount balance from payment table  
create trigger dbo.amount_update on dbo.payment
for insert
as
begin
update account 
set account_balance = sum_amount 
from account a join (select account_id , sum(amount) sum_amount from payment group by account_id) t on a.account_id = t.account_id
end

select * from Account;

--- create payment table 
drop table payment;
create table Payment(
payment_id varchar(25) not null,
payment_option int ,
account_id varchar(25) not null,
amount money not null,
constraint payment_pk primary key (payment_id),
constraint payment_fk foreign key (account_id) references Account (account_id),
constraint chk_option check (payment_option in (1,2)));

--- create table card payment

create table Card_Payment(
payment_id varchar(25) not null,
card_number char(16) not null,
card_name varchar(25) not null,
cvv int not null,
exp_date varchar(6) not null
constraint payment_id_pk primary key(payment_id),
constraint payment_id_fk foreign key(payment_id) references payment(payment_id),
constraint chk_card_number check( len(card_number) = 16 )
);


--- create table digital payment
drop table Digital_Payment;
CREATE TABLE Digital_Payment(
Payment_ID	varchar(25)	NOT NULL,
Wallet_Name	VARCHAR(255)	,
Wallet_User_Name	VARCHAR(255)	,
CONSTRAINT DigitalPayment_PK PRIMARY KEY (Payment_ID),
CONSTRAINT DigitalPayment_FK FOREIGN KEY (Payment_ID) REFERENCES Payment(Payment_ID));

--- create table service record

CREATE TABLE Service_Record(
Service_ID	VARCHAR(25)	NOT NULL,
Scooter_ID	BIGINT		NOT NULL,
Location_ID	VARCHAR(25)	NOT NULL,
Service_Date	DATE	not null,
Service_Duration	int		,
CONSTRAINT ServiceRecord_PK1 PRIMARY KEY (Service_ID, Scooter_ID, Location_ID, service_date) ,
CONSTRAINT ServiceRecord_FK1 FOREIGN KEY (Service_ID) REFERENCES Service(Service_ID),
CONSTRAINT ServiceRecord_FK2 FOREIGN KEY (Scooter_ID) REFERENCES Scooter(Scooter_ID),
CONSTRAINT ServiceRecord_FK3 FOREIGN KEY (Location_ID) REFERENCES Service_Location(Location_ID),
);


--- create table Employee_Service_Record

CREATE TABLE Employee_Service_Record(
Service_ID	VARCHAR(25)	NOT NULL,
Employee_ID	VARCHAR(25)	NOT NULL,
Service_Date date, 
Employee_Work_Duration int,
CONSTRAINT EmployeeServiceRecord_PK1 PRIMARY KEY (Service_ID,Employee_ID,Service_Date),
CONSTRAINT EmployeeServiceRecord_FK1 FOREIGN KEY (Service_ID) REFERENCES Service(Service_ID),
CONSTRAINT EmployeeServiceRecord_FK2 FOREIGN KEY (Employee_ID) REFERENCES Employee(Employee_ID));








