------------------------------------------------------------ENCRYPTION -------------------------------------------------------------------

----- encryption of the CVV and the card number in card_payment table 
---check for master key
USE master;
GO
SELECT *
FROM sys.symmetric_keys
WHERE name = '##MS_ServiceMasterKey##';
GO
---creating key for project
USE project;
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Password123';
GO

--creating certificate
CREATE CERTIFICATE Certificate1
WITH SUBJECT = 'Protect Data';

--creating key
CREATE SYMMETRIC KEY SymmetricKey1 
WITH ALGORITHM = AES_128 
ENCRYPTION BY CERTIFICATE Certificate1;

select * from Card_Payment;

--encrypt card_number
alter table Card_Payment add card_number_encrypt varbinary(MAX) NULL

OPEN SYMMETRIC KEY SymmetricKey1
DECRYPTION BY CERTIFICATE Certificate1;
GO
UPDATE Card_Payment
SET card_number_encrypt = EncryptByKey (Key_GUID('SymmetricKey1'),card_number)
FROM dbo.Card_Payment;
GO
-- Closes the symmetric key
CLOSE SYMMETRIC KEY SymmetricKey1;

--display card_number values
open SYMMETRIC KEY SymmetricKey1
DECRYPTION BY CERTIFICATE Certificate1;
go
select card_number_encrypt as 'Encrypted Card Num',
CONVERT(varchar, DecryptByKey(card_number_encrypt)) AS 'Decrypted Card Number' from Card_Payment
close SYMMETRIC KEY SymmetricKey1;

--encrypt cvv
alter table Card_Payment add cvv_encrypt varbinary(MAX) NULL

OPEN SYMMETRIC KEY SymmetricKey1
DECRYPTION BY CERTIFICATE Certificate1;
GO
UPDATE Card_Payment
SET cvv_encrypt = EncryptByKey (Key_GUID('SymmetricKey1'),CONVERT(varchar,cvv))
FROM dbo.Card_Payment;
GO
-- Closes the symmetric key
CLOSE SYMMETRIC KEY SymmetricKey1;

select * from card_payment;

--encrypt cvv
alter table Card_Payment add cvv_encrypt varbinary(MAX) NULL

OPEN SYMMETRIC KEY SymmetricKey1
DECRYPTION BY CERTIFICATE Certificate1;
GO
UPDATE Card_Payment
SET cvv_encrypt = EncryptByKey (Key_GUID('SymmetricKey1'),CONVERT(varchar,cvv))
FROM dbo.Card_Payment;
GO
-- Closes the symmetric key
CLOSE SYMMETRIC KEY SymmetricKey1;

select * from card_payment;

------------------------------------------------- VIEWS ----------------------------------------------------------------------
--- payment view:

create view  Payment_View as
select cp.payment_id ,convert(varchar,cp.card_number) as Details,'Card' as [Mode]
from Card_Payment cp
inner join Payment p 
on cp.payment_id=p.payment_id
union 
select dp.payment_id,dp.Wallet_Name as Details,'Digital' as [Mode]
from Digital_Payment dp
inner join Payment p 
on dp.payment_id=p.payment_id

select * from Payment_View;

--- total duration of rides 
create view rides_view as
select s.Scooter_id,coalesce(sum(datepart(hour,(end_time - Start_Time))),0) duration , coalesce(count(service_id),0) as services
from scooter s
left join Ride r on s.Scooter_id = r.Scooter_Id
left join service_record sr on sr.scooter_id = s.Scooter_id
group by s.Scooter_id;

select * from rides_view;

------------------------------------------------- STORED PROCEDURES ------------------------------------------------------------

--- procedure to track the services done for a scooter
create proc service_tracking @Scooter_ID bigint
as
begin
select s.Scooter_id,sr.Service_Date,sv.Service_Type,sl.location_name,s.Status_in_use
from Scooter s
inner join service_record sr on s.Scooter_id=sr.Scooter_id
inner join [Service] sv on  sv.Service_id=sr.Service_id
inner join Service_Location sl on sl.location_id=sr.location_id
where s.Scooter_id=@Scooter_ID
order by s.Scooter_id
end

exec service_tracking 10002;

--- procedure to track the number of rides a user has taken
create proc users_tracking @User_id VARCHAR(25)
as
begin
select u.Username,u.user_id,a.account_balance,Start_ds.Station_Name,End_ds.Station_Name,f.amount as fare_amount
from Users u
inner join dbo.account a on a.account_id=u.user_id
inner join ride r on r.account_id=a.account_id
inner join fares f on f.fare_id=r.fare_id
inner join Docking_station Start_ds on r.Start_Station_Id=Start_ds.station_id
inner join Docking_station End_ds on r.End_Station_Id=End_ds.station_id
where User_ID= @User_id
end

exec users_tracking 'U2730'

--- procedure to get the Efficient Employee
create procedure bestemployee @serviceid varchar(25),
@Employee_ID  varchar(25) OUTPUT as
begin
select @Employee_ID=a.Employee_ID from
(Select row_number() over (order by a.Employee_Work_Duration) as row_id,a.Employee_Work_Duration,a.Employee_ID, c.employee_name,b.Service_Type from Employee_Service_Record a join service b
on a.service_id=b.Service_id join employee c on a.Employee_ID=c.employee_id where b.Service_id=@serviceid)A
where a.row_id=1
end;

declare @Employee_ID varchar(25);
exec bestemployee @serviceid='S1200',@Employee_ID=@Employee_ID OUTPUT;
select @Employee_ID as 'Efficient_Employee'










