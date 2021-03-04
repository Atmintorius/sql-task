# About the data set

Data set contains of 4 tables: Employee, Employee_working_office, Working_office, Country.

- Provided data is falsified;
- The ‘experienced employees’ are defined as employees with at least 1 year of working experience in at least one location;
- The employee table also contains employees that are no longer working for the company, so don’t take them into consideration;
- Each employee has a country in the database, but this information is not mandatory; many of them have no country in the database. In this case, the country in which the employee is working should be used;
- Employee could be working in multiple offices. Regional Managers are good example. They work from several (inter)national offices. Those employees they should be assigned to the country of the office in which they have been working the longest. And if their tenure is equal across 2 or more offices, they should be assigned to the last working country.

# Expected output

- List of countries and the number of ‘experienced employees’ of each of the countries.
- Employees should be ordered by number, descending.
- If two or more countries have the same number of experienced employees, they should be ordered by country name (A-Z).

# Data modification

- Data exploration have showed that a null value was imported into Employee_working_office table’s Start_date column in the row with Employee_Id = 10208059.
- Letter case was modified too for Norway country id values from “No” into “NO” in country table. 

# Structure of the query

Each query is commented. The first queries are dedicated for data modification purposes. To implement the full algorithm views, function and temporary tables were used.

## Views

[Regional Manager] – Regional Managers with all multiple offices they have been working.  

[Distinct Regional Manager] – distinct ids of Regional Managers.

[Targeted Regular Employee] – employees with at least 1 year of working experience in only one location.

## Function

assignCountryForManagers(@Manager_ID) – assigns a country for certain Regional Manager. Returns country name and employee id.

## Global Temporary Tables 

##RegionalManager – list of distinct Regional Managers with assigned countries.

##TargetedEmployeeCountry – combines working countries of Regular Employees and Regional Managers.

# Database
MS SQL Server was used to complete the task.
