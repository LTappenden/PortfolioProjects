
--First Query 

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
ORDER BY 1,2

--Second Query 
--Take out 'World', 'EU', 'International', & Income categories to keep the data consistent 
--EU is part of Europe

SELECT location, SUM(cast(new_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null 
AND location not in ('World', 'European Union', 'International', 'High Income', 'Upper Middle Income', 'Lower Middle Income', 'Low Income')
GROUP BY location
ORDER BY TotalDeathCount desc

--Third Query 

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PercentPopulationInfected 
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

--Fourth query 
SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population, date 
ORDER BY PercentPopulationInfected desc

