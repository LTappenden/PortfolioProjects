/* COVID 19 Data Exploration

Skills include: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

--Checking that the data has been imported correctly

SELECT * 
FROM PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4 

--SELECT * 
--FROM PortfolioProject..CovidVaccinations
--Where continent is not null
--order by 3,4 

--Selecting data that is going to be used

SELECT location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1,2

--Looking at total cases vs total deaths
--Shows likelihood of dying from Covid if you catch its as a percentage in your country 

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathpercentage
From PortfolioProject..CovidDeaths
Where location like '%Belgium%'
Order by 1,2

--Total cases vs population
--Shows what percentage of population gets covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectedPopulationPercentage
From PortfolioProject..CovidDeaths
Where location like '%Belgium%'
Where continent is not null
Order by 1,2

--Looking at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS highestinfectioncount, MAX((total_cases/population))*100 AS PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location, population 
Order by PercentPopulationInfected desc

--Showing the countries with the highest death count per population 
--Need to convert nvarchar(255) to integer 

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount 
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location
Order by TotalDeathCount desc



--BREAKING THINGS DOWN BY CONTINENT

--Showing continents with the highest death count per continent 

--SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount 
--From PortfolioProject..CovidDeaths
--Where continent is not null 
--Group by continent
--Order by TotalDeathCount desc

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount 
From PortfolioProject..CovidDeaths
Where continent is null 
Group by location
Order by TotalDeathCount desc

SELECT continent, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1,2

SELECT continent, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathpercentage
From PortfolioProject..CovidDeaths
Where continent is not null 
Order by 1,2

SELECT continent, population, MAX(total_cases) AS highestinfectioncount, MAX((total_cases/population))*100 AS PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent, population 
Order by PercentPopulationInfected desc

--GLOBAL NUMBERS

SELECT date, SUM(New_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS deathpercentage
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by date
Order by 1,2

--Total death percentage across the world 
SELECT SUM(New_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS deathpercentage
From PortfolioProject..CovidDeaths
Where continent is not null 
Order by 1,2

--Coming back to vaccination table that was imported 

SELECT * 
FROM PortfolioProject..CovidVaccinations
Where continent is not null
order by 3,4 

--Joining the two tables 

SELECT *
FROM PortfolioProject..CovidDeaths AS Dea
JOIN PortfolioProject..CovidVaccinations AS Vac
	ON Dea.location = Vac.location 
	AND Dea.date = Vac.date

--Looking at total population vs vaccinations

SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
FROM PortfolioProject..CovidDeaths AS Dea
JOIN PortfolioProject..CovidVaccinations AS Vac
	ON Dea.location = Vac.location 
	AND Dea.date = Vac.date
WHERE Dea.continent is not null 
ORDER BY 2,3

--Showing the percentage of the population that has recieved at least one Covid Vaccine

SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
, SUM(CONVERT(bigint,Vac.new_vaccinations)) OVER (Partition by Dea.location ORDER BY Dea.location, Dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS Dea
JOIN PortfolioProject..CovidVaccinations AS Vac
	ON Dea.location = Vac.location 
	AND Dea.date = Vac.date
WHERE Dea.continent is not null 
ORDER BY 2,3

--Creating a CTE to perform Calculation on Partition By in Previous query 

With PopulationVsVaccination (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
, SUM(CONVERT(bigint,Vac.new_vaccinations)) OVER (Partition by Dea.location ORDER BY Dea.location, Dea.date) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/Population)*100
FROM PortfolioProject..CovidDeaths AS Dea
JOIN PortfolioProject..CovidVaccinations AS Vac
	ON Dea.location = Vac.location 
	AND Dea.date = Vac.date
WHERE Dea.continent is not null 
--ORDER BY 2,3 
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopulationVsVaccination

--Using a TEMP table to perform calculation on Partition By in previous query 

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255),
Date datetime, 
Population numeric,
New_vaccinations numeric, 
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
, SUM(CONVERT(bigint,Vac.new_vaccinations)) OVER (Partition by Dea.location ORDER BY Dea.location, Dea.date) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/Population)*100
FROM PortfolioProject..CovidDeaths AS Dea
JOIN PortfolioProject..CovidVaccinations AS Vac
	ON Dea.location = Vac.location 
	AND Dea.date = Vac.date
WHERE Dea.continent is not null 
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

--Creating View to store data for later visualisations 

CREATE View PercentPopulationVaccinated AS
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
, SUM(CONVERT(bigint,Vac.new_vaccinations)) OVER (Partition by Dea.location ORDER BY Dea.location, Dea.date) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/Population)*100
FROM PortfolioProject..CovidDeaths AS Dea
JOIN PortfolioProject..CovidVaccinations AS Vac
	ON Dea.location = Vac.location 
	AND Dea.date = Vac.date
WHERE Dea.continent is not null 

Create view TotalDeathCount as
SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount 
From PortfolioProject..CovidDeaths
Where continent is null 
Group by location
--Order by TotalDeathCount desc

