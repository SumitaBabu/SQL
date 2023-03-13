select * from NashvilleHousing;

----------------------------------------------------------------------------------------------------
--Standardizing date format

Alter table NashvilleHousing
add SaleDateConverted Date;

update NashvilleHousing
set SaleDateConverted = convert(date, SaleDate);

select SaleDateConverted from NashvilleHousing;

----------------------------------------------------------------------------------------------------
--handling null values in property address data

select [UniqueID ], ParcelID, PropertyAddress from NashvilleHousing
order by ParcelID;

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From NashvilleHousing A
JOIN NashvilleHousing B
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null;

Update A
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From NashvilleHousing A
JOIN NashvilleHousing B
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null;

----------------------------------------------
-- Splitting Property address and populating multiple columns based on delimiter

select SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as address,
ltrim(SUBSTRING(propertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(propertyAddress))) AS city
from NashvilleHousing;

select PropertySplitAddress,PropertySplitCity from NashvilleHousing;

--Column 1
Alter table NashvilleHousing
add PropertySplitAddress nvarchar(255);

update NashvilleHousing
set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1);

--Column 2
Alter table NashvilleHousing
add PropertySplitCity nvarchar(255);

update NashvilleHousing
set PropertySplitCity = ltrim(SUBSTRING(propertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(propertyAddress)));

----------------------------------------------------------------------------------------------------
-- Splitting OwnerAddress and populating multiple columns based on delimiter
select OwnerAddress from NashvilleHousing;

select PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
from NashvilleHousing;


ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255),
    OwnerSplitCity nvarchar(255),
    OwnerSplitState nvarchar(255);

update NashvilleHousing
set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);
	
select OwnerSplitAddress,OwnerSplitCity,OwnerSplitState from NashvilleHousing;

-----------------------------------------------------------------------------------
-- Standardising the SoldAsVacant field. Change Y/N to Yes/No
select SoldAsVacant, count(*)
from NashvilleHousing
group by SoldAsVacant
order by 2

--Case Statement 

select SoldAsVacant,
case 
	when SoldAsVacant='Y' then 'Yes'
	when SoldAsVacant='N' then 'No'
	else SoldAsVacant
end
from NashvilleHousing;

--Updating 
Update NashvilleHousing
set SoldAsVacant = case 
	when SoldAsVacant='Y' then 'Yes'
	when SoldAsVacant='N' then 'No'
	else SoldAsVacant
end
from NashvilleHousing;

--------------------------------------------------------------------------------------
-- Remove duplicates
WITH dups as (
select *, ROW_NUMBER() over (partition by ParcelID, PropertyAddress,SaleDate, SalePrice,
		LegalReference Order by UniqueId) as row_num
from NashvilleHousing) 

select * from dups
where row_num > 1;

--------------------------------------------------------------------------------------
-- deleting unused columns

select * from NashvilleHousing;

ALTER table NashvilleHousing
drop column PropertyAddress, OwnerAddress, SaleDate;
