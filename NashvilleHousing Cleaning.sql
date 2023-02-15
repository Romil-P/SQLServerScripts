select * from NashvilleHousing

--================================================================================================================================================
-- convert SaleDate from datetime to date (removing timestamps) to a new column
select convert(date,SaleDate) from NashvilleHousing

alter table nashvillehousing
add SaleDateConverted Date;

Update NashvilleHousing
set SaleDateConverted = convert(date,SaleDate)

--================================================================================================================================================

-- Some property addresses are null, however when looking at the data we find that ParcelID is shared with addresses that are the same. Lets populate the null addresses if there is a simmiliar ParcelID
select * from NashvilleHousing where PropertyAddress is null

-- join the table on itself using ParcelID as the key but also have different UniqueIDs. Query shows below how the Addresses are the same with the ParcelID and can be populated
select a.ParcelID,a.PropertyAddress,b.ParcelID, b.PropertyAddress 
from NashvilleHousing as a join NashvilleHousing as b on a.ParcelID = b.ParcelID and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

-- using ISNULL function, we want to find and replace the nulls with the values provided
select a.ParcelID,a.PropertyAddress,b.ParcelID, b.PropertyAddress, ISNULL(a.propertyaddress, b.PropertyAddress) as PropertyAddressClean 
from NashvilleHousing as a join NashvilleHousing as b on a.ParcelID = b.ParcelID and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

-- Update the table 
Update a
set propertyAddress = ISNULL(a.propertyaddress, b.PropertyAddress)
from NashvilleHousing as a join NashvilleHousing as b on a.ParcelID = b.ParcelID and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

--================================================================================================================================================

-- Splitting the address up, we already know there is always 1 comma in the address column
select propertyaddress from NashvilleHousing

-- using substring we split the address from the first character to the comma (minus 1 to remove comma) with the help of CHARINDEX function
select SUBSTRING(propertyaddress,1,CHARINDEX(',',propertyaddress)-1) as address from NashvilleHousing

-- Selecting the second half of the address, starting at the comma until the the length of the address
select SUBSTRING(propertyaddress,CHARINDEX(',',propertyaddress)+1,LEN(PropertyAddress)) as address2 from NashvilleHousing

-- Alter and Update the table
alter table NashvilleHousing
add PropertyAddressSplit varchar(250)

Update NashvilleHousing
set PropertyAddressSplit = SUBSTRING(propertyaddress,1,CHARINDEX(',',propertyaddress)-1) 

alter table NashvilleHousing
add PropertyCitySplit varchar(250)

Update NashvilleHousing
set PropertyCitySplit = SUBSTRING(propertyaddress,CHARINDEX(',',propertyaddress)+1,LEN(PropertyAddress))

--================================================================================================================================================

--Splitting the address with the function ParseName, there are multiple commas in this column
select owneraddress from NashvilleHousing

--Parsename will look for a period, so we must replace the comma with a period for the function to work. Parsename will split the string (reverse order) depending on where the period is placed
select parsename(replace(owneraddress,',','.'),3) as OwnerAddressSplit,
parsename(replace(owneraddress,',','.'),2) as OwnerCitySplit,
parsename(replace(owneraddress,',','.'),1) as OwnerStateSplit 
from nashvillehousing

--Update the table

alter table nashvillehousing
add OwnerAddressSplit varchar(250)

alter table nashvillehousing
add OwnerCitySplit varchar(250)

alter table nashvillehousing
add OwnerStateSplit varchar(250)

Update nashvillehousing
set OwnerAddressSplit = parsename(replace(owneraddress,',','.'),3)

Update nashvillehousing
set OwnerCitySplit = parsename(replace(owneraddress,',','.'),2)

Update nashvillehousing
set OwnerStateSplit = parsename(replace(owneraddress,',','.'),1)

select OwnerAddress,OwnerAddressSplit,OwnerCitySplit,OwnerStateSplit from NashvilleHousing

--================================================================================================================================================

-- Yes and No are also placed as Y and N, we want the data to be more consistent
select distinct SoldAsVacant from NashvilleHousing

-- checking the occurances of each entry
select soldAsVacant, count(soldAsVacant) from NashvilleHousing group by SoldAsVacant

--replacing the values
select SoldAsVacant,
case
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
end as newSoldAsVacant
from NashvilleHousing

--Update the values
Update NashvilleHousing
Set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes' when SoldAsVacant = 'N' then 'No' else SoldAsVacant end

--================================================================================================================================================
--Finding duplicate rows in our data
-- The following query adds a new column "row_num" which is partitioned over multiple columns to find duplicate rows. Duplicates are indicated by having a value of 2 or more (could be more than 1 of the same duplicate) instead of 1. The columns listed in the partition by is what we are looking for when finding duplicates, and row_number assigns the value in the row_num column
select *,
ROW_NUMBER() over(
partition by parcelID, propertyaddress,saleprice,saledate,legalreference order by uniqueID) as row_num
from NashvilleHousing order by ParcelID

--creating CTE because we cannot use where function with windows function
WITH rowNumCTE as (
select *,
ROW_NUMBER() over(
partition by parcelID, propertyaddress,saleprice,saledate,legalreference order by uniqueID) as row_num
from NashvilleHousing
)
Select * from rowNumCTE where row_num >1 order by ParcelID -- Finding the duplicate entries only

--Delete the rows
--WITH rowNumCTE as (
--select *,
--ROW_NUMBER() over(
--partition by parcelID, propertyaddress,saleprice,saledate,legalreference order by uniqueID) as row_num
--from NashvilleHousing
--)
--DELETE from rowNumCTE where row_num >1

--================================================================================================================================================