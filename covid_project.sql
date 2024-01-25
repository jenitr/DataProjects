select location, date, population, total_cases, (total_cases/population)*100 as percentofpopulationinfected
from project..CovidDeaths$
where location like '%states%'
order by 1,2


-- countries with highest infection rate compared to population
select location, population, MAX(total_cases) as highestinfectioncount, MAX(total_cases/population)*100 as 
percentpopulationinfected
from project..CovidDeaths$
group by location, population
order by percentpopulationinfected desc

-- countries with highest death count per population
select location, MAX(cast(total_deaths as int)) as totaldeathcount
from project..CovidDeaths$
where continent is not null 
-- we added this because when it is null the location is entire continent
group by location
order by totaldeathcount desc


-- same thing by continent 
select continent, MAX(cast(total_deaths as int)) as totaldeathcount
from project..CovidDeaths$
where continent is not null 
group by continent
order by totaldeathcount desc

-- same thing by continent but setting the continent as null
select location, MAX(cast(total_deaths as int)) as totaldeathcount
from project..CovidDeaths$
where continent is null 
group by location
order by totaldeathcount desc

--global numbers

select  sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, SUM(cast (new_deaths as int))/sum(New_Cases)*100 as deathpercentage
from project..CovidDeaths$
where continent is not null
--group by date
order by 1,2

--total population vs vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as peoplevaccinated
--, (peoplevaccinated/population)*100
from project..CovidDeaths$ dea 

-- we did partition by location so that the sum function does not go on and on forever and it will start over 
--new location begins
join project..CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- use cte
with popvsvac (continent, location, date, population, new_vaccinations, peoplevaccinated) as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as peoplevaccinated

from project..CovidDeaths$ dea 

join project..CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3 order by cant be in cte
)
select *, (peoplevaccinated/population)*100
from popvsvac

-- temp table
drop table if exists #percentpopulationvaccinated
create table #percentpopulationvaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
peoplevaccinated numeric
)

insert into #percentpopulationvaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as peoplevaccinated

from project..CovidDeaths$ dea 

join project..CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null

select *, (peoplevaccinated/population)*100
from #percentpopulationvaccinated




--creating view to store data for later vizualization

create view percentpopulationvaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as peoplevaccinated

from project..CovidDeaths$ dea 

join project..CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
