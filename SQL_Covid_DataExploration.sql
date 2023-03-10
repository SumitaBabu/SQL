-- COVID DEATH INSIGHTS
SELECT
    location,
    date,
    population,
    total_cases,
    new_cases,
    total_deaths
FROM
    coviddeaths
WHERE
    continent IS NOT NULL
ORDER BY
    1,
    2;

-- What is the total number of covid cases, deaths and death percentage?
SELECT
    SUM(total_cases)                                       AS total_cases,
    SUM(CAST(total_deaths AS bigint))                      AS total_deaths,
    SUM(CAST(new_deaths AS bigint)) / SUM(new_cases) * 100 AS death_percentage
FROM
    coviddeaths
WHERE
    continent IS NOT NULL;

-- What is the Death Percentage?
SELECT
    location,
    date,
    total_cases,
    total_deaths,
    ( total_deaths / total_cases ) * 100 AS deathpercentage
FROM
    coviddeaths
WHERE
    continent IS NOT NULL
ORDER BY
    1,
    2;

-- What percentage of the population that contracted covid?
SELECT
    location,
    date,
    population,
    total_cases,
    ( total_cases / population ) * 100 AS covidpercentage
FROM
    coviddeaths
WHERE
    continent IS NOT NULL
ORDER BY
    1,
    2;

--What are the countries with the highest infection rates in comparison to population?
SELECT
    location,
    population,
    MAX(total_cases)                      AS highestinfectioncount,
    MAX((total_cases / population)) * 100 AS covidpercentage
FROM
    coviddeaths
WHERE
    continent IS NOT NULL
GROUP BY
    location,
    population
ORDER BY
    covidpercentage DESC;

--What are the countries with the highest deaths in comparision to population?
SELECT
    location,
    MAX(CAST(total_deaths AS bigint)) AS highestdeathcount
FROM
    coviddeaths
WHERE
    continent IS NOT NULL
GROUP BY
    location
ORDER BY
    highestdeathcount DESC;

--What are the continents with the highest deaths?
SELECT
    continent,
    MAX(CAST(total_deaths AS bigint)) AS highestdeathcount
FROM
    coviddeaths
WHERE
    continent IS NOT NULL
GROUP BY
    continent
ORDER BY
    highestdeathcount DESC;

--

--What is the total number of new cases and new deaths each day globally and the death percentage?
SELECT
    date,
    SUM(total_cases)                                       AS total_cases,
    SUM(CAST(new_deaths AS bigint))                        AS total_deaths,
    SUM(CAST(new_deaths AS bigint)) / SUM(new_cases) * 100 AS death_percentage
FROM
    coviddeaths
WHERE
    continent IS NOT NULL
GROUP BY
    date
ORDER BY
    1,
    2;

-- What is the total number of covid vaccinations administered?
SELECT
    SUM(CAST(total_vaccinations AS bigint)) AS total_vaccination
FROM
    covidvaccinations
WHERE
    continent IS NOT NULL;

-- What is the total number of covid vaccinations administered by country each day?
SELECT
    location,
    date,
    SUM(CAST(total_vaccinations AS bigint)) AS total_vaccinations,
    SUM(CAST(people_vaccinated AS bigint))  AS people_vaccinated,
    SUM(CAST(new_vaccinations AS bigint))   AS new_vaccinations
FROM
    covidvaccinations
WHERE
    continent IS NOT NULL
GROUP BY
    location,
    date
ORDER BY
    1,
    2;

-- What is the rolling sum of people vaccinated?

SELECT
    d.continent,
    d.location,
    d.date,
    d.population,
    v.new_vaccinations,
    SUM(convert(bigint, v.new_vaccinations))
    OVER(PARTITION BY d.location
         ORDER BY
             d.location,
             d.date
    ) AS vaccination_rolling_sum
FROM
         coviddeaths d
    JOIN covidvaccinations v ON d.location = v.location
                                AND d.date = v.date
WHERE
    d.continent IS NOT NULL
ORDER BY
    2,
    3;

--What are the top 5 countries with the highest total number of covid vaccinations?
select top 5 location, sum(convert(bigint,new_vaccinations)) as highest_total_vaccination
from CovidVaccinations
where continent is not null
group by location
order by highest_total_vaccination desc;

-- What are the first 5 ranks of countries with the highest total number of covid vaccinations?

select location, highest_total_vaccination
from(
select location, sum(convert(bigint,new_vaccinations)) as highest_total_vaccination, DENSE_RANK() over(order by sum(convert(bigint,new_vaccinations)) DESC) as rnk
from CovidVaccinations
where continent is not null
group by location) as a
where rnk >=5;

-- What is the percentage of population that has been vaccinated each day?
WITH popvac (continent, location, date, population, new_vaccinations, vaccination_rolling_sum )
AS (
select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(convert(bigint, v.new_vaccinations)) over (partition by d.location
	order by d.location, d.date) as vaccination_rolling_sum
from CovidDeaths D 
join CovidVaccinations V 
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
)
select *, (vaccination_rolling_sum/population)*100 as vaccinated_perc
from popvac

-- Create a temp table
DROP table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated (
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
vaccination_rolling_sum numeric
)
insert into #PercentPopulationVaccinated 
select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(convert(bigint, v.new_vaccinations)) over (partition by d.location
	order by d.location, d.date) as vaccination_rolling_sum
from CovidDeaths D 
join CovidVaccinations V 
	on d.location = v.location
	and d.date = v.date
where d.continent is not null;

--selecting from temp table
select *, (vaccination_rolling_sum/population)*100 as vaccinated_perc
from #
percentpopulationvaccinated;

--Create a view for the percentage of population vaccinated

CREATE VIEW percentpopulationvaccinated AS
    SELECT
        d.continent,
        d.location,
        d.date,
        d.population,
        v.new_vaccinations,
        SUM(convert(bigint, v.new_vaccinations))
        OVER(PARTITION BY d.location
             ORDER BY
                 d.location,
                 d.date
        ) AS vaccination_rolling_sum
    FROM
             coviddeaths d
        JOIN covidvaccinations v ON d.location = v.location
                                    AND d.date = v.date
    WHERE
        d.continent IS NOT NULL;

SELECT
    *
FROM
    percentpopulationvaccinated;