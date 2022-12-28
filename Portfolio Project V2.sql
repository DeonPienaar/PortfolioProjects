SELECT *
FROM PortfolioProject.dbo.CovidDeaths$
ORDER BY 3,4
--------------------------------------------------------------------------------------------------------------------------------------------------
SELECT *
FROM PortfolioProject.dbo.CovidVaccinations$
ORDER BY 3,4
---------------------------------------------------------------------------------------------------------------------------------------------------
--Select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths$
ORDER BY 1,2
----------------------------------------------------------------------------------------------------------------------------------------------------
-- Looking at the total cases vs total deaths
-- Shows the likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2
----------------------------------------------------------------------------------------------------------------------------------------------------
--Looking at the total cases vs population
--Shows what percentage of populatin got Covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS cases_per_population
FROM PortfolioProject.dbo.CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2
---------------------------------------------------------------------------------------------------------------------------------------------------
-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths$
--WHERE location like '%South Africa%'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC
--------------------------------------------------------------------------------------------------------------------------------------------------
--Showing countries with highest death count per population
SELECT location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths$
--WHERE location like '%South Africa%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC
---------------------------------------------------------------------------------------------------------------------------------------------------
-- Let's break things down by continent
SELECT continent, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths$
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Let's break things down by continent 
-- Showing the continents with the highest death count per population
SELECT location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths$
--WHERE location like '%South Africa%'
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC
-------------------------------------------------------------------------------------------------------------------------------------------------
-- Global numbers
SELECT date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths$
-- WHERE location like '%states%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT date, SUM(new_cases) AS NewCasesPerDate, Sum(cast(new_deaths as int)) AS NewDeathsPerDate, 
(SUM(CAST(new_deaths AS INT))/Sum(new_cases))*100 AS PercentageDeaths 
FROM PortfolioProject.dbo.CovidDeaths$
-- WHERE location like '%states%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2
----------------------------------------------------------------------------------------------------------------------------------------------
SELECT SUM(new_cases) AS NewCasesPerDate, Sum(cast(new_deaths as int)) AS NewDeathsPerDate, 
(SUM(CAST(new_deaths AS INT))/Sum(new_cases))*100 AS PercentageDeaths 
FROM PortfolioProject.dbo.CovidDeaths$
-- WHERE location like '%states%'
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2
-----------------------------------------------------------------------------------------------------------------------------------------------
-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccine_rolling_totals
-- , (vaccine_rolling_totals/population)*100
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3
-----------------------------------------------------------------------------------------------------------------------------------------------
-- Use CTE (Common Table Expression)
WITH PopVsVac (continent, location, date, Population, new_vaccinations, vaccine_rolling_totals)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccine_rolling_totals
-- , (vaccine_rolling_totals/population)*100
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3
)
SELECT *, (vaccine_rolling_totals/population)*100 AS Percentage_People_Vaccinated_Per_Location_Population
FROM PopVsVac
-----------------------------------------------------------------------------------------------------------------------------------------------------
--Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated --Use if getting error about table name already existing
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert Into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
-- , (vaccine_rolling_totals/population)*100
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3
SELECT *, (RollingPeopleVaccinated/population)*100 AS Percentage_People_Vaccinated_Per_Location_Population
FROM #PercentPopulationVaccinated
------------------------------------------------------------------------------------------------------------------------------------------------------
-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
-- , (vaccine_rolling_totals/population)*100
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3
---------------------------------------------------------------------------------------------------------------------------------------------