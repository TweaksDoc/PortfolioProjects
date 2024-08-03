--Covid 19 Data Exploration 
--Data from 2020 till 14/7/2024


--Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types


SELECT * FROM CovidDeaths$
WHERE continent IS NOT NULL 
ORDER BY 3,4


-- Select Data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths$
WHERE continent IS NOT NULL 
ORDER BY 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, CAST((total_deaths/NULLIF(total_cases, 0)*100) AS DECIMAL(10,6)) AS DeathPercentage FROM CovidDeaths$
WHERE continent IS NOT NULL
AND location LIKE 'Sudan'
ORDER BY 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT location, date, total_cases, population, CAST((total_cases/population)*100 AS DECIMAL(10,6)) AS InfectedPopulationPercentage FROM CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount,CAST(MAX((total_cases/population))*100 AS DECIMAL(10,6)) AS HighestInfectedPopulationPercentage FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 desc


-- Countries with Highest Death Count per Population

SELECT location, population, MAX(total_deaths) AS HighestDeathCount, CAST(MAX((total_deaths/population))*100 AS DECIMAL(10,6)) AS HighestDeathPercentage FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT location, population, MAX(total_deaths) AS TotalDeathCount, CAST(MAX((total_deaths/population))*100 AS DECIMAL(10,6)) AS HighestDeathPercentage FROM CovidDeaths$
WHERE continent IS NULL
GROUP BY location, population
ORDER BY 4 desc


-- GLOBAL NUMBERS

-- Total cases, Total Deaths, & Death Percentage Per Week

SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, CAST(SUM(new_deaths)/SUM(new_cases)*100 AS DECIMAL(10,6)) AS DeathPercentage FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
HAVING SUM(new_cases) <> 0
ORDER BY 1,2


-- Total cases, Total Deaths, & Death Percentage from start until 14/7/2024

SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, CAST(SUM(new_deaths)/SUM(new_cases)*100 AS DECIMAL(10,6)) AS DeathPercentage FROM CovidDeaths$
WHERE continent IS NOT NULL
HAVING SUM(new_cases) <> 0
ORDER BY 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine, showing only days vaccines been given

SELECT dea.continent, dea.location, dea.date ,dea.population, new_vaccinations, SUM(CONVERT(float,new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND new_vaccinations IS NOT NULL
ORDER BY 2,3


-- Using CTE to perform Calculation on Partition By in previous query Showing percentage of vaccinated per day, skipping days without vaccines given

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingVaccinationCount)
AS
(
SELECT dea.continent, dea.location, dea.date ,dea.population, new_vaccinations, SUM(CONVERT(float,new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND new_vaccinations IS NOT NULL
--ORDER BY 2,3
)
SELECT *, CONVERT(decimal(10,6),(RollingVaccinationCount/population)*100) AS VaccinatedPercentage 
FROM PopvsVac
ORDER BY 2,3


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccinationCount numeric
)
Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date ,dea.population, new_vaccinations, SUM(CONVERT(float,new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND new_vaccinations IS NOT NULL
--ORDER BY 2,3

SELECT *, CONVERT(decimal(10,6),(RollingVaccinationCount/population)*100) AS VaccinatedPercentage 
FROM #PercentPopulationVaccinated
ORDER BY 2,3


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date ,dea.population, new_vaccinations, SUM(CONVERT(float,new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND new_vaccinations IS NOT NULL
--ORDER BY 2,3


