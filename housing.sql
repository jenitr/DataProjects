-- data cleaning project

-- standardize date format, removing the time from it 
select saledateconverted , convert (Date, SaleDate)
from project..housing

update project..housing
set SaleDate = convert(date, SaleDate)

alter table project..housing
add saledateconverted date;

update project..housing
set saledateconverted = convert (date, SaleDate)

-- filling the address where it is null, in this case some addresses have same address as another 
-- this can be found out with the help of parcel id, some addresses have same parcel id but one is filled and another is null
-- this query will give us the result, we are joining rows here from same column. 
Select a.ParcelID, b.ParcelID, a.PropertyAddress, b.PropertyAddress, isnull(a.PropertyAddress, b.PropertyAddress)
from project..housing a
join project..housing b
on a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

-- now here we will update the above thing, here we need to use update on the thing which is null and not on the housing table 
-- as a whole so we will use update on 'a' which is to be updated

-- is null means first thing we will write is the thing if it is null , if the condition meets the second thing we will write isd 
-- what we want to populate it with. 
update a
set PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
from project..housing a
join project..housing b
on a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

--now we will break address into individual columns like address city and sate etc
-- in our data the address is seperated with the coma which is the delimitter, so we will use the substring function 
-- till coma, substring function will fetch us  that and we will use charindex as the end position
select substring(PropertyAddress, 1, CHARINDEX (',', PropertyAddress)-1) as Address
 , substring(PropertyAddress, CHARINDEX (',', PropertyAddress)+1, len (PropertyAddress))  as Address

from project..housing

--now we will add 2 new columns for this 
alter table project..housing
add roomaddress varchar(255);

update project..housing
set roomaddress = substring(PropertyAddress, 1, CHARINDEX (',', PropertyAddress)-1)

alter table project..housing
add cityaddress varchar(255);

update project..housing
set cityaddress = substring(PropertyAddress, CHARINDEX (',', PropertyAddress)+1, len (PropertyAddress))

select cityaddress , roomaddress from project..housing



-- doing the same with owner address but using parsename function this time , parsefunction only seperates if there is fullstop 
-- so first we will replace the comma with fullstop

select parsename(replace(OwnerAddress,',','.'),3) 
, parsename(replace(OwnerAddress,',','.'),2) 
, parsename(replace(OwnerAddress,',','.'),1) 
from project..housing

-- now we will add them in our table

alter table project..housing
add ownerroomaddress varchar(255);

update project..housing
set ownerroomaddress = parsename(replace(OwnerAddress,',','.'),3) 

alter table project..housing
add ownercityaddress varchar(255);

update project..housing
set ownercityaddress = parsename(replace(OwnerAddress,',','.'),2) 

alter table project..housing
add ownerstateaddress varchar(255);

update project..housing
set ownerstateaddress = parsename(replace(OwnerAddress,',','.'),1) 

select ownerroomaddress, ownercityaddress, ownerstateaddress from project..housing

-- change Y and N to Yes and No in "sold as vacant" for more clarity

select distinct(SoldAsVacant), count(SoldAsVacant)
from project..housing
group by SoldAsVacant
order by 2

Select SoldAsVacant
,Case when SoldAsVacant = 'Y'  THEN 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
	end
	from project..housing
-- here we put else because there are values where its already Yes and No so we will keep that as it
	


-- now updating it in table
update project..housing
SET SoldAsVacant = Case When SoldAsVacant = 'Y'  THEN 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
	end
select * from project..housing

-- remove duplicates , when we are doing removing the duplicates we need a way to identify duplicate rows so we will use row number here 
-- we will need to select columns which should be unique to rows hence the columns we selected below in partition by, row number column will be added based on the 
-- columns given in partition by and each of those rows will given column number. this is ordered by unique id so if we get same data again for different unique id
-- it will be given row number as 2. the second part will show us the rows which are duplicate and delete it 
WITH rownumcte AS (
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order by 
					UniqueID 
					) row_num

from project..housing
--order by ParcelID
)
Delete
from rownumcte
where row_num > 1
--order by PropertyAddress

-- delete unneeded columns, we already split owneraddress and property adress in above queries so there is 
-- no need of them anymore 
alter table project..housing
drop column OwnerAddress, TaxDistrict, PropertyAddress