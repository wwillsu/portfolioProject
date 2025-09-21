SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- finds the fatality rate in a certain country, e.g. United States
SELECT location, date, total_cases, total_deaths, 
	   (CAST(total_deaths AS DECIMAL) / total_cases) * 100 AS fatalityRate
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY location, date

-- shows percentage of population infected with COVID
SELECT location, date, total_cases, population, 
	   (CAST(total_cases AS DECIMAL) / population) * 100 AS percentagePopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- countries with the highest infection rate compared to population
SELECT location, MAX(total_cases) AS HighestInfectionCount, 
	   (MAX(CAST(total_cases AS DECIMAL) / population)) * 100 AS percentagePopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY PercentagePopulationInfected DESC

-- countries with the highest death count 
SELECT location, MAX(total_deaths) AS totalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY totalDeathCount DESC

-- continents with the highest death count 
SELECT continent, MAX(total_deaths) AS totalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY totalDeathCount DESC

-- global stats
SELECT date, SUM(new_cases) as totalCases, SUM(new_deaths) as totalDeaths, 
	   (CAST(SUM(new_deaths) AS DECIMAL) / SUM(new_cases)) * 100 AS fatalityRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date ASC

-- shows rolling vaccinations
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations, 
	   SUM(COALESCE(vax.new_vaccinations, 0)) OVER (PARTITION BY death.location ORDER BY death.date ROWS UNBOUNDED PRECEDING) AS rollingVax
FROM PortfolioProject..CovidDeaths death
Join PortfolioProject..CovidVaccinations vax ON death.location = vax.location AND death.date = vax.date
WHERE death.continent IS NOT NULL
ORDER BY death.location, death.date

-- shows rolling vaccinated percentage
WITH vaxPercentage (continent, location, date, population, new_vaccinations, rollingVax) AS 
(
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations, 
	   SUM(COALESCE(vax.new_vaccinations, 0)) OVER (PARTITION BY death.location ORDER BY death.date ROWS UNBOUNDED PRECEDING) AS rollingVax
FROM PortfolioProject..CovidDeaths death
Join PortfolioProject..CovidVaccinations vax ON death.location = vax.location AND death.date = vax.date
WHERE death.continent IS NOT NULL
)

SELECT *, (CAST(rollingVax AS DECIMAL) / population) * 100 AS vaccinatedPercentage
FROM vaxPercentage
ORDER BY location, date

DROP TABLE IF EXISTS #rollingVax
CREATE TABLE #rollingVax
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric, 
rollingVax numeric
)

INSERT INTO #rollingVax
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations, 
	   SUM(COALESCE(vax.new_vaccinations, 0)) OVER (PARTITION BY death.location ORDER BY death.date ROWS UNBOUNDED PRECEDING) AS rollingVax
FROM PortfolioProject..CovidDeaths death
Join PortfolioProject..CovidVaccinations vax ON death.location = vax.location AND death.date = vax.date
WHERE death.continent IS NOT NULL
ORDER BY death.location, death.date

SELECT *, (rollingVax / population) * 100 AS vaccinatedPercentage
FROM #rollingVax
ORDER BY location, date

CREATE VIEW vaccinatedPercentage AS
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations, 
	   SUM(COALESCE(vax.new_vaccinations, 0)) OVER (PARTITION BY death.location ORDER BY death.date ROWS UNBOUNDED PRECEDING) AS rollingVax
FROM PortfolioProject..CovidDeaths death
Join PortfolioProject..CovidVaccinations vax ON death.location = vax.location AND death.date = vax.date
WHERE death.continent IS NOT NULL