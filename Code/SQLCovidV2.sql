-- Data Explortary
SELECT * 
FROM Covid19..Death;

SELECT * 
FROM Covid19.. Vac;

-- Dimensions of Death dataset (165180 by 26)
SELECT COUNT(*)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_CATALOG = 'Covid19'
AND TABLE_SCHEMA = 'dbo'
AND TABLE_NAME = 'Death'

SELECT COUNT(*)
FROM Covid19..Death


-- Dimensions of Vac dataset  (165180 by 45)
SELECT COUNT(*)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_CATALOG = 'Covid19'
AND TABLE_SCHEMA = 'dbo'
AND TABLE_NAME = 'Vac'

SELECT COUNT(*)
FROM Covid19..Vac


-- Checking if all iso_code has the same number of entries
SELECT iso_code, COUNT(iso_code) AS 'Count of iso_code' 
FROM Covid19..Death
GROUP BY iso_code;
-- Do not have the same number of entries. We also have some weird ISO code i.e OWID_KOS Checking them below 

-- Checking iso_code == OWID 
SELECT * 
FROM Covid19..Death
WHERE iso_code LIKE 'OWID%'
-- OWID are aggergated information for the whole continent or income bracket

-- Show the percentage of population got Covid per country
SELECT location, date,total_cases,new_cases,total_deaths,population,(total_cases/population) * 100 AS 'Contract Percentage'
FROM Covid19..Death
WHERE continent is NOT NULL
ORDER by location,date


-- Show the country with the highest infection rate
SELECT Location, Population, SUM(CAST(new_cases AS int)) AS HighestInfectionCount,  MAX((total_cases/population))*100 AS PercentInfected 
From Covid19..Death
WHERE location NOT LIKE '%income' 
AND location NOT LIKE 'European Union'
AND location NOT LIKE 'World'
and location NOT LIKE 'International'
GROUP by Location, Population
ORDER by PercentInfected DESC

-- Looking at total deaths per total cases
SELECT location, date,total_cases,new_cases,new_deaths,total_deaths,population,(total_deaths/total_cases) * 100 AS 'DeathPercentage'
FROM Covid19..Death
ORDER by location,date

-- Show the country with the highest death rate per capital
WITH TotalDeath (location,total_cases,total_deaths)
	AS
		(
		SELECT location,sum(new_cases) AS total_cases,MAX(CAST(total_deaths AS int)) AS total_deaths
		FROM Covid19..Death
		GROUP by location
		)

SELECT location,total_cases,total_deaths, (total_deaths/total_cases) * 100 AS Death_percent
FROM TotalDeath
WHERE location NOT LIKE '%income' 
AND location NOT LIKE 'European Union'
AND location NOT LIKE 'World'
and location NOT LIKE 'International'
ORDER by Death_percent DESC

-- Show continent with the total death toll percentage
WITH TotalDeath (location,continent,total_cases,total_deaths)
	AS
		(
		SELECT location,continent,sum(new_cases) AS total_cases,MAX(CAST(total_deaths AS int)) AS 
		total_deaths
		FROM Covid19..Death
		WHERE continent is NULL
		GROUP by location,continent		
		)

SELECT location,total_cases,total_deaths,(total_deaths/total_cases) * 100 AS Death_percent
FROM TotalDeath
WHERE location NOT LIKE '%income' 
AND location NOT LIKE 'European Union'
AND location NOT LIKE 'World'
and location NOT LIKE 'International'
ORDER BY Death_percent DESC


-- Show continent with daily death rate percentage

SELECT date,location,total_cases,total_deaths, (total_deaths/total_cases)*100 AS Death_percent
FROM Covid19..Death
WHERE continent is NULL
AND location NOT LIKE 'European Union'
AND location NOT LIKE 'World'
and location NOT LIKE 'International'
and location NOT LIKE '%income'
ORDER BY date




-- Show continent with  daily infection rate

SELECT location, date,total_cases,new_cases,total_deaths,population,(total_cases/population) * 100 AS 'Contract Percentage'
FROM Covid19..Death
WHERE continent is NULL
AND location NOT LIKE 'European Union'
and location NOT LIKE 'International'
and location NOT Like '%income'
ORDER by location,date

--Show continent with total infection rate
SELECT location,MAX(CAST(total_cases AS int)) AS HighestInfectionCount,MAX((total_cases/population)) * 100 AS 'Contract Percentage'
FROM Covid19..Death
WHERE continent is NULL
AND location NOT LIKE 'European Union'
AND location NOT LIKE 'World'
and location NOT LIKE 'International'
and location NOT Like '%income'
GROUP by location,population


Select Location, Population, MAX(CAST(new_cases AS int)) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentInfected 
From Covid19..Death
GROUP by Location, Population
ORDER by PercentInfected DESC

-- Global Statistics



-- Show the daily percentage of population die from Covid 
SELECT date,SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 AS DeathPercentage
From Covid19..Death
WHERE continent IS NOT NULL
GROUP By date
ORDER by date

--Show global percentage of population that die from Covid

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 AS DeathPercentage
From Covid19..Death
WHERE continent IS NOT NULL

-- Show the daily percentage of popluation that contact Covid

SELECT date,SUM(new_cases) AS total_cases,SUM(new_cases)/
	(SELECT sum(population)
		FROM 
		(SELECT DISTINCT location, population
			FROM Covid19..DEATH 
			WHERE continent IS NOT NULL) SQ)
	*100 AS ContactPercentage
FROM Covid19..Death
GROUP By date
ORDER By date

-- Show the global percentage of population that got Covid

SELECT SUM(new_cases) AS total_cases, (SUM(new_cases)/
	(SELECT sum(population)
		FROM 
		(SELECT DISTINCT location, population
			FROM Covid19..DEATH 
			WHERE continent IS NOT NULL) SQ) * 100) AS GlobalPercentInfected 
FROM Covid19..Death
WHERE continent IS NOT NULL

-- Vaccination dataset
SELECT *
FROM Covid19..Vac

-- Vaccination table is missing the population statistics per country. We will need to join table with death table
-- Joining Vaccination table with Death table.

SELECT *
FROM Covid19..Death AS death
JOIN Covid19..Vac AS Vac
ON death.iso_code = Vac.iso_code
AND death.date = Vac.date


--Using CTE and Partition to get vaccination information for each country 
WITH DeathVac
	AS (SELECT death.iso_code ,death.continent,death.population,death.location,death.date,total_cases,new_cases,total_deaths,new_deaths,new_tests,total_tests,new_vaccinations,people_vaccinated AS one_shot,total_boosters,total_vaccinations,vac.people_fully_vaccinated AS two_shot,total_boosters AS booster
		FROM Covid19..Death AS death
		JOIN Covid19..Vac AS Vac
		ON death.iso_code = Vac.iso_code
		AND death.date = Vac.date)
SELECT location,date,population,new_vaccinations,SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY location ORDER BY date) AS RunningTotalVacGiven, SUM (CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY location) AS Total_vaccination,one_shot, two_shot, booster,
(one_shot/population) * 100 AS PercentVacwith1shot,(two_shot/population)*100 AS PercentFullyVac,(booster/population) * 100 AS PercentBoosted
FROM DeathVac
WHERE continent IS NOT NULL


--Creating Temp Table for Vaccination for each continent 
DROP table if exists #PercentVacc
Create Table #PercentVacc
(iso_code nvarchar(255),
 continent nvarchar(255),
 population float,
 location nvarchar(255),
 date nvarchar(255),
 new_vaccinations nvarchar(255),
 one_shot nvarchar(255),
 total_vaccinations nvarchar(255),
 two_shot nvarchar(255),
  booster nvarchar(255),
 GlobalPopulation nvarchar(255))

 Insert into #PercentVacc
 SELECT death.iso_code ,death.continent,death.population,death.location,death.date,new_vaccinations,people_vaccinated AS one_shot,total_vaccinations,people_fully_vaccinated AS two_shot,total_boosters AS booster,
		(SELECT SUM(population) 
			FROM 
			(SELECT DISTINCT location,population 
			 FROM Covid19..Death 
			 WHERE continent IS NOT NULL)SQ) AS GlobalPopulation
		FROM Covid19..Death AS death
		JOIN Covid19..Vac AS Vac
		ON death.iso_code = Vac.iso_code
		AND death.date = Vac.date

SELECT location,date,population,new_vaccinations,SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY location ORDER BY date) AS RunningTotalVacGiven, SUM (CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY location) AS Total_vaccination,one_shot, two_shot, booster,
(one_shot/population) * 100 AS PercentVacwith1shot,(two_shot/population)*100 AS PercentFullyVac,(booster/population) * 100 AS PercentBoosted
FROM #PercentVacc
WHERE continent IS NULL
AND location NOT LIKE 'European Union'
AND location NOT LIKE 'World'
and location NOT LIKE 'International'
and location NOT Like '%income';

--Daily Vaccination for global

WITH DeathVac
	AS (SELECT death.iso_code ,death.continent,death.population,death.location,death.date,total_cases,new_cases,total_deaths,new_deaths,new_tests,total_tests,new_vaccinations,people_vaccinated AS one_shot,total_boosters,total_vaccinations,vac.people_fully_vaccinated AS two_shot,total_boosters AS booster,
		(SELECT SUM(population) 
			FROM 
			(SELECT DISTINCT location,population 
			 FROM Covid19..Death 
			 WHERE continent IS NOT NULL)SQ) AS GlobalPopulation
		FROM Covid19..Death AS death
		JOIN Covid19..Vac AS Vac
		ON death.iso_code = Vac.iso_code
		AND death.date = Vac.date)
SELECT date,SUM(CAST(total_vaccinations AS BIGINT)) AS total_vaccination_given, SUM(CAST(one_shot AS BIGINT)) AS one_shot, SUM(CAST(two_shot AS BIGINT)) AS two_shot, SUM(CAST(booster AS BIGINT)) AS booster,
(SUM(CAST(total_vaccinations AS BIGINT))/GlobalPopulation) * 100  AS total_vac_percent,(SUM(CAST(one_shot AS BIGINT))/GlobalPopulation) * 100 AS one_shot_percent, (SUM(CAST(two_shot AS BIGINT))/GlobalPopulation)*100 AS two_shot_percent, (SUM(CAST(booster AS BIGINT))/GlobalPopulation)*100 AS booster_percent
FROM DeathVac
WHERE location LIKE 'World'
GROUP by date,GlobalPopulation
ORDER by date


------------------------------------------------------------------------------------------Generating Views for Tableau visualization---------------------------------------------------------------------------------------------------------------------------------
USE [Covid19]
GO

CREATE VIEW CountryContact AS
SELECT location, date,total_cases,new_cases,total_deaths,population,(total_cases/population) * 100 AS 'Contract Percentage'
FROM Covid19..Death
WHERE continent is NOT NULL

CREATE VIEW CountryDeath AS 
SELECT location, date,total_cases,continent,new_cases,new_deaths,total_deaths,population,(total_deaths/total_cases) * 100 AS 'DeathPercentage'
FROM Covid19..Death

CREATE VIEW ContinentContact AS 
SELECT location, date,total_cases,new_cases,total_deaths,population,(total_cases/population) * 100 AS 'Contract Percentage'
FROM Covid19..Death
WHERE continent is NULL
AND location NOT LIKE 'European Union'
and location NOT LIKE 'International'
and location NOT Like '%income'
and location NOT LIKE 'World'

CREATE VIEW ContinentDeath AS
SELECT date,location,SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/NULLIF(SUM(new_Cases),0)*100 AS DeathPercentage
FROM Covid19..Death
WHERE continent is NULL
AND location NOT LIKE 'European Union'
AND location NOT LIKE 'World'
and location NOT LIKE 'International'
and location NOT LIKE '%income'
GROUP by date,location

CREATE VIEW GlobalDeath AS
SELECT date,SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
From Covid19..Death
WHERE continent IS NOT NULL
GROUP By date

CREATE VIEW GlobalContact AS 
SELECT date,SUM(new_cases) AS total_cases,SUM(new_cases)/
	(SELECT sum(population)
		FROM 
		(SELECT DISTINCT location, population
			FROM Covid19..DEATH 
			WHERE continent IS NOT NULL) SQ)
	*100 AS ContactPercentage
FROM Covid19..Death
GROUP By date

CREATE VIEW CountryVaccine AS 
WITH DeathVac
	AS (SELECT death.iso_code ,death.continent,death.population,death.location,death.date,total_cases,new_cases,total_deaths,new_deaths,new_tests,total_tests,new_vaccinations,people_vaccinated AS one_shot,total_boosters,total_vaccinations,vac.people_fully_vaccinated AS two_shot,total_boosters AS booster
		FROM Covid19..Death AS death
		JOIN Covid19..Vac AS Vac
		ON death.iso_code = Vac.iso_code
		AND death.date = Vac.date)
SELECT location,date,population,continent,new_vaccinations,SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY location ORDER BY date) AS RunningTotalVacGiven, SUM (CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY location) AS Total_vaccination,one_shot, two_shot, booster,
(one_shot/population) * 100 AS PercentVacwith1shot,(two_shot/population)*100 AS PercentFullyVac,(booster/population) * 100 AS PercentBoosted
FROM DeathVac
WHERE continent IS NOT NULL

CREATE VIEW ContinentVaccine AS 
WITH DeathVac
	AS (SELECT death.iso_code ,death.continent,death.population,death.location,death.date,total_cases,new_cases,total_deaths,new_deaths,new_tests,total_tests,new_vaccinations,people_vaccinated AS one_shot,total_boosters,total_vaccinations,vac.people_fully_vaccinated AS two_shot,total_boosters AS booster,
		(SELECT SUM(population) 
			FROM 
			(SELECT DISTINCT location,population 
			 FROM Covid19..Death 
			 WHERE continent IS NOT NULL)SQ) AS GlobalPopulation
		FROM Covid19..Death AS death
		JOIN Covid19..Vac AS Vac
		ON death.iso_code = Vac.iso_code
		AND death.date = Vac.date)
SELECT location,date,population,new_vaccinations,SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY location ORDER BY date) AS RunningTotalVacGiven, SUM (CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY location) AS Total_vaccination,one_shot, two_shot, booster,
(one_shot/population) * 100 AS PercentVacwith1shot,(two_shot/population)*100 AS PercentFullyVac,(booster/population) * 100 AS PercentBoosted
FROM DeathVac
WHERE continent IS NULL
AND location NOT LIKE 'European Union'
AND location NOT LIKE 'World'
and location NOT LIKE 'International'
and location NOT Like '%income'

CREATE VIEW GlobalVaccine AS
WITH DeathVac
	AS (SELECT death.iso_code ,death.continent,death.population,death.location,death.date,total_cases,new_cases,total_deaths,new_deaths,new_tests,total_tests,new_vaccinations,people_vaccinated AS one_shot,total_boosters,total_vaccinations,vac.people_fully_vaccinated AS two_shot,total_boosters AS booster,
		(SELECT SUM(population) 
			FROM 
			(SELECT DISTINCT location,population 
			 FROM Covid19..Death 
			 WHERE continent IS NOT NULL)SQ) AS GlobalPopulation
		FROM Covid19..Death AS death
		JOIN Covid19..Vac AS Vac
		ON death.iso_code = Vac.iso_code
		AND death.date = Vac.date)
SELECT date,SUM(CAST(total_vaccinations AS BIGINT)) AS total_vaccination_given, SUM(CAST(one_shot AS BIGINT)) AS one_shot, SUM(CAST(two_shot AS BIGINT)) AS two_shot, SUM(CAST(booster AS BIGINT)) AS booster,
(SUM(CAST(total_vaccinations AS BIGINT))/GlobalPopulation) * 100  AS total_vac_percent,(SUM(CAST(one_shot AS BIGINT))/GlobalPopulation) * 100 AS one_shot_percent, (SUM(CAST(two_shot AS BIGINT))/GlobalPopulation)*100 AS two_shot_percent, (SUM(CAST(booster AS BIGINT))/GlobalPopulation)*100 AS booster_percent
FROM DeathVac
WHERE location LIKE 'World'
GROUP by date,GlobalPopulation

CREATE VIEW CountryMAXDeath AS 
WITH TotalDeath (location,total_cases,total_deaths)
	AS
		(
		SELECT location,sum(new_cases) AS total_cases,MAX(CAST(total_deaths AS int)) AS total_deaths
		FROM Covid19..Death
		GROUP by location
		)

SELECT location,total_cases,total_deaths, (total_deaths/total_cases) * 100 AS Death_percent
FROM TotalDeath
WHERE location NOT LIKE '%income' 
AND location NOT LIKE 'European Union'
AND location NOT LIKE 'World'
and location NOT LIKE 'International'

CREATE VIEW CountryMAXContact AS 
SELECT Location, Population, SUM(CAST(new_cases AS int)) AS HighestInfectionCount,  MAX((total_cases/population))*100 AS PercentInfected 
From Covid19..Death
WHERE location NOT LIKE '%income' 
AND location NOT LIKE 'European Union'
AND location NOT LIKE 'World'
and location NOT LIKE 'International'
GROUP by Location, Population

CREATE VIEW ContinentMAXContact AS 
SELECT location,MAX(CAST(total_cases AS int)) AS HighestInfectionCount,MAX((total_cases/population)) * 100 AS 'Contract Percentage'
FROM Covid19..Death
WHERE continent is NULL
AND location NOT LIKE 'European Union'
AND location NOT LIKE 'World'
and location NOT LIKE 'International'
and location NOT Like '%income'
GROUP by location,population

CREATE VIEW ContinentMAXDeath AS 
WITH TotalDeath (location,continent,total_cases,total_deaths)
	AS
		(
		SELECT location,continent,sum(new_cases) AS total_cases,MAX(CAST(total_deaths AS int)) AS 
		total_deaths
		FROM Covid19..Death
		WHERE continent is NULL
		GROUP by location,continent		
		)

SELECT location,total_cases,total_deaths,(total_deaths/total_cases) * 100 AS Death_percent
FROM TotalDeath
WHERE location NOT LIKE '%income' 
AND location NOT LIKE 'European Union'
AND location NOT LIKE 'World'
and location NOT LIKE 'International'

CREATE VIEW GlobalMAXContact AS
SELECT SUM(new_cases) AS total_cases, (SUM(new_cases)/
	(SELECT sum(population)
		FROM 
		(SELECT DISTINCT location, population
			FROM Covid19..DEATH 
			WHERE continent IS NOT NULL) SQ) * 100) AS GlobalPercentInfected 
FROM Covid19..Death
WHERE continent IS NOT NULL

CREATE VIEW GlobalMAXDeath AS
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 AS DeathPercentage
From Covid19..Death
WHERE continent IS NOT NULL

SELECT * FROM Covid19..ContinentDeath
SELECT * FROM Covid19..CountryDeath


---- To Create hierarchical data 
CREATE VIEW Hiercharical Data AS 
SELECT CC.location,CC.date, CC.population,CC.total_cases AS CountryCase,CC.continent,CC.new_deaths AS CountryDailyDeath,CC.total_deaths AS CountryDeath,CC.DeathPercentage AS CountryDeathPer,CD.total_cases AS ContinentCase,CD.total_deaths AS ContinentDeath,CD.DeathPercentage AS ContinentDeathPer,
GD.total_cases AS GlobalCase,GD.total_deaths AS GlobalDeath,GD.DeathPercentage AS GlobalDeathPerc,CMD.total_cases AS ContinentTotalCase, CMD.total_deaths AS ContinentTotalDeath,CMD.Death_percent AS ContinentAggreatedTotalDeathPercent,
CMC.[Contract Percentage] AS ContinentAggregatedTotalContact,
CUMD.total_cases AS CountryMaxCases,CUMD.total_deaths AS CountryMaxDeath,CUMD.Death_percent AS CountryMaxDeathPercent,
CUMC.PercentInfected AS CountryMaxInfectionPercent,
CV.new_vaccinations AS ContinentDailyNewVaccine,CV.Total_vaccination AS ContientTotalVaccine,CV.one_shot AS ContinentRunningTotalOneShot, CV.two_shot AS ContinentRunningTotalTwoShot, CV.booster AS ContinentRunningTotalBooster, CV.PercentVacwith1shot AS ContinentRunningPercent1Shot,
CV.PercentFullyVac AS ContinentRunningPercentTwoShot,CV.PercentBoosted AS ContinentRunningPercentBoost,
ConV.new_vaccinations AS CountryDailyNewVacccine, Conv.Total_vaccination AS CountryTotal_vaccine,ConV.one_shot AS CountryRunningTotalOneshot, ConV.two_shot AS CountryRunningTotalTwoShot, ConV.booster AS CountryRunningTotalBooster, ConV.PercentVacwith1shot AS CountryRunninngPercent1Shot,
ConV.PercentFullyVac AS CountryRunningPercentTwoShot, ConV.PercentBoosted AS CountryRunningPercentBooster,
GV.total_vaccination_given AS GlobalTotalVaccineGiven, GV.one_shot AS GlobalRunningOneShot,GV.two_shot AS GlobalRunningTwoShot, GV.booster AS GlobalRunningBooster,GV.one_shot_percent AS GlobalRunningPercentOneShot, GV.two_shot_percent AS GlobalRunningPercentTwoShot, GV.booster_percent AS GlobalRunningPercentBooster
FROM Covid19..CountryDeath AS CC
JOIN Covid19..ContinentDeath AS CD 
ON CC.continent = CD.location AND
CC.date = CD.date
JOIN Covid19..GlobalDeath AS GD ON
CC.date = GD.date
JOIN Covid19..ContinentMAXDeath AS CMD ON
CC.continent = CMD.location
JOIN Covid19..CountryMAXDeath AS CUMD ON
CC.location = CUMD.location
JOIN Covid19..CountryMAXContact AS CUMC ON
CC.location = CUMC.Location
JOIN Covid19..ContinentMAXContact AS CMC ON
CC.continent = CMC.location
JOIN Covid19..ContinentVaccine AS CV ON
CC.continent = CV.location AND
CC.date = CV.date
JOIN Covid19..CountryVaccine AS ConV ON
CC.location = ConV.location AND
CC.date = ConV.date
JOIN Covid19..GlobalVaccine AS GV ON
CC.date = GV.date
