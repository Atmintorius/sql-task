-- DATA Modifications
-- Updating Country table
select distinct Country_id, Country.Name, Country.ID from Employee
FULL OUTER JOIN Country
on Employee.Country_ID = Country.ID 
where Country_ID is not null

update country
set id = 'NO'
where name = 'Norway'

-- Updating Start_date in Employee_working_office
select * from Employee_working_office
where Employee_ID is null or Working_office_ID is null or Start_date is null or Active is null

update Employee_working_office
set Start_date = CONVERT(datetime, '03/01/2003', 101)
where Employee_ID = 10208059 

-- Main queries
-- Creating view for experienced employees who work in multiple offices [Regional Manager]
CREATE VIEW [Regional Manager] AS
SELECT
	Employee_ID,
	Working_office_ID, 
	Working_office.Country_ID, 
	Country.Name,
	Start_date
FROM Employee_working_office as Office
JOIN Working_office
	on Office.Working_office_ID = Working_office.ID
JOIN Country
	on Working_office.Country_ID = Country.ID
WHERE Employee_ID IN (select Employee_ID
		from Employee_working_office
		group by Employee_ID
		having count(Employee_ID) > 1)
ORDER BY Employee_ID, Start_date OFFSET 0 ROWS

-- Function for assigning one country for Managers
CREATE FUNCTION assignCountryForManagers (@Manager_ID VARCHAR(255))
RETURNS @assignCountryForManagers TABLE 
(
	Employee_Id VARCHAR(255),
	Working_Country VARCHAR(255)
)
AS
BEGIN
	DECLARE @countOffices INT = 1, 
			@officesAmount INT = 0,
		
			@currentDate DATETIME, 
			@nextDate DATETIME, 
			@thisDate DATETIME = GETDATE(),

			@currentWorkingTime INT = 0,
			@longestWorkingTime INT = 0,

			@currentCountry VARCHAR(255), 
			@nextCountry VARCHAR(255),
			@finalCountry VARCHAR(255),

			@Employee_ID VARCHAR(255) = @Manager_ID; 

	select @officesAmount = max(id) from 
	(
		select ROW_NUMBER() OVER(ORDER BY Start_date) as Id from [Regional Manager]
		where Employee_ID = @Employee_ID
	) as CurrentManagerView

	select @currentDate = min(Start_date) from [Regional Manager]
	where Employee_ID = @Employee_ID  

	select @currentCountry = Name from [Regional Manager]
	where Employee_ID = @Employee_ID and Start_date = @currentDate

	select @nextDate = Start_date, @nextCountry = Name from 
	(
		select Name, Start_date, ROW_NUMBER() OVER(ORDER BY Start_date) as Id from [Regional Manager]
		where Employee_ID = @Employee_ID

	) as CurrentManagerView 

	WHILE @countOffices <= @officesAmount + 1
	BEGIN
		if (@countOffices = @officesAmount + 1)
			set @nextDate = GETDATE()
		else
			begin
				select @nextDate = Start_date, @nextCountry = Name from 
				(
					select Name, Start_date, ROW_NUMBER() OVER(ORDER BY Start_date) as Id from [Regional Manager]
					where Employee_ID = @Employee_ID
				) as CurrentManagerView 
				where Id = @countOffices + 1
			end

		set @currentWorkingTime = DATEDIFF(MONTH, @currentDate, @nextDate) 
	 
	
		if (@currentWorkingTime >= @longestWorkingTime)
			begin
				set @longestWorkingTime = @currentWorkingTime 
				set @finalCountry = @currentCountry
			end
	 
		set @currentDate = @nextDate
		set @currentCountry = @nextCountry

		set @countOffices += 1;
	END
	INSERT @assignCountryForManagers
        SELECT @Employee_ID, @finalCountry;
	RETURN
END
GO

-- VIEW [Distinct Regional Manager]
CREATE VIEW [Distinct Regional Managers] AS
SELECT DISTINCT Employee_ID
FROM dbo.[Regional Manager]

-- Global Temporary Table for defining the country of regional managers
IF OBJECT_ID(N'tempdb..##RegionalManagers') IS NOT NULL
BEGIN
DROP TABLE ##RegionalManagers
END
GO 
CREATE TABLE ##RegionalManagers
(
	Employee_Id VARCHAR(255),
	Country VARCHAR(255)
)

DECLARE @managersAmount INT,
		@countManagers INT = 1,
		@managerId VARCHAR(255);

select @managersAmount = count(distinct Employee_Id) from [Regional Manager]

WHILE (@countManagers <= @managersAmount)
BEGIN
	select @managerId = Employee_Id from 
	(
		select Employee_Id, ROW_NUMBER() OVER(ORDER BY Employee_Id) as Row_Id 
		from [Distinct Regional Managers]
	) as DistinctManagers
	where Row_Id = @countManagers

	insert into ##RegionalManagers(Employee_Id, Country)
	select Employee_Id, Working_Country
	from assignCountryForManagers(@managerId)

	set @countManagers += 1
END

-- Targeted Regular Employee 
CREATE VIEW [Targeted Regular Employee] AS
SELECT 
	Employee_ID,
	Country.Name 
FROM Employee_working_office as Office
JOIN Working_office
	on Office.Working_office_ID = Working_office.ID
JOIN Country
	on Working_office.Country_ID = Country.ID
WHERE Employee_ID in (select Employee_ID from Employee_working_office
		where DATEDIFF(MONTH, Start_date, GETDATE()) >= 12 
		group by Employee_ID
		having COUNT(Employee_ID) <= 1 )
and Active = 1 

-- Union results into temporary table
IF OBJECT_ID(N'tempdb..##TargetedEmployeeCountry') IS NOT NULL
BEGIN
DROP TABLE ##TargetedEmployeeCountry
END
GO 

select Employee_ID, Name 
into ##TargetedEmployeeCountry
from [Targeted Regular Employee]
union all
select Employee_Id, Country from ##RegionalManagers

-- Final query
select Name, Count(Name) from ##TargetedEmployeeCountry
group by Name 
order by Count(Name) desc
